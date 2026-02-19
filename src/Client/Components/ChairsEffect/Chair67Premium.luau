-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

--
local Chair67Premium = Component.new({
	Tag = script.Name,
})

function Chair67Premium:Construct()
	local chair = self.Instance

	if chair:IsA("Player") or chair:FindFirstChildOfClass("Humanoid") then
		return
	end

	local fx = chair.FX
	local head = fx.Head
	local leftHand = fx.LeftHand
	local rightHand = fx.RightHand

	local headInitialPivot = head:GetPivot()

	self._cleaner = Trove.new()

	self._cleaner:Add(RunService.RenderStepped:Connect(function(dt)
		local headOffset = math.sin(tick() * 4.5) * 0.25

		-- Linear interpolation from -maxRange to maxRange
		local maxRange = 0.025 -- Change this to adjust the range (-maxRange to maxRange)
		local period = 0.8 -- Change this to adjust speed (seconds for full cycle)
		local t = (tick() % (period * 2)) / period -- 0 to 2
		local normalized = t <= 1 and t or 2 - t -- 0 to 1 to 0 (ping-pong)
		local lOffset = (normalized * 2 - 1) * maxRange -- -maxRange to maxRange
		local rOffset = -lOffset

		leftHand:PivotTo(leftHand:GetPivot() * CFrame.new(0, lOffset, 0))
		rightHand:PivotTo(rightHand:GetPivot() * CFrame.new(0, rOffset, 0))
		head:PivotTo(head:GetPivot() * CFrame.Angles(0, 0, math.rad(headOffset)))
	end))
end

return Chair67Premium
