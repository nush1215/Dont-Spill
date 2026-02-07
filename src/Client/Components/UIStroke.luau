-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local UIStroke = Component.new({
	Tag = script.Name,
})

local ORIGINAL_HEIGHT = 1080

function UIStroke:Construct()
	--
	local camera = workspace.CurrentCamera
	local stroke: UIStroke = self.Instance

	if stroke:HasTag("IgnoreUIStroke") then
		return
	end

	if stroke.StrokeSizingMode == Enum.StrokeSizingMode.ScaledSize then
		return
	end

	--
	local defaultThickness = stroke.Thickness
	local ratio = defaultThickness / ORIGINAL_HEIGHT

	stroke.Thickness = math.ceil(camera.ViewportSize.Y * ratio)
	camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
		stroke.Thickness = math.ceil(camera.ViewportSize.Y * ratio)
	end)
end

return UIStroke
