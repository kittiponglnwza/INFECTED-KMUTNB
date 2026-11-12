-- Central client-side modal state registry for INFECTED-KMUTNB.
-- Tracks server/campaign modals (e.g., CCTV Timeline Puzzle) so FPSController can
-- safely unlock mouse, pause camera/firing/hotbar inputs, and prevent HUD/input overlap.

local Players = game:GetService("Players")

local UIStateManager = {}

local activeModals = {}
local closeCallbacks = {}
local listeners = {}

local function syncAttribute()
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local anyOpen = UIStateManager.isModalOpen()
		localPlayer:SetAttribute("ClientModalOpen", anyOpen)
	end
end

local function notifyListeners()
	local openNow = UIStateManager.isModalOpen()
	syncAttribute()
	for _, fn in ipairs(listeners) do
		task.spawn(fn, openNow)
	end
end

function UIStateManager.isModalOpen(modalId)
	if modalId ~= nil then
		return activeModals[modalId] == true
	end
	for _, open in pairs(activeModals) do
		if open == true then
			return true
		end
	end
	return false
end

function UIStateManager.openModal(modalId, onForceClose)
	if type(modalId) ~= "string" or modalId == "" then
		return
	end
	-- Close any conflicting registered modal before opening a new one
	for existingId, isOpen in pairs(activeModals) do
		if isOpen and existingId ~= modalId then
			UIStateManager.closeModal(existingId)
		end
	end
	activeModals[modalId] = true
	if type(onForceClose) == "function" then
		closeCallbacks[modalId] = onForceClose
	end
	notifyListeners()
end

function UIStateManager.closeModal(modalId)
	if type(modalId) ~= "string" then
		return
	end
	local wasOpen = activeModals[modalId] == true
	activeModals[modalId] = nil
	local cb = closeCallbacks[modalId]
	closeCallbacks[modalId] = nil
	if wasOpen then
		if type(cb) == "function" then
			pcall(cb)
		end
		notifyListeners()
	end
end

function UIStateManager.closeAll()
	local any = false
	for modalId, isOpen in pairs(activeModals) do
		if isOpen then
			any = true
			activeModals[modalId] = nil
			local cb = closeCallbacks[modalId]
			closeCallbacks[modalId] = nil
			if type(cb) == "function" then
				pcall(cb)
			end
		end
	end
	if any then
		notifyListeners()
	end
end

function UIStateManager.onChanged(fn)
	if type(fn) ~= "function" then
		return
	end
	table.insert(listeners, fn)
end

return UIStateManager
