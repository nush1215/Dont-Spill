return {
	PlayerDataTemplate = {
		-- Game Statistics
		GamesPlayed = 0,
		Wins = 0,
		Defeats = 0,
		Currency = 0,

		-- Rewards
		ClaimedGroupReward = false,

		-- Core Shop Stuff
		StarterPackStart = 0,
		PurchasedOnceProducts = {},

		FirstPurchaseOfTheDayTime = {
			RestoreStreak = 0,
			AnotherChance = 0,
		},

		-- Chair Skin
		EquippedChairSkin = "",
		OwnedChairSkins = {},

		-- Streak
		Streak = 0,
		PreviousStreak = 0,
		StreakTagged = false,
		FromShutdown1 = false,

		-- Daily Rewards
		DailyRewardStreak = 0,
		LastDailyRewardClaim = 0,
	},

	ToLeaderstats = {
		Wins = "Wins",
		Streak = "Streak",
	},
}
