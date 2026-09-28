--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

local CommonTypes = require(ReplicatedStorage.Shared.Types.Common)
type Currency = CommonTypes.Currency

local EconomyService = Knit.CreateService({ Name = "EconomyService", Client = {} })

local function isFinitePositive(amount: number): boolean
	return amount > 0 and amount == amount and amount ~= math.huge
end

function EconomyService:KnitInit()
	self._data = Knit.GetService("DataService")
end

function EconomyService:GetBalance(player: Player, currency: Currency): number?
	local data = self._data:GetData(player)
	return if data ~= nil then data.Currencies[currency] else nil
end

function EconomyService:CanAfford(player: Player, currency: Currency, amount: number): boolean
	local balance = self:GetBalance(player, currency)
	return balance ~= nil and isFinitePositive(amount) and balance >= amount
end

function EconomyService:Spend(
	player: Player,
	currency: Currency,
	amount: number,
	publish: boolean?
): boolean
	if not self:CanAfford(player, currency, amount) then
		return false
	end
	local data = self._data:GetData(player)
	if data == nil then
		return false
	end
	data.Currencies[currency] -= amount
	if publish ~= false then
		self._data:PublishSnapshot(player)
	end
	return true
end

function EconomyService:Award(
	player: Player,
	currency: Currency,
	amount: number,
	publish: boolean?
): boolean
	if not isFinitePositive(amount) then
		return false
	end
	local data = self._data:GetData(player)
	if data == nil then
		return false
	end
	data.Currencies[currency] += amount
	if publish ~= false then
		self._data:PublishSnapshot(player)
	end
	return true
end

function EconomyService:ResetCurrencies(player: Player, publish: boolean?): boolean
	local data = self._data:GetData(player)
	if data == nil then
		return false
	end
	data.Currencies.Cash = 0
	data.Currencies.Targets = 0
	if publish ~= false then
		self._data:PublishSnapshot(player)
	end
	return true
end

return EconomyService
