--[[
    Okay ts be the handler for the navigation UI, the buttons you see on the side of the screen like those shop button etc etc.
]]

-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local ShopController
local UIController

--
local NavigationUIController = {}

-- Binds a function to a button in the navigation ui
function NavigationUIController:BindButton(
	buttonName: string,
	callback: () -> (),
	onHoverCallback: (() -> ())?,
	onHoverEndCallback: (() -> ())?
)
	--
	local ui = self.UI
	local button = ui:FindFirstChild(buttonName, true)
	if not button or not button:IsA("GuiButton") then
		warn(`Button {buttonName} not found in NavigationUI`)
		return
	end

	--
	UIController:BindButtonClick(button, callback, true)

	button.MouseEnter:Connect(function()
		if onHoverCallback then
			onHoverCallback(button)
		end
	end)

	button.MouseLeave:Connect(function()
		if onHoverEndCallback then
			onHoverEndCallback(button)
		end
	end)

	return button
end

--
function NavigationUIController:OnInit()
	--
	ShopController = require(script.Parent.ShopController)
	UIController = require(script.Parent.UIController)

	self.UI = PlayerGui:WaitForChild("HudUI")
end

function NavigationUIController:OnStart() end

return NavigationUIController
