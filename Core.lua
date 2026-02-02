-- Core.lua - Main addon logic

local ADDON_NAME = ...
Dadabase = Dadabase or {}
Dadabase.VERSION = "0.3.0"

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

-- ============================================================================
-- Saved Variables (legacy)
-- ============================================================================

TarballsDadabaseDB = TarballsDadabaseDB or {}

-- Legacy cooldown setting (now global, not per-module)
if TarballsDadabaseDB.cooldown == nil then
    TarballsDadabaseDB.cooldown = 10
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
    TarballsDadabaseDB.soundEffect = "LEVELUP"
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
    if IsInRaid() then
        return "raid"
    elseif IsInGroup() then
        return "party"
    end
    return nil
end

local function SendContent(content, group)
    DebugPrint("Sending content to " .. (group or "local"))

    C_Timer.After(1, function()
        if group == "raid" then
            SendChatMessage(content, "RAID")
        elseif group == "party" then
            SendChatMessage(content, "PARTY")
        else
            -- Fallback - print locally
            print(content)
        end
    end)
end

local function TriggerContent(triggerType)
    DebugPrint("TriggerContent called: " .. triggerType)

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
    local group = GetCurrentGroup()

    -- For wipe triggers, require a group
    if not group and triggerType ~= "death" then
        DebugPrint("  BLOCKED: Not in a group")
        return
    end

    -- Get random content from database matching trigger and group
    local content, moduleId = Dadabase.DatabaseManager:GetRandomContent(triggerType, group)

    if content then
        lastContentTime = now
        local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
        SendContent(prefix .. content, group)

        -- Track statistics
        if not TarballsDadabaseDB.stats[moduleId] then
            TarballsDadabaseDB.stats[moduleId] = 0
        end
        TarballsDadabaseDB.stats[moduleId] = TarballsDadabaseDB.stats[moduleId] + 1

        -- Play sound effect if enabled
        if TarballsDadabaseDB.soundEnabled and TarballsDadabaseDB.soundEffect then
            PlaySound(TarballsDadabaseDB.soundEffect)
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
frame:RegisterEvent("PLAYER_DEAD")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        local addonName = ...
        if addonName == ADDON_NAME then
            -- Initialize database
            Dadabase.DatabaseManager:Initialize()

            -- Register with interface options
            if Dadabase.Config then
                Dadabase.Config:RegisterInterfaceOptions()
            end

            -- Print load message
            local contentCount = Dadabase.DatabaseManager:GetTotalContentCount()
            local contentTypeName = GetRandomContentTypeName()
            print("Tarball's Dadabase v" .. Dadabase.VERSION .. " loaded: " .. contentCount .. " " .. contentTypeName .. " loaded.")

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

        local inInstance, instanceType = IsInInstance()
        if instanceType ~= "party" and instanceType ~= "raid" then
            DebugPrint("  SKIPPED: Not in party or raid instance")
            encounterActive = false
            return
        end

        if encounterActive and success == 0 then
            DebugPrint("  WIPE DETECTED: Triggering content")
            TriggerContent("wipe")
        end

        encounterActive = false

    elseif event == "PLAYER_DEAD" then
        DebugPrint("=== PLAYER_DEAD ===")
        TriggerContent("death")
    end
end)

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

    elseif msg == "off" then
        -- Disable all modules
        for moduleId, _ in pairs(Dadabase.DatabaseManager.modules) do
            Dadabase.DatabaseManager:SetModuleEnabled(moduleId, false)
        end
        print("Tarball's Dadabase disabled (all modules).")

    elseif msg == "debug" then
        TarballsDadabaseDB.debug = not TarballsDadabaseDB.debug
        print("Tarball's Dadabase debug mode " .. (TarballsDadabaseDB.debug and "enabled" or "disabled") .. ".")

    elseif msg:match("^cooldown%s+%d+$") then
        local value = tonumber(msg:match("%d+"))
        TarballsDadabaseDB.cooldown = value
        print("Tarball's Dadabase cooldown set to " .. value .. " seconds.")

    elseif msg == "say" then
        local group = GetCurrentGroup()
        local content, moduleId = Dadabase.DatabaseManager:GetRandomContent("wipe", group or "party")
        local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
        local message = prefix .. content

        if IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        else
            SendChatMessage(message, "SAY")
        end

    elseif msg == "guild" then
        if not IsInGuild() then
            print("You are not in a guild!")
        else
            local group = GetCurrentGroup()
            local content, moduleId = Dadabase.DatabaseManager:GetRandomContent("wipe", group or "party")
            local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
            SendChatMessage(prefix .. content, "GUILD")
        end

    elseif msg == "status" then
        print("Tarball's Dadabase Status:")
        print("  Version: " .. Dadabase.VERSION)
        print("  Debug: " .. tostring(TarballsDadabaseDB.debug))
        print("  Cooldown: " .. TarballsDadabaseDB.cooldown .. " seconds")
        print("  Total content: " .. Dadabase.DatabaseManager:GetTotalContentCount())
        print("  In encounter: " .. tostring(encounterActive))
        local inInstance, instanceType = IsInInstance()
        print("  Instance type: " .. tostring(instanceType))

        -- Module status
        for moduleId, module in pairs(Dadabase.DatabaseManager.modules) do
            local moduleDB = TarballsDadabaseDB.modules[moduleId]
            if moduleDB then
                local content = Dadabase.DatabaseManager:GetEffectiveContent(moduleId)
                print("  [" .. module.name .. "] " .. (moduleDB.enabled and "ON" or "OFF") .. " - " .. #content .. " items")
            end
        end

    else
        print("Tarball's Dadabase commands:")
        print("  /dadabase - Open config panel")
        print("  /dadabase version")
        print("  /dadabase on - Enable all modules")
        print("  /dadabase off - Disable all modules")
        print("  /dadabase debug")
        print("  /dadabase cooldown <seconds>")
        print("  /dadabase say - Send content to party/raid/say")
        print("  /dadabase guild - Send content to guild chat")
        print("  /dadabase status")
    end
end
