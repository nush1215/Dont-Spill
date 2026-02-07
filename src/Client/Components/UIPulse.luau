-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local UIPulse = Component.new({
	Tag = script.Name,
})

function UIPulse:Construct()
	local ui = self.Instance
	local uiScale = ui:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = ui
	end

	local pulseScale = ui:GetAttribute("PulseScale") or 1.1
	local pulseDuration = ui:GetAttribute("PulseDuration") or 0.5

	local tweenInfo = TweenInfo.new(pulseDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true)
	local pulseTween = TweenService:Create(uiScale, tweenInfo, { Scale = pulseScale })
	pulseTween:Play()
end

return UIPulse
