--[[
    Room102MonitorEffects.lua
    Client-side lightweight visual effects for Security Control Room 102:
    - Scanline scrolling & static noise jitter on SurfaceGui Monitor Wall panels (no ViewportFrames)
    - Blinking red hazard dots on the Building Schematic screen
    - Flashing "UPS BACKUP: xx% CRITICAL" status & yellow UPS light flicker scaling with low UPS %
    - Alarm red screen flash synchronized to server Workspace attribute Room102AlarmActive
]]

local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Room102MonitorEffects = {}

local started = false

function Room102MonitorEffects.start()
	if started then
		return
	end
	started = true

	local cacheDirty = true
	local scanScreens = {}
	local staticLabels = {}
	local upsTexts = {}
	local hazardDots = {}
	local alarmOverlays = {}
	local upsLights = {}

	local function rebuildCache()
		cacheDirty = false
		table.clear(scanScreens)
		table.clear(staticLabels)
		table.clear(upsTexts)
		table.clear(hazardDots)
		table.clear(alarmOverlays)
		table.clear(upsLights)

		local m1Root = Workspace:FindFirstChild("MissionM1_Interactables")
		local wall = m1Root and m1Root:FindFirstChild("M1_MonitorWall")
		if wall then
			for _, desc in ipairs(wall:GetDescendants()) do
				if desc.Name == "ScanlineSweep" and desc:IsA("Frame") then
					table.insert(scanScreens, { frame = desc, phase = (#scanScreens * 0.17) % 1 })
				elseif desc.Name == "NoSignalText" and desc:IsA("TextLabel") then
					table.insert(staticLabels, desc)
				elseif desc.Name == "UPSStatusText" and desc:IsA("TextLabel") then
					table.insert(upsTexts, desc)
				elseif desc.Name:match("^HazardDot_%d+$") and desc:IsA("Frame") then
					table.insert(hazardDots, { dot = desc, phase = (#hazardDots * 0.28) })
				elseif desc.Name == "AlarmOverlay" and desc:IsA("Frame") then
					table.insert(alarmOverlays, desc)
				end
			end
		end

		local f1 = Workspace:FindFirstChild("Floor_1_Building40")
		local room102 = f1 and f1:FindFirstChild("Room_BottomLeft")
		if room102 then
			for _, desc in ipairs(room102:GetDescendants()) do
				if desc:IsA("PointLight") and desc:GetAttribute("Room102UPSLight") == true then
					table.insert(upsLights, {
						light = desc,
						base = tonumber(desc:GetAttribute("BaseBrightness")) or 1.0,
					})
				elseif desc.Name == "UPSStatusText" and desc:IsA("TextLabel") then
					table.insert(upsTexts, desc)
				end
			end
		end
	end

	Workspace.DescendantAdded:Connect(function(desc)
		local name = desc.Name
		if name == "MissionM1_Interactables" or name == "M1_MonitorWall" or name == "Room102Overhaul"
			or desc:GetAttribute("Room102UPSLight") == true
		then
			cacheDirty = true
		end
	end)

	Workspace.DescendantRemoving:Connect(function(desc)
		local name = desc.Name
		if name == "MissionM1_Interactables" or name == "M1_MonitorWall" or name == "Room102Overhaul" then
			cacheDirty = true
		end
	end)

	task.spawn(function()
		local tickAcc = 0
		local rescanCooldown = 0
		while true do
			local dt = task.wait(0.08)
			tickAcc += dt
			rescanCooldown += dt
			if cacheDirty or (rescanCooldown >= 4.0 and #upsLights == 0) then
				rescanCooldown = 0
				rebuildCache()
			end

			local now = os.clock()
			local upsPct = math.clamp(tonumber(Workspace:GetAttribute("Room102UPSPercent")) or 34, 5, 100)
			local alarmActive = Workspace:GetAttribute("Room102AlarmActive") == true
			local holdoutActive = Workspace:GetAttribute("Room102HoldoutActive") == true

			-- 1. Scanlines across Monitor Wall panels
			for _, item in ipairs(scanScreens) do
				if item.frame.Parent then
					local y = (item.phase + now * 0.28) % 0.88
					item.frame.Position = UDim2.fromScale(0, y)
				end
			end

			-- 2. Static jitter on NO SIGNAL panels
			for idx, lbl in ipairs(staticLabels) do
				if lbl.Parent then
					local jitter = math.sin(now * 27 + idx * 1.9)
					lbl.TextTransparency = (jitter > 0.72) and 0.55 or 0.05
				end
			end

			-- 3. Blinking red dots on schematic map
			for _, item in ipairs(hazardDots) do
				if item.dot.Parent then
					local pulse = (math.sin(now * 5.2 + item.phase) + 1) * 0.5
					item.dot.BackgroundTransparency = 0.1 + pulse * 0.65
				end
			end

			-- 4. "UPS BACKUP: xx% CRITICAL" text blink
			local upsBlinkOn = (math.floor(now * (holdoutActive and 4.5 or 2.4)) % 2) == 0
			for _, lbl in ipairs(upsTexts) do
				if lbl.Parent then
					lbl.Text = upsBlinkOn
						and string.format("UPS BACKUP: %d%%\nCRITICAL", upsPct)
						or string.format("UPS BACKUP: %d%%\n[LOW POWER]", upsPct)
					lbl.TextColor3 = upsBlinkOn
						and Color3.fromRGB(255, 198, 56)
						or Color3.fromRGB(255, 92, 58)
				end
			end

			-- 5. Alarm red screen flash across Monitor Wall when wrong sequence is triggered
			local alarmAlpha = 1
			if alarmActive then
				alarmAlpha = (math.floor(now * 7.0) % 2 == 0) and 0.48 or 0.88
			end
			for _, ov in ipairs(alarmOverlays) do
				if ov.Parent then
					ov.BackgroundTransparency = alarmAlpha
				end
			end

			-- 6. Dim yellow UPS lights flicker frequency inversely proportional to UPS %
			--    At 34% -> mild slow dip every ~2.2s; at 8% -> rapid nervous brownout flicker
			local severity = math.clamp((40 - upsPct) / 32, 0.15, 1.0)
			local waveFreq = 1.6 + severity * 9.5
			local flickerWave = math.sin(now * waveFreq) * math.sin(now * (waveFreq * 0.37 + 1.1))
			local dipThreshold = 0.78 - severity * 0.42
			local mult = 1.0
			if flickerWave > dipThreshold then
				mult = 0.28 + (1 - severity) * 0.32
			elseif holdoutActive and math.random() < (severity * 0.14) then
				mult = 0.42
			end
			for _, entry in ipairs(upsLights) do
				if entry.light.Parent then
					entry.light.Brightness = entry.base * mult
				end
			end
		end
	end)
end

return Room102MonitorEffects
