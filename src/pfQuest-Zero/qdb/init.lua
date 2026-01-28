-- pfQuest Database Selector
-- Allows per-zone selection between pfQuest and Questie databases

pfQDB = pfQDB or {}

-- ============================================================================
-- Holiday Detection and Filtering (must load before database.lua)
-- ============================================================================

-- Cache for current active holidays (detected on load) - TABLE for multiple holidays
pfQDB.detectedHolidays = nil  -- Table of active holiday IDs

-- Map of holiday names from calendar events to our holiday IDs
pfQDB.HOLIDAY_CALENDAR_MAP = {
  ["Lunar Festival"] = "lunar",
  ["Love is in the Air"] = "love",
  ["Noblegarden"] = "noblegarden",
  ["Children's Week"] = "children",
  ["Midsummer Fire Festival"] = "midsummer",
  ["Midsummer"] = "midsummer",
  ["Brewfest"] = "brewfest",
  ["Harvest Festival"] = "harvest",
  ["Hallow's End"] = "hallows",
  ["Pilgrim's Bounty"] = "pilgrims",
  ["Feast of Winter Veil"] = "winter",
  ["Winter Veil"] = "winter",
  ["Darkmoon Faire"] = "darkmoon",
  ["Stranglethorn Fishing Extravaganza"] = "fishing",
  ["Call to Arms"] = "pvp",
  ["Ahn'Qiraj War Effort"] = "aq",
  ["Scourge Invasion"] = "scourge",
}

-- Map holiday IDs to display names
pfQDB.HOLIDAY_NAMES = {
  ["none"] = "None (Always Show)",
  ["lunar"] = "Lunar Festival",
  ["love"] = "Love is in the Air",
  ["noblegarden"] = "Noblegarden",
  ["children"] = "Children's Week",
  ["midsummer"] = "Midsummer Fire Festival",
  ["brewfest"] = "Brewfest",
  ["harvest"] = "Harvest Festival",
  ["hallows"] = "Hallow's End",
  ["pilgrims"] = "Pilgrim's Bounty",
  ["winter"] = "Feast of Winter Veil",
  ["darkmoon"] = "Darkmoon Faire",
  ["fishing"] = "Stranglethorn Fishing Extravaganza",
  ["pvp"] = "Call to Arms",
  ["aq"] = "Ahn'Qiraj War Effort",
  ["scourge"] = "Scourge Invasion",
  ["pirates"] = "Pirates' Day",
}

-- Detect current holidays from calendar (runs on addon load)
-- Returns a TABLE of active holiday IDs (Synastria can have multiple!)
function pfQDB:DetectCurrentHolidays()
  local holidays = {}
  local holidayNames = {}

  -- Try to get today's date info using WotLK API
  local currentDay = 1
  if CalendarGetDate then
    -- WotLK 3.3.5 Calendar API
    local weekday, month, day, year = CalendarGetDate()
    currentDay = day or 1
  end

  -- Check calendar events for today
  if CalendarGetNumDayEvents then
    local numEvents = CalendarGetNumDayEvents(0, currentDay)
    for i = 1, numEvents do
      local title, hour, minute, calendarType, sequenceType, eventType, texture, modStatus, inviteStatus, invitedBy, difficultyInfo = CalendarGetDayEvent(0, currentDay, i)
      if title and calendarType == "HOLIDAY" then
        -- Check if this matches one of our known holidays
        for calendarName, holidayId in pairs(self.HOLIDAY_CALENDAR_MAP) do
          if strfind(title, calendarName) then
            -- Add to table if not already present
            if not holidays[holidayId] then
              holidays[holidayId] = true
              table.insert(holidayNames, title)
            end
          end
        end
      end
    end
  end

  -- Convert to indexed table for storage
  local holidayList = {}
  for holidayId, _ in pairs(holidays) do
    table.insert(holidayList, holidayId)
  end

  -- Store detected holidays
  if table.getn(holidayList) > 0 then
    self.detectedHolidays = holidayList
  else
    self.detectedHolidays = {}  -- Empty table = no holidays
  end

  return self.detectedHolidays, holidayNames
end

-- Get all current active holidays as a table
function pfQDB:GetActiveHolidays()
  -- Allow manual override via config (single holiday becomes table)
  if pfQuest_config and pfQuest_config.activeHoliday and pfQuest_config.activeHoliday ~= "auto" then
    if pfQuest_config.activeHoliday == "none" then
      return {}
    end
    return { pfQuest_config.activeHoliday }
  end

  -- Use detected holidays
  if self.detectedHolidays == nil then
    self:DetectCurrentHolidays()
  end

  return self.detectedHolidays or {}
end

-- Legacy function - returns first active holiday or "none"
function pfQDB:GetActiveHoliday()
  local holidays = self:GetActiveHolidays()
  if holidays and table.getn(holidays) > 0 then
    return holidays[1]
  end
  return "none"
end

-- Check if a specific holiday is currently active
function pfQDB:IsHolidayActive(holidayId)
  if not holidayId or holidayId == "none" then
    return true  -- "none" means always active
  end

  local activeHolidays = self:GetActiveHolidays()
  for _, active in ipairs(activeHolidays) do
    if active == holidayId then
      return true
    end
  end
  return false
end

-- Set holiday manually (for testing or manual override)
function pfQDB:SetActiveHoliday(holidayId)
  pfQuest_config = pfQuest_config or {}
  pfQuest_config.activeHoliday = holidayId
  DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Active holiday set to: " .. (holidayId or "none"))
end

-- Get formatted string of active holidays for display
function pfQDB:GetActiveHolidaysString()
  local holidays = self:GetActiveHolidays()
  if not holidays or table.getn(holidays) == 0 then
    return "|cffaaaaaaNo active holidays|r"
  end

  -- Map IDs to names
  local names = {}
  for _, holidayId in ipairs(holidays) do
    local name = self.HOLIDAY_NAMES[holidayId] or holidayId
    table.insert(names, "|cffffff00" .. name .. "|r")
  end

  return table.concat(names, ", ")
end

-- Check if an entity should be shown based on its holiday binding
-- Returns true if entity should be shown, false if it should be hidden
function pfQDB:ShouldShowEntity(entityType, entityId)
  -- Ensure pfQuest_customDB exists
  if not pfQuest_customDB then return true end

  -- Get custom entry to check for holiday binding
  local custom = pfQuest_customDB[entityType] and pfQuest_customDB[entityType][entityId]

  -- If no custom data or no holiday binding, always show
  if not custom or not custom.holiday or custom.holiday == "none" then
    return true
  end

  -- Check if the entity's holiday is in the active holidays list
  return self:IsHolidayActive(custom.holiday)
end

-- ============================================================================
-- Database Selection Configuration
-- ============================================================================

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

      -- Print active holidays (supports multiple on Synastria)
      if pfQDB and pfQDB.GetActiveHolidaysString then
        DEFAULT_CHAT_FRAME:AddMessage("|cff33ffccpfQuest|r: Active Holidays: " .. pfQDB:GetActiveHolidaysString())
      end
    end
  end)
end)
