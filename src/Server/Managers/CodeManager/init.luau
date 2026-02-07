-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local Codes = require(script.Codes)

--
local PlayerDataManager
local NotificationManager

--
local CodeManager = {
	ClaimCodeEvent = BridgeNet2.ReferenceBridge("ClaimCode"),
	_inCooldown = {},
}

function CodeManager:ClaimCode(player: Player, code: string)
	-- Add a debounce so that it wont call ts a billion times in 1 sec
	if self._inCooldown[player] then
		NotificationManager.NotifyNormalEvent:Fire(
			player,
			{ "Please wait a moment before redeeming another code!", 3, "Reject" }
		)
		return
	end

	self._inCooldown[player] = true
	task.delay(1, function()
		self._inCooldown[player] = false
	end)

	-- Check if the code is valid
	local codeData = Codes.GetCodeFromCode(code)
	if not codeData then
		NotificationManager.NotifyNormalEvent:Fire(player, { "Invalid code!", 5, "Reject" })
		return
	end

	-- Check if the player has already redeemed the code
	local hasData, playerData = PlayerDataManager:GetPlayerData(player):await()
	if not hasData then
		return
	end

	if table.find(playerData.RedeemedCodes, code) then
		NotificationManager.NotifyNormalEvent:Fire(player, { "You have already redeemed this code!", 5, "Reject" })
		return
	end

	-- Redeem the code
	table.insert(playerData.RedeemedCodes, code)
	PlayerDataManager:SetPlayerDataKey(player, "CodeRedeemed", playerData.CodeRedeemed)

	codeData.Callback(player)
	NotificationManager.NotifyNormalEvent:Fire(
		player,
		{ `Successfully Redeemed <font color="#ffd400">{code}</font> Code!`, 5, "CollectedReward" }
	)

	if codeData.OnClaimMessage then
		NotificationManager.NotifyNormalEvent:Fire(player, { codeData.OnClaimMessage, 5 })
	end

	task.spawn(function()
		pcall(function()
			AnalyticsService:LogCustomEvent(player, "Redeemed Code", 1, {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = code,
			})
		end)
	end)
end

function CodeManager:OnInit()
	PlayerDataManager = require(script.Parent.PlayerDataManager)
	NotificationManager = require(script.Parent.NotificationManager)
end

function CodeManager:OnStart()
	self.ClaimCodeEvent:Connect(function(player: Player, code: string)
		self:ClaimCode(player, code)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self._inCooldown[player] = nil
	end)
end

return CodeManager
