--!strict

local CommonTypes = require(script.Parent.Parent.Types.Common)
type Currency = CommonTypes.Currency

export type DeveloperProduct = {
	Currency: Currency,
	Amount: number,
}

export type GamePassEffect = {
	CashBonus: number?,
	TargetBonus: number?,
	RebirthBonus: number?,
	ProjectileCount: number?,
	ExplosiveRounds: boolean?,
}

return table.freeze({
	DeveloperProducts = {
		[1884207018] = { Currency = "Targets", Amount = 5_000 },
		[1884207405] = { Currency = "Targets", Amount = 15_000 },
		[1884208267] = { Currency = "Targets", Amount = 50_000 },
		[1884208988] = { Currency = "Targets", Amount = 250_000 },
		[1884209634] = { Currency = "Targets", Amount = 500_000 },
		[1884210216] = { Currency = "Targets", Amount = 1_000_000 },
		[1884210927] = { Currency = "Cash", Amount = 200_000 },
		[1884211386] = { Currency = "Cash", Amount = 1_000_000 },
		[1884211803] = { Currency = "Cash", Amount = 3_000_000 },
		[1884212636] = { Currency = "Cash", Amount = 10_000_000 },
		[1884213227] = { Currency = "Cash", Amount = 100_000_000 },
		[1884213736] = { Currency = "Cash", Amount = 1_000_000_000 },
	} :: { [number]: DeveloperProduct },

	GamePasses = {
		[869186485] = { CashBonus = 4 },
		[869662678] = { CashBonus = 9 },
		[869207509] = { TargetBonus = 4 },
		[869451152] = { TargetBonus = 9 },
		[869318346] = { RebirthBonus = 1 },
		[869205629] = { RebirthBonus = 2 },
		[869353401] = { ExplosiveRounds = true },
		[869538248] = { ProjectileCount = 2 },
		[869173976] = { ProjectileCount = 3 },
	} :: { [number]: GamePassEffect },
})
