-- Questie Data Loader
-- Provides access to pre-converted Questie database (static data)

pfQDB = pfQDB or {}

-- Get NPC data from static Questie database
-- Returns data in pfQuest format: { coords = {{x, y, zone, respawn}, ...}, lvl = "X-Y", fac = "A/H" }
function pfQDB:GetQuestieNPCData(npcId)
  if not self.questieDataAvailable then
    return nil
  end

  -- Check each expansion's data
  -- WotLK has the most complete data, check it first
  if self.questie.wotlk and self.questie.wotlk.units and self.questie.wotlk.units[npcId] then
    return self.questie.wotlk.units[npcId]
  end

  if self.questie.tbc and self.questie.tbc.units and self.questie.tbc.units[npcId] then
    return self.questie.tbc.units[npcId]
  end

  if self.questie.classic and self.questie.classic.units and self.questie.classic.units[npcId] then
    return self.questie.classic.units[npcId]
  end

  return nil
end

-- Get Object data from static Questie database
function pfQDB:GetQuestieObjectData(objectId)
  if not self.questieDataAvailable then
    return nil
  end

  -- Check each expansion's data
  if self.questie.wotlk and self.questie.wotlk.objects and self.questie.wotlk.objects[objectId] then
    return self.questie.wotlk.objects[objectId]
  end

  if self.questie.tbc and self.questie.tbc.objects and self.questie.tbc.objects[objectId] then
    return self.questie.tbc.objects[objectId]
  end

  if self.questie.classic and self.questie.classic.objects and self.questie.classic.objects[objectId] then
    return self.questie.classic.objects[objectId]
  end

  return nil
end

-- Get NPC name from static Questie database
function pfQDB:GetQuestieNPCName(npcId)
  if not self.questieDataAvailable then
    return nil
  end

  if self.questie.wotlk and self.questie.wotlk.units_loc and self.questie.wotlk.units_loc[npcId] then
    return self.questie.wotlk.units_loc[npcId]
  end

  if self.questie.tbc and self.questie.tbc.units_loc and self.questie.tbc.units_loc[npcId] then
    return self.questie.tbc.units_loc[npcId]
  end

  if self.questie.classic and self.questie.classic.units_loc and self.questie.classic.units_loc[npcId] then
    return self.questie.classic.units_loc[npcId]
  end

  return nil
end

-- Get Object name from static Questie database
function pfQDB:GetQuestieObjectName(objectId)
  if not self.questieDataAvailable then
    return nil
  end

  if self.questie.wotlk and self.questie.wotlk.objects_loc and self.questie.wotlk.objects_loc[objectId] then
    return self.questie.wotlk.objects_loc[objectId]
  end

  if self.questie.tbc and self.questie.tbc.objects_loc and self.questie.tbc.objects_loc[objectId] then
    return self.questie.tbc.objects_loc[objectId]
  end

  if self.questie.classic and self.questie.classic.objects_loc and self.questie.classic.objects_loc[objectId] then
    return self.questie.classic.objects_loc[objectId]
  end

  return nil
end

-- ConvertNPC - returns Questie NPC data in pfQuest format (for compatibility with database-selector.lua)
function pfQDB:ConvertNPC(npcId)
  return self:GetQuestieNPCData(npcId)
end

-- ConvertObject - returns Questie Object data in pfQuest format (for compatibility with database-selector.lua)
function pfQDB:ConvertObject(objectId)
  return self:GetQuestieObjectData(objectId)
end

-- Get NPC data for a specific zone only
function pfQDB:GetQuestieNPCDataForZone(npcId, zoneId)
  local data = self:GetQuestieNPCData(npcId)
  if not data or not data.coords then
    return nil
  end

  -- Filter coords for this zone only
  local zoneCoords = {}
  for _, coord in pairs(data.coords) do
    if coord[3] == zoneId then
      table.insert(zoneCoords, coord)
    end
  end

  if #zoneCoords == 0 then
    return nil
  end

  return {
    coords = zoneCoords,
    lvl = data.lvl,
    fac = data.fac,
  }
end

-- Get Object data for a specific zone only
function pfQDB:GetQuestieObjectDataForZone(objectId, zoneId)
  local data = self:GetQuestieObjectData(objectId)
  if not data or not data.coords then
    return nil
  end

  -- Filter coords for this zone only
  local zoneCoords = {}
  for _, coord in pairs(data.coords) do
    if coord[3] == zoneId then
      table.insert(zoneCoords, coord)
    end
  end

  if #zoneCoords == 0 then
    return nil
  end

  return {
    coords = zoneCoords,
  }
end

-- Search Questie database by name (similar to pfDatabase:GetIDByName)
-- Returns table of {id = name} pairs
function pfQDB:GetQuestieIDByName(name, db, partial)
  if not self.questieDataAvailable then
    return {}
  end

  local ret = {}
  local expansions = { "wotlk", "tbc", "classic" }

  -- Determine which loc table to search
  local locKey
  if db == "units" then
    locKey = "units_loc"
  elseif db == "objects" then
    locKey = "objects_loc"
  else
    return ret  -- Only units and objects supported for now
  end

  for _, exp in ipairs(expansions) do
    if self.questie[exp] and self.questie[exp][locKey] then
      for id, loc in pairs(self.questie[exp][locKey]) do
        if loc and name then
          local match = false
          if partial == true and strfind(strlower(loc), strlower(name), 1, true) then
            match = true
          elseif partial == "LOWER" and strlower(loc) == strlower(name) then
            match = true
          elseif loc == name then
            match = true
          end

          if match and not ret[id] then
            ret[id] = loc
          end
        end
      end
    end
  end

  return ret
end

-- Show Questie unit spawns on map (similar to pfDatabase:SearchMobID)
-- Returns map zones that have spawns
function pfQDB:SearchQuestieMobID(mobId, meta)
  if not self.questieDataAvailable then
    return {}
  end

  local data = self:GetQuestieNPCData(mobId)
  if not data or not data.coords then
    return {}
  end

  local name = self:GetQuestieNPCName(mobId) or ("Unit " .. mobId)
  local maps = {}

  for _, coord in pairs(data.coords) do
    local x, y, zone = coord[1], coord[2], coord[3]
    if zone and x and y then
      maps[zone] = maps[zone] or 0
      maps[zone] = maps[zone] + 1

      -- Add node to map
      local node = {
        title = name,
        zone = zone,
        x = x,
        y = y,
        level = data.lvl,
        spawn = mobId,
        spawntype = "Unit",
        respawn = coord[4] or 0,
        layer = 4,
        texture = "Interface\\AddOns\\pfQuest-Zero\\img\\available_c",
        dbSource = "questie",
        vertex = { 1, 0.6, 0.2 },  -- Orange tint for Questie
      }

      if meta and meta.addon then
        node.addon = meta.addon
      end

      pfMap:AddNode(node)
    end
  end

  return maps
end

-- Show Questie object spawns on map (similar to pfDatabase:SearchObjectID)
-- Returns map zones that have spawns
function pfQDB:SearchQuestieObjectID(objectId, meta)
  if not self.questieDataAvailable then
    return {}
  end

  local data = self:GetQuestieObjectData(objectId)
  if not data or not data.coords then
    return {}
  end

  local name = self:GetQuestieObjectName(objectId) or ("Object " .. objectId)
  local maps = {}

  for _, coord in pairs(data.coords) do
    local x, y, zone = coord[1], coord[2], coord[3]
    if zone and x and y then
      maps[zone] = maps[zone] or 0
      maps[zone] = maps[zone] + 1

      -- Add node to map
      local node = {
        title = name,
        zone = zone,
        x = x,
        y = y,
        spawn = objectId,
        spawntype = "Object",
        layer = 4,
        texture = "Interface\\AddOns\\pfQuest-Zero\\img\\available_c",
        dbSource = "questie",
        vertex = { 1, 0.6, 0.2 },  -- Orange tint for Questie
      }

      if meta and meta.addon then
        node.addon = meta.addon
      end

      pfMap:AddNode(node)
    end
  end

  return maps
end

-- Check if Questie has data for a specific zone
function pfQDB:HasQuestieDataForZone(zoneId)
  if not self.questieDataAvailable then
    return false
  end

  -- Check if any expansion has unit or object data for this zone
  local expansions = { "classic", "tbc", "wotlk" }

  for _, exp in ipairs(expansions) do
    if self.questie[exp] then
      -- Check units
      if self.questie[exp].units then
        for _, unitData in pairs(self.questie[exp].units) do
          if unitData.coords then
            for _, coord in pairs(unitData.coords) do
              if coord[3] == zoneId then
                return true
              end
            end
          end
        end
      end

      -- Check objects
      if self.questie[exp].objects then
        for _, objData in pairs(self.questie[exp].objects) do
          if objData.coords then
            for _, coord in pairs(objData.coords) do
              if coord[3] == zoneId then
                return true
              end
            end
          end
        end
      end
    end
  end

  return false
end
