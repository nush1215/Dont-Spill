-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Assets
local Assets = ReplicatedStorage.Assets
local Particles = Assets.Particles
local Fireworks = Particles.Fireworks

--
local DEFAULT_SPEED = 30

--
return function(
	origin: CFrameValue | Model,
	amount: number,
	spreadDistance: { MinSpread: number, MaxSpread: number },
	heightDistance: { MinHeight: number, MaxHeight: number },
	speed: number?,
	soundProperties: { MinDistance: number, MaxDistance: number, Volume: number }?
)
	--
	local random = Random.new()

	--
	origin = typeof(origin) == "CFrame" and origin or origin:GetPivot()

	--
	local function launchFireworks()
		--
		local endPosition = origin
			* CFrame.new(
				random:NextNumber(spreadDistance.MinSpread or -6, spreadDistance.MaxSpread or 6),
				random:NextNumber(heightDistance.MinHeight, heightDistance.MaxHeight),
				random:NextNumber(-2, 2)
			)
		local totalDistance = (origin.Position - endPosition.Position).Magnitude

		--
		local fireworksClone = Fireworks:Clone()
		fireworksClone:PivotTo(origin)
		fireworksClone.Parent = workspace.Terrain

		--
		local launchTween = TweenService:Create(
			fireworksClone.PrimaryPart,
			TweenInfo.new(totalDistance / speed or DEFAULT_SPEED, Enum.EasingStyle.Linear),
			{
				CFrame = endPosition,
			}
		)

		launchTween:Play()

		launchTween.Completed:Wait()
		for _, v in fireworksClone.Container.FireworksAttachment:GetChildren() do
			if v:IsA("ParticleEmitter") then
				v:Emit(v:GetAttribute("EmitAmount") or 10)
			end
		end

		-- Cleanup
		task.wait(3)
		fireworksClone:Destroy()
	end

	for _ = 1, amount do
		task.spawn(launchFireworks)
		random:NextNumber(0.2, 0.5)
	end
end
