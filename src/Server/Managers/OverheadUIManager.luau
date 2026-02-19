-- Services
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

-- Assets
local Assets = ReplicatedStorage.Assets
local UI = Assets.UI

--
local PlayerDataManager

--
local OverheadUIManager = {
	_cleaners = {},
}

function OverheadUIManager:_attachUI(player: Player)
	--
	local hasData, playerData = PlayerDataManager:GetPlayerData(player):await()
	if not hasData then
		return
	end

	--
	local cleaner = Trove.new()
	self._cleaners[player] = cleaner

	--
	local overheadUI = cleaner:Clone(UI.OverheadUI)
	overheadUI.Holder.PlayerName.Text = player.Name
	overheadUI.Holder.PlayerCurrency.Text = `${playerData.Currency}`
	overheadUI.Holder.StreakAmount.Text = playerData.Streak
	overheadUI.Holder.PlayerName.UIGradient.Enabled = player:HasTag("VIP")
	overheadUI.Parent = workspace.Terrain

	-- Set adornee
	local function parentOverhead()
		local character = player.Character
		local humanoid = character.Humanoid

		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None

		local characterSize = character:GetExtentsSize()
		overheadUI.StudsOffset = Vector3.new(0, characterSize.Y / 2, 0)
		overheadUI.Adornee = character.Head
	end

	if player.Character then
		parentOverhead()
	end
	player.CharacterAdded:Connect(parentOverhead)

	-- Listen for changes
	cleaner:Add(PlayerDataManager:ListenForChanges(player, "Currency", function(newCurrency: number)
		overheadUI.Holder.PlayerCurrency.Text = `${newCurrency}`
	end))

	cleaner:Add(PlayerDataManager:ListenForChanges(player, "Streak", function(newStreak: number)
		overheadUI.Holder.StreakAmount.Text = `{newStreak}`
	end))

	cleaner:Add(CollectionService:GetInstanceAddedSignal("VIP"):Connect(function(vipPlayer: Player)
		if vipPlayer == player then
			overheadUI.Holder.PlayerName.UIGradient.Enabled = true
		end
	end))
end

function OverheadUIManager:OnInit()
	PlayerDataManager = require(script.Parent.PlayerDataManager)
end

function OverheadUIManager:OnStart()
	Players.PlayerAdded:Connect(function(player)
		self:_attachUI(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_attachUI(player)
	end

	Players.PlayerRemoving:Connect(function(player)
		local cleaner = self._cleaners[player]
		if cleaner then
			cleaner:Destroy()
			self._cleaners[player] = nil
		end
	end)
end

return OverheadUIManager
