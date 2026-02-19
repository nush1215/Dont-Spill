-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local ZonePlus = require(Packages.ZonePlus)
local Spr = require(Packages.Spr)

-- Classes
local Class = script.Parent.Parent.Class
local Viewport = require(Class.Viewport)

-- Shared
local Shared = ReplicatedStorage.Shared
local Products = require(Shared.Config.Products)
local Gamepasses = require(Shared.Config.Gamepasses)
local RandomUtil = require(Shared.RandomUtil)
local GameColors = require(Shared.GameColors)
local ChairSkins = require(Shared.Config.ChairSkins)
local GuiUtil = require(Shared.GuiUtil)

--
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local PlayerDataController
local NavigationUIController
local UIController
local SoundController

--
local ShopController = {
	--
	RequestProductPurchase = BridgeNet2.ReferenceBridge("RequestProductPurchase"),
	RequestGamepassPurchase = BridgeNet2.ReferenceBridge("RequestGamepassPurchase"),

	--
	Prices = {},
}

-- Requests a product purchase from an id
function ShopController:PromptProductPurchaseFromId(id: string, toGift: Player?): (boolean, { any })
	--
	local productInfo = Products.GetProductFromId(id)
	if not productInfo then
		warn(`Product data for id {id} not found.`)
		return
	end

	--
	self.RequestProductPurchase:Fire({ id, toGift })
	return true, productInfo
end

-- Requests a gamepass purchase from an id
function ShopController:PromptGamepassPurchaseFromId(id: string, toGift: Player): (boolean, { any })
	--
	local gamepassInfo = Gamepasses.GetGamepassFromId(id)
	if not gamepassInfo then
		warn(`Gamepass data for id {id} not found.`)
		return
	end

	--
	self.RequestGamepassPurchase:Fire({ id, toGift })
	return true, gamepassInfo
end

-- Gets the product or gamepass data from an id
function ShopController:GetProductFromId(id: string): Gamepasses.Gamepass | Products.Product
	return Products.GetProductFromId(id) or Gamepasses.GetGamepassFromId(id)
end

-- Gets the price of a product or gamepass
function ShopController:GetPrice(id: string)
	--
	local data = Products.GetProductFromId(id) or Gamepasses.GetGamepassFromId(id)
	if not data then
		return "-"
	end
	local isGamepass = if Products.GetProductFromId(id) then false else true

	--
	if data.CurrencyPrice then
		return data.CurrencyPrice
	end

	--
	if self.Prices[data.Id] then
		return self.Prices[data.Id]
	end

	--
	local success, productInfo = pcall(function()
		return MarketplaceService:GetProductInfo(
			isGamepass and data.PassId or data.ProductId,
			isGamepass and Enum.InfoType.GamePass or Enum.InfoType.Product
		)
	end)

	if not success or not productInfo or productInfo.PriceInRobux == nil then
		return "-"
	end

	local price = productInfo.PriceInRobux
	self.Prices[data.Id] = price

	return price
end

-- Setups the starter pack category in the shop
function ShopController:_setupStarterPack()
	--
	local ui = self.UI
	local holder = ui.Holder
	local starterPack = holder.Container.ScrollingFrame.StarterPack
	local starterPackExternal = ui.StarterPackExternal

	-- Setup buttons in the shop
	starterPack.Purchase.Title.Text = `{utf8.char(0xE002)}{self:GetPrice("StarterPack")}`
	UIController:BindButtonClick(starterPack.Purchase, function()
		self:PromptProductPurchaseFromId("StarterPack")
	end, true, false, { ClickSoundName = "RobuxButton" })

	-- Setup external buttons / ui
	local button = NavigationUIController:BindButton("StarterPack", function()
		UIController:OpenFrame(starterPackExternal)
		SoundController:PlaySound("RobuxButton")
	end)

	--
	task.spawn(function()
		button.Price.Text = `{utf8.char(0xE002)}{self:GetPrice("StarterPack")}`
	end)

	-- Setup timers
	local hasData, playerReplica = PlayerDataController:GetReplica():await()
	if not hasData then
		return
	end

	local starterPackStartTime = playerReplica.Data.StarterPackStart

	local currentTimeLeft = starterPackStartTime - os.time()
	local function hideTimers()
		--
		starterPack.Timer.Visible = false
		starterPack.TimerTitle.Visible = false
		button.Timer.Visible = false

		--
		button.Visible = false
	end

	if table.find(playerReplica.Data.PurchasedOnceProducts, "StarterPack") then
		hideTimers()
		button.Visible = false
	end

	if currentTimeLeft <= 0 then
		hideTimers()
		return
	end

	self:_setupExternalStarterPack()

	task.spawn(function()
		while true do
			task.wait(1)
			local timeLeft = playerReplica.Data.StarterPackStart - os.time()
			button.Timer.Text = GuiUtil.ConvertSecondsToHHMMSS(math.max(0, timeLeft))
			starterPack.Timer.Text = GuiUtil.ConvertSecondsToHHMMSS(math.max(0, timeLeft))

			if timeLeft <= 0 then
				hideTimers()
				break
			end
		end
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId, isPurchased)
		if productId == Products.GetProductFromId("StarterPack").ProductId and isPurchased then
			button.Visible = false
			UIController:CloseFrame(starterPackExternal)
		end
	end)
end

-- Setups the external starter pack frame that gets opened when the starter pack button is clicked
function ShopController:_setupExternalStarterPack()
	local ui = self.UI
	local dim = ui.Dim
	local starterPackExternal = ui.StarterPackExternal

	-- Setup buttons in the shop
	starterPackExternal.Purchase.Title.Text = `{utf8.char(0xE002)}{self:GetPrice("StarterPack")}`
	UIController:BindButtonClick(starterPackExternal.Purchase, function()
		self:PromptProductPurchaseFromId("StarterPack")
	end, true, false, { ClickSoundName = "RobuxButton" })

	-- Setup external buttons / ui
	UIController:BindButtonClick(starterPackExternal.Exit, function()
		UIController:CloseFrame(starterPackExternal)
	end, true)

	--
	starterPackExternal:GetPropertyChangedSignal("Visible"):Connect(function()
		if starterPackExternal.Visible then
			TweenService:Create(dim, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.2 })
				:Play()
		else
			TweenService:Create(dim, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 }):Play()
		end
	end)
end

-- Setups the aura pack category in the shop
function ShopController:_setupAuraPack()
	--
	local ui = self.UI
	local holder = ui.Holder
	local auraPack = holder.Container.ScrollingFrame.AuraPack

	--
	for _, v in auraPack.ItemContainer:GetChildren() do
		local skinData = ChairSkins.GetChairFromId(v.Name)
		if not skinData then
			continue
		end

		--
		v.Title.Text = skinData.Name:upper()
		Viewport.new(skinData.Model:Clone(), v.Icon, CFrame.new(), true, holder)
	end

	UIController:BindButtonClick(auraPack.Purchase, function()
		self:PromptProductPurchaseFromId("AuraPack")
	end, true, false, { ClickSoundName = "RobuxButton" })

	auraPack.Purchase.Title.Text = `{utf8.char(0xE002)}{self:GetPrice("AuraPack")}`
end

-- Setups the gamepass category in the shop
function ShopController:_setupGamepass()
	--
	local ui = self.UI
	local holder = ui.Holder
	local container = holder.Container.ScrollingFrame
	local gamepassSection = container.Gamepasses

	--
	for _, gamepassFrame in gamepassSection:GetChildren() do
		if not gamepassFrame:IsA("Frame") then
			continue
		end

		--
		local gamepassData = Gamepasses.GetGamepassFromId(gamepassFrame.Name)
		if not gamepassData then
			warn(`Gamepass data for {gamepassFrame.Name} not found.`)
			continue
		end

		--
		gamepassFrame.Title.Text = gamepassData.Name:upper()
		gamepassFrame.Price.Text = `{utf8.char(0xE002)}{self:GetPrice(gamepassData.Id)}`

		UIController:BindButtonClick(gamepassFrame.Button, function()
			self:PromptGamepassPurchaseFromId(gamepassData.Id)
		end, true, false, {
			ShowFrame = gamepassFrame,
			ButtonDownScale = 0.95,
			ButtonHoverscale = 1.04,
			ClickSoundName = "RobuxButton",
		})
	end
end

-- Setups the bux category in the shop
function ShopController:_setupBux()
	--
	local ui = self.UI
	local holder = ui.Holder
	local bux = holder.Container.ScrollingFrame.Bux

	-- Setup the frames
	for _, buxFrame in bux:GetChildren() do
		task.spawn(function()
			if not buxFrame:IsA("Frame") then
				return
			end

			--
			local buxProductData = Products.GetProductFromId(buxFrame.Name)
			if not buxProductData then
				warn(`Bux product data for {buxFrame.Name} not found.`)
				return
			end

			--
			buxFrame.Price.Text = `{utf8.char(0xE002)}{self:GetPrice(buxProductData.Id)}`
			buxFrame.Title.Text = `{buxProductData.Value} BUX`

			UIController:BindButtonClick(buxFrame.Button, function()
				self:PromptProductPurchaseFromId(buxProductData.Id)
			end, true, false, {
				ShowFrame = buxFrame,
				ButtonDownScale = 0.95,
				ButtonHoverscale = 1.04,
				ClickSoundName = "RobuxButton",
			})
		end)
	end
end

function ShopController:_setupGamepassDisplay()
	--
	local currentGamepassId

	--
	local button = NavigationUIController:BindButton("GamepassDisplay", function()
		self:PromptGamepassPurchaseFromId(currentGamepassId)
		SoundController:PlaySound("RobuxButton")
	end)

	--
	local function getNewGamepass(): Gamepasses.Gamepass
		local gamepasses = Gamepasses.GetAllGamepasses()
		local randomGamepass = RandomUtil.GetRandomIntFromMinMax(1, #gamepasses)

		if gamepasses[randomGamepass].Id == currentGamepassId then
			task.wait()
			return getNewGamepass()
		end

		return gamepasses[randomGamepass]
	end

	local function updateDisplay()
		local newGamepass = getNewGamepass()
		currentGamepassId = newGamepass.Id
		button.Icon.Image = newGamepass.Icon
		button.Title.Text = newGamepass.Name:upper()
		button.Glow.ImageColor3 = GameColors.GAMEPASS_DISPLAYS[newGamepass.Id].GlowColor
		button.Rays.ImageColor3 = GameColors.GAMEPASS_DISPLAYS[newGamepass.Id].RayColor
		button.Price.Text = `{utf8.char(0xE002)}{self:GetPrice(newGamepass.Id)}`
	end

	while true do
		updateDisplay()
		task.wait(20)
	end
end

function ShopController:_setupChairDisplay()
	local ui = self.UI
	local holder = ui.Holder
	local chairDisplay = holder.Container.ScrollingFrame.ChairDisplay

	for _, v in chairDisplay:GetChildren() do
		if not v:IsA("Frame") then
			continue
		end

		local chairData = ChairSkins.GetChairFromId(v.Name)
		if not chairData then
			continue
		end

		if v.Name == "Chair67Premium" then
			Viewport.new(chairData.Model:Clone(), v.ViewportContainer.Icon, CFrame.new(1, 0, -3), true, holder)
		else
			Viewport.new(chairData.Model:Clone(), v.ViewportContainer.Icon, CFrame.new(), true, holder)
		end

		UIController:BindButtonClick(v.Purchase, function()
			self:PromptProductPurchaseFromId(chairData.Id)
		end, true, false, {
			ShowFrame = v.Purchase,
			ButtonDownScale = 0.95,
			ButtonHoverscale = 1.04,
			ClickSoundName = "RobuxButton",
		})

		v.Purchase.Title.Text = `{utf8.char(0xE002)}{self:GetPrice(chairData.Id)}`
	end
end

--
function ShopController:_setupUI()
	--
	local ui = self.UI
	local holder = ui.Holder

	--
	task.spawn(ShopController._setupBux, self)
	task.spawn(ShopController._setupGamepass, self)
	task.spawn(ShopController._setupStarterPack, self)
	task.spawn(ShopController._setupAuraPack, self)
	task.spawn(ShopController._setupGamepassDisplay, self)
	task.spawn(ShopController._setupChairDisplay, self)

	--
	NavigationUIController:BindButton("Shop", function()
		UIController:OpenFrame(holder)
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = -10 })
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = 0 })
	end)

	UIController:BindButtonClick(holder.Header.Exit, function()
		UIController:CloseFrame(holder)
	end, true)

	--
	UIController.OnFrameOpened:Connect(function(frame: string)
		if frame == holder then
			TweenService:Create(ui.Dim, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 0.3 })
				:Play()
			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
				FieldOfView = 75,
			}):Play()
			SoundController:PlaySound("ShopOpen")
		end
	end)

	UIController.OnFrameClosed:Connect(function(frame: string)
		if frame == holder then
			TweenService:Create(ui.Dim, TweenInfo.new(0.3, Enum.EasingStyle.Quint), { BackgroundTransparency = 1 })
				:Play()

			TweenService:Create(workspace.CurrentCamera, TweenInfo.new(0.5, Enum.EasingStyle.Quint), {
				FieldOfView = 70,
			}):Play()
		end
	end)
end

function ShopController:OnInit()
	--
	PlayerDataController = require(script.Parent.PlayerDataController)
	NavigationUIController = require(script.Parent.NavigationUIController)
	SoundController = require(script.Parent.SoundController)
	UIController = require(script.Parent.UIController)

	self.UI = PlayerGui:WaitForChild("ShopUI")
end

function ShopController:OnStart()
	task.spawn(ShopController._setupUI, self)
end

return ShopController
