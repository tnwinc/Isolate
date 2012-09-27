moduleFactory = undefined
mut = undefined

exports.isolateModulesLikeThis = (mf)->
  moduleFactory = mf
  return exports

exports.ensure_all_behaviours = (isolate)->
  throw Error 'Must call `isolateModulesLikeThis` first.' unless moduleFactory?

  describe 'Isolate Configuration', ->
    describe 'mapping rules', ->
      describe 'types of maps', ->
        describe 'passthru', ->
          describe 'when given a params list', ->
            beforeEach ->
              isolate.passthru 'dependency'
              mut = moduleFactory 'basic'
            it 'should provide the real implementations for the dependency module', ->
              (expect mut.dependency.name).to.equal 'real dependency'

          describe 'when given an array', ->
            beforeEach ->
              isolate.passthru ['dependency']
            it 'should provide the real implementations for each module', ->
              (expect mut.dependency.name).to.equal 'real dependency'

        describe 'map', ->
          describe 'when given a single mapping rule', ->
            beforeEach ->
              isolate.map 'dependency', name: 'fake dependency'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
              (expect mut.dependency.name).to.equal 'fake dependency'


          describe 'when given a hash of mapping rules', ->
            beforeEach ->
              isolate.map
                'dependency':
                  name: 'fake dependency'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
              (expect mut.dependency.name).to.equal 'fake dependency'


        describe 'mapType', ->
          describe 'when given a single mapping rule', ->
            beforeEach ->
              isolate.mapType 'object', name: 'fake type dep'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
              (expect mut.dependency.name).to.equal 'fake type dep'

          describe 'when given a hash of mapping rules', ->
            beforeEach ->
              isolate.mapType
                'object':
                  name: 'fake type dep'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
              (expect mut.dependency.name).to.equal 'fake type dep'





        describe 'mapAsFactory', ->
          describe 'when used standalone', ->
            describe 'when given a single mapping rule', ->
              beforeEach ->
                isolate.mapAsFactory 'dependency', -> name: 'factory fake'
                mut = moduleFactory 'basic'

              it 'should provide the fake implementations to the isolated module', ->
                (expect mut.dependency.name).to.equal 'factory fake'

            describe 'when given a hash of mapping rules', ->
              beforeEach ->
                isolate.mapAsFactory
                  'dependency': -> name: 'factory fake'
                mut = moduleFactory 'basic'

              it 'should provide the fake implementations to the isolated module', ->
                (expect mut.dependency.name).to.equal 'factory fake'

          describe 'when used with map', ->
            beforeEach ->
              isolate.map
                'dependency': isolate.mapAsFactory -> name: 'factory fake thru map'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
              (expect mut.dependency.name).to.equal 'factory fake thru map'

          describe 'when used with mapType', ->
            beforeEach ->
              isolate.mapType
                'object': isolate.mapAsFactory -> name: 'factory fake thru mapType'
              mut = moduleFactory 'basic'

            it 'should provide the fake implementations to the isolated module', ->
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
        beforeEach ->
          isolate.map /.*/, name: 'some-fake'
          mut = moduleFactory 'basic'

        it 'should return the expected fake', ->
          (expect mut.dependency.name).to.equal 'some-fake'

      describe 'mapping using strings representing RegExp', ->
        beforeEach ->
          isolate.map '/.*/', name: 'some-fake'
          mut = moduleFactory 'basic'

        it 'should return the expected fake', ->
          (expect mut.dependency.name).to.equal 'some-fake'




  describe 'Creating New Isolation Contexts', ->

  describe 'Accessing Isolated Module Dependencies', ->

  describe 'Manipulating the Isolated Module just before it is returned', ->
