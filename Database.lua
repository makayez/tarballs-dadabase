-- Database.lua - Generic content database manager

Dadabase = Dadabase or {}
Dadabase.DatabaseManager = {}

local DB = Dadabase.DatabaseManager

-- Registered modules
DB.modules = {}

-- Content cache for performance (especially with 1100+ jokes)
DB.contentCache = {}

-- Immutable constants for default prefix generation. Hoisted to file scope so
-- they are allocated once at load instead of rebuilt on every GetContentPrefix call.
local PREFIX_ADJECTIVES = {
    "uplifting",
    "inspiring",
    "heartwarming",
    "enlightening",
    "encouraging",
    "delightful",
    "magnificent",
    "spectacular",
    "brilliant",
    "empowering",
    "extraordinary",
    "legendary",
    "outstanding",
    "phenomenal",
    "remarkable",
    "triumphant",
    "awe-inspiring",
    "life-changing",
    "mind-blowing",
    "game-changing",
    "electrifying",
    "exhilarating",
    "mesmerizing",
    "enchanting",
    "spellbinding",
    "fascinating",
    "gripping",
    "compelling",
    "unforgettable",
    "timeless",
    "priceless",
    "unparalleled",
    "supreme",
    "transcendent",
    "majestic",
    "epic",
    "heroic",
    "bold",
    "daring",
    "intrepid"
}

local PREFIX_VOWELS = {a = true, e = true, i = true, o = true, u = true}

-- ============================================================================
-- Utility Functions
-- ============================================================================

-- Truncate a string to at most maxBytes bytes without splitting a multibyte
-- UTF-8 codepoint. Lua's # and string.sub operate on bytes; cutting mid-sequence
-- would leave an invalid trailing byte that renders as a garbled glyph in chat.
function DB:TruncateToBytes(text, maxBytes)
    if not text then
        return ""
    end
    if #text <= maxBytes then
        return text
    end

    -- Back up while the first byte we would drop (at i+1) is a UTF-8 continuation
    -- byte (0x80-0xBF), so we never cut a codepoint in half.
    local i = maxBytes
    while i > 0 do
        local b = text:byte(i + 1)
        if not b or b < 0x80 or b >= 0xC0 then
            break
        end
        i = i - 1
    end

    return text:sub(1, i)
end

-- Sanitize WoW formatting codes from user input
function DB:SanitizeText(text)
    if not text or text == "" then
        return ""
    end

    text = tostring(text)

    -- Remove WoW formatting codes
    text = text:gsub("|c%x%x%x%x%x%x%x%x", "")  -- Remove color codes (8 hex digits)
    text = text:gsub("|H.-|h.-|h", "")  -- Remove hyperlinks
    text = text:gsub("|r", "")  -- Remove color resets
    text = text:gsub("|T.-|t", "")  -- Remove textures
    text = text:gsub("|K.-|k", "")  -- Remove encrypted text
    text = text:gsub("|n", "")  -- Remove line breaks

    return text:trim()
end

-- ============================================================================
-- Module Registration
-- ============================================================================

function DB:RegisterModule(moduleId, config)
    if self.modules[moduleId] then
        error("Module '" .. moduleId .. "' already registered!")
    end

    self.modules[moduleId] = {
        id = moduleId,
        name = config.name,
        defaultContent = config.defaultContent or {},
        dbVersion = config.dbVersion or 1,
        defaultSettings = config.defaultSettings or {}
    }
end

-- ============================================================================
-- Database Initialization
-- ============================================================================

function DB:Initialize()
    TarballsDadabaseDB = TarballsDadabaseDB or {}
    TarballsDadabaseDB.modules = TarballsDadabaseDB.modules or {}

    -- Initialize each registered module
    for moduleId, module in pairs(self.modules) do
        local moduleDB = TarballsDadabaseDB.modules[moduleId]

        if TarballsDadabaseDB.debug then
            print("[DEBUG] " .. module.name .. ": Module dbVersion=" .. module.dbVersion .. ", defaultContent=" .. #module.defaultContent)

            if not moduleDB then
                print("[DEBUG] " .. module.name .. ": First install")
            else
                print("[DEBUG] " .. module.name .. ": Existing install, saved dbVersion=" .. (moduleDB.dbVersion or 0) .. ", has content=" .. tostring(moduleDB.content ~= nil))
            end
        end

        if not moduleDB then
            -- First install - create module DB with defaults
            TarballsDadabaseDB.modules[moduleId] = {
                enabled = module.defaultSettings.enabled or false,
                groups = module.defaultSettings.groups or {},
                userAdditions = {},
                userDeletions = {},
                dbVersion = module.dbVersion,
                prefixEnabled = true,  -- Enable prefix by default
                useCustomPrefix = false,  -- Use default prefix by default
                customPrefix = ""  -- Empty custom prefix by default
            }
            moduleDB = TarballsDadabaseDB.modules[moduleId]
        else
            -- Migration: Convert old 'content' array to new structure
            if moduleDB.content then
                -- Build set of default content for comparison
                local defaultSet = {}
                for _, item in ipairs(module.defaultContent) do
                    defaultSet[item] = true
                end

                -- Anything in content that's NOT in defaults = user addition
                moduleDB.userAdditions = {}
                for _, item in ipairs(moduleDB.content) do
                    if not defaultSet[item] then
                        table.insert(moduleDB.userAdditions, item)
                    end
                end

                -- Anything in defaults that's NOT in content = user deletion
                -- Build set of existing content for fast lookup
                local contentSet = {}
                for _, item in ipairs(moduleDB.content) do
                    contentSet[item] = true
                end

                moduleDB.userDeletions = {}
                for _, item in ipairs(module.defaultContent) do
                    if not contentSet[item] then
                        table.insert(moduleDB.userDeletions, item)
                    end
                end

                -- Remove old content field
                moduleDB.content = nil

                if TarballsDadabaseDB.debug then
                    print(module.name .. ": Migrated to new content tracking system")
                end
            end
        end

        -- Prune the legacy 'triggers' field if an old SavedVariables profile still
        -- carries it. It is never read anymore (group matching uses moduleDB.groups
        -- and the wipe trigger is implicit when a module is enabled).
        moduleDB.triggers = nil

        -- Ensure all settings exist
        if moduleDB.groups == nil then moduleDB.groups = {} end
        if moduleDB.userAdditions == nil then moduleDB.userAdditions = {} end
        if moduleDB.userDeletions == nil then moduleDB.userDeletions = {} end
        if moduleDB.dbVersion == nil then moduleDB.dbVersion = 0 end
        if moduleDB.prefixEnabled == nil then moduleDB.prefixEnabled = true end
        if moduleDB.useCustomPrefix == nil then moduleDB.useCustomPrefix = false end
        if moduleDB.customPrefix == nil then moduleDB.customPrefix = "" end

        -- Update version (new defaults will be automatically included via GetEffectiveContent)
        if moduleDB.dbVersion < module.dbVersion then
            moduleDB.dbVersion = module.dbVersion

            -- Invalidate cache so the next read rebuilds effective content lazily.
            self.contentCache[moduleId] = nil

            if TarballsDadabaseDB.debug then
                -- Materialize the count only when debug is on (avoids building and
                -- discarding the full content table on every version bump).
                local newCount = #self:GetEffectiveContent(moduleId)
                print(module.name .. ": Updated to version " .. module.dbVersion)
                print("  - Preserved " .. #moduleDB.userDeletions .. " user deletions")
                print("  - Preserved " .. #moduleDB.userAdditions .. " user additions")
                print("  - Total content now: " .. newCount)
            end
        end
    end
end

-- ============================================================================
-- Content Retrieval
-- ============================================================================

-- Returns the module's effective content list (defaults minus user deletions,
-- plus user additions). The returned table is the SHARED cached instance and
-- MUST be treated as read-only -- mutating it would corrupt the cache for all
-- subsequent reads until the next invalidation.
function DB:GetEffectiveContent(moduleId)
    -- Return cached content if available
    if self.contentCache[moduleId] then
        return self.contentCache[moduleId]
    end

    local module = self.modules[moduleId]

    -- Check if SavedVariables is initialized
    if not TarballsDadabaseDB or not TarballsDadabaseDB.modules then
        return {}
    end

    local moduleDB = TarballsDadabaseDB.modules[moduleId]

    if not module or not moduleDB then
        return {}
    end

    local effective = {}
    local deletionSet = {}

    -- Build fast lookup of deleted items
    for _, item in ipairs(moduleDB.userDeletions) do
        deletionSet[item] = true
    end

    -- Add default content (excluding deleted ones)
    for _, item in ipairs(module.defaultContent) do
        if not deletionSet[item] then
            table.insert(effective, item)
        end
    end

    -- Add user's custom additions
    for _, item in ipairs(moduleDB.userAdditions) do
        table.insert(effective, item)
    end

    -- Cache the result for future calls
    self.contentCache[moduleId] = effective

    return effective
end

function DB:GetTotalContentCount()
    local total = 0
    if not self.modules then
        return 0
    end
    for moduleId, _ in pairs(self.modules) do
        local content = self:GetEffectiveContent(moduleId)
        total = total + #content
    end
    return total
end

function DB:GetContentPrefix(moduleId)
    -- Check if prefix is enabled for this module
    local moduleDB = TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId]

    if not moduleDB or not moduleDB.prefixEnabled then
        return ""
    end

    -- Use custom prefix if enabled
    if moduleDB.useCustomPrefix and moduleDB.customPrefix and moduleDB.customPrefix ~= "" then
        -- Sanitize custom prefix
        local prefix = self:SanitizeText(moduleDB.customPrefix)

        -- Ensure prefix ends with a space
        if prefix ~= "" and not prefix:match("%s$") then
            prefix = prefix .. " "
        end

        return prefix
    end

    -- Bounds checking - fallback if adjectives table is empty or corrupted
    if #PREFIX_ADJECTIVES == 0 then
        return ""
    end

    local randomAdjective = PREFIX_ADJECTIVES[math.random(#PREFIX_ADJECTIVES)]

    if moduleId == "guildquotes" then
        return "And now, for some " .. randomAdjective .. " famous words from a friend: "
    end

    -- Determine a/an based on first letter
    local firstLetter = randomAdjective:sub(1, 1):lower()
    local article = PREFIX_VOWELS[firstLetter] and "an" or "a"

    local prefixes = {
        dadjokes = "And now, for " .. article .. " " .. randomAdjective .. " dad joke: ",
        demotivational = "And now, for " .. article .. " " .. randomAdjective .. " motivational quote: "
    }
    return prefixes[moduleId] or ""
end

function DB:GetRandomContent(group, ignoreTriggers)
    -- Check if database is initialized
    if not TarballsDadabaseDB or not TarballsDadabaseDB.modules then
        return nil, nil
    end

    -- Two-step weighted pick to avoid materializing the entire content pool
    -- (1100+ jokes) on every trigger: first choose a module weighted by its item
    -- count, then pick a uniform-random item within that module. This is
    -- distribution-equivalent to a flat uniform pick over all items
    -- (P(item) = (weight_m / total) * (1 / weight_m) = 1 / total) but allocates
    -- nothing per item and reuses the cached content arrays directly.
    local matching = {}
    local total = 0

    for moduleId, _ in pairs(self.modules) do
        local moduleDB = TarballsDadabaseDB.modules[moduleId]

        if moduleDB and moduleDB.enabled then
            -- Manual commands ignore group settings; automatic triggers require a
            -- group match (the wipe trigger is implicit when the module is enabled)
            local shouldInclude = ignoreTriggers or (moduleDB.groups[group] == true)

            if shouldInclude then
                local content = self:GetEffectiveContent(moduleId)
                local count = #content
                if count > 0 then
                    table.insert(matching, {content = content, moduleId = moduleId, weight = count})
                    total = total + count
                end
            end
        end
    end

    if total == 0 then
        return nil, nil
    end

    -- Cumulative-weight walk: r in [1, total] lands in exactly one module's band
    local r = math.random(total)
    for _, entry in ipairs(matching) do
        if r <= entry.weight then
            return entry.content[math.random(entry.weight)], entry.moduleId
        end
        r = r - entry.weight
    end

    -- Unreachable: weights sum to total and r <= total
    return nil, nil
end

function DB:GetModuleSettings(moduleId)
    if not TarballsDadabaseDB or not TarballsDadabaseDB.modules then
        return nil
    end
    return TarballsDadabaseDB.modules[moduleId]
end

function DB:SetModuleEnabled(moduleId, enabled)
    if TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].enabled = enabled
    end
end

function DB:SetModuleGroup(moduleId, group, enabled)
    if TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].groups[group] = enabled
    end
end

function DB:SetPrefixEnabled(moduleId, enabled)
    if TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].prefixEnabled = enabled
    end
end

function DB:SetUseCustomPrefix(moduleId, enabled)
    if TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].useCustomPrefix = enabled
    end
end

function DB:SetCustomPrefix(moduleId, prefix)
    if TarballsDadabaseDB and TarballsDadabaseDB.modules and TarballsDadabaseDB.modules[moduleId] then
        -- Sanitize and validate prefix
        prefix = self:SanitizeText(prefix or "")

        -- Limit prefix length to 50 bytes to leave room for content. UTF-8 safe so
        -- a multibyte prefix is not cut mid-codepoint (the edit box limits to 50
        -- characters, which can exceed 50 bytes for non-ASCII input).
        prefix = self:TruncateToBytes(prefix, 50)

        TarballsDadabaseDB.modules[moduleId].customPrefix = prefix
    end
end

function DB:SetEffectiveContent(moduleId, newContent)
    -- Validate inputs
    if type(moduleId) ~= "string" then
        error("SetEffectiveContent: moduleId must be a string, got " .. type(moduleId))
    end

    if type(newContent) ~= "table" then
        error("SetEffectiveContent: newContent must be a table, got " .. type(newContent))
    end

    local module = self.modules[moduleId]
    local moduleDB = TarballsDadabaseDB.modules[moduleId]

    if not module then
        error("SetEffectiveContent: module not found: " .. tostring(moduleId))
    end

    if not moduleDB then
        error("SetEffectiveContent: moduleDB not initialized for: " .. tostring(moduleId))
    end

    -- Build set of new content for fast lookup
    local newContentSet = {}
    for _, item in ipairs(newContent) do
        if type(item) ~= "string" then
            error("SetEffectiveContent: all content items must be strings, found " .. type(item))
        end
        newContentSet[item] = true
    end

    -- Build set of default content for fast lookup
    local defaultSet = {}
    for _, item in ipairs(module.defaultContent) do
        defaultSet[item] = true
    end

    -- Clear existing changes
    moduleDB.userAdditions = {}
    moduleDB.userDeletions = {}

    -- Find additions: items in newContent that are NOT in defaults
    for _, item in ipairs(newContent) do
        if not defaultSet[item] then
            table.insert(moduleDB.userAdditions, item)
        end
    end

    -- Find deletions: items in defaults that are NOT in newContent
    for _, item in ipairs(module.defaultContent) do
        if not newContentSet[item] then
            table.insert(moduleDB.userDeletions, item)
        end
    end

    -- Invalidate cache since content changed
    self.contentCache[moduleId] = nil
end
