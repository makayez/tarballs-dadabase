-- Config.lua - Configuration panel framework

Dadabase = Dadabase or {}
Dadabase.Config = {}

local Config = Dadabase.Config
local Manager = Dadabase.DatabaseManager

-- WoW checkboxes return 1/nil on some clients rather than true/false. Storing real
-- booleans keeps SavedVariables clean and comparisons predictable.
local function ToBoolean(value)
    return value and true or false
end

-- Constants
local CONFIG_PANEL_WIDTH = 700
local CONFIG_PANEL_HEIGHT = 650
-- Tabs live in a left gutter. A single horizontal row cannot fit six tabs:
-- 20 + 6 * (130 + 5) = 810, which overflows the 700px panel. A vertical gutter
-- scales to any number of content modules without re-layout.
local TAB_BUTTON_WIDTH = 150
local TAB_BUTTON_HEIGHT = 26
local TAB_BUTTON_SPACING = 6
local TAB_GUTTER_WIDTH = 175
local TAB_START_Y = -45
-- 255-byte chat limit minus the longest generated prefix (the Guild Quotes
-- prefix reaches 60 bytes with "extraordinary"), so a max-length entry plus its
-- prefix still fits in one chat message without truncation.
local MAX_CONTENT_ENTRY_LENGTH = Dadabase.MAX_CHAT_MESSAGE_LENGTH - Dadabase.MAX_PREFIX_LENGTH
local EDITOR_MIN_HEIGHT = 180
local EDITOR_LINE_HEIGHT = 14
local EDITOR_WIDTH = 450
local SLIDER_WIDTH = 300
local DROPDOWN_WIDTH = 180
local DIVIDER_WIDTH = 480
local STATUS_CLEAR_DELAY = 3

-- Sound effect options
local SOUND_OPTIONS = {
    {text = "Level Up", value = SOUNDKIT.LEVEL_UP or Dadabase.DefaultSound},
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
-- Helper Functions
-- ============================================================================

-- Tab buttons are stacked in the left gutter. Position is derived from the number
-- of buttons already added, so it is stable regardless of when the panel is shown.
local function CreateTabButton(panel, text, tabButtons)
    local tabBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    tabBtn:SetSize(TAB_BUTTON_WIDTH, TAB_BUTTON_HEIGHT)

    local yOffset = TAB_START_Y - #tabButtons * (TAB_BUTTON_HEIGHT + TAB_BUTTON_SPACING)
    tabBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 20, yOffset)

    tabBtn:SetText(text)
    return tabBtn
end

-- Content area sits to the right of the tab gutter.
local function CreateTabFrame(panel)
    local tab = CreateFrame("Frame", nil, panel)
    tab:SetPoint("TOPLEFT", TAB_GUTTER_WIDTH, TAB_START_Y)
    tab:SetPoint("BOTTOMRIGHT", -20, 20)
    return tab
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
    local settingsTab

    local function ShowTab(tabIndex)
        for i, tab in ipairs(tabs) do
            if i == tabIndex then
                tab:Show()
                tabButtons[i]:SetAlpha(1.0)
                -- Matched by identity rather than by index so reordering or adding
                -- tabs cannot break the stats refresh.
                if tab == settingsTab and tab.UpdateStats then
                    tab:UpdateStats()
                end
            else
                tab:Hide()
                tabButtons[i]:SetAlpha(0.6)
            end
        end
    end

    -- About Tab (first tab)
    local aboutTabBtn = CreateTabButton(panel, "About", tabButtons)
    aboutTabBtn:SetScript("OnClick", function() ShowTab(1) end)
    table.insert(tabButtons, aboutTabBtn)

    local aboutTab = CreateTabFrame(panel)
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
        "A World of Warcraft addon that shares uplifting dad jokes, Warcraft puns, " ..
        "motivational quotes, and memorable guild sayings when your raid wipes.\n\n" ..
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
        "1. Navigate to the Dad Jokes, Warcraft Jokes, Demotivational, or Guild Quotes tabs\n" ..
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
    local settingsTabBtn = CreateTabButton(panel, "Settings", tabButtons)
    settingsTabBtn:SetScript("OnClick", function() ShowTab(2) end)
    table.insert(tabButtons, settingsTabBtn)

    settingsTab = CreateTabFrame(panel)
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
    globalEnableCheckbox:SetChecked(ToBoolean(TarballsDadabaseDB.globalEnabled))
    globalEnableCheckbox:SetScript("OnClick", function(self)
        TarballsDadabaseDB.globalEnabled = ToBoolean(self:GetChecked())
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
        if not Manager.modules or not TarballsDadabaseDB or not TarballsDadabaseDB.stats then
            return stats
        end

        for moduleId, module in pairs(Manager.modules) do
            local told = TarballsDadabaseDB.stats[moduleId] or 0
            stats[moduleId] = {
                name = module.name,
                count = Manager:GetContentCount(moduleId),
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
    cooldownSlider:SetMinMaxValues(0, 600)
    cooldownSlider:SetValueStep(1)
    cooldownSlider:SetValue(TarballsDadabaseDB.cooldown)
    cooldownSlider:SetObeyStepOnDrag(true)

    cooldownSlider.Low:SetText("0s")
    cooldownSlider.High:SetText("10m")

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
    soundCheckbox:SetChecked(ToBoolean(TarballsDadabaseDB.soundEnabled))
    soundCheckbox:SetScript("OnClick", function(self)
        TarballsDadabaseDB.soundEnabled = ToBoolean(self:GetChecked())
    end)
    yOffset = yOffset - 35

    -- Sound dropdown
    local soundLabel = settingsTab:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    soundLabel:SetPoint("TOPLEFT", 30, yOffset)
    soundLabel:SetText("Sound effect:")

    local soundDropdown = CreateFrame("Frame", "TarballsDadabaseSoundDropdown", settingsTab, "UIDropDownMenuTemplate")
    soundDropdown:SetPoint("TOPLEFT", 110, yOffset + 5)

    UIDropDownMenu_SetWidth(soundDropdown, DROPDOWN_WIDTH)
    UIDropDownMenu_Initialize(soundDropdown, function(self, level)
        for _, option in ipairs(SOUND_OPTIONS) do
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
    for _, option in ipairs(SOUND_OPTIONS) do
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

    -- Re-apply saved-variable values into the settings widgets. Called on panel
    -- open (and after slash commands) so the displayed state never drifts from
    -- the database when both the panel and slash commands write the same settings.
    settingsTab.SyncFromDB = function()
        globalEnableCheckbox:SetChecked(ToBoolean(TarballsDadabaseDB.globalEnabled))
        cooldownSlider:SetValue(TarballsDadabaseDB.cooldown)  -- fires OnValueChanged, which updates valueText
        soundCheckbox:SetChecked(ToBoolean(TarballsDadabaseDB.soundEnabled))

        local soundName = "Level Up"
        for _, option in ipairs(SOUND_OPTIONS) do
            if option.value == TarballsDadabaseDB.soundEffect then
                soundName = option.text
                break
            end
        end
        UIDropDownMenu_SetText(soundDropdown, soundName)

        UpdateStats()
    end

    -- Module Tabs
    for _, moduleTab in ipairs(Config.moduleTabs) do
        local tabBtn = CreateTabButton(panel, moduleTab.name, tabButtons)
        local tabIndex = #tabs + 1
        tabBtn:SetScript("OnClick", function() ShowTab(tabIndex) end)
        table.insert(tabButtons, tabBtn)

        local moduleTabFrame = CreateTabFrame(panel)
        table.insert(tabs, moduleTabFrame)

        -- Build module-specific content
        moduleTab.buildContent(moduleTabFrame, moduleTab.moduleId)
    end

    -- Expose tabs so Config:Refresh() can resync widgets from the database on open
    panel.tabs = tabs

    -- Show about tab by default
    ShowTab(1)

    return panel
end

-- ============================================================================
-- Module Content Builder (shared for all modules)
-- ============================================================================

-- Widget factories shared by the module tabs. Keeping creation in small helpers lets
-- BuildModuleContent read as a list of sections instead of one long block.
local function AddSectionLabel(container, yOffset, text)
    local label = container:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    label:SetPoint("TOPLEFT", 10, yOffset)
    label:SetText(text)
    return label
end

local function AddHelpText(container, yOffset, text)
    local help = container:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    help:SetPoint("TOPLEFT", 20, yOffset)
    help:SetPoint("TOPRIGHT", -10, yOffset)
    help:SetJustifyH("LEFT")
    help:SetText(text)
    return help
end

local function AddCheckbox(container, x, yOffset, label, value, onCheck)
    local checkbox = CreateFrame("CheckButton", nil, container, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, yOffset)
    checkbox.text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    checkbox.text:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
    checkbox.text:SetText(label)
    checkbox:SetChecked(ToBoolean(value))

    if onCheck then
        checkbox:SetScript("OnClick", function(self)
            onCheck(ToBoolean(self:GetChecked()))
        end)
    end

    return checkbox
end

local function AddWarningBanner(container)
    local warningFrame = CreateFrame("Frame", nil, container, "BackdropTemplate")
    warningFrame:SetPoint("TOPLEFT", 10, -10)
    warningFrame:SetPoint("TOPRIGHT", -10, -10)
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

    -- Hidden by default; shown only when the addon is globally disabled
    warningFrame:Hide()
    return warningFrame
end

function Config:BuildModuleContent(container, moduleId)
    local moduleDB = Manager:GetModuleSettings(moduleId)
    if not moduleDB then return end

    local module = Manager.modules[moduleId]
    if not module then return end

    local warningFrame = AddWarningBanner(container)

    -- Enable checkbox stays interactive even when the addon is globally disabled
    local enableCheckbox = AddCheckbox(container, 10, -60, "Enable " .. module.name, moduleDB.enabled)

    AddSectionLabel(container, -100, "Trigger on wipes in:")

    local raidCheckbox = AddCheckbox(container, 20, -130, "Raids (includes LFR)", moduleDB.groups.raid, function(value)
        Manager:SetModuleGroup(moduleId, "raid", value)
    end)
    local partyCheckbox = AddCheckbox(container, 200, -130, "Parties (includes LFG)", moduleDB.groups.party, function(value)
        Manager:SetModuleGroup(moduleId, "party", value)
    end)

    -- Pooling help line: enabled modules are combined into one random pool, which is
    -- otherwise invisible to the user (they may expect this module alone to be used).
    AddHelpText(container, -160, "Content is pooled across all enabled modules - one item is picked at random from the combined pool.")

    AddSectionLabel(container, -195, "Message Prefix:")

    -- Forward declaration: the prefix checkbox needs it, but it closes over widgets
    -- that do not exist yet.
    local UpdatePrefixControls

    local prefixCheckbox = AddCheckbox(container, 20, -225, "Enable prefix", moduleDB.prefixEnabled, function(value)
        Manager:SetPrefixEnabled(moduleId, value)
        UpdatePrefixControls()
    end)
    local customPrefixCheckbox = AddCheckbox(container, 20, -255, "Use custom prefix:", moduleDB.useCustomPrefix, function(value)
        Manager:SetUseCustomPrefix(moduleId, value)
    end)

    local prefixInput = CreateFrame("EditBox", nil, container, "InputBoxTemplate")
    prefixInput:SetPoint("TOPLEFT", 40, -285)
    prefixInput:SetSize(440, 20)
    prefixInput:SetAutoFocus(false)
    prefixInput:SetMaxLetters(50)
    prefixInput:SetText(moduleDB.customPrefix or "")
    prefixInput:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
        Manager:SetCustomPrefix(moduleId, self:GetText())
    end)
    prefixInput:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    prefixInput:SetScript("OnEditFocusLost", function(self)
        Manager:SetCustomPrefix(moduleId, self:GetText())
    end)

    local prefixHelp = AddHelpText(container, -305, "Custom prefix will be added before each message (max 50 characters). Press Enter to save.")

    -- Custom prefix controls are only interactive when global + module + prefix are all on
    UpdatePrefixControls = function()
        local shouldEnable = TarballsDadabaseDB.globalEnabled and moduleDB.enabled and ToBoolean(prefixCheckbox:GetChecked())

        if shouldEnable then
            customPrefixCheckbox:Enable()
            customPrefixCheckbox.text:SetTextColor(1, 1, 1)
            prefixInput:Enable()
            prefixInput:SetTextColor(1, 1, 1, 1)
            prefixHelp:SetTextColor(1, 1, 1)
        else
            customPrefixCheckbox:Disable()
            customPrefixCheckbox.text:SetTextColor(0.5, 0.5, 0.5)
            prefixInput:Disable()
            prefixInput:SetTextColor(0.5, 0.5, 0.5, 1)
            prefixHelp:SetTextColor(0.5, 0.5, 0.5)
        end
    end

    -- Divider between auto-save settings and manual-save editor
    local editorDivider = container:CreateTexture(nil, "ARTWORK")
    editorDivider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    editorDivider:SetSize(DIVIDER_WIDTH, 2)
    editorDivider:SetPoint("TOPLEFT", 10, -350)

    local contentLabel = AddSectionLabel(container, -370, "Content Editor (" .. Manager:GetContentCount(moduleId) .. " items)")

    AddHelpText(container, -400, "Edit the content below (one item per line, max " .. MAX_CONTENT_ENTRY_LENGTH .. " characters per line to allow room for prefix). Click 'Save Changes' to apply your edits.")

    -- Multi-line text editor with border (includes buttons at bottom)
    local editorBorder = CreateFrame("Frame", nil, container, "BackdropTemplate")
    editorBorder:SetPoint("TOPLEFT", 5, -425)
    editorBorder:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -5, 20)
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
    scrollFrame:SetPoint("BOTTOMRIGHT", -30, 45)  -- Leave room for buttons at bottom

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

    scrollFrame:SetScrollChild(editBox)

    -- Click handlers to ensure focus (this is what actually fixes Guild Quotes)
    editorBorder:EnableMouse(true)
    editorBorder:SetScript("OnMouseDown", function(self)
        editBox:SetFocus()
    end)

    scrollFrame:EnableMouse(true)
    scrollFrame:SetScript("OnMouseDown", function(self)
        editBox:SetFocus()
    end)

    -- Divider line between editor and button bar
    local buttonDivider = editorBorder:CreateTexture(nil, "ARTWORK")
    buttonDivider:SetColorTexture(0.5, 0.5, 0.5, 0.5)
    buttonDivider:SetHeight(1)
    buttonDivider:SetPoint("BOTTOMLEFT", editorBorder, "BOTTOMLEFT", 10, 40)
    buttonDivider:SetPoint("BOTTOMRIGHT", editorBorder, "BOTTOMRIGHT", -10, 40)

    -- Button bar inside editor frame (visually groups buttons with editor)
    local saveBtn = CreateFrame("Button", nil, editorBorder, "UIPanelButtonTemplate")
    saveBtn:SetSize(100, 25)
    saveBtn:SetPoint("BOTTOMLEFT", editorBorder, "BOTTOMLEFT", 10, 10)
    saveBtn:SetText("Save Changes")
    saveBtn:Disable()

    local statusLabel = editorBorder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    statusLabel:SetPoint("LEFT", saveBtn, "RIGHT", 10, 0)
    statusLabel:SetText("")

    local resetBtn = CreateFrame("Button", nil, editorBorder, "UIPanelButtonTemplate")
    resetBtn:SetSize(120, 25)
    resetBtn:SetPoint("BOTTOMRIGHT", editorBorder, "BOTTOMRIGHT", -10, 10)
    resetBtn:SetText("Reset to Defaults")
    resetBtn:Disable()

    -- Track original content for change detection
    local originalText = ""

    local function LoadContent()
        local content = Manager:GetEffectiveContent(moduleId)
        local text = table.concat(content, "\n")
        editBox:SetText(text)
        originalText = text

        -- Calculate height based on content (ensure minimum height even when empty)
        local numLines = math.max(#content, 10)  -- Minimum 10 lines visible
        local calculatedHeight = math.max(numLines * EDITOR_LINE_HEIGHT, EDITOR_MIN_HEIGHT)
        editBox:SetHeight(calculatedHeight)

        editBox:SetCursorPosition(0)
        contentLabel:SetText("Content Editor (" .. #content .. " items)")
        saveBtn:Disable()
        resetBtn:Disable()
    end

    container.LoadContent = LoadContent

    -- Enable/disable buttons based on text changes
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then
            local currentText = self:GetText()
            if currentText ~= originalText then
                saveBtn:Enable()
                resetBtn:Enable()
            else
                saveBtn:Disable()
                resetBtn:Disable()
            end
        end
    end)

    saveBtn:SetScript("OnClick", function()
        local text = editBox:GetText()
        local newContent = {}
        local skippedLines = 0

        -- Parse lines (split by newline)
        for rawLine in text:gmatch("[^\r\n]+") do
            local line = rawLine:trim()
            if line ~= "" then
                -- Validate line length against the single-message cap (over-limit
                -- lines are skipped, not split -- there is no multi-message logic)
                if #line > MAX_CONTENT_ENTRY_LENGTH then
                    skippedLines = skippedLines + 1
                else
                    -- Sanitize input - remove WoW formatting codes
                    line = Manager:SanitizeText(line)
                    if line ~= "" then
                        table.insert(newContent, line)
                    end
                end
            end
        end

        -- Update the database
        Manager:SetEffectiveContent(moduleId, newContent)

        -- Reload the editor from canonical stored content so the displayed text
        -- always matches what was persisted (skipped over-length lines, sanitized
        -- formatting codes, and collapsed duplicates would otherwise linger on
        -- screen behind a "Saved!" message). LoadContent re-reads GetEffectiveContent,
        -- resets originalText, resizes, disables the buttons, and updates the count.
        LoadContent()

        -- Show feedback using the actual stored count
        local savedCount = Manager:GetContentCount(moduleId)
        local message = "Saved! (" .. savedCount .. " items)"
        if skippedLines > 0 then
            message = message .. " (" .. skippedLines .. " lines over "
                .. MAX_CONTENT_ENTRY_LENGTH .. " chars, skipped)"
        end
        statusLabel:SetText(message)

        -- Clear status after 3 seconds
        C_Timer.After(STATUS_CLEAR_DELAY, function()
            statusLabel:SetText("")
        end)
    end)

    resetBtn:SetScript("OnClick", function()
        -- Clear all user changes
        moduleDB.userAdditions = {}
        moduleDB.userDeletions = {}
        -- Invalidate content cache so runtime uses fresh defaults
        Manager:InvalidateCache(moduleId)
        LoadContent()
        statusLabel:SetText("Reset to defaults!")
        C_Timer.After(STATUS_CLEAR_DELAY, function()
            statusLabel:SetText("")
        end)
    end)

    -- Controls disabled when the addon or this module is disabled. enableCheckbox and
    -- editBox stay interactive on purpose: users can configure and add content before
    -- enabling the module. customPrefixCheckbox and prefixInput are handled by
    -- UpdatePrefixControls.
    local moduleControls = {raidCheckbox, partyCheckbox, prefixCheckbox, saveBtn, resetBtn}
    local controlsWithTooltips = {raidCheckbox, partyCheckbox, prefixCheckbox, saveBtn, resetBtn}

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

    local function SetControlState(control, enabled, tooltipType)
        if enabled then
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

        if tooltipType and tooltipStates[control] ~= tooltipType then
            if tooltipType == "global" then
                control:SetScript("OnEnter", ShowGlobalDisabledTooltip)
                control:SetScript("OnLeave", HideTooltip)
            elseif tooltipType == "module" then
                control:SetScript("OnEnter", ShowModuleDisabledTooltip)
                control:SetScript("OnLeave", HideTooltip)
            elseif tooltipType == "none" then
                control:SetScript("OnEnter", nil)
                control:SetScript("OnLeave", nil)
            end
            tooltipStates[control] = tooltipType
        end
    end

    local function RefreshControls()
        local globalEnabled = TarballsDadabaseDB.globalEnabled
        local moduleEnabled = moduleDB.enabled

        if globalEnabled then
            warningFrame:Hide()
        else
            warningFrame:Show()
        end

        -- Enable checkbox is always enabled (allows configuration when global is disabled)
        SetControlState(enableCheckbox, true, nil)

        local tooltipType = "none"
        if not globalEnabled then
            tooltipType = "global"
        elseif not moduleEnabled then
            tooltipType = "module"
        end

        local controlsEnabled = globalEnabled and moduleEnabled
        for _, control in ipairs(moduleControls) do
            SetControlState(control, controlsEnabled, nil)
        end
        for _, control in ipairs(controlsWithTooltips) do
            SetControlState(control, controlsEnabled, tooltipType)
        end

        UpdatePrefixControls()
    end

    enableCheckbox:SetScript("OnClick", function(self)
        Manager:SetModuleEnabled(moduleId, ToBoolean(self:GetChecked()))
        RefreshControls()
    end)

    container.RefreshControls = RefreshControls

    -- Re-apply saved-variable values into this module tab's widgets. Called on panel
    -- open (and after slash commands) so checkbox/prefix state cannot drift from the
    -- the database. Intentionally does NOT reload the content editor: no slash command edits
    -- content, and reloading would discard a user's unsaved edits.
    container.SyncFromDB = function()
        enableCheckbox:SetChecked(ToBoolean(moduleDB.enabled))
        raidCheckbox:SetChecked(ToBoolean(moduleDB.groups.raid))
        partyCheckbox:SetChecked(ToBoolean(moduleDB.groups.party))
        prefixCheckbox:SetChecked(ToBoolean(moduleDB.prefixEnabled))
        customPrefixCheckbox:SetChecked(ToBoolean(moduleDB.useCustomPrefix))
        prefixInput:SetText(moduleDB.customPrefix or "")
        RefreshControls()
    end

    RefreshControls()
    LoadContent()
end

-- ============================================================================
-- Panel Management
-- ============================================================================

Config.frame = nil

-- Resync all panel widgets from saved variables. Safe to call when the panel
-- has never been built (no-op) -- the build path already reads fresh values.
function Config:Refresh()
    if not self.frame or not self.frame.tabs then
        return
    end
    for _, tab in ipairs(self.frame.tabs) do
        if tab.SyncFromDB then
            tab.SyncFromDB()
        end
    end
end

function Config:Show()
    if not self.frame then
        self.frame = CreateConfigPanel()
    end
    -- Resync before showing so values changed via slash commands while the
    -- (cached) panel was hidden are reflected on reopen.
    self:Refresh()
    self.frame:Show()
end

function Config:Hide()
    if self.frame then
        self.frame:Hide()
    end
end

function Config:Toggle()
    if not self.frame then
        self:Show()
        return
    end

    -- Use IsVisible() instead of IsShown() for proper state detection
    -- IsVisible() checks if frame is actually visible on screen
    -- IsShown() only checks if the shown flag is set (can be out of sync with Settings panel)
    if self.frame:IsVisible() then
        self:Hide()
    else
        self:Show()
    end
end

-- ============================================================================
-- Interface Options Registration
-- ============================================================================

function Config:RegisterInterfaceOptions()
    -- Create a simple settings panel with a button to open the full config
    -- This prevents conflicts between embedded Settings display and standalone dialog
    local settingsPanel = CreateFrame("Frame", "TarballsDadabaseSettingsPanel")
    settingsPanel.name = "Tarball's Dadabase"

    -- Title
    local title = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("Tarball's Dadabase")

    -- Description
    local desc = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    desc:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    desc:SetPoint("TOPRIGHT", settingsPanel, "TOPRIGHT", -16, -32)
    desc:SetJustifyH("LEFT")
    desc:SetText("A World of Warcraft addon that shares uplifting dad jokes, Warcraft puns, motivational quotes, and memorable guild sayings when your raid wipes.")

    -- Open Config button
    local openBtn = CreateFrame("Button", nil, settingsPanel, "UIPanelButtonTemplate")
    openBtn:SetSize(180, 30)
    openBtn:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    openBtn:SetText("Open Configuration")
    openBtn:SetScript("OnClick", function()
        Config:Show()
        -- Close the Settings panel after opening config
        Settings.Close()
    end)

    -- Slash command info
    local slashInfo = settingsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    slashInfo:SetPoint("TOPLEFT", openBtn, "BOTTOMLEFT", 0, -16)
    slashInfo:SetText("You can also use the slash command: /dadabase")

    local category = Settings.RegisterCanvasLayoutCategory(settingsPanel, "Tarball's Dadabase")
    Settings.RegisterAddOnCategory(category)
    self.category = category
end
