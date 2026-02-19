-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Trove = require(Packages.Trove)

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local PlayerDataController
local ShopController
local UIController

--
local StreakController = {
	RestoreStreakEvent = BridgeNet2.ReferenceBridge("RestoreStreak"),
	RejectRestoreStreakEvent = BridgeNet2.ReferenceBridge("RejectRestoreStreak"),
}

function StreakController:OpenRestoreStreak(previousStreak: number)
	--
	local ui = self.UI
	local holder = ui.Holder

	--
	local cleaner = Trove.new()

	--
	local firstPurchaseOfTheDayTime = PlayerDataController:GetKey("FirstPurchaseOfTheDayTime")
	local restoreStreakProduct = "RestoreStreak"

	if
		firstPurchaseOfTheDayTime
		and firstPurchaseOfTheDayTime.RestoreStreak
		and os.time() > firstPurchaseOfTheDayTime.RestoreStreak
	then
		restoreStreakProduct = "FirstRestoreStreakOfTheDay"
	else
		restoreStreakProduct = "RestoreStreak"
	end
	local productData = ShopController:GetProductFromId(restoreStreakProduct)

	-- Setup text
	holder.Title.Text = `You lost your <font color="#ffbe18">{previousStreak} streak</font>, want to get it back?`
	holder.Choices.Yes.Icon.Title.Text = previousStreak
	holder.Choices.Yes.Deal.Visible = restoreStreakProduct == "FirstRestoreStreakOfTheDay"

	--
	cleaner:Add(UIController:BindButtonClick(holder.Choices.Yes, function()
		ShopController:PromptProductPurchaseFromId(restoreStreakProduct)
	end, true))

	cleaner:Add(UIController:BindButtonClick(holder.Choices.No, function()
		UIController:CloseFrame(holder)
		self.RejectRestoreStreakEvent:Fire()
	end, true))

	--
	UIController:OpenFrame(holder)

	--
	cleaner:Add(task.spawn(function()
		while true do
			holder.Vignette.ImageTransparency = 0.7 + math.sin(tick() * 4) * 0.1
			task.wait()
		end
	end))

	cleaner:Add(
		MarketplaceService.PromptProductPurchaseFinished:Connect(function(_, productId: number, wasPurchased: boolean)
			if productId == productData.ProductId and wasPurchased then
				UIController:CloseFrame(holder)
			end
		end)
	)
end

function StreakController:OnInit()
	PlayerDataController = require(script.Parent.PlayerDataController)
	ShopController = require(script.Parent.ShopController)
	UIController = require(script.Parent.UIController)

	self.UI = PlayerGui:WaitForChild("GetStreakBackUI")
end

function StreakController:OnStart()
	self.RestoreStreakEvent:Connect(function(previousStreak: number)
		self:OpenRestoreStreak(previousStreak)
	end)
end

return StreakController
