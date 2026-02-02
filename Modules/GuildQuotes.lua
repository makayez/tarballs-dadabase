-- Modules/GuildQuotes.lua - Guild Member Quotes Module

Dadabase = Dadabase or {}

-- No default quotes - this is entirely user-populated
local defaultQuotes = {}

-- Register with Database Manager
Dadabase.DatabaseManager:RegisterModule("guildquotes", {
    name = "Guild Quotes",
    defaultContent = defaultQuotes,
    dbVersion = 1,
    defaultSettings = {
        enabled = false,
        triggers = {
            wipe = false,
            death = false
        },
        groups = {
            raid = false,
            party = false
        }
    }
})

-- Register config tab
Dadabase.Config:RegisterModuleTab("guildquotes", {
    name = "Guild Quotes",
    buildContent = function(container, moduleId)
        Dadabase.Config:BuildModuleContent(container, moduleId)
    end
})
