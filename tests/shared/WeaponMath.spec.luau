--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local WeaponMath = require(ReplicatedStorage.Shared.Domain.WeaponMath)

	describe("WeaponMath", function()
		local base = { Damage = 2, Range = 30, FireRate = 3 }

		it("applies supported gate stats", function()
			local result = WeaponMath.applyGate(base, "Damage", 4)
			expect(result.Damage).to.equal(6)
			expect(result.Range).to.equal(30)
		end)

		it("keeps weapon stats positive after penalties", function()
			local result = WeaponMath.applyPenalty(base, 1)
			expect(result.Damage > 0).to.equal(true)
			expect(result.Range > 0).to.equal(true)
			expect(result.FireRate > 0).to.equal(true)
		end)
	end)
end
