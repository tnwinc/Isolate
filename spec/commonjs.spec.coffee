global.expect = (require 'chai').expect
isolate = require 'isolate'

describe "Using node's require", ->

  beforeEach ->
    module.constructor._cache = {}
    isolate.reset()

  require('all_behaviours')
    .ensure_all_behaviours(isolate, (module_name, isolationContext = isolate)->
      isolationContext.require module_name)
