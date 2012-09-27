global.expect = (require 'chai').expect
isolate = require 'isolate'

describe "Using node's require", ->

  beforeEach ->
    module.constructor._cache = {}
    isolate.reset()

  require('all_behaviours')
    .isolateModulesLikeThis( (module_name)-> isolate.require module_name)
    .ensure_all_behaviours(isolate)
