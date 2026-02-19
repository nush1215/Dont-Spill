return {
	PLAYER_SPOT_COLORS = {
		Player1 = Color3.fromRGB(0, 170, 255),
		Player2 = Color3.fromRGB(255, 0, 0),
		Tie = Color3.fromRGB(255, 255, 127),
	},

	TIMER_BAR_COLOR = {
		Color3.fromRGB(0, 255, 0),
		Color3.fromRGB(255, 255, 0),
		Color3.fromRGB(255, 0, 0),
	},

	RESULT_GLOW_COLORS = {
		Winner = Color3.fromRGB(255, 170, 0),
		Loser = Color3.fromRGB(255, 0, 0),
	},

	RESULT_RAYS_COLORS = {
		Winner = Color3.fromRGB(255, 255, 0),
		Loser = Color3.fromRGB(170, 0, 0),
	},

	RESULT_TEXT_COLORS = {
		Winner = Color3.fromRGB(255, 255, 0),
		Loser = Color3.fromRGB(255, 0, 0),
	},

	ANOTHER_CHANCE_COLORS = {
		Winner = {
			StrokeColor = Color3.fromRGB(10, 67, 9),
			VignetteColor = Color3.fromRGB(0, 255, 0),
		},

		Loser = {
			StrokeColor = Color3.fromRGB(59, 0, 0),
			VignetteColor = Color3.fromRGB(255, 0, 0),
		},
	},

	RARITY_COLORS = {
		Common = Color3.fromRGB(169, 169, 169), -- Dull gray for Common
		Uncommon = Color3.fromRGB(30, 215, 96), -- Bright green for Uncommon
		Rare = Color3.fromRGB(0, 112, 221), -- Deep blue for Rare
		Legendary = Color3.fromRGB(255, 191, 73), -- Vibrant gold for Legendary
		Limited = Color3.fromRGB(204, 50, 53), -- Deep red for Limited
	},

	RARITY_FRAME_COLORS = {
		Common = {
			BackgroundColor = Color3.fromRGB(21, 21, 21),
			StrokeColor = Color3.fromRGB(50, 50, 50),
			TextStrokeColor = Color3.fromRGB(30, 30, 30),
		},

		Uncommon = {
			BackgroundColor = Color3.fromRGB(0, 225, 0),
			StrokeColor = Color3.fromRGB(0, 85, 0),
			TextStrokeColor = Color3.fromRGB(0, 75, 0),
		},

		Rare = {
			BackgroundColor = Color3.fromRGB(0, 85, 255),
			StrokeColor = Color3.fromRGB(0, 0, 140),
			TextStrokeColor = Color3.fromRGB(0, 0, 100),
		},

		Legendary = {
			BackgroundColor = Color3.fromRGB(255, 170, 0),
			StrokeColor = Color3.fromRGB(157, 96, 12),
			TextStrokeColor = Color3.fromRGB(99, 50, 0),
		},

		Limited = {
			BackgroundColor = Color3.fromRGB(255, 85, 0),
			StrokeColor = Color3.fromRGB(139, 46, 0),
			TextStrokeColor = Color3.fromRGB(135, 45, 0),
		},

		Exclusive = {
			BackgroundColor = Color3.fromRGB(255, 255, 0),
			StrokeColor = Color3.fromRGB(200, 200, 0),
			TextStrokeColor = Color3.fromRGB(120, 110, 6),
		},
	},

	EQUIPPED_COLORS = {
		TextColor = Color3.fromRGB(0, 255, 0),
		TextStrokeColor = Color3.fromRGB(0, 85, 0),
	},

	--
	GAMEPASS_DISPLAYS = {
		x2Streak = {
			RayColor = Color3.fromRGB(255, 85, 0),
			GlowColor = Color3.fromRGB(255, 85, 0),
		},

		x2Win = {
			RayColor = Color3.fromRGB(255, 255, 0),
			GlowColor = Color3.fromRGB(255, 255, 0),
		},

		x2Bux = {
			RayColor = Color3.fromRGB(0, 170, 0),
			GlowColor = Color3.fromRGB(85, 255, 0),
		},

		VIP = {
			RayColor = Color3.fromRGB(255, 255, 127),
			GlowColor = Color3.fromRGB(255, 170, 0),
		},
	},
}
