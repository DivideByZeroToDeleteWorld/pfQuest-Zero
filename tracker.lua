-- multi api compat
local compat = pfQuestCompat

local fontsize = 12
local panelheight = 16
local entryheight = 20

local function HideTooltip()
  GameTooltip:Hide()
end

local function ShowTooltip()
  if this.tooltip then
    GameTooltip:ClearLines()
    GameTooltip_SetDefaultAnchor(GameTooltip, this)
    if this.text then
      GameTooltip:SetText(this.text:GetText())
      GameTooltip:SetText(this.text:GetText(), this.text:GetTextColor())
    else
      GameTooltip:SetText("|cff33ffccpf|cffffffffQuest")
    end

    if this.node and this.node.questid then
      if pfDB["quests"] and pfDB["quests"]["loc"] and pfDB["quests"]["loc"][this.node.questid] and pfDB["quests"]["loc"][this.node.questid]["O"] then
        GameTooltip:AddLine(pfDatabase:FormatQuestText(pfDB["quests"]["loc"][this.node.questid]["O"]), 1,1,1,1)
        GameTooltip:AddLine(" ")
      end

      local qlogid = pfQuest.questlog[this.node.questid] and pfQuest.questlog[this.node.questid].qlogid
      if qlogid then
        local objectives = GetNumQuestLeaderBoards(qlogid)
        if objectives and objectives > 0 then
          for i=1, objectives, 1 do
            local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
            local _, _, obj, cur, req = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")
            if done then
              GameTooltip:AddLine(" - " .. text, 0,1,0)
            elseif cur and req then
              local r,g,b = pfMap.tooltip:GetColor(cur, req)
              GameTooltip:AddLine(" - " .. text, r,g,b)
            else
              GameTooltip:AddLine(" - " .. text, 1,0,0)
            end
          end
          GameTooltip:AddLine(" ")
        end
      end
    end

    GameTooltip:AddLine(this.tooltip, 1,1,1)
    GameTooltip:Show()
  end
end

local expand_states = {}

tracker = CreateFrame("Frame", "pfQuestMapTracker", UIParent)
tracker:Hide()
tracker:SetPoint("LEFT", UIParent, "LEFT", 0, 0)
tracker:SetWidth(200)

-- make global available immediately
pfQuest.tracker = tracker
tracker:SetMovable(true)
tracker:EnableMouse(true)
tracker:SetClampedToScreen(true)
tracker:RegisterEvent("PLAYER_ENTERING_WORLD")
tracker:SetScript("OnEvent", function()
  -- update font sizes according to config
  fontsize = tonumber(pfQuest_config["trackerfontsize"]) or 12

  -- function to get configured font
  _G.GetTrackerFont = function()
    local fontName = pfQuest_config["trackerfont"] or "FranzBold"

    -- try to get font from LibSharedMedia first
    if LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) then
      local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
      local fontPath = LSM:Fetch("font", fontName, true)
      if fontPath then
        return fontPath
      end
    end

    -- fallback to game fonts
    if fontName == "FranzBold" then return pfUI.font_default end
    if fontName == "Arial" then return "Fonts\\ARIALN.TTF" end
    if fontName == "Skurri" then return "Fonts\\SKURRI.TTF" end
    if fontName == "Morpheus" then return "Fonts\\MORPHEUS.TTF" end
    if fontName == "IMMORTAL" then return "Fonts\\IMMORTAL.TTF" end

    -- final fallback
    return pfUI.font_default
  end

  -- get font style
  _G.GetTrackerFontStyle = function()
    return pfQuest_config["trackerfontstyle"] or "OUTLINE"
  end

  -- function to refresh all tracker fonts and layout
  _G.RefreshTrackerFonts = function()
    -- update font size from config
    fontsize = tonumber(pfQuest_config["trackerfontsize"]) or 12
    -- calculate row heights based on font size
    titlerowheight = fontsize + 5  -- Quest titles get more vertical space (includes bottom padding)
    objectiverowheight = fontsize + 3  -- Objectives use tighter spacing

    if not tracker.buttons then return end

    -- Just update fonts on existing elements, don't recalculate layout yet
    for id, button in pairs(tracker.buttons) do
      -- update button title font
      if button.text then
        button.text:SetFont(GetTrackerFont(), fontsize, GetTrackerFontStyle())
      end

      -- update objective fonts for this button
      if button.objectives then
        for i = 1, table.getn(button.objectives) do
          if button.objectives[i] then
            button.objectives[i]:SetFont(GetTrackerFont(), fontsize, GetTrackerFontStyle())
          end
        end
      end
    end
  end

  -- calculate row heights based on font size
  titlerowheight = fontsize + 5  -- Quest titles get more vertical space (includes bottom padding)
  objectiverowheight = fontsize + 3  -- Objectives use tighter spacing

  -- restore tracker state
  if pfQuest_config["showtracker"] and pfQuest_config["showtracker"] == "0" then
    this:Hide()
  else
    this:Show()
  end

  -- Hide perks button if SynastriaCoreLib is not available
  if tracker.btnperks then
    local SCL = LibStub and LibStub("SynastriaCoreLib-1.0", true)
    if not SCL or not SCL.Perks then
      tracker.btnperks:Hide()
    end
  end
end)

tracker:SetScript("OnMouseDown",function()
  if not pfQuest_config.lock then
    this:StartMoving()
  end
end)

tracker:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
  local anchor, x, y = pfUI.api.ConvertFrameAnchor(this, pfUI.api.GetBestAnchor(this))
  this:ClearAllPoints()
  this:SetPoint(anchor, x, y)

  -- save position
  pfQuest_config.trackerpos = { anchor, x, y }
end)

tracker:SetScript("OnUpdate", function()
  if WorldMapFrame:IsShown() then
    if this.strata ~= "FULLSCREEN_DIALOG" then
      this:SetFrameStrata("FULLSCREEN_DIALOG")
      this.strata = "FULLSCREEN_DIALOG"
    end
  else
    if this.strata ~= "BACKGROUND" then
      this:SetFrameStrata("BACKGROUND")
      this.strata = "BACKGROUND"
    end
  end

  local alpha = this.backdrop:GetAlpha()
  local content = tracker.buttons[1] and not tracker.buttons[1].empty and true or nil
  local goal = ( content and not MouseIsOver(this) ) and 0 or not content and not MouseIsOver(this) and 0.5 or 1
  if ceil(alpha*10) ~= ceil(goal*10)then
    this.backdrop:SetAlpha(alpha + ((goal - alpha) > 0 and .1 or (goal - alpha) < 0 and -.1 or 0))
  end

  if pfQuestCompat.QuestWatchFrame:IsShown() then
    pfQuestCompat.QuestWatchFrame:Hide()
  end
end)

tracker:SetScript("OnShow", function()
  pfQuest_config["showtracker"] = "1"

  -- load tracker position if exists
   if pfQuest_config.trackerpos then
     this:ClearAllPoints()
     this:SetPoint(unpack(pfQuest_config.trackerpos))
   end
end)

tracker:SetScript("OnHide", function()
  pfQuest_config["showtracker"] = "0"
end)

tracker.buttons = {}
tracker.mode = "QUEST_TRACKING"

tracker.backdrop = CreateFrame("Frame", nil, tracker)
tracker.backdrop:SetAllPoints(tracker)
tracker.backdrop.bg = tracker.backdrop:CreateTexture(nil, "BACKGROUND")
tracker.backdrop.bg:SetTexture(0,0,0,.2)
tracker.backdrop.bg:SetAllPoints()

do -- button panel
  tracker.panel = CreateFrame("Frame", nil, tracker.backdrop)
  tracker.panel:SetPoint("TOPLEFT", 0, 0)
  tracker.panel:SetPoint("TOPRIGHT", 0, 0)
  tracker.panel:SetHeight(panelheight)

  local anchors = {}
  local buttons = {}
  local function CreateButton(icon, anchor, tooltip, func)
    anchors[anchor] = anchors[anchor] and anchors[anchor] + 1 or 0
    local pos = 1+(panelheight+1)*anchors[anchor]
    pos = anchor == "TOPLEFT" and pos or pos*-1
    local func = func

    local b = CreateFrame("Button", nil, tracker.panel)
    b.tooltip = tooltip
    b.icon = b:CreateTexture(nil, "BACKGROUND")
    b.icon:SetAllPoints()
    b.icon:SetTexture(pfQuestConfig.path.."\\img\\tracker_"..icon)
    if table.getn(buttons) == 0 then b.icon:SetVertexColor(.2,1,.8) end

    b:SetPoint(anchor, pos, -1)
    b:SetWidth(panelheight-2)
    b:SetHeight(panelheight-2)

    b:SetScript("OnEnter", ShowTooltip)
    b:SetScript("OnLeave", HideTooltip)

    if anchor == "TOPLEFT" then
      table.insert(buttons, b)
      b:SetScript("OnClick", function()
        if func then func() end
        for id, button in pairs(buttons) do
          button.icon:SetVertexColor(1,1,1)
        end
        this.icon:SetVertexColor(.2,1,.8)
      end)
    else
      b:SetScript("OnClick", func)
    end

    return b
  end

  tracker.btnquest = CreateButton("quests", "TOPLEFT", pfQuest_Loc["Show Current Quests"], function()
    tracker.mode = "QUEST_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btndatabase = CreateButton("database", "TOPLEFT", pfQuest_Loc["Show Database Results"], function()
    tracker.mode = "DATABASE_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btngiver = CreateButton("giver", "TOPLEFT", pfQuest_Loc["Show Quest Givers"], function()
    tracker.mode = "GIVER_TRACKING"
    pfMap:UpdateNodes()
  end)

  tracker.btnperks = CreateButton("perks", "TOPLEFT", pfQuest_Loc["Show Perk Tasks"] or "Show Perk Tasks", function()
    if tracker.mode == "PERK_TRACKING" then
      -- Already in perk mode - toggle expand/collapse all
      local allCollapsed = true

      -- Check if all perk tasks are collapsed
      for id, button in pairs(tracker.buttons) do
        if not button.empty and button.title and expand_states[button.title] == 1 then
          allCollapsed = false
          break
        end
      end

      -- Toggle: if all collapsed, expand all; otherwise collapse all
      local newState = allCollapsed and 1 or 0

      for id, button in pairs(tracker.buttons) do
        if not button.empty and button.title then
          expand_states[button.title] = newState
        end
      end

      -- Refresh all buttons to apply new state
      for id, button in pairs(tracker.buttons) do
        if not button.empty then
          tracker.ButtonEvent(button)
        end
      end
    else
      tracker.mode = "PERK_TRACKING"
      tracker.Reset()
      tracker.ButtonEvent(tracker.buttons[1])
    end
  end)

  tracker.btnclose = CreateButton("close", "TOPRIGHT", pfQuest_Loc["Close Tracker"], function()
    DEFAULT_CHAT_FRAME:AddMessage(pfQuest_Loc["|cff33ffccpf|cffffffffQuest: Tracker is now hidden. Type `/db tracker` to show."])
    tracker:Hide()
  end)

  tracker.btnsettings = CreateButton("settings", "TOPRIGHT", pfQuest_Loc["Open Settings"], function()
    if pfQuestConfig then pfQuestConfig:Show() end
  end)

  tracker.btnclean = CreateButton("clean", "TOPRIGHT", pfQuest_Loc["Clean Database Results"], function()
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
  end)

  -- Lock button (custom, not using CreateButton since we need different textures for states)
  anchors["TOPRIGHT"] = anchors["TOPRIGHT"] and anchors["TOPRIGHT"] + 1 or 0
  local lockpos = -1-(panelheight+1)*anchors["TOPRIGHT"]

  tracker.btnlock = CreateFrame("Button", nil, tracker.panel)
  tracker.btnlock.tooltip = pfQuest_Loc["Lock Tracker Position"] or "Lock Tracker Position"
  tracker.btnlock.icon = tracker.btnlock:CreateTexture(nil, "BACKGROUND")
  tracker.btnlock.icon:SetAllPoints()

  tracker.btnlock:SetPoint("TOPRIGHT", lockpos, -1)
  tracker.btnlock:SetWidth(panelheight-2)
  tracker.btnlock:SetHeight(panelheight-2)

  tracker.btnlock:SetScript("OnEnter", ShowTooltip)
  tracker.btnlock:SetScript("OnLeave", HideTooltip)

  -- Update icon based on lock state
  local function UpdateLockIcon()
    if pfQuest_config.lock then
      tracker.btnlock.icon:SetTexture(pfQuestConfig.path.."\\img\\lock_2")
      tracker.btnlock.icon:SetVertexColor(.2,1,.8)
    else
      tracker.btnlock.icon:SetTexture(pfQuestConfig.path.."\\img\\lock_1")
      tracker.btnlock.icon:SetVertexColor(1,1,1)
    end
  end

  tracker.btnlock:SetScript("OnClick", function()
    pfQuest_config.lock = not pfQuest_config.lock and true or nil
    UpdateLockIcon()
  end)

  tracker.btnlock:SetScript("OnShow", UpdateLockIcon)
  UpdateLockIcon()

  tracker.btnsearch = CreateButton("search", "TOPRIGHT", pfQuest_Loc["Open Database Browser"], function()
    if pfBrowser then pfBrowser:Show() end
  end)
end

do -- scrollframe setup
  -- Create the ScrollFrame
  tracker.scrollframe = CreateFrame("ScrollFrame", "pfQuestMapTrackerScrollFrame", tracker)
  tracker.scrollframe:SetPoint("TOPLEFT", tracker.panel, "BOTTOMLEFT", 0, 0)
  tracker.scrollframe:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", 0, 0)
  
  -- Create the ScrollChild frame that will hold all quest buttons
  tracker.scrollchild = CreateFrame("Frame", "pfQuestMapTrackerScrollChild", tracker.scrollframe)
  tracker.scrollchild:SetWidth(1)
  tracker.scrollchild:SetHeight(1)
  tracker.scrollframe:SetScrollChild(tracker.scrollchild)
  
  -- Create the scrollbar (invisible, used only for scroll position tracking)
  tracker.scrollbar = CreateFrame("Slider", "pfQuestMapTrackerScrollBar", tracker.scrollframe)
  tracker.scrollbar:SetMinMaxValues(0, 1)
  tracker.scrollbar:SetValueStep(1)
  tracker.scrollbar:SetValue(0)
  tracker.scrollbar:Hide()
  
  -- Scrollbar functionality
  tracker.scrollbar:SetScript("OnValueChanged", function()
    tracker.scrollframe:SetVerticalScroll(this:GetValue())
  end)
  
  -- Mouse wheel scrolling
  tracker.scrollframe:EnableMouseWheel(true)
  tracker.scrollframe:SetScript("OnMouseWheel", function()
    local contentHeight = tracker.scrollchild:GetHeight()
    local frameHeight = tracker.scrollframe:GetHeight()
    local maxScroll = max(0, contentHeight - frameHeight)
    
    local current = tracker.scrollbar:GetValue()
    local step = entryheight -- scroll by one entry height at a time
    
    if arg1 > 0 then
      -- scroll up (decrease scroll value, show content at top)
      tracker.scrollbar:SetValue(max(0, current - step))
    else
      -- scroll down (increase scroll value, but never past maxScroll)
      tracker.scrollbar:SetValue(min(maxScroll, current + step))
    end
  end)
  
  -- Update scrollbar range based on content
  tracker.UpdateScrollBar = function()
    local contentHeight = tracker.scrollchild:GetHeight()
    local frameHeight = tracker.scrollframe:GetHeight()

    -- Ensure we have valid heights
    if not contentHeight or contentHeight <= 0 then contentHeight = 1 end
    if not frameHeight or frameHeight <= 0 then frameHeight = 1 end

    if contentHeight > frameHeight then
      -- Maximum scroll should stop when bottom of content aligns with bottom of frame
      local maxScroll = max(0, contentHeight - frameHeight)
      tracker.scrollbar:SetMinMaxValues(0, maxScroll)

      -- Clamp current scroll value to new max if needed
      local currentScroll = tracker.scrollbar:GetValue()
      if currentScroll > maxScroll then
        tracker.scrollbar:SetValue(maxScroll)
      end
    else
      -- Content fits entirely in frame, no scrolling needed
      tracker.scrollbar:SetValue(0)
      tracker.scrollframe:SetVerticalScroll(0)
      tracker.scrollbar:SetMinMaxValues(0, 0)
    end
  end
end

function tracker.ButtonEnter()
  pfMap.highlight = this.title
  ShowTooltip()
end

function tracker.ButtonLeave()
  pfMap.highlight = nil
  HideTooltip()
end

function tracker.ButtonUpdate()
  local alpha = tonumber((pfQuest_config["trackeralpha"] or .2)) or .2

  if not this.alpha or this.alpha ~= alpha then
    this.bg:SetTexture(0,0,0,alpha)
    this.bg:SetAlpha(alpha)
    this.alpha = alpha
  end

  if pfMap.highlight and pfMap.highlight == this.title then
    if not this.highlight then
      this.bg:SetTexture(1,1,1,math.max(.2, alpha))
      this.bg:SetAlpha(math.max(.5, alpha))
      this.highlight = true
    end
  elseif this.highlight then
    this.bg:SetTexture(0,0,0,alpha)
    this.bg:SetAlpha(alpha)
    this.highlight = nil
  end
end

function tracker.ButtonClick()
  if arg1 == "RightButton" then
    for questid, data in pairs(pfQuest.questlog) do
      if data.title == this.title then
        -- show questlog
        HideUIPanel(QuestLogFrame)
        SelectQuestLogEntry(data.qlogid)
        ShowUIPanel(QuestLogFrame)
        break
      end
    end
  elseif IsShiftKeyDown() then
    -- mark as done if node is quest and not in questlog
    if this.node.questid and not this.node.qlogid then
      -- mark as done in history
      pfQuest_history[this.node.questid] = { time(), UnitLevel("player") }
      UIErrorsFrame:AddMessage(string.format("The Quest |cffffcc00[%s]|r (id:%s) is now marked as done.", this.title, this.node.questid), 1,1,1)
    end

    pfMap:DeleteNode(this.node.addon, this.title)
    pfMap:UpdateNodes()

    pfQuest.updateQuestGivers = true
  elseif IsControlKeyDown() and not WorldMapFrame:IsShown() then
    -- show world map
    if ToggleWorldMap then
      -- vanilla & tbc
      ToggleWorldMap()
    else
      -- wotlk
      WorldMapFrame:Show()
    end
  elseif IsControlKeyDown() and pfQuest_config["spawncolors"] == "0" then
    -- switch color
    pfQuest_colors[this.title] = { pfMap.str2rgb(this.title .. GetTime()) }
    pfMap:UpdateNodes()
  elseif expand_states[this.title] == 0 then
    expand_states[this.title] = 1
    tracker.ButtonEvent(this)
  elseif expand_states[this.title] == 1 then
    expand_states[this.title] = 0
    tracker.ButtonEvent(this)
  end
end

local function trackersort(a,b)
  if a.empty then
    return false
  elseif ( a.tracked and 1 or -1 ) ~= (b.tracked and 1 or -1) then
    return ( a.tracked and 1 or -1 ) > (b.tracked and 1 or -1)
  elseif ( a.level or -1 ) ~= ( b.level or -1 ) then
    return (a.level or -1) > (b.level or -1)
  elseif ( a.perc or -1 ) ~= ( b.perc or -1 ) then
    return (a.perc or -1) > (b.perc or -1)
  elseif ( a.title or "" ) ~= ( b.title or "" ) then
    return ( a.title or "" ) < ( b.title or "" )
  else
    return false
  end
end

function tracker.ButtonEvent(self)
  local self   = self or this
  local title  = self.title
  local node   = self.node
  local id     = self.id
  local qid    = self.questid

  self:SetHeight(0)

  -- we got an event on a hidden button
  if not title then return end
  if self.empty then return end

  -- Don't set fixed height here - let it be calculated from wrapped text
  -- self:SetHeight(entryheight)

  -- initialize and hide all objectives
  self.objectives = self.objectives or {}
  for id, obj in pairs(self.objectives) do obj:Hide() end

  -- update button icon
  if node.texture then
    self.icon:SetTexture(node.texture)

    local r, g, b = unpack(node.vertex or {0,0,0})
    if r > 0 or g > 0 or b > 0 then
      self.icon:SetVertexColor(unpack(node.vertex))
    else
      self.icon:SetVertexColor(1,1,1,1)
    end
  elseif pfQuest_config["spawncolors"] == "1" then
    self.icon:SetTexture(pfQuestConfig.path.."\\img\\available_c")
    self.icon:SetVertexColor(1,1,1,1)
  else
    self.icon:SetTexture(pfQuestConfig.path.."\\img\\node")
    self.icon:SetVertexColor(pfMap.str2rgb(title))
  end

  if tracker.mode == "QUEST_TRACKING" then
    local qlogid = pfQuest.questlog[qid] and pfQuest.questlog[qid].qlogid or 0
    local qtitle, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
    if not qlogid or not qtitle then return end
    local objectives = GetNumQuestLeaderBoards(qlogid)
    local watched = IsQuestWatched(qlogid)
    local color = pfQuestCompat.GetDifficultyColor(level)
    local cur,max = 0,0
    local percent = 0

    -- write expand state
    if not expand_states[title] then
      expand_states[title] = pfQuest_config["trackerexpand"] == "1" and 1 or 0
    end

    local expanded = expand_states[title] == 1 and true or nil

    if objectives and objectives > 0 then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")
        if objNum and objNeeded then
          max = max + objNeeded
          cur = cur + objNum
        elseif not done then
          max = max + 1
        end
      end
    end

    if cur == max or complete then
      cur, max = 1, 1
      percent = 100
    else
      percent = cur/max*100
    end

    -- Set the title text FIRST so we can calculate its height
    local r,g,b = pfMap.tooltip:GetColor(cur, max)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. ( tag and "+" or "") .. "] " or ""

    self.tracked = watched
    self.perc = percent
    self.text:SetText(string.format("%s%s |cffaaaaaa(%s%s%%|cffaaaaaa)|r", showlevel, title or "", colorperc or "", ceil(percent)))
    self.text:SetTextColor(color.r, color.g, color.b)
    self.tooltip = pfQuest_Loc["|cff33ffcc<Click>|r Unfold/Fold Objectives\n|cff33ffcc<Right-Click>|r Show In QuestLog\n|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"]

    -- Initialize objectives table if it doesn't exist
    if not self.objectives then
      self.objectives = {}
    end

    -- Track total height accumulated by objectives
    local objectivesHeight = 0
    local visibleObjectives = 0

    -- Position objectives using anchor chains for proper wrapping
    if objectives and (expanded or ( percent > 0 and percent < 100 )) then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")

        if not self.objectives[i] then
          self.objectives[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectives[i]:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
          self.objectives[i]:SetJustifyH("LEFT")
          self.objectives[i]:SetJustifyV("TOP")  -- Top-align text to prevent gaps
          self.objectives[i]:SetWordWrap(true)
          self.objectives[i]:SetNonSpaceWrap(true)  -- Allow wrapping on any character if needed
        end

        -- Calculate available width for objectives (button width minus padding)
        local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
        local objectiveWidth = trackerWidth - 30  -- 20px left padding + 10px right padding

        -- Explicitly set width to force proper text wrapping
        self.objectives[i]:SetWidth(objectiveWidth)

        -- Position the objective
        self.objectives[i]:ClearAllPoints()
        if i == 1 then
          -- First objective anchors below the title (3px below title text)
          local firstObjOffset = -(fontsize + 3)
          self.objectives[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)
        else
          -- Subsequent objectives anchor to bottom of previous objective
          self.objectives[i]:SetPoint("TOPLEFT", self.objectives[i-1], "BOTTOMLEFT", 0, -2)
        end

        -- Set text AFTER width is constrained so wrapping calculates correctly
        if objNum and objNeeded then
          local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
          self.objectives[i]:SetTextColor(r+.2, g+.2, b+.2)
          self.objectives[i]:SetText(string.format("|cffffffff- %s:|r %s/%s", obj, objNum, objNeeded))
        else
          self.objectives[i]:SetTextColor(.8,.8,.8)
          self.objectives[i]:SetText("|cffffffff- " .. text)
        end

        self.objectives[i]:Show()
        visibleObjectives = i

        -- Get actual wrapped height (no rounding - use real height)
        local wrappedHeight = self.objectives[i]:GetHeight()
        objectivesHeight = objectivesHeight + wrappedHeight + (i > 1 and 2 or 0)  -- Add 2px spacing between objectives
      end
    end

    -- Hide any old objectives that are no longer needed
    for i = visibleObjectives + 1, table.getn(self.objectives) do
      if self.objectives[i] then
        self.objectives[i]:Hide()
      end
    end

    -- Calculate total height
    local actualHeight
    if objectivesHeight > 0 then
      -- Expanded: title area + objectives + bottom padding for separation from next button
      local titleArea = fontsize + 3  -- Matches first objective offset
      local bottomPadding = 3
      actualHeight = titleArea + objectivesHeight + bottomPadding
    else
      -- Collapsed: just the title row
      actualHeight = titlerowheight
    end

    self:SetHeight(actualHeight)
  elseif tracker.mode == "GIVER_TRACKING" then
    local level = node.qlvl or node.level or UnitLevel("player")
    local color = pfQuestCompat.GetDifficultyColor(level)

    -- red quests
    if node.qmin and node.qmin > UnitLevel("player") then
      color = { r = 1, g = 0, b = 0 }
    end

    -- detect daily quests
    if node.qmin and node.qlvl and math.abs(node.qmin - node.qlvl) >= 30 then
      level, color = 0, { r = .2, g = .8, b = 1 }
    end

    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. "] " or ""
    self.text:SetTextColor(color.r, color.g, color.b)
    self.text:SetText(showlevel .. title)
    self.level = tonumber(level)
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Mark As Done"]

    -- Fixed height for giver tracking - uses titlerowheight
    self:SetHeight(titlerowheight)
  elseif tracker.mode == "DATABASE_TRACKING" then
    self.text:SetText(title)
    self.text:SetTextColor(1,1,1,1)
    self.text:SetTextColor(pfMap.str2rgb(title))
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Shift-Click>|r Hide Nodes"]

    -- Fixed height for database tracking - uses titlerowheight
    self:SetHeight(titlerowheight)
  elseif tracker.mode == "PERK_TRACKING" then
    local perkData = node.perkData
    if not perkData then return end

    -- write expand state
    if not expand_states[title] then
      expand_states[title] = pfQuest_config["trackerexpand"] == "1" and 1 or 0
    end

    local expanded = expand_states[title] == 1 and true or nil

    -- Calculate progress percentage
    local cur = 0
    local max = perkData.task and perkData.task.req0 or 0
    local percent = 0

    -- Special case: "All Tasks Complete!" empty state should show 100%
    if not perkData.task and perkData.perkName == "All Tasks Complete!" then
      percent = 100
      cur = 1
      max = 1
    elseif max > 0 then
      cur = GetPerkTaskProg and GetPerkTaskProg(perkData.pivotId) or 0
      percent = cur / max * 100
      if cur >= max then percent = 100 end
    end

    -- Set title with progress
    local r, g, b = pfMap.tooltip:GetColor(cur, max > 0 and max or 1)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)

    self.tracked = true
    self.perc = percent
    self.text:SetText(string.format("%s |cffaaaaaa(%s%s%%|cffaaaaaa)|r", perkData.perkNameColored or title, colorperc, ceil(percent)))
    self.text:SetTextColor(1, 1, 1)
    self.tooltip = pfQuest_Loc["Perk Task"] or "|cff33ffcc<Click>|r Unfold/Fold Task"

    -- Initialize objectives table if needed
    if not self.objectives then
      self.objectives = {}
    end

    -- Track total height from objectives
    local objectivesHeight = 0

    -- Show task text as objective if expanded or in progress
    if perkData.text and (expanded or (percent > 0 and percent < 100)) then
      if not self.objectives[1] then
        self.objectives[1] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
        self.objectives[1]:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
        self.objectives[1]:SetJustifyH("LEFT")
        self.objectives[1]:SetJustifyV("TOP")  -- Top-align text to prevent gaps
        self.objectives[1]:SetWordWrap(true)
        self.objectives[1]:SetNonSpaceWrap(true)  -- Allow wrapping on any character if needed
      end

      -- Calculate available width for objectives (button width minus padding)
      local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
      local objectiveWidth = trackerWidth - 30  -- 20px left padding + 10px right padding

      -- Explicitly set width to force proper text wrapping
      self.objectives[1]:SetWidth(objectiveWidth)

      -- Position the objective (3px below title text, matching quests)
      local firstObjOffset = -(fontsize + 3)
      self.objectives[1]:ClearAllPoints()
      self.objectives[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)

      -- Format task text with progress
      local taskText = perkData.text or ""

      -- Handle $n (newline placeholder) - replace with space
      taskText = string.gsub(taskText, "%$n", " ")

      -- Fix color reset before % sign - move |r after the %
      taskText = string.gsub(taskText, "|r%%", "%%|r")

      -- Build the display text
      if max > 0 then
        -- Progress color for the numbers only
        local progressColor = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
        -- White dash, task text (has its own embedded colors that reset to white), progress in color
        taskText = string.format("|cffffffff- %s|r %s%d/%d|r", taskText, progressColor, cur, max)
      else
        taskText = "|cffffffff- " .. taskText .. "|r"
      end

      -- NOW set text - font string knows its width constraint and can wrap properly
      self.objectives[1]:SetText(taskText)
      -- Set base color to white - let embedded color codes handle the coloring
      self.objectives[1]:SetTextColor(1, 1, 1)
      self.objectives[1]:Show()

      -- Get actual wrapped height (no rounding - use real height)
      objectivesHeight = self.objectives[1]:GetHeight()
    else
      -- Hide objective if collapsed
      if self.objectives[1] then
        self.objectives[1]:Hide()
      end
    end

    -- Hide any extra objectives
    for i = 2, table.getn(self.objectives) do
      if self.objectives[i] then
        self.objectives[i]:Hide()
      end
    end

    -- Calculate total height (matching quest logic)
    local actualHeight
    if objectivesHeight > 0 then
      -- Expanded: title area + objectives + bottom padding for separation from next button
      local titleArea = fontsize + 3  -- Matches first objective offset
      local bottomPadding = 3
      actualHeight = titleArea + objectivesHeight + bottomPadding
    else
      -- Collapsed: just the title row
      actualHeight = titlerowheight
    end

    self:SetHeight(actualHeight)
  end

  -- sort all tracker entries
  table.sort(tracker.buttons, trackersort)

  self:Show()

  -- resize window and align buttons
  local height = 0
  local width = 100

  -- IMPORTANT: Use ipairs() to respect sort order, not pairs()!
  for bid = 1, table.getn(tracker.buttons) do
    local button = tracker.buttons[bid]
    button:ClearAllPoints()
    button:SetPoint("TOPRIGHT", tracker.scrollchild, "TOPRIGHT", 0, -height)
    button:SetPoint("TOPLEFT", tracker.scrollchild, "TOPLEFT", 0, -height)
    if not button.empty then
      if button.text:GetStringWidth() > width then
        width = button.text:GetStringWidth()
      end

      for id, objective in pairs(button.objectives) do
        if objective:IsShown() and objective:GetStringWidth() > width then
          width = objective:GetStringWidth()
        end
      end

      -- Accumulate height for next button positioning
      height = height + button:GetHeight()
    end
  end

  -- Get dimensions from config
  local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
  local maxTrackerHeight = tonumber(pfQuest_config["trackerheight"]) or 600

  -- Update scrollchild dimensions (this is the scrollable content area)
  -- Add small padding at bottom to prevent last objective from being cut off
  tracker.scrollchild:SetWidth(trackerWidth)
  tracker.scrollchild:SetHeight(height + 5)

  -- Calculate total content height (panel + quest buttons)
  local totalContentHeight = panelheight + height

  -- Set tracker height: grow with content but cap at max height
  local actualTrackerHeight = min(totalContentHeight, maxTrackerHeight)

  tracker:SetHeight(actualTrackerHeight)
  tracker:SetWidth(trackerWidth)

  -- Update scrollbar visibility and range
  tracker.UpdateScrollBar()

  -- Also update scrollbar on next frame to ensure frame dimensions have updated
  local delayedUpdate = CreateFrame("Frame")
  delayedUpdate:SetScript("OnUpdate", function()
    tracker.UpdateScrollBar()
    this:Hide()
  end)
end

function tracker.ButtonAdd(title, node)
  if not title or not node then return end

  local questid = title
  for qid, data in pairs(pfQuest.questlog) do
    if data.title == title then
      questid = qid
      break
    end
  end

  if tracker.mode == "QUEST_TRACKING" then -- skip everything that isn't in questlog
    if node.addon ~= "PFQUEST" then return end
    if not pfQuest.questlog or not pfQuest.questlog[questid] then return end
  elseif tracker.mode == "GIVER_TRACKING" then -- skip everything that isn't a questgiver
    if node.addon ~= "PFQUEST" then return end
    -- break on already taken quests
    if not pfQuest.questlog or pfQuest.questlog[questid] then return end
    -- every layer above 2 is not a questgiver
    if not node.layer or node.layer > 2 then return end
  elseif tracker.mode == "DATABASE_TRACKING" then -- skip everything that isn't db query
    if node.addon ~= "PFDB" then return end
  elseif tracker.mode == "PERK_TRACKING" then -- skip everything that isn't a perk task
    if node.addon ~= "PERK" then return end
  end

  local id

  -- skip duplicate titles
  for bid, button in pairs(tracker.buttons) do
    if button.title and button.title == title then
      if node.dummy or not node.texture then
        -- We found a node icon (1st prio)
        -- use the ID and update the button
        id = bid
        break
      elseif node.cluster and ( not button.node or button.node.texture ) then
        -- We found a cluster icon (2nd prio)
        -- set the id, but still try to find a node icon
        id = bid
      else
        -- got none of the above, therefore
        -- no icon update required, skip here
        return
      end
    end
  end

  if not id then
    -- use maxcount + 1 as default id
    id = table.getn(tracker.buttons)+1

    -- detect a reusable button
    for bid, button in pairs(tracker.buttons) do
      if button.empty then id = bid break end
    end
  end

  if id > 25 then return end

  -- create one if required
  if not tracker.buttons[id] then
    tracker.buttons[id] = CreateFrame("Button", "pfQuestMapButton"..id, tracker.scrollchild)
    tracker.buttons[id]:SetHeight(entryheight)

    tracker.buttons[id].bg = tracker.buttons[id]:CreateTexture(nil, "BACKGROUND")
    tracker.buttons[id].bg:SetTexture(1,1,1,.2)
    tracker.buttons[id].bg:SetAllPoints()
    tracker.buttons[id].bg:SetAlpha(0)

    tracker.buttons[id].text = tracker.buttons[id]:CreateFontString("pfQuestIDButton", "HIGH", "GameFontNormal")
    tracker.buttons[id].text:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
    tracker.buttons[id].text:SetJustifyH("LEFT")
    tracker.buttons[id].text:SetPoint("TOPLEFT", 16, -1)
    tracker.buttons[id].text:SetPoint("TOPRIGHT", -10, -1)
    tracker.buttons[id].text:SetWordWrap(true)  -- Enable wrapping

    tracker.buttons[id].icon = tracker.buttons[id]:CreateTexture(nil, "BORDER")
    tracker.buttons[id].icon:SetPoint("TOPLEFT", 2, -1)
    tracker.buttons[id].icon:SetWidth(12)
    tracker.buttons[id].icon:SetHeight(12)

    tracker.buttons[id]:RegisterEvent("QUEST_WATCH_UPDATE")
    tracker.buttons[id]:RegisterEvent("QUEST_LOG_UPDATE")
    tracker.buttons[id]:RegisterEvent("QUEST_FINISHED")

    tracker.buttons[id]:RegisterForClicks("LeftButtonUp", "RightButtonUp")

    tracker.buttons[id]:SetScript("OnEnter", tracker.ButtonEnter)
    tracker.buttons[id]:SetScript("OnLeave", tracker.ButtonLeave)
    tracker.buttons[id]:SetScript("OnUpdate", tracker.ButtonUpdate)
    tracker.buttons[id]:SetScript("OnEvent", tracker.ButtonEvent)
    tracker.buttons[id]:SetScript("OnClick", tracker.ButtonClick)
  end

  -- set required data
  tracker.buttons[id].empty = nil
  tracker.buttons[id].title = title
  tracker.buttons[id].node = node
  tracker.buttons[id].questid = questid

  -- reload button data
  tracker.ButtonEvent(tracker.buttons[id])
end

function tracker.Reset()
  -- Reset tracker to panel height initially (will grow as buttons are added)
  tracker:SetHeight(panelheight)

  for id, button in pairs(tracker.buttons) do
    button.level = nil
    button.title = nil
    button.perc = nil
    button.empty = true
    button:SetHeight(0)
    button:Hide()
  end

  -- Handle PERK_TRACKING mode
  if tracker.mode == "PERK_TRACKING" then
    -- Check if SynastriaCoreLib is available
    local SCL = LibStub and LibStub("SynastriaCoreLib-1.0", true)
    if SCL and SCL.Perks and SCL.Perks.GetActiveTasks then
      local activeTasks = SCL.Perks.GetActiveTasks()
      if activeTasks and table.getn(activeTasks) > 0 then
        for _, perkData in ipairs(activeTasks) do
          -- Store pivotId for progress lookup
          perkData.pivotId = SCL.Perks.GetAssign1 and SCL.Perks.GetAssign1(perkData.perkId) or 0

          local node = {
            addon = "PERK",
            perkData = perkData,
            texture = pfQuestConfig.path .. "\\img\\tracker_perks",
          }
          tracker.ButtonAdd(perkData.perkName, node)
        end
      else
        -- No active perk tasks - show congratulatory message
        local emptyNode = {
          addon = "PERK",
          perkData = {
            perkName = "All Tasks Complete!",
            perkNameColored = "|cff00ff000 Perk Tasks - Congrats!|r",
            text = nil,
            task = nil,
          },
          texture = pfQuestConfig.path .. "\\img\\tracker_perks",
        }
        tracker.ButtonAdd("All Tasks Complete!", emptyNode)
      end
    else
      -- SynastriaCoreLib not available
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest:|r SynastriaCoreLib not found. Perk tracking unavailable.")
    end
    return
  end

  -- add tracked quests (default behavior for other modes)
  local _, numQuests = GetNumQuestLogEntries()
  local found = 0

  -- iterate over all quests
  for qlogid=1,40 do
    local title, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
    if title and not header then
      local watched = IsQuestWatched(qlogid)
      if watched then
        local img = complete and pfQuestConfig.path.."\\img\\complete_c" or pfQuestConfig.path.."\\img\\complete"
        pfQuest.tracker.ButtonAdd(title, { dummy = true, addon = "PFQUEST", texture = img })
      end

      found = found + 1
      if found >= numQuests then
        break
      end
    end
  end
end


