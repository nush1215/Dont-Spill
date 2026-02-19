-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnalyticsService = game:GetService("AnalyticsService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Replica = require(Packages.Replica)
local Sift = require(Packages.Sift)

-- Shared
local Shared = ReplicatedStorage.Shared
local ChairSkins = require(Shared.Config.ChairSkins)
local GuiUtil = require(Shared.GuiUtil)
local RandomUtil = require(Shared.RandomUtil)

--
local GameConfigs = require(script.Parent.Parent.Config.GameConfigs)

-- Modules
local Modules = script.Parent.Parent.Modules
local Clock = require(Modules.Clock)

--
local GameStations = workspace.GameStations

--
local PlayerDataManager
local NotificationManager
local CurrencyManager
local ShopManager

--
local ChairSkinManager = {
	PurchaseChairSkinEvent = BridgeNet2.ReferenceBridge("PurchaseChairSkin"),
	EquipChairSkinEvent = BridgeNet2.ReferenceBridge("EquipChairSkin"),
	UnequipChairSkinEvent = BridgeNet2.ReferenceBridge("UnequipChairSkin"),
}

-- Purchases a chair skin for the specified player
function ChairSkinManager:PurchaseSkin(player: Player, id: string)
	--
	local skinData = ChairSkins.GetChairFromId(id)
	if not skinData then
		warn("Invalid chair skin ID: " .. id)
		return
	end

	local hasData, ownedChairSkins = PlayerDataManager:GetPlayerDataKey(player, "OwnedChairSkins"):await()
	if not hasData then
		return
	end

	if ownedChairSkins[id] then
		NotificationManager.NotifyNormalEvent:Fire(player, {
			`You already own the <font color="#ffd400">{skinData.Name}</font>`,
		})
		return
	end

	--
	if skinData.IsExclusive then
		skinData.ExclusivePurchaseCallback(player)
		return
	end

	-- Check if player can afford it
	local canAfford, currencyNeeded = CurrencyManager:CanAfford(player, skinData.Price)
	if not canAfford then
		NotificationManager.NotifyNormalEvent:Fire(player, {
			`You need <font color="#2de200">{currencyNeeded} Bux</font> more to purchase this chair skin`,
			nil,
			"Reject",
		})

		ShopManager:PromptCurrencyPurchase(player, currencyNeeded)
		return
	end

	-- Set chair skin data
	PlayerDataManager:GetPlayerDataKey(player, "OwnedChairSkins")
		:andThen(function(ownedSkins: { [string]: boolean })
			local newTab = Sift.Dictionary.set(ownedSkins, id, true)
			PlayerDataManager:SetPlayerDataKey(player, "OwnedChairSkins", newTab)
		end)
		:andThen(function()
			CurrencyManager:DeductCurrency(player, skinData.Price)
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`Successfully Purchased <font color="#ffd400">{skinData.Name}</font>`,
				nil,
				"CurrencyPurchase",
			})

			AnalyticsService:LogCustomEvent(player, "Chair Skin Purchased", 1, {
				[Enum.AnalyticsCustomFieldKeys.CustomField01.Name] = skinData.Id,
			})

			-- Economy Analytics
			task.spawn(function()
				pcall(function()
					PlayerDataManager:GetPlayerDataKey(player, "Currency"):andThen(function(currency)
						AnalyticsService:LogEconomyEvent(
							player,
							Enum.AnalyticsEconomyFlowType.Sink,
							"Bux",
							skinData.Price,
							currency,
							Enum.AnalyticsEconomyTransactionType.Shop.Name,
							skinData.Id
						)
					end)
				end)
			end)
		end)
end

-- Gives a random chair of the specified rarity to the player
function ChairSkinManager:GiveRandomRarityChair(player: Player, rarity: string)
	local chairs = ChairSkins.GetChairsByRarity(rarity)
	if not chairs then
		warn("No chairs found for rarity: " .. rarity)
		return
	end

	local randomChair = chairs[RandomUtil.GetRandomIntFromMinMax(1, #chairs)]
	if not randomChair then
		warn("No random chair found for rarity: " .. rarity)
		return
	end

	PlayerDataManager:GetPlayerDataKey(player, "OwnedChairSkins")
		:andThen(function(ownedSkins: { [string]: boolean })
			if ownedSkins[randomChair.Id] then
				local price = randomChair.Price and randomChair.Price * 0.3 or 150
				CurrencyManager:IncrementCurrency(player, price)
				NotificationManager.NotifyNormalEvent:Fire(player, {
					`You already own the <font color="#ffd400">{randomChair.Name}</font>! You received <font color="#2de200">{price} Bux</font> as a compensation!`,
					5,
				})
				return
			end

			local newTab = Sift.Dictionary.set(ownedSkins, randomChair.Id, true)
			PlayerDataManager:SetPlayerDataKey(player, "OwnedChairSkins", newTab)
		end)
		:andThen(function()
			NotificationManager.NotifyNormalEvent:Fire(
				player,
				{ `Received <font color="#ffd400">{randomChair.Name}</font>`, 5 }
			)
		end)
end

-- Gives a specific chair skin to the player
function ChairSkinManager:GivePlayerChair(player: Player, id: string)
	local skinData = ChairSkins.GetChairFromId(id)
	if not skinData then
		warn("Invalid chair skin ID: " .. id)
		return
	end

	PlayerDataManager:GetPlayerDataKey(player, "OwnedChairSkins")
		:andThen(function(ownedSkins: { [string]: boolean })
			local newTab = Sift.Dictionary.set(ownedSkins, id, true)
			PlayerDataManager:SetPlayerDataKey(player, "OwnedChairSkins", newTab)
		end)
		:andThen(function()
			NotificationManager.NotifyNormalEvent:Fire(player, {
				`Received <font color="#ffd400">{skinData.Name}</font>`,
				5,
			})
		end)
end

-- Equips a chair skin for the specified player
function ChairSkinManager:EquipSkin(player: Player, id: string)
	local skinData = ChairSkins.GetChairFromId(id)
	if not skinData then
		warn("Invalid chair skin ID: " .. id)
		return
	end

	local hasData, equippedSkin = PlayerDataManager:GetPlayerDataKey(player, "EquippedChairSkin"):await()
	if not hasData then
		return
	end

	if equippedSkin == id then
		NotificationManager.NotifyNormalEvent:Fire(
			player,
			`<font color="#ffd400">{skinData.Name}</font> is already equipped!`
		)
		return
	end

	PlayerDataManager:GetPlayerDataKey(player, "OwnedChairSkins")
		:andThen(function(ownedSkins: { [string]: boolean })
			if not ownedSkins[id] and (not skinData.IsExclusive and player:HasTag(skinData.ExclusiveTag)) then
				NotificationManager.NotifyNormalEvent:Fire(
					player,
					`You do not own the <font color="#ffd400">{skinData.Name}</font> chair skin!`
				)
				return
			end

			PlayerDataManager:SetPlayerDataKey(player, "EquippedChairSkin", id)
		end)
		:andThen(function()
			NotificationManager.NotifyNormalEvent:Fire(player, `Equipped <font color="#ffd400">{skinData.Name}</font>`)
		end)
end

-- Unequips the chair skin for the specified player
function ChairSkinManager:UnequipSkin(player: Player)
	local hasData, equippedSkin = PlayerDataManager:GetPlayerDataKey(player, "EquippedChairSkin"):await()
	if not hasData then
		return
	end

	PlayerDataManager:SetPlayerDataKey(player, "EquippedChairSkin", "")

	local skinData = ChairSkins.GetChairFromId(equippedSkin)
	if not skinData then
		return
	end

	NotificationManager.NotifyNormalEvent:Fire(player, `Unequipped <font color="#ffd400">{skinData.Name}</font>`)
end

-- Sets the chair skin for the specified chair on the station
function ChairSkinManager:SetChairSkin(id: string, station: Model, playerSlot: number)
	--
	local chairSkinData = ChairSkins.GetChairFromId(id)
	if not chairSkinData then
		warn("Invalid chair skin ID: " .. id)
		return
	end

	--
	local chair = station.Chairs:FindFirstChild(playerSlot)
	if not chair then
		warn("Chair not found for player slot: " .. playerSlot)
		return
	end

	-- Hide the default chair
	for _, v in chair:GetChildren() do
		if v:IsA("BasePart") then
			v.Transparency = 1
		end
	end

	--
	local chairModel = chairSkinData.Model:Clone()
	chairModel:AddTag(chairSkinData.Id)
	chairModel.Name = "ChairSkin"
	chairModel:PivotTo(chair:GetPivot())
	chairModel.Parent = chair
end

-- Removes the chair skin from the specified chair on the station
function ChairSkinManager:RemoveChairSkin(station: Model, playerSlot: number)
	--
	local chair = station.Chairs:FindFirstChild(playerSlot)
	if not chair then
		warn("Chair not found for player slot: " .. playerSlot)
		return
	end

	-- Show the default chair
	for _, v in chair:GetChildren() do
		if v:IsA("BasePart") and not v:IsA("Seat") then
			v.Transparency = 0
		end
	end

	-- Remove the chair skin model
	local chairSkin = chair:FindFirstChild("ChairSkin")
	if chairSkin then
		chairSkin:Destroy()
	end
end

-- Setups the random chairs for the chair market
function ChairSkinManager:_setupRandomChairs()
	--
	local chairShopReplica = Replica.New({
		Token = Replica.Token("ChairShop"),
		Data = {
			Chairs = {},
		},
	})

	chairShopReplica:Replicate()
	self._chairShopReplica = chairShopReplica

	--
	local function changeChairs(seed: number)
		local randomChairs = ChairSkins.GetRandomChairsByAmount(GameConfigs.CHAIRS_AMOUNT_SALE, seed)
		chairShopReplica:Set({ "Chairs" }, randomChairs)

		NotificationManager.NotifyNormalEvent:Fire(BridgeNet2.PlayersExcept(CollectionService:GetTagged("InGame")), {
			`The <font color="#ffd400">Chair Shop</font> has been updated with new chairs!`,
			6,
		})

		NotificationManager.NotifyChatEvent:Fire(
			BridgeNet2.PlayersExcept(CollectionService:GetTagged("InGame")),
			`The <font color="#ffd400">Chair Shop</font> has been updated with new chairs!`
		)
	end

	-- Start the loop
	local clock = Clock.new(GameConfigs.SKIN_CHANGE_INTERVAL)
	changeChairs(clock.CurrentSeed)

	clock.Reached:Connect(function(seed: number)
		changeChairs(seed)
	end)

	-- Update the time left for change
	local skinTitleUI = workspace.Map:FindFirstChild("SkinTitleUI", true)
	clock.OnTimeChanged:Connect(function(timeLeft: number)
		skinTitleUI.Time.Text = GuiUtil.ConvertSecondsToHHMMSS(timeLeft)
	end)
end

--
function ChairSkinManager:OnInit()
	PlayerDataManager = require(script.Parent.PlayerDataManager)
	NotificationManager = require(script.Parent.NotificationManager)
	CurrencyManager = require(script.Parent.CurrencyManager)
	ShopManager = require(script.Parent.ShopManager)
end

function ChairSkinManager:OnStart()
	task.spawn(ChairSkinManager._setupRandomChairs, self)

	self.PurchaseChairSkinEvent:Connect(function(player: Player, id: string)
		self:PurchaseSkin(player, id)
	end)

	self.EquipChairSkinEvent:Connect(function(player: Player, id: string)
		self:EquipSkin(player, id)
	end)

	self.UnequipChairSkinEvent:Connect(function(player: Player)
		self:UnequipSkin(player)
	end)
end

return ChairSkinManager
