-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Packages
local Packages = ReplicatedStorage.Packages
local Trove = require(Packages.Trove)

-- Modules
local ViewportUtil = require(script.Util)

export type Viewport = {
	-- Private properties
	_part: BasePart | Model,
	_viewportFrame: ViewportFrame,
	_offset: CFrame,
	_spin: boolean?,
	_spinReferenceFrame: Frame?,
	_spinDirection: Vector3?,
	_spinStartTime: number?,
	_spinInitialPivot: CFrame?,
	_cleaner: typeof(Trove.new()),

	-- Methods
	Destroy: (self: Viewport) -> (),
	_init: (self: Viewport) -> (),
}

--
local INITIAL_TIME = tick()

--[[
	Viewport Class
	
	Creates a viewport class that automatically displays a part or model in a ViewportFrame.
	Handles camera setup, model positioning, and optional spinning animations.
]]
local Viewport = {}
Viewport.__index = Viewport

--[=[
	Constructs a new Viewport instance.

	@param part BasePart | Model -- The part or model to display in the viewport.
	@param viewportFrame ViewportFrame -- The viewport frame to display the part or model.
	@param offset CFrame -- The offset to apply to the camera position.
	@param spin boolean? -- Whether the model should continuously spin (optional).
	@param spinReferenceFrame Frame? -- The frame whose visibility controls whether the model spins (optional).
	@param spinDirection Vector3? -- The axis direction for spinning (defaults to Y-axis if not provided).

	@return Viewport -- The constructed Viewport object.
]=]
function Viewport.new(
	part: BasePart | Model,
	viewportFrame: ViewportFrame,
	offset: CFrame,
	spin: boolean?,
	spinReferenceFrame: Frame?,
	spinDirection: Vector3?
)
	local self = setmetatable({
		_part = part,
		_viewportFrame = viewportFrame,
		_offset = offset,
		_spin = spin,
		_spinReferenceFrame = spinReferenceFrame,
		_spinDirection = spinDirection,

		_cleaner = Trove.new(),
	}, Viewport)

	self:_init()
	return self
end

--[=[
	Initializes the Viewport instance by setting up the camera, converting parts to models,
	positioning the model in the viewport, and handling optional spinning animations.
]=]
function Viewport:_init()
	local viewportFrame = self._viewportFrame

	-- Create and configure the camera for the viewport
	local camera = Instance.new("Camera")
	camera.FieldOfView = 70
	camera.Parent = self._viewportFrame

	-- Convert BasePart to Model if needed (for proper viewport display)
	if self._part:IsA("BasePart") then
		local model = Instance.new("Model")
		model.PrimaryPart = self._part
		self._part.Orientation = Vector3.new(0, 0, 0)
		self._part.Parent = model
		self._part = model

		-- Tag the model for spinning functionality
		self._part:AddTag("ModelSpin")
	end

	-- Create a WorldModel to contain the part/model (required for viewport rendering)
	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "WorldModel"
	worldModel.Parent = viewportFrame

	-- Set up viewport properties
	self._part.Parent = worldModel
	viewportFrame.CurrentCamera = camera

	-- Calculate optimal camera position to fit the model in the viewport
	local vpfModel = ViewportUtil.new(viewportFrame, camera)
	local cf, _ = self._part:GetBoundingBox()

	-- Set the model in the viewport frame utility
	vpfModel:SetModel(self._part)

	-- Position the camera with the specified offset
	self._offset = self._offset or CFrame.new()
	local distance = vpfModel:GetFitDistance(cf.Position)
	camera.CFrame = CFrame.new(cf.Position) * CFrame.new(0, 0, distance) * self._offset

	-- Set up spinning animation if enabled
	if self._spin then
		local spinDirection = self._spinDirection or Vector3.new(0, 1, 0)
		self._spinInitialPivot = self._part:GetPivot()

		-- Rotate the model continuously on the specified axis (synchronized using tick())
		self._cleaner:Add(RunService.Heartbeat:Connect(function()
			if self._spinReferenceFrame and not self._spinReferenceFrame.Visible then
				return
			end

			local elapsed = tick() - INITIAL_TIME
			local theta = math.rad(0.3) * elapsed * 60
			self._part:PivotTo(
				self._spinInitialPivot
					* CFrame.Angles(theta * spinDirection.X, theta * spinDirection.Y, theta * spinDirection.Z)
			)
		end))
	end
end

--[=[
	Destroys the Viewport instance, cleaning up all connections and destroying the model.
]=]
function Viewport:Destroy()
	self._cleaner:Destroy()
	self._part:Destroy()
	self = nil
end

return Viewport
