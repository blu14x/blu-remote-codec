require('testing')
require('Codecs/Lua Codecs/blu/blu_control_remote_source')

local utilityTestCluster = TestCluster:new('Utility Functions', {
  TestCase:new('val', {
    TestEntry:new('val.isTypesString (single type string)', function()
      assertFalse(val.isTypesString())
      assertFalse(val.isTypesString(true))
      assertFalse(val.isTypesString(1))
      assertFalse(val.isTypesString('sauce'))
      assertFalse(val.isTypesString(function() end))
      assertFalse(val.isTypesString({ 'sauce' }))

      assertTrue(val.isTypesString(NI))
      assertTrue(val.isTypesString(B))
      assertTrue(val.isTypesString(N))
      assertTrue(val.isTypesString(S))
      assertTrue(val.isTypesString(T))
      assertTrue(val.isTypesString(F))
    end),
    TestEntry:new('val.isTypesString (type strings table)', function()
      assertFalse(val.isTypesString({}))
      assertFalse(val.isTypesString({ 'sauce' }))

      assertTrue(val.isTypesString({ NI }))
      assertTrue(val.isTypesString({ B }))
      assertTrue(val.isTypesString({ N }))
      assertTrue(val.isTypesString({ S }))
      assertTrue(val.isTypesString({ T }))
      assertTrue(val.isTypesString({ F }))
      assertTrue(val.isTypesString({ NI, B, N, S, T, F }))
    end),
    TestEntry:new('val.ofType (invalid arguments)', function()
      assertError(function() val.ofType() end, 'val.ofType - arg #1: Must be a type string, or a table of type strings')
      assertError(function() val.ofType('test') end, 'val.ofType - arg #1: Must be a type string, or a table of type strings')
      assertError(function() val.ofType(N, 1, true) end, 'val.ofType - arg #2: Must be a table if arg #3 is true')
      assertError(function() val.ofType(N, { 1, 2, 3 }, 'salami') end, 'val.ofType - arg #3: Must be a boolean (default: false)')
    end),
    TestEntry:new('val.ofType (single type string, many = false)', function()
      assertFalse(val.ofType(NI, 'test'))
      assertTrue(val.ofType(NI))

      assertFalse(val.ofType(B, 'test'))
      assertTrue(val.ofType(B, true))
      assertTrue(val.ofType(B, false))

      assertFalse(val.ofType(N, 'test'))
      assertTrue(val.ofType(N, 420))

      assertFalse(val.ofType(S, 420))
      assertTrue(val.ofType(S, 'test'))

      assertFalse(val.ofType(T, 'test'))
      assertTrue(val.ofType(T, {}))

      assertFalse(val.ofType(F, 'test'))
      assertTrue(val.ofType(F, function() end))
    end),
    TestEntry:new('val.ofType (single type string, many = true)', function()
      assertFalse(val.ofType(NI, { 'test' }, true))
      assertFalse(val.ofType(NI, { 'test', nil }, true))
      -- reminder: tables cannot store nil values, so the next line correctly asserts false
      assertFalse(val.ofType(NI, { nil, nil }, true))

      assertFalse(val.ofType(B, { 'test' }, true))
      assertFalse(val.ofType(B, { 'test', false }, true))
      assertTrue(val.ofType(B, { false, true }, true))

      assertFalse(val.ofType(N, { 'test' }, true))
      assertFalse(val.ofType(N, { 'test', 420 }, true))
      assertTrue(val.ofType(N, { 420, 69 }, true))

      assertFalse(val.ofType(S, { 420 }, true))
      assertFalse(val.ofType(S, { 420, 'test' }, true))
      assertTrue(val.ofType(S, { 'test', 'salami' }, true))

      assertFalse(val.ofType(T, { 'test' }, true))
      assertFalse(val.ofType(T, { 'test', {} }, true))
      assertTrue(val.ofType(T, { {}, { 1, 2, 3 } }, true))

      assertFalse(val.ofType(F, { 'test' }, true))
      assertFalse(val.ofType(F, { 'test', function() end }, true))
      assertTrue(val.ofType(F, { function() end, function() end }, true))
    end),
    TestEntry:new('val.ofType (type strings table)', function()
      assertFalse(val.ofType({ B }))
      assertTrue(val.ofType({ B, NI }))
      assertFalse(val.ofType({ B }, { nil }, true))
      assertFalse(val.ofType({ B, NI }, { nil }, true))
      -- reminder: tables cannot store nil values, so the next 2 lines correctly assert true
      assertTrue(val.ofType({ B }, { nil, 420 }, true))
      assertTrue(val.ofType({ B, NI }, { nil, 420 }, true))

      assertFalse(val.ofType({ B }, 420))
      assertTrue(val.ofType({ B, N }, 420))
      assertFalse(val.ofType({ B }, { 420, true }, true))
      assertTrue(val.ofType({ B, N }, { 420, true }, true))

      assertFalse(val.ofType({ B }, 'test'))
      assertFalse(val.ofType({ B, N }, 'test'))
      assertTrue(val.ofType({ B, N, S }, 'test'))

      assertFalse(val.ofType({ B }, { true, 420, 'test' }, true))
      assertFalse(val.ofType({ B, N }, { true, 420, 'test' }, true))
      assertTrue(val.ofType({ B, N, S }, { true, 420, 'test' }, true))

    end),
    TestEntry:new('val.ofChoice (invalid arguments)', function()
      assertError(function() val.ofChoice() end, 'val.ofChoice - arg #1: Must be a boolean, number, string, or a table of such')
      assertError(function() val.ofChoice({ function() end }) end, 'val.ofChoice - arg #1: Must be a boolean, number, string, or a table of such')
      assertError(function() val.ofChoice({ 'salami', 'sauce' }, 'test', 'salami') end, 'val.ofChoice - arg #3: Must be a boolean (default: false)')
      assertError(function() val.ofChoice({ 'salami', 'sauce' }, 'test', true) end, 'val.ofChoice - arg #2: Must be a table if arg #3 is true')
    end),
    TestEntry:new('val.ofChoice (many = false)', function()
      assertFalse(val.ofChoice(2, 1))
      assertTrue(val.ofChoice(2, 2))

      assertFalse(val.ofChoice({ 3, 4 }, 1))
      assertFalse(val.ofChoice({ 3, 4 }, 2))
      assertTrue(val.ofChoice({ 3, 4 }, 3))
      assertTrue(val.ofChoice({ 3, 4 }, 4))

      assertFalse(val.ofChoice({ 3, true, 'nice' }, 1))
      assertFalse(val.ofChoice({ 3, true, 'nice' }, false))
      assertFalse(val.ofChoice({ 3, true, 'nice' }, 'test'))
      assertTrue(val.ofChoice({ 3, true, 'nice' }, 3))
      assertTrue(val.ofChoice({ 3, true, 'nice' }, true))
      assertTrue(val.ofChoice({ 3, true, 'nice' }, 'nice'))
    end),
    TestEntry:new('val.ofChoice (many = true)', function()
      assertFalse(val.ofChoice({ 3, 4 }, { 1, 2 }, true))
      assertFalse(val.ofChoice({ 3, 4 }, { 2, 3 }, true))
      assertTrue(val.ofChoice({ 3, 4 }, { 3, 4 }, true))
      assertFalse(val.ofChoice({ 3, 4 }, { 1, 3, 2, 4 }, true))
      assertTrue(val.ofChoice({ 3, 4 }, { 3, 3, 4, 4, 4, 3, 4, 4 }, true))

      assertFalse(val.ofChoice({ 3, true, 'nice' }, { 6, false, 'test' }, true))
      assertTrue(val.ofChoice({ 3, true, 'nice' }, { true, 3 }, true))
      assertTrue(val.ofChoice({ 3, true, 'nice' }, { 3, 'nice' }, true))
    end)
  }),
  TestCase:new("fnc", {
    TestEntry:new('fnc.parseArgOptions', function()
      assertError(function() fnc.parseArgOptions('test') end, 'fnc.parseArgOptions - arg #1: Must be a table or nil')

      assertError(function() fnc.parseArgOptions({ required = 'yes' }) end, 'fnc.parseArgOptions - arg #1: { required } must be a boolean (default: true)')
      assertError(function() fnc.parseArgOptions({ required = true, default = 'nice' }) end, 'fnc.parseArgOptions - arg #1: { required } and { default } cannot be used together')

      assertError(function() fnc.parseArgOptions({ types = 'test' }) end, 'fnc.parseArgOptions - arg #1: { types } must be a type string, or a table of type strings (optional)')
      assertError(function() fnc.parseArgOptions({ types = { 'test' } }) end, 'fnc.parseArgOptions - arg #1: { types } must be a type string, or a table of type strings (optional)')

      assertError(function() fnc.parseArgOptions({ choices = 1 }) end, 'fnc.parseArgOptions - arg #1: { choices } must be a table of booleans, numbers or strings (optional)')
      assertError(function() fnc.parseArgOptions({ choices = {} }) end, 'fnc.parseArgOptions - arg #1: { choices } must be a table of booleans, numbers or strings (optional)')
      assertError(function() fnc.parseArgOptions({ choices = { function() end } }) end, 'fnc.parseArgOptions - arg #1: { choices } must be a table of booleans, numbers or strings (optional)')

      assertError(function() fnc.parseArgOptions({ types = { N }, choices = { 1, 2, 3 } }) end, 'fnc.parseArgOptions - arg #1: { types } and { choices } cannot be used together')
      assertError(function() fnc.parseArgOptions({ types = { N, B }, default = 'test' }) end, 'fnc.parseArgOptions - arg #1: if { types } is set, then { default }\'s type must be part of it')
      assertError(function() fnc.parseArgOptions({ choices = { 1, 2, 3 }, default = 4 }) end, 'fnc.parseArgOptions - arg #1: if { choices } is set, then { default } must be part of it')

      assertError(function() fnc.parseArgOptions({ errLevel = 'test' }) end, 'fnc.parseArgOptions - arg #1: { errLevel } must be a number > 0 (default: 3)')

      assertTableEqual({ errLevel = 3, required = true }, fnc.parseArgOptions())
      assertTableEqual({ errLevel = 3, required = false }, fnc.parseArgOptions({ required = false }))

      assertTableEqual({ errLevel = 3, required = false, default = 'test' }, fnc.parseArgOptions({ default = 'test' }))
      assertTableEqual({ errLevel = 3, required = false, default = false }, fnc.parseArgOptions({ default = false }))
      assertTableEqual({ errLevel = 3, required = false, default = true }, fnc.parseArgOptions({ default = true }))

      assertTableEqual({ errLevel = 3, required = true, types = { S } }, fnc.parseArgOptions({ types = S }))
      assertTableEqual({ errLevel = 3, required = true, types = { S, N } }, fnc.parseArgOptions({ types = { S, N } }))

      assertTableEqual({ errLevel = 3, required = true, choices = { 4 } }, fnc.parseArgOptions({ choices = { 4 } }))
      assertTableEqual({ errLevel = 3, required = true, choices = { 4, 'test' } }, fnc.parseArgOptions({ choices = { 4, 'test' } }))

      assertTableEqual({ errLevel = 3, required = false, types = { S, N }, default = 'test' }, fnc.parseArgOptions({ types = { S, N }, default = 'test' }))
      assertTableEqual({ errLevel = 3, required = false, types = { S, N }, default = 420 }, fnc.parseArgOptions({ types = { S, N }, default = 420 }))

      assertTableEqual({ errLevel = 3, required = false, choices = { 420, 'test' }, default = 'test' }, fnc.parseArgOptions({ choices = { 420, 'test' }, default = 'test' }))
      assertTableEqual({ errLevel = 3, required = false, choices = { 420, 'test' }, default = 420 }, fnc.parseArgOptions({ choices = { 420, 'test' }, default = 420 }))
    end),
    TestEntry:new('fnc.arg', function()
      assertError(function() fnc.arg(nil) end, 'NoArgumentError: Argument missing!')
      assertError(function() fnc.arg('test', { types = N }) end, 'TypeError: Expected a value of type number, but got string.')
      assertError(function() fnc.arg('test', { default = 5 }) end, 'TypeError: Expected a value of type number, but got string. (adopt default type rule)')
      assertError(function() fnc.arg(true, { types = { N, S, F } }) end, 'TypeError: Expected a value of type number/string/function, but got boolean.')
      assertError(function() fnc.arg(4, { choices = { 1, 2, 3 } }) end, 'ValueError: Expected a value of 1/2/3, but got 4.')

      assertEqual(nil, fnc.arg(nil, { required = false }))
      assertEqual('test', fnc.arg(nil, { default = 'test' }))
      assertEqual('nice', fnc.arg('nice', { default = 'test' }))
    end),
    TestEntry:new('fnc.kwarg', function()
      assertError(function() fnc.kwarg('oh no') end, 'fnc.kwarg - arg #1: table or nil expected')
      assertError(function() fnc.kwarg({}) end, 'fnc.kwarg - arg #2: string expected')
      assertError(function() fnc.kwarg({}, 'key', 420) end, 'fnc.kwarg - arg #3: table or nil expected')
      assertError(function() fnc.kwarg({}, 'someKey') end, 'NoArgumentError: Argument missing!')

      local kwargs = { someKey = 34 }
      assertEqual(34, fnc.kwarg(kwargs, 'someKey'))
      assertEqual(53, fnc.kwarg(kwargs, 'anotherKey', { default = 53 }))
      assertEqual(nil, fnc.kwarg(kwargs, 'anotherKey', { required = false }))
      assertEqual(nil, fnc.kwarg(nil, 'anotherKey', { required = false }))
    end),
    TestEntry:new('fnc.assert', function()
      assertError(function() fnc.assert(false) end, 'AssertionError: Assertion failed!')
      assertError(function() fnc.assert(false, { message = 'oh no!' }) end, 'AssertionError: oh no!')
    end)
  }),
  TestCase:new("err", {
    TestEntry:new('err.base', function()
      assertEqual('Error: Something went wrong!', err.base())
      assertEqual('Error: Big Bada Boom!', err.base('Big Bada Boom!'))
    end),
    TestEntry:new('err.type', function()
      assertEqual('TypeError: Value had unexpected type!', err.type())
    end),
    TestEntry:new('err.value', function()
      assertEqual('ValueError: Unexpected value!', err.value())
    end),
    TestEntry:new('err.argMissing', function()
      assertEqual('NoArgumentError: Argument missing!', err.argMissing())
    end),
    TestEntry:new('err.assert', function()
      assertEqual('AssertionError: Assertion failed!', err.assert())
    end),
    TestEntry:new('err.program', function()
      assertEqual('ProgrammingError: Something was programmed incorrectly!', err.program())
    end),
    TestEntry:new('err.debug', function()
      assertEqual('Debugger: Debugger hit!', err.debug())
    end)
  }),
  TestCase:new("num", {
    TestEntry:new('num.fromHex', function()
      assertEqual(0, num.fromHex('0'))
      assertEqual(7, num.fromHex('07'))
      assertEqual(10, num.fromHex('0a'))
      assertEqual(198, num.fromHex('c6'))
      assertEqual(4095, num.fromHex('fff'))
    end),
    TestEntry:new('num.toHex', function()
      assertEqual('00', num.toHex(0))
      assertEqual('07', num.toHex(7))
      assertEqual('0a', num.toHex(10))
      assertEqual('c6', num.toHex(198))
      assertEqual('fff', num.toHex(4095))
    end),
    TestEntry:new('num.round', function()
      assertEqual(1, num.round(1.2))
      assertEqual(2, num.round(1.7))

      assertEqual(1.3, num.round(1.3456, 1))
      assertEqual(1.35, num.round(1.3456, 2))
      assertEqual(1.346, num.round(1.3456, 3))
    end)
  }),
  TestCase:new("str", {
    TestEntry:new('str.crop', function()
      assertEqual('', str.crop('salami'))
      assertEqual('sal', str.crop('salami', 3))
      assertEqual('salami', str.crop('salami', 30))
    end),
    TestEntry:new('str.strip', function()
      assertEqual('salami', str.strip('salami'))
      assertEqual('salami', str.strip('    salami    '))
    end),
    TestEntry:new('str.split', function()
      assertTableEqual({ 'salami' }, str.split('salami'))
      assertTableEqual({ 'sa', 'ami' }, str.split('salami', 'l'))

      assertTableEqual({ '1', '2', '3', '4', '5', '6' }, str.split('1 2 3 4 5 6'))
      assertTableEqual({ '1', '2', '3', '4', '5', '6' }, str.split('1,2,3,4,5,6', ','))
    end)
  }),
  TestCase:new("tbl", {
    TestEntry:new('tbl.plot', function()
      assertEqual("{}", tbl.plot({}))
      assertEqual("{\n  [1] = 'a',\n  [2] = 'b',\n  [3] = 'c'\n}", tbl.plot({ 'a', 'b', 'c' }))
      assertEqual("{\n  [1] = 'a',\n  [2] = 5,\n  [3] = true\n}", tbl.plot({ 'a', 5, true }))
      assertEqual("{\n  [1] = 'a',\n  [2] = 5,\n  c = true\n}", tbl.plot({ 'a', 5, c = true }))
      assertEqual("{\n  [1] = {\n    [1] = 'nested'\n  }\n}", tbl.plot({ { 'nested' } }))
    end),
    TestEntry:new('tbl.shallowCopy', function()
      local original = { 1, 2, shallow = { 'nested' } }
      local copy     = tbl.shallowCopy(original)

      assertFalse(tostring(original) == tostring(copy))
      assertTrue(tostring(original.shallow) == tostring(copy.shallow))
    end),
    TestEntry:new('tbl.deepCopy', function()
      local original = { 1, 2, deep = { 'nested' } }
      local copy     = tbl.deepCopy(original)

      assertFalse(tostring(original) == tostring(copy))
      assertFalse(tostring(original.deep) == tostring(copy.deep))
    end)
  }),
  TestCase:new("dct", {
    TestEntry:new('dct.len', function()
      assertEqual(0, dct.len({}))
      assertEqual(3, dct.len({ a = 'a', b = 'b', c = 'c' }))
    end),
    TestEntry:new('dct.hasKey', function()
      assertTrue(dct.hasKey({ a = 3, b = 4, c = 5 }, 'a'))
      assertFalse(dct.hasKey({ a = 3, b = 4, c = 5 }, 'd'))
    end),
    TestEntry:new('dct.hasValue', function()
      assertTrue(dct.hasValue({ a = 3, b = 4, c = 5 }, 3))
      assertFalse(dct.hasValue({ a = 3, b = 4, c = 5 }, 7))
    end),
    TestEntry:new('dct.keys', function()
      -- cannot use assertTableEqual here, because the iteration order of dct.keys is not guaranteed
      local keys = dct.keys({ a = 3, b = 4, c = 5 })
      assertEqual(3, #keys)
      assertTrue(lst.hasValue(keys, 'a'))
      assertTrue(lst.hasValue(keys, 'b'))
      assertTrue(lst.hasValue(keys, 'c'))
    end),
    TestEntry:new('dct.equals', function()
      local t1 = { a = 3, b = 4, c = 5 }
      local t2 = { a = 3, b = 4, c = 5 }
      local t3 = { a = 3, b = 7, c = 5 }
      local t4 = { a = 3, b = 4 }

      assertTrue(dct.equals(t1, t2))
      assertFalse(dct.equals(t1, t3))
      assertFalse(dct.equals(t1, t4))
    end),
    TestEntry:new('dct.get', function()
      local t = { a = 3, b = 4 }
      assertEqual(3, dct.get(t, 'a'))
      assertTableEqual({ a = 3, b = 4 }, t)

      assertEqual(4, dct.get(t, 'b'))
      assertTableEqual({ a = 3, b = 4 }, t)

      assertEqual(nil, dct.get(t, 'c'))
      assertEqual(8, dct.get(t, 'c', 8))
      assertTableEqual({ a = 3, b = 4 }, t)
    end),
    TestEntry:new('dct.pop', function()
      local t = { a = 3, b = 4 }
      assertEqual(3, dct.pop(t, 'a'))
      assertTableEqual({ b = 4 }, t)

      assertEqual(4, dct.pop(t, 'b'))
      assertTableEqual({ }, t)

      assertEqual(nil, dct.pop(t, 'c'))
      assertEqual(8, dct.pop(t, 'c', 8))
      assertTableEqual({ }, t)
    end)
  }),
  TestCase:new("lst", {
    TestEntry:new('lst.len', function()
      assertEqual(0, lst.len({}))
      assertEqual(4, lst.len({ 'a', 'b', 'c', 'd' }))
    end),
    TestEntry:new('lst.hasIndex', function()
      assertFalse(lst.hasIndex({}, 1))
      assertTrue(lst.hasIndex({ 'a', 'b', 'c', 'd' }, 1))
      assertTrue(lst.hasIndex({ 'a', 'b', 'c', 'd' }, 4))
      assertFalse(lst.hasIndex({ 'a', 'b', 'c', 'd' }, 5))
    end),
    TestEntry:new('lst.hasValue', function()
      assertTrue(lst.hasValue({ 'a', 'b', 'c', 'd' }, 'c'))
      assertFalse(lst.hasValue({ 'a', 'b', 'c', 'd' }, 'e'))
    end),
    TestEntry:new('lst.reversed', function()
      assertTableEqual({}, lst.reversed({}))
      assertTableEqual({ 'd', 'c', 'b', 'a' }, lst.reversed({ 'a', 'b', 'c', 'd' }))
    end),
    TestEntry:new('lst.first', function()
      assertEqual(nil, lst.first({ }))
      assertEqual('a', lst.first({ 'a', 'b', 'c', 'd' }))
    end),
    TestEntry:new('lst.last', function()
      assertEqual(nil, lst.last({ }))
      assertEqual('d', lst.last({ 'a', 'b', 'c', 'd' }))
    end),
    TestEntry:new('lst.section', function()
      local t = { 'a', 'b', 'c', 'd', 'e' }
      assertTableEqual({ 'a', 'b', 'c', 'd', 'e' }, lst.section(t))
      assertTableEqual({ 'c', 'd', 'e' }, lst.section(t, 3))
      assertTableEqual({ 'a', 'b', 'c' }, lst.section(t, 1, 3))
      assertTableEqual({ 'b', 'c', 'd' }, lst.section(t, 2, 4))
      assertTableEqual({  }, lst.section({}, 5, 2))
    end),
    TestEntry:new('lst.indexOf', function()
      assertEqual(2, lst.indexOf({ 'a', 'b', 'c', 'd' }, 'b'))
      assertEqual(4, lst.indexOf({ 'a', 'b', 'c', 'd' }, 'd'))
      assertEqual(nil, lst.indexOf({ 'a', 'b', 'c', 'd' }, 'e'))
    end),
    TestEntry:new('lst.equals', function()
      local t1 = { 'a', 'b', 'c' }
      local t2 = { 'a', 'b', 'c' }
      local t3 = { 'a', 'f', 'c' }
      local t4 = { 'a', 'b' }
      local t5 = { 'b', 'c', 'a' }

      assertTrue(lst.equals(t1, t2))
      assertFalse(lst.equals(t1, t3))
      assertFalse(lst.equals(t1, t4))
      assertFalse(lst.equals(t1, t5))
    end),
    TestEntry:new('lst.intersect', function()
      -- cannot use assertTableEqual here, because the iteration order of dct.keys is not guaranteed
      local t1         = { 'a', 'b', 'c' }
      local t2         = { 'b', 'c', 'd' }
      local intersect1 = lst.intersect(t1, t2)
      assertEqual(2, #intersect1)
      assertTrue(lst.hasValue(intersect1, 'b'))
      assertTrue(lst.hasValue(intersect1, 'c'))
    end),
    TestEntry:new('lst.rep', function()
      assertTableEqual({}, lst.rep('a', 0))
      assertTableEqual({ 'a', 'a', 'a', 'a', 'a' }, lst.rep('a', 5))
      assertTableEqual({ 3, 3, 3 }, lst.rep(3, 3))
      assertTableEqual({ true, true, true, true }, lst.rep(true, 4))
      assertTableEqual({ { 'tbl' }, { 'tbl' }, { 'tbl' } }, lst.rep({ 'tbl' }, 3))
    end)
  }),
  TestCase:new("col", {
    TestEntry:new('col.values', function()
      assertTableEqual({ 'bar', 'baz' }, col.values({ { foo = 'bar' }, { foo = 'baz' } }, 'foo'))
      assertTableEqual({ 3, 3, 4 }, col.values({ { a = 3 }, { a = 3 }, { a = 4 } }, 'a'))
    end),
    TestEntry:new('col.find', function()
      local collection  = { { k = 3 }, { k = 4 }, { k = 5 }, { k = 5 }, { k = 6 } }

      local ct1, index1 = col.find(collection, 'k', 4)
      assertTableEqual({ { k = 4 }, 2 }, { ct1, index1 })

      local ct2, index2 = col.find(collection, 'k', 5)
      assertTableEqual({ { k = 5 }, 3 }, { ct2, index2 })

      local ct3, index3 = col.find(collection, 'k', 6)
      assertTableEqual({ { k = 6 }, 5 }, { ct3, index3 })

      local ct4, index4 = col.find(collection, 'k', 42)
      assertTableEqual({ nil, nil }, { ct4, index4 })
    end),
    TestEntry:new('col.filter', function()
      local collection = { { k = 3 }, { k = 4 }, { k = 5 }, { k = 5 }, { k = 6 } }

      assertTableEqual({ { k = 4 } }, col.filter(collection, 'k', 4))
      assertTableEqual({ { k = 5 }, { k = 5 } }, col.filter(collection, 'k', 5))
      assertTableEqual({ { k = 6 } }, col.filter(collection, 'k', 6))
      assertTableEqual({ }, col.filter(collection, 'k', 42))
    end),
    TestEntry:new('col.exclude', function()
      local collection = { { k = 3 }, { k = 4 }, { k = 5 }, { k = 5 }, { k = 6 } }

      assertTableEqual({ { k = 3 }, { k = 5 }, { k = 5 }, { k = 6 } }, col.exclude(collection, 'k', 4))
      assertTableEqual({ { k = 3 }, { k = 4 }, { k = 6 } }, col.exclude(collection, 'k', 5))
      assertTableEqual({ { k = 3 }, { k = 4 }, { k = 5 }, { k = 5 } }, col.exclude(collection, 'k', 6))
      assertTableEqual({ { k = 3 }, { k = 4 }, { k = 5 }, { k = 5 }, { k = 6 } }, col.exclude(collection, 'k', 42))
    end)
  }),
  TestCase:new("midi", {
    TestEntry:new('midi.pattern', function()
      assertError(function() midi.pattern(420, 0, 0) end, 'ValueError: Expected a value of 128/144/160/176/192/208/224, but got 420.')
      assertEqual('800000', midi.pattern(midi.ns, 0, 0))
      assertEqual('c04b7c', midi.pattern(midi.pc, 75, 124))
      assertEqual('c0750x', midi.pattern(midi.pc, '75', '0x'))
    end)
  }),
})

utilityTestCluster:run()
