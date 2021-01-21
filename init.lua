-- https://github.com/Hammerspoon/hammerspoon/issues/363#issuecomment-764887739
require("pl")

hs.logger.defaultLogLevel="info"

-- Misc setup
hs.window.animationDuration = 0
local vw = hs.inspect.inspect
local configFileWatcher = nil

-- Keyboard modifiers, Capslock bound to escape when a single keyup/down, but used as a modifier cmd+alt+ctrl (via Karabiner Elements)
local modNone  = {""}
local modAlt   = {"⌥"}
local modCmd   = {"⌘"}
local modShift = {"⇧"}
local modHyper = {"⌘", "⌥", "⌃"}
local modShiftHyper = {"⌘", "⌥", "⌃", "⇧"}

-- anycomplete init
local anycomplete = require "anycomplete/anycomplete"
anycomplete.registerDefaultBindings(modHyper, 'space')

local rawFile = file.read(os.getenv("HOME") .. "/.local/anycomplete-custom-words.txt")
local customWords = stringx.splitlines(rawFile)
anycomplete.registerCustomWords(customWords)

-- Load InstallSpoon and use it to load all the other spoons
hs.loadSpoon("SpoonInstall")
spoon.SpoonInstall.use_syncinstall = true
Install=spoon.SpoonInstall

-- -- Load Seal - This is a pretty simple implementation of something like Alfred
-- Install:andUse("Seal")
-- spoon.Seal:loadPlugins({"apps"})
-- spoon.Seal:bindHotkeys({show={{"cmd"}, "Space"}})
-- spoon.Seal:start()

local debugMode = false
function printIfDebug(o)
    if(debugMode) then
        print(o)
    end
end

----------------------------------------------------------------------------------------------------
--
-- appWatcher stuff
--
currentlyActiveAppObj = nil
previouslyActiveAppObj = nil

function gtmToolbarMonitor(appName, eventType, appObject)
    local windowTitles={"Waiting to view *'s screen", "Now viewing *'s screen"}
end

function prevCurrHandler(appName, eventType, appObject)
    if (eventType == hs.application.watcher.activated) then
        printIfDebug("application watcher: appObject=" .. appObject:name())

        if(previouslyActiveAppObj ~= nil and currentlyActiveAppObj ~= nil) then
            printIfDebug(" ")
            if(previouslyActiveAppObj ~= nil and previouslyActiveAppObj:name() ~= nil) then
                printIfDebug("previouslyActiveAppObj=" .. previouslyActiveAppObj:name())
            end
            if(currentlyActiveAppObj ~= nil and currentlyActiveAppObj:name() ~= nil) then
                printIfDebug("currentlyActiveAppObj=" .. currentlyActiveAppObj:name())
            end
            printIfDebug("Shifting... ")
            printIfDebug(" ")
        end

        if(appObject:name() ~= nil) then
            if (appObject:name() ~= "Hammerspoon" and not appObject:name():find("GoToMeeting")) then
                previouslyActiveAppObj = currentlyActiveAppObj
                currentlyActiveAppObj = appObject
            end
        end
    end
end

function applicationWatcher(appName, eventType, appObject)
    prevCurrHandler(appName, eventType, appObject)
    gtmToolbarMonitor(appName, eventType, appObject)
end
local appWatcher = hs.application.watcher.new(applicationWatcher)
appWatcher:start()

----------------------------------------------------------------------------------------------------
--
-- clipboard history (only text)
--
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

-- hot reload config
hs.hotkey.bind(modShiftHyper, "R", function()
  hs.reload()
end)

local ffmpegCmdPid=nil
hs.hotkey.bind(modShiftHyper, "W", function()
  -- Sorta pulled from here, not working yet: https://github.com/Hammerspoon/hammerspoon/issues/1808
  -- local tracking = false
  -- local events = eventtap.event.types
  -- local mouseMoveTracker = hs.eventtap.new({ events.leftMouseDragged, events.leftMouseUp }, function(e)
  --   if e:getType() == events.leftMouseUp then
  --     mouseMoveTracker:stop()
  --     mouseMoveTracker = nil
  --     tracking = false
  --   elseif e:getType() == events.leftMouseDragged then
  --     tracking = true
  --   end
  -- end, false)
  -- mouseMoveTracker:start()

  local startingMousePosition = hs.mouse.getAbsolutePosition()
  local max = hs.screen.mainScreen():fullFrame()
  local maxCanvas = hs.canvas.new{x=max.x, y=max.y, h=max.h, w=max.w}
  maxCanvas:clickActivating(false)
  maxCanvas:canvasMouseEvents(true, true, false, true)
  maxCanvas:mouseCallback(function(_, event, id, x, y)
    local currentMousePosition = hs.mouse.getAbsolutePosition()
    if event == "mouseMove" then
      -- if tracking then
        maxCanvas:replaceElements({
          type="rectangle",
          action="stroke",
          strokeWidth=2.0,
          strokeColor= {green=1.0},
          frame = {
            x=startingMousePosition.x,
            y=startingMousePosition.y,
            h=(currentMousePosition.y-startingMousePosition.y),
            w=(currentMousePosition.x-startingMousePosition.x)
          },
        })
      -- end
    -- elseif event == "mouseDown" then
      -- tracking=true
    elseif event == "mouseUp" then
      --w:h:x:y
      x=math.floor(startingMousePosition.x)
      y=math.floor(startingMousePosition.y)
      h=math.floor((currentMousePosition.y-startingMousePosition.y))
      w=math.floor((currentMousePosition.x-startingMousePosition.x))
      dimensions=(w .. ":" .. h .. ":" ..  x .. ":" .. y)

      local filename = os.date("screen%Y%m%d-%H%M%S")
      local cmd='/usr/local/bin/ffmpeg -f avfoundation -capture_cursor 1 -i 5: -filter:v crop='..dimensions..' ~/screen-gifs/'..filename..'.gif'
      print(cmd)
      hs.pasteboard.setContents(cmd)

      print("running:")
      local applescript = 'do shell script "'..cmd..' > /dev/null 2>&1 & echo $!"'
      local b, o, d = hs.applescript(applescript)
      print(hs.inspect(o))
      ffmpegCmdPid=o

      maxCanvas:delete()
    end
  end)
  maxCanvas:level("dragging")
  maxCanvas:show()
end)

hs.hotkey.bind(modShiftHyper, "E", function()
  local cmd = 'kill -2 '..ffmpegCmdPid
  local applescript = 'do shell script "'..cmd..' > /dev/null 2>&1 & echo $!"'
  print("running:")
  print(applescript)
  local b, o, d = hs.applescript(applescript)
end)

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



--menubar audio device
-- local audioDeviceMenubar = hs.menubar.new()
-- function setAudioDeviceDisplay(state)
--     if state then
--         audioDeviceMenubar:setTitle("")
--     else
--         audioDeviceMenubar:setTitle("💤")
--     end
-- end
-- caffeineMenubar:setClickCallback(function()
--     setCaffeineDisplay(hs.caffeinate.toggle("displayIdle"))
-- end)
-- setCaffeineDisplay(hs.caffeinate.get("displayIdle"))


-- switch output devices quickly with keyboard
local toggleAudioOutput = require("audio_output_toggle")
hs.hotkey.bind(modShiftHyper, "a", toggleAudioOutput)


function ensureGtmMenuItemIsUnchecked()
    local gtm = hs.application.find("GoToMeeting")
    if(gtm ~= nil) then
        local menuItemString = "Show Toolbar"
        local menuItem = gtm:findMenuItem(menuItemString)

        if(menuItem['enabled']) then
            if(menuItem['ticked']) then
                gtm:selectMenuItem(menuItemString, false)
            end
        end
    end
end
hs.hotkey.bind(modHyper, 'U', ensureGtmMenuItemIsUnchecked)

-- let me know when you're done loading all this stuff
hs.notify.new( {title='Hammerspoon', subTitle='Configuration loaded'} ):send()


-- defeat paste blockers
hs.hotkey.bind(modShiftHyper, "V", function() hs.eventtap.keyStrokes(hs.pasteboard.getContents()) end)
