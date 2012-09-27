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

  describe 'Creating New Isolation Contexts', ->

  describe 'Accessing Isolated Module Dependencies', ->

  describe 'Manipulating the Isolated Module just before it is returned', ->
