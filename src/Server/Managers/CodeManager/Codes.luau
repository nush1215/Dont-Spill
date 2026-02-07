-- Services
local ServerScriptService = game:GetService("ServerScriptService")

-- Managers
local Managers = ServerScriptService.Server.Managers
local CurrencyManager = require(Managers.CurrencyManager)
local AbilitiesManager = require(Managers.AbilitiesManager)
local ChairSkinManager = require(Managers.ChairSkinManager)
local ChairSkinManager = require(Managers.ChairSkinManager)

export type Code = {
	Code: string,
	OnClaimMessage: string,
	Callback: (player: Player) -> (),
}

--
local Codes = {}
Codes.Data = {
	{
		Code = "HiTest123",
		OnClaimMessage = `You have received <font color="#2de200">100 Bux</font>`,
		Callback = function(player: Player)
			CurrencyManager:IncrementCurrency(player, 100)
		end,
	},

	{
		Code = "NY2026",
		OnClaimMessage = `You received the <font color="#55ff00">Year of the Horse</font> Chair Skin and <font color="#2de200">100 Bux</font>!`,
		Callback = function(player: Player)
			ChairSkinManager:GivePlayerChair(player, "YearOfTheHorse")
			CurrencyManager:IncrementCurrency(player, 100)
		end,
	},

	{
		Code = "UPD4",
		OnClaimMessage = `You received a <font color="#55ff00">Random Rare Chair</font>!`,
		Callback = function(player: Player)
			ChairSkinManager:GiveRandomRarityChair(player, "Rare")
		end,
	},

	{
		Code = "SLOWDOWN!",
		OnClaimMessage = `You have received the <font color="#55ff00">Slow Down Timer</font> ability!`,
		Callback = function(player: Player)
			AbilitiesManager:AddAbility(player, "SlowDownTimer", 1)
		end,
	},
}

function Codes.GetCodeFromCode(code: string): Code?
	for _, v in Codes.Data do
		if v.Code:lower() == code:lower() then
			return v
		end
	end

	return nil
end

return Codes
