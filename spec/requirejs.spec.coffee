global.expect = require('chai').expect

path = require 'path'
requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require
  baseUrl: path.join __dirname, 'modules_for_testing', 'requirejs'
global.define = global.requirejs = requirejs



runTests = (isolate)->

  moduleFactory = (module_name, fun)->
    isolationContext = isolate
    if(arguments.length > 2)
      isolationContext = arguments[0]
      module_name = arguments[1]
      fun = arguments[2]
    isolationContext = if isolationContext.name? then "#{isolationContext.name}:" else ''
    requirejs ["isolate!#{isolationContext}#{module_name}"], fun

  describe "Using amd require", ->

    beforeEach ->
      mainCtx = requirejs?.s?.contexts?['_'] or requirejs?.context
      undef = mainCtx.undef or mainCtx.require.undef
      undef _module for _module of mainCtx.defined
      isolate.reset()

    require('all_behaviours')
      .ensure_all_behaviours isolate, moduleFactory

    describe 'Handling requirejs plugins', ->
      beforeEach (done)->
        isolate.passthru 'dependency'
        isolate.map
          'text!dependency': { name: 'text[real dep]' }
          'text': {}

        requirejs.define 'text', [], load: (mod_name, req, load)-> load {}

        moduleFactory 'depends_on_plugin', (@mut)=>
          done()

      it 'should inject the naked dependency properly', ->
        (expect @mut.dependency.name).to.equal 'real dependency'
      it 'should properly find the naked dependency in the dependencies object', ->
        (expect @mut.dependencies['dependency'].name).to.equal 'real dependency'
      it 'should inject the wrapped dependency properly', ->
        (expect @mut.text_dependency.name).to.equal 'text[real dep]'
      it 'should properly find the wrapped dependency in the dependencies object', ->
        (expect @mut.dependencies['text!dependency'].name).to.equal 'text[real dep]'

if requirejs.version.match /^2\.1\..*/
  isolate = requirejs 'isolate'
  isolate.useRequire(requirejs)
  runTests isolate

else if requirejs.version.match /^2\.0\..*/
  requirejs ['isolate'], (isolate)->
    isolate.useRequire(requirejs)
    runTests isolate
