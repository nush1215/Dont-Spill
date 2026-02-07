-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Signal = require(Packages.Signal)

-- Shared
local Shared = ReplicatedStorage.Shared
local Products = require(Shared.Config.Products)
local Gamepasses = require(Shared.Config.Gamepasses)

--
local PlayerDataManager
local NotificationManager
local CurrencyManager

--
local ShopManager = {
	RequestProductPurchase = BridgeNet2.ReferenceBridge("RequestProductPurchase"),
	RequestGamepassPurchase = BridgeNet2.ReferenceBridge("RequestGamepassPurchase"),

	PlayerPurchased = Signal.new(),

	_toGiftPlayer = {},
}

--
local MAX_GAMEPASS_VERIFY_RETRIES = 3
local GAMEPASS_VERIFY_RETRY_DELAY = 0.5

--
local function validatePlayer(player: Player?): boolean
	return player ~= nil and player:IsDescendantOf(Players)
end

local function setupGiftTracking(player: Player, itemId: string, recipient: Player?)
	if not recipient then
		return
	end

	if not ShopManager._toGiftPlayer[player] then
		ShopManager._toGiftPlayer[player] = {}
	end

	ShopManager._toGiftPlayer[player][itemId] = recipient
end

local function clearGiftTracking(player: Player, itemId: string?)
	if not ShopManager._toGiftPlayer[player] then
		return
	end

	if itemId then
		ShopManager._toGiftPlayer[player][itemId] = nil
	else
		ShopManager._toGiftPlayer[player] = nil
	end
end

-- Attempts to prompt a product purchase for the player
-- @param player The player attempting the purchase
-- @param id The product ID
-- @param toGift Optional player to gift the product to
function ShopManager:AttemptProductPurchase(player: Player, id: string, toGift: Player?)
	if not validatePlayer(player) then
		warn(`Cannot attempt product purchase for invalid player: {player}`)
		return
	end

	local productData = Products.GetProductFromId(id)
	if not productData then
		warn(`Product with ID '{id}' not found`)
		return
	end

	PlayerDataManager:GetPlayerData(player)
		:andThen(function(playerData)
			if productData.PurchaseOnce and table.find(playerData.PurchasedOnceProducts or {}, id) then
				NotificationManager.NotifyNormalEvent:Fire(player, {
					`You have already purchased <font color="#ffd400">{productData.Name}</font>!`,
				})
				return
			end

			if toGift then
				setupGiftTracking(player, id, toGift)
			end

			if productData.ProductId then
				MarketplaceService:PromptProductPurchase(player, productData.ProductId)
			end
		end)
		:catch(function(error)
			warn(`Failed to attempt product purchase for {player.Name}: {error}`)
		end)
end

-- Attempts to prompt a gamepass purchase for the player
-- @param player The player attempting the purchase
-- @param id The gamepass ID
-- @param toGift Optional player to gift the gamepass to
function ShopManager:AttemptGamepassPurchase(player: Player, id: string, toGift: Player?)
	if not validatePlayer(player) then
		warn(`Cannot attempt gamepass purchase for invalid player: {player}`)
		return
	end

	local gamepassData = Gamepasses.GetGamepassFromId(id)
	if not gamepassData then
		warn(`Gamepass with ID '{id}' not found`)
		return
	end

	if toGift then
		setupGiftTracking(player, id, toGift)
	end

	if gamepassData.PassId then
		MarketplaceService:PromptGamePassPurchase(player, gamepassData.PassId)
	end
end

-- Prompts a currency purchase to the player for the amount needed
-- @param player The player to prompt
-- @param currencyNeeded The amount of currency needed
function ShopManager:PromptCurrencyPurchase(player: Player, currencyNeeded: number)
	if not validatePlayer(player) then
		warn(`Cannot prompt currency purchase for invalid player: {player}`)
		return
	end

	if currencyNeeded <= 0 then
		warn(`Invalid currency amount: {currencyNeeded}`)
		return
	end

	local currencyProducts = Products.GetProductsByType("Currency")
	table.sort(currencyProducts, function(a, b)
		return (a.Value or 0) < (b.Value or 0)
	end)

	for _, product in currencyProducts do
		if product.Value and product.Value >= currencyNeeded then
			self:AttemptProductPurchase(player, product.Id)
			return
		end
	end

	if #currencyProducts > 0 then
		local largestProduct = currencyProducts[#currencyProducts]
		self:AttemptProductPurchase(player, largestProduct.Id)
	else
		warn(`No currency products available for {player.Name}`)
	end
end

-- Handles gamepass purchase completion
-- @param player The player who purchased
-- @param gamepassId The gamepass ID from Roblox
-- @param isPurchased Whether the purchase was successful
function ShopManager:_onPurchaseGamepass(player: Player, gamepassId: number, isPurchased: boolean)
	if not isPurchased then
		return
	end

	if not validatePlayer(player) then
		return
	end

	local gamepassData = Gamepasses.GetGamepassFromPassId(gamepassId)
	if not gamepassData then
		warn(`Gamepass with PassId '{gamepassId}' not found`)
		return
	end

	player:AddTag(gamepassData.Id)

	if gamepassData.OnPurchaseCallback then
		task.spawn(function()
			pcall(gamepassData.OnPurchaseCallback, player)
		end)
	end

	if gamepassData.OnInitializeCallback then
		task.spawn(function()
			pcall(gamepassData.OnInitializeCallback, player)
		end)
	end

	self.PlayerPurchased:Fire(player, gamepassData.Id)

	NotificationManager.Notify:Fire(player, {
		`Successfully purchased <font color="#ffd400">{gamepassData.Name}</font>`,
		nil,
		"RobuxPurchase",
	})
end

-- Processes a product receipt from Roblox
-- @param receiptInfo The receipt information from Roblox
-- @returns ProductPurchaseDecision
function ShopManager:_processReceipt(receiptInfo: any): Enum.ProductPurchaseDecision
	local productData = Products.GetProductFromProductId(receiptInfo.ProductId)
	if not productData then
		warn(`Product with ProductId '{receiptInfo.ProductId}' not found`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player or not validatePlayer(player) then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	NotificationManager.NotifyNormalEvent:Fire(player, {
		`Successfully Purchased <font color="#ffd400">{productData.Name}</font>`,
		nil,
		"RobuxPurchase",
	})

	local originalPlayer = player
	local toGift = self._toGiftPlayer[player] and self._toGiftPlayer[player][productData.Id]

	if toGift and validatePlayer(toGift) then
		clearGiftTracking(originalPlayer, productData.Id)

		if toGift ~= originalPlayer then
			NotificationManager.NotifyNormalEvent:Fire(toGift, {
				`<font color="#ffd400">{originalPlayer.Name}</font> has gifted you <font color="#ff7272">{productData.Name}</font>!`,
			})
		end

		task.spawn(function()
			pcall(function()
				AnalyticsService:LogCustomEvent(originalPlayer, "Gifted Product", 1, {
					[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = productData.Id,
				})
			end)
		end)

		player = toGift
	end

	if productData.Callback then
		task.spawn(function()
			pcall(productData.Callback, player, toGift)
		end)
	end

	if productData.PurchaseOnce then
		PlayerDataManager:InsertPlayerDataKey(player, "PurchasedOnceProducts", productData.Id)
		player:AddTag(productData.Id)
	end

	self.PlayerPurchased:Fire(player, productData.Id)

	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- Verifies and initializes gamepasses for a player
-- @param player The player to verify gamepasses for
function ShopManager:_verifyGamepasses(player: Player)
	if not validatePlayer(player) then
		return
	end

	local allGamepasses = Gamepasses.GetAllGamepasses()

	local function verifyOwns(gamepassData: any, retryCount: number)
		if retryCount > MAX_GAMEPASS_VERIFY_RETRIES then
			warn(
				`Failed to verify gamepass '{gamepassData.Id}' for {player.Name} after {MAX_GAMEPASS_VERIFY_RETRIES} retries`
			)
			return
		end

		if not validatePlayer(player) then
			return
		end

		local success, playerOwns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassData.PassId)
		end)

		if not success then
			task.wait(GAMEPASS_VERIFY_RETRY_DELAY)
			return verifyOwns(gamepassData, retryCount + 1)
		end

		if success and playerOwns then
			if gamepassData.OnInitializeCallback then
				task.spawn(function()
					pcall(gamepassData.OnInitializeCallback, player)
				end)
			end

			player:AddTag(gamepassData.Id)
		end
	end

	for _, gamepassData in allGamepasses do
		task.spawn(verifyOwns, gamepassData, 0)
	end
end

-- Verifies and applies purchase-once products for a player
-- @param player The player to verify products for
function ShopManager:_verifyPurchaseOnes(player: Player)
	if not validatePlayer(player) then
		return
	end

	PlayerDataManager:GetPlayerDataKey(player, "PurchasedOnceProducts")
		:andThen(function(purchased: { string })
			if not purchased then
				return
			end

			for _, tag in purchased do
				player:AddTag(tag)
			end
		end)
		:catch(function(error)
			warn(`Failed to verify purchase-once products for {player.Name}: {error}`)
		end)
end

-- Sets up the starter pack start time for a player
-- @param player The player to set up
function ShopManager:_setupStarterPackTime(player: Player)
	if not validatePlayer(player) then
		return
	end

	PlayerDataManager:GetPlayerDataKey(player, "StarterPackStart")
		:andThen(function(starterPackStart: number)
			if starterPackStart == 0 then
				PlayerDataManager:SetPlayerDataKey(player, "StarterPackStart", os.time())
			end
		end)
		:catch(function(error)
			warn(`Failed to setup starter pack time for {player.Name}: {error}`)
		end)
end

-- Initializes the ShopManager
-- Sets up dependencies, event connections, and verifies existing players
function ShopManager:OnInit()
	PlayerDataManager = require(script.Parent.PlayerDataManager)
	NotificationManager = require(script.Parent.NotificationManager)
	CurrencyManager = require(script.Parent.CurrencyManager)

	Players.PlayerAdded:Connect(function(player: Player)
		self:_verifyGamepasses(player)
		self:_verifyPurchaseOnes(player)
		self:_setupStarterPackTime(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_verifyGamepasses(player)
		self:_verifyPurchaseOnes(player)
		self:_setupStarterPackTime(player)
	end

	Players.PlayerRemoving:Connect(function(player: Player)
		clearGiftTracking(player)
	end)

	MarketplaceService.ProcessReceipt = function(...)
		return self:_processReceipt(...)
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(...)
		self:_onPurchaseGamepass(...)
	end)

	MarketplaceService.PromptProductPurchaseFinished:Connect(function(player: Player)
		clearGiftTracking(player)
	end)

	self.RequestProductPurchase:Connect(function(player: Player, data: { any })
		if not validatePlayer(player) then
			return
		end
		self:AttemptProductPurchase(player, table.unpack(data))
	end)

	self.RequestGamepassPurchase:Connect(function(player: Player, data: { any })
		if not validatePlayer(player) then
			return
		end
		self:AttemptGamepassPurchase(player, table.unpack(data))
	end)
end

function ShopManager:OnStart() end

return ShopManager
