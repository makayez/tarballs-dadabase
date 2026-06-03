-- Core.lua - Main addon logic

local ADDON_NAME = ...
Dadabase = Dadabase or {}
Dadabase.VERSION = "0.5.2-alpha"

-- Constants
local DEFAULT_COOLDOWN = 10
local MAX_CHAT_MESSAGE_LENGTH = 255

-- ============================================================================
-- Load Confirmation
-- ============================================================================

local contentTypeNames = {
    "bad puns",
    "groaners",
    "dad jokes",
    "knee-slappers",
    "eye-rollers",
    "thigh-slappers",
    "zingers",
    "one-liners",
    "corny jokes",
    "silly jokes",
    "cheesy jokes",
    "rib-ticklers",
    "side-splitters",
    "stinkers",
    "doozies",
    "howlers",
    "chucklers",
    "gut-busters",
    "cringers",
    "face-palmers",
    "absolute bangers",
    "certified classics",
    "humdingers",
    "wisecracks",
    "quips",
    "gags",
    "japes",
    "real winners",
    "premium jokes",
    "crowd-pleasers"
}

local function GetRandomContentTypeName()
    return contentTypeNames[math.random(#contentTypeNames)]
end

-- ============================================================================
-- Frame / State
-- ============================================================================

local frame = CreateFrame("Frame")
local encounterActive = false
local lastContentTime = 0
local pendingMessage = false
local lastManualCommandTime = 0

-- ============================================================================
-- Saved Variables (Global Settings)
-- ============================================================================

TarballsDadabaseDB = TarballsDadabaseDB or {}

-- Global cooldown setting (migrated from per-module in earlier versions)
if TarballsDadabaseDB.cooldown == nil then
    TarballsDadabaseDB.cooldown = DEFAULT_COOLDOWN
end

-- Debug mode
if TarballsDadabaseDB.debug == nil then
    TarballsDadabaseDB.debug = false
end

-- Global enabled flag
if TarballsDadabaseDB.globalEnabled == nil then
    TarballsDadabaseDB.globalEnabled = true
end

-- Sound effect settings
if TarballsDadabaseDB.soundEnabled == nil then
    TarballsDadabaseDB.soundEnabled = false
end

if TarballsDadabaseDB.soundEffect == nil then
    TarballsDadabaseDB.soundEffect = SOUNDKIT.LEVEL_UP or 888
end

-- Usage statistics
TarballsDadabaseDB.stats = TarballsDadabaseDB.stats or {}

-- ============================================================================
-- Utilities
-- ============================================================================

local function DebugPrint(...)
    if TarballsDadabaseDB.debug then
        print(...)
    end
end

local function GetCurrentGroup()
    -- Check if in instance group first (LFR, LFD, Ritual Sites, etc.)
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        -- Distinguish LFR (raid) from LFG (party/scenario) by checking raid status
        -- Returns the content group for module filtering, plus "instance" chat type
        if IsInRaid() then
            return "raid", "instance"
        else
            return "party", "instance"
        end
    elseif IsInRaid() then
        return "raid", nil
    elseif IsInGroup() then
        return "party", nil
    end
    return nil, nil
end

local function SendContent(content, group)
    if pendingMessage then
        DebugPrint("Message already pending, skipping")
        return
    end

    -- Validate message length (UTF-8 safe, so we never split a multibyte glyph)
    if #content > MAX_CHAT_MESSAGE_LENGTH then
        DebugPrint("Message too long (" .. #content .. " bytes), truncating to " .. MAX_CHAT_MESSAGE_LENGTH)
        content = Dadabase.DatabaseManager:TruncateToBytes(content, MAX_CHAT_MESSAGE_LENGTH)
    end

    pendingMessage = true
    DebugPrint("Sending content to " .. (group or "local") .. " (" .. #content .. " bytes)")

    -- Delay message to avoid protected context (ADDON_ACTION_FORBIDDEN)
    -- 0.5s is needed to reliably escape the protected frame; 0.1s was insufficient for party and raid wipes
    C_Timer.After(0.5, function()
        if group == "instance" then
            SendChatMessage(content, "INSTANCE_CHAT")
        elseif group == "raid" then
            SendChatMessage(content, "RAID")
        elseif group == "party" then
            SendChatMessage(content, "PARTY")
        else
            -- Unreachable by design: the sole caller (TriggerContent) only passes
            -- "instance", "raid", or "party". Kept as a defensive fallback.
            print(content)
        end
        pendingMessage = false
    end)
end

local function TriggerContent()
    DebugPrint("TriggerContent called")

    -- Check if globally enabled
    if not TarballsDadabaseDB.globalEnabled then
        DebugPrint("  BLOCKED: Addon globally disabled")
        return
    end

    -- Check cooldown
    local now = GetTime()
    local timeSinceLastContent = now - lastContentTime
    DebugPrint("  Time since last: " .. timeSinceLastContent .. " (cooldown: " .. TarballsDadabaseDB.cooldown .. ")")

    if timeSinceLastContent < TarballsDadabaseDB.cooldown then
        DebugPrint("  BLOCKED: Still on cooldown")
        return
    end

    -- Get current group
    local group, chatType = GetCurrentGroup()

    -- Require a group for all automatic triggers
    if not group then
        DebugPrint("  BLOCKED: Not in a group")
        return
    end

    -- Get random content from database matching trigger and group
    local content, moduleId = Dadabase.DatabaseManager:GetRandomContent(group)

    if content then
        lastContentTime = now
        local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
        SendContent(prefix .. content, chatType or group)

        -- Track statistics
        if not TarballsDadabaseDB.stats[moduleId] then
            TarballsDadabaseDB.stats[moduleId] = 0
        end
        TarballsDadabaseDB.stats[moduleId] = TarballsDadabaseDB.stats[moduleId] + 1

        -- Play sound effect if enabled
        if TarballsDadabaseDB.soundEnabled and TarballsDadabaseDB.soundEffect then
            local success, err = pcall(PlaySound, TarballsDadabaseDB.soundEffect)
            if not success then
                DebugPrint("Failed to play sound: " .. tostring(err))
            end
        end
    else
        DebugPrint("  BLOCKED: No matching content found")
    end
end

-- ============================================================================
-- Event Handling
-- ============================================================================

frame:RegisterEvent("ENCOUNTER_START")
frame:RegisterEvent("ENCOUNTER_END")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LEAVING_WORLD")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            -- Seed random number generator for better randomness (if available)
            if math.randomseed then
                local success, err = pcall(math.randomseed, time())
                if not success then
                    DebugPrint("Could not seed random: " .. tostring(err))
                end
            end

            -- Initialize database
            Dadabase.DatabaseManager:Initialize()

            -- Register with interface options
            if Dadabase.Config then
                Dadabase.Config:RegisterInterfaceOptions()
            end

            -- Print load message
            local contentCount = Dadabase.DatabaseManager:GetTotalContentCount()
            local contentTypeName = GetRandomContentTypeName()
            print("Tarball's Dadabase v" .. Dadabase.VERSION .. " loaded: " .. contentCount .. " " .. contentTypeName .. " loaded. Type /dadabase to configure.")

            DebugPrint("Dadabase ADDON_LOADED")
            DebugPrint("  Total content: " .. contentCount)
            DebugPrint("  Cooldown: " .. TarballsDadabaseDB.cooldown)
        end

    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName = ...
        encounterActive = true
        DebugPrint("=== ENCOUNTER_START ===")
        DebugPrint("  ID: " .. tostring(encounterID))
        DebugPrint("  Name: " .. tostring(encounterName))

    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...

        DebugPrint("=== ENCOUNTER_END ===")
        DebugPrint("  Success: " .. tostring(success) .. " (0=wipe, 1=kill)")

        local _, instanceType = IsInInstance()
        if instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario" then
            DebugPrint("  SKIPPED: Not in party, raid, or scenario instance")
            encounterActive = false
            return
        end

        if encounterActive and success == 0 then
            DebugPrint("  WIPE DETECTED: Triggering content")
            TriggerContent()
        end

        encounterActive = false

    elseif event == "PLAYER_LEAVING_WORLD" then
        -- Reset encounter state on zone transitions (handles disconnect/leave mid-fight).
        -- Also clear pendingMessage for symmetry: a pending send timer that has not yet
        -- fired would otherwise leave the flag set across the zone boundary until it does.
        encounterActive = false
        pendingMessage = false

    end
end)

-- ============================================================================
-- Manual Content Commands
-- ============================================================================

-- Manual commands (/dadabase say|guild) intentionally use a send path independent
-- of the automatic wipe trigger: they send synchronously (to avoid taint from a
-- timer) and gate only on their own 3s lastManualCommandTime, deliberately NOT
-- sharing the automatic path's lastContentTime cooldown or pendingMessage flag.
-- A user explicitly invoking a command should not be blocked by automatic state.
local function SendManualContent(chatChannel)
    -- Check if globally enabled
    if not TarballsDadabaseDB.globalEnabled then
        print("Tarball's Dadabase is globally disabled. Enable it in /dadabase config.")
        return
    end

    -- Rate limiting for manual commands (3 second cooldown)
    local now = GetTime()
    if now - lastManualCommandTime < 3 then
        print("Please wait " .. math.ceil(3 - (now - lastManualCommandTime)) .. " second(s) before using this command again.")
        return
    end

    local content, moduleId = Dadabase.DatabaseManager:GetRandomContent(nil, true)
    if not content or not moduleId then
        print("No content available. Enable at least one module in /dadabase config.")
        return
    end

    local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
    local message = prefix .. content

    -- Validate message length (UTF-8 safe, so we never split a multibyte glyph)
    if #message > MAX_CHAT_MESSAGE_LENGTH then
        print("Warning: Message too long (" .. #message .. " bytes), truncating to " .. MAX_CHAT_MESSAGE_LENGTH)
        message = Dadabase.DatabaseManager:TruncateToBytes(message, MAX_CHAT_MESSAGE_LENGTH)
    end

    -- Commit the cooldown only once we are about to send, so a "no content"
    -- early return does not consume the 3s window.
    lastManualCommandTime = now

    -- Send directly without timers to avoid taint
    SendChatMessage(message, chatChannel)

    -- Track statistics
    if not TarballsDadabaseDB.stats[moduleId] then
        TarballsDadabaseDB.stats[moduleId] = 0
    end
    TarballsDadabaseDB.stats[moduleId] = TarballsDadabaseDB.stats[moduleId] + 1
end

local function GetManualChatChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "RAID"
    elseif IsInGroup() then
        return "PARTY"
    else
        return "SAY"
    end
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_TARBALLSDADABASE1 = "/dadabase"

SlashCmdList["TARBALLSDADABASE"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "" then
        if Dadabase.Config then
            Dadabase.Config:Toggle()
        end

    elseif msg == "version" then
        print("Tarball's Dadabase version " .. Dadabase.VERSION)

    elseif msg == "on" then
        -- Enable all modules
        for moduleId, _ in pairs(Dadabase.DatabaseManager.modules) do
            Dadabase.DatabaseManager:SetModuleEnabled(moduleId, true)
        end
        print("Tarball's Dadabase enabled (all modules).")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "off" then
        -- Disable all modules
        for moduleId, _ in pairs(Dadabase.DatabaseManager.modules) do
            Dadabase.DatabaseManager:SetModuleEnabled(moduleId, false)
        end
        print("Tarball's Dadabase disabled (all modules).")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "debug" then
        TarballsDadabaseDB.debug = not TarballsDadabaseDB.debug
        print("Tarball's Dadabase debug mode " .. (TarballsDadabaseDB.debug and "enabled" or "disabled") .. ".")

    elseif msg:match("^cooldown%s+%d+$") then
        local value = math.min(tonumber(msg:match("%d+")), 600)
        TarballsDadabaseDB.cooldown = value
        print("Tarball's Dadabase cooldown set to " .. value .. " seconds.")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "say" then
        SendManualContent(GetManualChatChannel())

    elseif msg == "guild" then
        if not IsInGuild() then
            print("You are not in a guild!")
            return
        end
        SendManualContent("GUILD")

    elseif msg == "status" then
        local _, instanceType = IsInInstance()
        local statusLines = {
            "Tarball's Dadabase Status:",
            "  Global Enabled: " .. (TarballsDadabaseDB.globalEnabled and "ON" or "OFF"),
            "  Version: " .. Dadabase.VERSION,
            "  Debug: " .. tostring(TarballsDadabaseDB.debug),
            "  Cooldown: " .. TarballsDadabaseDB.cooldown .. " seconds",
            "  Total content: " .. Dadabase.DatabaseManager:GetTotalContentCount(),
            "  In encounter: " .. tostring(encounterActive),
            "  Instance type: " .. tostring(instanceType),
            ""
        }

        -- Module status
        for moduleId, module in pairs(Dadabase.DatabaseManager.modules) do
            local moduleDB = TarballsDadabaseDB.modules[moduleId]
            if moduleDB then
                local content = Dadabase.DatabaseManager:GetEffectiveContent(moduleId)
                local stats = TarballsDadabaseDB.stats[moduleId] or 0
                table.insert(statusLines, "  [" .. module.name .. "] " .. (moduleDB.enabled and "ON" or "OFF") .. " - " .. #content .. " items, " .. stats .. " told")
            end
        end

        for _, line in ipairs(statusLines) do
            print(line)
        end

    else
        print("Tarball's Dadabase commands:")
        print("  /dadabase - Open config panel")
        print("  /dadabase version")
        print("  /dadabase on - Enable all modules")
        print("  /dadabase off - Disable all modules")
        print("  /dadabase debug")
        print("  /dadabase cooldown <seconds>")
        print("  /dadabase say - Send content to party/raid/instance/say")
        print("  /dadabase guild - Send content to guild chat")
        print("  /dadabase status")
    end
end
