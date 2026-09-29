--!strict

local RaceTypes = require(script.Parent.Parent.Types.Race)
type RunWeaponStats = RaceTypes.RunWeaponStats

local WeaponMath = {}

local MIN_DAMAGE = 1
local MIN_RANGE = 8
local MIN_FIRE_RATE = 0.5
local MAX_FIRE_RATE = 20

function WeaponMath.isAimWithinCone(
	aim: Vector3,
	forward: Vector3,
	toleranceDegrees: number
): boolean
	return aim.Unit:Dot(forward.Unit) >= math.cos(math.rad(toleranceDegrees))
end

function WeaponMath.applyGate(
	stats: RunWeaponStats,
	statName: string,
	delta: number
): RunWeaponStats
	local nextStats: RunWeaponStats = table.clone(stats)

	if statName == "Damage" then
		nextStats.Damage = math.max(MIN_DAMAGE, stats.Damage + delta)
	elseif statName == "Range" then
		nextStats.Range = math.max(MIN_RANGE, stats.Range + delta)
	elseif statName == "FireRate" then
		nextStats.FireRate = math.clamp(stats.FireRate + delta * 0.1, MIN_FIRE_RATE, MAX_FIRE_RATE)
	end

	return nextStats
end

function WeaponMath.applyPenalty(stats: RunWeaponStats, fraction: number): RunWeaponStats
	local clamped = math.clamp(fraction, 0, 0.95)
	return {
		Damage = math.max(MIN_DAMAGE, stats.Damage * (1 - clamped)),
		Range = math.max(MIN_RANGE, stats.Range * (1 - clamped)),
		FireRate = math.max(MIN_FIRE_RATE, stats.FireRate * (1 - clamped)),
	}
end

function WeaponMath.applyEvolver(stats: RunWeaponStats, multiplier: number): RunWeaponStats
	local safeMultiplier = math.max(1, multiplier)
	return {
		Damage = stats.Damage * safeMultiplier,
		Range = stats.Range * safeMultiplier,
		FireRate = math.min(MAX_FIRE_RATE, stats.FireRate * safeMultiplier),
	}
end

return table.freeze(WeaponMath)
