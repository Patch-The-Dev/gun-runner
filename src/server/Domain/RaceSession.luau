--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)
local TrackConfig = require(ReplicatedStorage.Shared.Config.TrackConfig)
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
		LastCheckpointPosition: Vector3,
		LastCheckpointAt: number,
		LastObservedPosition: Vector3,
		LastObservedAt: number,
		InvalidMovement: boolean,
		InvalidReason: string?,
		MaxObservedSpeed: number,
	},
	RaceSession
))

local function isFinitePositive(value: number): boolean
	return value > 0 and value == value and value ~= math.huge
end

local function isFiniteVector3(value: Vector3): boolean
	return value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

local function isNearTrackPosition(
	direction: Vector3,
	position: Vector3,
	characterPosition: Vector3
): boolean
	local offset = characterPosition - position
	local horizontal = Vector3.new(offset.X, 0, offset.Z)
	local forward = math.abs(horizontal:Dot(direction))
	local lateral = (horizontal - direction * horizontal:Dot(direction)).Magnitude
	return forward <= TrackConfig.CheckpointForwardTolerance
		and lateral <= TrackConfig.CheckpointLateralTolerance
		and math.abs(offset.Y) <= TrackConfig.CheckpointVerticalTolerance
end

function RaceSession.new(
	baseWeapon: RunWeaponStats,
	direction: Vector3,
	totalCheckpoints: number,
	startPosition: Vector3,
	startedAt: number?
): RaceSession
	assert(direction.Magnitude > 0.001, "Race direction must be non-zero")
	local now = startedAt or os.clock()
	return setmetatable({
		StartedAt = now,
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
		LastCheckpointPosition = startPosition,
		LastCheckpointAt = now,
		LastObservedPosition = startPosition,
		LastObservedAt = now,
		InvalidMovement = false,
		InvalidReason = nil,
		MaxObservedSpeed = 0,
	}, RaceSession)
end

function RaceSession:elapsed(): number
	return math.max(0, os.clock() - self.StartedAt)
end

function RaceSession:observePosition(position: Vector3, now: number?): boolean
	if self.Finished or self.InvalidMovement then
		return false
	end
	if not isFiniteVector3(position) then
		self.InvalidMovement = true
		self.InvalidReason = "non_finite_position"
		return false
	end
	local observedAt = now or os.clock()
	local elapsed = observedAt - self.LastObservedAt
	local delta = position - self.LastObservedPosition
	local horizontalDistance = Vector3.new(delta.X, 0, delta.Z).Magnitude
	if
		horizontalDistance
		> TrackConfig.MaxObservedHorizontalSpeed * math.max(0, elapsed)
			+ TrackConfig.PositionSampleSlack
	then
		self.InvalidMovement = true
		self.InvalidReason = "horizontal_speed"
		self.MaxObservedSpeed =
			math.max(self.MaxObservedSpeed, horizontalDistance / math.max(elapsed, 0.001))
		return false
	end
	if elapsed < TrackConfig.PositionSampleInterval then
		return true
	end
	self.MaxObservedSpeed = math.max(self.MaxObservedSpeed, horizontalDistance / elapsed)
	self.LastObservedPosition = position
	self.LastObservedAt = observedAt
	return true
end

function RaceSession:canTouchTrackObject(
	segmentIndex: number,
	objectPosition: Vector3,
	characterPosition: Vector3,
	now: number?,
	forwardHalfExtent: number?
): boolean
	if
		self.Finished
		or self.InvalidMovement
		or segmentIndex ~= self.LastCheckpointIndex + 1
		or segmentIndex > self.TotalCheckpoints + 1
	then
		return false
	end
	local offset = characterPosition - objectPosition
	if
		Vector3.new(offset.X, 0, offset.Z).Magnitude > 9
		or math.abs(offset.Y) > TrackConfig.CheckpointVerticalTolerance
	then
		return false
	end
	local observedAt = now or os.clock()
	if not self:observePosition(characterPosition, observedAt) then
		return false
	end
	local distance = (objectPosition - self.LastCheckpointPosition):Dot(self.Direction)
	local minimumTime = math.max(
		0,
		distance - math.max(0, forwardHalfExtent or 0) - TrackConfig.CheckpointTravelSlack - 3
	) / TrackConfig.RunnerFastPadSpeed * TrackConfig.MinimumFinishTimeScale
	return observedAt - self.LastCheckpointAt >= minimumTime
end

function RaceSession:touchCheckpoint(
	index: number,
	checkpointPosition: Vector3,
	characterPosition: Vector3,
	now: number?
): boolean
	if self.Finished or self.InvalidMovement then
		return false
	end

	local normalized = math.floor(index)
	if normalized ~= self.LastCheckpointIndex + 1 or normalized > self.TotalCheckpoints then
		return false
	end
	if not isNearTrackPosition(self.Direction, checkpointPosition, characterPosition) then
		return false
	end
	local observedAt = now or os.clock()
	if not self:observePosition(characterPosition, observedAt) then
		return false
	end
	local distance = (checkpointPosition - self.LastCheckpointPosition):Dot(self.Direction)
	local minimumTime = math.max(0, distance - TrackConfig.CheckpointTravelSlack)
		/ TrackConfig.RunnerFastPadSpeed
		* TrackConfig.MinimumFinishTimeScale
	if observedAt - self.LastCheckpointAt < minimumTime then
		return false
	end

	self.LastCheckpointIndex = normalized
	self.LastCheckpointPosition = checkpointPosition
	self.LastCheckpointAt = observedAt
	return true
end

function RaceSession:canFinish(
	minimumElapsedSeconds: number,
	finishPosition: Vector3,
	characterPosition: Vector3,
	now: number?
): boolean
	if
		self.Finished
		or self.InvalidMovement
		or self.LastCheckpointIndex < self.TotalCheckpoints
	then
		return false
	end
	if not isNearTrackPosition(self.Direction, finishPosition, characterPosition) then
		return false
	end
	local observedAt = now or os.clock()
	if not self:observePosition(characterPosition, observedAt) then
		return false
	end
	local distance = (finishPosition - self.LastCheckpointPosition):Dot(self.Direction)
	local minimumSegmentTime = math.max(0, distance - TrackConfig.CheckpointTravelSlack)
		/ TrackConfig.RunnerFastPadSpeed
		* TrackConfig.MinimumFinishTimeScale
	return observedAt - self.StartedAt >= math.max(0, minimumElapsedSeconds)
		and observedAt - self.LastCheckpointAt >= minimumSegmentTime
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
