-- Server-authoritative Quest Item, Key, Keycard, Fuse, & Co-op Recovery Service.
-- Pure-Luau factory (`KeyItemService.create(deps)`) so core logic runs identically
-- inside Roblox Server runtime and automated tests without Studio globals.

local KeyItemService = {}

function KeyItemService.create(deps)
	deps = deps or {}
	local ItemCatalog = deps.ItemCatalog
	local clockFn = deps.clockFn or os.clock

	local players = {} -- [userId] = { userId = number, name = string, alive = boolean, downed = boolean, items = { [itemId] = number } }
	local locks = {}   -- [lockKey] = { holderUserId = number, expiresAt = number }
	local worldPicked = {} -- [itemId] = boolean (true while held by team or completed)

	local service = {}

	local function getSortedPlayerIds()
		local ids = {}
		for userId in pairs(players) do
			table.insert(ids, userId)
		end
		table.sort(ids)
		return ids
	end

	local function findTeammate(excludeUserId, requireAlive)
		for _, uid in ipairs(getSortedPlayerIds()) do
			local p = players[uid]
			if uid ~= excludeUserId and p then
				if not requireAlive or (p.alive ~= false and p.downed ~= true) then
					return p
				end
			end
		end
		return nil
	end

	function service.registerPlayer(userId, playerName)
		if userId == nil then
			return nil
		end
		local existing = players[userId]
		if existing then
			if type(playerName) == "string" and playerName ~= "" then
				existing.name = playerName
			end
			return existing
		end
		local record = {
			userId = userId,
			name = (type(playerName) == "string" and playerName ~= "") and playerName or ("Player_" .. tostring(userId)),
			alive = true,
			downed = false,
			items = {},
		}
		players[userId] = record
		return record
	end

	function service.setPlayerStatus(userId, isAlive, isDowned)
		local p = players[userId]
		if not p then
			return false
		end
		p.alive = isAlive ~= false
		p.downed = isDowned == true
		return true
	end

	function service.acquireLock(lockKey, userId, durationSeconds)
		local now = clockFn()
		local existing = locks[lockKey]
		if existing and existing.holderUserId ~= userId and existing.expiresAt > now then
			return false, "Another survivor is currently interacting with this object"
		end
		locks[lockKey] = {
			holderUserId = userId,
			expiresAt = now + (durationSeconds or 0.8),
		}
		return true
	end

	function service.releaseLock(lockKey, userId)
		local existing = locks[lockKey]
		if existing and (userId == nil or existing.holderUserId == userId) then
			locks[lockKey] = nil
		end
	end

	function service.getItemHolder(itemId)
		for _, uid in ipairs(getSortedPlayerIds()) do
			local p = players[uid]
			local qty = p and p.items[itemId] or 0
			if qty > 0 then
				return {
					itemId = itemId,
					holderUserId = p.userId,
					holderName = p.name,
					quantity = qty,
				}
			end
		end
		return nil
	end

	function service.hasItem(userId, itemId, minQty)
		local needed = minQty or 1
		local p = players[userId]
		if not p then
			return false
		end
		return (p.items[itemId] or 0) >= needed
	end

	function service.getTeamItemCount(itemId)
		local total = 0
		for _, p in pairs(players) do
			total += (p.items[itemId] or 0)
		end
		return total
	end

	function service.hasTeamItem(itemId, minQty)
		return service.getTeamItemCount(itemId) >= (minQty or 1)
	end

	function service.isWorldPicked(itemId)
		return worldPicked[itemId] == true
	end

	function service.setWorldPicked(itemId, isPicked)
		worldPicked[itemId] = isPicked and true or nil
	end

	function service.grantItem(userId, playerName, itemId, qty, options)
		if ItemCatalog == nil then
			return false, "ItemCatalog missing"
		end
		local def = ItemCatalog.getQuestItem(itemId)
		if not def then
			return false, "Unknown quest item: " .. tostring(itemId)
		end
		local amount = math.max(1, math.floor(tonumber(qty) or 1))
		local playerRec = service.registerPlayer(userId, playerName)
		if not playerRec then
			return false, "Invalid player"
		end

		options = options or {}
		local maxStack = def.maxStack or 1
		local existingHolder = service.getItemHolder(itemId)
		if def.teamShared and maxStack == 1 and existingHolder and not options.allowDuplicateTeam then
			return false, string.format("%s is already carried by %s", def.displayName, existingHolder.holderName)
		end

		local currentQty = playerRec.items[itemId] or 0
		if not options.bypassMaxStack and currentQty + amount > maxStack then
			return false, string.format("%s stack limit (%d) reached", def.displayName, maxStack)
		end

		playerRec.items[itemId] = currentQty + amount
		worldPicked[itemId] = true

		return true, string.format("%s acquired %s", playerRec.name, def.displayName), {
			itemId = itemId,
			displayName = def.displayName,
			holderUserId = playerRec.userId,
			holderName = playerRec.name,
			quantity = playerRec.items[itemId],
		}
	end

	-- Consumes qty ONLY when the target player (or a teamShared holder if allowTeamPool ~= false)
	-- genuinely holds at least qty. Zero partial deduction occurs on failure.
	function service.consumeItem(userId, itemId, qty, options)
		local needed = math.max(1, math.floor(tonumber(qty) or 1))
		options = options or {}
		local def = ItemCatalog and ItemCatalog.getQuestItem(itemId)
		if not def then
			return false, "Unknown quest item: " .. tostring(itemId)
		end

		local holderRec = players[userId]
		if holderRec and (holderRec.items[itemId] or 0) >= needed then
			holderRec.items[itemId] = (holderRec.items[itemId] or 0) - needed
			if holderRec.items[itemId] <= 0 then
				holderRec.items[itemId] = nil
			end
			return true, string.format("Consumed %dx %s from %s", needed, def.displayName, holderRec.name), holderRec.userId
		end

		if def.teamShared ~= false and options.requireDirectHolder ~= true then
			if service.getTeamItemCount(itemId) < needed then
				return false, string.format("Requires %s", def.displayName)
			end
			local remaining = needed
			local lastHolderId = nil
			for _, uid in ipairs(getSortedPlayerIds()) do
				local p = players[uid]
				local have = p and (p.items[itemId] or 0) or 0
				if have > 0 then
					local take = math.min(have, remaining)
					p.items[itemId] = have - take
					if p.items[itemId] <= 0 then
						p.items[itemId] = nil
					end
					remaining -= take
					lastHolderId = uid
					if remaining <= 0 then
						break
					end
				end
			end
			return true, string.format("Consumed %dx %s from squad inventory", needed, def.displayName), lastHolderId
		end

		return false, string.format("%s required", def.displayName)
	end

	local function evacuatePlayerItems(userId, reason, removeRecord)
		local p = players[userId]
		if not p then
			return {}
		end

		-- Release any interaction locks held by this player immediately
		for lockKey, info in pairs(locks) do
			if info.holderUserId == userId then
				locks[lockKey] = nil
			end
		end

		local events = {}
		local heldIds = {}
		for itemId, qty in pairs(p.items) do
			if qty > 0 then
				table.insert(heldIds, itemId)
			end
		end
		table.sort(heldIds)

		-- Only transfer to an alive, standing teammate; otherwise restore world pickup cleanly
		local teammate = findTeammate(userId, true)

		if removeRecord then
			players[userId] = nil
		else
			p.alive = false
		end

		for _, itemId in ipairs(heldIds) do
			local qty = p.items[itemId] or 0
			if qty > 0 then
				if teammate then
					p.items[itemId] = nil
					teammate.items[itemId] = (teammate.items[itemId] or 0) + qty
					table.insert(events, {
						itemId = itemId,
						quantity = qty,
						reason = reason,
						fromUserId = userId,
						fromName = p.name,
						newHolderUserId = teammate.userId,
						newHolder = teammate.name,
						respawnWorld = false,
					})
				elseif removeRecord then
					p.items[itemId] = nil
					worldPicked[itemId] = nil
					table.insert(events, {
						itemId = itemId,
						quantity = qty,
						reason = reason,
						fromUserId = userId,
						fromName = p.name,
						newHolder = nil,
						respawnWorld = true,
					})
				else
					-- Solo player died: restore item into the world pickup cleanly so it cannot be lost.
					p.items[itemId] = nil
					worldPicked[itemId] = nil
					table.insert(events, {
						itemId = itemId,
						quantity = qty,
						reason = reason,
						fromUserId = userId,
						fromName = p.name,
						newHolder = nil,
						respawnWorld = true,
					})
				end
			end
		end

		return events
	end

	function service.onPlayerDied(userId)
		return evacuatePlayerItems(userId, "died", false)
	end

	function service.removePlayer(userId)
		return evacuatePlayerItems(userId, "disconnected", true)
	end

	function service.getHighestClearanceFromKeys()
		local best = 0
		if ItemCatalog == nil then
			return best
		end
		for _, p in pairs(players) do
			for itemId, qty in pairs(p.items) do
				if qty > 0 then
					local def = ItemCatalog.getQuestItem(itemId)
					if def and def.clearanceTier and def.clearanceTier > best then
						best = def.clearanceTier
					end
				end
			end
		end
		return best
	end

	function service.getInventoryList()
		local list = {}
		if ItemCatalog == nil then
			return list
		end
		for itemId, def in pairs(ItemCatalog.QUEST_ITEMS) do
			local holder = service.getItemHolder(itemId)
			local total = service.getTeamItemCount(itemId)
			if total > 0 then
				table.insert(list, {
					id = itemId,
					displayName = def.displayName,
					shortLabel = def.shortLabel or itemId,
					kind = def.kind or "QuestItem",
					missionId = def.missionId,
					quantity = total,
					holderUserId = holder and holder.holderUserId or nil,
					holderName = holder and holder.holderName or "Squad",
					consumeOnUse = def.consumeOnUse == true,
					clearanceTier = def.clearanceTier or 0,
					description = def.description or "",
				})
			end
		end
		table.sort(list, function(a, b)
			return (a.id or "") < (b.id or "")
		end)
		return list
	end

	function service.getQuestHolderLegacySummary()
		local holders = {}
		for _, item in ipairs(service.getInventoryList()) do
			holders[item.id] = item.holderName
		end
		return holders
	end

	function service.resetAll()
		locks = {}
		worldPicked = {}
		for _, p in pairs(players) do
			p.items = {}
			p.alive = true
			p.downed = false
		end
	end

	return service
end

return KeyItemService
