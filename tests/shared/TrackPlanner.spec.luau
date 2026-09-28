--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local TrackPlanner = require(ReplicatedStorage.Shared.Domain.TrackPlanner)

	local settings = {
		BoosterStrength = 20,
		BoosterSpawnChance = 0.5,
		NegativeBoosterChance = 0.25,
		PadSpawnChance = 0.4,
		NegativePadChance = 0.2,
		TargetSpawnChance = 0.4,
		ObstacleSpawnChance = 0.2,
		TrackLength = 12,
		FinishLength = 5,
		Rebirths = 3,
	}

	local function samePlan(a, b): boolean
		if
			a.Seed ~= b.Seed
			or a.FinishLength ~= b.FinishLength
			or a.TargetCount ~= b.TargetCount
			or a.HasEvolver ~= b.HasEvolver
		then
			return false
		end
		if #a.Segments ~= #b.Segments then
			return false
		end
		for index, segment in a.Segments do
			local other = b.Segments[index]
			if
				other == nil
				or segment.Index ~= other.Index
				or segment.HasTarget ~= other.HasTarget
				or segment.HasObstacle ~= other.HasObstacle
				or #segment.Gates ~= #other.Gates
			then
				return false
			end
			for gateIndex, gate in segment.Gates do
				local otherGate = other.Gates[gateIndex]
				if
					otherGate == nil
					or gate.Id ~= otherGate.Id
					or gate.Lane ~= otherGate.Lane
					or gate.Stat ~= otherGate.Stat
					or gate.Delta ~= otherGate.Delta
					or gate.ShotStep ~= otherGate.ShotStep
					or gate.HasPad ~= otherGate.HasPad
					or gate.PadNegative ~= otherGate.PadNegative
				then
					return false
				end
			end
		end
		return true
	end

	describe("TrackPlanner", function()
		it("is deterministic for a seed", function()
			local first = TrackPlanner.create(12345, settings)
			local second = TrackPlanner.create(12345, settings)
			expect(samePlan(first, second)).to.equal(true)
		end)

		it("creates the requested number of segments", function()
			local plan = TrackPlanner.create(7, settings)
			expect(#plan.Segments).to.equal(12)
			expect(plan.FinishLength).to.equal(5)
		end)

		it("uses unique gate ids", function()
			local plan = TrackPlanner.create(42, settings)
			local ids: { [string]: boolean } = {}
			for _, segment in plan.Segments do
				for _, gate in segment.Gates do
					expect(ids[gate.Id]).to.equal(nil)
					ids[gate.Id] = true
				end
			end
		end)
	end)
end
