-- TarballsDadabase.lua
local ADDON_NAME = ...
Dadabase = Dadabase or {}
Dadabase.VERSION = "0.3.0"
Dadabase.JOKE_DB_VERSION = 1

-- ============================================================================
-- Load confirmation
-- ============================================================================

local jokeTypeNames = {
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

local function GetRandomJokeTypeName()
    return jokeTypeNames[math.random(#jokeTypeNames)]
end

-- ============================================================================
-- Frame / State
-- ============================================================================

local frame = CreateFrame("Frame")

local encounterActive = false
local lastJokeTime = 0

-- ============================================================================
-- Saved Variables (account-wide)
-- ============================================================================

TarballsDadabaseDB = TarballsDadabaseDB or {}

if TarballsDadabaseDB.enabled == nil then
    TarballsDadabaseDB.enabled = true
end

-- Cooldown in seconds (user-adjustable later if desired)
if TarballsDadabaseDB.cooldown == nil then
    TarballsDadabaseDB.cooldown = 10
end

-- Debug mode (off by default)
if TarballsDadabaseDB.debug == nil then
    TarballsDadabaseDB.debug = false
end

-- ============================================================================
-- Joke Database Management
-- ============================================================================

local function InitializeJokeDatabase()
    -- Initialize joke storage
    if not TarballsDadabaseDB.jokes then
        TarballsDadabaseDB.jokes = {}
    end

    if not TarballsDadabaseDB.customJokes then
        TarballsDadabaseDB.customJokes = {}  -- Set of custom joke indices
    end

    if not TarballsDadabaseDB.jokeDBVersion then
        TarballsDadabaseDB.jokeDBVersion = 0
    end

    -- First install or version upgrade
    if TarballsDadabaseDB.jokeDBVersion < Dadabase.JOKE_DB_VERSION then
        if #TarballsDadabaseDB.jokes == 0 then
            -- First install: copy all default jokes
            for i, joke in ipairs(Dadabase.Jokes) do
                table.insert(TarballsDadabaseDB.jokes, joke)
            end
            DebugPrint("First install: Loaded " .. #TarballsDadabaseDB.jokes .. " default jokes")
        else
            -- Upgrade: merge in new jokes that don't already exist
            local existingJokes = {}
            for _, joke in ipairs(TarballsDadabaseDB.jokes) do
                existingJokes[joke] = true
            end

            local newCount = 0
            for _, joke in ipairs(Dadabase.Jokes) do
                if not existingJokes[joke] then
                    table.insert(TarballsDadabaseDB.jokes, joke)
                    newCount = newCount + 1
                end
            end

            if newCount > 0 then
                DebugPrint("Joke database updated: Added " .. newCount .. " new jokes")
                print("Tarball's Dadabase: " .. newCount .. " new jokes added!")
            end
        end

        TarballsDadabaseDB.jokeDBVersion = Dadabase.JOKE_DB_VERSION
    end
end

-- ============================================================================
-- Utilities
-- ============================================================================

local function DebugPrint(...)
    if TarballsDadabaseDB.debug then
        print(...)
    end
end

local function GetRandomJoke()
    if not TarballsDadabaseDB.jokes or #TarballsDadabaseDB.jokes == 0 then
        return "The Dadabase is empty. This wipe is now canon."
    end
    return TarballsDadabaseDB.jokes[math.random(#TarballsDadabaseDB.jokes)]
end

local function TellDadJoke(encounterName)
    DebugPrint("TellDadJoke called for: " .. tostring(encounterName))
    DebugPrint("  enabled: " .. tostring(TarballsDadabaseDB.enabled))
    
    if not TarballsDadabaseDB.enabled then
        DebugPrint("  BLOCKED: Addon is disabled")
        return
    end

    local now = GetTime()
    local timeSinceLastJoke = now - lastJokeTime
    DebugPrint("  Time since last joke: " .. timeSinceLastJoke .. " (cooldown: " .. TarballsDadabaseDB.cooldown .. ")")
    
    if timeSinceLastJoke < TarballsDadabaseDB.cooldown then
        DebugPrint("  BLOCKED: Still on cooldown")
        return
    end
    lastJokeTime = now

    local joke = GetRandomJoke()
    DebugPrint("  Joke selected: " .. joke)
    
    local message = joke
    
    DebugPrint("  Message to send: " .. message)
    DebugPrint("  Scheduling message send in 1 second...")

    -- Delay the message to avoid UI restrictions during encounter transitions
    C_Timer.After(1, function()
        if IsInRaid() then
            DebugPrint("  Sending to RAID")
            SendChatMessage(message, "RAID")
        elseif IsInGroup() then
            DebugPrint("  Sending to PARTY")
            SendChatMessage(message, "PARTY")
        else
            DebugPrint("  NOT SENT: Not in a group or raid")
            -- Fallback for testing - print to chat
            print(message)
        end
    end)
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
            InitializeJokeDatabase()
            RegisterInterfaceOptions()

            -- Print load message
            local jokeCount = #TarballsDadabaseDB.jokes
            local jokeTypeName = GetRandomJokeTypeName()
            print("Tarball's Dadabase v" .. Dadabase.VERSION .. " loaded: " .. jokeCount .. " " .. jokeTypeName .. " loaded.")

            DebugPrint("Dadabase ADDON_LOADED")
            DebugPrint("  Default jokes available: " .. tostring(Dadabase.Jokes ~= nil))
            if Dadabase.Jokes then
                DebugPrint("  Number of default jokes: " .. #Dadabase.Jokes)
            end
            DebugPrint("  User joke pool: " .. #TarballsDadabaseDB.jokes)
            DebugPrint("  Enabled: " .. tostring(TarballsDadabaseDB.enabled))
            DebugPrint("  Cooldown: " .. tostring(TarballsDadabaseDB.cooldown))
        end
        
    elseif event == "ENCOUNTER_START" then
        local encounterID, encounterName = ...
        encounterActive = true
        DebugPrint("=== ENCOUNTER_START ===")
        DebugPrint("  ID: " .. tostring(encounterID))
        DebugPrint("  Name: " .. tostring(encounterName))
        DebugPrint("  encounterActive set to: " .. tostring(encounterActive))

    elseif event == "ENCOUNTER_END" then
        local encounterID, encounterName, difficultyID, groupSize, success = ...
        
        DebugPrint("=== ENCOUNTER_END ===")
        DebugPrint("  ID: " .. tostring(encounterID))
        DebugPrint("  Name: " .. tostring(encounterName))
        DebugPrint("  Difficulty: " .. tostring(difficultyID))
        DebugPrint("  Group Size: " .. tostring(groupSize))
        DebugPrint("  Success: " .. tostring(success) .. " (0=wipe, 1=kill)")
        DebugPrint("  encounterActive was: " .. tostring(encounterActive))

        local inInstance, instanceType = IsInInstance()
        DebugPrint("  In Instance: " .. tostring(inInstance))
        DebugPrint("  Instance Type: " .. tostring(instanceType))
        
        if instanceType ~= "party" and instanceType ~= "raid" then
            DebugPrint("  SKIPPED: Not in party or raid instance")
            encounterActive = false
            return
        end

        if encounterActive and success == 0 then
            DebugPrint("  CONDITIONS MET: Calling TellDadJoke")
            TellDadJoke(encounterName)
        else
            DebugPrint("  CONDITIONS NOT MET:")
            DebugPrint("    encounterActive: " .. tostring(encounterActive))
            DebugPrint("    success == 0: " .. tostring(success == 0))
        end

        encounterActive = false
        DebugPrint("  encounterActive set to: false")
    end
end)

-- ============================================================================
-- Configuration Panel
-- ============================================================================

local ConfigPanel = {}

-- Create the main config frame
local function CreateConfigPanel()
    local panel = CreateFrame("Frame", "TarballsDadabaseConfigPanel", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(600, 500)
    panel:SetPoint("CENTER")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetFrameStrata("DIALOG")
    panel:Hide()

    panel.title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    panel.title:SetPoint("TOP", 0, -5)
    panel.title:SetText("Tarball's Dadabase")

    -- Tab buttons
    local tabButtons = {}
    local tabs = {}

    local function ShowTab(tabIndex)
        for i, tab in ipairs(tabs) do
            if i == tabIndex then
                tab:Show()
                tabButtons[i]:SetAlpha(1.0)
            else
                tab:Hide()
                tabButtons[i]:SetAlpha(0.6)
            end
        end
    end

    -- Settings Tab Button
    local settingsTabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    settingsTabBtn:SetSize(100, 25)
    settingsTabBtn:SetPoint("TOPLEFT", 20, -35)
    settingsTabBtn:SetText("Settings")
    settingsTabBtn:SetScript("OnClick", function() ShowTab(1) end)
    table.insert(tabButtons, settingsTabBtn)

    -- Jokes Tab Button
    local jokesTabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    jokesTabBtn:SetSize(100, 25)
    jokesTabBtn:SetPoint("LEFT", settingsTabBtn, "RIGHT", 5, 0)
    jokesTabBtn:SetText("Jokes")
    jokesTabBtn:SetScript("OnClick", function() ShowTab(2) end)
    table.insert(tabButtons, jokesTabBtn)

    -- Settings Tab Content
    local settingsTab = CreateFrame("Frame", nil, panel)
    settingsTab:SetPoint("TOPLEFT", 20, -70)
    settingsTab:SetPoint("BOTTOMRIGHT", -20, 20)
    table.insert(tabs, settingsTab)

    -- Version display
    local versionLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionLabel:SetPoint("TOPLEFT", 10, -10)
    versionLabel:SetText("Version: " .. Dadabase.VERSION)

    -- Enable/Disable checkbox
    local enableCheckbox = CreateFrame("CheckButton", nil, settingsTab, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 10, -40)
    enableCheckbox.text = enableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableCheckbox.text:SetPoint("LEFT", enableCheckbox, "RIGHT", 5, 0)
    enableCheckbox.text:SetText("Enable dad jokes on wipes")
    enableCheckbox:SetChecked(TarballsDadabaseDB.enabled)
    enableCheckbox:SetScript("OnClick", function(self)
        TarballsDadabaseDB.enabled = self:GetChecked()
        print("Tarball's Dadabase " .. (TarballsDadabaseDB.enabled and "enabled" or "disabled") .. ".")
    end)

    -- Cooldown slider
    local cooldownLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cooldownLabel:SetPoint("TOPLEFT", 10, -80)
    cooldownLabel:SetText("Cooldown between jokes:")

    local cooldownSlider = CreateFrame("Slider", nil, settingsTab, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", cooldownLabel, "BOTTOMLEFT", 0, -10)
    cooldownSlider:SetWidth(300)
    cooldownSlider:SetMinMaxValues(0, 60)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetValue(TarballsDadabaseDB.cooldown)
    cooldownSlider:SetObeyStepOnDrag(true)

    cooldownSlider.Low:SetText("0s")
    cooldownSlider.High:SetText("60s")

    cooldownSlider.valueText = cooldownSlider:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    cooldownSlider.valueText:SetPoint("TOP", cooldownSlider, "BOTTOM", 0, 0)
    cooldownSlider.valueText:SetText(TarballsDadabaseDB.cooldown .. " seconds")

    cooldownSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        TarballsDadabaseDB.cooldown = value
        self.valueText:SetText(value .. " seconds")
    end)

    -- Jokes Tab Content
    local jokesTab = CreateFrame("Frame", nil, panel)
    jokesTab:SetPoint("TOPLEFT", 20, -70)
    jokesTab:SetPoint("BOTTOMRIGHT", -20, 20)
    table.insert(tabs, jokesTab)

    -- Jokes list header
    local jokesHeader = jokesTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    jokesHeader:SetPoint("TOPLEFT", 10, -10)
    jokesHeader:SetText("Joke Pool (" .. #TarballsDadabaseDB.jokes .. " jokes)")

    -- Scrollable jokes list
    local scrollFrame = CreateFrame("ScrollFrame", nil, jokesTab, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -35)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 80)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollFrame:SetScrollChild(scrollChild)
    scrollChild:SetSize(scrollFrame:GetWidth(), 1)

    local jokeButtons = {}

    local function RefreshJokesList()
        -- Clear existing buttons
        for _, btn in ipairs(jokeButtons) do
            btn:Hide()
            btn:SetParent(nil)
        end
        jokeButtons = {}

        -- Update header
        jokesHeader:SetText("Joke Pool (" .. #TarballsDadabaseDB.jokes .. " jokes)")

        -- Create buttons for each joke
        local yOffset = 0
        for i, joke in ipairs(TarballsDadabaseDB.jokes) do
            local jokeFrame = CreateFrame("Frame", nil, scrollChild)
            jokeFrame:SetSize(scrollChild:GetWidth() - 10, 60)
            jokeFrame:SetPoint("TOPLEFT", 5, -yOffset)

            -- Joke text
            local jokeText = jokeFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            jokeText:SetPoint("TOPLEFT", 5, -5)
            jokeText:SetPoint("TOPRIGHT", -45, -5)
            jokeText:SetJustifyH("LEFT")
            jokeText:SetWordWrap(true)
            jokeText:SetText(joke)

            -- Delete button
            local deleteBtn = CreateFrame("Button", nil, jokeFrame, "UIPanelButtonTemplate")
            deleteBtn:SetSize(40, 20)
            deleteBtn:SetPoint("TOPRIGHT", -5, -5)
            deleteBtn:SetText("Del")
            deleteBtn.jokeIndex = i
            deleteBtn:SetScript("OnClick", function(self)
                table.remove(TarballsDadabaseDB.jokes, self.jokeIndex)
                TarballsDadabaseDB.customJokes[self.jokeIndex] = nil
                RefreshJokesList()
            end)

            -- Divider line
            local divider = jokeFrame:CreateTexture(nil, "ARTWORK")
            divider:SetHeight(1)
            divider:SetPoint("BOTTOMLEFT", 0, 0)
            divider:SetPoint("BOTTOMRIGHT", 0, 0)
            divider:SetColorTexture(0.3, 0.3, 0.3, 0.5)

            table.insert(jokeButtons, jokeFrame)
            yOffset = yOffset + 60
        end

        scrollChild:SetHeight(math.max(yOffset, scrollFrame:GetHeight()))
    end

    -- Add joke section
    local addJokeLabel = jokesTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    addJokeLabel:SetPoint("BOTTOMLEFT", 10, 50)
    addJokeLabel:SetText("Add new joke:")

    local addJokeEditBox = CreateFrame("EditBox", nil, jokesTab, "InputBoxTemplate")
    addJokeEditBox:SetPoint("BOTTOMLEFT", 10, 25)
    addJokeEditBox:SetPoint("BOTTOMRIGHT", -120, 25)
    addJokeEditBox:SetHeight(25)
    addJokeEditBox:SetAutoFocus(false)
    addJokeEditBox:SetMaxLetters(500)

    local addJokeBtn = CreateFrame("Button", nil, jokesTab, "UIPanelButtonTemplate")
    addJokeBtn:SetSize(100, 25)
    addJokeBtn:SetPoint("BOTTOMRIGHT", -10, 25)
    addJokeBtn:SetText("Add Joke")
    addJokeBtn:SetScript("OnClick", function()
        local newJoke = addJokeEditBox:GetText():trim()
        if newJoke ~= "" then
            table.insert(TarballsDadabaseDB.jokes, newJoke)
            TarballsDadabaseDB.customJokes[#TarballsDadabaseDB.jokes] = true
            addJokeEditBox:SetText("")
            RefreshJokesList()
            print("Joke added!")
        end
    end)

    panel.RefreshJokesList = RefreshJokesList

    -- Show settings tab by default
    ShowTab(1)

    return panel
end

ConfigPanel.frame = nil

function ConfigPanel:Show()
    if not self.frame then
        self.frame = CreateConfigPanel()
    end
    self.frame.RefreshJokesList()
    self.frame:Show()
end

function ConfigPanel:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function ConfigPanel:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- Register with WoW's Interface Options
local function RegisterInterfaceOptions()
    local category = Settings.RegisterCanvasLayoutCategory(ConfigPanel.frame or CreateConfigPanel(), "Tarball's Dadabase")
    Settings.RegisterAddOnCategory(category)
    ConfigPanel.category = category
end

-- ============================================================================
-- Slash Commands
-- ============================================================================

SLASH_TARBALLSDADABASE1 = "/dadabase"

SlashCmdList["TARBALLSDADABASE"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "" then
        ConfigPanel:Toggle()

    elseif msg == "version" then
        print("Tarball's Dadabase version " .. Dadabase.VERSION)

    elseif msg == "on" then
        TarballsDadabaseDB.enabled = true
        print("Tarball's Dadabase enabled.")

    elseif msg == "off" then
        TarballsDadabaseDB.enabled = false
        print("Tarball's Dadabase disabled.")

    elseif msg == "debug" then
        TarballsDadabaseDB.debug = not TarballsDadabaseDB.debug
        print("Tarball's Dadabase debug mode " .. (TarballsDadabaseDB.debug and "enabled" or "disabled") .. ".")

    elseif msg:match("^cooldown%s+%d+$") then
        local value = tonumber(msg:match("%d+"))
        TarballsDadabaseDB.cooldown = value
        print("Tarball's Dadabase cooldown set to " .. value .. " seconds.")

    elseif msg == "test" then
        if not TarballsDadabaseDB.jokes or #TarballsDadabaseDB.jokes == 0 then
            print("No jokes loaded!")
        else
            local joke = TarballsDadabaseDB.jokes[math.random(#TarballsDadabaseDB.jokes)]
            print("Test joke: " .. joke)
        end

    elseif msg == "joke" or msg == "joke say" then
        local joke = GetRandomJoke()
        SendChatMessage(joke, "SAY")

    elseif msg == "joke guild" then
        if not IsInGuild() then
            print("You are not in a guild!")
        else
            local joke = GetRandomJoke()
            SendChatMessage(joke, "GUILD")
        end

    elseif msg == "status" then
        print("Tarball's Dadabase Status:")
        print("  Version: " .. Dadabase.VERSION)
        print("  Enabled: " .. tostring(TarballsDadabaseDB.enabled))
        print("  Debug: " .. tostring(TarballsDadabaseDB.debug))
        print("  Cooldown: " .. TarballsDadabaseDB.cooldown .. " seconds")
        print("  Jokes in pool: " .. #TarballsDadabaseDB.jokes)
        print("  Joke DB version: " .. TarballsDadabaseDB.jokeDBVersion)
        print("  In encounter: " .. tostring(encounterActive))
        local inInstance, instanceType = IsInInstance()
        print("  Instance type: " .. tostring(instanceType))

    else
        print("Tarball's Dadabase commands:")
        print("  /dadabase - Open config panel")
        print("  /dadabase version")
        print("  /dadabase on")
        print("  /dadabase off")
        print("  /dadabase debug")
        print("  /dadabase cooldown <seconds>")
        print("  /dadabase joke - Tell a joke in say")
        print("  /dadabase joke guild - Tell a joke in guild chat")
        print("  /dadabase test")
        print("  /dadabase status")
    end
end