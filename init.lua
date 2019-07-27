local pprint = require('pprint')

hs.logger.defaultLogLevel="info"

-- Misc setup
hs.window.animationDuration = 0
local vw = hs.inspect.inspect
local configFileWatcher = nil
local appWatcher = nil

-- Keyboard modifiers, Capslock bound to escape when a single keyup/down, but used as a modifier cmd+alt+ctrl (via Karabiner Elements)
local modNone  = {""}
local modAlt   = {"⌥"}
local modCmd   = {"⌘"}
local modShift = {"⇧"}
local modHyper = {"⌘", "⌥", "⌃"}
local modShiftHyper = {"⌘", "⌥", "⌃", "⇧"}


-- Load InstallSpoon and use it to load all the other spoons
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install=spoon.SpoonInstall

-- Load Seal - This is a pretty simple implementation of something like Alfred
Install:andUse("Seal")
spoon.Seal:loadPlugins({"apps"})
spoon.Seal:bindHotkeys({show={{"cmd"}, "Space"}})
spoon.Seal:start()

-- cmd-tab replacement
currentlyActiveAppObj = nil
previouslyActiveAppObj = nil

function applicationWatcher(appName, eventType, appObject)
  if (eventType == hs.application.watcher.activated) then
    print("application watcher: appObject=" .. appObject:name())

    if(previouslyActiveAppObj ~= nil and currentlyActiveAppObj ~= nil) then
        print(" ")
        if(previouslyActiveAppObj ~= nil and previouslyActiveAppObj:name() ~= nil) then
            print("previouslyActiveAppObj=" .. previouslyActiveAppObj:name())
        end
        if(currentlyActiveAppObj ~= nil and currentlyActiveAppObj:name() ~= nil) then
            print("currentlyActiveAppObj=" .. currentlyActiveAppObj:name())
        end
        print("Shifting... ")
        print(" ")
    end

    if(appObject:name() ~= nil) then
        if (appObject:name() ~= "Hammerspoon" and not appObject:name():find("GoToMeeting")) then
            previouslyActiveAppObj = currentlyActiveAppObj
            currentlyActiveAppObj = appObject
        end
    end
  end
end
appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

-- this is actually bound to cmd-tab in BTT
hs.hotkey.bind(modAlt, 'tab', function() 
    if(previouslyActiveAppObj ~= nil) then
        previouslyActiveAppObj:activate()
    end
end)

--clipboard history (only text)
Install:andUse("TextClipboardHistory", {
    disable = false,
    config = {
        show_in_menubar = false,
    },
    hotkeys = {
        toggle_clipboard = { modHyper, "v" } 
    },
    start = true,
})

----not working yet
----emoji
--Install:andUse("Emojis", {
--    disable = false,
--    config = {
--        show_in_menubar = false,
--    },
--    hotkeys = {
--        toggle = { modShiftHyper, "e" } 
--    },
--})

-- -- NOT WORKING YET
-- -- keyboard shortcut cheatsheet creator
-- Install:andUse("KSheet")
-- hs.hotkey.bind(modHyper, '/', function() 
--     KSheet:show()
-- end)
--
--


-- modal window control
local screenMode = hs.hotkey.modal.new(modHyper, 'w')

function screenMode:entered()
    alertUuids = hs.fnutils.imap(hs.screen.allScreens(), function(screen)
       return hs.alert.show('Move Window', hs.alert.defaultStyle, screen, true)
    end)
end

function screenMode:exited()
    hs.fnutils.ieach(alertUuids, function(uuid)
        hs.alert.closeSpecific(uuid)
    end)
end

windowKeyList = {
    { key='h', unit=hs.geometry.rect(0, 0, 0.6, 1) },
    { key='l', unit=hs.geometry.rect(0.6, 0, 0.4, 1) },
    { key='m', unit=hs.layout.maximized },
}

hs.fnutils.each(windowKeyList, function(entry)
   screenMode:bind('', entry.key, function()
        hs.window.focusedWindow():moveToUnit(entry.unit)
        screenMode:exit()
    end)
end)

screenMode:bind('', 'escape', function() screenMode:exit() end)


-- modal finder window access
local finderMode = hs.hotkey.modal.new(modHyper, 'f')

function finderMode:entered()
    alertUuids = hs.fnutils.imap(hs.screen.allScreens(), function(screen)
       return hs.alert.show('Select Directory', hs.alert.defaultStyle, screen, true)
    end)
end

function finderMode:exited()
    hs.fnutils.ieach(alertUuids, function(uuid)
        hs.alert.closeSpecific(uuid)
    end)
end

finderKeyList = {
    { key='d', dir="/Users/kyounger/Desktop" },
    { key='j', dir="/Users/kyounger/Downloads" },
    { key='a', dir="/Applications" },
}

hs.fnutils.each(finderKeyList, function(entry)
   finderMode:bind('', entry.key, function()
        local applescript = 'tell application "Finder"\n' .. 'open ("' .. entry.dir .. '" as POSIX file) activate\nend tell'
        -- print(applescript)
        hs.applescript(applescript)
        finderMode:exit()
    end)
end)

finderMode:bind('', 'escape', function() finderMode:exit() end)


-- switch output devices quickly with keyboard
local toggleAudioOutput = require("audio_output_toggle")
hs.hotkey.bind(modShiftHyper, "a", toggleAudioOutput)

-- let me know when you're done loading all this stuff
hs.notify.new( {title='Hammerspoon', subTitle='Configuration loaded'} ):send()
