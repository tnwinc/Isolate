global.expect = (require 'chai').expect

path = require 'path'
requirejs = require 'requirejs'
requirejs.config
  nodeRequire: require
  baseUrl: path.join __dirname, 'modules_for_testing'
global.define = global.requirejs = requirejs

requirejs ['isolate'], (isolate)->
  isolate.useRequire(requirejs)
