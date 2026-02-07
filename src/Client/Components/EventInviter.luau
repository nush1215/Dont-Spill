-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local EventInviter = Component.new({
	Tag = script.Name,
})

function EventInviter:Construct()
	--
	local adornee = self.Instance
	local eventId = adornee:GetAttribute("Id")
	--
	if not eventId then
		return
	end

	--
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "View Event"
	prompt.HoldDuration = 0.5
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.Parent = adornee

	--
	prompt.Triggered:Connect(function()
		pcall(function()
			SocialService:PromptRsvpToEventAsync(eventId)
		end)
	end)
end

return EventInviter
