-- Config.lua - Configuration panel framework

Dadabase = Dadabase or {}
Dadabase.Config = {}

local Config = Dadabase.Config
local DB = Dadabase.DatabaseManager

-- Constants
local CONFIG_PANEL_WIDTH = 700
local CONFIG_PANEL_HEIGHT = 650
local TAB_BUTTON_WIDTH_SMALL = 120
local TAB_BUTTON_WIDTH_LARGE = 130
local TAB_BUTTON_HEIGHT = 25
local MAX_CHAT_MESSAGE_LENGTH = 255
local EDITOR_MIN_HEIGHT = 180
local EDITOR_LINE_HEIGHT = 14
local EDITOR_WIDTH = 600
local SLIDER_WIDTH = 300
local DROPDOWN_WIDTH = 180
local DIVIDER_WIDTH = 640
local STATUS_CLEAR_DELAY = 3

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
    panel:SetSize(CONFIG_PANEL_WIDTH, CONFIG_PANEL_HEIGHT)
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
    aboutTabBtn:SetSize(TAB_BUTTON_WIDTH_SMALL, TAB_BUTTON_HEIGHT)
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
    githubLink:SetText("https://github.com/makayez/tarballs-dadabase")
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
    settingsTabBtn:SetSize(TAB_BUTTON_WIDTH_SMALL, TAB_BUTTON_HEIGHT)
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
    divider1:SetSize(DIVIDER_WIDTH, 1)
    divider1:SetPoint("TOPLEFT", 10, yOffset)
    yOffset = yOffset - 20

    -- Statistics Section
    local statsLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    statsLabel:SetPoint("TOPLEFT", 10, yOffset)
    statsLabel:SetText("Statistics:")
    yOffset = yOffset - 25

    local function GetModuleStats()
        local stats = {}
        -- Check if database is initialized
        if not DB.modules or not TarballsDadabaseDB or not TarballsDadabaseDB.stats then
            return stats
        end

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
        if not statsText then
            return
        end

        local stats = GetModuleStats()
        if not stats or not next(stats) then
            statsText:SetText("No modules loaded yet")
            return
        end

        local lines = {}
        for moduleId, stat in pairs(stats) do
            table.insert(lines, stat.name .. ": " .. stat.count .. " items, " .. stat.told .. " told")
        end
        statsText:SetText(table.concat(lines, "\n"))
    end

    UpdateStats()
    settingsTab.UpdateStats = UpdateStats
    yOffset = yOffset - 80

    -- Divider
    local divider2 = settingsTab:CreateTexture(nil, "ARTWORK")
    divider2:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    divider2:SetSize(DIVIDER_WIDTH, 1)
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
    cooldownSlider:SetWidth(SLIDER_WIDTH)
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
        {text = "Ready Check", value = SOUNDKIT.READY_CHECK or 8960},
        {text = "Raid Warning", value = SOUNDKIT.RAID_WARNING or 8959},
        {text = "Alarm Clock", value = SOUNDKIT.ALARM_CLOCK_WARNING_3 or 12867},
        {text = "Message Alert", value = SOUNDKIT.UI_WORLDQUEST_COMPLETE or 73182},
        {text = "Whisper Received", value = SOUNDKIT.IG_CHAT_EMOTE_BUTTON or 567},
        {text = "Quest Complete", value = SOUNDKIT.UI_QUEST_COMPLETE or 878},
        {text = "Achievement", value = SOUNDKIT.ACHIEVEMENT_MENU_OPEN or 3337},
        {text = "Map Ping", value = SOUNDKIT.MAP_PING or 3175},
        {text = "Loot Coin", value = SOUNDKIT.LOOT_MONEY_COINS or 120},
        {text = "Auction Window", value = SOUNDKIT.AUCTION_WINDOW_OPEN or 5274},
        {text = "UI Tick", value = SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF or 857},
        {text = "UI Error", value = SOUNDKIT.IG_MAINMENU_OPTION or 852},
        {text = "UI Bell", value = SOUNDKIT.UI_ORDERHALL_TALENT_READY_TOAST or 73743},
        {text = "Raid Boss Warning", value = SOUNDKIT.RAID_BOSS_EMOTE_WARNING or 44854}
    }

    UIDropDownMenu_SetWidth(soundDropdown, DROPDOWN_WIDTH)
    UIDropDownMenu_Initialize(soundDropdown, function(self, level)
        for _, option in ipairs(soundOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = option.text
            info.value = option.value
            info.func = function()
                TarballsDadabaseDB.soundEffect = option.value
                UIDropDownMenu_SetText(soundDropdown, option.text)
                -- Don't play sound on selection, only on Test button
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
        local success, err = pcall(PlaySound, TarballsDadabaseDB.soundEffect)
        if not success then
            print("Failed to play sound: Invalid sound ID")
        end
    end)

    -- Module Tabs
    for _, moduleTab in ipairs(Config.moduleTabs) do
        local tabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        tabBtn:SetSize(TAB_BUTTON_WIDTH_LARGE, TAB_BUTTON_HEIGHT)
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

    -- Global disabled warning (shown when addon is globally disabled)
    local warningFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    warningFrame:SetPoint("TOPLEFT", 10, yOffset)
    warningFrame:SetPoint("TOPRIGHT", -10, yOffset)
    warningFrame:SetHeight(40)
    warningFrame:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    warningFrame:SetBackdropColor(0.8, 0.2, 0.2, 0.3)
    warningFrame:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)

    local warningText = warningFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    warningText:SetPoint("CENTER")
    warningText:SetTextColor(1, 0.3, 0.3)
    warningText:SetText("WARNING: Addon is globally disabled in Settings tab - this module will not trigger")

    -- Hide warning by default, will show if global disabled
    warningFrame:Hide()

    yOffset = yOffset - 50

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
    editBox:SetWidth(EDITOR_WIDTH)
    editBox:SetMaxLetters(0)
    editBox:SetEnabled(true)
    editBox:EnableMouse(true)
    editBox:EnableKeyboard(true)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnMouseDown", function(self)
        self:SetFocus()
        return true
    end)
    editBox:SetScript("OnShow", function(self)
        self:SetEnabled(true)
        self:EnableMouse(true)
        self:EnableKeyboard(true)
    end)

    scrollFrame:SetScrollChild(editBox)

    -- Add click handler to scrollFrame to pass focus to editBox
    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function(self)
        editBox:SetFocus()
    end)

    -- Add click handler to editorBorder too
    editorBorder:EnableMouse(true)
    editorBorder:SetScript("OnMouseDown", function(self)
        editBox:SetFocus()
    end)

    -- Save button and status (declare early so LoadContent can reference it)
    local saveBtn = CreateFrame("Button", nil, container, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 10, 30)
    saveBtn:SetText("Save Changes")
    saveBtn:Disable()

    local statusLabel = container:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusLabel:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    statusLabel:SetText("")

    -- Track original content for change detection
    local originalText = ""

    -- Populate with current content
    local function LoadContent()
        local content = DB:GetEffectiveContent(moduleId)
        local text = table.concat(content, "\n")
        editBox:SetText(text)
        originalText = text

        -- Calculate height based on content (ensure minimum height even when empty)
        local numLines = math.max(#content, 10)  -- Minimum 10 lines visible
        local calculatedHeight = math.max(numLines * EDITOR_LINE_HEIGHT, EDITOR_MIN_HEIGHT)
        editBox:SetHeight(calculatedHeight)

        editBox:SetCursorPosition(0)
        editBox:Enable()  -- Ensure editBox stays enabled
        editBox:EnableMouse(true)
        editBox:EnableKeyboard(true)
        editBox:Show()
        contentLabel:SetText("Content (" .. #content .. " items)")
        saveBtn:Disable()
    end

    container.LoadContent = LoadContent

    -- Enable/disable save button based on text changes
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local currentText = self:GetText()
            if currentText ~= originalText then
                saveBtn:Enable()
            else
                saveBtn:Disable()
            end
        end
    end)

    saveBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local newContent = {}
        local skippedLines = 0

        -- Parse lines (split by newline)
        for line in text:gmatch("[^\r\n]+") do
            line = line:trim()
            if line ~= "" then
                -- Validate line length (WoW chat message limit)
                if #line > MAX_CHAT_MESSAGE_LENGTH then
                    skippedLines = skippedLines + 1
                else
                    -- Sanitize input - remove WoW formatting codes
                    line = line:gsub("|c%x%x%x%x%x%x%x%x", "")  -- Remove color codes (8 hex digits)
                    line = line:gsub("|H.-|h.-|h", "")  -- Remove hyperlinks (more precise)
                    line = line:gsub("|r", "")  -- Remove color resets
                    line = line:gsub("|T.-|t", "")  -- Remove textures
                    line = line:gsub("|K.-|k", "")  -- Remove encrypted text
                    line = line:gsub("|n", "")  -- Remove line breaks
                    line = line:trim()  -- Final trim after sanitization
                    if line ~= "" then
                        table.insert(newContent, line)
                    end
                end
            end
        end

        -- Update the database
        DB:SetEffectiveContent(moduleId, newContent)

        -- Update original text to match saved content
        originalText = text

        -- Show feedback
        local message = "Saved! (" .. #newContent .. " items)"
        if skippedLines > 0 then
            message = message .. " (" .. skippedLines .. " lines too long, skipped)"
        end
        statusLabel:SetText(message)
        contentLabel:SetText("Content (" .. #newContent .. " items)")
        saveBtn:Disable()

        -- Clear status after 3 seconds
        C_Timer.After(STATUS_CLEAR_DELAY, function()
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
        C_Timer.After(STATUS_CLEAR_DELAY, function()
            statusLabel:SetText("")
        end)
    end)

    -- Store all controls that should be disabled when addon or module is disabled
    -- Note: enableCheckbox should always be enabled (even when global is off)
    -- Note: editBox should always remain enabled so users can add content before enabling module
    local moduleControls = {
        wipeCheckbox,
        deathCheckbox,
        raidCheckbox,
        partyCheckbox,
        saveBtn,
        resetBtn
    }

    -- Controls that get tooltip handlers (editBox excluded to prevent typing interference)
    local controlsWithTooltips = {
        wipeCheckbox,
        deathCheckbox,
        raidCheckbox,
        partyCheckbox,
        saveBtn,
        resetBtn
    }

    -- Tooltip handlers (defined once to prevent memory leaks)
    local function ShowGlobalDisabledTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Addon Disabled", 1, 0, 0)
        GameTooltip:AddLine("Enable the addon in the Settings tab to use this feature.", 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function ShowModuleDisabledTooltip(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Module Disabled", 1, 0.5, 0)
        GameTooltip:AddLine("Enable " .. module.name .. " to use this feature.", 1, 1, 1, true)
        GameTooltip:Show()
    end

    local function HideTooltip(self)
        GameTooltip:Hide()
    end

    -- Track tooltip state to prevent recreating handlers
    local tooltipStates = {}

    -- Function to refresh control states based on global and module enabled
    local function RefreshControls()
        local globalEnabled = TarballsDadabaseDB.globalEnabled
        local moduleEnabled = moduleDB.enabled

        -- Show/hide warning based on global enabled state
        if globalEnabled then
            warningFrame:Hide()
        else
            warningFrame:Show()
        end

        -- Enable checkbox is always enabled (allows configuration when global is disabled)
        enableCheckbox:Enable()
        if enableCheckbox.text then
            enableCheckbox.text:SetTextColor(1, 1, 1)
        end

        -- EditBox is always enabled (users can add content before enabling module)
        editBox:Enable()

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

        -- Add/remove tooltip handlers for controls (editBox excluded to allow typing)
        for _, control in ipairs(controlsWithTooltips) do
            local desiredState = "none"

            if not globalEnabled then
                desiredState = "global"
            elseif not moduleEnabled then
                desiredState = "module"
            end

            -- Only update handlers if state changed
            if tooltipStates[control] ~= desiredState then
                if desiredState == "global" then
                    control:SetScript("OnEnter", ShowGlobalDisabledTooltip)
                    control:SetScript("OnLeave", HideTooltip)
                elseif desiredState == "module" then
                    control:SetScript("OnEnter", ShowModuleDisabledTooltip)
                    control:SetScript("OnLeave", HideTooltip)
                else
                    control:SetScript("OnEnter", nil)
                    control:SetScript("OnLeave", nil)
                end
                tooltipStates[control] = desiredState
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

    -- Ensure editBox is always enabled for typing (even when module/global disabled)
    editBox:Enable()

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
