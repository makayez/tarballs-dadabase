-- Core.lua - Main addon logic

local ADDON_NAME = ...
Dadabase = Dadabase or {}
Dadabase.VERSION = "0.6.0-alpha.1"

-- Constants
local DEFAULT_COOLDOWN = 10
-- Chat limits live in Database.lua so the content editor's per-line cap can be
-- derived from the longest generated prefix instead of being hardcoded twice.
local MAX_CHAT_MESSAGE_LENGTH = Dadabase.MAX_CHAT_MESSAGE_LENGTH

-- ============================================================================
-- Load Confirmation
-- ============================================================================

-- Per-module descriptor pools. The generic list reads badly for non-joke content
-- ("30 knee-slappers" for guild quotes), so each module gets its own vocabulary.
local contentTypeNames = {
    dadjokes = {
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
    },
    warcraftjokes = {
        "Azeroth groaners",
        "Warcraft groaners",
        "puns of Azeroth",
        "goblin-engineered puns",
        "lore-accurate groaners",
        "raid-night groaners",
        "LFD groaners",
        "punny one-liners",
        "Shazam-tier groaners",
        "Lag-terning jokes",
        "class-flavoured puns",
        "punny gems",
        "knee-slappers of Azeroth",
        "groaners for the raid",
        "puns for the party",
        "punny classics",
        "one-liners from Azeroth",
        "puns that hit like a Charge",
        "groaners worthy of a Warbringer",
        "puns for the guild hall"
    },
    demotivational = {
        "demotivational sayings",
        "words of despair",
        "pessimistic proverbs",
        "gloomy gems",
        "downer sayings",
        "gallows humor",
        "cynical one-liners",
        "salty truths",
        "words of woe",
        "defeatist proverbs",
        "wipe-night wisdom",
        "repair-bill wisdom",
        "gloomy one-liners",
        "cynical classics",
        "pessimistic pearls",
        "downer classics",
        "words of doubt",
        "salty sayings"
    },
    guildquotes = {
        "pearls of wisdom",
        "words of wisdom",
        "pearls",
        "gems",
        "quotable moments",
        "classic lines",
        "legendary sayings",
        "timeless quotes",
        "memorable lines",
        "hall of fame quotes",
        "immortal words",
        "beloved sayings",
        "profound words",
        "words to live by",
        "famous last words",
        "quote vault entries",
        "quote hall classics",
        "memorable quotes",
        "the archives",
        "memorable sayings"
    },
    -- Fallback for any module without its own pool.
    default = { "items", "entries", "lines", "sayings" }
}

local function GetRandomContentTypeName(moduleId)
    local names = contentTypeNames[moduleId] or contentTypeNames.default
    return names[math.random(#names)]
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
    TarballsDadabaseDB.soundEffect = Dadabase.DefaultSound
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

-- Returns the content group (used for module filtering) and the chat type to send
-- to. Shared by the automatic trigger and the manual commands so the
-- instance/raid/party branch exists once. chatType is nil when not in a group.
local function GetCurrentGroup()
    -- Check if in instance group first (LFR, LFD, Ritual Sites, etc.)
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        -- Distinguish LFR (raid) from LFG (party/scenario) by checking raid status
        if IsInRaid() then
            return "raid", "INSTANCE_CHAT"
        end
        return "party", "INSTANCE_CHAT"
    elseif IsInRaid() then
        return "raid", "RAID"
    elseif IsInGroup() then
        return "party", "PARTY"
    end
    return nil, nil
end

-- Prefix + content, validated against the single-message chat limit.
-- Returns the message and whether it had to be truncated.
local function BuildMessage(moduleId, content)
    local message = Dadabase.DatabaseManager:GetContentPrefix(moduleId) .. content
    if #message > MAX_CHAT_MESSAGE_LENGTH then
        -- UTF-8 safe, so we never split a multibyte glyph
        return Dadabase.DatabaseManager:TruncateToBytes(message, MAX_CHAT_MESSAGE_LENGTH), true
    end
    return message, false
end

local function RecordUsage(moduleId)
    TarballsDadabaseDB.stats[moduleId] = (TarballsDadabaseDB.stats[moduleId] or 0) + 1
end

local function PlaySelectedSound()
    if not TarballsDadabaseDB.soundEnabled or not TarballsDadabaseDB.soundEffect then
        return
    end
    local success, err = pcall(PlaySound, TarballsDadabaseDB.soundEffect)
    if not success then
        DebugPrint("Failed to play sound: " .. tostring(err))
    end
end

local function SendContent(message, chatType)
    if pendingMessage then
        DebugPrint("Message already pending, skipping")
        return
    end

    pendingMessage = true
    DebugPrint("Sending content to " .. (chatType or "local") .. " (" .. #message .. " bytes)")

    -- Delay message to avoid protected context (ADDON_ACTION_FORBIDDEN)
    -- 0.5s is needed to reliably escape the protected frame; 0.1s was insufficient for party and raid wipes
    C_Timer.After(0.5, function()
        if chatType then
            SendChatMessage(message, chatType)
        else
            -- Defensive fallback: the automatic path always has a group, so chatType
            -- is set. Kept so a nil chat type can never silently drop the message.
            print(message)
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

        local message, truncated = BuildMessage(moduleId, content)
        if truncated then
            DebugPrint("Message truncated to " .. MAX_CHAT_MESSAGE_LENGTH .. " bytes")
        end

        SendContent(message, chatType)
        RecordUsage(moduleId)
        PlaySelectedSound()
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

            -- Build module tabs now that per-module SavedVariables defaults exist
            if Dadabase.Config then
                Dadabase.Config:BuildTabs()
                Dadabase.Config:RegisterInterfaceOptions()
            end

            -- Print load message. Empty databases are omitted so a fresh install
            -- (Guild Quotes unpopulated) does not advertise "0 pearls of wisdom".
            local summary = Dadabase.DatabaseManager:GetContentSummary()
            if #summary == 0 then
                print("Tarball's Dadabase v" .. Dadabase.VERSION .. " loaded: no content yet. Type /dadabase to configure.")
            else
                local parts = {}
                for _, entry in ipairs(summary) do
                    table.insert(parts, entry.count .. " " .. GetRandomContentTypeName(entry.moduleId))
                end
                print("Tarball's Dadabase v" .. Dadabase.VERSION .. " loaded: " .. table.concat(parts, ", ") .. ". Type /dadabase to configure.")
            end

            DebugPrint("Dadabase ADDON_LOADED")
            for _, entry in ipairs(summary) do
                DebugPrint("  " .. entry.name .. ": " .. entry.count)
            end
            DebugPrint("  Total content: " .. Dadabase.DatabaseManager:GetTotalContentCount())
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

    local message, truncated = BuildMessage(moduleId, content)
    if truncated then
        print("Warning: Message too long, truncated to " .. MAX_CHAT_MESSAGE_LENGTH .. " bytes")
    end

    -- Commit the cooldown only once we are about to send, so a "no content"
    -- early return does not consume the 3s window.
    lastManualCommandTime = now

    -- Send directly without timers to avoid taint
    SendChatMessage(message, chatChannel)

    RecordUsage(moduleId)
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_TARBALLSDADABASE1 = "/dadabase"

SlashCmdList["TARBALLSDADABASE"] = function(msg)
    msg = (msg or ""):lower():trim()

    local cooldownValue = msg:match("^cooldown%s+(%d+)$")

    if msg == "" then
        if Dadabase.Config then
            Dadabase.Config:Toggle()
        end

    elseif msg == "version" then
        print("Tarball's Dadabase version " .. Dadabase.VERSION)

    elseif msg == "on" then
        -- Enable all modules
        for moduleId in pairs(Dadabase.DatabaseManager.modules) do
            Dadabase.DatabaseManager:SetModuleEnabled(moduleId, true)
        end
        print("Tarball's Dadabase enabled (all modules).")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "off" then
        -- Disable all modules
        for moduleId in pairs(Dadabase.DatabaseManager.modules) do
            Dadabase.DatabaseManager:SetModuleEnabled(moduleId, false)
        end
        print("Tarball's Dadabase disabled (all modules).")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "debug" then
        TarballsDadabaseDB.debug = not TarballsDadabaseDB.debug
        print("Tarball's Dadabase debug mode " .. (TarballsDadabaseDB.debug and "enabled" or "disabled") .. ".")

    elseif cooldownValue then
        local value = math.min(tonumber(cooldownValue), 600)
        TarballsDadabaseDB.cooldown = value
        print("Tarball's Dadabase cooldown set to " .. value .. " seconds.")
        if Dadabase.Config then Dadabase.Config:Refresh() end

    elseif msg == "say" then
        local _, chatType = GetCurrentGroup()
        SendManualContent(chatType or "SAY")

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
                local count = Dadabase.DatabaseManager:GetContentCount(moduleId)
                local stats = TarballsDadabaseDB.stats[moduleId] or 0
                table.insert(statusLines, "  [" .. module.name .. "] " .. (moduleDB.enabled and "ON" or "OFF") .. " - " .. count .. " items, " .. stats .. " told")
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
