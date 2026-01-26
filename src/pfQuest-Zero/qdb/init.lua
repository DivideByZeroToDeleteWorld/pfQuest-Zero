-- pfQuest Database Selector
-- Allows per-zone selection between pfQuest and Questie databases

pfQDB = pfQDB or {}

-- Configuration defaults
pfQDB.defaults = {
  globalDefault = "pfquest",  -- Default database source
  enabled = true,             -- Feature enabled
}

-- Runtime state
pfQDB.initialized = false
pfQDB.questieDataAvailable = false

-- Cached converted data from Questie (static data)
pfQDB.cache = {
  units = {},
  objects = {},
  quests = {},
}

-- Check if static Questie data is available
function pfQDB:CheckQuestieDataAvailable()
  -- Check for static Questie data (loaded from qdb-*.lua files)
  if self.questie and
     self.questie.classic and self.questie.classic.units and
     self.questie.wotlk and self.questie.wotlk.units then
    self.questieDataAvailable = true
    return true
  end

  self.questieDataAvailable = false
  return false
end

-- Get the preferred database for a zone
function pfQDB:GetPreferredDB(zoneID)
  if not self.questieDataAvailable then
    return "pfquest"
  end

  -- Check per-zone preference
  if pfQuest_config and pfQuest_config.zoneDB and pfQuest_config.zoneDB[zoneID] then
    return pfQuest_config.zoneDB[zoneID]
  end

  -- Return global default
  return (pfQuest_config and pfQuest_config.zoneDBDefault) or self.defaults.globalDefault
end

-- Set the preferred database for a zone
function pfQDB:SetPreferredDB(zoneID, database)
  pfQuest_config = pfQuest_config or {}
  pfQuest_config.zoneDB = pfQuest_config.zoneDB or {}

  if database == "pfquest" or database == "questie" then
    pfQuest_config.zoneDB[zoneID] = database
  end
end

-- Set the global default database
function pfQDB:SetGlobalDefault(database)
  pfQuest_config = pfQuest_config or {}
  if database == "pfquest" or database == "questie" then
    pfQuest_config.zoneDBDefault = database
  end
end

-- Clear all per-zone preferences
function pfQDB:ResetZonePreferences()
  if pfQuest_config then
    pfQuest_config.zoneDB = {}
  end
end

-- Initialize the database selector
function pfQDB:Init()
  if self.initialized then return end

  -- Check static Questie data availability
  self:CheckQuestieDataAvailable()

  -- Load zone mapping
  if self.LoadZoneMapping then
    self:LoadZoneMapping()
  end

  self.initialized = true

  -- Print status
  if self.questieDataAvailable then
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Database selector ready. Questie data available.")
  end
end

-- Create initialization frame
local initFrame = CreateFrame("Frame", "pfQDBInit", UIParent)
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
  -- Delay init slightly to ensure all addons are loaded
  this.elapsed = 0
  this:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed > 1 then
      pfQDB:Init()
      this:SetScript("OnUpdate", nil)
      this:Hide()
    end
  end)
end)

-- Zone change notification frame
local zoneChangeFrame = CreateFrame("Frame", "pfQDBZoneChange", UIParent)
zoneChangeFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneChangeFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneChangeFrame.lastZone = nil

zoneChangeFrame:SetScript("OnEvent", function()
  -- Delay slightly to let zone data update
  this.elapsed = 0
  this:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed > 0.5 then
      this:SetScript("OnUpdate", nil)

      -- Get current zone info
      local zoneName = GetRealZoneText()
      if not zoneName or zoneName == "" then return end

      -- Skip if same zone (prevents spam)
      if zoneName == zoneChangeFrame.lastZone then return end
      zoneChangeFrame.lastZone = zoneName

      -- Get zone ID using pfMap
      local zoneID = pfMap and pfMap.GetMapIDByName and pfMap:GetMapIDByName(zoneName)
      if not zoneID then return end

      -- Get preferred database for this zone
      local dbPref = pfQDB:GetPreferredDB(zoneID)

      -- Format database name with color
      local dbText
      if dbPref == "questie" then
        dbText = "|cffff9900Questie|r"
      else
        dbText = "|cff33ffccpfQuest|r"
      end

      -- Print to chat
      DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: " .. zoneName .. " (ID: " .. zoneID .. ") using " .. dbText .. " database")
    end
  end)
end)
