-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local ImagePan = Component.new({
	Tag = script.Name,
})

function ImagePan:Construct()
	local image: ImageLabel = self.Instance

	local panSpeed = image:GetAttribute("PanSpeed") or 0.025
	local panDirection = image:GetAttribute("PanDirection") or Vector2.new(-1, -1)

	local offset = Vector2.new(0, 0)

	RunService.RenderStepped:Connect(function(deltaTime)
		offset = offset + panDirection * panSpeed * deltaTime
		image.Position = UDim2.new(-offset.X % 1, 0, -offset.Y % 1, 0)
	end)
end

return ImagePan
