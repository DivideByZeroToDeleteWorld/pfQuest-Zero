-- Database Editor Panel
-- Allows viewing and editing database entries for units/objects

pfQDB = pfQDB or {}

-- Panel defaults
local PANEL_WIDTH = 500
local PANEL_HEIGHT = 550
local ROW_HEIGHT = 22
local FIELD_HEIGHT = 20

-- Colors
local COLOR_BG = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 }
local COLOR_BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
local COLOR_HEADER = { r = 0.2, g = 0.8, b = 0.6, a = 1 }
local COLOR_PFQUEST = { r = 0.2, g = 1, b = 0.8, a = 1 }
local COLOR_QUESTIE = { r = 1, g = 0.6, b = 0.2, a = 1 }
local COLOR_TEXT = { r = 0.9, g = 0.9, b = 0.9, a = 1 }
local COLOR_ERROR = { r = 1, g = 0.3, b = 0.3, a = 1 }
local COLOR_SUCCESS = { r = 0.3, g = 1, b = 0.3, a = 1 }
local COLOR_BUTTON = { r = 0.15, g = 0.15, b = 0.15, a = 1 }
local COLOR_BUTTON_HOVER = { r = 0.25, g = 0.25, b = 0.25, a = 1 }

-- Editor state
local currentDatabase = "pfquest"  -- "pfquest" or "questie"
local currentEntityType = "units"  -- "units" or "objects"
local currentEntityId = nil
local currentEntityData = nil  -- Working copy of entity data
local hasUnsavedChanges = false
local validationErrors = {}

-- Holiday list for filtering event-specific NPCs/objects
local HOLIDAYS = {
  { id = "none", name = "None (Always Show)" },
  { id = "lunar", name = "Lunar Festival" },
  { id = "love", name = "Love is in the Air" },
  { id = "noblegarden", name = "Noblegarden" },
  { id = "children", name = "Children's Week" },
  { id = "midsummer", name = "Midsummer Fire Festival" },
  { id = "brewfest", name = "Brewfest" },
  { id = "harvest", name = "Harvest Festival" },
  { id = "hallows", name = "Hallow's End" },
  { id = "pilgrims", name = "Pilgrim's Bounty" },
  { id = "winter", name = "Winter Veil" },
  { id = "darkmoon", name = "Darkmoon Faire" },
  { id = "fishing", name = "Stranglethorn Fishing Extravaganza" },
  { id = "pvp", name = "PvP Event (Call to Arms)" },
  { id = "aq", name = "Ahn'Qiraj War Effort" },
  { id = "scourge", name = "Scourge Invasion" },
  { id = "other", name = "Other Event" },
}
local currentHoliday = "none"

-- Initialize custom database storage (will be saved)
pfQuest_customDB = pfQuest_customDB or {
  units = {},
  objects = {},
}

-- Create the main panel
local panel = CreateFrame("Frame", "pfQDBEditorPanel", UIParent)
panel:SetWidth(PANEL_WIDTH)
panel:SetHeight(PANEL_HEIGHT)
panel:SetPoint("CENTER", 0, 0)
panel:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
panel:SetBackdropColor(COLOR_BG.r, COLOR_BG.g, COLOR_BG.b, COLOR_BG.a)
panel:SetBackdropBorderColor(COLOR_BORDER.r, COLOR_BORDER.g, COLOR_BORDER.b, COLOR_BORDER.a)
panel:SetFrameStrata("DIALOG")
panel:SetMovable(true)
panel:EnableMouse(true)
panel:SetClampedToScreen(true)
panel:Hide()

-- Title bar
local titleBar = CreateFrame("Frame", nil, panel)
titleBar:SetHeight(24)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function()
  panel:StartMoving()
end)
titleBar:SetScript("OnDragStop", function()
  panel:StopMovingOrSizing()
end)

-- Title text
local title = titleBar:CreateFontString(nil, "OVERLAY")
title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
title:SetPoint("LEFT", 10, 0)
title:SetText("|cff33ffccpfQuest|r Database Editor")
panel.title = title

-- Close button
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetWidth(20)
closeBtn:SetHeight(20)
closeBtn:SetPoint("RIGHT", -4, 0)
closeBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
closeBtn:SetBackdropColor(0.3, 0.1, 0.1, 1)
closeBtn:SetBackdropBorderColor(0.4, 0.2, 0.2, 1)

closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY")
closeBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
closeBtn.text:SetPoint("CENTER", 0, 0)
closeBtn.text:SetText("X")
closeBtn.text:SetTextColor(1, 0.3, 0.3, 1)

closeBtn:SetScript("OnClick", function()
  if hasUnsavedChanges then
    -- Show confirmation
    StaticPopupDialogs["PFQUEST_EDITOR_UNSAVED"] = {
      text = "You have unsaved changes. Close anyway?",
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        panel:Hide()
        hasUnsavedChanges = false
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
    }
    StaticPopup_Show("PFQUEST_EDITOR_UNSAVED")
  else
    panel:Hide()
  end
end)
closeBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.5, 0.1, 0.1, 1)
end)
closeBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.3, 0.1, 0.1, 1)
end)

-- Helper function to create styled buttons
local function CreateStyledButton(parent, width, height, text, r, g, b)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(width)
  btn:SetHeight(height)
  btn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  btn:SetBackdropColor(r or 0.15, g or 0.15, b or 0.15, 1)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  btn.text = btn:CreateFontString(nil, "OVERLAY")
  btn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  btn.text:SetPoint("CENTER", 0, 0)
  btn.text:SetText(text)

  btn:SetScript("OnEnter", function()
    this:SetBackdropColor((r or 0.15) + 0.1, (g or 0.15) + 0.1, (b or 0.15) + 0.1, 1)
  end)
  btn:SetScript("OnLeave", function()
    this:SetBackdropColor(r or 0.15, g or 0.15, b or 0.15, 1)
  end)

  return btn
end

-- Helper function to create edit boxes
local function CreateEditBox(parent, width)
  local edit = CreateFrame("EditBox", nil, parent)
  edit:SetWidth(width)
  edit:SetHeight(FIELD_HEIGHT)
  edit:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  edit:SetTextColor(0.9, 0.9, 0.9, 1)
  edit:SetJustifyH("LEFT")
  edit:SetTextInsets(5, 5, 2, 2)
  edit:SetAutoFocus(false)
  edit:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  edit:SetBackdropColor(0.1, 0.1, 0.1, 1)
  edit:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  edit:SetScript("OnEditFocusGained", function()
    this:SetBackdropBorderColor(0.2, 0.8, 0.6, 1)
  end)
  edit:SetScript("OnEditFocusLost", function()
    this:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  end)
  edit:SetScript("OnEscapePressed", function()
    this:ClearFocus()
  end)
  edit:SetScript("OnEnterPressed", function()
    this:ClearFocus()
  end)

  return edit
end

-- ============================================================================
-- Database Source Selection
-- ============================================================================
local dbFrame = CreateFrame("Frame", nil, panel)
dbFrame:SetHeight(28)
dbFrame:SetPoint("TOPLEFT", 10, -28)
dbFrame:SetPoint("TOPRIGHT", -10, -28)

local dbLabel = dbFrame:CreateFontString(nil, "OVERLAY")
dbLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
dbLabel:SetPoint("LEFT", 0, 0)
dbLabel:SetText("Database:")
dbLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local pfquestBtn = CreateStyledButton(dbFrame, 80, 20, "pfQuest")
pfquestBtn:SetPoint("LEFT", 65, 0)
pfquestBtn.selectedColor = { r = 0.1, g = 0.5, b = 0.45 }  -- Teal
pfquestBtn.selectedHover = { r = 0.15, g = 0.6, b = 0.55 }
pfquestBtn:SetScript("OnClick", function()
  currentDatabase = "pfquest"
  panel:UpdateDatabaseButtons()
  panel:LoadEntity()
end)
pfquestBtn:SetScript("OnEnter", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedHover.r, this.selectedHover.g, this.selectedHover.b, 1)
  else
    this:SetBackdropColor(0.25, 0.25, 0.25, 1)
  end
end)
pfquestBtn:SetScript("OnLeave", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedColor.r, this.selectedColor.g, this.selectedColor.b, 1)
  else
    this:SetBackdropColor(0.15, 0.15, 0.15, 1)
  end
end)

local questieBtn = CreateStyledButton(dbFrame, 80, 20, "Questie")
questieBtn:SetPoint("LEFT", 150, 0)
questieBtn.selectedColor = { r = 0.7, g = 0.35, b = 0.1 }  -- Orange
questieBtn.selectedHover = { r = 0.85, g = 0.45, b = 0.15 }
questieBtn:SetScript("OnClick", function()
  currentDatabase = "questie"
  panel:UpdateDatabaseButtons()
  panel:LoadEntity()
end)
questieBtn:SetScript("OnEnter", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedHover.r, this.selectedHover.g, this.selectedHover.b, 1)
  else
    this:SetBackdropColor(0.25, 0.25, 0.25, 1)
  end
end)
questieBtn:SetScript("OnLeave", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedColor.r, this.selectedColor.g, this.selectedColor.b, 1)
  else
    this:SetBackdropColor(0.15, 0.15, 0.15, 1)
  end
end)

panel.pfquestBtn = pfquestBtn
panel.questieBtn = questieBtn

-- ============================================================================
-- Entity Type Selection
-- ============================================================================
local typeFrame = CreateFrame("Frame", nil, panel)
typeFrame:SetHeight(28)
typeFrame:SetPoint("TOPLEFT", 10, -54)
typeFrame:SetPoint("TOPRIGHT", -10, -54)

local typeLabel = typeFrame:CreateFontString(nil, "OVERLAY")
typeLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
typeLabel:SetPoint("LEFT", 0, 0)
typeLabel:SetText("Type:")
typeLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local unitsBtn = CreateStyledButton(typeFrame, 80, 20, "Units")
unitsBtn:SetPoint("LEFT", 65, 0)
unitsBtn.selectedColor = { r = 0.2, g = 0.4, b = 0.6 }  -- Blue
unitsBtn.selectedHover = { r = 0.25, g = 0.5, b = 0.7 }
unitsBtn:SetScript("OnClick", function()
  currentEntityType = "units"
  panel:UpdateTypeButtons()
  panel:ClearEntity()
end)
unitsBtn:SetScript("OnEnter", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedHover.r, this.selectedHover.g, this.selectedHover.b, 1)
  else
    this:SetBackdropColor(0.25, 0.25, 0.25, 1)
  end
end)
unitsBtn:SetScript("OnLeave", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedColor.r, this.selectedColor.g, this.selectedColor.b, 1)
  else
    this:SetBackdropColor(0.15, 0.15, 0.15, 1)
  end
end)

local objectsBtn = CreateStyledButton(typeFrame, 80, 20, "Objects")
objectsBtn:SetPoint("LEFT", 150, 0)
objectsBtn.selectedColor = { r = 0.5, g = 0.3, b = 0.5 }  -- Purple
objectsBtn.selectedHover = { r = 0.6, g = 0.4, b = 0.6 }
objectsBtn:SetScript("OnClick", function()
  currentEntityType = "objects"
  panel:UpdateTypeButtons()
  panel:ClearEntity()
end)
objectsBtn:SetScript("OnEnter", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedHover.r, this.selectedHover.g, this.selectedHover.b, 1)
  else
    this:SetBackdropColor(0.25, 0.25, 0.25, 1)
  end
end)
objectsBtn:SetScript("OnLeave", function()
  if this.isSelected then
    this:SetBackdropColor(this.selectedColor.r, this.selectedColor.g, this.selectedColor.b, 1)
  else
    this:SetBackdropColor(0.15, 0.15, 0.15, 1)
  end
end)

panel.unitsBtn = unitsBtn
panel.objectsBtn = objectsBtn

-- ============================================================================
-- Search Section
-- ============================================================================
local searchFrame = CreateFrame("Frame", nil, panel)
searchFrame:SetHeight(28)
searchFrame:SetPoint("TOPLEFT", 10, -82)
searchFrame:SetPoint("TOPRIGHT", -10, -82)

local searchLabel = searchFrame:CreateFontString(nil, "OVERLAY")
searchLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchLabel:SetPoint("LEFT", 0, 0)
searchLabel:SetText("Search:")
searchLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local searchBox = CreateEditBox(searchFrame, 200)
searchBox:SetPoint("LEFT", 65, 0)
panel.searchBox = searchBox

local searchBtn = CreateStyledButton(searchFrame, 60, 20, "Find")
searchBtn:SetPoint("LEFT", 270, 0)
searchBtn:SetScript("OnClick", function()
  panel:SearchEntity()
end)

-- Target button - use current target's info
local targetBtn = CreateStyledButton(searchFrame, 80, 20, "Use Target")
targetBtn:SetPoint("LEFT", 335, 0)
targetBtn:SetScript("OnClick", function()
  panel:UseTargetInfo()
end)
targetBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
  GameTooltip:SetText("Use Target Info")
  GameTooltip:AddLine("Fills search with your current target's name", 0.7, 0.7, 0.7, 1)
  GameTooltip:Show()
end)
targetBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
  GameTooltip:Hide()
end)

searchBox:SetScript("OnEnterPressed", function()
  this:ClearFocus()
  panel:SearchEntity()
end)

-- ============================================================================
-- Entity Info Section (Name, ID, Level, Holiday)
-- ============================================================================
local infoFrame = CreateFrame("Frame", nil, panel)
infoFrame:SetHeight(80)
infoFrame:SetPoint("TOPLEFT", 10, -115)
infoFrame:SetPoint("TOPRIGHT", -10, -115)

-- Entity ID
local idLabel = infoFrame:CreateFontString(nil, "OVERLAY")
idLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
idLabel:SetPoint("TOPLEFT", 0, 0)
idLabel:SetText("ID:")
idLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local idBox = CreateEditBox(infoFrame, 80)
idBox:SetPoint("TOPLEFT", 65, 0)
idBox:SetScript("OnTextChanged", function()
  hasUnsavedChanges = true
  panel:UpdateSaveButton()
end)
panel.idBox = idBox

-- Entity Name
local nameLabel = infoFrame:CreateFontString(nil, "OVERLAY")
nameLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
nameLabel:SetPoint("TOPLEFT", 160, 0)
nameLabel:SetText("Name:")
nameLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local nameBox = CreateEditBox(infoFrame, 200)
nameBox:SetPoint("TOPLEFT", 200, 0)
nameBox:SetScript("OnTextChanged", function()
  hasUnsavedChanges = true
  panel:UpdateSaveButton()
end)
panel.nameBox = nameBox

-- Level
local levelLabel = infoFrame:CreateFontString(nil, "OVERLAY")
levelLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
levelLabel:SetPoint("TOPLEFT", 0, -25)
levelLabel:SetText("Level:")
levelLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local levelBox = CreateEditBox(infoFrame, 50)
levelBox:SetPoint("TOPLEFT", 65, -25)
levelBox:SetScript("OnTextChanged", function()
  hasUnsavedChanges = true
  panel:UpdateSaveButton()
end)
panel.levelBox = levelBox

-- Respawn Time
local respawnLabel = infoFrame:CreateFontString(nil, "OVERLAY")
respawnLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
respawnLabel:SetPoint("TOPLEFT", 130, -25)
respawnLabel:SetText("Respawn (sec):")
respawnLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local respawnBox = CreateEditBox(infoFrame, 60)
respawnBox:SetPoint("TOPLEFT", 220, -25)
respawnBox:SetScript("OnTextChanged", function()
  hasUnsavedChanges = true
  panel:UpdateSaveButton()
end)
panel.respawnBox = respawnBox

-- Holiday Binding (Row 3)
local holidayLabel = infoFrame:CreateFontString(nil, "OVERLAY")
holidayLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
holidayLabel:SetPoint("TOPLEFT", 0, -50)
holidayLabel:SetText("Holiday:")
holidayLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

-- Holiday dropdown button
local holidayDropdown = CreateFrame("Button", "pfQDBHolidayDropdown", infoFrame)
holidayDropdown:SetWidth(200)
holidayDropdown:SetHeight(FIELD_HEIGHT)
holidayDropdown:SetPoint("TOPLEFT", 65, -50)
holidayDropdown:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
holidayDropdown:SetBackdropColor(0.1, 0.1, 0.1, 1)
holidayDropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

holidayDropdown.text = holidayDropdown:CreateFontString(nil, "OVERLAY")
holidayDropdown.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
holidayDropdown.text:SetPoint("LEFT", 5, 0)
holidayDropdown.text:SetTextColor(0.9, 0.9, 0.9, 1)
holidayDropdown.text:SetText("None (Always Show)")

holidayDropdown.arrow = holidayDropdown:CreateFontString(nil, "OVERLAY")
holidayDropdown.arrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
holidayDropdown.arrow:SetPoint("RIGHT", -5, 0)
holidayDropdown.arrow:SetText("▼")
holidayDropdown.arrow:SetTextColor(0.6, 0.6, 0.6, 1)

-- Holiday dropdown menu frame
local holidayMenu = CreateFrame("Frame", "pfQDBHolidayMenu", holidayDropdown)
holidayMenu:SetWidth(200)
holidayMenu:SetHeight(#HOLIDAYS * 18 + 4)
holidayMenu:SetPoint("TOPLEFT", holidayDropdown, "BOTTOMLEFT", 0, -1)
holidayMenu:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
holidayMenu:SetBackdropColor(0.1, 0.1, 0.1, 0.98)
holidayMenu:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
holidayMenu:SetFrameStrata("TOOLTIP")
holidayMenu:Hide()

-- Create menu items
holidayMenu.items = {}
for i, holiday in ipairs(HOLIDAYS) do
  local item = CreateFrame("Button", nil, holidayMenu)
  item:SetWidth(196)
  item:SetHeight(18)
  item:SetPoint("TOPLEFT", 2, -((i - 1) * 18) - 2)

  item.text = item:CreateFontString(nil, "OVERLAY")
  item.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  item.text:SetPoint("LEFT", 5, 0)
  item.text:SetText(holiday.name)
  item.text:SetTextColor(0.85, 0.85, 0.85, 1)

  item.holidayId = holiday.id
  item.holidayName = holiday.name

  item:SetScript("OnEnter", function()
    this:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    this:SetBackdropColor(0.2, 0.5, 0.4, 1)
  end)
  item:SetScript("OnLeave", function()
    this:SetBackdrop(nil)
  end)
  item:SetScript("OnClick", function()
    currentHoliday = this.holidayId
    holidayDropdown.text:SetText(this.holidayName)
    holidayMenu:Hide()
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
  end)

  holidayMenu.items[i] = item
end

holidayDropdown:SetScript("OnClick", function()
  if holidayMenu:IsShown() then
    holidayMenu:Hide()
  else
    holidayMenu:Show()
  end
end)
holidayDropdown:SetScript("OnEnter", function()
  this:SetBackdropBorderColor(0.2, 0.8, 0.6, 1)
end)
holidayDropdown:SetScript("OnLeave", function()
  this:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end)

-- Close menu when clicking elsewhere
holidayMenu:SetScript("OnShow", function()
  this:SetFrameLevel(100)
end)

panel.holidayDropdown = holidayDropdown
panel.holidayMenu = holidayMenu

-- ============================================================================
-- Spawn Coordinates Section
-- ============================================================================
local coordsHeader = panel:CreateFontString(nil, "OVERLAY")
coordsHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
coordsHeader:SetPoint("TOPLEFT", 10, -180)
coordsHeader:SetText("Spawn Locations")
coordsHeader:SetTextColor(COLOR_HEADER.r, COLOR_HEADER.g, COLOR_HEADER.b, 1)

-- Column headers
local colHeaderFrame = CreateFrame("Frame", nil, panel)
colHeaderFrame:SetHeight(20)
colHeaderFrame:SetPoint("TOPLEFT", 10, -200)
colHeaderFrame:SetPoint("TOPRIGHT", -10, -200)

local colX = colHeaderFrame:CreateFontString(nil, "OVERLAY")
colX:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
colX:SetPoint("LEFT", 5, 0)
colX:SetText("X")
colX:SetTextColor(0.7, 0.7, 0.7, 1)

local colY = colHeaderFrame:CreateFontString(nil, "OVERLAY")
colY:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
colY:SetPoint("LEFT", 70, 0)
colY:SetText("Y")
colY:SetTextColor(0.7, 0.7, 0.7, 1)

local colZone = colHeaderFrame:CreateFontString(nil, "OVERLAY")
colZone:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
colZone:SetPoint("LEFT", 135, 0)
colZone:SetText("Zone ID")
colZone:SetTextColor(0.7, 0.7, 0.7, 1)

local colRespawn = colHeaderFrame:CreateFontString(nil, "OVERLAY")
colRespawn:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
colRespawn:SetPoint("LEFT", 210, 0)
colRespawn:SetText("Respawn")
colRespawn:SetTextColor(0.7, 0.7, 0.7, 1)

local colActions = colHeaderFrame:CreateFontString(nil, "OVERLAY")
colActions:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
colActions:SetPoint("LEFT", 280, 0)
colActions:SetText("Actions")
colActions:SetTextColor(0.7, 0.7, 0.7, 1)

-- Scroll frame for spawn coordinates
local scrollFrame = CreateFrame("ScrollFrame", "pfQDBEditorScrollFrame", panel)
scrollFrame:SetPoint("TOPLEFT", 10, -220)
scrollFrame:SetPoint("BOTTOMRIGHT", -18, 100)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(PANEL_WIDTH - 35)
scrollChild:SetHeight(1)
scrollFrame:SetScrollChild(scrollChild)

-- Scrollbar
local scrollBar = CreateFrame("Frame", nil, panel)
scrollBar:SetWidth(6)
scrollBar:SetPoint("TOPRIGHT", -8, -220)
scrollBar:SetPoint("BOTTOMRIGHT", -8, 100)
scrollBar:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
})
scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

local scrollThumb = CreateFrame("Frame", nil, scrollBar)
scrollThumb:SetWidth(6)
scrollThumb:SetHeight(40)
scrollThumb:SetPoint("TOP", 0, 0)
scrollThumb:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
})
scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
scrollThumb:EnableMouse(true)

-- Mouse wheel scrolling
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
  local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
  if maxScroll <= 0 then return end

  local current = scrollFrame:GetVerticalScroll()
  local newScroll = current - (arg1 * 30)
  newScroll = math.max(0, math.min(newScroll, maxScroll))
  scrollFrame:SetVerticalScroll(newScroll)

  local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
  if thumbRange > 0 then
    local thumbPos = (newScroll / maxScroll) * thumbRange
    scrollThumb:ClearAllPoints()
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
  end
end)

panel.scrollFrame = scrollFrame
panel.scrollChild = scrollChild
panel.scrollBar = scrollBar
panel.scrollThumb = scrollThumb
panel.spawnRows = {}

-- ============================================================================
-- Add Spawn Button
-- ============================================================================
local addSpawnBtn = CreateStyledButton(panel, 120, 24, "+ Add Spawn Point")
addSpawnBtn:SetPoint("BOTTOMLEFT", 10, 65)
addSpawnBtn:SetBackdropColor(0.1, 0.3, 0.1, 1)
addSpawnBtn:SetScript("OnClick", function()
  panel:AddSpawnRow()
end)
addSpawnBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.15, 0.4, 0.15, 1)
end)
addSpawnBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.1, 0.3, 0.1, 1)
end)

-- Use My Location button (adds a spawn at player location)
local useLocationBtn = CreateStyledButton(panel, 120, 24, "Add My Location")
useLocationBtn:SetPoint("LEFT", addSpawnBtn, "RIGHT", 10, 0)
useLocationBtn:SetBackdropColor(0.1, 0.2, 0.4, 1)
useLocationBtn:SetScript("OnClick", function()
  panel:AddSpawnAtPlayerLocation()
end)
useLocationBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.15, 0.3, 0.5, 1)
  GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
  GameTooltip:SetText("Add My Location")
  GameTooltip:AddLine("Creates a new spawn point at your current position", 0.7, 0.7, 0.7, 1)
  GameTooltip:Show()
end)
useLocationBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.1, 0.2, 0.4, 1)
  GameTooltip:Hide()
end)

-- ============================================================================
-- Status/Error Message
-- ============================================================================
local statusText = panel:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
statusText:SetPoint("BOTTOMLEFT", 10, 42)
statusText:SetPoint("BOTTOMRIGHT", -10, 42)
statusText:SetJustifyH("LEFT")
statusText:SetTextColor(0.7, 0.7, 0.7, 1)
statusText:SetText("")
panel.statusText = statusText

-- ============================================================================
-- Bottom Buttons (Cancel / Save)
-- ============================================================================
local cancelBtn = CreateStyledButton(panel, 100, 28, "Cancel")
cancelBtn:SetPoint("BOTTOMLEFT", 10, 10)
cancelBtn:SetBackdropColor(0.3, 0.15, 0.15, 1)
cancelBtn:SetScript("OnClick", function()
  if hasUnsavedChanges then
    StaticPopupDialogs["PFQUEST_EDITOR_CANCEL"] = {
      text = "Discard unsaved changes?",
      button1 = "Yes",
      button2 = "No",
      OnAccept = function()
        hasUnsavedChanges = false
        panel:LoadEntity()
      end,
      timeout = 0,
      whileDead = true,
      hideOnEscape = true,
    }
    StaticPopup_Show("PFQUEST_EDITOR_CANCEL")
  else
    panel:LoadEntity()
  end
end)
cancelBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.4, 0.2, 0.2, 1)
end)
cancelBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.3, 0.15, 0.15, 1)
end)

local saveBtn = CreateStyledButton(panel, 100, 28, "Save")
saveBtn:SetPoint("BOTTOMRIGHT", -10, 10)
saveBtn:SetBackdropColor(0.15, 0.3, 0.15, 1)
saveBtn:SetScript("OnClick", function()
  panel:SaveEntity()
end)
saveBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.2, 0.4, 0.2, 1)
end)
saveBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.3, 0.15, 1)
end)
panel.saveBtn = saveBtn

-- Show on Map button
local showMapBtn = CreateStyledButton(panel, 100, 28, "Show on Map")
showMapBtn:SetPoint("BOTTOMRIGHT", saveBtn, "BOTTOMLEFT", -10, 0)
showMapBtn:SetBackdropColor(0.15, 0.25, 0.35, 1)
showMapBtn:SetScript("OnClick", function()
  panel:ShowOnMap()
end)
showMapBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.2, 0.35, 0.45, 1)
end)
showMapBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.25, 0.35, 1)
end)

-- ============================================================================
-- Panel Functions
-- ============================================================================

function panel:UpdateDatabaseButtons()
  if currentDatabase == "pfquest" then
    self.pfquestBtn.isSelected = true
    self.pfquestBtn:SetBackdropColor(self.pfquestBtn.selectedColor.r, self.pfquestBtn.selectedColor.g, self.pfquestBtn.selectedColor.b, 1)
    self.pfquestBtn:SetBackdropBorderColor(0.2, 0.7, 0.6, 1)
    self.pfquestBtn.text:SetTextColor(1, 1, 1, 1)

    self.questieBtn.isSelected = false
    self.questieBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.questieBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.questieBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)
  else
    self.pfquestBtn.isSelected = false
    self.pfquestBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.pfquestBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.pfquestBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)

    self.questieBtn.isSelected = true
    self.questieBtn:SetBackdropColor(self.questieBtn.selectedColor.r, self.questieBtn.selectedColor.g, self.questieBtn.selectedColor.b, 1)
    self.questieBtn:SetBackdropBorderColor(0.9, 0.5, 0.2, 1)
    self.questieBtn.text:SetTextColor(1, 1, 1, 1)
  end
end

function panel:UpdateTypeButtons()
  if currentEntityType == "units" then
    self.unitsBtn.isSelected = true
    self.unitsBtn:SetBackdropColor(self.unitsBtn.selectedColor.r, self.unitsBtn.selectedColor.g, self.unitsBtn.selectedColor.b, 1)
    self.unitsBtn:SetBackdropBorderColor(0.3, 0.55, 0.8, 1)
    self.unitsBtn.text:SetTextColor(1, 1, 1, 1)

    self.objectsBtn.isSelected = false
    self.objectsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.objectsBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.objectsBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)
  else
    self.unitsBtn.isSelected = false
    self.unitsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.unitsBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.unitsBtn.text:SetTextColor(0.6, 0.6, 0.6, 1)

    self.objectsBtn.isSelected = true
    self.objectsBtn:SetBackdropColor(self.objectsBtn.selectedColor.r, self.objectsBtn.selectedColor.g, self.objectsBtn.selectedColor.b, 1)
    self.objectsBtn:SetBackdropBorderColor(0.7, 0.45, 0.7, 1)
    self.objectsBtn.text:SetTextColor(1, 1, 1, 1)
  end
end

function panel:UpdateSaveButton()
  if hasUnsavedChanges then
    self.saveBtn.text:SetText("Save *")
    self.saveBtn:SetBackdropColor(0.2, 0.5, 0.2, 1)
  else
    self.saveBtn.text:SetText("Save")
    self.saveBtn:SetBackdropColor(0.15, 0.3, 0.15, 1)
  end
end

function panel:SetStatus(text, isError)
  self.statusText:SetText(text)
  if isError then
    self.statusText:SetTextColor(COLOR_ERROR.r, COLOR_ERROR.g, COLOR_ERROR.b, 1)
  else
    self.statusText:SetTextColor(COLOR_SUCCESS.r, COLOR_SUCCESS.g, COLOR_SUCCESS.b, 1)
  end
end

function panel:ClearEntity()
  currentEntityId = nil
  currentEntityData = nil
  hasUnsavedChanges = false

  self.idBox:SetText("")
  self.nameBox:SetText("")
  self.levelBox:SetText("")
  self.respawnBox:SetText("")
  self.statusText:SetText("")

  -- Reset holiday dropdown
  currentHoliday = "none"
  self.holidayDropdown.text:SetText("None (Always Show)")
  self.holidayMenu:Hide()

  -- Clear spawn rows
  for _, row in ipairs(self.spawnRows) do
    row:Hide()
    row:SetParent(nil)
  end
  self.spawnRows = {}
  self.scrollChild:SetHeight(1)

  self:UpdateSaveButton()
end

function panel:SearchEntity()
  local searchText = self.searchBox:GetText()
  if not searchText or searchText == "" then
    self:SetStatus("Enter a name or ID to search", true)
    return
  end

  local entityId = nil
  local entityName = nil

  -- Check if it's a numeric ID
  local numericId = tonumber(searchText)
  if numericId then
    entityId = numericId
  else
    -- Search by name
    local db = currentDatabase == "pfquest" and pfDB or (pfQDB.questie and pfQDB.questie.wotlk)
    if db then
      local locTable = currentDatabase == "pfquest" and pfDB[currentEntityType]["loc"] or
                       (currentEntityType == "units" and pfQDB.questie.wotlk.units_loc or pfQDB.questie.wotlk.objects_loc)

      if locTable then
        local searchLower = strlower(searchText)
        for id, name in pairs(locTable) do
          if strfind(strlower(name), searchLower, 1, true) then
            entityId = id
            entityName = name
            break
          end
        end
      end
    end
  end

  if entityId then
    currentEntityId = entityId
    self:LoadEntity()
  else
    self:SetStatus("Entity not found: " .. searchText, true)
  end
end

function panel:LoadEntity()
  if not currentEntityId then
    self:ClearEntity()
    return
  end

  -- Clear previous data
  for _, row in ipairs(self.spawnRows) do
    row:Hide()
    row:SetParent(nil)
  end
  self.spawnRows = {}

  local entityId = currentEntityId
  local entityName = ""
  local entityData = nil
  local level = ""
  local respawn = ""
  local holiday = "none"

  -- First check custom database
  if pfQuest_customDB[currentEntityType] and pfQuest_customDB[currentEntityType][entityId] then
    local custom = pfQuest_customDB[currentEntityType][entityId]
    entityName = custom.name or ""
    entityData = custom.coords or {}
    level = custom.level or ""
    respawn = custom.respawn or ""
    holiday = custom.holiday or "none"
  elseif currentDatabase == "pfquest" then
    -- Load from pfQuest database
    if pfDB[currentEntityType] then
      entityName = pfDB[currentEntityType]["loc"] and pfDB[currentEntityType]["loc"][entityId] or ""
      entityData = pfDB[currentEntityType]["data"] and pfDB[currentEntityType]["data"][entityId] and
                   pfDB[currentEntityType]["data"][entityId]["coords"] or {}
    end
  else
    -- Load from Questie database
    if pfQDB.questie and pfQDB.questie.wotlk then
      local locTable = currentEntityType == "units" and pfQDB.questie.wotlk.units_loc or pfQDB.questie.wotlk.objects_loc
      local dataTable = currentEntityType == "units" and pfQDB.questie.wotlk.units or pfQDB.questie.wotlk.objects

      if locTable then
        entityName = locTable[entityId] or ""
      end

      if dataTable and dataTable[entityId] then
        -- Convert Questie format to our format
        entityData = {}
        local questieData = dataTable[entityId]
        -- Questie stores spawns in index 7 (for units) as {zoneId = {{x, y}, ...}}
        local spawns = questieData[7]
        if spawns and type(spawns) == "table" then
          for zoneId, coords in pairs(spawns) do
            if type(coords) == "table" then
              for _, coord in pairs(coords) do
                if type(coord) == "table" and coord[1] and coord[2] then
                  table.insert(entityData, { coord[1], coord[2], zoneId, 0 })
                end
              end
            end
          end
        end
      end
    end
  end

  -- Update UI
  self.idBox:SetText(tostring(entityId))
  self.nameBox:SetText(entityName)
  self.levelBox:SetText(tostring(level))
  self.respawnBox:SetText(tostring(respawn))

  -- Update holiday dropdown
  currentHoliday = holiday
  local holidayName = "None (Always Show)"
  for _, h in ipairs(HOLIDAYS) do
    if h.id == holiday then
      holidayName = h.name
      break
    end
  end
  self.holidayDropdown.text:SetText(holidayName)
  self.holidayMenu:Hide()

  -- Create spawn rows
  if entityData and type(entityData) == "table" then
    for i, coord in ipairs(entityData) do
      self:CreateSpawnRow(i, coord)
    end
  end

  -- Update scroll
  self.scrollChild:SetHeight(#self.spawnRows * ROW_HEIGHT + 10)
  self.scrollFrame:SetVerticalScroll(0)

  hasUnsavedChanges = false
  self:UpdateSaveButton()
  self:SetStatus("Loaded: " .. entityName .. " (ID: " .. entityId .. ")", false)
end

function panel:CreateSpawnRow(index, coord)
  local row = CreateFrame("Frame", nil, self.scrollChild)
  row:SetWidth(PANEL_WIDTH - 35)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))

  -- Alternate row background
  if index % 2 == 0 then
    row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    row:SetBackdropColor(0.12, 0.12, 0.12, 0.5)
  end

  -- X coordinate
  local xBox = CreateEditBox(row, 55)
  xBox:SetPoint("LEFT", 0, 0)
  xBox:SetText(coord and coord[1] and string.format("%.2f", coord[1]) or "")
  xBox:SetScript("OnTextChanged", function()
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
  end)
  row.xBox = xBox

  -- Y coordinate
  local yBox = CreateEditBox(row, 55)
  yBox:SetPoint("LEFT", 65, 0)
  yBox:SetText(coord and coord[2] and string.format("%.2f", coord[2]) or "")
  yBox:SetScript("OnTextChanged", function()
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
  end)
  row.yBox = yBox

  -- Zone ID
  local zoneBox = CreateEditBox(row, 55)
  zoneBox:SetPoint("LEFT", 130, 0)
  zoneBox:SetText(coord and coord[3] and tostring(coord[3]) or "")
  zoneBox:SetScript("OnTextChanged", function()
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
  end)
  row.zoneBox = zoneBox

  -- Respawn time
  local respawnBox = CreateEditBox(row, 50)
  respawnBox:SetPoint("LEFT", 195, 0)
  respawnBox:SetText(coord and coord[4] and tostring(coord[4]) or "0")
  respawnBox:SetScript("OnTextChanged", function()
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
  end)
  row.respawnBox = respawnBox

  -- Use location button (small icon)
  local locBtn = CreateFrame("Button", nil, row)
  locBtn:SetWidth(18)
  locBtn:SetHeight(18)
  locBtn:SetPoint("LEFT", 255, 0)
  locBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  locBtn:SetBackdropColor(0.1, 0.2, 0.4, 1)
  locBtn:SetBackdropBorderColor(0.2, 0.3, 0.5, 1)

  locBtn.text = locBtn:CreateFontString(nil, "OVERLAY")
  locBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  locBtn.text:SetPoint("CENTER", 0, 0)
  locBtn.text:SetText("@")
  locBtn.text:SetTextColor(0.5, 0.7, 1, 1)

  locBtn.row = row
  locBtn:SetScript("OnClick", function()
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then
      panel:SetStatus("Cannot get position (indoors or invalid zone)", true)
      return
    end

    local zoneId = pfMap:GetMapIDByName(GetRealZoneText()) or 0

    this.row.xBox:SetText(string.format("%.2f", x * 100))
    this.row.yBox:SetText(string.format("%.2f", y * 100))
    this.row.zoneBox:SetText(tostring(zoneId))
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
    panel:SetStatus("Updated with your current location", false)
  end)
  locBtn:SetScript("OnEnter", function()
    this:SetBackdropColor(0.15, 0.3, 0.5, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Use My Location")
    GameTooltip:AddLine("Set this spawn to your current position", 0.7, 0.7, 0.7, 1)
    GameTooltip:Show()
  end)
  locBtn:SetScript("OnLeave", function()
    this:SetBackdropColor(0.1, 0.2, 0.4, 1)
    GameTooltip:Hide()
  end)
  row.locBtn = locBtn

  -- Use target location button
  local targetLocBtn = CreateFrame("Button", nil, row)
  targetLocBtn:SetWidth(18)
  targetLocBtn:SetHeight(18)
  targetLocBtn:SetPoint("LEFT", 277, 0)
  targetLocBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  targetLocBtn:SetBackdropColor(0.3, 0.2, 0.1, 1)
  targetLocBtn:SetBackdropBorderColor(0.5, 0.35, 0.2, 1)

  targetLocBtn.text = targetLocBtn:CreateFontString(nil, "OVERLAY")
  targetLocBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  targetLocBtn.text:SetPoint("CENTER", 0, 0)
  targetLocBtn.text:SetText("T")
  targetLocBtn.text:SetTextColor(1, 0.7, 0.3, 1)

  targetLocBtn.row = row
  targetLocBtn:SetScript("OnClick", function()
    if not UnitExists("target") then
      panel:SetStatus("No target selected - select a mob/object first", true)
      return
    end

    local targetName = UnitName("target")
    local x, y = GetPlayerMapPosition("player")
    if x == 0 and y == 0 then
      panel:SetStatus("Cannot get position (indoors or invalid zone)", true)
      return
    end

    local zoneId = pfMap:GetMapIDByName(GetRealZoneText()) or 0

    this.row.xBox:SetText(string.format("%.2f", x * 100))
    this.row.yBox:SetText(string.format("%.2f", y * 100))
    this.row.zoneBox:SetText(tostring(zoneId))
    hasUnsavedChanges = true
    panel:UpdateSaveButton()
    panel:SetStatus("Recorded location for target: " .. (targetName or "Unknown"), false)
  end)
  targetLocBtn:SetScript("OnEnter", function()
    this:SetBackdropColor(0.4, 0.3, 0.15, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Use Target Location")
    GameTooltip:AddLine("Set spawn to your position (stand next to target)", 0.7, 0.7, 0.7, 1)
    GameTooltip:AddLine("Requires a target to be selected", 0.5, 0.5, 0.5, 1)
    GameTooltip:Show()
  end)
  targetLocBtn:SetScript("OnLeave", function()
    this:SetBackdropColor(0.3, 0.2, 0.1, 1)
    GameTooltip:Hide()
  end)
  row.targetLocBtn = targetLocBtn

  -- Delete button
  local delBtn = CreateFrame("Button", nil, row)
  delBtn:SetWidth(18)
  delBtn:SetHeight(18)
  delBtn:SetPoint("LEFT", 299, 0)
  delBtn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  delBtn:SetBackdropColor(0.4, 0.1, 0.1, 1)
  delBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

  delBtn.text = delBtn:CreateFontString(nil, "OVERLAY")
  delBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  delBtn.text:SetPoint("CENTER", 0, 0)
  delBtn.text:SetText("X")
  delBtn.text:SetTextColor(1, 0.3, 0.3, 1)

  delBtn.rowIndex = index
  delBtn:SetScript("OnClick", function()
    panel:DeleteSpawnRow(this.rowIndex)
  end)
  delBtn:SetScript("OnEnter", function()
    this:SetBackdropColor(0.5, 0.15, 0.15, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Delete Spawn Point")
    GameTooltip:Show()
  end)
  delBtn:SetScript("OnLeave", function()
    this:SetBackdropColor(0.4, 0.1, 0.1, 1)
    GameTooltip:Hide()
  end)
  row.delBtn = delBtn

  row.index = index
  table.insert(self.spawnRows, row)

  return row
end

function panel:AddSpawnRow()
  local newIndex = #self.spawnRows + 1
  self:CreateSpawnRow(newIndex, { 0, 0, 0, 0 })
  self.scrollChild:SetHeight(#self.spawnRows * ROW_HEIGHT + 10)
  hasUnsavedChanges = true
  self:UpdateSaveButton()
end

function panel:AddSpawnAtPlayerLocation()
  -- Ensure map is set to current zone
  if not WorldMapFrame:IsShown() then
    SetMapToCurrentZone()
  end

  local x, y = GetPlayerMapPosition("player")
  if x == 0 and y == 0 then
    self:SetStatus("Cannot get position (indoors or invalid zone)", true)
    return
  end

  local zoneId = pfMap:GetMapIDByName(GetRealZoneText()) or 0
  local newIndex = #self.spawnRows + 1

  self:CreateSpawnRow(newIndex, { x * 100, y * 100, zoneId, 0 })
  self.scrollChild:SetHeight(#self.spawnRows * ROW_HEIGHT + 10)
  hasUnsavedChanges = true
  self:UpdateSaveButton()
  self:SetStatus("Added spawn at your current location", false)
end

function panel:DeleteSpawnRow(index)
  -- Remove the row and rebuild
  local newSpawnRows = {}
  for i, row in ipairs(self.spawnRows) do
    if i ~= index then
      table.insert(newSpawnRows, row)
    else
      row:Hide()
      row:SetParent(nil)
    end
  end

  -- Reposition remaining rows
  for i, row in ipairs(newSpawnRows) do
    row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
    row.index = i
    row.delBtn.rowIndex = i

    -- Update background
    if i % 2 == 0 then
      row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
      row:SetBackdropColor(0.12, 0.12, 0.12, 0.5)
    else
      row:SetBackdrop(nil)
    end
  end

  self.spawnRows = newSpawnRows
  self.scrollChild:SetHeight(#self.spawnRows * ROW_HEIGHT + 10)
  hasUnsavedChanges = true
  self:UpdateSaveButton()
end

function panel:UseTargetInfo()
  if not UnitExists("target") then
    self:SetStatus("No target selected", true)
    return
  end

  local targetName = UnitName("target")
  local targetLevel = UnitLevel("target")

  if targetName then
    self.searchBox:SetText(targetName)

    -- If we have an entity loaded, update the name
    if currentEntityId then
      self.nameBox:SetText(targetName)
      if targetLevel and targetLevel > 0 then
        self.levelBox:SetText(tostring(targetLevel))
      end
      hasUnsavedChanges = true
      self:UpdateSaveButton()
    end

    self:SetStatus("Using target: " .. targetName .. " (Level " .. (targetLevel or "?") .. ")", false)
  end
end

function panel:ValidateEntity()
  validationErrors = {}

  local entityId = tonumber(self.idBox:GetText())
  local entityName = self.nameBox:GetText()

  -- Required fields
  if not entityId or entityId <= 0 then
    table.insert(validationErrors, "ID must be a positive number")
  end

  if not entityName or entityName == "" then
    table.insert(validationErrors, "Name is required")
  end

  -- Validate spawn coordinates
  for i, row in ipairs(self.spawnRows) do
    local x = tonumber(row.xBox:GetText())
    local y = tonumber(row.yBox:GetText())
    local zone = tonumber(row.zoneBox:GetText())

    if not x or x < 0 or x > 100 then
      table.insert(validationErrors, "Spawn #" .. i .. ": X must be 0-100")
    end
    if not y or y < 0 or y > 100 then
      table.insert(validationErrors, "Spawn #" .. i .. ": Y must be 0-100")
    end
    if not zone or zone < 0 then
      table.insert(validationErrors, "Spawn #" .. i .. ": Zone ID must be a positive number")
    end
  end

  return #validationErrors == 0
end

function panel:SaveEntity()
  if not self:ValidateEntity() then
    local errorMsg = "Validation errors:\n" .. table.concat(validationErrors, "\n")
    self:SetStatus(validationErrors[1], true)
    return
  end

  local entityId = tonumber(self.idBox:GetText())
  local entityName = self.nameBox:GetText()
  local level = tonumber(self.levelBox:GetText()) or 0
  local respawn = tonumber(self.respawnBox:GetText()) or 0

  -- Collect spawn coordinates
  local coords = {}
  for _, row in ipairs(self.spawnRows) do
    local x = tonumber(row.xBox:GetText()) or 0
    local y = tonumber(row.yBox:GetText()) or 0
    local zone = tonumber(row.zoneBox:GetText()) or 0
    local spawnRespawn = tonumber(row.respawnBox:GetText()) or 0

    table.insert(coords, { x, y, zone, spawnRespawn })
  end

  -- Save to custom database
  pfQuest_customDB[currentEntityType] = pfQuest_customDB[currentEntityType] or {}
  pfQuest_customDB[currentEntityType][entityId] = {
    name = entityName,
    level = level,
    respawn = respawn,
    holiday = currentHoliday,  -- Holiday binding for event-specific NPCs/objects
    coords = coords,
    source = currentDatabase,  -- Track which database this was edited from
    modified = time(),
  }

  hasUnsavedChanges = false
  self:UpdateSaveButton()
  self:SetStatus("Saved: " .. entityName .. " (ID: " .. entityId .. ") with " .. #coords .. " spawn(s)", false)

  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest Editor|r: Saved " .. currentEntityType:sub(1, -2) .. " '" .. entityName .. "' with " .. #coords .. " spawn point(s)")
end

function panel:ShowOnMap()
  if not currentEntityId then
    self:SetStatus("No entity loaded", true)
    return
  end

  -- Find the first spawn with a valid zone
  for _, row in ipairs(self.spawnRows) do
    local zone = tonumber(row.zoneBox:GetText())
    if zone and zone > 0 then
      pfMap:ShowMapID(zone)
      self:SetStatus("Showing zone: " .. (pfMap:GetMapNameByID(zone) or zone), false)
      return
    end
  end

  self:SetStatus("No valid zone found in spawns", true)
end

function panel:Refresh()
  self:UpdateDatabaseButtons()
  self:UpdateTypeButtons()
  self:UpdateSaveButton()

  if currentEntityId then
    self:LoadEntity()
  else
    self:ClearEntity()
  end
end

-- ============================================================================
-- Public API
-- ============================================================================

function pfQDB:ShowEditorPanel(entityId, entityType, database)
  if entityId then
    currentEntityId = entityId
  end
  if entityType then
    currentEntityType = entityType
  end
  if database then
    currentDatabase = database
  end

  panel:Refresh()
  panel:Show()
end

function pfQDB:HideEditorPanel()
  panel:Hide()
end

function pfQDB:ToggleEditorPanel()
  if panel:IsShown() then
    panel:Hide()
  else
    panel:Refresh()
    panel:Show()
  end
end

-- Get custom database entry if it exists (for use by other modules)
function pfQDB:GetCustomEntry(entityType, entityId)
  if pfQuest_customDB[entityType] and pfQuest_customDB[entityType][entityId] then
    return pfQuest_customDB[entityType][entityId]
  end
  return nil
end

-- ============================================================================
-- Holiday UI Support (core functions are in qdb/init.lua)
-- ============================================================================

-- Get all holiday-bound entities (for debugging/info)
function pfQDB:GetHolidayBoundEntities()
  local result = {
    units = {},
    objects = {}
  }

  for entityType, entities in pairs(pfQuest_customDB) do
    if type(entities) == "table" then
      for entityId, data in pairs(entities) do
        if data.holiday and data.holiday ~= "none" then
          result[entityType] = result[entityType] or {}
          table.insert(result[entityType], {
            id = entityId,
            name = data.name,
            holiday = data.holiday
          })
        end
      end
    end
  end

  return result
end

-- ============================================================================
-- Register UI and Slash Commands
-- ============================================================================

tinsert(UISpecialFrames, "pfQDBEditorPanel")

SLASH_PFQDBEDIT1 = "/pfqedit"
SLASH_PFQDBEDIT2 = "/pfquest-edit"
SlashCmdList["PFQDBEDIT"] = function(msg)
  if msg and msg ~= "" then
    -- Parse arguments: /pfqedit [type] [id]
    local args = {}
    for word in string.gmatch(msg, "%S+") do
      table.insert(args, word)
    end

    if args[1] == "units" or args[1] == "unit" then
      currentEntityType = "units"
    elseif args[1] == "objects" or args[1] == "object" then
      currentEntityType = "objects"
    end

    if args[2] then
      local id = tonumber(args[2])
      if id then
        currentEntityId = id
      end
    end
  end

  pfQDB:ToggleEditorPanel()
end

-- Holiday management slash command
SLASH_PFQHOLIDAY1 = "/pfholiday"
SlashCmdList["PFQHOLIDAY"] = function(msg)
  if not msg or msg == "" or msg == "help" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest Holiday|r: Usage:")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday - Show current holidays")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday list - List all holidays")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday set <id> - Set active holiday (manual override)")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday auto - Auto-detect holidays from calendar")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday detect - Force re-detection from calendar")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday bound - Show holiday-bound entities")
    DEFAULT_CHAT_FRAME:AddMessage("  /pfholiday test <type> <id> - Test if entity would be shown")
    return
  end

  local args = {}
  for word in string.gmatch(msg, "%S+") do
    table.insert(args, word)
  end

  local cmd = strlower(args[1] or "")

  if cmd == "list" then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccAvailable holidays:|r")
    for _, h in ipairs(HOLIDAYS) do
      DEFAULT_CHAT_FRAME:AddMessage("  " .. h.id .. " - " .. h.name)
    end
  elseif cmd == "set" then
    local holidayId = args[2]
    if holidayId then
      -- Validate holiday ID
      local valid = false
      for _, h in ipairs(HOLIDAYS) do
        if h.id == holidayId then
          valid = true
          break
        end
      end
      if valid then
        pfQDB:SetActiveHoliday(holidayId)
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Unknown holiday '" .. holidayId .. "'. Use /pfholiday list")
      end
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Usage: /pfholiday set <holiday_id>")
    end
  elseif cmd == "auto" then
    pfQuest_config = pfQuest_config or {}
    pfQuest_config.activeHoliday = "auto"
    pfQDB.detectedHolidays = nil  -- Reset to force re-detection
    pfQDB:DetectCurrentHolidays()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Holiday detection set to auto.")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Active Holidays: " .. pfQDB:GetActiveHolidaysString())
  elseif cmd == "detect" then
    -- Force re-detection without changing override setting
    pfQDB.detectedHolidays = nil
    pfQDB:DetectCurrentHolidays()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Re-detected holidays from calendar.")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Detected: " .. pfQDB:GetActiveHolidaysString())

    -- Show override status
    if pfQuest_config and pfQuest_config.activeHoliday and pfQuest_config.activeHoliday ~= "auto" then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Note: Manual override is active (" .. pfQuest_config.activeHoliday .. ")")
    end
  elseif cmd == "bound" then
    local bound = pfQDB:GetHolidayBoundEntities()
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccHoliday-bound entities:|r")
    local total = 0
    for entityType, entities in pairs(bound) do
      if #entities > 0 then
        DEFAULT_CHAT_FRAME:AddMessage("  " .. entityType .. ":")
        for _, e in ipairs(entities) do
          DEFAULT_CHAT_FRAME:AddMessage("    [" .. e.id .. "] " .. e.name .. " - " .. e.holiday)
          total = total + 1
        end
      end
    end
    if total == 0 then
      DEFAULT_CHAT_FRAME:AddMessage("  (none)")
    end
  elseif cmd == "test" then
    -- Test if a specific entity would be shown
    local entityType = args[2]
    local entityId = tonumber(args[3])
    if not entityType or not entityId then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Usage: /pfholiday test <units|objects> <id>")
      return
    end

    -- Normalize entity type
    if entityType == "unit" then entityType = "units" end
    if entityType == "object" then entityType = "objects" end

    -- Get custom data
    local custom = pfQuest_customDB and pfQuest_customDB[entityType] and pfQuest_customDB[entityType][entityId]
    if not custom then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: No custom data for " .. entityType .. " [" .. entityId .. "]")
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Result: |cff00ff00SHOW|r (no holiday binding)")
      return
    end

    local holiday = custom.holiday or "none"
    local holidayName = pfQDB.HOLIDAY_NAMES and pfQDB.HOLIDAY_NAMES[holiday] or holiday
    local shouldShow = pfQDB:ShouldShowEntity(entityType, entityId)

    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Testing " .. entityType .. " [" .. entityId .. "] - " .. (custom.name or "Unknown"))
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Bound to holiday: " .. holidayName .. " (" .. holiday .. ")")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Active holidays: " .. pfQDB:GetActiveHolidaysString())
    if shouldShow then
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Result: |cff00ff00SHOW|r")
    else
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Result: |cffff0000HIDE|r")
    end
  else
    -- Show current holidays (supports multiple)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Active Holidays: " .. pfQDB:GetActiveHolidaysString())

    -- Also show raw IDs for debugging
    local holidays = pfQDB:GetActiveHolidays()
    if holidays and table.getn(holidays) > 0 then
      local ids = table.concat(holidays, ", ")
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Holiday IDs: " .. ids)
    end
  end
end
