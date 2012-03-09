(function() {
  var IsolationContext, IsolationFactory, build_dependencies, getMatcherForPath, getType, isolate_has_been_configured, passthru,
    __hasProp = Object.prototype.hasOwnProperty,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  getType = function(o) {
    return Object.prototype.toString.call(o);
  };

  passthru = function(actual) {
    return actual;
  };

  isolate_has_been_configured = false;

  getMatcherForPath = function(path) {
    var path_type;
    path_type = getType(path);
    if (path_type === '[object RegExp]') {
      return path;
    } else if (path_type === '[object String]') {
      if (path[0] + path.slice(-1) === '//') {
        return new RegExp(path.slice(1, -2));
      } else {
        return path;
      }
    }
    throw Error("Expected either a String or RegExp, but got " + (getType(path)));
  };

  build_dependencies = function(dependencies) {
    dependencies.find = function(val) {
      var mod, path, regex;
      regex = '[object RegExp]' === getType(val) ? val : new RegExp("\/[^\/]*" + val + "[^.]*\.");
      for (path in dependencies) {
        if (!__hasProp.call(dependencies, path)) continue;
        mod = dependencies[path];
        if (regex.test(path)) return mod;
      }
    };
    return dependencies;
  };

  IsolationFactory = (function() {

    function IsolationFactory(factory) {
      this.factory = factory;
    }

    return IsolationFactory;

  })();

  IsolationContext = (function() {

    function IsolationContext() {
      this.configure = __bind(this.configure, this);
      this.load = __bind(this.load, this);
      this.isolate = __bind(this.isolate, this);
      this.processDependency = __bind(this.processDependency, this);
      this.findMatchingHandler = __bind(this.findMatchingHandler, this);      this.rules = [];
      this.typeHandlers = {};
    }

    IsolationContext.prototype.findMatchingHandler = function(path, actual) {
      var rule, _i, _len, _ref;
      _ref = this.rules;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        rule = _ref[_i];
        if ((rule.matcher instanceof RegExp && rule.matcher.test(path)) || (rule.matcher === path)) {
          return rule.handler;
        }
      }
      return this.typeHandlers[getType(actual).toLowerCase()];
    };

    IsolationContext.prototype.processDependency = function(path, actual, parent_module_path) {
      var handler;
      handler = this.findMatchingHandler(path, actual);
      if (handler == null) {
        throw Error("Failed to generate fake for module [" + path + "] of type [" + (getType(actual)) + "] while isolating module [" + parent_module_path + "]");
      }
      return handler(actual, path, parent_module_path);
    };

    IsolationContext.prototype.isolate = function(requested_module, context) {
      var actual, clearModuleCache, dependencies, full_module_path, isolatedModule, moduleCache, path, resolveFilename;
      resolveFilename = module.constructor._resolveFilename;
      moduleCache = module.constructor._cache;
      clearModuleCache = function() {
        return moduleCache = module.constructor._cache = {};
      };
      if (!isolate_has_been_configured) {
        throw Error('Isolate has not been configured. Please see the documentation for configuration options');
      }
      full_module_path = resolveFilename(requested_module, context)[0];
      clearModuleCache();
      require(full_module_path);
      delete moduleCache[full_module_path];
      dependencies = {};
      for (path in moduleCache) {
        if (!__hasProp.call(moduleCache, path)) continue;
        actual = moduleCache[path];
        actual.exports = dependencies[path] = this.processDependency(path, actual.exports, full_module_path);
        actual.exports.actual = actual;
      }
      isolatedModule = require(full_module_path);
      isolatedModule.dependencies = build_dependencies(dependencies);
      return isolatedModule;
    };

    IsolationContext.prototype.load = function(requested_module, req, load, config) {
      var isolatedContextName, isolatedCtx, isolatedRequire, mainCtx,
        _this = this;
      mainCtx = this.require.s.contexts['_'];
      isolatedContextName = "isolated_" + (Math.floor(Math.random() * 100000));
      isolatedRequire = this.require.config({
        context: isolatedContextName,
        baseUrl: mainCtx.config.baseUrl
      });
      isolatedCtx = this.require.s.contexts[isolatedContextName];
      return req([requested_module], function(mod) {
        var key, modName, modVal, _i, _j, _len, _len2, _ref, _ref2, _ref3;
        _ref = isolatedCtx.defined;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          key = _ref[_i];
          delete isolatedCtx.defined[key];
        }
        _ref2 = isolatedCtx.loaded;
        for (_j = 0, _len2 = _ref2.length; _j < _len2; _j++) {
          key = _ref2[_j];
          delete isolatedCtx.loaded[key];
        }
        _ref3 = mainCtx.defined;
        for (modName in _ref3) {
          if (!__hasProp.call(_ref3, modName)) continue;
          modVal = _ref3[modName];
          if (modName === requested_module) continue;
          isolatedCtx.defined[modName] = _this.processDependency(modName, modVal, requested_module);
          isolatedCtx.loaded[modName] = true;
        }
        delete isolatedCtx.defined[requested_module];
        delete isolatedCtx.loaded[requested_module];
        return isolatedRequire([requested_module], function(isolatedModule) {
          isolatedModule.dependencies = build_dependencies(isolatedCtx.defined);
          return load(isolatedModule);
        });
      });
    };

    IsolationContext.prototype.configure = function(require, configurationFunction) {
      var contextConfigurator,
        _this = this;
      this.require = require;
      contextConfigurator = {
        passthru: function() {
          var path, paths, _i, _len;
          paths = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          for (_i = 0, _len = paths.length; _i < _len; _i++) {
            path = paths[_i];
            _this.rules.unshift({
              matcher: getMatcherForPath(path),
              handler: passthru
            });
          }
          return contextConfigurator;
        },
        map: function() {
          var args, handler, path, _ref;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (getType(args[0]) === '[object Object]') {
            _ref = args[0];
            for (path in _ref) {
              if (!__hasProp.call(_ref, path)) continue;
              handler = _ref[path];
              contextConfigurator.map(path, handler);
            }
          } else {
            path = args[0];
            handler = args[1];
            _this.rules.unshift({
              matcher: getMatcherForPath(path),
              handler: handler instanceof IsolationFactory ? handler.factory : function() {
                return handler;
              }
            });
          }
          return contextConfigurator;
        },
        mapType: function() {
          var args, handler, type, _ref;
          args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
          if (getType(args[0]) === '[object Object]') {
            _ref = args[0];
            for (type in _ref) {
              if (!__hasProp.call(_ref, type)) continue;
              handler = _ref[type];
              contextConfigurator.mapType(type, handler);
            }
          } else {
            type = "[object " + (args[0].toLowerCase()) + "]";
            handler = args[1];
            _this.typeHandlers[type] = handler instanceof IsolationFactory ? handler.factory : function() {
              return handler;
            };
          }
          return contextConfigurator;
        }
      };
      contextConfigurator.map.asFactory = function() {
        var args, factory, path;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (args.length === 1) return new IsolationFactory(args[0]);
        path = args[0];
        factory = args[1];
        _this.rules.unshift({
          matcher: getMatcherForPath(path),
          handler: factory
        });
      };
      isolate_has_been_configured = true;
      return configurationFunction(contextConfigurator);
    };

    return IsolationContext;

  })();

  module.exports = new IsolationContext;

}).call(this);
