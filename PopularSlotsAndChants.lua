local addonName, ns = ...

ns.addonName = addonName

local defaults = {
  selectedSpecID = nil,
  selectedTrackIndex = 4,
  selectedTab = "gear",
  windowPoint = nil,
  minimapAngle = 225,
}

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    PopularSlotsAndChantsDB = PopularSlotsAndChantsDB or {}
    for k, v in pairs(defaults) do
      if PopularSlotsAndChantsDB[k] == nil then
        PopularSlotsAndChantsDB[k] = v
      end
    end
    ns.db = PopularSlotsAndChantsDB

    frame:UnregisterEvent("ADDON_LOADED")
  end
end)

SLASH_POPULARSLOTS1 = "/psc"
SLASH_POPULARSLOTS2 = "/popularslots"
SlashCmdList["POPULARSLOTS"] = function()
  if ns.ToggleMainFrame then
    ns.ToggleMainFrame()
  end
end
