-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)

--
local BotClass

--
local BotsManager = {
	_bots = {
		--[botId: number] = BotClass
	},

	-- Two-phase signals to mirror real player "Start" / "End" button flow
	OnBotStartPour = Signal.new(), -- Fired when bot "presses" (after reaction delay)
	OnBotResponse = Signal.new(), -- Fired when bot "releases" (done pouring)
}

-- Generates a new bot
function BotsManager:GenerateBot()
	local bot = BotClass.new()
	self._bots[bot.UserId] = bot

	return bot
end

-- Destroys a bot
function BotsManager:DestroyBot(botId: number)
	local bot = self._bots[botId]
	if not bot then
		return
	end

	bot:Destroy()
	self._bots[botId] = nil
end

-- Checks if a bot exist
function BotsManager:IsBot(check: Player): boolean
	local userId = check.UserId
	return self._bots[userId]
end

-- Runs a function on the bot class
function BotsManager:RunBot(botId: number, functionName: string, ...)
	local bot = self._bots[botId]
	if not bot then
		return
	end

	bot[functionName](bot, ...)
end

function BotsManager:OnInit()
	BotClass = require(script.Bot)

	local botsFolder = Instance.new("Folder")
	botsFolder.Name = "Bots"
	botsFolder.Parent = workspace
end

return BotsManager
