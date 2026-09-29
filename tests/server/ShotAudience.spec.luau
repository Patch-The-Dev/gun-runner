--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local ShotAudience = require(ServerScriptService.Server.Domain.ShotAudience)

	describe("ShotAudience", function()
		it("selects nearby cells and updates when players move", function()
			local audience = ShotAudience.new()
			local nearby = Instance.new("Folder") :: any
			local distant = Instance.new("Folder") :: any
			audience:rebuild({
				[nearby] = Vector3.new(150, 0, 0),
				[distant] = Vector3.new(800, 0, 0),
			})
			local first = audience:near(Vector3.zero, 180)
			expect(table.find(first, nearby) ~= nil).to.equal(true)
			expect(table.find(first, distant)).to.equal(nil)
			audience:rebuild({
				[nearby] = Vector3.new(800, 0, 0),
				[distant] = Vector3.new(40, 0, 0),
			})
			local second = audience:near(Vector3.zero, 180)
			expect(table.find(second, nearby)).to.equal(nil)
			expect(table.find(second, distant) ~= nil).to.equal(true)
			nearby:Destroy()
			distant:Destroy()
		end)
	end)
end
