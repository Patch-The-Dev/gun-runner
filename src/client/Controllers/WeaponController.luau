--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(script.Parent.Parent.KnitClient)
local Trove = require(ReplicatedStorage.Packages.Trove)

local ShotTracer = require(script.Parent.Parent.Systems.ShotTracer)
local Store = require(script.Parent.Parent.State.ClientStore)

local WeaponController = Knit.CreateController({ Name = "WeaponController" })

function WeaponController:KnitInit()
	self._trove = Trove.new()
	self._lastShotAt = 0
end

function WeaponController:KnitStart()
	self._service = Knit.GetService("WeaponService")

	self._trove:Add(
		self._service.ShotReplicated:Connect(
			function(
				_shooterUserId: number,
				origin: Vector3,
				direction: Vector3,
				_weaponId: string,
				projectileCount: number,
				explosive: boolean
			)
				ShotTracer.renderSpread(origin, direction, projectileCount, explosive)
			end
		)
	)

	self._trove:Add(RunService.RenderStepped:Connect(function()
		self:_tryAutoFire()
	end))
end

function WeaponController:_tryAutoFire()
	local state = Store:getState()
	local weapon = state.Race.Weapon
	local direction = state.Race.Direction
	if state.Race.State ~= "Running" or weapon == nil or direction == nil then
		return
	end

	local interval = 1 / math.max(0.1, weapon.FireRate)
	local now = os.clock()
	if now - self._lastShotAt < interval then
		return
	end
	self._lastShotAt = now

	self._service:FireWeapon({ direction = direction }):catch(function(message: unknown)
		warn(string.format("Weapon fire failed: %s", tostring(message)))
	end)
end

return WeaponController
