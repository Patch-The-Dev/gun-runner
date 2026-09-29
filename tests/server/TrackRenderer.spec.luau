--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local TrackRenderer = require(ServerScriptService.Server.Infrastructure.TrackRenderer)

	describe("TrackRenderer", function()
		it("aligns an offset obstacle with the track", function()
			local base = Instance.new("Model")
			base.Name = "TestBase"
			base.Parent = workspace
			local origin = Instance.new("Part")
			origin.Name = "TrackOrigin"
			origin.Anchored = true
			origin.CFrame = CFrame.lookAt(Vector3.zero, Vector3.zAxis)
			origin.Parent = base

			local track = TrackRenderer.render(base, 123, {
				Seed = 1,
				Segments = { { Index = 1, Gates = {}, HasTarget = false, HasObstacle = true } },
				FinishLength = 1,
				TargetCount = 0,
				HasEvolver = false,
			})
			local obstacle = if track ~= nil then track:FindFirstChild("Obstacle") else nil
			local look = if obstacle ~= nil and obstacle:IsA("BasePart")
				then obstacle.CFrame.LookVector
				else Vector3.zero
			base:Destroy()

			expect(obstacle ~= nil).to.equal(true)
			expect(look:Dot(Vector3.zAxis) > 0.999).to.equal(true)
		end)
	end)
end
