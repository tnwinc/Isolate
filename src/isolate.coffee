((root, factory)->
  if typeof exports is 'object'
    module.exports = factory()
  else if typeof define is 'function' and define.amd
    define([],factory)
  else
    root.Isolate = factory()
) this, ->

  # used to keep contexts unique
  isolatedContextNameNumber = 0
  isolationContextNumber = 0

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
        return new RegExp "(^|[^a-zA-Z0-9_])#{path}([.][a-zA-Z]{1,3})?$"
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

    constructor: (@name = 'default')->
      # Update the contexts reference
      IsolationContext.contexts[@name] = this

      # Maintains an ordered list of matcher rules
      @rules = []

      # Maintains a hash of type -> handler rules.
      # Consulted if no @rules match requested module.
      @typeHandlers = {}

      # boostrap isolate into the module prototype
      # if using require inside of node
      if @env is 'commonjs'
        that = this
        Object.getPrototypeOf(module).isolate = (mod)-> that.require mod, this

    # Convert a real module dependency into the appropriate
    # standin implementation.
    processDependency: (path, actual, parent_module_path)=>
      handler = @findMatchingHandler path, actual
      throw Error "Failed to generate fake for module [#{path}] of type [#{getType actual}] while isolating module [#{parent_module_path}]" unless handler?
      return handler.call this, actual, path, parent_module_path

    # Find the appropriate handler configured for a
    # particular module.
    findMatchingHandler: (path, actual)=>
      for rule in @rules
        return rule.handler if rule.matcher.test path
      typeHandler = @typeHandlers[getType(actual).toLowerCase()]
      return typeHandler if typeHandler?
      if @env is 'commonjs'
        fakeModulePath = path.replace '.js', '.isolate-fake.js'
        try fakeModule = require fakeModulePath
        return fakeModule

    #### Node.js / CommonJs
    # Trigger isolation of a particular module.
    # `module.isolate 'some/module'`
    # - or -
    # `isolate.require 'some/module', module`
    require: (requested_module, context)->

      # The runtime context here is the requesting module, if called as
      # shown above.
      # Though the context can be overridden if needed via the second
      # parameter.
      context = context or this

      # Resolve the (possibly) relative module path via the reqeusting
      # module's context.
      full_module_path = module.constructor._resolveFilename(requested_module, context)

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

      # Clear the module cache so that modules will
      # be re-isolated as needed
      module.constructor._cache = {}

      # Run any registered handlers
      if @isolateCompleteHandlers?.length
        handler isolatedModule for handler in @isolateCompleteHandlers

      # Return the isolated module
      return isolatedModule

    #### RequireJs / AMD
    # Trigger isolate of a particular module
    # `require ['isolate!some/module'], (some_module)->`
    load: (requested_module, req, load, config)=>

      # If we haven't been given a reference to the proper require
      # instance, assume its the global require function
      IsolationContext._require or= require

      # Extract the desired isolation context name from the
      # requested module name
      if (_i = requested_module.indexOf ':') > -1
        [isolationContextName, requested_module] = requested_module.split ':'
      else
        isolationContextName = 'default'
      isolationCtx = IsolationContext.contexts[isolationContextName]

      # Get a reference to the main require context.
      # _Note: _ This is likely to break of you are already doing
      # interesting things with the require contexts, such as
      # multiversion support.
      mainCtx = IsolationContext._require?.s?.contexts?['_'] or IsolationContext._require?.context

      # Generate a secondary require context, used to hold the
      # standins.
      isolatedContextName = "isolated_#{isolatedContextNameNumber++}"
      isolationCtx.require = isolatedRequire = IsolationContext._require.config
        context: isolatedContextName
        baseUrl: mainCtx.config.baseUrl

      isolatedRequireCtx = IsolationContext._require.s.contexts[isolatedContextName]

      modulesToLoad = [requested_module].concat isolationCtx.ensuredAsyncModules || []

      # Require the requested module into the real
      # require context in order to load all its depencencies.
      try
        req modulesToLoad, (mod)=>

          # Clear out any items in the secondary require context
          # module cache.
          undef = isolatedRequireCtx.undef or isolatedRequireCtx.require?.undef
          undef _module for _module of isolatedRequireCtx.defined

          # Generate the proper standin for each module defined
          # in the real require context's cache and inject it into
          # the secondary require context.
          for own modName, modVal of mainCtx.defined
            continue if modName in [requested_module, 'isolate']
            isolatedRequireCtx.defined[modName] = isolationCtx.processDependency modName, modVal, requested_module

          dependencies = build_dependencies isolatedRequireCtx.defined

          reload = (done)->
            # Remove the requested module from the secondary
            # require context's cache.
            undef requested_module

            # Require the requested module using the secondary
            # require context, so that it gets the standin
            # implementations injected via the poisioned cache.
            isolatedRequire [requested_module], (isolatedModule)=>
              throw Error "The requested module #{requested_module} was not found." unless isolatedModule?

              # Attach the standin dependencies to the `.dependencies`
              # property.
              isolatedModule.dependencies = dependencies
              reload_method_name = if isolatedModule.reload? then '_reload' else 'reload'
              isolatedModule[reload_method_name] = reload

              # Clear the main module cache so that modules will
              # be re-isolated as needed
              delete mainCtx.defined[key] for key in mainCtx.defined
              #delete mainCtx.registry[key] for key in mainCtx.registry

              # Run any registered handlers
              if isolationCtx.isolateCompleteHandlers?.length
                handler isolatedModule for handler in isolationCtx.isolateCompleteHandlers

              # Pass the isolated module back to the requestor.
              done? isolatedModule

          reload (isolatedModule)-> load isolatedModule

      catch err
        urlForException = "https://github.com/tnwinc/Isolate/wiki/Error:-An-error-occurred-while-preparing-to-isolate-the-module"
        err.message = "An error occurred while preparing to isolate the module: #{requested_module}\nFor more information, see #{urlForException}\nInner Exception:\n#{err.message}"
        throw err

    useRequire: (_require)=>
      IsolationContext._require = _require
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

    isolateComplete: (handler)->
      (@isolateCompleteHandlers = @isolateCompleteHandlers || []).push handler
      return this

    newContext: (name)->
      name = name or "isolation_context_#{isolationContextNumber++}"
      ctx = new IsolationContext(name)
      ctx.rules = this.rules?.slice 0
      ctx.typeHandlers[type] = handler for type, handler of this.typeHandlers
      ctx.isolateCompleteHandlers = this.isolateCompleteHandlers?.slice 0
      return ctx

  IsolationContext.env = IsolationContext.prototype.env = if typeof exports is 'object' then 'commonjs' else 'amd'
  IsolationContext.contexts = {}

  return new IsolationContext
