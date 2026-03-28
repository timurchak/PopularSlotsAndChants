local _, ns = ...

local L = ns.L
local UI = ns.UI

local function ShowCopyPopup(exportCode)
  StaticPopup_Show("PSC_COPY_EXPORT", nil, nil, exportCode)
end

local function GetOrCreateTalentRow(parent, index)
  if UI.talentRowPool[index] then return UI.talentRowPool[index] end

  local row = CreateFrame("Frame", nil, parent, "BackdropTemplate")
  row:SetHeight(UI.TALENT_ROW_HEIGHT)
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

  -- Open Talents button
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

  UI.talentRowPool[index] = row
  return row
end

function UI.PopulateTalents(content, contentWidth, specData)
  local yOffset = 0
  local headerIndex = 0

  if not specData.talents or not specData.talents.builds then
    return yOffset
  end

  -- Hero Trees summary
  if specData.talents.heroTrees and #specData.talents.heroTrees > 0 then
    headerIndex = headerIndex + 1
    local header = UI.GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    local names = {}
    for _, ht in ipairs(specData.talents.heroTrees) do
      table.insert(names, ht.name .. " (#" .. ht.rank .. ")")
    end
    header.text:SetText("Hero Trees: " .. table.concat(names, ", "))
    header:Show()
    yOffset = yOffset + UI.HEADER_HEIGHT
  end

  -- Builds
  headerIndex = headerIndex + 1
  local header = UI.GetOrCreateHeader(content, headerIndex)
  header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
  header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
  header.text:SetText("Talent Builds")
  header:Show()
  yOffset = yOffset + UI.HEADER_HEIGHT

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
    yOffset = yOffset + UI.TALENT_ROW_HEIGHT + 4
  end

  return yOffset
end
