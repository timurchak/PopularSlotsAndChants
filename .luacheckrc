-- .luacheckrc for PopularSlotsAndChants (WoW Retail Addon)
-- Targets Lua 5.1 (WoW runtime)

std = "lua51"
max_line_length = false   -- StyLua handles formatting; luacheck handles semantics
cache = true
jobs = 4

-- Exclude vendored/generated/staging files
exclude_files = {
  "Libs/",
  "libs/",
  "Release/",
  "PopularSlotsAndChants_Data.lua",
  ".luacheckrc",
}

-- Warnings to suppress for common WoW addon patterns
ignore = {
  "11./SLASH_.*",      -- slash command globals are expected
  "212/self",          -- unused 'self' in method definitions
  "212/event",         -- unused 'event' in OnEvent handlers
  "212/elapsed",       -- unused 'elapsed' in OnUpdate handlers
  "211/addonName",     -- unused first return from `local addonName, ns = ...`
  "212/addonName",     -- same when treated as argument
  "212/contentWidth",  -- unused arg in UI.Populate* functions (kept for consistent API)
  "331/ns",            -- ns is set (mutated) then exported, not read directly
  "122/_G",            -- accessing _G.BetterGearCompare is intentional
  "143/table",         -- table.unpack exists in Lua 5.2+; WoW provides compat
}

-- Globals the addon WRITES
globals = {
  -- SavedVariables (declared in .toc)
  "PopularSlotsAndChantsDB",

  -- Slash command registration (Blizzard pattern)
  "SlashCmdList",
  "SLASH_POPULARSLOTS1",
  "SLASH_POPULARSLOTS2",

  -- Static popup dialog registration
  "StaticPopupDialogs",
}

-- Globals the addon READS (WoW API surface used by this addon)
read_globals = {
  -- Lua 5.1 extras provided by WoW
  "format",
  "unpack",

  -- Core frame/widget API
  "CreateFrame",
  "UIParent",

  -- Namespaced C_ APIs
  "C_Timer",
  "C_Spell",

  -- Dropdown API
  "UIDropDownMenu_SetWidth",
  "UIDropDownMenu_Initialize",
  "UIDropDownMenu_CreateInfo",
  "UIDropDownMenu_AddButton",
  "UIDropDownMenu_SetText",

  -- Specialization info
  "GetSpecialization",
  "GetSpecializationInfo",
  "GetSpecializationInfoByID",

  -- Item info
  "GetItemInfo",

  -- Tooltip
  "GameTooltip",

  -- Static popup
  "StaticPopup_Show",

  -- Input handling
  "IsShiftKeyDown",
  "HandleModifiedItemClick",

  -- Locale
  "GetLocale",

  -- Library loader
  "LibStub",

  -- UI constants
  "RAID_CLASS_COLORS",
  "CLOSE",

  -- Misc
  "print",

  -- Standard globals
  "_G",
}
