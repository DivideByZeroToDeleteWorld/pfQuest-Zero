-- multi api compat
local compat = pfQuestCompat
local L = pfQuest_Loc

pfQuest_history = {}
pfQuest_colors = {}
pfQuest_config = {}

-- ============================================================================
-- Font helpers (LSM with fallback to base fonts)
-- ============================================================================
local LSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)

-- Fallback fonts when LSM isn't available
local fallbackFonts = {
  ["FranzBold"] = pfUI and pfUI.font_default or "Fonts\\ARIALN.TTF",
  ["Arial"] = "Fonts\\ARIALN.TTF",
  ["Skurri"] = "Fonts\\SKURRI.TTF",
  ["Morpheus"] = "Fonts\\MORPHEUS.TTF",
  ["IMMORTAL"] = "Fonts\\IMMORTAL.TTF",
}

-- Get sorted list of available fonts
local function GetAvailableFonts()
  if LSM then
    -- Use LSM's list (always current, includes all registered fonts)
    local fonts = {}
    for _, fontName in ipairs(LSM:List("font")) do
      table.insert(fonts, fontName)
    end
    table.sort(fonts, function(a, b)
      return string.lower(a) < string.lower(b)
    end)
    return fonts
  else
    -- Fallback to base fonts
    local fonts = {}
    for fontName in pairs(fallbackFonts) do
      table.insert(fonts, fontName)
    end
    table.sort(fonts, function(a, b)
      return string.lower(a) < string.lower(b)
    end)
    return fonts
  end
end

-- Get font file path by name
local function GetFontPath(fontName)
  if LSM then
    return LSM:Fetch("font", fontName)
  else
    return fallbackFonts[fontName]
  end
end

-- ============================================================================
-- Custom Font Choice Dropdown (with font preview)
-- ============================================================================
local function CreateFontChoiceDropdown(parent, config, currentValue, onSelect)
  local width = 140
  local height = 20
  local itemHeight = 20
  local fontSize = 11

  -- Create main dropdown button
  local dropdown = CreateFrame("Button", nil, parent)
  dropdown:SetWidth(width)
  dropdown:SetHeight(height)
  pfUI.api.CreateBackdrop(dropdown, nil, true)

  -- Selected font text (will render in the selected font)
  local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
  selectedText:SetFont(pfUI.font_default, fontSize, "OUTLINE")
  selectedText:SetPoint("LEFT", 6, 0)
  selectedText:SetPoint("RIGHT", -18, 0)
  selectedText:SetJustifyH("LEFT")
  selectedText:SetText(currentValue or "Select Font...")
  selectedText:SetTextColor(0.2, 1, 0.8, 1)
  dropdown.selectedText = selectedText

  -- Set initial font preview
  local currentFontPath = currentValue and GetFontPath(currentValue)
  if currentFontPath then
    selectedText:SetFont(currentFontPath, fontSize, "OUTLINE")
  end

  -- Arrow indicator
  local arrow = dropdown:CreateFontString(nil, "OVERLAY")
  arrow:SetFont(pfUI.font_default, 10, "OUTLINE")
  arrow:SetPoint("RIGHT", -4, 0)
  arrow:SetText("v")
  arrow:SetTextColor(0.6, 0.6, 0.6, 1)
  dropdown.arrow = arrow

  -- State
  dropdown.selectedValue = currentValue
  dropdown.isOpen = false
  dropdown.config = config
  dropdown.onSelect = onSelect
  dropdown.itemButtons = {}

  -- Create dropdown list frame
  local list = CreateFrame("Frame", nil, dropdown)
  list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
  list:SetWidth(width)
  list:SetFrameStrata("FULLSCREEN_DIALOG")
  list:SetFrameLevel(dropdown:GetFrameLevel() + 50)
  pfUI.api.CreateBackdrop(list, nil, true, 0.95)
  list:Hide()
  dropdown.list = list

  -- Create scroll frame for the list
  local scrollFrame = CreateFrame("ScrollFrame", nil, list)
  scrollFrame:SetPoint("TOPLEFT", 2, -2)
  scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
  dropdown.scrollFrame = scrollFrame

  -- Create scroll child (content holder)
  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(width - 4)
  scrollFrame:SetScrollChild(scrollChild)
  dropdown.scrollChild = scrollChild

  -- Scrollbar
  local scrollBar = CreateFrame("Frame", nil, list)
  scrollBar:SetWidth(8)
  scrollBar:SetPoint("TOPRIGHT", -2, -2)
  scrollBar:SetPoint("BOTTOMRIGHT", -2, 2)
  scrollBar:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
  scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)
  scrollBar:Hide()
  dropdown.scrollBar = scrollBar

  -- Scrollbar thumb
  local scrollThumb = CreateFrame("Frame", nil, scrollBar)
  scrollThumb:SetWidth(6)
  scrollThumb:SetPoint("TOP", 0, 0)
  scrollThumb:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
  scrollThumb:SetBackdropColor(0.3, 0.3, 0.3, 1)
  scrollThumb:EnableMouse(true)
  scrollThumb:SetMovable(true)
  dropdown.scrollThumb = scrollThumb

  -- Create/update item buttons
  local function PopulateList()
    local fonts = GetAvailableFonts()
    dropdown.items = fonts

    -- Calculate max visible items based on 40% screen height
    local screenHeight = UIParent:GetHeight()
    local maxListHeight = screenHeight * 0.4
    local maxVisibleItems = math.floor(maxListHeight / itemHeight)

    local needsScroll = #fonts > maxVisibleItems
    local visibleCount = needsScroll and maxVisibleItems or #fonts
    local listHeight = (visibleCount * itemHeight) + 4

    list:SetHeight(listHeight)
    scrollChild:SetHeight(#fonts * itemHeight)

    -- Show/hide scrollbar
    if needsScroll then
      scrollBar:Show()
      scrollFrame:SetPoint("BOTTOMRIGHT", -12, 2)
      local thumbHeight = math.max(16, (visibleCount / #fonts) * (listHeight - 4))
      scrollThumb:SetHeight(thumbHeight)
    else
      scrollBar:Hide()
      scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    end

    -- Clear existing buttons
    for _, btn in ipairs(dropdown.itemButtons) do
      btn:Hide()
      btn:SetParent(nil)
    end
    dropdown.itemButtons = {}

    -- Create item buttons
    for i, fontName in ipairs(fonts) do
      local itemBtn = CreateFrame("Button", nil, scrollChild)
      itemBtn:SetSize(width - (needsScroll and 16 or 8), itemHeight)
      itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

      -- Checkmark for selected item
      local checkmark = itemBtn:CreateFontString(nil, "OVERLAY")
      checkmark:SetFont(pfUI.font_default, fontSize - 2, "OUTLINE")
      checkmark:SetPoint("LEFT", 3, 0)
      checkmark:SetText("|cff00cccc>|r")
      checkmark:Hide()
      itemBtn.checkmark = checkmark

      -- Font name text (rendered in its own font)
      local itemText = itemBtn:CreateFontString(nil, "OVERLAY")
      local fontFilePath = GetFontPath(fontName)
      if fontFilePath then
        -- Try to set the font, fallback to default if it fails
        if not itemText:SetFont(fontFilePath, fontSize, "") then
          itemText:SetFont(pfUI.font_default, fontSize, "OUTLINE")
        end
      else
        itemText:SetFont(pfUI.font_default, fontSize, "OUTLINE")
      end
      itemText:SetPoint("LEFT", 16, 0)
      itemText:SetPoint("RIGHT", -2, 0)
      itemText:SetJustifyH("LEFT")
      itemText:SetText(fontName)
      itemText:SetTextColor(0.9, 0.9, 0.9, 1)
      itemBtn.itemText = itemText
      itemBtn.fontName = fontName

      -- Update checkmark visibility
      if dropdown.selectedValue == fontName then
        checkmark:Show()
        itemText:SetTextColor(0.2, 1, 0.8, 1)
      end

      -- Hover effect
      itemBtn:SetScript("OnEnter", function()
        this:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        this:SetBackdropColor(0.15, 0.15, 0.15, 1)
      end)

      itemBtn:SetScript("OnLeave", function()
        this:SetBackdrop(nil)
      end)

      -- Click to select
      itemBtn:SetScript("OnClick", function()
        -- Update all checkmarks
        for _, btn in ipairs(dropdown.itemButtons) do
          btn.checkmark:Hide()
          btn.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
        end

        -- Show checkmark on selected
        this.checkmark:Show()
        this.itemText:SetTextColor(0.2, 1, 0.8, 1)

        -- Update dropdown state
        dropdown.selectedValue = this.fontName

        -- Update selected text with the font preview
        local selectedFontPath = GetFontPath(this.fontName)
        if selectedFontPath then
          dropdown.selectedText:SetFont(selectedFontPath, fontSize, "OUTLINE")
        end
        dropdown.selectedText:SetText(this.fontName)

        -- Close dropdown
        list:Hide()
        dropdown.isOpen = false
        dropdown.arrow:SetText("v")

        -- Call callback
        if dropdown.onSelect then
          dropdown.onSelect(this.fontName)
        end
      end)

      table.insert(dropdown.itemButtons, itemBtn)
    end

    -- Reset scroll position
    scrollFrame:SetVerticalScroll(0)
    scrollThumb:ClearAllPoints()
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, 0)
  end

  -- Mouse wheel scrolling
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function()
    local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
    if maxScroll <= 0 then return end

    local current = scrollFrame:GetVerticalScroll()
    local newScroll = current - (arg1 * itemHeight * 2)
    newScroll = math.max(0, math.min(newScroll, maxScroll))
    scrollFrame:SetVerticalScroll(newScroll)

    -- Update thumb position
    local scrollPercent = newScroll / maxScroll
    local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
    scrollThumb:ClearAllPoints()
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
  end)

  -- Thumb dragging
  scrollThumb:SetScript("OnMouseDown", function()
    if arg1 == "LeftButton" then
      this.dragging = true
      this.dragStartY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
      this.dragStartScroll = scrollFrame:GetVerticalScroll()
    end
  end)

  scrollThumb:SetScript("OnMouseUp", function()
    this.dragging = false
  end)

  scrollThumb:SetScript("OnUpdate", function()
    if this.dragging then
      local currentY = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
      local deltaY = this.dragStartY - currentY

      local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
      if maxScroll <= 0 then return end

      local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
      local scrollDelta = (deltaY / thumbRange) * maxScroll
      local newScroll = math.max(0, math.min(this.dragStartScroll + scrollDelta, maxScroll))

      scrollFrame:SetVerticalScroll(newScroll)

      -- Update thumb position
      local scrollPercent = newScroll / maxScroll
      scrollThumb:ClearAllPoints()
      scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
    end
  end)

  -- Toggle dropdown
  dropdown:SetScript("OnClick", function()
    if this.isOpen then
      this.list:Hide()
      this.isOpen = false
      this.arrow:SetText("v")
    else
      PopulateList()

      -- Smart positioning: check if list would go off-screen
      local scale = UIParent:GetEffectiveScale()
      local dropdownBottom = this:GetBottom() * scale
      local listHeight = list:GetHeight() * scale
      local screenHeight = UIParent:GetHeight() * scale

      list:ClearAllPoints()
      if dropdownBottom - listHeight - 4 < 0 then
        -- List would go below screen - grow upward instead
        list:SetPoint("BOTTOMLEFT", this, "TOPLEFT", 0, 2)
        this.arrow:SetText("v")
      else
        -- Normal: grow downward
        list:SetPoint("TOPLEFT", this, "BOTTOMLEFT", 0, -2)
        this.arrow:SetText("^")
      end

      this.list:Show()
      this.isOpen = true

      -- Scroll to selected item if any
      if this.selectedValue then
        for i, fontName in ipairs(this.items or {}) do
          if fontName == this.selectedValue then
            local targetScroll = (i - 1) * itemHeight
            local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
            if maxScroll > 0 then
              targetScroll = math.min(targetScroll, maxScroll)
              scrollFrame:SetVerticalScroll(targetScroll)

              local scrollPercent = targetScroll / maxScroll
              local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
              scrollThumb:ClearAllPoints()
              scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -scrollPercent * thumbRange)
            end
            break
          end
        end
      end
    end
  end)

  -- Hover effect on main button
  local onEnter = dropdown:GetScript("OnEnter")
  dropdown:SetScript("OnEnter", function()
    if onEnter then onEnter() end
    this:SetBackdropColor(0.1, 0.1, 0.1, 1)
  end)

  local onLeave = dropdown:GetScript("OnLeave")
  dropdown:SetScript("OnLeave", function()
    if onLeave then onLeave() end
    this:SetBackdropColor(0.05, 0.05, 0.05, 1)
  end)

  -- Close when clicking elsewhere
  list:SetScript("OnUpdate", function()
    if dropdown.isOpen and not this:IsMouseOver() and not dropdown:IsMouseOver() then
      if IsMouseButtonDown("LeftButton") then
        this:Hide()
        dropdown.isOpen = false
        dropdown.arrow:SetText("v")
      end
    end
  end)

  -- Helper methods
  function dropdown:GetValue()
    return self.selectedValue
  end

  function dropdown:SetValue(fontName)
    if not fontName then return end
    self.selectedValue = fontName

    local selectedFontPath = self.fontPaths[fontName]
    if selectedFontPath then
      self.selectedText:SetFont(selectedFontPath, fontSize, "OUTLINE")
    end
    self.selectedText:SetText(fontName)

    for _, btn in ipairs(self.itemButtons) do
      if btn.fontName == fontName then
        btn.checkmark:Show()
        btn.itemText:SetTextColor(0.2, 1, 0.8, 1)
      else
        btn.checkmark:Hide()
        btn.itemText:SetTextColor(0.9, 0.9, 0.9, 1)
      end
    end
  end

  return dropdown
end

local reset = {
  config = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the configuration?"]
    dialog.OnAccept = function()
      pfQuest_config = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  history = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the quest history?"]
    dialog.OnAccept = function()
      pfQuest_history = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  cache = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset the caches?"]
    dialog.OnAccept = function()
      pfQuest_questcache = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
  everything = function()
    local dialog = StaticPopupDialogs["PFQUEST_RESET"]
    dialog.text = L["Do you really want to reset everything?"]
    dialog.OnAccept = function()
      pfQuest_config, pfBrowser_fav, pfQuest_history, pfQuest_colors, pfQuest_server, pfQuest_questcache = nil
      ReloadUI()
    end

    StaticPopup_Show("PFQUEST_RESET")
  end,
}

-- default config
pfQuest_defconfig = {
  { -- 1: All Quests; 2: Tracked; 3: Manual; 4: Hide
    config = "trackingmethod",
    text = nil, default = 1, type = nil
  },

  { text = L["General"],
    default = nil, type = "header" },
  { text = L["Enable World Map Menu"],
    default = "1", type = "checkbox", config = "worldmapmenu" },
  { text = L["Enable Minimap Button"],
    default = "1", type = "checkbox", config = "minimapbutton" },
  { text = L["Enable Quest Tracker"],
    default = "1", type = "checkbox", config = "showtracker" },
  { text = L["Enable Quest Log Buttons"],
    default = "1", type = "checkbox", config = "questlogbuttons" },
  { text = L["Enable Quest Link Support"],
    default = "1", type = "checkbox", config = "questlinks" },
  { text = L["Show Database IDs"],
    default = "0", type = "checkbox", config = "showids" },
  { text = L["Draw Favorites On Login"],
    default = "0", type = "checkbox", config = "favonlogin" },
  { text = L["Minimum Item Drop Chance"],
    default = "1", type = "text", config = "mindropchance" },
  { text = L["Show Tooltips"],
    default = "1", type = "checkbox", config = "showtooltips" },
  { text = L["Show Help On Tooltips"],
    default = "1", type = "checkbox", config = "tooltiphelp" },
  { text = L["Show Level On Quest Tracker"],
    default = "1", type = "checkbox", config = "trackerlevel" },
  { text = L["Show Level On Quest Log"],
    default = "0", type = "checkbox", config = "questloglevel" },

  { text = L["Questing"],
    default = nil, type = "header" },
  { text = L["Quest Tracker Visibility"],
    default = "0", type = "text", config = "trackeralpha" },
  { text = L["Quest Tracker Unfold Objectives"],
    default = "0", type = "checkbox", config = "trackerexpand" },
  { text = L["Quest Objective Spawn Points (World Map)"],
    default = "1", type = "checkbox", config = "showspawn" },
  { text = L["Quest Objective Spawn Points (Mini Map)"],
    default = "1", type = "checkbox", config = "showspawnmini" },
  { text = L["Quest Objective Icons (World Map)"],
    default = "1", type = "checkbox", config = "showcluster" },
  { text = L["Quest Objective Icons (Mini Map)"],
    default = "0", type = "checkbox", config = "showclustermini" },
  { text = L["Display Available Quest Givers"],
    default = "1", type = "checkbox", config = "allquestgivers" },
  { text = L["Display Current Quest Givers"],
    default = "1", type = "checkbox", config = "currentquestgivers" },
  { text = L["Display Low Level Quest Givers"],
    default = "0", type = "checkbox", config = "showlowlevel" },
  { text = L["Display Level+3 Quest Givers"],
    default = "0", type = "checkbox", config = "showhighlevel" },
  { text = L["Display Event & Daily Quests"],
    default = "0", type = "checkbox", config = "showfestival" },

  { text = L["Map & Minimap"],
    default = nil, type = "header" },
  { text = L["Enable Minimap Nodes"],
    default = "1", type = "checkbox", config = "minimapnodes" },
  { text = L["Use Icons For Tracking Nodes"],
    default = "1", type = "checkbox", config = "trackingicons" },
  { text = L["Use Monochrome Cluster Icons"],
    default = "0", type = "checkbox", config = "clustermono" },
  { text = L["Use Cut-Out Minimap Node Icons"],
    default = "1", type = "checkbox", config = "cutoutminimap" },
  { text = L["Use Cut-Out World Map Node Icons"],
    default = "0", type = "checkbox", config = "cutoutworldmap" },
  { text = L["Color Map Nodes By Spawn"],
    default = "0", type = "checkbox", config = "spawncolors" },
  { text = L["World Map Node Transparency"],
    default = "1.0", type = "text", config = "worldmaptransp" },
  { text = L["Minimap Node Transparency"],
    default = "1.0", type = "text", config = "minimaptransp" },
  { text = L["Node Fade Transparency"],
    default = "0.3", type = "text", config = "nodefade" },
  { text = L["Highlight Nodes On Mouseover"],
    default = "1", type = "checkbox", config = "mouseover" },

  { text = L["Routes"],
    default = nil, type = "header" },
  { text = L["Show Route Between Objects"],
    default = "1", type = "checkbox", config = "routes" },
  { text = L["Include Unified Quest Locations"],
    default = "1", type = "checkbox", config = "routecluster" },
  { text = L["Include Quest Enders"],
    default = "1", type = "checkbox", config = "routeender" },
  { text = L["Include Quest Starters"],
    default = "0", type = "checkbox", config = "routestarter" },
  { text = L["Show Route On Minimap"],
    default = "0", type = "checkbox", config = "routeminimap" },
  { text = L["Show Arrow Along Routes"],
    default = "1", type = "checkbox", config = "arrow" },

  { text = L["Tracker"],
    default = nil, type = "header" },
  { text = L["Tracker Height"],
    default = "600", type = "text", config = "trackerheight" },
  { text = L["Tracker Width"],
    default = "300", type = "text", config = "trackerwidth" },
  { text = L["Tracker Font Size"],
    default = "12", type = "text", config = "trackerfontsize" },
  { text = L["Tracker Font"],
    default = "FranzBold", type = "dropdown", config = "trackerfont", values = "fonts" },
  { text = L["Tracker Font Style"],
    default = "OUTLINE", type = "dropdown", config = "trackerfontstyle", values = {"", "OUTLINE", "THICKOUTLINE"} },

  { text = L["Misc"] or "Misc",
    default = nil, type = "header" },
  { text = L["Global Settings"] or "Global Settings",
    default = "0", type = "checkbox", config = "globalsettings" },

  { text = L["User Data"],
    default = nil, type = "header" },
  { text = L["Reset Configuration"],
    default = "1", type = "button", func = reset.config },
  { text = L["Reset Quest History"],
    default = "1", type = "button", func = reset.history },
  { text = L["Reset Cache"],
    default = "1", type = "button", func = reset.cache },
  { text = L["Reset Everything"],
    default = "1", type = "button", func = reset.everything },
}

StaticPopupDialogs["PFQUEST_RESET"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

pfQuestConfig = CreateFrame("Frame", "pfQuestConfig", UIParent)
pfQuestConfig:Hide()
pfQuestConfig:SetWidth(280)
pfQuestConfig:SetHeight(550)
pfQuestConfig:SetPoint("CENTER", 0, 0)
pfQuestConfig:SetFrameStrata("HIGH")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:SetClampedToScreen(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")
-- Settings that should be shared globally when "Global Settings" is enabled
pfQuestConfig.globalSettingsKeys = {
  "arrowposx", "arrowposy",  -- Arrow position
  "trackerfont", "trackerfontstyle", "trackerfontsize",  -- Tracker fonts
  "trackerheight", "trackerwidth",  -- Tracker dimensions
}

pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" or arg1 == "pfQuest-Zero" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()
    pfQuestConfig:CreateConfigEntries(pfQuest_defconfig)

    pfQuest_questcache = pfQuest_questcache or {}
    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfQuest_track = pfQuest_track or {}
    pfQuest_global = pfQuest_global or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

    -- Apply global settings if enabled
    if pfQuest_config["globalsettings"] == "1" then
      for _, key in ipairs(pfQuestConfig.globalSettingsKeys) do
        if pfQuest_global[key] ~= nil then
          pfQuest_config[key] = pfQuest_global[key]
        end
      end
    end

    -- clear quest history on new characters
    if UnitXP("player") == 0 and UnitLevel("player") == 1 then
      pfQuest_history = {}
    end

    if pfBrowserIcon and pfQuest_config["minimapbutton"] == "0" then
      pfBrowserIcon:Hide()
    end
  end
end)

-- Helper function to save a setting to global config if global settings is enabled
function pfQuestConfig:SaveGlobalSetting(key, value)
  if pfQuest_config["globalsettings"] == "1" then
    pfQuest_global = pfQuest_global or {}
    pfQuest_global[key] = value
  end
end

pfQuestConfig:SetScript("OnMouseDown", function()
  this:StartMoving()
end)

pfQuestConfig:SetScript("OnMouseUp", function()
  this:StopMovingOrSizing()
end)

pfQuestConfig:SetScript("OnShow", function()
  this:UpdateConfigEntries()
end)

pfQuestConfig.vpos = 40

pfUI.api.CreateBackdrop(pfQuestConfig, nil, true, 0.75)
table.insert(UISpecialFrames, "pfQuestConfig")

-- detect current addon path
local tocs = { "", "-master", "-tbc", "-wotlk", "-Zero" }
for _, name in pairs(tocs) do
  local current = string.format("pfQuest%s", name)
  local _, title = GetAddOnInfo(current)
  if title then
    pfQuestConfig.path = "Interface\\AddOns\\" .. current
    pfQuestConfig.version = tostring(GetAddOnMetadata(current, "Version"))
    break
  end
end

pfQuestConfig.title = pfQuestConfig:CreateFontString("Status", "LOW", "GameFontNormal")
pfQuestConfig.title:SetFontObject(GameFontWhite)
pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
pfQuestConfig.title:SetJustifyH("LEFT")
pfQuestConfig.title:SetFont(pfUI.font_default, 14)
pfQuestConfig.title:SetText("|cff33ffccpf|rQuest " .. L["Config"])

pfQuestConfig.close = CreateFrame("Button", "pfQuestConfigClose", pfQuestConfig)
pfQuestConfig.close:SetPoint("TOPRIGHT", -5, -5)
pfQuestConfig.close:SetHeight(20)
pfQuestConfig.close:SetWidth(20)
pfQuestConfig.close.texture = pfQuestConfig.close:CreateTexture("pfQuestionDialogCloseTex")
pfQuestConfig.close.texture:SetTexture(pfQuestConfig.path.."\\compat\\close")
pfQuestConfig.close.texture:ClearAllPoints()
pfQuestConfig.close.texture:SetPoint("TOPLEFT", pfQuestConfig.close, "TOPLEFT", 4, -4)
pfQuestConfig.close.texture:SetPoint("BOTTOMRIGHT", pfQuestConfig.close, "BOTTOMRIGHT", -4, 4)

pfQuestConfig.close.texture:SetVertexColor(1,.25,.25,1)
pfUI.api.SkinButton(pfQuestConfig.close, 1, .5, .5)
pfQuestConfig.close:SetScript("OnClick", function()
  this:GetParent():Hide()
end)

pfQuestConfig.welcome = CreateFrame("Button", "pfQuestConfigWelcome", pfQuestConfig)
pfQuestConfig.welcome:SetWidth(160)
pfQuestConfig.welcome:SetHeight(28)
pfQuestConfig.welcome:SetPoint("BOTTOMLEFT", 10, 10)
pfQuestConfig.welcome:SetScript("OnClick", function() pfQuestConfig:Hide(); pfQuestInit:Show() end)
pfQuestConfig.welcome.text = pfQuestConfig.welcome:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.welcome.text:SetAllPoints(pfQuestConfig.welcome)
pfQuestConfig.welcome.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.welcome.text:SetText(L["Welcome Screen"])
pfUI.api.SkinButton(pfQuestConfig.welcome)

pfQuestConfig.save = CreateFrame("Button", "pfQuestConfigReload", pfQuestConfig)
pfQuestConfig.save:SetWidth(160)
pfQuestConfig.save:SetHeight(28)
pfQuestConfig.save:SetPoint("BOTTOMRIGHT", -10, 10)
pfQuestConfig.save:SetScript("OnClick", ReloadUI)
pfQuestConfig.save.text = pfQuestConfig.save:CreateFontString("Caption", "LOW", "GameFontWhite")
pfQuestConfig.save.text:SetAllPoints(pfQuestConfig.save)
pfQuestConfig.save.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfQuestConfig.save.text:SetText(L["Save & Close"])
pfUI.api.SkinButton(pfQuestConfig.save)

function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end
  for id, data in pairs(pfQuest_defconfig) do
    if data.config and not pfQuest_config[data.config] then
      pfQuest_config[data.config] = data.default
    end
  end
end

function pfQuestConfig:MigrateHistory()
  if not pfQuest_history then return end

  local match = false

  for entry, data in pairs(pfQuest_history) do
    if type(entry) == "string" then
      for id in pairs(pfDatabase:GetIDByName(entry, "quests")) do
        pfQuest_history[id] = { 0, 0 }
        pfQuest_history[entry] = nil
        match = true
      end
    elseif data == true then
      pfQuest_history[entry] = { 0, 0 }
    elseif type(data) == "table" and not data[1] then
      pfQuest_history[entry] = { 0, 0 }
    end
  end

  if match == true then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: " .. L["Quest history migration completed."])
  end
end

local maxh, maxw = 0, 0
local width, height = 230, 22
local maxtext = 130
local configframes = {}
function pfQuestConfig:CreateConfigEntries(config)
  local count = 1

  for _, data in pairs(config) do
    if data.type then
      -- basic frame
      local frame = CreateFrame("Frame", "pfQuestConfig" .. count, pfQuestConfig)
      configframes[data.text] = frame

      -- caption
      frame.caption = frame:CreateFontString("Status", "LOW", "GameFontWhite")
      frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
      frame.caption:SetPoint("LEFT", 20, 0)
      frame.caption:SetJustifyH("LEFT")
      frame.caption:SetText(data.text)
      maxtext = max(maxtext, frame.caption:GetStringWidth())

      -- header
      if data.type == "header" then
        frame.caption:SetPoint("LEFT", 10, 0)
        frame.caption:SetTextColor(.3,1,.8)
        frame.caption:SetFont(pfUI.font_default, pfUI_config.global.font_size+2, "OUTLINE")

      -- checkbox
      elseif data.type == "checkbox" then
        frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.input:SetNormalTexture("")
        frame.input:SetPushedTexture("")
        frame.input:SetHighlightTexture("")
        pfUI.api.CreateBackdrop(frame.input, nil, true)

        frame.input:SetWidth(16)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT" , -20, 0)

        frame.input.config = data.config
        if pfQuest_config[data.config] == "1" then
          frame.input:SetChecked()
        end

        frame.input:SetScript("OnClick", function ()
          if this:GetChecked() then
            pfQuest_config[this.config] = "1"
          else
            pfQuest_config[this.config] = "0"
          end

          pfQuest:ResetAll()
        end)
      elseif data.type == "text" then
        -- input field
        frame.input = CreateFrame("EditBox", nil, frame)
        frame.input:SetTextColor(.2,1,.8,1)
        frame.input:SetJustifyH("RIGHT")
        frame.input:SetTextInsets(5,5,5,5)
        frame.input:SetWidth(32)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT", -20, 0)
        frame.input:SetFontObject(GameFontNormal)
        frame.input:SetAutoFocus(false)
        frame.input:SetScript("OnEscapePressed", function(self)
          this:ClearFocus()
        end)

        frame.input.config = data.config
        frame.input:SetText(pfQuest_config[data.config])

        frame.input:SetScript("OnTextChanged", function(self)
          pfQuest_config[this.config] = this:GetText()

          -- Refresh tracker when font size changes
          if this.config == "trackerfontsize" then
            if _G.RefreshTrackerFonts then
              _G.RefreshTrackerFonts()
            end
            pfQuest:ResetAll()
          end

          -- Refresh tracker when dimensions change
          if this.config == "trackerheight" or this.config == "trackerwidth" then
            pfQuest:ResetAll()
          end
        end)

        pfUI.api.CreateBackdrop(frame.input, nil, true)
      elseif data.type == "button" and data.func then
        frame.input = CreateFrame("Button", nil, frame)
        frame.input:SetWidth(32)
        frame.input:SetHeight(16)
        frame.input:SetPoint("RIGHT", -20, 0)
        frame.input:SetScript("OnClick", data.func)
        frame.input.text = frame.input:CreateFontString("Caption", "LOW", "GameFontWhite")
        frame.input.text:SetAllPoints(frame.input)
        frame.input.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
        frame.input.text:SetText("OK")
        pfUI.api.SkinButton(frame.input)
      elseif data.type == "dropdown" then
        -- Check if this is a font dropdown - use custom font choice dropdown
        if data.values == "fonts" then
          local current = pfQuest_config[data.config] or data.default
          frame.input = CreateFontChoiceDropdown(frame, data.config, current, function(fontName)
            pfQuest_config[data.config] = fontName

            -- Refresh tracker fonts when font changes
            if data.config == "trackerfont" then
              if _G.RefreshTrackerFonts then
                _G.RefreshTrackerFonts()
              end
            end

            pfQuest:ResetAll()
          end)

          frame.input:SetPoint("RIGHT", -20, 0)
          frame.input.config = data.config
        else
          -- Regular dropdown using UIDropDownMenu for non-font values
          local dropdownName = "pfQuestConfigDropdown" .. count
          frame.input = CreateFrame("Frame", dropdownName, frame, "UIDropDownMenuTemplate")
          frame.input:SetWidth(120)
          frame.input:SetPoint("TOPRIGHT", -5, -2)
          frame.input.config = data.config

          -- initialize dropdown
          UIDropDownMenu_Initialize(frame.input, function()
            local values = data.values
            local sortedValues = {}

            if type(values) == "table" and values[1] then
              -- Already an array, keep as is
              sortedValues = values
            else
              -- convert hash to array and sort
              for k, v in pairs(values) do
                table.insert(sortedValues, k)
              end
              table.sort(sortedValues)
            end

            local current = pfQuest_config[data.config] or data.default

            -- Add buttons
            for idx, name in ipairs(sortedValues) do
              local info = {}
              info.text = name
              info.value = name
              info.checked = (current == name)
              info.func = function()
                pfQuest_config[data.config] = this.value
                UIDropDownMenu_SetText(frame.input, this.value)

                -- Refresh tracker fonts when style changes
                if data.config == "trackerfontstyle" then
                  if _G.RefreshTrackerFonts then
                    _G.RefreshTrackerFonts()
                  end
                end

                pfQuest:ResetAll()
              end
              UIDropDownMenu_AddButton(info)
            end
          end)

          -- store current value for selection
          local current = pfQuest_config[data.config] or data.default
          frame.input.currentValue = current

          -- defer all UIDropDownMenu setup to OnShow to ensure structure is ready
          frame.input:SetScript("OnShow", function()
            if this.initialized then return end

            UIDropDownMenu_SetWidth(this, 120)
            UIDropDownMenu_SetButtonWidth(this, 125)
            UIDropDownMenu_JustifyText(this, "RIGHT")

            local currentValue = pfQuest_config[data.config] or data.default
            if currentValue and currentValue ~= "" then
              UIDropDownMenu_SetText(this, currentValue)
            end

            this.initialized = true
          end)
        end
      end

      -- increase size and zoom back due to blizzard backdrop reasons...
      if frame.input and pfUI.api.emulated then
        frame.input:SetWidth(frame.input:GetWidth()/.6)
        frame.input:SetHeight(frame.input:GetHeight()/.6)
        frame.input:SetScale(.8)
        if frame.input.SetTextInsets then
          frame.input:SetTextInsets(8,8,8,8)
        end
      end

      count = count + 1
    end
  end

  -- update sizes / positions
  width = maxtext + 100
  local column, row = 1, 0

  for _, data in pairs(config) do
    if data.type then
      -- empty line for headers, next column for > 20 entries
      row = row + ( data.type == "header" and row > 1 and 2 or 1 )
      if row > 22 and data.type == "header" then
        column, row = column + 1, 1
      end

      -- update max size values
      maxw, maxh = max(maxw, column), max(maxh, row)

      -- align frames to sizings
      local spacer = (column-1)*20
      local x, y = (column-1)*width, -(row-1)*height
      local frame = configframes[data.text]
      frame:SetWidth(width)
      frame:SetHeight(height)
      frame:SetPoint("TOPLEFT", pfQuestConfig, "TOPLEFT", x + spacer + 10, y - 40)
    end
  end

  local spacer = (maxw-1)*20
  pfQuestConfig:SetWidth(maxw*width + spacer + 20)
  pfQuestConfig:SetHeight(maxh*height + 100)
end

function pfQuestConfig:UpdateConfigEntries()
  for _, data in pairs(pfQuest_defconfig) do
    if data.type and configframes[data.text] then
      if data.type == "checkbox" then
        configframes[data.text].input:SetChecked((pfQuest_config[data.config] == "1" and true or nil))
      elseif data.type == "text" then
        configframes[data.text].input:SetText(pfQuest_config[data.config])
      end
    end
  end
end

do -- welcome/init popup dialog
  local config_stage = {
    arrow = 1,
    mode = 2
  }

  local desaturate = function(texture, state)
    local supported = texture:SetDesaturated(state)
    if not supported then
      if state then
        texture:SetVertexColor(0.5, 0.5, 0.5)
      else
        texture:SetVertexColor(1.0, 1.0, 1.0)
      end
    end
  end

  -- create welcome/init window
  pfQuestInit = CreateFrame("Frame", "pfQuestInit", UIParent)
  pfQuestInit:Hide()
  pfQuestInit:SetWidth(400)
  pfQuestInit:SetHeight(270)
  pfQuestInit:SetMovable(true)
  pfQuestInit:EnableMouse(true)
  pfQuestInit:SetPoint("CENTER", 0, 0)
  pfQuestInit:RegisterEvent("PLAYER_ENTERING_WORLD")
  pfQuestInit:SetScript("OnMouseDown", function()
    this:StartMoving()
  end)

  pfQuestInit:SetScript("OnMouseUp", function()
    this:StopMovingOrSizing()
  end)

  pfQuestInit:SetScript("OnEvent", function()
    if pfQuest_config.welcome ~= "1" then
      -- parse current config
      if pfQuest_config["showspawn"] == "0" and pfQuest_config["showcluster"] == "1" then
        config_stage.mode = 1
      elseif pfQuest_config["showspawn"] == "1" and pfQuest_config["showcluster"] == "0" then
        config_stage.mode = 3
      end

      if pfQuest_config["arrow"] == "0" then
        config_stage.arrow = nil
      end

      pfQuestInit:Show()
    end
    this:UnregisterAllEvents()
  end)

  pfQuestInit:SetScript("OnShow", function()
    -- reload ui elements
    desaturate(pfQuestInit[1].bg, true)
    desaturate(pfQuestInit[2].bg, true)
    desaturate(pfQuestInit[3].bg, true)
    desaturate(pfQuestInit[config_stage.mode].bg, false)
    pfQuestInit.checkbox:SetChecked(config_stage.arrow)
  end)

  pfUI.api.CreateBackdrop(pfQuestInit, nil, true, 0.85)

  -- welcome title
  pfQuestInit.title = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
  pfQuestInit.title:SetPoint("TOP", pfQuestInit, "TOP", 0, -17)
  pfQuestInit.title:SetJustifyH("LEFT")
  pfQuestInit.title:SetText(L["Please select your preferred |cff33ffccpf|cffffffffQuest|r mode:"])

  -- questing mode
  local buttons = {
    { caption = L["Simple Markers"], texture = "\\img\\init\\simple", position = { "TOPLEFT", 10, -40 },
      tooltip = L["Only show cluster icons with summarized objective locations based on spawn points"] },
    { caption = L["Combined"], texture = "\\img\\init\\combined", position = { "TOP", 0, -40 },
      tooltip = L["Show cluster icons with summarized locations and also display all spawn points of each quest objective"] },
    { caption = L["Spawn Points"], texture = "\\img\\init\\spawns", position = { "TOPRIGHT", -10, -40 },
      tooltip = L["Display all spawn points of each quest objective and hide summarized cluster icons."] },
  }

  for i, button in pairs(buttons) do
    pfQuestInit[i] = CreateFrame("Button", "pfQuestInitLeft", pfQuestInit)
    pfQuestInit[i]:SetWidth(120)
    pfQuestInit[i]:SetHeight(160)
    pfQuestInit[i]:SetPoint(unpack(button.position))
    pfQuestInit[i]:SetID(i)

    pfQuestInit[i].bg = pfQuestInit[i]:CreateTexture(nil, "NORMAL")
    pfQuestInit[i].bg:SetWidth(200)
    pfQuestInit[i].bg:SetHeight(200)
    pfQuestInit[i].bg:SetPoint("CENTER", 0, 0)
    pfQuestInit[i].bg:SetTexture(pfQuestConfig.path..button.texture)

    pfQuestInit[i].caption = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
    pfQuestInit[i].caption:SetPoint("TOP", pfQuestInit[i], "BOTTOM", 0, -5)
    pfQuestInit[i].caption:SetJustifyH("LEFT")
    pfQuestInit[i].caption:SetText(button.caption)

    pfUI.api.SkinButton(pfQuestInit[i])

    pfQuestInit[i]:SetScript("OnClick", function()
      desaturate(pfQuestInit[1].bg, true)
      desaturate(pfQuestInit[2].bg, true)
      desaturate(pfQuestInit[3].bg, true)
      desaturate(pfQuestInit[this:GetID()].bg, false)
      config_stage.mode = this:GetID()
    end)

    local OnEnter = pfQuestInit[i]:GetScript("OnEnter")
    pfQuestInit[i]:SetScript("OnEnter", function()
      if OnEnter then OnEnter() end
      GameTooltip_SetDefaultAnchor(GameTooltip, this)

      GameTooltip:SetText(this.caption:GetText())
      GameTooltip:AddLine(buttons[this:GetID()].tooltip, 1, 1, 1, true)
      GameTooltip:SetWidth(100)
      GameTooltip:Show()
    end)

    local OnLeave = pfQuestInit[i]:GetScript("OnLeave")
    pfQuestInit[i]:SetScript("OnLeave", function()
      if OnLeave then OnLeave() end
      GameTooltip:Hide()
    end)
  end

  -- show arrows
  pfQuestInit.checkbox = CreateFrame("CheckButton", nil, pfQuestInit, "UICheckButtonTemplate")
  pfQuestInit.checkbox:SetPoint("BOTTOMLEFT", 10, 10)
  pfQuestInit.checkbox:SetNormalTexture("")
  pfQuestInit.checkbox:SetPushedTexture("")
  pfQuestInit.checkbox:SetHighlightTexture("")
  pfQuestInit.checkbox:SetWidth(22)
  pfQuestInit.checkbox:SetHeight(22)
  pfUI.api.CreateBackdrop(pfQuestInit.checkbox, nil, true)

  pfQuestInit.checkbox.caption = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
  pfQuestInit.checkbox.caption:SetPoint("LEFT", pfQuestInit.checkbox, "RIGHT", 5, 0)
  pfQuestInit.checkbox.caption:SetJustifyH("LEFT")
  pfQuestInit.checkbox.caption:SetText(L["Show Navigation Arrow"])
  pfQuestInit.checkbox:SetScript("OnClick", function()
    config_stage.arrow = this:GetChecked()
  end)

  pfQuestInit.checkbox:SetScript("OnEnter", function()
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    GameTooltip:SetText(L["Navigation Arrow"])
    GameTooltip:AddLine(L["Show navigation arrow that points you to the nearest quest location."], 1, 1, 1, true)
    GameTooltip:SetWidth(100)
    GameTooltip:Show()
  end)

  pfQuestInit.checkbox:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- save button
  pfQuestInit.save = CreateFrame("Button", nil, pfQuestInit)
  pfQuestInit.save:SetWidth(100)
  pfQuestInit.save:SetHeight(24)
  pfQuestInit.save:SetPoint("BOTTOMRIGHT", -10, 10)
  pfQuestInit.save.text = pfQuestInit.save:CreateFontString("Caption", "LOW", "GameFontWhite")
  pfQuestInit.save.text:SetAllPoints(pfQuestInit.save)
  pfQuestInit.save.text:SetText(L["Save & Close"])

  pfUI.api.SkinButton(pfQuestInit.save)

  pfQuestInit.save:SetScript("OnClick", function()
    -- write current config
    if config_stage.mode == 1 then
      pfQuest_config["showspawn"] = "0"
      pfQuest_config["showspawnmini"] = "0"
      pfQuest_config["showcluster"] = "1"
      pfQuest_config["showclustermini"] = "1"
    elseif config_stage.mode == 2 then
      pfQuest_config["showspawn"] = "1"
      pfQuest_config["showspawnmini"] = "1"
      pfQuest_config["showcluster"] = "1"
      pfQuest_config["showclustermini"] = "0"
    elseif config_stage.mode == 3 then
      pfQuest_config["showspawn"] = "1"
      pfQuest_config["showspawnmini"] = "1"
      pfQuest_config["showcluster"] = "0"
      pfQuest_config["showclustermini"] = "0"
    end

    if config_stage.arrow then
      pfQuest_config["arrow"] = "1"
    else
      pfQuest_config["arrow"] = "0"
    end

    -- save welcome flag and reload
    pfQuest_config["welcome"] = "1"
    pfQuest:ResetAll()
    pfQuestInit:Hide()
  end)
end
