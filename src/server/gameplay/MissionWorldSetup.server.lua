-- Legacy 7-station [E] 1s campaign skip pedestals are intentionally disabled in Phase 1.
-- Playable M1 (Security Access) world pickups, keycard door, clues, CCTV terminal, and
-- override console are built and validated exclusively by MissionService + MissionWorldInteractables.
-- M2-M7 remain NOT IMPLEMENTED to prevent fake progression triggers.

local Workspace = game:GetService("Workspace")

local oldStations = Workspace:FindFirstChild("CampaignStations")
if oldStations then
	oldStations:Destroy()
end

print("🗺️ [MissionWorldSetup] Legacy quick-skip stations retired; M1 real interactables owned by MissionService.")
