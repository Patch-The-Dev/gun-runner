--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)
local WeaponMath = require(ReplicatedStorage.Shared.Domain.WeaponMath)

type RunWeaponStats = RaceTypes.RunWeaponStats
type RaceSnapshot = RaceTypes.RaceSnapshot

local RaceSession = {}
RaceSession.__index = RaceSession

export type RaceSession = typeof(setmetatable(
	{} :: {
		StartedAt: number,
		RunCash: number,
		RunTargets: number,
		RawTargetsCollected: number,
		FinishMultiplier: number,
		Direction: Vector3,
		Weapon: RunWeaponStats,
		Finished: boolean,
		ClaimedTargets: { [string]: boolean },
		ClaimedPillars: { [string]: boolean },
		ConsumedGates: { [string]: boolean },
		ConsumedObstacles: { [string]: boolean },
		EvolverUsed: boolean,
		TotalCheckpoints: number,
		LastCheckpointIndex: number,
	},
	RaceSession
))

local function isFinitePositive(value: number): boolean
	return value > 0 and value == value and value ~= math.huge
end

function RaceSession.new(
	baseWeapon: RunWeaponStats,
	direction: Vector3,
	totalCheckpoints: number
): RaceSession
	assert(direction.Magnitude > 0.001, "Race direction must be non-zero")
	return setmetatable({
		StartedAt = os.clock(),
		RunCash = 0,
		RunTargets = 0,
		RawTargetsCollected = 0,
		FinishMultiplier = 1,
		Direction = direction.Unit,
		Weapon = table.clone(baseWeapon),
		Finished = false,
		ClaimedTargets = {},
		ClaimedPillars = {},
		ConsumedGates = {},
		ConsumedObstacles = {},
		EvolverUsed = false,
		TotalCheckpoints = math.max(1, math.floor(totalCheckpoints)),
		LastCheckpointIndex = 0,
	}, RaceSession)
end

function RaceSession:elapsed(): number
	return math.max(0, os.clock() - self.StartedAt)
end

function RaceSession:touchCheckpoint(index: number): boolean
	if self.Finished then
		return false
	end

	local normalized = math.floor(index)
	if normalized ~= self.LastCheckpointIndex + 1 or normalized > self.TotalCheckpoints then
		return false
	end

	self.LastCheckpointIndex = normalized
	return true
end

function RaceSession:canFinish(minimumElapsedSeconds: number): boolean
	return not self.Finished
		and self.LastCheckpointIndex >= self.TotalCheckpoints
		and self:elapsed() >= math.max(0, minimumElapsedSeconds)
end

function RaceSession:addCash(amount: number): boolean
	if self.Finished or not isFinitePositive(amount) then
		return false
	end
	self.RunCash += amount
	return true
end

function RaceSession:addTargets(amount: number): boolean
	if self.Finished or not isFinitePositive(amount) then
		return false
	end
	self.RunTargets += amount
	return true
end

function RaceSession:consumeTarget(targetId: string, reward: number): boolean
	if self.Finished or self.ClaimedTargets[targetId] or not isFinitePositive(reward) then
		return false
	end
	self.ClaimedTargets[targetId] = true
	self.RawTargetsCollected += 1
	self.RunTargets += reward
	return true
end

function RaceSession:consumePillar(pillarId: string, reward: number): boolean
	if self.Finished or self.ClaimedPillars[pillarId] or not isFinitePositive(reward) then
		return false
	end
	self.ClaimedPillars[pillarId] = true
	self.RunCash += reward
	return true
end

function RaceSession:applyGate(gateId: string, statName: string, delta: number): boolean
	if self.Finished or self.ConsumedGates[gateId] then
		return false
	end
	self.ConsumedGates[gateId] = true
	self.Weapon = WeaponMath.applyGate(self.Weapon, statName, delta)
	return true
end

function RaceSession:applyObstacle(obstacleId: string, penaltyFraction: number): boolean
	if self.Finished or self.ConsumedObstacles[obstacleId] then
		return false
	end
	self.ConsumedObstacles[obstacleId] = true
	self.Weapon = WeaponMath.applyPenalty(self.Weapon, penaltyFraction)
	return true
end

function RaceSession:applyEvolver(multiplier: number): boolean
	if self.Finished or self.EvolverUsed then
		return false
	end
	self.EvolverUsed = true
	self.Weapon = WeaponMath.applyEvolver(self.Weapon, multiplier)
	return true
end

function RaceSession:finish(multiplier: number, chestMultiplier: number): (number, number)
	if self.Finished then
		return 0, 0
	end
	self.Finished = true
	self.FinishMultiplier = math.max(1, multiplier)
	return self.RunCash * self.FinishMultiplier * math.max(1, chestMultiplier), self.RunTargets
end

function RaceSession:snapshot(): RaceSnapshot
	return {
		State = if self.Finished then "Finished" else "Running",
		RunCash = self.RunCash,
		RunTargets = self.RunTargets,
		TargetsCollected = self.RawTargetsCollected,
		FinishMultiplier = self.FinishMultiplier,
		Direction = self.Direction,
		Weapon = table.clone(self.Weapon),
	}
end

return RaceSession
