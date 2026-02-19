-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local EffectsManager = {
	PlayEffectEvent = BridgeNet2.ReferenceBridge("PlayEffect"),
}

function EffectsManager:OnStart()
	self.PlayEffectEvent:Connect(function(player: Player, effectData: { any })
		self.PlayEffectEvent:Fire(BridgeNet2.PlayersExcept({ player }), effectData)
	end)
end

return EffectsManager
