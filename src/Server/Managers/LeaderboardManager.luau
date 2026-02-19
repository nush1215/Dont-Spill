-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)

--
local SAVE_TIME_INTERVAL = 2.5 * 60
local LOAD_TIME_INTERVAL = 3 * 60
local TOTAL_LEADERBOARD_ENTRIES = 25

--
local LEADERBOARD_DATA = {
	Currency = DataStoreService:GetOrderedDataStore("RICHEST_LEADERBOARD_V1"),
	Wins = DataStoreService:GetOrderedDataStore("MOST_WINS_LEADERBOARD_V1"),
	Streak = DataStoreService:GetOrderedDataStore("HIGHEST_STREAK_LEADERBOARD_V1"),
}

--
local PlayerDataManager

--
local LeaderboardManager = {
	_leaderboardReplica = nil,
}

function LeaderboardManager:SaveLeaderboard()
	for _, player in Players:GetPlayers() do
		PlayerDataManager:GetPlayerData(player):andThen(function(playerData)
			for dataKey, dataStore: OrderedDataStore in LEADERBOARD_DATA do
				local currentKeyData = playerData[dataKey]
				if not currentKeyData then
					continue
				end

				pcall(function()
					dataStore:SetAsync(player.UserId, math.round(currentKeyData))
				end)
			end
		end)
	end
end

function LeaderboardManager:LoadLeaderboard()
	local leaderboardData = {}
	for key, dataStore: OrderedDataStore in LEADERBOARD_DATA do
		local success, pages = pcall(function()
			return dataStore:GetSortedAsync(false, TOTAL_LEADERBOARD_ENTRIES, 1)
		end)

		if not success then
			continue
		end

		local top15 = pages:GetCurrentPage()
		leaderboardData[key] = top15
	end

	self._leaderboardReplica:Set({ "RefreshTime" }, workspace:GetServerTimeNow() + LOAD_TIME_INTERVAL)
	self._leaderboardReplica:Set({ "LeaderboardData" }, leaderboardData)
end

function LeaderboardManager:GetLeaderboardData(key: string)
	return self._leaderboardReplica.Data[key]
end

function LeaderboardManager:RemoveUserIdFromLeaderboards(userId: number)
	for _, dataStore: OrderedDataStore in LEADERBOARD_DATA do
		dataStore:RemoveAsync(userId)
	end
end

function LeaderboardManager:OnInit()
	--
	PlayerDataManager = require(script.Parent.PlayerDataManager)

	--
	self._leaderboardReplica = Replica.New({
		Token = Replica.Token("Leaderboard"),
		Data = {
			LeaderboardData = {},
			RefreshTime = workspace:GetServerTimeNow() + LOAD_TIME_INTERVAL,
		},
	})

	--
	task.spawn(function()
		while true do
			self:SaveLeaderboard()
			task.wait(SAVE_TIME_INTERVAL)
		end
	end)

	task.spawn(function()
		while true do
			self:LoadLeaderboard()
			task.wait(LOAD_TIME_INTERVAL)
		end
	end)

	--
	task.delay(3, function()
		self._leaderboardReplica:Replicate()
	end)
end

function LeaderboardManager:OnStart() end

return LeaderboardManager
