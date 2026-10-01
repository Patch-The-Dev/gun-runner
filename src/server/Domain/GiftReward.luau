--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)

local GiftReward = {}
local MAX_SAFE_INTEGER = 9_007_199_254_740_991

local function validAmount(value: number): boolean
	return value > 0 and value == value and value <= MAX_SAFE_INTEGER and value % 1 == 0
end

function GiftReward.apply(
	data: PlayerDataTypes.PlayerData,
	cash: number,
	targets: number,
	now: number
): boolean
	if
		not validAmount(cash)
		or not validAmount(targets)
		or now ~= now
		or now < 0
		or now >= math.huge
		or now - data.Gift.LastClaimAt < GameConfig.GiftCooldownSeconds
	then
		return false
	end
	local newCash = data.Currencies.Cash + cash
	local newTargets = data.Currencies.Targets + targets
	if not validAmount(newCash) or not validAmount(newTargets) then
		return false
	end
	-- Validate both balances before a synchronous commit. No service calls or yields.
	data.Currencies = { Cash = newCash, Targets = newTargets }
	data.Gift.LastClaimAt = now
	return true
end

return table.freeze(GiftReward)
