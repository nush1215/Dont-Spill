-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local SoundManager = {
	PlaySoundEvent = BridgeNet2.ReferenceBridge("PlaySound"),
	PlayRandomSoundEvent = BridgeNet2.ReferenceBridge("PlayRandomSoundInFolder"),
	ReplicateToOthersEvent = BridgeNet2.ReferenceBridge("ReplicateSoundToOthers"),
}

function SoundManager:PlayToPlayer(
	player: Player,
	soundName: string,
	location: Vector3 | Part?,
	customProperties: { [any]: any }?,
	limit: boolean?
)
	self.PlaySoundEvent:Fire(player, { soundName, location, customProperties, limit })
end

function SoundManager:PlayToPlayers(
	soundName: string,
	location: Vector3 | Part?,
	customProperties: { [any]: any }?,
	limit: boolean?
)
	self.PlaySoundEvent:Fire(BridgeNet2.AllPlayers(), { soundName, location, customProperties, limit })
end

function SoundManager:PlayFromRandomPlayerToPlayers(
	folderName: string,
	location: Vector3 | Part?,
	customProperties: { [any]: any }?,
	limit: boolean?
)
	self.PlayRandomSoundEvent:Fire(BridgeNet2.AllPlayers(), { folderName, { location, customProperties, limit } })
end

function SoundManager:ReplicateSounds(fromPlayer: Player, params: { string })
	self.PlaySoundEvent:Fire(BridgeNet2.PlayersExcept({ fromPlayer }), params)
end

function SoundManager:OnStart()
	self.ReplicateToOthersEvent:Connect(function(fromPlayer: Player, params: { string })
		self:ReplicateSounds(fromPlayer, params)
	end)
end

return SoundManager
