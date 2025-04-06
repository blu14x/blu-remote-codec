do
  -- class
  do
    initClass = function()
      local middleclass = {
        _VERSION     = 'middleclass v4.1.1',
        _DESCRIPTION = 'Object Orientation for Lua',
        _URL         = 'https://github.com/kikito/middleclass',
        _LICENSE     = 'MIT LICENSE (c) 2011 Enrique García Cota'
      }

      local function _createIndexWrapper(aClass, f)
        if f == nil then
          return aClass.__instanceDict
        elseif type(f) == "function" then
          return function(self, name)
            local value = aClass.__instanceDict[name]

            if value ~= nil then
              return value
            else
              return (f(self, name))
            end
          end
        else
          -- if  type(f) == "table" then
          return function(self, name)
            local value = aClass.__instanceDict[name]

            if value ~= nil then
              return value
            else
              return f[name]
            end
          end
        end
      end

      local function _propagateInstanceMethod(aClass, name, f)
        f                           = name == "__index" and _createIndexWrapper(aClass, f) or f
        aClass.__instanceDict[name] = f

        for subclass in pairs(aClass.subclasses) do
          if rawget(subclass.__declaredMethods, name) == nil then
            _propagateInstanceMethod(subclass, name, f)
          end
        end
      end

      local function _declareInstanceMethod(aClass, name, f)
        aClass.__declaredMethods[name] = f

        if f == nil and aClass.super then
          f = aClass.super.__instanceDict[name]
        end

        _propagateInstanceMethod(aClass, name, f)
      end

      local function _tostring(self) return "class " .. self.name end
      local function _call(self, ...) return self:new(...) end

      local function _createClass(name, super)
        local dict   = {}
        dict.__index = dict

        local aClass = { name           = name, super = super, static = {},
                         __instanceDict = dict, __declaredMethods = {},
                         subclasses     = setmetatable({}, { __mode = 'k' }) }

        if super then
          setmetatable(aClass.static, {
            __index = function(_, k)
              local result = rawget(dict, k)
              if result == nil then
                return super.static[k]
              end
              return result
            end
          })
        else
          setmetatable(aClass.static, { __index = function(_, k) return rawget(dict, k) end })
        end

        setmetatable(aClass, { __index = aClass.static, __tostring = _tostring,
                               __call  = _call, __newindex = _declareInstanceMethod })

        return aClass
      end

      local function _includeMixin(aClass, mixin)
        assert(type(mixin) == 'table', "mixin must be a table")

        for name, method in pairs(mixin) do
          if name ~= "included" and name ~= "static" then aClass[name] = method end
        end

        for name, method in pairs(mixin.static or {}) do
          aClass.static[name] = method
        end

        if type(mixin.included) == "function" then mixin:included(aClass) end
        return aClass
      end

      local DefaultMixin = {
        __tostring   = function(self) return "instance of " .. tostring(self.class) end,

        initialize   = function(self, ...) end,

        isInstanceOf = function(self, aClass)
          return type(aClass) == 'table'
            and type(self) == 'table'
            and (self.class == aClass
            or type(self.class) == 'table'
            and type(self.class.isSubclassOf) == 'function'
            and self.class:isSubclassOf(aClass))
        end,

        static       = {
          allocate     = function(self)
            assert(type(self) == 'table', "Make sure that you are using 'Class:allocate' instead of 'Class.allocate'")
            return setmetatable({ class = self }, self.__instanceDict)
          end,

          new          = function(self, ...)
            assert(type(self) == 'table', "Make sure that you are using 'Class:new' instead of 'Class.new'")
            local instance = self:allocate()
            instance:initialize(...)
            return instance
          end,

          subclass     = function(self, name)
            assert(type(self) == 'table', "Make sure that you are using 'Class:subclass' instead of 'Class.subclass'")
            assert(type(name) == "string", "You must provide a name(string) for your class")

            local subclass = _createClass(name, self)

            for methodName, f in pairs(self.__instanceDict) do
              if not (methodName == "__index" and type(f) == "table") then
                _propagateInstanceMethod(subclass, methodName, f)
              end
            end
            subclass.initialize       = function(instance, ...) return self.initialize(instance, ...) end

            self.subclasses[subclass] = true
            self:subclassed(subclass)

            return subclass
          end,

          subclassed   = function(self, other) end,

          isSubclassOf = function(self, other)
            return type(other) == 'table' and
              type(self.super) == 'table' and
              (self.super == other or self.super:isSubclassOf(other))
          end,

          include      = function(self, ...)
            assert(type(self) == 'table', "Make sure you that you are using 'Class:include' instead of 'Class.include'")
            for _, mixin in ipairs({ ... }) do _includeMixin(self, mixin) end
            return self
          end
        }
      }

      function middleclass.class(name, super)
        assert(type(name) == 'string', "A name (string) is needed for the new class")
        return super and super:subclass(name) or _includeMixin(_createClass(name), DefaultMixin)
      end

      setmetatable(middleclass, { __call = function(_, ...) return middleclass.class(...) end })

      return middleclass
    end
    class     = initClass()
  end

  -- init environment
  do
    unpack              = unpack or table.unpack
    isRemoteEnvironment = remote ~= nil

    remoteDebug         = {
      define_items        = function(items)
        pprint(col.values(fnc.arg(items, { types = T }), 'name'), 'Defined Items')
      end,
      define_auto_inputs  = function(inputs)
        pprint(col.values(fnc.arg(inputs, { types = T }), 'name'), 'Defined Auto Inputs')
      end,
      define_auto_outputs = function(outputs)
        pprint(col.values(fnc.arg(outputs, { types = T }), 'name'), 'Defined Auto Outputs')
      end,
      is_item_enabled     = function(item_index)
        return true
      end,
      get_item_text_value = function(item_index)
        return 'item text value'
      end,
      get_time_ms         = function()
        return 0
      end
    }
    remote              = remote or remoteDebug
  end

  -- utility
  do
    -- type strings
    NI       = 'nil'
    B        = 'boolean'
    N        = 'number'
    S        = 'string'
    T        = 'table'
    F        = 'function'
    TH       = 'thread'

    val      = {
      _validTypesMap = {
        [NI] = true,
        [B]  = true,
        [N]  = true,
        [S]  = true,
        [T]  = true,
        [F]  = true,
        [TH] = true,
      },
      -- handling and validation of types
      isTypesString  = function(types)
        if type(types) == S then
          return val._validTypesMap[types] or false
        elseif type(types) == T then
          if #types == 0 then return false end
          for _, t in ipairs(types) do
            if not val._validTypesMap[t] then return false end
          end
          return true
        end
        return false
      end,
      ofType         = function(types, value, many)
        if type(types) ~= T then types = { types } end
        assert(val.isTypesString(types), 'val.ofType - arg #1: Must be a type string, or a table of type strings')
        assert(type(many) == NI or type(many) == B, 'val.ofType - arg #3: Must be a boolean (default: false)')

        if type(many) == NI then many = false end
        if many then assert(type(value) == T, 'val.ofType - arg #2: Must be a table if arg #3 is true') end

        -- case: value = nil and many = false
        if not many and value == nil then
          for _, t in ipairs(types) do
            if t == NI then return true end
          end
          return false
        end

        if not many then value = { value } end
        if #value == 0 then return false end

        for _, v in ipairs(value) do
          local currentValueIsOfType = false
          for _, t in ipairs(types) do
            if type(v) == t then
              currentValueIsOfType = true
              break
            end
          end
          if not currentValueIsOfType then return false end
        end
        return true
      end,
      ofChoice       = function(choices, value, many)
        if type(choices) ~= T then choices = { choices } end
        assert(val.ofType({ B, N, S }, choices, true), 'val.ofChoice - arg #1: Must be a boolean, number, string, or a table of such')
        assert(type(many) == NI or type(many) == B, 'val.ofChoice - arg #3: Must be a boolean (default: false)')

        if type(many) == NI then many = false end
        if many then assert(type(value) == T, 'val.ofChoice - arg #2: Must be a table if arg #3 is true') end

        if not many then value = { value } end
        if #value == 0 then return false end

        for _, v in ipairs(value) do
          local currentValueIsOfChoice = false
          for _, c in ipairs(choices) do
            if v == c then
              currentValueIsOfChoice = true
              break
            end
          end
          if not currentValueIsOfChoice then return false end
        end
        return true
      end,

      -- formatting
      toString       = function(v)
        if type(v) == NI then return "<nil>"
        elseif type(v) == B then return v and 'true' or 'false'
        elseif type(v) == N then return v
        elseif type(v) == S then return string.format("'%s'", v)
        elseif type(v) == T or type(v) == F or type(v) == TH then return string.format('<%s>', tostring(v))
        end
        return tostring(v)
      end
    }
    fnc      = {
      -- function argument typing and validation
      parseArgOptions = function(options)
        assert(val.ofType({ NI, T }, options), 'fnc.parseArgOptions - arg #1: Must be a table or nil')
        options             = options or {}

        local hasRequired   = options.required ~= nil
        local hasDefault    = options.default ~= nil
        local hasTypes      = options.types ~= nil
        local hasChoices    = options.choices ~= nil
        local hasErrorLevel = options.errLevel ~= nil

        assert(not (hasRequired and hasDefault), 'fnc.parseArgOptions - arg #1: { required } and { default } cannot be used together')
        assert(val.ofType({ NI, B }, options.required), 'fnc.parseArgOptions - arg #1: { required } must be a boolean (default: true)')

        assert(not (hasTypes and hasChoices), 'fnc.parseArgOptions - arg #1: { types } and { choices } cannot be used together')
        assert(not hasTypes or val.isTypesString(options.types), 'fnc.parseArgOptions - arg #1: { types } must be a type string, or a table of type strings (optional)')
        assert(not hasChoices or (val.ofType(T, options.choices) and val.ofType({ B, N, S }, options.choices, true)), 'fnc.parseArgOptions - arg #1: { choices } must be a table of booleans, numbers or strings (optional)')

        assert(not hasErrorLevel or (val.ofType(N, options.errLevel) and options.errLevel > 0), 'fnc.parseArgOptions - arg #1: { errLevel } must be a number > 0 (default: 3)')

        local parsedOptions = { default = options.default, errLevel = options.errLevel or 3 }

        if hasDefault then
          parsedOptions.required = false
        else
          parsedOptions.required = not hasRequired and true or options.required
        end

        if hasChoices then
          parsedOptions.choices = options.choices
          if hasDefault then
            assert(val.ofChoice(parsedOptions.choices, parsedOptions.default), 'fnc.parseArgOptions - arg #1: if { choices } is set, then { default } must be part of it')
          end
        elseif hasTypes then
          parsedOptions.types = options.types
          if type(parsedOptions.types) ~= T then parsedOptions.types = { parsedOptions.types } end
          if hasDefault then
            assert(val.ofType(parsedOptions.types, parsedOptions.default), 'fnc.parseArgOptions - arg #1: if { types } is set, then { default }\'s type must be part of it')
          end
        end

        return parsedOptions
      end,
      arg             = function(arg, options)
        options = fnc.parseArgOptions(options)

        if arg == nil then
          if options.required then error(err.argMissing(), options.errLevel) end
          return options.default
        end

        if options.choices and not val.ofChoice(options.choices, arg) then
          local choicesStrs = {}
          for _, choice in ipairs(options.choices) do table.insert(choicesStrs, val.toString(choice)) end
          local errMessage = str.f('Expected a value of %s, but got %s.',
                                   table.concat(choicesStrs, '/'), val.toString(arg))
          error(err.value(errMessage), options.errLevel)
        elseif options.types and not val.ofType(options.types, arg) then
          local errMessage = str.f('Expected a value of type %s, but got %s.',
                                   table.concat(options.types, '/'), type(arg))
          error(err.type(errMessage), options.errLevel)
        elseif options.default ~= nil and not val.ofType(type(options.default), arg) then
          -- if no choices and no types are specified, but a default is set, we adopt the default's type
          -- and only allow arguments of the same type
          local errMessage = str.f('Expected a value of type %s, but got %s. (adopt default type rule)',
                                   type(options.default), type(arg))
          error(err.type(errMessage), options.errLevel)
        end

        return arg
      end,
      kwarg           = function(kwArguments, key, options)
        assert(val.ofType({ NI, T }, kwArguments), 'fnc.kwarg - arg #1: table or nil expected')
        assert(val.ofType({ S }, key), 'fnc.kwarg - arg #2: string expected')
        assert(val.ofType({ NI, T }, options), 'fnc.kwarg - arg #3: table or nil expected')

        if kwArguments == nil then kwArguments = {} end
        return fnc.arg(kwArguments[key], options)
      end,
      assert          = function(assertion, options)
        local message  = fnc.kwarg(options, 'message', { types = S, required = false })
        local errLevel = fnc.kwarg(options, 'errLevel', { types = N, default = 2 })
        assert(errLevel > 0, 'fnc.assert - option "errLevel": nil or number(>0) expected')
        if not assertion then error(err.assert(message), errLevel) end
      end,
    }
    err      = {
      -- Error message formatters
      base       = function(message, options)
        return string.format(
          isRemoteEnvironment and "\n%s: %s\n" or "%s: %s",
          fnc.kwarg(options, 'errorType', { default = 'Error' }),
          fnc.arg(message, { default = 'Something went wrong!' })
        )
      end,
      type       = function(message)
        return err.base(fnc.arg(message, { default = 'Value had unexpected type!' }), { errorType = 'TypeError' })
      end,
      value      = function(message)
        return err.base(fnc.arg(message, { default = 'Unexpected value!' }), { errorType = 'ValueError' })
      end,
      argMissing = function(message)
        return err.base(fnc.arg(message, { default = 'Argument missing!' }), { errorType = 'NoArgumentError' })
      end,
      assert     = function(message)
        return err.base(fnc.arg(message, { default = 'Assertion failed!' }), { errorType = 'AssertionError' })
      end,
      program    = function(message)
        return err.base(fnc.arg(message, { default = 'Something was programmed incorrectly!' }), { errorType = 'ProgrammingError' })
      end,
      remoteMap  = function(message)
        return err.base(fnc.arg(message, { default = 'There is something wrong on the Remote Map File!' }), { errorType = 'RemoteMapError' })
      end,
      debug      = function(message)
        return err.base(fnc.arg(message, { default = 'Debugger hit!' }), { errorType = 'Debugger' })
      end
    }

    num      = {
      -- Number manipulation and conversion
      fromHex = function(hex)
        -- returns a base-10 integer from a hex value string
        return tonumber(fnc.arg(hex, { types = S }), 16)
      end,
      toHex   = function(n, padding)
        -- returns a base-16 string from a number value (if padding is true, zero-padded with 2 characters)
        local _n       = fnc.arg(n, { types = N })
        local _padding = fnc.arg(padding, { default = true })
        return str.f(_padding and '%02x' or '%x', _n)
      end,
      round   = function(n, decimals)
        local _n        = fnc.arg(n, { types = N })
        local _decimals = fnc.arg(decimals, { default = 0 })
        fnc.assert(_decimals >= 0, { message = '"decimals" must be >= 0 (default: 0)' })
        local multiplier = 10 ^ _decimals
        return math.floor(_n * multiplier + 0.5) / multiplier
      end
    }
    str      = {
      -- String manipulation and extractors
      f     = string.format, -- shorthand
      crop  = function(s, length)
        -- returns a string of limited length
        local _s      = fnc.arg(s, { types = S })
        local _length = fnc.arg(length, { default = 0 })
        fnc.assert(_length >= 0, { message = '"length" must be >= 0' })
        return _s:sub(1, _length)
      end,
      pad   = function(s, length, options)
        local _s      = fnc.arg(s, { types = S })
        local _length = fnc.arg(length, { types = N })
        fnc.assert(_length >= 0, { message = '"length" must be >= 0' })

        local leading = fnc.kwarg(options, 'leading', { default = false })
        local char    = fnc.kwarg(options, 'char', { default = ' ' })
        fnc.assert(#char == 1, { message = '"char" must be a string of length 1' })

        if #_s < _length then
          local padding = string.rep(char, _length - #_s)
          _s            = leading and padding .. _s or _s .. padding
        end
        return _s
      end,
      strip = function(s)
        -- returns a string cleaned from leading and trailing spaces
        local strippedString, _ = fnc.arg(s, { types = S }):gsub('^%s*(.-)%s*$', '%1')
        return strippedString
      end,
      split = function(s, separator)
        -- returns a list of substring of a string
        local _s         = fnc.arg(s, { types = S })
        local _separator = fnc.arg(separator, { default = ' ' })
        local subStrings = {}
        for subString in string.gmatch(_s, "([^" .. _separator .. "]+)") do table.insert(subStrings, subString) end
        return subStrings
      end
    }
    tbl      = {
      -- General table functions
      plot        = function(t, indent, level)
        -- returns a printable string from a table
        local _indent = fnc.arg(indent, { default = 2 })
        local _level  = fnc.arg(level, { default = 0 })
        fnc.assert(_indent > 0, { message = '"indent" must be >0' })
        fnc.assert(_level >= 0, { message = '"level" must be >=0. This is for recursive calls only!' })

        local maxLevel = 4
        if type(t) == T then
          if _level == maxLevel then
            return str.f('%s (max depth reached!)', val.toString(t))
          end
          local entries = {}
          for k, v in ipairs(t) do
            table.insert(entries, { str.f('[%s]', k), tbl.plot(v, _indent, _level + 1) })
          end
          for k, v in pairs(t) do if type(k) == S and k ~= 'metatable' then
            if k == 'class' then
              table.insert(entries, { k, v.name })
            else
              table.insert(entries, { k, tbl.plot(v, _indent, _level + 1) })
            end
          end end
          local results = {}
          for _, entry in ipairs(entries) do
            local k, v = unpack(entry)
            table.insert(results, str.f('%s%s = %s', string.rep(' ', (_level + 1) * _indent), k, v))
          end
          if #results == 0 then return '{}' end
          return str.f('{\n%s\n%s}',
                       table.concat(results, ',\n'), string.rep(' ', _level * _indent))
        else
          return val.toString(t)
        end
      end,
      shallowCopy = function(t)
        -- returns a shallow copy
        local copy = {}
        for k, v in pairs(fnc.arg(t, { types = T })) do copy[k] = v end
        return copy
      end,
      deepCopy    = function(t)
        -- returns a deep copy
        local copy = {}
        for k, v in pairs(fnc.arg(t, { types = T })) do
          copy[k] = type(v) == T and tbl.deepCopy(v) or v
        end
        return copy
      end
    }
    dct      = {
      -- Functions for Key/Value-only tables
      -- (in use with tables containing indexes, these may return wrong results)
      len      = function(t)
        -- returns the count of keys
        local _t    = fnc.arg(t, { types = T })
        local count = 0
        for k, _ in pairs(_t) do if type(k) == S then count = count + 1 end end
        return count
      end,
      hasKey   = function(t, key)
        -- returns true if a key exists in a table
        local _t   = fnc.arg(t, { types = T })
        local _key = fnc.arg(key, { types = S })
        for k, _ in pairs(_t) do if type(k) == S then if k == _key then return true end end end
        return false
      end,
      hasValue = function(t, value)
        -- returns true if a value exists in a table
        local _t     = fnc.arg(t, { types = T })
        local _value = fnc.arg(value, { types = { B, N, S } })
        for k, v in pairs(_t) do if type(k) == S then if v == _value then return true end end end
        return false
      end,
      keys     = function(t)
        -- returns a list of all the keys in a table
        local _t   = fnc.arg(t, { types = T })
        local keys = {}
        for k, _ in pairs(_t) do if type(k) == S then table.insert(keys, k) end end
        return keys
      end,
      equals   = function(t1, t2)
        -- returns true if 2 tables have the same keys and values
        local _t1 = fnc.arg(t1, { types = T })
        local _t2 = fnc.arg(t2, { types = T })
        if dct.len(_t1) ~= dct.len(_t2) then return false end
        -- TODO recursive check
        for k, v in pairs(_t1) do if type(k) == S then if _t2[k] ~= v then return false end end end
        return true
      end,
      get      = function(t, key, default)
        -- returns the value of a key from a table
        -- (in contrast to Python, this always falls back to nil, even if the default is not explicitly set)
        local _t    = fnc.arg(t, { types = T })
        local _key  = fnc.arg(key, { types = S })
        local value = _t[_key]
        if value == nil then
          return default
        end
        return value
      end,
      pop      = function(t, key, default)
        -- returns the value of a key from a table and removes it from the table
        -- (in contrast to Python, this always falls back to nil, even if the default is not explicitly set)
        local _t    = fnc.arg(t, { types = T })
        local _key  = fnc.arg(key, { types = S })
        local value = _t[_key]
        _t[_key]    = nil
        if value == nil then
          return default
        end
        return value
      end
    }
    lst      = {
      -- Functions for value-only tables
      -- (in use with tables containing keys, these may return wrong results)
      len       = function(t)
        -- returns the count of entries
        local _t = fnc.arg(t, { types = T })
        return #_t
      end,
      hasIndex  = function(t, index)
        -- returns true if an index exists in a table
        local _t     = fnc.arg(t, { types = T })
        local _index = fnc.arg(index, { types = N })
        for i, _ in ipairs(_t) do if i == _index then return true end end
        return false
      end,
      hasValue  = function(t, value)
        -- returns true if a value exists in a table
        local _t     = fnc.arg(t, { types = T })
        local _value = fnc.arg(value, { types = { B, N, S } })
        for _, v in ipairs(_t) do if v == _value then return true end end
        return false
      end,
      reversed  = function(t)
        -- returns a reversed table
        local _t       = fnc.arg(t, { types = T })
        local reversed = {}
        for i = lst.len(_t), 1, -1 do table.insert(reversed, _t[i]) end
        return reversed
      end,
      first     = function(t)
        -- returns the first value of a table
        local _t = fnc.arg(t, { types = T })
        return _t[1]
      end,
      last      = function(t)
        -- returns the last value of a table
        local _t = fnc.arg(t, { types = T })
        return _t[#_t]
      end,
      section   = function(t, from, to)
        -- returns a section of a table
        local _t      = fnc.arg(t, { types = T })
        local _from   = fnc.arg(from, { default = 1 })
        local _to     = fnc.arg(to, { default = #t })

        local section = {}
        for i = _from, _to do table.insert(section, _t[i]) end
        return section
      end,
      indexOf   = function(t, value)
        -- returns the index of a value in a table if it exists, otherwise nil
        local _t     = fnc.arg(t, { types = T })
        local _value = fnc.arg(value, { types = { B, N, S } })
        for i, v in ipairs(_t) do if v == _value then return i end end
        return nil
      end,
      equals    = function(t1, t2)
        -- returns true if two Arrays (t1 & t2) are equal
        local _t1 = fnc.arg(t1, { types = T })
        local _t2 = fnc.arg(t2, { types = T })
        if lst.len(_t1) ~= lst.len(_t2) then return false end
        for i, v in ipairs(_t1) do if _t2[i] ~= v then return false end end
        return true
      end,
      intersect = function(t1, t2)
        -- returns a list containing all the elements that appear on both tables
        local _t1 = fnc.arg(t1, { types = T })
        local _t2 = fnc.arg(t2, { types = T })
        if lst.len(_t1) > lst.len(_t2) then _t1, _t2 = _t2, _t1 end
        local intersection = {}
        for _, v in ipairs(_t1) do if lst.hasValue(_t2, v) then table.insert(intersection, v) end end
        return intersection
      end,
      concat    = function(...)
        local concatenatedTable = {}
        for _i, t in ipairs({ ... }) do
          fnc.assert(type(t) == T, { message = 'arguments must be tables' })
          for _j, v in ipairs(t) do table.insert(concatenatedTable, v) end
        end
        return concatenatedTable
      end,
      rep       = function(value, n)
        -- returns a new list containing a value n times
        local _value = fnc.arg(value, { types = { B, N, S, T } })
        local _n     = fnc.arg(n, { types = N })
        fnc.assert(_n >= 0, { message = '"n" must be >=0' })
        local list = {}
        for _ = 1, _n do table.insert(list, type(_value) == T and tbl.deepCopy(_value) or _value) end
        return list
      end
    }
    col      = {
      -- Functions for tables of child-tables (eg. { {foo='bar'}, {foo='baz'} }), alias "collections"
      -- (the child-tables are expected to have the same scheme)
      -- (in use with tables containing keys, these may return wrong results)
      values  = function(t, key)
        -- returns each value of attr from all child-tables
        -- (!reminder: tables cannot store nil values; so the returned list may not have the same length anymore)
        local _t     = fnc.arg(t, { types = T })
        local _key   = fnc.arg(key, { types = S })
        local values = {}
        for _, ct in ipairs(_t) do table.insert(values, dct.get(ct, _key)) end
        return values
      end,
      find    = function(t, key, value)
        -- returns the child-table and its index by key and value
        -- (returns nil, nil if not existing)
        local _t     = fnc.arg(t, { types = T })
        local _key   = fnc.arg(key, { types = S })
        local _value = fnc.arg(value, { types = { B, N, S } })
        for i, ct in ipairs(_t) do if ct[_key] == _value then return ct, i end end
        return nil, nil
      end,
      filter  = function(t, key, value)
        -- returns a list of all child-table matching key and value
        local _t      = fnc.arg(t, { types = T })
        local _key    = fnc.arg(key, { types = S })
        local _value  = fnc.arg(value, { types = { B, N, S } })
        local results = {}
        for _, ct in ipairs(_t) do if ct[_key] == _value then table.insert(results, ct) end end
        return results
      end,
      exclude = function(t, key, value)
        -- returns a list of all child-table NOT matching key and value
        local _t      = fnc.arg(t, { types = T })
        local _key    = fnc.arg(key, { type = S })
        local _value  = fnc.arg(value, { required = false, types = { B, N, S } })
        local results = {}
        for _, ct in ipairs(_t) do if ct[_key] ~= _value then table.insert(results, ct) end end
        return results
      end,
    }

    fif      = function(condition, ifTrue, ifFalse)
      -- Alternative to "(condition) and ifTrue or ifFalse".
      -- For cases where "(condition) and false or whatever" would always return whatever instead of false.
      -- But unfortunately with the disadvantage, that both ifTrue and ifFalse will always be evaluated.
      if condition then return ifTrue else return ifFalse end
    end

    debugger = function(data)
      -- immediately raises an error with data
      -- the only useful way to debug remote scripts within Reason environment
      local message = data ~= nil and str.f("data = %s", tbl.plot(data)) or nil
      error(err.debug(message), 2)
    end
    pprint   = function(data, prepend)
      -- prints using tbl.plot
      -- handy while debugging with interactive Lua
      local _prepend = fnc.arg(prepend, { types = S, required = false })
      local plotData = tbl.plot(data)
      if _prepend then
        print(str.f('%s: %s', _prepend, plotData))
      else
        print(plotData)
      end
    end
  end

  -- midi
  do
    MIDI_QUEUE = {}

    midi       = {
      ne           = 128, -- (80) Note Off (key abbreviated as 'Note End')
      ns           = 144, -- (90) Note On (key abbreviated as 'Note Start')
      pa           = 160, -- (A0) Polyphonic After-touch
      cc           = 176, -- (B0) Control Change
      pc           = 192, -- (C0) Program Change
      ca           = 208, -- (D0) Channel After-touch
      pb           = 224, -- (E0) Pitch Bending
      ss           = 240, -- (F0) SysEx Start
      se           = 247, -- (F7) SysEx End

      pattern      = function(typeValue, dataByte1, dataByte2, channel)
        local _typeValue = fnc.arg(typeValue, { choices = { midi.ne, midi.ns, midi.pa, midi.cc, midi.pc, midi.ca, midi.pb } })
        local _dataByte1 = fnc.arg(dataByte1, { types = { N, S } })
        local _dataByte2 = fnc.arg(dataByte2, { types = { N, S } })
        local _channel   = fnc.arg(channel, { default = 0 })
        fnc.assert(_channel >= 0 and _channel <= 15, { message = 'channel may be a number between 0 and 15' })

        local _statusByte = num.toHex(_typeValue + _channel)
        _dataByte1        = type(_dataByte1) == N and num.toHex(_dataByte1) or _dataByte1
        _dataByte2        = type(_dataByte2) == N and num.toHex(_dataByte2) or _dataByte2
        return _statusByte .. _dataByte1 .. _dataByte2
      end,

      addToQueue   = function(message)
        table.insert(MIDI_QUEUE, fnc.arg(message, { types = T }))
      end,
      clearQueue   = function()
        MIDI_QUEUE = {}
      end,
      processQueue = function()
        local messages = MIDI_QUEUE
        midi.clearQueue()
        return messages
      end
    }
  end

  -- Remote Callbacks
  do
    getSurfaceClass = nil
    SURFACE         = nil

    callbacks       = {
      init             = function(manufacturer, model)
        local surfaceClass = nil
        if type(getSurfaceClass) == F then surfaceClass = getSurfaceClass(manufacturer, model) end
        SURFACE = surfaceClass and surfaceClass(manufacturer, model) or nil

        fnc.assert(ControlSurface.isInstanceOf(SURFACE, ControlSurface),
                   { message = 'global function "getSurfaceClass" must return a ControlSurface subclass!' })

        remote.define_items(SURFACE:getRemoteItems())
        remote.define_auto_inputs(SURFACE:getRemoteAutoInputs())
        remote.define_auto_outputs(SURFACE:getRemoteAutoOutputs())
      end,
      set_state        = function(changedItemIndices)
        local timestamp           = remote.get_time_ms()
        local updatedScriptStates = SURFACE:setScriptStates(changedItemIndices)

        -- Handle individual changed item
        for _, index in ipairs(changedItemIndices) do
          SURFACE.items[index]:onChange(timestamp)
        end

        SURFACE:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      end,
      deliver_midi     = function(maxbytes, port)
        local timestamp = remote.get_time_ms()

        -- Use Remote's regular call interval of deliver_midi for surface-specific "tick" functions
        SURFACE:tick(timestamp)

        -- Return all due midi messages
        return midi.processQueue()
      end,
      process_midi     = function(event)
        local eventMeta         = { size = event.size, port = event.port, timeStamp = event.time_stamp }
        local eventValues       = lst.section(event, 1, eventMeta.size)

        local handled, messages = false, {}
        if lst.first(eventValues) == midi.ss and lst.last(eventValues) == midi.se then
          -- SysEx event
          handled, messages = SURFACE:handleSysexEvent(eventValues, eventMeta)
        else
          -- Any other event
          local item, midi = SURFACE:translateMidiEvent(eventValues, eventMeta)
          if midi then
            handled, messages = item:handleInput(midi)
          end
        end

        for _, message in ipairs(messages) do
          remote.handle_input({ time_stamp = eventMeta.timeStamp, item = message.item, value = message.value,
                                note       = message.note, velocity = message.velocity })
        end
        return handled
      end,
      prepare_for_use  = function()
        return SURFACE:prepareForUse()
      end,
      release_from_use = function()
        local retEvents = {}

        for _, item in ipairs(SURFACE.items) do
          retEvents = lst.concat(retEvents, item:releaseFromUse())
        end
        retEvents = lst.concat(retEvents, SURFACE:releaseFromUse())

        return retEvents
      end
    }
    for name, func in pairs(callbacks) do
      -- Setup global Remote Callback functions ("remote_init" ... )
      _G["remote_" .. name] = func
    end
  end

  -- Reason Constants
  do
    reason = {
      remoteBaseChannelStep = 8
    }
  end

  -- classes
  do
    ControlItemInput = class('ControlItemInput')
    do
      function ControlItemInput:initialize(item, type_, options)
        local errLevel  = 3
        self.item       = fnc.arg(item, { types = T, errLevel = errLevel })
        self.type       = fnc.arg(type_, { choices = { 'button', 'value', 'delta', 'keyboard' }, errLevel = errLevel })
        self.autoHandle = fnc.kwarg(options, 'autoHandle', { default = true, errLevel = errLevel })
        self.pattern    = fnc.kwarg(options, 'pattern', { types = S, required = false, errLevel = errLevel })
        self.port       = fnc.kwarg(options, 'port', { types = N, required = false, errLevel = errLevel })
        self.value      = fnc.kwarg(options, 'value', { types = S, required = false, errLevel = errLevel })
        self.note       = fnc.kwarg(options, 'note', { types = S, required = false, errLevel = errLevel })
        self.velocity   = fnc.kwarg(options, 'velocity', { types = S, required = false, errLevel = errLevel })
      end
      function ControlItemInput:toInternal()
        return { name  = self.item.name, pattern = self.pattern, port = self.port,
                 value = self.value, note = self.note, velocity = self.velocity }
      end
    end

    ControlItemOutput = class('ControlItemOutput')
    do
      function ControlItemOutput:initialize(item, type_, options)
        local errLevel  = 3
        self.item       = fnc.arg(item, { types = T, errLevel = errLevel })
        self.type       = fnc.arg(type_, { choices = { 'value', 'text' }, errLevel = errLevel })
        self.autoHandle = fnc.kwarg(options, 'autoHandle', { default = true, errLevel = errLevel })
        self.pattern    = fnc.kwarg(options, 'pattern', { types = S, required = false, errLevel = errLevel })
        self.port       = fnc.kwarg(options, 'port', { types = N, required = false, errLevel = errLevel })
        self.x          = fnc.kwarg(options, 'x', { types = S, required = false, errLevel = errLevel })
        self.y          = fnc.kwarg(options, 'y', { types = S, required = false, errLevel = errLevel })
        self.z          = fnc.kwarg(options, 'z', { types = S, required = false, errLevel = errLevel })
      end
      function ControlItemOutput:toInternal()
        return { name = self.item.name, pattern = self.pattern, port = self.port,
                 x    = self.x, y = self.y, z = self.z }
      end
    end

    ControlItem = class('ControlItem')
    do
      function ControlItem:initialize(surface, name, options)
        -- link item <-> surface
        self.surface = fnc.arg(surface, { types = T })
        table.insert(self.surface.items, self)
        self.index  = #self.surface.items

        -- item data
        self.name   = fnc.arg(name, { types = S })
        self.min    = fnc.kwarg(options, 'min', { types = N, required = false, })
        self.max    = fnc.kwarg(options, 'max', { types = N, required = false, })
        self.input  = fnc.kwarg(options, 'input', { types = T, required = false, })
        self.output = fnc.kwarg(options, 'output', { types = T, required = false, })

        fnc.assert(self.input == nil or ControlItemInput.isInstanceOf(self.input, ControlItemInput))
        fnc.assert(self.output == nil or ControlItemOutput.isInstanceOf(self.output, ControlItemOutput))
      end
      function ControlItem:__tostring()
        return str.f('%s("%s")', self.class.name, self.name)
      end
      function ControlItem:toInternal()
        local inputType  = self.input and self.input.type or 'noinput'
        local outputType = self.output and self.output.type or 'nooutput'
        return { name = self.name, input = inputType, output = outputType,
                 min  = self.min, max = self.max, modes = col.values(self:getModesData(), 'name') }
      end
      function ControlItem:sendMidi(params)
        local _params = fnc.arg(params, { types = T })
        if self.output and self.output.pattern then
          midi.addToQueue(remote.make_midi(self.output.pattern, _params))
        else
          error(err.program('A ControlItems\'s "sendMidi" method was called, but the Item has no output.'))
        end
      end
      function ControlItem:releaseFromUse()
        -- ControlSurface subclasses may overwrite this
        return {}
      end
      function ControlItem:handleInput(midi)
        -- ControlSurface subclasses may overwrite this
        local handled  = false
        local messages = {}
        return handled, messages
      end
      function ControlItem:onChange(timestamp)
        -- ControlSurface subclasses may overwrite this
      end
      function ControlItem:getModesData()
        -- ControlSurface subclasses may overwrite this
        local modesData = {}
        return modesData
      end

      -- utility wrapper methods
      function ControlItem:modeData() return self:getModesData()[remote.get_item_mode(self.index)] end
      function ControlItem:isEnabled() return remote.is_item_enabled(self.index) end
      function ControlItem:remotableName() return remote.get_item_name(self.index) end
      function ControlItem:remotableNameAndValue() return remote.get_item_name_and_value(self.index) end
      function ControlItem:remotableShortName() return remote.get_item_short_name(self.index) end
      function ControlItem:remotableShortNameAndValue() return remote.get_item_short_name_and_value(self.index) end
      function ControlItem:remotableShortestName() return remote.get_item_shortest_name(self.index) end
      function ControlItem:remotableShortestNameAndValue() return remote.get_item_shortest_name_and_value(self.index) end
      function ControlItem:remotableState() return remote.get_item_state(self.index) end
      function ControlItem:remotableTextValue() return remote.get_item_text_value(self.index) end
      function ControlItem:remotableValue() return remote.get_item_value(self.index) end
    end

    ScriptItem = class('ScriptItem', ControlItem)
    do
      function ScriptItem:initialize(surface, name)
        local errLevel = 5
        self.surface   = fnc.arg(surface, { types = T, errLevel = errLevel })
        self.name      = fnc.arg(name, { types = S, errLevel = errLevel })

        ControlItem.initialize(self, surface, name, {
          output = ControlItemOutput(self, 'text', { autoHandle = false })
        })

        self.surface.scriptState[self.name] = ''
        table.insert(self.surface.scriptItemIndices, self.index)
      end
      function ScriptItem:setState()
        local state                         = self:isEnabled() and self:remotableTextValue() or ''
        self.surface.scriptState[self.name] = state
        return state
      end
    end

    --VirtualItem = class('VirtualItem', ControlItem)
    -- TODO

    ControlSurface = class('ControlSurface')
    do
      function ControlSurface:initialize(manufacturer, model)
        local errLevel         = 5
        self.manufacturer      = fnc.arg(manufacturer, { types = S, errLevel = errLevel })
        self.model             = fnc.arg(model, { types = S, errLevel = errLevel })

        self.items             = {}
        self.scriptState       = {}
        self.scriptItemIndices = {}

        self:setup()
      end
      function ControlSurface:setup()
        error(err.program('The "setup()" method for the ControlSurface is not defined'))
      end
      function ControlSurface:getRemoteItems()
        local internalItems = {}
        for _, item in ipairs(self.items) do table.insert(internalItems, item:toInternal()) end
        return internalItems
      end
      function ControlSurface:getRemoteAutoInputs()
        local internalAutoInputs = {}
        for _, item in ipairs(col.exclude(self.items, 'input', nil)) do
          if item.input.autoHandle then table.insert(internalAutoInputs, item.input:toInternal()) end
        end
        return internalAutoInputs
      end
      function ControlSurface:getRemoteAutoOutputs()
        local internalAutoOutputs = {}
        for _, item in ipairs(col.exclude(self.items, 'output', nil)) do
          if item.output.autoHandle then table.insert(internalAutoOutputs, item.output:toInternal()) end
        end
        return internalAutoOutputs
      end
      function ControlSurface:setScriptStates(changedItemIndices)
        local updatedScriptStates = {}
        for _, index in ipairs(lst.intersect(changedItemIndices, self.scriptItemIndices)) do
          local item                     = self.items[index]
          updatedScriptStates[item.name] = item:setState()
        end
        return updatedScriptStates
      end
      function ControlSurface:translateMidiEvent(eventValues, eventMeta)
        for _, item in ipairs(self.items) do
          if item.input and item.input.pattern then
            local midi = remote.match_midi(item.input.pattern, eventValues)
            if midi then return item, midi end
          end
        end
        return nil, nil
      end

      function ControlSurface:prepareForUse()
        -- ControlSurface subclasses may overwrite this
        return {}
      end
      function ControlSurface:releaseFromUse()
        -- ControlSurface subclasses may overwrite this
        return {}
      end
      function ControlSurface:handleSysexEvent(eventValues, eventMeta)
        -- ControlSurface subclasses may overwrite this
        return false, {}
      end
      function ControlSurface:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
        -- ControlSurface subclasses may overwrite this
      end
      function ControlSurface:tick(timestamp)
        -- ControlSurface subclasses may overwrite this
      end
    end
  end
end

getSurfaceClass = function(manufacturer, model)
  local classMap = { ['X-Touch'] = XTouch }
  return classMap[model]
end

-- X-Touch
do
  XTMixChannel = class('XTMixChannel')
  do
    function XTMixChannel:initialize(surface, channelId, options)
      -- link mixChannel <-> surface
      self.surface        = fnc.arg(surface, { types = T })
      self.channelId      = fnc.arg(channelId, { types = N })
      self.lite           = fnc.kwarg(options, 'lite', { default = false })

      self.channelNr      = self.channelId + 1
      self.itemIndicesMap = {}

      if not self.lite then
        self.scribble                            = XTScribble(self)
        self.surface.mixChannels[self.channelNr] = self
      end
    end
    function XTMixChannel:registerItem(key, item)
      local _key  = fnc.arg(key, { types = S })
      local _item = fnc.arg(item, { types = T })

      fnc.assert(self[_key] == nil, { message = str.f('MixChannel of channelId %s already has a "%s" item', self.channelId, _key) })
      fnc.assert(_item.mixChannel == nil, {
        message = str.f('ControlItem "%s" is already registered to MixChannel of channelId %s', _item.name, self.channelId)
      })

      _item.mixChannel          = self
      self[_key]                = _item
      self.itemIndicesMap[_key] = _item.index
    end
    function XTMixChannel:getChangedItemKeys(changedItemIndices)
      local changedItemKeys = {}
      for key, itemIndex in pairs(self.itemIndicesMap) do
        if lst.hasValue(changedItemIndices, itemIndex) then table.insert(changedItemKeys, key) end
      end
      return changedItemKeys
    end
    function XTMixChannel:itemChangedAndIsEnabled(changedItemKeys, itemKey)
      return lst.hasValue(changedItemKeys, itemKey) and self[itemKey]:isEnabled()
    end
    function XTMixChannel:anyItemIsEnabled(itemKeys)
      for _, itemKey in pairs(itemKeys) do
        if self[itemKey]:isEnabled() then return true end
      end
      return false
    end
    function XTMixChannel:anyScribbleRelatedItemIsEnabled()
      return self:anyItemIsEnabled({ 'encoder', 'record', 'encoderClick', 'fader' })
    end
  end

  XTScribbleManager = class('XTScribbleManager')
  do
    function XTScribbleManager:initialize(surface, options)
      self.surface                  = fnc.arg(surface, { types = T })
      self.scribbles                = {}

      self.holdRemoteItemNamesLayer = false
      self.prioritizeSecondaryItems = false

      self.baseChannel              = nil
      self.channelFocus             = nil
    end
    function XTScribbleManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      if not lst.len(changedItemIndices) then return end

      local forceLayer = nil
      if updatedScriptStates._EA or updatedScriptStates._G or updatedScriptStates._M then
        -- encoder assign, group or modifier changed
        forceLayer = 'remoteItemNames'
      end
      if updatedScriptStates._SRN then
        -- "show Scribbles Remotable Names" changed
        self.holdRemoteItemNamesLayer = updatedScriptStates._SRN == 'on'
        forceLayer                    = self.holdRemoteItemNamesLayer and 'remoteItemNames' or 'header'
      end
      if updatedScriptStates._SSR then
        -- "prefer Scribbles Secondary Remotables" changed
        self.prioritizeSecondaryItems = updatedScriptStates._SSR == 'on'
        forceLayer                    = 'remoteItemNames'
      end
      if updatedScriptStates._CF then
        -- channel focus changed
        self.channelFocus = tonumber(updatedScriptStates._CF)
        forceLayer        = 'header'
      end
      if updatedScriptStates._RBC then
        -- remote base channel changed
        self.baseChannel = tonumber(updatedScriptStates._RBC)
        forceLayer       = 'header'
      end

      if forceLayer then
        for _, scribble in ipairs(self.scribbles) do
          if forceLayer == 'header' then
            scribble:sendHeaderLayer()
          elseif forceLayer == 'remoteItemNames' and scribble.mixChannel:anyScribbleRelatedItemIsEnabled() then
            local mixChannel   = scribble.mixChannel
            local item1, item2 = unpack(self.prioritizeSecondaryItems
                                          and { mixChannel.encoderClick, mixChannel.fader }
                                          or { mixChannel.encoder, mixChannel.record })
            scribble:sendRemoteItemNamesLayer(item1, item2)
          end
        end

      else
        local scribbleRelevantControlItemKeys = { 'fader', 'encoder', 'encoderClick', 'record', }
        local scribbleRelevantDisplayItemKeys = { 'header', 'color' }
        local updates                         = {}
        for _, scribble in ipairs(self.scribbles) do
          local _, colorValueIsMimicked, colorValueByChannelNr = scribble:getColorValue()
          local changedItemKeys                                = scribble.mixChannel:getChangedItemKeys(changedItemIndices)
          local changedControlItemKeys                         = lst.intersect(scribbleRelevantControlItemKeys, changedItemKeys)
          local changedDisplayItemKeys                         = lst.intersect(scribbleRelevantDisplayItemKeys, changedItemKeys)

          table.insert(updates, {
            scribble                = scribble,
            channelNr               = scribble.mixChannel.channelNr,

            colorValueIsMimicked    = colorValueIsMimicked,
            colorValueByChannelNr   = colorValueIsMimicked and colorValueByChannelNr or nil,

            controlItemsHaveChanged = #changedControlItemKeys > 0,
            displayItemsHaveChanged = #changedDisplayItemKeys > 0,

            changedControlItemKeys  = changedControlItemKeys,
          })
        end

        local updatedChannelNrs = {}
        for _, update in ipairs(col.filter(updates, 'controlItemsHaveChanged', true)) do
          update.scribble:onChangeUpdate(update.changedControlItemKeys)
          table.insert(updatedChannelNrs, update.channelNr)
        end
        for _, update in ipairs(col.filter(updates, 'displayItemsHaveChanged', true)) do
          if not lst.hasValue(updatedChannelNrs, update.channelNr) then
            update.scribble:sendHeaderLayer()
            table.insert(updatedChannelNrs, update.channelNr)
          end
        end
        for _, update in ipairs(col.filter(updates, 'colorValueIsMimicked', true)) do
          if not lst.hasValue(updatedChannelNrs, update.channelNr) and lst.hasValue(updatedChannelNrs, update.colorValueByChannelNr) then
            table.insert(updatedChannelNrs, update.channelNr)
            update.scribble:changelessUpdate()
          end
        end
      end
    end
    function XTScribbleManager:tick(timestamp)
      for _, scribble in ipairs(self.scribbles) do
        scribble:tick(timestamp)
      end
    end
  end

  XTScribble = class('XTScribble')
  do
    function XTScribble.initStaticData()
      if XTScribble.colorsData == nil then

        local colorValues       = { red = 1, green = 2, yellow = 3, blue = 4, purple = 5, cyan = 6, white = 7 }
        local colorSuffixValues = { }
        for key, value in pairs(colorValues) do colorSuffixValues[key:sub(1, 1)] = value end

        XTScribble.static.colorsData = {
          values       = colorValues,
          suffixValues = colorSuffixValues
        }
      end
      if XTScribble.lcdData == nil then
        local rows                = 2
        local charsPerRow         = 7
        XTScribble.static.lcdData = { rows = rows, charsPerRow = charsPerRow, totalTextLength = rows * charsPerRow }
      end
    end
    function XTScribble:getColorData()
      self:initStaticData()
      return XTScribble.colorsData
    end
    function XTScribble:getLcdData()
      self:initStaticData()
      return XTScribble.lcdData
    end
    function XTScribble:initialize(mixChannel, options)
      self.mixChannel = fnc.arg(mixChannel, { types = T })
      self.manager    = self.mixChannel.surface.scribbleManager
      table.insert(self.manager.scribbles, self)

      self.faderIsTouched  = false
      self.lastMessageType = ''
      self.lastMessageTime = 0
    end
    function XTScribble:onFaderTouch(faderIsTouched)
      self.faderIsTouched = faderIsTouched
      self:changelessUpdate()
    end

    function XTScribble:getColorValue(recursionLevel)
      local scribbleColor = self.mixChannel.scribbleColor
      local a, b          = unpack(str.split(scribbleColor.textValue, '_'))
      if a == 'mimic' then
        local _recursionLevel = fnc.arg(recursionLevel, { default = 0 })
        if _recursionLevel >= self.mixChannel.surface.mixChannelsCount then
          error(err.remoteMap('Current mapping of Scribble Color items using "mimic_<channelNumber>" leads to an endless loop.'))
        end

        local channelNr                            = fnc.arg(tonumber(b), { types = N })
        local colorValue, _, colorValueByChannelNr = self.mixChannel.surface.mixChannels[channelNr].scribble:getColorValue(_recursionLevel + 1)
        return colorValue, true, colorValueByChannelNr
      elseif a == 'header' and b == 'suffix' then
        local _, suffixColorValue = self:getHeaderTextAndSuffixColorValue()
        local colorValue          = suffixColorValue or self:getColorData().values.white
        return colorValue, false, self.mixChannel.channelNr
      else
        local colorValue = self:getColorData().values[a] or self:getColorData().values.white
        return colorValue, false, self.mixChannel.channelNr
      end
    end
    function XTScribble:getHeaderTextAndSuffixColorValue()
      local scribbleHeader   = self.mixChannel.scribbleHeader
      local textWithoutTail  = scribbleHeader.textValue:sub(1, -3)
      local tail             = scribbleHeader.textValue:sub(-2)
      local colorSuffix      = tail:sub(1, 1) == ' ' and tail:sub(2, 2):lower() or nil
      local suffixColorValue = self:getColorData().suffixValues[colorSuffix]
      local text             = (suffixColorValue and scribbleHeader:modeData().cutColorSuffix) and textWithoutTail or scribbleHeader.textValue
      return text, suffixColorValue
    end
    function XTScribble:getHeaderLayerText()
      local scribbleHeader = self.mixChannel.scribbleHeader
      local lcdData        = self:getLcdData()
      local headerText, _  = self:getHeaderTextAndSuffixColorValue()

      local textRow1       = str.pad(str.crop(headerText, lcdData.charsPerRow), lcdData.charsPerRow)
      local textRow2       = string.rep(' ', lcdData.charsPerRow)

      if scribbleHeader:modeData().includeRMSChannelNumber then
        local baseChannel = self.manager.baseChannel
        if baseChannel and scribbleHeader:remotableItemIsChannelName() then
          local rmsChannelNumber = baseChannel + self.mixChannel.channelId
          if self.manager.channelFocus ~= nil then
            rmsChannelNumber = baseChannel + self.manager.channelFocus - 1
          end
          textRow2 = str.pad('Ch: ' .. rmsChannelNumber, lcdData.charsPerRow)
        end
      end

      return textRow1 .. textRow2
    end
    function XTScribble:getRemoteItemNameText(item)
      local lcdData = self:getLcdData()
      local text    = string.rep(' ', lcdData.charsPerRow)
      if item:isEnabled() then
        local remoteItemName = item:remotableName()
        if remoteItemName:len() > lcdData.charsPerRow then remoteItemName = item:remotableShortName() end
        if remoteItemName:len() > lcdData.charsPerRow then remoteItemName = item:remotableShortestName() end
        text = str.pad(str.crop(remoteItemName, lcdData.charsPerRow), lcdData.charsPerRow)
      end
      return text
    end
    function XTScribble:getRemoteItemValueText(item)
      local lcdData = self:getLcdData()
      local text    = string.rep(' ', lcdData.charsPerRow)
      if item:isEnabled() then
        local booleanItemIndices = { self.mixChannel.record.index, self.mixChannel.encoderClick.index }
        if lst.hasValue(booleanItemIndices, item.index) then
          text = item:remotableValue() > 0 and 'On' or 'Off'
        else
          text = item:remotableTextValue()
        end
      end
      return str.pad(str.crop(text, lcdData.charsPerRow), lcdData.charsPerRow, { leading = true })
    end

    function XTScribble:sendTurnOffMessage()
      local lcdData = self:getLcdData()
      local text    = string.rep(' ', lcdData.totalTextLength)
      self:sendText(text, { colorValue = 0, messageType = 'turnOff' })
    end
    function XTScribble:sendHeaderLayer()
      if self.mixChannel.scribbleHeader.textValue ~= '' then
        local text = self:getHeaderLayerText()
        self:sendText(text, { colorValue = self:getColorValue(), invertRow2 = true, messageType = 'header' })
      else
        self:changelessUpdate()
      end
    end
    function XTScribble:sendRemoteItemNamesLayer(item1, item2)
      local textRow1 = self:getRemoteItemNameText(item1)
      local textRow2 = self:getRemoteItemNameText(item2)
      self:sendText(textRow1 .. textRow2, { colorValue = self:getColorValue(), invertRow2 = false, messageType = 'itemNames' })
    end
    function XTScribble:sendRemoteItemValueLayer(item)
      local textRow1 = self:getRemoteItemNameText(item)
      local textRow2 = self:getRemoteItemValueText(item)
      self:sendText(textRow1 .. textRow2, { colorValue = self:getColorValue(), invertRow2 = true, messageType = 'itemValue' })
    end

    function XTScribble:onChangeUpdate(changedControlItemKeys)
      if (not self.faderIsTouched) and self.mixChannel:itemChangedAndIsEnabled(changedControlItemKeys, 'encoder') then
        self:sendRemoteItemValueLayer(self.mixChannel.encoder)
      elseif (not self.faderIsTouched) and self.mixChannel:itemChangedAndIsEnabled(changedControlItemKeys, 'record') then
        self:sendRemoteItemValueLayer(self.mixChannel.record)
      elseif (not self.faderIsTouched) and self.mixChannel:itemChangedAndIsEnabled(changedControlItemKeys, 'encoderClick') then
        self:sendRemoteItemValueLayer(self.mixChannel.encoderClick)
      elseif self.mixChannel:itemChangedAndIsEnabled(changedControlItemKeys, 'fader') then
        self:sendRemoteItemValueLayer(self.mixChannel.fader)
      else
        self:changelessUpdate()
      end
    end
    function XTScribble:changelessUpdate()
      if self.faderIsTouched and self.mixChannel.fader:isEnabled() then
        self:sendRemoteItemValueLayer(self.mixChannel.fader)
      elseif self.mixChannel:anyScribbleRelatedItemIsEnabled() then
        if (not self.manager.holdRemoteItemNamesLayer) and self.mixChannel.scribbleHeader.textValue ~= '' then
          self:sendHeaderLayer()
        else
          local mixChannel   = self.mixChannel
          local item1, item2 = unpack(self.manager.prioritizeSecondaryItems
                                        and { mixChannel.encoderClick, mixChannel.fader }
                                        or { mixChannel.encoder, mixChannel.record })
          self:sendRemoteItemNamesLayer(item1, item2)
        end
      else
        self:sendTurnOffMessage()
      end
    end
    function XTScribble:tick(timestamp)
      if self.faderIsTouched or self.lastSendType == 'turnOff' then return end

      local delayMS = 1500
      if timestamp < (self.lastMessageTime + delayMS) then return end

      if self.mixChannel:anyScribbleRelatedItemIsEnabled() and self.manager.holdRemoteItemNamesLayer and self.lastSendType ~= 'itemNames' then
        local mixChannel   = self.mixChannel
        local item1, item2 = unpack(self.manager.prioritizeSecondaryItems
                                      and { mixChannel.encoderClick, mixChannel.fader }
                                      or { mixChannel.encoder, mixChannel.record })
        self:sendRemoteItemNamesLayer(item1, item2)
      elseif (not self.manager.holdRemoteItemNamesLayer) and self.lastSendType ~= 'header' then
        self:sendHeaderLayer()
      end

    end

    function XTScribble:getTextValues(text)
      local values = {}
      for i = 1, text:len() do table.insert(values, text:byte(i)) end
      return values
    end
    function XTScribble:sendText(text, options)
      local lcdData = self:getLcdData()
      local _text   = fnc.arg(text, { types = S })
      fnc.assert(#_text == lcdData.totalTextLength)

      local colorData   = self:getColorData()
      local _colorValue = fnc.kwarg(options, 'colorValue', { default = colorData.values.white })
      local _invertRow  = fnc.kwarg(options, 'invertRow2', { default = false })
      _colorValue       = _invertRow and _colorValue + 64 or _colorValue

      local addressByte = 32 + self.mixChannel.channelId
      local payload     = lst.concat({ midi.ss, 0, 0, 102, 88, addressByte, _colorValue }, self:getTextValues(text), { midi.se })
      midi.addToQueue(payload)

      local _messageType   = fnc.kwarg(options, 'messageType', { types = S, require = false })
      self.lastMessageType = _messageType
      self.lastMessageTime = remote.get_time_ms()
    end
  end

  XTScribbleHeader = class('XTScribble', ControlItem)
  do
    function XTScribbleHeader.initStaticData()
      if XTScribbleHeader.modesData == nil then
        XTScribbleHeader.static.modesData = {
          { name = 'default', cutColorSuffix = false, includeRMSChannelNumber = false }, -- default
          { name = 'cut_color_suffix', cutColorSuffix = true, includeRMSChannelNumber = false }, -- default
          { name = 'rms', cutColorSuffix = true, includeRMSChannelNumber = true }
        }
      end
    end
    function XTScribbleHeader:getModesData()
      self:initStaticData()
      return XTScribbleHeader.modesData
    end
    function XTScribbleHeader:initialize(surface, name, options)
      local mixChannel = fnc.kwarg(options, 'mixChannel', { types = T })

      self.textValue   = ''

      ControlItem.initialize(self, surface, name, {
        output = ControlItemOutput(self, 'text', { autoHandle = false }),
      })

      mixChannel:registerItem('scribbleHeader', self)
    end
    function XTScribbleHeader:remotableItemIsChannelName()
      return self:isEnabled() and (self:remotableName()):match("^Channel %d+ Channel Name$") ~= nil
    end
    function XTScribbleHeader:onChange(timestamp)
      self.textValue = self:isEnabled() and str.strip(self:remotableTextValue()) or ''
    end
  end

  XTScribbleColor = class('XTScribbleColor', ControlItem)
  do
    function XTScribbleColor:initialize(surface, name, options)
      local mixChannel = fnc.kwarg(options, 'mixChannel', { types = T })

      self.textValue   = ''

      ControlItem.initialize(self, surface, name, {
        output = ControlItemOutput(self, 'text', { autoHandle = false }),
      })

      mixChannel:registerItem('scribbleColor', self)
    end
    function XTScribbleColor:onChange(timestamp)
      self.textValue = self:isEnabled() and str.strip(self:remotableTextValue()) or ''
    end
  end

  XTTimeCodeManager = class('XTTimeCodeManager')
  do
    function XTTimeCodeManager.initStaticData()
      if XTTimeCodeManager.translationMap == nil then
        XTTimeCodeManager.static.translationMap = {
          [' '] = 0x00, ['0'] = 0x3F, ['1'] = 0x06, ['2'] = 0x5B, ['3'] = 0x4F, ['4'] = 0x66, ['5'] = 0x6D,
          ['6'] = 0x7D, ['7'] = 0x07, ['8'] = 0x7F, ['9'] = 0x6F, ['A'] = 0x77, ['B'] = 0x7C, ['C'] = 0x39,
          ['D'] = 0x5E, ['E'] = 0x79, ['F'] = 0x71, ['G'] = 0x3D, ['H'] = 0x76, ['I'] = 0x30, ['J'] = 0x1E,
          ['K'] = 0x75, ['L'] = 0x38, ['M'] = 0x15, ['N'] = 0x37, ['O'] = 0x3F, ['P'] = 0x73, ['Q'] = 0x6B,
          ['R'] = 0x33, ['S'] = 0x6D, ['T'] = 0x78, ['U'] = 0x3E, ['V'] = 0x3E, ['W'] = 0x2A, ['X'] = 0x76,
          ['Y'] = 0x6E, ['Z'] = 0x5B, ['a'] = 0x5F, ['b'] = 0x7C, ['c'] = 0x58, ['d'] = 0x5E, ['e'] = 0x7B,
          ['f'] = 0x71, ['g'] = 0x6F, ['h'] = 0x74, ['i'] = 0x10, ['j'] = 0x0C, ['k'] = 0x75, ['l'] = 0x30,
          ['m'] = 0x14, ['n'] = 0x54, ['o'] = 0x5C, ['p'] = 0x73, ['q'] = 0x67, ['r'] = 0x50, ['s'] = 0x6D,
          ['t'] = 0x78, ['u'] = 0x1C, ['v'] = 0x1C, ['w'] = 0x14, ['x'] = 0x76, ['y'] = 0x6E, ['z'] = 0x5B,
          ['-'] = 0x40, ['?'] = 0x53
        }
      end
    end
    function XTTimeCodeManager:initialize(surface, options)
      self.surface              = fnc.arg(surface, { types = T })

      self.fragments            = {}

      self.assignmentSection    = { pos = nil, width = nil }
      self.scrollMessageSection = { pos = nil, width = nil }

      self.scrollMessage        = {
        active         = false,
        hasPriority    = false,
        text           = '',
        index          = 1,
        lastUpdateTime = 0,
        scrollsCount   = 1,
      }
    end
    function XTTimeCodeManager:registerFragment(item, fragmentType)
      local _item         = fnc.arg(item, { types = T })
      local _fragmentType = fnc.arg(fragmentType, { types = S })
      fnc.assert(_item.manager == nil, { message = str.f('XTTimeCodeFragment "%s" is already registered to the XTTimeCodeManager', _item.name) })

      _item.manager = self
      table.insert(self.fragments, _item)

      local relatedManagerSection = nil
      if _fragmentType == "assignment" then
        relatedManagerSection = self.assignmentSection
      elseif _fragmentType == "scrollMessage" then
        relatedManagerSection = self.scrollMessageSection
      end

      local fragmentSection = _item.section

      if relatedManagerSection.pos == nil then
        relatedManagerSection.pos = fragmentSection.pos
      elseif relatedManagerSection.pos > fragmentSection.pos then
        relatedManagerSection.pos = fragmentSection.pos
      end

      if relatedManagerSection.width == nil then
        relatedManagerSection.width = fragmentSection.width
      else
        relatedManagerSection.width = relatedManagerSection.width + fragmentSection.width
      end
    end

    function XTTimeCodeManager:sendText(section, text, decimals)
      self:initStaticData()
      local translationMap = XTTimeCodeManager.translationMap

      fnc.assert(#text == section.width)
      local _decimals = fnc.arg(decimals, { choices = { 'trailing', 'all' }, required = false })

      for i = 1, #text do
        local typeAddressByte = _decimals == 'all' or (_decimals == 'trailing' and i == #text) and 112 or 96
        local addressByte     = typeAddressByte + (section.pos - 1) + (i - 1)
        local charRaw         = text:sub(i, i)
        local char            = translationMap[charRaw] or translationMap[' ']
        midi.addToQueue({ midi.cc, addressByte, char })
      end
    end

    function XTTimeCodeManager:getChangedFragments(changedItemIndices)
      local changedFragments = {}
      for _, fragment in pairs(self.fragments) do
        if lst.hasValue(changedItemIndices, fragment.index) then table.insert(changedFragments, fragment) end
      end
      return changedFragments
    end
    function XTTimeCodeManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      local newScrollMessageText = nil
      local newScrollMessageType = nil

      if updatedScriptStates._S then
        newScrollMessageText = updatedScriptStates._S ~= '' and updatedScriptStates._S or 'detached'
        newScrollMessageType = 'Sc'
      elseif updatedScriptStates._CF then
        local channelText  = 'Multi'
        local channelFocus = tonumber(updatedScriptStates._CF)
        if channelFocus ~= nil or channelFocus == 0 then
          if channelFocus == 9 then
            channelText = 'Master'
          else
            local baseChannel = tonumber(self.surface.scriptState._RBC)
            if baseChannel then
              channelText = baseChannel + channelFocus - 1
            else
              channelText = "??"
            end
          end
        end

        newScrollMessageText = str.f('Chnl %s', channelText)
        newScrollMessageType = 'CF'
      elseif updatedScriptStates._EA then
        newScrollMessageText = updatedScriptStates._EA ~= '' and updatedScriptStates._EA or 'none'
        newScrollMessageType = 'EA'
      elseif updatedScriptStates._G then
        newScrollMessageText = updatedScriptStates._G ~= '' and updatedScriptStates._G or 'none'
        newScrollMessageType = 'Gr'
      elseif updatedScriptStates._M then
        newScrollMessageText = updatedScriptStates._M ~= '' and updatedScriptStates._M or 'none'
        newScrollMessageType = 'Md'
      end

      if newScrollMessageText then
        self:startScrollMessage(newScrollMessageText, { type = newScrollMessageType, timestamp = timestamp })
      elseif not self.scrollMessage.active then
        for _, fragment in ipairs(self:getChangedFragments(changedItemIndices)) do
          fragment:sendRemoteValueText()
        end
      end
    end
    function XTTimeCodeManager:startScrollMessage(text, options)
      local _text        = fnc.arg(text, { types = S })
      local _type        = fnc.kwarg(options, 'type', { types = S, required = false })
      local _timestamp   = fnc.kwarg(options, 'timestamp', { types = N, required = false })
      local _hasPriority = fnc.kwarg(options, 'hasPriority', { default = false })

      -- for prepare_for_use
      if not _hasPriority and self.scrollMessage.hasPriority and self.scrollMessage.active then return end

      self.scrollMessage.active         = true
      self.scrollMessage.hasPriority    = _hasPriority
      self.scrollMessage.text           = _text
      self.scrollMessage.index          = 1
      self.scrollMessage.lastUpdateTime = _timestamp or remote.get_time_ms()

      local sectionWidth                = self.scrollMessageSection.width
      self.scrollMessage.scrollsCount   = #_text <= sectionWidth and 1 or #_text - sectionWidth + 1

      local typeText                    = _type or string.rep(' ', self.assignmentSection.width)
      local scrollMessageText           = self:getScrollMessageText()

      self:sendText(self.assignmentSection, typeText)
      self:sendText(self.scrollMessageSection, scrollMessageText)
    end
    function XTTimeCodeManager:getScrollMessageText()
      local index        = self.scrollMessage.index
      local scrollsCount = self.scrollMessage.scrollsCount
      local sectionWidth = self.scrollMessageSection.width

      index              = index > scrollsCount and 1 or index
      local text         = self.scrollMessage.text:sub(index, index + sectionWidth - 1)
      return str.pad(str.crop(text, sectionWidth), sectionWidth)
    end
    function XTTimeCodeManager:getScrollMessageDelay()
      local index        = self.scrollMessage.index
      local scrollsCount = self.scrollMessage.scrollsCount
      local delayMap     = { start = 1000, intermediate = 75, close = 600, review = 1000 }

      if scrollsCount > 1 then
        if index == 1 then return delayMap.start
        elseif index > 1 and index < scrollsCount then return delayMap.intermediate
        elseif index == scrollsCount then return delayMap.close
        elseif index > scrollsCount then return delayMap.review
        end
      end
      return delayMap.review
    end
    function XTTimeCodeManager:tick(timestamp)
      if not self.scrollMessage.active then return end

      local delayMS = self:getScrollMessageDelay()
      if timestamp < (self.scrollMessage.lastUpdateTime + delayMS) then return end

      self.scrollMessage.index          = self.scrollMessage.index + 1
      self.scrollMessage.lastUpdateTime = timestamp

      if self.scrollMessage.index > (self.scrollMessage.scrollsCount + 1) then
        -- index is bigger then the 'review' index. end the scroll message
        self.scrollMessage.active = false
        for _, fragment in ipairs(self.fragments) do
          fragment:sendRemoteValueText()
        end
      else
        local scrollMessageText = self:getScrollMessageText()
        self:sendText(self.scrollMessageSection, scrollMessageText)
      end
    end
  end

  XTTimeCodeFragment = class('XTTimeCodeFragment', ControlItem)
  do
    function XTTimeCodeFragment.initStaticData()
      if XTTimeCodeFragment.modesData == nil then
        XTTimeCodeFragment.static.modesData = {
          { name = 'default', decimals = nil }, -- default
          { name = 'decimal_trailing', decimals = 'trailing' },
          { name = 'decimal_all', decimals = 'all' },
        }
      end
    end
    function XTTimeCodeFragment:getModesData()
      self:initStaticData()
      return XTTimeCodeFragment.modesData
    end
    function XTTimeCodeFragment:initialize(surface, name, options)
      local _section = fnc.kwarg(options, 'section', { types = T })
      fnc.assert(val.ofType(N, _section.pos) and _section.pos > 0)
      fnc.assert(val.ofType(N, _section.width) and _section.pos > 0)

      self.section = _section
      ControlItem.initialize(self, surface, name, {
        output = ControlItemOutput(self, 'text', { autoHandle = false }),
      })
    end
    function XTTimeCodeFragment:sendRemoteValueText()
      local textLength = self.section.width
      local text       = string.rep(' ', textLength)
      if self:isEnabled() then
        text = str.pad(str.crop(self:remotableTextValue(), textLength), textLength, { leading = true })
      end
      self.manager:sendText(self.section, text, self:modeData().decimals)
    end
  end

  XTFaderBankManager = class('XTFaderBankManager')
  do
    function XTFaderBankManager:initialize(surface, options)
      self.surface                   = fnc.arg(surface, { types = T })

      self.availableChannelsLeft     = 0
      self.availableChannelsRight    = 0

      self.faderBankCheckItems       = {}
      self.faderBankCheckItemIndices = {}

      self.navigationButtons         = {}
    end
    function XTFaderBankManager:registerFaderBankCheck(channelNr, item)
      local _channelNr = fnc.arg(channelNr, { types = N })
      local _item      = fnc.arg(item, { types = T })

      fnc.assert(self.faderBankCheckItems[_channelNr] == nil, { message = str.f('FaderBankManager already has a check item of channelNr "%s"', _channelNr) })
      fnc.assert(_item.faderBankManager == nil, { message = str.f('ControlItem "%s" is already registered to the XTFaderBankManager', _item.name) })

      _item.faderBankManager               = self
      self.faderBankCheckItems[_channelNr] = _item
      table.insert(self.faderBankCheckItemIndices, _item.index)
    end
    function XTFaderBankManager:registerNavigationButton(item)
      local _item = fnc.arg(item, { types = T })
      fnc.assert(_item.faderBankManager == nil, { message = str.f('ControlItem "%s" is already registered to the XTFaderBankManager', _item.name) })

      _item.faderBankManager = self
      table.insert(self.navigationButtons, _item)
    end
    function XTFaderBankManager:getNavigationButtonAction(item)
      local actionMap = {
        ['Previous 8 Remote Base Channel'] = { direction = 'left', width = 'page' },
        ['Previous Remote Base Channel']   = { direction = 'left', width = 'channel' },
        ['Next 8 Remote Base Channel']     = { direction = 'right', width = 'page' },
        ['Next Remote Base Channel']       = { direction = 'right', width = 'channel' },
      }
      return dct.get(actionMap, item:remotableName())
    end
    function XTFaderBankManager:getNavigationButtonsByAction()
      local navigationButtonsByAction = { left = { page = nil, channel = nil }, right = { page = nil, channel = nil } }
      for _, item in ipairs(self.navigationButtons) do
        local action = self:getNavigationButtonAction(item)
        if action then navigationButtonsByAction[action.direction][action.width] = item end
      end
      return navigationButtonsByAction
    end
    function XTFaderBankManager:directionHasAvailableChannels(direction)
      local hasAvailableChannels = { left = self.availableChannelsLeft > 0, right = self.availableChannelsRight > 0 }
      return hasAvailableChannels[direction]
    end
    function XTFaderBankManager:updateNavigationButtonLeds(timestamp)
      local navigationButtonsByAction = self:getNavigationButtonsByAction()
      for _i, items in pairs(navigationButtonsByAction) do
        for _j, item in pairs(items) do
          item:onChange(timestamp)
        end
      end
    end
    function XTFaderBankManager:handleNavigationButtonAction(action)
      local handled, messages = false, {}

      if action.direction == 'left' then
        -- no need to handle anything in this direction, as
        -- the remote base channel can never go lower then the first channel.
        return handled, messages
      end

      local steps = action.width == 'channel' and 1 or reason.remoteBaseChannelStep
      if steps > self.availableChannelsRight then
        -- there are less channels on the right side than the action wants to go.
        -- so we interrupt here, and do only as many steps to the right as possible, if even necessary.
        handled = true

        if self.availableChannelsRight > 0 then
          -- if we are here, the "Next 8 Remote Base Channel" item must have been triggered.
          -- we make remote forget that this happened and tell it that the "Next Remote Base Channel" item
          -- was triggered self.availableChannelsRight -times instead.
          local nextRemoteBaseChannelItem = self:getNavigationButtonsByAction().right.channel
          if nextRemoteBaseChannelItem then
            messages = lst.rep({ item = nextRemoteBaseChannelItem.index, value = 1 }, self.availableChannelsRight)
          end
        end
      end

      return handled, messages
    end
    function XTFaderBankManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      local updateNavigationLeds = false

      if updatedScriptStates._RBC then
        local baseChannel           = tonumber(updatedScriptStates._RBC)
        local availableChannelsLeft = baseChannel ~= nil and baseChannel - 1 or 0
        if availableChannelsLeft > reason.remoteBaseChannelStep then availableChannelsLeft = reason.remoteBaseChannelStep end
        if self.availableChannelsLeft ~= availableChannelsLeft then updateNavigationLeds = true end
        self.availableChannelsLeft = availableChannelsLeft
      end

      local changedFaderBankCheckItems = lst.intersect(self.faderBankCheckItemIndices, changedItemIndices)
      if #changedFaderBankCheckItems > 0 then
        local availableChannelsRight = 0
        for channelNr, item in ipairs(self.faderBankCheckItems) do
          if item:remotableItemIsChannelName() then
            availableChannelsRight = channelNr
          else
            break
          end
        end
        if self.availableChannelsRight ~= availableChannelsRight then updateNavigationLeds = true end
        self.availableChannelsRight = availableChannelsRight
      end

      if updateNavigationLeds then self:updateNavigationButtonLeds(timestamp) end
    end
  end

  XTFaderBankCheck = class('XTFaderBankCheck', ControlItem)
  do
    function XTFaderBankCheck:initialize(surface, name, options)
      ControlItem.initialize(self, surface, name, {
        output = ControlItemOutput(self, 'text', { autoHandle = false }),
      })
    end
    function XTFaderBankCheck:remotableItemIsChannelName()
      return self:isEnabled() and (self:remotableName()):match("^Channel %d+ Channel Name$") ~= nil
    end
  end

  XTButton = class('XTButton', ControlItem)
  do
    function XTButton.initStaticData()
      if XTButton.static.modesData == nil then
        local ledOff      = 0
        local ledFlash    = 1
        local ledOn       = 2

        local buttonModes = {
          button    = { { name = "toggle", hold = false }, -- default
                        { name = "hold", hold = true } },
          led       = { { name = "os", values = { ledOff, ledOn } }, -- default
                        { name = "of", values = { ledOff, ledFlash } },
                        { name = "so", values = { ledOn, ledOff } },
                        { name = "sf", values = { ledOn, ledFlash } },
                        { name = "fo", values = { ledFlash, ledOff } },
                        { name = "fs", values = { ledFlash, ledOn } },
                        { name = "o", values = { ledOff, ledOff } },
                        { name = "s", values = { ledOn, ledOn } },
                        { name = "f", values = { ledFlash, ledFlash } } },
          ledButton = {}
        }

        for _i, buttonMode in ipairs(buttonModes.button) do
          for _j, ledMode in ipairs(buttonModes.led) do
            table.insert(buttonModes.ledButton, {
              name   = buttonMode.hold and str.f('%s_%s', ledMode.name, buttonMode.name) or ledMode.name,
              values = ledMode.values,
              hold   = buttonMode.hold,
            })
          end
        end

        XTButton.static.modesData = buttonModes
      end
    end
    function XTButton:getModesData()
      self:initStaticData()

      if not self.hasInput then
        return XTButton.static.modesData.led
      elseif not self.hasOutput then
        return XTButton.static.modesData.button
      else
        return XTButton.static.modesData.ledButton
      end
    end
    function XTButton:initialize(surface, name, options)
      local addressByte       = fnc.kwarg(options, 'addressByte', { types = N, required = false })
      -- or --
      local mixChannel        = fnc.kwarg(options, 'mixChannel', { types = T, required = false })
      local mixChannelKey     = fnc.kwarg(options, 'mixChannelKey', { types = S, required = false })
      local addressByteOffset = fnc.kwarg(options, 'addressByteOffset', { types = N, required = false })

      local noInput           = fnc.kwarg(options, 'noInput', { default = false })
      local noOutput          = fnc.kwarg(options, 'noOutput', { default = false })

      self.hasInput           = not noInput
      self.hasOutput          = not noOutput

      local modesDataKey      = 'ledButton'
      if not self.hasInput then
        modesDataKey = 'led'
      elseif not self.hasOutput then
        modesDataKey = 'button'
      end

      addressByte = addressByte or addressByteOffset + mixChannel.channelId

      input       = nil
      if self.hasInput then
        input = ControlItemInput(self, 'button', {
          pattern = midi.pattern(midi.ns, addressByte, "?<???x>")
        })
      end

      -- Because remote works how it works... remote.get_item_mode(<index_of_item_without_output>) returns always 1.
      -- That's why we also register an output if self.hasOutput is false.
      -- We handle changes ourselves with XTButton:onChange and just do nothing if self.hasOutput is false.
      output = ControlItemOutput(self, 'value', {
        pattern    = midi.pattern(midi.ns, addressByte, "xx"),
        autoHandle = false,
      })

      ControlItem.initialize(self, surface, name, {
        min    = 0, max = 1,
        input  = input,
        output = output,
      })

      self.isPressed = false

      if mixChannel then
        mixChannel:registerItem(mixChannelKey, self)
      end
    end
    function XTButton:releaseFromUse()
      return self.hasOutput and { remote.make_midi(self.output.pattern, { x = 0 }) } or {}
    end
    function XTButton:onChange(timestamp)
      -- if no output actually exists, there is nothing to do
      if not self.hasOutput then return end

      local isEnabled = self:isEnabled()
      local value     = isEnabled and self:remotableValue() or 0

      -- if the button is assigned as fader bank navigation, the fader bank manager determines the output value
      if isEnabled and self.faderBankManager then
        local faderBankAction = self.faderBankManager:getNavigationButtonAction(self)
        if faderBankAction then
          value = self.faderBankManager:directionHasAvailableChannels(faderBankAction.direction) and 1 or 0
        end
      end

      local modeValues = self:modeData().values
      local retValue   = modeValues[value + 1]
      self:sendMidi({ x = retValue })
    end
    function XTButton:handleInput(midi)
      local handled, messages    = false, {}
      local isPressed            = midi.x > 0

      -- if fader bank navigation
      local isHandledByFaderBank = false
      if self.faderBankManager then
        local faderBankAction = self.faderBankManager:getNavigationButtonAction(self)
        if faderBankAction then
          isHandledByFaderBank = true
          if isPressed then
            handled, messages = self.faderBankManager:handleNavigationButtonAction(faderBankAction)
          end
        end
      end

      -- otherwise
      if not isHandledByFaderBank then
        if self:modeData().hold then
          if isPressed then
            if self.isPressed then handled = true end
          else
            if self.isPressed then messages = { { item = self.index, value = 1 } }
            else handled = true end
          end
        end
      end

      self.isPressed = isPressed
      return handled, messages
    end
  end

  XTEncoder = class('XTEncoder', ControlItem)
  do
    function XTEncoder.initStaticData()
      if XTEncoder.static.modesData == nil then
        local ledOffChar         = '0'
        local ledOnChar          = '1'

        local ledOffCharReadable = '-'
        local ledOnCharReadable  = '+'

        local variantDefault     = 'def'
        local variantMirrored    = 'mir'
        local variantInverted    = 'inv'

        local categoryFull       = 'full'
        local categoryLeft       = 'left'
        local categoryRight      = 'right'

        local ledModeSpecs       = {
          { name      = "dot", variants = { variantDefault, variantInverted }, fragmentStatesCount = 6,
            litStates = { "+------------", "-+-----------", "--+----------", "---+---------", "----+--------",
                          "-----+-------", "------+------", "-------+-----", "--------+----", "---------+---",
                          "----------+--", "-----------+-", "------------+" } },
          { name      = "fill", variants = { variantDefault, variantMirrored }, fragmentStatesCount = 6,
            litStates = { "+------------", "++-----------", "+++----------", "++++---------", "+++++--------",
                          "++++++-------", "+++++++------", "++++++++-----", "+++++++++----", "++++++++++---",
                          "+++++++++++--", "++++++++++++-", "+++++++++++++" } },
          { name      = "rms_gatcmb", variants = { variantDefault }, fragmentStatesCount = 6,
            litStates = { "-------------", "+------------", "++-----------", "+++----------", "++++---------",
                          "+++++--------" } },
          { name      = "dot_blur", variants = { variantDefault, variantInverted }, fragmentStatesCount = 11,
            litStates = { "+------------", "++-----------", "-+-----------", "-++----------", "--+----------",
                          "--++---------", "---+---------", "---++--------", "----+--------", "----++-------",
                          "-----+-------", "-----++------", "------+------", "------++-----", "-------+-----",
                          "-------++----", "--------+----", "--------++---", "---------+---", "---------++--",
                          "----------+--", "----------++-", "-----------+-", "-----------++", "------------+" } },
          { name      = "bip", variants = { variantDefault, variantInverted },
            litStates = { "+++++++------", "-++++++------", "--+++++------", "---++++------", "----+++------",
                          "-----++------", "------+------", "------++-----", "------+++----", "------++++---",
                          "------+++++--", "------++++++-", "------+++++++" } },
          { name      = "pan", variants = { variantDefault, variantInverted },
            litStates = { "++++++-------", "+++++++------", "++++++++-----", "+++++++++----", "++++++++++---",
                          "+++++++++++--", "-+++++++++++-", "--+++++++++++", "---++++++++++", "----+++++++++",
                          "-----++++++++", "------+++++++", "-------++++++" } },
          { name      = "dot_spread", variants = { variantDefault, variantInverted },
            litStates = { "------+------", "-----+-+-----", "----+---+----", "---+-----+---", "--+-------+--",
                          "-+---------+-", "+-----------+" } },
          { name      = "fill_spread", variants = { variantDefault },
            litStates = { "------+------", "-----+++-----", "----+++++----", "---+++++++---", "--+++++++++--",
                          "-+++++++++++-", "+++++++++++++" } },
          -- separate definition of fill_spread to avoid empty leds on 'inv' and 'rev_inv' variants
          { name      = "fill_spread", variants = { variantInverted },
            litStates = { "-------------", "------+------", "-----+++-----", "----+++++----", "---+++++++---",
                          "--+++++++++--", "-+++++++++++-" } },
          { name      = "rms_pan", variants = { variantDefault },
            litStates = { "+------------", "++-----------", "+++----------", "++++---------", "+++++--------",
                          "++++++-------", "+++++++------", "++++++++-----", "+++++++++----", "++++++++++---",
                          "+++++++++++--", "++++++++++++-", "+++++++++++++", "-++++++++++++", "--+++++++++++",
                          "---++++++++++", "----+++++++++", "-----++++++++", "------+++++++", "-------++++++",
                          "--------+++++", "---------++++", "----------+++", "-----------++", "------------+",
            } }
        }

        local ledsCountLeft      = 7
        local ledsCountRight     = 6
        local ledsCountTotal     = ledsCountLeft + ledsCountRight

        local mirrorLitStates    = function(litStates)
          local mirroredLitStates = {}
          for _, state in ipairs(litStates) do
            local mirrored = ''
            for i = state:len(), 1, -1 do
              mirrored = mirrored .. state:sub(i, i)
            end
            table.insert(mirroredLitStates, mirrored)
          end
          return mirroredLitStates
        end
        local invertLitStates    = function(litStates)
          local invertedLitStates = {}
          for _, state in ipairs(litStates) do
            local inverted = ''
            for i = 1, state:len() do
              inverted = inverted .. (state:sub(i, i) == ledOffCharReadable and ledOnCharReadable or ledOffCharReadable)
            end
            table.insert(invertedLitStates, inverted)
          end
          return invertedLitStates
        end

        local litLedsCategories  = { [categoryFull] = {}, [categoryLeft] = {}, [categoryRight] = {} }

        for _, modeSpecs in ipairs(ledModeSpecs) do
          local fullLitStates     = modeSpecs.litStates
          local fragmentLitStates = {}
          for i = 1, modeSpecs.fragmentStatesCount or 0 do
            table.insert(fragmentLitStates, str.crop(fullLitStates[i], ledsCountRight))
          end

          -- default
          if lst.hasValue(modeSpecs.variants, variantDefault) then
            local fullLitStatesRev = lst.reversed(fullLitStates)
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name, litStates = fullLitStates })
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name .. '_rev', litStates = fullLitStatesRev })

            if modeSpecs.fragmentStatesCount then
              local fragmentLitStatesRev = lst.reversed(fragmentLitStates)
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name, litStates = fragmentLitStates })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name, litStates = mirrorLitStates(fragmentLitStates) })
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name .. '_rev', litStates = fragmentLitStatesRev })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name .. '_rev', litStates = mirrorLitStates(fragmentLitStatesRev) })
            end
          end

          -- mirrored
          if lst.hasValue(modeSpecs.variants, variantMirrored) then
            local fullLitStatesMir    = mirrorLitStates(fullLitStates)
            local fullLitStatesMirRev = mirrorLitStates(lst.reversed(fullLitStates))
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name .. '_mir', litStates = fullLitStatesMir })
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name .. '_mir_rev', litStates = fullLitStatesMirRev })

            if modeSpecs.fragmentStatesCount then
              local fragmentLitStatesMir    = mirrorLitStates(fragmentLitStates)
              local fragmentLitStatesMirRev = mirrorLitStates(lst.reversed(fragmentLitStates))
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name .. '_mir', litStates = fragmentLitStatesMir })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name .. '_mir', litStates = mirrorLitStates(fragmentLitStatesMir) })
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name .. '_mir_rev', litStates = fragmentLitStatesMirRev })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name .. '_mir_rev', litStates = mirrorLitStates(fragmentLitStatesMirRev) })
            end
          end

          -- inverted
          if lst.hasValue(modeSpecs.variants, variantInverted) then
            local fullLitStatesInv    = invertLitStates(fullLitStates)
            local fullLitStatesInvRev = invertLitStates(lst.reversed(fullLitStates))
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name .. '_inv', litStates = fullLitStatesInv })
            table.insert(litLedsCategories[categoryFull], { name = modeSpecs.name .. '_inv_rev', litStates = fullLitStatesInvRev })

            if modeSpecs.fragmentStatesCount then
              local fragmentLitStatesInv    = invertLitStates(fragmentLitStates)
              local fragmentLitStatesInvRev = invertLitStates(lst.reversed(fragmentLitStates))
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name .. '_inv', litStates = fragmentLitStatesInv })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name .. '_inv', litStates = mirrorLitStates(fragmentLitStatesInv) })
              table.insert(litLedsCategories[categoryLeft], { name = modeSpecs.name .. '_inv_rev', litStates = fragmentLitStatesInvRev })
              table.insert(litLedsCategories[categoryRight], { name = modeSpecs.name .. '_inv_rev', litStates = mirrorLitStates(fragmentLitStatesInvRev) })
            end
          end
        end

        local encodeLitStateReadableToValue = function(litStatereadable)
          local litStateBinary = ''
          for i = 1, litStatereadable:len() do
            litStateBinary = litStateBinary .. (litStatereadable:sub(i, i) == ledOffCharReadable and ledOffChar or ledOnChar)
          end
          return tonumber(litStateBinary:reverse(), 2)
        end

        local encoderModes                  = { [categoryFull] = {}, [categoryLeft] = {}, [categoryRight] = {} }

        for category, categorySpecs in pairs(litLedsCategories) do
          for _, categorySpec in ipairs(categorySpecs) do
            local modeValues = {}
            for _, litStateReadable in ipairs(categorySpec.litStates) do

              table.insert(modeValues, category == categoryFull
                and { encodeLitStateReadableToValue(litStateReadable:sub(1, ledsCountLeft)),
                      encodeLitStateReadableToValue(litStateReadable:sub(ledsCountLeft + 1, ledsCountTotal)) }
                or encodeLitStateReadableToValue(litStateReadable))
            end
            table.insert(encoderModes[category], { name = categorySpec.name, values = modeValues })
          end
        end

        XTEncoder.static.modesData = encoderModes
      end
    end
    function XTEncoder.normaliseRemoteValue(remoteValue, maxRemoteValue, modeValuesCount)
      local stepSize = maxRemoteValue / modeValuesCount
      return math.ceil((modeValuesCount - 1) * (remoteValue - stepSize / 2) / maxRemoteValue)
    end
    function XTEncoder.updateLeds(encoderItem)
      local isEnabled = encoderItem:isEnabled()
      local value     = isEnabled and encoderItem:remotableValue() or 0

      if encoderItem.fragment then
        local retValue = 0
        if isEnabled then
          local modeValues      = encoderItem:modeData().values
          local normalisedValue = XTEncoder.normaliseRemoteValue(value, encoderItem.max, #modeValues)
          retValue              = modeValues[normalisedValue + 1]
        end
        midi.addToQueue({ midi.cc, encoderItem.outputAddressByte, retValue })
      else
        local retValueLeft, retValueRight = 0, 0
        if isEnabled then
          local modeValues            = encoderItem:modeData().values
          local normalisedValue       = XTEncoder.normaliseRemoteValue(value, encoderItem.max, #modeValues)
          retValueLeft, retValueRight = unpack(modeValues[normalisedValue + 1])
        end
        midi.addToQueue({ midi.cc, encoderItem.outputAddressByteLeft, retValueLeft })
        midi.addToQueue({ midi.cc, encoderItem.outputAddressByteRight, retValueRight })
      end
    end
    function XTEncoder:getModesData()
      self:initStaticData()
      return XTEncoder.static.modesData.full
    end
    function XTEncoder:initialize(surface, name, options)
      local mixChannel            = fnc.kwarg(options, 'mixChannel', { types = T })

      self.ledsCount              = 13
      self.inputAddressByte       = 16 + mixChannel.channelId
      self.outputAddressByteLeft  = 48 + mixChannel.channelId
      self.outputAddressByteRight = 56 + mixChannel.channelId

      ControlItem.initialize(self, surface, name, {
        min    = 0, max = math.pow(2, self.ledsCount),
        input  = ControlItemInput(self, 'delta', { pattern = midi.pattern(midi.cc, self.inputAddressByte, '<?y??>x'), value = 'x*(1-2*y)' }),
        output = ControlItemOutput(self, 'value', { autoHandle = false }),
      })

      mixChannel:registerItem('encoder', self)
    end
    function XTEncoder:releaseFromUse()
      return {
        { midi.cc, self.outputAddressByteLeft, 0 },
        { midi.cc, self.outputAddressByteRight, 0 }
      }
    end
    function XTEncoder:onChange(timestamp)
      local fragmentsAreEnabled = self.mixChannel.encoderLedLeft:isEnabled() or self.mixChannel.encoderLedRight:isEnabled()
      local ledItemIsEnabled    = self.mixChannel.encoderLed:isEnabled()
      if not fragmentsAreEnabled and not ledItemIsEnabled then
        XTEncoder.updateLeds(self)
      end
    end
  end

  XTEncoderLed = class('XTEncoderLed', ControlItem)
  do
    function XTEncoderLed:getModesData()
      XTEncoder.initStaticData()
      local listName = self.fragment or 'full'
      return XTEncoder.static.modesData[listName]
    end
    function XTEncoderLed:initialize(surface, name, options)
      local mixChannel            = fnc.kwarg(options, 'mixChannel', { types = T })
      self.fragment               = fnc.kwarg(options, 'fragment', { required = false, choices = { 'left', 'right' } })

      self.ledsCount              = self.fragment and 6 or 13
      self.outputAddressByteLeft  = 48 + mixChannel.channelId
      self.outputAddressByteRight = 56 + mixChannel.channelId
      self.outputAddressByte      = self.fragment == 'left' and self.outputAddressByteLeft or self.outputAddressByteRight

      ControlItem.initialize(self, surface, name, {
        min    = 0, max = math.pow(2, self.ledsCount),
        output = ControlItemOutput(self, 'value', { autoHandle = false }),
      })

      local mixChannelKey = 'encoderLed'
      if self.fragment then
        mixChannelKey = mixChannelKey .. (self.fragment == 'left' and 'Left' or 'Right')
      end
      mixChannel:registerItem(mixChannelKey, self)
    end
    function XTEncoderLed:getSibling()
      if self.fragment == nil then return nil end
      return self.fragment == 'left' and self.mixChannel.encoderLedRight or self.mixChannel.encoderLedLeft
    end
    function XTEncoderLed:onChange(timestamp)
      if self.fragment then
        local sibling = self:getSibling()
        if self:isEnabled() or sibling:isEnabled() then
          XTEncoder.updateLeds(self)
          XTEncoder.updateLeds(sibling)
        elseif self.mixChannel.encoderLed:isEnabled() then
          XTEncoder.updateLeds(self.mixChannel.encoderLed)
        else
          XTEncoder.updateLeds(self.mixChannel.encoder)
        end

      else
        if self.mixChannel.encoderLedLeft:isEnabled() or self.mixChannel.encoderLedRight:isEnabled() then
          return
        elseif self:isEnabled() then
          XTEncoder.updateLeds(self)
        else
          XTEncoder.updateLeds(self.mixChannel.encoder)
        end
      end
    end
  end

  XTEncoderClick = class('XTEncoderClick', ControlItem)
  do
    function XTEncoderClick:initialize(surface, name, options)
      local mixChannel = fnc.kwarg(options, 'mixChannel', { types = T })

      ControlItem.initialize(self, surface, name, {
        min   = 0, max = 1,
        input = ControlItemInput(self, 'button', { pattern = midi.pattern(midi.ns, 32 + mixChannel.channelId, "?<???x>") }),
      })

      mixChannel:registerItem('encoderClick', self)
    end
  end

  XTFader = class('XTFader', ControlItem)
  do
    function XTFader:initialize(surface, name, options)
      local mixChannel = fnc.kwarg(options, 'mixChannel', { types = T })

      ControlItem.initialize(self, surface, name, {
        min    = 0, max = 1023,
        input  = ControlItemInput(self, 'value', { pattern = midi.pattern(midi.pb, '<?xxx>', '?yy', mixChannel.channelId),
                                                   value   = 'y*8+x' }),
        output = ControlItemOutput(self, 'value', { pattern = midi.pattern(midi.pb, '<0xxx>', '0yy', mixChannel.channelId),
                                                    x       = 'bit.band(value,7)*enabled',
                                                    y       = 'bit.rshift(value,3)*enabled' }),
      })

      mixChannel:registerItem('fader', self)
    end
    function XTFader:releaseFromUse()
      return { remote.make_midi(self.output.pattern, { x = 0, y = 0 }) }
    end

  end

  XTFaderTouch = class('XTFaderTouch', ControlItem)
  do
    function XTFaderTouch:initialize(surface, name, options)
      local mixChannel = fnc.kwarg(options, 'mixChannel', { types = T })

      ControlItem.initialize(self, surface, name, {
        min   = 0, max = 1,
        input = ControlItemInput(self, 'value', { pattern = midi.pattern(midi.ns, 104 + mixChannel.channelId, '?<???x>') }),
      })

      mixChannel:registerItem('faderTouch', self)
    end
    function XTFaderTouch:handleInput(midi)
      if not self.mixChannel.lite then
        self.mixChannel.scribble:onFaderTouch(midi.x > 0)
      end
      return false, {}
    end
  end

  XTLevelIndicator = class('XTLevelIndicator', ControlItem)
  do
    function XTLevelIndicator:initialize(surface, name, options)
      local mixChannel    = fnc.kwarg(options, 'mixChannel', { types = T })

      self.updateInterval = 60 --ms

      self.value          = 0
      self.lastUpdate     = remote.get_time_ms()

      ControlItem.initialize(self, surface, name, {
        min    = 0, max = 8,
        output = ControlItemOutput(self, 'value', {
          pattern = midi.pattern(midi.ca, str.f('%s<xxxx>', num.toHex(mixChannel.channelId, false)), ''),
          x       = 'enabled*value' }),
      })

      mixChannel:registerItem('levelIndicator', self)
    end
    function XTLevelIndicator:releaseFromUse()
      return { remote.make_midi(self.output.pattern, { x = 0 }) }
    end
    function XTLevelIndicator:tick(timestamp)
      if self.value > 0 then
        if timestamp > (self.lastUpdate + self.updateInterval) then
          self:sendMidi({ x = self.value })
          self.lastUpdate = timestamp
        end
      end
    end
    function XTLevelIndicator:onChange(timestamp)
      self.value      = self:isEnabled() and self:remotableValue() or 0
      self.lastUpdate = timestamp
    end
  end

  XTJogWheel = class('XTJogWheel', ControlItem)
  do
    function XTJogWheel:initialize(surface, name, options)
      local isCloneOf = fnc.kwarg(options, 'isCloneOf', { types = T, required = false })

      ControlItem.initialize(self, surface, name, {
        input = ControlItemInput(self, 'delta', {
          autoHandle = isCloneOf == nil,
          pattern    = midi.pattern(midi.cc, 60, '<?y??>x'),
          value      = 'x-2*x*y'
        }),
      })

      self.isClone = isCloneOf ~= nil
      if self.isClone then
        table.insert(isCloneOf.clones, self)
      else
        self.clones = {}
      end
    end
    function XTJogWheel:handleInput(midi)
      local messages  = {}
      local realValue = midi.x - 2 * midi.x * midi.y

      for _, clone in ipairs(self.clones) do
        table.insert(messages, { item = clone.index, value = realValue })
      end

      if self.surface.scriptState._JRN == 'Remote Base Channel Delta' then
        local availableChannelsRight = self.surface.faderBankManager.availableChannelsRight
        local adjustedValue          = realValue > availableChannelsRight and availableChannelsRight or realValue
        table.insert(messages, { item = self.index, value = adjustedValue })
      else
        table.insert(messages, { item = self.index, value = realValue })
      end

      return true, messages
    end
  end

  XTouch = class('X-Touch', ControlSurface)
  do
    function XTouch:handleSysexEvent(eventValues, eventMeta)
      -- XCTL Handshake
      local handshake = {
        request    = { midi.ss, 0, 32, 50, 88, 84, 0, midi.se },
        response   = { midi.ss, 0, 0, 102, 20, 0, midi.se },
        validation = { midi.ss, 0, 0, 102, 88, 1, 48, 49, 53, 54, 52, 48, 53, 52, 56, 69, 68, midi.se },
      }

      local handled   = false
      if lst.equals(eventValues, handshake.request) then
        midi.addToQueue(handshake.response)
        handled = true
      elseif lst.equals(eventValues, handshake.validation) then
        handled = true
      end
      return handled, {}
    end
    function XTouch:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      self.timeCodeManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      self.scribbleManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
      self.faderBankManager:onItemsChanged(changedItemIndices, updatedScriptStates, timestamp)
    end
    function XTouch:tick(timestamp)
      self.timeCodeManager:tick(timestamp)
      self.scribbleManager:tick(timestamp)

      for _, mixChannel in ipairs(self.mixChannels) do
        mixChannel.levelIndicator:tick(timestamp)
      end
    end
    function XTouch:prepareForUse()
      self.timeCodeManager:startScrollMessage('Hello', { hasPriority = true })
      return {  }
    end
    function XTouch:releaseFromUse()
      midi.clearQueue()
      self.timeCodeManager:startScrollMessage('Bye bye', { hasPriority = true })
      for _, scribble in ipairs(self.scribbleManager.scribbles) do scribble:sendTurnOffMessage() end
      return midi.processQueue()
    end
    function XTouch:setup()
      -- Script Items
      do
        local scriptItemNames = {
          '_S', -- Scope: str
          '_G', -- Group: str
          '_M', -- Modifier: str
          '_EA', -- Encoder Assign: str
          '_CF', -- Channel Focus: <nil> | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 (master)
          '_SRN', -- show Scribbles Remotable Names: 'off' | 'on'
          '_SSR', -- prefer Scribbles Secondary Remotables: 'off' | 'on'
          '_RBC', -- Remote Base Channel: <nil> | int
          '_JRN' -- Jog wheel Remotable Name: str - for cases when remote.get_item_name(index) is buggy
        }
        for _, scriptItemName in ipairs(scriptItemNames) do ScriptItem(self, scriptItemName) end
      end

      -- Fader Bank
      do
        self.faderBankManager = XTFaderBankManager(self)
        for channel = 1, reason.remoteBaseChannelStep do
          local faderBankCheck = XTFaderBankCheck(self, str.f('_FBC %s', channel))
          self.faderBankManager:registerFaderBankCheck(channel, faderBankCheck)
        end
      end

      -- TimeCode
      do
        local timeCodeFragmentsData = {
          { name = 'Assignment', section = { pos = 1, width = 2 }, fragmentType = "assignment" },
          { name = 'Bars', section = { pos = 3, width = 3 }, fragmentType = "scrollMessage" },
          { name = 'Beats', section = { pos = 6, width = 2 }, fragmentType = "scrollMessage" },
          { name = 'Sub Division', section = { pos = 8, width = 2 }, fragmentType = "scrollMessage" },
          { name = 'Ticks', section = { pos = 10, width = 3 }, fragmentType = "scrollMessage" },
        }
        self.timeCodeManager        = XTTimeCodeManager(self)
        for _, fragmentData in ipairs(timeCodeFragmentsData) do
          local fragment = XTTimeCodeFragment(self, str.f("TC: %s", fragmentData.name), { section = fragmentData.section })
          self.timeCodeManager:registerFragment(fragment, fragmentData.fragmentType)
        end
      end

      -- Jog Wheel
      do
        local jogWheel = XTJogWheel(self, 'Jog Wheel')
        for c = 1, 2 do
          XTJogWheel(self, str.f('%s Clone %s', jogWheel.name, c), { isCloneOf = jogWheel })
        end
      end

      -- Main Section Buttons
      do
        local masterSectionButtonsData = {
          -- Main Section
          ["Main"] = { { name = "Flip", options = { addressByte = 50 } } },
          -- Encoder Assign
          ["EA"]   = { { name = "Track", options = { addressByte = 40 } }, { name = "Pan/Surround", options = { addressByte = 42 } },
                       { name = "Eq", options = { addressByte = 44 } }, { name = "Send", options = { addressByte = 41 } },
                       { name = "Plug-In", options = { addressByte = 43 } }, { name = "Inst", options = { addressByte = 45 } } },
          -- Timecode Display
          ["TC"]   = { { name = "Name/Value", options = { addressByte = 52, noOutput = true } },
                       { name = "SMPTE/Beats", options = { addressByte = 53, noOutput = true } },
                       { name = "SMPTE Led", options = { addressByte = 113, noInput = true } },
                       { name = "Beats Led", options = { addressByte = 114, noInput = true } },
                       { name = "Solo Led", options = { addressByte = 115, noInput = true } } },
          -- View
          ["View"] = { { name = "Global View", options = { addressByte = 51 } }, { name = "Midi Tracks", options = { addressByte = 62 } },
                       { name = "Inputs", options = { addressByte = 63 } }, { name = "Audio Tracks", options = { addressByte = 64 } },
                       { name = "Audio Inst", options = { addressByte = 65 } }, { name = "Aux", options = { addressByte = 66 } },
                       { name = "Buses", options = { addressByte = 67 } }, { name = "Outputs", options = { addressByte = 68 } },
                       { name = "User", options = { addressByte = 69 } } },
          -- Function
          ["Func"] = { { name = "F1", options = { addressByte = 54 } }, { name = "F2", options = { addressByte = 55 } },
                       { name = "F3", options = { addressByte = 56 } }, { name = "F4", options = { addressByte = 57 } },
                       { name = "F5", options = { addressByte = 58 } }, { name = "F6", options = { addressByte = 59 } },
                       { name = "F7", options = { addressByte = 60 } }, { name = "F8", options = { addressByte = 61 } } },
          -- Modify
          ["Mod"]  = { { name = "Shift", options = { addressByte = 70 } }, { name = "Option", options = { addressByte = 71 } },
                       { name = "Control", options = { addressByte = 72 } }, { name = "Alt", options = { addressByte = 73 } } },
          -- Automation
          ["Aut"]  = { { name = "Read/Off", options = { addressByte = 74 } }, { name = "Write", options = { addressByte = 75 } },
                       { name = "Trim", options = { addressByte = 76 } }, { name = "Touch", options = { addressByte = 77 } },
                       { name = "Latch", options = { addressByte = 78 } }, { name = "Group", options = { addressByte = 79 } } },
          -- Utility
          ["Util"] = { { name = "Save", options = { addressByte = 80 } }, { name = "Undo", options = { addressByte = 81 } },
                       { name = "Cancel", options = { addressByte = 82 } }, { name = "Enter", options = { addressByte = 83 } } },
          -- Transport
          ["Tr"]   = { { name = "Marker", options = { addressByte = 84 } }, { name = "Nudge", options = { addressByte = 85 } },
                       { name = "Cycle", options = { addressByte = 86 } }, { name = "Drop", options = { addressByte = 87 } },
                       { name = "Replace", options = { addressByte = 88 } }, { name = "Click", options = { addressByte = 89 } },
                       { name = "Solo", options = { addressByte = 90 } }, { name = "Rewind", options = { addressByte = 91 } },
                       { name = "Fast Forward", options = { addressByte = 92 } }, { name = "Stop", options = { addressByte = 93 } },
                       { name = "Play", options = { addressByte = 94 } }, { name = "Record", options = { addressByte = 95 } } },
          -- Page Selection
          ["Page"] = { { name = "FB Left", options = { addressByte = 46 }, faderBank = true },
                       { name = "FB Right", options = { addressByte = 47 }, faderBank = true },
                       { name = "Ch Left", options = { addressByte = 48 }, faderBank = true },
                       { name = "Ch Right", options = { addressByte = 49 }, faderBank = true } },
          -- Navigation
          ["Nav"]  = { { name = "Up", options = { addressByte = 96 } }, { name = "Down", options = { addressByte = 97 } },
                       { name = "Left", options = { addressByte = 98 } }, { name = "Right", options = { addressByte = 99 } },
                       { name = "Zoom", options = { addressByte = 100 } }, { name = "Scrub", options = { addressByte = 101 } } }
        }
        for catName, catButtons in pairs(masterSectionButtonsData) do
          for _, buttonData in ipairs(catButtons) do
            local button = XTButton(self, str.f('%s: %s', catName, buttonData.name), buttonData.options)
            if buttonData.faderBank then
              self.faderBankManager:registerNavigationButton(button)
            end
          end
        end
      end

      -- Mix Channels
      do
        self.scribbleManager           = XTScribbleManager(self)
        self.mixChannels               = {}

        local channelButtonsData       = {
          { key = "record", name = "Record", offset = 0 }, { key = "solo", name = "Solo", offset = 8 },
          { key = "mute", name = "Mute", offset = 16 }, { key = "select", name = "Select", offset = 24 }
        }

        self.mixChannelsCount          = 8
        local mixChannelsCountWithMain = self.mixChannelsCount + 1

        for channelId = 0, (mixChannelsCountWithMain - 1) do
          local channelNr     = channelId + 1
          local isMainChannel = channelNr == mixChannelsCountWithMain

          local mixChannel    = XTMixChannel(self, channelId, { lite = isMainChannel })

          local namePrefix    = isMainChannel and 'Main' or str.f('Ch %s', channelNr)

          XTFader(self, str.f('%s: Fader', namePrefix), { mixChannel = mixChannel })
          XTFaderTouch(self, str.f('%s: Fader Touch', namePrefix), { mixChannel = mixChannel })

          if isMainChannel then break end -- stop here

          XTScribbleHeader(self, str.f('%s: Scribble Header', namePrefix), { mixChannel = mixChannel })
          XTScribbleColor(self, str.f('%s: Scribble Color', namePrefix), { mixChannel = mixChannel })

          XTLevelIndicator(self, str.f('%s: Level Indicator', namePrefix), { mixChannel = mixChannel })

          XTEncoder(self, str.f('%s: Encoder', namePrefix), { mixChannel = mixChannel })
          XTEncoderLed(self, str.f('%s: Encoder Led', namePrefix), { mixChannel = mixChannel })
          XTEncoderLed(self, str.f('%s: Encoder Led Left', namePrefix), { mixChannel = mixChannel, fragment = 'left' })
          XTEncoderLed(self, str.f('%s: Encoder Led Right', namePrefix), { mixChannel = mixChannel, fragment = 'right' })
          XTEncoderClick(self, str.f('%s: Encoder Click', namePrefix), { mixChannel = mixChannel })

          for _, buttonData in ipairs(channelButtonsData) do
            XTButton(self, str.f('%s: %s', namePrefix, buttonData.name), {
              mixChannel        = mixChannel,
              mixChannelKey     = buttonData.key,
              addressByteOffset = buttonData.offset
            })
          end
        end
      end
    end
  end
end
