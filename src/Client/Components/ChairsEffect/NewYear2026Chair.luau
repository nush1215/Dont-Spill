-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Component = require(ReplicatedStorage.Packages.Component)
local Trove = require(ReplicatedStorage.Packages.Trove)

--
local EffectsController = require(script.Parent.Parent.Parent.Controllers.EffectsController)

--
local NewYear2026Chair = Component.new({
	Tag = script.Name,
})

function NewYear2026Chair:Construct()
	local chair = self.Instance

	if chair:IsA("Player") or chair:FindFirstChildOfClass("Humanoid") then
		return
	end

	self._cleaner = Trove.new()

	self._cleaner:Add(task.spawn(function()
		while true do
			EffectsController:RunEffect("Fireworks", {
				chair, -- origin: Model
				math.random(3, 7), -- amount: number of fireworks
				{ MinSpread = -8, MaxSpread = 8 }, -- spreadDistance
				{ MinHeight = 5, MaxHeight = 10 }, -- heightDistance
				10, -- speed (optional, uses DEFAULT_SPEED if not provided)
			})

			task.wait(math.random(2, 3))
		end
	end))
end

function NewYear2026Chair:Stop()
	self._cleaner:Clean()
end

return NewYear2026Chair
