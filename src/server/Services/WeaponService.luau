--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)

local CommonTypes = require(ReplicatedStorage.Shared.Types.Common)
local Contract = require(ReplicatedStorage.Shared.Network.Contract)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local NetworkTypes = require(ReplicatedStorage.Shared.Types.Network)
local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)
local ShotAudience = require(script.Parent.Parent.Domain.ShotAudience)
local WeaponConfig = require(ReplicatedStorage.Shared.Config.WeaponConfig)
local WeaponMath = require(ReplicatedStorage.Shared.Domain.WeaponMath)

type ActionResult = CommonTypes.ActionResult
type FireWeaponRequest = NetworkTypes.FireWeaponRequest
type WeaponRequest = NetworkTypes.WeaponRequest

local WeaponService = Knit.CreateService({
	Name = "WeaponService",
	Client = {
		WeaponChanged = Knit.CreateSignal(),
		ShotReplicated = Knit.CreateSignal(),
	},
})

local function isFiniteVector3(value: Vector3): boolean
	return value.X == value.X
		and value.Y == value.Y
		and value.Z == value.Z
		and math.abs(value.X) < math.huge
		and math.abs(value.Y) < math.huge
		and math.abs(value.Z) < math.huge
end

local function spreadDirections(direction: Vector3, projectileCount: number): { Vector3 }
	local unit = direction.Unit
	if projectileCount <= 1 then
		return { unit }
	end

	local directions: { Vector3 } = {}
	local center = (projectileCount + 1) / 2
	for index = 1, projectileCount do
		local degrees = (index - center) * 2.5
		local rotated = CFrame.fromAxisAngle(Vector3.yAxis, math.rad(degrees))
			:VectorToWorldSpace(unit)
		table.insert(directions, rotated.Unit)
	end
	return directions
end

function WeaponService:KnitInit()
	self._requests = Knit.GetService("RequestGateService")
	self._data = Knit.GetService("DataService")
	self._economy = Knit.GetService("EconomyService")
	self._race = Knit.GetService("RaceService")
	self._limiters = {} :: { [Player]: RateLimiter.RateLimiter }
	self._audience = ShotAudience.new()
end

function WeaponService:KnitStart()
	self:_refreshAudience()
	local refreshAccumulator = 0
	RunService.Heartbeat:Connect(function(deltaTime)
		refreshAccumulator += deltaTime
		if refreshAccumulator >= 0.25 then
			refreshAccumulator %= 0.25
			self:_refreshAudience()
		end
	end)
	self._data.SessionRemoving:Connect(function(player)
		self._limiters[player] = nil
	end)
end

function WeaponService:_refreshAudience()
	local positions: { [Player]: Vector3 } = {}
	for _, viewer in Players:GetPlayers() do
		local character = viewer.Character
		local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
		if root ~= nil and root:IsA("BasePart") then
			positions[viewer] = root.Position
		end
	end
	self._audience:rebuild(positions)
end

function WeaponService.Client:PurchaseWeapon(player: Player, request: unknown)
	if not self.Server._requests:Allow(player, "Mutation") then
		return { ok = false, error = "rate_limited" }
	end
	if not Contract.WeaponRequest(request) then
		return { ok = false, error = "invalid_request" }
	end
	local typedRequest = request :: WeaponRequest
	return self.Server:PurchaseWeapon(player, typedRequest.weaponId)
end

function WeaponService:PurchaseWeapon(player: Player, weaponId: string): ActionResult
	local session = self._data:GetSession(player)
	local definition = WeaponConfig[weaponId]
	if session == nil then
		return { ok = false, error = "profile_not_loaded" }
	end
	if session.Race ~= nil then
		return { ok = false, error = "race_in_progress" }
	end
	if definition == nil then
		return { ok = false, error = "unknown_weapon" }
	end
	if session.Data.Weapons.Owned[weaponId] then
		return { ok = false, error = "already_owned" }
	end
	if not self._economy:Spend(player, "Targets", definition.Price, false) then
		return { ok = false, error = "insufficient_targets" }
	end

	session.Data.Weapons.Owned[weaponId] = true
	session.Data.Weapons.Equipped = weaponId
	self._data:PublishSnapshot(player)
	self.Client.WeaponChanged:Fire(player, weaponId)
	return { ok = true }
end

function WeaponService.Client:EquipWeapon(player: Player, request: unknown)
	if not self.Server._requests:Allow(player, "Mutation") then
		return { ok = false, error = "rate_limited" }
	end
	if not Contract.WeaponRequest(request) then
		return { ok = false, error = "invalid_request" }
	end
	local typedRequest = request :: WeaponRequest
	return self.Server:EquipWeapon(player, typedRequest.weaponId)
end

function WeaponService:EquipWeapon(player: Player, weaponId: string): ActionResult
	local session = self._data:GetSession(player)
	if session == nil then
		return { ok = false, error = "profile_not_loaded" }
	end
	if session.Race ~= nil then
		return { ok = false, error = "race_in_progress" }
	end
	if WeaponConfig[weaponId] == nil or not session.Data.Weapons.Owned[weaponId] then
		return { ok = false, error = "weapon_not_owned" }
	end

	session.Data.Weapons.Equipped = weaponId
	self._data:PublishSnapshot(player)
	self.Client.WeaponChanged:Fire(player, weaponId)
	return { ok = true }
end

function WeaponService.Client:FireWeapon(player: Player, request: unknown): boolean
	if not self.Server._requests:Allow(player, "Fire") then
		return false
	end
	if not Contract.FireWeaponRequest(request) then
		return false
	end
	local typedRequest = request :: FireWeaponRequest
	return self.Server:FireWeapon(player, typedRequest.direction)
end

function WeaponService:FireWeapon(player: Player, direction: Vector3): boolean
	if not isFiniteVector3(direction) or direction.Magnitude < 0.01 then
		return false
	end

	local session = self._data:GetSession(player)
	local race = if session ~= nil then session.Race else nil
	if session == nil or race == nil or race.Finished then
		return false
	end
	if
		not WeaponMath.isAimWithinCone(
			direction,
			race.Direction,
			GameConfig.WeaponAimToleranceDegrees
		)
	then
		return false
	end

	local character = player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	if root == nil or not root:IsA("BasePart") then
		return false
	end
	if not self._race:ValidateCharacterPosition(player) then
		return false
	end

	local limiter = self._limiters[player]
	if limiter == nil then
		limiter = RateLimiter.new()
		self._limiters[player] = limiter
	end
	local interval = 1 / math.max(0.1, race.Weapon.FireRate)
	if not limiter:allow("fire", interval) then
		return false
	end

	local origin = root.Position + Vector3.new(0, 1.5, 0)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { character }

	local damageMultiplier = if session.Entitlements.ExplosiveRounds then 1.5 else 1
	local damage = race.Weapon.Damage * damageMultiplier
	local directions = spreadDirections(direction, session.Entitlements.ProjectileCount)

	for _, shotDirection in directions do
		local result = Workspace:Raycast(origin, shotDirection * race.Weapon.Range, raycastParams)
		if result ~= nil then
			self._race:HandleShotHit(player, result.Instance, damage)
		end
	end

	local function replicateTo(viewer: Player)
		self.Client.ShotReplicated:Fire(
			viewer,
			player.UserId,
			origin,
			direction.Unit,
			session.Data.Weapons.Equipped or GameConfig.StarterWeaponId,
			#directions,
			session.Entitlements.ExplosiveRounds
		)
	end
	replicateTo(player)
	for _, viewer in self._audience:near(origin, 180) do
		if viewer == player or viewer.Parent ~= Players then
			continue
		end
		local viewerCharacter = viewer.Character
		local viewerRoot = if viewerCharacter ~= nil
			then viewerCharacter:FindFirstChild("HumanoidRootPart")
			else nil
		if
			viewerRoot ~= nil
			and viewerRoot:IsA("BasePart")
			and (viewerRoot.Position - origin).Magnitude <= 180
		then
			replicateTo(viewer)
		end
	end
	return true
end

return WeaponService
