--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local CommonTypes = require(ReplicatedStorage.Shared.Types.Common)
local Contract = require(ReplicatedStorage.Shared.Network.Contract)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local NetworkTypes = require(ReplicatedStorage.Shared.Types.Network)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)
local ProgressionConfig = require(ReplicatedStorage.Shared.Config.ProgressionConfig)

type ActionResult = CommonTypes.ActionResult
type UpgradeRequest = NetworkTypes.UpgradeRequest

local ProgressionService = Knit.CreateService({
	Name = "ProgressionService",
	Client = { ProgressionChanged = Knit.CreateSignal() },
})

function ProgressionService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._economy = Knit.GetService("EconomyService")
	self._entitlements = Knit.GetService("EntitlementService")
end

function ProgressionService.Client:BuyUpgrade(player: Player, request: unknown)
	if not Contract.UpgradeRequest(request) then
		return { ok = false, error = "invalid_request" }
	end
	local typedRequest = request :: UpgradeRequest
	return self.Server:BuyUpgrade(player, typedRequest.upgradeId)
end

function ProgressionService:BuyUpgrade(player: Player, upgradeId: string): ActionResult
	local definition = ProgressionConfig[upgradeId]
	local session = self._data:GetSession(player)
	local data = if session ~= nil then session.Data else nil
	if definition == nil then
		return { ok = false, error = "unknown_upgrade" }
	end
	if data == nil then
		return { ok = false, error = "profile_not_loaded" }
	end
	if session ~= nil and session.Race ~= nil then
		return { ok = false, error = "race_in_progress" }
	end

	local level = math.max(0, math.floor(data.Upgrades[upgradeId] or 0))
	if Progression.isMaxLevel(upgradeId, level) then
		return { ok = false, error = "max_level" }
	end

	local cost = Progression.getUpgradeCost(upgradeId, level)
	if cost == nil or not self._economy:Spend(player, definition.Currency, cost, false) then
		return { ok = false, error = "insufficient_funds" }
	end

	data.Upgrades[upgradeId] = level + 1
	self._data:PublishSnapshot(player)
	self.Client.ProgressionChanged:Fire(player, upgradeId, data.Upgrades[upgradeId])
	return { ok = true }
end

function ProgressionService.Client:BuyRebirth(player: Player)
	return self.Server:BuyRebirth(player)
end

function ProgressionService:BuyRebirth(player: Player): ActionResult
	local session = self._data:GetSession(player)
	local data = if session ~= nil then session.Data else nil
	if data == nil then
		return { ok = false, error = "profile_not_loaded" }
	end
	if session ~= nil and session.Race ~= nil then
		return { ok = false, error = "race_in_progress" }
	end

	local cost = Progression.getRebirthCost(data.Rebirths)
	if not self._economy:Spend(player, "Cash", cost, false) then
		return { ok = false, error = "insufficient_cash" }
	end

	data.Rebirths += self._entitlements:Get(player).RebirthIncrement
	Progression.resetRebirthProgress(data)
	data.Currencies.Cash = 0
	data.Currencies.Targets = 0
	data.Weapons = {
		Owned = { [GameConfig.StarterWeaponId] = true },
		Equipped = GameConfig.StarterWeaponId,
	}

	self._data:PublishSnapshot(player)
	self.Client.ProgressionChanged:Fire(player, "Rebirths", data.Rebirths)
	return { ok = true }
end

return ProgressionService
