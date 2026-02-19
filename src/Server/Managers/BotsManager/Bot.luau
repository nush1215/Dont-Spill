-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

-- Assets
local Assets = ReplicatedStorage.Assets
local Bots = Assets.Bots

-- Server Configs
local Configs = script.Parent.Parent.Parent.Config
local GameConfigs = require(Configs.GameConfigs)

--
local BotsManager = require(script.Parent)
local BotNames = require(script.Parent.BotNames)

--
local Bot = {}
Bot.__index = Bot

function Bot.new()
	--
	local randomBot = Bots:GetChildren()[math.random(1, #Bots:GetChildren())]
	local name = randomBot:GetAttribute("Name") or BotNames[math.random(1, #BotNames)]
	local userId = randomBot:GetAttribute("UserId") or math.random(1, 1000000000)

	--
	local self = setmetatable({
		Name = name,
		UserId = userId,
		Character = randomBot:Clone(),

		_cleaner = Trove.new(),
	}, Bot)

	self:_init()
	return self
end

-- Initializes the bot
function Bot:_init()
	--
	local character = self.Character

	--
	character.PrimaryPart.Anchored = true
	character:PivotTo(CFrame.new(0, 999, 0)) -- Hide the bot
	character.Parent = workspace.Bots
end

-- Spawns the bot in the game
function Bot:SpawnBot(location: Vector3)
	--
	local character = self.Character

	--
	character:PivotTo(CFrame.new(location))
	character.PrimaryPart.Anchored = false

	--
	character:SetAttribute("IsBot", true)
	character:SetAttribute("BotId", self.UserId)
end

-- Simulates a human-like turn: reaction delay, hold (adapts to cup space), then release.
function Bot:RequestResponse(attemptStartTime, attemptEndTime, waterLevel, waterThreshold, waterPerSec, isHardMode)
	-- 1. Reaction delay: random pause before the bot "presses"
	local reactionRange
	if isHardMode then
		reactionRange = GameConfigs.BOT_REAL_HARD_MODE_REACTION_TIME
	else
		reactionRange = GameConfigs.BOT_REACTION_TIME
	end
	local reactionDelay = reactionRange.Min + math.random() * (reactionRange.Max - reactionRange.Min)
	local pressTime = attemptStartTime + reactionDelay

	-- 2. Calculate how long the bot should hold (adapts to cup space)
	local waterToOverflow = math.max(0, waterThreshold - waterLevel)
	local timeToOverflow = (waterPerSec > 0) and (waterToOverflow / waterPerSec) or math.huge

	local safetyMargin
	if isHardMode then
		safetyMargin = GameConfigs.BOT_REAL_HARD_MODE_SAFETY_MARGIN
	else
		safetyMargin = GameConfigs.BOT_SAFETY_MARGIN
	end

	-- Target hold = time until overflow minus safety margin, capped by remaining turn time
	local maxHoldTime = math.max(0, attemptEndTime - pressTime)
	local targetHoldDuration = math.clamp(timeToOverflow - safetyMargin, 0, maxHoldTime)

	-- 3. Human-like jitter on the release
	local accRange
	local accMin
	if isHardMode then
		accRange = GameConfigs.BOT_REAL_HARD_MODE_ACCURACY.Max - GameConfigs.BOT_REAL_HARD_MODE_ACCURACY.Min
		accMin = GameConfigs.BOT_REAL_HARD_MODE_ACCURACY.Min
	else
		accRange = GameConfigs.BOT_ACCURACY.Max - GameConfigs.BOT_ACCURACY.Min
		accMin = GameConfigs.BOT_ACCURACY.Min
	end
	local accuracy = accMin + math.random() * accRange
	local jitter = (math.random() - 0.5) * 2 * accuracy
	local holdDuration = math.clamp(targetHoldDuration + jitter, 0, maxHoldTime)

	local releaseTime = pressTime + holdDuration

	-- Schedule the two-phase flow
	self._cleaner:Add(task.spawn(function()
		-- Wait for reaction delay
		local waitToPress = pressTime - workspace:GetServerTimeNow()
		if waitToPress > 0 then
			task.wait(waitToPress)
		end

		-- Phase 1: bot "presses" (start pouring)
		BotsManager.OnBotStartPour:Fire(self, workspace:GetServerTimeNow())

		-- Wait for hold duration
		local waitToRelease = releaseTime - workspace:GetServerTimeNow()
		if waitToRelease > 0 then
			task.wait(waitToRelease)
		end

		-- Phase 2: bot "releases" (stop pouring)
		BotsManager.OnBotResponse:Fire(self, workspace:GetServerTimeNow())
	end))
end

--
function Bot:Destroy()
	self.Character:Destroy()
	self._cleaner:Destroy()
	self = nil
end

return Bot
