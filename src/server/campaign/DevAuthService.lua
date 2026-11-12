-- Server-authoritative Developer authorization & Development Mode state manager.
-- Never trusts client attributes or client-supplied admin flags.
-- Also supports pure createEngine(env) instantiation for automated unit testing.

local NetProtocol = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("NetProtocol"))
local ServerEnvironmentConfig = require(script.Parent:WaitForChild("ServerEnvironmentConfig"))

local DevAuthService = {}

function DevAuthService.createEngine(options)
	options = options or {}
	local config = options.config or ServerEnvironmentConfig
	local env = options.env or {
		isStudio = function()
			return game:GetService("RunService"):IsStudio()
		end,
		getPrivateServerId = function()
			return game.PrivateServerId
		end,
		getCreatorType = function()
			return game.CreatorType
		end,
		getCreatorId = function()
			return game.CreatorId
		end,
		isUserCreatorType = function(ct)
			return ct == Enum.CreatorType.User
		end,
		setWorkspaceAttribute = function(key, val)
			game:GetService("Workspace"):SetAttribute(key, val)
		end,
		syncPlayerAttributes = function(player, canTools, devActive, godActive)
			if not player or not player.SetAttribute then
				return
			end
			player:SetAttribute(NetProtocol.Attributes.CanUseDevTools, canTools)
			player:SetAttribute(NetProtocol.Attributes.CanUseAdminMode, devActive)
			player:SetAttribute(NetProtocol.Attributes.DevModeActive, devActive)
			player:SetAttribute(NetProtocol.Attributes.IsAdminGodMode, godActive)
			local char = player.Character
			if char and char.SetAttribute then
				char:SetAttribute(NetProtocol.Attributes.IsAdminGodMode, godActive)
			end
		end,
	}

	local devModeByUserId = {}
	local godModeByUserId = {}
	local devSessionTainted = false

	local engine = {}

	function engine.getEnvironmentKind()
		if env.isStudio() then
			return "Studio"
		elseif env.getPrivateServerId() ~= "" then
			return "PrivateServer"
		end
		return "PublicServer"
	end

	function engine.isEnvironmentDevAllowed()
		local kind = engine.getEnvironmentKind()
		if kind == "Studio" then
			return config.ALLOW_DEV_TOOLS_IN_STUDIO == true
		elseif kind == "PrivateServer" then
			return config.ALLOW_DEV_TOOLS_IN_PRIVATE_SERVER == true
		end
		return config.ALLOW_DEV_TOOLS_IN_PUBLIC_SERVER == true
	end

	function engine.isAuthorizedDeveloper(player)
		if not player or type(player.UserId) ~= "number" then
			return false, "Invalid player"
		end
		if not engine.isEnvironmentDevAllowed() then
			return false, "Developer tools are disabled in public production servers"
		end
		if config.DEV_USER_IDS and config.DEV_USER_IDS[player.UserId] == true then
			return true
		end
		local creatorId = env.getCreatorId()
		if env.isUserCreatorType(env.getCreatorType()) and creatorId and creatorId > 0 and player.UserId == creatorId then
			return true
		end
		if env.isStudio() and config.ALLOW_OFFLINE_STUDIO_PLAYER1_DEV and player.UserId == -1 then
			return true
		end
		return false, "User is not on the server developer allowlist"
	end

	function engine.hasAnyActiveDevMode()
		for _, active in pairs(devModeByUserId) do
			if active == true then
				return true
			end
		end
		return false
	end

	function engine.isDevSessionTainted()
		return devSessionTainted
	end

	function engine.markDevSessionTainted()
		if not devSessionTainted then
			devSessionTainted = true
			env.setWorkspaceAttribute(NetProtocol.Attributes.DevSessionTainted, true)
		end
	end

	function engine.syncWorkspaceMode()
		local mode = engine.hasAnyActiveDevMode() and NetProtocol.EnvironmentMode.Development or NetProtocol.EnvironmentMode.Campaign
		env.setWorkspaceAttribute(NetProtocol.Attributes.EnvironmentMode, mode)
		return mode
	end

	function engine.syncPlayer(player)
		if not player or type(player.UserId) ~= "number" then
			return
		end
		local allowed = engine.isAuthorizedDeveloper(player)
		local uid = player.UserId
		if not allowed then
			devModeByUserId[uid] = false
			godModeByUserId[uid] = false
		end
		local devActive = allowed and (devModeByUserId[uid] == true)
		local godActive = devActive and (godModeByUserId[uid] == true)
		env.syncPlayerAttributes(player, allowed, devActive, godActive)
	end

	function engine.isDevModeEnabled(player)
		if not player or type(player.UserId) ~= "number" then
			return false
		end
		local allowed = engine.isAuthorizedDeveloper(player)
		return allowed and (devModeByUserId[player.UserId] == true)
	end

	function engine.isGodModeEnabled(player)
		if not engine.isDevModeEnabled(player) then
			return false
		end
		return godModeByUserId[player.UserId] == true
	end

	function engine.setDevModeEnabled(player, enabled)
		local allowed, reason = engine.isAuthorizedDeveloper(player)
		if not allowed then
			engine.syncPlayer(player)
			return false, reason
		end
		local nextState = (enabled == true)
		devModeByUserId[player.UserId] = nextState
		if nextState then
			engine.markDevSessionTainted()
		else
			godModeByUserId[player.UserId] = false
		end
		engine.syncPlayer(player)
		engine.syncWorkspaceMode()
		return true, nextState
	end

	function engine.setGodModeEnabled(player, enabled)
		local allowed, reason = engine.isAuthorizedDeveloper(player)
		if not allowed then
			engine.syncPlayer(player)
			return false, reason
		end
		if not engine.isDevModeEnabled(player) then
			return false, "Enable Development Mode first (!dev)"
		end
		local nextGod = (enabled == true)
		godModeByUserId[player.UserId] = nextGod
		engine.markDevSessionTainted()
		engine.syncPlayer(player)
		return true, nextGod
	end

	function engine.clearPlayer(player)
		if not player or type(player.UserId) ~= "number" then
			return
		end
		devModeByUserId[player.UserId] = nil
		godModeByUserId[player.UserId] = nil
		engine.syncWorkspaceMode()
	end

	function engine.resetAll()
		table.clear(devModeByUserId)
		table.clear(godModeByUserId)
		devSessionTainted = false
		env.setWorkspaceAttribute(NetProtocol.Attributes.DevSessionTainted, false)
		engine.syncWorkspaceMode()
	end

	env.setWorkspaceAttribute(NetProtocol.Attributes.EnvironmentMode, NetProtocol.EnvironmentMode.Campaign)
	env.setWorkspaceAttribute(NetProtocol.Attributes.DevSessionTainted, false)

	return engine
end

local singleton = nil
function DevAuthService.getSingleton()
	if not singleton then
		singleton = DevAuthService.createEngine()
	end
	return singleton
end

return DevAuthService
