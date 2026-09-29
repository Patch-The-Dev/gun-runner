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

		it("rejects excess fire requests without blocking a legitimate 20 shot burst", function()
			local budget = RequestBudget.new()
			local player = Instance.new("Folder") :: any
			for _ = 1, 40 do
				expect(budget:allow(player, "Fire", 100)).to.equal(true)
			end
			expect(budget:allow(player, "Fire", 100)).to.equal(false)
			expect(budget:allow(player, "Fire", 100.04)).to.equal(true)
			player:Destroy()
		end)
	end)
end
