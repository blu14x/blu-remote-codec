--[[
┌─────────────────────────────────────────┐
│                                         │
│      <<  LaunchPad  [blu edit]  >>      │
│                 v 1.0.0                 │
│                                         │
│           Reason Remote Codec           │
│                   for                   │
│  Novation`s Launchpad,  DAW Controller  │
│                                         │
│          made by  Benjamin Lux          │
│   shared at  https://github.com/blu93   │
│                                         │
│   created and tested with  Reason v12   │
│                                         │
└─────────────────────────────────────────┘
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
    util = {
      number = {
        fromHex = function(hex)
          -- returns the Base 10 Integer Equivalent of a Base 16 Integer/String (hex)
          return tonumber(hex, 16)
        end,
        toHex   = function(num)
          -- return the Base 16 String (Zero-padded with 2 Characters) of a Base 10 Integer (num)
          return string.format("%02x", num)
        end,
        modulo  = function(a, b)
          -- Somehow using the '%' operator throws errors within the Remote environment. Use this workaround instead
          return a - math.floor(a / b) * b
        end,
        round   = function(num, decimals)
          -- round a number (num) to the given (decimals)
          local mul = 10 ^ (decimals or 0)
          return math.floor(num * mul + 0.5) / mul
        end,
      },
      string = {
        crop       = function(str, len, args)
          -- limit a String (str) to a specific length (len)
          -- Accepts an (args) object for left_align or zero_padding
          len                   = len >= 0 and len or 0
          args                  = args or {}
          args.left_align       = args.left_align or false
          args.zero_padding     = args.zero_padding or false
          local formatting_flag = ""
          if args.left_align then formatting_flag = "-" elseif args.zero_padding then formatting_flag = "0" end
          local format_string = string.format("%%%s%s.%ss", formatting_flag, len, len)
          return string.format(format_string, str)
        end,
        strip      = function(str)
          -- removes leading and trailing spaces of a String (str)
          return str:match("^%s*(.-)%s*$")
        end,
        split      = function(str, sep)
          -- returns an Array of Substrings of a String (str), divided by the Separator (sep)
          local _sep       = sep or ' '
          local substrings = {}
          for s in string.gmatch(str, "([^" .. _sep .. "]+)") do table.insert(substrings, s) end
          return substrings
        end,
        substrings = function(str)
          -- returns an Array of Substrings of a String (str)
          local substrings = {}
          for word in str:gmatch("%S+") do table.insert(substrings, word) end
          return substrings
        end,
      },
      table  = {
        -- General Table functions
        print       = function(tbl, indent)
          -- Print a Table (tbl) in a well formatted and nicely readable way, useful for debugging.
          -- Usage: error(util.table.print(tbl)) raises contents of "tbl", with indentation.
          -- You can then copy the error that Reason throws into the clipboard and paste it
          -- into a text editor to read the full text.
          indent       = indent or 0
          local output = "\n"
          if type(tbl) == "table" then
            for k, v in pairs(tbl) do
              if k ~= "metatable" then
                local _k         = type(k) == "number" and "[" .. (k < 99 and util.string.crop(k, 2) or k) .. "]" or k
                local formatting = string.rep("  ", indent) .. _k .. " = "
                if type(v) == "table" then
                  if next(v) == nil then
                    output = output .. formatting .. "{}" .. "\n"
                  elseif v.__classname then
                    if v.repr then
                      output = output .. formatting .. v:__classname() .. "(\"" .. v:repr() .. "\")\n"
                    else
                      output = output .. formatting .. v:__classname() .. "({" ..
                          util.table.print(_v, indent + 1) .. string.rep("  ", indent) .. "})\n"
                    end
                  else
                    output = output .. formatting .. "{" ..
                        util.table.print(v, indent + 1) .. string.rep("  ", indent) .. "}\n"
                  end
                elseif type(v) == "string" then
                  output = output .. formatting .. "\"" .. tostring(v) .. "\"\n"
                elseif type(v) == "boolean" then
                  output = output .. formatting .. tostring(v) .. "\n"
                else
                  output = output .. formatting .. tostring(v) .. "\n"
                end
              end
            end
          end
          return output
        end,
        shallowCopy = function(tbl)
          -- returns a shallow copy of a Table (tbl)
          if type(tbl) == "table" then
            local copy = {}
            for k, v in pairs(tbl) do copy[k] = v end
            return copy
          else
            return tbl
          end
        end,
        deepCopy    = function(tbl)
          -- returns a deep copy of a Table (tbl)
          if type(tbl) == "table" then
            local copy = {}
            for k, v in pairs(tbl) do
              if type(v) == "table" then copy[k] = util.table.deepCopy(v) else copy[k] = v end
            end
            return copy
          else
            return tbl
          end
        end,
      },
      object = {
        -- Key:Value-paired Tables
        length   = function(obj)
          -- returns the Length of an Object (obj)
          local count = 0
          for _ in pairs(obj) do count = count + 1 end
          return count
        end,
        hasKey   = function(obj, key)
          -- check if an Object (obj) has a specific Key (key)
          for k, _ in pairs(obj) do if k == key then return true end end
          return false
        end,
        hasValue = function(obj, value)
          -- check if an Object (obj) has a specific Value (value)
          for _, v in pairs(obj) do if v == value then return true end end
          return false
        end,
        keys     = function(obj)
          -- returns all keys of an Object (obj)
          local keys = {}
          for key, _ in pairs(obj) do table.insert(keys, key) end
          return keys
        end,
        equals   = function(obj1, obj2)
          -- check if two Objects (obj1 & obj2) are equal
          if util.object.length(obj1) ~= util.object.length(obj2) then return false end
          for k, v in pairs(obj1) do if obj2[k] ~= v then return false end end
          return true
        end,
      },
      array  = {
        -- Indexed Tables
        length           = function(arr)
          -- returns the Length of an Array (arr)
          local count = 0
          for _ in ipairs(arr) do count = count + 1 end
          return count
        end,
        hasValue         = function(arr, value)
          -- check if an Array (arr) has a specific Value (value)
          for _, v in ipairs(arr) do if v == value then return true end end
          return false
        end,
        reverse          = function(arr)
          -- returns a reversed copy of an Array (arr)
          local reversed = {}
          for i = util.array.length(arr), 1, -1 do table.insert(reversed, arr[i]) end
          return reversed
        end,
        last             = function(arr)
          -- returns the last value of an Array (arr)
          return arr[util.array.length(arr)]
        end,
        section          = function(arr, from, to)
          -- returns a Section of an Array (tbl) by (from) and (to)
          assert(from <= to)
          local section = {}
          for i = from, to do
            table.insert(section, arr[i])
          end
          return section
        end,
        attrValues       = function(arr, attr)
          -- takes an Array (arr) of Objects and returns each Value of the Attribute (attr)
          local values = {}
          for i, obj in ipairs(arr) do values[i] = obj[attr] end
          return values
        end,
        indexOfValue     = function(arr, value)
          -- returns the Index of a specific Value (v) within an Array (arr)
          -- (Note: on multiple appearances, always the first one)
          for i, v in ipairs(arr) do if v == value then return i end end
          return nil
        end,
        indexOfAttrValue = function(arr, attr, value)
          -- returns the Index of an Object with a specific Attribute (attr) : Value (value) within an Array (arr)
          -- (Note: on multiple appearances, always the first one)
          local values = util.array.attrValues(arr, attr)
          for i, v in ipairs(values) do if v == value then return i end end
          return nil
        end,
        equals           = function(arr1, arr2)
          -- check if two Arrays (arr1 & arr2) are equal
          if util.array.length(arr1) ~= util.array.length(arr2) then return false end
          for i, v in ipairs(arr1) do if arr2[i] ~= v then return false end end
          return true
        end,
        intersects       = function(arr1, arr2)
          -- returns a Table of Values that appear in both Arrays (arr1 & arr2)
          local arr1n, arr2n = util.table.shallowCopy(tbl1), util.table.shallowCopy(tbl2)
          if util.array.length(arr2n) >= util.array.length(arr1n) then arr1n, arr2n = arr2n, arr1n end
          local equal_values = {}
          for _, v in ipairs(arr2n) do if util.array.hasValue(arr1n, v) then table.insert(equal_values, v) end end
          return equal_values
        end,
        initiate         = function(value, count)
          -- creates and returns an Array of (count) times the (value)
          local initArray = {}
          for _ = 1, count do table.insert(initArray, util.table.deepCopy(value)) end
          return initArray
        end,
      },
    }
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
          ["n_off"] = midi.noteOff,
          ["n_on"]  = midi.noteOn,
          ["pa"]    = midi.polyAftertouch,
          ["cc"]    = midi.controlChange,
          ["pc"]    = midi.programChange,
          ["ca"]    = midi.channelAftertouch,
          ["pb"]    = midi.pitchBend,
        }
        return byte_map[action] + channel
      end,
      pattern           = function(action, channel, databyte_1, databyte_2)
        -- returns a pattern string for midi input and output definitions
        local statusbyte = midi.getStatusByte(action, channel)
        local pattern    = util.number.toHex(statusbyte)
        for _, databyte in ipairs({ databyte_1, databyte_2 }) do
          local parsed_byte = type(databyte) == "number" and util.number.toHex(databyte) or databyte
          pattern           = pattern .. parsed_byte
        end
        return pattern
      end
    }
  end
  -- CODEC
  do
    Codec = Class()
    function Codec:construct()
      self.__classname = 'Codec'
      self.state       = {}
      self.midiQueue   = {}

      -- ATTRIBUTES
      self.attr        = {
        remoteBaseChannelStep = 8
      }
    end
    function Codec:now()
      return remote.get_time_ms()
    end
    function Codec:sendMidi(message, args)
      -- adds a midi message to the midi queue
      args                  = args or {}
      args.delayMS          = args.delayMS or 0
      args.overridePrevious = args.overridePrevious or false

      local function getIndexOfPrevious(message)
        for i, queue_item in ipairs(self.midiQueue) do
          if util.arraysAreEqual(queue_item.message, message) then
            return i
          end
        end
        return nil
      end

      local timeStamp       = self:now() + args.delayMS
      local indexOfPrevious = getIndexOfPrevious(message)
      if args.overridePrevious and indexOfPrevious then
        self.midiQueue[indexOfPrevious].timeStamp = timeStamp
      else
        local newQueueItem = { message = message, timeStamp = timeStamp }
        table.insert(self.midiQueue, newQueueItem)
      end
    end
    function Codec:handleMidiQueue()
      -- returns all midi messages which are due to be delivered
      local retEvents    = {}
      local newMidiQueue = {}
      for _, queueItem in ipairs(self.midiQueue) do
        if self:now() >= queueItem.timeStamp then
          table.insert(retEvents, queueItem.message)
        else
          table.insert(newMidiQueue, queueItem)
        end
      end
      self.midiQueue = newMidiQueue
      return retEvents
    end
    CODEC = Codec()
  end
  -- RUNTIME
  do
    local runtime = {
      -- Remote Callbacks wrapper
      init         = function(manufacturer, model)
        _G["SURFACE"] = SURFACE_CLASS(manufacturer, model)
        remote.define_items(SURFACE:getRemoteItems())
        remote.define_auto_inputs(SURFACE:getRemoteAutoInputs())
        remote.define_auto_outputs(SURFACE:getRemoteAutoOutputs())

        --if SURFACE_SETUP.initialized then SURFACE_SETUP.initialized() end
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
          changedGroupItems[groupName] = util.intersection(groupItems, changedItems)
        end

        -- Collect new ScriptItem states
        local newScriptItemStates = {}
        for _, index in ipairs(SURFACE.itemGroups.script) do
          if util.hasValue(changedItems, index) then
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
        -- Fix Remote bug which causes new events to be instantiated incorrectly.
        local event = {}
        for k, v in pairs(_event) do
          if type(k) ~= "number" or k <= _event.size then
            event[k] = v
          end
        end

        --   SYSEX Events
        if event[1] == midi.sysexStart and event[event.size] == midi.sysexEnd then
          if SURFACE.handleSysexEvent then return SURFACE:handleSysexEvent(event) else return false end

          -- Other Events
        else
          local index, midi = SURFACE:translateMidiEvent(event)
          if index then
            local item = SURFACE.items[index]
            if item.handleInput then
              local messages, handled = item:handleInput(midi)
              for _, message in ipairs(messages) do
                remote.handle_input({ time_stamp = event.time_stamp, item = message.item, value = message.value,
                                      note       = message.note, velocity = message.velocity })
              end
              return handled
            end
          end
        end
      end,
      deliver_midi = function(maxbytes, port)
        -- Use Remote's regular call interval of deliver_midi for surface-specific "tick" functions
        if SURFACE.tick then SURFACE:tick() end

        -- Return all due midi messages
        return CODEC:handleMidiQueue()
      end,
      ----  TODO
      --on_auto_input    = function(item_index) end,
      --probe            = function(manufacturer, model, prober) end,
      --prepare_for_use  = function()
      --  local retEvents = {}
      --  return retEvents
      --end,
      --release_from_use = function()
      --  local retEvents = {}
      --  return retEvents
      --end,
    }
    for name, func in pairs(runtime) do
      -- Setup global Remote Callback functions ("remote_init" ... )
      _G["remote_" .. name] = func
    end
  end
  -- Control Surface
  do
    ControlSurface = Class()
    function ControlSurface:__classname() return 'ControlSurface' end
    function ControlSurface:construct()
      self.items                   = {}
      self.itemGroups              = {}
      self.state                   = {}

      local defaultScriptItemNames = {
        '_S', -- Scope
      }
      for _, scriptItemName in ipairs(defaultScriptItemNames) do
        ScriptItem(self, scriptItemName)
      end
    end
    function ControlSurface:repr() return 'ControlSurface' end
    function ControlSurface:getItemByName(itemName)
      for i, item in ipairs(self.items) do
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
  end
  -- Surface & Script Items
  do
    SurfaceItem = Class()
    function SurfaceItem:__classname() return 'SurfaceItem' end
    function SurfaceItem:repr() return self.name end
    function SurfaceItem:construct(surface, groups, config)
      self.name    = config.name
      self.min     = config.min
      self.max     = config.max
      self.input   = config.input
      self.output  = config.output
      self.modes   = config.modes
      self.meta    = config.meta

      self.surface = surface
      table.insert(self.surface.items, self)
      self.index = util.getLength(self.surface.items)

      -- Add to item groups
      groups     = groups or {}
      for _, groupName in ipairs(groups) do
        if not util.hasKey(self.surface.itemGroups, groupName) then
          self.surface.itemGroups[groupName] = {}
        end
        table.insert(self.surface.itemGroups[groupName], self.index)
      end
    end
    function SurfaceItem:getRemoteItem()
      return {
        name   = self.name,
        input  = self.input and self.input.type or nil,
        output = self.output and self.output.type or nil,
        min    = self.min,
        max    = self.max,
        modes  = self.modes and util.getAttributes(self.modes, "name") or nil
      }
    end
    function SurfaceItem:getRemoteAutoInput()
      if self.input and self.input.auto then
        return {
          name     = self.name,
          pattern  = self.input.pattern,
          value    = self.input.value,
          note     = self.input.note,
          velocity = self.input.velocity,
          port     = self.input.port
        }
      else
        return nil
      end
    end
    function SurfaceItem:getRemoteAutoOutput()
      if self.output and self.output.auto then
        return {
          name    = self.name,
          pattern = self.output.pattern,
          x       = self.output.x,
          y       = self.output.y,
          z       = self.output.z,
          port    = self.output.port
        }
      else
        return nil
      end
    end
    function SurfaceItem:getModeData()
      return self.modes and self.modes[remote.get_item_mode(self.index)] or {}
    end

    ScriptItem = Class(SurfaceItem)
    function ScriptItem:__classname() return 'ScriptItem' end
    function ScriptItem:construct(surface, name)
      ScriptItem.super.construct(self, surface, { 'script' }, {
        name   = name,
        output = {
          auto = false,
          type = 'text',
        }
      })
      self.surface.state[self.name .. '_Prev'] = ''
      self.surface.state[self.name]            = ''
    end
    function ScriptItem:handleOutput()
      local newValue                           = remote.is_item_enabled(self.index)
          and remote.get_item_text_value(self.index) or ''
      self.surface.state[self.name .. '_Prev'] = self.surface.state[self.name]
      self.surface.state[self.name]            = newValue
    end
  end
end

-- Item Classes
do
  local maxBrightness = 3
  local colorCodes    = {}
  for r = 0, maxBrightness do
    for g = 0, maxBrightness do
      colorCodes[r .. g] = r + 16 * g
    end
  end

  local ledModes = {}
  do
    for cc1, value1 in pairs(colorCodes) do
      for cc2, value2 in pairs(colorCodes) do
        local name, values = '', {}
        if cc1 == cc2 then
          name, values = cc1, { value1 }
        else
          name, values = cc1 .. '_' .. cc2, { value1, value2 }
        end
        table.insert(ledModes, { name = name, values = values, hold = false })
        table.insert(ledModes, { name = name .. '_hold', values = values, hold = true })
      end
    end

    -- Redrum Step Out
    table.insert(ledModes, { name = 'redrumStepOut', values = {
      colorCodes['00'],
      colorCodes['13'],
      colorCodes['32'],
      colorCodes['20'],
      colorCodes['02'],
    } })
  end

  ButtonItem = Class(SurfaceItem)
  function ButtonItem:__classname() return 'ButtonItem' end
  function ButtonItem:construct(surface, groups, data)
    local meta     = data.meta or {}
    meta.overrides = {}
    ButtonItem.super.construct(self, surface, groups, {
      name   = data.name,
      min    = 0,
      max    = 1,
      input  = {
        auto    = true,
        type    = 'button',
        pattern = midi.pattern(data.midiAction, 0, data.addressByte, '?<???x>')
      },
      output = {
        auto    = false,
        type    = 'value',
        pattern = midi.pattern(data.midiAction, 0, data.addressByte, 'xx'),
      },
      modes  = ledModes,
      meta   = meta
    })
  end
  function ButtonItem:enabledInputOverride()
    for _, overrideItem in ipairs(self.meta.overrides) do
      if overrideItem.handleInput and remote.is_item_enabled(overrideItem.index) then
        return overrideItem
      end
    end
    return nil
  end
  function ButtonItem:enabledOutputOverride()
    for _, overrideItem in ipairs(self.meta.overrides) do
      if overrideItem.handleOutput and remote.is_item_enabled(overrideItem.index) then
        return overrideItem
      end
    end
    return nil
  end
  function ButtonItem:handleInput(midi)
    local overrideItem = self:enabledInputOverride()
    if overrideItem then
      return overrideItem:handleInput(self.index, midi)
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
        if pressed and not util.hasValue(holdGroup, self.index) then
          table.insert(holdGroup, self.index)
        elseif util.hasValue(holdGroup, self.index) then
          table.remove(holdGroup, util.getIndex(holdGroup, self.index))
          table.insert(messages, { item = self.index, value = 1 })
        end
      end
      return messages, handled
    end
  end
  function ButtonItem:handleOutput()
    local overrideItem = self:enabledOutputOverride()
    if (not overrideItem or remote.is_item_enabled(overrideItem.index) == false) and not remote.is_item_enabled(self.led.index) then
      local retValue = 0
      if remote.is_item_enabled(self.index) then
        local modeData = self:getModeData()
        retValue       = modeData.values[remote.get_item_value(self.index) + 1]
      end
      CODEC:sendMidi(remote.make_midi(self.output.pattern, { x = retValue }))
    end
  end

  LedItem = Class(SurfaceItem)
  function LedItem:__classname() return 'LedItem' end
  function LedItem:construct(surface, groups, buttonItem)
    LedItem.super.construct(self, surface, groups, {
      name   = buttonItem.name .. ' LED',
      min    = 0,
      max    = 127,
      output = {
        auto = false,
        type = 'value'
      },
      modes  = ledModes
    })
    self.button    = buttonItem
    buttonItem.led = self
  end
  function LedItem:convertRemoteValue(remoteValue, maxValue)
    return math.floor(remoteValue * maxValue / self.max)
  end
  function LedItem:handleOutput()
    if remote.is_item_enabled(self.index) then
      local modeValues  = self:getModeData().values
      local remoteValue = self:convertRemoteValue(remote.get_item_value(self.index), util.getLength(modeValues))
      CODEC:sendMidi(remote.make_midi(self.button.output.pattern, { x = modeValues[remoteValue + 1] }))
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

  RedrumEditAccentOverrideItem = Class(OverrideMixin)
  function RedrumEditAccentOverrideItem:__classname() return 'RedrumEditAccentOverrideItem' end
  function RedrumEditAccentOverrideItem:construct(surface, groups, data)
    -- OverrideMixin
    RedrumEditAccentOverrideItem.super.construct(self, { data.meta.hardAccentItem, data.meta.softAccentItem })

    -- SurfaceItem
    RedrumEditAccentOverrideItem.super.super.construct(self, surface, groups, {
      name   = data.name,
      min    = 0,
      max    = 2,
      input  = {
        auto = false,
        type = 'value'
      },
      output = {
        auto = false,
        type = 'value',
      },
      modes  = ledModes,
      meta   = data.meta
    })

    self.accentItems       = {
      hard = data.meta.hardAccentItem,
      soft = data.meta.softAccentItem
    }
    self.sourceItemMap     = {
      [data.meta.hardAccentItem.index] = 'hard',
      [data.meta.softAccentItem.index] = 'soft'
    }
    self.hardAccentPressed = false
    self.softAccentPressed = false
  end
  function RedrumEditAccentOverrideItem:handleInput(sourceItemIndex, midi)
    local messages, handled = {}, false
    local pressed           = midi.x > 0
    local accentType        = self.sourceItemMap[sourceItemIndex]
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
  function RedrumEditAccentOverrideItem:handleOutput()
    if remote.is_item_enabled(self.index) then
      local valueMap = { colorCodes['13'], colorCodes['32'], colorCodes['20'] }
      local retValue = valueMap[remote.get_item_value(self.index) + 1]
      for _, slaveItem in ipairs(self.slaves) do
        CODEC:sendMidi(remote.make_midi(slaveItem.output.pattern, { x = retValue }))
      end
    else
      for _, slaveItem in ipairs(self.slaves) do
        slaveItem:handleOutput()
      end
    end
  end

  RedrumEditStepsOverrideItem = Class(OverrideMixin)
  function RedrumEditStepsOverrideItem:__classname() return 'RedrumEditStepsOverrideItem' end
  function RedrumEditStepsOverrideItem:construct(surface, groups, data)
    -- OverrideMixin
    RedrumEditStepsOverrideItem.super.construct(self, data.meta.slaveItems)

    -- SurfaceItem
    RedrumEditAccentOverrideItem.super.super.construct(self, surface, groups, {
      name   = data.name,
      min    = 0,
      max    = 3,
      input  = {
        auto = false,
        type = 'value'
      },
      output = {
        auto = false,
        type = 'value'
      },
      meta   = data.meta
    })

    self.stepItems     = {}
    self.sourceItemMap = {}
    for i, item in ipairs(data.meta.slaveItems) do
      self.stepItems[i - 1]          = item
      self.sourceItemMap[item.index] = i - 1
    end

    --error(util.tablePrint({ test = RedrumEditAccentOverrideItem.super.super.construct }))
  end
  function RedrumEditStepsOverrideItem:handleInput(sourceItemIndex, midi)
    local messages, handled = {}, false
    local pressed           = midi.x > 0
    local inputValue        = self.sourceItemMap[sourceItemIndex]
    if inputValue ~= nil then
      handled = true
    end
    if handled and pressed then
      table.insert(messages, { item = self.index, value = inputValue })
    end
    return messages, handled
  end
  function RedrumEditStepsOverrideItem:handleOutput()
    if remote.is_item_enabled(self.index) then
      local valueMap    = { colorCodes['01'], colorCodes['03'] }
      local remoteValue = remote.get_item_value(self.index)
      for itemValue, item in pairs(self.stepItems) do
        local retValue = itemValue == remoteValue and valueMap[2] or valueMap[1]
        CODEC:sendMidi(remote.make_midi(item.output.pattern, { x = retValue }))
      end
    else
      for _, slaveItem in ipairs(self.slaves) do
        slaveItem:handleOutput()
      end
    end
  end

  RedrumStepPlayingOverrideItem = Class(OverrideMixin)
  function RedrumStepPlayingOverrideItem:__classname() return 'RedrumStepPlayingOverrideItem' end
  function RedrumStepPlayingOverrideItem:construct(surface, groups, data)
    -- OverrideMixin
    RedrumStepPlayingOverrideItem.super.construct(self, data.meta.slaveItems)

    -- SurfaceItem
    RedrumStepPlayingOverrideItem.super.super.construct(self, surface, groups, {
      name   = data.name,
      min    = 0,
      max    = 63,
      output = {
        auto = false,
        type = 'value'
      },
      meta   = data.meta
    })

    self.barItems  = {}
    self.beatItems = {}
    for i, item in ipairs(data.meta.slaveItems) do
      if i <= 4 then
        self.barItems[i - 1] = item
      else
        self.beatItems[i - 1 - 4] = item
      end
    end

    --error(util.tablePrint({ test = RedrumEditAccentOverrideItem.super.super.construct }))
  end
  function RedrumStepPlayingOverrideItem:handleOutput()
    if remote.is_item_enabled(self.index) then
      local remoteValue  = remote.get_item_value(self.index)
      local bar          = math.floor(util.modulo(remoteValue / 16, 4))
      local beat         = math.floor(util.modulo(remoteValue, 16) / 4)
      local sixteenth    = math.floor(util.modulo(remoteValue, 4))
      local valueMapBar  = { colorCodes['00'], colorCodes['21'] }
      local valueMapBeat = { colorCodes['00'], colorCodes['21'], colorCodes['03'], colorCodes['02'], colorCodes['01'] }
      for itemValue, item in pairs(self.barItems) do
        local retValue = itemValue == bar and valueMapBar[2] or valueMapBar[1]
        CODEC:sendMidi(remote.make_midi(item.output.pattern, { x = retValue }))
      end
      for itemValue, item in pairs(self.beatItems) do
        local retValue = itemValue == beat and valueMapBeat[2 + sixteenth] or valueMapBar[1]
        CODEC:sendMidi(remote.make_midi(item.output.pattern, { x = retValue }))
      end
    else
      for _, slaveItem in ipairs(self.slaves) do
        slaveItem:handleOutput()
      end
    end
  end
end

-- Keyboard
do
  local keyboardModes  = {
    layout = {
      { name = 'push', rowOffset = 3 },
      { name = 'diatonic', rowOffset = 2 },
      { name = 'diagonal', rowOffset = 1 },
      { name = 'octave', rowOffset = 7 },
    },
    scale  = {
      { name = 'minor', intervals = { 0, 2, 3, 5, 7, 8, 10 } },
      { name = 'major', intervals = { 0, 2, 4, 5, 7, 9, 11 } },
      { name = 'harmonic', intervals = { 0, 2, 3, 5, 7, 8, 11 } },
      { name = 'byzantine', intervals = { 0, 2, 3, 6, 7, 8, 11 } },
      -- special cases
      { name = 'melodic', intervals = { asc = { 0, 2, 3, 5, 7, 9, 11 }, desc = { 0, 2, 3, 5, 7, 8, 10 }, directional = true } },
      { name = 'chromatic', intervals = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 } },
    },
    root   = {
      { name = 'a', noteOffset = 0 }, { name = 'a#', noteOffset = 1 }, { name = 'b', noteOffset = 2 },
      { name = 'c', noteOffset = 3 }, { name = 'c#', noteOffset = 4 }, { name = 'd', noteOffset = 5 },
      { name = 'd#', noteOffset = 6 }, { name = 'e', noteOffset = 7 }, { name = 'f', noteOffset = 8 },
      { name = 'f#', noteOffset = 9 }, { name = 'g', noteOffset = 10 }, { name = 'g#', noteOffset = 11 },
    },
    octave = {
      { name = '2', noteOffset = -24 }, { name = '3', noteOffset = -12 }, { name = '4', noteOffset = 0 },
      { name = '5', noteOffset = 12 }, { name = '6', noteOffset = 24 },
    }
  }
  KeyboardOverrideItem = Class(OverrideMixin)
  function KeyboardOverrideItem:__classname() return 'KeyboardOverrideItem' end
  function KeyboardOverrideItem:construct(surface, groups, data)
    -- OverrideMixin
    KeyboardOverrideItem.super.construct(self, data.meta.slaveItems)

    -- SurfaceItem
    KeyboardOverrideItem.super.super.construct(self, surface, groups, {
      name   = data.name,
      min    = 0,
      max    = 1,
      input  = {
        auto = false,
        type = 'keyboard',
      },
      output = {
        auto = false,
        type = 'value',
      },
      meta   = data.meta
    })

    self.currentModes = {
      layout = keyboardModes.layout[1],
      scale  = keyboardModes.scale[1],
      root   = keyboardModes.root[1],
      octave = keyboardModes.octave[3],
    }

    self.grid         = {}
    for _, item in ipairs(data.meta.slaveItems) do
      local row, col = unpack(item.meta.kbCoordinates)
      if not util.hasKey(self.grid, row) then
        self.grid[row] = {}
      end
      self.grid[row][col] = { item = item, note = nil, isRootNote = false }
    end
    --error(util.tablePrint(self.grid))
  end
  function KeyboardOverrideItem:getNote(row, col)
    local note                        = nil
    local rowOffset                   = self.currentModes.layout.rowOffset
    local intervals, scaleDirectional = self.currentModes.scale.intervals, self.currentModes.scale.directional
    local noteOffsetRoot              = self.currentModes.root.noteOffset
    local noteOffsetOctave            = self.currentModes.octave.noteOffset
  end
  function KeyboardOverrideItem:updateGrid()
    for row, cols in pairs(self.grid) do
      for col, obj in pairs(cols) do
        --self:getNote(row, col)
      end
    end
  end
  function KeyboardOverrideItem:update(newScriptItemStates)
    local update = false
    if newScriptItemStates._KB_Layout then
      update                   = true
      local modeIndex          = util.getIndexByAttrValue(keyboardModes.layout, 'name', newScriptItemStates._KB_Layout)
      self.currentModes.layout = keyboardModes.layout[modeIndex]
    end
    if newScriptItemStates._KB_Scale then
      update                  = true
      local modeIndex         = util.getIndexByAttrValue(keyboardModes.scale, 'name', newScriptItemStates._KB_Scale)
      self.currentModes.scale = keyboardModes.scale[modeIndex]
    end
    if newScriptItemStates._KB_Root then
      update                 = true
      local modeIndex        = util.getIndexByAttrValue(keyboardModes.root, 'name', newScriptItemStates._KB_Root)
      self.currentModes.root = keyboardModes.root[modeIndex]
    end
    if newScriptItemStates._KB_Octave then
      update                   = true
      local modeIndex          = util.getIndexByAttrValue(keyboardModes.octave, 'name', newScriptItemStates._KB_Octave)
      self.currentModes.octave = keyboardModes.octave[modeIndex]
    end
    --error(util.tablePrint(self.currentModes))
    --error(util.tablePrint(newScriptItemStates))
  end
  function KeyboardOverrideItem:handleOutput()
    error(util.tablePrint(remote.get_item_state(self.index)))
  end
end

-- Surface Class
do
  Launchpad = Class(ControlSurface)
  function Launchpad:__classname() return 'Launchpad' end
  function Launchpad:construct(manufacturer, modes)
    Launchpad.super:construct()

    -- setup State
    self.state.buttonHoldGroup = {}
    -- Script Items
    do
      local scriptItemNames = {
        '_KB_Layout',
        '_KB_Scale',
        '_KB_Root',
        '_KB_Octave',
      }
      for _, scriptItemName in ipairs(scriptItemNames) do
        ScriptItem(self, scriptItemName)
      end
    end

    local function getRowChar(row)
      return string.char(string.byte('A') + row - 2)
    end

    local topButtons       = {}
    local sideButtons      = {}
    local gridButtons      = {}

    local maxRows, maxCols = 9, 9
    do
      for row = 1, maxRows do
        for col = 1, maxCols do
          if not (row == 1 and col == maxCols) then
            local midiRow       = row - 1
            local midiCol       = col - 1
            local type          = row == 1 and 'top' or col == maxCols and 'side' or 'grid'

            local nameSuffix    = type == 'top' and col or type == 'side' and getRowChar(row) or getRowChar(row) .. col
            local name          = type:gsub("^%l", string.upper) .. ' ' .. nameSuffix
            local midiAction    = type == 'top' and 'cc' or 'n_on'
            local addressByte   = type == 'top' and 104 + midiCol or 16 * (midiRow - 1) + midiCol
            local kbCoordinates = type == 'grid' and { maxRows - row + 1, col } or nil
            local buttonData    = {
              name = name, midiAction = midiAction, addressByte = addressByte, meta = {
                type = type, kbCoordinates = kbCoordinates
              }
            }
            local button        = ButtonItem(self, { 'button', type }, buttonData)
            LedItem(self, { 'led', type }, button)

            if type == 'top' then
              table.insert(topButtons, button)
            elseif type == 'side' then
              table.insert(sideButtons, button)
            elseif type == 'grid' then
              table.insert(gridButtons, button)
            end
          end
        end
      end
    end

    -- Redrum: Edit Accent
    do
      local editAccentData = {
        name = 'Redrum: Edit Accent',
        meta = { hardAccentItem = self:getItemByName('Side G'), softAccentItem = self:getItemByName('Side H') }
      }
      RedrumEditAccentOverrideItem(self, {}, editAccentData)
    end
    -- Redrum: Edit Steps
    do
      local editStepsData = {
        name = 'Redrum: Edit Steps',
        meta = { slaveItems = {
          self:getItemByName('Grid F5'),
          self:getItemByName('Grid F6'),
          self:getItemByName('Grid F7'),
          self:getItemByName('Grid F8'),
        } }
      }
      RedrumEditStepsOverrideItem(self, {}, editStepsData)
    end
    -- Redrum: Step Playing
    do
      local stepPlayingData = {
        name = 'Redrum: Step Playing',
        meta = { slaveItems = topButtons }
      }
      RedrumStepPlayingOverrideItem(self, {}, stepPlayingData)
    end
    -- Keyboard
    do
      local keyboardData = {
        name = 'Keyboard',
        meta = { slaveItems = gridButtons }
      }
      self.keyboard      = KeyboardOverrideItem(self, {}, keyboardData)
    end
  end
  function Launchpad:handleChangedItems(changedItems, changedGroupItems, newScriptItemStates)
    self.keyboard:update(newScriptItemStates)
  end
  function Launchpad:tick()
    local now = CODEC.now()
  end

  SURFACE_CLASS = Launchpad
end

--asd = { 'a', 'b', 'c', 'd', 'e' }
--error(util.table.print(asd))
