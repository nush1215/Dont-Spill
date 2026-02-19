-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)
local Trove = require(Packages.Trove)

-- Modules
local Shared = ReplicatedStorage.Shared
local MathUtil = require(Shared.MathUtil)
local GuiUtil = require(Shared.GuiUtil)

-- Assets
local Assets = ReplicatedStorage.Assets
local UI = Assets.UI

-- Leaderboards
local Leaderboards = workspace:WaitForChild("Leaderboards")

--
local RANK_COLORS = {
	[1] = Color3.fromRGB(255, 170, 0),
	[2] = Color3.fromRGB(171, 171, 171),
	[3] = Color3.fromRGB(170, 85, 0),
}

local DEFAULT_COLOR = Color3.fromRGB(255, 255, 255)

local FORMAT_LEADERBOARD_DATA = {
	Default = function(amount)
		return GuiUtil.ConvertNumberWithCommas(MathUtil.RoundUpTo2Dec(amount))
	end,
}

--
local LeaderboardController = {
	--
	_cachedNames = {},
	_cachedThumbnails = {},

	--
	_hasSetup = false,
	_refreshTime = 0,

	--
	_cleaner = Trove.new(),
}

function LeaderboardController:RefreshLeaderboard(updatedLeaderboardData: {})
	--
	self._cleaner:Clean()

	--
	for leaderboardKey, leaderboardData in updatedLeaderboardData do
		self._cleaner:Add(task.spawn(function()
			--
			local leaderboard = Leaderboards:WaitForChild(leaderboardKey, 2)
			local leaderboardUI = leaderboard and leaderboard.Board:FindFirstChild("LeaderboardUI")
			if not leaderboardUI then
				return
			end

			-- Remove old leaderboard data
			local container = leaderboardUI.Holder.Container

			--
			for rank, data in leaderboardData do
				if tonumber(data.key) < 1 then
					return
				end

				--
				local playerName = self._cachedNames[data.key]
				if not playerName then
					local success, name = pcall(function()
						return Players:GetNameFromUserIdAsync(data.key)
					end)

					if success then
						playerName = name
						self._cachedNames[data.key] = name
					else
						playerName = ""
					end
				end

				local formatFunc = FORMAT_LEADERBOARD_DATA[leaderboardKey] or FORMAT_LEADERBOARD_DATA.Default

				--
				local template: Frame = self._cleaner:Clone(leaderboardUI.Templates.EntryTemplate)
				template.Amount.Text = formatFunc(data.value)
				template.LayoutOrder = rank
				template.PlayerName.Text = playerName:upper() or ""
				template.Rank.Text = `#{rank}`
				template.BackgroundColor3 = RANK_COLORS[rank] or DEFAULT_COLOR
				template.Visible = true
				template.Parent = container

				self._cleaner:Add(task.spawn(function()
					local playerThumbnail = self._cachedThumbnails[data.key]

					if not playerThumbnail then
						local success, thumbnail = pcall(function()
							return Players:GetUserThumbnailAsync(
								data.key,
								Enum.ThumbnailType.HeadShot,
								Enum.ThumbnailSize.Size48x48
							)
						end)

						if success then
							playerThumbnail = thumbnail
							self._cachedThumbnails[data.key] = thumbnail
						end
					end

					if template then
						template.PlayerIcon.Image = playerThumbnail
					end
				end))
			end
		end))
	end
end

function LeaderboardController:SetupLeaderboard(initialLeaderboardData: { any: { any } })
	--
	local leaderboardUIs = {}
	for key, _ in initialLeaderboardData do
		local leaderboard = Leaderboards:WaitForChild(key, 3)
		if leaderboard then
			local leaderboardUI = UI.LeaderboardUI:Clone()
			leaderboardUI.Parent = leaderboard:WaitForChild("Board")
			table.insert(leaderboardUIs, leaderboardUI)
		end
	end

	--
	--[[task.spawn(function()
		while true do
			local timeLeft = self._refreshTime - workspace:GetServerTimeNow()

			for _, v in leaderboardUIs do
				v.Holder.RefreshTitle.Visible = not (timeLeft <= 0)
				v.Holder.RefreshTime.Text = timeLeft <= 0 and "Refreshing" or `{GuiUtil.ConvertSecondsToMMSS(timeLeft)}`
			end

			task.wait(1)
		end
	end)]]

	self:RefreshLeaderboard(initialLeaderboardData)
	self._hasSetup = true
end

function LeaderboardController:OnInit()
	--
	Replica.OnNew("Leaderboard", function(replica)
		--
		self._refreshTime = replica.Data.RefreshTime
		replica:OnSet({ "RefreshTime" }, function(newTime)
			self._refreshTime = newTime
		end)

		--
		self:SetupLeaderboard(replica.Data.LeaderboardData)
		replica:OnSet({ "LeaderboardData" }, function(leaderboardData)
			self:RefreshLeaderboard(leaderboardData)
		end)
	end)
end

--

return LeaderboardController
