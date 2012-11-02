global.expect = (require 'chai').expect

path = require 'path'
requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require
  baseUrl: path.join __dirname, 'modules_for_testing', 'requirejs'
global.define = global.requirejs = requirejs

isolate = requirejs 'isolate'
isolate.useRequire(requirejs)


describe "Using amd require", ->

  beforeEach ->
    mainCtx = requirejs?.s?.contexts?['_'] or requirejs?.context
    undef = mainCtx.undef or mainCtx.require.undef
    undef _module for _module of mainCtx.defined
    isolate.reset()

  require('all_behaviours')
    .ensure_all_behaviours isolate, (module_name, fun)->
      isolationContext = isolate
      if(arguments.length > 2)
        isolationContext = arguments[0]
        module_name = arguments[1]
        fun = arguments[2]
      isolationContext = if isolationContext.name? then "#{isolationContext.name}:" else ''
      requirejs ["isolate!#{isolationContext}#{module_name}"], fun
