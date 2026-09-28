--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local t = require(ReplicatedStorage.Packages.t)

local Contract = {}

Contract.UpgradeRequest = t.strictInterface({
	upgradeId = t.string,
})

Contract.WeaponRequest = t.strictInterface({
	weaponId = t.string,
})

Contract.FireWeaponRequest = t.strictInterface({
	direction = t.Vector3,
})

return table.freeze(Contract)
