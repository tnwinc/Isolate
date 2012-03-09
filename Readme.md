Isolate Js
===============

**Isolate.js** is a tool to allow injection of module dependencies when
doing Test Driven Javascript/Coffeescript development.

Paired with a Spy/Fake/Mock framework, this allows for a powerful TDD
environment where the code under test is properly isolated from its
dependencies.

Isolate.js can be used with either [requirejs](http://requirejs.org/) ([AMD](https://github.com/amdjs/amdjs-api/wiki/AMD))
or [node's require](http://nodejs.org/) ([CommonJs](http://www.commonjs.org/specs/modules/1.0/)).
It works by hijacking the loader cache in either environment
and injecting alternate stand-ins for each of the cached modules.

### Tools that go well with IsolateJs
* [mocha](http://visionmedia.github.com/mocha/) as a testing framework
* [chai](http://chaijs.com/) as an expectations framework
* [spy]() for spies/fakes/mocks/stubs

### Examples
Since code is worth 1024 words, here is a quick overview of what using
IsolateJs in your code looks like.

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

`npm install isolate` or go to [downloads]()

If you are using requirejs in the browser, Isolate integrates via their
[Loader Plugins](http://requirejs.org/docs/api.html#plugins) API. You
should place isolate.js _"in the same directory as your app's main JS file."_

### Configuration

#### Mapping Functions
**passthru**
**map**
**mapType**

#### Mapping to literals vs factories
**map.asFactory**

### Getting Started

**requirejs / AMD**

**node / CommonJS**

#### Accessing Fakes from Tests
