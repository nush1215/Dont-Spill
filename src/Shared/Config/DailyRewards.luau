-- Services
local AnalyticsService = game:GetService("AnalyticsService")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

export type DailyReward = {
	Day: number,
	Type: "Currency" | "Skin",
	Id: string, -- Optional for stuff we want to have an id
	Title: string,
	Callback: (player: Player) -> (),
}

--
local CurrencyManager
local ChairSkinManager
local PlayerDataManager

if RunService:IsServer() then
	CurrencyManager = require(ServerScriptService.Server.Managers.CurrencyManager)
	ChairSkinManager = require(ServerScriptService.Server.Managers.ChairSkinManager)
	PlayerDataManager = require(ServerScriptService.Server.Managers.PlayerDataManager)
end

-- Helper for analytics
local function logCurrencySource(player: Player, amount: number, day: string)
	task.spawn(function()
		pcall(function()
			PlayerDataManager:GetPlayerDataKey(player, "Currency"):andThen(function(currency)
				AnalyticsService:LogEconomyEvent(
					player,
					Enum.AnalyticsEconomyFlowType.Source,
					"Bux",
					amount,
					currency,
					Enum.AnalyticsEconomyTransactionType.TimedReward.Name,
					day
				)
			end)
		end)
	end)
end

--
local DailyRewards = {}
DailyRewards.CLAIM_INTERVAL = 24 * 60 * 60 -- 24 hours in seconds

DailyRewards.Data = {
	{
		Day = 1,
		Title = "100 Bux",
		Type = "Currency",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 100)
			logCurrencySource(player, 100, "Day 1")
		end,
	},

	{
		Day = 2,
		Title = "Random Rare Skin",
		Id = "Skin",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			ChairSkinManager:GiveRandomRarityChair(player, "Rare")
		end,
	},

	{
		Day = 3,
		Title = "250 Bux",
		Type = "Currency",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 250)
			logCurrencySource(player, 250, "Day 3")
		end,
	},

	{
		Day = 4,
		Title = "500 Bux",
		Type = "Currency",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 500)
			logCurrencySource(player, 500, "Day 4")
		end,
	},

	{
		Day = 5,
		Title = "1,000 Bux",
		Type = "Currency",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 1000)
			logCurrencySource(player, 1000, "Day 5")
		end,
	},

	{
		Day = 6,
		Title = "1,500 Bux",
		Type = "Currency",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			CurrencyManager:IncrementCurrency(player, 1500)
			logCurrencySource(player, 1500, "Day 6")
		end,
	},

	{
		Day = 7,
		Title = "Random Limited Chair",
		Type = "Chair",
		Callback = function(player: Player)
			if RunService:IsClient() then
				return
			end

			ChairSkinManager:GiveRandomRarityChair(player, "Limited")
		end,
	},
}
table.freeze(DailyRewards.Data)

function DailyRewards.GetAllRewards(): { DailyReward }
	return DailyRewards.Data
end

function DailyRewards.GetRewardForDay(day: number): DailyReward?
	for _, rewardData in DailyRewards.Data do
		if rewardData.Day == day then
			return rewardData
		end
	end

	return nil
end

function DailyRewards.GetTotalRewards(): number
	return #DailyRewards.Data
end

return DailyRewards
