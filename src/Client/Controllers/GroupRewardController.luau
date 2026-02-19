-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Spr = require(Packages.Spr)

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local NavigationUIController
local UIController

--
local GroupRewardController = {
	ClaimRewardEvent = BridgeNet2.ReferenceBridge("ClaimGroupReward"),
}

function GroupRewardController:_setupUI()
	local ui = self.UI
	local holder = ui.Holder

	UIController:BindButtonClick(holder.Claim, function()
		self.ClaimRewardEvent:Fire()
	end, true)

	UIController:BindButtonClick(holder.Header.Exit, function()
		UIController:OpenFrame(holder)
	end, true)

	NavigationUIController:BindButton("GroupReward", function()
		UIController:OpenFrame(holder)
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = -10 })
	end, function(button: GuiButton)
		Spr.target(button.Icon, 0.6, 4, { Rotation = 0 })
	end)
end

function GroupRewardController:OnInit()
	NavigationUIController = require(script.Parent.NavigationUIController)
	UIController = require(script.Parent.UIController)

	self.UI = PlayerGui:WaitForChild("GroupRewardUI")
end

function GroupRewardController:OnStart()
	task.spawn(GroupRewardController._setupUI, self)
end

return GroupRewardController
