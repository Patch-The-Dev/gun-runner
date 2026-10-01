--!strict

local CELL_SIZE = 256
local MOVEMENT_MARGIN = 32

local ShotAudience = {}
ShotAudience.__index = ShotAudience

export type ShotAudience = typeof(setmetatable(
	{} :: {
		_cells: { [string]: { Player } },
	},
	ShotAudience
))

local function cellKey(x: number, z: number): string
	return string.format("%d:%d", x, z)
end

function ShotAudience.new(): ShotAudience
	return setmetatable({ _cells = {} }, ShotAudience)
end

function ShotAudience.rebuild(self: ShotAudience, positions: { [Player]: Vector3 })
	local cells: { [string]: { Player } } = {}
	for player, position in positions do
		local x = math.floor(position.X / CELL_SIZE)
		local z = math.floor(position.Z / CELL_SIZE)
		local key = cellKey(x, z)
		local cell = cells[key]
		if cell == nil then
			cell = {}
			cells[key] = cell
		end
		table.insert(cell, player)
	end
	self._cells = cells
end

function ShotAudience.near(self: ShotAudience, origin: Vector3, radius: number): { Player }
	local viewers: { Player } = {}
	local centerX = math.floor(origin.X / CELL_SIZE)
	local centerZ = math.floor(origin.Z / CELL_SIZE)
	local cellRadius = math.ceil((radius + MOVEMENT_MARGIN) / CELL_SIZE)
	for x = centerX - cellRadius, centerX + cellRadius do
		for z = centerZ - cellRadius, centerZ + cellRadius do
			local cell = self._cells[cellKey(x, z)]
			if cell ~= nil then
				for _, player in cell do
					table.insert(viewers, player)
				end
			end
		end
	end
	return viewers
end

return ShotAudience
