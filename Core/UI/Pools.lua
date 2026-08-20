local _, ns = ...

local L = ns.L
local UI = ns.UI

local MESSAGE_INSET = 20
local MESSAGE_TOP_OFFSET = 40

-- Copy popup dialog
StaticPopupDialogs["PSC_COPY_EXPORT"] = {
  text = "%s",
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

function UI.ItemString(itemID)
  local track = UI.UPGRADE_TRACKS[UI.selectedTrackIndex]
  if track.contextBonus then
    return "item:" .. itemID .. "::::::::::::2:" .. track.bonusID .. ":" .. track.contextBonus
  else
    return "item:" .. itemID .. "::::::::::::1:" .. track.bonusID
  end
end

function UI.GetClassColor(classSlug)
  local classToken = UI.CLASS_FROM_SLUG[classSlug]
  if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
    return RAID_CLASS_COLORS[classToken]
  end
  return { r = 1, g = 1, b = 1, colorStr = "ffffffff" }
end

function UI.GetSpecDisplayName(specID, slug)
  if UI.SPEC_NAMES[specID] then
    return UI.SPEC_NAMES[specID]
  end
  if not slug then
    return tostring(specID)
  end
  local classSlug = slug:match("^([^/]+)/")
  local specSlug = slug:match("/(.+)$")
  if not classSlug or not specSlug then
    return slug
  end

  local _, name = GetSpecializationInfoByID(specID)
  if name then
    local cc = UI.GetClassColor(classSlug)
    local display = string.format("|c%s%s|r", cc.colorStr, name)
    UI.SPEC_NAMES[specID] = display
    return display
  end

  local pretty = specSlug:gsub("-", " "):gsub("(%a)([%w_']*)", function(a, b)
    return a:upper() .. b
  end)
  UI.SPEC_NAMES[specID] = pretty
  return pretty
end

function UI.GetCurrentSpecSlug()
  local specIndex = GetSpecialization()
  if not specIndex then
    return nil
  end
  local specID = GetSpecializationInfo(specIndex)
  if not specID then
    return nil
  end
  local data = ns.ArchonData
  if data and data.specIDs and data.specIDs[specID] then
    return specID
  end
  return nil
end

-- Row/Header pool

function UI.GetOrCreateHeader(parent, index)
  if UI.headerPool[index] then
    return UI.headerPool[index]
  end

  local header = CreateFrame("Frame", nil, parent)
  header:SetHeight(UI.HEADER_HEIGHT)

  local text = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("LEFT", 4, 0)
  text:SetTextColor(0.35, 0.82, 1)
  header.text = text

  local line = header:CreateTexture(nil, "ARTWORK")
  line:SetHeight(1)
  line:SetPoint("BOTTOMLEFT", header, "BOTTOMLEFT", 0, 0)
  line:SetPoint("BOTTOMRIGHT", header, "BOTTOMRIGHT", 0, 0)
  line:SetColorTexture(0.2, 0.2, 0.3, 0.8)

  UI.headerPool[index] = header
  return header
end

function UI.GetOrCreateRow(parent, index)
  if UI.rowPool[index] then
    return UI.rowPool[index]
  end

  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(UI.ROW_HEIGHT)
  row:EnableMouse(true)

  local icon = row:CreateTexture(nil, "ARTWORK")
  icon:SetSize(UI.ICON_SIZE, UI.ICON_SIZE)
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

  local highlight = row:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetColorTexture(1, 1, 1, 0.05)

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

  row:SetScript("OnMouseUp", function(self, button)
    if button == "LeftButton" and IsShiftKeyDown() and self.itemLink then
      HandleModifiedItemClick(self.itemLink)
    end
  end)

  UI.rowPool[index] = row
  return row
end

-- Centered placeholder message (empty spec/mode data)

function UI.GetOrCreateMessage(parent)
  if UI.messageLabel then
    return UI.messageLabel
  end

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  text:SetPoint("TOPLEFT", parent, "TOPLEFT", MESSAGE_INSET, -MESSAGE_TOP_OFFSET)
  text:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -MESSAGE_INSET, -MESSAGE_TOP_OFFSET)
  text:SetJustifyH("CENTER")
  text:SetJustifyV("TOP")
  text:SetWordWrap(true)
  text:SetTextColor(0.6, 0.6, 0.6)

  UI.messageLabel = text
  return text
end

function UI.ShowMessage(parent, message)
  local label = UI.GetOrCreateMessage(parent)
  label:SetText(message)
  label:Show()
  return MESSAGE_TOP_OFFSET + label:GetStringHeight() + MESSAGE_INSET
end

function UI.HideAll()
  if UI.messageLabel then
    UI.messageLabel:Hide()
  end
  for _, row in pairs(UI.rowPool) do
    row:Hide()
  end
  for _, header in pairs(UI.headerPool) do
    header:Hide()
  end
  for _, row in pairs(UI.talentRowPool) do
    row:Hide()
  end
  for _, row in pairs(UI.statRowPool) do
    row:Hide()
  end
  if UI.exportBGCBtn then
    UI.exportBGCBtn:Hide()
  end
end

function UI.SetupItemRow(row, itemID, popularity, useTrack)
  local itemStr = useTrack and UI.ItemString(itemID) or ("item:" .. itemID)
  local itemName, itemLink, itemQuality, _, _, _, _, _, _, itemTexture = GetItemInfo(itemStr)

  if itemName then
    row.icon:SetTexture(itemTexture)
    local qc = UI.QUALITY_COLORS[itemQuality] or UI.QUALITY_COLORS[1]
    row.nameText:SetText(itemName)
    row.nameText:SetTextColor(qc[1], qc[2], qc[3])
    row.itemLink = itemLink or itemStr
  else
    row.icon:SetTexture(134400)
    row.nameText:SetText(L["LOADING"] .. " (ID: " .. itemID .. ")")
    row.nameText:SetTextColor(0.5, 0.5, 0.5)
    row.itemLink = nil
    UI.pendingItems[itemID] = true
  end

  row.popText:SetText(string.format(L["POPULARITY"], popularity))
end

function UI.SetupSpellRow(row, spellID, popularity)
  local spellInfo = C_Spell.GetSpellInfo(spellID)
  if spellInfo then
    row.icon:SetTexture(spellInfo.iconID)
    row.nameText:SetText(spellInfo.name)
    row.nameText:SetTextColor(0.35, 0.82, 1)
    row.itemLink = nil
  else
    row.icon:SetTexture(134400)
    row.nameText:SetText(L["LOADING"] .. " (ID: " .. spellID .. ")")
    row.nameText:SetTextColor(0.5, 0.5, 0.5)
    row.itemLink = nil
  end

  row.popText:SetText(string.format(L["POPULARITY"], popularity))
end
