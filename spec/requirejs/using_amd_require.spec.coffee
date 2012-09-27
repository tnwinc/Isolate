describe "Using amd require", ->
  moduleUnderTest = undefined

  beforeEach ->
    path = require 'path'
    requirejs = require 'requirejs'
    requirejs.config
      nodeRequire: require
      baseUrl: path.dirname __dirname
    global.define = requirejs

    requirejs ['isolate'], (isolate)->
      isolate.reset()
        .useRequire(requirejs)
        .map /amd_dependency/, name: 'fake amd dep'

      requirejs ['isolate!modules_for_testing/amd_basic'], (mut)->
        moduleUnderTest = mut

  afterEach ->
    global.define = undefined

  it 'should provide the fake dependency', ->
    (expect moduleUnderTest.dependency.name).to.equal 'fake amd dep'
