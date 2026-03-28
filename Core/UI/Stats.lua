local _, ns = ...

local L = ns.L
local UI = ns.UI

local function GetOrCreateStatRow(parent, index)
  if UI.statRowPool[index] then return UI.statRowPool[index] end

  local row = CreateFrame("Frame", nil, parent)
  row:SetHeight(UI.STAT_ROW_HEIGHT)

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

  UI.statRowPool[index] = row
  return row
end

local function ConvertArchonWeights(statsData)
  local weights = {}
  for _, stat in ipairs(statsData) do
    local bgcKey = UI.STAT_KEY_MAP[stat.name]
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

function UI.PopulateStats(content, contentWidth, specData)
  local yOffset = 0
  local headerIndex = 0

  if not specData.stats or #specData.stats == 0 then
    return yOffset
  end

  headerIndex = headerIndex + 1
  local header = UI.GetOrCreateHeader(content, headerIndex)
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
  header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
  header.text:SetText("Stat Priority")
  header:Show()
  yOffset = yOffset + UI.HEADER_HEIGHT

  local maxValue = 0
  for _, stat in ipairs(specData.stats) do
    local w = stat.order == 1 and 1000 or stat.value
    if w > maxValue then maxValue = w end
  end
  if maxValue == 0 then maxValue = 1 end

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

    local color = UI.STAT_BAR_COLORS[math.min(i, #UI.STAT_BAR_COLORS)]
    row.bar:SetColorTexture(color[1], color[2], color[3], 1)
    row.nameText:SetTextColor(color[1], color[2], color[3])

    row.valueText:SetText(string.format("%.2f", weight))

    row:Show()
    yOffset = yOffset + UI.STAT_ROW_HEIGHT
  end

  -- Export to BGC button
  if not UI.exportBGCBtn then
    UI.exportBGCBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    UI.exportBGCBtn:SetSize(160, 26)
    UI.exportBGCBtn:SetBackdrop({
      bgFile = "Interface/Buttons/WHITE8X8",
      edgeFile = "Interface/Buttons/WHITE8X8",
      edgeSize = 1,
    })
    UI.exportBGCBtn:SetBackdropColor(0.15, 0.35, 0.15, 1)
    UI.exportBGCBtn:SetBackdropBorderColor(0.2, 0.8, 0.2, 0.6)
    local btnText = UI.exportBGCBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    btnText:SetPoint("CENTER")
    btnText:SetText(L["EXPORT_TO_BGC"])
    btnText:SetTextColor(0.2, 1, 0.2)
    UI.exportBGCBtn.text = btnText
    UI.exportBGCBtn:SetScript("OnEnter", function(self)
      self:SetBackdropColor(0.2, 0.5, 0.2, 1)
    end)
    UI.exportBGCBtn:SetScript("OnLeave", function(self)
      self:SetBackdropColor(0.15, 0.35, 0.15, 1)
    end)
  end

  yOffset = yOffset + 8
  UI.exportBGCBtn:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -yOffset)
  UI.exportBGCBtn:SetScript("OnClick", function()
    local bgc = _G.BetterGearCompare
    if not bgc or not bgc.ImportWeights then
      print("|cffff5555" .. L["EXPORT_NO_BGC"] .. "|r")
      return
    end
    local weights = ConvertArchonWeights(specData.stats)
    local _, specName, _, _, _, className = GetSpecializationInfoByID(UI.selectedSpecID)
    local modeLabel = UI.selectedMode == "raid" and "Raid" or "M+"
    local profileName = "Archon " .. modeLabel
    if className and specName then
      profileName = profileName .. " - " .. className .. " - " .. specName
    end
    bgc:ImportWeights(profileName, weights)
    print("|cff59b8ff" .. string.format(L["EXPORT_SUCCESS"], profileName) .. "|r")
  end)
  UI.exportBGCBtn:Show()
  yOffset = yOffset + 34

  return yOffset
end
