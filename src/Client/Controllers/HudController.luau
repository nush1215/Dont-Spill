-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Spr = require(Packages.Spr)

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local HudController = {
	_hudFramesOrigPos = {},
}

function HudController:ShowHud()
	for frame, origPos in self._hudFramesOrigPos do
		Spr.target(frame, 0.8, 2.5, {
			Position = origPos,
		})
	end
end

function HudController:HideHud()
	local ui = self.UI

	Spr.target(ui.Left, 0.8, 2, {
		Position = UDim2.fromScale(-0.3, 0.5),
	})

	Spr.target(ui.BottomLeft, 0.8, 2, {
		Position = UDim2.fromScale(0.205, 1.3),
	})

	Spr.target(ui.Right, 0.8, 2, {
		Position = UDim2.fromScale(1.1, 0.5),
	})
end

function HudController:OnInit()
	self.UI = PlayerGui:WaitForChild("HudUI")

	for _, frame in self.UI:GetChildren() do
		if frame:IsA("Frame") then
			self._hudFramesOrigPos[frame] = frame.Position
		end
	end
end

return HudController
