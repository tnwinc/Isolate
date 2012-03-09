# These are helpers to keep later code more readable

getType = (o)-> Object.prototype.toString.call o
passthru = (actual)-> actual

isolate_has_been_configured = false
getMatcherForPath = (path)->
  path_type = getType path
  if path_type == '[object RegExp]'
    return path
  else if path_type == '[object String]'
    if path[0] + path.slice(-1) == '//'
      return new RegExp path[1...-2]
    else
      return path
  throw Error "Expected either a String or RegExp, but got #{getType path}"

build_dependencies = (dependencies)->
  dependencies.find = (val)->
    regex = if '[object RegExp]' == getType val then val else new RegExp "\/[^\/]*#{val}[^.]*\."
    for own path, mod of dependencies
      return mod if regex.test path
  return dependencies



# Provides a fully internally-used marker class
class IsolationFactory
  constructor: (@factory)->


class IsolationContext

  constructor: ->
    @rules = []
    @typeHandlers = {}

  # this method should probably be memoized
  findMatchingHandler: (path, actual)=>
    for rule in @rules
      return rule.handler if (rule.matcher instanceof RegExp and rule.matcher.test path) or (rule.matcher == path)
    return @typeHandlers[getType(actual).toLowerCase()]

  processDependency: (path, actual, parent_module_path)=>
    handler = @findMatchingHandler path, actual
    throw Error "Failed to generate fake for module [#{path}] of type [#{getType actual}] while isolating module [#{parent_module_path}]" unless handler?
    return handler actual, path, parent_module_path


  isolate: (requested_module, context)=>
    resolveFilename = module.constructor._resolveFilename
    moduleCache = module.constructor._cache
    clearModuleCache = ->
      moduleCache = module.constructor._cache = {}

    throw Error 'Isolate has not been configured. Please see the documentation for configuration options' unless isolate_has_been_configured
    full_module_path = resolveFilename(requested_module, context)[0]
    clearModuleCache()
    require full_module_path
    delete moduleCache[full_module_path]

    dependencies = {}
    for own path, actual of moduleCache
      actual.exports = dependencies[path] = @processDependency(path, actual.exports, full_module_path)
      actual.exports.actual = actual

    isolatedModule = require full_module_path
    isolatedModule.dependencies = build_dependencies dependencies

    return isolatedModule

  load: (requested_module, req, load, config)=>
    mainCtx = @require.s.contexts['_']
    isolatedContextName = "isolated_#{Math.floor Math.random() * 100000}"
    isolatedRequire = @require.config
      context: isolatedContextName
      baseUrl: mainCtx.config.baseUrl
    isolatedCtx = @require.s.contexts[isolatedContextName]

    req [requested_module], (mod)=>
      delete isolatedCtx.defined[key] for key in isolatedCtx.defined
      delete isolatedCtx.loaded[key] for key in isolatedCtx.loaded

      for own modName, modVal of mainCtx.defined
        continue if modName == requested_module
        isolatedCtx.defined[modName] = @processDependency modName, modVal, requested_module
        isolatedCtx.loaded[modName] = true

      delete isolatedCtx.defined[requested_module]
      delete isolatedCtx.loaded[requested_module]

      isolatedRequire [requested_module], (isolatedModule)->
        isolatedModule.dependencies = build_dependencies isolatedCtx.defined
        load isolatedModule

  configure: (@require, configurationFunction)=>
    contextConfigurator =
      passthru: (paths...)=>
        for path in paths
          @rules.unshift
            matcher: getMatcherForPath path
            handler: passthru
        return contextConfigurator
      map: (args...)=>
        if getType(args[0]) == '[object Object]'
          contextConfigurator.map(path, handler) for own path, handler of args[0]
        else
          path = args[0]
          handler = args[1]
          @rules.unshift
            matcher: getMatcherForPath path
            handler: if handler instanceof IsolationFactory then handler.factory else -> handler
        return contextConfigurator

      mapType: (args...)=>
        if getType(args[0]) == '[object Object]'
          contextConfigurator.mapType(type, handler) for own type, handler of args[0]
        else
          type = "[object #{args[0].toLowerCase()}]"
          handler = args[1]
          @typeHandlers[type] = if handler instanceof IsolationFactory then handler.factory else -> handler
        return contextConfigurator


    contextConfigurator.map.asFactory = (args...)=>
      if args.length == 1
        return new IsolationFactory args[0]
      path = args[0]
      factory = args[1]
      @rules.unshift
        matcher: getMatcherForPath path
        handler: factory
      return undefined

    isolate_has_been_configured = true
    configurationFunction contextConfigurator


module.exports = new IsolationContext
