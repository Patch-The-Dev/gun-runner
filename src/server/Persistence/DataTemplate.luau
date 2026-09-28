--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)

type PlayerData = PlayerDataTypes.PlayerData

local template: PlayerData = {
	SchemaVersion = 6,
	Currencies = {
		Cash = 0,
		Targets = 0,
	},
	Rebirths = 0,
	Upgrades = Progression.getDefaultUpgradeLevels(),
	Weapons = {
		Owned = {
			[GameConfig.StarterWeaponId] = true,
		},
		Equipped = GameConfig.StarterWeaponId,
	},
	Gift = {
		LastClaimAt = 0,
	},
	Chest = {
		LastOpenedAt = 0,
	},
	ProcessedReceipts = {},
}

return template
