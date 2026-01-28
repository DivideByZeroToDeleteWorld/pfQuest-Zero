-- multi api compat
local compat = pfQuestCompat

-- default config
pfBrowser_fav = {["units"] = {}, ["objects"] = {}, ["items"] = {}, ["quests"] = {}}

local tooltip_limit = 5
local search_limit = 512

-- add database shortcuts
local items = pfDB["items"]["data"]
local units = pfDB["units"]["data"]
local objects = pfDB["objects"]["data"]
local refloot = pfDB["refloot"]["data"]
local quests = pfDB["quests"]["data"]
local zones = pfDB["zones"]["loc"]

local function ShowTooltip()
  if not this.tooltips then return end
  GameTooltip_SetDefaultAnchor(GameTooltip, this)
  GameTooltip:ClearLines()
  for k, v in pairs(this.tooltips) do
    if k == 1 then
      GameTooltip:AddLine(v, 1, 1, 1)
    else
      GameTooltip:AddLine(v)
    end
  end
  GameTooltip:Show()
end

local function EnableTooltips(frame, tooltips)
  frame.tooltips = tooltips
  frame:SetScript("OnEnter", ShowTooltip)
  frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function ResultButtonEnter()
  this.tex:SetTexture(1,1,1,.1)

  -- quest
  if this.btype == "quests" then
    pfDatabase:ShowExtendedTooltip(this.id, GameTooltip, this, "ANCHOR_LEFT", -10, -5)

  -- item
  elseif this.btype == "items" then
    GameTooltip:SetOwner(this, "ANCHOR_LEFT", -10, -5)
    GameTooltip:SetHyperlink("item:" .. this.id .. pfQuestCompat.itemsuffix)
    GameTooltip:Show()

  -- units / objects
  else
    local id = this.id
    local name = this.name
    local maps = {}
    GameTooltip:SetOwner(this, "ANCHOR_LEFT", -10, -5)

    -- Show database source in tooltip title
    local titleColor = { .3, 1, .8 }
    if pfBrowser.dbSource == "questie" then
      GameTooltip:SetText("|cffff9900[Questie]|r " .. name, titleColor[1], titleColor[2], titleColor[3])
    else
      GameTooltip:SetText(name, titleColor[1], titleColor[2], titleColor[3])
    end

    -- Get data from appropriate database
    local entityData
    if pfBrowser.dbSource == "questie" and pfQDB and pfQDB.questieDataAvailable then
      if this.btype == "units" then
        entityData = pfQDB:GetQuestieNPCData(id)
      else
        entityData = pfQDB:GetQuestieObjectData(id)
      end
    else
      entityData = pfDB[this.btype]["data"][id]
    end

    if this.btype == "units" then
      if entityData and entityData.lvl then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(pfQuest_Loc["Level"], entityData.lvl, 1,1,.8, 1,1,1)
      end

      local reactionStringA = "|c00ff0000" .. pfQuest_Loc["Hostile"] .. "|r"
      local reactionStringH = "|c00ff0000" .. pfQuest_Loc["Hostile"] .. "|r"
      if entityData and entityData.fac then
        if entityData.fac == "AH" then
          reactionStringA = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
          reactionStringH = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        elseif entityData.fac == "A" then
          reactionStringA = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        elseif entityData.fac == "H" then
          reactionStringH = "|c0000ff00" .. pfQuest_Loc["Friendly"] .. "|r"
        end
      end
      GameTooltip:AddLine("\n" .. pfQuest_Loc["Reaction"], 1,1,.8)
      GameTooltip:AddDoubleLine(pfQuest_Loc["Alliance"], reactionStringA, 1,1,1, 0,0,0)
      GameTooltip:AddDoubleLine(pfQuest_Loc["Horde"], reactionStringH, 1,1,1, 0,0,0)
    end
    GameTooltip:AddLine("\n" .. pfQuest_Loc["Location"], 1,1,.8)
    if entityData and entityData.coords then
      for _, data in pairs(entityData.coords) do
        maps[data[3]] = maps[data[3]] or { count = 0 }
        maps[data[3]].count = maps[data[3]].count + 1
      end
    end

    local unknown = true
    for zone, obj in pfQuest:SortedPairs(maps, "count", nil) do
      GameTooltip:AddDoubleLine(( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), obj.count, 1,1,1, .3,1,.8)
      unknown = nil
    end

    if unknown then
      GameTooltip:AddLine(UNKNOWN, 1,.5,.5)
    end

    GameTooltip:Show()
  end
end

local function ResultButtonUpdate()
  this.refreshCount = this.refreshCount + 1

  if not this.itemColor then
    GameTooltip:SetHyperlink("item:" .. this.id .. pfQuestCompat.itemsuffix)
    GameTooltip:Hide()

    local _, _, itemQuality = GetItemInfo(this.id)
    if itemQuality then
      local r = ceil(ITEM_QUALITY_COLORS[itemQuality].r*255)
      local g = ceil(ITEM_QUALITY_COLORS[itemQuality].g*255)
      local b = ceil(ITEM_QUALITY_COLORS[itemQuality].b*255)
      this.itemColor = "|c" .. string.format("ff%02x%02x%02x", r, g, b)
    end
  end

  if this.itemColor then
    local custom = pfQuest_server["items"][this.id] and " [|cff33ffcc!|r]" or ""
    this.text:SetText(this.itemColor .."|Hitem:"..this.id..pfQuestCompat.itemsuffix.."|h[".. this.name.."]|h|r"..custom)
    this.text:SetWidth(this.text:GetStringWidth())
  end

  if this.refreshCount > 10 or this.itemColor then
    this:SetScript("OnUpdate", nil)
  end
end

local function ResultButtonClick()
  local meta = { ["addon"] = "PFDB" }

  if this.btype == "items" then
    local link = "item:"..this.id..pfQuestCompat.itemsuffix
    local text = ( this.itemColor or "|cffffffff" ) .."|H" .. link .. "|h["..this.name.."]|h|r"
    SetItemRef(link, text, arg1)
  elseif this.btype == "quests" then
    if IsShiftKeyDown() then
      pfQuestCompat.InsertQuestLink(this.id)
    elseif pfBrowser.selectState then
      local maps = pfDatabase:SearchQuest(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      local maps = pfDatabase:SearchQuestID(this.id, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  elseif this.btype == "units" then
    local maps
    if pfBrowser.dbSource == "questie" and pfQDB and pfQDB.questieDataAvailable then
      -- Use Questie search
      maps = pfQDB:SearchQuestieMobID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    elseif pfBrowser.selectState then
      maps = pfDatabase:SearchMob(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      maps = pfDatabase:SearchMobID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  elseif this.btype == "objects" then
    local maps
    if pfBrowser.dbSource == "questie" and pfQDB and pfQDB.questieDataAvailable then
      -- Use Questie search
      maps = pfQDB:SearchQuestieObjectID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    elseif pfBrowser.selectState then
      maps = pfDatabase:SearchObject(this.name, meta)
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    else
      maps = pfDatabase:SearchObjectID(this.id, meta)
      pfMap:UpdateNodes()
      pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
    end
  end
end

local function ResultButtonClickFav()
  local parent = this:GetParent()
  if pfBrowser_fav[parent.btype][parent.id] then
    pfBrowser_fav[parent.btype][parent.id] = nil
    this.icon:SetVertexColor(1,1,1,.1)
  else
    pfBrowser_fav[parent.btype][parent.id] = parent.name
    this.icon:SetVertexColor(1,1,1,1)
  end
end

local function ResultButtonLeave()
  if pfBrowser.selectState then
    pfBrowser.selectState = "clean"
  end

  if compat.mod(this:GetID(),2) == 1 then
    this.tex:SetTexture(1,1,1,.02)
  else
    this.tex:SetTexture(1,1,1,.04)
  end
  GameTooltip:Hide()
end

local function ResultButtonClickSpecial()
  local param = this:GetParent()[this.parameter]
  local meta = { ["addon"] = "PFDB" }
  local maps = {}
  if this.buttonType == "O" or this.buttonType == "U" then
    if this.selectState then
      maps = pfDatabase:SearchItem(this:GetParent().name, meta)
    else
      maps = pfDatabase:SearchItemID(param, meta, nil, {[this.buttonType]=true})
    end
  elseif this.buttonType == "V" then
    maps = pfDatabase:SearchVendor(param, meta)
  end
  pfMap:UpdateNodes()
  pfMap:ShowMapID(pfDatabase:GetBestMap(maps))
end

local function ResultButtonEnterSpecial()
  local id = this:GetParent().id
  local count = 0
  local skip = false

  GameTooltip:SetOwner(pfBrowser, "ANCHOR_CURSOR")

  -- unit
  if this.buttonType == "U" then
    if items[id]["U"] then
      GameTooltip:SetText(pfQuest_Loc["Looted from"], .3, 1, .8)
      for unitID, chance in pairs(items[id]["U"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if units[unitID] and not skip then
          local name = pfDB.units.loc[unitID]
          local zone = nil
          if units[unitID].coords and units[unitID].coords[1] then
            zone = units[unitID].coords[1][3]
          end
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        end
      end

      -- reference tables
      if items[id]["R"] then
        for ref, chance in pairs(items[id]["R"]) do
          if refloot[ref] and refloot[ref]["U"] then
            for unit in pairs(refloot[ref]["U"]) do
              count = count + 1
              if count > tooltip_limit then
                skip = true
              end
              if units[unit] and not skip then
                local name = pfDB.units.loc[unit]
                local zone = nil
                if units[unit].coords and units[unit].coords[1] then
                  zone = units[unit].coords[1][3]
                end
                GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
              end
            end
          end
        end
      end
    end

  -- object
  elseif this.buttonType == "O" then
    if items[id]["O"] then
      GameTooltip:SetText(pfQuest_Loc["Looted from"], .3, 1, .8)
      for objectID, chance in pairs(items[id]["O"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if objects[objectID] and not skip then
          local name = pfDB.objects.loc[objectID] or objectID
          local zone = nil
          if objects[objectID].coords and objects[objectID].coords[1] then
            zone = objects[objectID].coords[1][3]
          end
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        end
      end

      -- reference tables
      if items[id]["R"] then
        for ref, chance in pairs(items[id]["R"]) do
          if refloot[ref] and refloot[ref]["O"] then
            for unit in pairs(refloot[ref]["O"]) do
              count = count + 1
              if count > tooltip_limit then
                skip = true
              end
              if objects[unit] and not skip then
                local name = pfDB.objects.loc[unit]
                local zone = nil
                if objects[unit].coords and objects[unit].coords[1] then
                  zone = objects[unit].coords[1][3]
                end
                GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
              end
            end
          end
        end
      end
    end

  -- vendor
  elseif this.buttonType == "V" then
    if items[id]["V"] then
      GameTooltip:SetText(pfQuest_Loc["Sold by"], .3, 1, .8)
      for unitID, sellcount in pairs(items[id]["V"]) do
        count = count + 1
        if count > tooltip_limit then
          skip = true
        end
        if units[unitID] and not skip then
          local name = pfDB.units.loc[unitID]
          if sellcount ~= 0 then name = name .. " (" .. sellcount .. ")" end
          local zone = units[unitID].coords and units[unitID].coords[1] and units[unitID].coords[1][3]
          GameTooltip:AddDoubleLine(name, ( zone and pfMap:GetMapNameByID(zone) or UNKNOWN), 1,1,1, .5,.5,.5)
        end
      end
    end
  end

  if count > tooltip_limit then
    GameTooltip:AddLine("\n" .. pfQuest_Loc["and"] .. " " .. (count - tooltip_limit).." " .. pfQuest_Loc["others"],.8,.8,.8)
  end
  GameTooltip:Show()
end

local function ResultButtonLeaveSpecial()
  GameTooltip:Hide()
end

local function ResultButtonReload(self)
  self.idText:SetText("ID: " .. self.id)

  if pfQuest_config.showids == "1" then
    self.idText:Show()
  else
    self.idText:Hide()
  end

  self.itemColor = nil

  -- update faction
  if self.btype ~= "items" then
    self.factionA:Hide()
    self.factionH:Hide()

    local raceMask = pfDatabase:GetRaceMaskByID(self.id, self.btype)
    if (bit.band(77, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionA:Show()
    end
    if (bit.band(178, raceMask) > 0)  or (raceMask == 0 and self.btype == "quests") then
      self.factionH:Show()
    end
  end

  -- activate fav buttons if needed
  if pfBrowser_fav and pfBrowser_fav[self.btype] and pfBrowser_fav[self.btype][self.id] then
    self.fav.icon:SetVertexColor(1,1,1,1)
  else
    self.fav.icon:SetVertexColor(1,1,1,.1)
  end

  -- actions by search type
  if self.btype == "quests" then
    self.name = pfDB[self.btype]["loc"][self.id]["T"]
    self.text:SetText("|cffffcc00|Hquest:0:0:0:0|h[" .. self.name .. "]|h|r")
  elseif self.btype == "units" or self.btype == "objects" then
    -- Get data from selected database source
    local data, level
    if pfBrowser.dbSource == "questie" and pfQDB and pfQDB.questieDataAvailable then
      if self.btype == "units" then
        data = pfQDB:GetQuestieNPCData(self.id)
      else
        data = pfQDB:GetQuestieObjectData(self.id)
      end
      level = data and data.lvl or ""
    else
      data = pfDB[self.btype]["data"][self.id]
      level = data and data.lvl or ""
    end

    if level and level ~= "" then level = " (" .. level .. ")" end

    -- Add database indicator when viewing Questie
    local dbIndicator = ""
    if pfBrowser.dbSource == "questie" then
      dbIndicator = "|cffff9900[Q]|r "
    end
    self.text:SetText(dbIndicator .. self.name .. "|cffaaaaaa" .. level)

    if data and data.coords then
      self.text:SetTextColor(1,1,1)
    else
      self.text:SetTextColor(.5,.5,.5)
    end
  elseif self.btype == "items" then
    for _, key in ipairs({"U","O","V"}) do
      if items[self.id] and items[self.id][key] then
        self[key]:Show()
      else
        self[key]:Hide()
      end
    end

    self.text:SetText("|cffff5555[?] |cffffffff" .. self.name)

    self.refreshCount = 0
    self:SetScript("OnUpdate", ResultButtonUpdate)
  end

  self.text:SetWidth(self.text:GetStringWidth())
  self:Show()
end

local function ResultButtonCreate(i, resultType)
  local f = CreateFrame("Button", nil, pfBrowser.tabs[resultType].list)
  f:SetPoint("TOPLEFT", pfBrowser.tabs[resultType].list, "TOPLEFT", 10, -i*30 + 5)
  f:SetPoint("BOTTOMRIGHT", pfBrowser.tabs[resultType].list, "TOPRIGHT", 10, -i*30 - 15)
  f:Hide()
  f:SetID(i)

  f.btype = resultType
  f.pfResultButton = true

  f.tex = f:CreateTexture("BACKGROUND")
  f.tex:SetAllPoints(f)
  f.tex:SetTexture(1,1,1, ( compat.mod(i,2) == 1 and .02 or .04))

  -- text properties
  f.text = f:CreateFontString("Caption", "LOW", "GameFontWhite")
  f.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  f.text:SetAllPoints(f)
  f.text:SetJustifyH("CENTER")
  f.idText = f:CreateFontString("ID", "LOW", "GameFontDisable")
  f.idText:SetPoint("LEFT", f, "LEFT", 30, 0)

  -- favourite button
  f.fav = CreateFrame("Button", nil, f)
  f.fav:SetHitRectInsets(-3,-3,-3,-3)
  f.fav:SetPoint("LEFT", 0, 0)
  f.fav:SetWidth(16)
  f.fav:SetHeight(16)
  f.fav.icon = f.fav:CreateTexture("OVERLAY")
  f.fav.icon:SetTexture(pfQuestConfig.path.."\\img\\fav")
  f.fav.icon:SetAllPoints(f.fav)

  -- faction icons
  if resultType ~= "items" then
    f.factionA = f:CreateTexture("OVERLAY")
    f.factionA:SetTexture(pfQuestConfig.path.."\\img\\icon_alliance")
    f.factionA:SetWidth(16)
    f.factionA:SetHeight(16)
    f.factionA:SetPoint("RIGHT", -5, 0)
    f.factionH = f:CreateTexture("OVERLAY")
    f.factionH:SetTexture(pfQuestConfig.path.."\\img\\icon_horde")
    f.factionH:SetWidth(16)
    f.factionH:SetHeight(16)
    f.factionH:SetPoint("RIGHT", -24, 0)
  end

  -- drop, loot, vendor buttons
  if resultType == "items" then
    local buttons = {
      ["U"] = { ["offset"] = -5,  ["icon"] = "icon_npc",    ["parameter"] = "id",   },
      ["O"] = { ["offset"] = -24, ["icon"] = "icon_object", ["parameter"] = "id",   },
      ["V"] = { ["offset"] = -43, ["icon"] = "icon_vendor", ["parameter"] = "name", },
    }

    for button, settings in pairs(buttons) do
      f[button] = CreateFrame("Button", nil, f)
      f[button]:SetHitRectInsets(-3,-3,-3,-3)
      f[button]:SetPoint("RIGHT", settings.offset, 0)
      f[button]:SetWidth(16)
      f[button]:SetHeight(16)

      f[button].buttonType = button
      f[button].parameter = settings.parameter

      f[button].icon = f[button]:CreateTexture("OVERLAY")
      f[button].icon:SetAllPoints(f[button])
      f[button].icon:SetTexture(pfQuestConfig.path.."\\img\\"..settings.icon)

      f[button]:SetScript("OnEnter", ResultButtonEnterSpecial)
      f[button]:SetScript("OnLeave", ResultButtonLeaveSpecial)
      f[button]:SetScript("OnClick", ResultButtonClickSpecial)
    end
  end

  -- bind functions
  f.Reload = ResultButtonReload
  f:SetScript("OnLeave", ResultButtonLeave)
  f:SetScript("OnEnter", ResultButtonEnter)
  f:SetScript("OnClick", ResultButtonClick)
  f.fav:SetScript("OnClick", ResultButtonClickFav)

  return f
end

local function SelectView(view)
  for id, frame in pairs(pfBrowser.tabs) do
    -- Reset all tab buttons to inactive state
    frame.button:SetBackdropColor(0.12, 0.12, 0.12, 1)
    frame.button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    if frame.button.text then
      frame.button.text:SetTextColor(0.7, 0.7, 0.7, 1)
    end
    frame:Hide()
  end
  -- Highlight selected tab
  view.button:SetBackdropColor(0.1, 0.35, 0.3, 1)
  view.button:SetBackdropBorderColor(0.2, 0.7, 0.6, 1)
  if view.button.text then
    view.button.text:SetTextColor(0.2, 1, 0.8, 1)
  end
  view.button:Hide()
  view.button:Show()
  view:Show()
end

-- sets the browser result values when they change
local function RefreshView(i, key, caption)
  pfBrowser.tabs[key].list:Hide()
  pfBrowser.tabs[key].list:SetHeight(i * 30 )
  pfBrowser.tabs[key].list:Show()
  pfBrowser.tabs[key].list:GetParent():SetScrollChild(pfBrowser.tabs[key].list)
  pfBrowser.tabs[key].list:GetParent():SetVerticalScroll(0)

  if not pfBrowser.tabs[key].list.warn then
    pfBrowser.tabs[key].list.warn = pfBrowser.tabs[key].list:CreateFontString("Caption", "LOW", "GameFontWhite")
    pfBrowser.tabs[key].list.warn:SetTextColor(1,.2,.2,1)
    pfBrowser.tabs[key].list.warn:SetJustifyH("CENTER")
    pfBrowser.tabs[key].list.warn:SetPoint("TOP", 5, -5)
    pfBrowser.tabs[key].list.warn:SetText("!! |cffffffff" .. pfQuest_Loc["Too many entries. Results shown"] .. ": " .. search_limit .. "|r !!")
  end

  if i >= search_limit then
    pfBrowser.tabs[key].list.warn:Show()
  else
    pfBrowser.tabs[key].list.warn:Hide()
  end

  -- Update button text via the fontstring
  local buttonText = pfQuest_Loc[caption] .. " " .. "|cffaaaaaa(" .. (i >= search_limit and "*" or i) .. ")"
  if pfBrowser.tabs[key].button.text then
    pfBrowser.tabs[key].button.text:SetText(buttonText)
  else
    pfBrowser.tabs[key].button:SetText(buttonText)
  end
  for j=i+1, table.getn(pfBrowser.tabs[key].buttons) do
    if pfBrowser.tabs[key].buttons[j] then
      pfBrowser.tabs[key].buttons[j]:Hide()
      pfBrowser.tabs[key].buttons[j].id = nil
      pfBrowser.tabs[key].buttons[j].name = nil
    end
  end
end

-- sets up all the browse windows and their activation buttons
local function CreateBrowseWindow(fname, name, parent, anchor, x, y)
  if not parent.tabs then parent.tabs = {} end
  parent.tabs[fname] = pfUI.api.CreateScrollFrame(name, parent)
  parent.tabs[fname]:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -85)
  parent.tabs[fname]:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -10, 45)
  parent.tabs[fname]:Hide()
  parent.tabs[fname].buttons = { }

  -- Dark styled backdrop for scroll area
  parent.tabs[fname].backdrop = CreateFrame("Frame", name .. "Backdrop", parent.tabs[fname])
  parent.tabs[fname].backdrop:SetFrameLevel(1)
  parent.tabs[fname].backdrop:SetPoint("TOPLEFT", parent.tabs[fname], "TOPLEFT", -5, 5)
  parent.tabs[fname].backdrop:SetPoint("BOTTOMRIGHT", parent.tabs[fname], "BOTTOMRIGHT", 5, -5)
  parent.tabs[fname].backdrop:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  parent.tabs[fname].backdrop:SetBackdropColor(0.05, 0.05, 0.05, 0.9)
  parent.tabs[fname].backdrop:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)

  -- Dark styled tab button
  parent.tabs[fname].button = CreateFrame("Button", name .. "Button", parent)
  parent.tabs[fname].button:SetPoint(anchor, x, y)
  parent.tabs[fname].button:SetWidth(153)
  parent.tabs[fname].button:SetHeight(30)
  parent.tabs[fname].button:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    tile = false, tileSize = 1, edgeSize = 1,
  })
  parent.tabs[fname].button:SetBackdropColor(0.12, 0.12, 0.12, 1)
  parent.tabs[fname].button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
  parent.tabs[fname].button.text = parent.tabs[fname].button:CreateFontString(nil, "OVERLAY")
  parent.tabs[fname].button.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
  parent.tabs[fname].button.text:SetPoint("CENTER", 0, 0)
  parent.tabs[fname].button.text:SetTextColor(0.7, 0.7, 0.7, 1)
  parent.tabs[fname].button:SetScript("OnClick", function()
    SelectView(parent.tabs[fname])
  end)
  parent.tabs[fname].button:SetScript("OnEnter", function()
    this:SetBackdropColor(0.2, 0.2, 0.2, 1)
  end)
  parent.tabs[fname].button:SetScript("OnLeave", function()
    this:SetBackdropColor(0.12, 0.12, 0.12, 1)
  end)

  if fname == "units" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Units"],
      pfQuest_Loc["Display related creatures and NPCs"],
    })
  elseif fname == "objects" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Objects"],
      pfQuest_Loc["Display related objects like ores, herbs, chests, etc."],
    })
  elseif fname == "items" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Items"],
      pfQuest_Loc["Display related items"],
    })
  elseif fname == "quests" then
    EnableTooltips(parent.tabs[fname].button, {
      pfQuest_Loc["Quests"],
      pfQuest_Loc["Display related quests"],
    })
  end

  parent.tabs[fname].list = pfUI.api.CreateScrollChild(name .. "Scroll", parent.tabs[fname])
  parent.tabs[fname].list:SetWidth(600)
end

-- browser window
pfBrowser = CreateFrame("Frame", "pfQuestBrowser", UIParent)
pfBrowser:Hide()
pfBrowser:SetWidth(640)
pfBrowser:SetHeight(480)
pfBrowser:SetPoint("CENTER", 0, 0)
pfBrowser:SetFrameStrata("FULLSCREEN_DIALOG")
pfBrowser:SetMovable(true)
pfBrowser:EnableMouse(true)
pfBrowser:RegisterEvent("PLAYER_ENTERING_WORLD")
pfBrowser:SetScript("OnEvent", function()
  -- show all favorites on login if configured
  if pfQuest_config.favonlogin == "1" then
    -- search units
    for id, name in pairs(pfBrowser_fav.units) do
      pfDatabase:SearchMobID(id)
    end

    -- search objects
    for id, name in pairs(pfBrowser_fav.objects) do
      pfDatabase:SearchObjectID(id)
    end

    -- search items
    for id, name in pairs(pfBrowser_fav.items) do
      pfDatabase:SearchItemID(id)
    end

    -- search quests
    for id, name in pairs(pfBrowser_fav.quests) do
      pfDatabase:SearchQuestID(id)
    end
  end
end)
pfBrowser:SetScript("OnMouseDown",function()
  this:StartMoving()
end)

pfBrowser:SetScript("OnMouseUp",function()
  this:StopMovingOrSizing()
end)

pfBrowser:SetScript("OnUpdate", function()
  -- multi-select handling
  if not this.selectState and IsControlKeyDown() and GetMouseFocus() and GetMouseFocus().pfResultButton then
    for id, frame in pairs(pfBrowser.tabs) do
      for id, button in pairs(frame.buttons) do
        if button.name == GetMouseFocus().name then
          button.tex:SetTexture(.3,1,.8,.4)
        end
      end
    end
    this.selectState = "active"

  elseif this.selectState and (this.selectState == "clean" or not IsControlKeyDown()) then
    for id, frame in pairs(pfBrowser.tabs) do
      for id, button in pairs(frame.buttons) do
        if compat.mod(button:GetID(),2) == 1 then
          button.tex:SetTexture(1,1,1,.02)
        else
          button.tex:SetTexture(1,1,1,.04)
        end
      end
    end
    this.selectState = nil
  end
end)

-- Custom dark backdrop (matching Editor/Compare panels)
pfBrowser:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
  insets = { left = 0, right = 0, top = 0, bottom = 0 }
})
pfBrowser:SetBackdropColor(0.08, 0.08, 0.08, 0.95)
pfBrowser:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
table.insert(UISpecialFrames, "pfQuestBrowser")

pfBrowser.title = pfBrowser:CreateFontString("Status", "LOW", "GameFontNormal")
pfBrowser.title:SetFontObject(GameFontWhite)
pfBrowser.title:SetPoint("TOP", pfBrowser, "TOP", 0, -8)
pfBrowser.title:SetJustifyH("LEFT")
pfBrowser.title:SetFont(pfUI.font_default, 14)
pfBrowser.title:SetText("|cff33ffccpf|rQuest Database Browser")

pfBrowser.close = CreateFrame("Button", "pfQuestBrowserClose", pfBrowser)
pfBrowser.close:SetPoint("TOPRIGHT", -4, -4)
pfBrowser.close:SetHeight(20)
pfBrowser.close:SetWidth(20)
pfBrowser.close:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.close:SetBackdropColor(0.3, 0.1, 0.1, 1)
pfBrowser.close:SetBackdropBorderColor(0.4, 0.2, 0.2, 1)
pfBrowser.close.text = pfBrowser.close:CreateFontString(nil, "OVERLAY")
pfBrowser.close.text:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
pfBrowser.close.text:SetPoint("CENTER", 0, 0)
pfBrowser.close.text:SetText("X")
pfBrowser.close.text:SetTextColor(1, 0.3, 0.3, 1)
pfBrowser.close:SetScript("OnClick", function()
  this:GetParent():Hide()
end)
pfBrowser.close:SetScript("OnEnter", function()
  this:SetBackdropColor(0.5, 0.1, 0.1, 1)
end)
pfBrowser.close:SetScript("OnLeave", function()
  this:SetBackdropColor(0.3, 0.1, 0.1, 1)
end)
EnableTooltips(pfBrowser.close, {
  pfQuest_Loc["Close"],
  pfQuest_Loc["Hide browser window"],
})

pfBrowser.journal = CreateFrame("Button", "pfQuestJournalOpen", pfBrowser)
pfBrowser.journal:SetPoint("TOPRIGHT", -30, -4)
pfBrowser.journal:SetHeight(20)
pfBrowser.journal:SetWidth(20)
pfBrowser.journal:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.journal:SetBackdropColor(0.15, 0.15, 0.15, 1)
pfBrowser.journal:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
pfBrowser.journal.texture = pfBrowser.journal:CreateTexture("pfQuestionDialogCloseTex")
pfBrowser.journal.texture:SetTexture(pfQuestConfig.path.."\\img\\tracker_quests")
pfBrowser.journal.texture:ClearAllPoints()
pfBrowser.journal.texture:SetPoint("TOPLEFT", pfBrowser.journal, "TOPLEFT", 2, -2)
pfBrowser.journal.texture:SetPoint("BOTTOMRIGHT", pfBrowser.journal, "BOTTOMRIGHT", -2, 2)
pfBrowser.journal:SetScript("OnClick", function()
  if pfJournal:IsShown() then pfJournal:Hide() else pfJournal:Show() end
end)
pfBrowser.journal:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
end)
pfBrowser.journal:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
end)
EnableTooltips(pfBrowser.journal, {
  pfQuest_Loc["Journal"],
  pfQuest_Loc["Toggle completed quest browser"],
})

pfBrowser.clean = CreateFrame("Button", "pfQuestBrowserClean", pfBrowser)
pfBrowser.clean:SetPoint("TOPRIGHT", pfBrowser, "TOPRIGHT", -5, -30)
pfBrowser.clean:SetHeight(22)
pfBrowser.clean:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.clean:SetBackdropColor(0.15, 0.15, 0.15, 1)
pfBrowser.clean:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
pfBrowser.clean:SetScript("OnClick", function()
  pfMap:DeleteNode("PFDB")
  pfMap:UpdateNodes()
end)
pfBrowser.clean:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
end)
pfBrowser.clean:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
end)
pfBrowser.clean.text = pfBrowser.clean:CreateFontString("Caption", "LOW", "GameFontWhite")
pfBrowser.clean.text:SetAllPoints(pfBrowser.clean)
pfBrowser.clean.text:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.clean.text:SetText(pfQuest_Loc["Clean Map"])
local width = pfBrowser.clean.text:GetStringWidth() > 90 and pfBrowser.clean.text:GetStringWidth() + 20 or 90
pfBrowser.clean:SetWidth(width)
EnableTooltips(pfBrowser.clean, {
  pfQuest_Loc["Clean Map"],
  pfQuest_Loc["Remove all manually searched objects from the map"],
})

CreateBrowseWindow("units", "pfQuestBrowserUnits", pfBrowser, "BOTTOMLEFT", 5, 5)
CreateBrowseWindow("objects", "pfQuestBrowserObjects", pfBrowser, "BOTTOMLEFT", 164, 5)
CreateBrowseWindow("items", "pfQuestBrowserItems", pfBrowser, "BOTTOMRIGHT", -164, 5)
CreateBrowseWindow("quests", "pfQuestBrowserQuests", pfBrowser, "BOTTOMRIGHT", -5, 5)

SelectView(pfBrowser.tabs["units"])

pfBrowser.input = CreateFrame("EditBox", "pfQuestBrowserSearch", pfBrowser)
pfBrowser.input:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.input:SetFontObject("GameFontDisable")
pfBrowser.input:SetAutoFocus(false)
pfBrowser.input:SetText(pfQuest_Loc["Search"])
pfBrowser.input:SetJustifyH("LEFT")
pfBrowser.input:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 5, -30)
pfBrowser.input:SetPoint("BOTTOMRIGHT", pfBrowser.clean, "BOTTOMLEFT", -5, 0)
pfBrowser.input:SetTextInsets(24,12,4,4)

pfBrowser.input.searchIcon = pfBrowser.input:CreateTexture("$parentSearchIcon", "OVERLAY")
pfBrowser.input.searchIcon:SetTexture(pfQuestConfig.path.."\\img\\tracker_search")
pfBrowser.input.searchIcon:SetHeight(14)
pfBrowser.input.searchIcon:SetWidth(14)
pfBrowser.input.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
pfBrowser.input.searchIcon:SetPoint("LEFT", pfBrowser.input, "LEFT", 6, 0)

pfBrowser.input.clearButton = CreateFrame("Button", "$parentClearButton", pfBrowser.input)
pfBrowser.input.clearButton:Hide()
pfBrowser.input.clearButton:SetHeight(17)
pfBrowser.input.clearButton:SetWidth(17)
pfBrowser.input.clearButton:SetPoint("RIGHT", pfBrowser.input, "RIGHT", -3, 0)
pfBrowser.input.clearButton.texture = pfBrowser.input.clearButton:CreateTexture(nil, "ARTWORK")
pfBrowser.input.clearButton.texture:SetTexture(pfQuestConfig.path.."\\img\\tracker_close")
pfBrowser.input.clearButton.texture:SetHeight(17)
pfBrowser.input.clearButton.texture:SetWidth(17)
pfBrowser.input.clearButton.texture:SetAlpha(0.5)
pfBrowser.input.clearButton.texture:SetPoint("TOPLEFT", pfBrowser.input.clearButton, "TOPLEFT", 0, 0)
pfBrowser.input.clearButton:SetScript("OnEnter", function()
  this.texture:SetAlpha(1.0)
end)
pfBrowser.input.clearButton:SetScript("OnLeave", function()
  this.texture:SetAlpha(0.5)
end)
pfBrowser.input.clearButton:SetScript("OnMouseDown", function()
  if this:IsEnabled() then
    this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 1, -1)
  end
end)
pfBrowser.input.clearButton:SetScript("OnMouseUp", function()
  this.texture:SetPoint("TOPLEFT", this, "TOPLEFT", 0, 0)
end)
pfBrowser.input.clearButton:SetScript("OnClick", function()
  PlaySound("igMainMenuOptionCheckBoxOn")
  pfBrowser.input:SetText("")
  --[[
  If there is no focus, then the ClearFocus() method does not call the OnEditFocusLost script.
  In 1.12, there is no HasFocus() method, so there is no way to check for focus. therefore,
  for ease of implementation and to avoid double calling the OnEditFocusLost script, I use the
  SetFocus() method to accurately ensure that the OnEditFocusLost script is called.
  --]]
  pfBrowser.input:SetFocus()
  pfBrowser.input:ClearFocus()
end)

pfBrowser.input:SetScript("OnEscapePressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEnterPressed", function() this:ClearFocus() end)
pfBrowser.input:SetScript("OnEditFocusGained", function()
  this:HighlightText()
  this:SetFontObject("GameFontWhite")
  this:SetBackdropBorderColor(0.2, 0.8, 0.6, 1)  -- Highlight border when focused
  this.searchIcon:SetVertexColor(1.0, 1.0, 1.0)
  if this:GetText() == pfQuest_Loc["Search"] then this:SetText("") end
  this.clearButton:Show()
end)

pfBrowser.input:SetScript("OnEditFocusLost", function()
  this:HighlightText(0, 0)
  this:SetFontObject("GameFontDisable")
  this:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)  -- Normal border when not focused
  this.searchIcon:SetVertexColor(0.6, 0.6, 0.6)
  if this:GetText() == "" then
    this:SetText(pfQuest_Loc["Search"])
    this.clearButton:Hide()
  end
end)

-- This script updates all the search tabs when the search text changes
pfBrowser.input:SetScript("OnTextChanged", function()
  local text = this:GetText()
  if (text == pfQuest_Loc["Search"]) then text = "" end

  local custom = string.find(text, "^custom:")
  text = string.gsub(text, "^custom:", "")

  for _, caption in ipairs({"Units","Objects","Items","Quests"}) do
    local searchType = strlower(caption)

    local data
    if strlen(text) >= 3 or custom then
      -- Check which database to search
      if pfBrowser.dbSource == "questie" and pfQDB and pfQDB.questieDataAvailable then
        -- Search Questie database (only units and objects supported)
        if searchType == "units" or searchType == "objects" then
          data = pfQDB:GetQuestieIDByName(text, searchType, true)
        else
          -- Items and Quests not in Questie data, show empty
          data = {}
        end
      else
        -- Search pfQuest database (default)
        data = pfDatabase:GetIDByName(text, searchType, true, custom)
      end
    else
      data = pfBrowser_fav[searchType]
    end

    local i = 0
    for id, text in pairs(data) do
      i = i + 1

      if i >= search_limit then break end
      pfBrowser.tabs[searchType].buttons[i] = pfBrowser.tabs[searchType].buttons[i] or ResultButtonCreate(i, searchType)
      pfBrowser.tabs[searchType].buttons[i].id = id
      pfBrowser.tabs[searchType].buttons[i].name = text
      pfBrowser.tabs[searchType].buttons[i]:Reload()
    end

    RefreshView(i, searchType, caption)
  end
end)

-- Dark styled search input backdrop
pfBrowser.input:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.input:SetBackdropColor(0.1, 0.1, 0.1, 1)
pfBrowser.input:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

-- Database source toggle (pfQuest / Questie)
pfBrowser.dbSource = "pfquest"  -- Current database source for browsing

-- Database toggle frame with subtle background
pfBrowser.dbToggle = CreateFrame("Frame", "pfQuestBrowserDBToggle", pfBrowser)
pfBrowser.dbToggle:SetPoint("TOPLEFT", pfBrowser, "TOPLEFT", 5, -57)
pfBrowser.dbToggle:SetPoint("TOPRIGHT", pfBrowser, "TOPRIGHT", -5, -57)
pfBrowser.dbToggle:SetHeight(22)
pfBrowser.dbToggle:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.dbToggle:SetBackdropColor(0.06, 0.06, 0.06, 0.8)
pfBrowser.dbToggle:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.5)

-- Label
pfBrowser.dbToggle.label = pfBrowser.dbToggle:CreateFontString(nil, "OVERLAY")
pfBrowser.dbToggle.label:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.dbToggle.label:SetPoint("LEFT", 5, 0)
pfBrowser.dbToggle.label:SetText("Database:")
pfBrowser.dbToggle.label:SetTextColor(0.7, 0.7, 0.7, 1)

-- pfQuest radio button
pfBrowser.dbToggle.pfRadio = CreateFrame("CheckButton", "pfBrowserPfRadio", pfBrowser.dbToggle, "UIRadioButtonTemplate")
pfBrowser.dbToggle.pfRadio:SetPoint("LEFT", pfBrowser.dbToggle.label, "RIGHT", 10, 0)
pfBrowser.dbToggle.pfRadio:SetChecked(true)
pfBrowser.dbToggle.pfRadio:SetScript("OnClick", function()
  pfBrowser.dbSource = "pfquest"
  pfBrowser.dbToggle.pfRadio:SetChecked(true)
  pfBrowser.dbToggle.questieRadio:SetChecked(false)
  -- Refresh search results
  pfBrowser.input:GetScript("OnTextChanged")()
end)

pfBrowser.dbToggle.pfLabel = pfBrowser.dbToggle:CreateFontString(nil, "OVERLAY")
pfBrowser.dbToggle.pfLabel:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.dbToggle.pfLabel:SetPoint("LEFT", pfBrowser.dbToggle.pfRadio, "RIGHT", 2, 0)
pfBrowser.dbToggle.pfLabel:SetText("pfQuest")
pfBrowser.dbToggle.pfLabel:SetTextColor(0.2, 1, 0.8, 1)

-- Questie radio button
pfBrowser.dbToggle.questieRadio = CreateFrame("CheckButton", "pfBrowserQuestieRadio", pfBrowser.dbToggle, "UIRadioButtonTemplate")
pfBrowser.dbToggle.questieRadio:SetPoint("LEFT", pfBrowser.dbToggle.pfLabel, "RIGHT", 15, 0)
pfBrowser.dbToggle.questieRadio:SetChecked(false)
pfBrowser.dbToggle.questieRadio:SetScript("OnClick", function()
  if pfQDB and pfQDB.questieDataAvailable then
    pfBrowser.dbSource = "questie"
    pfBrowser.dbToggle.pfRadio:SetChecked(false)
    pfBrowser.dbToggle.questieRadio:SetChecked(true)
    -- Refresh search results
    pfBrowser.input:GetScript("OnTextChanged")()
  else
    -- Questie data not available, revert
    pfBrowser.dbToggle.questieRadio:SetChecked(false)
    pfBrowser.dbToggle.pfRadio:SetChecked(true)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Questie database not available.")
  end
end)

pfBrowser.dbToggle.questieLabel = pfBrowser.dbToggle:CreateFontString(nil, "OVERLAY")
pfBrowser.dbToggle.questieLabel:SetFont(pfUI.font_default, pfUI_config.global.font_size, "OUTLINE")
pfBrowser.dbToggle.questieLabel:SetPoint("LEFT", pfBrowser.dbToggle.questieRadio, "RIGHT", 2, 0)
pfBrowser.dbToggle.questieLabel:SetText("Questie")
pfBrowser.dbToggle.questieLabel:SetTextColor(1, 0.6, 0.2, 1)

-- Editor button
pfBrowser.editorBtn = CreateFrame("Button", "pfBrowserEditorBtn", pfBrowser.dbToggle)
pfBrowser.editorBtn:SetPoint("RIGHT", pfBrowser.dbToggle, "RIGHT", -5, 0)
pfBrowser.editorBtn:SetWidth(50)
pfBrowser.editorBtn:SetHeight(18)
pfBrowser.editorBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.editorBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
pfBrowser.editorBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

pfBrowser.editorBtn.text = pfBrowser.editorBtn:CreateFontString(nil, "OVERLAY")
pfBrowser.editorBtn.text:SetFont(pfUI.font_default, pfUI_config.global.font_size - 1, "OUTLINE")
pfBrowser.editorBtn.text:SetPoint("CENTER", 0, 0)
pfBrowser.editorBtn.text:SetText("Editor")

pfBrowser.editorBtn:SetScript("OnClick", function()
  if pfQDB and pfQDB.ShowEditorPanel then
    -- Try to get currently focused result button
    local focus = GetMouseFocus()
    if focus and focus.pfResultButton and focus.id and (focus.btype == "units" or focus.btype == "objects") then
      pfQDB:ShowEditorPanel(focus.id, focus.btype, pfBrowser.dbSource or "pfquest")
    else
      pfQDB:ShowEditorPanel(nil, nil, pfBrowser.dbSource or "pfquest")
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Editor panel not available.")
  end
end)
pfBrowser.editorBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
end)
pfBrowser.editorBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
end)

EnableTooltips(pfBrowser.editorBtn, {
  "Database Editor",
  "Edit database entries (units/objects)",
})

-- Compare button
pfBrowser.compareBtn = CreateFrame("Button", "pfBrowserCompareBtn", pfBrowser.dbToggle)
pfBrowser.compareBtn:SetPoint("RIGHT", pfBrowser.editorBtn, "LEFT", -5, 0)
pfBrowser.compareBtn:SetWidth(60)
pfBrowser.compareBtn:SetHeight(18)
pfBrowser.compareBtn:SetBackdrop({
  bgFile = "Interface\\Buttons\\WHITE8X8",
  edgeFile = "Interface\\Buttons\\WHITE8X8",
  tile = false, tileSize = 1, edgeSize = 1,
})
pfBrowser.compareBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
pfBrowser.compareBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

pfBrowser.compareBtn.text = pfBrowser.compareBtn:CreateFontString(nil, "OVERLAY")
pfBrowser.compareBtn.text:SetFont(pfUI.font_default, pfUI_config.global.font_size - 1, "OUTLINE")
pfBrowser.compareBtn.text:SetPoint("CENTER", 0, 0)
pfBrowser.compareBtn.text:SetText("Compare")

pfBrowser.compareBtn:SetScript("OnClick", function()
  if pfQDB and pfQDB.ShowComparePanel then
    -- Try to get currently focused result button
    local focus = GetMouseFocus()
    if focus and focus.pfResultButton and focus.id and (focus.btype == "units" or focus.btype == "objects") then
      pfQDB:ShowComparePanel(focus.id, focus.btype)
    else
      pfQDB:ShowComparePanel()
    end
  else
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Compare panel not available.")
  end
end)
pfBrowser.compareBtn:SetScript("OnEnter", function()
  this:SetBackdropColor(0.25, 0.25, 0.25, 1)
end)
pfBrowser.compareBtn:SetScript("OnLeave", function()
  this:SetBackdropColor(0.15, 0.15, 0.15, 1)
end)

EnableTooltips(pfBrowser.compareBtn, {
  "Compare Databases",
  "Open the database comparison panel",
})
