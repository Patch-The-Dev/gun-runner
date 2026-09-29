--!strict

return function()
	local ServerScriptService = game:GetService("ServerScriptService")
	local PlayerRepository = require(ServerScriptService.Server.Persistence.PlayerRepository)

	describe("PlayerRepository receipt confirmation", function()
		it("confirms only a save containing the purchase id", function()
			local repository = PlayerRepository.new()
			local player = Instance.new("Folder") :: any
			local afterSave = Instance.new("BindableEvent")
			local sessionEnd = Instance.new("BindableEvent")
			local saves = 0
			local profile = {
				LastSavedData = { ProcessedReceipts = {} },
				OnAfterSave = afterSave.Event,
				OnSessionEnd = sessionEnd.Event,
				IsActive = function()
					return true
				end,
				Save = function(self)
					saves += 1
					self.LastSavedData.ProcessedReceipts["receipt-1"] = os.time()
					afterSave:Fire(self.LastSavedData)
				end,
			}
			repository._profiles[player] = profile :: any
			local success, persisted = repository:saveAndConfirmReceipt(player, "receipt-1"):await()
			expect(success).to.equal(true)
			expect(persisted).to.equal(true)
			expect(saves).to.equal(1)
			local _, alreadySaved = repository:saveAndConfirmReceipt(player, "receipt-1"):await()
			expect(alreadySaved).to.equal(true)
			expect(saves).to.equal(1)
			afterSave:Destroy()
			sessionEnd:Destroy()
			player:Destroy()
		end)

		it("rejects confirmation when the profile session ends before save", function()
			local repository = PlayerRepository.new()
			local player = Instance.new("Folder") :: any
			local afterSave = Instance.new("BindableEvent")
			local sessionEnd = Instance.new("BindableEvent")
			repository._profiles[player] = {
				LastSavedData = { ProcessedReceipts = {} },
				OnAfterSave = afterSave.Event,
				OnSessionEnd = sessionEnd.Event,
				IsActive = function()
					return true
				end,
				Save = function()
					sessionEnd:Fire()
				end,
			} :: any
			local success, persisted = repository:saveAndConfirmReceipt(player, "receipt-2"):await()
			expect(success).to.equal(true)
			expect(persisted).to.equal(false)
			afterSave:Destroy()
			sessionEnd:Destroy()
			player:Destroy()
		end)
	end)
end
