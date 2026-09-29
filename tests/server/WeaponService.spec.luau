--!strict

return function()
	local CollectionService = game:GetService("CollectionService")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Workspace = game:GetService("Workspace")
	local RaceSession = require(ServerScriptService.Server.Domain.RaceSession)
	local ShotAudience = require(ServerScriptService.Server.Domain.ShotAudience)
	local RaceService = require(ServerScriptService.Server.Services.RaceService)
	local WeaponService = require(ServerScriptService.Server.Services.WeaponService)

	describe("WeaponService raycast", function()
		it("turns a server raycast hit into one race target reward", function()
			local previousWeaponData = WeaponService._data
			local previousWeaponRace = WeaponService._race
			local previousLimiters = WeaponService._limiters
			local previousAudience = WeaponService._audience
			local previousShotSignal = WeaponService.Client.ShotReplicated
			local previousRaceData = RaceService._data
			local previousRaceSignal = RaceService.Client.RaceChanged
			local player = { UserId = 123 } :: any
			local character = Instance.new("Model")
			character.Name = "TestShooter"
			character.Parent = Workspace
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored = true
			root.Position = Vector3.zero
			root.Parent = character
			player.Character = character
			local target = Instance.new("Part")
			target.Name = "TestTarget"
			target.Anchored = true
			target.Size = Vector3.new(4, 4, 1)
			target.Position = Vector3.new(0, 1.5, 10)
			target:SetAttribute("OwnerUserId", 123)
			target:SetAttribute("TargetId", "test-target")
			target.Parent = Workspace
			CollectionService:AddTag(target, "RaceTarget")
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero
			)
			local session = {
				Race = race,
				Data = { Weapons = { Equipped = "Revolver" }, Rebirths = 0 },
				Entitlements = {
					ExplosiveRounds = false,
					ProjectileCount = 1,
					TargetMultiplier = 1,
				},
			}
			WeaponService._data = {
				GetSession = function()
					return session
				end,
			}
			RaceService._data = WeaponService._data
			RaceService.Client.RaceChanged = { Fire = function() end } :: any
			WeaponService._race = {
				ValidateCharacterPosition = function()
					return true
				end,
				HandleShotHit = function(_, hitPlayer, instance, damage)
					return RaceService:HandleShotHit(hitPlayer, instance, damage)
				end,
			}
			WeaponService._limiters = {}
			WeaponService._audience = ShotAudience.new()
			WeaponService.Client.ShotReplicated = { Fire = function() end } :: any

			expect(WeaponService:FireWeapon(player, Vector3.zAxis)).to.equal(true)
			expect(race.RunTargets).to.equal(1)
			expect(race.RawTargetsCollected).to.equal(1)
			expect(target.Parent).to.equal(nil)
			WeaponService._data = previousWeaponData
			WeaponService._race = previousWeaponRace
			WeaponService._limiters = previousLimiters
			WeaponService._audience = previousAudience
			WeaponService.Client.ShotReplicated = previousShotSignal
			RaceService._data = previousRaceData
			RaceService.Client.RaceChanged = previousRaceSignal
			if target.Parent ~= nil then
				target:Destroy()
			end
			character:Destroy()
		end)
	end)
end
