--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local EntitlementTypes = require(ReplicatedStorage.Shared.Types.Entitlements)
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

type Entitlements = EntitlementTypes.Entitlements
type GamePassEffect = ProductConfig.GamePassEffect

export type LookupResult = {
	Id: number,
	Success: boolean,
	Owns: boolean?,
}

local EntitlementPolicy = {}

function EntitlementPolicy.merge(
	known: { [number]: boolean },
	results: { LookupResult }
): ({ [number]: boolean }, boolean)
	local nextKnown = table.clone(known)
	local failed = false
	for _, result in results do
		if result.Success then
			nextKnown[result.Id] = result.Owns == true
		else
			failed = true
		end
	end
	return nextKnown, failed
end

local function applyEffect(state: Entitlements, effect: GamePassEffect)
	state.CashMultiplier += effect.CashBonus or 0
	state.TargetMultiplier += effect.TargetBonus or 0
	state.RebirthIncrement += effect.RebirthBonus or 0
	state.ProjectileCount = math.max(state.ProjectileCount, effect.ProjectileCount or 1)
	state.ExplosiveRounds = state.ExplosiveRounds or effect.ExplosiveRounds == true
end

function EntitlementPolicy.build(known: { [number]: boolean }): Entitlements
	local state: Entitlements = {
		CashMultiplier = 1,
		TargetMultiplier = 1,
		RebirthIncrement = 1,
		ProjectileCount = 1,
		ExplosiveRounds = false,
	}
	for gamePassId, effect in ProductConfig.GamePasses do
		if known[gamePassId] == true then
			applyEffect(state, effect)
		end
	end
	return state
end

return table.freeze(EntitlementPolicy)
