-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

-- Server
local Server = script.Parent
local Managers = Server.Managers
local Components = Server.Components

-- Modules
local LoadedComponents = require(Server.Modules.LoadedComponents)

--
local PRIORITY_TO_LOAD = {
	"PlayerDataManager",
}

--
local LoadedManagers = {}
local startTime = os.clock()

--
local function initManager(manager: ModuleScript, initType: "Init" | "Start")
	local managerName = manager.Name
	local loadedManager = LoadedManagers[managerName]

	if not loadedManager then
		local success, result = pcall(function()
			return require(manager)
		end)

		if not success then
			warn(`Failed to load manager '{managerName}': {result}`)
			return
		end

		loadedManager = result
		LoadedManagers[managerName] = loadedManager
	end

	local initFunctionName = `On{initType}`
	local initFunction = loadedManager[initFunctionName]

	if initFunction then
		local success, error = pcall(initFunction, loadedManager)
		if not success then
			warn(`Error in {managerName}.{initFunctionName}: {error}`)
		end
	end
end

-- Load the Priorities
local function loadPriorityManagers(initType: "Init" | "Start")
	local loadStartTime = os.clock()

	for _, managerName in PRIORITY_TO_LOAD do
		local manager = Managers:FindFirstChild(managerName)

		if manager and manager:IsA("ModuleScript") then
			initManager(manager, initType)
		else
			warn(`Priority manager '{managerName}' not found or is not a ModuleScript`)
		end
	end

	local loadTime = (os.clock() - loadStartTime) * 1000
	print(string.format("Server %s Priority Loaded: %.2f ms", initType, loadTime))
end

-- Load Everything else
local function loadOtherManagers(initType: "Init" | "Start")
	local loadStartTime = os.clock()

	for _, manager in Managers:GetChildren() do
		if not manager:IsA("ModuleScript") then
			continue
		end

		if table.find(PRIORITY_TO_LOAD, manager.Name) then
			continue
		end

		initManager(manager, initType)
	end

	local loadTime = (os.clock() - loadStartTime) * 1000
	print(string.format("Server %s Others Loaded: %.2f ms", initType, loadTime))
end

-- Load the Components
local function loadComponents()
	for _, component in Components:GetDescendants() do
		if not component:IsA("ModuleScript") then
			continue
		end

		local success, result = pcall(function()
			return require(component)
		end)

		if success then
			LoadedComponents[component.Name] = result
		else
			warn(`Failed to load component '{component.Name}': {result}`)
		end
	end
end

--
loadPriorityManagers("Init")
loadOtherManagers("Init")
loadPriorityManagers("Start")
loadOtherManagers("Start")
loadComponents()

--
ReplicatedStorage:SetAttribute("ServerLoaded", true)

--
local totalLoadTime = (os.clock() - startTime) * 1000
print(string.format("Server Fully Loaded: %.2f ms", totalLoadTime))
