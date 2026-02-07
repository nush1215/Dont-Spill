-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)
local Promise = require(Packages.Promise)

-- Local Player
local LocalPlayer = Players.LocalPlayer

--
local DEFAULT_TIMEOUT = 15

--
local PlayerDataController = {
	_playerDataReplica = nil,
}

function PlayerDataController:GetReplica(timeout: string)
	--
	timeout = timeout or DEFAULT_TIMEOUT
	local getTimeout = os.clock() + timeout

	--
	return Promise.new(function(resolve, reject)
		-- if there player replica has not yet been created, keep trying until it has
		if not self._playerDataReplica then
			repeat
				task.wait()
			until self._playerDataReplica or getTimeout - os.clock() <= 0

			if not self._playerDataReplica then
				reject("Timeout Reached! Player Replica does not exist.")
			end
		end

		--
		resolve(self._playerDataReplica)
	end)
end

function PlayerDataController:GetData(): { any }
	local hasData, playerDataReplica = self:GetReplica():await()
	if not hasData then
		return
	end

	return playerDataReplica.Data
end

function PlayerDataController:GetKey(key: string): any
	local playerData = PlayerDataController:GetData()
	return playerData[key]
end

function PlayerDataController:OnInit()
	Replica.OnNew("PlayerData", function(replica)
		if not (replica.Tags.UserId == LocalPlayer.UserId) then
			return
		end

		self._playerDataReplica = replica
	end)
end

return PlayerDataController
