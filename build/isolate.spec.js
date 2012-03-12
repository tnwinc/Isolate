(function() {
  var isolate;

  isolate = require('isolate');

  describe('Isolate', function() {
    describe('the exported object', function() {
      return it('should be an instance of Isolate', function() {
        (expect(isolate.constructor)).to.exist;
        return (expect(isolate)).to.be["instanceof"](isolate.constructor);
      });
    });
    describe('unmapped behavior', function() {});
    return describe('mapping rules', function() {
      describe('types of maps', function() {
        describe('passthru', function() {
          describe('when given a params list', function() {});
          return describe('when given an array', function() {});
        });
        describe('map', function() {
          describe('when given a single mapping rule', function() {});
          return describe('when given a hash of mapping rules', function() {});
        });
        describe('mapType', function() {
          describe('when given a single mapping rule', function() {});
          return describe('when given a hash of mapping rules', function() {});
        });
        return describe('map.asFactory', function() {
          describe('when used standalone', function() {
            describe('when given a single mapping rule', function() {});
            return describe('when given a hash of mapping rules', function() {});
          });
          describe('when used with map', function() {});
          return describe('when used with mapType', function() {});
        });
      });
      describe('order of precedence', function() {
        return describe('fall-through to mapType', function() {});
      });
      describe('mapping using RegExp instances', function() {});
      return describe('mapping using strings representing RegExp', function() {});
    });
  });

}).call(this);
