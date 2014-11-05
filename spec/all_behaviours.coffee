
forEachVariation = (variations, fn)->
  fn(type, matcher) for own type, matcher of variations

exports.ensure_all_behaviours = (isolate, moduleFactory)->
  throw Error 'Must provide a moduleFactory.' unless moduleFactory?

  describe 'Isolate Configuration', ->
    describe 'mapping rules', ->
      describe 'types of maps', ->


        describe 'passthru', ->
          describe 'when given a params list', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the real implementations for the dependency module', (done)->
                  isolate.passthru matcher
                  moduleFactory 'basic', (mut)->
                    (expect mut.dependency.name).to.equal 'real dependency'
                    done()

          describe 'when given an array', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the real implementations for each module', (done)->
                  isolate.passthru [matcher]
                  moduleFactory 'basic', (mut)->
                    (expect mut.dependency.name).to.equal 'real dependency'
                    done()



        describe 'map', ->
          describe 'when given a single mapping rule', ->
            forEachVariation string: 'dependency', regex: /dep.*/, regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the fake implementations to the isolated module', (done)->
                  isolate.map matcher, name: 'fake dependency'
                  moduleFactory 'basic', (mut)->
                    (expect mut.dependency.name).to.equal 'fake dependency'
                    done()

          describe 'when given a hash of mapping rules', ->
            forEachVariation string: 'dependency', regexInString: '/dep.*/', (type, matcher)->
              describe "specifying the matcher as a #{type}", ->
                it 'should provide the fake implementations to the isolated module', (done)->
                  settings = {}
                  settings[matcher] = name: 'fake dependency'
                  isolate.map settings
                  moduleFactory 'basic', (mut)->
                    (expect mut.dependency.name).to.equal 'fake dependency'
                    done()





        describe 'mapType', ->
          describe 'when given a single mapping rule', ->
            it 'should provide the fake implementations to the isolated module', (done)->
              isolate.mapType 'object', name: 'fake type dep'
              moduleFactory 'basic', (mut)->
                (expect mut.dependency.name).to.equal 'fake type dep'
                done()

          describe 'when given a hash of mapping rules', ->
            it 'should provide the fake implementations to the isolated module', (done)->
              isolate.mapType
                'object':
                  name: 'fake type dep'
              moduleFactory 'basic', (mut)->
                (expect mut.dependency.name).to.equal 'fake type dep'
                done()





        describe 'mapAsFactory', ->
          describe 'when used standalone', ->
            describe 'when given a single mapping rule', ->
              it 'should provide the fake implementations to the isolated module', (done)->
                isolate.mapAsFactory 'dependency', -> name: 'factory fake'
                moduleFactory 'basic', (mut)->
                  (expect mut.dependency.name).to.equal 'factory fake'
                  done()

              it 'should execute the factory bound to the isolation context', (done)->
                ctx = isolate.newContext('tmp').reset()
                ctx.map 'dependency': isolate.mapAsFactory -> contextName: @name
                moduleFactory ctx, 'basic', (mut)->
                  (expect mut.dependency.contextName).to.equal 'tmp'
                  done()

            describe 'when given a hash of mapping rules', ->
              it 'should provide the fake implementations to the isolated module', (done)->
                isolate.mapAsFactory
                  'dependency': -> name: 'factory fake'
                moduleFactory 'basic', (mut)->
                  (expect mut.dependency.name).to.equal 'factory fake'
                  done()

          describe 'when used with map', ->
            it 'should provide the fake implementations to the isolated module', (done)->
              isolate.map
                'dependency': isolate.mapAsFactory -> name: 'factory fake thru map'
              moduleFactory 'basic', (mut)->
                (expect mut.dependency.name).to.equal 'factory fake thru map'
                done()

          describe 'when used with mapType', ->
            it 'should provide the fake implementations to the isolated module', (done)->
              isolate.mapType
                'object': isolate.mapAsFactory -> name: 'factory fake thru mapType'
              moduleFactory 'basic', (mut)->
                (expect mut.dependency.name).to.equal 'factory fake thru mapType'
                done()




        describe 'order of precedence', ->

          mut = undefined
          beforeEach (done)->
            isolate.mapType 'object', name: 'the-fake-object'
            isolate.map 'dependency', name: 'the-fake-dep'
            isolate.map 'dependency', name: 'the-second-fake-dep'
            moduleFactory 'basic', (m)->
              mut = m
              done()

          it 'should select last matching rule defined', ->
            (expect mut.dependency.name).to.equal 'the-second-fake-dep'





      describe 'mapping using RegExp instances', ->
        it 'should return the expected fake', (done)->
          isolate.map /.*/, name: 'some-fake'
          moduleFactory 'basic', (mut)->
            (expect mut.dependency.name).to.equal 'some-fake'
            done()

      describe 'mapping using strings representing RegExp', ->
        it 'should return the expected fake', (done)->
          isolate.map '/.*/', name: 'some-fake'
          moduleFactory 'basic', (mut)->
            (expect mut.dependency.name).to.equal 'some-fake'
            done()




  describe 'Creating New Isolation Contexts', ->

    mut = undefined
    beforeEach (done)->
      ctx = isolate.newContext().reset()
      ctx.map 'dependency', name: 'new context dependency'
      isolate.map 'dependency', name: 'main context dependency'
      moduleFactory ctx, 'basic', (m)->
        mut = m
        done()

    it 'should resolve the dependency using the new context', ->
      (expect mut.dependency.name).to.equal 'new context dependency'

  describe 'Accessing Isolated Module Dependencies', ->
    mut = undefined
    beforeEach (done)->
      isolate.map 'dependency', name: 'fake dependency'
      moduleFactory 'basic', (m)->
        mut = m
        done()

    it 'should provide access to the injected modules from the isolated module', ->
      (expect mut.dependencies).to.be.defined
      (expect mut.dependencies.find).to.be.defined
      (expect mut.dependencies.find 'dependency').to.be.defined
      (expect mut.dependencies.find('dependency').name).to.equal 'fake dependency'


  describe 'Manipulating the Isolated Module just before it is returned', ->
    completeRan = undefined
    beforeEach (done)->
      completeRan = false
      isolate
        .map('dependency', name: 'fake dependency')
        .isolateComplete -> completeRan = true
      moduleFactory 'basic', (m)->
        mut = m
        done()

    it 'should execute the isolateComplete handler', ->
      (expect completeRan).to.equal true
