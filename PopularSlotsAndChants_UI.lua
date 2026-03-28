local _, ns = ...

local L = ns.L

-- Upgrade tracks (same as BetterGearCompare BisUI)
local UPGRADE_TRACKS = {
  { key = "VETERAN",  bonusID = 12782, contextBonus = 13332 },
  { key = "CHAMPION", bonusID = 12790, contextBonus = nil },
  { key = "HERO",     bonusID = 12798, contextBonus = 13334 },
  { key = "MYTH",     bonusID = 12806, contextBonus = 13335 },
}

local CLASS_FROM_SLUG = {
  ["death-knight"] = "DEATHKNIGHT",
  ["demon-hunter"] = "DEMONHUNTER",
  ["druid"]        = "DRUID",
  ["evoker"]       = "EVOKER",
  ["hunter"]       = "HUNTER",
  ["mage"]         = "MAGE",
  ["monk"]         = "MONK",
  ["paladin"]      = "PALADIN",
  ["priest"]       = "PRIEST",
  ["rogue"]        = "ROGUE",
  ["shaman"]       = "SHAMAN",
  ["warlock"]      = "WARLOCK",
  ["warrior"]      = "WARRIOR",
}

local GEAR_SLOT_ORDER = {
  "Head", "Neck", "Shoulders", "Back", "Chest", "Wrist",
  "Gloves", "Belt", "Legs", "Feet", "Rings", "Trinket",
  "Main-Hand", "Off-Hand",
}

local ENCHANT_SLOT_ORDER = {
  "Main-Hand", "Rings", "Head", "Shoulders", "Chest", "Legs", "Feet", "Back",
}

local CONSUMABLE_ORDER = {
  "Flask", "Combat Potion", "Health Potion", "Weapon Buff",
}

local QUALITY_COLORS = {
  [0] = { 0.62, 0.62, 0.62 },
  [1] = { 1, 1, 1 },
  [2] = { 0.12, 1, 0 },
  [3] = { 0, 0.44, 0.87 },
  [4] = { 0.64, 0.21, 0.93 },
  [5] = { 1, 0.50, 0 },
}

local TABS = {
  { key = "gear",        label = "TAB_GEAR" },
  { key = "enchants",    label = "TAB_ENCHANTS" },
  { key = "gems",        label = "TAB_GEMS" },
  { key = "consumables", label = "TAB_CONSUMABLES" },
  { key = "talents",     label = "TAB_TALENTS" },
  { key = "stats",       label = "TAB_STATS" },
}

local ROW_HEIGHT = 28
local HEADER_HEIGHT = 22
local ICON_SIZE = 24
local FRAME_WIDTH = 450
local FRAME_HEIGHT = 630

local SPEC_NAMES = {}

local mainFrame
local scrollArea
local specDropdown
local tierDropdown

local selectedSpecID
local selectedTrackIndex
local selectedTab = "gear"
local selectedMode = "mythicplus"

local rowPool = {}
local headerPool = {}
local talentRowPool = {}
local statRowPool = {}
local pendingItems = {}
local tabButtons = {}
local modeButtons = {}
local exportBGCBtn

-- Copy popup dialog
StaticPopupDialogs["PSC_COPY_EXPORT"] = {
  text = "Copy talent export string:",
  button1 = CLOSE or "Close",
  hasEditBox = true,
  editBoxWidth = 350,
  OnShow = function(self)
    self.EditBox:SetText(self.data or "")
    self.EditBox:SetFocus()
    self.EditBox:HighlightText()
  end,
  EditBoxOnEscapePressed = function(self)
    self:GetParent():Hide()
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}

-- Helpers

local function ItemString(itemID)
  local track = UPGRADE_TRACKS[selectedTrackIndex]
  if track.contextBonus then
    return "item:" .. itemID .. "::::::::::::2:" .. track.bonusID .. ":" .. track.contextBonus
  else
    return "item:" .. itemID .. "::::::::::::1:" .. track.bonusID
  end
end

local function GetClassColor(classSlug)
  local classToken = CLASS_FROM_SLUG[classSlug]
  if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
    return RAID_CLASS_COLORS[classToken]
  end
  return { r = 1, g = 1, b = 1, colorStr = "ffffffff" }
end

local function GetSpecDisplayName(specID, slug)
  if SPEC_NAMES[specID] then
    return SPEC_NAMES[specID]
  end
  if not slug then return tostring(specID) end
  local classSlug = slug:match("^([^/]+)/")
  local specSlug = slug:match("/(.+)$")
  if not classSlug or not specSlug then return slug end

  -- Try WoW API
  local _, name, _, icon = GetSpecializationInfoByID(specID)
  if name then
    local cc = GetClassColor(classSlug)
    local display = string.format("|c%s%s|r", cc.colorStr, name)
    SPEC_NAMES[specID] = display
    return display
  end

  -- Fallback: prettify slug
  local pretty = specSlug:gsub("-", " "):gsub("(%a)([%w_']*)", function(a, b) return a:upper() .. b end)
  SPEC_NAMES[specID] = pretty
  return pretty
end

local function GetCurrentSpecSlug()
  local specIndex = GetSpecialization()
  if not specIndex then return nil end
  local specID = GetSpecializationInfo(specIndex)
  if not specID then return nil end
  local data = ns.ArchonData
  if data and data.specIDs and data.specIDs[specID] then
    return specID
  end
  return nil
end

-- Row/Header pool

local function GetOrCreateHeader(parent, index)
  if headerPool[index] then return headerPool[index] end

  local header = CreateFrame("Frame", nil, parent)
  header:SetHeight(HEADER_HEIGHT)

  local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", 4, 0)
  text:SetTextColor(0.35, 0.82, 1)
  header.text = text

  local line = header:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
  line:SetColorTexture(0.2, 0.2, 0.3, 0.8)

  headerPool[index] = header
  return header
end

local function GetOrCreateRow(parent, index)
  if rowPool[index] then return rowPool[index] end

  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(ROW_HEIGHT)
  row:EnableMouse(true)

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(ICON_SIZE, ICON_SIZE)
  icon:SetPoint("LEFT", 6, 0)
  row.icon = icon

  local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nameText:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  nameText:SetPoint("RIGHT", row, "RIGHT", -60, 0)
  nameText:SetJustifyH("LEFT")
  nameText:SetWordWrap(false)
  row.nameText = nameText

  local popText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  popText:SetPoint("RIGHT", row, "RIGHT", -6, 0)
  popText:SetJustifyH("RIGHT")
  popText:SetTextColor(0.7, 0.7, 0.7)
  row.popText = popText

  -- Highlight on hover
  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(1, 1, 1, 0.05)

  -- Tooltip on hover
  row:SetScript("OnEnter", function(self)
    if self.itemLink then
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetHyperlink(self.itemLink)
      GameTooltip:Show()
    end
  end)
  row:SetScript("OnLeave", function()
    GameTooltip:Hide()
  end)

  -- Shift+click to link in chat
  row:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() and self.itemLink then
      HandleModifiedItemClick(self.itemLink)
    end
  end)

  rowPool[index] = row
  return row
end

-- Populate functions

local function HideAll()
  for _, row in pairs(rowPool) do row:Hide() end
  for _, header in pairs(headerPool) do header:Hide() end
  for _, row in pairs(talentRowPool) do row:Hide() end
  for _, row in pairs(statRowPool) do row:Hide() end
  if exportBGCBtn then exportBGCBtn:Hide() end
end

local function SetupItemRow(row, itemID, popularity, useTrack)
  local itemStr = useTrack and ItemString(itemID) or ("item:" .. itemID)
  local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemStr)

  if itemName then
    row.icon:SetTexture(itemTexture)
    local qc = QUALITY_COLORS[itemQuality] or QUALITY_COLORS[1]
    row.nameText:SetText(itemName)
    row.nameText:SetTextColor(qc[1], qc[2], qc[3])
    row.itemLink = itemLink or itemStr
  else
    row.icon:SetTexture(134400) -- question mark
    row.nameText:SetText(L["LOADING"] .. " (ID: " .. itemID .. ")")
    row.nameText:SetTextColor(0.5, 0.5, 0.5)
    row.itemLink = nil
    pendingItems[itemID] = true
  end

  row.popText:SetText(string.format(L["POPULARITY"], popularity))
end

local function PopulateGear(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, slotName in ipairs(GEAR_SLOT_ORDER) do
    local items = specData.gear[slotName]
    if items and #items > 0 then
      headerIndex = headerIndex + 1
      local header = GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(slotName)
      header:Show()
      yOffset = yOffset + HEADER_HEIGHT

      for _, entry in ipairs(items) do
        rowIndex = rowIndex + 1
        local row = GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        SetupItemRow(row, entry.id, entry.popularity, true)
        row:Show()
        yOffset = yOffset + ROW_HEIGHT
      end
    end
  end

  return yOffset
end

local function PopulateEnchants(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, slotName in ipairs(ENCHANT_SLOT_ORDER) do
    local items = specData.enchants[slotName]
    if items and #items > 0 then
      headerIndex = headerIndex + 1
      local header = GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(slotName)
      header:Show()
      yOffset = yOffset + HEADER_HEIGHT

      for _, entry in ipairs(items) do
        rowIndex = rowIndex + 1
        local row = GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        SetupItemRow(row, entry.id, entry.popularity, false)
        row:Show()
        yOffset = yOffset + ROW_HEIGHT
      end
    end
  end

  return yOffset
end

local function PopulateGems(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  -- Epic Gems
  if specData.epicGems and #specData.epicGems > 0 then
    headerIndex = headerIndex + 1
    local header = GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    header.text:SetText(L["HEADER_EPIC_GEMS"])
    header:Show()
    yOffset = yOffset + HEADER_HEIGHT

    for _, entry in ipairs(specData.epicGems) do
      rowIndex = rowIndex + 1
      local row = GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      SetupItemRow(row, entry.id, entry.popularity, false)
      row:Show()
      yOffset = yOffset + ROW_HEIGHT
    end
  end

  -- Regular Gems
  if specData.gems and #specData.gems > 0 then
    headerIndex = headerIndex + 1
    local header = GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    header.text:SetText(L["HEADER_GEMS"])
    header:Show()
    yOffset = yOffset + HEADER_HEIGHT

    for _, entry in ipairs(specData.gems) do
      rowIndex = rowIndex + 1
      local row = GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      SetupItemRow(row, entry.id, entry.popularity, false)
      row:Show()
      yOffset = yOffset + ROW_HEIGHT
    end
  end

  return yOffset
end

local function PopulateConsumables(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, category in ipairs(CONSUMABLE_ORDER) do
    local entry = specData.consumables[category]
    if entry then
      headerIndex = headerIndex + 1
      local header = GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(category)
      header:Show()
      yOffset = yOffset + HEADER_HEIGHT

      rowIndex = rowIndex + 1
      local row = GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      SetupItemRow(row, entry.id, entry.popularity, false)
      row:Show()
      yOffset = yOffset + ROW_HEIGHT
    end
  end

  -- Extra consumables not in order list
  if specData.consumables then
    for category, entry in pairs(specData.consumables) do
      local found = false
      for _, c in ipairs(CONSUMABLE_ORDER) do
        if c == category then found = true; break end
      end
      if not found then
        headerIndex = headerIndex + 1
        local header = GetOrCreateHeader(content, headerIndex)
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        header.text:SetText(category)
        header:Show()
        yOffset = yOffset + HEADER_HEIGHT

        rowIndex = rowIndex + 1
        local row = GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        SetupItemRow(row, entry.id, entry.popularity, false)
        row:Show()
        yOffset = yOffset + ROW_HEIGHT
      end
    end
  end

  return yOffset
end

-- Talent row: header + title + hero tree + popularity + Copy + Apply buttons

local TALENT_ROW_HEIGHT = 70

local function ShowCopyPopup(exportCode)
  StaticPopup_Show("PSC_COPY_EXPORT", nil, nil, exportCode)
end

local function GetOrCreateTalentRow(parent, index)
  if talentRowPool[index] then return talentRowPool[index] end

  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetHeight(TALENT_ROW_HEIGHT)
  row:EnableMouse(true)
  row:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
  row:SetBackdropColor(0.1, 0.1, 0.15, 0.5)

  local titleText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleText:SetPoint("TOPLEFT", row, "TOPLEFT", 8, -6)
  titleText:SetTextColor(1, 1, 1)
  row.titleText = titleText

  local heroText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  heroText:SetPoint("TOPLEFT", titleText, "BOTTOMLEFT", 0, -2)
  heroText:SetTextColor(0.35, 0.82, 1)
  row.heroText = heroText

  local popText = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  popText:SetPoint("TOPRIGHT", row, "TOPRIGHT", -8, -6)
  popText:SetJustifyH("RIGHT")
  popText:SetTextColor(0.7, 0.7, 0.7)
  row.popText = popText

  -- Copy button
  local copyBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
  copyBtn:SetSize(70, 22)
  copyBtn:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 8, 6)
  copyBtn:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
  })
  copyBtn:SetBackdropColor(0.15, 0.25, 0.35, 1)
  copyBtn:SetBackdropBorderColor(0.35, 0.82, 1, 0.6)
  local copyText = copyBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  copyText:SetPoint("CENTER")
  copyText:SetText(L["COPY_EXPORT"])
  copyText:SetTextColor(0.35, 0.82, 1)
  copyBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.2, 0.35, 0.5, 1)
  end)
  copyBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.15, 0.25, 0.35, 1)
  end)
  row.copyBtn = copyBtn

  -- Apply button → Open Talents button
  local openBtn = CreateFrame("Button", nil, row, "BackdropTemplate")
  openBtn:SetSize(90, 22)
  openBtn:SetPoint("LEFT", copyBtn, "RIGHT", 6, 0)
  openBtn:SetBackdrop({
    bgFile = "Interface/Buttons/WHITE8X8",
    edgeFile = "Interface/Buttons/WHITE8X8",
    edgeSize = 1,
  })
  openBtn:SetBackdropColor(0.15, 0.35, 0.15, 1)
  openBtn:SetBackdropBorderColor(0.2, 0.8, 0.2, 0.6)
  local openText = openBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  openText:SetPoint("CENTER")
  openText:SetText(L["OPEN_TALENTS"])
  openText:SetTextColor(0.2, 1, 0.2)
  openBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.2, 0.5, 0.2, 1)
  end)
  openBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(0.15, 0.35, 0.15, 1)
  end)
  row.openBtn = openBtn

  talentRowPool[index] = row
  return row
end

local function PopulateTalents(content, contentWidth, specData)
  local yOffset = 0
  local headerIndex = 0

  if not specData.talents or not specData.talents.builds then
    return yOffset
  end

  -- Hero Trees summary
  if specData.talents.heroTrees and #specData.talents.heroTrees > 0 then
    headerIndex = headerIndex + 1
    local header = GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    local names = {}
    for _, ht in ipairs(specData.talents.heroTrees) do
      table.insert(names, ht.name .. " (#" .. ht.rank .. ")")
    end
    header.text:SetText("Hero Trees: " .. table.concat(names, ", "))
    header:Show()
    yOffset = yOffset + HEADER_HEIGHT
  end

  -- Builds
  headerIndex = headerIndex + 1
  local header = GetOrCreateHeader(content, headerIndex)
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
  header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
  header.text:SetText("Talent Builds")
  header:Show()
  yOffset = yOffset + HEADER_HEIGHT

  for i, build in ipairs(specData.talents.builds) do
    local row = GetOrCreateTalentRow(content, i)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    row:SetPoint("RIGHT", content, "RIGHT", 0, 0)

    local titleStr = build.title or ("Build #" .. i)
    row.titleText:SetText(titleStr)

    if build.heroTree and build.heroTree ~= "" then
      row.heroText:SetText(string.format(L["HERO_TREE"], build.heroTree))
      row.heroText:Show()
    else
      row.heroText:Hide()
    end

    row.popText:SetText(string.format(L["POPULARITY"], build.popularity))

    local exportCode = build.exportCode
    row.copyBtn:SetScript("OnClick", function()
      ShowCopyPopup(exportCode)
    end)

    row.openBtn:SetScript("OnClick", function()
      if not PlayerSpellsFrame or not PlayerSpellsFrame:IsShown() then
        TogglePlayerSpellsFrame(PlayerSpellsUtil.FrameTabs.ClassTalents)
      end
    end)

    row:Show()
    yOffset = yOffset + TALENT_ROW_HEIGHT + 4
  end

  return yOffset
end

-- Stat name → BGC weight key mapping
local STAT_KEY_MAP = {
  ["Intellect"] = "ITEM_MOD_INTELLECT_SHORT",
  ["Strength"]  = "ITEM_MOD_STRENGTH_SHORT",
  ["Agility"]   = "ITEM_MOD_AGILITY_SHORT",
  ["Stamina"]   = "ITEM_MOD_STAMINA_SHORT",
  ["Crit"]      = "ITEM_MOD_CRIT_RATING_SHORT",
  ["Haste"]     = "ITEM_MOD_HASTE_RATING_SHORT",
  ["Mastery"]   = "ITEM_MOD_MASTERY_RATING_SHORT",
  ["Vers"]      = "ITEM_MOD_VERSATILITY",
}

-- Stat bar colors by priority order
local STAT_BAR_COLORS = {
  { 0.35, 0.82, 1.0 },   -- 1st: accent blue
  { 0.30, 0.70, 0.90 },  -- 2nd
  { 0.25, 0.58, 0.78 },  -- 3rd
  { 0.20, 0.46, 0.66 },  -- 4th
  { 0.15, 0.34, 0.54 },  -- 5th
}

local STAT_ROW_HEIGHT = 32

local function GetOrCreateStatRow(parent, index)
  if statRowPool[index] then return statRowPool[index] end

  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(STAT_ROW_HEIGHT)

  local nameText = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  nameText:SetPoint("LEFT", row, "LEFT", 8, 0)
  nameText:SetWidth(80)
  nameText:SetJustifyH("LEFT")
  row.nameText = nameText

  local barBg = row:CreateTexture(nil, "BACKGROUND")
  barBg:SetPoint("LEFT", nameText, "RIGHT", 8, 0)
  barBg:SetHeight(16)
  barBg:SetWidth(240)
  barBg:SetColorTexture(0.1, 0.1, 0.15, 1)
  row.barBg = barBg

  local bar = row:CreateTexture(nil, "ARTWORK")
  bar:SetPoint("LEFT", barBg, "LEFT", 0, 0)
  bar:SetHeight(16)
  row.bar = bar

  local valueText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  valueText:SetPoint("LEFT", barBg, "RIGHT", 8, 0)
  valueText:SetWidth(50)
  valueText:SetJustifyH("LEFT")
  row.valueText = valueText

  statRowPool[index] = row
  return row
end

local function ConvertArchonWeights(statsData)
  local weights = {}
  for _, stat in ipairs(statsData) do
    local bgcKey = STAT_KEY_MAP[stat.name]
    if bgcKey then
      if stat.order == 1 then
        weights[bgcKey] = 10
      else
        weights[bgcKey] = stat.value / 100
      end
    end
  end
  return weights
end

local function PopulateStats(content, contentWidth, specData)
  local yOffset = 0
  local headerIndex = 0

  if not specData.stats or #specData.stats == 0 then
    return yOffset
  end

  -- Header
  headerIndex = headerIndex + 1
  local header = GetOrCreateHeader(content, headerIndex)
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
  header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
  header.text:SetText("Stat Priority")
  header:Show()
  yOffset = yOffset + HEADER_HEIGHT

  -- Find max value for bar scaling
  local maxValue = 0
  for _, stat in ipairs(specData.stats) do
    local w = stat.order == 1 and 1000 or stat.value
    if w > maxValue then maxValue = w end
  end
  if maxValue == 0 then maxValue = 1 end

  -- Stat rows
  for i, stat in ipairs(specData.stats) do
    local row = GetOrCreateStatRow(content, i)
    row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    row:SetPoint("RIGHT", content, "RIGHT", 0, 0)

    row.nameText:SetText(stat.name)

    local weight
    if stat.order == 1 then
      weight = 10
    else
      weight = stat.value / 100
    end

    local barFraction = (stat.order == 1 and 1000 or stat.value) / maxValue
    local barMaxWidth = 240
    row.bar:SetWidth(math.max(barFraction * barMaxWidth, 2))

    local color = STAT_BAR_COLORS[math.min(i, #STAT_BAR_COLORS)]
    row.bar:SetColorTexture(color[1], color[2], color[3], 1)
    row.nameText:SetTextColor(color[1], color[2], color[3])

    row.valueText:SetText(string.format("%.2f", weight))

    row:Show()
    yOffset = yOffset + STAT_ROW_HEIGHT
  end

  -- Export to BGC button
  if not exportBGCBtn then
    exportBGCBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    exportBGCBtn:SetSize(160, 26)
    exportBGCBtn:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8X8",
      edgeFile = "Interface/Buttons/WHITE8X8",
      edgeSize = 1,
    })
    exportBGCBtn:SetBackdropColor(0.15, 0.35, 0.15, 1)
    exportBGCBtn:SetBackdropBorderColor(0.2, 0.8, 0.2, 0.6)
    local btnText = exportBGCBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("CENTER")
    btnText:SetText(L["EXPORT_TO_BGC"])
    btnText:SetTextColor(0.2, 1, 0.2)
    exportBGCBtn.text = btnText
    exportBGCBtn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.2, 0.5, 0.2, 1)
    end)
    exportBGCBtn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.15, 0.35, 0.15, 1)
    end)
  end

  yOffset = yOffset + 8
  exportBGCBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOffset)
  exportBGCBtn:SetScript("OnClick", function()
    local bgc = _G.BetterGearCompare
    if not bgc or not bgc.ImportWeights then
      print("|cffff5555" .. L["EXPORT_NO_BGC"] .. "|r")
      return
    end
    local weights = ConvertArchonWeights(specData.stats)
    local _, specName, _, _, _, className = GetSpecializationInfoByID(selectedSpecID)
    local modeLabel = selectedMode == "raid" and "Raid" or "M+"
    local profileName = "Archon " .. modeLabel
    if className and specName then
      profileName = profileName .. " - " .. className .. " - " .. specName
    end
    bgc:ImportWeights(profileName, weights)
    print("|cff59b8ff" .. string.format(L["EXPORT_SUCCESS"], profileName) .. "|r")
  end)
  exportBGCBtn:Show()
  yOffset = yOffset + 34

  return yOffset
end

local function PopulateContent()
  if not mainFrame or not mainFrame:IsShown() then return end

  HideAll()
  pendingItems = {}

  local data = ns.ArchonData
  if not data or not data.specs then return end

  local slug = data.specIDs and data.specIDs[selectedSpecID]
  local specEntry = slug and data.specs[slug]
  local specData = specEntry and specEntry[selectedMode]
  if not specData then return end

  local content = scrollArea.content
  local contentWidth = scrollArea:GetWidth()
  local yOffset = 0

  if selectedTab == "gear" then
    yOffset = PopulateGear(content, contentWidth, specData)
  elseif selectedTab == "enchants" then
    yOffset = PopulateEnchants(content, contentWidth, specData)
  elseif selectedTab == "gems" then
    yOffset = PopulateGems(content, contentWidth, specData)
  elseif selectedTab == "consumables" then
    yOffset = PopulateConsumables(content, contentWidth, specData)
  elseif selectedTab == "talents" then
    yOffset = PopulateTalents(content, contentWidth, specData)
  elseif selectedTab == "stats" then
    yOffset = PopulateStats(content, contentWidth, specData)
  end

  content:SetHeight(math.max(yOffset, 1))

  C_Timer.After(0, function()
    if scrollArea.UpdateScrollBar then
      scrollArea.UpdateScrollBar()
    end
  end)
end

-- Mode switching (M+ / Raid)

local MODE_BUTTONS = {
  { key = "mythicplus", label = "MODE_MYTHICPLUS" },
  { key = "raid",       label = "MODE_RAID" },
}

local function UpdateModeButtons()
  for _, btn in ipairs(modeButtons) do
    if btn.modeKey == selectedMode then
      btn:SetBackdropColor(0.20, 0.30, 0.45, 1)
      btn:SetBackdropBorderColor(0.35, 0.82, 1, 1)
      btn.text:SetTextColor(0.35, 0.82, 1)
    else
      btn:SetBackdropColor(0.06, 0.08, 0.12, 0.85)
      btn:SetBackdropBorderColor(0.2, 0.2, 0.3, 0.6)
      btn.text:SetTextColor(0.5, 0.5, 0.5)
    end
  end
end

local function SelectMode(modeKey)
  selectedMode = modeKey
  if ns.db then ns.db.selectedMode = modeKey end
  UpdateModeButtons()
  PopulateContent()
end

-- Tab switching

local function UpdateTabButtons()
  for _, btn in ipairs(tabButtons) do
    if btn.tabKey == selectedTab then
      btn:SetBackdropColor(0.15, 0.25, 0.35, 1)
      btn:SetBackdropBorderColor(0.35, 0.82, 1, 1)
      btn.text:SetTextColor(0.35, 0.82, 1)
    else
      btn:SetBackdropColor(0.06, 0.08, 0.12, 0.85)
      btn:SetBackdropBorderColor(0.2, 0.2, 0.3, 0.6)
      btn.text:SetTextColor(0.6, 0.6, 0.6)
    end
  end
end

local function SelectTab(tabKey)
  selectedTab = tabKey
  if ns.db then ns.db.selectedTab = tabKey end
  UpdateTabButtons()
  PopulateContent()
end

-- Spec dropdown

local function BuildSpecEntries()
  local data = ns.ArchonData
  if not data or not data.specIDs then return {} end

  local entries = {}
  for specID, slug in pairs(data.specIDs) do
    table.insert(entries, {
      specID = specID,
      slug = slug,
      display = GetSpecDisplayName(specID, slug),
    })
  end

  table.sort(entries, function(a, b)
    return a.slug < b.slug
  end)

  return entries
end

-- Scroll frame

local function CreateScrollArea(parent)
  local scrollFrame = CreateFrame("ScrollFrame", nil, parent)

  local content = CreateFrame("Frame", nil, scrollFrame)
  content:SetWidth(scrollFrame:GetWidth())
  scrollFrame:SetScrollChild(content)
  scrollFrame.content = content

  -- Scrollbar
  local scrollbar = CreateFrame("Frame", nil, scrollFrame, "BackdropTemplate")
  scrollbar:SetWidth(6)
  scrollbar:SetPoint("TOPRIGHT", scrollFrame, "TOPRIGHT", 0, 0)
  scrollbar:SetPoint("BOTTOMRIGHT", scrollFrame, "BOTTOMRIGHT", 0, 0)
  scrollbar:SetBackdrop({ bgFile = "Interface/Buttons/WHITE8X8" })
  scrollbar:SetBackdropColor(0, 0, 0, 0.3)

  local thumb = scrollbar:CreateTexture(nil, "OVERLAY")
  thumb:SetTexture("Interface/Buttons/WHITE8X8")
  thumb:SetVertexColor(0.24, 0.72, 0.72, 0.8)
  thumb:SetWidth(6)

  local function UpdateScrollBar()
    local contentHeight = content:GetHeight()
    local frameHeight = scrollFrame:GetHeight()
    if contentHeight <= frameHeight then
      scrollbar:Hide()
      scrollFrame:SetVerticalScroll(0)
      return
    end
    scrollbar:Show()
    local ratio = frameHeight / contentHeight
    local thumbHeight = math.max(ratio * frameHeight, 20)
    thumb:SetHeight(thumbHeight)

    local scrollMax = contentHeight - frameHeight
    local scrollCurrent = scrollFrame:GetVerticalScroll()
    local thumbOffset = (scrollCurrent / scrollMax) * (frameHeight - thumbHeight)
    thumb:ClearAllPoints()
    thumb:SetPoint("TOPLEFT", scrollbar, "TOPLEFT", 0, -thumbOffset)
  end

  scrollFrame.UpdateScrollBar = UpdateScrollBar

  scrollFrame:SetScript("OnMouseWheel", function(_, delta)
    local contentHeight = content:GetHeight()
    local frameHeight = scrollFrame:GetHeight()
    local scrollMax = math.max(contentHeight - frameHeight, 0)
    local step = ROW_HEIGHT * 3
    local newScroll = math.max(0, math.min(scrollMax, scrollFrame:GetVerticalScroll() - delta * step))
    scrollFrame:SetVerticalScroll(newScroll)
    UpdateScrollBar()
  end)

  scrollFrame:SetScript("OnSizeChanged", function()
    content:SetWidth(scrollFrame:GetWidth())
    UpdateScrollBar()
  end)

  return scrollFrame
end

-- Main frame

local function CreateMainFrame()
  local f = CreateFrame("Frame", "PopularSlotsAndChantsFrame", UIParent, "BackdropTemplate")
  f:SetSize(FRAME_WIDTH, FRAME_HEIGHT)
  f:SetFrameStrata("DIALOG")
  f:SetMovable(true)
  f:EnableMouse(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", f.StartMoving)
  f:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if ns.db then
      local point, _, relPoint, x, y = self:GetPoint()
      ns.db.windowPoint = { point, "UIParent", relPoint, x, y }
    end
  end)
  f:SetClampedToScreen(true)

  f:SetBackdrop({
    bgFile = "Interface/Tooltips/UI-Tooltip-Background",
    edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
  })
  f:SetBackdropColor(0.08, 0.08, 0.12, 0.95)
  f:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

  -- Restore position
  if ns.db and ns.db.windowPoint then
    local p = ns.db.windowPoint
    f:SetPoint(p[1], UIParent, p[3], p[4], p[5])
  else
    f:SetPoint("CENTER")
  end

  -- Title
  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -10)
  title:SetText(L["ADDON_TITLE"])
  title:SetTextColor(0.35, 0.82, 1)

  -- Close button
  local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  closeBtn:SetPoint("TOPRIGHT", f, "TOPRIGHT", -2, -2)

  -- Source label
  local sourceLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  sourceLabel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -30, -14)
  sourceLabel:SetText(L["SOURCE_LABEL"])
  sourceLabel:SetTextColor(0.4, 0.4, 0.4)

  -- Spec dropdown
  local halfWidth = math.floor((FRAME_WIDTH - 50) / 2)
  specDropdown = CreateFrame("Frame", "PSCSpecDropdown", f, "UIDropDownMenuTemplate")
  specDropdown:SetPoint("TOPLEFT", f, "TOPLEFT", -4, -34)

  UIDropDownMenu_SetWidth(specDropdown, halfWidth)
  UIDropDownMenu_Initialize(specDropdown, function(_, level)
    local entries = BuildSpecEntries()
    for _, entry in ipairs(entries) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = entry.display
      info.value = entry.specID
      info.checked = (entry.specID == selectedSpecID)
      info.func = function(self)
        selectedSpecID = self.value
        if ns.db then ns.db.selectedSpecID = selectedSpecID end
        UIDropDownMenu_SetText(specDropdown, GetSpecDisplayName(selectedSpecID, ns.ArchonData.specIDs[selectedSpecID]))
        pendingItems = {}
        PopulateContent()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Tier dropdown
  tierDropdown = CreateFrame("Frame", "PSCTierDropdown", f, "UIDropDownMenuTemplate")
  tierDropdown:SetPoint("TOPLEFT", f, "TOPLEFT", halfWidth + 12, -34)

  UIDropDownMenu_SetWidth(tierDropdown, halfWidth)
  UIDropDownMenu_Initialize(tierDropdown, function(_, level)
    for trackIdx, track in ipairs(UPGRADE_TRACKS) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = L["TRACK_" .. track.key]
      info.value = trackIdx
      info.checked = (trackIdx == selectedTrackIndex)
      info.func = function(self)
        selectedTrackIndex = self.value
        if ns.db then ns.db.selectedTrackIndex = selectedTrackIndex end
        UIDropDownMenu_SetText(tierDropdown, L["TRACK_" .. UPGRADE_TRACKS[selectedTrackIndex].key])
        pendingItems = {}
        PopulateContent()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Mode buttons (M+ / Raid)
  local modeY = -64
  local modeWidth = math.floor((FRAME_WIDTH - 20) / #MODE_BUTTONS)
  for i, mode in ipairs(MODE_BUTTONS) do
    local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
    btn:SetSize(modeWidth - 4, 26)
    btn:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (i - 1) * modeWidth, modeY)
    btn:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8X8",
      edgeFile = "Interface/Buttons/WHITE8X8",
      edgeSize = 1,
    })
    btn.modeKey = mode.key

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    text:SetPoint("CENTER")
    text:SetText(L[mode.label])
    btn.text = text

    btn:SetScript("OnClick", function()
      SelectMode(mode.key)
    end)

    btn:SetScript("OnEnter", function(self)
      if self.modeKey ~= selectedMode then
        self:SetBackdropColor(0.12, 0.18, 0.28, 1)
      end
    end)
    btn:SetScript("OnLeave", function()
      UpdateModeButtons()
    end)

    table.insert(modeButtons, btn)
  end

  -- Tab buttons
  local tabY = -94
  local tabWidth = math.floor((FRAME_WIDTH - 20) / #TABS)
  for i, tab in ipairs(TABS) do
    local btn = CreateFrame("Button", nil, f, "BackdropTemplate")
    btn:SetSize(tabWidth - 4, 24)
    btn:SetPoint("TOPLEFT", f, "TOPLEFT", 10 + (i - 1) * tabWidth, tabY)
    btn:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8X8",
      edgeFile = "Interface/Buttons/WHITE8X8",
      edgeSize = 1,
    })
    btn.tabKey = tab.key

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    text:SetPoint("CENTER")
    text:SetText(L[tab.label])
    btn.text = text

    btn:SetScript("OnClick", function()
      SelectTab(tab.key)
    end)

    btn:SetScript("OnEnter", function(self)
      if self.tabKey ~= selectedTab then
        self:SetBackdropColor(0.10, 0.15, 0.25, 1)
      end
    end)
    btn:SetScript("OnLeave", function()
      UpdateTabButtons()
    end)

    table.insert(tabButtons, btn)
  end

  -- Scroll area
  scrollArea = CreateScrollArea(f)
  scrollArea:SetPoint("TOPLEFT", f, "TOPLEFT", 8, tabY - 28)
  scrollArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

  -- Listen for item data loading
  f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  f:SetScript("OnEvent", function(_, event, itemID)
    if event == "GET_ITEM_INFO_RECEIVED" and pendingItems[itemID] then
      pendingItems[itemID] = nil
      PopulateContent()
    end
  end)

  mainFrame = f
  return f
end

function ns.ToggleMainFrame()
  local isFirstOpen = not mainFrame
  if isFirstOpen then
    CreateMainFrame()
    mainFrame:Hide()
  end

  if not isFirstOpen and mainFrame:IsShown() then
    mainFrame:Hide()
    return
  end

  -- Restore saved state
  if ns.db then
    selectedTrackIndex = ns.db.selectedTrackIndex or 4
    selectedTab = ns.db.selectedTab or "gear"
    selectedMode = ns.db.selectedMode or "mythicplus"
    selectedSpecID = ns.db.selectedSpecID
  end

  -- Auto-detect current spec if no saved selection
  if not selectedSpecID then
    selectedSpecID = GetCurrentSpecSlug()
  end

  -- Fallback to first available spec
  if not selectedSpecID and ns.ArchonData and ns.ArchonData.specIDs then
    for specID in pairs(ns.ArchonData.specIDs) do
      selectedSpecID = specID
      break
    end
  end

  -- Update dropdown texts
  if selectedSpecID and ns.ArchonData then
    UIDropDownMenu_SetText(specDropdown, GetSpecDisplayName(selectedSpecID, ns.ArchonData.specIDs[selectedSpecID]))
  end
  UIDropDownMenu_SetText(tierDropdown, L["TRACK_" .. UPGRADE_TRACKS[selectedTrackIndex].key])

  UpdateTabButtons()
  UpdateModeButtons()
  mainFrame:Show()
  PopulateContent()
end
