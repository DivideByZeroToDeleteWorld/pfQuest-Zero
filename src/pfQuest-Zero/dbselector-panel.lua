-- Database Selector UI Panel
-- Allows users to select database source (pfQuest/Questie) per zone

pfQDB = pfQDB or {}

-- Panel defaults
local PANEL_WIDTH = 400
local PANEL_HEIGHT = 500
local ROW_HEIGHT = 20
local SCROLL_WIDTH = 16

-- Pending choices (not yet saved)
local pendingChoices = {}

-- Colors
local COLOR_BG = { r = 0.08, g = 0.08, b = 0.08, a = 0.95 }
local COLOR_BORDER = { r = 0.3, g = 0.3, b = 0.3, a = 1 }
local COLOR_HEADER = { r = 0.2, g = 0.8, b = 0.6, a = 1 }
local COLOR_PFQUEST = { r = 0.2, g = 1, b = 0.8, a = 1 }
local COLOR_QUESTIE = { r = 1, g = 0.6, b = 0.2, a = 1 }
local COLOR_TEXT = { r = 0.9, g = 0.9, b = 0.9, a = 1 }

-- Create the main panel
local panel = CreateFrame("Frame", "pfQDBSelectorPanel", UIParent)
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
title:SetText("|cff33ffccpfQuest|r Database Selector")

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
  if this.isPressed then
    this:SetBackdropColor(0.2, 0.05, 0.05, 1)
  else
    this:SetBackdropColor(0.5, 0.1, 0.1, 1)
  end
end)
closeBtn:SetScript("OnLeave", function()
  this.isPressed = false
  this:SetBackdropColor(0.3, 0.1, 0.1, 1)
end)
closeBtn:SetScript("OnMouseDown", function()
  this.isPressed = true
  this:SetBackdropColor(0.2, 0.05, 0.05, 1)
  this.text:SetPoint("CENTER", 1, -1)
end)
closeBtn:SetScript("OnMouseUp", function()
  this.isPressed = false
  this.text:SetPoint("CENTER", 0, 0)
  if MouseIsOver(this) then
    this:SetBackdropColor(0.5, 0.1, 0.1, 1)
  else
    this:SetBackdropColor(0.3, 0.1, 0.1, 1)
  end
end)

-- Status text
local statusText = panel:CreateFontString(nil, "OVERLAY")
statusText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
statusText:SetPoint("TOPLEFT", 10, -28)
statusText:SetPoint("TOPRIGHT", -10, -28)
statusText:SetJustifyH("LEFT")
statusText:SetTextColor(0.7, 0.7, 0.7, 1)
panel.statusText = statusText

-- Default database dropdown area
local defaultFrame = CreateFrame("Frame", nil, panel)
defaultFrame:SetHeight(40)
defaultFrame:SetPoint("TOPLEFT", 10, -45)
defaultFrame:SetPoint("TOPRIGHT", -10, -45)

local defaultLabel = defaultFrame:CreateFontString(nil, "OVERLAY")
defaultLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
defaultLabel:SetPoint("LEFT", 0, 0)
defaultLabel:SetText("Default Database:")
defaultLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

-- pfQuest radio button
local pfRadio = CreateFrame("CheckButton", nil, defaultFrame, "UIRadioButtonTemplate")
pfRadio:SetPoint("LEFT", 120, 0)
pfRadio:SetScript("OnClick", function()
  pfQDB:SetGlobalDefault("pfquest")
  panel:UpdateRadios()
end)

local pfRadioLabel = defaultFrame:CreateFontString(nil, "OVERLAY")
pfRadioLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
pfRadioLabel:SetPoint("LEFT", pfRadio, "RIGHT", 2, 0)
pfRadioLabel:SetText("pfQuest")
pfRadioLabel:SetTextColor(COLOR_PFQUEST.r, COLOR_PFQUEST.g, COLOR_PFQUEST.b, 1)

-- Questie radio button
local questieRadio = CreateFrame("CheckButton", nil, defaultFrame, "UIRadioButtonTemplate")
questieRadio:SetPoint("LEFT", 220, 0)
questieRadio:SetScript("OnClick", function()
  pfQDB:SetGlobalDefault("questie")
  panel:UpdateRadios()
end)

local questieRadioLabel = defaultFrame:CreateFontString(nil, "OVERLAY")
questieRadioLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
questieRadioLabel:SetPoint("LEFT", questieRadio, "RIGHT", 2, 0)
questieRadioLabel:SetText("Questie")
questieRadioLabel:SetTextColor(COLOR_QUESTIE.r, COLOR_QUESTIE.g, COLOR_QUESTIE.b, 1)

panel.pfRadio = pfRadio
panel.questieRadio = questieRadio

-- Filter dropdown area
local filterFrame = CreateFrame("Frame", nil, panel)
filterFrame:SetHeight(30)
filterFrame:SetPoint("TOPLEFT", 10, -85)
filterFrame:SetPoint("TOPRIGHT", -10, -85)

local filterLabel = filterFrame:CreateFontString(nil, "OVERLAY")
filterLabel:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
filterLabel:SetPoint("LEFT", 0, 0)
filterLabel:SetText("Filter:")
filterLabel:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

-- Simple filter buttons
local filterButtons = {}
local filters = { "All", "Classic", "TBC", "WotLK" }
local currentFilter = "All"

for i, filterName in ipairs(filters) do
  local btn = CreateFrame("Button", nil, filterFrame)
  btn:SetWidth(60)
  btn:SetHeight(20)
  btn:SetPoint("LEFT", 50 + ((i-1) * 65), 0)
  btn:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
  btn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  local btnText = btn:CreateFontString(nil, "OVERLAY")
  btnText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  btnText:SetPoint("CENTER", 0, 0)
  btnText:SetText(filterName)
  btn.text = btnText
  btn.filterName = filterName

  btn:SetScript("OnClick", function()
    currentFilter = this.filterName
    panel:UpdateFilterButtons()
    panel:UpdateZoneList()
  end)

  btn:SetScript("OnEnter", function()
    if this.isPressed then
      this:SetBackdropColor(0.1, 0.1, 0.1, 1)
    else
      this:SetBackdropColor(0.25, 0.25, 0.25, 1)
    end
  end)
  btn:SetScript("OnLeave", function()
    this.isPressed = false
    if currentFilter == this.filterName then
      this:SetBackdropColor(0.2, 0.6, 0.4, 1)
    else
      this:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end
  end)
  btn:SetScript("OnMouseDown", function()
    this.isPressed = true
    this:SetBackdropColor(0.1, 0.1, 0.1, 1)
    this.text:SetPoint("CENTER", 1, -1)
  end)
  btn:SetScript("OnMouseUp", function()
    this.isPressed = false
    this.text:SetPoint("CENTER", 0, 0)
    if MouseIsOver(this) then
      this:SetBackdropColor(0.25, 0.25, 0.25, 1)
    elseif currentFilter == this.filterName then
      this:SetBackdropColor(0.2, 0.6, 0.4, 1)
    else
      this:SetBackdropColor(0.15, 0.15, 0.15, 1)
    end
  end)

  filterButtons[filterName] = btn
end

panel.filterButtons = filterButtons

-- Search box (below filter buttons)
local searchBox = CreateFrame("EditBox", nil, panel)
searchBox:SetHeight(22)
searchBox:SetPoint("TOPLEFT", 10, -115)
searchBox:SetPoint("TOPRIGHT", -10, -115)
searchBox:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchBox:SetTextColor(0.9, 0.9, 0.9, 1)
searchBox:SetJustifyH("LEFT")
searchBox:SetTextInsets(22, 24, 2, 2)
searchBox:SetAutoFocus(false)
searchBox:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
searchBox:SetBackdropColor(0.08, 0.08, 0.08, 1)
searchBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

-- Search icon (texture)
searchBox.icon = searchBox:CreateTexture(nil, "OVERLAY")
searchBox.icon:SetTexture(pfQuestConfig.path.."\\img\\tracker_search")
searchBox.icon:SetHeight(14)
searchBox.icon:SetWidth(14)
searchBox.icon:SetVertexColor(0.5, 0.5, 0.5)
searchBox.icon:SetPoint("LEFT", 6, 0)

-- Placeholder text
searchBox.placeholder = searchBox:CreateFontString(nil, "OVERLAY")
searchBox.placeholder:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchBox.placeholder:SetPoint("LEFT", 22, 0)
searchBox.placeholder:SetTextColor(0.4, 0.4, 0.4, 1)
searchBox.placeholder:SetText("Search zones...")

-- Clear button
searchBox.clear = CreateFrame("Button", nil, searchBox)
searchBox.clear:SetSize(14, 14)
searchBox.clear:SetPoint("RIGHT", -5, 0)
searchBox.clear:Hide()

searchBox.clear.text = searchBox.clear:CreateFontString(nil, "OVERLAY")
searchBox.clear.text:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
searchBox.clear.text:SetPoint("CENTER", 0, 0)
searchBox.clear.text:SetText("x")
searchBox.clear.text:SetTextColor(0.6, 0.6, 0.6, 1)

searchBox.clear:SetScript("OnClick", function()
  searchBox:SetText("")
  searchBox:ClearFocus()
end)
searchBox.clear:SetScript("OnEnter", function()
  this.text:SetTextColor(1, 0.3, 0.3, 1)
end)
searchBox.clear:SetScript("OnLeave", function()
  this.text:SetTextColor(0.6, 0.6, 0.6, 1)
end)

searchBox:SetScript("OnTextChanged", function()
  local text = this:GetText()
  if text and text ~= "" then
    this.placeholder:Hide()
    this.icon:Hide()
    this.clear:Show()
  else
    this.placeholder:Show()
    this.icon:Show()
    this.clear:Hide()
  end
  -- Filter zone list
  panel:UpdateZoneList()
end)

searchBox:SetScript("OnEscapePressed", function()
  this:SetText("")
  this:ClearFocus()
end)

searchBox:SetScript("OnEnterPressed", function()
  this:ClearFocus()
end)

searchBox:SetScript("OnEditFocusGained", function()
  this:SetBackdropBorderColor(0.2, 0.8, 0.6, 1)
end)

searchBox:SetScript("OnEditFocusLost", function()
  this:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
end)

panel.searchBox = searchBox

-- Scroll frame for zone list (custom styled, no template)
local scrollFrame = CreateFrame("ScrollFrame", "pfQDBSelectorScrollFrame", panel)
scrollFrame:SetPoint("TOPLEFT", 10, -170)
scrollFrame:SetPoint("BOTTOMRIGHT", -18, 70)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetWidth(PANEL_WIDTH - 35)
scrollChild:SetHeight(1)  -- Will be adjusted dynamically
scrollFrame:SetScrollChild(scrollChild)

-- Scrollbar track (slim, matching config panel style)
local scrollBar = CreateFrame("Frame", nil, panel)
scrollBar:SetWidth(6)
scrollBar:SetPoint("TOPRIGHT", -8, -155)
scrollBar:SetPoint("BOTTOMRIGHT", -8, 70)
scrollBar:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
})
scrollBar:SetBackdropColor(0.1, 0.1, 0.1, 0.8)

-- Scrollbar thumb (draggable)
local scrollThumb = CreateFrame("Frame", nil, scrollBar)
scrollThumb:SetWidth(6)
scrollThumb:SetHeight(40)
scrollThumb:SetPoint("TOP", 0, 0)
scrollThumb:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
})
scrollThumb:SetBackdropColor(0.4, 0.4, 0.4, 1)
scrollThumb:EnableMouse(true)

-- Drag state
panel.isDragging = false

-- Thumb drag handling
scrollThumb:SetScript("OnMouseDown", function()
  panel.isDragging = true
  local _, cursorY = GetCursorPosition()
  panel.dragStartY = cursorY / UIParent:GetEffectiveScale()
  panel.dragStartScroll = scrollFrame:GetVerticalScroll()
end)

scrollThumb:SetScript("OnMouseUp", function()
  panel.isDragging = false
end)

scrollThumb:SetScript("OnUpdate", function()
  if not panel.isDragging then return end

  -- Clear drag state if mouse released
  if not IsMouseButtonDown("LeftButton") then
    panel.isDragging = false
    return
  end

  local _, cursorY = GetCursorPosition()
  local currentY = cursorY / UIParent:GetEffectiveScale()
  local deltaY = panel.dragStartY - currentY

  local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
  if maxScroll <= 0 then return end

  local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
  if thumbRange <= 0 then return end

  local scrollPerPixel = maxScroll / thumbRange
  local newScroll = panel.dragStartScroll + (deltaY * scrollPerPixel)
  newScroll = math.max(0, math.min(newScroll, maxScroll))

  scrollFrame:SetVerticalScroll(newScroll)

  -- Update thumb position
  local thumbPos = (newScroll / maxScroll) * thumbRange
  scrollThumb:ClearAllPoints()
  scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
end)

-- Mouse wheel scrolling
scrollFrame:EnableMouseWheel(true)
scrollFrame:SetScript("OnMouseWheel", function()
  local maxScroll = scrollChild:GetHeight() - scrollFrame:GetHeight()
  if maxScroll <= 0 then return end

  local current = scrollFrame:GetVerticalScroll()
  local newScroll = current - (arg1 * 30)
  newScroll = math.max(0, math.min(newScroll, maxScroll))
  scrollFrame:SetVerticalScroll(newScroll)

  -- Update thumb position
  local thumbRange = scrollBar:GetHeight() - scrollThumb:GetHeight()
  if thumbRange > 0 then
    local thumbPos = (newScroll / maxScroll) * thumbRange
    scrollThumb:ClearAllPoints()
    scrollThumb:SetPoint("TOP", scrollBar, "TOP", 0, -thumbPos)
  end
end)

panel.scrollBar = scrollBar
panel.scrollThumb = scrollThumb

panel.scrollFrame = scrollFrame
panel.scrollChild = scrollChild
panel.zoneRows = {}

-- Reset button
local resetBtn = CreateFrame("Button", nil, panel)
resetBtn:SetWidth(120)
resetBtn:SetHeight(24)
resetBtn:SetPoint("BOTTOMLEFT", 10, 15)
resetBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
resetBtn:SetBackdropColor(0.4, 0.15, 0.15, 1)
resetBtn:SetBackdropBorderColor(0.5, 0.2, 0.2, 1)

local resetText = resetBtn:CreateFontString(nil, "OVERLAY")
resetText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
resetText:SetPoint("CENTER", 0, 0)
resetText:SetText("Reset All Zones")
resetBtn.text = resetText

resetBtn:SetScript("OnClick", function()
  pfQDB:ResetZonePreferences()
  panel:UpdateZoneList()
end)
resetBtn:SetScript("OnEnter", function()
  if this.isPressed then
    this:SetBackdropColor(0.25, 0.1, 0.1, 1)
  else
    this:SetBackdropColor(0.5, 0.2, 0.2, 1)
  end
end)
resetBtn:SetScript("OnLeave", function()
  this.isPressed = false
  this:SetBackdropColor(0.4, 0.15, 0.15, 1)
end)
resetBtn:SetScript("OnMouseDown", function()
  this.isPressed = true
  this:SetBackdropColor(0.25, 0.1, 0.1, 1)
  this.text:SetPoint("CENTER", 1, -1)
end)
resetBtn:SetScript("OnMouseUp", function()
  this.isPressed = false
  this.text:SetPoint("CENTER", 0, 0)
  if MouseIsOver(this) then
    this:SetBackdropColor(0.5, 0.2, 0.2, 1)
  else
    this:SetBackdropColor(0.4, 0.15, 0.15, 1)
  end
end)

-- Save Choices button
local saveBtn = CreateFrame("Button", nil, panel)
saveBtn:SetWidth(120)
saveBtn:SetHeight(24)
saveBtn:SetPoint("BOTTOMRIGHT", -10, 15)
saveBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
saveBtn:SetBackdropColor(0.15, 0.3, 0.15, 1)
saveBtn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1)

local saveText = saveBtn:CreateFontString(nil, "OVERLAY")
saveText:SetFont("Fonts\\FRIZQT__.TTF", 11, "OUTLINE")
saveText:SetPoint("CENTER", 0, 0)
saveText:SetText("Save Choices")
saveBtn.text = saveText

saveBtn:SetScript("OnClick", function()
  -- Save all pending choices to config
  for zoneID, db in pairs(pendingChoices) do
    pfQDB:SetPreferredDB(zoneID, db)
  end
  -- Clear pending choices
  pendingChoices = {}
  panel:UpdatePendingIndicator()
  -- Show confirmation
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Database choices saved.")
end)
saveBtn:SetScript("OnEnter", function()
  if this.isPressed then
    this:SetBackdropColor(0.1, 0.2, 0.1, 1)
  else
    this:SetBackdropColor(0.2, 0.4, 0.2, 1)
  end
end)
saveBtn:SetScript("OnLeave", function()
  this.isPressed = false
  this:SetBackdropColor(0.15, 0.3, 0.15, 1)
end)
saveBtn:SetScript("OnMouseDown", function()
  this.isPressed = true
  this:SetBackdropColor(0.1, 0.2, 0.1, 1)
  this.text:SetPoint("CENTER", 1, -1)
end)
saveBtn:SetScript("OnMouseUp", function()
  this.isPressed = false
  this.text:SetPoint("CENTER", 0, 0)
  if MouseIsOver(this) then
    this:SetBackdropColor(0.2, 0.4, 0.2, 1)
  else
    this:SetBackdropColor(0.15, 0.3, 0.15, 1)
  end
end)

panel.saveBtn = saveBtn

-- Total zones counter at bottom left (above buttons)
local totalZonesText = panel:CreateFontString(nil, "OVERLAY")
totalZonesText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
totalZonesText:SetPoint("BOTTOMLEFT", 10, 50)
totalZonesText:SetTextColor(0.7, 0.7, 0.7, 1)
totalZonesText:SetText("Total Zones: 0")
panel.totalZonesText = totalZonesText

-- Update functions
function panel:UpdateRadios()
  local default = (pfQuest_config and pfQuest_config.zoneDBDefault) or "pfquest"
  self.pfRadio:SetChecked(default == "pfquest")
  self.questieRadio:SetChecked(default == "questie")
end

function panel:UpdateFilterButtons()
  for name, btn in pairs(self.filterButtons) do
    if name == currentFilter then
      btn:SetBackdropColor(0.2, 0.6, 0.4, 1)
      btn.text:SetTextColor(1, 1, 1, 1)
    else
      btn:SetBackdropColor(0.15, 0.15, 0.15, 1)
      btn.text:SetTextColor(0.7, 0.7, 0.7, 1)
    end
  end
end

function panel:UpdatePendingIndicator()
  -- Count pending changes
  local count = 0
  for _ in pairs(pendingChoices) do
    count = count + 1
  end

  -- Update save button to show pending count
  if count > 0 then
    self.saveBtn.text:SetText("Save Choices (" .. count .. ")")
    self.saveBtn:SetBackdropColor(0.2, 0.5, 0.2, 1)
    self.saveBtn:SetBackdropBorderColor(0.3, 0.6, 0.3, 1)
  else
    self.saveBtn.text:SetText("Save Choices")
    self.saveBtn:SetBackdropColor(0.15, 0.3, 0.15, 1)
    self.saveBtn:SetBackdropBorderColor(0.2, 0.4, 0.2, 1)
  end
end

function panel:GetFilteredZones()
  local zones = {}
  local expansion = nil
  local searchText = self.searchBox and strlower(self.searchBox:GetText() or "") or ""

  if currentFilter == "Classic" then
    expansion = "classic"
  elseif currentFilter == "TBC" then
    expansion = "tbc"
  elseif currentFilter == "WotLK" then
    expansion = "wotlk"
  end

  if expansion then
    zones = pfQDB:GetZonesByExpansion(expansion)
  else
    -- All zones
    for zoneID, info in pairs(pfQDB.zones.info) do
      table.insert(zones, { id = zoneID, name = info.name, continent = info.continent, expansion = info.expansion })
    end
    -- Sort by name
    table.sort(zones, function(a, b) return a.name < b.name end)
  end

  -- Apply search filter
  if searchText ~= "" then
    local filteredZones = {}
    for _, zone in ipairs(zones) do
      if strfind(strlower(zone.name), searchText, 1, true) then
        table.insert(filteredZones, zone)
      end
    end
    zones = filteredZones
  end

  return zones
end

function panel:CreateZoneRow(zone, index)
  local row = CreateFrame("Frame", nil, self.scrollChild)
  row:SetWidth(PANEL_WIDTH - 25)
  row:SetHeight(ROW_HEIGHT)
  row:SetPoint("TOPLEFT", 0, -((index - 1) * ROW_HEIGHT))

  -- Alternate row background
  if index % 2 == 0 then
    row:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8"})
    row:SetBackdropColor(0.12, 0.12, 0.12, 0.5)
  end

  -- Zone name
  local nameText = row:CreateFontString(nil, "OVERLAY")
  nameText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
  nameText:SetPoint("LEFT", 5, 0)
  nameText:SetWidth(180)
  nameText:SetJustifyH("LEFT")
  nameText:SetText(zone.name)
  nameText:SetTextColor(COLOR_TEXT.r, COLOR_TEXT.g, COLOR_TEXT.b, 1)

  -- pfQuest radio
  local pfRadio = CreateFrame("CheckButton", nil, row, "UIRadioButtonTemplate")
  pfRadio:SetPoint("LEFT", 200, 0)
  pfRadio.zoneID = zone.id
  pfRadio:SetScript("OnClick", function()
    local row = this:GetParent()
    pendingChoices[this.zoneID] = "pfquest"
    row.pfRadio:SetChecked(true)
    row.questieRadio:SetChecked(false)
    panel:UpdatePendingIndicator()
  end)

  -- Questie radio
  local questieRadio = CreateFrame("CheckButton", nil, row, "UIRadioButtonTemplate")
  questieRadio:SetPoint("LEFT", 280, 0)
  questieRadio.zoneID = zone.id
  questieRadio:SetScript("OnClick", function()
    local row = this:GetParent()
    pendingChoices[this.zoneID] = "questie"
    row.pfRadio:SetChecked(false)
    row.questieRadio:SetChecked(true)
    panel:UpdatePendingIndicator()
  end)

  -- Set checked state from pending or saved
  local pref = pendingChoices[zone.id] or pfQDB:GetPreferredDB(zone.id)
  pfRadio:SetChecked(pref == "pfquest")
  questieRadio:SetChecked(pref == "questie")

  -- Disable Questie radio if data not available
  if not pfQDB.questieDataAvailable then
    questieRadio:Disable()
    questieRadio:SetAlpha(0.3)
  end

  -- Compare button
  local compareBtn = CreateFrame("Button", nil, row)
  compareBtn:SetWidth(16)
  compareBtn:SetHeight(16)
  compareBtn:SetPoint("LEFT", 330, 0)
  compareBtn.zoneID = zone.id
  compareBtn.zoneName = zone.name

  compareBtn.text = compareBtn:CreateFontString(nil, "OVERLAY")
  compareBtn.text:SetFont("Fonts\\FRIZQT__.TTF", 9, "OUTLINE")
  compareBtn.text:SetPoint("CENTER", 0, 0)
  compareBtn.text:SetText("C")
  compareBtn.text:SetTextColor(0.7, 0.7, 0.7, 1)

  compareBtn:SetScript("OnClick", function()
    if pfQDB and pfQDB.ShowZoneComparePanel then
      pfQDB:ShowZoneComparePanel(this.zoneID)
    end
  end)
  compareBtn:SetScript("OnEnter", function()
    this.text:SetTextColor(1, 1, 0.5, 1)
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText("Compare Zone Data")
    GameTooltip:AddLine("Compare pfQuest and Questie data for " .. this.zoneName, 0.7, 0.7, 0.7, 1)
    GameTooltip:Show()
  end)
  compareBtn:SetScript("OnLeave", function()
    this.text:SetTextColor(0.7, 0.7, 0.7, 1)
    GameTooltip:Hide()
  end)

  row.pfRadio = pfRadio
  row.questieRadio = questieRadio
  row.compareBtn = compareBtn
  row.zoneID = zone.id

  return row
end

function panel:UpdateZoneList()
  -- Clear existing rows
  for _, row in ipairs(self.zoneRows) do
    row:Hide()
    row:SetParent(nil)
  end
  self.zoneRows = {}

  -- Get filtered zones
  local zones = self:GetFilteredZones()

  -- Create rows
  for i, zone in ipairs(zones) do
    local row = self:CreateZoneRow(zone, i)
    table.insert(self.zoneRows, row)
  end

  -- Update scroll child height
  self.scrollChild:SetHeight(#zones * ROW_HEIGHT)

  -- Reset scroll position and thumb
  self.scrollFrame:SetVerticalScroll(0)
  self.scrollThumb:ClearAllPoints()
  self.scrollThumb:SetPoint("TOP", self.scrollBar, "TOP", 0, 0)

  -- Update thumb size based on content
  local maxScroll = self.scrollChild:GetHeight() - self.scrollFrame:GetHeight()
  if maxScroll > 0 then
    local visibleRatio = self.scrollFrame:GetHeight() / self.scrollChild:GetHeight()
    local thumbHeight = math.max(20, self.scrollBar:GetHeight() * visibleRatio)
    self.scrollThumb:SetHeight(thumbHeight)
    self.scrollThumb:Show()
  else
    self.scrollThumb:Hide()
  end

  -- Update total zones counter
  self.totalZonesText:SetText("Total Zones for \"" .. currentFilter .. "\" Filter: " .. #zones)
end

function panel:UpdateStatus()
  if pfQDB.questieDataAvailable then
    self.statusText:SetText("Questie data |cff00ff00available|r")
  else
    self.statusText:SetText("Questie data |cffff0000not loaded|r")
  end
end

function panel:Refresh()
  -- Clear pending choices when panel opens fresh
  pendingChoices = {}
  -- Clear search box
  if self.searchBox then
    self.searchBox:SetText("")
  end
  self:UpdateStatus()
  self:UpdateRadios()
  self:UpdateFilterButtons()
  self:UpdateZoneList()
  self:UpdatePendingIndicator()
end

-- Show/hide toggle
function pfQDB:TogglePanel()
  if panel:IsShown() then
    panel:Hide()
  else
    panel:Refresh()
    panel:Show()
  end
end

function pfQDB:ShowPanel()
  panel:Refresh()
  panel:Show()
end

function pfQDB:HidePanel()
  panel:Hide()
end

-- Add column headers (positioned below search box)
local headerFrame = CreateFrame("Frame", nil, panel)
headerFrame:SetHeight(20)
headerFrame:SetPoint("TOPLEFT", 10, -145)
headerFrame:SetPoint("TOPRIGHT", -30, -145)

local headerZone = headerFrame:CreateFontString(nil, "OVERLAY")
headerZone:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
headerZone:SetPoint("LEFT", 5, 0)
headerZone:SetText("Zone")
headerZone:SetTextColor(COLOR_HEADER.r, COLOR_HEADER.g, COLOR_HEADER.b, 1)

local headerPf = headerFrame:CreateFontString(nil, "OVERLAY")
headerPf:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
headerPf:SetPoint("LEFT", 200, 0)
headerPf:SetText("pfQuest")
headerPf:SetTextColor(COLOR_PFQUEST.r, COLOR_PFQUEST.g, COLOR_PFQUEST.b, 1)

local headerQuestie = headerFrame:CreateFontString(nil, "OVERLAY")
headerQuestie:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
headerQuestie:SetPoint("LEFT", 270, 0)
headerQuestie:SetText("Questie")
headerQuestie:SetTextColor(COLOR_QUESTIE.r, COLOR_QUESTIE.g, COLOR_QUESTIE.b, 1)

local headerCompare = headerFrame:CreateFontString(nil, "OVERLAY")
headerCompare:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
headerCompare:SetPoint("LEFT", 330, 0)
headerCompare:SetText("Compare")
headerCompare:SetTextColor(0.8, 0.8, 0.5, 1)

-- ESC key closes panel
tinsert(UISpecialFrames, "pfQDBSelectorPanel")

-- Slash command
SLASH_PFQDB1 = "/pfqdb"
SLASH_PFQDB2 = "/pfquest-db"
SlashCmdList["PFQDB"] = function(msg)
  pfQDB:TogglePanel()
end
