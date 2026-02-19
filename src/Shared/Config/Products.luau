-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local AnalyticsService = game:GetService("AnalyticsService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

-- Shared
local Shared = ReplicatedStorage.Shared
local RandomUtil = require(Shared.RandomUtil)

-- Managers
local NotificationManager
local PlayerDataManager
local CurrencyManager
local StreakManager
local DailyRewardManager

if RunService:IsServer() then
	NotificationManager = require(ServerScriptService.Server.Managers.NotificationManager)
	PlayerDataManager = require(ServerScriptService.Server.Managers.PlayerDataManager)
	CurrencyManager = require(ServerScriptService.Server.Managers.CurrencyManager)
	StreakManager = require(ServerScriptService.Server.Managers.StreakManager)
	DailyRewardManager = require(ServerScriptService.Server.Managers.DailyRewardManager)
end

-- Helper for analytics
local function logCurrencySource(player: Player, amount: number, productId: string)
	if RunService:IsClient() then
		return
	end
	task.spawn(function()
		pcall(function()
			PlayerDataManager:GetPlayerDataKey(player, "Currency"):andThen(function(currency)
				AnalyticsService:LogEconomyEvent(
					player,
					Enum.AnalyticsEconomyFlowType.Source,
					"Bux",
					amount,
					currency,
					Enum.AnalyticsEconomyTransactionType.IAP.Name,
					productId
				)
			end)
		end)
	end)
end

--
export type Product = {
	Id: string,
	Name: string,
	Type: "Core" | "Troll" | "Currency",
	Description: string,
	PurchaseOnce: boolean,
	Icon: string,
	ProductId: number,
	CurrencyPrice: number?,
	Value: number?, -- this is optional mostly used for reference how much X amount an X thing is
	Callback: (player: Player, toGift: Player?) -> ()?,
}

local Products = {}
Products.Data = {

	{
		Id = "StarterPack",
		Name = "Starter Pack",
		Type = "Core",
		ProductId = 3539938207,
		PurchaseOnce = true,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			--
			CurrencyManager:IncrementCurrency(player, 500)
			logCurrencySource(player, 500, "StarterPack")

			-- Give a random chair to the player
			local ChairChances = {
				{ "Common", 65 },
				{ "Uncommon", 20 },
				{ "Rare", 10 },
				{ "Legendary", 3 },
				{ "Limited", 2 },
			}
			local ChairSkinManager = require(ServerScriptService.Server.Managers.ChairSkinManager)

			--
			local randomRarity = RandomUtil.GetResultFromWeight(ChairChances)
			ChairSkinManager:GiveRandomRarityChair(player, randomRarity)

			--
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You have received <font color="#2de200">500 Bux</font> from the Starter Pack!`,
				5,
			})

			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You have received an <font color="#ffd400">Exclusive Chair</font> from the Starter Pack!`,
				5,
			})
		end,
	},

	{
		Id = "AnotherChance",
		Name = "Another Chance",
		Type = "Core",
		ProductId = 3539938456,
	},

	{
		Id = "FirstAnotherChanceOfTheDay",
		Name = "First Another Chance Of The Day",
		Type = "Core",
		ProductId = 3539938631,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			PlayerDataManager:SetPlayerDataKey(
				player,
				{ "FirstPurchaseOfTheDayTime", "AnotherChance" },
				os.time() + 24 * 60 * 60
			)
		end,
	},

	{
		Id = "RestoreStreak",
		Name = "Restore Streak",
		Type = "Core",
		ProductId = 3539938807,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			StreakManager:RestorePlayerStreak(player)
		end,
	},

	{
		Id = "FirstRestoreStreakOfTheDay",
		Name = "First Restore Streak Of The Day",
		Type = "Core",
		ProductId = 3539938631,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			StreakManager:RestorePlayerStreak(player)

			PlayerDataManager:SetPlayerDataKey(
				player,
				{ "FirstPurchaseOfTheDayTime", "RestoreStreak" },
				os.time() + 24 * 60 * 60
			)
		end,
	},

	-- Match Purchasables
	{
		Id = "SkipTurn",
		Name = "Skip Turn",
		Type = "Core",
		ProductId = 3536978316,
	},

	{
		Id = "HideOpponentCup",
		Name = "Hide Opponent Cup",
		Type = "Core",
		ProductId = 3536978817,
	},

	{
		Id = "EmptyCup",
		Name = "Empty Cup",
		Type = "Core",
		ProductId = 3536978482,
	},

	{
		Id = "ChristmasPack",
		Name = "Christmas Pack",
		Type = "Core",
		PurchaseOnce = true,
		ProductId = 3482718549,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			--
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You have received <font color="#ffd400">Candy Cane Chair</font>!`,
				5,
			})
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You have received <font color="#ffd400">Frosty Chair</font>!`,
				5,
			})
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You have received <font color="#ffd400">Ginger Bread Chair</font>!`,
				5,
			})
		end,
	},

	{
		Id = "AuraPack",
		Name = "Aura Pack",
		Type = "Core",
		PurchaseOnce = true,
		ProductId = 3482719864,
	},

	{
		Id = "NewYear2026Chair",
		Name = "New Year 2026 Chair",
		Type = "Core",
		PurchaseOnce = true,
		ProductId = 3495571115,
	},

	{
		Id = "Chair67Premium",
		Name = "Chair 67 Premium",
		Type = "Core",
		PurchaseOnce = true,
		ProductId = 3539950998,
	},

	{
		Id = "RainbowChair",
		Name = "Rainbow Chair",
		Type = "Core",
		PurchaseOnce = true,
		ProductId = 3539951106,
	},

	{
		Id = "SkipDay",
		Name = "Skip Day",
		Type = "Core",
		ProductId = 3498146122,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			DailyRewardManager:ClaimReward(player, true)
		end,
	},

	{
		Id = "ClaimAllDailyRewards",
		Name = "Claim All Daily Rewards",
		Type = "Core",
		ProductId = 3498146411,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			DailyRewardManager:CollectAllRewards(player)
		end,
	},

	------------ [[ BUX ]] -------------
	{
		Id = "BuxPack1",
		Name = "Bux Pack 1",
		Type = "Currency",
		ProductId = 3539950363,
		Value = 300,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 300)
			logCurrencySource(player, 300, "BuxPack1")
		end,
	},

	{
		Id = "BuxPack2",
		Name = "Bux Pack 2",
		Type = "Currency",
		ProductId = 3539950471,
		Value = 1000,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 1000)
			logCurrencySource(player, 1000, "BuxPack2")
		end,
	},

	{
		Id = "BuxPack3",
		Name = "Bux Pack 3",
		Type = "Currency",
		ProductId = 3539950538,
		Value = 4000,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 4000)
			logCurrencySource(player, 4000, "BuxPack3")
		end,
	},

	{
		Id = "BuxPack4",
		Name = "Bux Pack 4",
		Type = "Currency",
		ProductId = 3539950609,
		Value = 15000,
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 15000)
			logCurrencySource(player, 15000, "BuxPack4")
		end,
	},
}
table.freeze(Products.Data)

function Products.GetProductFromId(id: string): Product?
	for _, v in Products.Data do
		if v.Id == id then
			return v
		end
	end

	return nil
end

function Products.GetProductFromProductId(productId: number): Product?
	for _, v in Products.Data do
		if v.ProductId == productId then
			return v
		end
	end

	return nil
end

function Products.GetProductsByType(productType: "Core" | "Troll" | "Currency"): { Product }
	local products = {}
	for _, v in Products.Data do
		if v.Type == productType then
			table.insert(products, v)
		end
	end

	return products
end

function Products.GetProducts(): { Product }
	return Products.Data
end

return Products
