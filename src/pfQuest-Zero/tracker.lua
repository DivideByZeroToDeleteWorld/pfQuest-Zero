-- multi api compat
local compat = pfQuestCompat

local fontsize = 12
local panelheight = 16
local entryheight = 20

-- Bullet font path (Source Code Pro Bold for special characters)
local bulletFontPath = "Interface\\AddOns\\pfQuest-Zero\\compat\\fonts\\SourceCodePro-Bold.ttf"

-- Helper function to get gradient color from red (rank 0) to green (rank 10)
local function GetRankColor(rank)
  rank = tonumber(rank) or 0
  if rank < 0 then rank = 0 end
  if rank > 10 then rank = 10 end

  -- Gradient from red (0) -> yellow (5) -> green (10)
  local r, g, b
  if rank <= 5 then
    -- Red to Yellow (0-5)
    r = 1.0
    g = rank / 5
    b = 0
  else
    -- Yellow to Green (5-10)
    r = 1.0 - ((rank - 5) / 5)
    g = 1.0
    b = 0
  end

  return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- Helper function to parse color config string "r,g,b,a" to hex color code
local function GetRepColorHex(configKey, defaultColor)
  local colorStr = pfQuest_config[configKey] or defaultColor
  if not colorStr then return "|cffffffff" end
  local r, g, b = strsplit(",", colorStr)
  r = tonumber(r) or 1
  g = tonumber(g) or 1
  b = tonumber(b) or 1
  return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end

-- Reputation level color mapping
local function GetRepLevelColor(level)
  local levelLower = string.lower(level or "")
  if levelLower == "hated" then
    return GetRepColorHex("rephatedcolor", "0.5,0,0,1")
  elseif levelLower == "hostile" then
    return GetRepColorHex("rephostilecolor", "0.8,0,0,1")
  elseif levelLower == "unfriendly" then
    return GetRepColorHex("repunfriendlycolor", "0.9,0.4,0,1")
  elseif levelLower == "neutral" then
    return GetRepColorHex("repneutralcolor", "1,1,0,1")
  elseif levelLower == "friendly" then
    return GetRepColorHex("repfriendlycolor", "0.4,0.9,0.2,1")
  elseif levelLower == "honored" then
    return GetRepColorHex("rephonoredcolor", "0.2,0.8,0.5,1")
  elseif levelLower == "revered" then
    return GetRepColorHex("repreveredcolor", "0.3,0.6,1,1")
  elseif levelLower == "exalted" then
    return GetRepColorHex("repexaltedcolor", "0.8,0.5,1,1")
  else
    return "|cffffffff"  -- White for unknown
  end
end

-- Format reputation objective text with colors
-- Format: "Faction Name: Required Level / Current Level"
local function FormatReputationText(text)
  -- Match pattern: "Faction: Level1 / Level2"
  local faction, reqLevel, curLevel = string.match(text, "^(.+):%s*(%w+)%s*/%s*(%w+)$")

  if faction and reqLevel and curLevel then
    local factionColor = GetRepColorHex("repfactioncolor", "0.4,0.8,1,1")
    local reqColor = GetRepLevelColor(reqLevel)
    local curColor = GetRepLevelColor(curLevel)

    return string.format("%s%s|r: %s%s|r |cffffffff/|r %s%s|r",
      factionColor, faction, reqColor, reqLevel, curColor, curLevel)
  end

  return nil  -- Not a reputation objective
end

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

-- Quest timer tracking
-- Stores {maxTime, startTime} for each timed quest by questid
-- Uses pfQuest_timers SavedVariable to persist across reloads
local questTimers = {}  -- Temporary until SavedVariable loads

-- Format seconds into mm:ss or h:mm:ss
local function FormatTime(seconds)
  if not seconds or seconds <= 0 then return "0:00" end
  seconds = math.floor(seconds)
  local hours = math.floor(seconds / 3600)
  local mins = math.floor((seconds % 3600) / 60)
  local secs = seconds % 60
  if hours > 0 then
    return string.format("%d:%02d:%02d", hours, mins, secs)
  else
    return string.format("%d:%02d", mins, secs)
  end
end

-- Create a text-based progress bar that empties as time runs out
-- Returns something like: [=========-] 2:34 / 10:00
local function FormatTimerBar(remaining, maxTime)
  local bracketColor = "|cff888888"  -- Gray for [ ] : and /
  local emptyColor = "|cff555555"    -- Darker gray for empty ---
  local maxColor = "|cff6699cc"      -- Muted blue for max time
  local showMax = pfQuest_config["showtimermax"] == "1"

  if not remaining or remaining <= 0 then
    local maxSuffix = ""
    if showMax then
      maxSuffix = bracketColor .. " / " .. maxColor .. FormatTime(maxTime)
    end
    return bracketColor .. "[" .. "|cffff0000" .. "----------" .. bracketColor .. "] " .. "|cffff0000" .. "0:00" .. maxSuffix .. "|r"
  end

  local barWidth = 10
  local pct = maxTime > 0 and (remaining / maxTime) or 0
  if pct > 1 then pct = 1 end
  local filled = math.floor(pct * barWidth + 0.5)
  local empty = barWidth - filled

  -- Gradient color based on time remaining percentage (for filled bar and numbers)
  local fillColor
  if pct > 0.5 then
    fillColor = "|cff00ff00"  -- Green
  elseif pct > 0.25 then
    fillColor = "|cffffff00"  -- Yellow
  elseif pct > 0.1 then
    fillColor = "|cffff8800"  -- Orange
  else
    fillColor = "|cffff0000"  -- Red
  end

  -- Build bar: [===-------]
  local bar = bracketColor .. "[" .. fillColor .. string.rep("=", filled) .. emptyColor .. string.rep("-", empty) .. bracketColor .. "]"

  -- Format remaining time with colored numbers
  local timeStr = FormatTime(remaining)
  local coloredTime = fillColor .. timeStr

  -- Optionally append max time
  local maxSuffix = ""
  if showMax then
    maxSuffix = bracketColor .. " / " .. maxColor .. FormatTime(maxTime)
  end

  return bar .. " " .. coloredTime .. maxSuffix .. "|r"
end

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
tracker:RegisterEvent("TRACKED_ACHIEVEMENT_LIST_CHANGED")
tracker:RegisterEvent("TRACKED_ACHIEVEMENT_UPDATE")
tracker:SetScript("OnEvent", function()
  -- Handle achievement tracking events - refresh tracker if in achievement mode
  if event == "TRACKED_ACHIEVEMENT_LIST_CHANGED" or event == "TRACKED_ACHIEVEMENT_UPDATE" then
    if tracker.mode == "ACHIEVEMENT_TRACKING" then
      pfMap:UpdateNodes()
    end
    return
  end

  -- Initialize quest timer storage (persists across reloads)
  if not pfQuest_timers then pfQuest_timers = {} end
  questTimers = pfQuest_timers

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
    local style = pfQuest_config["trackerfontstyle"]
    if style and style ~= "" then
      return style
    end
    return "OUTLINE"
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

      -- update bullet fonts (use Source Code Pro Bold for special characters)
      if button.objectiveBullets then
        for i, bullet in pairs(button.objectiveBullets) do
          if bullet then
            bullet:SetFont(bulletFontPath, fontsize, GetTrackerFontStyle())
          end
        end
      end

      -- update objective fonts for this button
      if button.objectives then
        for i, obj in pairs(button.objectives) do
          if obj then
            obj:SetFont(GetTrackerFont(), fontsize, GetTrackerFontStyle())
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
    else
      -- Register callback for perk data updates
      if SCL.RegisterCallback and SCL.Events and not tracker.sclCallbackRegistered then
        SCL.RegisterCallback(tracker, SCL.Events.CustomGameDataFinish, function()
          if tracker.mode == "PERK_TRACKING" then
            -- Delay the update slightly to ensure SCL has finished processing new data
            -- This prevents showing stale rank info when a perk levels up
            tracker.pendingPerkUpdate = GetTime() + 0.2
          end
        end)
        tracker.sclCallbackRegistered = true
      end
    end
  end

  -- Schedule a delayed font refresh to ensure fonts are applied after quest list populates
  if not tracker.fontRefreshScheduled then
    tracker.fontRefreshScheduled = true
    local fontRefreshFrame = CreateFrame("Frame")
    fontRefreshFrame.elapsed = 0
    fontRefreshFrame:SetScript("OnUpdate", function()
      this.elapsed = this.elapsed + arg1
      -- Wait 0.5 seconds to ensure quest list has populated
      if this.elapsed >= 0.5 then
        if _G.RefreshTrackerFonts then
          _G.RefreshTrackerFonts()
        end
        this:Hide()
      end
    end)
  end

  -- Apply tracker colors from config
  if _G.UpdateTrackerColors then
    _G.UpdateTrackerColors()
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
  -- Check for pending perk update (delayed to ensure SCL data is fresh)
  if tracker.pendingPerkUpdate and GetTime() >= tracker.pendingPerkUpdate then
    tracker.pendingPerkUpdate = nil
    if tracker.mode == "PERK_TRACKING" then
      pfMap:UpdateNodes()
    end
  end

  -- Use MEDIUM strata - above most UI but below map/dialogs
  if this.strata ~= "MEDIUM" then
    this:SetFrameStrata("MEDIUM")
    this.strata = "MEDIUM"
  end

  local backdropAlpha = this.backdrop:GetAlpha()
  local content = tracker.buttons[1] and not tracker.buttons[1].empty and true or nil
  local mouseOver = MouseIsOver(this)
  local barAlways = pfQuest_config["trackerbaralways"] == "1"
  local bgAlways = pfQuest_config["trackerbgalways"] == "1"

  -- Determine backdrop alpha goal (controlled by bgAlways)
  local backdropGoal
  if bgAlways then
    backdropGoal = 1
  elseif content and not mouseOver then
    backdropGoal = 0
  elseif not content and not mouseOver then
    backdropGoal = 0.5
  else
    backdropGoal = 1
  end

  -- Animate backdrop alpha
  if ceil(backdropAlpha*10) ~= ceil(backdropGoal*10) then
    this.backdrop:SetAlpha(backdropAlpha + ((backdropGoal - backdropAlpha) > 0 and .1 or (backdropGoal - backdropAlpha) < 0 and -.1 or 0))
  end

  -- Handle panel (config bar) visibility separately (controlled by barAlways)
  if tracker.panel then
    local panelGoal
    if barAlways then
      panelGoal = 1
    elseif content and not mouseOver then
      panelGoal = 0
    elseif not content and not mouseOver then
      panelGoal = 0.5
    else
      panelGoal = 1
    end

    local panelAlpha = tracker.panel:GetAlpha()
    if ceil(panelAlpha*10) ~= ceil(panelGoal*10) then
      tracker.panel:SetAlpha(panelAlpha + ((panelGoal - panelAlpha) > 0 and .1 or (panelGoal - panelAlpha) < 0 and -.1 or 0))
    end
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
tracker.backdrop:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 2,
  insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
tracker.backdrop:SetBackdropColor(0, 0, 0, 0.2)
tracker.backdrop:SetBackdropBorderColor(0.3, 0.3, 0.3, 0)

-- Helper to parse color from config string "r,g,b,a"
local function ParseTrackerColor(colorStr)
  if not colorStr then return 0, 0, 0, 1 end
  local r, g, b, a = strsplit(",", colorStr)
  return tonumber(r) or 0, tonumber(g) or 0, tonumber(b) or 0, tonumber(a) or 1
end

-- Helper to get border texture path from config
local function GetTrackerBorderPath(borderName)
  if not borderName or borderName == "None" then
    return nil
  end

  -- Try to get from LibSharedMedia
  if LibStub and LibStub:GetLibrary("LibSharedMedia-3.0", true) then
    local LSM = LibStub:GetLibrary("LibSharedMedia-3.0")
    local path = LSM:Fetch("border", borderName, true)
    if path then return path end
  end

  -- Fallback for "Solid"
  if borderName == "Solid" then
    return "Interface\\Buttons\\WHITE8X8"
  end

  return nil
end

-- Global function to update tracker colors from config
_G.UpdateTrackerColors = function()
  if not pfQuest_config then return end

  -- Get border settings
  local borderTexture = pfQuest_config["trackerbordertexture"] or "None"
  local borderWidth = tonumber(pfQuest_config["trackerborderwidth"]) or 2
  local borderPath = GetTrackerBorderPath(borderTexture)
  local hasBorder = borderPath ~= nil

  -- Update backdrop with new border settings
  local insetSize = hasBorder and math.max(1, math.floor(borderWidth / 2)) or 0
  tracker.backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = borderPath,
    tile = false, tileSize = 1, edgeSize = borderWidth,
    insets = { left = insetSize, right = insetSize, top = insetSize, bottom = insetSize }
  })

  -- Update backdrop color
  local bgR, bgG, bgB, bgA = ParseTrackerColor(pfQuest_config["trackerbgcolor"] or "0,0,0,0.2")
  tracker.backdrop:SetBackdropColor(bgR, bgG, bgB, bgA)

  -- Update border color
  local borderR, borderG, borderB, borderA = ParseTrackerColor(pfQuest_config["trackerbordercolor"] or "0.3,0.3,0.3,1")
  if hasBorder then
    tracker.backdrop:SetBackdropBorderColor(borderR, borderG, borderB, borderA)
  else
    tracker.backdrop:SetBackdropBorderColor(0, 0, 0, 0)
  end

  -- Update panel positioning based on border width
  if tracker.panel then
    local offset = hasBorder and borderWidth or 0
    tracker.panel:ClearAllPoints()
    tracker.panel:SetPoint("TOPLEFT", offset, -offset)
    tracker.panel:SetPoint("TOPRIGHT", -offset, -offset)
  end

  -- Update scrollframe positioning based on border width
  if tracker.scrollframe then
    local offset = hasBorder and borderWidth or 0
    tracker.scrollframe:ClearAllPoints()
    tracker.scrollframe:SetPoint("TOPLEFT", tracker.panel, "BOTTOMLEFT", 0, 0)
    tracker.scrollframe:SetPoint("BOTTOMRIGHT", tracker, "BOTTOMRIGHT", -offset, offset)
  end

  -- Update panel color
  if tracker.panel and tracker.panel.bg then
    local panelR, panelG, panelB, panelA = ParseTrackerColor(pfQuest_config["trackerpanelcolor"] or "0,0,0,0.5")
    tracker.panel.bg:SetTexture(panelR, panelG, panelB, panelA)
  end
end

do -- button panel
  tracker.panel = CreateFrame("Frame", nil, tracker.backdrop)
  tracker.panel:SetPoint("TOPLEFT", 0, 0)
  tracker.panel:SetPoint("TOPRIGHT", 0, 0)
  tracker.panel:SetHeight(panelheight)

  -- Panel background
  tracker.panel.bg = tracker.panel:CreateTexture(nil, "BACKGROUND")
  tracker.panel.bg:SetTexture(0, 0, 0, 0.5)
  tracker.panel.bg:SetAllPoints()

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

    b:SetScript("OnEnter", function()
      ShowTooltip()
      -- Hover color for right-side buttons
      if anchor == "TOPRIGHT" and not this.isPressed then
        this.icon:SetVertexColor(.2, 1, .8)
      end
    end)
    b:SetScript("OnLeave", function()
      HideTooltip()
      this.isPressed = false
      -- Reset color for right-side buttons
      if anchor == "TOPRIGHT" then
        this.icon:SetVertexColor(1, 1, 1)
      end
    end)
    b:SetScript("OnMouseDown", function()
      this.isPressed = true
      -- Wild pressed color - bright orange/gold
      this.icon:SetVertexColor(1, 0.6, 0)
    end)
    b:SetScript("OnMouseUp", function()
      this.isPressed = false
      if MouseIsOver(this) then
        if anchor == "TOPRIGHT" then
          this.icon:SetVertexColor(.2, 1, .8)
        else
          this.icon:SetVertexColor(.2, 1, .8)
        end
      else
        if anchor == "TOPRIGHT" then
          this.icon:SetVertexColor(1, 1, 1)
        end
      end
    end)

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

  tracker.btnachievements = CreateButton("achievements", "TOPLEFT", pfQuest_Loc["Show Tracked Achievements"] or "Show Tracked Achievements", function()
    if tracker.mode == "ACHIEVEMENT_TRACKING" then
      -- Already in achievement mode - toggle expand/collapse all
      local allCollapsed = true

      -- Check if all achievements are collapsed
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
      tracker.mode = "ACHIEVEMENT_TRACKING"
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

  -- Update icon based on lock state (defined first so it can be referenced)
  local function UpdateLockIcon()
    if pfQuest_config and pfQuest_config.lock then
      tracker.btnlock.icon:SetTexture(pfQuestConfig.path.."\\img\\lock_2")
      tracker.btnlock.icon:SetVertexColor(.2,1,.8)
    else
      tracker.btnlock.icon:SetTexture(pfQuestConfig.path.."\\img\\lock_1")
      tracker.btnlock.icon:SetVertexColor(1,1,1)
    end
  end

  tracker.btnlock:SetScript("OnEnter", function()
    ShowTooltip()
    this.icon:SetVertexColor(.2, 1, .8)
  end)
  tracker.btnlock:SetScript("OnLeave", function()
    HideTooltip()
    UpdateLockIcon()  -- Restore proper color based on lock state
  end)

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

  -- Update quest timer display in real-time
  if this.questTimerActive and this.timerIndex and this.qlogid and this.objectives and this.objectives[this.timerIndex] then
    -- Throttle updates to every 0.2 seconds
    local now = GetTime()
    if not this.timerLastUpdate or (now - this.timerLastUpdate) >= 0.2 then
      this.timerLastUpdate = now

      -- Must select quest first since GetQuestLogTimeLeft returns time for selected quest
      SelectQuestLogEntry(this.qlogid)
      local timeLeft = GetQuestLogTimeLeft and GetQuestLogTimeLeft() or nil
      if timeLeft and timeLeft > 0 then
        local qid = this.questid
        local maxTime = questTimers[qid] and questTimers[qid].maxTime or timeLeft

        local timerText = FormatTimerBar(timeLeft, maxTime)
        this.objectives[this.timerIndex]:SetText("|cffcccccc[T]|r " .. timerText)
      elseif this.questTimerActive then
        -- Timer just expired - show FAILED state and stop updating
        this.objectives[this.timerIndex]:SetText("|cffff0000[T] FAILED|r")
        this.questTimerActive = nil
      end
    end
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
  elseif arg1 == "MiddleButton" then
    -- Middle-click to hide nodes (changed from shift-click for server compatibility)
    -- Handle achievement mode - open achievement panel with shift-click instead
    if tracker.mode == "ACHIEVEMENT_TRACKING" and this.node and this.node.achievementData and IsShiftKeyDown() then
      if AchievementFrame_LoadUI then AchievementFrame_LoadUI() end
      if AchievementFrame and AchievementFrame:IsShown() then
        AchievementFrame:Hide()
      else
        ShowUIPanel(AchievementFrame)
        if AchievementFrame_SelectAchievement and this.node.achievementData.achievementID then
          AchievementFrame_SelectAchievement(this.node.achievementData.achievementID)
        end
      end
      return
    end

    -- mark as done if node is quest and not in questlog
    if this.node.questid and not this.node.qlogid then
      -- mark as done in history
      pfQuest_history[this.node.questid] = { time(), UnitLevel("player") }
      UIErrorsFrame:AddMessage(string.format("The Quest |cffffcc00[%s]|r (id:%s) is now marked as done.", this.title, this.node.questid), 1,1,1)
    end

    pfMap:DeleteNode(this.node.addon, this.title)
    pfMap:UpdateNodes()

    pfQuest.updateQuestGivers = true
  elseif IsShiftKeyDown() and tracker.mode == "ACHIEVEMENT_TRACKING" and this.node and this.node.achievementData then
    -- Shift-click opens achievement panel (kept for achievements only)
    if AchievementFrame_LoadUI then AchievementFrame_LoadUI() end
    if AchievementFrame and AchievementFrame:IsShown() then
      AchievementFrame:Hide()
    else
      ShowUIPanel(AchievementFrame)
      if AchievementFrame_SelectAchievement and this.node.achievementData.achievementID then
        AchievementFrame_SelectAchievement(this.node.achievementData.achievementID)
      end
    end
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

    -- write expand state (initial default only)
    if expand_states[title] == nil then
      expand_states[title] = pfQuest_config["trackerexpand"] == "1" and 1 or 0
    end

    -- Check for quest timer FIRST so we can use it in percent calculation and title coloring
    SelectQuestLogEntry(qlogid)
    local timeLeft = GetQuestLogTimeLeft and GetQuestLogTimeLeft() or nil
    local hasActiveTimer = timeLeft and timeLeft > 0
    local hasExpiredTimer = questTimers[qid] and (not timeLeft or timeLeft <= 0)
    local isTimedQuest = hasActiveTimer or hasExpiredTimer or questTimers[qid]

    if objectives and objectives > 0 then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")
        if objNum and objNeeded then
          max = max + objNeeded
          cur = cur + objNum
        elseif done then
          -- Objective is done but has no numeric format - count as 1/1
          max = max + 1
          cur = cur + 1
        else
          max = max + 1
        end
      end
    end

    -- Calculate percentage - for timed quests, ignore the 'complete' flag and use actual progress
    if hasExpiredTimer then
      -- Timer expired = FAILED, don't show as 100%
      if max > 0 then
        percent = cur/max*100
      else
        percent = 0
      end
    elseif (cur == max and max > 0) or (complete and not isTimedQuest) then
      cur, max = 1, 1
      percent = 100
    elseif max > 0 then
      percent = cur/max*100
    else
      percent = 0  -- No objectives yet
    end

    -- Auto-fold completed quests if option is enabled
    if percent >= 100 and pfQuest_config["foldcomplete"] == "1" then
      expand_states[title] = 0
    end

    -- Auto-unfold incomplete quests if option is enabled
    if percent < 100 and pfQuest_config["unfoldincomplete"] == "1" then
      expand_states[title] = 1
    end

    -- Determine expanded state for display
    local expanded = expand_states[title] == 1 and true or nil

    -- Set the title text FIRST so we can calculate its height
    local r,g,b = pfMap.tooltip:GetColor(cur, max)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)
    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. ( tag and "+" or "") .. "] " or ""

    -- Override colors if timer has expired (FAILED state)
    if hasExpiredTimer then
      colorperc = "|cffff0000"  -- Red for percentage
    end

    -- Set explicit width on title for proper word wrapping/truncation
    local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
    local titleWidth = trackerWidth - 26  -- 16px left padding + 10px right padding
    local truncateText = pfQuest_config["trackertruncate"] == "1"
    self.text:SetWidth(titleWidth)
    self.text:SetWordWrap(not truncateText)

    self.tracked = watched
    self.perc = percent
    self.text:SetText(string.format("%s%s |cffaaaaaa(%s%s%%|cffaaaaaa)|r", showlevel, title or "", colorperc or "", ceil(percent)))
    if hasExpiredTimer then
      self.text:SetTextColor(1, 0, 0)  -- Red title when timer failed
    else
      self.text:SetTextColor(color.r, color.g, color.b)
    end
    self.tooltip = pfQuest_Loc["|cff33ffcc<Click>|r Unfold/Fold Objectives\n|cff33ffcc<Right-Click>|r Show In QuestLog\n|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Middle-Click>|r Hide Nodes"]

    -- Get actual title height after text is set (for wrapped titles)
    local titleHeight = self.text:GetHeight()

    -- Initialize objectives table if it doesn't exist
    if not self.objectives then
      self.objectives = {}
    end

    -- Track total height accumulated by objectives
    local objectivesHeight = 0
    local visibleObjectives = 0

    -- Initialize bullet storage
    self.objectiveBullets = self.objectiveBullets or {}
    for bid, bullet in pairs(self.objectiveBullets) do bullet:Hide() end

    -- Position objectives using anchor chains for proper wrapping
    if objectives and (expanded or ( percent > 0 and percent < 100 )) then
      for i=1, objectives, 1 do
        local text, _, done = GetQuestLogLeaderBoard(i, qlogid)
        local _, _, obj, objNum, objNeeded = strfind(gsub(text, "\239\188\154", ":"), "(.*):%s*([%d]+)%s*/%s*([%d]+)")

        -- Create bullet FontString using Source Code Pro Bold for special characters
        if not self.objectiveBullets[i] then
          self.objectiveBullets[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectiveBullets[i]:SetFont(bulletFontPath, fontsize, _G.GetTrackerFontStyle())
          self.objectiveBullets[i]:SetJustifyH("LEFT")
          self.objectiveBullets[i]:SetJustifyV("TOP")
        end

        -- Create objective text FontString using regular tracker font
        if not self.objectives[i] then
          self.objectives[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectives[i]:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
          self.objectives[i]:SetJustifyH("LEFT")
          self.objectives[i]:SetJustifyV("TOP")
        end

        -- Set word wrap based on config (must be set each time, not just at creation)
        self.objectives[i]:SetWordWrap(not truncateText)
        self.objectives[i]:SetNonSpaceWrap(not truncateText)

        -- Get bullet character from config
        local bullet = pfQuest_config["objectivebullet"] or "-"
        local showBullet = bullet ~= "None" and bullet ~= ""

        -- Calculate available width for objectives (button width minus padding minus bullet width if shown)
        local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
        local bulletWidth = showBullet and 12 or 0  -- Fixed width for bullet character, 0 if hidden
        local objectiveWidth = trackerWidth - 30 - bulletWidth  -- 20px left padding + 10px right padding + bullet

        -- Set bullet text if shown
        if showBullet then
          self.objectiveBullets[i]:SetText(bullet)
          self.objectiveBullets[i]:SetTextColor(1, 1, 1)
          self.objectiveBullets[i]:SetFont(bulletFontPath, fontsize, _G.GetTrackerFontStyle())
        end

        -- Explicitly set width for text wrapping
        self.objectives[i]:SetWidth(objectiveWidth)

        -- Position based on whether bullet is shown
        if showBullet then
          -- Position the bullet
          self.objectiveBullets[i]:ClearAllPoints()
          if i == 1 then
            local firstObjOffset = -(titleHeight + 3)
            self.objectiveBullets[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)
          else
            -- Anchor to bottom of previous objective row
            self.objectiveBullets[i]:SetPoint("TOPLEFT", self.objectives[i-1], "BOTTOMLEFT", -bulletWidth, -2)
          end

          -- Position the objective text next to the bullet
          self.objectives[i]:ClearAllPoints()
          self.objectives[i]:SetPoint("TOPLEFT", self.objectiveBullets[i], "TOPLEFT", bulletWidth, 0)
          self.objectiveBullets[i]:Show()
        else
          -- No bullet - position objective directly
          self.objectives[i]:ClearAllPoints()
          if i == 1 then
            local firstObjOffset = -(titleHeight + 3)
            self.objectives[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)
          else
            self.objectives[i]:SetPoint("TOPLEFT", self.objectives[i-1], "BOTTOMLEFT", 0, -2)
          end
          self.objectiveBullets[i]:Hide()
        end

        -- Set text AFTER width is constrained so wrapping calculates correctly
        if objNum and objNeeded then
          local r,g,b = pfMap.tooltip:GetColor(objNum, objNeeded)
          self.objectives[i]:SetTextColor(r+.2, g+.2, b+.2)

          -- Format objective based on config options
          local reqFirst = pfQuest_config["objectivereqfirst"] == "1"
          local reqBrackets = pfQuest_config["objectivereqbrackets"] == "1"
          local reqText = reqBrackets and string.format("[%s/%s]", objNum, objNeeded) or string.format("%s/%s", objNum, objNeeded)

          if reqFirst then
            self.objectives[i]:SetText(string.format("%s |cffffffff%s", reqText, obj))
          else
            self.objectives[i]:SetText(string.format("%s: %s", obj, reqText))
          end
        else
          -- Try to format as reputation objective first
          local repText = FormatReputationText(text)
          if repText then
            self.objectives[i]:SetTextColor(1, 1, 1)  -- White base for colored text
            self.objectives[i]:SetText(repText)
          else
            self.objectives[i]:SetTextColor(.8,.8,.8)
            self.objectives[i]:SetText(text)
          end
        end

        -- Note: bullet visibility is handled in the positioning block above (Show/Hide based on showBullet)
        self.objectives[i]:Show()
        visibleObjectives = i

        -- Get actual wrapped height (no rounding - use real height)
        local wrappedHeight = self.objectives[i]:GetHeight()
        objectivesHeight = objectivesHeight + wrappedHeight + (i > 1 and 2 or 0)  -- Add 2px spacing between objectives
      end
    end

    -- Store quest timer info (always track, even when collapsed, so we don't lose max time)
    -- timeLeft was already retrieved earlier for title coloring
    if timeLeft and timeLeft > 0 then
      if not questTimers[qid] then
        questTimers[qid] = { maxTime = timeLeft, startTime = GetTime() }
      else
        -- Update max if we see a higher value (quest was just accepted)
        if timeLeft > questTimers[qid].maxTime then
          questTimers[qid].maxTime = timeLeft
          questTimers[qid].startTime = GetTime()
        end
      end
    end

    -- Display timer bar - optionally collapse with objectives
    local hasTimer = hasActiveTimer or hasExpiredTimer
    local showTimer
    if pfQuest_config["collapsetimer"] == "1" then
      -- Collapse with objectives: show if expanded OR quest in progress
      showTimer = hasTimer and (expanded or (percent > 0 and percent < 100))
    else
      -- Always show timer if active/expired (don't collapse)
      showTimer = hasTimer
    end

    if showTimer then
      local maxTime = questTimers[qid].maxTime

      -- Create timer font string if needed (use a special index)
      local timerIndex = 100  -- Use high index to not conflict with objectives
      if not self.objectives[timerIndex] then
        self.objectives[timerIndex] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
        self.objectives[timerIndex]:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
        self.objectives[timerIndex]:SetJustifyH("LEFT")
        self.objectives[timerIndex]:SetJustifyV("TOP")
        self.objectives[timerIndex]:SetWordWrap(false)
      end

      -- Calculate width
      local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
      local objectiveWidth = trackerWidth - 30

      self.objectives[timerIndex]:SetWidth(objectiveWidth)
      self.objectives[timerIndex]:ClearAllPoints()

      -- Position timer below last objective or below title if no objectives
      if visibleObjectives > 0 then
        self.objectives[timerIndex]:SetPoint("TOPLEFT", self.objectives[visibleObjectives], "BOTTOMLEFT", 0, -4)
      else
        local firstObjOffset = -(titleHeight + 3)
        self.objectives[timerIndex]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)
      end

      -- Format and display timer
      local timerText
      if hasExpiredTimer then
        -- Timer expired - show FAILED in red (including [T])
        timerText = "|cffff0000[T] FAILED|r"
        self.questTimerActive = nil  -- Stop updating
      else
        timerText = "|cffcccccc[T]|r " .. FormatTimerBar(timeLeft, maxTime)
        self.questTimerActive = true  -- Keep updating
      end
      self.objectives[timerIndex]:SetText(timerText)
      self.objectives[timerIndex]:SetTextColor(1, 1, 1)
      self.objectives[timerIndex]:Show()

      -- Store reference for OnUpdate refresh
      self.timerIndex = timerIndex
      self.qlogid = qlogid

      -- Add timer height (with extra spacing to separate from objectives)
      local timerHeight = self.objectives[timerIndex]:GetHeight()
      local timerSpacing = visibleObjectives > 0 and 4 or 0
      objectivesHeight = objectivesHeight + timerHeight + timerSpacing
    else
      -- Timer not shown (collapsed or expired) - hide timer element and clear active flag
      if self.objectives and self.objectives[100] then
        self.objectives[100]:Hide()
      end
      self.questTimerActive = nil

      -- Only clean up stored timer data if timer actually expired (not just collapsed)
      if not timeLeft or timeLeft <= 0 then
        if questTimers[qid] then
          questTimers[qid] = nil
        end
      end
    end

    -- Hide any old objectives that are no longer needed (but not timer at index 100)
    for i = visibleObjectives + 1, table.getn(self.objectives) do
      if self.objectives[i] and i ~= 100 then
        self.objectives[i]:Hide()
      end
    end

    -- Calculate total height
    local actualHeight
    if objectivesHeight > 0 then
      -- Expanded: title area + objectives + bottom padding for separation from next button
      local titleArea = titleHeight + 3  -- Use actual title height + padding
      local bottomPadding = 3
      actualHeight = titleArea + objectivesHeight + bottomPadding
    else
      -- Collapsed: just the title row (use actual wrapped title height + padding)
      actualHeight = titleHeight + 5
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

    -- Set explicit width on title for proper word wrapping/truncation
    local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
    local titleWidth = trackerWidth - 26  -- 16px left padding + 10px right padding
    local truncateText = pfQuest_config["trackertruncate"] == "1"
    self.text:SetWidth(titleWidth)
    self.text:SetWordWrap(not truncateText)

    local showlevel = pfQuest_config["trackerlevel"] == "1" and "[" .. ( level or "??" ) .. "] " or ""
    self.text:SetTextColor(color.r, color.g, color.b)
    self.text:SetText(showlevel .. title)
    self.level = tonumber(level)
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Middle-Click>|r Mark As Done"]

    -- Use actual wrapped title height + padding
    local titleHeight = self.text:GetHeight()
    self:SetHeight(titleHeight + 5)
  elseif tracker.mode == "DATABASE_TRACKING" then
    -- Set explicit width on title for proper word wrapping/truncation
    local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
    local titleWidth = trackerWidth - 26  -- 16px left padding + 10px right padding
    local truncateText = pfQuest_config["trackertruncate"] == "1"
    self.text:SetWidth(titleWidth)
    self.text:SetWordWrap(not truncateText)

    self.text:SetText(title)
    self.text:SetTextColor(1,1,1,1)
    self.text:SetTextColor(pfMap.str2rgb(title))
    self.tooltip = pfQuest_Loc["|cff33ffcc<Ctrl-Click>|r Show Map / Toggle Color\n|cff33ffcc<Middle-Click>|r Hide Nodes"]

    -- Use actual wrapped title height + padding
    local titleHeight = self.text:GetHeight()
    self:SetHeight(titleHeight + 5)
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

    -- Set explicit width on title for proper word wrapping/truncation
    local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
    local titleWidth = trackerWidth - 26  -- 16px left padding + 10px right padding
    local truncateText = pfQuest_config["trackertruncate"] == "1"
    self.text:SetWidth(titleWidth)
    self.text:SetWordWrap(not truncateText)

    self.tracked = true
    self.perc = percent

    -- Add rank display with gradient color (skip for "All Tasks Complete!" message)
    local rankText = ""
    if perkData.perkLevel then
      local perkLevel = perkData.perkLevel or 0
      local rankColor = GetRankColor(perkLevel)
      rankText = string.format(" %s[Rank %d]|r", rankColor, perkLevel)
    end

    self.text:SetText(string.format("%s%s |cffaaaaaa(%s%s%%|cffaaaaaa)|r", perkData.perkNameColored or title, rankText, colorperc, ceil(percent)))
    self.text:SetTextColor(1, 1, 1)
    self.tooltip = pfQuest_Loc["Perk Task"] or "|cff33ffcc<Click>|r Unfold/Fold Task"

    -- Get actual title height after text is set (for wrapped titles)
    local titleHeight = self.text:GetHeight()

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
        self.objectives[1]:SetJustifyV("TOP")
      end

      -- Set word wrap based on config
      self.objectives[1]:SetWordWrap(not truncateText)
      self.objectives[1]:SetNonSpaceWrap(not truncateText)

      -- Calculate available width for objectives (button width minus padding)
      local objectiveWidth = trackerWidth - 30  -- 20px left padding + 10px right padding

      -- Explicitly set width to force proper text wrapping/truncation
      self.objectives[1]:SetWidth(objectiveWidth)

      -- Position the objective (below title using actual title height)
      local firstObjOffset = -(titleHeight + 3)
      self.objectives[1]:ClearAllPoints()
      self.objectives[1]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, firstObjOffset)

      -- Format task text with progress
      local taskText = perkData.text or ""

      -- Handle $n (newline placeholder) - replace with space
      taskText = string.gsub(taskText, "%$n", " ")

      -- Handle $d and $#d (damage placeholders) - remove them since we don't have spell data
      taskText = string.gsub(taskText, "%$%d*d", "")

      -- Handle $r (relative level placeholder) - player level minus 3
      local playerLevel = UnitLevel("player") or 80
      local relativeLevel = playerLevel - 3
      taskText = string.gsub(taskText, "%$r%+?", tostring(relativeLevel))

      -- Handle $#s (plural markers like $1s) - just replace with 's'
      taskText = string.gsub(taskText, "%$%d+s", "s")

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
      local titleArea = titleHeight + 3  -- Use actual title height + padding
      local bottomPadding = 3
      actualHeight = titleArea + objectivesHeight + bottomPadding
    else
      -- Collapsed: just the title row (use actual wrapped title height + padding)
      actualHeight = titleHeight + 5
    end

    self:SetHeight(actualHeight)
  elseif tracker.mode == "ACHIEVEMENT_TRACKING" then
    local achievementData = node.achievementData
    if not achievementData then return end

    -- write expand state
    if not expand_states[title] then
      expand_states[title] = pfQuest_config["trackerexpand"] == "1" and 1 or 0
    end

    local expanded = expand_states[title] == 1 and true or nil

    -- Calculate progress percentage
    local numCriteria = achievementData.numCriteria or 0
    local totalCompleted = achievementData.totalCompleted or 0
    local percent = 0

    if achievementData.completed then
      percent = 100
    elseif numCriteria > 0 then
      percent = (totalCompleted / numCriteria) * 100
    end

    -- Set title with progress
    local r, g, b = pfMap.tooltip:GetColor(totalCompleted, numCriteria > 0 and numCriteria or 1)
    local colorperc = string.format("|cff%02x%02x%02x", r*255, g*255, b*255)

    -- Set explicit width on title for proper word wrapping/truncation
    local trackerWidth = tonumber(pfQuest_config["trackerwidth"]) or 300
    local titleWidth = trackerWidth - 26  -- 16px left padding + 10px right padding
    local truncateText = pfQuest_config["trackertruncate"] == "1"
    self.text:SetWidth(titleWidth)
    self.text:SetWordWrap(not truncateText)

    -- Color the achievement name yellow (achievement color)
    local achievementColor = achievementData.completed and "|cff00ff00" or "|cffffff00"

    self.tracked = true
    self.perc = percent

    -- Don't show percentage for empty state
    if achievementData.name == "No Achievements Tracked" then
      self.text:SetText("|cffaaaaaa" .. achievementData.name .. "|r")
    else
      self.text:SetText(string.format("%s%s|r |cffaaaaaa(%s%s%%|cffaaaaaa)|r", achievementColor, achievementData.name or title, colorperc, ceil(percent)))
    end
    self.text:SetTextColor(1, 1, 1)
    self.tooltip = "|cff33ffcc<Click>|r Expand/Collapse\n|cff33ffcc<Shift-Click>|r Open Achievement Panel"

    -- Get actual title height after text is set (for wrapped titles)
    local titleHeight = self.text:GetHeight()

    -- Initialize objectives table if needed
    if not self.objectives then
      self.objectives = {}
    end

    -- Track total height from objectives
    local objectivesHeight = 0

    -- Show criteria as objectives if expanded or in progress
    local criteria = achievementData.criteria or {}
    if (expanded or (percent > 0 and percent < 100)) and table.getn(criteria) > 0 then
      local objectiveWidth = trackerWidth - 30

      for i, criterion in ipairs(criteria) do
        if not self.objectives[i] then
          self.objectives[i] = self:CreateFontString(nil, "HIGH", "GameFontNormal")
          self.objectives[i]:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
          self.objectives[i]:SetJustifyH("LEFT")
          self.objectives[i]:SetJustifyV("TOP")
        end

        -- Set word wrap based on config
        self.objectives[i]:SetWordWrap(not truncateText)
        self.objectives[i]:SetNonSpaceWrap(not truncateText)
        self.objectives[i]:SetWidth(objectiveWidth)

        -- Position the objective (first uses title height, rest chain)
        if i > 1 then
          self.objectives[i]:ClearAllPoints()
          self.objectives[i]:SetPoint("TOPLEFT", self.objectives[i-1], "BOTTOMLEFT", 0, -2)
        else
          local objOffset = -(titleHeight + 3)
          self.objectives[i]:ClearAllPoints()
          self.objectives[i]:SetPoint("TOPLEFT", self, "TOPLEFT", 20, objOffset)
        end

        -- Format criterion text with progress
        local criterionText = criterion.name or ""
        local cr, cg, cb

        if criterion.completed then
          cr, cg, cb = 0, 1, 0  -- Green for completed
          criterionText = string.format("|cff00ff00- %s|r", criterionText)
        elseif criterion.reqQuantity and criterion.reqQuantity > 1 then
          cr, cg, cb = pfMap.tooltip:GetColor(criterion.quantity or 0, criterion.reqQuantity)
          local progressColor = string.format("|cff%02x%02x%02x", cr*255, cg*255, cb*255)
          criterionText = string.format("|cffffffff- %s:|r %s%d/%d|r", criterionText, progressColor, criterion.quantity or 0, criterion.reqQuantity)
        else
          cr, cg, cb = 0.7, 0.7, 0.7  -- Gray for incomplete
          criterionText = string.format("|cffaaaaaa- %s|r", criterionText)
        end

        self.objectives[i]:SetText(criterionText)
        self.objectives[i]:SetTextColor(1, 1, 1)
        self.objectives[i]:Show()

        objectivesHeight = objectivesHeight + self.objectives[i]:GetHeight() + (i > 1 and 2 or 0)
      end

      -- Hide extra objectives
      for i = table.getn(criteria) + 1, table.getn(self.objectives) do
        if self.objectives[i] then
          self.objectives[i]:Hide()
        end
      end
    else
      -- Hide all objectives if collapsed
      for i = 1, table.getn(self.objectives) do
        if self.objectives[i] then
          self.objectives[i]:Hide()
        end
      end
    end

    -- Calculate total height
    local actualHeight
    if objectivesHeight > 0 then
      local titleArea = titleHeight + 3  -- Use actual title height + padding
      local bottomPadding = 3
      actualHeight = titleArea + objectivesHeight + bottomPadding
    else
      -- Collapsed: just the title row (use actual wrapped title height + padding)
      actualHeight = titleHeight + 5
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

  -- Calculate total content height (panel + quest buttons + bottom padding)
  local bottomPadding = 2  -- Small gap so text doesn't touch frame bottom
  local totalContentHeight = panelheight + height + bottomPadding

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
  elseif tracker.mode == "ACHIEVEMENT_TRACKING" then -- skip everything that isn't an achievement
    if node.addon ~= "ACHIEVEMENT" then return end
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

  -- Always ensure font is set (handles buttons created before font was configured)
  if tracker.buttons[id].text then
    tracker.buttons[id].text:SetFont(_G.GetTrackerFont(), fontsize, _G.GetTrackerFontStyle())
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

  -- Handle ACHIEVEMENT_TRACKING mode
  if tracker.mode == "ACHIEVEMENT_TRACKING" then
    local trackedAchievements = {}

    -- Use Blizzard API to get tracked achievements
    if GetTrackedAchievements then
      trackedAchievements = { GetTrackedAchievements() }
    end

    if trackedAchievements and table.getn(trackedAchievements) > 0 then
      for _, achievementID in ipairs(trackedAchievements) do
        local id, name, points, completed, month, day, year, description, flags, icon, rewardText, isGuild, wasEarnedByMe, earnedBy = GetAchievementInfo(achievementID)
        if name then
          -- Build criteria data
          local numCriteria = GetAchievementNumCriteria(achievementID)
          local criteria = {}
          local totalCompleted = 0

          for i = 1, numCriteria do
            local criteriaName, criteriaType, criteriaCompleted, quantity, reqQuantity, charName, flags, assetID, quantityString, criteriaID = GetAchievementCriteriaInfo(achievementID, i)
            if criteriaName and criteriaName ~= "" then
              table.insert(criteria, {
                name = criteriaName,
                completed = criteriaCompleted,
                quantity = quantity,
                reqQuantity = reqQuantity,
                quantityString = quantityString,
              })
              if criteriaCompleted then
                totalCompleted = totalCompleted + 1
              end
            end
          end

          local achievementData = {
            achievementID = achievementID,
            name = name,
            description = description,
            points = points,
            completed = completed,
            icon = icon,
            criteria = criteria,
            numCriteria = numCriteria,
            totalCompleted = totalCompleted,
          }

          local node = {
            addon = "ACHIEVEMENT",
            achievementData = achievementData,
            texture = pfQuestConfig.path .. "\\img\\tracker_achievements",
          }
          tracker.ButtonAdd(name, node)
        end
      end
    else
      -- No tracked achievements
      local emptyNode = {
        addon = "ACHIEVEMENT",
        achievementData = {
          name = "No Achievements Tracked",
          description = "Track achievements from the Achievement panel (Y)",
          criteria = {},
          numCriteria = 0,
          totalCompleted = 0,
          completed = false,
        },
        texture = pfQuestConfig.path .. "\\img\\tracker_achievements",
      }
      tracker.ButtonAdd("No Achievements Tracked", emptyNode)
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


