mut = undefined

forEachVariation = (variations, fn)->
  fn(type, matcher) for own type, matcher of variations

exports.ensure_all_behaviours = (isolate, moduleFactory)->
  throw Error 'Must call `isolateModulesLikeThis` first.' unless moduleFactory?

  describe 'Isolate Configuration', ->
    describe 'mapping rules', ->
      describe 'types of maps', ->


        describe 'passthru', ->
          describe 'when given a params list', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the real implementations for the dependency module', ->
                  isolate.passthru matcher
                  mut = moduleFactory 'basic'
                  (expect mut.dependency.name).to.equal 'real dependency'

          describe 'when given an array', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the real implementations for each module', ->
                  isolate.passthru [matcher]
                  (expect mut.dependency.name).to.equal 'real dependency'



        describe 'map', ->
          describe 'when given a single mapping rule', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the fake implementations to the isolated module', ->
                  isolate.map matcher, name: 'fake dependency'
                  mut = moduleFactory 'basic'
                  (expect mut.dependency.name).to.equal 'fake dependency'

          describe 'when given a hash of mapping rules', ->
            forEachVariation string: 'dependency', regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the fake implementations to the isolated module', ->
                  settings = {}
                  settings[matcher] = name: 'fake dependency'
                  isolate.map settings
                  mut = moduleFactory 'basic'
                  (expect mut.dependency.name).to.equal 'fake dependency'





        describe 'mapType', ->
          describe 'when given a single mapping rule', ->
            it 'should provide the fake implementations to the isolated module', ->
              isolate.mapType 'object', name: 'fake type dep'
              mut = moduleFactory 'basic'
              (expect mut.dependency.name).to.equal 'fake type dep'

          describe 'when given a hash of mapping rules', ->
            it 'should provide the fake implementations to the isolated module', ->
              isolate.mapType
                'object':
                  name: 'fake type dep'
              mut = moduleFactory 'basic'
              (expect mut.dependency.name).to.equal 'fake type dep'





        describe 'mapAsFactory', ->
          describe 'when used standalone', ->
            describe 'when given a single mapping rule', ->
              it 'should provide the fake implementations to the isolated module', ->
                isolate.mapAsFactory 'dependency', -> name: 'factory fake'
                mut = moduleFactory 'basic'
                (expect mut.dependency.name).to.equal 'factory fake'

            describe 'when given a hash of mapping rules', ->
              it 'should provide the fake implementations to the isolated module', ->
                isolate.mapAsFactory
                  'dependency': -> name: 'factory fake'
                mut = moduleFactory 'basic'
                (expect mut.dependency.name).to.equal 'factory fake'

          describe 'when used with map', ->
            it 'should provide the fake implementations to the isolated module', ->
              isolate.map
                'dependency': isolate.mapAsFactory -> name: 'factory fake thru map'
              mut = moduleFactory 'basic'
              (expect mut.dependency.name).to.equal 'factory fake thru map'

          describe 'when used with mapType', ->
            it 'should provide the fake implementations to the isolated module', ->
              isolate.mapType
                'object': isolate.mapAsFactory -> name: 'factory fake thru mapType'
              mut = moduleFactory 'basic'
              (expect mut.dependency.name).to.equal 'factory fake thru mapType'




        describe 'order of precedence', ->

          beforeEach ->
            isolate.mapType 'object', name: 'the-fake-object'
            isolate.map 'dependency', name: 'the-fake-dep'
            isolate.map 'dependency', name: 'the-second-fake-dep'
            mut = moduleFactory 'basic'

          it 'should select last matching rule defined', ->
            (expect mut.dependency.name).to.equal 'the-second-fake-dep'





      describe 'mapping using RegExp instances', ->
        it 'should return the expected fake', ->
          isolate.map /.*/, name: 'some-fake'
          mut = moduleFactory 'basic'
          (expect mut.dependency.name).to.equal 'some-fake'

      describe 'mapping using strings representing RegExp', ->
        it 'should return the expected fake', ->
          isolate.map '/.*/', name: 'some-fake'
          mut = moduleFactory 'basic'
          (expect mut.dependency.name).to.equal 'some-fake'




  describe 'Creating New Isolation Contexts', ->

    beforeEach ->
      ctx = isolate.newContext().reset()
      ctx.map 'dependency', name: 'new context dependency'
      isolate.map 'dependency', name: 'main context dependency'
      mut = moduleFactory 'basic', ctx

    it 'should resolve the dependency using the new context', ->
      (expect mut.dependency.name).to.equal 'new context dependency'

  describe 'Accessing Isolated Module Dependencies', ->
    beforeEach ->
      isolate.map 'dependency', name: 'fake dependency'
      mut = moduleFactory 'basic'

    it 'should provide access to the injected modules from the isolated module', ->
      (expect mut.dependencies).to.be.defined
      (expect mut.dependencies.find).to.be.defined
      (expect mut.dependencies.find 'dependency').to.be.defined
      (expect mut.dependencies.find('dependency').name).to.equal 'fake dependency'


  describe 'Manipulating the Isolated Module just before it is returned', ->
    completeRan = undefined
    beforeEach ->
      completeRan = false
      isolate
        .map('dependency', name: 'fake dependency')
        .isolateComplete -> completeRan = true
      mut = moduleFactory 'basic'

    it 'should execute the isolateComplete handler', ->
      (expect completeRan).to.equal true
