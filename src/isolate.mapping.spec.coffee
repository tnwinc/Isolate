isolate_instance = require 'isolate'

# boilerplate to configure context
configure = (configurator)->
  isolate_instance.reset()
  configurator? isolate_instance

describe 'Isolate', ->
  beforeEach ->
    configure()

  describe 'the exported object', ->
    it 'should be an instance of Isolate', ->
      (expect module.isolate.constructor).to.exist
      (expect module.isolate).to.be.instanceof module.isolate.constructor

  describe 'mapping rules', ->
    describe 'types of maps', ->
      describe 'passthru', ->
        describe 'when given a params list', ->
          beforeEach ->
            configure (ctx)->
              ctx.passthru 'b', 'c'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'
          it 'should provid the real implementations for each module', ->
            (expect @a.myB.name).to.equal 'the-real-b'
            (expect @a.myC.name).to.equal 'the-real-c'

        describe 'when given an array', ->
          beforeEach ->
            configure (ctx)->
              ctx.passthru  ['b', 'c']
          it 'should provid the real implementations for each module', ->
            (expect @a.myB.name).to.equal 'the-real-b'
            (expect @a.myC.name).to.equal 'the-real-c'

      describe 'map', ->
        describe 'when given a single mapping rule', ->
          beforeEach ->
            configure (ctx)->
              ctx.map 'b', name: 'the-fake-b'
              ctx.map 'c', name: 'the-fake-c'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-fake-b'
            (expect @a.myC.name).to.equal 'the-fake-c'


        describe 'when given a hash of mapping rules', ->
          beforeEach ->
            configure (ctx)->
              ctx.map
                'b': name: 'the-fake-b'
                'c': name: 'the-fake-c'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-fake-b'
            (expect @a.myC.name).to.equal 'the-fake-c'

      describe 'mapType', ->
        describe 'when given a single mapping rule', ->
          beforeEach ->
            configure (ctx)->
              ctx.mapType 'object', name: 'the-fake-object'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-fake-object'
            (expect @a.myC.name).to.equal 'the-fake-object'

        describe 'when given a hash of mapping rules', ->
          beforeEach ->
            configure (ctx)->
              ctx.mapType
                'function': (->)
                'object'  : name: 'the-fake-object'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-fake-object'
            (expect @a.myC.name).to.equal 'the-fake-object'

      describe 'mapAsFactory', ->
        describe 'when used standalone', ->
          describe 'when given a single mapping rule', ->
            beforeEach ->
              configure (ctx)->
                ctx.mapAsFactory 'b', -> name: 'the-generated-fake-b'
                ctx.mapAsFactory 'c', -> name: 'the-generated-fake-c'
              @a = module.isolate 'spec-fixtures/mapping-rules/a'

            it 'should provide the fake implementations to the isolated module', ->
              (expect @a.myB.name).to.equal 'the-generated-fake-b'
              (expect @a.myC.name).to.equal 'the-generated-fake-c'

          describe 'when given a hash of mapping rules', ->
            beforeEach ->
              configure (ctx)->
                ctx.mapAsFactory
                  'b': -> name: 'the-generated-fake-b'
                  'c': -> name: 'the-generated-fake-c'
              @a = module.isolate 'spec-fixtures/mapping-rules/a'

            it 'should provide the fake implementations to the isolated module', ->
              (expect @a.myB.name).to.equal 'the-generated-fake-b'
              (expect @a.myC.name).to.equal 'the-generated-fake-c'

        describe 'when used with map', ->
          beforeEach ->
            configure (ctx)->
              ctx.map
                'b': ctx.mapAsFactory -> name: 'the-factory-fake-b'
                'c': ctx.mapAsFactory -> name: 'the-factory-fake-c'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-factory-fake-b'
            (expect @a.myC.name).to.equal 'the-factory-fake-c'

        describe 'when used with mapType', ->
          beforeEach ->
            configure (ctx)->
              ctx.mapType 'object', ctx.mapAsFactory -> name: 'the-factory-fake-object'
            @a = module.isolate 'spec-fixtures/mapping-rules/a'

          it 'should provide the fake implementations to the isolated module', ->
            (expect @a.myB.name).to.equal 'the-factory-fake-object'
            (expect @a.myC.name).to.equal 'the-factory-fake-object'

    describe 'order of precedence', ->

      beforeEach ->
        configure (ctx)->
          ctx.mapType 'object', name: 'the-fake-object'
          ctx.map 'b', name: 'the-fake-b'
          ctx.map 'b', name: 'the-second-fake-b'
        @a = module.isolate 'spec-fixtures/mapping-rules/a'

      it 'should fall-through to mapType', ->
        (expect @a.myC.name).to.equal 'the-fake-object'
      it 'should select last matching rule defined', ->
        (expect @a.myB.name).to.equal 'the-second-fake-b'

    describe 'mapping using RegExp instances', ->
      beforeEach ->
        configure (ctx)->
          ctx.map /.*/, name: 'some-fake'
        @a = module.isolate 'spec-fixtures/mapping-rules/a'

      it 'should return the expected fake', ->
        (expect @a.myB.name).to.equal 'some-fake'

    describe 'mapping using strings representing RegExp', ->
      beforeEach ->
        configure (ctx)->
          ctx.map '/.*/', name: 'some-fake'
        @a = module.isolate 'spec-fixtures/mapping-rules/a'

      it 'should return the expected fake', ->
        (expect @a.myB.name).to.equal 'some-fake'
