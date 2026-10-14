--[[ Tests/wow_stub.lua

A stub WoW client so the addon can be smoke-tested without the game.

Usage:
    lua Tests/wow_stub.lua            # from the addon folder
    lua Tests/wow_stub.lua /path/to/TarballsDadabase

Exit code 0 = all checks passed, 1 = at least one failed.

It loads the files in TOC order, dispatches ADDON_LOADED, drives the slash
commands and a simulated wipe, builds the config panel, and asserts behaviour
that has previously regressed (see CHECKS below).

It is a harness, not a UI test: widget methods the harness does not model
resolve to a callable no-op proxy. Any key that fell back to the proxy is
recorded in frame._proxied and printed at the end, so a typo'd field name
(e.g. a call to a function that was never written) shows up as a proxied key
instead of passing silently.
--]]

local ADDON_DIR = (arg and arg[1]) or "."

-- ============================================================================
-- FrameXML-ish helpers
-- ============================================================================

function string:trim()
    return (self:gsub("^%s+", ""):gsub("%s+$", ""))
end
table.wipe = function(t)
    for k in pairs(t) do t[k] = nil end
end

-- Callable + indexable no-op, so widget chains (slider.Low:SetText) resolve.
local noop
noop = setmetatable({}, {
    __call = function() return noop end,
    __index = function() return noop end,
    __newindex = function() end,
    __tostring = function() return "noop" end,
})

local frames = {}          -- every frame created, for the proxy audit
local eventFrames = {}     -- event name -> { frame, ... }
local timers = {}
local sentMessages = {}
local printLog = {}

local newFrame
do
    local frame_mt = {
        __index = function(f, key)
            f._proxied[key] = true
            return noop
        end,
    }

    newFrame = function(kind, name, parent, template)
        local f = setmetatable({
            kind = kind, name = name, template = template,
            _scripts = {}, _children = {}, _proxied = {},
            _checked = false, _text = "", _value = 0,
            _enabled = true, _shown = false, _multiLine = false,
        }, frame_mt)

        if parent and parent._children then
            table.insert(parent._children, f)
        end
        table.insert(frames, f)

        f.SetScript = function(_, script, fn) f._scripts[script] = fn end
        f.GetScript = function(_, script) return f._scripts[script] end
        f.RegisterEvent = function(_, event)
            eventFrames[event] = eventFrames[event] or {}
            table.insert(eventFrames[event], f)
        end
        f.UnregisterEvent = function() end

        f.Show = function() f._shown = true end
        f.Hide = function() f._shown = false end
        f.IsShown = function() return f._shown end
        f.IsVisible = function() return f._shown end

        f.SetText = function(_, text) f._text = tostring(text) end
        f.GetText = function() return f._text end
        f.SetChecked = function(_, v) f._checked = v and true or false end
        -- WoW's GetChecked returns true/nil, never false.
        f.GetChecked = function() return f._checked or nil end

        f.Enable = function() f._enabled = true end
        f.Disable = function() f._enabled = false end
        f.IsEnabled = function() return f._enabled end

        f.SetValue = function(_, v) f._value = v end
        f.GetValue = function() return f._value end

        f.CreateFontString = function() return newFrame("FontString", nil, f) end
        f.CreateTexture = function() return newFrame("Texture", nil, f) end
        f.SetMultiLine = function(_, v) f._multiLine = v and true or false end

        return f
    end
end

CreateFrame = newFrame
UIParent = newFrame("Frame", "UIParent")
GameTooltip = newFrame("GameTooltip", UIParent)

C_Timer = { After = function(_, fn) table.insert(timers, fn) end }
local function runTimers()
    local pending = timers
    timers = {}
    for _, fn in ipairs(pending) do fn() end
end

local clock = 1000
GetTime = function() return clock end
time = function() return clock end

PlaySound = function() return true end
SendChatMessage = function(message, channel)
    table.insert(sentMessages, { message = message, channel = channel })
end

SlashCmdList = {}
LE_PARTY_CATEGORY_INSTANCE = "instance"

local instanceType = "raid"
IsInInstance = function() return true, instanceType end
IsInRaid = function() return true end
IsInGroup = function() return true end
IsInGuild = function() return true end

SOUNDKIT = {
    LEVEL_UP = 888, READY_CHECK = 8960, RAID_WARNING = 8959,
    ALARM_CLOCK_WARNING_3 = 12867, UI_WORLDQUEST_COMPLETE = 73182,
    IG_CHAT_EMOTE_BUTTON = 567, UI_QUEST_COMPLETE = 878,
    ACHIEVEMENT_MENU_OPEN = 3337, MAP_PING = 3175, LOOT_MONEY_COINS = 120,
    AUCTION_WINDOW_OPEN = 5274, IG_MAINMENU_OPTION_CHECKBOX_OFF = 857,
    IG_MAINMENU_OPTION = 852, UI_ORDERHALL_TALENT_READY_TOOST = 73743,
    UI_ORDERHALL_TALENT_READY_TOAST = 73743, RAID_BOSS_EMOTE_WARNING = 44854,
}

UIDropDownMenu_CreateInfo = function() return {} end
UIDropDownMenu_AddButton = function() end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_Initialize = function() end
UIDropDownMenu_SetText = function() end

local interfaceOptionsRegistered = 0
Settings = {
    RegisterCanvasLayoutCategory = function(frame, name)
        return { frame = frame, name = name }
    end,
    RegisterAddOnCategory = function()
        interfaceOptionsRegistered = interfaceOptionsRegistered + 1
    end,
    Close = function() end,
}

-- print goes to the log as well as stdout so tests can assert on it.
local realPrint = print
print = function(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = tostring(select(i, ...))
    end
    local line = table.concat(parts, " ")
    table.insert(printLog, line)
    realPrint(line)
end

-- ============================================================================
-- Harness utilities
-- ============================================================================

local checks = { passed = 0, failed = 0 }

local function check(name, ok, detail)
    if ok then
        checks.passed = checks.passed + 1
        realPrint("  PASS  " .. name)
    else
        checks.failed = checks.failed + 1
        realPrint("  FAIL  " .. name .. (detail and ("  -- " .. tostring(detail)) or ""))
    end
end

local function dispatch(event, ...)
    local errors = {}
    for _, f in ipairs(eventFrames[event] or {}) do
        local handler = f:GetScript("OnEvent")
        if handler then
            local ok, err = pcall(handler, f, event, ...)
            if not ok then errors[#errors + 1] = tostring(err) end
        end
    end
    return errors
end

local function callSlash(msg)
    return pcall(SlashCmdList["TARBALLSDADABASE"], msg)
end

-- Depth-first search over a frame's descendants.
local function findFrame(root, predicate)
    for _, child in ipairs(root._children or {}) do
        if predicate(child) then return child end
        local found = findFrame(child, predicate)
        if found then return found end
    end
end

local function findButton(root, label)
    return findFrame(root, function(f)
        return f.kind == "Button" and f._text == label
    end)
end

local function findCheckButton(root, label)
    return findFrame(root, function(f)
        return f.kind == "CheckButton" and f.text and f.text._text == label
    end)
end

local function findMultiLineEditBox(root)
    return findFrame(root, function(f)
        return f.kind == "EditBox" and f._multiLine
    end)
end

local function lastPrintContaining(needle)
    for i = #printLog, 1, -1 do
        if printLog[i]:find(needle, 1, true) then return printLog[i] end
    end
end

-- ============================================================================
-- Load the addon in TOC order
-- ============================================================================

local function readTocFiles()
    local path = ADDON_DIR .. "/TarballsDadabase.toc"
    local file = io.open(path, "r")
    if not file then return nil, "cannot open " .. path end
    local files = {}
    for rawLine in file:lines() do
        local line = rawLine:gsub("^%s+", ""):gsub("%s+$", ""):gsub("\\", "/")
        if line ~= "" and not line:match("^##") and line:match("%.lua$") then
            table.insert(files, line)
        end
    end
    file:close()
    return files
end

realPrint("== Loading addon from " .. ADDON_DIR .. " ==")
local files, tocErr = readTocFiles()
if not files then
    realPrint("FATAL: " .. tostring(tocErr))
    os.exit(1)
end

local loadErrors = {}
for _, file in ipairs(files) do
    local chunk, err = loadfile(ADDON_DIR .. "/" .. file)
    if not chunk then
        table.insert(loadErrors, file .. ": " .. tostring(err))
    else
        local ok, runErr = pcall(chunk, "TarballsDadabase")
        if not ok then table.insert(loadErrors, file .. ": " .. tostring(runErr)) end
    end
end

realPrint("== Checks ==")

-- CHECKS (each one has caught a real regression at some point):
--  1. every file loads and ADDON_LOADED completes without a Lua error
--  2. the start-up content message and the Interface Options entry both happen
--  3. a wipe sends exactly one message, and the cooldown blocks the next wipe
--  4. duplicate editor lines collapse on save (they used to be stored, counted
--     and picked N times)
--  5. /dadabase status lists modules in registration order (pairs over a
--     string-keyed table has no defined order, so the rows reshuffled)
--  6. Save/Reset are not force-disabled while the editor holds unsaved edits
--  7. the config panel builds one tab per About/Settings + registered content tab

check("all files load", #loadErrors == 0, table.concat(loadErrors, "; "))

local eventErrors = dispatch("ADDON_LOADED", "TarballsDadabase")
runTimers()
check("ADDON_LOADED completes without error", #eventErrors == 0, table.concat(eventErrors, "; "))

check("start-up message printed",
    lastPrintContaining("loaded:") ~= nil,
    "no 'loaded:' line (a Lua error in ADDON_LOADED aborts the rest of the handler)")
check("Interface Options category registered",
    interfaceOptionsRegistered == 1, "got " .. interfaceOptionsRegistered)

-- Wipe trigger + cooldown
dispatch("ENCOUNTER_START", 1, "Test Boss")
clock = clock + 60
dispatch("ENCOUNTER_END", 1, "Test Boss", 1, 25, 0)
runTimers()
check("wipe sends one chat message", #sentMessages == 1, "got " .. #sentMessages)
check("wipe message goes to instance chat",
    sentMessages[1] and sentMessages[1].channel == "INSTANCE_CHAT",
    sentMessages[1] and sentMessages[1].channel)

dispatch("ENCOUNTER_START", 1, "Test Boss")
dispatch("ENCOUNTER_END", 1, "Test Boss", 1, 25, 0)
runTimers()
check("cooldown suppresses the next wipe", #sentMessages == 1, "got " .. #sentMessages)

-- Manual command
clock = clock + 60
local okManual, errManual = callSlash("say")
check("/dadabase say sends without error", okManual, errManual)

-- Duplicate content collapse
local Manager = Dadabase.DatabaseManager
Manager:RegisterModule("harness", {
    name = "Harness",
    defaultContent = { "default line" },
    dbVersion = 1,
    defaultSettings = { enabled = true, groups = { raid = true, party = true } },
})
Manager:Initialize()
Manager:SetEffectiveContent("harness", { "default line", "custom line", "custom line", "custom line" })
local effective = Manager:GetEffectiveContent("harness")
check("duplicate lines collapse on save", #effective == 2, "got " .. #effective)
Manager:SetEffectiveContent("harness", { "default line" })
check("removing every custom line works", #Manager:GetEffectiveContent("harness") == 1)
Manager:SetModuleEnabled("harness", false)

-- Status lists modules in registration order
local function statusModuleNames()
    local start = #printLog
    callSlash("status")
    local names = {}
    for i = start + 1, #printLog do
        local name = printLog[i]:match("^  %[(.-)%]")
        if name then names[#names + 1] = name end
    end
    return names
end
local printedOrder = statusModuleNames()
local expectedOrder = {}
for _, entry in ipairs(Manager:OrderedModules()) do
    expectedOrder[#expectedOrder + 1] = entry.module.name
end
check("/dadabase status lists modules in registration order",
    table.concat(printedOrder, ", ") == table.concat(expectedOrder, ", "),
    table.concat(printedOrder, ", ") .. " vs " .. table.concat(expectedOrder, ", "))

-- Config panel
local okPanel, errPanel = callSlash("")
check("config panel opens without error", okPanel, errPanel)
local panel = Dadabase.Config.frame
check("panel has About + Settings + one tab per registered content tab",
    panel and panel.tabs and #panel.tabs == 2 + #Dadabase.Config.moduleTabs,
    panel and panel.tabs and ("got " .. #panel.tabs))

-- Save/Reset gating: content editing is independent of trigger state, so a
-- refresh (panel reopen, /dadabase on|off) must not gray out Save while the
-- editor still holds unsaved text.
local container = newFrame("Frame", "HarnessModuleTab")
TarballsDadabaseDB.modules.guildquotes.enabled = false
Dadabase.Config:BuildModuleContent(container, "guildquotes")

local saveBtn = findButton(container, "Save Changes")
local resetBtn = findButton(container, "Reset to Defaults")
local editBox = findMultiLineEditBox(container)
local raidCheckbox = findCheckButton(container, "Raids (includes LFR)")

check("module tab builds save/reset/editor",
    saveBtn and resetBtn and editBox and raidCheckbox,
    "widget lookup failed")

if saveBtn and editBox then
    check("save starts disabled (nothing edited)", not saveBtn:IsEnabled())
    check("trigger checkboxes are disabled for a disabled module", not raidCheckbox:IsEnabled())

    editBox:SetText("a brand new quote")
    local onTextChanged = editBox:GetScript("OnTextChanged")
    onTextChanged(editBox, true)
    check("typing enables save", saveBtn:IsEnabled())

    container.SyncFromDB()
    check("refresh keeps save enabled while edits are unsaved", saveBtn:IsEnabled(),
        "SyncFromDB/RefreshControls force-disabled Save even though the editor was dirty")
end

-- Proxy audit: every key that resolved to the no-op proxy. These should all be
-- real FrameXML methods; anything else is a field the addon never defined.
local proxied = {}
for _, f in ipairs(frames) do
    for key in pairs(f._proxied) do proxied[key] = true end
end
local keys = {}
for key in pairs(proxied) do keys[#keys + 1] = key end
table.sort(keys)
realPrint("== proxied widget keys (" .. #keys .. ") ==")
realPrint("  " .. table.concat(keys, ", "))

realPrint("== passed " .. checks.passed .. ", failed " .. checks.failed .. " ==")
os.exit(checks.failed == 0 and 0 or 1)
