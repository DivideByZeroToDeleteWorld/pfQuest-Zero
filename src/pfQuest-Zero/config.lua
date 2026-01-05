-- multi api compat
local compat = pfQuestCompat
local L = pfQuest_Loc

-- NOTE: Do NOT initialize pfQuest_history, pfQuest_colors, or pfQuest_config here!
-- SavedVariables are loaded by WoW before ADDON_LOADED fires.
-- Initializing them here would overwrite any saved data.
-- They are properly initialized in the ADDON_LOADED handler below.

-- ============================================================================
-- Font helpers (LSM with fallback to base fonts)
-- ============================================================================
-- Get LSM - cached on first access (allows other addons to register fonts before we check)
local cachedLSM = nil
local lsmChecked = false

local function GetLSM()
  if not lsmChecked then
    lsmChecked = true
    cachedLSM = LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true)
  end
  return cachedLSM
end

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
  local LSM = GetLSM()
  if LSM then
    local fonts = {}
    for _, fontName in ipairs(LSM:List("font")) do
      table.insert(fonts, fontName)
    end
    table.sort(fonts, function(a, b)
      return string.lower(a) < string.lower(b)
    end)
    return fonts
  else
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
  local LSM = GetLSM()
  if LSM then
    return LSM:Fetch("font", fontName)
  else
    return fallbackFonts[fontName]
  end
end

-- ============================================================================
-- Config Panel Defaults
-- ============================================================================
local configPanelDefaults = {
  width = 320,
  height = 700,
  fontSize = 11,
  font = "FranzBold",
}

-- ============================================================================
-- Styled Dropdown (UIFactory-style)
-- ============================================================================
local function CreateStyledDropdown(parent, width, options)
  options = options or {}
  local height = 18  -- Match text input height
  local fontSize = options.fontSize or 11
  local menuWidth = options.menuWidth or width  -- Allow menu to be wider than button

  -- Get font
  local fontPath = GetFontPath(pfQuest_config.configPanelFont or configPanelDefaults.font)
  if not fontPath then fontPath = pfUI.font_default end

  -- Colors
  local bgColor = {r = 0.08, g = 0.08, b = 0.08, a = 1}
  local borderColor = {r = 0.3, g = 0.3, b = 0.3, a = 1}

  -- Create main button
  local dropdown = CreateFrame("Button", nil, parent)
  dropdown:SetSize(width, height)
  dropdown:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  })
  dropdown:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
  dropdown:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)

  -- Selected text
  local selectedText = dropdown:CreateFontString(nil, "OVERLAY")
  selectedText:SetFont(fontPath, fontSize, "OUTLINE")
  selectedText:SetPoint("LEFT", 8, 0)
  selectedText:SetPoint("RIGHT", -20, 0)
  selectedText:SetJustifyH("LEFT")
  selectedText:SetText(options.placeholder or "Select...")
  selectedText:SetTextColor(0.2, 1, 0.8, 1)
  dropdown.selectedText = selectedText

  -- Arrow indicator
  local arrow = dropdown:CreateFontString(nil, "OVERLAY")
  arrow:SetFont(fontPath, 10, "OUTLINE")
  arrow:SetPoint("RIGHT", -6, 0)
  arrow:SetText("v")
  arrow:SetTextColor(0.6, 0.6, 0.6, 1)
  dropdown.arrow = arrow

  -- Store state
  dropdown.items = options.items or {}
  dropdown.selectedValue = options.selectedValue
  dropdown.onSelect = options.onSelect
  dropdown.isOpen = false
  dropdown.fontSize = fontSize
  dropdown.isFontDropdown = options.isFontDropdown or false

  -- Create dropdown list (hidden by default, parented to UIParent for proper layering)
  local list = CreateFrame("Frame", nil, UIParent)
  list:SetWidth(menuWidth)
  list:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  })
  list:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
  list:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
  list:SetFrameStrata("TOOLTIP")
  list:SetFrameLevel(100)
  list:Hide()
  dropdown.list = list

  -- Position list below dropdown (updated dynamically when shown)
  local function PositionList()
    list:ClearAllPoints()
    list:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 0, -2)
  end

  -- Scrollframe for long lists
  local scrollFrame = CreateFrame("ScrollFrame", nil, list)
  scrollFrame:SetPoint("TOPLEFT", 2, -2)
  scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
  dropdown.scrollFrame = scrollFrame

  local scrollChild = CreateFrame("Frame", nil, scrollFrame)
  scrollChild:SetWidth(menuWidth - 4)
  scrollFrame:SetScrollChild(scrollChild)
  dropdown.scrollChild = scrollChild

  dropdown.itemButtons = {}

  -- Function to populate list items
  local function PopulateList()
    local itemHeight = 20
    local items = dropdown.items

    -- Clear existing buttons
    for _, btn in ipairs(dropdown.itemButtons) do
      btn:Hide()
      btn:SetParent(nil)
    end
    dropdown.itemButtons = {}

    -- Calculate max visible items
    local screenHeight = UIParent:GetHeight()
    local maxListHeight = screenHeight * 0.4
    local maxVisibleItems = math.floor(maxListHeight / itemHeight)
    local needsScroll = #items > maxVisibleItems
    local visibleCount = needsScroll and maxVisibleItems or #items
    local listHeight = (visibleCount * itemHeight) + 4

    list:SetHeight(listHeight)
    scrollChild:SetHeight(#items * itemHeight)

    if needsScroll then
      scrollFrame:SetPoint("BOTTOMRIGHT", -10, 2)
    else
      scrollFrame:SetPoint("BOTTOMRIGHT", -2, 2)
    end

    for i, item in ipairs(items) do
      local value, label, color
      if type(item) == "table" then
        value = item.value or item[1]
        label = item.label or item[2] or tostring(value)
        color = item.color
      else
        value = item
        label = tostring(item)
      end

      local itemBtn = CreateFrame("Button", nil, scrollChild)
      itemBtn:SetSize(menuWidth - (needsScroll and 14 or 8), itemHeight)
      itemBtn:SetPoint("TOPLEFT", 2, -((i - 1) * itemHeight))

      local itemText = itemBtn:CreateFontString(nil, "OVERLAY")

      -- For font dropdowns, try to show each item in its own font
      local fontSet = false
      if dropdown.isFontDropdown then
        local specificFontPath = GetFontPath(value)
        if specificFontPath then
          fontSet = itemText:SetFont(specificFontPath, fontSize - 1, "OUTLINE")
        end
      end

      -- Fallback to config panel font if specific font failed
      if not fontSet and fontPath then
        fontSet = itemText:SetFont(fontPath, fontSize - 1, "OUTLINE")
      end

      -- Last resort: use a guaranteed WoW font
      if not fontSet then
        itemText:SetFont("Fonts\\FRIZQT__.TTF", fontSize - 1, "OUTLINE")
      end

      itemText:SetPoint("LEFT", 6, 0)
      itemText:SetText(label)

      if color then
        itemText:SetTextColor(color.r, color.g, color.b, 1)
      else
        itemText:SetTextColor(0.9, 0.9, 0.9, 1)
      end

      itemBtn.value = value
      itemBtn.label = label
      itemBtn.color = color
      itemBtn.itemText = itemText

      -- Hover effect
      itemBtn:SetScript("OnEnter", function()
        this:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        this:SetBackdropColor(0.2, 0.2, 0.2, 1)
      end)

      itemBtn:SetScript("OnLeave", function()
        this:SetBackdrop(nil)
      end)

      -- Click to select
      itemBtn:SetScript("OnClick", function()
        dropdown.selectedValue = this.value
        dropdown.selectedText:SetText(this.label)
        if this.color then
          dropdown.selectedText:SetTextColor(this.color.r, this.color.g, this.color.b, 1)
        else
          dropdown.selectedText:SetTextColor(0.2, 1, 0.8, 1)
        end
        list:Hide()
        dropdown.isOpen = false
        dropdown.arrow:SetText("v")

        if dropdown.onSelect then
          dropdown.onSelect(this.value, this.label)
        end
      end)

      table.insert(dropdown.itemButtons, itemBtn)
    end
  end

  -- Mouse wheel scrolling
  list:EnableMouseWheel(true)
  list:SetScript("OnMouseWheel", function()
    local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
    if maxScroll <= 0 then return end

    local current = scrollFrame:GetVerticalScroll()
    local newScroll = current - (arg1 * 40)
    newScroll = math.max(0, math.min(newScroll, maxScroll))
    scrollFrame:SetVerticalScroll(newScroll)
  end)

  -- Toggle dropdown
  dropdown:SetScript("OnClick", function()
    if this.isOpen then
      this.list:Hide()
      this.isOpen = false
      this.arrow:SetText("v")
    else
      PositionList()
      PopulateList()
      this.list:Show()
      this.isOpen = true
      this.arrow:SetText("^")
    end
  end)

  -- Hover effect
  dropdown:SetScript("OnEnter", function()
    this:SetBackdropColor(bgColor.r + 0.05, bgColor.g + 0.05, bgColor.b + 0.05, bgColor.a)
  end)

  dropdown:SetScript("OnLeave", function()
    this:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
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
  function dropdown:SetSelectedValue(value)
    self.selectedValue = value
    for _, item in ipairs(self.items) do
      local itemValue, itemLabel
      if type(item) == "table" then
        itemValue = item.value or item[1]
        itemLabel = item.label or item[2] or tostring(itemValue)
      else
        itemValue = item
        itemLabel = tostring(item)
      end

      if itemValue == value then
        self.selectedText:SetText(itemLabel)
        return
      end
    end
  end

  function dropdown:GetSelectedValue()
    return self.selectedValue
  end

  function dropdown:SetItems(items)
    self.items = items
  end

  -- Set initial selection
  if options.selectedValue then
    dropdown:SetSelectedValue(options.selectedValue)
  end

  return dropdown
end

-- ============================================================================
-- Font Choice Dropdown (with font preview)
-- ============================================================================
local fontListRefreshed = false  -- Flag to only refresh once per session

local function CreateFontDropdown(parent, width, currentValue, onSelect, fontSize)
  local fonts = GetAvailableFonts()
  local items = {}
  for _, fontName in ipairs(fonts) do
    table.insert(items, { value = fontName, label = fontName })
  end

  local dropdown = CreateStyledDropdown(parent, width, {
    items = items,
    selectedValue = currentValue,
    onSelect = onSelect,
    fontSize = fontSize or 11,
    placeholder = "Select Font...",
    isFontDropdown = true,
    menuWidth = 200,  -- Wider menu to fit long font names
  })

  -- Update the selected text to use the font itself for preview
  local currentFontPath = currentValue and GetFontPath(currentValue)
  if currentFontPath then
    dropdown.selectedText:SetFont(currentFontPath, fontSize or 11, "OUTLINE")
  end

  -- Override the onSelect to also update font preview
  local origOnSelect = dropdown.onSelect
  dropdown.onSelect = function(value, label)
    local fontPath = GetFontPath(value)
    if fontPath then
      dropdown.selectedText:SetFont(fontPath, fontSize or 11, "OUTLINE")
    end
    if origOnSelect then origOnSelect(value, label) end
  end

  -- Hook OnClick to refresh font list on first click (catches late-registered fonts)
  local origOnClick = dropdown:GetScript("OnClick")
  dropdown:SetScript("OnClick", function()
    if not fontListRefreshed then
      fontListRefreshed = true
      -- Refresh font list from LSM
      local freshFonts = GetAvailableFonts()
      local freshItems = {}
      for _, fontName in ipairs(freshFonts) do
        table.insert(freshItems, { value = fontName, label = fontName })
      end
      dropdown:SetItems(freshItems)
    end
    if origOnClick then origOnClick() end
  end)

  return dropdown
end

-- ============================================================================
-- Font Outline Dropdown (with style preview)
-- ============================================================================
local function CreateFontOutlineDropdown(parent, width, currentValue, onSelect, fontSize)
  fontSize = fontSize or 11

  -- Define all valid font outline options
  local outlineOptions = {
    { value = "", label = "NONE" },
    { value = "OUTLINE", label = "OUTLINE" },
    { value = "THICKOUTLINE", label = "THICKOUTLINE" },
    { value = "MONOCHROME", label = "MONOCHROME" },
    { value = "OUTLINE, MONOCHROME", label = "OUTLINE + MONO" },
    { value = "THICKOUTLINE, MONOCHROME", label = "THICKOUTLINE + MONO" },
  }

  -- Get font for preview
  local fontPath = GetFontPath(pfQuest_config.configPanelFont or configPanelDefaults.font)
  if not fontPath then fontPath = "Fonts\\FRIZQT__.TTF" end

  local dropdown = CreateStyledDropdown(parent, width, {
    items = outlineOptions,
    selectedValue = currentValue or "OUTLINE",
    onSelect = onSelect,
    fontSize = fontSize,
    placeholder = "Select Style...",
    menuWidth = 145,  -- Menu is wider to fit longest option
  })

  -- Store font path for preview updates
  dropdown.fontPath = fontPath
  dropdown.fontSize = fontSize

  -- Update selected text to show outline preview
  if currentValue then
    for _, item in ipairs(outlineOptions) do
      if item.value == currentValue then
        dropdown.selectedText:SetText(item.label)
        dropdown.selectedText:SetFont(fontPath, fontSize, currentValue)
        break
      end
    end
  end

  -- Override onSelect to update preview
  local origOnSelect = dropdown.onSelect
  dropdown.onSelect = function(value, label)
    dropdown.selectedText:SetFont(dropdown.fontPath, dropdown.fontSize, value)
    if origOnSelect then origOnSelect(value, label) end
  end

  -- Override SetSelectedValue to update preview
  local origSetSelectedValue = dropdown.SetSelectedValue
  dropdown.SetSelectedValue = function(self, value)
    self.selectedValue = value
    for _, item in ipairs(outlineOptions) do
      if item.value == value then
        self.selectedText:SetText(item.label)
        self.selectedText:SetFont(self.fontPath, self.fontSize, value)
        return
      end
    end
    self.selectedText:SetText(value == "" and "NONE" or value)
  end

  return dropdown
end

-- ============================================================================
-- Reset Functions
-- ============================================================================
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

-- ============================================================================
-- Config Definition (organized by blocks)
-- ============================================================================
pfQuest_defconfig = {
  -- Hidden tracking method config
  { config = "trackingmethod", default = 1, type = nil },

  -- Config Panel Block (new!)
  { text = "Config Panel", default = nil, type = "header", block = "config" },
  { text = "Panel Width", default = "320", type = "text", config = "configPanelWidth", block = "config" },
  { text = "Panel Height", default = "700", type = "text", config = "configPanelHeight", block = "config" },
  { text = "Panel Font Size", default = "11", type = "text", config = "configPanelFontSize", block = "config" },
  { text = "Panel Font", default = "FranzBold", type = "fontdropdown", config = "configPanelFont", block = "config" },

  -- Tracker Block
  { text = L["Tracker"], default = nil, type = "header", block = "tracker" },
  { text = L["Tracker Height"], default = "600", type = "text", config = "trackerheight", block = "tracker" },
  { text = L["Tracker Width"], default = "300", type = "text", config = "trackerwidth", block = "tracker" },
  { text = L["Tracker Font Size"], default = "12", type = "text", config = "trackerfontsize", block = "tracker" },
  { text = L["Tracker Font"], default = "FranzBold", type = "fontdropdown", config = "trackerfont", block = "tracker" },
  { text = L["Tracker Font Style"], default = "OUTLINE", type = "fontoutlinedropdown", config = "trackerfontstyle", block = "tracker" },
  { text = L["Always Show Tracker Background"], default = "0", type = "checkbox", config = "trackerbgalways", block = "tracker" },
  { text = L["Always Show Tracker Config Bar & BG"], default = "0", type = "checkbox", config = "trackerbaralways", block = "tracker" },

  -- General Block
  { text = L["General"], default = nil, type = "header", block = "general" },
  { text = L["Enable World Map Menu"], default = "1", type = "checkbox", config = "worldmapmenu", block = "general" },
  { text = L["Enable Minimap Button"], default = "1", type = "checkbox", config = "minimapbutton", block = "general" },
  { text = L["Enable Quest Tracker"], default = "1", type = "checkbox", config = "showtracker", block = "general" },
  { text = L["Enable Quest Log Buttons"], default = "1", type = "checkbox", config = "questlogbuttons", block = "general" },
  { text = L["Enable Quest Link Support"], default = "1", type = "checkbox", config = "questlinks", block = "general" },
  { text = L["Show Database IDs"], default = "0", type = "checkbox", config = "showids", block = "general" },
  { text = L["Draw Favorites On Login"], default = "0", type = "checkbox", config = "favonlogin", block = "general" },
  { text = L["Minimum Item Drop Chance"], default = "1", type = "text", config = "mindropchance", block = "general" },
  { text = L["Show Tooltips"], default = "1", type = "checkbox", config = "showtooltips", block = "general" },
  { text = L["Show Help On Tooltips"], default = "1", type = "checkbox", config = "tooltiphelp", block = "general" },
  { text = L["Show Level On Quest Tracker"], default = "1", type = "checkbox", config = "trackerlevel", block = "general" },
  { text = L["Show Level On Quest Log"], default = "0", type = "checkbox", config = "questloglevel", block = "general" },

  -- Questing Block
  { text = L["Questing"], default = nil, type = "header", block = "questing" },
  { text = L["Quest Tracker Visibility"], default = "0", type = "text", config = "trackeralpha", block = "questing" },
  { text = L["Quest Tracker Unfold Objectives"], default = "0", type = "checkbox", config = "trackerexpand", block = "questing" },
  { text = L["Quest Timers Fold Into Objectives"], default = "1", type = "checkbox", config = "collapsetimer", block = "questing" },
  { text = L["Quest Objective Spawn Points (World Map)"], default = "1", type = "checkbox", config = "showspawn", block = "questing" },
  { text = L["Quest Objective Spawn Points (Mini Map)"], default = "1", type = "checkbox", config = "showspawnmini", block = "questing" },
  { text = L["Quest Objective Icons (World Map)"], default = "1", type = "checkbox", config = "showcluster", block = "questing" },
  { text = L["Quest Objective Icons (Mini Map)"], default = "0", type = "checkbox", config = "showclustermini", block = "questing" },
  { text = L["Display Available Quest Givers"], default = "1", type = "checkbox", config = "allquestgivers", block = "questing" },
  { text = L["Display Current Quest Givers"], default = "1", type = "checkbox", config = "currentquestgivers", block = "questing" },
  { text = L["Display Low Level Quest Givers"], default = "0", type = "checkbox", config = "showlowlevel", block = "questing" },
  { text = L["Display Level+3 Quest Givers"], default = "0", type = "checkbox", config = "showhighlevel", block = "questing" },
  { text = L["Display Event & Daily Quests"], default = "0", type = "checkbox", config = "showfestival", block = "questing" },
  { text = L["Display Quest Timer Max Duration"], default = "1", type = "checkbox", config = "showtimermax", block = "questing" },

  -- Map & Minimap Block
  { text = L["Map & Minimap"], default = nil, type = "header", block = "map" },
  { text = L["Enable Minimap Nodes"], default = "1", type = "checkbox", config = "minimapnodes", block = "map" },
  { text = L["Use Icons For Tracking Nodes"], default = "1", type = "checkbox", config = "trackingicons", block = "map" },
  { text = L["Use Monochrome Cluster Icons"], default = "0", type = "checkbox", config = "clustermono", block = "map" },
  { text = L["Use Cut-Out Minimap Node Icons"], default = "1", type = "checkbox", config = "cutoutminimap", block = "map" },
  { text = L["Use Cut-Out World Map Node Icons"], default = "0", type = "checkbox", config = "cutoutworldmap", block = "map" },
  { text = L["Color Map Nodes By Spawn"], default = "0", type = "checkbox", config = "spawncolors", block = "map" },
  { text = L["World Map Node Transparency"], default = "1.0", type = "text", config = "worldmaptransp", block = "map" },
  { text = L["Minimap Node Transparency"], default = "1.0", type = "text", config = "minimaptransp", block = "map" },
  { text = L["Node Fade Transparency"], default = "0.3", type = "text", config = "nodefade", block = "map" },
  { text = L["Highlight Nodes On Mouseover"], default = "1", type = "checkbox", config = "mouseover", block = "map" },

  -- Routes Block
  { text = L["Routes"], default = nil, type = "header", block = "routes" },
  { text = L["Show Route Between Objects"], default = "1", type = "checkbox", config = "routes", block = "routes" },
  { text = L["Include Unified Quest Locations"], default = "1", type = "checkbox", config = "routecluster", block = "routes" },
  { text = L["Include Quest Enders"], default = "1", type = "checkbox", config = "routeender", block = "routes" },
  { text = L["Include Quest Starters"], default = "0", type = "checkbox", config = "routestarter", block = "routes" },
  { text = L["Show Route On Minimap"], default = "0", type = "checkbox", config = "routeminimap", block = "routes" },
  { text = L["Show Arrow Along Routes"], default = "1", type = "checkbox", config = "arrow", block = "routes" },

  -- User Data Block
  { text = L["User Data"], default = nil, type = "header", block = "userdata" },
  { text = L["Reset Configuration"], default = "1", type = "button", func = reset.config, block = "userdata" },
  { text = L["Reset Quest History"], default = "1", type = "button", func = reset.history, block = "userdata" },
  { text = L["Reset Cache"], default = "1", type = "button", func = reset.cache, block = "userdata" },
  { text = L["Reset Everything"], default = "1", type = "button", func = reset.everything, block = "userdata" },
}

StaticPopupDialogs["PFQUEST_RESET"] = {
  button1 = YES,
  button2 = NO,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

-- ============================================================================
-- Config Panel Frame
-- ============================================================================
pfQuestConfig = CreateFrame("Frame", "pfQuestConfig", UIParent)
pfQuestConfig:Hide()
pfQuestConfig:SetPoint("CENTER", 0, 0)
pfQuestConfig:SetFrameStrata("HIGH")
pfQuestConfig:SetMovable(true)
pfQuestConfig:EnableMouse(true)
pfQuestConfig:SetClampedToScreen(true)
pfQuestConfig:RegisterEvent("ADDON_LOADED")

-- Detect current addon path
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

-- ============================================================================
-- Helper: Get Config Font
-- ============================================================================
local function GetConfigFont()
  local fontName = pfQuest_config.configPanelFont or configPanelDefaults.font
  local fontPath = GetFontPath(fontName)
  return fontPath or pfUI.font_default
end

local function GetConfigFontSize()
  return tonumber(pfQuest_config.configPanelFontSize) or configPanelDefaults.fontSize
end

-- ============================================================================
-- Create Panel Structure
-- ============================================================================
local function CreateConfigPanel()
  local panelWidth = tonumber(pfQuest_config.configPanelWidth) or configPanelDefaults.width
  local panelHeight = tonumber(pfQuest_config.configPanelHeight) or configPanelDefaults.height
  local fontSize = GetConfigFontSize()
  local fontPath = GetConfigFont()

  pfQuestConfig:SetWidth(panelWidth)
  pfQuestConfig:SetHeight(panelHeight)

  -- Sleek 1px border backdrop
  pfQuestConfig:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
    insets = { left = 0, right = 0, top = 0, bottom = 0 }
  })
  pfQuestConfig:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
  pfQuestConfig:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

  -- Title
  if not pfQuestConfig.title then
    pfQuestConfig.title = pfQuestConfig:CreateFontString(nil, "OVERLAY")
  end
  pfQuestConfig.title:SetFont(fontPath, fontSize + 3, "OUTLINE")
  pfQuestConfig.title:SetPoint("TOP", pfQuestConfig, "TOP", 0, -8)
  pfQuestConfig.title:SetText("|cff33ffccpf|rQuest " .. L["Config"])

  -- Close button
  if not pfQuestConfig.close then
    pfQuestConfig.close = CreateFrame("Button", nil, pfQuestConfig)
    pfQuestConfig.close:SetPoint("TOPRIGHT", -5, -5)
    pfQuestConfig.close:SetSize(18, 18)
    pfQuestConfig.close:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false, tileSize = 1, edgeSize = 1,
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    pfQuestConfig.close:SetBackdropColor(0.3, 0.1, 0.1, 1)
    pfQuestConfig.close:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

    pfQuestConfig.close.text = pfQuestConfig.close:CreateFontString(nil, "OVERLAY")
    pfQuestConfig.close.text:SetFont(fontPath, fontSize, "OUTLINE")
    pfQuestConfig.close.text:SetPoint("CENTER", 0, 0)
    pfQuestConfig.close.text:SetText("X")
    pfQuestConfig.close.text:SetTextColor(1, 0.3, 0.3, 1)

    pfQuestConfig.close:SetScript("OnClick", function() pfQuestConfig:Hide() end)
    pfQuestConfig.close:SetScript("OnEnter", function()
      this:SetBackdropColor(0.5, 0.1, 0.1, 1)
    end)
    pfQuestConfig.close:SetScript("OnLeave", function()
      this:SetBackdropColor(0.3, 0.1, 0.1, 1)
    end)
  end

  -- Scroll frame for content
  if not pfQuestConfig.scrollFrame then
    pfQuestConfig.scrollFrame = CreateFrame("ScrollFrame", nil, pfQuestConfig)
    pfQuestConfig.scrollFrame:SetPoint("TOPLEFT", 5, -30)
    pfQuestConfig.scrollFrame:SetPoint("BOTTOMRIGHT", -12, 45)  -- Leave room for scrollbar

    pfQuestConfig.scrollChild = CreateFrame("Frame", nil, pfQuestConfig.scrollFrame)
    pfQuestConfig.scrollChild:SetWidth(panelWidth - 17)  -- Account for scrollbar
    pfQuestConfig.scrollChild:SetHeight(1) -- Will be updated
    pfQuestConfig.scrollFrame:SetScrollChild(pfQuestConfig.scrollChild)

    -- Scrollbar track (slim, no buttons)
    pfQuestConfig.scrollBar = CreateFrame("Frame", nil, pfQuestConfig)
    pfQuestConfig.scrollBar:SetWidth(6)
    pfQuestConfig.scrollBar:SetPoint("TOPRIGHT", -5, -30)
    pfQuestConfig.scrollBar:SetPoint("BOTTOMRIGHT", -5, 45)
    pfQuestConfig.scrollBar:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    pfQuestConfig.scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

    -- Scrollbar thumb (draggable)
    pfQuestConfig.scrollThumb = CreateFrame("Frame", nil, pfQuestConfig.scrollBar)
    pfQuestConfig.scrollThumb:SetWidth(6)
    pfQuestConfig.scrollThumb:SetHeight(40)
    pfQuestConfig.scrollThumb:SetPoint("TOP", 0, 0)
    pfQuestConfig.scrollThumb:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    pfQuestConfig.scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
    pfQuestConfig.scrollThumb:EnableMouse(true)

    -- Drag state
    pfQuestConfig.isDragging = false

    -- Thumb drag handling
    pfQuestConfig.scrollThumb:SetScript("OnMouseDown", function()
      pfQuestConfig.isDragging = true
      local _, cursorY = GetCursorPosition()
      pfQuestConfig.dragStartY = cursorY / UIParent:GetEffectiveScale()
      pfQuestConfig.dragStartScroll = pfQuestConfig.scrollFrame:GetVerticalScroll()
    end)

    pfQuestConfig.scrollThumb:SetScript("OnMouseUp", function()
      pfQuestConfig.isDragging = false
    end)

    pfQuestConfig.scrollThumb:SetScript("OnUpdate", function()
      if not pfQuestConfig.isDragging then return end

      -- Clear drag state if mouse released
      if not IsMouseButtonDown("LeftButton") then
        pfQuestConfig.isDragging = false
        return
      end

      local _, cursorY = GetCursorPosition()
      local currentY = cursorY / UIParent:GetEffectiveScale()
      local deltaY = pfQuestConfig.dragStartY - currentY

      local maxScroll = pfQuestConfig.scrollChild:GetHeight() - pfQuestConfig.scrollFrame:GetHeight()
      if maxScroll <= 0 then return end

      local thumbRange = pfQuestConfig.scrollBar:GetHeight() - pfQuestConfig.scrollThumb:GetHeight()
      if thumbRange <= 0 then return end

      local scrollPerPixel = maxScroll / thumbRange
      local newScroll = pfQuestConfig.dragStartScroll + (deltaY * scrollPerPixel)
      newScroll = math.max(0, math.min(newScroll, maxScroll))

      pfQuestConfig.scrollFrame:SetVerticalScroll(newScroll)

      -- Update thumb position
      local thumbPos = (newScroll / maxScroll) * thumbRange
      pfQuestConfig.scrollThumb:ClearAllPoints()
      pfQuestConfig.scrollThumb:SetPoint("TOP", pfQuestConfig.scrollBar, "TOP", 0, -thumbPos)
    end)

    -- Mouse wheel scrolling (also updates thumb)
    pfQuestConfig.scrollFrame:EnableMouseWheel(true)
    pfQuestConfig.scrollFrame:SetScript("OnMouseWheel", function()
      local maxScroll = pfQuestConfig.scrollChild:GetHeight() - pfQuestConfig.scrollFrame:GetHeight()
      if maxScroll <= 0 then return end

      local current = pfQuestConfig.scrollFrame:GetVerticalScroll()
      local newScroll = current - (arg1 * 30)
      newScroll = math.max(0, math.min(newScroll, maxScroll))
      pfQuestConfig.scrollFrame:SetVerticalScroll(newScroll)

      -- Update thumb position
      local thumbRange = pfQuestConfig.scrollBar:GetHeight() - pfQuestConfig.scrollThumb:GetHeight()
      if thumbRange > 0 then
        local thumbPos = (newScroll / maxScroll) * thumbRange
        pfQuestConfig.scrollThumb:ClearAllPoints()
        pfQuestConfig.scrollThumb:SetPoint("TOP", pfQuestConfig.scrollBar, "TOP", 0, -thumbPos)
      end
    end)
  else
    pfQuestConfig.scrollChild:SetWidth(panelWidth - 17)
  end

  -- Bottom buttons (3 buttons: Welcome Screen, Save, Save & Reload)
  local buttonWidth = (panelWidth - 20) / 3 - 3  -- 3 buttons with spacing

  if not pfQuestConfig.welcome then
    pfQuestConfig.welcome = CreateFrame("Button", nil, pfQuestConfig)
    pfQuestConfig.welcome:SetSize(buttonWidth, 28)
    pfQuestConfig.welcome:SetPoint("BOTTOMLEFT", 5, 8)
    pfQuestConfig.welcome:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false, tileSize = 1, edgeSize = 1,
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    pfQuestConfig.welcome:SetBackdropColor(0.1, 0.1, 0.1, 1)
    pfQuestConfig.welcome:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    pfQuestConfig.welcome.text = pfQuestConfig.welcome:CreateFontString(nil, "OVERLAY")
    pfQuestConfig.welcome.text:SetFont(fontPath, fontSize, "OUTLINE")
    pfQuestConfig.welcome.text:SetPoint("CENTER", 0, 0)
    pfQuestConfig.welcome.text:SetText(L["Welcome"])

    pfQuestConfig.welcome:SetScript("OnClick", function()
      pfQuestInit:Show()
    end)
    pfQuestConfig.welcome:SetScript("OnEnter", function()
      this:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end)
    pfQuestConfig.welcome:SetScript("OnLeave", function()
      this:SetBackdropColor(0.1, 0.1, 0.1, 1)
    end)
  end

  if not pfQuestConfig.save then
    pfQuestConfig.save = CreateFrame("Button", nil, pfQuestConfig)
    pfQuestConfig.save:SetSize(buttonWidth, 28)
    pfQuestConfig.save:SetPoint("LEFT", pfQuestConfig.welcome, "RIGHT", 5, 0)
    pfQuestConfig.save:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false, tileSize = 1, edgeSize = 1,
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    pfQuestConfig.save:SetBackdropColor(0.1, 0.15, 0.1, 1)
    pfQuestConfig.save:SetBackdropBorderColor(0.2, 0.4, 0.2, 1)

    pfQuestConfig.save.text = pfQuestConfig.save:CreateFontString(nil, "OVERLAY")
    pfQuestConfig.save.text:SetFont(fontPath, fontSize, "OUTLINE")
    pfQuestConfig.save.text:SetPoint("CENTER", 0, 0)
    pfQuestConfig.save.text:SetText(L["Save"])

    pfQuestConfig.save:SetScript("OnClick", function()
      pfQuestConfig:Hide()
    end)
    pfQuestConfig.save:SetScript("OnEnter", function()
      this:SetBackdropColor(0.15, 0.25, 0.15, 1)
    end)
    pfQuestConfig.save:SetScript("OnLeave", function()
      this:SetBackdropColor(0.1, 0.15, 0.1, 1)
    end)
  end

  if not pfQuestConfig.saveReload then
    pfQuestConfig.saveReload = CreateFrame("Button", nil, pfQuestConfig)
    pfQuestConfig.saveReload:SetSize(buttonWidth, 28)
    pfQuestConfig.saveReload:SetPoint("LEFT", pfQuestConfig.save, "RIGHT", 5, 0)
    pfQuestConfig.saveReload:SetBackdrop({
      bgFile = "Interface\\Buttons\\WHITE8X8",
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      tile = false, tileSize = 1, edgeSize = 1,
      insets = { left = 0, right = 0, top = 0, bottom = 0 }
    })
    pfQuestConfig.saveReload:SetBackdropColor(0.15, 0.1, 0.1, 1)
    pfQuestConfig.saveReload:SetBackdropBorderColor(0.4, 0.2, 0.2, 1)

    pfQuestConfig.saveReload.text = pfQuestConfig.saveReload:CreateFontString(nil, "OVERLAY")
    pfQuestConfig.saveReload.text:SetFont(fontPath, fontSize, "OUTLINE")
    pfQuestConfig.saveReload.text:SetPoint("CENTER", 0, 0)
    pfQuestConfig.saveReload.text:SetText(L["Save & Reload"])

    pfQuestConfig.saveReload:SetScript("OnClick", ReloadUI)
    pfQuestConfig.saveReload:SetScript("OnEnter", function()
      this:SetBackdropColor(0.25, 0.15, 0.15, 1)
    end)
    pfQuestConfig.saveReload:SetScript("OnLeave", function()
      this:SetBackdropColor(0.15, 0.1, 0.1, 1)
    end)
  end

  -- Update button sizes for new panel width
  local buttonWidth = (panelWidth - 20) / 3 - 3
  pfQuestConfig.welcome:SetWidth(buttonWidth)
  pfQuestConfig.save:SetWidth(buttonWidth)
  pfQuestConfig.saveReload:SetWidth(buttonWidth)
end

-- ============================================================================
-- Create Config Entries
-- ============================================================================
local configFrames = {}
local blockFrames = {}

local function CreateConfigEntries()
  local fontSize = GetConfigFontSize()
  local fontPath = GetConfigFont()
  local panelWidth = tonumber(pfQuest_config.configPanelWidth) or configPanelDefaults.width
  local contentWidth = panelWidth - 20

  local rowHeight = fontSize + 10
  local blockPadding = 10
  local yOffset = 0

  -- Block colors (pastel-ish)
  local blockColors = {
    config = { r = 0.8, g = 0.6, b = 0.2 },    -- Gold
    general = { r = 0.2, g = 0.8, b = 0.6 },   -- Teal
    questing = { r = 0.6, g = 0.8, b = 0.2 },  -- Lime
    map = { r = 0.2, g = 0.6, b = 0.8 },       -- Blue
    routes = { r = 0.8, g = 0.2, b = 0.6 },    -- Magenta
    tracker = { r = 0.6, g = 0.2, b = 0.8 },   -- Purple
    userdata = { r = 0.8, g = 0.3, b = 0.3 },  -- Red
  }

  -- Clear existing frames
  for _, frame in pairs(configFrames) do
    frame:Hide()
    frame:SetParent(nil)
  end
  configFrames = {}
  blockFrames = {}

  local currentBlock = nil

  for idx, data in ipairs(pfQuest_defconfig) do
    if data.type then
      local frame = CreateFrame("Frame", nil, pfQuestConfig.scrollChild)
      frame:SetWidth(contentWidth)
      frame:SetHeight(rowHeight)
      configFrames[data.text or idx] = frame

      if data.type == "header" then
        -- Block header
        yOffset = yOffset + (currentBlock and blockPadding or 0)

        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 0, -yOffset)
        frame:SetHeight(rowHeight + 4)

        -- Block background
        local blockColor = blockColors[data.block] or { r = 0.3, g = 0.3, b = 0.3 }

        local headerBg = frame:CreateTexture(nil, "BACKGROUND")
        headerBg:SetTexture("Interface\\Buttons\\WHITE8X8")
        headerBg:SetAllPoints()
        headerBg:SetVertexColor(blockColor.r * 0.2, blockColor.g * 0.2, blockColor.b * 0.2, 0.8)

        -- Left accent bar
        local accent = frame:CreateTexture(nil, "ARTWORK")
        accent:SetTexture("Interface\\Buttons\\WHITE8X8")
        accent:SetWidth(3)
        accent:SetPoint("TOPLEFT", 0, 0)
        accent:SetPoint("BOTTOMLEFT", 0, 0)
        accent:SetVertexColor(blockColor.r, blockColor.g, blockColor.b, 1)

        -- Header text
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize + 1, "OUTLINE")
        frame.caption:SetPoint("LEFT", 10, 0)
        frame.caption:SetTextColor(blockColor.r, blockColor.g, blockColor.b, 1)
        frame.caption:SetText(data.text)

        yOffset = yOffset + rowHeight + 6
        currentBlock = data.block
        blockFrames[data.block] = { header = frame, items = {} }

      elseif data.type == "checkbox" then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Checkbox
        frame.input = CreateFrame("CheckButton", nil, frame, "UICheckButtonTemplate")
        frame.input:SetNormalTexture("")
        frame.input:SetPushedTexture("")
        frame.input:SetHighlightTexture("")
        frame.input:SetSize(16, 16)
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input:SetBackdrop({
          bgFile = "Interface\\Buttons\\WHITE8X8",
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          tile = false, tileSize = 1, edgeSize = 1,
          insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        frame.input:SetBackdropColor(0.1, 0.1, 0.1, 1)
        frame.input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        frame.input.config = data.config
        if pfQuest_config[data.config] == "1" then
          frame.input:SetChecked(true)
        end

        frame.input:SetScript("OnClick", function()
          if this:GetChecked() then
            pfQuest_config[this.config] = "1"
          else
            pfQuest_config[this.config] = "0"
          end

          -- Special handling for minimap button visibility
          if this.config == "minimapbutton" and pfQuestIcon then
            if pfQuest_config["minimapbutton"] == "1" then
              pfQuestIcon:Show()
            else
              pfQuestIcon:Hide()
            end
          end

          pfQuest:ResetAll()
        end)

        yOffset = yOffset + rowHeight
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end

      elseif data.type == "text" then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Input field
        frame.input = CreateFrame("EditBox", nil, frame)
        frame.input:SetSize(50, 18)
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input:SetFont(fontPath, fontSize, "OUTLINE")
        frame.input:SetTextColor(0.2, 1, 0.8, 1)
        frame.input:SetJustifyH("RIGHT")
        frame.input:SetTextInsets(5, 5, 2, 2)
        frame.input:SetAutoFocus(false)
        frame.input:SetBackdrop({
          bgFile = "Interface\\Buttons\\WHITE8X8",
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          tile = false, tileSize = 1, edgeSize = 1,
          insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        frame.input:SetBackdropColor(0.1, 0.1, 0.1, 1)
        frame.input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        frame.input.config = data.config
        frame.input:SetText(pfQuest_config[data.config] or data.default or "")

        frame.input:SetScript("OnEscapePressed", function() this:ClearFocus() end)
        frame.input:SetScript("OnEnterPressed", function() this:ClearFocus() end)
        frame.input:SetScript("OnTextChanged", function()
          pfQuest_config[this.config] = this:GetText()

          -- Special handling for tracker configs (live update is fine)
          if this.config == "trackerfontsize" or this.config == "trackerheight" or this.config == "trackerwidth" then
            if _G.RefreshTrackerFonts then _G.RefreshTrackerFonts() end
            pfQuest:ResetAll()
          end
        end)

        -- Config panel settings need to rebuild, so only do it on focus loss
        frame.input:SetScript("OnEditFocusLost", function()
          if this.config == "configPanelWidth" or this.config == "configPanelHeight" or this.config == "configPanelFontSize" then
            CreateConfigPanel()
            CreateConfigEntries()
          end
        end)

        yOffset = yOffset + rowHeight
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end

      elseif data.type == "button" and data.func then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Button
        frame.input = CreateFrame("Button", nil, frame)
        frame.input:SetSize(40, 18)
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input:SetBackdrop({
          bgFile = "Interface\\Buttons\\WHITE8X8",
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          tile = false, tileSize = 1, edgeSize = 1,
          insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        frame.input:SetBackdropColor(0.15, 0.15, 0.15, 1)
        frame.input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

        frame.input.text = frame.input:CreateFontString(nil, "OVERLAY")
        frame.input.text:SetFont(fontPath, fontSize, "OUTLINE")
        frame.input.text:SetPoint("CENTER", 0, 0)
        frame.input.text:SetText("OK")
        frame.input.text:SetTextColor(0.8, 0.8, 0.8, 1)

        frame.input:SetScript("OnClick", data.func)
        frame.input:SetScript("OnEnter", function()
          this:SetBackdropColor(0.25, 0.25, 0.25, 1)
        end)
        frame.input:SetScript("OnLeave", function()
          this:SetBackdropColor(0.15, 0.15, 0.15, 1)
        end)

        yOffset = yOffset + rowHeight
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end

      elseif data.type == "dropdown" then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Dropdown
        local items = {}
        if type(data.values) == "table" then
          for _, v in ipairs(data.values) do
            table.insert(items, { value = v, label = v == "" and "(None)" or v })
          end
        end

        frame.input = CreateStyledDropdown(frame, 120, {
          items = items,
          selectedValue = pfQuest_config[data.config] or data.default,
          onSelect = function(value)
            pfQuest_config[data.config] = value
            if data.config == "trackerfontstyle" then
              if _G.RefreshTrackerFonts then _G.RefreshTrackerFonts() end
            end
            pfQuest:ResetAll()
          end,
          fontSize = fontSize,
        })
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input.config = data.config

        yOffset = yOffset + rowHeight + 4  -- Extra padding for dropdowns
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end

      elseif data.type == "fontdropdown" then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Font dropdown
        frame.input = CreateFontDropdown(frame, 120, pfQuest_config[data.config] or data.default, function(value)
          pfQuest_config[data.config] = value
          if data.config == "trackerfont" then
            if _G.RefreshTrackerFonts then _G.RefreshTrackerFonts() end
          elseif data.config == "configPanelFont" then
            CreateConfigPanel()
            CreateConfigEntries()
          end
          pfQuest:ResetAll()
        end, fontSize)
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input.config = data.config

        yOffset = yOffset + rowHeight + 4  -- Extra padding for dropdowns
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end

      elseif data.type == "fontoutlinedropdown" then
        frame:SetPoint("TOPLEFT", pfQuestConfig.scrollChild, "TOPLEFT", 5, -yOffset)

        -- Caption
        frame.caption = frame:CreateFontString(nil, "OVERLAY")
        frame.caption:SetFont(fontPath, fontSize, "OUTLINE")
        frame.caption:SetPoint("LEFT", 5, 0)
        frame.caption:SetTextColor(0.9, 0.9, 0.9, 1)
        frame.caption:SetText(data.text)

        -- Font outline dropdown (button is compact, menu expands to fit all options)
        frame.input = CreateFontOutlineDropdown(frame, 110, pfQuest_config[data.config] or data.default, function(value)
          pfQuest_config[data.config] = value
          if data.config == "trackerfontstyle" then
            if _G.RefreshTrackerFonts then _G.RefreshTrackerFonts() end
          end
          pfQuest:ResetAll()
        end, fontSize)
        frame.input:SetPoint("RIGHT", -5, 0)
        frame.input.config = data.config

        yOffset = yOffset + rowHeight + 4  -- Extra padding for dropdowns
        if blockFrames[currentBlock] then
          table.insert(blockFrames[currentBlock].items, frame)
        end
      end
    end
  end

  -- Set scroll child height
  pfQuestConfig.scrollChild:SetHeight(yOffset + 10)

  -- Update scrollbar thumb size based on content
  if pfQuestConfig.scrollBar and pfQuestConfig.scrollThumb then
    local contentHeight = yOffset + 10
    local viewHeight = pfQuestConfig.scrollFrame:GetHeight()
    local barHeight = pfQuestConfig.scrollBar:GetHeight()

    if contentHeight > viewHeight then
      -- Calculate thumb size proportional to visible area
      local thumbHeight = math.max(20, (viewHeight / contentHeight) * barHeight)
      pfQuestConfig.scrollThumb:SetHeight(thumbHeight)
      pfQuestConfig.scrollBar:Show()
    else
      -- No scrolling needed, hide scrollbar
      pfQuestConfig.scrollBar:Hide()
    end

    -- Reset thumb position to top
    pfQuestConfig.scrollThumb:ClearAllPoints()
    pfQuestConfig.scrollThumb:SetPoint("TOP", pfQuestConfig.scrollBar, "TOP", 0, 0)
    pfQuestConfig.scrollFrame:SetVerticalScroll(0)
  end
end

-- ============================================================================
-- Load/Update Config
-- ============================================================================
function pfQuestConfig:LoadConfig()
  if not pfQuest_config then pfQuest_config = {} end
  for _, data in pairs(pfQuest_defconfig) do
    if data.config and pfQuest_config[data.config] == nil then
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

function pfQuestConfig:UpdateConfigEntries()
  for _, data in pairs(pfQuest_defconfig) do
    if data.type and data.config and configFrames[data.text] then
      local frame = configFrames[data.text]
      if data.type == "checkbox" and frame.input then
        frame.input:SetChecked(pfQuest_config[data.config] == "1")
      elseif data.type == "text" and frame.input then
        frame.input:SetText(pfQuest_config[data.config] or "")
      elseif (data.type == "dropdown" or data.type == "fontdropdown" or data.type == "fontoutlinedropdown") and frame.input then
        if frame.input.SetSelectedValue then
          frame.input:SetSelectedValue(pfQuest_config[data.config])
        end
      end
    end
  end
end

-- ============================================================================
-- Event Handlers
-- ============================================================================
pfQuestConfig:SetScript("OnEvent", function()
  if arg1 == "pfQuest" or arg1 == "pfQuest-tbc" or arg1 == "pfQuest-wotlk" or arg1 == "pfQuest-Zero" then
    pfQuestConfig:LoadConfig()
    pfQuestConfig:MigrateHistory()

    pfQuest_questcache = pfQuest_questcache or {}
    pfQuest_history = pfQuest_history or {}
    pfQuest_colors = pfQuest_colors or {}
    pfQuest_config = pfQuest_config or {}
    pfQuest_track = pfQuest_track or {}
    pfBrowser_fav = pfBrowser_fav or {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

    -- Clear quest history on new characters
    if UnitXP("player") == 0 and UnitLevel("player") == 1 then
      pfQuest_history = {}
    end

    if pfQuestIcon and pfQuest_config["minimapbutton"] == "0" then
      pfQuestIcon:Hide()
    end

    -- Create the panel structure
    CreateConfigPanel()
    CreateConfigEntries()
  end
end)

pfQuestConfig:SetScript("OnMouseDown", function()
  this:StartMoving()
end)

pfQuestConfig:SetScript("OnMouseUp", function()
  this:StopMovingOrSizing()
end)

pfQuestConfig:SetScript("OnShow", function()
  this:UpdateConfigEntries()
end)

table.insert(UISpecialFrames, "pfQuestConfig")

-- ============================================================================
-- Welcome/Init Popup Dialog
-- ============================================================================
do
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

  pfQuestInit = CreateFrame("Frame", "pfQuestInit", UIParent)
  pfQuestInit:Hide()
  pfQuestInit:SetWidth(400)
  pfQuestInit:SetHeight(270)
  pfQuestInit:SetMovable(true)
  pfQuestInit:EnableMouse(true)
  pfQuestInit:SetPoint("CENTER", 0, 0)
  pfQuestInit:RegisterEvent("PLAYER_ENTERING_WORLD")

  pfQuestInit:SetScript("OnMouseDown", function() this:StartMoving() end)
  pfQuestInit:SetScript("OnMouseUp", function() this:StopMovingOrSizing() end)

  pfQuestInit:SetScript("OnEvent", function()
    if pfQuest_config.welcome ~= "1" then
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
    desaturate(pfQuestInit[1].bg, true)
    desaturate(pfQuestInit[2].bg, true)
    desaturate(pfQuestInit[3].bg, true)
    desaturate(pfQuestInit[config_stage.mode].bg, false)
    pfQuestInit.checkbox:SetChecked(config_stage.arrow)
  end)

  pfUI.api.CreateBackdrop(pfQuestInit, nil, true, 0.85)

  pfQuestInit.title = pfQuestInit:CreateFontString("Status", "LOW", "GameFontWhite")
  pfQuestInit.title:SetPoint("TOP", pfQuestInit, "TOP", 0, -17)
  pfQuestInit.title:SetJustifyH("LEFT")
  pfQuestInit.title:SetText(L["Please select your preferred |cff33ffccpf|cffffffffQuest|r mode:"])

  local buttons = {
    { caption = L["Simple Markers"], texture = "\\img\\init\\simple", position = { "TOPLEFT", 10, -40 },
      tooltip = L["Only show cluster icons with summarized objective locations based on spawn points"] },
    { caption = L["Combined"], texture = "\\img\\init\\combined", position = { "TOP", 0, -40 },
      tooltip = L["Show cluster icons with summarized locations and also display all spawn points of each quest objective"] },
    { caption = L["Spawn Points"], texture = "\\img\\init\\spawns", position = { "TOPRIGHT", -10, -40 },
      tooltip = L["Display all spawn points of each quest objective and hide summarized cluster icons."] },
  }

  for i, button in pairs(buttons) do
    pfQuestInit[i] = CreateFrame("Button", "pfQuestInitButton" .. i, pfQuestInit)
    pfQuestInit[i]:SetWidth(120)
    pfQuestInit[i]:SetHeight(160)
    pfQuestInit[i]:SetPoint(unpack(button.position))
    pfQuestInit[i]:SetID(i)

    pfQuestInit[i].bg = pfQuestInit[i]:CreateTexture(nil, "NORMAL")
    pfQuestInit[i].bg:SetWidth(200)
    pfQuestInit[i].bg:SetHeight(200)
    pfQuestInit[i].bg:SetPoint("CENTER", 0, 0)
    pfQuestInit[i].bg:SetTexture(pfQuestConfig.path .. button.texture)

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

  pfQuestInit.save = CreateFrame("Button", nil, pfQuestInit)
  pfQuestInit.save:SetWidth(100)
  pfQuestInit.save:SetHeight(24)
  pfQuestInit.save:SetPoint("BOTTOMRIGHT", -10, 10)
  pfQuestInit.save.text = pfQuestInit.save:CreateFontString("Caption", "LOW", "GameFontWhite")
  pfQuestInit.save.text:SetAllPoints(pfQuestInit.save)
  pfQuestInit.save.text:SetText(L["Save & Close"])

  pfUI.api.SkinButton(pfQuestInit.save)

  pfQuestInit.save:SetScript("OnClick", function()
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

    pfQuest_config["welcome"] = "1"
    pfQuest:ResetAll()
    pfQuestInit:Hide()
  end)
end
