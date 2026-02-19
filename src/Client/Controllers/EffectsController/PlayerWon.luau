-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Assets
local Assets = ReplicatedStorage.Assets
local Particles = Assets.Particles

return function(player: Player)
	--
	local character = player.Character
	if not character then
		return
	end

	local rootPart = character.PrimaryPart

	local winParticle = Particles.WinParticles:Clone()
	winParticle.Parent = rootPart

	for _, v in winParticle:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end
end
