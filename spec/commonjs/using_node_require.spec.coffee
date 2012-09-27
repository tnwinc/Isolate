describe "Using node's require", ->
  moduleUnderTest = undefined

  beforeEach ->
    isolate = require 'isolate'
    isolate.reset()
      .map /commonjs_dependency/, name: 'fake commonjs dep'

    moduleUnderTest = isolate.require 'modules_for_testing/commonjs_basic'

  it 'should provide the fake dependency', ->
    (expect moduleUnderTest.dependency.name).to.equal 'fake commonjs dep'
