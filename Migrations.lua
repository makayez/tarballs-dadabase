-- Migrations.lua - one-time SavedVariables migrations

Dadabase = Dadabase or {}
Dadabase.Migrations = {}

local M = Dadabase.Migrations

-- Content that has been moved from one module to another. User deletions must
-- follow the content, otherwise a joke a user removed reappears in the destination
-- database after the split.
--
-- `items` is optional: when omitted, the destination module's default content is
-- treated as the moved set (true for the 0.6.0 Dad Jokes -> Warcraft Jokes split,
-- where the whole destination database came from the source).
M.contentMoves = {
    { from = "dadjokes", to = "warcraftjokes" }
}

function M:Run()
    if not TarballsDadabaseDB or not TarballsDadabaseDB.modules then
        return
    end

    TarballsDadabaseDB.migrations = TarballsDadabaseDB.migrations or {}

    for _, move in ipairs(self.contentMoves) do
        local key = move.from .. "->" .. move.to
        if not TarballsDadabaseDB.migrations[key] then
            self:ApplyContentMove(move, key)
        end
    end
end

function M:ApplyContentMove(move, key)
    local source = TarballsDadabaseDB.modules[move.from]
    local target = TarballsDadabaseDB.modules[move.to]

    if not source or not target then
        return
    end

    local module = Dadabase.DatabaseManager.modules[move.to]
    local items = move.items or (module and module.defaultContent) or {}

    local movedSet = {}
    for _, item in ipairs(items) do
        movedSet[item] = true
    end

    local alreadyDeleted = {}
    for _, item in ipairs(target.userDeletions) do
        alreadyDeleted[item] = true
    end

    local carried = 0
    local remaining = {}

    for _, item in ipairs(source.userDeletions) do
        if movedSet[item] then
            if not alreadyDeleted[item] then
                table.insert(target.userDeletions, item)
                alreadyDeleted[item] = true
            end
            carried = carried + 1
        else
            table.insert(remaining, item)
        end
    end

    -- Deletions that followed content out of the source module are no longer
    -- meaningful there; prune them so the saved profile stays accurate.
    source.userDeletions = remaining

    TarballsDadabaseDB.migrations[key] = true

    if carried > 0 then
        Dadabase.DatabaseManager.contentCache[move.to] = nil
        Dadabase.DatabaseManager.contentCache[move.from] = nil

        if TarballsDadabaseDB.debug then
            print("[MIGRATION] " .. key .. ": carried " .. carried .. " deletion(s) to " .. move.to)
        end
    end
end
