Isolate
===============

**Isolate** is a tool to allow injection of module dependencies when
doing Test Driven Javascript/Coffeescript development. It extends
requirejs and node's require to act more like IoC containers than simple
module loaders.

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
* [spy]() for spies/fakes/mocks/stubs

### Examples
Since code is worth 1024 words, here is a quick overview of what using
Isolate in your code looks like.

**requirejs / AMD**

_path/to/module.under.test.coffee_

```coffeescript
define ['path/to/dependency'], (dependency)->
  # implementation
```

_isolate configuration_

```coffeescript
isolate.configure require, (ctx)->
  ctx.map 'path/to/dependency', someMethod: -> true
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

_isolate configuration_

```coffeescript
isolate.configure require, (ctx)->
  ctx.map 'path/to/dependency', someMethod: -> true
```

_spec file_

```coffeescript
moduleUnderTest = isolate 'path/to/module.under.test'
dependency = moduleUnderTest.dependencies['path/to/dependency']
dependency.someMethod() # true
```

### Installation

`npm install isolate` or grab the lastest from [downloads]()

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

Isolate.configure require, (ctx)->
  ctx.mapType #...
  ctx.map #...
  ctx.passthru #...
```

#### Mapping Options

```coffeescript
Isolate.configure require, (ctx)->
  ctx.passthru 'jquery', 'underscore', /lib\/.*/, '/libraries\/.*/' #...
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
  new RegExp on the resulting string
* Any other string which must match the full module path exactly

```coffeescript
Isolate.configure require, (ctx)->
  ctx.map 'some/module', {}
  ctx.map '/.*_controller$/', (options)-> #...
  ctx.map /.*_view/, (options)-> #...
```
or
```coffeescript
Isolate.configure require, (ctx)->
  ctx.map
    'some/module'      : {}
    '/.*_controller$/' : (options)-> #...
    '/.*_view/'        : (options)-> #...
```
`map` allows you to provide a specific standin implmentation to inject
for any given _matcher_ (See the _passthru_ section above for details
on matchers).

This option expects to be provided a matcher and either a standin
instance to inject, or a _factory_ (see `map.asFactory` below). As
syntactic sugar, you can also pass an object map of matcher: standin
pairs too (second example above)

_Note:_ Conflicts between `passthru`, `map`, and overlapping matchers of
each are resolved by choosing the last-defined matching rule.

```coffeescript
Isolate.configure require, (ctx)->
  ctx.mapType 'function', ->
  ctx.mapType 'object', {}
```
or
```coffeescript
Isolate.configure require, (ctx)->
  ctx.mapType
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
`Object.prototype.toString` on the actual module implmentation. Just the
substring containing the type is compared, so for a dependency which is
a function, `Object.prototype.toString` would return `[object Function]`
which means you should specify 'function' as the type to map.

#### Mapping to literals vs factories
**map.asFactory**

### Getting Started

**requirejs / AMD**

**node / CommonJS**

#### Accessing Fakes from Tests
