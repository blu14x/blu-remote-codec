---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by blu.
--- DateTime: 06.02.23 11:44
---

require('framework')

initSurface = function(manufacturer, model)
  -- get control surface class by model name
  local surfaceClasses = {['X-Touch'] = XTouch, ['Launchpad'] = Launchpad, ['DS1'] = DS1}
  return surfaceClasses[model](manufacturer, model)
end

do
  XTouchButton = class('XTouchButton', ControlItem)
  do
    function XTouchButton.setupModesData()
      XTouchButton.static.modesData = {{name = 'default'}, {name = 'salami'}}
    end
    function XTouchButton:initialize(surface, name, kwargs)
      ControlItem.initialize(self, surface, name, {input = 'button', output = 'value'})
      self.autoInput  = AutoInput(self, 'abc')
      self.autoOutput = AutoOutput(self, 'abc')
    end
  end

  XTouch = class('XTouch', ControlSurface)
  do
    function XTouch:setup()
      --some_input    = AutoInput()
      scope              = ScriptItem(self, '$scope')
      a_button           = XTouchButton(self, 'Buttooon')
      anotha_button      = XTouchButton(self, 'Buttooon 2')
      anothatha_button   = XTouchButton(self, 'Buttooon 3')
      anothatssha_button = XTouchButton(self, 'Buttooon 4')
    end
  end
end

if remote.isDebugEnvironment then
  callbacks.init('Behringer', 'X-Touch')
  callbacks.set_state({1})
  pprint(SURFACE.scriptState)
end
