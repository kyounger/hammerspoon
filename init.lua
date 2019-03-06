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
local modHyper = {"⌘", "⌥", "⌃"}
local modShiftHyper = {"⌘", "⌥", "⌃", "⇧"}

--test modal
k = hs.hotkey.modal.new({"cmd", "shift"}, "d")
function k:entered() hs.alert.show('Entered mode') end
function k:exited()  hs.alert.show('Exited mode')  end
k:bind({}, 'escape', function() k:exit() end)
k:bind({}, 'J', function() hs.alert.show("Pressed J") end)

-- Load Seal - This is a pretty simple implementation of something like Alfred
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true

spoon.SpoonInstall:andUse("Seal")
spoon.Seal:loadPlugins({"apps"})
spoon.Seal:bindHotkeys({show={{"cmd"}, "Space"}})
spoon.Seal:start()

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
    if(previouslyActiveAppObj ~= nil and currentlyActiveAppObj ~= nil) then
        print(" ")
        print("previouslyActiveAppObj=" .. previouslyActiveAppObj:name())
        print("currentlyActiveAppObj=" .. currentlyActiveAppObj:name())
        print("appObject=" .. appObject:name())
        print("Shifting... ")
        print(" ")
    end
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

-- local key_tap = hs.eventtap.new(
--   {hs.eventtap.event.types.keyUp, hs.eventtap.event.types.keyDown},
--   keyDownHandler
-- )
-- key_tap:start()


-- hs.urlevent.bind("cmdTab", function(eventName, params)
--     print("url binding start")
--     if(previouslyActiveAppObj ~= nil) then
--         previouslyActiveAppObj:activate()
--         hs.alert("Boom")
--     end
--     print("url binding end")
-- end)

hs.notify.new( {title='Hammerspoon', subTitle='Configuration loaded'} ):send()
