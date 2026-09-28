--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)

type PlayerData = PlayerDataTypes.PlayerData
type MutableData = { [string | number]: unknown }

local CURRENT_SCHEMA_VERSION = 6
local Migrations = {}

local function tableOrEmpty(value: unknown): MutableData
	return if type(value) == "table" then value :: MutableData else {}
end

local function numberOr(value: unknown, fallback: number): number
	return if type(value) == "number"
			and value == value
			and value ~= math.huge
			and value ~= -math.huge
		then value
		else fallback
end

local function maxLevelForUpgrade(upgradeId: string): number?
	local definition = ProgressionConfig[upgradeId]
	if definition == nil then
		return nil
	end
	if definition.MaxLevel ~= nil then
		return definition.MaxLevel
	end
	if definition.MaxValue ~= nil and definition.Step > 0 then
		return math.max(
			0,
			math.floor((definition.MaxValue - definition.BaseValue) / definition.Step + 0.5)
		)
	end
	if definition.MinValue ~= nil and definition.Step < 0 then
		return math.max(
			0,
			math.floor((definition.MinValue - definition.BaseValue) / definition.Step + 0.5)
		)
	end
	return nil
end

local function levelFromLegacyValue(upgradeId: string, value: unknown): number
	local definition = ProgressionConfig[upgradeId]
	if definition == nil then
		return 0
	end
	local numericValue = numberOr(value, definition.BaseValue)
	if definition.Step == 0 then
		return 0
	end
	local level =
		math.max(0, math.floor((numericValue - definition.BaseValue) / definition.Step + 0.5))
	local maxLevel = maxLevelForUpgrade(upgradeId)
	return if maxLevel ~= nil then math.min(level, maxLevel) else level
end

local function migrateLegacyArray(rawData: MutableData)
	local upgrades = Progression.getDefaultUpgradeLevels()
	upgrades.TrackLength = levelFromLegacyValue("TrackLength", rawData[2])
	upgrades.FinishLength = levelFromLegacyValue("FinishLength", rawData[3])
	upgrades.CashMultiplier = levelFromLegacyValue("CashMultiplier", rawData[5])
	upgrades.BoosterStrength = levelFromLegacyValue("BoosterStrength", rawData[6])
	upgrades.BoosterSpawnChance = levelFromLegacyValue("BoosterSpawnChance", rawData[7])
	upgrades.NegativeBoosterChance = levelFromLegacyValue("NegativeBoosterChance", rawData[8])
	upgrades.PadSpawnChance = levelFromLegacyValue("PadSpawnChance", rawData[9])
	upgrades.NegativePadChance = levelFromLegacyValue("NegativePadChance", rawData[10])
	upgrades.TargetSpawnChance = levelFromLegacyValue("TargetSpawnChance", rawData[11])
	upgrades.ObstacleSpawnChance = levelFromLegacyValue("ObstacleSpawnChance", rawData[12])

	local owned: { [string]: boolean } = {
		[GameConfig.StarterWeaponId] = true,
	}
	local index = 20
	while rawData[index] ~= nil do
		local weaponId = rawData[index]
		if type(weaponId) == "string" and WeaponConfig[weaponId] ~= nil then
			owned[weaponId] = true
		end
		index += 1
	end

	local lastOpenAt = math.max(0, numberOr(rawData[18], 0))
	rawData.Currencies = {
		Cash = math.max(0, numberOr(rawData[16], 0)),
		Targets = math.max(0, numberOr(rawData[17], 0)),
	}
	rawData.Rebirths = math.max(0, math.floor(numberOr(rawData[1], 0)))
	rawData.Upgrades = upgrades
	rawData.Weapons = {
		Owned = owned,
		Equipped = GameConfig.StarterWeaponId,
	}
	rawData.Gift = { LastClaimAt = 0 }
	rawData.Chest = { LastOpenedAt = lastOpenAt }
	rawData.ProcessedReceipts = {}

	for key in rawData do
		if type(key) == "number" then
			rawData[key] = nil
		end
	end
	rawData.SchemaVersion = 4
end

local function migrateToStructuredData(rawData: MutableData)
	local currencies = tableOrEmpty(rawData.Currencies)
	local cash = if currencies.Cash ~= nil then currencies.Cash else rawData.Cash
	local targets = if currencies.Targets ~= nil then currencies.Targets else rawData.Targets
	currencies.Cash = math.max(0, numberOr(cash, 0))
	currencies.Targets = math.max(0, numberOr(targets, 0))
	rawData.Currencies = currencies

	local upgrades = tableOrEmpty(rawData.Upgrades)
	local legacyLevels = tableOrEmpty(rawData.UpgradeLevels)
	for upgradeId, defaultLevel in Progression.getDefaultUpgradeLevels() do
		local candidate = if upgrades[upgradeId] ~= nil
			then upgrades[upgradeId]
			else legacyLevels[upgradeId]
		upgrades[upgradeId] = math.max(0, math.floor(numberOr(candidate, defaultLevel)))
	end
	rawData.Upgrades = upgrades
	rawData.UpgradeLevels = nil

	local weapons = tableOrEmpty(rawData.Weapons)
	local ownedInput = tableOrEmpty(weapons.Owned)
	local owned: MutableData = {}
	for weaponId, isOwned in ownedInput do
		if type(weaponId) == "string" and isOwned == true and WeaponConfig[weaponId] ~= nil then
			owned[weaponId] = true
		end
	end
	owned[GameConfig.StarterWeaponId] = true
	weapons.Owned = owned
	if type(weapons.Equipped) ~= "string" or owned[weapons.Equipped] ~= true then
		weapons.Equipped = GameConfig.StarterWeaponId
	end
	rawData.Weapons = weapons

	local gift = tableOrEmpty(rawData.Gift)
	local lastGiftClaimAt = if gift.LastClaimAt ~= nil
		then gift.LastClaimAt
		else rawData.LastGiftClaimAt
	gift.LastClaimAt = math.max(0, numberOr(lastGiftClaimAt, 0))
	rawData.Gift = gift
	rawData.LastGiftClaimAt = nil

	local chest = tableOrEmpty(rawData.Chest)
	local lastChestOpenedAt = if chest.LastOpenedAt ~= nil
		then chest.LastOpenedAt
		else rawData.LastChestOpenedAt
	chest.LastOpenedAt = math.max(0, numberOr(lastChestOpenedAt, 0))
	rawData.Chest = chest
	rawData.LastChestOpenedAt = nil

	rawData.ProcessedReceipts = tableOrEmpty(rawData.ProcessedReceipts)
	rawData.Rebirths = math.max(0, math.floor(numberOr(rawData.Rebirths, 0)))
end

function Migrations.apply(rawData: MutableData): PlayerData
	if rawData.SchemaVersion == nil and rawData[1] ~= nil then
		migrateLegacyArray(rawData)
	end

	local version = math.max(1, math.floor(numberOr(rawData.SchemaVersion, 1)))
	if version > CURRENT_SCHEMA_VERSION then
		error(
			string.format(
				"Profile schema %d is newer than runtime schema %d",
				version,
				CURRENT_SCHEMA_VERSION
			)
		)
	end

	if version < 4 then
		migrateToStructuredData(rawData)
		version = 4
	end

	if version < 5 then
		local receipts = tableOrEmpty(rawData.ProcessedReceipts)
		for purchaseId, timestamp in receipts do
			if type(purchaseId) ~= "string" or type(timestamp) ~= "number" then
				receipts[purchaseId] = nil
			end
		end
		rawData.ProcessedReceipts = receipts
		version = 5
	end

	if version < 6 then
		rawData.Social = nil
		version = 6
	end

	rawData.SchemaVersion = version
	return rawData :: PlayerData
end

return table.freeze(Migrations)
