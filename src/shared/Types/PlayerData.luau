--!strict

local EntitlementTypes = require(script.Parent.Entitlements)
type Entitlements = EntitlementTypes.Entitlements

export type CurrencyBalances = {
	Cash: number,
	Targets: number,
}

export type UpgradeLevels = { [string]: number }

export type WeaponInventory = {
	Owned: { [string]: boolean },
	Equipped: string,
}

export type GiftData = {
	LastClaimAt: number,
}

export type ChestData = {
	LastOpenedAt: number,
}

export type PlayerData = {
	SchemaVersion: number,
	Currencies: CurrencyBalances,
	Rebirths: number,
	Upgrades: UpgradeLevels,
	Weapons: WeaponInventory,
	Gift: GiftData,
	Chest: ChestData,
	ProcessedReceipts: { [string]: number },
}

export type PlayerSnapshot = {
	Currencies: CurrencyBalances,
	Rebirths: number,
	Upgrades: UpgradeLevels,
	Weapons: WeaponInventory,
	Entitlements: Entitlements,
}

return table.freeze({})
