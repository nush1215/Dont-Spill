-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

--
local GradientPart = Component.new({
	Tag = script.Name,
})

function GradientPart:Construct()
	--
	local part: BasePart = self.Instance
	local gradient1: Color3 = part:GetAttribute("Gradient1")
	local gradient2: Color3 = part:GetAttribute("Gradient2")

	--
	self._cleaner = Trove.new()
	part.Color = gradient1

	--
	self._cleaner:Add(task.spawn(function()
		while true do
			TweenService:Create(part, TweenInfo.new(4, Enum.EasingStyle.Linear), { Color = gradient2 }):Play()
			task.wait(4)
			TweenService:Create(part, TweenInfo.new(4, Enum.EasingStyle.Linear), { Color = gradient1 }):Play()
			task.wait(4)
		end
	end))

	--
	self._cleaner = Trove.new()
end

function GradientPart:Stop()
	self._cleaner:Destroy()
end

return GradientPart
