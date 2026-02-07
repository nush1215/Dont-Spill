-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Packages
local Packages = ReplicatedStorage.Packages
local Signal = require(Packages.Signal)
local Trove = require(Packages.Trove)
local Spr = require(Packages.Spr)

-- Player
local LPlayer = Players.LocalPlayer
local PlayerGui = LPlayer.PlayerGui

--
local SoundController

--
local UIController = {
	OnFrameOpened = Signal.new(),
	OnFrameClosed = Signal.new(),

	_currentOpenedFrame = nil,
}

--[[
	Opens up the frame that we provide:
	- frame: Frame - The frame to open
	- independent: boolean? - Whether or not this frame is independent of others
	if its not independent it will close any other open frames
]]
function UIController:OpenFrame(frame: Frame, independent: boolean?)
	local uiScale = frame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = frame
	end

	if not frame:GetAttribute("OrigPosition") then
		frame:SetAttribute("OrigPosition", frame.Position)
	end

	-- Close if already opened
	if self._currentOpenedFrame == frame then
		self:CloseFrame(frame)
		return
	end

	-- Setup the effect
	frame.Position = frame:GetAttribute("OrigPosition") + UDim2.fromScale(0, 0.1)
	uiScale.Scale = 0.95

	-- Start the effect
	Spr.target(uiScale, 0.45, 5, { Scale = 1 })
	Spr.target(frame, 0.45, 5, { Position = frame:GetAttribute("OrigPosition") })
	frame.Visible = true

	if not independent then
		if self._currentOpenedFrame and self._currentOpenedFrame ~= frame then
			self:CloseFrame(self._currentOpenedFrame)
		end

		self._currentOpenedFrame = frame
	end

	self.OnFrameOpened:Fire(frame)
end

--[[
	Closes the frame that we provide
	- frame: Frame - The frame to close
]]
function UIController:CloseFrame(frame: Frame)
	--
	frame.Visible = false

	if self._currentOpenedFrame == frame then
		self._currentOpenedFrame = nil
	end

	self.OnFrameClosed:Fire(frame)
end

--
function UIController:BindButtonClick(
	button: GuiButton,
	clickCallback: () -> (),
	bindEffect: boolean?,
	disconnectAfter: boolean?,
	bindEffectProperties: {
		ShowFrame: Frame?,
		ButtonDownScale: number?,
		ButtonHoverscale: number?,
		OnHoverCallback: () -> ()?,
		OnHoverEndCallback: () -> ()?,
		ClickSoundName: string?,
		ButtonNormalScale: number?,
	}?
): { Disconnect: () -> () }
	--
	local cleaner = Trove.new()

	cleaner:Add(button.MouseButton1Click:Connect(function()
		if clickCallback then
			task.spawn(clickCallback)
		end

		if disconnectAfter then
			cleaner:Destroy()
		end
	end))

	if bindEffect then
		bindEffectProperties = bindEffectProperties or {}
		cleaner:Add(self:BindButtonEffect(button, bindEffectProperties))
	end

	return {
		Disconnect = function()
			cleaner:Destroy()
		end,
	}
end

function UIController:BindButtonEffect(
	button: GuiButton,
	properties: {
		ShowFrame: Frame?,
		ButtonDownScale: number?,
		ButtonHoverscale: number?,
		OnHoverCallback: () -> ()?,
		OnHoverEndCallback: () -> ()?,
		ClickSoundName: string?,
		ButtonNormalScale: number?,
	}?
)
	--
	local cleaner = Trove.new()

	--
	properties = properties or {}
	local showFrame = properties.ShowFrame or button
	local buttonDownScale = properties.ButtonDownScale
	local buttonHoverscale = properties.ButtonHoverscale
	local onHoverCallback = properties.OnHoverCallback
	local OnHoverEndCallback = properties.OnHoverEndCallback
	local clickSoundName = properties.ClickSoundName
	local buttonNormalScale = properties.ButtonNormalScale

	--
	local uiScale = showFrame:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = showFrame
	end

	local damping = 0.4
	local frequency = 5.5

	local buttonSprings = {
		Press = function()
			Spr.target(uiScale, damping, frequency, {
				Scale = buttonDownScale or 0.93,
			})
		end,

		Hover = function()
			Spr.target(uiScale, damping, frequency, {
				Scale = buttonHoverscale or 1.06,
			})
		end,

		Normal = function()
			Spr.target(uiScale, damping, frequency, {
				Scale = buttonNormalScale or 1,
			})
		end,
	}

	--
	cleaner:Add(button.MouseButton1Down:Connect(function()
		SoundController:PlaySound(clickSoundName or "InteractUI")
		buttonSprings.Press()
	end))

	cleaner:Add(button.MouseButton1Up:Connect(function()
		buttonSprings.Normal()
	end))

	cleaner:Add(button.MouseEnter:Connect(function()
		if onHoverCallback then
			onHoverCallback()
		end

		SoundController:PlaySound("ButtonHover")
		buttonSprings.Hover()
	end))

	cleaner:Add(button.MouseLeave:Connect(function()
		if OnHoverEndCallback then
			OnHoverEndCallback()
		end

		buttonSprings.Normal()
	end))

	cleaner:Add(buttonSprings.Normal)

	return {
		Disconnect = function()
			cleaner:Destroy()
		end,
	}
end

function UIController:OnInit()
	--
	PlayerDataController = require(script.Parent.PlayerDataController)
	SoundController = require(script.Parent.SoundController)

	--
	for _, v in PlayerGui:GetDescendants() do
		if not v:IsA("UIStroke") then
			continue
		end

		v:AddTag("UIStroke")
	end

	PlayerGui.DescendantAdded:Connect(function(v)
		if v:IsA("UIStroke") then
			v:AddTag("UIStroke")
		end
	end)

	-- Disable Reset Button
	--[[task.spawn(function()
		repeat
			local success = pcall(function()
				StarterGui:SetCore("ResetButtonCallback", false)
			end)
			task.wait(1)
		until success
	end)]]
end

function UIController:OnStart() end

return UIController
