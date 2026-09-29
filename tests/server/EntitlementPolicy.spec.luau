--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local EntitlementPolicy = require(ServerScriptService.Server.Domain.EntitlementPolicy)

	describe("EntitlementPolicy", function()
		it("keeps verified passes when another lookup fails", function()
			local known = { [869186485] = true }
			local merged, failed = EntitlementPolicy.merge(known, {
				{ Id = 869186485, Success = false },
				{ Id = 869207509, Success = true, Owns = true },
			})
			local state = EntitlementPolicy.build(merged)
			expect(failed).to.equal(true)
			expect(state.CashMultiplier).to.equal(5)
			expect(state.TargetMultiplier).to.equal(5)
			expect(known[869207509]).to.equal(nil)
		end)

		it("does not grant an unverified pass", function()
			local merged = EntitlementPolicy.merge({}, {
				{ Id = 869353401, Success = false },
			})
			expect(EntitlementPolicy.build(merged).ExplosiveRounds).to.equal(false)
		end)
	end)
end
