-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local RainbowUI = Component.new({
	Tag = script.Name,
})

function RainbowUI:Construct()
	--
	local ui = self.Instance

	--
	local rainbowGradient = ui:IsA("UIStroke") and ui or Instance.new("UIGradient")
	rainbowGradient.Parent = ui

	local time = ui:GetAttribute("RainbowSpeed") or 2 -- amount of time it takes to get from 0 to 1
	local range = 10 -- amount of colors

	--
	RunService.Heartbeat:Connect(function()
		local loop = tick() % time / time
		local colors = {}

		for i = 1, range + 1, 1 do
			z = Color3.fromHSV(loop - ((i - 1) / range), 1, 1)

			if loop - ((i - 1) / range) < 0 then
				z = Color3.fromHSV((loop - ((i - 1) / range)) + 1, 1, 1)
			end

			local d = ColorSequenceKeypoint.new((i - 1) / range, z)
			table.insert(colors, d)
		end

		rainbowGradient.Color = ColorSequence.new(colors)
	end)
end

return RainbowUI
