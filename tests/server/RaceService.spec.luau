--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local RaceService = require(ServerScriptService.Server.Services.RaceService)

	describe("RaceService run payout", function()
		it("connects start, checkpoint, finish, and currency awards", function()
			local previousData = RaceService._data
			local previousBase = RaceService._base
			local previousTracks = RaceService._tracks
			local previousEconomy = RaceService._economy
			local previousActivePlayers = RaceService._activePlayers
			local previousSignal = RaceService.Client.RaceChanged
			local player = { UserId = 123 } :: any
			local character = Instance.new("Model")
			local root = Instance.new("Part")
			root.Name = "HumanoidRootPart"
			root.Anchored = true
			root.Parent = character
			player.Character = character
			local base = Instance.new("Model")
			local origin = Instance.new("Part")
			origin.Name = "TrackOrigin"
			origin.CFrame = CFrame.lookAt(Vector3.zero, Vector3.zAxis)
			origin.Parent = base
			local track = Instance.new("Model")
			track:SetAttribute("CheckpointCount", 1)
			local session = {
				Data = {
					Weapons = { Equipped = "Revolver" },
					Chest = { LastOpenedAt = 0 },
				},
				Race = nil,
			}
			local awards = { Cash = 0, Targets = 0 }
			local clears = 0
			RaceService._activePlayers = {}
			RaceService._data = {
				GetSession = function()
					return session
				end,
				PublishSnapshot = function() end,
			}
			RaceService._base = {
				GetBase = function()
					return base
				end,
				TeleportToBase = function() end,
			}
			RaceService._tracks = {
				CreateTrack = function()
					return track
				end,
				ClearTrack = function()
					clears += 1
				end,
			}
			RaceService._economy = {
				Award = function(_, _, currency, amount)
					awards[currency] += amount
					return true
				end,
			}
			RaceService.Client.RaceChanged = { Fire = function() end } :: any

			expect(RaceService:StartRace(player)).to.equal(true)
			local race = session.Race
			expect(race ~= nil).to.equal(true)
			race.StartedAt = os.clock() - 3
			race.LastCheckpointAt = race.StartedAt
			race.LastObservedAt = race.StartedAt
			race.WindowStartedAt = race.StartedAt
			race:addCash(10)
			race:addTargets(5)
			root.Position = Vector3.new(0, 0, 28)
			local checkpoint = Instance.new("Part")
			checkpoint.Position = root.Position
			checkpoint:SetAttribute("OwnerUserId", 123)
			checkpoint:SetAttribute("CheckpointIndex", 1)
			expect(RaceService:HandleCheckpointTouched(player, checkpoint)).to.equal(true)

			race.LastCheckpointAt = os.clock() - 1
			race.LastObservedAt = race.LastCheckpointAt
			race.WindowStartedAt = race.LastCheckpointAt
			root.Position = Vector3.new(0, 0, 56)
			local finish = Instance.new("Part")
			finish.Position = root.Position
			finish:SetAttribute("OwnerUserId", 123)
			finish:SetAttribute("FinishMultiplier", 2)
			finish:SetAttribute("MinElapsedSeconds", 0)
			expect(RaceService:HandleFinishTouched(player, finish)).to.equal(true)
			expect(awards.Cash).to.equal(20)
			expect(awards.Targets).to.equal(5)
			expect(session.Race).to.equal(nil)
			expect(clears).to.equal(1)
			task.wait()

			RaceService._data = previousData
			RaceService._base = previousBase
			RaceService._tracks = previousTracks
			RaceService._economy = previousEconomy
			RaceService._activePlayers = previousActivePlayers
			RaceService.Client.RaceChanged = previousSignal
			checkpoint:Destroy()
			finish:Destroy()
			track:Destroy()
			base:Destroy()
			character:Destroy()
		end)
	end)
end
