global.expect = (require 'chai').expect

path = require 'path'
requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require
  baseUrl: path.join __dirname, 'modules_for_testing', 'requirejs'
global.define = global.requirejs = requirejs

isolate = undefined
requirejs ['isolate'], (_isolate)->
  _isolate.useRequire(requirejs)
  isolate = _isolate


describe "Using amd require", ->

  beforeEach ->
    requirejs ['isolate'], (isolate)->
      mainCtx = requirejs?.s?.contexts?['_'] or requirejs?.context
      mainCtx.undef _module for _module of mainCtx.defined
      isolate.reset()

  require('all_behaviours')
    .isolateModulesLikeThis (module_name)->
      moduleUnderTest = undefined
      requirejs ["isolate!#{module_name}"], (mut)->
        moduleUnderTest = mut
      return moduleUnderTest
    .ensure_all_behaviours(isolate)
