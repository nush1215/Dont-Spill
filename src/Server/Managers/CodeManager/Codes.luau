-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Managers
local Managers = ServerScriptService.Server.Managers
export type Code = {
	Code: string,
	OnClaimMessage: string,
	Callback: (player: Player) -> (),
}

--
local Codes = {}
Codes.Data = {}

function Codes.GetCodeFromCode(code: string): Code?
	for _, v in Codes.Data do
		if v.Code:lower() == code:lower() then
			return v
		end
	end

	return nil
end

return Codes
