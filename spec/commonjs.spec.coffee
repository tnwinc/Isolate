global.expect = (require 'chai').expect
isolate = require 'isolate'

describe "Using node's require", ->

  beforeEach ->
    module.constructor._cache = {}
    isolate.reset()

  require('./all_behaviours')
    .ensure_all_behaviours isolate, (module_name, fun)->
      isolationContext = isolate
      if(arguments.length > 2)
        isolationContext = arguments[0]
        module_name = arguments[1]
        fun = arguments[2]
      mod = isolationContext.require "./commonjs_specific/"+module_name
      fun mod
