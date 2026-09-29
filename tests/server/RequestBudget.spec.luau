--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RequestBudget = require(ServerScriptService.Server.Domain.RequestBudget)

	describe("RequestBudget", function()
		it("limits each player's category and refills over time", function()
			local budget = RequestBudget.new()
			local first = Instance.new("Folder") :: any
			local second = Instance.new("Folder") :: any
			for _ = 1, 4 do
				expect(budget:allow(first, "Mutation", 100)).to.equal(true)
			end
			expect(budget:allow(first, "Mutation", 100)).to.equal(false)
			expect(budget:allow(second, "Mutation", 100)).to.equal(true)
			expect(budget:allow(first, "Read", 100)).to.equal(true)
			expect(budget:allow(first, "Mutation", 100.5)).to.equal(true)
			expect(budget:allow(first, "Mutation", 100.5)).to.equal(false)
			budget:forget(first)
			expect(budget:allow(first, "Mutation", 100.5)).to.equal(true)
			first:Destroy()
			second:Destroy()
		end)
	end)
end
