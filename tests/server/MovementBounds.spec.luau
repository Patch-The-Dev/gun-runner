--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RaceSession = require(ServerScriptService.Server.Domain.RaceSession)
	local function createRace()
		return RaceSession.new(
			{ Damage = 1, Range = 20, FireRate = 2 },
			Vector3.zAxis,
			2,
			Vector3.zero,
			100
		)
	end
	describe("Race movement bounds", function()
		it("rejects rapid ascent and descent", function()
			for _, height in { 40, -80 } do
				local race = createRace()
				expect(race:observePosition(Vector3.new(0, height, 3), 100.1)).to.equal(false)
				expect(race.InvalidReason).to.equal("vertical_speed")
			end
		end)
		it("accepts normal jump displacement", function()
			local race = createRace()
			expect(race:observePosition(Vector3.new(0, 5, 3), 100.1)).to.equal(true)
			expect(race:observePosition(Vector3.new(0, 2, 6), 100.2)).to.equal(true)
		end)
		it("rejects repeated slack-sized steps over the rolling window", function()
			local race = createRace()
			local accepted = true
			for sample = 1, 8 do
				accepted = race:observePosition(Vector3.new(0, 0, sample * 8), 100 + sample * 0.1)
				if not accepted then
					break
				end
			end
			expect(accepted).to.equal(false)
		end)
		it("rejects a sample clock that moves backwards", function()
			expect(createRace():observePosition(Vector3.zero, 99)).to.equal(false)
		end)
	end)
end
