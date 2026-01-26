-- Zone mapping between pfQuest and Questie
-- Also provides zone names and categorization for UI

pfQDB = pfQDB or {}
pfQDB.zones = pfQDB.zones or {}

-- Zone information table
-- Format: [zoneID] = { name = "Zone Name", expansion = "classic"|"tbc"|"wotlk", continent = "Continent" }
-- Only includes main world zones where quests/spawns occur
pfQDB.zones.info = {
  -- Eastern Kingdoms - Classic
  [1] = { name = "Dun Morogh", expansion = "classic", continent = "Eastern Kingdoms" },
  [3] = { name = "Badlands", expansion = "classic", continent = "Eastern Kingdoms" },
  [4] = { name = "Blasted Lands", expansion = "classic", continent = "Eastern Kingdoms" },
  [8] = { name = "Swamp of Sorrows", expansion = "classic", continent = "Eastern Kingdoms" },
  [10] = { name = "Duskwood", expansion = "classic", continent = "Eastern Kingdoms" },
  [11] = { name = "Wetlands", expansion = "classic", continent = "Eastern Kingdoms" },
  [12] = { name = "Elwynn Forest", expansion = "classic", continent = "Eastern Kingdoms" },
  [25] = { name = "Blackrock Mountain", expansion = "classic", continent = "Eastern Kingdoms" },
  [28] = { name = "Western Plaguelands", expansion = "classic", continent = "Eastern Kingdoms" },
  [33] = { name = "Stranglethorn Vale", expansion = "classic", continent = "Eastern Kingdoms" },
  [36] = { name = "Alterac Mountains", expansion = "classic", continent = "Eastern Kingdoms" },
  [38] = { name = "Loch Modan", expansion = "classic", continent = "Eastern Kingdoms" },
  [40] = { name = "Westfall", expansion = "classic", continent = "Eastern Kingdoms" },
  [41] = { name = "Deadwind Pass", expansion = "classic", continent = "Eastern Kingdoms" },
  [44] = { name = "Redridge Mountains", expansion = "classic", continent = "Eastern Kingdoms" },
  [45] = { name = "Arathi Highlands", expansion = "classic", continent = "Eastern Kingdoms" },
  [46] = { name = "Burning Steppes", expansion = "classic", continent = "Eastern Kingdoms" },
  [47] = { name = "The Hinterlands", expansion = "classic", continent = "Eastern Kingdoms" },
  [51] = { name = "Searing Gorge", expansion = "classic", continent = "Eastern Kingdoms" },
  [85] = { name = "Tirisfal Glades", expansion = "classic", continent = "Eastern Kingdoms" },
  [130] = { name = "Silverpine Forest", expansion = "classic", continent = "Eastern Kingdoms" },
  [139] = { name = "Eastern Plaguelands", expansion = "classic", continent = "Eastern Kingdoms" },
  [267] = { name = "Hillsbrad Foothills", expansion = "classic", continent = "Eastern Kingdoms" },

  -- Kalimdor - Classic
  [14] = { name = "Durotar", expansion = "classic", continent = "Kalimdor" },
  [15] = { name = "Dustwallow Marsh", expansion = "classic", continent = "Kalimdor" },
  [16] = { name = "Azshara", expansion = "classic", continent = "Kalimdor" },
  [17] = { name = "The Barrens", expansion = "classic", continent = "Kalimdor" },
  [141] = { name = "Teldrassil", expansion = "classic", continent = "Kalimdor" },
  [148] = { name = "Darkshore", expansion = "classic", continent = "Kalimdor" },
  [215] = { name = "Mulgore", expansion = "classic", continent = "Kalimdor" },
  [331] = { name = "Ashenvale", expansion = "classic", continent = "Kalimdor" },
  [357] = { name = "Feralas", expansion = "classic", continent = "Kalimdor" },
  [361] = { name = "Felwood", expansion = "classic", continent = "Kalimdor" },
  [400] = { name = "Thousand Needles", expansion = "classic", continent = "Kalimdor" },
  [405] = { name = "Desolace", expansion = "classic", continent = "Kalimdor" },
  [406] = { name = "Stonetalon Mountains", expansion = "classic", continent = "Kalimdor" },
  [440] = { name = "Tanaris", expansion = "classic", continent = "Kalimdor" },
  [490] = { name = "Un'Goro Crater", expansion = "classic", continent = "Kalimdor" },
  [493] = { name = "Moonglade", expansion = "classic", continent = "Kalimdor" },
  [618] = { name = "Winterspring", expansion = "classic", continent = "Kalimdor" },
  [1377] = { name = "Silithus", expansion = "classic", continent = "Kalimdor" },

  -- PvP Zones - Classic
  [2597] = { name = "Alterac Valley", expansion = "classic", continent = "Battlegrounds" },

  -- Cities - Classic
  [1497] = { name = "Undercity", expansion = "classic", continent = "Cities" },
  [1519] = { name = "Stormwind City", expansion = "classic", continent = "Cities" },
  [1537] = { name = "Ironforge", expansion = "classic", continent = "Cities" },
  [1637] = { name = "Orgrimmar", expansion = "classic", continent = "Cities" },
  [1638] = { name = "Thunder Bluff", expansion = "classic", continent = "Cities" },
  [1657] = { name = "Darnassus", expansion = "classic", continent = "Cities" },

  -- TBC - Eastern Kingdoms
  [3430] = { name = "Eversong Woods", expansion = "tbc", continent = "Eastern Kingdoms" },
  [3433] = { name = "Ghostlands", expansion = "tbc", continent = "Eastern Kingdoms" },
  [4080] = { name = "Isle of Quel'Danas", expansion = "tbc", continent = "Eastern Kingdoms" },

  -- TBC - Kalimdor
  [3524] = { name = "Azuremyst Isle", expansion = "tbc", continent = "Kalimdor" },
  [3525] = { name = "Bloodmyst Isle", expansion = "tbc", continent = "Kalimdor" },

  -- TBC - Outland
  [3483] = { name = "Hellfire Peninsula", expansion = "tbc", continent = "Outland" },
  [3518] = { name = "Nagrand", expansion = "tbc", continent = "Outland" },
  [3519] = { name = "Terokkar Forest", expansion = "tbc", continent = "Outland" },
  [3520] = { name = "Shadowmoon Valley", expansion = "tbc", continent = "Outland" },
  [3521] = { name = "Zangarmarsh", expansion = "tbc", continent = "Outland" },
  [3522] = { name = "Blade's Edge Mountains", expansion = "tbc", continent = "Outland" },
  [3523] = { name = "Netherstorm", expansion = "tbc", continent = "Outland" },

  -- TBC - Cities
  [3487] = { name = "Silvermoon City", expansion = "tbc", continent = "Cities" },
  [3557] = { name = "The Exodar", expansion = "tbc", continent = "Cities" },
  [3703] = { name = "Shattrath City", expansion = "tbc", continent = "Cities" },

  -- WotLK - Northrend
  [65] = { name = "Dragonblight", expansion = "wotlk", continent = "Northrend" },
  [66] = { name = "Zul'Drak", expansion = "wotlk", continent = "Northrend" },
  [67] = { name = "The Storm Peaks", expansion = "wotlk", continent = "Northrend" },
  [210] = { name = "Icecrown", expansion = "wotlk", continent = "Northrend" },
  [394] = { name = "Grizzly Hills", expansion = "wotlk", continent = "Northrend" },
  [495] = { name = "Howling Fjord", expansion = "wotlk", continent = "Northrend" },
  [2817] = { name = "Crystalsong Forest", expansion = "wotlk", continent = "Northrend" },
  [3537] = { name = "Borean Tundra", expansion = "wotlk", continent = "Northrend" },
  [3711] = { name = "Sholazar Basin", expansion = "wotlk", continent = "Northrend" },
  [4197] = { name = "Wintergrasp", expansion = "wotlk", continent = "Northrend" },

  -- WotLK - Cities
  [4395] = { name = "Dalaran", expansion = "wotlk", continent = "Cities" },
}

-- Questie areaId to pfQuest zoneID mapping
-- Most zones share the same ID between Questie and pfQuest
-- This table only needs entries where IDs differ
pfQDB.zones.questieToPf = {
  -- If IDs are the same, no entry needed
  -- Add any exceptions here as they are discovered
  -- [questieAreaId] = pfQuestZoneId
}

-- Reverse mapping (pfQuest to Questie)
pfQDB.zones.pfToQuestie = {
  -- Built dynamically from questieToPf if needed
}

-- Get zone name by ID
function pfQDB:GetZoneName(zoneID)
  if self.zones.info[zoneID] then
    return self.zones.info[zoneID].name
  end
  return "Unknown Zone (" .. tostring(zoneID) .. ")"
end

-- Get zone expansion
function pfQDB:GetZoneExpansion(zoneID)
  if self.zones.info[zoneID] then
    return self.zones.info[zoneID].expansion
  end
  return "unknown"
end

-- Get zone continent
function pfQDB:GetZoneContinent(zoneID)
  if self.zones.info[zoneID] then
    return self.zones.info[zoneID].continent
  end
  return "Unknown"
end

-- Convert Questie areaId to pfQuest zoneID
function pfQDB:QuestieZoneToPf(questieAreaId)
  -- Check for explicit mapping first
  if self.zones.questieToPf[questieAreaId] then
    return self.zones.questieToPf[questieAreaId]
  end
  -- Default: same ID
  return questieAreaId
end

-- Convert pfQuest zoneID to Questie areaId
function pfQDB:PfZoneToQuestie(pfZoneId)
  -- Check for explicit mapping first
  if self.zones.pfToQuestie[pfZoneId] then
    return self.zones.pfToQuestie[pfZoneId]
  end
  -- Default: same ID
  return pfZoneId
end

-- Get all zones by expansion
function pfQDB:GetZonesByExpansion(expansion)
  local zones = {}
  for zoneID, info in pairs(self.zones.info) do
    if info.expansion == expansion then
      table.insert(zones, { id = zoneID, name = info.name, continent = info.continent })
    end
  end
  -- Sort by name
  table.sort(zones, function(a, b) return a.name < b.name end)
  return zones
end

-- Get all zones (sorted by name)
function pfQDB:GetAllZones()
  local zones = {}
  for zoneID, info in pairs(self.zones.info) do
    table.insert(zones, { id = zoneID, name = info.name, expansion = info.expansion, continent = info.continent })
  end
  -- Sort by name
  table.sort(zones, function(a, b) return a.name < b.name end)
  return zones
end

-- Get all zones by continent
function pfQDB:GetZonesByContinent(continent)
  local zones = {}
  for zoneID, info in pairs(self.zones.info) do
    if info.continent == continent then
      table.insert(zones, { id = zoneID, name = info.name, expansion = info.expansion })
    end
  end
  -- Sort by name
  table.sort(zones, function(a, b) return a.name < b.name end)
  return zones
end

-- Get all continents
function pfQDB:GetContinents()
  local continents = {}
  local seen = {}
  for _, info in pairs(self.zones.info) do
    if not seen[info.continent] then
      seen[info.continent] = true
      table.insert(continents, info.continent)
    end
  end
  table.sort(continents)
  return continents
end

-- Load zone mapping (called during init)
function pfQDB:LoadZoneMapping()
  -- Build reverse mapping
  for questieId, pfId in pairs(self.zones.questieToPf) do
    self.zones.pfToQuestie[pfId] = questieId
  end
end
