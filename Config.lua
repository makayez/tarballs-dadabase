-- Config.lua - Configuration panel framework

Dadabase = Dadabase or {}
Dadabase.Config = {}

local Config = Dadabase.Config
local DB = Dadabase.DatabaseManager

-- Registered module config tabs
Config.moduleTabs = {}

-- ============================================================================
-- Module Tab Registration
-- ============================================================================

function Config:RegisterModuleTab(moduleId, config)
    table.insert(self.moduleTabs, {
        moduleId = moduleId,
        name = config.name,
        buildContent = config.buildContent
    })
end

-- ============================================================================
-- Configuration Panel Creation
-- ============================================================================

local function CreateConfigPanel()
    local panel = CreateFrame("Frame", "TarballsDadabaseConfigPanel", UIParent, "BasicFrameTemplateWithInset")
    panel:SetSize(700, 650)
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

    -- Tab system
    local tabButtons = {}
    local tabs = {}

    local function ShowTab(tabIndex)
        for i, tab in ipairs(tabs) do
            if i == tabIndex then
                tab:Show()
                tabButtons[i]:SetAlpha(1.0)
                -- Refresh stats when showing settings tab
                if i == 2 and tab.UpdateStats then
                    tab:UpdateStats()
                end
            else
                tab:Hide()
                tabButtons[i]:SetAlpha(0.6)
            end
        end
    end

    -- About Tab (first tab)
    local aboutTabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    aboutTabBtn:SetSize(120, 25)
    aboutTabBtn:SetPoint("TOPLEFT", 20, -35)
    aboutTabBtn:SetText("About")
    aboutTabBtn:SetScript("OnClick", function() ShowTab(1) end)
    table.insert(tabButtons, aboutTabBtn)

    local aboutTab = CreateFrame("Frame", nil, panel)
    aboutTab:SetPoint("TOPLEFT", 20, -70)
    aboutTab:SetPoint("BOTTOMRIGHT", -20, 20)
    table.insert(tabs, aboutTab)

    -- Build about tab content
    local aboutYOffset = -10

    local aboutTitle = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    aboutTitle:SetPoint("TOP", 0, aboutYOffset)
    aboutTitle:SetText("Tarball's Dadabase")
    aboutYOffset = aboutYOffset - 40

    local aboutDesc = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    aboutDesc:SetPoint("TOPLEFT", 20, aboutYOffset)
    aboutDesc:SetPoint("TOPRIGHT", -20, aboutYOffset)
    aboutDesc:SetJustifyH("LEFT")
    aboutDesc:SetSpacing(3)
    aboutDesc:SetText(
        "A World of Warcraft addon that shares uplifting dad jokes, motivational quotes, " ..
        "and memorable guild sayings when your raid wipes or when you experience a personal death.\n\n" ..
        "Perfect for lightening the mood after a difficult encounter!"
    )
    aboutYOffset = aboutYOffset - 100

    local howToTitle = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    howToTitle:SetPoint("TOPLEFT", 20, aboutYOffset)
    howToTitle:SetText("How to Add Your Own Content")
    aboutYOffset = aboutYOffset - 30

    local howToDesc = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    howToDesc:SetPoint("TOPLEFT", 30, aboutYOffset)
    howToDesc:SetPoint("TOPRIGHT", -20, aboutYOffset)
    howToDesc:SetJustifyH("LEFT")
    howToDesc:SetSpacing(3)
    howToDesc:SetText(
        "1. Navigate to the Dad Jokes, Demotivational, or Guild Quotes tabs\n" ..
        "2. Scroll to the content editor at the bottom\n" ..
        "3. Add your own jokes or quotes (one per line)\n" ..
        "4. Delete any lines you don't want\n" ..
        "5. Click 'Save Changes' to update\n\n" ..
        "Your custom additions will be preserved even when the addon updates with new default content!"
    )
    aboutYOffset = aboutYOffset - 150

    local githubTitle = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    githubTitle:SetPoint("TOPLEFT", 20, aboutYOffset)
    githubTitle:SetText("GitHub Repository")
    aboutYOffset = aboutYOffset - 30

    local githubLink = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    githubLink:SetPoint("TOPLEFT", 30, aboutYOffset)
    githubLink:SetJustifyH("LEFT")
    githubLink:SetText("https://github.com/makayez/tarballs-datadabase")
    aboutYOffset = aboutYOffset - 50

    local thanksTitle = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    thanksTitle:SetPoint("TOPLEFT", 20, aboutYOffset)
    thanksTitle:SetText("Thank You!")
    aboutYOffset = aboutYOffset - 30

    local thanksDesc = aboutTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    thanksDesc:SetPoint("TOPLEFT", 30, aboutYOffset)
    thanksDesc:SetPoint("TOPRIGHT", -20, aboutYOffset)
    thanksDesc:SetJustifyH("LEFT")
    thanksDesc:SetSpacing(3)
    thanksDesc:SetText(
        "Thank you for using Tarball's Dadabase! I hope this addon brings a smile to your " ..
        "raid team's faces during those challenging progression nights.\n\n" ..
        "May your wipes be few and your dad jokes be legendary!\n\n" ..
        "- Tarball-Whisperwind"
    )

    -- Settings Tab (second tab)
    local settingsTabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    settingsTabBtn:SetSize(120, 25)
    settingsTabBtn:SetPoint("LEFT", aboutTabBtn, "RIGHT", 5, 0)
    settingsTabBtn:SetText("Settings")
    settingsTabBtn:SetScript("OnClick", function() ShowTab(2) end)
    table.insert(tabButtons, settingsTabBtn)

    local settingsTab = CreateFrame("Frame", nil, panel)
    settingsTab:SetPoint("TOPLEFT", 20, -70)
    settingsTab:SetPoint("BOTTOMRIGHT", -20, 20)
    table.insert(tabs, settingsTab)

    -- Build settings tab content
    local yOffset = -10

    local versionLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    versionLabel:SetPoint("TOPLEFT", 10, yOffset)
    versionLabel:SetText("Version: " .. Dadabase.VERSION)
    yOffset = yOffset - 30

    -- Global Enable/Disable
    local globalEnableCheckbox = CreateFrame("CheckButton", nil, settingsTab, "UICheckButtonTemplate")
    globalEnableCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    globalEnableCheckbox.text = globalEnableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    globalEnableCheckbox.text:SetPoint("LEFT", globalEnableCheckbox, "RIGHT", 5, 0)
    globalEnableCheckbox.text:SetText("Enable Addon")
    globalEnableCheckbox:SetChecked(TarballsDadabaseDB.globalEnabled)
    globalEnableCheckbox:SetScript("OnClick", function(self)
        TarballsDadabaseDB.globalEnabled = self:GetChecked()
        -- Refresh all module tabs to update their disabled state
        for _, tab in ipairs(tabs) do
            if tab.RefreshControls then
                tab:RefreshControls()
            end
        end
    end)
    yOffset = yOffset - 40

    -- Divider
    local divider1 = settingsTab:CreateTexture(nil, "ARTWORK")
    divider1:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    divider1:SetSize(640, 1)
    divider1:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 20

    -- Statistics Section
    local statsLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statsLabel:SetPoint("TOPLEFT", 10, yOffset)
    statsLabel:SetText("Statistics:")
    yOffset = yOffset - 25

    local function GetModuleStats()
        local stats = {}
        for moduleId, module in pairs(DB.modules) do
            local content = DB:GetEffectiveContent(moduleId)
            local told = TarballsDadabaseDB.stats[moduleId] or 0
            stats[moduleId] = {
                name = module.name,
                count = #content,
                told = told
            }
        end
        return stats
    end

    local statsText = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statsText:SetPoint("TOPLEFT", 20, yOffset)
    statsText:SetJustifyH("LEFT")

    local function UpdateStats()
        local stats = GetModuleStats()
        local text = ""
        for moduleId, stat in pairs(stats) do
            text = text .. stat.name .. ": " .. stat.count .. " items, " .. stat.told .. " told\n"
        end
        statsText:SetText(text)
    end

    UpdateStats()
    settingsTab.UpdateStats = UpdateStats
    yOffset = yOffset - 80

    -- Divider
    local divider2 = settingsTab:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    divider2:SetSize(640, 1)
    divider2:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 20

    -- Cooldown Section
    local cooldownLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    cooldownLabel:SetPoint("TOPLEFT", 10, yOffset)
    cooldownLabel:SetText("Global cooldown between messages:")
    yOffset = yOffset - 20

    local cooldownHelp = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cooldownHelp:SetPoint("TOPLEFT", 10, yOffset)
    cooldownHelp:SetPoint("TOPRIGHT", -10, yOffset)
    cooldownHelp:SetJustifyH("LEFT")
    cooldownHelp:SetText("Prevents messages from being sent if one was recently sent within the specified time.")
    yOffset = yOffset - 30

    local cooldownSlider = CreateFrame("Slider", nil, settingsTab, "OptionsSliderTemplate")
    cooldownSlider:SetPoint("TOPLEFT", 10, yOffset)
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
    yOffset = yOffset - 50

    -- Sound Effect Section
    local soundCheckbox = CreateFrame("CheckButton", nil, settingsTab, "UICheckButtonTemplate")
    soundCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    soundCheckbox.text = soundCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundCheckbox.text:SetPoint("LEFT", soundCheckbox, "RIGHT", 5, 0)
    soundCheckbox.text:SetText("Play sound effect when content triggers")
    soundCheckbox:SetChecked(TarballsDadabaseDB.soundEnabled)
    soundCheckbox:SetScript("OnClick", function(self)
        TarballsDadabaseDB.soundEnabled = self:GetChecked()
    end)
    yOffset = yOffset - 35

    -- Sound dropdown
    local soundLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundLabel:SetPoint("TOPLEFT", 30, yOffset)
    soundLabel:SetText("Sound effect:")

    local soundDropdown = CreateFrame("Frame", "TarballsDadabaseSoundDropdown", settingsTab, "UIDropDownMenuTemplate")
    soundDropdown:SetPoint("TOPLEFT", 110, yOffset + 5)

    local soundOptions = {
        {text = "Level Up", value = SOUNDKIT.LEVEL_UP or 888},
        {text = "Achievement", value = SOUNDKIT.ACHIEVEMENT_MENU_OPEN or 3337},
        {text = "Quest Complete", value = SOUNDKIT.UI_QUEST_COMPLETE or 878},
        {text = "Ready Check", value = SOUNDKIT.READY_CHECK or 8960},
        {text = "Raid Warning", value = SOUNDKIT.RAID_WARNING or 8959},
        {text = "Alarm Clock Warning", value = SOUNDKIT.ALARM_CLOCK_WARNING_3 or 12867},
        {text = "PVP Victory", value = SOUNDKIT.UI_BATTLEGROUND_VICTORY_HORDE or 8454},
        {text = "PVP Defeat", value = SOUNDKIT.UI_BATTLEGROUND_VICTORY_ALLIANCE or 8455},
        {text = "Gong", value = SOUNDKIT.UI_GUILDACHIEVEMENT_TOAST or 34076},
        {text = "Treasure Found", value = SOUNDKIT.UI_LEGENDARY_LOOT_TOAST or 31578},
        {text = "Auction Window Open", value = SOUNDKIT.AUCTION_WINDOW_OPEN or 5274},
        {text = "Ship Bell", value = SOUNDKIT.UI_GARRISON_MISSION_COMPLETE_ENCOUNTER or 62648},
        {text = "Drums of War", value = SOUNDKIT.UI_IG_PLAYER_RAID_WARNING or 31744},
        {text = "Mage Portal Open", value = SOUNDKIT.UI_PORTAL_OPEN or 2531},
        {text = "UI Ethereal Window", value = SOUNDKIT.UI_ETHEREAL_WINDOW_OPEN or 3193},
        {text = "UI Warlock Portal", value = SOUNDKIT.UI_WARLOCKSGLIMPSE_SPELLOPEN or 3194},
        {text = "Death Knight Death Gate", value = SOUNDKIT.UI_DEATHKNIGHT_DEATHGATE_SPELLOPEN or 3195}
    }

    UIDropDownMenu_SetWidth(soundDropdown, 180)
    UIDropDownMenu_Initialize(soundDropdown, function(self, level)
        for _, option in ipairs(soundOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function()
                TarballsDadabaseDB.soundEffect = option.value
                UIDropDownMenu_SetText(soundDropdown, option.text)
                PlaySound(option.value)
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end)

    -- Set initial dropdown text
    local currentSound = "Level Up"
    for _, option in ipairs(soundOptions) do
        if option.value == TarballsDadabaseDB.soundEffect then
            currentSound = option.text
            break
        end
    end
    UIDropDownMenu_SetText(soundDropdown, currentSound)

    -- Test sound button
    local testSoundBtn = CreateFrame("Button", nil, settingsTab, "UIPanelButtonTemplate")
    testSoundBtn:SetSize(60, 25)
    testSoundBtn:SetPoint("LEFT", soundDropdown, "RIGHT", -15, -2)
    testSoundBtn:SetText("Test")
    testSoundBtn:SetScript("OnClick", function()
        PlaySound(TarballsDadabaseDB.soundEffect)
    end)

    -- Module Tabs
    for _, moduleTab in ipairs(Config.moduleTabs) do
        local tabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tabBtn:SetSize(130, 25)
        tabBtn:SetPoint("LEFT", tabButtons[#tabButtons], "RIGHT", 5, 0)

        tabBtn:SetText(moduleTab.name)
        local tabIndex = #tabs + 1
        tabBtn:SetScript("OnClick", function() ShowTab(tabIndex) end)
        table.insert(tabButtons, tabBtn)

        local moduleTabFrame = CreateFrame("Frame", nil, panel)
        moduleTabFrame:SetPoint("TOPLEFT", 20, -70)
        moduleTabFrame:SetPoint("BOTTOMRIGHT", -20, 20)
        table.insert(tabs, moduleTabFrame)

        -- Build module-specific content
        moduleTab.buildContent(moduleTabFrame, moduleTab.moduleId)
    end

    -- Show about tab by default
    ShowTab(1)

    return panel
end

-- ============================================================================
-- Module Content Builder (shared for all modules)
-- ============================================================================

function Config:BuildModuleContent(container, moduleId)
    local moduleDB = DB:GetModuleSettings(moduleId)
    if not moduleDB then return end

    local module = DB.modules[moduleId]
    if not module then return end

    local yOffset = -10

    -- Enable checkbox
    local enableCheckbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    enableCheckbox:SetPoint("TOPLEFT", 10, yOffset)
    enableCheckbox.text = enableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    enableCheckbox.text:SetPoint("LEFT", enableCheckbox, "RIGHT", 5, 0)
    enableCheckbox.text:SetText("Enable " .. module.name)
    enableCheckbox:SetChecked(moduleDB.enabled)

    yOffset = yOffset - 40

    -- Triggers section (left side)
    local triggersLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    triggersLabel:SetPoint("TOPLEFT", 10, yOffset)
    triggersLabel:SetText("Triggers:")

    -- Groups section (right side)
    local groupsLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    groupsLabel:SetPoint("TOPLEFT", 340, yOffset)
    groupsLabel:SetText("Enabled for:")
    yOffset = yOffset - 30

    -- Wipe trigger
    local wipeCheckbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    wipeCheckbox:SetPoint("TOPLEFT", 20, yOffset)
    wipeCheckbox.text = wipeCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    wipeCheckbox.text:SetPoint("LEFT", wipeCheckbox, "RIGHT", 5, 0)
    wipeCheckbox.text:SetText("Party/Raid wipes")
    wipeCheckbox:SetChecked(moduleDB.triggers.wipe == true)
    wipeCheckbox:SetScript("OnClick", function(self)
        DB:SetModuleTrigger(moduleId, "wipe", self:GetChecked())
    end)

    -- Raid group (right side, same row)
    local raidCheckbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    raidCheckbox:SetPoint("TOPLEFT", 350, yOffset)
    raidCheckbox.text = raidCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidCheckbox.text:SetPoint("LEFT", raidCheckbox, "RIGHT", 5, 0)
    raidCheckbox.text:SetText("Raids")
    raidCheckbox:SetChecked(moduleDB.groups.raid == true)
    raidCheckbox:SetScript("OnClick", function(self)
        DB:SetModuleGroup(moduleId, "raid", self:GetChecked())
    end)
    yOffset = yOffset - 30

    -- Death trigger
    local deathCheckbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    deathCheckbox:SetPoint("TOPLEFT", 20, yOffset)
    deathCheckbox.text = deathCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    deathCheckbox.text:SetPoint("LEFT", deathCheckbox, "RIGHT", 5, 0)
    deathCheckbox.text:SetText("Personal death")
    deathCheckbox:SetChecked(moduleDB.triggers.death == true)
    deathCheckbox:SetScript("OnClick", function(self)
        DB:SetModuleTrigger(moduleId, "death", self:GetChecked())
    end)

    -- Party group (right side, same row)
    local partyCheckbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    partyCheckbox:SetPoint("TOPLEFT", 350, yOffset)
    partyCheckbox.text = partyCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    partyCheckbox.text:SetPoint("LEFT", partyCheckbox, "RIGHT", 5, 0)
    partyCheckbox.text:SetText("Parties")
    partyCheckbox:SetChecked(moduleDB.groups.party == true)
    partyCheckbox:SetScript("OnClick", function(self)
        DB:SetModuleGroup(moduleId, "party", self:GetChecked())
    end)
    yOffset = yOffset - 40

    -- Content management section
    local effectiveContent = DB:GetEffectiveContent(moduleId)
    local contentLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    contentLabel:SetPoint("TOPLEFT", 10, yOffset)
    contentLabel:SetText("Content (" .. #effectiveContent .. " items)")
    yOffset = yOffset - 30

    -- Instructions
    local instructionsLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    instructionsLabel:SetPoint("TOPLEFT", 10, yOffset)
    instructionsLabel:SetPoint("TOPRIGHT", -10, yOffset)
    instructionsLabel:SetJustifyH("LEFT")
    instructionsLabel:SetText("Edit the content below (one item per line). Delete lines to remove items, add lines to create new ones.")
    yOffset = yOffset - 25

    -- Multi-line text editor with border
    local editorBorder = CreateFrame("Frame", nil, container, "BackdropTemplate")
    editorBorder:SetPoint("TOPLEFT", 5, yOffset)
    editorBorder:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 65)
    editorBorder:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    editorBorder:SetBackdropColor(0, 0, 0, 0.8)
    editorBorder:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)

    local scrollFrame = CreateFrame("ScrollFrame", nil, editorBorder, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 10, -10)
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 10)

    local editBox = CreateFrame("EditBox", nil, scrollFrame)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:SetFontObject("GameFontHighlightSmall")
    editBox:SetWidth(600)
    editBox:SetMaxLetters(0)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)

    scrollFrame:SetScrollChild(editBox)

    -- Populate with current content
    local function LoadContent()
        local content = DB:GetEffectiveContent(moduleId)
        local text = table.concat(content, "\n")
        editBox:SetText(text)

        -- Calculate height based on content (roughly 14 pixels per line)
        local numLines = #content
        local lineHeight = 14
        local calculatedHeight = math.max(numLines * lineHeight, 180)
        editBox:SetHeight(calculatedHeight)

        editBox:SetCursorPosition(0)
        contentLabel:SetText("Content (" .. #content .. " items)")
    end

    container.LoadContent = LoadContent

    -- Save button and status
    local saveBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 10, 30)
    saveBtn:SetText("Save Changes")

    local statusLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusLabel:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    statusLabel:SetText("")

    saveBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local newContent = {}

        -- Parse lines (split by newline)
        for line in text:gmatch("[^\r\n]+") do
            line = line:trim()
            if line ~= "" then
                table.insert(newContent, line)
            end
        end

        -- Update the database
        DB:SetEffectiveContent(moduleId, newContent)

        -- Show feedback
        statusLabel:SetText("Saved! (" .. #newContent .. " items)")
        contentLabel:SetText("Content (" .. #newContent .. " items)")

        -- Clear status after 3 seconds
        C_Timer.After(3, function()
            statusLabel:SetText("")
        end)
    end)

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("LEFT", saveBtn, "RIGHT", 120, 0)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:SetScript("OnClick", function()
        -- Clear all user changes
        moduleDB.userAdditions = {}
        moduleDB.userDeletions = {}
        LoadContent()
        statusLabel:SetText("Reset to defaults!")
        C_Timer.After(3, function()
            statusLabel:SetText("")
        end)
    end)

    -- Store all controls that should be disabled when addon or module is disabled
    -- Note: enableCheckbox should always be enabled (even when global is off)
    local moduleControls = {
        wipeCheckbox,
        deathCheckbox,
        raidCheckbox,
        partyCheckbox,
        saveBtn,
        resetBtn,
        editBox
    }

    local allControls = {
        enableCheckbox,
        wipeCheckbox,
        deathCheckbox,
        raidCheckbox,
        partyCheckbox,
        saveBtn,
        resetBtn,
        editBox
    }

    -- Function to refresh control states based on global and module enabled
    local function RefreshControls()
        local globalEnabled = TarballsDadabaseDB.globalEnabled
        local moduleEnabled = moduleDB.enabled

        -- Handle enableCheckbox separately - only disabled by global setting
        if globalEnabled then
            enableCheckbox:Enable()
            if enableCheckbox.text then
                enableCheckbox.text:SetTextColor(1, 1, 1)
            end
        else
            enableCheckbox:Disable()
            if enableCheckbox.text then
                enableCheckbox.text:SetTextColor(0.5, 0.5, 0.5)
            end
        end

        -- Handle other module controls - disabled by either global or module setting
        for _, control in ipairs(moduleControls) do
            if globalEnabled and moduleEnabled then
                control:Enable()
                if control.text then
                    control.text:SetTextColor(1, 1, 1)
                end
            else
                control:Disable()
                if control.text then
                    control.text:SetTextColor(0.5, 0.5, 0.5)
                end
            end
        end

        -- Add/remove tooltip handlers for all controls
        for _, control in ipairs(allControls) do
            if not globalEnabled then
                control:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Addon Disabled", 1, 0, 0)
                    GameTooltip:AddLine("Enable the addon in the Settings tab to use this feature.", 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                control:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            elseif control ~= enableCheckbox and not moduleEnabled then
                -- Module is disabled but addon is enabled
                control:SetScript("OnEnter", function(self)
                    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                    GameTooltip:SetText("Module Disabled", 1, 0.5, 0)
                    GameTooltip:AddLine("Enable " .. module.name .. " to use this feature.", 1, 1, 1, true)
                    GameTooltip:Show()
                end)
                control:SetScript("OnLeave", function(self)
                    GameTooltip:Hide()
                end)
            else
                control:SetScript("OnEnter", nil)
                control:SetScript("OnLeave", nil)
            end
        end
    end

    -- Hook up enable checkbox to refresh controls
    enableCheckbox:SetScript("OnClick", function(self)
        DB:SetModuleEnabled(moduleId, self:GetChecked())
        RefreshControls()
    end)

    container.RefreshControls = RefreshControls
    RefreshControls()
    LoadContent()
end

-- ============================================================================
-- Panel Management
-- ============================================================================

Config.frame = nil

function Config:Show()
    if not self.frame then
        self.frame = CreateConfigPanel()
    end
    self.frame:Show()
end

function Config:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Config:Toggle()
    if self.frame and self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

-- ============================================================================
-- Interface Options Registration
-- ============================================================================

function Config:RegisterInterfaceOptions()
    if not self.frame then
        self.frame = CreateConfigPanel()
    end
    local category = Settings.RegisterCanvasLayoutCategory(self.frame, "Tarball's Dadabase")
    Settings.RegisterAddOnCategory(category)
    self.category = category
end
