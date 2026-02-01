-- Database.lua - Generic content database manager

Dadabase = Dadabase or {}
Dadabase.DatabaseManager = {}

local DB = Dadabase.DatabaseManager

-- Registered modules
DB.modules = {}

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

        if not moduleDB then
            -- First install - create module DB with defaults
            TarballsDadabaseDB.modules[moduleId] = {
                enabled = module.defaultSettings.enabled or false,
                triggers = module.defaultSettings.triggers or {},
                groups = module.defaultSettings.groups or {},
                userAdditions = {},
                userDeletions = {},
                dbVersion = module.dbVersion
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

                print(module.name .. ": Migrated to new content tracking system")
            end
        end

        -- Ensure all settings exist
        if moduleDB.triggers == nil then moduleDB.triggers = {} end
        if moduleDB.groups == nil then moduleDB.groups = {} end
        if moduleDB.userAdditions == nil then moduleDB.userAdditions = {} end
        if moduleDB.userDeletions == nil then moduleDB.userDeletions = {} end
        if moduleDB.dbVersion == nil then moduleDB.dbVersion = 0 end

        -- Update version (new defaults will be automatically included via GetEffectiveContent)
        if moduleDB.dbVersion < module.dbVersion then
            -- Clear user deletions on version upgrade to get new default content
            -- User additions are preserved
            local deletionCount = #moduleDB.userDeletions
            moduleDB.userDeletions = {}

            moduleDB.dbVersion = module.dbVersion
            if deletionCount > 0 then
                print(module.name .. ": Updated to version " .. module.dbVersion .. " (restored " .. deletionCount .. " previously removed items)")
            else
                print(module.name .. ": Updated to version " .. module.dbVersion)
            end
        end
    end
end

-- ============================================================================
-- Content Retrieval
-- ============================================================================

function DB:GetEffectiveContent(moduleId)
    local module = self.modules[moduleId]
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

    return effective
end

function DB:GetTotalContentCount()
    local total = 0
    for moduleId, _ in pairs(self.modules) do
        local content = self:GetEffectiveContent(moduleId)
        total = total + #content
    end
    return total
end

function DB:GetContentPrefix(moduleId)
    -- Random adjectives to inject into prefixes
    local adjectives = {
        "uplifting",
        "inspiring",
        "satisfying",
        "heartwarming",
        "gratifying",
        "enlightening",
        "encouraging",
        "rewarding",
        "fulfilling",
        "refreshing",
        "invigorating",
        "delightful",
        "wonderful",
        "magnificent",
        "spectacular",
        "amazing",
        "breathtaking",
        "brilliant",
        "captivating",
        "charming",
        "dazzling",
        "empowering",
        "exceptional",
        "extraordinary",
        "fabulous",
        "glorious",
        "incredible",
        "legendary",
        "marvelous",
        "motivating",
        "outstanding",
        "phenomenal",
        "powerful",
        "remarkable",
        "sensational",
        "splendid",
        "stirring",
        "stunning",
        "sublime",
        "superb",
        "tremendous",
        "triumphant",
        "upbeat",
        "vibrant",
        "awe-inspiring",
        "life-changing",
        "thought-provoking",
        "soul-stirring",
        "mind-blowing",
        "game-changing"
    }

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

function DB:GetRandomContent(trigger, group)
    -- Build pool of all matching content from enabled modules
    -- Each entry is {content = "text", moduleId = "id"}
    local contentPool = {}

    for moduleId, _ in pairs(self.modules) do
        local moduleDB = TarballsDadabaseDB.modules[moduleId]

        if moduleDB and moduleDB.enabled then
            -- Check if this module matches the trigger
            local triggerMatch = moduleDB.triggers[trigger] == true

            -- Check if this module matches the group
            local groupMatch = moduleDB.groups[group] == true

            if triggerMatch and groupMatch then
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
        return "The Dadabase is empty. This wipe is now canon.", nil
    end

    local selected = contentPool[math.random(#contentPool)]
    return selected.content, selected.moduleId
end

function DB:GetModuleSettings(moduleId)
    return TarballsDadabaseDB.modules[moduleId]
end

function DB:SetModuleEnabled(moduleId, enabled)
    if TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].enabled = enabled
    end
end

function DB:SetModuleTrigger(moduleId, trigger, enabled)
    if TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].triggers[trigger] = enabled
    end
end

function DB:SetModuleGroup(moduleId, group, enabled)
    if TarballsDadabaseDB.modules[moduleId] then
        TarballsDadabaseDB.modules[moduleId].groups[group] = enabled
    end
end

function DB:SetEffectiveContent(moduleId, newContent)
    local module = self.modules[moduleId]
    local moduleDB = TarballsDadabaseDB.modules[moduleId]

    if not module or not moduleDB then
        return
    end

    -- Build set of new content for fast lookup
    local newContentSet = {}
    for _, item in ipairs(newContent) do
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
end

-- Legacy function for backward compatibility
function DB:AddContent(moduleId, content)
    if TarballsDadabaseDB.modules[moduleId] then
        table.insert(TarballsDadabaseDB.modules[moduleId].userAdditions, content)
    end
end

-- Legacy function for backward compatibility
function DB:RemoveContent(moduleId, index)
    local effective = self:GetEffectiveContent(moduleId)
    if effective[index] then
        local itemToRemove = effective[index]
        local module = self.modules[moduleId]
        local moduleDB = TarballsDadabaseDB.modules[moduleId]

        -- Check if it's a default item
        local isDefault = false
        for _, defaultItem in ipairs(module.defaultContent) do
            if defaultItem == itemToRemove then
                isDefault = true
                break
            end
        end

        if isDefault then
            -- Add to deletions
            table.insert(moduleDB.userDeletions, itemToRemove)
        else
            -- Remove from additions
            for i, item in ipairs(moduleDB.userAdditions) do
                if item == itemToRemove then
                    table.remove(moduleDB.userAdditions, i)
                    break
                end
            end
        end
    end
end

-- Legacy function for backward compatibility
function DB:GetContent(moduleId)
    return self:GetEffectiveContent(moduleId)
end
