--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RaceSession = require(ServerScriptService.Server.Domain.RaceSession)

	describe("RaceSession", function()
		it("requires ordered checkpoints", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				3,
				Vector3.zero,
				100
			)
			expect(race:touchCheckpoint(2, Vector3.new(0, 0, 56), Vector3.new(0, 0, 56), 101)).to.equal(
				false
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101)).to.equal(
				true
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101)).to.equal(
				false
			)
			expect(race:touchCheckpoint(2, Vector3.new(0, 0, 56), Vector3.new(0, 0, 56), 102)).to.equal(
				true
			)
			expect(race:touchCheckpoint(3, Vector3.new(0, 0, 84), Vector3.new(0, 0, 84), 103)).to.equal(
				true
			)
			expect(race.LastCheckpointIndex).to.equal(3)
		end)

		it("rejects remote or too-fast checkpoints", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				2,
				Vector3.zero,
				100
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.zero, 101)).to.equal(
				false
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 100.1)).to.equal(
				false
			)
			expect(race.InvalidMovement).to.equal(true)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101)).to.equal(
				false
			)
		end)

		it("invalidates a run after an implausible position jump", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero,
				100
			)
			expect(race:observePosition(Vector3.new(0, 0, 3), 100.2)).to.equal(true)
			expect(race:observePosition(Vector3.new(0, 0, 80), 100.4)).to.equal(false)
			expect(race.InvalidReason).to.equal("horizontal_speed")
			expect(race.MaxObservedSpeed > 48).to.equal(true)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 102)).to.equal(
				false
			)
			expect(race:canFinish(0, Vector3.new(0, 0, 56), Vector3.new(0, 0, 56), 103)).to.equal(
				false
			)
		end)

		it("requires travel time and proximity from the final checkpoint to the finish", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero,
				100
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101)).to.equal(
				true
			)
			expect(race:canFinish(0, Vector3.new(0, 0, 56), Vector3.zero, 102)).to.equal(false)
			expect(race:canFinish(0, Vector3.new(0, 0, 56), Vector3.new(0, 0, 56), 101.1)).to.equal(
				false
			)
			expect(race.InvalidMovement).to.equal(true)
		end)

		it("accepts plausible progress to the finish", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero,
				100
			)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101)).to.equal(
				true
			)
			expect(race:canFinish(0, Vector3.new(0, 0, 56), Vector3.new(0, 0, 56), 102)).to.equal(
				true
			)
		end)

		it("requires current-segment timing and proximity for touch objects", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				2,
				Vector3.zero,
				100
			)
			local gatePosition = Vector3.new(7, 0, 21)
			expect(race:canTouchTrackObject(2, gatePosition, gatePosition, 101)).to.equal(false)
			expect(race:canTouchTrackObject(1, gatePosition, Vector3.zero, 101)).to.equal(false)
			expect(race:canTouchTrackObject(1, gatePosition, gatePosition, 100.1)).to.equal(false)
			expect(race.InvalidMovement).to.equal(true)
		end)

		it("accepts a current-segment touch after plausible travel", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				2,
				Vector3.zero,
				100
			)
			local gatePosition = Vector3.new(7, 0, 21)
			expect(
				race:canTouchTrackObject(1, Vector3.new(7, 0, 21), Vector3.new(7, 0, 16), 100.46, 5)
			).to.equal(true)
			expect(race:canTouchTrackObject(1, gatePosition, gatePosition, 101)).to.equal(true)
			expect(race:touchCheckpoint(1, Vector3.new(0, 0, 28), Vector3.new(0, 0, 28), 101.3)).to.equal(
				true
			)
			expect(race:canTouchTrackObject(1, gatePosition, gatePosition, 102)).to.equal(false)
		end)

		it("does not consume the same target twice", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero
			)
			expect(race:consumeTarget("target-1", 10)).to.equal(true)
			expect(race:consumeTarget("target-1", 10)).to.equal(false)
			expect(race.RunTargets).to.equal(10)
		end)

		it("does not claim invalid rewards or mutate a finished run", function()
			local race = RaceSession.new(
				{ Damage = 1, Range = 20, FireRate = 2 },
				Vector3.zAxis,
				1,
				Vector3.zero
			)
			expect(race:consumePillar("pillar-1", 0)).to.equal(false)
			expect(race:consumePillar("pillar-1", 25)).to.equal(true)
			expect(race:consumeTarget("target-1", 10)).to.equal(true)
			race:finish(1, 1)
			expect(race:consumePillar("pillar-2", 25)).to.equal(false)
			expect(race:consumeTarget("target-2", 10)).to.equal(false)
			expect(race.RunCash).to.equal(25)
			expect(race.RunTargets).to.equal(10)
		end)
	end)
end
