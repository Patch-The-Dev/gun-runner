--!strict

export type Currency = "Cash" | "Targets"
export type RaceState = "Idle" | "Running" | "Finished"
export type GateStat = "Damage" | "Range" | "FireRate"

export type ActionResult = {
	ok: boolean,
	error: string?,
}

return table.freeze({})
