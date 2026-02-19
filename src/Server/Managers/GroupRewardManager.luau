-- Services
local AnalyticsService = game:GetService("AnalyticsService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local NotificationManager
local PlayerDataManager
local CurrencyManager

--
local GROUP_ID = 424552416
local REWARD = 250

--
local GroupRewardManager = {
	--
	ClaimRewardEvent = BridgeNet2.ReferenceBridge("ClaimGroupReward"),

	--
	_inCooldown = {},
}

--
function GroupRewardManager:ClaimReward(player: Player)
	-- Add a debounce so that it wont call ts a billion times in 1 sec
	if self._inCooldown[player] then
		return
	end

	self._inCooldown[player] = true
	task.delay(3, function()
		self._inCooldown[player] = false
	end)

	-- Check if player has already claimed the reward
	local hasData, hasClaimedGroupReward = PlayerDataManager:GetPlayerDataKey(player, "ClaimedGroupReward"):await()
	if not hasData then
		return
	end

	if hasClaimedGroupReward then
		NotificationManager.NotifyNormalEvent:Fire(player, { "You have already claimed the reward!", 5, "Reject" })
		return
	end

	--
	local success, isPlayerInGroup = pcall(function()
		return player:IsInGroup(GROUP_ID)
	end)

	if not success then
		return
	end

	if not isPlayerInGroup then
		NotificationManager.NotifyNormalEvent:Fire(player, {
			`Join the Group and Like the Game to get the <font color="#ffd400">Reward!</font>`,
			5,
			"Reject",
		})
		return
	end

	--
	PlayerDataManager:SetPlayerDataKey(player, "ClaimedGroupReward", true)
	CurrencyManager:IncrementCurrency(player, REWARD, true)
	NotificationManager.NotifyNormalEvent:Fire(
		player,
		{ `You have received <font color="#2de200">{REWARD} Bux</font>`, 6, "CollectedReward" }
	)

	-- Analytics
	task.spawn(function()
		pcall(function()
			PlayerDataManager:GetPlayerDataKey(player, "Currency"):andThen(function(currency)
				AnalyticsService:LogEconomyEvent(
					player,
					Enum.AnalyticsEconomyFlowType.Source,
					"Bux",
					REWARD,
					currency,
					Enum.AnalyticsEconomyTransactionType.Onboarding.Name,
					"GroupReward"
				)
			end)
		end)
	end)
end

--
function GroupRewardManager:OnInit()
	NotificationManager = require(script.Parent.NotificationManager)
	PlayerDataManager = require(script.Parent.PlayerDataManager)
	CurrencyManager = require(script.Parent.CurrencyManager)
end

function GroupRewardManager:OnStart()
	self.ClaimRewardEvent:Connect(function(player: Player)
		self:ClaimReward(player)
	end)
end

return GroupRewardManager
