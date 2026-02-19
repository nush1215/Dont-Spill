-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Trove = require(Packages.Trove)

--
local SoundController = require(script.Parent.Parent.Controllers.SoundController)

--
local EnabledFaucet = Component.new({
	Tag = script.Name,
})

function EnabledFaucet:Construct()
	local faucet = self.Instance

	self._cleaner = Trove.new()
	self._stopped = false

	local tween = TweenService:Create(
		faucet.Water,
		TweenInfo.new(0.2, Enum.EasingStyle.Linear),
		{ Size = Vector3.new(2.3, 0.08, 0.08), Transparency = 0 }
	)
	tween:Play()
	self._cleaner:Add(function()
		if tween then
			tween:Cancel()
		end
	end)

	local sound = SoundController:PlaySound("Water1", faucet.Water.Position)
	self._sound = sound
	self._soundVolumeTween = nil
	self._soundDelayThread = nil

	self._cleaner:Add(function()
		if self._sound then
			-- Cancel any pending delay
			if self._soundDelayThread then
				task.cancel(self._soundDelayThread)
				self._soundDelayThread = nil
			end
			-- Cancel volume tween if it exists
			if self._soundVolumeTween then
				self._soundVolumeTween:Cancel()
				self._soundVolumeTween = nil
			end
			-- Fade out sound and destroy after delay
			self._soundVolumeTween =
				TweenService:Create(self._sound, TweenInfo.new(0.2, Enum.EasingStyle.Linear), { Volume = 0 })
			self._soundVolumeTween:Play()
			self._soundDelayThread = task.delay(0.2, function()
				if self._sound and not self._stopped then
					self._sound:Destroy()
					self._sound = nil
				end
			end)
		end
	end)

	for _, v in faucet:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = true
		end
	end
end

function EnabledFaucet:Stop()
	if self._stopped then
		return
	end

	self._stopped = true
	local faucet = self.Instance

	-- Cancel any pending sound operations immediately
	if self._soundDelayThread then
		task.cancel(self._soundDelayThread)
		self._soundDelayThread = nil
	end
	if self._soundVolumeTween then
		self._soundVolumeTween:Cancel()
		self._soundVolumeTween = nil
	end
	if self._sound then
		self._sound:Destroy()
		self._sound = nil
	end

	-- Stop all particle emitters immediately
	for _, v in faucet:GetDescendants() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end

	-- Clean up all resources (tweens, sounds, etc.)
	self._cleaner:Destroy()

	-- Create and play stop tween
	local stopTween = TweenService:Create(
		faucet.Water,
		TweenInfo.new(0.05, Enum.EasingStyle.Linear),
		{ Size = Vector3.new(2.3, 0, 0), Transparency = 1 }
	)
	stopTween:Play()
end

return EnabledFaucet
