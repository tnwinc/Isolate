define ['require'], (req)->

  o = b: name: ''
  req ['spec-fixtures/async-require/b'], (b)->
    o.b.name = b.name

  return o
