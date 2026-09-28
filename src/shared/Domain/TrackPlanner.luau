--!strict

local RaceTypes = require(script.Parent.Parent.Types.Race)
local TrackConfig = require(script.Parent.Parent.Config.TrackConfig)

type GateSpec = RaceTypes.GateSpec
type SegmentSpec = RaceTypes.SegmentSpec
type TrackPlan = RaceTypes.TrackPlan

export type TrackSettings = {
	BoosterStrength: number,
	BoosterSpawnChance: number,
	NegativeBoosterChance: number,
	PadSpawnChance: number,
	NegativePadChance: number,
	TargetSpawnChance: number,
	ObstacleSpawnChance: number,
	TrackLength: number,
	FinishLength: number,
	Rebirths: number,
}

local TrackPlanner = {}

local function chance(random: Random, probability: number): boolean
	return random:NextNumber() < math.clamp(probability, 0, 1)
end

local function buildGate(
	random: Random,
	settings: TrackSettings,
	id: string,
	lane: number
): GateSpec
	local stat = TrackConfig.GateStats[random:NextInteger(1, #TrackConfig.GateStats)]
	local rawMagnitude = random:NextNumber(0.5, 2) * math.max(1, settings.BoosterStrength / 10)
	local magnitude =
		math.clamp(rawMagnitude, TrackConfig.MinimumGateDelta, TrackConfig.MaximumGateDelta)
	local negative = chance(random, settings.NegativeBoosterChance)
	local delta = if negative then -magnitude else magnitude
	local hasPad = chance(random, settings.PadSpawnChance)
	local padNegative = hasPad and chance(random, settings.NegativePadChance)

	return {
		Id = id,
		Lane = lane,
		Stat = stat,
		Delta = delta,
		ShotStep = math.max(0.1, magnitude * TrackConfig.GateShotStepScale),
		HasPad = hasPad,
		PadNegative = padNegative,
	}
end

function TrackPlanner.create(seed: number, settings: TrackSettings): TrackPlan
	local random = Random.new(seed)
	local segments: { SegmentSpec } = {}
	local targetCount = 0
	local length = math.max(1, math.floor(settings.TrackLength))

	for index = 1, length do
		local gates: { GateSpec } = {}
		if chance(random, settings.BoosterSpawnChance) then
			table.insert(
				gates,
				buildGate(
					random,
					settings,
					string.format("%d-A", index),
					if chance(random, 0.5) then -1 else 1
				)
			)
		end
		if #gates > 0 and chance(random, settings.BoosterSpawnChance * 0.5) then
			local firstLane = gates[1].Lane
			table.insert(
				gates,
				buildGate(
					random,
					settings,
					string.format("%d-B", index),
					if firstLane == -1 then 1 else -1
				)
			)
		end

		local hasTarget = chance(random, settings.TargetSpawnChance)
		if hasTarget then
			targetCount += 1
		end

		table.insert(segments, {
			Index = index,
			Gates = gates,
			HasTarget = hasTarget,
			HasObstacle = chance(random, settings.ObstacleSpawnChance),
		})
	end

	return {
		Seed = seed,
		Segments = segments,
		FinishLength = math.max(1, math.floor(settings.FinishLength)),
		TargetCount = targetCount,
		HasEvolver = settings.Rebirths >= 1 and targetCount >= 2,
	}
end

return table.freeze(TrackPlanner)
