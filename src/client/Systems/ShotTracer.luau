--!strict

local Debris = game:GetService("Debris")
local Workspace = game:GetService("Workspace")

local MIN_VISUAL_LENGTH = 2
local MAX_VISUAL_LENGTH = 28

local ShotTracer = {}

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

	local tracer = Instance.new("Part")
	tracer.Name = "ShotTracer"
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.CanQuery = false
	tracer.CanTouch = false
	tracer.Material = Enum.Material.Neon
	tracer.Size = Vector3.new(thickness, thickness, length)
	tracer.CFrame = CFrame.lookAt(origin, origin + direction.Unit) * CFrame.new(0, 0, -length / 2)
	tracer.Parent = Workspace
	Debris:AddItem(tracer, 0.08)
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
