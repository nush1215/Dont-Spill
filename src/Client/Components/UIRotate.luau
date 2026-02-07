-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local UIRotate = Component.new({
	Tag = script.Name,
})

function UIRotate:Construct()
	local uiElement = self.Instance
	local speed = uiElement:GetAttribute("Speed") or 0.25

	RunService.Heartbeat:Connect(function(deltaTime)
		uiElement.Rotation += speed * 60 * deltaTime
	end)
end

return UIRotate
