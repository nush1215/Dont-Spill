-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui = game:GetService("StarterGui")

-- Client
local Client = script.Parent
local Controllers = Client.Controllers
local Components = Client.Components

-- Packages
local Packages = ReplicatedStorage.Packages
local Replica = require(Packages.Replica)

-- Modules
local LoadedComponents = require(Client.Modules.LoadedComponents)

--
local PRIORITY_TO_LOAD = {
	"PlayerDataController",
}

--
local LoadedControllers = {}
local startTime = os.clock()

repeat
	task.wait()
until ReplicatedStorage:GetAttribute("ServerLoaded") == true

--
Replica.RequestData()

--
local function initController(controller: ModuleScript, initType: "Init" | "Start")
	local controllerName = controller.Name
	local loadedController = LoadedControllers[controllerName]

	if not loadedController then
		local success, result = pcall(function()
			return require(controller)
		end)

		if not success then
			warn(`Failed to load controller '{controllerName}': {result}`)
			return
		end

		loadedController = result
		LoadedControllers[controllerName] = loadedController
	end

	local initFunctionName = `On{initType}`
	local initFunction = loadedController[initFunctionName]

	if initFunction then
		local success, error = pcall(initFunction, loadedController)
		if not success then
			warn(`Error in {controllerName}.{initFunctionName}: {error}`)
		end
	end
end

-- Load the Priorities
local function loadPriorityControllers(initType: "Init" | "Start")
	local loadStartTime = os.clock()

	for _, controllerName in PRIORITY_TO_LOAD do
		local controller = Controllers:FindFirstChild(controllerName)

		if controller and controller:IsA("ModuleScript") then
			initController(controller, initType)
		else
			warn(`Priority controller '{controllerName}' not found or is not a ModuleScript`)
		end
	end

	local loadTime = (os.clock() - loadStartTime) * 1000
	print(string.format("Client %s Priority Loaded: %.2f ms", initType, loadTime))
end

-- Load Everything else
local function loadOtherControllers(initType: "Init" | "Start")
	local loadStartTime = os.clock()

	for _, controller in Controllers:GetChildren() do
		if not controller:IsA("ModuleScript") then
			continue
		end

		if table.find(PRIORITY_TO_LOAD, controller.Name) then
			continue
		end

		initController(controller, initType)
	end

	local loadTime = (os.clock() - loadStartTime) * 1000
	print(string.format("Client %s Others Loaded: %.2f ms", initType, loadTime))
end

-- Load the Components
local function loadComponents()
	for _, component in Components:GetDescendants() do
		if not component:IsA("ModuleScript") then
			continue
		end

		task.spawn(function()
			local success, result = pcall(function()
				return require(component)
			end)

			if success then
				LoadedComponents[component.Name] = result
			else
				warn(`Failed to load component '{component.Name}': {result}`)
			end
		end)
	end
end

--
loadPriorityControllers("Init")
loadOtherControllers("Init")
loadPriorityControllers("Start")
loadOtherControllers("Start")
loadComponents()

--
ReplicatedStorage:SetAttribute("ClientLoaded", true)

--
local totalLoadTime = (os.clock() - startTime) * 1000
print(string.format("Client Fully Loaded: %.2f ms", totalLoadTime))
