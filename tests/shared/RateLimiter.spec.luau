--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RateLimiter = require(ReplicatedStorage.Shared.Util.RateLimiter)

return function()
	describe("RateLimiter", function()
		it("rejects calls inside the configured interval", function()
			local limiter = RateLimiter.new()
			expect(limiter:allow("fire", 0.5, 10)).to.equal(true)
			expect(limiter:allow("fire", 0.5, 10.49)).to.equal(false)
			expect(limiter:allow("fire", 0.5, 10.5)).to.equal(true)
		end)

		it("tracks keys independently", function()
			local limiter = RateLimiter.new()
			expect(limiter:allow("a", 1, 5)).to.equal(true)
			expect(limiter:allow("b", 1, 5)).to.equal(true)
			expect(limiter:allow("a", 1, 5.5)).to.equal(false)
		end)
	end)
end
