local _, ns = ...

local L = ns.L
local UI = ns.UI

-- False when Archon has not published data for this mode yet (e.g. a raid tier
-- that has not opened). The generator omits the mode key entirely in that case.
local function hasModeData(specData)
  return specData ~= nil and next(specData.gear or {}) ~= nil
end

local function RefreshScrollBar()
  C_Timer.After(0, function()
    if UI.scrollArea and UI.scrollArea.UpdateScrollBar then
      UI.scrollArea.UpdateScrollBar()
    end
  end)
end

local function ShowPlaceholder(content, message)
  content:SetHeight(math.max(UI.ShowMessage(content, message), 1))
  RefreshScrollBar()
end

local function PopulateContent()
  if not UI.mainFrame or not UI.mainFrame:IsShown() then
    return
  end

  UI.HideAll()
  UI.pendingItems = {}

  local content = UI.scrollArea.content
  local contentWidth = UI.scrollArea:GetWidth()

  local data = ns.ArchonData
  if not data or not data.specs then
    ShowPlaceholder(content, L["NO_DATA"])
    return
  end

  local slug = data.specIDs and data.specIDs[UI.selectedSpecID]
  local specEntry = slug and data.specs[slug]
  local specData = specEntry and specEntry[UI.selectedMode]

  if not hasModeData(specData) then
    ShowPlaceholder(content, UI.selectedMode == "raid" and L["RAID_COMING_SOON"] or L["NO_DATA"])
    return
  end

  local yOffset = 0

  if UI.selectedTab == "gear" then
    yOffset = UI.PopulateGear(content, contentWidth, specData)
  elseif UI.selectedTab == "enchants" then
    yOffset = UI.PopulateEnchants(content, contentWidth, specData)
  elseif UI.selectedTab == "gems" then
    yOffset = UI.PopulateGems(content, contentWidth, specData)
  elseif UI.selectedTab == "consumables" then
    yOffset = UI.PopulateConsumables(content, contentWidth, specData)
  elseif UI.selectedTab == "talents" then
    yOffset = UI.PopulateTalents(content, contentWidth, specData)
  elseif UI.selectedTab == "stats" then
    yOffset = UI.PopulateStats(content, contentWidth, specData)
  end

  content:SetHeight(math.max(yOffset, 1))

  RefreshScrollBar()
end

-- Mode switching (M+ / Raid)

local function UpdateModeButtons()
  for _, btn in ipairs(UI.modeButtons) do
    if btn.modeKey == UI.selectedMode then
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
  UI.selectedMode = modeKey
  if ns.db then
    ns.db.selectedMode = modeKey
  end
  UpdateModeButtons()
  PopulateContent()
end

-- Tab switching

local function UpdateTabButtons()
  for _, btn in ipairs(UI.tabButtons) do
    if btn.tabKey == UI.selectedTab then
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
  UI.selectedTab = tabKey
  if ns.db then
    ns.db.selectedTab = tabKey
  end
  UpdateTabButtons()
  PopulateContent()
end

-- Spec dropdown

local function BuildSpecEntries()
  local data = ns.ArchonData
  if not data or not data.specIDs then
    return {}
  end

  local entries = {}
  for specID, slug in pairs(data.specIDs) do
    table.insert(entries, {
      specID = specID,
      slug = slug,
      display = UI.GetSpecDisplayName(specID, slug),
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
    local step = UI.ROW_HEIGHT * 3
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
  f:SetSize(UI.FRAME_WIDTH, UI.FRAME_HEIGHT)
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

  tinsert(UISpecialFrames, "PopularSlotsAndChantsFrame")

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
  local halfWidth = math.floor((UI.FRAME_WIDTH - 50) / 2)
  UI.specDropdown = CreateFrame("Frame", "PSCSpecDropdown", f, "UIDropDownMenuTemplate")
  UI.specDropdown:SetPoint("TOPLEFT", f, "TOPLEFT", -4, -34)

  UIDropDownMenu_SetWidth(UI.specDropdown, halfWidth)
  UIDropDownMenu_Initialize(UI.specDropdown, function(_, level)
    local entries = BuildSpecEntries()
    for _, entry in ipairs(entries) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = entry.display
      info.value = entry.specID
      info.checked = (entry.specID == UI.selectedSpecID)
      info.func = function(self)
        UI.selectedSpecID = self.value
        if ns.db then
          ns.db.selectedSpecID = UI.selectedSpecID
        end
        UIDropDownMenu_SetText(
          UI.specDropdown,
          UI.GetSpecDisplayName(UI.selectedSpecID, ns.ArchonData.specIDs[UI.selectedSpecID])
        )
        UI.pendingItems = {}
        PopulateContent()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Tier dropdown
  UI.tierDropdown = CreateFrame("Frame", "PSCTierDropdown", f, "UIDropDownMenuTemplate")
  UI.tierDropdown:SetPoint("TOPLEFT", f, "TOPLEFT", halfWidth + 12, -34)

  UIDropDownMenu_SetWidth(UI.tierDropdown, halfWidth)
  UIDropDownMenu_Initialize(UI.tierDropdown, function(_, level)
    for trackIdx, track in ipairs(UI.UPGRADE_TRACKS) do
      local info = UIDropDownMenu_CreateInfo()
      info.text = L["TRACK_" .. track.key]
      info.value = trackIdx
      info.checked = (trackIdx == UI.selectedTrackIndex)
      info.func = function(self)
        UI.selectedTrackIndex = self.value
        if ns.db then
          ns.db.selectedTrackIndex = UI.selectedTrackIndex
        end
        UIDropDownMenu_SetText(UI.tierDropdown, L["TRACK_" .. UI.UPGRADE_TRACKS[UI.selectedTrackIndex].key])
        UI.pendingItems = {}
        PopulateContent()
      end
      UIDropDownMenu_AddButton(info, level)
    end
  end)

  -- Mode buttons (M+ / Raid)
  local modeY = -64
  local modeWidth = math.floor((UI.FRAME_WIDTH - 20) / #UI.MODE_BUTTONS)
  for i, mode in ipairs(UI.MODE_BUTTONS) do
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
      if self.modeKey ~= UI.selectedMode then
        self:SetBackdropColor(0.12, 0.18, 0.28, 1)
      end
    end)
    btn:SetScript("OnLeave", function()
      UpdateModeButtons()
    end)

    table.insert(UI.modeButtons, btn)
  end

  -- Tab buttons
  local tabY = -94
  local tabWidth = math.floor((UI.FRAME_WIDTH - 20) / #UI.TABS)
  for i, tab in ipairs(UI.TABS) do
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
      if self.tabKey ~= UI.selectedTab then
        self:SetBackdropColor(0.10, 0.15, 0.25, 1)
      end
    end)
    btn:SetScript("OnLeave", function()
      UpdateTabButtons()
    end)

    table.insert(UI.tabButtons, btn)
  end

  -- Scroll area
  UI.scrollArea = CreateScrollArea(f)
  UI.scrollArea:SetPoint("TOPLEFT", f, "TOPLEFT", 8, tabY - 28)
  UI.scrollArea:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 8)

  -- Listen for item data loading
  f:RegisterEvent("GET_ITEM_INFO_RECEIVED")
  f:SetScript("OnEvent", function(_, event, itemID)
    if event == "GET_ITEM_INFO_RECEIVED" and UI.pendingItems[itemID] then
      UI.pendingItems[itemID] = nil
      PopulateContent()
    end
  end)

  UI.mainFrame = f
  return f
end

function ns.ToggleMainFrame()
  local isFirstOpen = not UI.mainFrame
  if isFirstOpen then
    CreateMainFrame()
    UI.mainFrame:Hide()
  end

  if not isFirstOpen and UI.mainFrame:IsShown() then
    UI.mainFrame:Hide()
    return
  end

  -- Restore saved state
  if ns.db then
    UI.selectedTrackIndex = ns.db.selectedTrackIndex or 4
    UI.selectedTab = ns.db.selectedTab or "gear"
    UI.selectedMode = ns.db.selectedMode or "mythicplus"
  end

  -- Always detect current spec
  UI.selectedSpecID = UI.GetCurrentSpecSlug()

  -- Fallback to saved selection
  if not UI.selectedSpecID and ns.db then
    UI.selectedSpecID = ns.db.selectedSpecID
  end

  -- Fallback to first available spec
  if not UI.selectedSpecID and ns.ArchonData and ns.ArchonData.specIDs then
    UI.selectedSpecID = next(ns.ArchonData.specIDs)
  end

  -- Update dropdown texts
  if UI.selectedSpecID and ns.ArchonData then
    UIDropDownMenu_SetText(
      UI.specDropdown,
      UI.GetSpecDisplayName(UI.selectedSpecID, ns.ArchonData.specIDs[UI.selectedSpecID])
    )
  end
  UIDropDownMenu_SetText(UI.tierDropdown, L["TRACK_" .. UI.UPGRADE_TRACKS[UI.selectedTrackIndex].key])

  UpdateTabButtons()
  UpdateModeButtons()
  UI.mainFrame:Show()
  PopulateContent()
end
