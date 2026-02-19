-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Replica = require(Packages.Replica)
local Sift = require(Packages.Sift)
local Trove = require(Packages.Trove)
local Spr = require(Packages.Spr)

-- Shared
local Shared = ReplicatedStorage.Shared
local ChairSkins = require(Shared.Config.ChairSkins)
local GameColors = require(Shared.GameColors)

-- Assets
local Assets = ReplicatedStorage.Assets
local UI = Assets.UI

-- Class
local Class = script.Parent.Parent.Class
local Viewport = require(Class.Viewport)

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--
local PlayerDataController
local NavigationUIController
local UIController
local ShopController

--
local ChairSkinController = {
	PurchaseChairSkinEvent = BridgeNet2.ReferenceBridge("PurchaseChairSkin"),
	EquipChairSkinEvent = BridgeNet2.ReferenceBridge("EquipChairSkin"),
	UnequipChairSkinEvent = BridgeNet2.ReferenceBridge("UnequipChairSkin"),
}

-- Setups the display
function ChairSkinController:_setupDisplays()
	--
	local chairSkinDisplays = workspace:WaitForChild("ChairSkinDisplays")

	-- Sets up a chair skin display for the specified skin
	local prompts = {}
	local ownedSkins = {}

	--
	local function setupChairSkinDisplay(skinId: ChairSkins.Skin, platform: BasePart)
		--
		local skinData = ChairSkins.GetChairFromId(skinId)
		if not skinData then
			warn(`Invalid SkinId on ChairSkinDisplay: {skinId}`)
			return
		end

		--
		local modelClone = skinData.Model:Clone()
		local heightOffset = modelClone:GetAttribute("HeightOffset") or 0

		modelClone:AddTag(skinData.Id)
		modelClone:ScaleTo(1.2)
		modelClone.Parent = platform
		modelClone:PivotTo(platform:GetPivot() * CFrame.new(0, (modelClone:GetExtentsSize().Y / 2) + heightOffset, 0))

		modelClone:SetAttribute("SpinSpeed", 0.25)
		modelClone:AddTag("PartSpin")

		local price = skinData.IsExclusive and ShopController:GetPrice(skinData.ExclusiveTag) or skinData.Price
		price = skinData.IsExclusive and `{utf8.char(0xE002)}{price}` or `${price}`

		local color = GameColors.RARITY_COLORS[skinData.Rarity]

		-- Setup detail ui and prompt
		local chairSkinDetails = UI.ChairSkinDetails:Clone()
		chairSkinDetails.UI.Price.Text = price
		chairSkinDetails.UI.Rarity.Text = skinData.Rarity:upper()
		chairSkinDetails.UI.Rarity.TextColor3 = color or Color3.fromRGB(255, 255, 255)
		chairSkinDetails.UI.Rarity.ExclusiveGradient.Enabled = skinData.IsExclusive
		chairSkinDetails.Parent = platform

		--
		local promptAttachment = Instance.new("Attachment")
		promptAttachment.CFrame = CFrame.new(0, 2.77, 0)
		promptAttachment.Parent = platform

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Purchase"
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.ObjectText = skinData.Name
		prompt.Parent = promptAttachment

		prompt.Triggered:Connect(function()
			self.PurchaseChairSkinEvent:Fire(skinData.Id)
		end)

		prompts[skinId] = prompt
	end

	local function setupPackDisplay(packId: string, platform: BasePart)
		local chairPackData = ChairSkins.GetAllChairsFromExclusiveTag(packId)
		if #chairPackData == 0 then
			warn(`No chairs found for pack: {packId}`)
			return
		end

		local currentIndex = 1
		local currentModel: Model? = nil
		local chairPackSample = chairPackData[1]

		local function displayChair(skinData: ChairSkins.Skin)
			-- Clone and setup new model
			local modelClone = skinData.Model:Clone()
			local heightOffset = modelClone:GetAttribute("HeightOffset") or 0

			modelClone:ScaleTo(1.2)
			modelClone.Parent = platform

			if currentModel then
				modelClone:PivotTo(currentModel:GetPivot())
				currentModel:Destroy()
			else
				modelClone:PivotTo(
					platform:GetPivot() * CFrame.new(0, (modelClone:GetExtentsSize().Y / 2) + heightOffset, 0)
				)
			end

			modelClone:SetAttribute("SpinSpeed", 0.25)
			modelClone:AddTag("PartSpin")

			currentModel = modelClone
		end

		-- Initial display
		displayChair(chairPackData[currentIndex])

		-- Setup price and details UI
		local price = ShopController:GetPrice(packId)
		local color = GameColors.RARITY_COLORS["Exclusive"]

		local chairSkinDetails = UI.ChairSkinDetails:Clone()
		chairSkinDetails.UI.AlwaysOnTop = packId == "AuraPack" -- cause the aura is too much
		chairSkinDetails.UI.Price.Text = `{utf8.char(0xE002)}{price}`
		chairSkinDetails.UI.Rarity.Text = "EXCLUSIVE"
		chairSkinDetails.UI.Rarity.TextColor3 = color or Color3.fromRGB(255, 255, 255)
		chairSkinDetails.UI.Rarity.ExclusiveGradient.Enabled = true
		chairSkinDetails.Parent = platform

		-- Setup prompt
		local promptAttachment = Instance.new("Attachment")
		promptAttachment.CFrame = CFrame.new(0, 2.77, 0)
		promptAttachment.Parent = platform

		local prompt = Instance.new("ProximityPrompt")
		prompt.ActionText = "Purchase Pack"
		prompt.RequiresLineOfSight = false
		prompt.Style = Enum.ProximityPromptStyle.Custom
		prompt.ObjectText = chairPackSample.PackName
		prompt.Parent = promptAttachment

		prompt.Triggered:Connect(function()
			self.PurchaseChairSkinEvent:Fire(chairPackSample.Id)
		end)

		-- Rotate through chairs every 10 seconds
		task.spawn(function()
			while true do
				task.wait(10)
				currentIndex = (currentIndex % #chairPackData) + 1
				displayChair(chairPackData[currentIndex])
			end
		end)
	end

	-- Setup the hardcoded display
	for _, v in chairSkinDisplays.HardcodeDisplay:GetChildren() do
		setupChairSkinDisplay(v.Name, v)
	end

	-- Setup the pack display
	for _, v in chairSkinDisplays.Packs:GetChildren() do
		setupPackDisplay(v.Name, v)
	end

	-- Setup the displays that is on the shop
	local chairShopCleaner = Trove.new()

	local function updatePrompts()
		for skinId, prompt in prompts do
			if ownedSkins[skinId] then
				prompt.ActionText = "Owned"
			else
				prompt.ActionText = "Purchase"
			end
		end
	end

	local function setupChairShop(chairs: { ChairSkins.Skin })
		-- cleanup previous displays
		chairShopCleaner:Clean()

		-- setup the new ones
		for i, platform in chairSkinDisplays.RandomDisplays:GetChildren() do
			setupChairSkinDisplay(chairs[i], platform)

			chairShopCleaner:Add(function()
				for _, v in platform:GetChildren() do
					v:Destroy()
				end

				prompts[chairs[i]] = nil
			end)
		end

		updatePrompts()
	end

	-- Setup the exclusive owned skins
	for _, v in ChairSkins.GetExclusiveChairs() do
		if LocalPlayer:HasTag(v.ExclusiveTag) then
			ownedSkins[v.Id] = true
		else
			CollectionService:GetInstanceAddedSignal(v.ExclusiveTag):Connect(function(player: Player)
				if player == LocalPlayer then
					ownedSkins[v.Id] = true
					updatePrompts()
				end
			end)
		end
	end

	-- Setup the replic
	Replica.OnNew("ChairShop", function(replica)
		-- Setup chair display
		setupChairShop(replica.Data.Chairs)
		replica:OnSet({ "Chairs" }, function(newChairs)
			setupChairShop(newChairs)
		end)
	end)

	PlayerDataController:GetReplica():andThen(function(replica)
		-- Update prompts
		ownedSkins = Sift.Dictionary.merge(ownedSkins, replica.Data.OwnedChairSkins)
		updatePrompts()
		replica:OnSet({ "OwnedChairSkins" }, function(newOwnedChairSkins)
			ownedSkins = Sift.Dictionary.merge(ownedSkins, newOwnedChairSkins)
			updatePrompts()
		end)
	end)
end

-- Setups the ui
function ChairSkinController:_setupUI()
	--
	local ui = self.UI
	local holder = ui.Holder
	local templates = ui.Templates
	local container = holder.Container.ScrollingFrame

	--
	local ownedSkins = {}
	local equippedSkin = ""

	-- Create a chair skin frame for the specified skin
	local function createChairSkinFrame(skinId: string)
		local skinData = ChairSkins.GetChairFromId(skinId)
		if not skinData then
			warn(`Invalid SkinId on ChairSkinFrame: {skinId}`)
			return
		end

		local color = GameColors.RARITY_FRAME_COLORS[skinData.Rarity]

		--  Craete template
		local template = templates.ChairSkinTemplate:Clone()
		template.Name = skinId
		template.Holder.Title.Text = skinData.Name:upper()
		template.LayoutOrder = ChairSkins.Priority[skinData.Rarity]

		-- Setup viewport
		Viewport.new(skinData.Model:Clone(), template.Holder.ViewportFrame, CFrame.new(), true, holder)

		-- Set colors
		template.Holder.BackgroundColor3 = color.BackgroundColor
		template.Holder.UIStroke.Color = color.StrokeColor
		template.Holder.Equip.UIStroke.Color = color.TextStrokeColor
		template.Holder.Title.UIStroke.Color = color.TextStrokeColor

		template.Visible = true
		template.Parent = container

		UIController:BindButtonClick(template.Holder.Button, function()
			if equippedSkin == skinId then
				self.UnequipChairSkinEvent:Fire()
			else
				self.EquipChairSkinEvent:Fire(skinId)
			end
		end, true, false, { ShowFrame = template.Holder })
	end

	-- Refreshes the skin container to show all of the skins
	local function refreshSkinContainer()
		for skinId, _ in ownedSkins do
			local skinData = ChairSkins.GetChairFromId(skinId)
			local skinFrame = container:FindFirstChild(skinId)
			if skinFrame then
				local isEquipped = equippedSkin == skinId

				skinFrame.Holder.Equip.Text = isEquipped and "Equipped" or "Equip"
				skinFrame.Holder.Equip.TextColor3 = isEquipped and GameColors.EQUIPPED_COLORS.TextColor
					or Color3.fromRGB(255, 255, 255)
				skinFrame.Holder.Equip.UIStroke.Color = isEquipped and GameColors.EQUIPPED_COLORS.TextStrokeColor
					or GameColors.RARITY_FRAME_COLORS[skinData.Rarity].TextStrokeColor
			else
				createChairSkinFrame(skinId)
			end
		end

		local totalSkins = #ChairSkins.Data
		local unlockedSkins = Sift.Dictionary.count(ownedSkins)

		holder.Unlocked.Text = `UNLOCKED SKINS: {unlockedSkins}/{totalSkins}`
	end

	-- Setup the exclusive owned skins
	for _, v in ChairSkins.GetExclusiveChairs() do
		if LocalPlayer:HasTag(v.ExclusiveTag) then
			ownedSkins[v.Id] = true
		else
			CollectionService:GetInstanceAddedSignal(v.ExclusiveTag):Connect(function(player: Player)
				if player == LocalPlayer then
					ownedSkins[v.Id] = true
					refreshSkinContainer()
				end
			end)
		end
	end

	-- Update the owned skins
	PlayerDataController:GetReplica():andThen(function(replica)
		ownedSkins = Sift.Dictionary.merge(ownedSkins, replica.Data.OwnedChairSkins)
		equippedSkin = replica.Data.EquippedChairSkin

		replica:OnSet({ "OwnedChairSkins" }, function(newOwnedChairSkins)
			ownedSkins = Sift.Dictionary.merge(ownedSkins, newOwnedChairSkins)
			refreshSkinContainer()
		end)

		replica:OnSet({ "EquippedChairSkin" }, function(newEquippedChairSkin)
			equippedSkin = newEquippedChairSkin
			refreshSkinContainer()
		end)

		refreshSkinContainer()
	end)

	-- Setup the buttons
	NavigationUIController:BindButton("ChairSkin", function()
		UIController:OpenFrame(holder)
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = -10 })
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = 0 })
	end)

	UIController:BindButtonClick(holder.Header.Exit, function()
		UIController:CloseFrame(holder)
	end, true)
end

--
function ChairSkinController:OnInit()
	PlayerDataController = require(script.Parent.PlayerDataController)
	ShopController = require(script.Parent.ShopController)
	NavigationUIController = require(script.Parent.NavigationUIController)
	UIController = require(script.Parent.UIController)

	self.UI = PlayerGui:WaitForChild("ChairSkinUI")
end

function ChairSkinController:OnStart()
	task.spawn(ChairSkinController._setupDisplays, self)
	task.spawn(ChairSkinController._setupUI, self)
end

return ChairSkinController
