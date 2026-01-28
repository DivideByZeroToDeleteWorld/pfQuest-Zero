-- multi api compat
local compat = pfQuestCompat

-- ============================================================================
-- Debug Output Frame - Scrollable, copyable text window for diagnostic output
-- ============================================================================
local debugFrame = CreateFrame("Frame", "pfQuestDebugFrame", UIParent)
debugFrame:Hide()
debugFrame:SetWidth(700)
debugFrame:SetHeight(500)
debugFrame:SetPoint("CENTER", 0, 0)
debugFrame:SetFrameStrata("DIALOG")
debugFrame:SetMovable(true)
debugFrame:EnableMouse(true)
debugFrame:SetClampedToScreen(true)
debugFrame:RegisterForDrag("LeftButton")
debugFrame:SetScript("OnDragStart", function() this:StartMoving() end)
debugFrame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
debugFrame:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
debugFrame:SetBackdropColor(0.05, 0.05, 0.05, 0.95)
debugFrame:SetBackdropBorderColor(0.2, 0.8, 0.5, 1)

-- Title bar
local titleBar = CreateFrame("Frame", nil, debugFrame)
titleBar:SetHeight(24)
titleBar:SetPoint("TOPLEFT", 0, 0)
titleBar:SetPoint("TOPRIGHT", 0, 0)
titleBar:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
})
titleBar:SetBackdropColor(0.1, 0.3, 0.2, 1)

local titleText = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
titleText:SetPoint("LEFT", 8, 0)
titleText:SetText("|cff33ffccpfQuest|r Debug Output")
debugFrame.titleText = titleText

-- Close button
local closeBtn = CreateFrame("Button", nil, debugFrame)
closeBtn:SetWidth(20)
closeBtn:SetHeight(20)
closeBtn:SetPoint("TOPRIGHT", -4, -2)
closeBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
closeBtn:SetBackdropColor(0.6, 0.1, 0.1, 1)
closeBtn:SetBackdropBorderColor(0.8, 0.2, 0.2, 1)
local closeTxt = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeTxt:SetPoint("CENTER", 0, 0)
closeTxt:SetText("X")
closeBtn:SetScript("OnClick", function() debugFrame:Hide() end)

-- Hint text
local hintText = debugFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hintText:SetPoint("BOTTOMLEFT", 8, 4)
hintText:SetText("|cff888888Ctrl+A to select all, Ctrl+C to copy|r")

-- Scroll frame
local scrollFrame = CreateFrame("ScrollFrame", "pfQuestDebugScrollFrame", debugFrame, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 8, -28)
scrollFrame:SetPoint("BOTTOMRIGHT", -30, 20)

-- Edit box inside scroll frame
local editBox = CreateFrame("EditBox", "pfQuestDebugEditBox", scrollFrame)
editBox:SetMultiLine(true)
editBox:SetAutoFocus(false)
editBox:SetFontObject(GameFontHighlightSmall)
editBox:SetWidth(650)
editBox:SetScript("OnEscapePressed", function() this:ClearFocus(); debugFrame:Hide() end)
-- Prevent editing - reset text if user types
editBox:SetScript("OnTextChanged", function()
  if editBox._locked then
    this:SetText(editBox._lockedText or "")
  end
end)
scrollFrame:SetScrollChild(editBox)

debugFrame.editBox = editBox
debugFrame.scrollFrame = scrollFrame

-- Strip WoW color codes for plain text output
local function StripColors(str)
  if not str then return "" end
  str = string.gsub(str, "|c%x%x%x%x%x%x%x%x", "")
  str = string.gsub(str, "|r", "")
  return str
end

-- Set the debug frame text and show it
function pfQuestDebugFrame_Show(title, lines)
  local text = table.concat(lines, "\n")
  debugFrame.editBox._locked = false
  debugFrame.editBox:SetText(text)
  debugFrame.editBox._lockedText = text
  debugFrame.editBox._locked = true
  debugFrame.titleText:SetText("|cff33ffccpfQuest|r " .. (title or "Debug Output"))
  debugFrame:Show()
  debugFrame.editBox:SetCursorPosition(0)
end

-- ============================================================================

SLASH_PFDB1, SLASH_PFDB2, SLASH_PFDB3, SLASH_PFDB4 = "/db", "/shagu", "/pfquest", "/pfdb"
SlashCmdList["PFDB"] = function(input, editbox)
  local params = {}
  local meta = { ["addon"] = "PFDB" }

  if (input == "" or input == nil) then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest (v" .. pfQuestConfig.version .. "):")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff lock |cffcccccc - " .. pfQuest_Loc["Lock map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff tracker |cffcccccc - " .. pfQuest_Loc["Show map tracker"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff journal |cffcccccc - " .. pfQuest_Loc["Show quest journal"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff arrow |cffcccccc - " .. pfQuest_Loc["Show quest arrow"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff show |cffcccccc - " .. pfQuest_Loc["Show database interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff config |cffcccccc - " .. pfQuest_Loc["Show configuration interface"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff locale |cffcccccc - " .. pfQuest_Loc["Display addon locales"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff track <list>|cffcccccc - " .. pfQuest_Loc["Show available tracking lists"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff unit <unit> |cffcccccc - " .. pfQuest_Loc["Search unit"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff object <gameobject> |cffcccccc - " .. pfQuest_Loc["Search object"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff item <item> |cffcccccc - " .. pfQuest_Loc["Search loot"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff vendor <item> |cffcccccc - " .. pfQuest_Loc["Search item vendors"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quest <questname> |cffcccccc - " .. pfQuest_Loc["Show specific quest"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff quests |cffcccccc - " .. pfQuest_Loc["Show all quests on map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff clean |cffcccccc - " .. pfQuest_Loc["Clean Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff reset |cffcccccc - " .. pfQuest_Loc["Reset Map"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff debug [on|off|full] |cffcccccc - " .. "Toggle debug mode + pipeline tracing")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff scanzone |cffcccccc - " .. "Scan current zone: data, quests, entity counts, trace log")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff trace [quests|tracking|failures|all|clear] |cffcccccc - " .. "Show pipeline trace log (filtered)")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff scan |cffcccccc - " .. pfQuest_Loc["Scan the server for custom items"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff query |cffcccccc - " .. pfQuest_Loc["Query the server for completed quests"])
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff cal begin |cffcccccc - " .. "Start subzone calibration (suggests NPCs)")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff cal <npc> |cffcccccc - " .. "Add calibration point at NPC location")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff cal done |cffcccccc - " .. "Calculate transform from calibration points")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/db|cffffffff cal status |cffcccccc - " .. "Show current calibration progress")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/pfqdb|cffffffff |cffcccccc - " .. "Open database source selector panel")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/pfcompare|cffffffff [zone] |cffcccccc - " .. "Open database compare panel")
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc/pfqedit|cffffffff [type] [id] |cffcccccc - " .. "Open database editor panel")
    return
  end

  local commandlist = { }
  local command

  for command in compat.gfind(input, "[^ ]+") do
    table.insert(commandlist, command)
  end

  local arg1, arg2 = commandlist[1], ""

  -- handle whitespace mob- and item names correctly
  for i in pairs(commandlist) do
    if (i ~= 1) then
      arg2 = arg2 .. commandlist[i]
      if (commandlist[i+1] ~= nil) then
        arg2 = arg2 .. " "
      end
    end
  end

  -- argument: debug
  if (arg1 == "debug") then
    -- Toggle debug mode on/off
    if arg2 == "on" then
      pfQuest_config.debug = true
      pfDatabase.trace.enabled = true
      pfDatabase:TraceClear()
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Debug Mode: |cff33ff33ON|r (pipeline tracing enabled)")
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest|r: Trace log cleared. Do |cff33ffcc/reload|r then |cff33ffcc/db scanzone|r to see pipeline results.")
      return
    elseif arg2 == "off" then
      pfQuest_config.debug = false
      pfDatabase.trace.enabled = false
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Debug Mode: |cffff3333OFF|r (pipeline tracing disabled)")
      return
    elseif arg2 == "" or arg2 == nil then
      -- No argument = toggle
      pfQuest_config.debug = not pfQuest_config.debug
      pfDatabase.trace.enabled = pfQuest_config.debug
      if pfQuest_config.debug then pfDatabase:TraceClear() end
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Debug Mode: " .. (pfQuest_config.debug and "|cff33ff33ON|r" or "|cffff3333OFF|r"))
      return
    end

    -- If arg2 is "full" or "diag", run full diagnostics
    if arg2 ~= "full" and arg2 ~= "diag" and arg2 ~= "diagnostics" then
      return
    end

    -- Use a reliable chat output function
    local function chatMsg(msg)
      if ChatFrame1 then
        ChatFrame1:AddMessage(msg)
      elseif DEFAULT_CHAT_FRAME then
        DEFAULT_CHAT_FRAME:AddMessage(msg)
      elseif print then
        print(msg)
      end
    end

    local issues = {}

    local function addCheck(category, name, checkFn)
      local ok, result = pcall(checkFn)
      local status, passed
      if not ok then
        status = "|cffff3333ERROR|r"
        table.insert(issues, {cat = category, name = name, err = tostring(result)})
        passed = false
      elseif result then
        status = "|cff33ff33YES|r"
        passed = true
      else
        status = "|cffff8800NO|r"
        table.insert(issues, {cat = category, name = name})
        passed = false
      end
      chatMsg("  " .. name .. ": " .. status)
      return passed
    end

    chatMsg("|cff33ffcc========== pfQuest-Zero Full Diagnostics ==========|r")
    chatMsg("")

    -- Core Systems
    chatMsg("|cffffcc00[Core Systems]|r")
    addCheck("Core", "pfQuest", function() return pfQuest end)
    addCheck("Core", "pfDatabase", function() return pfDatabase end)
    addCheck("Core", "pfMap", function() return pfMap end)
    addCheck("Core", "pfBrowser", function() return pfBrowser end)
    addCheck("Core", "pfQuest_config", function() return pfQuest_config end)
    addCheck("Core", "pfQuest_defconfig", function() return pfQuest_defconfig end)
    addCheck("Core", "pfQuestCompat", function() return pfQuestCompat end)
    chatMsg("")

    -- pfUI Dependencies
    chatMsg("|cffffcc00[pfUI Dependencies]|r")
    addCheck("pfUI", "pfUI", function() return pfUI end)
    addCheck("pfUI", "pfUI.api", function() return pfUI and pfUI.api end)
    addCheck("pfUI", "pfUI.font_default", function() return pfUI and pfUI.font_default end)
    chatMsg("")

    -- Config Panel
    chatMsg("|cffffcc00[Config Panel]|r")
    addCheck("Config", "pfQuestConfig frame", function() return pfQuestConfig end)
    addCheck("Config", "pfQuestConfig.scrollFrame", function() return pfQuestConfig and pfQuestConfig.scrollFrame end)
    addCheck("Config", "pfQuestConfig.scrollChild", function() return pfQuestConfig and pfQuestConfig.scrollChild end)
    addCheck("Config", "pfQuestConfig.scrollBar", function() return pfQuestConfig and pfQuestConfig.scrollBar end)
    addCheck("Config", "pfQuestConfig.searchBox", function() return pfQuestConfig and pfQuestConfig.searchBox end)
    addCheck("Config", "pfQuestConfig.welcome", function() return pfQuestConfig and pfQuestConfig.welcome end)
    addCheck("Config", "pfQuestConfig.save", function() return pfQuestConfig and pfQuestConfig.save end)
    addCheck("Config", "pfQuestConfig.title", function() return pfQuestConfig and pfQuestConfig.title end)
    addCheck("Config", "pfQuestConfig.close", function() return pfQuestConfig and pfQuestConfig.close end)
    chatMsg("")

    -- Tracker
    chatMsg("|cffffcc00[Tracker]|r")
    addCheck("Tracker", "pfQuest.tracker", function() return pfQuest and pfQuest.tracker end)
    addCheck("Tracker", "tracker visible", function() return pfQuest and pfQuest.tracker and pfQuest.tracker:IsShown() end)
    chatMsg("")

    -- Database
    chatMsg("|cffffcc00[Database]|r")
    addCheck("Database", "pfDB", function() return pfDB end)
    addCheck("Database", "pfDB.quests", function() return pfDB and pfDB.quests end)
    addCheck("Database", "pfDB.units", function() return pfDB and pfDB.units end)
    addCheck("Database", "pfDB.objects", function() return pfDB and pfDB.objects end)
    addCheck("Database", "pfDB.items", function() return pfDB and pfDB.items end)
    addCheck("Database", "pfDB.zones", function() return pfDB and pfDB.zones end)
    chatMsg("")

    -- Test Config Panel Show()
    chatMsg("|cffffcc00[Config Panel Show Test]|r")
    if pfQuestConfig then
      local showOk, showErr = pcall(function() pfQuestConfig:Show() end)
      if showOk then
        chatMsg("  Show() call: |cff33ff33SUCCESS|r")
        local visible = pfQuestConfig:IsShown()
        chatMsg("  IsShown(): " .. (visible and "|cff33ff33YES|r" or "|cffff3333NO|r"))
        if visible then
          local point = pfQuestConfig:GetPoint()
          chatMsg("  Position: " .. tostring(point))
          chatMsg("  Size: " .. tostring(pfQuestConfig:GetWidth()) .. " x " .. tostring(pfQuestConfig:GetHeight()))
          -- Hide it after test
          pfQuestConfig:Hide()
        else
          table.insert(issues, {cat = "Config", name = "Panel not visible after Show()"})
        end
      else
        chatMsg("  Show() call: |cffff3333FAILED|r")
        chatMsg("  Error: |cffff8800" .. tostring(showErr) .. "|r")
        table.insert(issues, {cat = "Config", name = "Show() failed", err = tostring(showErr)})
      end
    else
      chatMsg("  |cffff3333Cannot test - pfQuestConfig is nil|r")
    end
    chatMsg("")

    -- Summary
    chatMsg("|cff33ffcc========== Summary ==========|r")
    if table.getn(issues) == 0 then
      chatMsg("|cff33ff33All checks passed!|r Everything should be working.")
    else
      chatMsg("|cffff3333Issues found: " .. table.getn(issues) .. "|r")
      for _, issue in ipairs(issues) do
        local msg = "  |cffff8800[" .. issue.cat .. "]|r " .. issue.name
        if issue.err then
          msg = msg .. " |cffff3333(" .. issue.err .. ")|r"
        end
        chatMsg(msg)
      end
      chatMsg("")
      chatMsg("|cffffcc00Suggestions:|r")

      -- Specific suggestions based on issues
      local hasConfigIssue = false
      local hasCoreIssue = false
      local hasPfUIIssue = false
      for _, issue in ipairs(issues) do
        if issue.cat == "Config" then hasConfigIssue = true end
        if issue.cat == "Core" then hasCoreIssue = true end
        if issue.cat == "pfUI" then hasPfUIIssue = true end
      end

      if hasCoreIssue then
        chatMsg("  - Core systems missing. Check for Lua errors on login.")
      end
      if hasPfUIIssue then
        chatMsg("  - pfUI not loaded. Some features may not work correctly.")
      end
      if hasConfigIssue then
        chatMsg("  - Config panel incomplete. Try /reload or check for errors.")
      end
    end
    chatMsg("|cff33ffcc============================================|r")
    return
  end

  -- argument: calibrate (for subzone coordinate correction)
  if (arg1 == "calibrate" or arg1 == "cal") then
    -- Initialize calibration storage if needed
    pfQuest_calibration = pfQuest_calibration or {}

    -- Get current zone info
    local px, py = GetPlayerMapPosition("player")
    px, py = px * 100, py * 100
    local continent = GetCurrentMapContinent()
    local zoneIndex = GetCurrentMapZone()
    local currentZoneID = pfMap:GetMapID(continent, zoneIndex)
    local zoneName = GetZoneText()
    local subZoneName = GetSubZoneText()
    local realZoneName = GetRealZoneText()

    -- /db calibrate begin - Start new calibration session
    if arg2 == "" or arg2 == "begin" or arg2 == "start" then
      -- Find stationary NPCs in parent zones that would appear in this subzone
      local units = pfDB["units"]["data"]
      local candidates = {}

      -- Look for NPCs that have coords in a parent zone but might be in this subzone
      -- We want NPCs with single spawn points (stationary) - vendors, trainers, quest givers
      for id, data in pairs(units) do
        if data["coords"] and table.getn(data["coords"]) == 1 then
          local coords = data["coords"][1]
          local dbX, dbY, dbZone, respawn = unpack(coords)

          -- Check if this NPC is in a potential parent zone (respawn 0 = stationary)
          if respawn == 0 and dbZone > 0 then
            local unitName = pfDB["units"]["loc"][id]
            if unitName then
              table.insert(candidates, {
                id = id,
                name = unitName,
                x = dbX,
                y = dbY,
                zone = dbZone,
                zoneName = pfDB["zones"]["loc"] and pfDB["zones"]["loc"][dbZone] or ("Zone " .. dbZone)
              })
            end
          end
        end
      end

      -- Sort by zone to group them, then pick 3 spread out ones
      table.sort(candidates, function(a, b)
        if a.zone ~= b.zone then return a.zone < b.zone end
        return a.x < b.x
      end)

      -- Reset calibration state
      pfQuest_calibration = {
        subzoneID = currentZoneID,
        subzoneName = realZoneName or zoneName,
        continent = continent,
        zoneIndex = zoneIndex,
        points = {},
        suggested = {}
      }

      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc--- Calibration Mode Started ---|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88Current Map:|r " .. (realZoneName or zoneName) .. " |cff888888(ID: " .. currentZoneID .. ")|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88SubZone:|r " .. (subZoneName or "none"))
      DEFAULT_CHAT_FRAME:AddMessage("")
      DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Suggested stationary NPCs (single spawn, no respawn):|r")

      -- Show up to 10 candidates from different zones
      local shown = 0
      local lastZone = nil
      for _, npc in ipairs(candidates) do
        if shown < 10 then
          if npc.zone ~= lastZone then
            DEFAULT_CHAT_FRAME:AddMessage("|cff888888-- " .. npc.zoneName .. " (Zone " .. npc.zone .. ") --|r")
            lastZone = npc.zone
          end
          DEFAULT_CHAT_FRAME:AddMessage("  |cff33ffcc" .. npc.name .. "|r |cff666666@ " .. string.format("%.1f", npc.x) .. ", " .. string.format("%.1f", npc.y) .. "|r")
          table.insert(pfQuest_calibration.suggested, npc)
          shown = shown + 1
        end
      end

      if shown == 0 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800No stationary NPCs found in database.|r")
        DEFAULT_CHAT_FRAME:AddMessage("|cffccccccYou can still manually calibrate with any NPC you find.|r")
      end

      DEFAULT_CHAT_FRAME:AddMessage("")
      DEFAULT_CHAT_FRAME:AddMessage("|cffccccccGo stand ON TOP of an NPC and run:|r |cff33ffcc/db cal <npc name>|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cffccccccRepeat for 3 different NPCs spread across the zone.|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cffccccccThen run:|r |cff33ffcc/db cal done|r |cffccccccto calculate the transform.|r")
      return
    end

    -- /db calibrate done - Calculate transform from collected points
    if arg2 == "done" or arg2 == "finish" or arg2 == "calc" then
      if not pfQuest_calibration.points or table.getn(pfQuest_calibration.points) < 2 then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff3333Need at least 2 calibration points!|r Currently have: " .. (pfQuest_calibration.points and table.getn(pfQuest_calibration.points) or 0))
        return
      end

      local points = pfQuest_calibration.points
      local n = table.getn(points)

      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc--- Calibration Results ---|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88SubZone:|r " .. (pfQuest_calibration.subzoneName or "?") .. " |cff888888(ID: " .. (pfQuest_calibration.subzoneID or "?") .. ")|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88Points collected:|r " .. n)
      DEFAULT_CHAT_FRAME:AddMessage("")

      -- Group points by parent zone
      local byParentZone = {}
      for _, p in ipairs(points) do
        byParentZone[p.dbZone] = byParentZone[p.dbZone] or {}
        table.insert(byParentZone[p.dbZone], p)
      end

      -- Calculate transform for each parent zone
      for parentZone, zonePoints in pairs(byParentZone) do
        local parentZoneName = pfDB["zones"]["loc"] and pfDB["zones"]["loc"][parentZone] or ("Zone " .. parentZone)
        DEFAULT_CHAT_FRAME:AddMessage("|cffffcc00Parent Zone:|r " .. parentZoneName .. " |cff888888(ID: " .. parentZone .. ")|r")

        if table.getn(zonePoints) >= 2 then
          -- Calculate affine transform: subzone = scale * parent + offset
          -- Using least squares for 2+ points
          local p1, p2 = zonePoints[1], zonePoints[2]

          -- Solve for X: px = sx * dbx + ox
          local sx, ox
          if p1.dbX ~= p2.dbX then
            sx = (p1.playerX - p2.playerX) / (p1.dbX - p2.dbX)
            ox = p1.playerX - sx * p1.dbX
          else
            sx = 1
            ox = p1.playerX - p1.dbX
          end

          -- Solve for Y: py = sy * dby + oy
          local sy, oy
          if p1.dbY ~= p2.dbY then
            sy = (p1.playerY - p2.playerY) / (p1.dbY - p2.dbY)
            oy = p1.playerY - sy * p1.dbY
          else
            sy = 1
            oy = p1.playerY - p1.dbY
          end

          DEFAULT_CHAT_FRAME:AddMessage("|cff33ff33TRANSFORM FORMULA:|r")
          DEFAULT_CHAT_FRAME:AddMessage("  subzone_x = " .. string.format("%.6f", sx) .. " * parent_x + " .. string.format("%.6f", ox))
          DEFAULT_CHAT_FRAME:AddMessage("  subzone_y = " .. string.format("%.6f", sy) .. " * parent_y + " .. string.format("%.6f", oy))
          DEFAULT_CHAT_FRAME:AddMessage("")
          DEFAULT_CHAT_FRAME:AddMessage("|cff33ff33LUA TABLE FORMAT:|r")
          DEFAULT_CHAT_FRAME:AddMessage("  [" .. pfQuest_calibration.subzoneID .. "] = { -- " .. (pfQuest_calibration.subzoneName or "?"))
          DEFAULT_CHAT_FRAME:AddMessage("    parent = " .. parentZone .. ", -- " .. parentZoneName)
          DEFAULT_CHAT_FRAME:AddMessage("    sx = " .. string.format("%.6f", sx) .. ",")
          DEFAULT_CHAT_FRAME:AddMessage("    sy = " .. string.format("%.6f", sy) .. ",")
          DEFAULT_CHAT_FRAME:AddMessage("    ox = " .. string.format("%.6f", ox) .. ",")
          DEFAULT_CHAT_FRAME:AddMessage("    oy = " .. string.format("%.6f", oy) .. ",")
          DEFAULT_CHAT_FRAME:AddMessage("  },")

          -- Verify with all points
          DEFAULT_CHAT_FRAME:AddMessage("")
          DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88Verification (error should be near 0):|r")
          local totalError = 0
          for i, p in ipairs(zonePoints) do
            local predX = sx * p.dbX + ox
            local predY = sy * p.dbY + oy
            local errX = p.playerX - predX
            local errY = p.playerY - predY
            local err = math.sqrt(errX*errX + errY*errY)
            totalError = totalError + err
            DEFAULT_CHAT_FRAME:AddMessage("  " .. p.npcName .. ": error=" .. string.format("%.4f", err) .. " |cff666666(dx=" .. string.format("%.2f", errX) .. ", dy=" .. string.format("%.2f", errY) .. ")|r")
          end
          DEFAULT_CHAT_FRAME:AddMessage("  |cffffcc00Total error:|r " .. string.format("%.4f", totalError))

          if totalError > 5 then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff3333WARNING: High error! Transform may not be accurate.|r")
          elseif totalError < 1 then
            DEFAULT_CHAT_FRAME:AddMessage("|cff33ff33Transform looks accurate!|r")
          end
        else
          DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Only 1 point for this zone - need at least 2 for accurate transform|r")
          local p = zonePoints[1]
          DEFAULT_CHAT_FRAME:AddMessage("  " .. p.npcName .. ": DB(" .. string.format("%.2f", p.dbX) .. "," .. string.format("%.2f", p.dbY) .. ") -> Player(" .. string.format("%.2f", p.playerX) .. "," .. string.format("%.2f", p.playerY) .. ")")
        end
        DEFAULT_CHAT_FRAME:AddMessage("")
      end

      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc--- End Calibration Results ---|r")
      return
    end

    -- /db calibrate clear - Reset calibration
    if arg2 == "clear" or arg2 == "reset" then
      pfQuest_calibration = {}
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccCalibration data cleared.|r")
      return
    end

    -- /db calibrate status - Show current calibration state
    if arg2 == "status" then
      if not pfQuest_calibration.points then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff8800No calibration in progress.|r Run |cff33ffcc/db cal begin|r to start.")
        return
      end
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc--- Calibration Status ---|r")
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88SubZone:|r " .. (pfQuest_calibration.subzoneName or "?"))
      DEFAULT_CHAT_FRAME:AddMessage("|cff88ff88Points:|r " .. table.getn(pfQuest_calibration.points) .. "/3")
      for i, p in ipairs(pfQuest_calibration.points) do
        DEFAULT_CHAT_FRAME:AddMessage("  [" .. i .. "] " .. p.npcName .. " - DB(" .. string.format("%.2f", p.dbX) .. "," .. string.format("%.2f", p.dbY) .. ") -> (" .. string.format("%.2f", p.playerX) .. "," .. string.format("%.2f", p.playerY) .. ")")
      end
      return
    end

    -- /db calibrate <npc name> - Add a calibration point
    if arg2 ~= "" then
      -- Initialize if needed
      if not pfQuest_calibration.points then
        pfQuest_calibration = {
          subzoneID = currentZoneID,
          subzoneName = realZoneName or zoneName,
          continent = continent,
          zoneIndex = zoneIndex,
          points = {}
        }
      end

      -- Search for the NPC
      local units = pfDB["units"]["data"]
      local foundNPC = nil
      local foundID = nil

      for id in pairs(pfDatabase:GetIDByName(arg2, "units", "LOWER")) do
        if units[id] and units[id]["coords"] then
          foundID = id
          foundNPC = pfDB["units"]["loc"][id]
          break
        end
      end

      if not foundNPC then
        DEFAULT_CHAT_FRAME:AddMessage("|cffff3333No NPC found matching:|r " .. arg2)
        return
      end

      -- Get the NPC's database coordinates (use first spawn point)
      local coords = units[foundID]["coords"][1]
      local dbX, dbY, dbZone, respawn = unpack(coords)

      -- Check if already calibrated this NPC
      for _, p in ipairs(pfQuest_calibration.points) do
        if p.npcID == foundID then
          DEFAULT_CHAT_FRAME:AddMessage("|cffff8800Already calibrated " .. foundNPC .. "! Use a different NPC.|r")
          return
        end
      end

      -- Add calibration point
      local point = {
        npcID = foundID,
        npcName = foundNPC,
        dbX = dbX,
        dbY = dbY,
        dbZone = dbZone,
        playerX = px,
        playerY = py
      }
      table.insert(pfQuest_calibration.points, point)

      local count = table.getn(pfQuest_calibration.points)
      local parentZoneName = pfDB["zones"]["loc"] and pfDB["zones"]["loc"][dbZone] or ("Zone " .. dbZone)

      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc[" .. count .. "/3] Calibration point added:|r " .. foundNPC)
      DEFAULT_CHAT_FRAME:AddMessage("  |cff888888Parent Zone:|r " .. parentZoneName .. " (ID: " .. dbZone .. ")")
      DEFAULT_CHAT_FRAME:AddMessage("  |cff888888DB Position:|r " .. string.format("%.2f", dbX) .. ", " .. string.format("%.2f", dbY))
      DEFAULT_CHAT_FRAME:AddMessage("  |cff888888Your Position:|r " .. string.format("%.2f", px) .. ", " .. string.format("%.2f", py))

      if count >= 3 then
        DEFAULT_CHAT_FRAME:AddMessage("")
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ff333 points collected!|r Run |cff33ffcc/db cal done|r to calculate transform.")
      else
        DEFAULT_CHAT_FRAME:AddMessage("|cffccccccNeed " .. (3 - count) .. " more point(s). Go to another NPC.|r")
      end
      return
    end
  end

  -- argument: scanzone - Diagnostic scan of current zone data
  if (arg1 == "scanzone" or arg1 == "zoneinfo" or arg1 == "zonediag") then
    local debugLines = {}
    local function chatMsg(msg)
      DEFAULT_CHAT_FRAME:AddMessage(msg)
      table.insert(debugLines, StripColors(msg))
    end

    -- Get current zone info
    local zoneName = GetRealZoneText() or GetZoneText() or "Unknown"
    local continent = GetCurrentMapContinent()
    local zoneIndex = GetCurrentMapZone()
    local zoneID = pfMap and pfMap.GetMapID and pfMap:GetMapID(continent, zoneIndex)

    chatMsg("|cff33ffcc========== pfQuest Zone Diagnostic ==========|r")
    chatMsg("")

    -- Zone info
    chatMsg("|cffffcc00[Zone Info]|r")
    chatMsg("  Zone: |cff88ff88" .. zoneName .. "|r")
    chatMsg("  Zone ID: |cff88ff88" .. (zoneID and tostring(zoneID) or "|cffff3333UNKNOWN|r") .. "|r")
    chatMsg("  Continent: " .. tostring(continent) .. " | Zone Index: " .. tostring(zoneIndex))

    -- Zone DB preference
    if zoneID then
      local dbPref = pfQDB:GetPreferredDB(zoneID)
      local dbText = dbPref == "questie" and "|cffff9900Questie|r" or "|cff33ffccpfQuest|r"
      chatMsg("  Database Preference: " .. dbText)

      -- Show zone info from zone-mapping
      if pfQDB.zones and pfQDB.zones.info and pfQDB.zones.info[zoneID] then
        local zi = pfQDB.zones.info[zoneID]
        chatMsg("  Expansion: |cff88ff88" .. (zi.expansion or "?") .. "|r | Continent: " .. (zi.continent or "?"))
      end
    end
    chatMsg("")

    -- pfQDB status
    chatMsg("|cffffcc00[Database System Status]|r")
    chatMsg("  pfQDB initialized: " .. (pfQDB.initialized and "|cff33ff33YES|r" or "|cffff3333NO|r"))
    chatMsg("  Questie data available: " .. (pfQDB.questieDataAvailable and "|cff33ff33YES|r" or "|cffff3333NO|r"))

    if pfQDB.questieDataAvailable and pfQDB.questie then
      local function countTable(t)
        local c = 0
        if t then for _ in pairs(t) do c = c + 1 end end
        return c
      end
      local cU = countTable(pfQDB.questie.classic and pfQDB.questie.classic.units)
      local cO = countTable(pfQDB.questie.classic and pfQDB.questie.classic.objects)
      local tU = countTable(pfQDB.questie.tbc and pfQDB.questie.tbc.units)
      local tO = countTable(pfQDB.questie.tbc and pfQDB.questie.tbc.objects)
      local wU = countTable(pfQDB.questie.wotlk and pfQDB.questie.wotlk.units)
      local wO = countTable(pfQDB.questie.wotlk and pfQDB.questie.wotlk.objects)
      chatMsg("  Questie Classic: " .. cU .. " units, " .. cO .. " objects")
      chatMsg("  Questie TBC: " .. tU .. " units, " .. tO .. " objects")
      chatMsg("  Questie WotLK: " .. wU .. " units, " .. wO .. " objects")
    end
    chatMsg("")

    -- Count entities in this zone
    if zoneID then
      chatMsg("|cffffcc00[Entities in " .. zoneName .. " (Zone " .. zoneID .. ")]|r")

      -- pfQuest units/objects in zone
      local pfUnits, pfObjects = 0, 0
      if pfDB and pfDB.units and pfDB.units.data then
        for id, data in pairs(pfDB.units.data) do
          if data.coords then
            for _, coord in pairs(data.coords) do
              if coord[3] == zoneID then
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
              if coord[3] == zoneID then
                pfObjects = pfObjects + 1
                break
              end
            end
          end
        end
      end
      chatMsg("  pfQuest: |cff33ffcc" .. pfUnits .. "|r units, |cff33ffcc" .. pfObjects .. "|r objects")

      -- Questie entities in zone
      if pfQDB.questieDataAvailable and pfQDB.questie then
        local qUnits, qObjects = 0, 0
        local function countInZone(dataTable, targetZone)
          local count = 0
          if not dataTable then return 0 end
          for id, data in pairs(dataTable) do
            if data.coords then
              for _, coord in pairs(data.coords) do
                if coord[3] == targetZone then
                  count = count + 1
                  break
                end
              end
            end
          end
          return count
        end

        for _, exp in ipairs({"classic", "tbc", "wotlk"}) do
          if pfQDB.questie[exp] then
            qUnits = qUnits + countInZone(pfQDB.questie[exp].units, zoneID)
            qObjects = qObjects + countInZone(pfQDB.questie[exp].objects, zoneID)
          end
        end
        chatMsg("  Questie: |cffff9900" .. qUnits .. "|r units, |cffff9900" .. qObjects .. "|r objects")
      else
        chatMsg("  Questie: |cffff8800N/A (data not loaded)|r")
      end

      -- Rares check
      local pfRares, questieRares = 0, 0
      if pfDB and pfDB.meta and pfDB.meta.rares then
        for rareId, _ in pairs(pfDB.meta.rares) do
          local data = pfDB.units and pfDB.units.data and pfDB.units.data[rareId]
          if data and data.coords then
            for _, coord in pairs(data.coords) do
              if coord[3] == zoneID then
                pfRares = pfRares + 1
                break
              end
            end
          end
        end
      end
      -- Check Questie for rares in zone (any unit in zone that pfDB.meta.rares knows about)
      if pfQDB.questieDataAvailable and pfQDB.questie and pfDB and pfDB.meta and pfDB.meta.rares then
        for rareId, _ in pairs(pfDB.meta.rares) do
          local data = pfQDB:GetQuestieNPCData(rareId)
          if data and data.coords then
            for _, coord in pairs(data.coords) do
              if coord[3] == zoneID then
                questieRares = questieRares + 1
                break
              end
            end
          end
        end
      end
      chatMsg("  Rare mobs (pfDB.meta.rares list): pfQuest=" .. pfRares .. " Questie=" .. questieRares)
      chatMsg("  |cff888888Note: rares list only has Classic/TBC IDs - no WotLK rares catalogued|r")
      chatMsg("")
    end

    -- Quest log analysis
    chatMsg("|cffffcc00[Quest Log Analysis]|r")
    local numEntries = GetNumQuestLogEntries()
    local questCount = 0
    local totalUnits, totalObjects, totalItems = 0, 0, 0
    local wotlkQuests = 0

    for qlogid = 1, 40 do
      local title, level, tag, header, collapsed, complete = compat.GetQuestLogTitle(qlogid)
      if title and not header then
        questCount = questCount + 1

        -- Get quest ID
        local questId = nil
        if GetQuestLink then
          local link = GetQuestLink(qlogid)
          if link then
            local _, _, id = strfind(link, "quest:(%d+)")
            if id then questId = tonumber(id) end
          end
        end

        -- Check pfDB for this quest
        local inPfDB = questId and pfDB and pfDB.quests and pfDB.quests.data and pfDB.quests.data[questId]

        if not inPfDB then
          wotlkQuests = wotlkQuests + 1
        end

        -- Get objectives
        local numObj = GetNumQuestLeaderBoards(qlogid)
        local objUnits, objObjects, objItems = 0, 0, 0
        local objDetails = {}

        if numObj and numObj > 0 then
          for objIdx = 1, numObj do
            local desc, objType, done = GetQuestLogLeaderBoard(objIdx, qlogid)
            if not done then
              if objType == "monster" then
                objUnits = objUnits + 1
                -- Try to extract mob name from description
                local mobName = nil
                if desc then
                  local _, _, name = strfind(desc, "(.+) slain")
                  if not name then
                    _, _, name = strfind(desc, "(.+):")
                  end
                  mobName = name
                end
                table.insert(objDetails, "  |cffaaaaaa  U: " .. (desc or "?") .. "|r")
              elseif objType == "object" or objType == "event" then
                objObjects = objObjects + 1
                table.insert(objDetails, "  |cffaaaaaa  O: " .. (desc or "?") .. "|r")
              elseif objType == "item" then
                objItems = objItems + 1
                table.insert(objDetails, "  |cffaaaaaa  I: " .. (desc or "?") .. "|r")
              end
            end
          end
        end

        totalUnits = totalUnits + objUnits
        totalObjects = totalObjects + objObjects
        totalItems = totalItems + objItems

        -- Format quest line
        local dbLabel = inPfDB and "|cff33ff33pfDB|r" or "|cffff8800WotLK|r"
        local questIdStr = questId and tostring(questId) or "title"
        local completeMark = complete and complete == 1 and " |cff33ff33[DONE]|r" or ""
        local pendingStr = ""
        if objUnits > 0 or objObjects > 0 or objItems > 0 then
          pendingStr = " |cffcccccc(" .. objUnits .. "U " .. objObjects .. "O " .. objItems .. "I pending)|r"
        end

        chatMsg("  [" .. dbLabel .. " " .. questIdStr .. "] " .. (title or "?") .. completeMark .. pendingStr)

        -- Show objective details for WotLK quests (most useful for debugging)
        if not inPfDB and table.getn(objDetails) > 0 then
          for _, detail in ipairs(objDetails) do
            chatMsg(detail)
          end
        end
      end
    end

    chatMsg("")
    chatMsg("  |cff88ff88Total:|r " .. questCount .. " quests (" .. wotlkQuests .. " WotLK/not in pfDB)")
    chatMsg("  |cff88ff88Pending objectives:|r " .. totalUnits .. " units, " .. totalObjects .. " objects, " .. totalItems .. " items")
    chatMsg("")

    -- Active holidays
    chatMsg("|cffffcc00[Active Holidays]|r")
    chatMsg("  " .. pfQDB:GetActiveHolidaysString())
    chatMsg("")

    -- Map nodes summary
    chatMsg("|cffffcc00[Map Nodes]|r")
    if pfMap and pfMap.nodes then
      local totalNodes = 0
      local zoneNodes = 0
      for mapId, mapNodes in pairs(pfMap.nodes) do
        for _, _ in pairs(mapNodes) do
          totalNodes = totalNodes + 1
          if mapId == zoneID then
            zoneNodes = zoneNodes + 1
          end
        end
      end
      chatMsg("  Nodes on current zone map: |cff88ff88" .. zoneNodes .. "|r")
      chatMsg("  Total nodes across all maps: " .. totalNodes)
    else
      chatMsg("  |cffff8800pfMap.nodes not available|r")
    end

    -- Pipeline trace log (if debug/tracing was on during quest processing)
    chatMsg("|cffffcc00[Pipeline Trace Log]|r")
    if pfDatabase and pfDatabase.trace then
      local traceLog = pfDatabase.trace.log
      local numEntries = table.getn(traceLog)
      if numEntries == 0 then
        chatMsg("  |cff888888No trace entries. Enable with |cff33ffcc/db debug on|r then |cff33ffcc/reload|r|r")
      else
        -- Count by source
        local sourceCounts = {}
        for _, entry in ipairs(traceLog) do
          local src = entry.source or "general"
          sourceCounts[src] = (sourceCounts[src] or 0) + 1
        end
        local srcParts = {}
        for src, count in pairs(sourceCounts) do
          table.insert(srcParts, src .. "=" .. count)
        end
        chatMsg("  |cff88ff88" .. numEntries .. " trace entries|r (" .. table.concat(srcParts, ", ") .. ")")

        -- Summarize by source+reason (quest pipeline only in scanzone)
        local reasonColors = {
          added = "|cff33ff33", no_data = "|cffff3333", holiday = "|cffff8800",
          no_coords = "|cffff8800", complete = "|cff888888", parse_fail = "|cffff3333",
          no_name_match = "|cffff3333", wotlk_fallback = "|cff33ccff", wotlk_result = "|cff33ccff",
        }

        -- Show quest pipeline summary
        chatMsg("")
        chatMsg("  |cffffff00Quest Pipeline:|r")
        local questReasons = {}
        local questReasonCounts = {}
        for _, entry in ipairs(traceLog) do
          if (entry.source or "general") == "quest" then
            local key = entry.type .. ":" .. entry.reason
            questReasonCounts[key] = (questReasonCounts[key] or 0) + 1
            if not questReasons[key] then questReasons[key] = entry end
          end
        end

        local summaryOrder = {"quest:no_data", "quest:complete", "quest:parse_fail", "quest:no_name_match",
          "quest:wotlk_fallback", "quest:wotlk_result",
          "unit:added", "unit:no_data", "unit:holiday", "unit:no_coords",
          "object:added", "object:no_data", "object:holiday", "object:no_coords"}

        local hasQuestEntries = false
        local shown = {}
        for _, key in ipairs(summaryOrder) do
          if questReasonCounts[key] then
            local entry = questReasons[key]
            local color = reasonColors[entry.reason] or "|cffcccccc"
            chatMsg("    " .. color .. key .. "|r: " .. questReasonCounts[key] .. "x")
            shown[key] = true
            hasQuestEntries = true
          end
        end
        for key, count in pairs(questReasonCounts) do
          if not shown[key] then
            chatMsg("    |cffcccccc" .. key .. "|r: " .. count .. "x")
            hasQuestEntries = true
          end
        end
        if not hasQuestEntries then
          chatMsg("    |cff888888No quest pipeline entries recorded|r")
        end

        -- Show quest pipeline failures in detail
        chatMsg("")
        local failures = {}
        for _, entry in ipairs(traceLog) do
          if (entry.source or "general") == "quest"
            and entry.reason ~= "added" and entry.reason ~= "complete"
            and entry.reason ~= "wotlk_result" then
            table.insert(failures, entry)
          end
        end

        if table.getn(failures) > 0 then
          chatMsg("  |cffff8800Quest Failures/Skips (max 30):|r")
          local showCount = 0
          for _, entry in ipairs(failures) do
            if showCount >= 30 then
              chatMsg("  |cff888888... " .. (table.getn(failures) - 30) .. " more|r")
              break
            end
            local nameStr = entry.name ~= "" and entry.name or "?"
            local color = reasonColors[entry.reason] or "|cffcccccc"
            chatMsg("    " .. color .. "[" .. entry.type .. " " .. tostring(entry.id) .. "]|r "
              .. nameStr .. " - " .. entry.reason .. ": " .. entry.detail)
            showCount = showCount + 1
          end
        else
          chatMsg("  |cff33ff33No quest failures recorded.|r")
        end

        chatMsg("")
        chatMsg("  |cff888888Use /db trace quests, /db trace tracking, /db trace failures for details|r")
      end
    else
      chatMsg("  |cffff8800Trace system not available|r")
    end

    chatMsg("|cff33ffcc============================================|r")
    pfQuestDebugFrame_Show("Zone Diagnostic: " .. (zoneName or "Unknown"), debugLines)
    return
  end

  -- argument: trace - Show just the pipeline trace log
  -- Supports: /db trace [quests|tracking|failures|all|clear]
  if (arg1 == "trace") then
    local debugLines = {}
    local function chatMsg(msg)
      DEFAULT_CHAT_FRAME:AddMessage(msg)
      table.insert(debugLines, StripColors(msg))
    end

    if arg2 == "clear" then
      pfDatabase:TraceClear()
      chatMsg("|cff33ffccpfQuest|r: Trace log cleared.")
      return
    end

    if not pfDatabase or not pfDatabase.trace then
      chatMsg("|cffff3333Trace system not available.|r")
      return
    end

    local traceLog = pfDatabase.trace.log
    local numEntries = table.getn(traceLog)

    -- Determine filter mode
    local filterMode = arg2 or ""
    local filterLabel = "all"
    if filterMode == "quests" or filterMode == "quest" then
      filterLabel = "quest pipeline only"
    elseif filterMode == "tracking" then
      filterLabel = "tracking only"
    elseif filterMode == "failures" or filterMode == "fails" then
      filterLabel = "failures only"
    end

    chatMsg("|cff33ffcc========== Pipeline Trace Log ==========|r")
    chatMsg("  Tracing: " .. (pfDatabase.trace.enabled and "|cff33ff33ON|r" or "|cffff3333OFF|r"))
    chatMsg("  Entries: " .. numEntries .. " / " .. pfDatabase.trace.maxEntries)
    chatMsg("  Filter: |cffffff00" .. filterLabel .. "|r")

    -- Count by source
    local sourceCounts = {}
    for _, entry in ipairs(traceLog) do
      local src = entry.source or "general"
      sourceCounts[src] = (sourceCounts[src] or 0) + 1
    end
    local srcParts = {}
    for src, count in pairs(sourceCounts) do
      table.insert(srcParts, src .. "=" .. count)
    end
    chatMsg("  Sources: " .. table.concat(srcParts, ", "))
    chatMsg("")

    if numEntries == 0 then
      chatMsg("  |cff888888No entries. Enable: |cff33ffcc/db debug on|r then |cff33ffcc/reload|r")
      chatMsg("|cff33ffcc========================================|r")
      pfQuestDebugFrame_Show("Pipeline Trace: empty", debugLines)
      return
    end

    local reasonColors = {
      added = "|cff33ff33", no_data = "|cffff3333", holiday = "|cffff8800",
      no_coords = "|cffff8800", complete = "|cff888888", parse_fail = "|cffff3333",
      no_name_match = "|cffff3333", wotlk_fallback = "|cff33ccff", wotlk_result = "|cff33ccff",
    }

    -- Filter entries
    local filtered = {}
    for _, entry in ipairs(traceLog) do
      local show = true
      local src = entry.source or "general"
      if filterMode == "quests" or filterMode == "quest" then
        show = (src == "quest")
      elseif filterMode == "tracking" then
        show = (src == "tracking")
      elseif filterMode == "failures" or filterMode == "fails" then
        show = (entry.reason ~= "added" and entry.reason ~= "complete" and entry.reason ~= "wotlk_result")
      end
      if show then
        table.insert(filtered, entry)
      end
    end

    local maxShow = 100
    if filterMode == "all" then maxShow = table.getn(filtered) end

    chatMsg("  Showing " .. math.min(maxShow, table.getn(filtered)) .. " of " .. table.getn(filtered) .. " filtered entries:")
    chatMsg("")

    for i, entry in ipairs(filtered) do
      if i > maxShow then
        chatMsg("  |cff888888... " .. (table.getn(filtered) - maxShow) .. " more (use /db trace all)|r")
        break
      end
      local nameStr = entry.name ~= "" and entry.name or "?"
      local color = reasonColors[entry.reason] or "|cffcccccc"
      local srcTag = entry.source and (" |cff666666[" .. entry.source .. "]|r") or ""
      chatMsg("  " .. color .. "[" .. entry.type .. " " .. tostring(entry.id) .. "]|r "
        .. nameStr .. " - " .. entry.reason .. ": " .. entry.detail .. srcTag)
    end

    chatMsg("|cff33ffcc========================================|r")
    pfQuestDebugFrame_Show("Pipeline Trace: " .. filterLabel, debugLines)
    return
  end

  -- argument: item
  if (arg1 == "item") then
    local maps = pfDatabase:SearchItem(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: vendor
  if (arg1 == "vendor") then
    local maps = pfDatabase:SearchVendor(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: unit
  if (arg1 == "unit") then
    local maps = pfDatabase:SearchMob(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: object
  if (arg1 == "object") then
    local maps = pfDatabase:SearchObject(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quest
  if (arg1 == "quest") then
    local maps = pfDatabase:SearchQuest(arg2, meta, "LOWER")
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: quests
  if (arg1 == "quests") then
    local maps = pfDatabase:SearchQuests(meta)
    pfMap:UpdateNodes()
    return
  end

  -- argument: track
  if (arg1 == "track" or arg1 == "meta") then
    local list = commandlist[2]

    -- show available lists
    if not list or list == "" then
      local available = nil
      for list in pairs(pfDB["meta"]) do
        available = (available and available .. ", " or "") .. "\"|cff33ffcc"..list.."|r\""
      end

      DEFAULT_CHAT_FRAME:AddMessage(string.format(pfQuest_Loc["Available tracking targets are: %s. Or type \"|cff33ffcc/db track clean|r\" to untrack all."], available))
      return
    end

    -- clean all tracking results
    if commandlist[2] == "clean" then
      for list in pairs(pfDB["meta"]) do
        pfDatabase:TrackMeta(list, false)
      end

      return
    end

    -- load arguments into state
    local state = {
      min = commandlist[3],
      max = commandlist[4],
      faction = commandlist[3],
    }

    -- read skill for auto mines
    if (list == "mines" and commandlist[3] == "auto") then
      state.max = pfDatabase:GetPlayerSkill(186) or 0
      state.min = state.max - 100
    end

    -- read skill for auto herbs
    if (list == "herbs" and commandlist[3] == "auto") then
      state.max = pfDatabase:GetPlayerSkill(182) or 0
      state.min = state.max - 100
    end

    -- clean specific list
    if commandlist[3] == "clean" then
      state = nil
    end

    -- perform tracking
    local maps = pfDatabase:TrackMeta(list, state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- warn about deprecated arguments
  local deprecated = {
    ["chests"] = true, ["taxi"] = true, ["flights"] = true, ["rares"] = true, ["mines"] = true, ["herbs"] = true
  }

  if deprecated[arg1] then
    DEFAULT_CHAT_FRAME:AddMessage(string.format(pfQuest_Loc["|cffffcc00WARNING:|r The command \"|cff33ffcc/db %s|r\" is deprecated and will be removed soon. Please use the \"|cff33ffcc/db track %s|r\" instead to achieve the same functionality."], arg1, arg1))
  end

  -- argument: chests (deprecated)
  if (arg1 == "chests") then
    local state = true

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("chests", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: taxi (deprecated)
  if (arg1 == "flights" or arg1 == "taxi") then
    local state = {
      faction = commandlist[2],
    }

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("flight", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: rares (deprecated)
  if (arg1 == "rares") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if commandlist[2] == "clean" then
      state = nil
    end

    local maps = pfDatabase:TrackMeta("rares", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: mines (deprecated)
  if (arg1 == "mines") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      state.max = pfDatabase:GetPlayerSkill(186) or 0
      state.min = state.max - 100
    end

    if commandlist[2] == "clean" then
      state = nil
    end

    state = commandlist[2] == "clean" and nil or state
    local maps = pfDatabase:TrackMeta("mines", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: herbs (deprecated)
  if (arg1 == "herbs") then
    local state = {
      min = commandlist[2],
      max = commandlist[3],
    }

    if (arg2 == "auto") then
      state.max = pfDatabase:GetPlayerSkill(182) or 0
      state.min = state.max - 100
    end

    if commandlist[2] == "clean" then
      state = nil
    end

    state = commandlist[2] == "clean" and nil or state
    local maps = pfDatabase:TrackMeta("herbs", state)
    pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    return
  end

  -- argument: clean
  if (arg1 == "clean") then
    pfMap:DeleteNode("PFDB")
    pfMap:UpdateNodes()
    return
  end

  -- argument: reset
  if (arg1 == "reset") then
    pfQuest:ResetAll()
    return
  end

  -- argument: show
  if (arg1 == "show") then
    if pfBrowser then pfBrowser:Show() end
    return
  end

  -- argument: tracker
  if (arg1 == "tracker") then
    if pfQuest.tracker then pfQuest.tracker:Show() end
    return
  end

  -- argument: lock
  if (arg1 == "lock") then
    pfQuest_config.lock = not pfQuest_config.lock
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpf|cffffffffQuest Tracker: " .. ( pfQuest_config.lock and "Locked" or "Unlocked" ))
    return
  end

  -- argument: journal
  if (arg1 == "journal") then
    if pfJournal then pfJournal:Show() end
    return
  end

  -- argument: arrow
  if (arg1 == "arrow") then
    if pfQuest_config["arrow"] == "1" then
      pfQuest_config["arrow"] = "0"
      pfQuest.route.arrow:Hide()
    else
      pfQuest_config["arrow"] = "1"
    end
    return
  end

  -- argument: show
  if (arg1 == "config") then
    if pfQuestConfig then pfQuestConfig:Show() end
    return
  end

  -- argument: locale
  if (arg1 == "locale") then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffcc" .. pfQuest_Loc["Locales"] .. "|r:" .. pfDatabase.dbstring)
    return
  end

  -- argument: scan
  if (arg1 == "scan") then
    pfDatabase:ScanServer()
    return
  end

    -- argument: query
  if (arg1 == "query") then
    pfDatabase:QueryServer()
    return
  end

  -- argument: <text>
  if (type(arg1)=="string") then
    if pfBrowser then
      pfBrowser:Show()
      pfBrowser.input:SetText((string.gsub(string.format("%s %s",arg1,arg2),"^%s*(.-)%s*$", "%1")))
    end
    return
  end
end
