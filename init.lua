-- Misc setup
hs.window.animationDuration = 0
local vw = hs.inspect.inspect
local configFileWatcher = nil
local appWatcher = nil

-- Keyboard modifiers, Capslock bound to cmd+alt+ctrl+shift via Seil and Karabiner
local modNone  = {""}
local modAlt   = {"⌥"}
local modCmd   = {"⌘"}
local modShift = {"⇧"}
local modHyper = {"⌘", "⌥", "⌃", "⇧"}


-- cmd-tab replacement
currentlyActiveAppObj = nil
previouslyActiveAppObj = nil

function betterLaunchOrFocus(appName)
   local app = hs.appfinder.appFromName(appName)
   if app == nil then
      hs.application.launchOrFocus(appName)
   else
      windows = app:allWindows()
      if windows[1] then
         windows[1]:focus()
      end
   end
end

function applicationWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    previouslyActiveAppObj = currentlyActiveAppObj
    currentlyActiveAppObj = appObject
  end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

-- hs.hotkey.bind(modCmd, 'tab', function() 
--     previouslyActiveAppObj:activate()
-- end)

function keyDownHandler(keyDownEvent)
    local flags = keyDownEvent:getFlags()
    local keyCode = keyDownEvent:getKeyCode()

    if(flags.cmd and keyCode == 48) then
        if(previouslyActiveAppObj ~= nil) then
            -- previouslyActiveAppObj:activate()
            hs.alert("Boom")
        end
        return false
    end

end

local key_tap = hs.eventtap.new(
  {hs.eventtap.event.types.keyUp, hs.eventtap.event.types.keyDown},
  keyDownHandler
)
-- key_tap:start()


hs.urlevent.bind("cmdTab", function(eventName, params)
    if(previouslyActiveAppObj ~= nil) then
        previouslyActiveAppObj:activate()
        hs.alert("Boom")
    end
end)


