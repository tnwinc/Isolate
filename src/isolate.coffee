# module loader boilerplate to allow this module to be
# loaded by either requirejs(AMD) or node's require (CommonJs)
+{define: if typeof define == 'function' then define else (F)-> F require, exports, module}.define (require, exports, module)->

  #### Helpers to keep later code more readable
  # Get's the Object.prototype.toString "type" of an object.
  # It is often more informative than a simple typeof statement.
  getType = (o)-> Object.prototype.toString.call o

  # Handler function for passthru mappings.
  # Simply returns its argument
  passthru = (actual)-> actual

  # Converts a RegExp or string into a matcher, given
  # specific rules around handling of strings.
  getMatcherForPath = (path)->
    path_type = getType path
    if path_type == '[object RegExp]'
      return path
    else if path_type == '[object String]'
      if path[0] + path.slice(-1) == '//'
        return new RegExp path[1...-2]
      else
        return new RegExp "(^|[^a-zA-Z0-9_])#{path}(\.[a-zA-Z]+)?$"
    throw Error "Expected either a String or RegExp, but got #{getType path}"

  # Extend a dependencies array with a find function
  # to make dependency lookup easier.
  build_dependencies = (dependencies)->
    dependencies.find = (val)->
      regex = getMatcherForPath val
      matching_dependencies = []
      for own path, mod of dependencies
        continue if 0 == path.indexOf 'isolate!'
        matching_dependencies.push path if regex.test path
      if matching_dependencies.length > 1
        throw Error "Ambiguous call to find dependency: '#{val}' matched: [#{matching_dependencies}]"
      return dependencies[matching_dependencies[0]]
    return dependencies


  # Internally used marker class to flag a rule
  # handler as a factory, instead of just a function literal.
  class IsolationFactory
    constructor: (@factory)->


  # The main class for Isolate
  class IsolationContext

    constructor: ->
      # Maintains an ordered list of matcher rules
      @rules = []

      # Maintains a hash of type -> handler rules.
      # Consulted if no @rules match requested module.
      @typeHandlers = {}

      # boostrap isolate into the module prototype
      # if using require inside of node
      Object.getPrototypeOf(module).isolate = @isolate

    # Convert a real module dependency into the appropriate
    # standin implementation.
    processDependency: (path, actual, parent_module_path)=>
      handler = @findMatchingHandler path, actual
      throw Error "Failed to generate fake for module [#{path}] of type [#{getType actual}] while isolating module [#{parent_module_path}]" unless handler?
      return handler actual, path, parent_module_path

    # Find the appropriate handler configured for a
    # particular module.
    findMatchingHandler: (path, actual)=>
      for rule in @rules
        return rule.handler if rule.matcher.test path
      return @typeHandlers[getType(actual).toLowerCase()]

    #### Node.js / CommonJs
    # Trigger isolation of a particular module.
    # `module.isolate 'some/module'`
    isolate: (requested_module, context)=>

      # The runtime context here is the requesting module, if called as
      # shown above.
      # Though the context can be overridden if needed via the second
      # parameter.
      context = context | this

      # Resolve the (possibly) relative module path via the reqeusting
      # module's context.
      full_module_path = module.constructor._resolveFilename(requested_module, context)[0]

      # Clear module cache so that when we load the module again, only
      # it's dependency tree will be loaded.
      module.constructor._cache = {}

      # Load the requested module into the newly clean cache.
      try
        require full_module_path
      catch err
        urlForException = "https://github.com/tnwinc/Isolate/wiki/Error:-An-error-occurred-while-preparing-to-isolate-the-module"
        err.message = "An error occurred while preparing to isolate the module: #{requested_module}\nFor more information, see #{urlForException}\nInner Exception:\n#{err.message}"
        throw err


      # Remove the requested module from the cache so that only its
      # depencency tree is remaining.
      delete module.constructor._cache[full_module_path]

      # For each dependency in the cache, create the proper standin and
      # replace the instance in the cache.
      dependencies = {}
      for own path, actual of module.constructor._cache
        actual.exports = dependencies[path] = @processDependency(path, actual.exports, full_module_path)
        # Sometimes you really need to get to the real deal.
        # It's magically available via the `.actual` property of the
        # standin.
        actual.exports.actual = actual

      # Re-require the requested module using the poisioned cache so
      # that it loads the standins.
      isolatedModule = require full_module_path

      # Make the standins available via the `.dependencies` property.
      isolatedModule.dependencies = build_dependencies dependencies

      # Return the isolated module
      return isolatedModule

    #### RequireJs / AMD
    # Trigger isolate of a particular module
    # `require ['isolate!some/module'], (some_module)->`
    load: (requested_module, req, load, config)=>

      # If we haven't been given a reference to the proper require
      # instance, assume its the global require function
      @require or= require

      # Get a reference to the main require context.
      # _Note: _ This is likely to break of you are already doing
      # interesting things with the require contexts, such as
      # multiversion support.
      mainCtx = @require.s.contexts['_']

      # Generate a secondary require context, used to hold the
      # standins.
      isolatedContextName = "isolated_#{Math.floor Math.random() * 100000}"
      isolatedRequire = @require.config
        context: isolatedContextName
        baseUrl: mainCtx.config.baseUrl
      isolatedCtx = @require.s.contexts[isolatedContextName]

      modulesToLoad = [requested_module].concat @ensuredAsyncModules || []

      # Require the requested module into the real
      # require context in order to load all its depencencies.
      try
        req modulesToLoad, (mod)=>

          # Clear out any items in the secondary require context
          # module cache.
          delete isolatedCtx.defined[key] for key in isolatedCtx.defined
          delete isolatedCtx.loaded[key] for key in isolatedCtx.loaded

          # Generate the proper standin for each module defined
          # in the real require context's cache and inject it into
          # the secondary require context.
          for own modName, modVal of mainCtx.defined
            continue if modName == requested_module
            isolatedCtx.defined[modName] = @processDependency modName, modVal, requested_module unless modName == 'isolate'
            isolatedCtx.loaded[modName] = true

          # Remove the requested module from the secondary
          # require context's cache.
          delete isolatedCtx.defined[requested_module]
          delete isolatedCtx.loaded[requested_module]

          # Require the requested module using the secondary
          # require context, so that it gets the standin
          # implementations injected via the poisioned cache.
          isolatedRequire [requested_module], (isolatedModule)->
            throw Error "The requested module #{requested_module} was not found." unless isolatedModule?

            # Attach the standin dependencies to the `.dependencies`
            # property.
            isolatedModule.dependencies = build_dependencies isolatedCtx.defined

            # Pass the isolated module back to the requestor.
            load isolatedModule
      catch err
        urlForException = "https://github.com/tnwinc/Isolate/wiki/Error:-An-error-occurred-while-preparing-to-isolate-the-module"
        err.message = "An error occurred while preparing to isolate the module: #{requested_module}\nFor more information, see #{urlForException}\nInner Exception:\n#{err.message}"
        throw err

    useRequire: (@require)=>
      return this

    passthru: (paths...)=>
      paths= paths[0] if '[object Array]' == getType paths[0]
      for path in paths
        @rules.unshift
          matcher: getMatcherForPath path
          handler: passthru
      return this

    map: (args...)=>
      if getType(args[0]) == '[object Object]'
        @map(path, handler) for own path, handler of args[0]
      else
        path = args[0]
        handler = args[1]
        @rules.unshift
          matcher: getMatcherForPath path
          handler: if handler instanceof IsolationFactory then handler.factory else -> handler
      return this

    mapType: (args...)=>
      if getType(args[0]) == '[object Object]'
        @mapType(type, handler) for own type, handler of args[0]
      else
        type = "[object #{args[0].toLowerCase()}]"
        handler = args[1]
        @typeHandlers[type] = if handler instanceof IsolationFactory then handler.factory else -> handler
      return this

    willRequire: (args...)=>
      @ensuredAsyncModules or= []
      @ensuredAsyncModules.push args...
      return this

    reset: =>
      @rules.length = 0
      @typeHandlers = {}
      return this

    mapAsFactory: (args...)=>
      if args.length == 1
        if '[object Function]' == getType args[0]
          return new IsolationFactory args[0]
        else
          for own path, factory of args[0]
            @mapAsFactory path, factory
      else
        path = args[0]
        factory = args[1]
        @rules.unshift
          matcher: getMatcherForPath path
          handler: factory
      return this

  module.exports = new IsolationContext
