--!strict

local PlayerDataTypes = require(script.Parent.Parent.Types.PlayerData)
local ProgressionConfig = require(script.Parent.Parent.Config.ProgressionConfig)

type PlayerData = PlayerDataTypes.PlayerData

local Progression = {}

function Progression.getRebirthCashMultiplier(rebirths: number): number
	local normalized = math.max(0, math.floor(rebirths))
	if normalized == 0 then
		return 1
	elseif normalized <= 10 then
		return 10 + (normalized - 1) * 5
	end
	return 55 + (normalized - 10) * 2
end

function Progression.getRebirthTargetMultiplier(rebirths: number): number
	return Progression.getRebirthCashMultiplier(rebirths)
end

function Progression.getRebirthCost(rebirths: number): number
	local normalized = math.max(0, math.floor(rebirths))
	if normalized == 0 then
		return 100_000
	elseif normalized <= 5 then
		return 600_000 * normalized
	elseif normalized < 10 then
		return 1_000_000 * normalized
	end
	return 1_400_000 * normalized
end

function Progression.getUpgradeValue(upgradeId: string, level: number): number?
	local definition = ProgressionConfig[upgradeId]
	if definition == nil or level < 0 or level ~= level or math.abs(level) == math.huge then
		return nil
	end

	local boundedLevel = if definition.MaxLevel ~= nil
		then math.min(math.floor(level), definition.MaxLevel)
		else math.floor(level)
	local value = definition.BaseValue + definition.Step * boundedLevel
	if definition.MinValue ~= nil then
		value = math.max(value, definition.MinValue)
	end
	if definition.MaxValue ~= nil then
		value = math.min(value, definition.MaxValue)
	end
	return value
end

function Progression.getUpgradeCost(upgradeId: string, level: number): number?
	local definition = ProgressionConfig[upgradeId]
	if definition == nil or level < 0 then
		return nil
	end

	local normalizedLevel = math.floor(level)
	return math.max(1, math.floor(definition.BaseCost * (definition.CostGrowth ^ normalizedLevel)))
end

function Progression.isMaxLevel(upgradeId: string, level: number): boolean
	local definition = ProgressionConfig[upgradeId]
	if definition == nil then
		return true
	end
	if definition.MaxLevel ~= nil and level >= definition.MaxLevel then
		return true
	end
	if definition.MaxValue ~= nil then
		local value = Progression.getUpgradeValue(upgradeId, level)
		return value ~= nil and value >= definition.MaxValue
	end
	if definition.MinValue ~= nil and definition.Step < 0 then
		local value = Progression.getUpgradeValue(upgradeId, level)
		return value ~= nil and value <= definition.MinValue
	end
	return false
end

function Progression.getDefaultUpgradeLevels(): { [string]: number }
	local levels: { [string]: number } = {}
	for upgradeId in ProgressionConfig do
		levels[upgradeId] = 0
	end
	return levels
end

function Progression.resetRebirthProgress(data: PlayerData)
	for upgradeId, definition in ProgressionConfig do
		if definition.ResetOnRebirth then
			data.Upgrades[upgradeId] = 0
		end
	end
end

return table.freeze(Progression)
