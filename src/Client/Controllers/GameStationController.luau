-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Replica = require(Packages.Replica)
local Trove = require(Packages.Trove)
local Spr = require(Packages.Spr)

-- Shared
local Shared = ReplicatedStorage.Shared
local GuiUtil = require(Shared.GuiUtil)

-- Assets
local Assets = ReplicatedStorage.Assets
local UI = Assets.UI

--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Controls = require(LocalPlayer.PlayerScripts.PlayerModule):GetControls()

--
local Camera = workspace.CurrentCamera

--
local GameColors = require(Shared.GameColors)
local ANOTHER_CHANCE_COLORS = GameColors.ANOTHER_CHANCE_COLORS

--
local PlayerDataController
local NotificationController
local CameraController
local FriendController
local SoundController
local DecisionController
local ShopController
local HudController
local UIController

--
local GameStationController = {
	--
	RequestLeaveGameStationEvent = BridgeNet2.ReferenceBridge("RequestLeaveGameStation"),
	StartBotMatchEvent = BridgeNet2.ReferenceBridge("StartBotMatch"),

	--
	PromptPlayerAnotherChanceEvent = BridgeNet2.ReferenceBridge("PromptPlayerAnotherChance"),
	AnnounceGameWinnerEvent = BridgeNet2.ReferenceBridge("AnnounceGameWinner"),
	AnotherChanceEvent = BridgeNet2.ReferenceBridge("AnotherChance"),
	DenyAnotherChanceEvent = BridgeNet2.ReferenceBridge("DenyAnotherChance"),

	--
	PlayerJoinedStationEvent = BridgeNet2.ReferenceBridge("PlayerJoinedStation"),
	PlayerLeftStationEvent = BridgeNet2.ReferenceBridge("PlayerLeftStation"),

	GameStartedEvent = BridgeNet2.ReferenceBridge("GameStarted"),
	GameStoppedEvent = BridgeNet2.ReferenceBridge("GameStopped"),

	PlayerAttemptEvent = BridgeNet2.ReferenceBridge("PlayerAttempt"),
	PlayerResponseEvent = BridgeNet2.ReferenceBridge("PlayerResponse"),

	--
	_onJoinedCleaner = Trove.new(),
	_gameCleaner = Trove.new(),
	_purchasableCleaner = Trove.new(),

	--
	InGame = false,
	InStation = false,
}

-- Starts the game, handles everything related to the game
function GameStationController:_onGameStart(station: Model, players: { Player })
	--
	self.InGame = true
	self._onJoinedCleaner:Clean()

	-- UI
	local ui = self.UI
	local vsFrame = ui.VsFrame
	local statusFrame = ui.StatusFrame
	local barHolder = statusFrame.BarHolder
	local hitbox: TextButton = ui.Hitbox
	local gameResult = ui.GameResult

	-- Station folder
	local cameraViews = station.CameraViews

	--
	local player1 = players[1]
	local player2 = players[2]

	local ourPlayerSlot = player1.Name == LocalPlayer.Name and "Player1" or "Player2"
	local otherPlayerSlot = player1.Name == LocalPlayer.Name and "Player2" or "Player1"

	local ourButton = station.Buttons[ourPlayerSlot]
	local buttonPos = ourButton.Button.Position

	-- Pan Camera to the view
	if ourPlayerSlot == "Player1" then
		CameraController:SetCameraCFrameTo(
			cameraViews.Player1PlayView.CFrame,
			true,
			TweenInfo.new(2, Enum.EasingStyle.Quad)
		)

		self:_toggleSelfInvisible(true)
	else
		CameraController:SetCameraCFrameTo(
			cameraViews[otherPlayerSlot .. "SpectateView"].CFrame,
			true,
			TweenInfo.new(2, Enum.EasingStyle.Quad)
		)
	end

	------------------[[ INTRO ]] ---------------------
	local function runIntro()
		-- Prepare the text
		vsFrame.Player1.TextLabel.Text = player1.Name
		vsFrame.Player2.TextLabel.Text = player2.Name

		vsFrame.Player1.TextLabel.Position = UDim2.fromScale(0.5, -4)
		vsFrame.Player2.TextLabel.Position = UDim2.fromScale(0.5, 4)

		vsFrame.Player1.TextLabel.Visible = false
		vsFrame.Player2.TextLabel.Visible = false

		--
		vsFrame.Visible = true

		vsFrame.Player1.TextLabel.Visible = true
		Spr.target(vsFrame.Player1.TextLabel, 0.7, 3.5, { Position = UDim2.fromScale(0.5, 0.5) })
		SoundController:PlaySound("IntroWoosh", nil, { PlaybackSpeed = Random.new():NextNumber(1, 1.1) })
		task.wait(0.7)
		vsFrame.Player2.TextLabel.Visible = true
		Spr.target(vsFrame.Player2.TextLabel, 0.7, 3.5, { Position = UDim2.fromScale(0.5, 0.5) })
		SoundController:PlaySound("IntroWoosh", nil, { PlaybackSpeed = Random.new():NextNumber(1, 1.1) })
	end
	self._gameCleaner:Add(task.spawn(runIntro))

	--
	local turnCleaner = self._gameCleaner:Extend()
	local delayTime = 1 -- time to wait before starting the timer
	local gameStationReplica = nil

	-- Function to run when its the local player's turn
	local function ourTurn()
		SoundController:SetBGMCoreVolume(0.5, 1)
		CameraController:SetCameraCFrameTo(cameraViews[ourPlayerSlot .. "PlayView"].CFrame)
		self:_toggleSelfInvisible(true)

		-- Do the round text effect
		local yourTurnText = ui.YourTurn
		yourTurnText.TextTransparency = 0
		yourTurnText.UIStroke.Transparency = 0
		yourTurnText.UIScale.Scale = 1.5

		yourTurnText.Visible = true
		Spr.target(yourTurnText.UIScale, 0.5, 5, { Scale = 1 })

		-- Add highlight thing
		local highlight: Highlight = turnCleaner:Construct(Instance.new, "Highlight")
		highlight.DepthMode = Enum.HighlightDepthMode.Occluded
		highlight.FillColor = Color3.fromRGB(0, 255, 255)
		highlight.OutlineTransparency = 1
		highlight.Parent = ourButton

		turnCleaner:Add(task.spawn(function()
			while highlight do
				highlight.FillTransparency = 0.9 + math.sin(tick() * 4) * 0.1
				task.wait()
			end
		end))

		task.delay(1, function()
			TweenService:Create(yourTurnText, TweenInfo.new(0.5), { TextTransparency = 1 }):Play()
			TweenService:Create(yourTurnText.UIStroke, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		end)

		task.delay(0.07, function()
			SoundController:PlaySound("RoundChange")
			GuiUtil.PulseText(yourTurnText, 1.4, 0.45)
		end)

		--
		statusFrame.TitleText.Text = `POUR <font color="#00aaff">WATER</font> BEFORE THE TIMER RUNS OUT!`
		statusFrame.Description.Visible = true

		task.wait(delayTime)

		-- Start heartbeat sound
		local fillRatio = 0
		if gameStationReplica and gameStationReplica.Data.WaterThreshold > 0 then
			fillRatio = gameStationReplica.Data.WaterLevel / gameStationReplica.Data.WaterThreshold
		end
		local stage = 0
		if fillRatio >= 0.95 then
			stage = 3
		elseif fillRatio >= 0.90 then
			stage = 2
		elseif fillRatio >= 0.80 then
			stage = 1
		end

		local hbSound = SoundController:PlaySound(`Heartbeat{stage}`)
		turnCleaner:Add(function()
			if hbSound then
				TweenService:Create(hbSound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { Volume = 0 }):Play()
				task.delay(0.2, function()
					if hbSound then
						hbSound:Destroy()
					end
				end)
			end
		end)

		--
		local buttonScreenPos = Camera:WorldToViewportPoint(ourButton.Base.Position)
		hitbox.Visible = true
		hitbox.Position = UDim2.fromOffset(buttonScreenPos.X, buttonScreenPos.Y)

		local pressed = false
		turnCleaner:Add(hitbox.MouseButton1Down:Connect(function()
			self.PlayerResponseEvent:Fire({ "Start", workspace:GetServerTimeNow() })
			Spr.target(ourButton.Button, 0.7, 3.5, { Position = buttonPos - Vector3.new(0, 0.08, 0) })
			pressed = true
		end))

		turnCleaner:Add(hitbox.MouseButton1Up:Connect(function()
			if not pressed then
				return
			end

			self.PlayerResponseEvent:Fire({ "End", workspace:GetServerTimeNow() })
			Spr.target(ourButton.Button, 0.7, 3.5, { Position = buttonPos })
			hitbox.Visible = false
			pressed = false
		end))

		turnCleaner:Add(function()
			Spr.target(ourButton.Button, 0.7, 3.5, { Position = buttonPos })
		end)
	end

	-- Function to run when its the other player's turn
	local function theirTurn()
		local otherPlayer = player1 == LocalPlayer and player2 or player1

		CameraController:SetCameraCFrameTo(cameraViews[otherPlayerSlot .. "SpectateView"].CFrame)
		self:_toggleSelfInvisible(false)

		--
		statusFrame.TitleText.Text = `{otherPlayer.Name} IS POURING <font color="#00aaff">WATER</font>!`
		statusFrame.Description.Visible = false
	end

	-- Function to display the timer
	local function displayTimer(attemptTime: number, attemptTimeLength: number)
		-- Reset the bar color
		barHolder.Bar.BackgroundColor3 = GameColors.TIMER_BAR_COLOR[1]

		task.wait(delayTime)
		-- Start the timer
		turnCleaner:Add(SoundController:PlaySound("Timer"))
		turnCleaner:Add(RunService.RenderStepped:Connect(function()
			local timeLeft = attemptTime - workspace:GetServerTimeNow()
			local timeLeftPercentage = timeLeft / attemptTimeLength

			if timeLeftPercentage <= 0 then
				return
			end

			local bar = barHolder.Bar
			bar.Size = UDim2.fromScale(math.clamp(timeLeftPercentage, 0, 1), 1)

			-- Change color depending on the time left
			if timeLeftPercentage <= 0.2 then
				TweenService:Create(bar, TweenInfo.new(0.1), { BackgroundColor3 = GameColors.TIMER_BAR_COLOR[3] })
					:Play()
			elseif timeLeftPercentage <= 0.6 then
				TweenService:Create(bar, TweenInfo.new(0.1), { BackgroundColor3 = GameColors.TIMER_BAR_COLOR[2] })
					:Play()
			else
				TweenService:Create(bar, TweenInfo.new(0.1), { BackgroundColor3 = GameColors.TIMER_BAR_COLOR[1] })
					:Play()
			end
		end))
	end

	self._gameCleaner:Add(self.PlayerAttemptEvent:Connect(function(data: { any })
		local player = data[1]
		local attemptTime = data[2]
		local attemptTimeLength = data[3]

		turnCleaner:Clean()

		self:_togglePurchasableSection(player == LocalPlayer)

		if player == LocalPlayer then
			turnCleaner:Add(task.spawn(function()
				ourTurn(attemptTime)
			end))
		else
			turnCleaner:Add(task.spawn(function()
				theirTurn()
			end))
		end

		--
		UIController:OpenFrame(statusFrame, true)

		--
		turnCleaner:Add(task.spawn(function()
			displayTimer(attemptTime, attemptTimeLength)
		end))

		-- Reset the bar
		turnCleaner:Add(function()
			barHolder.Bar.BackgroundColor3 = GameColors.TIMER_BAR_COLOR[1]
			barHolder.Bar.Size = UDim2.fromScale(1, 1)
		end)
	end))

	-- This is to clean anything related to the intro and setup when its time for the first attempt
	self._gameCleaner:Once(self.PlayerAttemptEvent, function()
		vsFrame.Visible = false
	end)

	--
	self._gameCleaner:Add(Replica.OnNew("GameStation", function(replica)
		if not (replica.Tags.Station == station.Name) then
			return
		end

		gameStationReplica = replica

		--
		replica:OnSet({ "WaterLevel" }, function(newValue)
			if newValue > replica.Data.WaterThreshold then
				turnCleaner:Clean()
			end
		end)
	end))

	self._gameCleaner:Add(self.AnotherChanceEvent:Connect(function(anotherChancePlayer: Player)
		if not (anotherChancePlayer == LocalPlayer) then
			NotificationController:NotifyNormal("Your opponent bought another try!")
		end
	end))

	--
	self._gameCleaner:Add(self.AnnounceGameWinnerEvent:Connect(function(data: { any })
		--
		local winner = data[1]
		local isWinner = winner == LocalPlayer

		-- Reset for the tween
		gameResult.Position = UDim2.fromScale(0.5, 1.5)

		-- Set the texts and visibility
		gameResult.WinImage.Visible = isWinner
		gameResult.LoseImage.Visible = not isWinner
		gameResult.Title.Text = isWinner and "YOU WON!" or "YOU LOST!"
		gameResult.Description.Text = isWinner and "Your opponent spilled the water!"
			or "You spilled the water! Be more careful next time"
		gameResult.Glow.ImageColor3 = isWinner and GameColors.RESULT_GLOW_COLORS.Winner
			or GameColors.RESULT_GLOW_COLORS.Loser
		gameResult.Rays.ImageColor3 = isWinner and GameColors.RESULT_RAYS_COLORS.Winner
			or GameColors.RESULT_RAYS_COLORS.Loser
		gameResult.Title.TextColor3 = isWinner and GameColors.RESULT_TEXT_COLORS.Winner
			or GameColors.RESULT_TEXT_COLORS.Loser

		TweenService:Create(ui.Dim, TweenInfo.new(0.5), { BackgroundTransparency = 0.35 }):Play()

		--
		SoundController:PlaySound(isWinner and "GameWin" or "GameLose")

		-- Show
		gameResult.Visible = true
		Spr.target(gameResult, 0.8, 1.2, { Position = UDim2.fromScale(0.5, 0.5) })

		-- Hide other uis
		UIController:CloseFrame(statusFrame)
	end))
end

-- Stops the game and cleanups everything up
function GameStationController:_onGameStop(station: Model)
	--
	self.InGame = false

	local ui = self.UI
	local gameResult = ui.GameResult
	local vsFrame = ui.VsFrame
	local statusFrame = ui.StatusFrame
	local hitbox: TextButton = ui.Hitbox
	local yourTurnText = ui.YourTurn

	-- Clean up all game-related resources
	self._gameCleaner:Clean()
	self:_toggleSelfInvisible(false)
	CameraController:SetBackToDefault()
	self:_togglePurchasableSection(false)
	SoundController:SetBGMCoreVolume(1, 1)

	-- Reset UI state that isn't cleared by _gameCleaner (e.g. if game stopped before first attempt)
	vsFrame.Visible = false
	hitbox.Visible = false
	yourTurnText.Visible = false

	-- Hide other uis
	UIController:CloseFrame(statusFrame)

	--
	task.wait(3)

	Spr.target(gameResult, 0.7, 1.2, { Position = UDim2.fromScale(0.5, 1.5) })
	TweenService:Create(ui.Dim, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()

	task.delay(1, function()
		UIController:CloseFrame(gameResult)
	end)
end

-- Handles when the player joins the station
function GameStationController:_onJoinStation(station: Model)
	--
	local ui = self.UI
	local choices = ui.Choices
	local aiPrompt = ui.AIPrompt

	--
	local tableModel = station.Table

	--
	HudController:HideHud()
	self.InStation = true

	for _, v in workspace.Map:GetDescendants() do
		if v:IsA("BillboardGui") then
			v.Enabled = false
		end
	end

	for _, v in workspace.Terrain:GetChildren() do
		if v:IsA("BillboardGui") then
			v.Enabled = false
		end
	end

	-- Disable controls
	Controls:Disable()

	self._onJoinedCleaner:Add(task.delay(0, function()
		if not self.InStation or self.InGame then
			return
		end

		UIController:OpenFrame(aiPrompt, true)

		self._onJoinedCleaner:Add(UIController:BindButtonClick(aiPrompt.Play, function()
			self.StartBotMatchEvent:Fire()
			UIController:CloseFrame(aiPrompt)
		end, true))
	end))

	-- Show choices and bind buttons and cleanups
	UIController:OpenFrame(choices, true)

	self._onJoinedCleaner:Add(UIController:BindButtonClick(choices.Leave, function()
		self.RequestLeaveGameStationEvent:Fire()
	end, true))

	self._onJoinedCleaner:Add(UIController:BindButtonClick(choices.InviteFriends, function()
		FriendController:OpenFriendInvitePrompt()
	end, true))

	self._onJoinedCleaner:Add(function()
		UIController:CloseFrame(choices)
		UIController:CloseFrame(aiPrompt)
	end)

	-- Make camera orbit around the table while looking on it
	Camera.CameraType = Enum.CameraType.Scriptable
	self._onJoinedCleaner:Add(RunService.RenderStepped:Connect(function()
		local currentTime = tick()

		local radius = 10
		local speed = 0.2
		local height = 8

		local x = tableModel.Position.X + math.cos(currentTime * speed) * radius
		local z = tableModel.Position.Z + math.sin(currentTime * speed) * radius
		local y = tableModel.Position.Y + height

		local cameraPosition = Vector3.new(x, y, z)
		Camera.CFrame = CFrame.new(cameraPosition, tableModel.Position + Vector3.new(0, 3, 0))
	end))
end

-- Handles when the player leaves the station
function GameStationController:_onLeftStation()
	--
	self._onJoinedCleaner:Clean()
	Controls:Enable()
	HudController:ShowHud()
	Camera.CameraType = Enum.CameraType.Custom
	self.InStation = false

	for _, v in workspace.Map:GetDescendants() do
		if v:IsA("BillboardGui") then
			v.Enabled = true
		end
	end

	for _, v in workspace.Terrain:GetChildren() do
		if v:IsA("BillboardGui") then
			v.Enabled = true
		end
	end
end

function GameStationController:_togglePurchasableSection(toggle: boolean)
	--
	local ui = self.UI
	local purchasableSection = ui.Purchasables

	--
	self._purchasableCleaner:Clean()

	--
	Spr.target(
		purchasableSection,
		0.7,
		3,
		{ Position = toggle and UDim2.fromScale(0.5, 0.9) or UDim2.fromScale(0.5, 1.1) }
	)

	--
	for _, v in purchasableSection.Holder:GetChildren() do
		if not v:IsA("GuiButton") then
			continue
		end

		if not toggle then
			continue
		end

		self._purchasableCleaner:Add(UIController:BindButtonClick(v, function()
			ShopController:PromptProductPurchaseFromId(v.Name)
		end, true))
	end
end

-- Toggles the self invisible
function GameStationController:_toggleSelfInvisible(toggle: boolean)
	local character = LocalPlayer.Character

	for _, v in character:GetDescendants() do
		if v:IsA("BasePart") or v:IsA("Decal") then
			if not v:GetAttribute("OrigTransparency") then
				v:SetAttribute("OrigTransparency", v.Transparency)
			end

			v.Transparency = toggle and 1 or (v:GetAttribute("OrigTransparency") or 0)
		end
	end
end

-- Prompts the user to by the "Another Chance" product
function GameStationController:_promptAnotherChance(loserPlayer: Player, expiryTime: number)
	--
	local ui = self.UI

	--
	local anotherChanceUI = PlayerGui.AnotherChanceUI
	local holder = anotherChanceUI.Holder

	--
	local cleaner = Trove.new()

	--
	local didLose = loserPlayer == LocalPlayer

	--
	local firstPurchaseOfTheDayTime = PlayerDataController:GetKey("FirstPurchaseOfTheDayTime")
	local anotherChanceProduct = "AnotherChance"

	if
		firstPurchaseOfTheDayTime
		and firstPurchaseOfTheDayTime.AnotherChance
		and os.time() > firstPurchaseOfTheDayTime.AnotherChance
	then
		anotherChanceProduct = "FirstAnotherChanceOfTheDay"
	end

	-- make sure both buttons are visible if we are the loser
	if didLose then
		holder.Choices.Yes.Visible = true
		holder.Choices.No.Visible = true

		cleaner:Add(UIController:BindButtonEffect(holder.Choices.Yes))
		cleaner:Add(UIController:BindButtonEffect(holder.Choices.No))

		--
		holder.Choices.Yes.Deal.Visible = anotherChanceProduct == "FirstAnotherChanceOfTheDay"

		--
		local productData = ShopController:GetProductFromId(anotherChanceProduct)
		cleaner:Add(
			MarketplaceService.PromptProductPurchaseFinished:Once(function(_, productId: number, wasPurchased: boolean)
				if productId == productData.ProductId then
					if not wasPurchased then
						self.DenyAnotherChanceEvent:Fire()
					end

					UIController:CloseFrame(holder)
					cleaner:Destroy()
				end
			end)
		)
	end

	-- Set texts and visibility
	local colors = didLose and ANOTHER_CHANCE_COLORS.Loser or ANOTHER_CHANCE_COLORS.Winner

	holder.Vignette.ImageColor3 = colors.VignetteColor
	holder.UIStroke.Color = colors.StrokeColor
	holder.Timer.UIStroke.Color = colors.StrokeColor
	holder.Title.UIStroke.Color = colors.StrokeColor

	holder.Title.Position = didLose and UDim2.fromScale(0.5, 0.255) or UDim2.fromScale(0.5, 0.3)
	holder.Title.Size = didLose and UDim2.fromScale(0.9, 0.28) or UDim2.fromScale(0.9, 0.385)

	holder.Timer.Position = didLose and UDim2.fromScale(0.5, 0.5) or UDim2.fromScale(0.5, 0.69)
	holder.Timer.Size = didLose and UDim2.fromScale(0.9, 0.15) or UDim2.fromScale(0.9, 0.285)

	--
	holder.Title.Text = didLose and "You spilled the water! Want another chance to win?"
		or "You won! But your opponent can buy one more chance to come back!"
	holder.Choices.Visible = didLose

	--
	UIController:OpenFrame(holder, true)
	UIController:CloseFrame(ui.StatusFrame)
	UIController:CloseFrame(ui.Purchasables)

	SoundController:PlaySound("Notice")

	-- show the timer thing
	cleaner:Add(task.spawn(function()
		while holder.Visible do
			local currentTime = workspace:GetServerTimeNow()
			local timeLeft = math.max(0, expiryTime - currentTime)

			if didLose then
				holder.Timer.Text = string.format("OFFER GONE IN: %0.1f", timeLeft)
			else
				holder.Timer.Text = string.format("OPPONENT DECIDING: %0.1f", timeLeft)
			end

			task.wait()
		end

		UIController:CloseFrame(holder)
		cleaner:Destroy()
	end))

	cleaner:Add(task.spawn(function()
		while true do
			holder.Vignette.ImageTransparency = 0.7 + math.sin(tick() * 4) * 0.1
			task.wait()
		end
	end))

	--
	if didLose then
		local purchaseAnotherChance = DecisionController:Decide(holder.Choices.Yes, holder.Choices.No, expiryTime)

		if purchaseAnotherChance then
			ShopController:PromptProductPurchaseFromId(anotherChanceProduct)
			holder.Choices.No.Visible = false
		else
			self.DenyAnotherChanceEvent:Fire()
			UIController:CloseFrame(holder)
		end
	else
		cleaner:Add(self.AnotherChanceEvent:Connect(function()
			UIController:CloseFrame(holder)
			cleaner:Destroy()
		end))

		cleaner:Add(self.AnnounceGameWinnerEvent:Connect(function()
			UIController:CloseFrame(holder)
			cleaner:Destroy()
		end))
	end
end

--
function GameStationController:OnInit()
	--
	PlayerDataController = require(script.Parent.PlayerDataController)
	CameraController = require(script.Parent.CameraController)
	NotificationController = require(script.Parent.NotificationController)
	FriendController = require(script.Parent.FriendController)
	ShopController = require(script.Parent.ShopController)
	DecisionController = require(script.Parent.DecisionController)
	HudController = require(script.Parent.HudController)
	UIController = require(script.Parent.UIController)
	SoundController = require(script.Parent.SoundController)

	--
	self.UI = PlayerGui:WaitForChild("GameUI")

	self.PlayerJoinedStationEvent:Connect(function(station: Model)
		self:_onJoinStation(station)
	end)

	self.PlayerLeftStationEvent:Connect(function(station: Model)
		self:_onLeftStation(station)
	end)

	self.GameStartedEvent:Connect(function(data: { any })
		self:_onGameStart(table.unpack(data))
	end)

	self.GameStoppedEvent:Connect(function(station: Model)
		self:_onGameStop(station)
	end)

	self.PromptPlayerAnotherChanceEvent:Connect(function(data: { any })
		local expiryTime = data[1]
		local currentGameLoser = data[2]

		self:_promptAnotherChance(currentGameLoser, expiryTime)
	end)
end

function GameStationController:OnStart()
	UIController:BindButtonClick(self.UI.Choices.InviteFriends, function()
		FriendController:OpenFriendInvitePrompt()
	end, true)
end

return GameStationController
