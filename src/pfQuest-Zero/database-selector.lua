-- Database Selector
-- Provides unified interface for accessing data from pfQuest or Questie

pfQDB = pfQDB or {}

-- Get unit data with database selection
-- Returns data in pfQuest format regardless of source
function pfQDB:GetUnitData(unitId)
  local units = pfDB["units"]["data"]

  -- First check if pfQuest has this unit
  local pfData = units[unitId]
  if not pfData then
    -- pfQuest doesn't have this unit, try Questie
    if self.questieDataAvailable then
      return self:ConvertNPC(unitId)
    end
    return nil
  end

  -- Check if we should use Questie for any zones this unit spawns in
  if not self.questieDataAvailable then
    return pfData
  end

  -- Get zone preferences for this unit's spawn locations
  local useQuestie = false
  if pfData.coords then
    for _, coord in pairs(pfData.coords) do
      local zoneID = coord[3]
      if self:GetPreferredDB(zoneID) == "questie" then
        useQuestie = true
        break
      end
    end
  end

  -- If any zone prefers Questie and we have Questie data, merge/replace
  if useQuestie then
    local questieData = self:ConvertNPC(unitId)
    if questieData then
      -- Return merged data based on zone preferences
      return self:MergeUnitData(unitId, pfData, questieData)
    end
  end

  return pfData
end

-- Get object data with database selection
function pfQDB:GetObjectData(objectId)
  local objects = pfDB["objects"]["data"]

  local pfData = objects[objectId]
  if not pfData then
    if self.questieDataAvailable then
      return self:ConvertObject(objectId)
    end
    return nil
  end

  if not self.questieDataAvailable then
    return pfData
  end

  -- Check zone preferences
  local useQuestie = false
  if pfData.coords then
    for _, coord in pairs(pfData.coords) do
      local zoneID = coord[3]
      if self:GetPreferredDB(zoneID) == "questie" then
        useQuestie = true
        break
      end
    end
  end

  if useQuestie then
    local questieData = self:ConvertObject(objectId)
    if questieData then
      return self:MergeObjectData(objectId, pfData, questieData)
    end
  end

  return pfData
end

-- Merge unit data from pfQuest and Questie based on zone preferences
function pfQDB:MergeUnitData(unitId, pfData, questieData)
  local merged = {
    coords = {},
    lvl = pfData.lvl or questieData.lvl,
    fac = pfData.fac or questieData.fac,
  }

  -- Track which zones we've handled
  local zoneCoords = {}

  -- First, add pfQuest coords for zones that prefer pfQuest
  if pfData.coords then
    for _, coord in pairs(pfData.coords) do
      local zoneID = coord[3]
      local pref = self:GetPreferredDB(zoneID)

      if pref == "pfquest" then
        if not zoneCoords[zoneID] then
          zoneCoords[zoneID] = {}
        end
        table.insert(zoneCoords[zoneID], coord)
      end
    end
  end

  -- Then, add Questie coords for zones that prefer Questie
  if questieData.coords then
    for _, coord in pairs(questieData.coords) do
      local zoneID = coord[3]
      local pref = self:GetPreferredDB(zoneID)

      if pref == "questie" then
        if not zoneCoords[zoneID] then
          zoneCoords[zoneID] = {}
        end
        table.insert(zoneCoords[zoneID], coord)
      end
    end
  end

  -- Flatten into final coords array
  for _, coords in pairs(zoneCoords) do
    for _, coord in pairs(coords) do
      table.insert(merged.coords, coord)
    end
  end

  return merged
end

-- Merge object data from pfQuest and Questie based on zone preferences
function pfQDB:MergeObjectData(objectId, pfData, questieData)
  local merged = {
    coords = {},
    fac = pfData.fac or questieData.fac,
  }

  local zoneCoords = {}

  if pfData.coords then
    for _, coord in pairs(pfData.coords) do
      local zoneID = coord[3]
      local pref = self:GetPreferredDB(zoneID)

      if pref == "pfquest" then
        if not zoneCoords[zoneID] then
          zoneCoords[zoneID] = {}
        end
        table.insert(zoneCoords[zoneID], coord)
      end
    end
  end

  if questieData.coords then
    for _, coord in pairs(questieData.coords) do
      local zoneID = coord[3]
      local pref = self:GetPreferredDB(zoneID)

      if pref == "questie" then
        if not zoneCoords[zoneID] then
          zoneCoords[zoneID] = {}
        end
        table.insert(zoneCoords[zoneID], coord)
      end
    end
  end

  for _, coords in pairs(zoneCoords) do
    for _, coord in pairs(coords) do
      table.insert(merged.coords, coord)
    end
  end

  return merged
end

-- Filter coordinates by zone preference
-- Takes a coords table and unitId/objectId, returns filtered coords
function pfQDB:FilterCoordsByPreference(coords, entityId, entityType)
  if not self.questieDataAvailable then
    return coords
  end

  local filtered = {}
  local questieCoordsByZone = {}

  -- Check which zones prefer Questie
  local needQuestie = false
  for _, coord in pairs(coords) do
    local zoneID = coord[3]
    if self:GetPreferredDB(zoneID) == "questie" then
      needQuestie = true
      break
    end
  end

  if not needQuestie then
    return coords
  end

  -- Load Questie coords for this entity
  local questieData
  if entityType == "unit" then
    questieData = self:ConvertNPC(entityId)
  elseif entityType == "object" then
    questieData = self:ConvertObject(entityId)
  end

  if questieData and questieData.coords then
    for _, coord in pairs(questieData.coords) do
      local zoneID = coord[3]
      if not questieCoordsByZone[zoneID] then
        questieCoordsByZone[zoneID] = {}
      end
      table.insert(questieCoordsByZone[zoneID], coord)
    end
  end

  -- Build filtered coords
  for _, coord in pairs(coords) do
    local zoneID = coord[3]
    local pref = self:GetPreferredDB(zoneID)

    if pref == "questie" and questieCoordsByZone[zoneID] then
      -- Use Questie coords for this zone (only add once per zone)
      if questieCoordsByZone[zoneID] then
        for _, qCoord in pairs(questieCoordsByZone[zoneID]) do
          table.insert(filtered, qCoord)
        end
        questieCoordsByZone[zoneID] = nil  -- Mark as added
      end
    else
      -- Use pfQuest coord
      table.insert(filtered, coord)
    end
  end

  return filtered
end

-- Get unit name with database selection
function pfQDB:GetUnitName(unitId)
  -- Check pfQuest first
  local pfName = pfDB.units.loc and pfDB.units.loc[unitId]
  if pfName then
    return pfName
  end

  -- Fall back to Questie
  if self.questieDataAvailable then
    return self:GetQuestieNPCName(unitId)
  end

  return nil
end

-- Get object name with database selection
function pfQDB:GetObjectName(objectId)
  local pfName = pfDB.objects.loc and pfDB.objects.loc[objectId]
  if pfName then
    return pfName
  end

  if self.questieDataAvailable then
    return self:GetQuestieObjectName(objectId)
  end

  return nil
end

-- Check if database selector is enabled for a zone
function pfQDB:IsQuestieEnabledForZone(zoneID)
  if not self.questieDataAvailable then
    return false
  end
  return self:GetPreferredDB(zoneID) == "questie"
end

-- Get database status string for display
function pfQDB:GetStatusString()
  if not self.questieDataAvailable then
    return "|cff33ffccpfQuest|r database only"
  end

  -- Count zones using each database
  local pfCount = 0
  local questieCount = 0

  if pfQuest_config and pfQuest_config.zoneDB then
    for _, db in pairs(pfQuest_config.zoneDB) do
      if db == "questie" then
        questieCount = questieCount + 1
      elseif db == "pfquest" then
        pfCount = pfCount + 1
      end
    end
  end

  if questieCount == 0 then
    return "|cff33ffccpfQuest|r database (default), Questie data available"
  else
    return "|cff33ffccpfQuest|r: " .. pfCount .. " zones, |cffff9900Questie|r: " .. questieCount .. " zones"
  end
end
