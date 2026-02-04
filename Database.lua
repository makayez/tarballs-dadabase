-- Database.lua - Generic content database manager

Dadabase = Dadabase or {}
Dadabase.DatabaseManager = {}

local DB = Dadabase.DatabaseManager

-- Registered modules
DB.modules = {}

-- Content cache for performance (especially with 1100+ jokes)
DB.contentCache = {}

-- ============================================================================
-- Utility Functions
-- ============================================================================

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

        -- Ensure all settings exist (including legacy fields for backward compatibility)
        if moduleDB.triggers == nil then moduleDB.triggers = {} end  -- Legacy: preserved for old SavedVariables
        if moduleDB.groups == nil then moduleDB.groups = {} end
        if moduleDB.userAdditions == nil then moduleDB.userAdditions = {} end
        if moduleDB.userDeletions == nil then moduleDB.userDeletions = {} end
        if moduleDB.dbVersion == nil then moduleDB.dbVersion = 0 end
        if moduleDB.prefixEnabled == nil then moduleDB.prefixEnabled = true end
        if moduleDB.useCustomPrefix == nil then moduleDB.useCustomPrefix = false end
        if moduleDB.customPrefix == nil then moduleDB.customPrefix = "" end

        -- Update version (new defaults will be automatically included via GetEffectiveContent)
        if moduleDB.dbVersion < module.dbVersion then
            -- Invalidate cache before checking counts
            self.contentCache[moduleId] = nil

            -- Preserve both user deletions and additions
            -- New default content will appear automatically (not in deletions list)
            local deletionCount = #moduleDB.userDeletions
            local additionCount = #moduleDB.userAdditions
            local oldCount = #self:GetEffectiveContent(moduleId)

            moduleDB.dbVersion = module.dbVersion

            -- Invalidate cache again after version change
            self.contentCache[moduleId] = nil

            local newCount = #self:GetEffectiveContent(moduleId)
            local addedCount = newCount - oldCount

            if TarballsDadabaseDB.debug then
                print(module.name .. ": Updated to version " .. module.dbVersion)
                print("  - Preserved " .. deletionCount .. " user deletions")
                print("  - Preserved " .. additionCount .. " user additions")
                print("  - Added " .. addedCount .. " new default items")
                print("  - Total content now: " .. newCount)
            end
        end
    end
end

-- ============================================================================
-- Content Retrieval
-- ============================================================================

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

    -- Random adjectives to inject into prefixes (40 most fitting)
    local adjectives = {
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

    -- Bounds checking - fallback if adjectives table is empty or corrupted
    if #adjectives == 0 then
        return ""
    end

    local randomAdjective = adjectives[math.random(#adjectives)]

    -- Determine a/an based on first letter
    local firstLetter = randomAdjective:sub(1, 1):lower()
    local vowels = {a = true, e = true, i = true, o = true, u = true}
    local article = vowels[firstLetter] and "an" or "a"

    local prefixes = {
        dadjokes = "And now, for " .. article .. " " .. randomAdjective .. " dad joke: ",
        demotivational = "And now, for " .. article .. " " .. randomAdjective .. " motivational quote: ",
        guildquotes = "And now, for some " .. randomAdjective .. " famous words from a friend: "
    }
    return prefixes[moduleId] or ""
end

function DB:GetRandomContent(trigger, group, ignoreTriggers)
    -- Build pool of all matching content from enabled modules
    -- Each entry is {content = "text", moduleId = "id"}
    local contentPool = {}

    -- Check if database is initialized
    if not TarballsDadabaseDB or not TarballsDadabaseDB.modules then
        return "The Dadabase is empty. This wipe is now canon.", "unknown"
    end

    for moduleId, _ in pairs(self.modules) do
        local moduleDB = TarballsDadabaseDB.modules[moduleId]

        if moduleDB and moduleDB.enabled then
            local shouldInclude = false

            if ignoreTriggers then
                -- For manual commands, ignore group settings
                shouldInclude = true
            else
                -- Check if this module matches the group (wipe trigger is implicit when module is enabled)
                local groupMatch = moduleDB.groups[group] == true
                shouldInclude = groupMatch
            end

            if shouldInclude then
                -- Add all effective content from this module to the pool
                local content = self:GetEffectiveContent(moduleId)
                for _, item in ipairs(content) do
                    table.insert(contentPool, {content = item, moduleId = moduleId})
                end
            end
        end
    end

    -- Return random item from pool
    if #contentPool == 0 then
        -- Return fallback with first enabled module ID (or "unknown" if none)
        local fallbackModuleId = "unknown"
        for moduleId, _ in pairs(self.modules) do
            local moduleDB = TarballsDadabaseDB.modules[moduleId]
            if moduleDB and moduleDB.enabled then
                fallbackModuleId = moduleId
                break
            end
        end
        return "The Dadabase is empty. This wipe is now canon.", fallbackModuleId
    end

    local selected = contentPool[math.random(#contentPool)]
    return selected.content, selected.moduleId
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

        -- Limit prefix length (50 characters max to leave room for content)
        if #prefix > 50 then
            prefix = prefix:sub(1, 50)
        end

        TarballsDadabaseDB.modules[moduleId].customPrefix = prefix
    end
end

function DB:SetEffectiveContent(moduleId, newContent)
    -- Validate inputs
    if type(moduleId) ~= "string" then
        error("SetEffectiveContent: moduleId must be a string, got " .. type(moduleId))
        return
    end

    if type(newContent) ~= "table" then
        error("SetEffectiveContent: newContent must be a table, got " .. type(newContent))
        return
    end

    local module = self.modules[moduleId]
    local moduleDB = TarballsDadabaseDB.modules[moduleId]

    if not module then
        error("SetEffectiveContent: module not found: " .. tostring(moduleId))
        return
    end

    if not moduleDB then
        error("SetEffectiveContent: moduleDB not initialized for: " .. tostring(moduleId))
        return
    end

    -- Build set of new content for fast lookup
    local newContentSet = {}
    for _, item in ipairs(newContent) do
        if type(item) ~= "string" then
            error("SetEffectiveContent: all content items must be strings, found " .. type(item))
            return
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
