--!strict

return function()
	local Players = game:GetService("Players")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Repository = require(ServerScriptService.Server.Persistence.PlayerRepository)

	describe("Profile acquisition cleanup", function()
		for _, step in { "AddUserId", "Reconcile", "Connect" } do
			it(`ends an acquired session when {step} fails`, function()
				local ends = 0
				local player = { UserId = 991, Parent = Players } :: any
				local profile = {
					Data = {},
					AddUserId = function()
						if step == "AddUserId" then
							error("initialization failed")
						end
					end,
					Reconcile = function()
						if step == "Reconcile" then
							error("initialization failed")
						end
					end,
					IsActive = function()
						return ends == 0
					end,
					EndSession = function()
						ends += 1
					end,
					OnSessionEnd = {
						Connect = function()
							if step == "Connect" then
								error("initialization failed")
							end
						end,
					},
				}
				local repository = Repository.new({
					StartSessionAsync = function()
						return profile
					end,
				} :: any)
				local succeeded = repository:load(player):await()
				expect(succeeded).to.equal(false)
				expect(ends).to.equal(1)
				expect(repository:get(player)).to.equal(nil)
				expect(next(repository._loads)).to.equal(nil)
			end)
		end

		it("waits for an in-flight load and releases a session acquired during shutdown", function()
			local ends = 0
			local started = false
			local cancel: (() -> boolean)? = nil
			local player = { UserId = 992, Parent = Players } :: any
			local repository = Repository.new({
				StartSessionAsync = function(_, _, options)
					started = true
					cancel = options.Cancel
					while not options.Cancel() do
						task.wait()
					end
					return {
						Data = {},
						AddUserId = function() end,
						Reconcile = function() end,
						IsActive = function()
							return ends == 0
						end,
						EndSession = function()
							ends += 1
						end,
					}
				end,
			} :: any)
			local load = repository:load(player)
			local deadline = os.clock() + 3
			while not started and os.clock() < deadline do
				task.wait()
			end
			assert(started, "Load did not start")
			repository:close(deadline)
			local succeeded = load:await()
			expect(succeeded).to.equal(false)
			expect(ends).to.equal(1)
			expect(next(repository._loads)).to.equal(nil)
			assert(cancel ~= nil, "Load cancellation callback was missing")
			expect(cancel()).to.equal(true)
			expect(repository:load(player):await()).to.equal(false)
		end)
	end)

	describe("Receipt deadlines", function()
		for _, mode in { "silent", "throw" } do
			it(`returns false if a save is {mode}`, function()
				local repository = Repository.new(nil, 0.02)
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
						if mode == "throw" then
							error("save failed")
						end
					end,
				} :: any
				local succeeded, confirmed =
					repository:saveAndConfirmReceipt(player, "unsaved"):await()
				expect(succeeded).to.equal(true)
				expect(confirmed).to.equal(false)
				afterSave:Destroy()
				sessionEnd:Destroy()
				player:Destroy()
			end)
		end
	end)
end
