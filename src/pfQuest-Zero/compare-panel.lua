-- Database Compare Panel
-- Allows side-by-side comparison of pfQuest and Questie databases

pfQDB = pfQDB or {}

-- Panel defaults
local PANEL_WIDTH = 550
local PANEL_HEIGHT = 450
local ROW_HEIGHT = 18

-- Colors
local COLOR_BG = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 }
local COLOR_BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
local COLOR_HEADER = { r = 0.2, g = 0.8, b = 0.6, a = 1 }
local COLOR_PFQUEST = { r = 0.2, g = 1, b = 0.8, a = 1 }
local COLOR_QUESTIE = { r = 1, g = 0.6, b = 0.2, a = 1 }
local COLOR_TEXT = { r = 0.9, g = 0.9, b = 0.9, a = 1 }
local COLOR_DIMMED = { r = 0.5, g = 0.5, b = 0.5, a = 1 }

-- Current compare state
local currentMode = "entity"  -- "entity" or "zone"
local currentEntityId = nil
local currentEntityType = nil  -- "units" or "objects"
local currentZoneId = nil

-- Create the main panel
local panel = CreateFrame("Frame", "pfQDBComparePanel", UIParent)
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
title:SetText("|cff33ffccpfQuest|r Database Compare")
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
  panel:Hide()
end)
closeBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.5, 0.1, 0.1, 1)
end)
closeBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.3, 0.1, 0.1, 1)
end)

-- Mode toggle buttons (Entity / Zone)
local modeFrame = CreateFrame("Frame", nil, panel)
modeFrame:SetHeight(28)
modeFrame:SetPoint("TOPLEFT", 10, -28)
modeFrame:SetPoint("TOPRIGHT", -10, -28)

local modeLabel = modeFrame:CreateFontString(nil, "OVERLAY")
modeLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
modeLabel:SetPoint("LEFT", 0, 0)
modeLabel:SetText("Compare:")
modeLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local entityBtn = CreateFrame("Button", nil, modeFrame)
entityBtn:SetWidth(70)
entityBtn:SetHeight(20)
entityBtn:SetPoint("LEFT", 60, 0)
entityBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})

entityBtn.text = entityBtn:CreateFontString(nil, "OVERLAY")
entityBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
entityBtn.text:SetPoint("CENTER", 0, 0)
entityBtn.text:SetText("Entity")

entityBtn:SetScript("OnClick", function()
  currentMode = "entity"
  panel:UpdateModeButtons()
  panel:Refresh()
end)

local zoneBtn = CreateFrame("Button", nil, modeFrame)
zoneBtn:SetWidth(70)
zoneBtn:SetHeight(20)
zoneBtn:SetPoint("LEFT", 135, 0)
zoneBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})

zoneBtn.text = zoneBtn:CreateFontString(nil, "OVERLAY")
zoneBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
zoneBtn.text:SetPoint("CENTER", 0, 0)
zoneBtn.text:SetText("Zone")

zoneBtn:SetScript("OnClick", function()
  currentMode = "zone"
  panel:UpdateModeButtons()
  panel:Refresh()
end)

panel.entityBtn = entityBtn
panel.zoneBtn = zoneBtn

function panel:UpdateModeButtons()
  if currentMode == "entity" then
    self.entityBtn:SetBackdropColor(0.2, 0.6, 0.4, 1)
    self.entityBtn:SetBackdropBorderColor(0.3, 0.7, 0.5, 1)
    self.entityBtn.text:SetTextColor(1, 1, 1, 1)
    self.zoneBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.zoneBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.zoneBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)
  else
    self.zoneBtn:SetBackdropColor(0.2, 0.6, 0.4, 1)
    self.zoneBtn:SetBackdropBorderColor(0.3, 0.7, 0.5, 1)
    self.zoneBtn.text:SetTextColor(1, 1, 1, 1)
    self.entityBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.entityBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.entityBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)
  end
end

-- Search input for entity mode
local searchFrame = CreateFrame("Frame", nil, panel)
searchFrame:SetHeight(28)
searchFrame:SetPoint("TOPLEFT", 10, -58)
searchFrame:SetPoint("TOPRIGHT", -10, -58)

local searchLabel = searchFrame:CreateFontString(nil, "OVERLAY")
searchLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchLabel:SetPoint("LEFT", 0, 0)
searchLabel:SetText("Search:")
searchLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local searchInput = CreateFrame("EditBox", "pfQDBCompareSearchInput", searchFrame)
searchInput:SetWidth(200)
searchInput:SetHeight(20)
searchInput:SetPoint("LEFT", 60, 0)
searchInput:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchInput:SetAutoFocus(false)
searchInput:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
searchInput:SetBackdropColor(0.1, 0.1, 0.1, 1)
searchInput:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
searchInput:SetTextInsets(5, 5, 0, 0)
searchInput:SetScript("OnEscapePressed", function() this:ClearFocus() end)
searchInput:SetScript("OnEnterPressed", function()
  this:ClearFocus()
  panel:DoSearch()
end)

panel.searchInput = searchInput
panel.searchFrame = searchFrame

-- Type dropdown (Units/Objects)
local typeLabel = searchFrame:CreateFontString(nil, "OVERLAY")
typeLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
typeLabel:SetPoint("LEFT", 280, 0)
typeLabel:SetText("Type:")
typeLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local unitsBtn = CreateFrame("Button", nil, searchFrame)
unitsBtn:SetWidth(55)
unitsBtn:SetHeight(20)
unitsBtn:SetPoint("LEFT", 315, 0)
unitsBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
unitsBtn:SetBackdropColor(0.2, 0.6, 0.4, 1)
unitsBtn:SetBackdropBorderColor(0.3, 0.7, 0.5, 1)

unitsBtn.text = unitsBtn:CreateFontString(nil, "OVERLAY")
unitsBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
unitsBtn.text:SetPoint("CENTER", 0, 0)
unitsBtn.text:SetText("Units")
unitsBtn.text:SetTextColor(1, 1, 1, 1)

local objectsBtn = CreateFrame("Button", nil, searchFrame)
objectsBtn:SetWidth(55)
objectsBtn:SetHeight(20)
objectsBtn:SetPoint("LEFT", 375, 0)
objectsBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
objectsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
objectsBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

objectsBtn.text = objectsBtn:CreateFontString(nil, "OVERLAY")
objectsBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
objectsBtn.text:SetPoint("CENTER", 0, 0)
objectsBtn.text:SetText("Objects")
objectsBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)

currentEntityType = "units"

unitsBtn:SetScript("OnClick", function()
  currentEntityType = "units"
  panel:UpdateTypeButtons()
end)

objectsBtn:SetScript("OnClick", function()
  currentEntityType = "objects"
  panel:UpdateTypeButtons()
end)

panel.unitsBtn = unitsBtn
panel.objectsBtn = objectsBtn

function panel:UpdateTypeButtons()
  if currentEntityType == "units" then
    self.unitsBtn:SetBackdropColor(0.2, 0.6, 0.4, 1)
    self.unitsBtn:SetBackdropBorderColor(0.3, 0.7, 0.5, 1)
    self.unitsBtn.text:SetTextColor(1, 1, 1, 1)
    self.objectsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.objectsBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.objectsBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)
  else
    self.objectsBtn:SetBackdropColor(0.2, 0.6, 0.4, 1)
    self.objectsBtn:SetBackdropBorderColor(0.3, 0.7, 0.5, 1)
    self.objectsBtn.text:SetTextColor(1, 1, 1, 1)
    self.unitsBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    self.unitsBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    self.unitsBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)
  end
end

-- Zone dropdown for zone mode (simple button that opens zone selector)
local zoneFrame = CreateFrame("Frame", nil, panel)
zoneFrame:SetHeight(28)
zoneFrame:SetPoint("TOPLEFT", 10, -58)
zoneFrame:SetPoint("TOPRIGHT", -10, -58)
zoneFrame:Hide()

local zoneLabel = zoneFrame:CreateFontString(nil, "OVERLAY")
zoneLabel:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
zoneLabel:SetPoint("LEFT", 0, 0)
zoneLabel:SetText("Zone:")
zoneLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

local zoneDropdown = CreateFrame("Button", nil, zoneFrame)
zoneDropdown:SetWidth(280)
zoneDropdown:SetHeight(20)
zoneDropdown:SetPoint("LEFT", 50, 0)
zoneDropdown:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
zoneDropdown:SetBackdropColor(0.15, 0.15, 0.15, 1)
zoneDropdown:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

zoneDropdown.text = zoneDropdown:CreateFontString(nil, "OVERLAY")
zoneDropdown.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
zoneDropdown.text:SetPoint("LEFT", 5, 0)
zoneDropdown.text:SetText("Select Zone...")
zoneDropdown.text:SetTextColor(0.7, 0.7, 0.7, 1)

zoneDropdown.arrow = zoneDropdown:CreateFontString(nil, "OVERLAY")
zoneDropdown.arrow:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
zoneDropdown.arrow:SetPoint("RIGHT", -5, 0)
zoneDropdown.arrow:SetText("v")
zoneDropdown.arrow:SetTextColor(0.7, 0.7, 0.7, 1)

zoneDropdown:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
end)
zoneDropdown:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
end)
zoneDropdown:SetScript("OnClick", function()
  panel:ShowZoneDropdown()
end)

panel.zoneFrame = zoneFrame
panel.zoneDropdown = zoneDropdown

-- Content area (two columns)
local contentFrame = CreateFrame("Frame", nil, panel)
contentFrame:SetPoint("TOPLEFT", 10, -90)
contentFrame:SetPoint("BOTTOMRIGHT", -10, 45)
contentFrame:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
contentFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
contentFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 1)

panel.contentFrame = contentFrame

-- Column headers
local pfHeader = contentFrame:CreateFontString(nil, "OVERLAY")
pfHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
pfHeader:SetPoint("TOPLEFT", 10, -5)
pfHeader:SetText("pfQuest")
pfHeader:SetTextColor(COLOR_PFQUEST.r, COLOR_PFQUEST.g, COLOR_PFQUEST.b, 1)

local questieHeader = contentFrame:CreateFontString(nil, "OVERLAY")
questieHeader:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
questieHeader:SetPoint("TOPRIGHT", -10, -5)
questieHeader:SetJustifyH("RIGHT")
questieHeader:SetText("Questie")
questieHeader:SetTextColor(COLOR_QUESTIE.r, COLOR_QUESTIE.g, COLOR_QUESTIE.b, 1)

-- Divider line
local divider = contentFrame:CreateTexture(nil, "ARTWORK")
divider:SetTexture(1, 1, 1, 0.2)
divider:SetWidth(1)
divider:SetPoint("TOP", contentFrame, "TOP", 0, -25)
divider:SetPoint("BOTTOM", contentFrame, "BOTTOM", 0, 5)

-- Left column scroll (pfQuest)
local leftScroll = CreateFrame("ScrollFrame", "pfQDBCompareLeftScroll", contentFrame)
leftScroll:SetPoint("TOPLEFT", 5, -25)
leftScroll:SetPoint("BOTTOMLEFT", 5, 5)
leftScroll:SetWidth((PANEL_WIDTH - 40) / 2)

local leftChild = CreateFrame("Frame", nil, leftScroll)
leftChild:SetWidth((PANEL_WIDTH - 40) / 2)
leftChild:SetHeight(1)
leftScroll:SetScrollChild(leftChild)
leftScroll:EnableMouseWheel(true)
leftScroll:SetScript("OnMouseWheel", function()
  local maxScroll = leftChild:GetHeight() - leftScroll:GetHeight()
  if maxScroll <= 0 then return end
  local current = leftScroll:GetVerticalScroll()
  local newScroll = current - (arg1 * 20)
  newScroll = math.max(0, math.min(newScroll, maxScroll))
  leftScroll:SetVerticalScroll(newScroll)
end)

panel.leftScroll = leftScroll
panel.leftChild = leftChild

-- Right column scroll (Questie)
local rightScroll = CreateFrame("ScrollFrame", "pfQDBCompareRightScroll", contentFrame)
rightScroll:SetPoint("TOPRIGHT", -5, -25)
rightScroll:SetPoint("BOTTOMRIGHT", -5, 5)
rightScroll:SetWidth((PANEL_WIDTH - 40) / 2)

local rightChild = CreateFrame("Frame", nil, rightScroll)
rightChild:SetWidth((PANEL_WIDTH - 40) / 2)
rightChild:SetHeight(1)
rightScroll:SetScrollChild(rightChild)
rightScroll:EnableMouseWheel(true)
rightScroll:SetScript("OnMouseWheel", function()
  local maxScroll = rightChild:GetHeight() - rightScroll:GetHeight()
  if maxScroll <= 0 then return end
  local current = rightScroll:GetVerticalScroll()
  local newScroll = current - (arg1 * 20)
  newScroll = math.max(0, math.min(newScroll, maxScroll))
  rightScroll:SetVerticalScroll(newScroll)
end)

panel.rightScroll = rightScroll
panel.rightChild = rightChild

-- Store text elements for reuse
panel.leftTexts = {}
panel.rightTexts = {}

-- Bottom buttons
local showPfBtn = CreateFrame("Button", nil, panel)
showPfBtn:SetWidth(100)
showPfBtn:SetHeight(24)
showPfBtn:SetPoint("BOTTOMLEFT", 10, 10)
showPfBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
showPfBtn:SetBackdropColor(0.1, 0.4, 0.3, 1)
showPfBtn:SetBackdropBorderColor(0.15, 0.5, 0.4, 1)

showPfBtn.text = showPfBtn:CreateFontString(nil, "OVERLAY")
showPfBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
showPfBtn.text:SetPoint("CENTER", 0, 0)
showPfBtn.text:SetText("Show pfQuest")
showPfBtn.text:SetTextColor(COLOR_PFQUEST.r, COLOR_PFQUEST.g, COLOR_PFQUEST.b, 1)

showPfBtn:SetScript("OnClick", function()
  panel:ShowOnMap("pfquest")
end)
showPfBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.15, 0.5, 0.4, 1)
end)
showPfBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.1, 0.4, 0.3, 1)
end)

panel.showPfBtn = showPfBtn

local showQuestieBtn = CreateFrame("Button", nil, panel)
showQuestieBtn:SetWidth(100)
showQuestieBtn:SetHeight(24)
showQuestieBtn:SetPoint("BOTTOM", 0, 10)
showQuestieBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
showQuestieBtn:SetBackdropColor(0.4, 0.25, 0.1, 1)
showQuestieBtn:SetBackdropBorderColor(0.5, 0.3, 0.15, 1)

showQuestieBtn.text = showQuestieBtn:CreateFontString(nil, "OVERLAY")
showQuestieBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
showQuestieBtn.text:SetPoint("CENTER", 0, 0)
showQuestieBtn.text:SetText("Show Questie")
showQuestieBtn.text:SetTextColor(COLOR_QUESTIE.r, COLOR_QUESTIE.g, COLOR_QUESTIE.b, 1)

showQuestieBtn:SetScript("OnClick", function()
  panel:ShowOnMap("questie")
end)
showQuestieBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.5, 0.3, 0.15, 1)
end)
showQuestieBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.4, 0.25, 0.1, 1)
end)

panel.showQuestieBtn = showQuestieBtn

local showBothBtn = CreateFrame("Button", nil, panel)
showBothBtn:SetWidth(100)
showBothBtn:SetHeight(24)
showBothBtn:SetPoint("BOTTOMRIGHT", -10, 10)
showBothBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
showBothBtn:SetBackdropColor(0.3, 0.3, 0.15, 1)
showBothBtn:SetBackdropBorderColor(0.4, 0.4, 0.2, 1)

showBothBtn.text = showBothBtn:CreateFontString(nil, "OVERLAY")
showBothBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
showBothBtn.text:SetPoint("CENTER", 0, 0)
showBothBtn.text:SetText("Show Both")

showBothBtn:SetScript("OnClick", function()
  panel:ShowOnMap("both")
end)
showBothBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.4, 0.4, 0.2, 1)
end)
showBothBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.3, 0.3, 0.15, 1)
end)

panel.showBothBtn = showBothBtn

-- Search results dropdown
local searchResults = CreateFrame("Frame", "pfQDBCompareSearchResults", panel)
searchResults:SetWidth(200)
searchResults:SetHeight(150)
searchResults:SetPoint("TOPLEFT", searchInput, "BOTTOMLEFT", 0, -2)
searchResults:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
searchResults:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
searchResults:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
searchResults:SetFrameStrata("TOOLTIP")
searchResults:Hide()

searchResults.buttons = {}
panel.searchResults = searchResults

-- Zone dropdown list
local zoneList = CreateFrame("Frame", "pfQDBCompareZoneList", panel)
zoneList:SetWidth(280)
zoneList:SetHeight(200)
zoneList:SetPoint("TOPLEFT", zoneDropdown, "BOTTOMLEFT", 0, -2)
zoneList:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
zoneList:SetBackdropColor(0.1, 0.1, 0.1, 0.95)
zoneList:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
zoneList:SetFrameStrata("TOOLTIP")
zoneList:Hide()

local zoneListScroll = CreateFrame("ScrollFrame", "pfQDBCompareZoneListScroll", zoneList)
zoneListScroll:SetPoint("TOPLEFT", 2, -2)
zoneListScroll:SetPoint("BOTTOMRIGHT", -2, 2)

local zoneListChild = CreateFrame("Frame", nil, zoneListScroll)
zoneListChild:SetWidth(276)
zoneListChild:SetHeight(1)
zoneListScroll:SetScrollChild(zoneListChild)
zoneListScroll:EnableMouseWheel(true)
zoneListScroll:SetScript("OnMouseWheel", function()
  local maxScroll = zoneListChild:GetHeight() - zoneListScroll:GetHeight()
  if maxScroll <= 0 then return end
  local current = zoneListScroll:GetVerticalScroll()
  local newScroll = current - (arg1 * 30)
  newScroll = math.max(0, math.min(newScroll, maxScroll))
  zoneListScroll:SetVerticalScroll(newScroll)
end)

zoneList.scroll = zoneListScroll
zoneList.child = zoneListChild
zoneList.buttons = {}
panel.zoneList = zoneList

-- Helper function to create text row
local function CreateTextRow(parent, textArray, index)
  local row = parent:CreateFontString(nil, "OVERLAY")
  row:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  row:SetPoint("TOPLEFT", 5, -((index - 1) * ROW_HEIGHT))
  row:SetWidth(parent:GetWidth() - 10)
  row:SetJustifyH("LEFT")
  row:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)
  table.insert(textArray, row)
  return row
end

-- Clear content columns
function panel:ClearContent()
  for _, text in ipairs(self.leftTexts) do
    text:SetText("")
    text:Hide()
  end
  for _, text in ipairs(self.rightTexts) do
    text:SetText("")
    text:Hide()
  end
end

-- Show entity comparison
function panel:ShowEntityComparison(entityId, entityType)
  self:ClearContent()

  if not entityId or not entityType then
    return
  end

  -- Get pfQuest data
  local pfData = pfDB[entityType] and pfDB[entityType]["data"] and pfDB[entityType]["data"][entityId]
  local pfName = pfDB[entityType] and pfDB[entityType]["loc"] and pfDB[entityType]["loc"][entityId]

  -- Get Questie data
  local questieData, questieName
  if pfQDB and pfQDB.questieDataAvailable then
    if entityType == "units" then
      questieData = pfQDB:GetQuestieNPCData(entityId)
      questieName = pfQDB:GetQuestieNPCName(entityId)
    else
      questieData = pfQDB:GetQuestieObjectData(entityId)
      questieName = pfQDB:GetQuestieObjectName(entityId)
    end
  end

  -- Display name and ID
  self.title:SetText("|cff33ffccpfQuest|r Compare: " .. (pfName or questieName or "Unknown") .. " (ID: " .. entityId .. ")")

  local leftIdx = 1
  local rightIdx = 1

  -- pfQuest column
  if pfData then
    local row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
    row:SetText("|cff33ffccName:|r " .. (pfName or "Unknown"))
    row:Show()
    leftIdx = leftIdx + 1

    if entityType == "units" and pfData.lvl then
      row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
      row:SetText("|cff33ffccLevel:|r " .. pfData.lvl)
      row:Show()
      leftIdx = leftIdx + 1
    end

    if entityType == "units" and pfData.fac then
      row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
      row:SetText("|cff33ffccFaction:|r " .. pfData.fac)
      row:Show()
      leftIdx = leftIdx + 1
    end

    -- Count spawns by zone
    if pfData.coords then
      row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
      row:SetText("")
      row:Show()
      leftIdx = leftIdx + 1

      row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
      row:SetText("|cff33ffccSpawn Locations:|r")
      row:Show()
      leftIdx = leftIdx + 1

      local zoneSpawns = {}
      local totalSpawns = 0
      for _, coord in pairs(pfData.coords) do
        local zoneId = coord[3]
        zoneSpawns[zoneId] = (zoneSpawns[zoneId] or 0) + 1
        totalSpawns = totalSpawns + 1
      end

      for zoneId, count in pairs(zoneSpawns) do
        local zoneName = pfMap and pfMap:GetMapNameByID(zoneId) or ("Zone " .. zoneId)
        row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
        row:SetText("  " .. zoneName .. ": " .. count)
        row:Show()
        leftIdx = leftIdx + 1
      end

      row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
      row:SetText("|cff33ffccTotal:|r " .. totalSpawns)
      row:Show()
      leftIdx = leftIdx + 1
    end
  else
    local row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
    row:SetText("|cffff5555No data in pfQuest|r")
    row:Show()
    leftIdx = leftIdx + 1
  end

  -- Questie column
  if questieData then
    local row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
    row:SetText("|cffff9900Name:|r " .. (questieName or "Unknown"))
    row:Show()
    rightIdx = rightIdx + 1

    if entityType == "units" and questieData.lvl then
      row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
      row:SetText("|cffff9900Level:|r " .. questieData.lvl)
      row:Show()
      rightIdx = rightIdx + 1
    end

    if entityType == "units" and questieData.fac then
      row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
      row:SetText("|cffff9900Faction:|r " .. questieData.fac)
      row:Show()
      rightIdx = rightIdx + 1
    end

    -- Count spawns by zone
    if questieData.coords then
      row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
      row:SetText("")
      row:Show()
      rightIdx = rightIdx + 1

      row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
      row:SetText("|cffff9900Spawn Locations:|r")
      row:Show()
      rightIdx = rightIdx + 1

      local zoneSpawns = {}
      local totalSpawns = 0
      for _, coord in pairs(questieData.coords) do
        local zoneId = coord[3]
        zoneSpawns[zoneId] = (zoneSpawns[zoneId] or 0) + 1
        totalSpawns = totalSpawns + 1
      end

      for zoneId, count in pairs(zoneSpawns) do
        local zoneName = pfMap and pfMap:GetMapNameByID(zoneId) or ("Zone " .. zoneId)
        row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
        row:SetText("  " .. zoneName .. ": " .. count)
        row:Show()
        rightIdx = rightIdx + 1
      end

      row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
      row:SetText("|cffff9900Total:|r " .. totalSpawns)
      row:Show()
      rightIdx = rightIdx + 1
    end
  else
    local row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
    row:SetText("|cffff5555No data in Questie|r")
    row:Show()
    rightIdx = rightIdx + 1
  end

  -- Update scroll child heights
  self.leftChild:SetHeight(leftIdx * ROW_HEIGHT)
  self.rightChild:SetHeight(rightIdx * ROW_HEIGHT)
end

-- Show zone comparison
function panel:ShowZoneComparison(zoneId)
  self:ClearContent()

  if not zoneId then
    return
  end

  local zoneName = pfMap and pfMap:GetMapNameByID(zoneId) or ("Zone " .. zoneId)
  self.title:SetText("|cff33ffccpfQuest|r Compare Zone: " .. zoneName)

  local leftIdx = 1
  local rightIdx = 1

  -- Count pfQuest units/objects in this zone
  local pfUnits = 0
  local pfObjects = 0

  if pfDB and pfDB.units and pfDB.units.data then
    for id, data in pairs(pfDB.units.data) do
      if data.coords then
        for _, coord in pairs(data.coords) do
          if coord[3] == zoneId then
            pfUnits = pfUnits + 1
            break
          end
        end
      end
    end
  end

  if pfDB and pfDB.objects and pfDB.objects.data then
    for id, data in pairs(pfDB.objects.data) do
      if data.coords then
        for _, coord in pairs(data.coords) do
          if coord[3] == zoneId then
            pfObjects = pfObjects + 1
            break
          end
        end
      end
    end
  end

  -- pfQuest column
  local row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("|cff33ffccZone:|r " .. zoneName)
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("")
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("|cff33ffccUnits:|r " .. pfUnits)
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("|cff33ffccObjects:|r " .. pfObjects)
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("")
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("|cff33ffccTotal Entities:|r " .. (pfUnits + pfObjects))
  row:Show()
  leftIdx = leftIdx + 1

  -- Count Questie units/objects in this zone
  local questieUnits = 0
  local questieObjects = 0

  if pfQDB and pfQDB.questieDataAvailable then
    local expansions = { "wotlk", "tbc", "classic" }
    local countedUnits = {}
    local countedObjects = {}

    for _, exp in ipairs(expansions) do
      if pfQDB.questie[exp] and pfQDB.questie[exp].units then
        for id, data in pairs(pfQDB.questie[exp].units) do
          if not countedUnits[id] and data.coords then
            for _, coord in pairs(data.coords) do
              if coord[3] == zoneId then
                questieUnits = questieUnits + 1
                countedUnits[id] = true
                break
              end
            end
          end
        end
      end

      if pfQDB.questie[exp] and pfQDB.questie[exp].objects then
        for id, data in pairs(pfQDB.questie[exp].objects) do
          if not countedObjects[id] and data.coords then
            for _, coord in pairs(data.coords) do
              if coord[3] == zoneId then
                questieObjects = questieObjects + 1
                countedObjects[id] = true
                break
              end
            end
          end
        end
      end
    end
  end

  -- Questie column
  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("|cffff9900Zone:|r " .. zoneName)
  row:Show()
  rightIdx = rightIdx + 1

  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("")
  row:Show()
  rightIdx = rightIdx + 1

  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("|cffff9900Units:|r " .. questieUnits)
  row:Show()
  rightIdx = rightIdx + 1

  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("|cffff9900Objects:|r " .. questieObjects)
  row:Show()
  rightIdx = rightIdx + 1

  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("")
  row:Show()
  rightIdx = rightIdx + 1

  row = self.rightTexts[rightIdx] or CreateTextRow(self.rightChild, self.rightTexts, rightIdx)
  row:SetText("|cffff9900Total Entities:|r " .. (questieUnits + questieObjects))
  row:Show()
  rightIdx = rightIdx + 1

  -- Difference summary
  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("")
  row:Show()
  leftIdx = leftIdx + 1

  local unitDiff = questieUnits - pfUnits
  local objDiff = questieObjects - pfObjects
  local diffColor = unitDiff >= 0 and "|cff00ff00+" or "|cffff0000"

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("|cffffffffDifference (Q-P):|r")
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("  Units: " .. (unitDiff >= 0 and "|cff00ff00+" or "|cffff0000") .. unitDiff .. "|r")
  row:Show()
  leftIdx = leftIdx + 1

  row = self.leftTexts[leftIdx] or CreateTextRow(self.leftChild, self.leftTexts, leftIdx)
  row:SetText("  Objects: " .. (objDiff >= 0 and "|cff00ff00+" or "|cffff0000") .. objDiff .. "|r")
  row:Show()
  leftIdx = leftIdx + 1

  -- Update scroll child heights
  self.leftChild:SetHeight(leftIdx * ROW_HEIGHT)
  self.rightChild:SetHeight(rightIdx * ROW_HEIGHT)
end

-- Perform search
function panel:DoSearch()
  local searchText = self.searchInput:GetText()
  if not searchText or searchText == "" then
    self.searchResults:Hide()
    return
  end

  -- Clear previous results
  for _, btn in ipairs(self.searchResults.buttons) do
    btn:Hide()
  end

  -- Search both databases
  local results = {}

  -- Search pfQuest
  local pfResults = pfDatabase and pfDatabase:GetIDByName(searchText, currentEntityType, true, false) or {}
  for id, name in pairs(pfResults) do
    if not results[id] then
      results[id] = { id = id, name = name, inPf = true, inQuestie = false }
    else
      results[id].inPf = true
    end
  end

  -- Search Questie
  if pfQDB and pfQDB.questieDataAvailable then
    local questieResults = pfQDB:GetQuestieIDByName(searchText, currentEntityType, true) or {}
    for id, name in pairs(questieResults) do
      if not results[id] then
        results[id] = { id = id, name = name, inPf = false, inQuestie = true }
      else
        results[id].inQuestie = true
      end
    end
  end

  -- Create result buttons
  local i = 0
  for id, info in pairs(results) do
    i = i + 1
    if i > 10 then break end

    local btn = self.searchResults.buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, self.searchResults)
      btn:SetWidth(196)
      btn:SetHeight(18)
      btn:SetPoint("TOPLEFT", 2, -((i-1) * 18) - 2)

      btn.text = btn:CreateFontString(nil, "OVERLAY")
      btn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
      btn.text:SetPoint("LEFT", 5, 0)
      btn.text:SetJustifyH("LEFT")

      btn:SetScript("OnEnter", function()
        this:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        this:SetBackdropColor(0.3, 0.3, 0.3, 1)
      end)
      btn:SetScript("OnLeave", function()
        this:SetBackdrop(nil)
      end)
      btn:SetScript("OnClick", function()
        currentEntityId = this.entityId
        panel.searchResults:Hide()
        panel.searchInput:SetText(this.entityName)
        panel.searchInput:ClearFocus()
        panel:ShowEntityComparison(this.entityId, currentEntityType)
      end)

      self.searchResults.buttons[i] = btn
    end

    btn.entityId = id
    btn.entityName = info.name

    -- Show indicators for which database has this entity
    local indicators = ""
    if info.inPf then indicators = indicators .. "|cff33ffccP|r" end
    if info.inQuestie then indicators = indicators .. "|cffff9900Q|r" end

    btn.text:SetText("[" .. indicators .. "] " .. info.name)
    btn:Show()
  end

  if i > 0 then
    self.searchResults:SetHeight(i * 18 + 4)
    self.searchResults:Show()
  else
    self.searchResults:Hide()
  end
end

-- Show zone dropdown
function panel:ShowZoneDropdown()
  -- Clear previous
  for _, btn in ipairs(self.zoneList.buttons) do
    btn:Hide()
  end

  -- Get all zones
  local zones = {}
  if pfQDB and pfQDB.zones and pfQDB.zones.info then
    for zoneId, info in pairs(pfQDB.zones.info) do
      table.insert(zones, { id = zoneId, name = info.name })
    end
  elseif pfDB and pfDB.zones and pfDB.zones.loc then
    for zoneId, name in pairs(pfDB.zones.loc) do
      table.insert(zones, { id = zoneId, name = name })
    end
  end

  -- Sort by name
  table.sort(zones, function(a, b) return a.name < b.name end)

  -- Create buttons
  for i, zone in ipairs(zones) do
    local btn = self.zoneList.buttons[i]
    if not btn then
      btn = CreateFrame("Button", nil, self.zoneList.child)
      btn:SetWidth(272)
      btn:SetHeight(18)
      btn:SetPoint("TOPLEFT", 2, -((i-1) * 18))

      btn.text = btn:CreateFontString(nil, "OVERLAY")
      btn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
      btn.text:SetPoint("LEFT", 5, 0)
      btn.text:SetJustifyH("LEFT")

      btn:SetScript("OnEnter", function()
        this:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
        this:SetBackdropColor(0.3, 0.3, 0.3, 1)
      end)
      btn:SetScript("OnLeave", function()
        this:SetBackdrop(nil)
      end)
      btn:SetScript("OnClick", function()
        currentZoneId = this.zoneId
        panel.zoneDropdown.text:SetText(this.zoneName)
        panel.zoneDropdown.text:SetTextColor(1, 1, 1, 1)
        panel.zoneList:Hide()
        panel:ShowZoneComparison(this.zoneId)
      end)

      self.zoneList.buttons[i] = btn
    end

    btn.zoneId = zone.id
    btn.zoneName = zone.name
    btn.text:SetText(zone.name)
    btn:Show()
  end

  self.zoneList.child:SetHeight(#zones * 18)
  self.zoneList:Show()
end

-- Show on map
function panel:ShowOnMap(source)
  local meta = { ["addon"] = "PFDB" }

  if currentMode == "entity" and currentEntityId then
    pfMap:DeleteNode("PFDB")

    if source == "pfquest" or source == "both" then
      if currentEntityType == "units" then
        pfDatabase:SearchMobID(currentEntityId, meta)
      else
        pfDatabase:SearchObjectID(currentEntityId, meta)
      end
    end

    if source == "questie" or source == "both" then
      if pfQDB and pfQDB.questieDataAvailable then
        if currentEntityType == "units" then
          pfQDB:SearchQuestieMobID(currentEntityId, meta)
        else
          pfQDB:SearchQuestieObjectID(currentEntityId, meta)
        end
      end
    end

    pfMap:UpdateNodes()

  elseif currentMode == "zone" and currentZoneId then
    -- For zone mode, just show the zone on the map
    pfMap:ShowMapID(currentZoneId)
  end
end

-- Refresh panel based on current mode
function panel:Refresh()
  if currentMode == "entity" then
    self.searchFrame:Show()
    self.zoneFrame:Hide()
    if currentEntityId then
      self:ShowEntityComparison(currentEntityId, currentEntityType)
    else
      self:ClearContent()
    end
  else
    self.searchFrame:Hide()
    self.zoneFrame:Show()
    if currentZoneId then
      self:ShowZoneComparison(currentZoneId)
    else
      self:ClearContent()
    end
  end

  self:UpdateModeButtons()
  self:UpdateTypeButtons()
  self.searchResults:Hide()
  self.zoneList:Hide()
end

-- Search input text changed handler
searchInput:SetScript("OnTextChanged", function()
  panel:DoSearch()
end)

-- API function to show compare panel
function pfQDB:ShowComparePanel(entityId, entityType)
  if entityId and entityType then
    currentMode = "entity"
    currentEntityId = entityId
    currentEntityType = entityType
    panel.searchInput:SetText(pfDB[entityType] and pfDB[entityType]["loc"] and pfDB[entityType]["loc"][entityId] or "")
  end
  panel:Refresh()
  panel:Show()
end

function pfQDB:ShowZoneComparePanel(zoneId)
  currentMode = "zone"
  currentZoneId = zoneId
  if zoneId then
    local zoneName = pfMap and pfMap:GetMapNameByID(zoneId) or ("Zone " .. zoneId)
    panel.zoneDropdown.text:SetText(zoneName)
    panel.zoneDropdown.text:SetTextColor(1, 1, 1, 1)
  end
  panel:Refresh()
  panel:Show()
end

-- ESC key closes panel
tinsert(UISpecialFrames, "pfQDBComparePanel")

-- Slash command
SLASH_PFCOMPARE1 = "/pfcompare"
SlashCmdList["PFCOMPARE"] = function(msg)
  if msg and msg ~= "" then
    -- Try to parse as zone name
    if pfMap and pfMap.GetMapIDByName then
      local zoneId = pfMap:GetMapIDByName(msg)
      if zoneId then
        pfQDB:ShowZoneComparePanel(zoneId)
        return
      end
    end
  end
  pfQDB:ShowComparePanel()
end
