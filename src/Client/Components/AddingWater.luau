-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

--
local SoundController = require(script.Parent.Parent.Controllers.SoundController)

-- Water fill is driven by server-set attributes per match: WaterPerSec, WaterThreshold, etc.
-- Level 0..WaterThreshold maps to height 0..MaxHeight (all from server for accuracy).
local AddingWater = Component.new({
	Tag = script.Name,
})

function AddingWater:Construct()
	self._cleaner = Trove.new()

	local water = self.Instance :: BasePart
	local baseSize = water.Size

	local originalCFrame = water:GetAttribute("OriginalCFrame")
	if not originalCFrame then
		originalCFrame = water.CFrame
		water:SetAttribute("OriginalCFrame", originalCFrame)
	end

	local function updateHeight()
		local startTime = water:GetAttribute("StartTime")
		local currentLevel = water:GetAttribute("CurrentLevel")
		local waterPerSec = water:GetAttribute("WaterPerSec")
		local waterThreshold = water:GetAttribute("WaterThreshold")
		local maxHeight = water:GetAttribute("MaxHeight")

		-- Only animate when we have all server-set values (per-match pressure and threshold)
		if
			startTime == nil
			or currentLevel == nil
			or waterPerSec == nil
			or waterThreshold == nil
			or maxHeight == nil
		then
			return
		end
		if waterThreshold <= 0 then
			return
		end

		local elapsed = workspace:GetServerTimeNow() - startTime
		local level = currentLevel + elapsed * waterPerSec
		local fraction = math.clamp(level / waterThreshold, 0, 1)
		local height = fraction * maxHeight

		if height > 0 then
			water.Transparency = 0
		else
			water.Transparency = 1
		end

		water.Size = Vector3.new(height, baseSize.Y, baseSize.Z)
		water.CFrame = originalCFrame * CFrame.new(height / 2, 0, 0)
	end

	local sound = SoundController:PlaySound("Water2", water.Position)
	self._cleaner:Add(function()
		if sound then
			TweenService:Create(sound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { Volume = 0 }):Play()
			task.delay(0.2, function()
				if sound then
					sound:Destroy()
				end
			end)
		end
	end)

	updateHeight()
	self._cleaner:Add(RunService.Heartbeat:Connect(updateHeight))
end

function AddingWater:Stop()
	self._cleaner:Destroy()
end

return AddingWater
