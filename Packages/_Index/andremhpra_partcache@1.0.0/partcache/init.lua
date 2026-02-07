---- TYPE DEFINITION ----
type PartCacheImpl = {
	__index: PartCacheImpl,
	new: (
		template: BasePart,
		numPrecreatedParts: number?,
		currentCacheParent: Instance?
	) -> PartCache,

	GetPart: (self: PartCache) -> BasePart,
	ReturnPart: (self: PartCache, part: BasePart) -> (),
	SetCacheParent: (self: PartCache, newParent: Instance) -> (),
	Expand: (self: PartCache, numParts: number?) -> (),
	Dispose: (self: PartCache) -> (),
}

export type PartCache = typeof(setmetatable(
	{} :: {
		Open: { BasePart },
		InUse: { BasePart },
		CurrentCacheParent: Instance?,
		Template: BasePart?,
		ExpansionSize: number,
	},
	{} :: PartCacheImpl
))

---- PRIVATE CONSTANTS ----
local CF_REALLY_FAR_AWAY = CFrame.new(0, 10e8, 0)

---- PRIVATE FUNCTIONS ----
local function MakeFromTemplate(template: BasePart, currentCacheParent: Instance): BasePart
	local part = template:Clone()
	part.CFrame = CF_REALLY_FAR_AWAY
	part.Anchored = true
	part.Parent = currentCacheParent
	return part
end

---- MODULE IMPLEMENTATION ----
local PartCache = {} :: PartCacheImpl
PartCache.__index = PartCache

function PartCache.new(
	template: BasePart,
	numPrecreatedParts: number?,
	currentCacheParent: Instance?
): PartCache
	assert(template and template:IsA("BasePart"), "Invalid *template*!")

	local numParts = numPrecreatedParts or 5
	local cacheParent = currentCacheParent or workspace

	assert(numParts > 0, "PrecreatedParts cannot be negative!")

	-- Ensure template is clonable
	local oldArchivable = template.Archivable
	template.Archivable = true
	local newTemplate = template:Clone()
	template.Archivable = oldArchivable

	-- Create the cache
	local self = setmetatable({
		Open = {},
		InUse = {},
		CurrentCacheParent = cacheParent,
		Template = newTemplate,
		ExpansionSize = 10,
	}, PartCache)

	-- Precreate parts
	for _ = 1, numParts do
		table.insert(self.Open, MakeFromTemplate(newTemplate, cacheParent))
	end

	newTemplate.Parent = nil
	return self
end

function PartCache:GetPart(): BasePart
	if #self.Open == 0 then
		for _ = 1, self.ExpansionSize do
			table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
		end
	end

	local part = table.remove(self.Open)
	table.insert(self.InUse, part)
	return part
end

function PartCache:ReturnPart(part: BasePart)
	local index = table.find(self.InUse, part)
	if index then
		table.remove(self.InUse, index)
		table.insert(self.Open, part)
		part.CFrame = CF_REALLY_FAR_AWAY
		part.Anchored = true
	else
		error("Attempted to return a part that is not in use!")
	end
end

function PartCache:SetCacheParent(newParent: Instance)
	assert(
		newParent:IsDescendantOf(workspace) or newParent == workspace,
		"Cache parent must be within Workspace!"
	)
	self.CurrentCacheParent = newParent

	for _, part in ipairs(self.Open) do
		part.Parent = newParent
	end

	for _, part in ipairs(self.InUse) do
		part.Parent = newParent
	end
end

function PartCache:Expand(numParts: number?)
	local expandBy = numParts or self.ExpansionSize
	for _ = 1, expandBy do
		table.insert(self.Open, MakeFromTemplate(self.Template, self.CurrentCacheParent))
	end
end

function PartCache:Dispose()
	for _, part in ipairs(self.Open) do
		part:Destroy()
	end

	for _, part in ipairs(self.InUse) do
		part:Destroy()
	end

	self.Template:Destroy()
	self.Open = {}
	self.InUse = {}
	self.CurrentCacheParent = nil
end

return PartCache
