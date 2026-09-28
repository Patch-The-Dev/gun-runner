--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local Migrations = require(ServerScriptService.Server.Persistence.Migrations)

	describe("Migrations", function()
		it("converts the original positional Studio datastore format", function()
			local raw: { [string | number]: unknown } = {
				[1] = 2,
				[2] = 12,
				[3] = 6,
				[4] = 4,
				[5] = 2.5,
				[6] = 18,
				[7] = 0.61,
				[8] = 0.42,
				[9] = 0.31,
				[10] = 0.36,
				[11] = 0.44,
				[12] = 0.27,
				[13] = 1,
				[14] = 25,
				[15] = 2,
				[16] = 12_345,
				[17] = 99,
				[18] = 1_700_000_000,
				[19] = true,
				[20] = "Revolver",
			}

			local migrated = Migrations.apply(raw)
			expect(migrated.SchemaVersion).to.equal(6)
			expect(migrated.Rebirths).to.equal(2)
			expect(migrated.Currencies.Cash).to.equal(12_345)
			expect(migrated.Currencies.Targets).to.equal(99)
			expect(migrated.Chest.LastOpenedAt).to.equal(1_700_000_000)
			expect(migrated.Upgrades.TrackLength).to.equal(7)
			expect(migrated.Upgrades.CashMultiplier).to.equal(3)
			expect(raw[1]).to.equal(nil)
		end)

		it("preserves legacy named currency values before reconciliation", function()
			local migrated = Migrations.apply({
				SchemaVersion = 1,
				Cash = 12_345,
				Targets = 99,
				Rebirths = 2,
			})

			expect(migrated.SchemaVersion).to.equal(6)
			expect(migrated.Currencies.Cash).to.equal(12_345)
			expect(migrated.Currencies.Targets).to.equal(99)
		end)

		it("removes the obsolete persisted invite bonus", function()
			local raw: { [string | number]: unknown } = {
				SchemaVersion = 5,
				Currencies = { Cash = 0, Targets = 0 },
				Rebirths = 0,
				Upgrades = {},
				Weapons = { Owned = { Revolver = true }, Equipped = "Revolver" },
				Gift = { LastClaimAt = 0 },
				Chest = { LastOpenedAt = 0 },
				Social = { InvitePromptBonusClaimed = true },
				ProcessedReceipts = {},
			}
			local migrated = Migrations.apply(raw)

			expect(migrated.SchemaVersion).to.equal(6)
			expect(raw.Social).to.equal(nil)
		end)
	end)
end
