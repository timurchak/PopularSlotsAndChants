local _, ns = ...

local L = ns.L
local UI = ns.UI

function UI.PopulateGear(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, slotName in ipairs(UI.GEAR_SLOT_ORDER) do
    local items = specData.gear[slotName]
    if items and #items > 0 then
      headerIndex = headerIndex + 1
      local header = UI.GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(slotName)
      header:Show()
      yOffset = yOffset + UI.HEADER_HEIGHT

      for _, entry in ipairs(items) do
        rowIndex = rowIndex + 1
        local row = UI.GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        UI.SetupItemRow(row, entry.id, entry.popularity, true)
        row:Show()
        yOffset = yOffset + UI.ROW_HEIGHT
      end
    end
  end

  return yOffset
end

function UI.PopulateEnchants(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, slotName in ipairs(UI.ENCHANT_SLOT_ORDER) do
    local items = specData.enchants[slotName]
    if items and #items > 0 then
      headerIndex = headerIndex + 1
      local header = UI.GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(slotName)
      header:Show()
      yOffset = yOffset + UI.HEADER_HEIGHT

      for _, entry in ipairs(items) do
        rowIndex = rowIndex + 1
        local row = UI.GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        UI.SetupItemRow(row, entry.id, entry.popularity, false)
        row:Show()
        yOffset = yOffset + UI.ROW_HEIGHT
      end
    end
  end

  return yOffset
end

function UI.PopulateGems(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  if specData.epicGems and #specData.epicGems > 0 then
    headerIndex = headerIndex + 1
    local header = UI.GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    header.text:SetText(L["HEADER_EPIC_GEMS"])
    header:Show()
    yOffset = yOffset + UI.HEADER_HEIGHT

    for _, entry in ipairs(specData.epicGems) do
      rowIndex = rowIndex + 1
      local row = UI.GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      UI.SetupItemRow(row, entry.id, entry.popularity, false)
      row:Show()
      yOffset = yOffset + UI.ROW_HEIGHT
    end
  end

  if specData.gems and #specData.gems > 0 then
    headerIndex = headerIndex + 1
    local header = UI.GetOrCreateHeader(content, headerIndex)
    header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
    header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
    header.text:SetText(L["HEADER_GEMS"])
    header:Show()
    yOffset = yOffset + UI.HEADER_HEIGHT

    for _, entry in ipairs(specData.gems) do
      rowIndex = rowIndex + 1
      local row = UI.GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      UI.SetupItemRow(row, entry.id, entry.popularity, false)
      row:Show()
      yOffset = yOffset + UI.ROW_HEIGHT
    end
  end

  return yOffset
end

function UI.PopulateConsumables(content, contentWidth, specData)
  local yOffset = 0
  local rowIndex = 0
  local headerIndex = 0

  for _, category in ipairs(UI.CONSUMABLE_ORDER) do
    local entry = specData.consumables[category]
    if entry then
      headerIndex = headerIndex + 1
      local header = UI.GetOrCreateHeader(content, headerIndex)
      header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      header.text:SetText(category)
      header:Show()
      yOffset = yOffset + UI.HEADER_HEIGHT

      rowIndex = rowIndex + 1
      local row = UI.GetOrCreateRow(content, rowIndex)
      row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
      row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
      if entry.isSpell then
        UI.SetupSpellRow(row, entry.id, entry.popularity)
      else
        UI.SetupItemRow(row, entry.id, entry.popularity, false)
      end
      row:Show()
      yOffset = yOffset + UI.ROW_HEIGHT
    end
  end

  if specData.consumables then
    for category, entry in pairs(specData.consumables) do
      local found = false
      for _, c in ipairs(UI.CONSUMABLE_ORDER) do
        if c == category then found = true; break end
      end
      if not found then
        headerIndex = headerIndex + 1
        local header = UI.GetOrCreateHeader(content, headerIndex)
        header:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        header:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        header.text:SetText(category)
        header:Show()
        yOffset = yOffset + UI.HEADER_HEIGHT

        rowIndex = rowIndex + 1
        local row = UI.GetOrCreateRow(content, rowIndex)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -yOffset)
        row:SetPoint("RIGHT", content, "RIGHT", 0, 0)
        if entry.isSpell then
          UI.SetupSpellRow(row, entry.id, entry.popularity)
        else
          UI.SetupItemRow(row, entry.id, entry.popularity, false)
        end
        row:Show()
        yOffset = yOffset + UI.ROW_HEIGHT
      end
    end
  end

  return yOffset
end
