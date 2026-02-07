-- Services
local BadgeService = game:GetService("BadgeService")

-- Modules
local Modules = script.Parent.Parent.Modules
local Badges
local NotificationManager

local BadgeManager = {
	_playerBadges = {},
}

--[=[
	Initializes the player's badge cache table if it doesn't exist.

	@param player Player -- The player to initialize the cache for.
	@private
]=]
function BadgeManager:_ensurePlayerCache(player: Player)
	if not self._playerBadges[player] then
		self._playerBadges[player] = {}
	end
end

--[=[
	Checks if a player has a specific badge via BadgeService.

	@param userId number -- The user ID to check.
	@param badgeId number -- The badge ID to check.
	@return boolean -- Whether the check was successful.
	@return boolean -- Whether the user has the badge.
	@private
]=]
function BadgeManager:_checkBadgeOwnership(userId: number, badgeId: number): (boolean, boolean)
	local success, hasBadge = pcall(function()
		return BadgeService:UserHasBadgeAsync(userId, badgeId)
	end)

	return success, hasBadge
end

--[=[
	Awards a badge to the specified player if they have not already received it.

	@param player Player -- The player to award the badge to.
	@param badgeKey string -- The key of the badge to be awarded.
	@param dontAnnounce boolean? -- Whether to skip the notification announcement.
	@return boolean -- Whether the badge was successfully awarded.
]=]
function BadgeManager:AwardBadge(player: Player, badgeKey: string, dontAnnounce: boolean?): boolean
	local badgeData = Badges.GetBadgeFromKey(badgeKey)
	if not badgeData then
		warn(`BadgeManager:AwardBadge -> Badge key "{badgeKey}" does not exist in config!`)
		return false
	end

	self:_ensurePlayerCache(player)

	-- Check if already cached as having the badge
	if self._playerBadges[player][badgeKey] then
		return false
	end

	-- Verify badge ownership via BadgeService
	local success, hasBadge = self:_checkBadgeOwnership(player.UserId, badgeData.BadgeId)
	if not success then
		warn(`BadgeManager:AwardBadge -> Failed to check badge ownership for player {player.Name} (Badge: {badgeKey})`)
		return false
	end

	if hasBadge then
		self._playerBadges[player][badgeKey] = true
		return false
	end

	-- Award the badge
	local awardSuccess, errorMessage = pcall(function()
		BadgeService:AwardBadge(player.UserId, badgeData.BadgeId)
	end)

	if not awardSuccess then
		warn(`BadgeManager:AwardBadge -> Failed to award badge to {player.Name}: {errorMessage}`)
		return false
	end

	-- Cache and notify
	self._playerBadges[player][badgeKey] = true

	if not dontAnnounce then
		NotificationManager.NotifyNormalEvent:Fire(
			player,
			{ `Badge <font color="#ffd400">{badgeData.Name}</font> Unlocked!` }
		)
	end

	return true
end

--[=[
	Checks if a player has a specific badge (cached check only).

	@param player Player -- The player to check.
	@param badgeKey string -- The key of the badge to check.
	@return boolean -- Whether the player has the badge.
]=]
function BadgeManager:PlayerHasBadge(player: Player, badgeKey: string): boolean
	local playerCache = self._playerBadges[player]
	return playerCache ~= nil and playerCache[badgeKey] == true
end

--[=[
	Caches all badges that the specified player has already received.

	@param player Player -- The player whose badges are to be cached.
	@private
]=]
function BadgeManager:_cachePlayerBadges(player: Player)
	self:_ensurePlayerCache(player)

	local function cacheBadge(badgeData: Badges.Badge)
		local success, hasBadge = self:_checkBadgeOwnership(player.UserId, badgeData.BadgeId)

		if success and hasBadge then
			self._playerBadges[player][badgeData.Key] = true
		end
	end

	-- Cache all badges asynchronously
	for _, badge: Badges.Badge in Badges.GetBadges() do
		task.spawn(cacheBadge, badge)
	end
end

--[=[
	Handles when a player joins the game.

	@param player Player -- The player who joined.
]=]
function BadgeManager:OnPlayerAdded(player: Player)
	self._playerBadges[player] = {}
	self:_cachePlayerBadges(player)
end

--[=[
	Handles when a player leaves the game.

	@param player Player -- The player who left.
]=]
function BadgeManager:OnPlayerRemoving(player: Player)
	self._playerBadges[player] = nil
end

--[=[
	Initializes the BadgeManager and sets up badge listeners.
]=]
function BadgeManager:OnInit()
	NotificationManager = require(script.Parent.NotificationManager)
	Badges = require(Modules.Badges)

	-- Initialize badge listeners
	for _, badge: Badges.Badge in Badges.GetBadges() do
		if not badge.OnInitCallback then
			continue
		end

		badge.OnInitCallback(function(player: Player, badgeKey: string, announce: boolean?)
			if self:PlayerHasBadge(player, badgeKey) then
				return
			end

			self:AwardBadge(player, badgeKey, announce)
		end)
	end
end

function BadgeManager:OnStart() end

return BadgeManager
