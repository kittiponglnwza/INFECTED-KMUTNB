-- Server-only explicit environment and Developer allowlist configuration.
-- Clients never require or read this module.

return {
	-- Add authorized developer Roblox UserIds here.
	-- Experience owner (game.CreatorId when CreatorType == User) is automatically included.
	DEV_USER_IDS = {
		-- [123456789] = true,
	},

	-- Explicit server environment policy:
	ALLOW_DEV_TOOLS_IN_STUDIO = true,
	-- In Studio offline Local Server, Player1 (UserId == -1) is authorized so devs can test Dev Mode,
	-- while Player2 (-2), Player3 (-3), Player4 (-4) remain normal Campaign players for security/co-op checks.
	ALLOW_OFFLINE_STUDIO_PLAYER1_DEV = true,
	-- Allowlisted devs may test in private test servers; public production servers block dev commands by default.
	ALLOW_DEV_TOOLS_IN_PRIVATE_SERVER = true,
	ALLOW_DEV_TOOLS_IN_PUBLIC_SERVER = false,
}
