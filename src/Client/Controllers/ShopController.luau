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

-- Shared
local Shared = ReplicatedStorage.Shared
local Products = require(Shared.Config.Products)
local Gamepasses = require(Shared.Config.Gamepasses)
local GuiUtil = require(Shared.GuiUtil)

--
local PlayerDataController
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

function ShopController:OnInit()
	--
	PlayerDataController = require(script.Parent.PlayerDataController)
end

function ShopController:OnStart() end

return ShopController
