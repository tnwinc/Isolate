isolate_instance = require 'isolate'
requirejs = require 'requirejs'
requirejs.config
  baseUrl: "#{__dirname}/../"
requirejs.define 'isolate', isolate_instance

describe 'Isolate', ->
  describe 'Async require statements in module under test', ->

    beforeEach (done)->
      isolate_instance.configure requirejs, (ctx)->
        ctx.reset()
        ctx.map 'b', name: 'fake-b'
        ctx.ensureAsyncModules 'spec-fixtures/async-require/b'

      requirejs ['isolate!spec-fixtures/async-require/a'], (@a)=>
        done()

    it 'should provide the proper fake to the module under test', (done)->
      doIt = =>
        (expect @a.b.name).to.equal 'fake-b'
        done()
      setTimeout doIt, 0
