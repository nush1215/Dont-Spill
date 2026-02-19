-- Services
local AnalyticsService = game:GetService("AnalyticsService")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local ZonePlus = require(Packages.ZonePlus)

-- Shared
local Shared = ReplicatedStorage.Shared
local RandomUtil = require(Shared.RandomUtil)
local GameColors = require(Shared.GameColors)

-- Server Configs
local Configs = script.Parent.Parent.Config
local GameConfigs = require(Configs.GameConfigs)
local Trove = require(Packages.Trove)

--
local GameStationClass = require(script.GameStation)

--
local AbilitiesManager
local ShopManager
local StreakManager
local CurrencyManager
local PlayerDataManager
local EffectsManager
local NotificationManager
local ChairSkinManager
local BotsManager

--
local GameStationManager = {
	--
	Stations = {},
	SlowDownTimer = {},

	---------------- EVENTS ----------------

	--
	StartBotMatchEvent = BridgeNet2.ReferenceBridge("StartBotMatch"),
	RunTrollEvent = BridgeNet2.ReferenceBridge("RunTroll"),
	RequestLeaveGameStationEvent = BridgeNet2.ReferenceBridge("RequestLeaveGameStation"),
	AnnounceGameWinnerEvent = BridgeNet2.ReferenceBridge("AnnounceGameWinner"),

	-- Another Chance Events
	PromptPlayerAnotherChanceEvent = BridgeNet2.ReferenceBridge("PromptPlayerAnotherChance"),
	AnotherChanceEvent = BridgeNet2.ReferenceBridge("AnotherChance"),
	DenyAnotherChanceEvent = BridgeNet2.ReferenceBridge("DenyAnotherChance"),

	-- Game Logic Events
	PlayerJoinedStationEvent = BridgeNet2.ReferenceBridge("PlayerJoinedStation"),
	PlayerLeftStationEvent = BridgeNet2.ReferenceBridge("PlayerLeftStation"),

	GameStartedEvent = BridgeNet2.ReferenceBridge("GameStarted"),
	GameStoppedEvent = BridgeNet2.ReferenceBridge("GameStopped"),

	PlayerAttemptEvent = BridgeNet2.ReferenceBridge("PlayerAttempt"),

	PlayerResponseEvent = BridgeNet2.ReferenceBridge("PlayerResponse"),
	AnnounceRoundWinnerEvent = BridgeNet2.ReferenceBridge("AnnounceRoundWinner"),
}

-- Starts the full game loop and ends it too
function GameStationManager:StartGame(station: Model)
	--
	local stationClass = self.Stations[station]
	if not stationClass then
		warn("No station class found for station:", station.Name)
		return
	end

	--
	local gameCleaner = Trove.new()

	-- Get the players
	local player1 = stationClass:GetPlayerInSlot("Player1")
	local player2 = stationClass:GetPlayerInSlot("Player2")

	--
	local water = station.Cup.Water
	local faucet = station.Faucet

	-- Prepare the payload for the players (for events)
	local players = {}
	if not BotsManager:IsBot(player1) then
		table.insert(players, player1)
	end

	if not BotsManager:IsBot(player2) then
		table.insert(players, player2)
	end

	--
	local gameDone = false
	local forceStopped = false

	-- Random water pressure for this match (same for both players this game)
	local waterPerSec =
		RandomUtil.GetRandomFromMinMax(GameConfigs.WATER_PER_SEC_RANGE.Min, GameConfigs.WATER_PER_SEC_RANGE.Max)

	-- Random water threshold for this match (how much water fills the cup before overflow)
	local waterThreshold =
		RandomUtil.GetRandomIntFromMinMax(GameConfigs.WATER_THRESHOLD_RANGE.Min, GameConfigs.WATER_THRESHOLD_RANGE.Max)
	stationClass:SetWaterThreshold(waterThreshold)

	-- Add to their stats
	if not BotsManager:IsBot(player1) then
		PlayerDataManager:IncrementDataKey(player1, "GamesPlayed", 1)
	end

	if not BotsManager:IsBot(player2) then
		PlayerDataManager:IncrementDataKey(player2, "GamesPlayed", 1)
	end

	-- Record Match for Analytics
	task.spawn(function()
		local nonBot = if not BotsManager:IsBot(player1) then player1 else player2
		pcall(function()
			AnalyticsService:LogCustomEvent(nonBot, "Match", 1, {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = station:GetAttribute("IsHardMode") and "HardMode"
					or "NormalMode",
			})
		end)
	end)

	-- Cache player wins for difficulty calculation
	local player1Wins = 0
	local player2Wins = 0

	-- Get wins for real players
	if not BotsManager:IsBot(player1) then
		PlayerDataManager:GetPlayerDataKey(player1, "Wins")
			:andThen(function(wins: number?)
				player1Wins = wins or 0
				-- If player2 is a bot, use player1's wins for the bot
				if BotsManager:IsBot(player2) then
					player2Wins = player1Wins
				end
			end)
			:catch(function(err)
				-- If promise rejects, default to 0 wins (Easy difficulty)
				warn(`Failed to get wins for {player1.Name}:`, err)
				player1Wins = 0
			end)
	end

	if not BotsManager:IsBot(player2) then
		PlayerDataManager:GetPlayerDataKey(player2, "Wins")
			:andThen(function(wins: number?)
				player2Wins = wins or 0
				-- If player1 is a bot, use player2's wins for the bot
				if BotsManager:IsBot(player1) then
					player1Wins = player2Wins
				end
			end)
			:catch(function(err)
				-- If promise rejects, default to 0 wins (Easy difficulty)
				warn(`Failed to get wins for {player2.Name}:`, err)
				player2Wins = 0
			end)
	end

	--
	gameCleaner:Add(stationClass.GameStopped:Once(function()
		if stationClass:GetWaterLevel() >= stationClass:GetWaterThreshold() then
			gameDone = true
		else
			NotificationManager.NotifyNormalEvent:Fire(BridgeNet2.Players(players), {
				"Your opponent left the game, No winner has been declared!",
			})

			forceStopped = true
		end

		self.GameStoppedEvent:Fire(BridgeNet2.Players(players), station)
	end))

	-- Setup the text stuff
	local tableUI = station:FindFirstChild("TableUI", true)
	tableUI.InGame.PlayersVs.Visible = true
	tableUI.InGame.PlayersVs.Text =
		`<font color="#{GameColors.PLAYER_SPOT_COLORS.Player1:ToHex()}">{player1.Name}</font> <font color="#ffaa00">VS</font> <font color="#{GameColors.PLAYER_SPOT_COLORS.Player2:ToHex()}">{player2.Name}</font>`

	--
	self.GameStartedEvent:Fire(BridgeNet2.Players(players), { station, { player1, player2 } })

	-- did this so that we can stop it anytime before the game logic starts
	local count = 0
	repeat
		count += task.wait()
	until count >= 2.5 or forceStopped

	------------------------------ THE WHOLE GAME LOGIC GOES HERE ---------------------------

	--
	local response = {}
	local anotherChancePurchased
	local hideCupNextTurn = false
	local turnFinished
	local currentTurn
	-- When it's a bot's turn, start time of their "hold" (for water calculation when they respond)
	local currentBotAttemptStartTime = nil

	local function resetVisuals() -- resets any troll effects and stuff
		station.Cover.Transparency = 1
	end

	-- Listens and stores the player responses (button click) for each round
	local function updateWater()
		-- Set the actual water level (height in studs from current level and max height)
		local fraction = stationClass:GetWaterLevel() / stationClass:GetWaterThreshold()
		local height = fraction * GameConfigs.WATER_MODEL_FULL_HEIGHT

		local originalCFrame = water:GetAttribute("OriginalCFrame")
		if not originalCFrame then
			originalCFrame = water.CFrame
			water:SetAttribute("OriginalCFrame", originalCFrame)
		end

		water.Size = Vector3.new(height, water.Size.Y, water.Size.Z)
		water.CFrame = originalCFrame * CFrame.new(height / 2, 0, 0)
	end

	local function startWaterIncreaseVisual(timeSent: number)
		-- Setup for water visual (use client time so visual matches server water amount)
		water:SetAttribute("StartTime", timeSent)
		water:SetAttribute("CurrentLevel", stationClass:GetWaterLevel())
		water:SetAttribute("WaterPerSec", waterPerSec)
		water:SetAttribute("WaterThreshold", waterThreshold)
		water:SetAttribute("MaxHeight", GameConfigs.WATER_MODEL_FULL_HEIGHT)

		--
		water:AddTag("AddingWater") -- keep adding water visual
		faucet:AddTag("EnabledFaucet") -- keep faucet visual
	end

	local function stopWaterIncreaseVisual()
		faucet:RemoveTag("EnabledFaucet")
		water:RemoveTag("AddingWater")
		water:SetAttribute("StartTime", nil)
	end

	-- Reset water part to 0 and disable all water effects (call when game ends)
	local function resetWaterAndEffects()
		stopWaterIncreaseVisual()
		stationClass:SetWaterLevel(0)
		updateWater()

		task.delay(0.1, function()
			station.Cup.Water.Transparency = 1
			for _, v in station.WaterSpill:GetDescendants() do
				if v:IsA("BasePart") then
					TweenService:Create(v, TweenInfo.new(0.5), { Transparency = 1 }):Play()
				end
			end
		end)
	end

	local function addWaterFromPlayerResponse(player: Player, timeSent: number)
		local currentTime = timeSent
		local startTime = response[player] and response[player].StartTime
			or workspace:GetServerTimeNow() - RandomUtil.GetRandomFromMinMax(0.1, 1)

		local diff = currentTime - startTime
		local waterAdded = diff * waterPerSec

		response[player] = nil

		stationClass:AddWater(waterAdded, player)
		updateWater()
	end

	-- Listen for purchases / trolls
	gameCleaner:Add(ShopManager.PlayerPurchased:Connect(function(player: Player, purchasedItem: string)
		-- Check if the purchaser is from this match
		if player.Name ~= player1.Name and player.Name ~= player2.Name then
			return
		end

		local opponent = player.Name == player1.Name and player2 or player1

		if purchasedItem == "AnotherChance" or purchasedItem == "FirstAnotherChanceOfTheDay" then
			anotherChancePurchased = true
		elseif purchasedItem == "SkipTurn" and currentTurn == player then
			turnFinished = player

			NotificationManager.NotifyChatEvent:Fire(BridgeNet2.Players(players), {
				`<font color="#ffaa00">{player.Name}</font> skipped their turn!`,
			})
		elseif purchasedItem == "HideOpponentCup" then
			hideCupNextTurn = true
		elseif purchasedItem == "EmptyCup" then
			stationClass:AddWater(-stationClass:GetWaterLevel(), opponent)
			updateWater()

			NotificationManager.NotifyChatEvent:Fire(BridgeNet2.Players(players), {
				`<font color="#ffaa00">{player.Name}</font> emptied the cup!`,
			})
		end
	end))

	local turnCleaner = gameCleaner:Extend()
	gameCleaner:Add(self.PlayerResponseEvent:Connect(function(player, data: { any })
		if not (currentTurn == player) then
			return
		end

		local responseType = data[1]
		local timeSent = data[2]

		if responseType == "Start" then
			response[player] = {
				StartTime = timeSent,
			}

			startWaterIncreaseVisual(timeSent)

			-- Get potential overflow wait time
			-- How much time left before it will overflow
			local waterLevel = stationClass:GetWaterLevel()
			local waterThreshold = stationClass:GetWaterThreshold()

			local waterToOverflow = waterThreshold - waterLevel
			local timeToOverflow = waterToOverflow / waterPerSec
			-- timeToOverflow is the number of seconds left if the player holds down before overflow will occur

			turnCleaner:Add(task.delay(timeToOverflow, function()
				addWaterFromPlayerResponse(player, workspace:GetServerTimeNow())
				stopWaterIncreaseVisual()
				turnFinished = player
			end))
		else
			stopWaterIncreaseVisual()
			turnCleaner:Clean()
			turnFinished = player

			if stationClass:GetWaterLevel() < stationClass:GetWaterThreshold() then
				addWaterFromPlayerResponse(player, timeSent)
			end

			response[player] = nil
		end
	end))

	gameCleaner:Add(self.DenyAnotherChanceEvent:Connect(function(player: Player)
		-- Check if the purchaser is from this match
		if player.Name ~= player1.Name and player.Name ~= player2.Name then
			return
		end

		anotherChancePurchased = false
		gameDone = true
	end))

	-- Bot integration (mirrors real player "Start" / "End" button flow):
	-- Phase 1: bot "presses" after reaction delay → start water visual (like PlayerResponseEvent "Start")
	gameCleaner:Add(BotsManager.OnBotStartPour:Connect(function(bot, pressTime: number)
		if bot.Name ~= player1.Name and bot.Name ~= player2.Name then
			return
		end
		if currentTurn ~= bot then
			return
		end
		-- Record when the bot started holding (for water calculation on release)
		currentBotAttemptStartTime = pressTime
		response[bot] = { StartTime = pressTime }
		startWaterIncreaseVisual(pressTime)

		-- Safety: if the bot holds past overflow, force-stop like a real player
		local botWaterLevel = stationClass:GetWaterLevel()
		local botWaterThreshold = stationClass:GetWaterThreshold()
		local botWaterToOverflow = botWaterThreshold - botWaterLevel
		local botTimeToOverflow = waterPerSec > 0 and (botWaterToOverflow / waterPerSec) or math.huge

		turnCleaner:Add(task.delay(botTimeToOverflow, function()
			if currentTurn == bot and response[bot] then
				addWaterFromPlayerResponse(bot, workspace:GetServerTimeNow())
				stopWaterIncreaseVisual()
				turnFinished = bot
				currentBotAttemptStartTime = nil
			end
		end))
	end))

	-- Phase 2: bot "releases" → stop water visual and add water (like PlayerResponseEvent "End")
	gameCleaner:Add(BotsManager.OnBotResponse:Connect(function(bot, releaseTime: number)
		if bot.Name ~= player1.Name and bot.Name ~= player2.Name then
			return
		end
		if currentTurn ~= bot then
			return
		end
		-- Only process if the bot was actually pouring (has a start time)
		if not currentBotAttemptStartTime then
			return
		end
		stopWaterIncreaseVisual()
		turnCleaner:Clean()

		if stationClass:GetWaterLevel() < stationClass:GetWaterThreshold() then
			addWaterFromPlayerResponse(bot, releaseTime)
		end

		response[bot] = nil
		turnFinished = bot
		currentBotAttemptStartTime = nil
	end))

	gameCleaner:Add(stationClass.OnThresholdHit:Connect(function()
		local drip = station.WaterSpill.Drip
		local puddle = station.WaterSpill.Puddle

		for _, v in drip:GetChildren() do
			TweenService:Create(v, TweenInfo.new(0.3), { Transparency = 0 }):Play()
		end

		task.delay(1, function()
			for _, v in puddle:GetChildren() do
				TweenService:Create(v, TweenInfo.new(1.25), { Transparency = 0 }):Play()
			end
		end)

		local loser = stationClass:GetLastWaterAdder()

		-- If the loser is a bot, skip the another chance prompt entirely
		if BotsManager:IsBot(loser) then
			gameDone = true
			return
		end

		local anotherChanceOfferExpiryTime = workspace:GetServerTimeNow() + 15.5 -- add .5 for latency compensation

		self.PromptPlayerAnotherChanceEvent:Fire(BridgeNet2.Players(players), { anotherChanceOfferExpiryTime, loser })

		repeat
			task.wait()
		until workspace:GetServerTimeNow() >= anotherChanceOfferExpiryTime or anotherChancePurchased ~= nil

		if not anotherChancePurchased then
			gameDone = true
		end
	end))

	-- Starts a player's attempt
	local function doPlayerAttempt(player: Player)
		-- Apply the trolls here
		local opponent = player.Name == player1.Name and player2 or player1

		if hideCupNextTurn then
			hideCupNextTurn = false
			station.Cover.Transparency = 0
			NotificationManager.NotifyChatEvent:Fire(BridgeNet2.Players(players), {
				`<font color="#ffaa00">{opponent.Name} has hidden the cup! `,
			})
		end

		-- Start the new turn
		local attemptTime = workspace:GetServerTimeNow() + GameConfigs.PLAYER_ATTEMPT_TIME + 1 -- 1 is for the "Your Turn" text and .5 for the latency compensation
		currentTurn = player
		self.PlayerAttemptEvent:Fire(
			BridgeNet2.Players(players),
			{ player, attemptTime, GameConfigs.PLAYER_ATTEMPT_TIME }
		)

		-- If this turn is a bot, request its two-phase response (reaction delay → pour → release)
		-- Water visual will start when OnBotStartPour fires (not immediately)
		local bot = BotsManager:IsBot(player)
		if bot then
			local turnStartTime = workspace:GetServerTimeNow()
			local isHardMode = station:GetAttribute("IsHardMode") == true
			local currentWaterLevel = stationClass:GetWaterLevel()
			local currentWaterThreshold = stationClass:GetWaterThreshold()
			BotsManager:RunBot(
				player.UserId,
				"RequestResponse",
				turnStartTime,
				attemptTime,
				currentWaterLevel,
				currentWaterThreshold,
				waterPerSec,
				isHardMode
			)
		end

		repeat
			task.wait()
		until workspace:GetServerTimeNow() >= attemptTime or gameDone or forceStopped or turnFinished == currentTurn

		-- If the player held the button we calculate and add the water from their response
		if response[player] then
			addWaterFromPlayerResponse(player, workspace:GetServerTimeNow())
		elseif turnFinished == nil then
			-- Player did not make their turn (timed out / no input) — add random penalty water
			local penalty = RandomUtil.GetRandomIntFromMinMax(
				GameConfigs.TURN_TIMEOUT_WATER_PENALTY.Min,
				GameConfigs.TURN_TIMEOUT_WATER_PENALTY.Max
			)
			stationClass:AddWater(penalty, player)
			updateWater()
		end

		-- Stop the water increase visual, pretty sure this will be stopped already but eh
		stopWaterIncreaseVisual()
		currentBotAttemptStartTime = nil
		turnFinished = nil

		-- if the water level is greater than the threshold then we need to wait for the another chance to be purchased
		if stationClass:GetWaterLevel() >= stationClass:GetWaterThreshold() then
			repeat
				task.wait()
			until gameDone or forceStopped or anotherChancePurchased ~= nil

			if anotherChancePurchased then
				self.AnotherChanceEvent:Fire(BridgeNet2.Players(players), stationClass:GetLastWaterAddedBySlot())

				-- Deduct the water
				local randomDeduction = math.random(5, 15)
				stationClass:AddWater(-randomDeduction, stationClass:GetLastWaterAddedBySlot())
				updateWater()

				-- Clear the water spill and reset stuff
				for _, v in station.WaterSpill:GetDescendants() do
					if v:IsA("BasePart") then
						TweenService:Create(v, TweenInfo.new(0.5), { Transparency = 1 }):Play()
					end
				end

				task.wait(2.5)
			end

			anotherChancePurchased = nil
		end
	end

	gameCleaner:Add(task.spawn(function()
		while true do
			if gameDone or forceStopped then
				break
			end

			---------------- DO SOME CLEANUPS ----------------
			table.clear(response)
			anotherChancePurchased = nil
			turnFinished = nil
			currentBotAttemptStartTime = nil

			--  Runs the turn for the player
			local function doAttemptForPlayer(player: Player)
				if gameDone or forceStopped then
					return
				end

				resetVisuals() -- reset any troll effects
				doPlayerAttempt(player) -- do the player's turn
				resetVisuals()
			end

			-- Do the player's turn
			doAttemptForPlayer(player1)
			task.wait(0.1)
			doAttemptForPlayer(player2)
			task.wait(0.1)
		end
	end))

	-- Wait till the game is done
	repeat
		task.wait()
	until gameDone or forceStopped

	--
	resetVisuals()
	resetWaterAndEffects()

	--
	if forceStopped then
		stationClass:StopGame()
		gameCleaner:Destroy()
		return
	end

	--------- Get winner and loser -----------
	local loser = stationClass:GetLastWaterAdder()
	local winner = stationClass:GetOtherPlayer(loser)

	-- Reward the loser
	if loser and not BotsManager:IsBot(loser) and loser.Character then
		pcall(function()
			local loserReward =
				RandomUtil.GetRandomIntFromMinMax(GameConfigs.LOSE_REWARD.Min, GameConfigs.LOSE_REWARD.Max)

			--
			CurrencyManager:IncrementCurrency(loser, loserReward)
			PlayerDataManager:IncrementDataKey(loser, "Defeats", 1)
			StreakManager:RemoveStreak(loser, true)

			-- Analytics
			task.spawn(function()
				pcall(function()
					PlayerDataManager:GetPlayerDataKey(loser, "Currency"):andThen(function(currency)
						AnalyticsService:LogEconomyEvent(
							loser,
							Enum.AnalyticsEconomyFlowType.Source,
							"Bux",
							loserReward,
							currency,
							Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
							"LoseReward"
						)
					end)
				end)
			end)
		end)
	end

	-- Reward the winner
	if winner and not BotsManager:IsBot(winner) and winner.Character then
		pcall(function()
			local winnerReward =
				RandomUtil.GetRandomIntFromMinMax(GameConfigs.CURRENCY_REWARD.Min, GameConfigs.CURRENCY_REWARD.Max)

			if station:GetAttribute("IsHardMode") then
				winnerReward = winnerReward * 2
			end

			local winsAmount = winner:HasTag("x2Win") and 2 or 1

			--
			CurrencyManager:IncrementCurrency(winner, winnerReward)
			StreakManager:AddStreak(winner)
			PlayerDataManager:IncrementDataKey(winner, "Wins", winsAmount)

			-- Analytics
			task.spawn(function()
				pcall(function()
					PlayerDataManager:GetPlayerDataKey(winner, "Currency"):andThen(function(currency)
						AnalyticsService:LogEconomyEvent(
							winner,
							Enum.AnalyticsEconomyFlowType.Source,
							"Bux",
							winnerReward,
							currency,
							Enum.AnalyticsEconomyTransactionType.Gameplay.Name,
							"WinReward"
						)
					end)
				end)
			end)
		end)
	end

	self.AnnounceGameWinnerEvent:Fire(BridgeNet2.Players(players), { winner })

	--
	task.wait(1)

	-- Cleanup
	stationClass:StopGame()
	gameCleaner:Destroy()
	resetWaterAndEffects()
end

-- Starts a bot match
function GameStationManager:StartBotMatch(player: Player)
	-- Get the station
	local stationClass = self:GetPlayerGameStation(player)
	if not stationClass then
		return
	end

	-- Check if there's a free slot
	local freeSlot = stationClass:GetFreeSlot()
	if not freeSlot then
		return
	end

	--
	local bot = BotsManager:GenerateBot()
	bot:SpawnBot(stationClass.Station.Chairs[freeSlot].Seat.Position + Vector3.new(3, 0, 0))
	stationClass:AddPlayer(bot, freeSlot)
end

-- Force remove a player from a station
function GameStationManager:RemovePlayer(player: Player)
	--
	local stationClass = self:GetPlayerGameStation(player)
	if not stationClass then
		return
	end

	--
	stationClass:RemovePlayer(player)
end

-- Gets the game station for a player
function GameStationManager:GetPlayerGameStation(player: Player)
	for _, stationClass in self.Stations do
		local players = stationClass:GetPlayers()
		for _, v in players do
			if v == player then
				return stationClass
			end
		end
	end
end

-- Setups the game station
function GameStationManager:_setupStation(station: Model)
	--
	local tableModel = station.Table
	local tableUI = tableModel.Attachment.TableUI

	--
	local stationClass = GameStationClass.new(station, GameConfigs.COUNTDOWN_TIME, GameConfigs.WATER_THRESHOLD)
	self.Stations[station] = stationClass

	--
	local function updatePlayersInGameText()
		local playersInStation = #stationClass:GetPlayers()
		tableUI.PreGame.PlayersAmount.Visible = true
		tableUI.PreGame.PlayersAmount.Text = `{playersInStation}/2`
	end

	-- Checks if a player is eligible to play in the station
	local function checkIfPlayerIsEligible(player: Player): boolean
		if station:GetAttribute("IsHardMode") then
			local hasData, playerWins = PlayerDataManager:GetPlayerDataKey(player, "Wins"):await()
			if not hasData then
				return false
			end

			return playerWins >= 10
		end

		return true
	end

	--
	stationClass.OnCountdown:Connect(function(currentTime)
		tableUI.PreGame.Countdown.Visible = true
		tableUI.PreGame.Countdown.Text = `GAME STARTS IN {currentTime}`
	end)

	--
	stationClass.OnPlayerJoined:Connect(function(player: Player, playerSlot: string)
		local isEligible = checkIfPlayerIsEligible(player)
		if not isEligible and not BotsManager:IsBot(player) then
			task.delay(0.5, function()
				stationClass:RemovePlayer(player)
			end)

			NotificationManager.NotifyNormalEvent:Fire(player, {
				`You need to <font color='#ffd400'>win 10 games</font> to play in <font color='#ff0000'>hard mode</font>!`,
				3,
				"Reject",
			})

			task.delay(3, function()
				stationClass:RemovePlayer(player)
			end)

			return
		end

		updatePlayersInGameText()
		tableUI.PreGame.Visible = true

		-- Set chair skin if there is one
		if BotsManager:IsBot(player) then
			return
		end

		player:AddTag("InGame")

		self.PlayerJoinedStationEvent:Fire(player, station)

		PlayerDataManager:GetPlayerDataKey(player, "EquippedChairSkin"):andThen(function(equippedSkin: string)
			if equippedSkin == "" then
				return
			end

			ChairSkinManager:SetChairSkin(equippedSkin, station, playerSlot)
		end)
	end)

	stationClass.OnPlayerLeft:Connect(function(player: Player, playerSlot: string)
		updatePlayersInGameText()
		tableUI.PreGame.Countdown.Visible = false

		if not BotsManager:IsBot(player) then
			self.PlayerLeftStationEvent:Fire(player, station)
			player:RemoveTag("InGame")
		end

		if stationClass.IsGameStarted and not BotsManager:IsBot(player) then
			StreakManager:TagPlayer(player)
		end

		ChairSkinManager:RemoveChairSkin(station, playerSlot)

		-- Check if the removed player is a bot so we can clean it up
		local isBot = BotsManager:IsBot(player)
		if isBot then
			BotsManager:DestroyBot(player.UserId)
		end

		-- Remove the bot in the station if it exists, this is for the case when the real player leaves the station
		local players = stationClass:GetPlayers()
		local bot = players[1]

		if bot and BotsManager:IsBot(bot) then
			stationClass:RemovePlayer(bot)
		end
	end)

	local zone
	stationClass.GameStarted:Connect(function()
		--
		tableUI.PreGame.Visible = false
		tableUI.InGame.Visible = true

		-- Setup borders
		for _, v in station.Borders:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = true
			end
		end

		-- Setup the zone so that any players that managed to glitch inside are removed
		zone = ZonePlus.new(station.EnterHitbox)
		for _, v in zone:getPlayers() do
			if stationClass:GetPlayerSlot(v) then
				continue
			end

			v.Character:PivotTo(station.EnteredExit:GetPivot())
		end

		zone.playerEntered:Connect(function(player: Player)
			if stationClass:GetPlayerSlot(player) then
				return
			end

			player.Character:PivotTo(station.EnteredExit:GetPivot())
		end)

		--
		self:StartGame(station)
	end)

	stationClass.GameStopped:Connect(function()
		tableUI.InGame.Visible = false
		tableUI.PreGame.Visible = true

		-- disable barriers, destroy zone
		for _, v in station.Borders:GetChildren() do
			if v:IsA("BasePart") then
				v.CanCollide = false
			end
		end

		if zone then
			zone:destroy()
		end
	end)
end

--
function GameStationManager:OnInit()
	--
	ShopManager = require(script.Parent.ShopManager)
	PlayerDataManager = require(script.Parent.PlayerDataManager)
	NotificationManager = require(script.Parent.NotificationManager)
	CurrencyManager = require(script.Parent.CurrencyManager)
	EffectsManager = require(script.Parent.EffectsManager)
	StreakManager = require(script.Parent.StreakManager)
	ChairSkinManager = require(script.Parent.ChairSkinManager)
	BotsManager = require(script.Parent.BotsManager)
	--
	for _, station in CollectionService:GetTagged("GameStation") do
		self:_setupStation(station)
	end
end

function GameStationManager:OnStart()
	self.RequestLeaveGameStationEvent:Connect(function(player: Player)
		self:RemovePlayer(player)
	end)

	self.StartBotMatchEvent:Connect(function(player: Player)
		self:StartBotMatch(player)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self.SlowDownTimer[player] = nil
	end)
end

return GameStationManager
