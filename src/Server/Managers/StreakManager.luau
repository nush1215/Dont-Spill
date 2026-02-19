-- Services
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local PlayerDataManager
local NotificationManager
local SpinWheelManager
local CurrencyManager

--
local StreakManager = {
	RestoreStreakEvent = BridgeNet2.ReferenceBridge("RestoreStreak"),
	RejectRestoreStreakEvent = BridgeNet2.ReferenceBridge("RejectRestoreStreak"),
	_isShuttingDown = false,
}

-- Adds to the player's current streak and previous streak
function StreakManager:AddStreak(player: Player)
	local streakAmount = player:HasTag("x2Streak") and 2 or 1
	PlayerDataManager:IncrementDataKey(player, "Streak", streakAmount)

	local hasData, currentStreak = PlayerDataManager:GetPlayerDataKey(player, "Streak"):await()
	if not hasData then
		return
	end

	PlayerDataManager:SetPlayerDataKey(player, "PreviousStreak", currentStreak)
end

-- Restores the player's previous streak
function StreakManager:RestorePlayerStreak(player: Player)
	local hasData, previousStreak = PlayerDataManager:GetPlayerDataKey(player, "PreviousStreak"):await()
	if not hasData then
		return
	end

	PlayerDataManager:SetPlayerDataKey(player, "Streak", previousStreak)
	PlayerDataManager:SetPlayerDataKey(player, "PreviousStreak", 0)
end

-- Removes the player's current streak
function StreakManager:RemoveStreak(player: Player, advertise: boolean)
	--
	PlayerDataManager:SetPlayerDataKey(player, "Streak", 0)

	if not advertise then
		PlayerDataManager:SetPlayerDataKey(player, "PreviousStreak", 0)
		return
	end

	-- Advertist the get lost streak back
	PlayerDataManager:GetPlayerDataKey(player, "PreviousStreak"):andThen(function(previousStreak)
		if advertise and previousStreak and previousStreak > 0 then
			self.RestoreStreakEvent:Fire(player, previousStreak)
		end
	end)
end

-- Tags the player, this is used if they left the game
function StreakManager:TagPlayer(player: Player)
	if self._isShuttingDown then
		return
	end

	PlayerDataManager:SetPlayerDataKey(player, "StreakTagged", true)
end

-- Checks if player has the tag if they have then we remove it
function StreakManager:_checkForTag(player: Player)
	local hasData, playerData = PlayerDataManager:GetPlayerData(player):await()
	if not hasData then
		return
	end

	if playerData.FromShutdown1 then
		return
	end

	if not playerData.StreakTagged then
		return
	end

	--
	if not player.Character then
		player.CharacterAdded:Wait()
	end

	task.delay(3, function()
		self:RemoveStreak(player, true)
		PlayerDataManager:SetPlayerDataKey(player, "StreakTagged", false)
		NotificationManager.NotifyNormalEvent:Fire(
			player,
			{ "Your streak has been removed because you left the game while on a match!", 5 }
		)
	end)
end

--
function StreakManager:OnInit()
	NotificationManager = require(script.Parent.Parent.Managers.NotificationManager)
	PlayerDataManager = require(script.Parent.Parent.Managers.PlayerDataManager)
	CurrencyManager = require(script.Parent.Parent.Managers.CurrencyManager)
	SpinWheelManager = require(script.Parent.Parent.Managers.SpinWheelManager)
end

function StreakManager:OnStart()
	Players.PlayerAdded:Connect(function(player)
		self:_checkForTag(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_checkForTag(player)
	end

	self.RejectRestoreStreakEvent:Connect(function(player: Player)
		self:RemoveStreak(player, false)
	end)

	game:BindToClose(function()
		self._isShuttingDown = true
	end)
end

return StreakManager
