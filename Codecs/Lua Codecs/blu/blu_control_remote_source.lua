do
  -- class
  do
    initClass = function()
      local middleclass = {
        _VERSION     = 'middleclass v4.1.1',
        _DESCRIPTION = 'Object Orientation for Lua',
        _URL         = 'https://github.com/kikito/middleclass',
        _LICENSE     = [[
    MIT LICENSE

    Copyright (c) 2011 Enrique García Cota

    Permission is hereby granted, free of charge, to any person obtaining a
    copy of this software and associated documentation files (the
    "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish,
    distribute, sublicense, and/or sell copies of the Software, and to
    permit persons to whom the Software is furnished to do so, subject to
    the following conditions:

    The above copyright notice and this permission notice shall be included
    in all copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
    OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
    MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
    CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
    TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
  ]]
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

    typesMap = {
      [NI] = true,
      [B]  = true,
      [N]  = true,
      [S]  = true,
      [T]  = true,
      [F]  = true,
      [TH] = true,
    }

    val      = {
      -- handling and validation of types
      isTypesString = function(types)
        if type(types) == S then
          return typesMap[types] or false
        elseif type(types) == T then
          if #types == 0 then return false end
          for _, t in ipairs(types) do
            if not typesMap[t] then return false end
          end
          return true
        end
        return false
      end,
      ofType        = function(types, value, many)
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
      ofChoice      = function(choices, value, many)
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
      toString      = function(v)
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
      assert          = function(test, options)
        local message  = fnc.kwarg(options, 'message', { types = S, required = false })
        local errLevel = fnc.kwarg(options, 'errLevel', { types = N, default = 3 })
        assert(errLevel > 0, 'fnc.assert - option "errLevel": nil or number(>0) expected')
        if not test then error(err.assert(message), errLevel) end
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
      toHex   = function(n)
        -- returns a base-16 string from a number value (zero-padded with 2 characters)
        return str.f("%02x", fnc.arg(n, { types = N }))
      end,
      round   = function(n, decimals)
        local n_        = fnc.arg(n, { types = N })
        local decimals_ = fnc.arg(decimals, { default = 0 })
        fnc.assert(decimals_ >= 0, { message = '"decimals" must be >= 0' })
        local res = str.f(" %." .. decimals_ .. "f", n_)
        if decimals_ > 0 then res = res:gsub("%.?0+$", "") end
        return tonumber(res)
      end
    }
    str      = {
      -- String manipulation and extractors
      f     = string.format, -- shorthand
      crop  = function(s, length)
        -- returns a string of limited length
        local s_      = fnc.arg(s, { types = S })
        local length_ = fnc.arg(length, { default = 0 })
        fnc.assert(length_ >= 0, { message = '"length" must be >= 0' })
        return s_:sub(1, length_)
      end,
      strip = function(s)
        -- returns a string cleaned from leading and trailing spaces
        local strippedString, _ = fnc.arg(s, { types = S }):gsub('%s+', '')
        return strippedString
      end,
      split = function(s, separator)
        -- returns a list of substring of a string
        local s_         = fnc.arg(s, { types = S })
        local separator_ = fnc.arg(separator, { default = ' ' })
        local subStrings = {}
        for subString in string.gmatch(s_, "([^" .. separator_ .. "]+)") do table.insert(subStrings, subString) end
        return subStrings
      end
    }
    tbl      = {
      -- General table functions
      plot        = function(t, indent, _level)
        -- returns a printable string from a table
        local indent_ = fnc.arg(indent, { default = 2 })
        local level_  = fnc.arg(_level, { default = 0 })
        fnc.assert(indent_ > 0, { message = '"indent" must be >0' })
        fnc.assert(level_ >= 0, { message = '"_level" must be >=0. This is for recursive calls only!' })

        local maxLevel = 6
        if type(t) == T then
          if level_ == maxLevel then
            return str.f('%s (max depth reached!)', val.toString(t))
          end
          local entries = {}
          for k, v in ipairs(t) do
            table.insert(entries, { str.f('[%s]', k), tbl.plot(v, indent_, level_ + 1) })
          end
          for k, v in pairs(t) do if type(k) == S and k ~= 'metatable' then
            if k == 'class' then
              table.insert(entries, { k, v.name })
            else
              table.insert(entries, { k, tbl.plot(v, indent_, level_ + 1) })
            end
          end end
          local results = {}
          for _, entry in ipairs(entries) do
            local k, v = unpack(entry)
            table.insert(results, str.f('%s%s = %s', string.rep(' ', (level_ + 1) * indent_), k, v))
          end
          if #results == 0 then return '{}' end
          return str.f('{\n%s\n%s}',
                       table.concat(results, ',\n'), string.rep(' ', level_ * indent_))
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
        local t_    = fnc.arg(t, { types = T })
        local count = 0
        for k, _ in pairs(t_) do if type(k) == S then count = count + 1 end end
        return count
      end,
      hasKey   = function(t, key)
        -- returns true if a key exists in a table
        local t_   = fnc.arg(t, { types = T })
        local key_ = fnc.arg(key, { types = S })
        for k, _ in pairs(t_) do if type(k) == S then if k == key_ then return true end end end
        return false
      end,
      hasValue = function(t, value)
        -- returns true if a value exists in a table
        local t_     = fnc.arg(t, { types = T })
        local value_ = fnc.arg(value, { types = { B, N, S } })
        for k, v in pairs(t_) do if type(k) == S then if v == value_ then return true end end end
        return false
      end,
      keys     = function(t)
        -- returns a list of all the keys in a table
        local t_   = fnc.arg(t, { types = T })
        local keys = {}
        for k, _ in pairs(t_) do if type(k) == S then table.insert(keys, k) end end
        return keys
      end,
      equals   = function(t1, t2)
        -- returns true if 2 tables have the same keys and values
        local t1_ = fnc.arg(t1, { types = T })
        local t2_ = fnc.arg(t2, { types = T })
        if dct.len(t1_) ~= dct.len(t2_) then return false end
        -- TODO recursive check
        for k, v in pairs(t1_) do if type(k) == S then if t2_[k] ~= v then return false end end end
        return true
      end,
      get      = function(t, key, default)
        -- returns the value of a key from a table
        -- (in contrast to Python, this always falls back to nil, even if the default is not explicitly set)
        local t_    = fnc.arg(t, { types = T })
        local key_  = fnc.arg(key, { types = S })
        local value = t_[key_]
        return value ~= nil and value or default
      end,
      pop      = function(t, key, default)
        -- returns the value of a key from a table and removes it from the table
        -- (in contrast to Python, this always falls back to nil, even if the default is not explicitly set)
        local t_    = fnc.arg(t, { types = T })
        local key_  = fnc.arg(key, { types = S })
        local value = t_[key_]
        t_[key_]    = nil
        return value ~= nil and value or default
      end
    }
    lst      = {
      -- Functions for value-only tables
      -- (in use with tables containing keys, these may return wrong results)
      len       = function(t)
        -- returns the count of entries
        local t_ = fnc.arg(t, { types = T })
        return #t_
      end,
      hasIndex  = function(t, index)
        -- returns true if an index exists in a table
        local t_     = fnc.arg(t, { types = T })
        local index_ = fnc.arg(index, { types = N })
        for i, _ in ipairs(t_) do if i == index_ then return true end end
        return false
      end,
      hasValue  = function(t, value)
        -- returns true if a value exists in a table
        local t_     = fnc.arg(t, { types = T })
        local value_ = fnc.arg(value, { types = { B, N, S } })
        for _, v in ipairs(t_) do if v == value_ then return true end end
        return false
      end,
      reversed  = function(t)
        -- returns a reversed table
        local t_       = fnc.arg(t, { types = T })
        local reversed = {}
        for i = lst.len(t_), 1, -1 do table.insert(reversed, t_[i]) end
        return reversed
      end,
      first     = function(t)
        -- returns the first value of a table
        local t_ = fnc.arg(t, { types = T })
        return t_[1]
      end,
      last      = function(t)
        -- returns the last value of a table
        local t_ = fnc.arg(t, { types = T })
        return t_[#t_]
      end,
      section   = function(t, from, to)
        -- returns a section of a table
        local t_      = fnc.arg(t, { types = T })
        local from_   = fnc.arg(from, { default = 1 })
        local to_     = fnc.arg(to, { default = #t })

        local section = {}
        for i = from_, to_ do table.insert(section, t_[i]) end
        return section
      end,
      indexOf   = function(t, value)
        -- returns the index of a value in a table if it exists, otherwise nil
        local t_     = fnc.arg(t, { types = T })
        local value_ = fnc.arg(value, { types = { B, N, S } })
        for i, v in ipairs(t_) do if v == value_ then return i end end
        return nil
      end,
      equals    = function(t1, t2)
        -- returns true if two Arrays (t1 & t2) are equal
        local t1_ = fnc.arg(t1, { types = T })
        local t2_ = fnc.arg(t2, { types = T })
        if lst.len(t1_) ~= lst.len(t2_) then return false end
        for i, v in ipairs(t1_) do if t2_[i] ~= v then return false end end
        return true
      end,
      intersect = function(t1, t2)
        -- returns a list containing all the elements that appear on both tables
        local t1_ = fnc.arg(t1, { types = T })
        local t2_ = fnc.arg(t2, { types = T })
        if lst.len(t1_) > lst.len(t2_) then t1_, t2_ = t2_, t1_ end
        local intersection = {}
        for _, v in ipairs(t1_) do if lst.hasValue(t2_, v) then table.insert(intersection, v) end end
        return intersection
      end,
      rep       = function(value, n)
        -- returns a new list containing a value n times
        local value_ = fnc.arg(value, { types = { B, N, S, T } })
        local n_     = fnc.arg(n, { types = N })
        fnc.assert(n_ >= 0, { message = '"n" must be >=0' })
        local list = {}
        for _ = 1, n_ do table.insert(list, type(value_) == T and tbl.deepCopy(value_) or value_) end
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
        local t_     = fnc.arg(t, { types = T })
        local key_   = fnc.arg(key, { types = S })
        local values = {}
        for _, ct in ipairs(t_) do table.insert(values, dct.get(ct, key_)) end
        return values
      end,
      find    = function(t, key, value)
        -- returns the child-table and its index by key and value
        -- (returns nil, nil if not existing)
        local t_     = fnc.arg(t, { types = T })
        local key_   = fnc.arg(key, { types = S })
        local value_ = fnc.arg(value, { types = { B, N, S } })
        for i, ct in ipairs(t_) do if ct[key_] == value_ then return ct, i end end
        return nil, nil
      end,
      filter  = function(t, key, value)
        -- returns a list of all child-table matching key and value
        local t_      = fnc.arg(t, { types = T })
        local key_    = fnc.arg(key, { types = S })
        local value_  = fnc.arg(value, { types = { B, N, S } })
        local results = {}
        for _, ct in ipairs(t_) do if ct[key_] == value_ then table.insert(results, ct) end end
        return results
      end,
      exclude = function(t, key, value)
        -- returns a list of all child-table NOT matching key and value
        local t_      = fnc.arg(t, { types = T })
        local key_    = fnc.arg(key, { type = S })
        local value_  = fnc.arg(value, { required = false, types = { B, N, S } })
        local results = {}
        for _, ct in ipairs(t_) do if ct[key_] ~= value_ then table.insert(results, ct) end end
        return results
      end,
    }

    midi     = {
      ne      = 128, -- (80) Note Off (key abbreviated as 'Note End')
      ns      = 144, -- (90) Note On (key abbreviated as 'Note Start')
      pa      = 160, -- (A0) Polyphonic After-touch
      cc      = 176, -- (B0) Control Change
      pc      = 192, -- (C0) Program Change
      ca      = 208, -- (D0) Channel After-touch
      pb      = 224, -- (E0) Pitch Bending
      ss      = 240, -- (F0) SysEx Start
      se      = 247, -- (F7) SysEx End
      pattern = function(typeValue, dataByte1, dataByte2, channel)
        local typeValue_ = fnc.arg(typeValue, { choices = {
          midi.ns, midi.ne, midi.pa, midi.cc, midi.pc, midi.ca, midi.pb } })
        local dataByte1_ = fnc.arg(dataByte1, { types = { N, S } })
        local dataByte2_ = fnc.arg(dataByte2, { types = { N, S } })
        local channel_   = fnc.arg(channel, { types = N, default = 0 })
        fnc.assert(channel_ >= 0 and channel_ <= 15, { message = 'channel may be a number between 0 and 15' })
        local statusByte_ = num.toHex(typeValue_ + channel_)
        dataByte1_        = type(dataByte1_) == N and num.toHex(dataByte1_) or dataByte1_
        dataByte2_        = type(dataByte2_) == N and num.toHex(dataByte2_) or dataByte2_
        return statusByte_ .. dataByte1_ .. dataByte2_
      end
    }

    debugger = function(data)
      -- immediately raises an error with data
      -- the only useful way to debug remote scripts within Reason environment
      local message = data ~= nil and str.f("data = %s", tbl.plot(data)) or nil
      error(err.debug(message), 2)
    end
    pprint   = function(data, prepend)
      -- prints using tbl.plot
      -- handy while debugging with interactive Lua
      local prepend_ = fnc.arg(prepend, { types = S, required = false })
      local plotData = tbl.plot(data)
      if prepend_ then
        print(str.f('%s: %s', prepend_, plotData))
      else
        print(plotData)
      end
    end
  end
