--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local GiftReward = require(ServerScriptService.Server.Domain.GiftReward)

	describe("Gift rewards", function()
		it(
			"rejects overflow and a non-finite claim time without changing the transaction",
			function()
				local data = {
					Currencies = { Cash = 9_007_199_254_740_991, Targets = 2 },
					Gift = { LastClaimAt = 0 },
				} :: any
				expect(GiftReward.apply(data, 1, 5, 1000)).to.equal(false)
				expect(data.Currencies.Targets).to.equal(2)
				expect(data.Gift.LastClaimAt).to.equal(0)
				data.Currencies.Cash = 10
				expect(GiftReward.apply(data, 1, 5, 0 / 0)).to.equal(false)
				expect(data.Currencies.Cash).to.equal(10)
				expect(data.Currencies.Targets).to.equal(2)
			end
		)
		it("commits both currencies and the cooldown together", function()
			local data =
				{ Currencies = { Cash = 10, Targets = 2 }, Gift = { LastClaimAt = 0 } } :: any
			expect(GiftReward.apply(data, 2500, 5, 1000)).to.equal(true)
			expect(data.Currencies.Cash).to.equal(2510)
			expect(data.Currencies.Targets).to.equal(7)
			expect(data.Gift.LastClaimAt).to.equal(1000)
			expect(GiftReward.apply(data, 2500, 5, 1000)).to.equal(false)
			expect(data.Currencies.Cash).to.equal(2510)
		end)
		it("does not award the first currency when the second is invalid", function()
			local data =
				{ Currencies = { Cash = 10, Targets = 2 }, Gift = { LastClaimAt = 0 } } :: any
			for _, amount in { 0, -1, math.huge, 0 / 0, 0.5 } do
				expect(GiftReward.apply(data, 2500, amount, 1000)).to.equal(false)
				expect(data.Currencies.Cash).to.equal(10)
				expect(data.Gift.LastClaimAt).to.equal(0)
			end
		end)
	end)
end
