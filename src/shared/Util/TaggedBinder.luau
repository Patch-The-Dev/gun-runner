--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

type Cleanup = () -> ()
type Factory = (instance: Instance) -> Cleanup?

local TaggedBinder = {}
TaggedBinder.__index = TaggedBinder

export type TaggedBinder = typeof(setmetatable(
	{} :: {
		_tag: string,
		_factory: Factory,
		_trove: typeof(Trove.new()),
		_cleanups: { [Instance]: Cleanup },
	},
	TaggedBinder
))

function TaggedBinder.new(tag: string, factory: Factory): TaggedBinder
	local self = setmetatable({
		_tag = tag,
		_factory = factory,
		_trove = Trove.new(),
		_cleanups = {},
	}, TaggedBinder)

	local function bind(instance: Instance)
		if self._cleanups[instance] ~= nil then
			return
		end
		self._cleanups[instance] = factory(instance) or function() end
	end

	local function unbind(instance: Instance)
		local cleanup = self._cleanups[instance]
		if cleanup == nil then
			return
		end
		self._cleanups[instance] = nil
		cleanup()
	end

	for _, instance in CollectionService:GetTagged(tag) do
		bind(instance)
	end
	self._trove:Connect(CollectionService:GetInstanceAddedSignal(tag), bind)
	self._trove:Connect(CollectionService:GetInstanceRemovedSignal(tag), unbind)
	self._trove:Add(function()
		local instances = {}
		for instance in self._cleanups do
			table.insert(instances, instance)
		end
		for _, instance in instances do
			unbind(instance)
		end
	end)

	return self
end

function TaggedBinder:Destroy()
	self._trove:Destroy()
end

return TaggedBinder
