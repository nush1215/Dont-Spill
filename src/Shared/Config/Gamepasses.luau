-- Services
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")

--
if RunService:IsServer() then
end

--
export type Gamepass = {
	Id: string,
	Name: string,
	Icon: string,
	PassId: number,
	OnPurchaseCallback: (player: Player) -> (), -- will only be ran once when you purchase the gamepass
	OnInitializeCallback: (player: Player) -> (), -- this will be ran for when the player purchase the gamepass and everytime the player joins the game
}

local Gamepasses = {}
Gamepasses.Data = {} :: { Gamepass }

table.freeze(Gamepasses.Data)

function Gamepasses.GetGamepassFromId(id: string)
	for _, v in Gamepasses.Data do
		if v.Id == id then
			return v
		end
	end

	return nil
end

function Gamepasses.GetGamepassFromPassId(passId: string)
	for _, v in Gamepasses.Data do
		if v.PassId == passId then
			return v
		end
	end

	return nil
end

function Gamepasses.GetAllGamepasses()
	return Gamepasses.Data
end

return Gamepasses
