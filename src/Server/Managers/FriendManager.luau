-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages

--
local FRIEND_REFRESH_INTERVAL = 10

--
local FriendManager = {}

function FriendManager:_refreshFriendsAmount()
	--
	local function refreshPlayer(player: Player)
		local friendsAmount = 0

		for _, currentPlayer in Players:GetPlayers() do
			local success, isFriend = pcall(function()
				return player:IsFriendsWith(currentPlayer.UserId)
			end)

			if success and isFriend then
				friendsAmount = math.clamp(friendsAmount + 1, 0, 10)
			end
		end

		player:SetAttribute("FriendsAmount", friendsAmount)
	end

	for _, player in Players:GetPlayers() do
		refreshPlayer(player)
	end
end

function FriendManager:OnStart()
	task.spawn(function()
		while true do
			self:_refreshFriendsAmount()
			task.wait(FRIEND_REFRESH_INTERVAL)
		end
	end)
end

return FriendManager
