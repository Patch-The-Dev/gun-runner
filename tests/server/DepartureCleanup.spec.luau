--!strict
return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local Service = require(ServerScriptService.Server.Services.DataService)
	describe("Departure cleanup", function()
		it("releases the profile even if notification and session cleanup throw", function()
			local previous = {
				sessions = Service._sessions,
				repository = Service._repository,
				signal = Service.SessionRemoving,
			}
			local player = {} :: any
			local releases = 0
			Service._sessions = {
				[player] = {
					Destroy = function()
						error("cleanup failed")
					end,
				},
			}
			Service._repository = {
				release = function()
					releases += 1
				end,
			}
			Service.SessionRemoving = {
				Fire = function()
					error("notification failed")
				end,
			}
			local success, failure = pcall(Service._removePlayer, Service, player)
			local remaining = Service._sessions[player]
			Service._sessions = previous.sessions
			Service._repository = previous.repository
			Service.SessionRemoving = previous.signal
			assert(success, tostring(failure))
			expect(releases).to.equal(1)
			expect(remaining).to.equal(nil)
		end)
	end)
end
