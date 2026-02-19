-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

--
local DecisionController = {}

-- This function handles a decision prompt with yes/no buttons and an optional duration
-- Yields until the player makes a choice or the duration expires
function DecisionController:Decide(yesButton: GuiButton, noButton: GuiButton, expiryTime: number?)
	--
	local decision = nil
	local completed = false

	--
	local cleaner = Trove.new()

	-- Connect button clicks
	cleaner:Add(yesButton.Activated:Connect(function()
		decision = true
		completed = true
	end))

	cleaner:Add(noButton.Activated:Connect(function()
		decision = false
		completed = true
	end))

	-- Wait for decision or timeout
	while not completed do
		if expiryTime and workspace:GetServerTimeNow() >= expiryTime then
			break
		end
		task.wait()
	end

	-- Cleanup
	cleaner:Destroy()

	return decision
end

return DecisionController
