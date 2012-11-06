Isolate [![Build Status](https://secure.travis-ci.org/tnwinc/Isolate.png)](http://travis-ci.org/tnwinc/Isolate)
===============

**Isolate** is a tool to allow injection of module dependencies when
doing Test Driven Javascript/Coffeescript development. It extends
requirejs and node's require to allow isolation of a module under test.

Paired with a Spy/Fake/Mock framework, this allows for a powerful TDD
environment where the code under test is properly isolated from its
dependencies.

Isolate can be used with either [requirejs](http://requirejs.org/) ([AMD](https://github.com/amdjs/amdjs-api/wiki/AMD))
or [node's require](http://nodejs.org/) ([CommonJs](http://www.commonjs.org/specs/modules/1.0/)).
It works by hijacking the loader cache in either environment
and injecting alternate stand-ins for each of the cached modules.

### Why?
When building large or complex Javascript applications, modularity and
testing is key. With these two ingredients alone, though, you quickly
reach a point where a small mistake in one module can easily lead to
large swaths of your tests failing because each module, to some degree,
relies on its dependencies to function as expected.

If you instead isolate each module in its test environment with standin
implementations of its dependencies, breaking the operation of one
module only breaks its related tests. This allows you to develop with
more confidence and track down issues faster.

### Tools that go well with Isolate
* [mocha](http://visionmedia.github.com/mocha/) as a testing framework
* [chai](http://chaijs.com/) as an expectations framework

### Examples
Since code is worth 1024 words, here is a quick overview of what using
Isolate in your code looks like.

**requirejs / AMD**

_path/to/module.under.test.coffee_

```coffeescript
define ['path/to/dependency'], (dependency)->
  # implementation
```

_path/to/depencency.coffee_

```coffeescript
define [], ->
  someMethod: -> # some logic
```

_isolate configuration_

```coffeescript
isolate.map 'path/to/dependency',
  someMethod: -> true
```

_spec file_

```coffeescript
define ['isolate!path/to/module.under.test'], (moduleUnderTest)->
  dependency = moduleUnderTest.dependencies['path/to/dependency']
  dependency.someMethod() # true
```

**node / CommonJS**

_path/to/module.under.test.coffee_

```coffeescript
dependency = require 'path/to/dependency'
# implementation
```

_path/to/depencency.coffee_

```coffeescript
exports.someMethod = -> # some logic
```

_isolate configuration_

```coffeescript
isolate.map 'path/to/dependency',
  someMethod: -> true
```

_spec file_

```coffeescript
moduleUnderTest = module.isolate 'path/to/module.under.test'
dependency = moduleUnderTest.dependencies['path/to/dependency']
dependency.someMethod() # true
```

### Installation
`npm install isolate`

If you are using requirejs in the browser, Isolate integrates via their
[Loader Plugins](http://requirejs.org/docs/api.html#plugins) API. You
should place isolate.js _"in the same directory as your app's main JS file."_

### Configuration
Isolate maps real module dependencies to fake implementations. It does
this via mapping rules that you provide in its configuration. For small
projects, you may be able to configure Isolate "just in time", right in
your spec file - though it is much more maintainable to instead
configure it during the bootstrap phase of running your specs.

For instance, if you are using [mocha](http://visionmedia.github.com/mocha/),
you could put your isolate configuration in `test/configure-isolate.js` and
add something like the following to your `test/mocha.opts` file:

```
--require test/configure-isolate.js
```

The `test/configure-isolate.coffee` file will be similar to:

```coffeescript
Isolate = require 'Isolate'
global.isolate = Isolate.isolate

Isolate
  .mapType #...
  .map #...
  .passthru #...
  .mapAsFactory #...
```

#### Configuration Options

##### useRequire

```coffeescript
Isolate.useRequire require
```
`useRequire` allows you to specify the instance of require.js require to use
when isolating AMD modules. If this is not set, Isolate will try to use the global
`require` instance by default.

##### passthru

```coffeescript
Isolate.passthru 'jquery', 'underscore', /lib\/.*/, '/libraries\/.*/' #...
```
or

```coffeescript
Isolate.passthru [ 'jquery', 'underscore', /lib\/.*/, '/libraries\/.*/' ]
```
`passthru` allows you to specify that certain modules should be allowed through
without injecting a standin. This is good for external libraries that
are assumed to be working and stable, or are too complex to
realistically build suitable standins for.

This option expects a list of _matchers_, and can be called multiple
times. A _matcher_ can be one of:

* A RegExp designed to match against the full module path
* A string staring and ending with a '/', which will be turned into a
  RegExp instance by removing the '/' from the start and end and calling
  `new RegExp()` on the resulting string
* Any other string which is injected into a RegExp instance which
  attempts to match the module name

##### map

```coffeescript
Isolate
  .map('some/module', {})
  .map('/.*_controller$/', (options)-> {})
  .map(/.*_view/, (options)-> {})
```
or

```coffeescript
Isolate
  .map
    'some/module'      : {}
    '/.*_controller$/' : (options)-> {}
    '/.*_view/'        : (options)-> {}
```
`map` allows you to provide a specific standin implementation to inject
for any given _matcher_ (See the _passthru_ section above for details
on matchers).

This option expects to be provided a matcher and either a standin
instance to inject, or a _factory_ (see `map.asFactory` below). As
syntactic sugar, you can also pass an object map of matcher: standin
pairs too (second example above)

_Note:_ Conflicts between `passthru`, `map`, and overlapping matchers of
each are resolved by choosing the last-defined matching rule.

##### mapType

```coffeescript
Isolate
  .mapType 'function', ->
  .mapType 'object', {}
```
or

```coffeescript
Isolate
  .mapType
    'function': ->
    'object'  : {}
```
`mapType` allows you to setup "catch-all" rules to construct standins
for modules which failed to match any `map` or `passthru` rules defined.

This option expects to be provided a _type_ argument,and either a
standin instance to inject, or a _factory_ (see `map.asFactory` below).
As syntactic sugar, you can also pass an object map of type: standin
paris too (second example above).

The _type_ argument is compared (case insensitive) to the output of running
`Object.prototype.toString` on the actual module implemenntation. Just the
substring containing the type is compared, so for a dependency which is
a function, `Object.prototype.toString` would return `[object Function]`
which means you should specify 'function' as the type to map.

##### isolateComplete

```coffeescript
Isolate.isolateComplete (module)->
```
`isolateComplete` allows you to perform last-minute processing of a
module before it is injected to the requesting code. The `module`
reference has the `dependencies` property already prepared.

#### Mapping to factories instead of literals

##### Usage as a rule mapper

```coffeescript
Isolate
  .mapAsFactory 'some/module',
    (actual, module_path, requesting_module_path)-> {}
  .mapAsFactory '/.*_controller$/',
    (actual, module_path, requesting_module_path)->
      (options)-> {}
  .mapAsFactory /.*_view/,
    (actual, module_path, requesting_module_path)->
      (options)-> {}
```
or

```coffeescript
Isolate
  .map
    'some/module'      : (actual, module_path, requesting_module_path)-> {}
    '/.*_controller$/' : (actual, module_path, requesting_module_path)->
                           (options)-> {}
    '/.*_view/'        : (actual, module_path, requesting_module_path)->
                           (options)-> {}
```
`mapAsFactory` allows you to provide a dynamically generated standin implementation
to inject with the possibility to customize the standin to the requested
module details. `mapAsFactory` follows the same _matcher_ rules described in the
_passthru_ section above.

This option expects to be provided a matcher and a function which
generates the standin to inject. The function is provided 3 parameters

* `actual` The real module instance which is being "faked" out.
* `requested_module_path` The full module path to the module being
  "faked" out.
* `requesting_module_path` The full module path to the module being
  isolated.

As syntactic sugar, you can also pass an object map of matcher: standin
pairs too (second example above)

_Note:_ Conflicts between `passthru`, `map`, and overlapping matchers of
each are resolved by choosing the last-defined matching rule.

##### Usage as a modifier to `map` and `mapType`

```coffeescript
Isolate
  .map /.*_controller/, Isolate.mapAsFactory (actual_module, module_path, requesting_module_path)->
    toString: -> "[Fake for #{module_path}]"
  .mapType 'function', Isolate.mapAsFactory (actual_module, module_path, requesting_module_path)->
    fake_function = ->
    fake_function.toString = -> "[Fake Function for #{module_path}]"
    return fake_function
```

`map.asFactory` can also be used to provide a factory function to `map` and
`mapType`. The factory function will be evaluated when resolving the
dependency. The parameters passed to the factory function are the same
as described in the _Usage as a rule mapper_.

_Note_: `mapAsFactory` is very helpful when you want to inject a standin for
adding some surface area to a module for specs (like wrapping functions
in spies), but you still want to check that the integration between the
modules hasn't been broken.

### Using Isolate in tests

**requirejs / AMD**

**node / CommonJS**
