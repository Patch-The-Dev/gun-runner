--!strict

export type WeaponDefinition = {
	Id: string,
	DisplayName: string,
	Price: number,
	Damage: number,
	Range: number,
	FireRate: number,
}

local weapons: { [string]: WeaponDefinition } = {
	Revolver = {
		Id = "Revolver",
		DisplayName = "Revolver",
		Price = 0,
		Damage = 1,
		Range = 20,
		FireRate = 2,
	},
	Repeater = {
		Id = "Repeater",
		DisplayName = "Repeater",
		Price = 15_000,
		Damage = 1.4,
		Range = 24,
		FireRate = 2.5,
	},
	Rifle = {
		Id = "Rifle",
		DisplayName = "Rifle",
		Price = 100_000,
		Damage = 2.2,
		Range = 32,
		FireRate = 3.1,
	},
	RPK = {
		Id = "RPK",
		DisplayName = "RPK",
		Price = 750_000,
		Damage = 2.8,
		Range = 38,
		FireRate = 4.5,
	},
	Railgun = {
		Id = "Railgun",
		DisplayName = "Railgun",
		Price = 5_000_000,
		Damage = 5.5,
		Range = 52,
		FireRate = 1.35,
	},
}

return table.freeze(weapons)
