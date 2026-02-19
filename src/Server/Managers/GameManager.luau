-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local ZonePlus = require(Packages.ZonePlus)

--
local BadgeManager

--
local GameManager = {}

function GameManager:_setupAntiFall()
	local spawnLocation = workspace.Map.SpawnLocation
	local antiFallPart = workspace.Map.AntiFall

	antiFallPart.Touched:Connect(function(hit)
		local character = hit.Parent
		local player = character and Players:GetPlayerFromCharacter(character)

		if player then
			character:PivotTo(spawnLocation.CFrame + Vector3.new(0, 5, 0))
		end
	end)
end

function GameManager:OnInit()
	BadgeManager = require(script.Parent.BadgeManager)
end

function GameManager:OnStart()
	task.spawn(GameManager._setupAntiFall, self)
end

return GameManager
