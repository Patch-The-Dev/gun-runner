--!strict

local CommonTypes = require(script.Parent.Common)
type GateStat = CommonTypes.GateStat
type RaceState = CommonTypes.RaceState

export type RunWeaponStats = {
	Damage: number,
	Range: number,
	FireRate: number,
}

export type GateSpec = {
	Id: string,
	Lane: number,
	Stat: GateStat,
	Delta: number,
	ShotStep: number,
	HasPad: boolean,
	PadNegative: boolean,
}

export type SegmentSpec = {
	Index: number,
	Gates: { GateSpec },
	HasTarget: boolean,
	HasObstacle: boolean,
}

export type TrackPlan = {
	Seed: number,
	Segments: { SegmentSpec },
	FinishLength: number,
	TargetCount: number,
	HasEvolver: boolean,
}

export type RaceSnapshot = {
	State: RaceState,
	RunCash: number,
	RunTargets: number,
	TargetsCollected: number,
	FinishMultiplier: number,
	Direction: Vector3?,
	Weapon: RunWeaponStats?,
}

return table.freeze({})
