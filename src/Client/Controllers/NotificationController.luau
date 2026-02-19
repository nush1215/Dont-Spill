-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)
local Spr = require(Packages.Spr)

-- Local Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui

--
local SoundController

--
local DEFAULT_DURATION = 3

--
local NotificationController = {
	NotifyNormalEvent = BridgeNet2.ReferenceBridge("NotifyNormal"),
	NotifyChatEvent = BridgeNet2.ReferenceBridge("NotifyChat"),

	_activeNotifications = {},
}

-- Shows a notification on the screen of the player
function NotificationController:NotifyNormal(notification: string, duration: number?, sound: string?, scale: number?)
	--
	local ui = self.UI
	local normalNotificationContainer = ui.NormalNotificationContainer
	local notificationDuration = duration or DEFAULT_DURATION

	-- If already active
	if self._activeNotifications[notification] then
		local data = self._activeNotifications[notification]
		data.Count = data.Count + 1
		data.TimeLeft = notificationDuration

		-- Update label with [N]
		data.Instance.Text = notification .. " [" .. data.Count .. "]"
		SoundController:PlaySound(sound or "Notify")
		return
	end

	-- Create new notification
	local normalNotificationTemplate = ui.Templates.NormalNotificationTemplate:Clone()
	normalNotificationTemplate.Text = notification
	normalNotificationTemplate.UIScale.Scale = 0.5
	normalNotificationTemplate.Visible = true
	normalNotificationTemplate.Parent = normalNotificationContainer

	-- Effect
	Spr.target(normalNotificationTemplate.UIScale, 0.5, 4, { Scale = scale or 1 })
	SoundController:PlaySound(sound or "Notify")

	-- Track the notification
	local notificationData = {
		Count = 1,
		TimeLeft = notificationDuration,
		Instance = normalNotificationTemplate,
	}
	self._activeNotifications[notification] = notificationData

	-- Timer loop
	task.spawn(function()
		while notificationData.TimeLeft > 0 do
			local dt = task.wait()
			notificationData.TimeLeft = notificationData.TimeLeft - dt
		end

		-- Fade out and cleanup
		TweenService
			:Create(
				normalNotificationTemplate.UIStroke,
				TweenInfo.new(0.5, Enum.EasingStyle.Sine),
				{ Transparency = 1 }
			)
			:Play()
		TweenService
			:Create(normalNotificationTemplate, TweenInfo.new(0.5, Enum.EasingStyle.Sine), { TextTransparency = 1 })
			:Play()

		task.wait(0.5)
		normalNotificationTemplate:Destroy()
		self._activeNotifications[notification] = nil
	end)
end

-- Adds a notification to the chat
function NotificationController:NotifyChat(notificationText: string)
	local rbxSystemTextChannel = TextChatService.TextChannels.RBXSystem
	rbxSystemTextChannel:DisplaySystemMessage(`<font color="#ffffff">{notificationText}</font>`)
end

function NotificationController:OnInit()
	--
	SoundController = require(script.Parent.SoundController)

	--
	self.UI = PlayerGui:WaitForChild("NotificationUI")
end

function NotificationController:OnStart()
	self.NotifyNormalEvent:Connect(function(data)
		if typeof(data) ~= "table" then
			self:NotifyNormal(data)
			return
		end

		self:NotifyNormal(table.unpack(data))
	end)

	self.NotifyChatEvent:Connect(function(notificationText)
		self:NotifyChat(notificationText)
	end)
end

return NotificationController
