--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)
local TrackPlanner = require(ReplicatedStorage.Shared.Domain.TrackPlanner)
local TrackRenderer = require(script.Parent.Parent.Infrastructure.TrackRenderer)

type PlayerData = PlayerDataTypes.PlayerData

local TrackService = Knit.CreateService({ Name = "TrackService", Client = {} })

local function upgradeValue(data: PlayerData, upgradeId: string, fallback: number): number
	return Progression.getUpgradeValue(upgradeId, data.Upgrades[upgradeId] or 0) or fallback
end

function TrackService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._base = Knit.GetService("BaseService")
	self._tracks = {} :: { [Player]: Model }
end

function TrackService:KnitStart()
	self._data.SessionRemoving:Connect(function(player)
		self:ClearTrack(player)
	end)
end

function TrackService:CreateTrack(player: Player): Model?
	local session = self._data:GetSession(player)
	local base = self._base:GetBase(player)
	if session == nil or base == nil then
		return nil
	end

	self:ClearTrack(player)
	local data = session.Data
	local seed = math.abs((player.UserId * 1_103_515_245 + os.time()) % 2_147_483_647)
	local plan = TrackPlanner.create(seed, {
		BoosterStrength = upgradeValue(data, "BoosterStrength", 10),
		BoosterSpawnChance = upgradeValue(data, "BoosterSpawnChance", 0.5),
		NegativeBoosterChance = upgradeValue(data, "NegativeBoosterChance", 0.5),
		PadSpawnChance = upgradeValue(data, "PadSpawnChance", 0.2),
		NegativePadChance = upgradeValue(data, "NegativePadChance", 0.5),
		TargetSpawnChance = upgradeValue(data, "TargetSpawnChance", 0.2),
		ObstacleSpawnChance = upgradeValue(data, "ObstacleSpawnChance", 0.5),
		TrackLength = upgradeValue(data, "TrackLength", 5),
		FinishLength = upgradeValue(data, "FinishLength", 3),
		Rebirths = data.Rebirths,
	})

	local model = TrackRenderer.render(base, player.UserId, plan)
	if model ~= nil then
		model:SetAttribute("TargetCount", plan.TargetCount)
		self._tracks[player] = model
	end
	return model
end

function TrackService:GetTrack(player: Player): Model?
	return self._tracks[player]
end

function TrackService:ClearTrack(player: Player)
	local model = self._tracks[player]
	self._tracks[player] = nil
	if model ~= nil and model.Parent ~= nil then
		model:Destroy()
	end
end

return TrackService
