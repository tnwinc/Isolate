global.expect = (require 'chai').expect
isolate = require 'isolate'

describe "Using node's require", ->

  beforeEach ->
    module.constructor._cache = {}
    isolate.reset()

  require('all_behaviours')
    .ensure_all_behaviours isolate, (module_name, fun)->
      isolationContext = isolate
      if(arguments.length > 2)
        isolationContext = arguments[0]
        module_name = arguments[1]
        fun = arguments[2]
      mod = isolationContext.require module_name
      fun mod

  describe 'requiring modules with a deep path', ->

    beforeEach ->
      ctx = isolate.newContext('complex-requirement')
               .passthru 'complex'
      @mut = ctx.require 'module-with-complex-requirement'

    it 'should passthru the module', ->
      (expect @mut.requirement?.name).to.equal 'real complex-module'
