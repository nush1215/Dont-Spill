-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local EffectsController = {
	PlayEffectEvent = BridgeNet2.ReferenceBridge("PlayEffect"),
	_loadedEffects = {},
}

function EffectsController:RunEffect(effectName: string, params: { any }, replicateToOthers: boolean)
	local effectModule = self._loadedEffects[effectName]
	if not effectName then
		warn(`Effect {effectName} not found.`)
		return
	end

	-- force it to be a table
	if not (params == nil) and typeof(params) ~= "table" then
		params = { params }
	end

	effectModule(table.unpack(params or {}))

	if replicateToOthers then
		self.PlayEffectEvent:Fire({ effectName, params })
	end
end

function EffectsController:OnInit()
	for _, effect in script:GetChildren() do
		if effect:IsA("ModuleScript") then
			local effectModule = require(effect)
			self._loadedEffects[effect.Name] = effectModule
		end
	end
end

function EffectsController:OnStart()
	self.PlayEffectEvent:Connect(function(effectData)
		self:RunEffect(table.unpack(effectData))
	end)
end

return EffectsController
