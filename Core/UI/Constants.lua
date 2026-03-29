local _, ns = ...

local UI = {}
ns.UI = UI

-- Upgrade tracks (same as BetterGearCompare BisUI)
UI.UPGRADE_TRACKS = {
  { key = "VETERAN", bonusID = 12782, contextBonus = 13332 },
  { key = "CHAMPION", bonusID = 12790, contextBonus = nil },
  { key = "HERO", bonusID = 12798, contextBonus = 13334 },
  { key = "MYTH", bonusID = 12806, contextBonus = 13335 },
}

UI.CLASS_FROM_SLUG = {
  ["death-knight"] = "DEATHKNIGHT",
  ["demon-hunter"] = "DEMONHUNTER",
  ["druid"] = "DRUID",
  ["evoker"] = "EVOKER",
  ["hunter"] = "HUNTER",
  ["mage"] = "MAGE",
  ["monk"] = "MONK",
  ["paladin"] = "PALADIN",
  ["priest"] = "PRIEST",
  ["rogue"] = "ROGUE",
  ["shaman"] = "SHAMAN",
  ["warlock"] = "WARLOCK",
  ["warrior"] = "WARRIOR",
}

UI.GEAR_SLOT_ORDER = {
  "Head",
  "Neck",
  "Shoulders",
  "Back",
  "Chest",
  "Wrist",
  "Gloves",
  "Belt",
  "Legs",
  "Feet",
  "Rings",
  "Trinket",
  "Main-Hand",
  "Off-Hand",
}

UI.ENCHANT_SLOT_ORDER = {
  "Main-Hand",
  "Rings",
  "Head",
  "Shoulders",
  "Chest",
  "Legs",
  "Feet",
  "Back",
}

UI.CONSUMABLE_ORDER = {
  "Flask",
  "Combat Potion",
  "Health Potion",
  "Weapon Buff",
}

UI.QUALITY_COLORS = {
  [0] = { 0.62, 0.62, 0.62 },
  [1] = { 1, 1, 1 },
  [2] = { 0.12, 1, 0 },
  [3] = { 0, 0.44, 0.87 },
  [4] = { 0.64, 0.21, 0.93 },
  [5] = { 1, 0.50, 0 },
}

UI.TABS = {
  { key = "gear", label = "TAB_GEAR" },
  { key = "enchants", label = "TAB_ENCHANTS" },
  { key = "gems", label = "TAB_GEMS" },
  { key = "consumables", label = "TAB_CONSUMABLES" },
  { key = "talents", label = "TAB_TALENTS" },
  { key = "stats", label = "TAB_STATS" },
}

UI.MODE_BUTTONS = {
  { key = "mythicplus", label = "MODE_MYTHICPLUS" },
  { key = "raid", label = "MODE_RAID" },
}

UI.ROW_HEIGHT = 28
UI.HEADER_HEIGHT = 22
UI.ICON_SIZE = 24
UI.FRAME_WIDTH = 450
UI.FRAME_HEIGHT = 630
UI.TALENT_ROW_HEIGHT = 70
UI.STAT_ROW_HEIGHT = 32

-- Stat name -> BGC weight key mapping
UI.STAT_KEY_MAP = {
  ["Intellect"] = "ITEM_MOD_INTELLECT_SHORT",
  ["Strength"] = "ITEM_MOD_STRENGTH_SHORT",
  ["Agility"] = "ITEM_MOD_AGILITY_SHORT",
  ["Stamina"] = "ITEM_MOD_STAMINA_SHORT",
  ["Crit"] = "ITEM_MOD_CRIT_RATING_SHORT",
  ["Haste"] = "ITEM_MOD_HASTE_RATING_SHORT",
  ["Mastery"] = "ITEM_MOD_MASTERY_RATING_SHORT",
  ["Vers"] = "ITEM_MOD_VERSATILITY",
}

-- Stat bar colors by priority order
UI.STAT_BAR_COLORS = {
  { 0.35, 0.82, 1.0 },
  { 0.30, 0.70, 0.90 },
  { 0.25, 0.58, 0.78 },
  { 0.20, 0.46, 0.66 },
  { 0.15, 0.34, 0.54 },
}

-- Data key -> locale key mappings (English data keys from _Data.lua -> L[] keys)
UI.SLOT_L10N = {
  ["Head"] = "SLOT_HEAD",
  ["Neck"] = "SLOT_NECK",
  ["Shoulders"] = "SLOT_SHOULDERS",
  ["Back"] = "SLOT_BACK",
  ["Chest"] = "SLOT_CHEST",
  ["Wrist"] = "SLOT_WRIST",
  ["Gloves"] = "SLOT_GLOVES",
  ["Belt"] = "SLOT_BELT",
  ["Legs"] = "SLOT_LEGS",
  ["Feet"] = "SLOT_FEET",
  ["Rings"] = "SLOT_RINGS",
  ["Trinket"] = "SLOT_TRINKET",
  ["Main-Hand"] = "SLOT_MAIN_HAND",
  ["Off-Hand"] = "SLOT_OFF_HAND",
}

UI.CONSUMABLE_L10N = {
  ["Flask"] = "CONSUMABLE_FLASK",
  ["Combat Potion"] = "CONSUMABLE_COMBAT_POTION",
  ["Health Potion"] = "CONSUMABLE_HEALTH_POTION",
  ["Weapon Buff"] = "CONSUMABLE_WEAPON_BUFF",
}

UI.STAT_L10N = {
  ["Intellect"] = "STAT_INTELLECT",
  ["Strength"] = "STAT_STRENGTH",
  ["Agility"] = "STAT_AGILITY",
  ["Stamina"] = "STAT_STAMINA",
  ["Crit"] = "STAT_CRIT",
  ["Haste"] = "STAT_HASTE",
  ["Mastery"] = "STAT_MASTERY",
  ["Vers"] = "STAT_VERS",
}

-- Shared mutable state
UI.SPEC_NAMES = {}
UI.mainFrame = nil
UI.scrollArea = nil
UI.specDropdown = nil
UI.tierDropdown = nil
UI.selectedSpecID = nil
UI.selectedTrackIndex = 4
UI.selectedTab = "gear"
UI.selectedMode = "mythicplus"
UI.rowPool = {}
UI.headerPool = {}
UI.talentRowPool = {}
UI.statRowPool = {}
UI.pendingItems = {}
UI.tabButtons = {}
UI.modeButtons = {}
UI.exportBGCBtn = nil
