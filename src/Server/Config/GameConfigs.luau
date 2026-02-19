return {
	COUNTDOWN_TIME = 5,
	PLAYER_ATTEMPT_TIME = 13,

	-- Don't Spill: game ends when water reaches this (e.g. 100 = full cup)
	WATER_THRESHOLD = 100, -- base/fallback; each match uses random from range below
	WATER_THRESHOLD_RANGE = NumberRange.new(100, 120), -- random threshold per match (100 = base, higher = longer game; never goes below 100 to preserve visual)
	WATER_PER_SEC = 10, -- base/fallback; each match uses random from range below
	WATER_PER_SEC_RANGE = NumberRange.new(5, 7), -- random pressure per match (lower = slower fill, higher = faster)
	WATER_MODEL_FULL_HEIGHT = 1.3,

	-- Water added when a player doesn't take their turn (times out / no input); random per timeout
	TURN_TIMEOUT_WATER_PENALTY = NumberRange.new(18, 28),

	TIME_TO_SET = {
		Easy = NumberRange.new(6, 8),
		Medium = NumberRange.new(4, 6),
		Hard = NumberRange.new(3, 5),
		Extreme = NumberRange.new(1, 3),
		RealHardMode = NumberRange.new(0.2, 1),
	},

	DIFFIICULTY_SETS = {
		Easy = 0,
		Medium = 3,
		Hard = 6,
		Extreme = 15,
	},

	CURRENCY_REWARD = NumberRange.new(30, 50),
	LOSE_REWARD = NumberRange.new(3, 5),

	-- Bot reaction time (seconds) — delay before the bot "presses" to start pouring (simulates reading "YOUR TURN")
	BOT_REACTION_TIME = NumberRange.new(0.8, 2.5),
	BOT_REAL_HARD_MODE_REACTION_TIME = NumberRange.new(0.3, 1.0),
	-- Bot accuracy (seconds) — random jitter applied to the release time (simulates imprecise timing)
	BOT_ACCURACY = NumberRange.new(0.25, 0.85),
	BOT_REAL_HARD_MODE_ACCURACY = NumberRange.new(0.01, 0.15),
	-- Bot safety margin (seconds) — how far before overflow the bot aims to release (adapts to cup space)
	BOT_SAFETY_MARGIN = 0.8,
	BOT_REAL_HARD_MODE_SAFETY_MARGIN = 0.2,

	--
	SKIN_CHANGE_INTERVAL = 24 * 60 * 60, -- 24 hours between each skin change
	CHAIRS_AMOUNT_SALE = 6,

	--
	GIFT_CLAIM_FREQUENCY = 5 * 60,
	FREE_SPIN_INTERVAL = 24 * 60 * 60, -- 24 hours between each free spin
}
