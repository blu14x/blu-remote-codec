--[[
┌──────────────────────────────────────┐
│                                      │
│        << blu Remote Codec >>        │
│               v 1.2.0                │
│                                      │
│                 for:                 │
│          Novation Launchpad          │
│              Livid DS1               │
│                                      │
│  created and tested with Reason v12  │
│                                      │
│             Benjamin Lux             │
│       https://github.com/blu93       │
│                                      │
└──────────────────────────────────────┘
--]]

-- REMOTE EXTENSION FRAMEWORK
do
  -- Class
  do
    --[[
    class.lua (https://github.com/tenry92/class.lua)
    The MIT License (MIT)

    Copyright (c) 2016 Simon "Tenry" Burchert
    ]]

    Class    = {
      instanceOf = function(self, class)
        if type(self) == 'table' then
          local myClass = getmetatable(self).__class

          while myClass ~= class do
            if myClass.super then
              myClass = myClass.super
            else
              return false
            end
          end

          return true
        else
          return false
        end
      end
    }
    local mt = {}
    function mt.__call(func, base)
      local class     = {}
      local mt
      -- local mt = { __index = class }
      class.metatable = {
        -- __index = class
        construct  = function() return setmetatable({}, mt) end,
        -- getters = {},
        -- setters = {},
        __index    = function(self, prop)
          local getter
          -- foobar => getFoobar
          if type(prop) == 'string' then
            getter = 'get' .. prop:upper():sub(1, 1) .. prop:sub(2)
          end

          -- check for getter (e.g. getFoobar) in class + base classes
          if getter and type(class[getter]) == 'function' then
            return class[getter](self)
            -- otherwise just get the attribute (e.g. foobar),
            -- possibly from a base class
          else
            return class[prop]
          end
        end,
        __newindex = function(self, prop, value)
          local setter
          -- foobar => setFoobar
          if type(prop) == 'string' then
            setter = 'set' .. prop:upper():sub(1, 1) .. prop:sub(2)
          end

          -- check for getter (e.g. setFoobar) in class + base classes
          if setter and type(class[setter]) == 'function' then
            return class[setter](self, value)
            -- otherwise rawset the attribute (e.g. foobar) in this instance
          else
            -- class[prop] = value
            rawset(self, prop, value)
          end
        end,
        __class    = class
      }
      mt              = class.metatable -- shorthand

      local function construct(func, ...)
        -- local self = setmetatable(mt.construct(), mt)
        local self = mt.construct(class, ...)

        if class.construct then
          class.construct(self, ...)
        end

        return self
      end

      local function destruct(self)
        local base = self
        while base do
          if type(base) == 'table' and rawget(base, 'destruct') then
            base.destruct(self)
          end

          if base == self then base = class
          else base = base.super end
          -- local mt = getmetatable(base)
          -- if (not mt) or (not mt.__index) then break end
          -- base = mt.__index
        end
      end
      mt.__gc = destruct

      setmetatable(class, { __call = construct, __index = base })

      class.super      = base
      class.instanceOf = Class.instanceOf

      -- if base then
      --   setmetatable(class, { __index = base })
      -- end

      return class
    end
    setmetatable(Class, mt)
  end
  -- Utility
  do
    err          = {
      base             = function(typePrefix, message, level)
        error(str.f('\n%s:\n%s', typePrefix, message), (level or 1) + 1)
      end,
      keyMissing       = function(key, level)
        local errorMessage = str.f('Expected key "%s" in table.', key)
        err.base('Key Missing', errorMessage, (level or 1) + 2)
      end,
      programmingError = function(errorMessage, level)
        err.base('Programming Error', errorMessage, (level or 1) + 2)
      end,
      remoteMapError   = function(errorMessage, level)
        err.base('Remote Map Error', errorMessage, (level or 1) + 2)
      end,
    }
    asrt         = {
      argType = function(val, expectedType, funcName, argName, level)
        if type(expectedType) == 'string' then expectedType = { expectedType } end
        local valType = type(val)
        for _, argType in ipairs(expectedType) do
          if valType == argType then return end
        end
        local errorMessage = str.f('"%s" expected "%s" to be of the type %s, but got %s.',
                                   funcName, argName, table.concat(expectedType, ', '), valType)
        err.base('Wrong Type', errorMessage, (level or 1) + 2)
      end
    }
    num          = {
      fromHex = function(hex)
        -- returns the Base 10 Integer Equivalent of a Base 16 Integer/String (hex)
        asrt.argType(hex, { 'number', 'string' }, 'num.fromHex', 'hex')
        return tonumber(hex, 16)
      end,
      toHex   = function(n)
        -- return the Base 16 String (Zero-padded with 2 Characters) of a Base 10 Integer (num)
        asrt.argType(n, 'number', 'num.toHex', 'n')
        return str.f("%02x", n)
      end,
      round   = function(n, decimals)
        -- round a number (num) to the given (decimals)
        asrt.argType(n, 'number', 'num.round', 'n')
        asrt.argType(decimals, 'number', 'num.round', 'decimals')
        local mul = 10 ^ (decimals or 0)
        return math.floor(n * mul + 0.5) / mul
      end,
    }
    str          = {
      f          = string.format, -- shorthand
      crop       = function(s, len, args)
        -- limit a String (str) to a specific length (len)
        asrt.argType(s, 'string', 'str.crop', 's')
        asrt.argType(len, 'number', 'str.crop', 'len')

        len                  = len >= 0 and len or 0
        args                 = args or {}
        local alignRight     = obj.get(args, 'alignRight', false, false)

        local formattingFlag = alignRight and "" or "-"
        local formatString   = str.f("%%%s%s.%ss", formattingFlag, len, len)
        return str.f(formatString, s)
      end,
      strip      = function(s)
        -- removes leading and trailing spaces of a String (str)
        asrt.argType(s, 'string', 'str.strip', 's')
        return s:match("^%s*(.-)%s*$")
      end,
      split      = function(s, args)
        -- returns an Array of Substrings of a String (str)
        asrt.argType(s, 'string', 'str.split', 's')
        args             = args or {}
        local sep        = obj.get(args, 'sep', false, ' ')
        local substrings = {}
        for sub in string.gmatch(s, "([^" .. sep .. "]+)") do table.insert(substrings, sub) end
        return substrings
      end,
      startsWith = function(s, start)
        return s:sub(1, #start) == start
      end,
      endsWith   = function(s, ending)
        return s:sub(-#ending) == ending
      end
    }
    tbl          = {
      print       = function(t, depth, indent)
        depth        = depth or 2
        indent       = indent or 0
        local output = '\n'
        if type(t) == 'table' then
          for k, v in pairs(t) do
            if k ~= 'metatable' then
              local _k         = type(k) == "number"
                  and '[' .. (k < 999 and str.crop(tostring(k), 3, { alignRight = true }) or k) .. ']'
                  or k
              local formatting = string.rep(' ', depth * indent) .. _k .. ' = '
              if type(v) == 'table' then
                if next(v) == nil then
                  output = output .. formatting .. '{},\n'
                elseif v.__classname then
                  if v.repr then
                    output = output .. formatting .. v:__classname() .. '("' .. v:repr() .. '")\n'
                  else
                    output = output .. formatting .. v:__classname() .. '({' ..
                        tbl.print(_v, depth, indent + 1) .. string.rep(' ', depth * indent) .. '}),\n'
                  end
                else
                  output = output .. formatting .. '{' ..
                      tbl.print(v, depth, indent + 1) .. string.rep(' ', depth * indent) .. '},\n'
                end
              elseif type(v) == 'string' then
                output = output .. formatting .. '"' .. tostring(v) .. '",\n'
              elseif type(v) == 'boolean' then
                output = output .. formatting .. tostring(v) .. ",\n"
              elseif type(v) == "nil" then
                output = output .. formatting .. '<nil>' .. ",\n"
              else
                output = output .. formatting .. tostring(v) .. ",\n"
              end
            end
          end
        end
        return output
      end,
      shallowCopy = function(t)
        -- returns a shallow copy of a Table (t)
        asrt.argType(t, 'table', 'tbl.shallowCopy', 't')
        local copy = {}
        for k, v in pairs(t) do copy[k] = v end
        return copy
      end,
      deepCopy    = function(t)
        -- returns a deep copy of a Table (t)
        asrt.argType(t, 'table', 'tbl.deepCopy', 't')
        local copy = {}
        for k, v in pairs(t) do copy[k] = type(v) == "table" and tbl.deepCopy(v) or v end
        return copy
      end,
    }
    obj          = {
      length   = function(o)
        -- returns the Length of an Object (o)
        asrt.argType(o, 'table', 'obj.length', 'o')
        local count = 0
        for _ in pairs(o) do count = count + 1 end
        return count
      end,
      hasKey   = function(o, key)
        -- check if an Object (o) has a specific Key
        asrt.argType(o, 'table', 'obj.hasKey', 'o')
        asrt.argType(key, { 'string', 'number' }, 'obj.hasKey', 'key')
        for k, _ in pairs(o) do if k == key then return true end end
        return false
      end,
      hasValue = function(o, value)
        -- check if an Object (o) has a specific Value (value)
        asrt.argType(o, 'table', 'obj.hasValue', 'o')
        asrt.argType(value, { 'number', 'string', 'boolean' }, 'obj.hasValue', 'value')
        for _, v in pairs(o) do if v == value then return true end end
        return false
      end,
      keys     = function(o)
        -- returns all keys of an Object (o)
        asrt.argType(o, 'table', 'obj.keys', 'o')
        local keys = {}
        for key, _ in pairs(o) do table.insert(keys, key) end
        return keys
      end,
      equals   = function(o1, o2)
        -- check if two Objects (o1 & o2) are equal
        asrt.argType(o1, 'table', 'obj.equals', 'o1')
        asrt.argType(o2, 'table', 'obj.equals', 'o2')
        if obj.length(o1) ~= obj.length(o2) then return false end
        for k, v in pairs(o1) do if o2[k] ~= v then return false end end
        return true
      end,
      get      = function(o, key, raiseKeyMissing, default)
        -- gets the value of an Object (o) by key
        asrt.argType(o, 'table', 'obj.get', 'o')
        asrt.argType(key, 'string', 'obj.get', 'key')
        asrt.argType(raiseKeyMissing, 'boolean', 'obj.get', 'raiseKeyMissing')

        if obj.hasKey(o, key) then return o[key]
        elseif raiseKeyMissing then err.keyMissing(key) end
        return default
      end,
      pop      = function(o, key, raiseKeyMissing, default)
        -- gets the value of an Object (o) by key and  removes it from the Object
        asrt.argType(o, 'table', 'obj.pop', 'o')
        asrt.argType(key, 'string', 'obj.pop', 'key')
        asrt.argType(raiseKeyMissing, 'boolean', 'obj.pop', 'raiseKeyMissing')

        if obj.hasKey(o, key) then
          local value = o[key]
          o[key]      = nil
          return value
        elseif raiseKeyMissing then err.keyMissing(key) end
        return default
      end
    }
    arr          = {
      length           = function(a)
        -- returns the Length of an Array (a)
        asrt.argType(a, 'table', 'arr.length', 'a')
        local count = 0
        for _ in ipairs(a) do count = count + 1 end
        return count
      end,
      hasIndex         = function(a, index)
        -- check if an Array (a) has a specific index
        asrt.argType(a, 'table', 'arr.hasIndex', 'a')
        asrt.argType(index, 'number', 'arr.hasIndex', 'index')
        for i, _ in ipairs(a) do if i == index then return true end end
        return false
      end,
      hasValue         = function(a, value)
        -- check if an Array (a) has a specific Value (value)
        asrt.argType(a, 'table', 'arr.hasValue', 'a')
        asrt.argType(value, { 'number', 'string', 'boolean' }, 'arr.hasValue', 'value')
        for _, v in ipairs(a) do if v == value then return true end end
        return false
      end,
      reverse          = function(a)
        -- returns a reversed copy of an Array (a)
        asrt.argType(a, 'table', 'arr.reverse', 'a')
        local reversed = {}
        for i = arr.length(a), 1, -1 do table.insert(reversed, a[i]) end
        return reversed
      end,
      last             = function(a)
        -- returns the last value of an Array (a)
        asrt.argType(a, 'table', 'arr.last', 'a')
        return a[arr.length(a)]
      end,
      section          = function(a, from, to)
        -- returns a Section of an Array (tbl) by (from) and (to)
        asrt.argType(a, 'table', 'arr.section', 'a')
        asrt.argType(from, 'number', 'arr.section', 'from')
        asrt.argType(to, 'number', 'arr.section', 'to')
        assert(from <= to)

        local section = {}
        for i = from, to do
          table.insert(section, a[i])
        end
        return section
      end,
      attrValues       = function(a, attr)
        -- takes an Array (a) of Objects and returns each Value of the attribute (attr)
        asrt.argType(a, 'table', 'arr.attrValues', 'a')
        asrt.argType(attr, 'string', 'arr.attrValues', 'key')
        local values = {}
        for i, o in ipairs(a) do values[i] = o[attr] end
        return values
      end,
      indexOfValue     = function(a, value)
        -- returns the Index of a specific Value (v) within an Array (a)
        -- (Note: on multiple appearances, always the first one)
        asrt.argType(a, 'table', 'arr.indexOfValue', 'a')
        asrt.argType(value, { 'number', 'string' }, 'arr.indexOfValue', 'value')
        for i, v in ipairs(a) do if v == value then return i end end
        return nil
      end,
      indexOfAttrValue = function(a, attr, value)
        -- returns the Index of an Object with a specific Attribute (a) : Value (value) within an Array (a)
        -- (Note: on multiple appearances, always the first one)
        asrt.argType(a, 'table', 'arr.indexOfAttrValue', 'a')
        asrt.argType(attr, 'string', 'arr.indexOfAttrValue', 'key')
        asrt.argType(value, { 'number', 'string' }, 'arr.indexOfAttrValue', 'value')
        for i, o in ipairs(a) do if obj.get(o, attr, true) == value then return i end end
      end,
      getByAttrValue   = function(a, attr, value)
        -- returns the an Object with a specific Attribute (a) : Value (value) within an Array (a)
        -- (Note: on multiple appearances, always the first one)
        asrt.argType(a, 'table', 'arr.getByAttrValue', 'a')
        asrt.argType(attr, 'string', 'arr.getByAttrValue', 'key')
        asrt.argType(value, { 'number', 'string' }, 'arr.getByAttrValue', 'value')
        for _, o in ipairs(a) do if obj.get(o, attr, true) == value then return o end end
      end,
      equals           = function(a1, a2)
        -- check if two Arrays (a1 & a2) are equal
        asrt.argType(a1, 'table', 'arr.equals', 'a1')
        asrt.argType(a2, 'table', 'arr.equals', 'a2')
        if arr.length(a1) ~= arr.length(a2) then return false end
        for i, v in ipairs(a1) do if a2[i] ~= v then return false end end
        return true
      end,
      intersects       = function(a1, a2)
        -- returns a Table of Values that appear in both Arrays (a1 & a2)
        asrt.argType(a1, 'table', 'arr.intersects', 'a1')
        asrt.argType(a2, 'table', 'arr.intersects', 'a2')
        local a1n, a2n = tbl.shallowCopy(a1), tbl.shallowCopy(a2)
        if arr.length(a2n) >= arr.length(a1n) then a1n, a2n = a2n, a1n end
        local equal_values = {}
        for _, v in ipairs(a2n) do if arr.hasValue(a1n, v) then table.insert(equal_values, v) end end
        return equal_values
      end,
      init             = function(value, count)
        -- creates and returns an Array of (count) times the (value)
        asrt.argType(value, { 'boolean', 'number', 'string', 'table' }, 'arr.initiate', 'value')
        local initArray = {}
        for _ = 1, count do table.insert(initArray, type(value) == 'table' and tbl.deepCopy(value) or value) end
        return initArray
      end,
    }

    debugger     = function(data)
      local debugMessage = type(data) == "table" and tbl.print(data) or tostring(data)
      err.base('Debugger', debugMessage, 2)
    end
    assertEquals = function(expected, actual)
      if expected ~= actual then
        local _expected    = type(expected) == 'string' and str.f('"%s"', expected) or expected
        local _actual      = type(actual) == 'string' and str.f('"%s"', actual) or actual
        local errorMessage = str.f("expected:  %s\nactual:       %s", _expected, _actual)
        err.base('Assertion Error', errorMessage, 2)
      end
    end
  end
  -- Midi
  do
    midi = {
      -- Midi Specs and Functions
      sysexStart        = 240,
      sysexEnd          = 247,
      noteOff           = 128, -- (80) Note Off
      noteOn            = 144, -- (90) Note On
      polyAftertouch    = 160, -- (A0) Polyphonic Aftertouch
      controlChange     = 176, -- (B0) Control Change
      programChange     = 192, -- (C0) Program Change
      channelAftertouch = 208, -- (D0) Channel Aftertouch
      pitchBend         = 224, -- (E0) Pitch Bending

      getStatusByte     = function(action, channel)
        -- returns the status byte by action type and channel
        local byte_map = {
          n_off = midi.noteOff,
          n_on  = midi.noteOn,
          pa    = midi.polyAftertouch,
          cc    = midi.controlChange,
          pc    = midi.programChange,
          ca    = midi.channelAftertouch,
          pb    = midi.pitchBend,
        }
        return byte_map[action] + channel
      end,
      pattern           = function(action, channel, addressByte, dataByte)
        local _statusByte  = num.toHex(midi.getStatusByte(action, channel))
        local _addressByte = type(addressByte) == "string" and addressByte or num.toHex(addressByte)
        local _dataByte    = type(dataByte) == "string" and dataByte or num.toHex(dataByte)
        return _statusByte .. _addressByte .. _dataByte
      end
    }
  end
  -- Callbacks
  do
    local callbacks = {
      init             = function(manufacturer, model)
        _G["SURFACE"] = getSurface(manufacturer, model)

        remote.define_items(SURFACE:getRemoteItems())
        remote.define_auto_inputs(SURFACE:getRemoteAutoInputs())
        remote.define_auto_outputs(SURFACE:getRemoteAutoOutputs())
      end,
      set_state        = function(changedItems)
        -- Handle individual changed item
        for _, index in ipairs(changedItems) do
          local item = SURFACE.items[index]
          if not VirtualItem.evaluate(item) then
            item:setState()
          end
        end

        -- Collect changed items by group
        local changedItemsPerGroup = {}
        for groupName, groupItems in pairs(SURFACE.itemGroups) do
          changedItemsPerGroup[groupName] = arr.intersects(groupItems, changedItems)
        end

        -- Collect new ScriptItem states
        local newScriptStates = {}
        for _, index in ipairs(SURFACE.itemGroups.ScriptItems) do
          if arr.hasValue(changedItems, index) then
            local internalName            = SURFACE.items[index].internalName
            newScriptStates[internalName] = SURFACE.scriptState[internalName]
          end
        end

        -- Run custom changed_items logic
        SURFACE:setState(changedItems, changedItemsPerGroup, newScriptStates)
      end,
      process_midi     = function(event)
        local _event = {}
        for k, v in pairs(event) do
          -- Fix a bug of remote which causes new events to be instantiated incorrectly.
          if type(k) ~= "number" or k <= event.size then
            _event[k] = v
          end
        end

        local messages, handled = {}, false

        --   SYSEX Events
        if _event[1] == midi.sysexStart and _event[_event.size] == midi.sysexEnd then
          handled = SURFACE:processSysexEvent(_event)

          -- Other Events
        else
          local item, midi = SURFACE:translateMidiEvent(_event)
          if item then
            if item.boundVirtualItem then
              messages, handled = item.boundVirtualItem:processMidi(midi, item)
            else
              messages, handled = item:processMidi(midi)
            end
          end
        end

        -- handle messages
        for _, message in ipairs(messages) do
          message.time_stamp = _event.time_stamp
          remote.handle_input(message)
        end

        return handled
      end,
      deliver_midi     = function(maxbytes, port)
        -- Use Remote's regular call interval of deliver_midi for surface-specific "tick" functions
        SURFACE:tick(remote.get_time_ms())

        -- Return all due midi messages
        return SURFACE:processMidiQueue()
      end,
      on_auto_input    = function(item_index)
        SURFACE.items[item_index]:onAutoInput()
      end,
      --probe                      = function() end,
      --supported_control_surfaces = function() end
      prepare_for_use  = function()
        return SURFACE:prepareForUse()
      end,
      release_from_use = function()
        return SURFACE:releaseFromUse()
      end,
    }

    for name, func in pairs(callbacks) do
      -- Setup global Remote Callback functions ("remote_init" ... )
      _G["remote_" .. name] = func
    end
  end
  -- Control Surface & I/O Elements
  do
    ControlSurface = Class()
    function ControlSurface:__classname() return 'ControlSurface' end
    function ControlSurface:repr() return 'ControlSurface' end
    function ControlSurface:construct()
      self.items       = {}
      self.itemGroups  = {
        ScriptItems  = {},
        VirtualItems = {},
      }
      self.midiQueue   = {}
      self.scriptState = {}
    end
    function ControlSurface:addItem(itemClass, itemKwargs)
      return itemClass(self, itemKwargs)
    end
    function ControlSurface:getItemByName(itemName)
      for _, item in ipairs(self.items) do
        if item.name == itemName then
          return item
        end
      end
      return nil
    end
    function ControlSurface:getRemoteItems()
      local remoteItems = {}
      for _, item in ipairs(self.items) do table.insert(remoteItems, item:getRemoteItem()) end
      return remoteItems
    end
    function ControlSurface:getRemoteAutoInputs()
      local autoInputs = {}
      for _, item in ipairs(self.items) do
        local autoInput = item:getRemoteAutoInput()
        if autoInput then table.insert(autoInputs, autoInput) end
      end
      return autoInputs
    end
    function ControlSurface:getRemoteAutoOutputs()
      local autoOutputs = {}
      for _, item in ipairs(self.items) do
        local autoOutput = item:getRemoteAutoOutput()
        if autoOutput then table.insert(autoOutputs, autoOutput) end
      end
      return autoOutputs
    end
    function ControlSurface:addToMidiQueue(message, kwargs)
      asrt.argType(message, 'table', 'ControlSurface:addToMidiQueue', 'message')

      kwargs                 = kwargs or {}
      local delayMS          = obj.get(kwargs, 'delayMS', false, 0)
      local overridePrevious = obj.get(kwargs, 'overridePrevious', false, false)

      local timeStamp        = remote.get_time_ms() + delayMS
      local indexOfPrevious
      if overridePrevious then
        for i, queueItem in ipairs(self.midiQueue) do
          if arr.equals(queueItem.message, message) then
            indexOfPrevious = i
            break
          end
        end
      end

      if indexOfPrevious then
        self.midiQueue[indexOfPrevious].timeStamp = timeStamp
      else
        local newQueueItem = { message = message, timeStamp = timeStamp }
        table.insert(self.midiQueue, newQueueItem)
      end
    end
    function ControlSurface:processMidiQueue()
      local retEvents        = {}
      local updatedMidiQueue = {}
      for _, queueItem in ipairs(self.midiQueue) do
        if remote.get_time_ms() >= queueItem.timeStamp then
          table.insert(retEvents, queueItem.message)
        else
          table.insert(updatedMidiQueue, queueItem)
        end
      end
      self.midiQueue = updatedMidiQueue
      return retEvents
    end
    function ControlSurface:processSysexEvent(event)
      return {}, false
    end
    function ControlSurface:tick(timestamp)
      return
    end
    function ControlSurface:translateMidiEvent(event)
      -- returns the index of a matching item and the midi values by event
      for _, item in ipairs(self.items) do
        if item.input and item.input.pattern then
          local midi = remote.match_midi(item.input.pattern, event)
          if midi then return item, midi end
        end
      end
      return nil, nil
    end
    function ControlSurface:setState(changedItems, changedItemsPerGroup, newScriptStates)
      return
    end
    function ControlSurface:prepareForUse()
      return {}
    end
    function ControlSurface:releaseFromUse()
      return {}
    end

    MidiInput = Class()
    function MidiInput:__classname() return 'MidiInput' end
    function MidiInput:repr() return self.item.name end
    function MidiInput:construct(item, kwargs)
      asrt.argType(item, 'table', 'MidiInput:construct', 'item')
      asrt.argType(kwargs, 'table', 'MidiInput:construct', 'kwargs')

      self.item        = item
      self.type        = obj.get(kwargs, 'type', true)
      self.auto_handle = obj.get(kwargs, 'auto_handle', false, true)

      self.pattern     = obj.get(kwargs, 'pattern', false)
      self.value       = obj.get(kwargs, 'value', false, 'x')
      self.note        = obj.get(kwargs, 'note', false, 'y')
      self.velocity    = obj.get(kwargs, 'velocity', false, 'z')
      self.port        = obj.get(kwargs, 'port', false)
    end

    MidiOutput = Class()
    function MidiOutput:__classname() return 'MidiOutput' end
    function MidiOutput:repr() return self.item.name end
    function MidiOutput:construct(item, kwargs)
      asrt.argType(item, 'table', 'MidiOutput:construct', 'item')
      asrt.argType(kwargs, 'table', 'MidiOutput:construct', 'kwargs')

      self.item        = item
      self.type        = obj.get(kwargs, 'type', true)
      self.auto_handle = obj.get(kwargs, 'auto_handle', false, true)

      self.pattern     = obj.get(kwargs, 'pattern', false)
      self.x           = obj.get(kwargs, 'x', false, 'value')
      self.y           = obj.get(kwargs, 'y', false, 'mode')
      self.z           = obj.get(kwargs, 'z', false, 'enabled')
      self.port        = obj.get(kwargs, 'port', false)
    end

    SurfaceItem = Class()
    function SurfaceItem:__classname() return 'SurfaceItem' end
    function SurfaceItem:repr() return self.name end
    function SurfaceItem:construct(surface, kwargs)
      asrt.argType(surface, 'table', 'SurfaceItem:construct', 'surface')
      asrt.argType(kwargs, 'table', 'SurfaceItem:construct', 'kwargs')

      self.surface = surface
      table.insert(self.surface.items, self)
      self.index         = arr.length(self.surface.items)

      self.name          = obj.get(kwargs, 'name', true)
      self.min           = obj.get(kwargs, 'min', false)
      self.max           = obj.get(kwargs, 'max', false)
      self.modes         = obj.get(kwargs, 'modes', false, {})
      self.meta          = obj.get(kwargs, 'meta', false, {})

      local inputKwargs  = obj.get(kwargs, 'input', false)
      local outputKwargs = obj.get(kwargs, 'output', false)

      self.input         = inputKwargs and MidiInput(self, inputKwargs) or nil
      self.output        = outputKwargs and MidiOutput(self, outputKwargs) or nil

      self.overrideItems = {}
      self.slaveItems    = obj.get(kwargs, 'slaveItems', false, {})
      for _, item in ipairs(self.slaveItems) do
        table.insert(item.overrideItems, self)
      end

      self.groups = obj.get(kwargs, 'groups', false, {})
      for _, groupName in ipairs(self.groups) do
        if not obj.hasKey(self.surface.itemGroups, groupName) then self.surface.itemGroups[groupName] = {} end
        table.insert(self.surface.itemGroups[groupName], self.index)
      end
    end
    function SurfaceItem:sendMidi(midi, kwargs)
      local message = remote.make_midi(self.output.pattern, midi)
      self.surface:addToMidiQueue(message, kwargs)
    end
    function SurfaceItem:getEnabledInputOverride()
      for _, overrideItem in ipairs(self.overrideItems) do
        if overrideItem:isEnabled() and overrideItem.input then return overrideItem end
      end
      return nil
    end
    function SurfaceItem:getEnabledOutputOverride()
      for _, overrideItem in ipairs(self.overrideItems) do
        if overrideItem:isEnabled() and overrideItem.output then return overrideItem end
      end
      return nil
    end
    function SurfaceItem:getRemoteItem()
      return {
        name   = self.name,
        input  = self.input and self.input.type or 'noinput',
        output = self.output and self.output.type or 'nooutput',
        min    = self.min,
        max    = self.max,
        modes  = self.modes and arr.attrValues(self.modes, "name") or {}
      }
    end
    function SurfaceItem:getRemoteAutoInput()
      return (self.input and self.input.auto_handle) and {
        name     = self.name,
        pattern  = self.input.pattern,
        value    = self.input.value,
        note     = self.input.note,
        velocity = self.input.velocity,
        port     = self.input.port
      } or nil
    end
    function SurfaceItem:getRemoteAutoOutput()
      return (self.output and self.output.auto_handle) and {
        name    = self.name,
        pattern = self.output.pattern,
        x       = self.output.x,
        y       = self.output.y,
        z       = self.output.z,
        port    = self.output.port
      } or nil
    end
    function SurfaceItem:processMidi(midi)
      return {}, false
    end
    function SurfaceItem:setState()
      return
    end
    function SurfaceItem:onAutoInput()
      return
    end
    -- utility wrapper methods
    function SurfaceItem:modeData()
      return #self.modes and self.modes[remote.get_item_mode(self.index)] or nil
    end
    function SurfaceItem:isEnabled()
      return remote.is_item_enabled(self.index)
    end
    function SurfaceItem:remotableName()
      return remote.get_item_name(self.index)
    end
    function SurfaceItem:remotableNameAndValue()
      return remote.get_item_name_and_value(self.index)
    end
    function SurfaceItem:remotableShortName()
      return remote.get_item_short_name(self.index)
    end
    function SurfaceItem:remotableShortNameAndValue()
      return remote.get_item_short_name_and_value(self.index)
    end
    function SurfaceItem:remotableShortestName()
      return remote.get_item_shortest_name(self.index)
    end
    function SurfaceItem:remotableShortestNameAndValue()
      return remote.get_item_shortest_name_and_value(self.index)
    end
    function SurfaceItem:remotableState()
      return remote.get_item_state(self.index)
    end
    function SurfaceItem:remotableTextValue()
      return remote.get_item_text_value(self.index)
    end
    function SurfaceItem:remotableValue()
      return remote.get_item_value(self.index)
    end

    VirtualItem = Class(SurfaceItem)
    function VirtualItem:__classname() return 'VirtualItem' end
    function VirtualItem:repr() return self.name end
    function VirtualItem:construct(surface, kwargs)
      local name  = obj.get(kwargs, 'name', true)
      kwargs.name = '_' .. name
      VirtualItem.super.construct(self, surface, kwargs)
      self.internalName    = name
      self.boundItems      = {}
      self.boundItemValues = {}
    end
    function VirtualItem.bind(item, virtualItemName, value)
      local virtualItem = item.surface:getItemByName(virtualItemName)
      if not virtualItem then
        err.remoteMapError(str.f('VirtualItem of the name "%s" does not exist', virtualItemName))
      end
      local cleanValue                        = tonumber(value) or value
      virtualItem.boundItems[cleanValue]      = item
      virtualItem.boundItemValues[item.index] = cleanValue
      item.boundVirtualItem                   = virtualItem
    end
    function VirtualItem.unbind(item)
      if not item.boundVirtualItem then return end
      local virtualItem                       = item.boundVirtualItem
      local lastBoundValue                    = virtualItem.boundItemValues[item.index]
      virtualItem.boundItems[lastBoundValue]  = nil
      virtualItem.boundItemValues[item.index] = nil
      item.boundVirtualItem                   = nil
    end
    function VirtualItem.evaluate(item)
      -- in the remotemap assign a string eg "bind:_RedrumEditAccent:soft"
      local bindText, virtualItemName, value = unpack(str.split(item:remotableTextValue(), { sep = ':' }))
      if bindText == 'bind' then
        -- for the case where last assignment was a virtual item as well, we unbind it first
        VirtualItem.unbind(item)
        VirtualItem.bind(item, virtualItemName, value)
        return true
      else
        VirtualItem.unbind(item)
        return false
      end
    end

    ScriptItem = Class(SurfaceItem)
    function ScriptItem:__classname() return 'ScriptItem' end
    function ScriptItem:repr() return self.name end
    function ScriptItem:construct(surface, kwargs)
      local name = obj.get(kwargs, 'name', true)
      ScriptItem.super.construct(self, surface, {
        name   = '$' .. name,
        output = { auto_handle = false, type = 'text' },
        groups = { 'ScriptItems' }
      })
      self.internalName                                      = name
      self.surface.scriptState[self.internalName .. '_prev'] = ''
      self.surface.scriptState[self.internalName]            = ''
    end
    function ScriptItem:setState()
      local newValue                                         = self:isEnabled() and self:remotableTextValue() or ''
      self.surface.scriptState[self.internalName .. '_prev'] = self.surface.scriptState[self.internalName]
      self.surface.scriptState[self.internalName]            = newValue
    end
  end
end

getSurface = function(manufacturer, model)
  if model == 'Launchpad' then
    return Launchpad(manufacturer, model)
  elseif model == 'DS1' then
    return DS1(manufacturer, model)
  elseif model == 'X-Touch' then
    return XTouch(manufacturer, model)
  end
end

-- Novation Launchpad (Mk1)
do
  local maxBrightness = 3
  local colorCodes    = {}
  local ledModes      = {}
  local buttonModes   = {}
  for r1 = 0, maxBrightness do
    for g1 = 0, maxBrightness do
      local name1       = r1 .. g1
      local value1      = r1 + 16 * g1
      colorCodes[name1] = value1

      for r2 = 0, maxBrightness do
        for g2 = 0, maxBrightness do
          local name2    = r2 .. g2
          local value2   = r2 + 16 * g2

          local modeName = name1 == name2 and name1 or name1 .. name2
          table.insert(ledModes, { name = modeName, values = { value1, value2 } })
          table.insert(buttonModes, { name = modeName, values = { value1, value2 }, hold = false })
          table.insert(buttonModes, { name = modeName .. 'h', values = { value1, value2 }, hold = true })
        end
      end
    end
  end
  table.insert(ledModes, {
    name   = 'redrumStepOut',
    values = { colorCodes['00'], colorCodes['13'], colorCodes['32'], colorCodes['20'], colorCodes['02'] }
  })

  LPButtonItem = Class(SurfaceItem)
  function LPButtonItem:__classname() return 'LPButtonItem' end
  function LPButtonItem:construct(surface, kwargs)
    local name          = obj.get(kwargs, 'name', true)
    local midiAction    = obj.get(kwargs, 'midiAction', true)
    local addressByte   = obj.get(kwargs, 'addressByte', true)
    local meta          = obj.get(kwargs, 'meta', false, {})

    local inputPattern  = midi.pattern(midiAction, 0, addressByte, '?<???x>')
    local outputPattern = midi.pattern(midiAction, 0, addressByte, 'xx')

    LPButtonItem.super.construct(self, surface, {
      name   = name,
      min    = 0,
      max    = 1,
      modes  = buttonModes,
      meta   = meta,
      input  = {
        type    = 'button',
        pattern = inputPattern
      },
      output = {
        auto_handle = false,
        type        = 'value',
        pattern     = outputPattern,
      }
    })
  end
  function LPButtonItem:processMidi(midi)
    local overrideItem = self:getEnabledInputOverride()
    if overrideItem then
      return overrideItem:processMidi(midi, self)
    else
      local messages, handled = {}, false
      local pressed           = midi.x > 0
      local modeData          = self:modeData()
      if modeData.hold then
        local remotableItemOn = self:remotableValue() > 0
        if pressed == remotableItemOn then
          handled = true
        end
        local holdGroup = self.surface.scriptState.buttonHoldGroup
        if pressed and not arr.hasValue(holdGroup, self.index) then
          table.insert(holdGroup, self.index)
        elseif arr.hasValue(holdGroup, self.index) then
          table.remove(holdGroup, arr.indexOfValue(holdGroup, self.index))
          table.insert(messages, { item = self.index, value = 1 })
        end
      end
      return messages, handled
    end
  end
  function LPButtonItem:setState()
    local overrideItem = self:getEnabledOutputOverride()
    if (not overrideItem or not overrideItem:isEnabled()) and not self.led:isEnabled() then
      local retValue = 0
      if self:isEnabled() then
        local modeValues = self:modeData().values
        if arr.length(modeValues) == 1 then
          retValue = modeValues[1]
        else
          retValue = modeValues[self:remotableValue() + 1]
        end
      end
      self:sendMidi({ x = retValue })
    end
  end

  LPLedItem = Class(SurfaceItem)
  function LPLedItem:__classname() return 'LPLedItem' end
  function LPLedItem:construct(surface, kwargs)
    local button = obj.get(kwargs, 'button', true)

    LPLedItem.super.construct(self, surface, {
      name   = button.name .. ' LED',
      min    = 0,
      max    = 127,
      output = {
        auto_handle = false,
        type        = 'value'
      },
      modes  = ledModes
    })
    self.button = button
    button.led  = self
  end
  function LPLedItem:convertRemoteValue(remoteValue, maxValue)
    return math.floor(remoteValue * maxValue / self.max)
  end
  function LPLedItem:setState()
    if self:isEnabled() then
      local modeValues  = self:modeData().values
      local remoteValue = self:convertRemoteValue(self:remotableValue(), arr.length(modeValues) - 1)
      self.button:sendMidi({ x = modeValues[remoteValue + 1] })
    else
      self.button:setState()
    end
  end

  LPRedrumEditAccentVirtualItem = Class(VirtualItem)
  function LPRedrumEditAccentVirtualItem:__classname() return 'LPRedrumEditAccentVirtualItem' end
  function LPRedrumEditAccentVirtualItem:construct(surface, kwargs)
    LPRedrumEditAccentVirtualItem.super.construct(self, surface, {
      name   = obj.get(kwargs, 'name', true),
      min    = 0,
      max    = 2,
      input  = {
        auto_handle = false,
        type        = 'value'
      },
      output = {
        auto_handle = false,
        type        = 'value',
      },
    })
    self.retValues = { colorCodes['13'], colorCodes['32'], colorCodes['20'] }
    self.pressed   = {
      hard = false,
      soft = false
    }
  end
  function LPRedrumEditAccentVirtualItem:processMidi(midi, sourceItem)
    local pressed            = midi.x > 0
    local boundValue         = self.boundItemValues[sourceItem.index]
    self.pressed[boundValue] = pressed
    local inputValue         = 1 + (self.pressed.hard and 1 or 0) - (self.pressed.soft and 1 or 0)
    return { { item = self.index, value = inputValue } }, true
  end
  function LPRedrumEditAccentVirtualItem:setState()
    if self:isEnabled() then
      local retValue = self.retValues[self:remotableValue() + 1]
      for _, item in pairs(self.boundItems) do
        item:sendMidi({ x = retValue })
      end
    end
  end

  LPRedrumEditStepsVirtualItem = Class(VirtualItem)
  function LPRedrumEditStepsVirtualItem:__classname() return 'LPRedrumEditStepsVirtualItem' end
  function LPRedrumEditStepsVirtualItem:construct(surface, kwargs)
    LPRedrumEditStepsVirtualItem.super.construct(self, surface, {
      name   = obj.get(kwargs, 'name', true),
      min    = 0,
      max    = 3,
      input  = {
        auto_handle = false,
        type        = 'value'
      },
      output = {
        auto_handle = false,
        type        = 'value',
      },
    })
  end
  function LPRedrumEditStepsVirtualItem:processMidi(midi, sourceItem)
    local messages, handled = {}, false
    local pressed           = midi.x > 0
    local inputValue        = self.boundItemValues[sourceItem.index]
    if pressed then
      handled = true
      table.insert(messages, { item = self.index, value = inputValue })
    end
    return messages, handled
  end
  function LPRedrumEditStepsVirtualItem:setState()
    if self:isEnabled() then
      local remoteValue = self:remotableValue()
      for itemValue, item in pairs(self.boundItems) do
        local modeValues = item:modeData().values
        local retValue   = itemValue == remoteValue and modeValues[2] or modeValues[1]
        item:sendMidi({ x = retValue })
      end
    end
  end

  LPRedrumStepPlayingVirtualItem = Class(VirtualItem)
  function LPRedrumStepPlayingVirtualItem:__classname() return 'LPRedrumStepPlayingVirtualItem' end
  function LPRedrumStepPlayingVirtualItem:construct(surface, kwargs)
    LPRedrumStepPlayingVirtualItem.super.construct(self, surface, {
      name   = obj.get(kwargs, 'name', true),
      min    = 0,
      max    = 63,
      output = {
        auto_handle = false,
        type        = 'value',
      },
    })
    self.retValues = { colorCodes['00'], colorCodes['21'], colorCodes['03'], colorCodes['02'], colorCodes['01'] }
  end
  function LPRedrumStepPlayingVirtualItem:setState()
    if self:isEnabled() then
      local remoteValue = self:remotableValue()
      local bar         = math.floor(bit.mod(remoteValue / 16, 4))
      local beat        = math.floor(bit.mod(remoteValue, 16) / 4)
      local sixteenth   = math.floor(bit.mod(remoteValue, 4))
      for itemValue, item in pairs(self.boundItems) do
        local division, index = unpack(str.split(itemValue, { sep = '/' }))
        local value           = tonumber(index)
        local retValue        = self.retValues[1]
        if division == 'bar' then
          retValue = value == bar and self.retValues[2] or self.retValues[1]
        elseif division == 'beat' then
          retValue = value == beat and self.retValues[2 + sixteenth] or self.retValues[1]
        end
        item:sendMidi({ x = retValue })
      end
    end
  end

  local keyboardSetupModes = {
    layout = {
      { name = 'push', rowOffset = 5 },
      { name = 'diatonic', rowOffset = 6 },
      { name = 'diagonal', rowOffset = 7 },
      { name = 'octave', rowOffset = 1 },
    },
    scale  = {
      { name = 'minor', intervals = { 0, 2, 3, 5, 7, 8, 10 } },
      { name = 'major', intervals = { 0, 2, 4, 5, 7, 9, 11 } },
      { name = 'harmonic', intervals = { 0, 2, 3, 5, 7, 8, 11 } },
      { name = 'byzantine', intervals = { 0, 2, 3, 6, 7, 8, 11 } },
      -- special cases
      { name = 'melodic', intervals = { 0, 2, 3, 5, 7, 9, 11 }, downIntervals = { 0, 2, 3, 5, 7, 8, 10 } },
      { name = 'chromatic', intervals = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 } },
    },
    root   = {
      { name = 'a', noteOffset = 0 }, { name = 'a#', noteOffset = 1 }, { name = 'b', noteOffset = 2 },
      { name = 'c', noteOffset = 3 }, { name = 'c#', noteOffset = 4 }, { name = 'd', noteOffset = 5 },
      { name = 'd#', noteOffset = 6 }, { name = 'e', noteOffset = 7 }, { name = 'f', noteOffset = 8 },
      { name = 'f#', noteOffset = 9 }, { name = 'g', noteOffset = 10 }, { name = 'g#', noteOffset = 11 },
    },
    octave = {
      { name = '1', octaveOffset = -4 }, { name = '2', octaveOffset = -3 }, { name = '3', octaveOffset = -2 },
      { name = '4', octaveOffset = -1 }, { name = '5', octaveOffset = 0 }, { name = '6', octaveOffset = 1 },
    }
  }

  LPKeyboardOverrideItem   = Class(SurfaceItem)
  function LPKeyboardOverrideItem:__classname() return 'LPKeyboardOverrideItem' end
  function LPKeyboardOverrideItem:construct(surface, kwargs)
    local name       = obj.get(kwargs, 'name', true)
    local slaveItems = obj.get(kwargs, 'slaveItems', true)

    LPKeyboardOverrideItem.super.construct(self, surface, {
      name       = name,
      min        = 0,
      max        = 1,
      input      = {
        auto_handle = false,
        type        = 'keyboard',
      },
      output     = {
        auto_handle = false,
        type        = 'value',
      },
      modes      = { { name = 'keyboard', values = { colorCodes['00'], colorCodes['21'], colorCodes['03'] } } },
      slaveItems = slaveItems
    })

    self.active       = false
    self.ready        = false
    self.currentModes = {
      layout = arr.getByAttrValue(keyboardSetupModes.layout, 'name', 'push'),
      scale  = arr.getByAttrValue(keyboardSetupModes.scale, 'name', 'minor'),
      root   = arr.getByAttrValue(keyboardSetupModes.root, 'name', 'a'),
      octave = arr.getByAttrValue(keyboardSetupModes.octave, 'name', '3'),
    }

    self:updateGridData()
  end
  function LPKeyboardOverrideItem:updateGridData()
    self.gridData             = {}
    self.lastPlayedNoteId     = 0
    self.lastPlayedNoteWentUp = false
    local scaleLength         = arr.length(self.currentModes.scale.intervals)
    local rowOffset           = self.currentModes.layout.rowOffset
    if self.currentModes.layout.name == 'octave' and self.currentModes.scale.name == 'chromatic' then rowOffset = 0 end

    for _, item in pairs(self.slaveItems) do
      local row, col   = unpack(item.meta.kbCoordinates)
      local noteId     = row * (8 - rowOffset) + col
      item.meta.noteId = noteId
      if not obj.hasKey(self.gridData, noteId) then
        self.gridData[noteId] = {
          octave         = math.floor(noteId / scaleLength),
          intervalIndex  = bit.mod(noteId, scaleLength) + 1,
          buttons        = {},
          buttonsPressed = {},
          notePlayed     = false
        }
      end
      local gridCell = self.gridData[noteId]
      table.insert(gridCell.buttons, item)
      gridCell.buttonsPressed[item.index] = false
    end
  end
  function LPKeyboardOverrideItem:updateKeyboard(newScriptItemStates)
    local newLayout = obj.get(newScriptItemStates, 'KB_Layout', false)
    local newScale  = obj.get(newScriptItemStates, 'KB_Scale', false)
    local newRoot   = obj.get(newScriptItemStates, 'KB_Root', false)
    local newOctave = obj.get(newScriptItemStates, 'KB_Octave', false)

    if newLayout then self.currentModes.layout = arr.getByAttrValue(keyboardSetupModes.layout, 'name', newLayout) end
    if newScale then self.currentModes.scale = arr.getByAttrValue(keyboardSetupModes.scale, 'name', newScale) end
    if newRoot then self.currentModes.root = arr.getByAttrValue(keyboardSetupModes.root, 'name', newRoot) end
    if newOctave then self.currentModes.octave = arr.getByAttrValue(keyboardSetupModes.octave, 'name', newOctave) end

    if newLayout or newScale then self:updateGridData() end

    if self:isEnabled() and not self.active then
      self:activate()
    elseif not self:isEnabled() and self.active then
      self:deactivate()
    end
  end
  function LPKeyboardOverrideItem:activate()
    self.active      = true
    local modeValues = self:modeData().values
    for _, data in pairs(self.gridData) do
      local value = data.intervalIndex == 1 and modeValues[2] or modeValues[1]
      for _, button in pairs(data.buttons) do button:sendMidi({ x = value }) end
    end
    self.ready = true
  end
  function LPKeyboardOverrideItem:deactivate()
    self.active = false
    self.ready  = false
    for _, button in pairs(self.slaveItems) do button:setState() end
  end
  function LPKeyboardOverrideItem:isEnabled()
    return self.surface.scriptState.Scope == 'Master Keyboard' and self.surface.scriptState.Var == 'Keyboard'
  end
  function LPKeyboardOverrideItem:getNoteValue(noteId, gridCell)
    if noteId > self.lastPlayedNoteId then
      self.lastPlayedNoteWentUp = true
    elseif noteId < self.lastPlayedNoteId then
      self.lastPlayedNoteWentUp = false
    end
    self.lastPlayedNoteId = noteId

    local intervals       = {}
    local scale           = self.currentModes.scale
    if obj.hasKey(scale, 'downIntervals') then
      intervals = self.lastPlayedNoteWentUp and scale.intervals or scale.downIntervals
    else
      intervals = scale.intervals
    end

    local baseNoteValue    = 69  -- this is the midi value for A4. nice
    local rootNoteOffset   = self.currentModes.root.noteOffset
    local modeOctaveOffset = 12 * self.currentModes.octave.octaveOffset
    local gridOctaveOffset = 12 * gridCell.octave
    local intervalOffset   = intervals[gridCell.intervalIndex]

    return baseNoteValue + rootNoteOffset + modeOctaveOffset + gridOctaveOffset + intervalOffset
  end
  function LPKeyboardOverrideItem:processMidi(midi, sourceItem)
    local messages, handled                   = {}, false
    local noteId                              = sourceItem.meta.noteId
    local gridCell                            = self.gridData[noteId]
    gridCell.buttonsPressed[sourceItem.index] = midi.x > 0
    local modeValues                          = self:modeData().values
    if not gridCell.notePlayed and obj.hasValue(gridCell.buttonsPressed, true) then
      handled         = true
      local noteValue = self:getNoteValue(noteId, gridCell)
      table.insert(messages, { item = self.index, note = noteValue, value = 1, velocity = 100 })
      gridCell.notePlayed = noteValue
      local onValue       = modeValues[3]
      for _, button in pairs(gridCell.buttons) do
        button:sendMidi({ x = onValue })
      end

    elseif gridCell.notePlayed and not obj.hasValue(gridCell.buttonsPressed, true) then
      handled = true
      table.insert(messages, { item = self.index, note = gridCell.notePlayed, value = 0 })
      gridCell.notePlayed = false
      local offValue      = gridCell.intervalIndex == 1 and modeValues[2] or modeValues[1]
      for _, button in pairs(gridCell.buttons) do
        button:sendMidi({ x = offValue })
      end
    end
    return messages, handled
  end

  Launchpad = Class(ControlSurface)
  function Launchpad:repr() return 'Launchpad' end
  function Launchpad:construct(manufacturer, modes)
    Launchpad.super.construct(self)

    -- setup State
    self.scriptState.buttonHoldGroup = {}

    -- Script Items
    do
      self:addItem(ScriptItem, { name = 'Scope' })
      self:addItem(ScriptItem, { name = 'Var' })
      self:addItem(ScriptItem, { name = 'KB_Layout' })
      self:addItem(ScriptItem, { name = 'KB_Scale' })
      self:addItem(ScriptItem, { name = 'KB_Root' })
      self:addItem(ScriptItem, { name = 'KB_Octave' })
    end

    local function rowChar(row)
      return string.char(string.byte('A') + row - 2)
    end

    local topButtons  = {}
    local gridButtons = {}

    -- Buttons & LEDs
    do
      local maxRows, maxCols = 9, 9
      for row = 1, maxRows do
        for col = 1, maxCols do
          if not (row == 1 and col == maxCols) then
            local midiRow       = row - 1
            local midiCol       = col - 1
            local zone          = row == 1 and 'Top' or col == maxCols and 'Side' or 'Grid'

            local name          = zone == 'Top' and tostring(col) or zone == 'Side' and rowChar(row) or rowChar(row) .. col
            local midiAction    = zone == 'Top' and 'cc' or 'n_on'
            local addressByte   = zone == 'Top' and 104 + midiCol or 16 * (midiRow - 1) + midiCol
            local kbCoordinates = zone == 'Grid' and { maxRows - 1 - midiRow, midiCol } or nil

            local buttonItem    = self:addItem(LPButtonItem, {
              name        = name,
              midiAction  = midiAction,
              addressByte = addressByte,
              meta        = {
                zone          = zone,
                kbCoordinates = kbCoordinates
              },
              groups      = { zone .. 'Buttons' }
            })

            self:addItem(LPLedItem, { button = buttonItem, groups = { zone .. 'Leds' } })

            if zone == 'Top' then
              table.insert(topButtons, buttonItem)
            elseif zone == 'Grid' then
              table.insert(gridButtons, buttonItem)
            end
          end
        end
      end
    end

    self.keyboard = self:addItem(LPKeyboardOverrideItem, { name = 'Keyboard', slaveItems = gridButtons })
    self:addItem(LPRedrumEditAccentVirtualItem, { name = 'RedrumEditAccent' })
    self:addItem(LPRedrumEditStepsVirtualItem, { name = 'RedrumEditSteps' })
    self:addItem(LPRedrumStepPlayingVirtualItem, { name = 'RedrumStepPlaying' })

  end
  function Launchpad:setState(changedItems, changedItemsPerGroup, newScriptStates)
    self.keyboard:updateKeyboard(newScriptStates)
  end
  function Launchpad:prepareForUse()
    return { { 176, 0, 1 } }
  end
  function Launchpad:releaseFromUse()
    return { { 176, 0, 0 } }
  end
end

-- Livid DS1
do
  local ledModes    = {}
  local colorValues = { o = 0, w = 1, c = 4, p = 8, r = 16, b = 32, y = 64, g = 127 }
  for color1, value1 in pairs(colorValues) do
    for color2, value2 in pairs(colorValues) do
      local modeName = color1 == color2 and color1 or color1 .. color2
      table.insert(ledModes, { name = modeName, values = { value1, value2 } })
    end
  end

  DS1ButtonItem = Class(SurfaceItem)
  function DS1ButtonItem:__classname() return 'DS1ButtonItem' end
  function DS1ButtonItem:construct(surface, kwargs)
    local name        = obj.get(kwargs, 'name', true)
    local addressByte = obj.get(kwargs, 'addressByte', true)
    local groups      = obj.get(kwargs, 'groups', false, {})

    DS1ButtonItem.super.construct(self, surface, {
      name   = name,
      min    = 0,
      max    = 1,
      modes  = ledModes,
      input  = {
        type    = 'button',
        pattern = midi.pattern('n_on', 0, addressByte, '<?x??>?')
      },
      output = {
        auto_handle = false,
        type        = 'value',
        pattern     = midi.pattern('n_on', 0, addressByte, 'xx'),
      },
      groups = groups
    })
  end
  function DS1ButtonItem:processMidi(midi)
    local overrideItem = self:getEnabledInputOverride()
    if overrideItem then
      return overrideItem:processMidi(midi, self)
    else
      local messages, handled = {}, false
      local pressed           = midi.x > 0
      local modeData          = self:modeData()
      if modeData.hold then
        local remotableItemOn = self:remotableValue() > 0
        if pressed == remotableItemOn then
          handled = true
        end
        local holdGroup = self.surface.scriptState.buttonHoldGroup
        if pressed and not arr.hasValue(holdGroup, self.index) then
          table.insert(holdGroup, self.index)
        elseif arr.hasValue(holdGroup, self.index) then
          table.remove(holdGroup, arr.indexOfValue(holdGroup, self.index))
          table.insert(messages, { item = self.index, value = 1 })
        end
      end
      return messages, handled
    end
  end
  function DS1ButtonItem:setState()
    local retValue = 0
    if self:isEnabled() then
      local modeValues = self:modeData().values
      retValue         = modeValues[self:remotableValue() + 1]
    end
    self:sendMidi({ x = retValue })
  end

  DS1 = Class(ControlSurface)
  function DS1:repr() return 'DS1' end
  function DS1:construct(manufacturer, model)
    DS1.super.construct(self)

    -- Channels 1 - 8
    local channelCount       = 8
    local rotariesPerChannel = 5
    local buttonsPerChannel  = 2
    for channelNr = 1, channelCount do
      local itemNamePrefix = str.f('Ch %s: ', channelNr)
      local channelId      = channelNr - 1

      -- Fader
      self:addItem(SurfaceItem, {
        name = itemNamePrefix .. 'Fader', min = 0, max = 127, input = {
          type    = 'value',
          pattern = midi.pattern('cc', 0, num.fromHex('29') + channelId, 'xx')
        } })

      -- Rotaries
      for rotaryNr = 1, rotariesPerChannel do
        self:addItem(SurfaceItem, {
          name = itemNamePrefix .. 'R' .. rotaryNr, min = 0, max = 127, input = {
            type    = 'value',
            pattern = midi.pattern('cc', 0, channelId * rotariesPerChannel + rotaryNr, 'xx')
          } })
      end

      -- Buttons
      for buttonNr = 1, buttonsPerChannel do
        local buttonId = buttonNr - 1
        self:addItem(DS1ButtonItem, {
          name        = itemNamePrefix .. 'B' .. buttonNr,
          addressByte = channelId * buttonsPerChannel + buttonId,
          groups      = { 'Buttons' }
        })
      end
    end

    -- Main section
    local rotariesMainSection   = 4
    local buttonRowsMainSection = 3
    local buttonColsMainSection = 3
    local encodersMainSection   = 4
    do
      local itemNamePrefix = 'Main: '
      local mainChannelNr  = channelCount + 1
      local channelId      = mainChannelNr - 1

      -- Fader
      self:addItem(SurfaceItem, {
        name = itemNamePrefix .. 'Fader', min = 0, max = 127, input = {
          type    = 'value',
          pattern = midi.pattern('cc', 0, num.fromHex('29') + channelId, 'xx')
        } })

      -- Rotaries
      for rotaryNr = 1, rotariesMainSection do
        self:addItem(SurfaceItem, {
          name = itemNamePrefix .. 'R' .. rotaryNr, min = 0, max = 127, input = {
            type    = 'value',
            pattern = midi.pattern('cc', 0, num.fromHex('31') + rotaryNr, 'xx')
          } })
      end

      -- Buttons
      for rowNr = 1, buttonRowsMainSection do
        local rowId = rowNr - 1
        for colNr = 1, buttonColsMainSection do
          local colId = colNr - 1
          self:addItem(DS1ButtonItem, {
            name        = itemNamePrefix .. 'B' .. rowId * buttonColsMainSection + colNr,
            addressByte = num.fromHex('10') + rowId + buttonColsMainSection * colId,
            groups      = { 'Buttons' }
          })
        end
      end

      -- Buttons
      for encoderNr = 1, encodersMainSection do
        local encoderId = encoderNr - 1
        self:addItem(SurfaceItem, {
          name = itemNamePrefix .. 'E' .. encoderNr, input = {
            type    = 'delta',
            pattern = midi.pattern('cc', 0, num.fromHex('60') + encoderId, '?<??x?>'),
            value   = '2*x-1'
          } })
      end
    end

  end
  function DS1:releaseFromUse()
    local turnOffEvents = {}
    for _, index in ipairs(self.itemGroups.Buttons) do
      table.insert(turnOffEvents, remote.make_midi(self.items[index].output.pattern, { x = 0 }))
    end
    return turnOffEvents
  end
end

-- Behringer X-Touch
do
  local encoderLedModeData     = {
    { name      = "dot",
      abstracts = { "x............", ".x...........", "..x..........", "...x.........", "....x........",
                    ".....x.......", "......x......", ".......x.....", "........x....", ".........x...",
                    "..........x..", "...........x.", "............x" } },
    { name      = "dotb",
      abstracts = { "x............", "xx...........", ".x...........", ".xx..........", "..x..........",
                    "..xx.........", "...x.........", "...xx........", "....x........", "....xx.......",
                    ".....x.......", ".....xx......", "......x......", "......xx.....", ".......x.....",
                    ".......xx....", "........x....", "........xx...", ".........x...", ".........xx..",
                    "..........x..", "..........xx.", "...........x.", "...........xx", "............x" } },
    { name      = "fill",
      abstracts = { "x............", "xx...........", "xxx..........", "xxxx.........", "xxxxx........",
                    "xxxxxx.......", "xxxxxxx......", "xxxxxxxx.....", "xxxxxxxxx....", "xxxxxxxxxx...",
                    "xxxxxxxxxxx..", "xxxxxxxxxxxx.", "xxxxxxxxxxxxx" } },
    { name      = "bip",
      abstracts = { "xxxxxxx......", ".xxxxxx......", "..xxxxx......", "...xxxx......", "....xxx......",
                    ".....xx......", "......x......", "......xx.....", "......xxx....", "......xxxx...",
                    "......xxxxx..", "......xxxxxx.", "......xxxxxxx" } },
    { name      = "pan",
      abstracts = { "xxxxxx.......", "xxxxxxx......", "xxxxxxxx.....", "xxxxxxxxx....", "xxxxxxxxxx...",
                    "xxxxxxxxxxx..", ".xxxxxxxxxxx.", "..xxxxxxxxxxx", "...xxxxxxxxxx", "....xxxxxxxxx",
                    ".....xxxxxxxx", "......xxxxxxx", ".......xxxxxx" } },
    { name      = "pani",
      abstracts = { "......xxxxxxx", ".......xxxxxx", "........xxxxx", ".........xxxx", "..........xxx",
                    "...........xx", "x...........x", "xx...........", "xxx..........", "xxxx.........",
                    "xxxxx........", "xxxxxx.......", "xxxxxxx......" } },
    { name      = "panf",
      abstracts = { "x............", "xx...........", "xxx..........", "xxxx.........", "xxxxx........",
                    "xxxxxx.......", "xxxxxxx......", "xxxxxxxx.....", "xxxxxxxxx....", "xxxxxxxxxx...",
                    "xxxxxxxxxxx..", "xxxxxxxxxxxx.", "xxxxxxxxxxxxx", ".xxxxxxxxxxxx", "..xxxxxxxxxxx",
                    "...xxxxxxxxxx", "....xxxxxxxxx", ".....xxxxxxxx", "......xxxxxxx", ".......xxxxxx",
                    "........xxxxx", ".........xxxx", "..........xxx", "...........xx", "............x" } },
    { name      = "spread",
      abstracts = { "......x......", ".....x.x.....", "....x...x....", "...x.....x...", "..x.......x..",
                    ".x.........x.", "x...........x" } },
    { name      = "spreadb",
      abstracts = { "......x......", ".....xxx.....", ".....x.x.....", "....xx.xx....", "....x...x....",
                    "...xx...xx...", "...x.....x...", "..xx.....xx..", "..x.......x..", ".xx.......xx.",
                    ".x.........x.", "xx.........xx", "x...........x" } },
    { name      = "spreadf",
      abstracts = { "......x......", ".....xxx.....", "....xxxxx....", "...xxxxxxx...", "..xxxxxxxxx..",
                    ".xxxxxxxxxxx.", "xxxxxxxxxxxxx" } },

  }
  local encoderLedSideModeData = {
    { name      = "dot",
      abstracts = { "x.....", ".x....", "..x...", "...x..", "....x.", ".....x" } },
    { name      = "rms_gtcmp",
      abstracts = { "......", "x.....", ".x....", "..x...", "...x..", "....x." } },
    { name      = "dotb",
      abstracts = { "x.....", "xx....", ".x....", ".xx...", "..x...", "..xx..",
                    "...x..", "...xx.", "....x.", "....xx", ".....x" } },
    { name      = "fill",
      abstracts = { "x.....", "xx....", "xxx...", "xxxx..", "xxxxx.", "xxxxxx" } },
  }

  local function valueFromAbstract(abstract)
    return tonumber(abstract:gsub('x', '1'):gsub('%.', '0'):reverse(), 2)
  end

  local encoderModes = {}
  for _, data in pairs(encoderLedModeData) do
    local values = {}
    for i, abstract in pairs(data.abstracts) do
      local valueLeft  = valueFromAbstract(abstract:sub(1, 7))
      local valueRight = valueFromAbstract(abstract:sub(8, 13))
      table.insert(values, { valueLeft, valueRight })
    end
    table.insert(encoderModes, { name = data.name, values = values })
  end
  --debugger(encoderModes)

  XTouch = Class(ControlSurface)
  function XTouch:repr() return 'XTouch' end
  function XTouch:processSysexEvent(event)
    -- XCTL Handshake
    local eventValues = {}
    for k, v in pairs(event) do
      if type(k) == "number" then
        eventValues[k] = v
      end
    end
    local handshake = {
      request    = { midi.sysexStart, 0, 32, 50, 88, 84, 0, midi.sysexEnd },
      response   = { midi.sysexStart, 0, 0, 102, 20, 0, midi.sysexEnd },
      validation = { midi.sysexStart, 0, 0, 102, 88, 1, 48, 49, 53, 54, 52, 48, 53, 52, 56, 69, 68, midi.sysexEnd },
    }
    if arr.equals(eventValues, handshake.request) then
      self:addToMidiQueue(handshake.response)
      return true
    elseif arr.equals(eventValues, handshake.validation) then
      return true
    end
    return false
  end
end
