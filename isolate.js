(function() {
  var __hasProp = Object.prototype.hasOwnProperty,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; },
    __slice = Array.prototype.slice;

  (function(root, factory) {
    if (typeof exports === 'object') {
      return module.exports = factory();
    } else if (typeof define === 'function' && define.amd) {
      return define([], factory);
    } else {
      return root.Isolate = factory();
    }
  })(this, function() {
    var IsolationContext, IsolationFactory, build_dependencies, getMatcherForPath, getType, passthru;
    getType = function(o) {
      return Object.prototype.toString.call(o);
    };
    passthru = function(actual) {
      return actual;
    };
    getMatcherForPath = function(path) {
      var path_type;
      path_type = getType(path);
      if (path_type === '[object RegExp]') {
        return path;
      } else if (path_type === '[object String]') {
        if (path[0] + path.slice(-1) === '//') {
          return new RegExp(path.slice(1, -2));
        } else {
          return new RegExp("(^|[^a-zA-Z0-9_])" + path + "([.][a-zA-Z]{1,3})?$");
        }
      }
      throw Error("Expected either a String or RegExp, but got " + (getType(path)));
    };
    build_dependencies = function(dependencies) {
      dependencies.find = function(val) {
        var matching_dependencies, mod, path, regex;
        regex = getMatcherForPath(val);
        matching_dependencies = [];
        for (path in dependencies) {
          if (!__hasProp.call(dependencies, path)) continue;
          mod = dependencies[path];
          if (0 === path.indexOf('isolate!')) continue;
          if (regex.test(path)) matching_dependencies.push(path);
        }
        if (matching_dependencies.length > 1) {
          throw Error("Ambiguous call to find dependency: '" + val + "' matched: [" + matching_dependencies + "]");
        }
        return dependencies[matching_dependencies[0]];
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

      function IsolationContext(name) {
        var that;
        this.name = name != null ? name : 'default';
        this.mapAsFactory = __bind(this.mapAsFactory, this);
        this.reset = __bind(this.reset, this);
        this.willRequire = __bind(this.willRequire, this);
        this.mapType = __bind(this.mapType, this);
        this.map = __bind(this.map, this);
        this.passthru = __bind(this.passthru, this);
        this.useRequire = __bind(this.useRequire, this);
        this.load = __bind(this.load, this);
        this.findMatchingHandler = __bind(this.findMatchingHandler, this);
        this.processDependency = __bind(this.processDependency, this);
        IsolationContext.contexts[this.name] = this;
        this.rules = [];
        this.typeHandlers = {};
        if (this.env === 'commonjs') {
          that = this;
          Object.getPrototypeOf(module).isolate = function(mod) {
            return that.require(mod, this);
          };
        }
      }

      IsolationContext.prototype.processDependency = function(path, actual, parent_module_path) {
        var handler;
        handler = this.findMatchingHandler(path, actual);
        if (handler == null) {
          throw Error("Failed to generate fake for module [" + path + "] of type [" + (getType(actual)) + "] while isolating module [" + parent_module_path + "]");
        }
        return handler(actual, path, parent_module_path);
      };

      IsolationContext.prototype.findMatchingHandler = function(path, actual) {
        var fakeModule, fakeModulePath, rule, typeHandler, _i, _len, _ref;
        _ref = this.rules;
        for (_i = 0, _len = _ref.length; _i < _len; _i++) {
          rule = _ref[_i];
          if (rule.matcher.test(path)) return rule.handler;
        }
        typeHandler = this.typeHandlers[getType(actual).toLowerCase()];
        if (typeHandler != null) return typeHandler;
        if (this.env === 'commonjs') {
          fakeModulePath = path.replace('.js', '.isolate-fake.js');
          try {
            fakeModule = require(fakeModulePath);
          } catch (_error) {}
          return fakeModule;
        }
      };

      IsolationContext.prototype.require = function(requested_module, context) {
        var actual, dependencies, full_module_path, handler, isolatedModule, path, urlForException, _i, _len, _ref, _ref2, _ref3;
        context = context || this;
        full_module_path = module.constructor._resolveFilename(requested_module, context);
        module.constructor._cache = {};
        try {
          require(full_module_path);
        } catch (err) {
          urlForException = "https://github.com/tnwinc/Isolate/wiki/Error:-An-error-occurred-while-preparing-to-isolate-the-module";
          err.message = "An error occurred while preparing to isolate the module: " + requested_module + "\nFor more information, see " + urlForException + "\nInner Exception:\n" + err.message;
          throw err;
        }
        delete module.constructor._cache[full_module_path];
        dependencies = {};
        _ref = module.constructor._cache;
        for (path in _ref) {
          if (!__hasProp.call(_ref, path)) continue;
          actual = _ref[path];
          actual.exports = dependencies[path] = this.processDependency(path, actual.exports, full_module_path);
          actual.exports.actual = actual;
        }
        isolatedModule = require(full_module_path);
        isolatedModule.dependencies = build_dependencies(dependencies);
        module.constructor._cache = {};
        if ((_ref2 = this.isolateCompleteHandlers) != null ? _ref2.length : void 0) {
          _ref3 = this.isolateCompleteHandlers;
          for (_i = 0, _len = _ref3.length; _i < _len; _i++) {
            handler = _ref3[_i];
            handler(isolatedModule);
          }
        }
        return isolatedModule;
      };

      IsolationContext.prototype.load = function(requested_module, req, load, config) {
        var isolatedContextName, isolatedRequire, isolatedRequireCtx, isolationContextName, isolationCtx, mainCtx, modulesToLoad, urlForException, _i, _ref, _ref2, _ref3, _ref4, _ref5,
          _this = this;
        IsolationContext._require || (IsolationContext._require = require);
        if ((_i = requested_module.indexOf(':')) > -1) {
          _ref = requested_module.split(':'), isolationContextName = _ref[0], requested_module = _ref[1];
        } else {
          isolationContextName = 'default';
        }
        isolationCtx = IsolationContext.contexts[isolationContextName];
        mainCtx = ((_ref2 = IsolationContext._require) != null ? (_ref3 = _ref2.s) != null ? (_ref4 = _ref3.contexts) != null ? _ref4['_'] : void 0 : void 0 : void 0) || ((_ref5 = IsolationContext._require) != null ? _ref5.context : void 0);
        isolatedContextName = "isolated_" + (Math.floor(Math.random() * 100000));
        isolatedRequire = IsolationContext._require.config({
          context: isolatedContextName,
          baseUrl: mainCtx.config.baseUrl
        });
        isolatedRequireCtx = IsolationContext._require.s.contexts[isolatedContextName];
        modulesToLoad = [requested_module].concat(isolationCtx.ensuredAsyncModules || []);
        try {
          return req(modulesToLoad, function(mod) {
            var dependencies, modName, modVal, reload, undef, _module, _ref6, _ref7;
            undef = isolatedRequireCtx.undef || ((_ref6 = isolatedRequireCtx.require) != null ? _ref6.undef : void 0);
            for (_module in isolatedRequireCtx.defined) {
              undef(_module);
            }
            _ref7 = mainCtx.defined;
            for (modName in _ref7) {
              if (!__hasProp.call(_ref7, modName)) continue;
              modVal = _ref7[modName];
              if (modName === requested_module || modName === 'isolate') continue;
              isolatedRequireCtx.defined[modName] = isolationCtx.processDependency(modName, modVal, requested_module);
            }
            dependencies = build_dependencies(isolatedRequireCtx.defined);
            reload = function(done) {
              var _this = this;
              undef(requested_module);
              return isolatedRequire([requested_module], function(isolatedModule) {
                var handler, key, reload_method_name, _j, _k, _len, _len2, _ref10, _ref8, _ref9;
                if (isolatedModule == null) {
                  throw Error("The requested module " + requested_module + " was not found.");
                }
                isolatedModule.dependencies = dependencies;
                reload_method_name = isolatedModule.reload != null ? '_reload' : 'reload';
                isolatedModule[reload_method_name] = reload;
                _ref8 = mainCtx.defined;
                for (_j = 0, _len = _ref8.length; _j < _len; _j++) {
                  key = _ref8[_j];
                  delete mainCtx.defined[key];
                }
                if ((_ref9 = isolationCtx.isolateCompleteHandlers) != null ? _ref9.length : void 0) {
                  _ref10 = isolationCtx.isolateCompleteHandlers;
                  for (_k = 0, _len2 = _ref10.length; _k < _len2; _k++) {
                    handler = _ref10[_k];
                    handler(isolatedModule);
                  }
                }
                return typeof done === "function" ? done(isolatedModule) : void 0;
              });
            };
            return reload(function(isolatedModule) {
              return load(isolatedModule);
            });
          });
        } catch (err) {
          urlForException = "https://github.com/tnwinc/Isolate/wiki/Error:-An-error-occurred-while-preparing-to-isolate-the-module";
          err.message = "An error occurred while preparing to isolate the module: " + requested_module + "\nFor more information, see " + urlForException + "\nInner Exception:\n" + err.message;
          throw err;
        }
      };

      IsolationContext.prototype.useRequire = function(_require) {
        IsolationContext._require = _require;
        return this;
      };

      IsolationContext.prototype.passthru = function() {
        var path, paths, _i, _len;
        paths = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if ('[object Array]' === getType(paths[0])) paths = paths[0];
        for (_i = 0, _len = paths.length; _i < _len; _i++) {
          path = paths[_i];
          this.rules.unshift({
            matcher: getMatcherForPath(path),
            handler: passthru
          });
        }
        return this;
      };

      IsolationContext.prototype.map = function() {
        var args, handler, path, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (getType(args[0]) === '[object Object]') {
          _ref = args[0];
          for (path in _ref) {
            if (!__hasProp.call(_ref, path)) continue;
            handler = _ref[path];
            this.map(path, handler);
          }
        } else {
          path = args[0];
          handler = args[1];
          this.rules.unshift({
            matcher: getMatcherForPath(path),
            handler: handler instanceof IsolationFactory ? handler.factory : function() {
              return handler;
            }
          });
        }
        return this;
      };

      IsolationContext.prototype.mapType = function() {
        var args, handler, type, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (getType(args[0]) === '[object Object]') {
          _ref = args[0];
          for (type in _ref) {
            if (!__hasProp.call(_ref, type)) continue;
            handler = _ref[type];
            this.mapType(type, handler);
          }
        } else {
          type = "[object " + (args[0].toLowerCase()) + "]";
          handler = args[1];
          this.typeHandlers[type] = handler instanceof IsolationFactory ? handler.factory : function() {
            return handler;
          };
        }
        return this;
      };

      IsolationContext.prototype.willRequire = function() {
        var args, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        this.ensuredAsyncModules || (this.ensuredAsyncModules = []);
        (_ref = this.ensuredAsyncModules).push.apply(_ref, args);
        return this;
      };

      IsolationContext.prototype.reset = function() {
        this.rules.length = 0;
        this.typeHandlers = {};
        return this;
      };

      IsolationContext.prototype.mapAsFactory = function() {
        var args, factory, path, _ref;
        args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
        if (args.length === 1) {
          if ('[object Function]' === getType(args[0])) {
            return new IsolationFactory(args[0]);
          } else {
            _ref = args[0];
            for (path in _ref) {
              if (!__hasProp.call(_ref, path)) continue;
              factory = _ref[path];
              this.mapAsFactory(path, factory);
            }
          }
        } else {
          path = args[0];
          factory = args[1];
          this.rules.unshift({
            matcher: getMatcherForPath(path),
            handler: factory
          });
        }
        return this;
      };

      IsolationContext.prototype.isolateComplete = function(handler) {
        (this.isolateCompleteHandlers = this.isolateCompleteHandlers || []).push(handler);
        return this;
      };

      IsolationContext.prototype.newContext = function(name) {
        var ctx, handler, type, _ref, _ref2, _ref3;
        name = name || ("isolation_context_" + (Math.floor(Math.random() * 10000)));
        ctx = new IsolationContext(name);
        ctx.rules = (_ref = this.rules) != null ? _ref.slice(0) : void 0;
        _ref2 = this.typeHandlers;
        for (type in _ref2) {
          handler = _ref2[type];
          ctx.typeHandlers[type] = handler;
        }
        ctx.isolateCompleteHandlers = (_ref3 = this.isolateCompleteHandlers) != null ? _ref3.slice(0) : void 0;
        return ctx;
      };

      return IsolationContext;

    })();
    IsolationContext.env = IsolationContext.prototype.env = typeof exports === 'object' ? 'commonjs' : 'amd';
    IsolationContext.contexts = {};
    return new IsolationContext;
  });

}).call(this);