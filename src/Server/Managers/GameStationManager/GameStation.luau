-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)
local Trove = require(Packages.Trove)
local Signal = require(Packages.Signal)
local Sift = require(Packages.Sift)

-- Managers
local BotsManager = require(script.Parent.Parent.BotsManager)

--
local GAME_STATION_TOKEN = Replica.Token("GameStation")

--
local GameStation = {}
GameStation.__index = GameStation

--[[
	Don't Spill the Water: turn-based, no rounds.
	Game ends when: (1) the other player moves / causes spill, or (2) water threshold is hit.
]]
function GameStation.new(station: Model, countdownTime: number, waterThreshold: number?)
	local self = setmetatable({
		--
		Station = station,

		--
		IsGameStarted = false,

		--
		_countdownTime = countdownTime,
		_waterThreshold = waterThreshold or 100,

		--
		_gameCleaner = Trove.new(),

		--
		OnPlayerJoined = Signal.new(),
		OnPlayerLeft = Signal.new(),
		GameStarted = Signal.new(),
		GameStopped = Signal.new(),
		OnCountdown = Signal.new(),

		-- Turn-based
		OnTurnChanged = Signal.new(),
		OnWaterAdded = Signal.new(),
		OnThresholdHit = Signal.new(),
		GameEnded = Signal.new(),
	}, GameStation)

	self:_init()
	return self
end

function GameStation:_init()
	--
	local station = self.Station
	local chairs = station.Chairs

	-- Setup the replica
	local stationReplica = Replica.New({
		Token = GAME_STATION_TOKEN,
		Tags = { Station = self.Station.Name },
		Data = {
			-- "Player1" | "Player2" - whose turn to add water
			CurrentTurn = "Player1",

			Players = {
				--[Player: Player] = "Player1" | "Player2"
			},

			-- Water level (0 to WaterThreshold); game ends when >= WaterThreshold
			WaterLevel = 0,
			WaterThreshold = self._waterThreshold,

			-- Who last added water (slot); when threshold is hit, they are the loser
			LastWaterAddedBy = nil :: "Player1" | "Player2" | nil,

			-- Set when game ends (single match, no rounds)
			GameWinner = nil :: Player?,
			GameLoser = nil :: Player?,
		},
	})

	stationReplica:Replicate()
	self._stationReplica = stationReplica

	-- Setup the seat for the player slots
	for _, chair in chairs:GetChildren() do
		local seat: Seat = chair.Seat

		seat:GetPropertyChangedSignal("Occupant"):Connect(function()
			local currentOccupant = seat.Occupant
			if currentOccupant then
				local player = Players:GetPlayerFromCharacter(currentOccupant.Parent)
				self:AddPlayer(player, chair.Name)
			else
				self:RemovePlayerFromSlot(chair.Name)
			end
		end)
	end

	-- Setup listeners
	Players.PlayerRemoving:Connect(function(player, reason)
		self:RemovePlayer(player)
	end)
end

-- Attempts to start the game
function GameStation:_attemptStartGame()
	local players = self._stationReplica.Data.Players
	local playerCount = Sift.Dictionary.count(players)

	if playerCount == 2 then
		self:_startGame()
	end
end

-- Starts the match
function GameStation:_startGame()
	-- Setup the countdown
	local toStartThread = task.spawn(function()
		-- Countdown before starting
		for i = self._countdownTime, 0, -1 do
			self.OnCountdown:Fire(i)
			task.wait(1)
		end

		self.GameStarted:Fire(self.Station)
		self.IsGameStarted = true
	end)
	self._gameCleaner:Add(toStartThread)

	-- Keep checking if players leave during countdown
	self._gameCleaner:Add(task.spawn(function()
		repeat
			task.wait()
		until self.IsGameStarted or Sift.Dictionary.count(self._stationReplica.Data.Players) < 2

		if not self.IsGameStarted then
			task.cancel(toStartThread)
		end
	end))
end

-- Stops the match / Cleans up everything for a full reset
function GameStation:StopGame()
	--
	self._gameCleaner:Clean()
	self.IsGameStarted = false
	self.GameStopped:Fire(self.Station)

	-- Reset turn and water state
	self._stationReplica:Set({ "CurrentTurn" }, "Player1")
	self._stationReplica:Set({ "WaterLevel" }, 0)
	self._stationReplica:Set({ "LastWaterAddedBy" }, nil)
	self._stationReplica:Set({ "GameWinner" }, nil)
	self._stationReplica:Set({ "GameLoser" }, nil)

	self:RemovePlayerFromSlot("Player1")
	self:RemovePlayerFromSlot("Player2")

	print(self.Station.Name .. " game stopped.")
end

-- Water level and threshold
function GameStation:GetWaterLevel(): number
	return self._stationReplica.Data.WaterLevel
end

function GameStation:GetWaterThreshold(): number
	return self._stationReplica.Data.WaterThreshold
end

function GameStation:SetWaterThreshold(threshold: number)
	self._waterThreshold = threshold
	self._stationReplica:Set({ "WaterThreshold" }, threshold)
end

-- Add water. Pass the player who is adding (used to track last adder = loser when threshold hit).
-- Returns (newLevel, overflowed). If overflowed, game should end (last adder loses).
function GameStation:AddWater(amount: number, playerWhoAdded: Player): (number, boolean)
	local level = self._stationReplica.Data.WaterLevel
	local threshold = self._stationReplica.Data.WaterThreshold
	local newLevel = math.clamp(level + amount, 0, threshold + 15)
	self._stationReplica:Set({ "WaterLevel" }, newLevel)
	local slot = self:GetPlayerSlot(playerWhoAdded)
	if slot then
		self._stationReplica:Set({ "LastWaterAddedBy" }, slot)
	end
	self.OnWaterAdded:Fire(newLevel, amount)

	print(newLevel, threshold)

	local overflowed = newLevel >= threshold
	if overflowed then
		self.OnThresholdHit:Fire(newLevel)
	end

	return newLevel, overflowed
end

function GameStation:SetWaterLevel(level: number)
	level = math.max(0, level)
	self._stationReplica:Set({ "WaterLevel" }, level)
end

function GameStation:IsThresholdReached(): boolean
	return self._stationReplica.Data.WaterLevel >= self._stationReplica.Data.WaterThreshold
end

-- End the game. Winner/loser are the Player objects.
function GameStation:EndGame(winner: Player?, loser: Player?)
	self._stationReplica:Set({ "GameWinner" }, winner)
	self._stationReplica:Set({ "GameLoser" }, loser)
	self.GameEnded:Fire(winner, loser)
end

-- Call when water threshold was just hit: last player who added water loses (they overflowed), other wins.
function GameStation:EndGameFromThresholdHit()
	local loser = self:GetLastWaterAdder()
	local winner = if loser then self:GetOtherPlayer(loser) else nil
	self:EndGame(winner, loser)
end

-- Call when a player moved out of turn (e.g. moved the cup): that player loses, other wins.
function GameStation:EndGameFromPlayerMovedOutOfTurn(playerWhoMoved: Player)
	local loser = playerWhoMoved
	local winner = self:GetOtherPlayer(playerWhoMoved)
	self:EndGame(winner, loser)
end

-- Gets the other player in the station (opponent)
function GameStation:GetOtherPlayer(player: Player): Player?
	local slot = self:GetPlayerSlot(player)
	if not slot then
		return nil
	end
	local otherSlot = if slot == "Player1" then "Player2" else "Player1"
	return self:GetPlayerInSlot(otherSlot)
end

function GameStation:GetGameWinner(): Player?
	return self._stationReplica.Data.GameWinner
end

function GameStation:GetGameLoser(): Player?
	return self._stationReplica.Data.GameLoser
end

-- Who last added water (the one who loses when threshold is hit)
function GameStation:GetLastWaterAdder(): Player?
	local slot = self._stationReplica.Data.LastWaterAddedBy
	return if slot then self:GetPlayerInSlot(slot) else nil
end

function GameStation:GetLastWaterAddedBySlot(): "Player1" | "Player2" | nil
	return self._stationReplica.Data.LastWaterAddedBy
end

-- True if the game has been ended (winner/loser set)
function GameStation:IsGameEnded(): boolean
	return self._stationReplica.Data.GameWinner ~= nil or self._stationReplica.Data.GameLoser ~= nil
end

-- Adds the player to the station
function GameStation:AddPlayer(player: Player, playerSlot: "Player1" | "Player2")
	-- Get the current players
	local currentPlayers = self._stationReplica.Data.Players
	local playerInSlot = self:GetPlayerInSlot(playerSlot)

	-- Check if there's already a player in the slot
	if playerInSlot then
		return
	end

	-- Force the player to sit in the chair
	local chairs = self.Station.Chairs
	local slotChair = chairs[playerSlot]
	local seat: Seat = slotChair.Seat
	seat:Sit(player.Character.Humanoid)

	-- Set the player in the slot
	currentPlayers[player] = playerSlot

	-- Update the replica
	self._stationReplica:Set({ "Players" }, currentPlayers)
	self.OnPlayerJoined:Fire(player, playerSlot)

	-- Attempt to start game
	self:_attemptStartGame()
end

-- Removes the player from the station
function GameStation:RemovePlayer(player: Player)
	local slotName = self:GetPlayerSlot(player)
	if slotName then
		self:RemovePlayerFromSlot(slotName)
	end
end

-- Removes the player from the specified slot
function GameStation:RemovePlayerFromSlot(slotName: "Player1" | "Player2")
	-- Get the current players
	local playerInSlot = self:GetPlayerInSlot(slotName)
	if not playerInSlot then
		return
	end

	--
	local currentPlayers = self._stationReplica.Data.Players
	currentPlayers[playerInSlot] = nil

	-- Update the replica
	self._stationReplica:Set({ "Players" }, currentPlayers)
	self.OnPlayerLeft:Fire(playerInSlot, slotName)

	-- Remove them from the chair
	local chairs = self.Station.Chairs
	local slotChair = chairs[slotName]

	slotChair.Seat.Disabled = true
	task.delay(0.5, function()
		slotChair.Seat.Disabled = false
	end)

	--
	if self.IsGameStarted then
		self:StopGame()
	end
end

-- Gets the player's slot in the station
function GameStation:GetPlayerSlot(player: Player): "Player1" | "Player2" | nil
	local players = self._stationReplica.Data.Players
	return players[player]
end

-- Gets the player in the specified slot
function GameStation:GetPlayerInSlot(slotName: "Player1" | "Player2"): Player | nil
	local players = self._stationReplica.Data.Players
	for player, slot in pairs(players) do
		if slot == slotName then
			return player
		end
	end
	return nil
end

-- Gets all players in the station
function GameStation:GetPlayers(): { Player }
	return Sift.Dictionary.keys(self._stationReplica.Data.Players)
end

-- Gets a free slot in the station
function GameStation:GetFreeSlot(): "Player1" | "Player2" | nil
	local player1 = self:GetPlayerInSlot("Player1")
	if not player1 then
		return "Player1"
	end

	local player2 = self:GetPlayerInSlot("Player2")
	if not player2 then
		return "Player2"
	end

	return nil
end

-- Alias for single-match winner (replaces old round-based GetWinner)
function GameStation:GetWinner(): Player?
	return self:GetGameWinner()
end

-- Alias for single-match loser (replaces old round-based GetLoser)
function GameStation:GetLoser(): Player?
	return self:GetGameLoser()
end

return GameStation
