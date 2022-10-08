--[[
┌──────────────────────────────────────┐
│                                      │
│        << blu Remote Codec >>        │
│               v 1.2.0                │
│                                      │
│                 for:                 │
│          Novation Launchpad          │
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
  --Remote Extension Framework v1.0.1

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
  -- UTIL
  do
    err          = {
      base       = function(typePrefix, message, level)
        error(string.format('\n%s:\n%s', typePrefix, message), (level or 1) + 1)
      end,
      keyMissing = function(key, level)
        local errorMessage = string.format('Expected key "%s" in table.', key)
        err.base('Key Missing', errorMessage, (level or 1) + 2)
      end,
    }
    asrt         = {
      argType = function(val, expectedType, funcName, argName, level)
        if type(expectedType) == 'string' then expectedType = { expectedType } end
        local valType = type(val)
        for _, argType in ipairs(expectedType) do
          if valType == argType then return end
        end
        local errorMessage = string.format('"%s" expected "%s" to be of the type %s, but got %s.',
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
        return string.format("%02x", n)
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
      crop  = function(s, len, args)
        -- limit a String (str) to a specific length (len)
        asrt.argType(s, 'string', 'str.crop', 's')
        asrt.argType(len, 'number', 'str.crop', 'len')

        len                  = len >= 0 and len or 0
        args                 = args or {}
        local alignRight     = obj.get(args, 'alignRight', false, false)

        local formattingFlag = alignRight and "" or "-"
        local formatString   = string.format("%%%s%s.%ss", formattingFlag, len, len)
        return string.format(formatString, s)
      end,
      strip = function(s)
        -- removes leading and trailing spaces of a String (str)
        asrt.argType(s, 'string', 'str.strip', 's')
        return s:match("^%s*(.-)%s*$")
      end,
      split = function(s, args)
        -- returns an Array of Substrings of a String (str)
        asrt.argType(s, 'string', 'str.split', 's')
        args             = args or {}
        local sep        = obj.get(args, 'sep', false, ' ')
        local substrings = {}
        for sub in string.gmatch(s, "([^" .. sep .. "]+)") do table.insert(substrings, sub) end
        return substrings
      end,
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
        local _expected    = type(expected) == 'string' and string.format('"%s"', expected) or expected
        local _actual      = type(actual) == 'string' and string.format('"%s"', actual) or actual
        local errorMessage = string.format("expected:  %s\nactual:       %s", _expected, _actual)
        err.base('Assertion Error', errorMessage, 2)
      end
    end
  end
  -- MIDI
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
      pattern           = function(action, channel, databyte1, databyte2)
        -- returns a pattern string for midi input and output definitions
        local pattern = num.toHex(midi.getStatusByte(action, channel))
        for _, databyte in ipairs({ databyte1, databyte2 }) do
          local parsed_byte = type(databyte) == "number" and num.toHex(databyte) or databyte
          pattern           = pattern .. parsed_byte
        end
        return pattern
      end
    }
  end
  -- CODEC
  do
    codec = {
      midiQueue        = {},
      const            = {
        remoteBaseChannelStep = 8
      },
      now              = function()
        return remote.get_time_ms()
      end,
      sendMidi         = function(args)
        -- adds a midi message to the midi queue
        local message          = obj.get(args, 'message', true)
        local delayMS          = obj.get(args, 'delayMS', false, 0)
        local overridePrevious = obj.get(args, 'overridePrevious', false, false)

        local timeStamp        = codec.now() + delayMS
        local indexOfPrevious
        if overridePrevious then
          for i, queueItem in ipairs(codec.midiQueue) do
            if arr.equals(queueItem.message, message) then
              indexOfPrevious = i
              break
            end
          end
        end

        if indexOfPrevious then
          codec.midiQueue[indexOfPrevious].timeStamp = timeStamp
        else
          local newQueueItem = { message = message, timeStamp = timeStamp }
          table.insert(codec.midiQueue, newQueueItem)
        end
      end,
      processMidiQueue = function()
        -- returns all midi messages which are due to be delivered & removes them from the queue
        local retEvents        = {}
        local updatedMidiQueue = {}
        for _, queueItem in ipairs(codec.midiQueue) do
          if codec.now() >= queueItem.timeStamp then
            table.insert(retEvents, queueItem.message)
          else
            table.insert(updatedMidiQueue, queueItem)
          end
        end
        codec.midiQueue = updatedMidiQueue
        return retEvents
      end
    }
  end
  -- CALLBACKS
  do
    local callbacks = {
      init         = function(manufacturer, model)
        _G["SURFACE"] = getSurface(manufacturer, model)

        remote.define_items(SURFACE:getRemoteItems())
        remote.define_auto_inputs(SURFACE:getRemoteAutoInputs())
        remote.define_auto_outputs(SURFACE:getRemoteAutoOutputs())
      end,
      set_state    = function(changedItems)
        -- Handle individual changed item
        for _, index in ipairs(changedItems) do
          local item = SURFACE.items[index]
          if item.handleOutput then item:handleOutput() end
        end

        -- Collect changed items by group
        local changedGroupItems = {}
        for groupName, groupItems in pairs(SURFACE.itemGroups) do
          changedGroupItems[groupName] = arr.intersects(groupItems, changedItems)
        end

        -- Collect new ScriptItem states
        local newScriptItemStates = {}
        for _, index in ipairs(SURFACE.itemGroups.ScriptItems) do
          if arr.hasValue(changedItems, index) then
            local scriptItemName                = SURFACE.items[index].name
            newScriptItemStates[scriptItemName] = SURFACE.state[scriptItemName]
          end
        end

        -- Run custom changed_items logic
        if SURFACE.handleChangedItems then
          SURFACE:handleChangedItems(changedItems, changedGroupItems, newScriptItemStates)
        end
      end,
      process_midi = function(_event)
        local event = {}
        for k, v in pairs(_event) do
          -- Fix Remote bug which causes new events to be instantiated incorrectly.
          if type(k) ~= "number" or k <= _event.size then
            event[k] = v
          end
        end

        --   SYSEX Events
        if event[1] == midi.sysexStart and event[event.size] == midi.sysexEnd then
          return SURFACE:handleSysexEvent(event)

          -- Other Events
        else
          local index, midi = SURFACE:translateMidiEvent(event)
          if index then
            local item = SURFACE.items[index]
            if item.handleInput then
              local messages, handled = item:handleInput(midi)
              for _, message in ipairs(messages) do
                remote.handle_input({
                                      time_stamp = event.time_stamp,
                                      item       = message.item,
                                      value      = message.value,
                                      note       = message.note,
                                      velocity   = message.velocity
                                    })
              end
              return handled
            end
          end
        end
      end,
      deliver_midi = function(maxbytes, port)
        -- Use Remote's regular call interval of deliver_midi for surface-specific "tick" functions
        if SURFACE.tick then SURFACE:tick(codec.now()) end

        -- Return all due midi messages
        return codec.processMidiQueue()
      end,
      --on_auto_input              = function() end,
      --prepare_for_use            = function() end,
      --probe                      = function() end,
      --release_from_use           = function() end,
      --supported_control_surfaces = function() end
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
    function ControlSurface:construct()
      self.items      = {}
      self.itemGroups = {}
      self.state      = {}
    end
    function ControlSurface:addItem(args)
      local item   = obj.get(args, 'item', true)
      local groups = obj.get(args, 'groups', false, {})

      if item.index then
        local errorMessage = string.format('The Item "%s" was already added to the Surface', item.name)
        err.base('Item Already Added', errorMessage)
      end

      table.insert(self.items, item)
      item.index   = arr.length(self.items)
      item.surface = self
      item.groups  = groups

      for _, groupName in ipairs(groups) do
        if not obj.hasKey(self.itemGroups, groupName) then
          self.itemGroups[groupName] = {}
        end
        table.insert(self.itemGroups[groupName], item.index)
      end
    end
    function ControlSurface:addScriptItem(name)
      local scriptItem = ScriptItem { name = name }
      self:addItem { item = scriptItem, groups = { 'ScriptItems' } }
      self.state[scriptItem.name .. '_prev'] = ''
      self.state[scriptItem.name]            = ''
    end
    function ControlSurface:repr() return 'ControlSurface' end
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
      for _, item in ipairs(self.items) do
        table.insert(remoteItems, item:getRemoteItem())
      end
      return remoteItems
    end
    function ControlSurface:getRemoteAutoInputs()
      local autoInputs = {}
      for _, item in ipairs(self.items) do
        local autoInput = item:getRemoteAutoInput()
        if autoInput then
          table.insert(autoInputs, autoInput)
        end
      end
      return autoInputs
    end
    function ControlSurface:getRemoteAutoOutputs()
      local autoOutputs = {}
      for _, item in ipairs(self.items) do
        local autoOutput = item:getRemoteAutoOutput()
        if autoOutput then
          table.insert(autoOutputs, autoOutput)
        end
      end
      return autoOutputs
    end
    function ControlSurface:handleSysexEvent(event)
      return false
    end
    function ControlSurface:tick(timestamp)
      return
    end
    function ControlSurface:translateMidiEvent(event)
      -- returns the index of a matching item and the midi values by event
      for index, item in ipairs(self.items) do
        if item.input and item.input.pattern then
          local midi = remote.match_midi(item.input.pattern, event)
          if midi then
            return index, midi
          end
        end
      end
      return nil, nil
    end

    MidiInput = Class()
    function MidiInput:__classname() return 'MidiInput' end
    function MidiInput:repr() return self.item.name end
    function MidiInput:construct(args)
      self.item        = obj.get(args, 'item', true)
      self.type        = obj.get(args, 'type', true)
      self.auto_handle = obj.get(args, 'auto_handle', false, true)

      self.pattern     = obj.get(args, 'pattern', false)
      self.value       = obj.get(args, 'value', false, 'x')
      self.note        = obj.get(args, 'note', false, 'y')
      self.velocity    = obj.get(args, 'velocity', false, 'z')
      self.port        = obj.get(args, 'port', false)
    end

    MidiOutput = Class()
    function MidiOutput:__classname() return 'MidiOutput' end
    function MidiOutput:repr() return self.item.name end
    function MidiOutput:construct(args)
      self.item        = obj.get(args, 'item', true)
      self.type        = obj.get(args, 'type', true)
      self.auto_handle = obj.get(args, 'auto_handle', false, true)

      self.pattern     = obj.get(args, 'pattern', false)
      self.x           = obj.get(args, 'x', false, 'value')
      self.y           = obj.get(args, 'y', false, 'mode')
      self.z           = obj.get(args, 'z', false, 'enabled')
      self.port        = obj.get(args, 'port', false)
    end

    SurfaceItem = Class()
    function SurfaceItem:__classname() return 'SurfaceItem' end
    function SurfaceItem:repr() return self.name end
    function SurfaceItem:construct(args)
      local inputArgs  = obj.get(args, 'input', false)
      local outputArgs = obj.get(args, 'output', false)
      if inputArgs then inputArgs['item'] = self end
      if outputArgs then outputArgs['item'] = self end

      self.name          = obj.get(args, 'name', true)
      self.min           = obj.get(args, 'min', false)
      self.max           = obj.get(args, 'max', false)
      self.modes         = obj.get(args, 'modes', false, {})
      self.meta          = obj.get(args, 'meta', false, {})

      self.input         = inputArgs and MidiInput(inputArgs) or nil
      self.output        = outputArgs and MidiOutput(outputArgs) or nil

      self.overrideItems = {}
      self.slaveItems    = obj.get(args, 'slaveItems', false, {})

      for _, item in ipairs(self.slaveItems) do
        table.insert(item.overrideItems, self)
      end
    end
    function SurfaceItem:enabledInputOverride()
      for _, overrideItem in ipairs(self.overrideItems) do
        if overrideItem.handleInput and overrideItem:isEnabled() then return overrideItem end
      end
      return nil
    end
    function SurfaceItem:enabledOutputOverride()
      for _, overrideItem in ipairs(self.overrideItems) do
        if overrideItem.handleOutput and overrideItem:isEnabled() then return overrideItem end
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
    function SurfaceItem:getModeData()
      return self.modes and self.modes[remote.get_item_mode(self.index)] or nil
    end
    function SurfaceItem:isEnabled()
      return remote.is_item_enabled(self.index)
    end
    function SurfaceItem:handleInput()
      return {}, false
    end

    ScriptItem = Class(SurfaceItem)
    function ScriptItem:__classname() return 'ScriptItem' end
    function ScriptItem:repr() return self.name end
    function ScriptItem:construct(args)
      ScriptItem.super.construct(self, {
        name   = obj.get(args, 'name', true),
        output = { auto_handle = false, type = 'text' }
      })
    end
    function ScriptItem:handleOutput()
      local newValue                           = self:isEnabled() and remote.get_item_text_value(self.index) or ''
      self.surface.state[self.name .. '_prev'] = self.surface.state[self.name]
      self.surface.state[self.name]            = newValue
    end
  end
end

getSurface = function(manufacturer, model)
  if model == 'LaunchPad' then
    return LaunchPad(manufacturer, model)
  end
end

-- LaunchPad Control Surface
do
  -- Item Classes
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
      name   = 'redrumEditAccent',
      values = { colorCodes['13'], colorCodes['32'], colorCodes['20'] }
    })
    table.insert(ledModes, {
      name   = 'redrumStepPlaying',
      values = { colorCodes['00'], colorCodes['21'], colorCodes['03'], colorCodes['02'], colorCodes['01'] }
    })
    table.insert(ledModes, {
      name   = 'redrumStepOut',
      values = { colorCodes['00'], colorCodes['13'], colorCodes['32'], colorCodes['20'], colorCodes['02'] }
    })

    LPButtonItem = Class(SurfaceItem)
    function LPButtonItem:__classname() return 'LPButtonItem' end
    function LPButtonItem:construct(args)
      local name          = obj.get(args, 'name', true)
      local midiAction    = obj.get(args, 'midiAction', true)
      local addressByte   = obj.get(args, 'addressByte', true)
      local meta          = obj.get(args, 'meta', false, {})

      local inputPattern  = midi.pattern(midiAction, 0, addressByte, '?<???x>')
      local outputPattern = midi.pattern(midiAction, 0, addressByte, 'xx')

      LPButtonItem.super.construct(self, {
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
    function LPButtonItem:handleInput(midi)
      local overrideItem = self:enabledInputOverride()
      if overrideItem then
        return overrideItem:handleInput(midi, self)
      else
        local messages, handled = {}, false
        local pressed           = midi.x > 0
        local modeData          = self:getModeData()
        if modeData.hold then
          local remotableItemOn = remote.get_item_value(self.index) > 0
          if pressed == remotableItemOn then
            handled = true
          end
          local holdGroup = self.surface.state.buttonHoldGroup
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
    function LPButtonItem:handleOutput()
      local overrideItem = self:enabledOutputOverride()
      if (not overrideItem or not overrideItem:isEnabled()) and not self.led:isEnabled() then
        local retValue = 0
        if self:isEnabled() then
          local modeValues = self:getModeData().values
          if arr.length(modeValues) == 1 then
            retValue = modeValues[1]
          else
            retValue = modeValues[remote.get_item_value(self.index) + 1]
          end
        end
        codec.sendMidi { message = remote.make_midi(self.output.pattern, { x = retValue }) }
      end
    end

    LPLedItem = Class(SurfaceItem)
    function LPLedItem:__classname() return 'LPLedItem' end
    function LPLedItem:construct(args)
      local button = obj.get(args, 'button', true)

      LPLedItem.super.construct(self, {
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
    function LPLedItem:handleOutput()
      if self:isEnabled() then
        local modeValues  = self:getModeData().values
        local remoteValue = self:convertRemoteValue(remote.get_item_value(self.index), arr.length(modeValues) - 1)
        codec.sendMidi { message = remote.make_midi(self.button.output.pattern, { x = modeValues[remoteValue + 1] }) }
      else
        self.button:handleOutput()
      end
    end

    OverrideMixin = Class(SurfaceItem)
    function OverrideMixin:__classname() return 'OverrideMixin' end
    function OverrideMixin:construct(slaveItems)
      self.slaves = {}
      for _, item in ipairs(slaveItems) do
        table.insert(self.slaves, item)
        table.insert(item.meta.overrides, self)
      end
    end

    LPRedrumEditAccentOverrideItem = Class(SurfaceItem)
    function LPRedrumEditAccentOverrideItem:__classname() return 'LPRedrumEditAccentOverrideItem' end
    function LPRedrumEditAccentOverrideItem:construct(args)
      local name           = obj.get(args, 'name', true)
      local hardAccentItem = obj.get(args, 'hardAccentItem', true)
      local softAccentItem = obj.get(args, 'softAccentItem', true)

      LPRedrumEditAccentOverrideItem.super.construct(self, {
        name       = name,
        min        = 0,
        max        = 2,
        input      = {
          auto_handle = false,
          type        = 'value'
        },
        output     = {
          auto_handle = false,
          type        = 'value',
        },
        modes      = ledModes,
        slaveItems = { hardAccentItem, softAccentItem }
      })

      self.accentItems       = {
        hard = hardAccentItem,
        soft = softAccentItem
      }
      self.sourceItemMap     = {
        [hardAccentItem.index] = 'hard',
        [softAccentItem.index] = 'soft'
      }
      self.hardAccentPressed = false
      self.softAccentPressed = false
    end
    function LPRedrumEditAccentOverrideItem:handleInput(midi, sourceItem)
      local messages, handled = {}, false
      local pressed           = midi.x > 0
      local accentType        = self.sourceItemMap[sourceItem.index]
      if accentType == 'hard' then
        self.hardAccentPressed = pressed
        handled                = true
      elseif accentType == 'soft' then
        self.softAccentPressed = pressed
        handled                = true
      end
      if handled then
        local inputValue = 1 + (self.hardAccentPressed and 1 or 0) - (self.softAccentPressed and 1 or 0)
        table.insert(messages, { item = self.index, value = inputValue })
      end
      return messages, handled
    end
    function LPRedrumEditAccentOverrideItem:handleOutput()
      if self:isEnabled() then
        local modeValues = self:getModeData().values
        local retValue   = modeValues[remote.get_item_value(self.index) + 1]
        for _, slaveItem in ipairs(self.slaveItems) do
          codec.sendMidi { message = remote.make_midi(slaveItem.output.pattern, { x = retValue }) }
        end
      else
        for _, slaveItem in ipairs(self.slaveItems) do
          slaveItem:handleOutput()
        end
      end
    end

    LPRedrumEditStepsOverrideItem = Class(SurfaceItem)
    function LPRedrumEditStepsOverrideItem:__classname() return 'LPRedrumEditStepsOverrideItem' end
    function LPRedrumEditStepsOverrideItem:construct(args)
      local name     = obj.get(args, 'name', true)
      local val0Item = obj.get(args, 'val0Item', true)
      local val1Item = obj.get(args, 'val1Item', true)
      local val2Item = obj.get(args, 'val2Item', true)
      local val3Item = obj.get(args, 'val3Item', true)

      LPRedrumEditAccentOverrideItem.super.construct(self, {
        name       = name,
        min        = 0,
        max        = 3,
        input      = {
          auto_handle = false,
          type        = 'value'
        },
        output     = {
          auto_handle = false,
          type        = 'value'
        },
        modes      = ledModes,
        slaveItems = { val0Item, val1Item, val2Item, val3Item }
      })

      self.stepItems     = {}
      self.sourceItemMap = {}
      for i, item in ipairs(self.slaveItems) do
        self.stepItems[i - 1]          = item
        self.sourceItemMap[item.index] = i - 1
      end
    end
    function LPRedrumEditStepsOverrideItem:handleInput(midi, sourceItem)
      local messages, handled = {}, false
      local pressed           = midi.x > 0
      local inputValue        = self.sourceItemMap[sourceItem.index]
      if inputValue ~= nil then
        handled = true
      end
      if handled and pressed then
        table.insert(messages, { item = self.index, value = inputValue })
      end
      return messages, handled
    end
    function LPRedrumEditStepsOverrideItem:handleOutput()
      if self:isEnabled() then
        local modeValues  = self:getModeData().values
        local remoteValue = remote.get_item_value(self.index)
        for itemValue, item in pairs(self.stepItems) do
          local retValue = itemValue == remoteValue and modeValues[2] or modeValues[1]
          codec.sendMidi { message = remote.make_midi(item.output.pattern, { x = retValue }) }
        end
      else
        for _, slaveItem in ipairs(self.slaveItems) do
          slaveItem:handleOutput()
        end
      end
    end

    LPRedrumStepPlayingOverrideItem = Class(SurfaceItem)
    function LPRedrumStepPlayingOverrideItem:__classname() return 'LPRedrumStepPlayingOverrideItem' end
    function LPRedrumStepPlayingOverrideItem:construct(args)
      local name       = obj.get(args, 'name', true)
      local slaveItems = obj.get(args, 'slaveItems', true)

      LPRedrumStepPlayingOverrideItem.super.construct(self, {
        name       = name,
        min        = 0,
        max        = 63,
        output     = {
          auto_handle = false,
          type        = 'value'
        },
        modes      = ledModes,
        slaveItems = slaveItems
      })

      self.barItems  = {}
      self.beatItems = {}
      for i, item in ipairs(self.slaveItems) do
        if i <= 4 then
          self.barItems[i - 1] = item
        else
          self.beatItems[i - 1 - 4] = item
        end
      end
    end
    function LPRedrumStepPlayingOverrideItem:handleOutput()
      if self:isEnabled() then
        local remoteValue = remote.get_item_value(self.index)
        local bar         = math.floor(bit.mod(remoteValue / 16, 4))
        local beat        = math.floor(bit.mod(remoteValue, 16) / 4)
        local sixteenth   = math.floor(bit.mod(remoteValue, 4))
        local modeValues  = self:getModeData().values
        for itemValue, item in pairs(self.barItems) do
          local retValue = itemValue == bar and modeValues[2] or modeValues[1]
          codec.sendMidi { message = remote.make_midi(item.output.pattern, { x = retValue }) }
        end
        for itemValue, item in pairs(self.beatItems) do
          local retValue = itemValue == beat and modeValues[2 + sixteenth] or modeValues[1]
          codec.sendMidi { message = remote.make_midi(item.output.pattern, { x = retValue }) }
        end
      else
        for _, slaveItem in ipairs(self.slaveItems) do
          slaveItem:handleOutput()
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
        { name = '4', octaveOffset = 1 }, { name = '5', octaveOffset = 0 }, { name = '6', octaveOffset = 1 },
      }
    }

    LPKeyboardOverrideItem   = Class(SurfaceItem)
    function LPKeyboardOverrideItem:__classname() return 'LPKeyboardOverrideItem' end
    function LPKeyboardOverrideItem:construct(args)
      local name       = obj.get(args, 'name', true)
      local slaveItems = obj.get(args, 'slaveItems', true)

      LPKeyboardOverrideItem.super.construct(self, {
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
      local newLayout = obj.get(newScriptItemStates, '_KB_Layout', false)
      local newScale  = obj.get(newScriptItemStates, '_KB_Scale', false)
      local newRoot   = obj.get(newScriptItemStates, '_KB_Root', false)
      local newOctave = obj.get(newScriptItemStates, '_KB_Octave', false)

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
      local modeValues = self:getModeData().values
      for _, data in pairs(self.gridData) do
        if data.intervalIndex == 1 then
          for _, button in pairs(data.buttons) do
            codec.sendMidi { message = remote.make_midi(button.output.pattern, { x = modeValues[2] }) }
          end
        end
      end
      self.ready = true
    end
    function LPKeyboardOverrideItem:deactivate()
      self.active = false
      self.ready  = false
      for _, button in pairs(self.slaveItems) do
        button:handleOutput()
      end
    end
    function LPKeyboardOverrideItem:isEnabled()
      return self.surface.state._Scope == 'Master Keyboard' and self.surface.state._Var == 'Keyboard'
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
    function LPKeyboardOverrideItem:handleInput(midi, sourceItem)
      local messages, handled                   = {}, false
      local noteId                              = sourceItem.meta.noteId
      local gridCell                            = self.gridData[noteId]
      gridCell.buttonsPressed[sourceItem.index] = midi.x > 0
      local modeValues                          = self:getModeData().values
      if not gridCell.notePlayed and obj.hasValue(gridCell.buttonsPressed, true) then
        handled         = true
        local noteValue = self:getNoteValue(noteId, gridCell)
        table.insert(messages, { item = self.index, note = noteValue, value = 1, velocity = 100 })
        gridCell.notePlayed = noteValue
        local onValue       = modeValues[3]
        for _, button in pairs(gridCell.buttons) do
          codec.sendMidi { message = remote.make_midi(button.output.pattern, { x = onValue }) }
        end

      elseif gridCell.notePlayed and not obj.hasValue(gridCell.buttonsPressed, true) then
        handled = true
        table.insert(messages, { item = self.index, note = gridCell.notePlayed, value = 0 })
        gridCell.notePlayed = false
        local offValue      = gridCell.intervalIndex == 1 and modeValues[2] or modeValues[1]
        for _, button in pairs(gridCell.buttons) do
          codec.sendMidi { message = remote.make_midi(button.output.pattern, { x = offValue }) }
        end
      end
      return messages, handled
    end
  end

  LaunchPad = Class(ControlSurface)
  function LaunchPad:repr() return 'LaunchPad' end
  function LaunchPad:construct(manufacturer, modes)
    LaunchPad.super.construct(self)

    -- setup State
    self.state.buttonHoldGroup = {}
    -- Script Items
    do
      local scriptItemNames = {
        '_Scope',
        '_Var',
        '_KB_Layout',
        '_KB_Scale',
        '_KB_Root',
        '_KB_Octave',
      }
      for _, scriptItemName in ipairs(scriptItemNames) do
        self:addScriptItem(scriptItemName)
      end
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

            local buttonItem    = LPButtonItem {
              name        = name,
              midiAction  = midiAction,
              addressByte = addressByte,
              meta        = {
                zone          = zone,
                kbCoordinates = kbCoordinates
              }
            }
            local ledItem       = LPLedItem { button = buttonItem }

            if zone == 'Top' then
              table.insert(topButtons, buttonItem)
            elseif zone == 'Grid' then
              table.insert(gridButtons, buttonItem)
            end

            self:addItem { item = buttonItem, groups = { zone .. 'Buttons' } }
            self:addItem { item = ledItem, groups = { zone .. 'Leds' } }
          end
        end
      end
    end

    -- Override Items
    do
      self.keyboard = LPKeyboardOverrideItem { name = 'Keyboard', slaveItems = gridButtons }
      self:addItem { item = self.keyboard, groups = { 'Keyboard' } }

      -- Overrides for Redrum
      self:addItem { item = LPRedrumEditAccentOverrideItem {
        name           = 'Redrum: Edit Accent',
        hardAccentItem = self:getItemByName('G'),
        softAccentItem = self:getItemByName('H'),
      } }
      self:addItem { item = LPRedrumEditStepsOverrideItem {
        name     = 'Redrum: Edit Steps',
        val0Item = self:getItemByName('F5'),
        val1Item = self:getItemByName('F6'),
        val2Item = self:getItemByName('F7'),
        val3Item = self:getItemByName('F8'),
      } }
      self:addItem { item = LPRedrumStepPlayingOverrideItem {
        name       = 'Redrum: Step Playing',
        slaveItems = topButtons,
      } }
    end

  end
  function LaunchPad:handleChangedItems(changedItems, changedGroupItems, newScriptItemStates)
    self.keyboard:updateKeyboard(newScriptItemStates)
  end
end
