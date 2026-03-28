local _, ns = ...

local L = ns.L
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LibStub("LibDBIcon-1.0")

local ADDON_KEY = "PopularSlotsAndChants"

local minimapObject = LDB:NewDataObject(ADDON_KEY, {
  type = "launcher",
  text = "Popular Slots & Chants",
  icon = "Interface\\AddOns\\PopularSlotsAndChants\\icon",

  OnClick = function(_, button)
    if button == "LeftButton" then
      if ns.ToggleMainFrame then
        ns.ToggleMainFrame()
      end
    end
  end,

  OnTooltipShow = function(tt)
    tt:AddLine("Popular Slots & Chants", 1, 1, 1)
    tt:AddLine(L["SOURCE_LABEL"], 0.7, 0.7, 0.7)
  end,
})

local loader = CreateFrame("Frame")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(self)
  self:UnregisterAllEvents()

  if not ns.db.minimap then
    ns.db.minimap = { hide = false }
  end

  if not LDBIcon:IsRegistered(ADDON_KEY) then
    LDBIcon:Register(ADDON_KEY, minimapObject, ns.db.minimap)
  end
end)
