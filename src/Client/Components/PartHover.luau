-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

-- Constants
local HOVER_AMPLITUDE = 0.01 -- How high/low the part moves (in studs)
local HOVER_SPEED = 3 -- How fast the hover animation plays (cycles per second)
local HOVER_AXIS = Vector3.new(0, 1, 0) -- Which axis to hover on (Y-axis by default)

--
local PartHover = Component.new({
	Tag = script.Name,
})

function PartHover:Construct()
	--
	local part = self.Instance

	--
	self._cleaner = Trove.new()

	--
	local canSpin = part:GetAttribute("CanSpin") or false
	local spinSpeed = canSpin and (part:GetAttribute("SpinSpeed") or 1) or 0

	--
	self._cleaner:Add(RunService.RenderStepped:Connect(function(deltaTime)
		local offset = HOVER_AXIS * math.sin(tick() * HOVER_SPEED) * HOVER_AMPLITUDE
		local newCFrame = part.CFrame * CFrame.new(offset) * CFrame.Angles(0, math.rad(spinSpeed), 0)

		part:PivotTo(newCFrame)
	end))
end

function PartHover:Stop()
	self._cleaner:Destroy()
end

return PartHover
