--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ClientStore = require(ReplicatedStorage.ClientState.ClientStore)

	describe("ClientStore", function()
		it("owns deeply frozen copies of incoming snapshots", function()
			local store = ClientStore.new()
			local profile = {
				Currencies = { Cash = 100, Targets = 5 },
				Rebirths = 0,
				Upgrades = { CashMultiplier = 1 },
				Weapons = { Owned = { Revolver = true }, Equipped = "Revolver" },
				Entitlements = {
					CashMultiplier = 1,
					TargetMultiplier = 1,
					RebirthIncrement = 1,
					ProjectileCount = 1,
					ExplosiveRounds = false,
				},
			}
			store:setProfile(profile)
			profile.Currencies.Cash = 999
			profile.Weapons.Owned.Revolver = false
			local snapshot = store:getState()
			expect(snapshot.Profile.Currencies.Cash).to.equal(100)
			expect(snapshot.Profile.Weapons.Owned.Revolver).to.equal(true)
			local changedCurrency = pcall(function()
				snapshot.Profile.Currencies.Cash = 1
			end)
			local changedInventory = pcall(function()
				snapshot.Profile.Weapons.Owned.Revolver = false
			end)
			expect(changedCurrency).to.equal(false)
			expect(changedInventory).to.equal(false)

			local race = {
				State = "Running",
				RunCash = 0,
				RunTargets = 0,
				TargetsCollected = 0,
				FinishMultiplier = 1,
				Direction = Vector3.zAxis,
				Weapon = { Damage = 5, Range = 20, FireRate = 2 },
			}
			store:setRace(race)
			race.Weapon.Damage = 100
			expect(store:getState().Race.Weapon.Damage).to.equal(5)
			local changedWeapon = pcall(function()
				store:getState().Race.Weapon.Damage = 100
			end)
			expect(changedWeapon).to.equal(false)
			store:destroy()
		end)
	end)
end
