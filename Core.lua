-- Core.lua - Main addon logic

local ADDON_NAME = ...
Dadabase = Dadabase or {}
Dadabase.VERSION = "0.4.0"

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
    if IsInRaid() then
        return "raid"
    elseif IsInGroup() then
        return "party"
    end
    return nil
end

-- Send a message to a specific channel, splitting if needed
-- channel: "RAID", "PARTY", "SAY", "GUILD", or nil for local print
local function SendMessage(message, channel)
    if pendingMessage then
        DebugPrint("Message already pending, skipping")
        return
    end

    pendingMessage = true
    DebugPrint("Sending message to " .. (channel or "local") .. " (" .. #message .. " chars)")

    -- Split message if it exceeds max length
    if #message > MAX_CHAT_MESSAGE_LENGTH then
        DebugPrint("Message too long, splitting into multiple messages")

        local messages = {}
        local remainingText = message
        local maxIterations = 20  -- Safety limit to prevent infinite loops

        while #remainingText > 0 and #messages < maxIterations do
            if #remainingText <= MAX_CHAT_MESSAGE_LENGTH then
                -- Last chunk fits within limit
                if remainingText:trim() ~= "" then
                    table.insert(messages, remainingText:trim())
                end
                break
            else
                -- Find a good break point (space, period, comma)
                local breakPoint = MAX_CHAT_MESSAGE_LENGTH
                local searchStart = math.max(1, MAX_CHAT_MESSAGE_LENGTH - 50)

                -- Look for a space, period, comma, or other punctuation near the limit
                local lastSpace = remainingText:sub(searchStart, MAX_CHAT_MESSAGE_LENGTH):match(".*()[%s%.,%!%?;:]")
                if lastSpace then
                    breakPoint = searchStart + lastSpace - 1
                else
                    -- No punctuation found, try to break at any whitespace
                    local anySpace = remainingText:sub(1, MAX_CHAT_MESSAGE_LENGTH):match(".*()%s")
                    if anySpace then
                        breakPoint = anySpace - 1
                    else
                        -- No whitespace at all, force break at limit (edge case for very long words)
                        breakPoint = MAX_CHAT_MESSAGE_LENGTH
                    end
                end

                -- Extract chunk and validate it's not empty
                local chunk = remainingText:sub(1, breakPoint):trim()
                if chunk ~= "" then
                    table.insert(messages, chunk)
                end

                -- Move to next chunk
                remainingText = remainingText:sub(breakPoint + 1):trim()

                -- Safety check: if we're not making progress, force break
                if breakPoint == 0 or #remainingText >= #message then
                    DebugPrint("Message splitting stalled, forcing break")
                    if remainingText:trim() ~= "" then
                        table.insert(messages, remainingText:sub(1, MAX_CHAT_MESSAGE_LENGTH):trim())
                    end
                    break
                end
            end
        end

        -- Warn if we hit iteration limit
        if #messages >= maxIterations then
            DebugPrint("Warning: Message splitting hit max iterations, some content may be truncated")
        end

        DebugPrint("Split into " .. #messages .. " messages")

        -- Send first message immediately
        if #messages > 0 then
            if channel then
                SendChatMessage(messages[1], channel)
            else
                print(messages[1])
            end
        end

        -- Send remaining messages with delay
        for i = 2, #messages do
            local delay = (i - 1) * 1.5  -- 1.5 seconds between each message
            local msgIndex = i
            C_Timer.After(delay, function()
                -- Validate channel still available before sending (for group channels)
                if channel == "RAID" and not IsInRaid() then
                    DebugPrint("No longer in raid, canceling remaining messages")
                    return
                elseif channel == "PARTY" and not IsInGroup() then
                    DebugPrint("No longer in party, canceling remaining messages")
                    return
                elseif channel == "GUILD" and not IsInGuild() then
                    DebugPrint("No longer in guild, canceling remaining messages")
                    return
                end

                if channel then
                    SendChatMessage(messages[msgIndex], channel)
                else
                    print(messages[msgIndex])
                end
            end)
        end

        -- Clear pending flag after all messages are scheduled
        local totalDelay = (#messages - 1) * 1.5
        C_Timer.After(totalDelay + 0.5, function()
            pendingMessage = false
        end)
    else
        -- Send message directly (no timer) to avoid taint issues
        if channel then
            SendChatMessage(message, channel)
        else
            print(message)
        end
        pendingMessage = false
    end
end

local function SendContent(content, group)
    local channel = nil
    if group == "raid" then
        channel = "RAID"
    elseif group == "party" then
        channel = "PARTY"
    end
    SendMessage(content, channel)
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

    -- Require a group for all automatic triggers
    if not group then
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
        -- Rate limiting for manual commands (3 second cooldown)
        local now = GetTime()
        if now - lastManualCommandTime < 3 then
            print("Please wait " .. math.ceil(3 - (now - lastManualCommandTime)) .. " second(s) before using this command again.")
            return
        end
        lastManualCommandTime = now

        local content, moduleId = Dadabase.DatabaseManager:GetRandomContent(nil, nil, true)
        if not content or not moduleId then
            print("No content available. Enable at least one module in /dadabase config.")
            return
        end

        local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
        local message = prefix .. content

        -- Truncate if too long (no splitting for manual commands to avoid taint)
        if #message > MAX_CHAT_MESSAGE_LENGTH then
            print("Message too long (" .. #message .. " chars), truncating to " .. MAX_CHAT_MESSAGE_LENGTH)
            message = message:sub(1, MAX_CHAT_MESSAGE_LENGTH)
        end

        -- Send directly without timers to avoid taint
        if IsInRaid() then
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            SendChatMessage(message, "PARTY")
        else
            SendChatMessage(message, "SAY")
        end

        -- Track statistics
        if not TarballsDadabaseDB.stats[moduleId] then
            TarballsDadabaseDB.stats[moduleId] = 0
        end
        TarballsDadabaseDB.stats[moduleId] = TarballsDadabaseDB.stats[moduleId] + 1

    elseif msg == "guild" then
        if not IsInGuild() then
            print("You are not in a guild!")
            return
        end

        -- Rate limiting for manual commands (3 second cooldown)
        local now = GetTime()
        if now - lastManualCommandTime < 3 then
            print("Please wait " .. math.ceil(3 - (now - lastManualCommandTime)) .. " second(s) before using this command again.")
            return
        end
        lastManualCommandTime = now

        local content, moduleId = Dadabase.DatabaseManager:GetRandomContent(nil, nil, true)
        if not content or not moduleId then
            print("No content available. Enable at least one module in /dadabase config.")
            return
        end

        local prefix = Dadabase.DatabaseManager:GetContentPrefix(moduleId)
        local message = prefix .. content

        -- Truncate if too long (no splitting for manual commands to avoid taint)
        if #message > MAX_CHAT_MESSAGE_LENGTH then
            print("Message too long (" .. #message .. " chars), truncating to " .. MAX_CHAT_MESSAGE_LENGTH)
            message = message:sub(1, MAX_CHAT_MESSAGE_LENGTH)
        end

        -- Send directly without timers to avoid taint
        SendChatMessage(message, "GUILD")

        -- Track statistics
        if not TarballsDadabaseDB.stats[moduleId] then
            TarballsDadabaseDB.stats[moduleId] = 0
        end
        TarballsDadabaseDB.stats[moduleId] = TarballsDadabaseDB.stats[moduleId] + 1

    elseif msg == "status" then
        local inInstance, instanceType = IsInInstance()
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
        print("  /dadabase say - Send content to party/raid/say")
        print("  /dadabase guild - Send content to guild chat")
        print("  /dadabase status")
    end
end
