--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local GiftReward = require(script.Parent.Parent.Domain.GiftReward)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)

local GiftService = Knit.CreateService({ Name = "GiftService", Client = {} })

function GiftService:KnitInit()
	self._requests = Knit.GetService("RequestGateService")
	self._data = Knit.GetService("DataService")
end

function GiftService:GetStatus(player: Player)
	local data = self._data:GetData(player)
	if data == nil then
		return nil
	end
	local elapsed = os.time() - data.Gift.LastClaimAt
	local remaining = math.max(0, GameConfig.GiftCooldownSeconds - elapsed)
	return {
		ready = remaining == 0,
		remaining = remaining,
	}
end

function GiftService.Client:GetStatus(player: Player)
	if not self.Server._requests:Allow(player, "Read") then
		return nil
	end
	return self.Server:GetStatus(player)
end

function GiftService.Client:Claim(player: Player)
	if not self.Server._requests:Allow(player, "Claim") then
		return { ok = false, error = "rate_limited" }
	end
	return self.Server:Claim(player)
end

function GiftService:Claim(player: Player)
	local session = self._data:GetSession(player)
	if session == nil then
		return { ok = false, error = "profile_not_loaded" }
	end
	local data = session.Data
	local now = os.time()
	if now - data.Gift.LastClaimAt < GameConfig.GiftCooldownSeconds then
		return { ok = false, error = "cooldown" }
	end

	local cashReward = math.floor(
		2_500
			* Progression.getRebirthCashMultiplier(data.Rebirths)
			* session.Entitlements.CashMultiplier
	)
	local targetReward = math.floor(
		5
			* Progression.getRebirthTargetMultiplier(data.Rebirths)
			* session.Entitlements.TargetMultiplier
	)
	if not GiftReward.apply(data, cashReward, targetReward, now) then
		return { ok = false, error = "award_failed" }
	end
	local published, publishError = pcall(self._data.PublishSnapshot, self._data, player)
	if not published then
		warn(`Gift notification failed: {tostring(publishError)}`)
	end
	return { ok = true, cash = cashReward, targets = targetReward }
end

return GiftService
