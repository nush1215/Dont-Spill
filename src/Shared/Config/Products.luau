-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

if RunService:IsServer() then
end

--
export type Product = {
	Id: string,
	Name: string,
	Type: "Core" | "Troll" | "Currency",
	Description: string,
	PurchaseOnce: boolean,
	Icon: string,
	ProductId: number,
	CurrencyPrice: number?,
	Value: number?, -- this is optional mostly used for reference how much X amount an X thing is
	Callback: (player: Player, toGift: Player?) -> ()?,
}

local Products = {}
Products.Data = {}
table.freeze(Products.Data)

function Products.GetProductFromId(id: string): Product?
	for _, v in Products.Data do
		if v.Id == id then
			return v
		end
	end

	return nil
end

function Products.GetProductFromProductId(productId: number): Product?
	for _, v in Products.Data do
		if v.ProductId == productId then
			return v
		end
	end

	return nil
end

function Products.GetProductsByType(productType: "Core" | "Troll" | "Currency"): { Product }
	local products = {}
	for _, v in Products.Data do
		if v.Type == productType then
			table.insert(products, v)
		end
	end

	return products
end

function Products.GetProducts(): { Product }
	return Products.Data
end

return Products
