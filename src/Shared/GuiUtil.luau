-- Services
local TweenService = game:GetService("TweenService")

-- Constants
local TRANSPARENCY_PROPERTIES = {
	"Transparency",
	"TextTransparency",
	"BackgroundTransparency",
	"ImageTransparency",
	"ScrollBarImageTransparency",
}

local IGNORED_CLASSES = {
	UIGradient = true,
}

local CLEANUP_DELAY = 1
local PULSE_CLEANUP_DELAY = 0.5

local GuiUtil = {}

--[[
	Animates a number from 0 to a goal value, calling the callback with each updated value.
	@param goal The target value to animate to
	@param detailed Whether to use NumberValue (true) or IntValue (false)
	@param duration Duration of the animation in seconds
	@param callback Function called with the current value on each update
	@param onFinished Optional function called when animation completes
]]
function GuiUtil.AnimateNumberTo(
	goal: number,
	detailed: boolean,
	duration: number,
	callback: (number) -> (),
	onFinished: (() -> ())?
)
	local valueObject = detailed and Instance.new("NumberValue") or Instance.new("IntValue")
	valueObject.Value = 0

	valueObject:GetPropertyChangedSignal("Value"):Connect(function()
		callback(valueObject.Value)
	end)

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
	local tween = TweenService:Create(valueObject, tweenInfo, { Value = goal })

	tween.Completed:Once(function()
		if onFinished then
			onFinished()
		end
		-- Clean up after a short delay to ensure callback is called
		task.delay(CLEANUP_DELAY, function()
			valueObject:Destroy()
		end)
	end)

	tween:Play()
end

--[[
	Creates a pulse effect on a text label by cloning it and animating scale/transparency.
	@param textLabel The TextLabel to pulse
	@param pulseScale The scale multiplier for the pulse effect
	@param duration Duration of the pulse animation in seconds
]]
function GuiUtil.PulseText(textLabel: TextLabel, pulseScale: number, duration: number)
	local pulseText = textLabel:Clone()
	pulseText.Parent = textLabel.Parent
	pulseText.ZIndex = textLabel.ZIndex - 1

	-- Ensure UIScale exists
	local uiScale = pulseText:FindFirstChildOfClass("UIScale")
	if not uiScale then
		uiScale = Instance.new("UIScale")
		uiScale.Parent = pulseText
	end

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)

	-- Animate scale and text transparency
	TweenService:Create(uiScale, tweenInfo, { Scale = pulseScale }):Play()
	TweenService:Create(pulseText, tweenInfo, { TextTransparency = 1 }):Play()

	-- Animate UIStroke if present
	local uiStroke = pulseText:FindFirstChildOfClass("UIStroke")
	if uiStroke then
		TweenService:Create(uiStroke, tweenInfo, { Transparency = 1 }):Play()
	end

	-- Clean up after animation
	task.delay(duration + PULSE_CLEANUP_DELAY, function()
		pulseText:Destroy()
	end)
end

--[[
	Formats a number with comma separators (e.g., 100000 -> "100,000").
	@param amount The number to format
	@return Formatted string with commas
]]
function GuiUtil.ConvertNumberWithCommas(amount: number): string
	if amount < 1000 then
		return tostring(amount)
	end

	local amountStr = tostring(amount)
	-- Reverse, add commas every 3 digits, reverse back, remove leading comma
	return amountStr:reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")
end

--[[
	Converts seconds to MM:SS format (e.g., 125 -> "02:05").
	@param totalSeconds Total seconds to convert
	@return Formatted string in MM:SS format
]]
function GuiUtil.ConvertSecondsToMMSS(totalSeconds: number): string
	local minutes = math.floor(totalSeconds / 60)
	local seconds = math.floor(totalSeconds % 60)
	return string.format("%02d:%02d", minutes, seconds)
end

--[[
	Converts seconds to HH:MM:SS format (e.g., 3665 -> "01:01:05").
	@param totalSeconds Total seconds to convert
	@return Formatted string in HH:MM:SS format
]]
function GuiUtil.ConvertSecondsToHHMMSS(totalSeconds: number): string
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = math.floor(totalSeconds % 60)
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

--[[
	Converts seconds to a human-readable format (e.g., "2 Days, 03 Hrs, 15 Mins, 30 Secs").
	@param totalSeconds Total seconds to convert
	@return Human-readable string
]]
function GuiUtil.ConvertSecondsToHumanReadable(totalSeconds: number): string
	local days = math.floor(totalSeconds / 86400)
	local hours = math.floor((totalSeconds % 86400) / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local seconds = math.floor(totalSeconds % 60)
	return string.format("%d Days, %02d Hrs, %02d Mins, %02d Secs", days, hours, minutes, seconds)
end

--[[
	Gets all GUI objects in a container that can have their transparency changed.
	@param container The root GUI object to search
	@return Dictionary mapping GUI objects to their changeable transparency properties
]]
function GuiUtil.GetCanGroupTransparent(container: GuiObject): { [GuiObject]: { string } }
	local result = {}

	--[[
		Gets valid transparency properties for a GUI object.
		@param guiObject The GUI object to check
		@return Array of transparency property names that exist on this object
	]]
	local function getTransparencyProperties(guiObject: GuiObject): { string }
		if IGNORED_CLASSES[guiObject.ClassName] then
			return {}
		end

		local properties = {}
		for _, propertyName in TRANSPARENCY_PROPERTIES do
			local success = pcall(function()
				return guiObject[propertyName]
			end)

			if success then
				table.insert(properties, propertyName)
			end
		end

		return properties
	end

	--[[
		Gets transparency properties that can be changed for a GUI object.
		Handles caching and ignores already-transparent properties.
		@param guiObject The GUI object to check
		@return Array of changeable transparency property names
	]]
	local function getChangeableTransparencyProperties(guiObject: GuiObject): { string }
		local availableProperties = getTransparencyProperties(guiObject)
		local changeableProperties = {}

		for _, propertyName in availableProperties do
			local ignoreAttribute = `Ignore{propertyName}`
			local canChangeAttribute = `CanChange{propertyName}`
			local setAttribute = `Set{propertyName}Transparency`
			local originalAttribute = `Original{propertyName}`

			-- Skip if property is locked
			if guiObject:GetAttribute(ignoreAttribute) then
				continue
			end

			-- Get current or previously set transparency
			local currentTransparency = guiObject:GetAttribute(setAttribute) or guiObject[propertyName]

			-- If already fully transparent and not marked as changeable, lock it
			if currentTransparency == 1 and not guiObject:GetAttribute(canChangeAttribute) then
				guiObject:SetAttribute(ignoreAttribute, true)
				continue
			end

			-- Mark as changeable and store original value if needed
			table.insert(changeableProperties, propertyName)
			guiObject:SetAttribute(canChangeAttribute, true)

			-- Store original transparency value if it's partially transparent
			if
				currentTransparency > 0
				and currentTransparency < 1
				and not guiObject:GetAttribute(originalAttribute)
			then
				guiObject:SetAttribute(originalAttribute, guiObject[propertyName])
			end
		end

		return changeableProperties
	end

	-- Process container itself
	result[container] = getChangeableTransparencyProperties(container)

	-- Process all descendants
	for _, descendant in container:GetDescendants() do
		if not descendant:IsA("GuiObject") then
			continue
		end

		local transparencyProperties = getTransparencyProperties(descendant)
		if #transparencyProperties == 0 then
			continue
		end

		result[descendant] = getChangeableTransparencyProperties(descendant)
	end

	return result
end

--[[
	Sets the transparency of a container and all its descendants that support transparency.
	@param container The root GUI object
	@param transparency Target transparency value (0-1)
	@param timeToTake Duration of the fade animation in seconds
]]
function GuiUtil.SetGroupTransparency(container: GuiObject, transparency: number, timeToTake: number)
	local changeableObjects = GuiUtil.GetCanGroupTransparent(container)
	local tweenInfo = TweenInfo.new(timeToTake, Enum.EasingStyle.Linear)

	for guiObject, transparencyProperties in changeableObjects do
		-- Handle GuiButton visibility based on transparency
		if guiObject:IsA("GuiButton") and not guiObject:GetAttribute("VisibleConnection") then
			local propertyName = if guiObject:IsA("TextButton")
				then "BackgroundTransparency"
				elseif guiObject:IsA("ImageButton") then "ImageTransparency"
				else nil

			if propertyName then
				guiObject:SetAttribute("VisibleConnection", true)
				guiObject:GetPropertyChangedSignal(propertyName):Connect(function()
					guiObject.Visible = guiObject[propertyName] < 1
				end)
			end
		end

		-- Tween each transparency property
		for _, propertyName in transparencyProperties do
			local targetTransparency = if transparency < 1 and guiObject:GetAttribute(`Original{propertyName}`)
				then guiObject:GetAttribute(`Original{propertyName}`)
				else transparency

			TweenService:Create(guiObject, tweenInfo, { [propertyName] = targetTransparency }):Play()
			guiObject:SetAttribute(`Set{propertyName}Transparency`, targetTransparency)
		end
	end
end

return GuiUtil
