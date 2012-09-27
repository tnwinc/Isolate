describe "Using amd require", ->
  moduleUnderTest = undefined

  beforeEach ->
    requirejs ['isolate'], (isolate)->
      isolate.reset()
        .map /amd_dependency/, name: 'fake amd dep'

      requirejs ['isolate!amd_basic'], (mut)->
        moduleUnderTest = mut

  afterEach ->
    global.define = undefined

  it 'should provide the fake dependency', ->
    (expect moduleUnderTest.dependency.name).to.equal 'fake amd dep'
