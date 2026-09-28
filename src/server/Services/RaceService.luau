--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Progression = require(ReplicatedStorage.Shared.Domain.Progression)
local RaceSession = require(script.Parent.Parent.Domain.RaceSession)
local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)
local TrackConfig = require(ReplicatedStorage.Shared.Config.TrackConfig)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)

type RaceSnapshot = RaceTypes.RaceSnapshot

local RaceService = Knit.CreateService({
	Name = "RaceService",
	Client = {
		RaceChanged = Knit.CreateSignal(),
	},
})

local IDLE_SNAPSHOT: RaceSnapshot = {
	State = "Idle",
	RunCash = 0,
	RunTargets = 0,
	TargetsCollected = 0,
	FinishMultiplier = 1,
	Direction = nil,
	Weapon = nil,
}

local function ownsRaceInstance(player: Player, instance: Instance): boolean
	return instance:GetAttribute("OwnerUserId") == player.UserId
end

local function resolveDirection(base: Instance): Vector3?
	local origin = base:FindFirstChild("TrackOrigin", true)
		or base:FindFirstChild("BeginLine", true)
	if origin == nil or not origin:IsA("BasePart") then
		return nil
	end
	local direction = Vector3.new(origin.CFrame.LookVector.X, 0, origin.CFrame.LookVector.Z)
	return if direction.Magnitude > 0.001 then direction.Unit else nil
end

function RaceService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._economy = Knit.GetService("EconomyService")
	self._base = Knit.GetService("BaseService")
	self._tracks = Knit.GetService("TrackService")
end

function RaceService:KnitStart()
	self._data.SessionAdded:Connect(function(player, session)
		session.Trove:Connect(player.CharacterRemoving, function()
			self:CancelRace(player)
		end)
	end)
	self._data.SessionRemoving:Connect(function(player, session)
		if session.Race ~= nil then
			session.Race = nil
		end
		self._tracks:ClearTrack(player)
	end)
end

function RaceService:StartRace(player: Player): boolean
	local session = self._data:GetSession(player)
	local base = self._base:GetBase(player)
	if session == nil or base == nil or session.Race ~= nil then
		return false
	end

	local direction = resolveDirection(base)
	if direction == nil then
		return false
	end

	local weaponDefinition = WeaponConfig[session.Data.Weapons.Equipped]
		or WeaponConfig[GameConfig.StarterWeaponId]
	if weaponDefinition == nil then
		return false
	end
	local track = self._tracks:CreateTrack(player)
	if track == nil then
		return false
	end
	local checkpointCount = track:GetAttribute("CheckpointCount")
	if type(checkpointCount) ~= "number" or checkpointCount < 1 then
		self._tracks:ClearTrack(player)
		return false
	end

	session.Race = RaceSession.new({
		Damage = weaponDefinition.Damage,
		Range = weaponDefinition.Range,
		FireRate = weaponDefinition.FireRate,
	}, direction, checkpointCount)
	base:SetAttribute("RaceActive", true)
	self.Client.RaceChanged:Fire(player, session.Race:snapshot())
	return true
end

function RaceService:GetRace(player: Player)
	local session = self._data:GetSession(player)
	return if session ~= nil then session.Race else nil
end

function RaceService:GetSnapshot(player: Player): RaceSnapshot
	local race = self:GetRace(player)
	return if race ~= nil then race:snapshot() else table.clone(IDLE_SNAPSHOT)
end

function RaceService.Client:GetSnapshot(player: Player): RaceSnapshot
	return self.Server:GetSnapshot(player)
end

function RaceService:_publish(player: Player)
	self.Client.RaceChanged:Fire(player, self:GetSnapshot(player))
end

function RaceService:CancelRace(player: Player)
	local session = self._data:GetSession(player)
	if session == nil or session.Race == nil then
		return
	end
	local base = self._base:GetBase(player)
	if base ~= nil then
		base:SetAttribute("RaceActive", false)
	end
	self._tracks:ClearTrack(player)
	session.Race = nil
	self:_publish(player)
end

function RaceService:HandleCheckpointTouched(player: Player, checkpoint: Instance): boolean
	local race = self:GetRace(player)
	if race == nil or not ownsRaceInstance(player, checkpoint) then
		return false
	end
	local checkpointIndex = checkpoint:GetAttribute("CheckpointIndex")
	if type(checkpointIndex) ~= "number" then
		return false
	end
	return race:touchCheckpoint(checkpointIndex)
end

function RaceService:HandleGateTouched(player: Player, gate: Instance): boolean
	local race = self:GetRace(player)
	if race == nil or not ownsRaceInstance(player, gate) then
		return false
	end
	local gateId = gate:GetAttribute("GateId")
	local statName = gate:GetAttribute("Stat")
	local delta = gate:GetAttribute("Delta")
	local shotStep = gate:GetAttribute("ShotStep")
	if type(gateId) ~= "string" or type(statName) ~= "string" or type(delta) ~= "number" then
		return false
	end

	if gate:GetAttribute("HasPad") == true and type(shotStep) == "number" then
		local padDelta = shotStep * 2
		delta += if gate:GetAttribute("PadNegative") == true then -padDelta else padDelta
	end

	local applied = race:applyGate(gateId, statName, delta)
	if applied then
		gate:Destroy()
		self:_publish(player)
	end
	return applied
end

function RaceService:HandleObstacleTouched(player: Player, obstacle: Instance): boolean
	local race = self:GetRace(player)
	if race == nil or not ownsRaceInstance(player, obstacle) then
		return false
	end
	local obstacleId = obstacle:GetAttribute("ObstacleId")
	if type(obstacleId) ~= "string" then
		return false
	end
	local applied = race:applyObstacle(obstacleId, TrackConfig.ObstaclePenaltyFraction)
	if applied then
		obstacle:Destroy()
		self:_publish(player)
	end
	return applied
end

function RaceService:HandleEvolverTouched(player: Player, evolver: Instance): boolean
	local race = self:GetRace(player)
	if race == nil or not ownsRaceInstance(player, evolver) then
		return false
	end
	local requiredTargets = evolver:GetAttribute("RequiredTargets")
	local multiplier = evolver:GetAttribute("Multiplier")
	if type(requiredTargets) ~= "number" or type(multiplier) ~= "number" then
		return false
	end
	if race.RawTargetsCollected < requiredTargets then
		return false
	end
	local applied = race:applyEvolver(multiplier)
	if applied then
		self:_publish(player)
	end
	return applied
end

function RaceService:HandleShotHit(player: Player, instance: Instance, damage: number): boolean
	local race = self:GetRace(player)
	if race == nil or not ownsRaceInstance(player, instance) then
		return false
	end

	if CollectionService:HasTag(instance, "RaceGate") then
		local delta = instance:GetAttribute("Delta")
		local shotStep = instance:GetAttribute("ShotStep")
		if type(delta) ~= "number" or type(shotStep) ~= "number" then
			return false
		end
		instance:SetAttribute(
			"Delta",
			math.clamp(delta + shotStep * math.max(1, damage), -100, 100)
		)
		return true
	end

	if CollectionService:HasTag(instance, "RaceTarget") then
		local targetId = instance:GetAttribute("TargetId")
		local session = self._data:GetSession(player)
		if type(targetId) ~= "string" or session == nil then
			return false
		end
		local reward = TrackConfig.TargetReward
			* Progression.getRebirthTargetMultiplier(session.Data.Rebirths)
			* session.Entitlements.TargetMultiplier
		local consumed = race:consumeTarget(targetId, reward)
		if consumed then
			instance:Destroy()
			self:_publish(player)
		end
		return consumed
	end

	if CollectionService:HasTag(instance, "RacePillar") then
		local pillarId = instance:GetAttribute("PillarId")
		local health = instance:GetAttribute("Health")
		local rewardMultiplier = instance:GetAttribute("RewardMultiplier")
		local session = self._data:GetSession(player)
		if
			type(pillarId) ~= "string"
			or type(health) ~= "number"
			or type(rewardMultiplier) ~= "number"
			or session == nil
		then
			return false
		end

		health -= math.max(0, damage)
		instance:SetAttribute("Health", health)
		if health > 0 then
			return true
		end

		local cashMultiplier = Progression.getUpgradeValue(
			"CashMultiplier",
			session.Data.Upgrades.CashMultiplier or 0
		) or 1
		local inviteMultiplier = if session.InviteBonusActive
			then GameConfig.InvitePromptCashMultiplier
			else 1
		local reward = TrackConfig.PillarBaseCash
			* rewardMultiplier
			* cashMultiplier
			* Progression.getRebirthCashMultiplier(session.Data.Rebirths)
			* session.Entitlements.CashMultiplier
			* inviteMultiplier
		local consumed = race:consumePillar(pillarId, reward)
		if consumed then
			instance:Destroy()
			self:_publish(player)
		end
		return consumed
	end

	return false
end

function RaceService:HandleFinishTouched(player: Player, finish: Instance): boolean
	local session = self._data:GetSession(player)
	local race = if session ~= nil then session.Race else nil
	if session == nil or race == nil or not ownsRaceInstance(player, finish) then
		return false
	end

	local finishMultiplier = finish:GetAttribute("FinishMultiplier")
	local minimumElapsedSeconds = finish:GetAttribute("MinElapsedSeconds")
	if type(finishMultiplier) ~= "number" or type(minimumElapsedSeconds) ~= "number" then
		return false
	end
	if not race:canFinish(minimumElapsedSeconds) then
		return false
	end

	local chestMultiplier = 1
	if finish:GetAttribute("ClaimChest") == true then
		local elapsed = os.time() - session.Data.Chest.LastOpenedAt
		if elapsed >= GameConfig.ChestCooldownSeconds then
			chestMultiplier = TrackConfig.ChestBonusMultiplier
			session.Data.Chest.LastOpenedAt = os.time()
		end
	end

	local cash, targets = race:finish(math.max(1, math.floor(finishMultiplier)), chestMultiplier)
	if cash > 0 then
		self._economy:Award(player, "Cash", cash, false)
	end
	if targets > 0 then
		self._economy:Award(player, "Targets", targets, false)
	end
	self._data:PublishSnapshot(player)
	self.Client.RaceChanged:Fire(player, race:snapshot())

	local base = self._base:GetBase(player)
	if base ~= nil then
		base:SetAttribute("RaceActive", false)
	end
	self._tracks:ClearTrack(player)
	session.Race = nil
	task.defer(function()
		self._base:TeleportToBase(player)
		self:_publish(player)
	end)
	return true
end

return RaceService
