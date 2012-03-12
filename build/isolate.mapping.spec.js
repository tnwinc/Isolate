(function() {
  var configure, isolate_instance;

  isolate_instance = require('isolate');

  configure = function(configurator) {
    return isolate_instance.configure(function(ctx) {
      ctx.reset();
      return typeof configurator === "function" ? configurator(ctx) : void 0;
    });
  };

  describe('Isolate', function() {
    beforeEach(function() {
      return configure();
    });
    describe('the exported object', function() {
      return it('should be an instance of Isolate', function() {
        (expect(module.isolate.constructor)).to.exist;
        return (expect(module.isolate)).to.be["instanceof"](module.isolate.constructor);
      });
    });
    return describe('mapping rules', function() {
      describe('types of maps', function() {
        describe('passthru', function() {
          describe('when given a params list', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.passthru('b', 'c');
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provid the real implementations for each module', function() {
              (expect(this.a.myB.name)).to.equal('the-real-b');
              return (expect(this.a.myC.name)).to.equal('the-real-c');
            });
          });
          return describe('when given an array', function() {
            beforeEach(function() {
              return configure(function(ctx) {
                return ctx.passthru(['b', 'c']);
              });
            });
            return it('should provid the real implementations for each module', function() {
              (expect(this.a.myB.name)).to.equal('the-real-b');
              return (expect(this.a.myC.name)).to.equal('the-real-c');
            });
          });
        });
        describe('map', function() {
          describe('when given a single mapping rule', function() {
            beforeEach(function() {
              configure(function(ctx) {
                ctx.map('b', {
                  name: 'the-fake-b'
                });
                return ctx.map('c', {
                  name: 'the-fake-c'
                });
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-fake-b');
              return (expect(this.a.myC.name)).to.equal('the-fake-c');
            });
          });
          return describe('when given a hash of mapping rules', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.map({
                  'b': {
                    name: 'the-fake-b'
                  },
                  'c': {
                    name: 'the-fake-c'
                  }
                });
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-fake-b');
              return (expect(this.a.myC.name)).to.equal('the-fake-c');
            });
          });
        });
        describe('mapType', function() {
          describe('when given a single mapping rule', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.mapType('object', {
                  name: 'the-fake-object'
                });
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-fake-object');
              return (expect(this.a.myC.name)).to.equal('the-fake-object');
            });
          });
          return describe('when given a hash of mapping rules', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.mapType({
                  'function': (function() {}),
                  'object': {
                    name: 'the-fake-object'
                  }
                });
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-fake-object');
              return (expect(this.a.myC.name)).to.equal('the-fake-object');
            });
          });
        });
        return describe('map.asFactory', function() {
          describe('when used standalone', function() {
            describe('when given a single mapping rule', function() {
              beforeEach(function() {
                configure(function(ctx) {
                  ctx.map.asFactory('b', function() {
                    return {
                      name: 'the-generated-fake-b'
                    };
                  });
                  return ctx.map.asFactory('c', function() {
                    return {
                      name: 'the-generated-fake-c'
                    };
                  });
                });
                return this.a = module.isolate('spec-fixtures/mapping-rules/a');
              });
              return it('should provide the fake implementations to the isolated module', function() {
                (expect(this.a.myB.name)).to.equal('the-generated-fake-b');
                return (expect(this.a.myC.name)).to.equal('the-generated-fake-c');
              });
            });
            return describe('when given a hash of mapping rules', function() {
              beforeEach(function() {
                configure(function(ctx) {
                  return ctx.map.asFactory({
                    'b': function() {
                      return {
                        name: 'the-generated-fake-b'
                      };
                    },
                    'c': function() {
                      return {
                        name: 'the-generated-fake-c'
                      };
                    }
                  });
                });
                return this.a = module.isolate('spec-fixtures/mapping-rules/a');
              });
              return it('should provide the fake implementations to the isolated module', function() {
                (expect(this.a.myB.name)).to.equal('the-generated-fake-b');
                return (expect(this.a.myC.name)).to.equal('the-generated-fake-c');
              });
            });
          });
          describe('when used with map', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.map({
                  'b': ctx.map.asFactory(function() {
                    return {
                      name: 'the-factory-fake-b'
                    };
                  }),
                  'c': ctx.map.asFactory(function() {
                    return {
                      name: 'the-factory-fake-c'
                    };
                  })
                });
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-factory-fake-b');
              return (expect(this.a.myC.name)).to.equal('the-factory-fake-c');
            });
          });
          return describe('when used with mapType', function() {
            beforeEach(function() {
              configure(function(ctx) {
                return ctx.mapType('object', ctx.map.asFactory(function() {
                  return {
                    name: 'the-factory-fake-object'
                  };
                }));
              });
              return this.a = module.isolate('spec-fixtures/mapping-rules/a');
            });
            return it('should provide the fake implementations to the isolated module', function() {
              (expect(this.a.myB.name)).to.equal('the-factory-fake-object');
              return (expect(this.a.myC.name)).to.equal('the-factory-fake-object');
            });
          });
        });
      });
      describe('order of precedence', function() {
        beforeEach(function() {
          configure(function(ctx) {
            ctx.mapType('object', {
              name: 'the-fake-object'
            });
            ctx.map('b', {
              name: 'the-fake-b'
            });
            return ctx.map('b', {
              name: 'the-second-fake-b'
            });
          });
          return this.a = module.isolate('spec-fixtures/mapping-rules/a');
        });
        it('should fall-through to mapType', function() {
          return (expect(this.a.myC.name)).to.equal('the-fake-object');
        });
        return it('should select last matching rule defined', function() {
          return (expect(this.a.myB.name)).to.equal('the-second-fake-b');
        });
      });
      describe('mapping using RegExp instances', function() {
        beforeEach(function() {
          configure(function(ctx) {
            return ctx.map(/.*/, {
              name: 'some-fake'
            });
          });
          return this.a = module.isolate('spec-fixtures/mapping-rules/a');
        });
        return it('should return the expected fake', function() {
          return (expect(this.a.myB.name)).to.equal('some-fake');
        });
      });
      return describe('mapping using strings representing RegExp', function() {
        beforeEach(function() {
          configure(function(ctx) {
            return ctx.map('/.*/', {
              name: 'some-fake'
            });
          });
          return this.a = module.isolate('spec-fixtures/mapping-rules/a');
        });
        return it('should return the expected fake', function() {
          return (expect(this.a.myB.name)).to.equal('some-fake');
        });
      });
    });
  });

}).call(this);
