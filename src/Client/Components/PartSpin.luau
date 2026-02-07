-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local PartSpin = Component.new({
	Tag = script.Name,
})

function PartSpin:Construct()
	local part: BasePart = self.Instance
	local spinDirection = part:GetAttribute("SpinDirection") or Vector3.new(0, 1, 0)
	local spinSpeed = part:GetAttribute("SpinSpeed") or 1

	--
	RunService.RenderStepped:Connect(function(deltaTime)
		part:PivotTo(
			part:GetPivot()
				* CFrame.Angles(
					spinDirection.X * spinSpeed * deltaTime,
					spinDirection.Y * spinSpeed * deltaTime,
					spinDirection.Z * spinSpeed * deltaTime
				)
		)
	end)
end

return PartSpin
