--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Progression = require(ReplicatedStorage.Shared.Domain.Progression)

	describe("Progression", function()
		it("increases rebirth cost", function()
			expect(Progression.getRebirthCost(1)).to.be.ok()
			expect(Progression.getRebirthCost(2) > Progression.getRebirthCost(1)).to.equal(true)
		end)

		it("clamps bounded upgrade values", function()
			local chance = Progression.getUpgradeValue("BoosterSpawnChance", 10_000)
			expect(chance).to.equal(0.95)
		end)

		it("returns nil for unknown upgrades", function()
			expect(Progression.getUpgradeCost("missing", 0)).to.equal(nil)
		end)
	end)
end
