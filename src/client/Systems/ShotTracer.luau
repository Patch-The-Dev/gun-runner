--!strict

local Workspace = game:GetService("Workspace")

local MIN_VISUAL_LENGTH = 2
local MAX_VISUAL_LENGTH = 28
local MAX_TRACERS = 96
local TRACER_LIFETIME = 0.08

local ShotTracer = {}
local pool: { Part } = {}
local generations: { number } = {}
local nextSlot = 1

local function acquireTracer(): (Part, number)
	local slot = nextSlot
	nextSlot = (slot % MAX_TRACERS) + 1
	local tracer: Part? = pool[slot]
	if tracer == nil then
		local created = Instance.new("Part")
		created.Name = "ShotTracer"
		created.Anchored = true
		created.CanCollide = false
		created.CanQuery = false
		created.CanTouch = false
		created.Material = Enum.Material.Neon
		pool[slot] = created
		return created, slot
	end
	return tracer, slot
end

local function spreadDirections(direction: Vector3, projectileCount: number): { Vector3 }
	local unit = direction.Unit
	if projectileCount <= 1 then
		return { unit }
	end

	local directions: { Vector3 } = {}
	local center = (projectileCount + 1) / 2
	for index = 1, projectileCount do
		local degrees = (index - center) * 2.5
		local rotated = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees))
			:VectorToWorldSpace(unit)
		table.insert(directions, rotated.Unit)
	end
	return directions
end

function ShotTracer.render(origin: Vector3, direction: Vector3, explosive: boolean)
	if direction.Magnitude < 0.001 then
		return
	end

	local length = math.clamp(
		if explosive then MAX_VISUAL_LENGTH else 12,
		MIN_VISUAL_LENGTH,
		MAX_VISUAL_LENGTH
	)
	local thickness = if explosive then 0.35 else 0.12

	local tracer, slot = acquireTracer()
	tracer.Size = Vector3.new(thickness, thickness, length)
	tracer.CFrame = CFrame.lookAt(origin, origin + direction.Unit) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = Workspace
	local generation = (generations[slot] or 0) + 1
	generations[slot] = generation
	task.delay(TRACER_LIFETIME, function()
		if generations[slot] == generation then
			tracer.Parent = nil
		end
	end)
end

function ShotTracer.renderSpread(
	origin: Vector3,
	direction: Vector3,
	projectileCount: number,
	explosive: boolean
)
	if direction.Magnitude < 0.001 then
		return
	end
	for _, shotDirection in spreadDirections(direction, math.max(1, math.floor(projectileCount))) do
		ShotTracer.render(origin, shotDirection, explosive)
	end
end

return table.freeze(ShotTracer)
