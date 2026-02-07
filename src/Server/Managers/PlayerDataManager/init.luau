-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)
local Promise = require(Packages.Promise)
local Signal = require(Packages.Signal)

-- Server Packages
local ServerPackages = ServerScriptService.ServerPackages
local ProfileStore = require(ServerPackages.ProfileStore)

-- Modules
local DataSettings = require(script.DataSettings)

--
local USE_STUDIO_DATA = false
local LIVE_DATA_VERSION = "PLAYER_DATA_A1"
local STUDIO_DATA_VERSION = "PLAYER_DATA_STUDIO_A3"
local DEFAULT_TIMEOUT = 25
local DATA_POLL_INTERVAL = 0.1

--
local PlayerDataToken = Replica.Token("PlayerData")

--
local PlayerDataManager = {
	OnDataChanged = Signal.new(),
	_playerData = {},
}

local PlayerDataStore = ProfileStore.New(
	RunService:IsStudio() and STUDIO_DATA_VERSION or LIVE_DATA_VERSION,
	DataSettings.PlayerDataTemplate
)

if RunService:IsStudio() and not USE_STUDIO_DATA then
	PlayerDataStore = PlayerDataStore.Mock
end

--
local function normalizeKey(key: string | { string }): { string }
	if typeof(key) == "table" then
		return key
	end
	return { key }
end

local function validatePlayer(player: Player): boolean
	return player and player:IsDescendantOf(Players)
end

-----[[ GET FUNCTIONS ]] -----
-- Note: all of the Get Functions returns a Promise

-- Gets a copy of the player data and the replica
-- @param player The player to get data for
-- @param timeout Optional timeout in seconds (default: DEFAULT_TIMEOUT)
-- @returns Promise<PlayerData, Replica>
function PlayerDataManager:GetPlayerData(player: Player, timeout: number?)
	if not validatePlayer(player) then
		return Promise.reject("Invalid player")
	end

	local startTime = tick()
	local timeoutDuration = timeout or DEFAULT_TIMEOUT

	return Promise.new(function(resolve, reject)
		local function checkData()
			local playerData = self._playerData[player]

			if playerData then
				resolve(playerData.Replica.Data, playerData.Replica)
				return true
			end

			if tick() - startTime >= timeoutDuration then
				reject(`Player data not found for {player.Name} within {timeoutDuration} seconds`)
				return true
			end

			if not validatePlayer(player) then
				reject(`Player {player.Name} left before data could be loaded`)
				return true
			end

			return false
		end

		-- Initial check
		if checkData() then
			return
		end

		-- Poll for data
		task.spawn(function()
			while true do
				task.wait(DATA_POLL_INTERVAL)
				if checkData() then
					break
				end
			end
		end)
	end)
end

-- Gets a specific key from player data
-- @param player The player to get data for
-- @param key The key to retrieve
-- @returns Promise<any>
function PlayerDataManager:GetPlayerDataKey(player: Player, key: string)
	return Promise.new(function(resolve, reject)
		local success, playerData, replica = self:GetPlayerData(player):await()

		if not success then
			reject(`Failed to get player data for {player.Name}`)
			return
		end

		if playerData[key] == nil then
			reject(`Key '{key}' not found in player data for {player.Name}`)
			return
		end

		resolve(playerData[key])
	end)
end

-----[[ SET FUNCTIONS ]] -----

-- Sets a value in player data
-- @param player The player whose data to modify
-- @param key The key (string or table path) to set
-- @param newValue The new value to set
function PlayerDataManager:SetPlayerDataKey(player: Player, key: string | table, newValue: any)
	if not validatePlayer(player) then
		warn(`Cannot set data for invalid player: {player}`)
		return
	end

	self:GetPlayerData(player)
		:andThen(function(playerData, replica)
			local normalizedKey = normalizeKey(key)
			replica:Set(normalizedKey, newValue)
			self.OnDataChanged:Fire(player, normalizedKey[1], newValue)
		end)
		:catch(function(error)
			warn(`Failed to set player data key for {player.Name}: {error}`)
		end)
end

-- Inserts a value into an array in player data
-- @param player The player whose data to modify
-- @param key The key (string or table path) to the array
-- @param value The value to insert
function PlayerDataManager:InsertPlayerDataKey(player: Player, key: string | table, value: any)
	if not validatePlayer(player) then
		warn(`Cannot insert data for invalid player: {player}`)
		return
	end

	self:GetPlayerData(player)
		:andThen(function(playerData, replica)
			local normalizedKey = normalizeKey(key)
			local currentValue = playerData[normalizedKey[1]]

			if currentValue == nil then
				warn(`Key '{normalizedKey[1]}' does not exist for {player.Name}`)
				return
			end

			if typeof(currentValue) ~= "table" then
				warn(`Expected table for key '{normalizedKey[1]}', got {typeof(currentValue)}`)
				return
			end

			replica:TableInsert(normalizedKey, value)
			self.OnDataChanged:Fire(player, normalizedKey[1], playerData[normalizedKey[1]])
		end)
		:catch(function(error)
			warn(`Failed to insert player data key for {player.Name}: {error}`)
		end)
end

-- Removes a value from an array in player data
-- @param player The player whose data to modify
-- @param key The key (string or table path) to the array
-- @param value The value to remove
function PlayerDataManager:RemovePlayerDataKey(player: Player, key: string | table, value: any)
	if not validatePlayer(player) then
		warn(`Cannot remove data for invalid player: {player}`)
		return
	end

	self:GetPlayerData(player)
		:andThen(function(playerData, replica)
			local normalizedKey = normalizeKey(key)
			local currentValue = playerData[normalizedKey[1]]

			if currentValue == nil then
				warn(`Key '{normalizedKey[1]}' does not exist for {player.Name}`)
				return
			end

			if typeof(currentValue) ~= "table" then
				warn(`Expected table for key '{normalizedKey[1]}', got {typeof(currentValue)}`)
				return
			end

			local index = table.find(currentValue, value)
			if not index then
				warn(`Value '{value}' not found in key '{normalizedKey[1]}' for {player.Name}`)
				return
			end

			replica:TableRemove(normalizedKey, index)
			self.OnDataChanged:Fire(player, normalizedKey[1], playerData[normalizedKey[1]])
		end)
		:catch(function(error)
			warn(`Failed to remove player data key for {player.Name}: {error}`)
		end)
end

-- Increments a numeric value in player data
-- @param player The player whose data to modify
-- @param key The key to increment
-- @param amount The amount to increment by (default: 1)
function PlayerDataManager:IncrementDataKey(player: Player, key: string, amount: number?)
	if not validatePlayer(player) then
		warn(`Cannot increment data for invalid player: {player}`)
		return
	end

	amount = amount or 1

	self:GetPlayerData(player)
		:andThen(function(playerData, replica)
			if typeof(playerData[key]) ~= "number" then
				warn(`Expected number for key '{key}', got {typeof(playerData[key])}`)
				return
			end

			local currentValue = playerData[key]
			local newValue = currentValue + amount
			replica:Set({ key }, newValue)
			self.OnDataChanged:Fire(player, key, newValue)
		end)
		:catch(function(error)
			warn(`Failed to increment data key for {player.Name}: {error}`)
		end)
end

-- Decrements a numeric value in player data
-- @param player The player whose data to modify
-- @param key The key to decrement
-- @param amount The amount to decrement by (default: 1)
function PlayerDataManager:DecrementDataKey(player: Player, key: string, amount: number?)
	if not validatePlayer(player) then
		warn(`Cannot decrement data for invalid player: {player}`)
		return
	end

	amount = amount or 1

	self:GetPlayerData(player)
		:andThen(function(playerData, replica)
			if typeof(playerData[key]) ~= "number" then
				warn(`Expected number for key '{key}', got {typeof(playerData[key])}`)
				return
			end

			local currentValue = playerData[key]
			local newValue = currentValue - amount
			replica:Set({ key }, newValue)
			self.OnDataChanged:Fire(player, key, newValue)
		end)
		:catch(function(error)
			warn(`Failed to decrement data key for {player.Name}: {error}`)
		end)
end

-----[[ LISTEN FUNCTIONS ]] -----
-- Listens for changes to a specific key in player data
-- @param player The player to listen for
-- @param key The key to listen for changes on
-- @param callback Function called when the key changes
function PlayerDataManager:ListenForChanges(player: Player, key: string, callback: (newValue: any) -> ())
	return self.OnDataChanged:Connect(function(dataChangedPlayer, changedKey, newValue)
		if dataChangedPlayer == player and changedKey == key then
			callback(newValue)
		end
	end)
end

-- Sets up player data when a player joins
-- @param player The player to set up
function PlayerDataManager:_setupPlayer(player: Player)
	if not validatePlayer(player) then
		return
	end

	local playerProfile = PlayerDataStore:StartSessionAsync(`Player_{player.UserId}`, {
		Cancel = function()
			return not validatePlayer(player)
		end,
	})

	if not playerProfile then
		player:Kick("There's a problem loading your data! Please try rejoining.")
		return
	end

	playerProfile:AddUserId(player.UserId)
	playerProfile:Reconcile()

	playerProfile.OnSessionEnd:Connect(function()
		self._playerData[player] = nil
		player:Kick()
	end)

	if not validatePlayer(player) then
		playerProfile:EndSession()
		return
	end

	local dataReplica = Replica.New({
		Token = PlayerDataToken,
		Tags = { UserId = player.UserId },
		Data = playerProfile.Data,
	})

	self:_setupLeaderstats(player, playerProfile.Data)
	self:_subscribePlayerToReplica(player, dataReplica)

	self._playerData[player] = {
		Profile = playerProfile,
		Replica = dataReplica,
	}

	if playerProfile.Data.HasOGTag then
		player:AddTag("OG")
	end
end

-- Sets up leaderstats for a player
-- @param player The player to set up leaderstats for
-- @param playerData The player's data
function PlayerDataManager:_setupLeaderstats(player: Player, playerData: any)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	for dataKey, dataName in DataSettings.ToLeaderstats do
		if not DataSettings.PlayerDataTemplate[dataKey] then
			warn(`{dataKey} not found in PlayerDataTemplate`)
			continue
		end

		local intValue = Instance.new("IntValue")
		intValue.Name = dataName
		intValue.Value = playerData[dataKey]
		intValue.Parent = leaderstats

		self:ListenForChanges(player, dataKey, function(newValue)
			intValue.Value = newValue
		end)
	end
end

-- Subscribes a player to their data replica
-- @param player The player to subscribe
-- @param dataReplica The replica to subscribe to
function PlayerDataManager:_subscribePlayerToReplica(player: Player, dataReplica: any)
	if Replica.ReadyPlayers[player] then
		dataReplica:Subscribe(player)
		return
	end

	local connection
	connection = Replica.NewReadyPlayer:Connect(function(readyPlayer)
		if readyPlayer == player then
			dataReplica:Subscribe(player)
			connection:Disconnect()
		end
	end)

	dataReplica.Maid:Add(connection)
end

-- Cleans up player data when a player leaves
-- @param player The player to clean up
function PlayerDataManager:_cleanupPlayer(player: Player)
	local playerData = self._playerData[player]

	if playerData then
		playerData.Profile:EndSession()
		playerData.Replica:Destroy()
		self._playerData[player] = nil
	end
end

-- Initializes the PlayerDataManager
-- Sets up event connections for player join/leave
function PlayerDataManager:OnInit()
	Players.PlayerAdded:Connect(function(player: Player)
		self:_setupPlayer(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_cleanupPlayer(player)
	end)
end

return PlayerDataManager
