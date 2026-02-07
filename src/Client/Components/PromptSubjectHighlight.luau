-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)

--
local PromptSubjectHighlight = Component.new({
	Tag = script.Name,
})

function PromptSubjectHighlight:Construct()
	task.wait()
	--
	local subject: Model = self.Instance
	local prompt: ProximityPrompt = subject:FindFirstChildWhichIsA("ProximityPrompt", true)

	--
	if not prompt then
		warn("PromptSubjectHighlight: Construct: No ProximityPrompt found")
		return
	end

	--
	local highlight
	prompt.PromptShown:Connect(function()
		--
		highlight = Instance.new("Highlight")
		highlight.FillTransparency = 1
		highlight.OutlineTransparency = 1
		highlight.Parent = subject

		--
		TweenService:Create(highlight, TweenInfo.new(0.5), { OutlineTransparency = 0 }):Play()
	end)

	prompt.PromptHidden:Connect(function()
		TweenService:Create(highlight, TweenInfo.new(0.5), { OutlineTransparency = 1 }):Play()
		task.delay(0.5, function()
			highlight:Destroy()
		end)
	end)
end

return PromptSubjectHighlight
