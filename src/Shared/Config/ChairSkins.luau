-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPack = game:GetService("StarterPack")

-- Assets
local Assets = ReplicatedStorage.Assets
local Chairs = Assets.Chairs

-- Shared
local Shared = ReplicatedStorage.Shared
local RandomUtil = require(Shared.RandomUtil)

--
export type Skin = {
	Id: string,
	Name: string,
	Model: Model,
	Price: number,
	Rarity: "Common" | "Uncommon" | "Rare" | "Legendary" | "Limited" | "Exclusive",
	Hide: boolean?, -- whether to hide the chair from the shop
	IsExclusive: boolean?,
	ExclusiveTag: string?, -- the tag required on the player to access this skin
	PackName: string?, --
	ExclusivePurchaseCallback: ((player: Player) -> ())?, -- function to call when the player attempts to purchase this skin
}

local RARITY_ODDS = {
	{ "Common", 40 },
	{ "Uncommon", 35 },
	{ "Rare", 15 },
	{ "Legendary", 7 },
	{ "Limited", 3 },
}

local ShopManager
if RunService:IsServer() then
	ShopManager = require(ServerScriptService.Server.Managers.ShopManager)
end

local ChairSkins = {}
ChairSkins.Data = {
	------------- [[ COMMON CHAIRS ]] -------------
	{
		Id = "BlackChair",
		Name = "Black Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "BlueChair",
		Name = "Blue Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "BrownChair",
		Name = "Brown Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "EggplantChair",
		Name = "Eggplant Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "GrayChair",
		Name = "Gray Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "CyanChair",
		Name = "Cyan Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "GreenChair",
		Name = "Green Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "OrangeChair",
		Name = "Orange Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "PinkChair",
		Name = "Pink Chair",
		Rarity = "Common",
		Price = 30,
	},

	{
		Id = "RubyChair",
		Name = "Ruby Chair",
		Rarity = "Common",
		Price = 50,
	},

	{
		Id = "WhiteChair",
		Name = "White Chair",
		Rarity = "Common",
		Price = 50,
	},

	{
		Id = "YellowChair",
		Name = "Yellow Chair",
		Rarity = "Common",
		Price = 30,
	},

	------------- [[ UNCOMMON CHAIRS ]] -------------
	{
		Id = "BrightBlue",
		Name = "Bright Blue",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "BrightRed",
		Name = "Bright Red",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "BrightWhite",
		Name = "Bright White",
		Rarity = "Uncommon",
		Price = 180,
	},

	{
		Id = "Dark",
		Name = "Dark",
		Rarity = "Uncommon",
		Price = 150,
	},

	{
		Id = "DarkBrown",
		Name = "Dark Brown",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "DeepViolet",
		Name = "Deep Violet",
		Rarity = "Uncommon",
		Price = 150,
	},

	{
		Id = "FreshLime",
		Name = "Fresh Lime",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "GoldenGlow",
		Name = "Golden Glow",
		Rarity = "Uncommon",
		Price = 200,
	},

	{
		Id = "LimeGreen",
		Name = "Lime Green",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "Mulberry",
		Name = "Mulberry",
		Rarity = "Uncommon",
		Price = 150,
	},

	{
		Id = "NavyBlue",
		Name = "Navy Blue",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "Orange",
		Name = "Orange",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "Persimmon",
		Name = "Persimmon",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "Plum",
		Name = "Plum",
		Rarity = "Uncommon",
		Price = 150,
	},

	{
		Id = "ReddishBrown",
		Name = "Reddish Brown",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "Teal",
		Name = "Teal",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "RosyPink",
		Name = "Rosy Pink",
		Rarity = "Uncommon",
		Price = 120,
	},

	{
		Id = "SoftBlue",
		Name = "Soft Blue",
		Rarity = "Uncommon",
		Price = 120,
	},

	------------- [[ RARE CHAIRS ]] -------------
	{
		Id = "AppleChair",
		Name = "Apple Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "BananaChair",
		Name = "Banana Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "Chair67",
		Name = "Chair 67",
		Rarity = "Rare",
		Price = 67,
	},

	{
		Id = "CoinChair",
		Name = "Coin Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "DollarChair",
		Name = "Dollar Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "ErrorChair",
		Name = "Error Chair",
		Rarity = "Rare",
		Price = 350,
	},

	{
		Id = "FieryChair",
		Name = "Fiery Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "LuckyChair",
		Name = "Lucky Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "NeonChair",
		Name = "Neon Chair",
		Rarity = "Rare",
		Price = 350,
	},

	{
		Id = "OceanChair",
		Name = "Ocean Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "PinkWhiteRabbit",
		Name = "Pink White Rabbit",
		Rarity = "Rare",
		Price = 350,
	},

	{
		Id = "PurpleWhiteRabbit",
		Name = "Purple White Rabbit",
		Rarity = "Rare",
		Price = 350,
	},

	{
		Id = "ShadowChair",
		Name = "Shadow Chair",
		Rarity = "Rare",
		Price = 450,
	},

	{
		Id = "StrawberryChair",
		Name = "Strawberry Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "SunriseChair",
		Name = "Sunrise Chair",
		Rarity = "Rare",
		Price = 350,
	},

	{
		Id = "VerdantChair",
		Name = "Verdant Chair",
		Rarity = "Rare",
		Price = 300,
	},

	{
		Id = "WhiteCat",
		Name = "White Cat",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "WhiteDog",
		Name = "White Dog",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "AngryChair",
		Name = "Angry Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "DonutChair",
		Name = "Donut Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "FireChair",
		Name = "Fire Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "HazardChair",
		Name = "Hazard Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "HeartChair",
		Name = "Heart Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "LaughChair",
		Name = "Laugh Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "LeafChair",
		Name = "Leaf Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "RoseChair",
		Name = "Rose Chair",
		Rarity = "Rare",
		Price = 400,
	},

	{
		Id = "StarChair",
		Name = "Star Chair",
		Rarity = "Rare",
		Price = 400,
	},

	------------- [[ LEGENDARY CHAIRS ]] -------------
	{
		Id = "ArcaneThrone",
		Name = "Arcane Throne",
		Rarity = "Legendary",
		Price = 1200,
	},

	{
		Id = "AscendantThrone",
		Name = "Ascendant Throne",
		Rarity = "Legendary",
		Price = 1500,
	},

	{
		Id = "BlazingThrone",
		Name = "Blazing Throne",
		Rarity = "Legendary",
		Price = 1000,
	},

	{
		Id = "BlueFlameThrone",
		Name = "Blue Flame Throne",
		Rarity = "Legendary",
		Price = 1300,
	},

	{
		Id = "CursedThrone",
		Name = "Cursed Throne",
		Rarity = "Legendary",
		Price = 1800,
	},

	{
		Id = "FrostThrone",
		Name = "Frost Throne",
		Rarity = "Legendary",
		Price = 1100,
	},

	{
		Id = "FrostlightThrone",
		Name = "Frostlight Throne",
		Rarity = "Legendary",
		Price = 1400,
	},

	{
		Id = "InfernoThrone",
		Name = "Inferno Throne",
		Rarity = "Legendary",
		Price = 1300,
	},

	{
		Id = "RadiantMajesty",
		Name = "Radiant Majesty",
		Rarity = "Legendary",
		Price = 2000,
	},

	{
		Id = "RageChair",
		Name = "Rage Chair",
		Rarity = "Legendary",
		Price = 1600,
	},

	{
		Id = "StormThrone",
		Name = "Storm Throne",
		Rarity = "Legendary",
		Price = 1100,
	},

	{
		Id = "TornadoChair",
		Name = "Tornado Chair",
		Rarity = "Legendary",
		Price = 1200,
	},

	{
		Id = "VelvetMirage",
		Name = "Velvet Mirage",
		Rarity = "Legendary",
		Price = 1800,
	},

	{
		Id = "EthercoilThrone",
		Name = "Ethercoil Throne",
		Rarity = "Legendary",
		Price = 1500,
	},

	{
		Id = "HydroSurgeThrone",
		Name = "Hydro Surge Throne",
		Rarity = "Legendary",
		Price = 1500,
	},

	{
		Id = "SurgeThrone",
		Name = "Surge Throne",
		Rarity = "Legendary",
		Price = 1500,
	},

	------------- [[ LIMITED CHAIRS ]] -------------
	{
		Id = "Stool",
		Name = "Stool",
		Rarity = "Limited",
		Price = 1000,
	},

	{
		Id = "MetalChair",
		Name = "Metal Chair",
		Rarity = "Limited",
		Price = 1500,
	},

	{
		Id = "CampingChair",
		Name = "Camping Chair",
		Rarity = "Limited",
		Price = 2200,
	},

	{
		Id = "RockingChair",
		Name = "Rocking Chair",
		Rarity = "Limited",
		Price = 3500,
	},

	{
		Id = "OfficeChair",
		Name = "Office Chair",
		Rarity = "Limited",
		Price = 6000,
	},

	{
		Id = "DeskChair",
		Name = "Desk Chair",
		Rarity = "Limited",
		Price = 10000,
	},

	{
		Id = "GamingChair",
		Name = "Gaming Chair",
		Rarity = "Limited",
		Price = 15000,
	},

	{
		Id = "Throne",
		Name = "Throne",
		Rarity = "Limited",
		Price = 30000,
	},

	------ EXCLUSIVE CHAIRS
	{
		Id = "PlasticChair",
		Name = "Plastic Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "StarterPack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "StarterPack")
		end,
	},

	{
		Id = "GoldenChair",
		Name = "Golden Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "VIP",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptGamepassPurchase(player, "VIP")
		end,
	},

	{
		Id = "MagicalThrone",
		Name = "Magical Throne",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "SpinWheelGrandPrize",
		ExclusivePurchaseCallback = function(player: Player) end,
	},

	{
		Id = "VoidThrone",
		Name = "Void Throne",
		Rarity = "Exclusive",
		ExclusiveTag = "SpinWheelGrandPrize2",
		ExclusivePurchaseCallback = function(player: Player) end,
	},

	{
		Id = "CandyCaneChair",
		Name = "Candy Cane Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "ChristmasPack",
		PackName = "Christmas Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "ChristmasPack")
		end,
	},

	{
		Id = "FrostyChair",
		Name = "Frosty Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "ChristmasPack",
		PackName = "Christmas Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "ChristmasPack")
		end,
	},

	{
		Id = "GingerBreadChair",
		Name = "Ginger Bread Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "ChristmasPack",
		PackName = "Christmas Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "ChristmasPack")
		end,
	},

	{
		Id = "BlueAuraChair",
		Name = "Blue Aura Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "AuraPack",
		PackName = "Aura Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "AuraPack")
		end,
	},

	{
		Id = "RedAuraChair",
		Name = "Red Aura Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "AuraPack",
		PackName = "Aura Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "AuraPack")
		end,
	},

	{
		Id = "YellowAuraChair",
		Name = "Yellow Aura Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "AuraPack",
		PackName = "Aura Pack",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "AuraPack")
		end,
	},

	{
		Id = "NewYear2026Chair",
		Name = "New Year 2026 Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "NewYear2026Chair",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "NewYear2026Chair")
		end,
	},

	{
		Id = "Chair67Premium",
		Name = "Chair 67 Premium",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "Chair67Premium",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "Chair67Premium")
		end,
	},

	{
		Id = "RainbowChair",
		Name = "Rainbow Chair",
		Rarity = "Exclusive",
		IsExclusive = true,
		ExclusiveTag = "RainbowChair",
		ExclusivePurchaseCallback = function(player: Player)
			ShopManager:AttemptProductPurchase(player, "RainbowChair")
		end,
	},

	{
		Id = "YearOfTheHorse",
		Name = "Year Of The Horse Chair",
		Rarity = "Limited",
	},
} :: { Skin }

ChairSkins.Priority = { --- Layout order
	Exclusive = 1,
	Limited = 2,
	Legendary = 3,
	Rare = 4,
	Uncommon = 5,
	Common = 6,
}

for _, v in ChairSkins.Data do
	local chair = Chairs:FindFirstChild(v.Id, true)
	if not chair then
		warn("Chair skin model not found for ID:", v.Id)
		continue
	end

	v.Model = chair
end

table.freeze(ChairSkins.Data)

--
function ChairSkins.GetChairFromId(id: string): Skin?
	for _, v in ChairSkins.Data do
		if v.Id == id then
			return v
		end
	end

	return nil
end

function ChairSkins.GetChairFromExclusiveTag(tag: string): Skin?
	for _, v in ChairSkins.Data do
		if v.IsExclusive and v.ExclusiveTag == tag then
			return v
		end
	end

	return nil
end

function ChairSkins.GetAllChairsFromExclusiveTag(tag: string): { Skin }
	local chairs: { Skin } = {}

	for _, v in ChairSkins.Data do
		if v.IsExclusive and v.ExclusiveTag == tag then
			table.insert(chairs, v)
		end
	end

	return chairs
end

function ChairSkins.GetExclusiveChairs(): { Skin }
	local exclusiveChairs: { Skin } = {}

	for _, v in ChairSkins.Data do
		if v.IsExclusive then
			table.insert(exclusiveChairs, v)
		end
	end

	return exclusiveChairs
end

function ChairSkins.GetChairsByRarity(rarity: string): { Skin }
	local chairs = {}

	for _, v in ChairSkins.Data do
		if v.Rarity == rarity and not v.Hide then
			table.insert(chairs, v)
		end
	end

	return chairs
end

function ChairSkins.GetRandomChairsByAmount(amount: number, seed: number): { string }
	local randomChairs = {}
	local function getChair(i)
		local rarity = RandomUtil.GetResultFromWeight(
			RARITY_ODDS,
			seed * i * RandomUtil.GetRandomIntFromMinMax(1, 10000, seed + (game.PlaceId / 2) * i)
		)
		local chairs = ChairSkins.GetChairsByRarity(rarity)

		-- make sure we got chairs with the rarity (check for empty table, not just nil)
		if not chairs or #chairs == 0 then
			return getChair(i)
		end

		local randomChair = chairs[RandomUtil.GetRandomIntFromMinMax(
			1,
			#chairs,
			seed * i * RandomUtil.GetRandomIntFromMinMax(1, 10000, seed + (game.PlaceId / 2) * i)
		)]

		-- Make sure we got a chair
		if not randomChair then
			return getChair(i)
		end

		-- Make sure we don't get the same chair twice
		if table.find(randomChairs, randomChair.Id) then
			return getChair(i)
		end

		table.insert(randomChairs, randomChair.Id)
	end

	for i = 1, amount do
		getChair(i)
	end

	return randomChairs
end

return ChairSkins
