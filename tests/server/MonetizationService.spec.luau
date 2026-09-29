--!strict

return function()
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local ServerScriptService = game:GetService("ServerScriptService")
	local Promise = require(ReplicatedStorage.Packages.Promise)
	local MonetizationService = require(ServerScriptService.Server.Services.MonetizationService)

	describe("MonetizationService receipts", function()
		local previousData: any
		local previousEconomy: any
		beforeEach(function()
			previousData = MonetizationService._data
			previousEconomy = MonetizationService._economy
		end)
		afterEach(function()
			MonetizationService._data = previousData
			MonetizationService._economy = previousEconomy
		end)

		it("grants once and retries acknowledgement until the receipt is saved", function()
			local player = Instance.new("Folder") :: any
			local data = { Currencies = { Cash = 0, Targets = 0 }, ProcessedReceipts = {} }
			local saved = false
			local awards = 0
			MonetizationService._data = {
				GetData = function()
					return data
				end,
				PublishSnapshot = function() end,
				ConfirmReceiptSaved = function()
					return Promise.resolve(saved)
				end,
			}
			MonetizationService._economy = {
				Award = function(_, _, currency, amount)
					awards += 1
					data.Currencies[currency] += amount
					return true
				end,
			}
			local receipt = { ProductId = 1884207018, PurchaseId = "receipt-1" }
			expect(MonetizationService:_processReceiptForPlayer(player, receipt)).to.equal(
				Enum.ProductPurchaseDecision.NotProcessedYet
			)
			expect(data.Currencies.Targets).to.equal(5_000)
			expect(awards).to.equal(1)
			saved = true
			expect(MonetizationService:_processReceiptForPlayer(player, receipt)).to.equal(
				Enum.ProductPurchaseDecision.PurchaseGranted
			)
			expect(awards).to.equal(1)
			player:Destroy()
		end)

		it("does not acknowledge an award that failed", function()
			local player = Instance.new("Folder") :: any
			local data = { Currencies = { Cash = 0, Targets = 0 }, ProcessedReceipts = {} }
			MonetizationService._data = {
				GetData = function()
					return data
				end,
			}
			MonetizationService._economy = {
				Award = function()
					return false
				end,
			}
			expect(MonetizationService:_processReceiptForPlayer(player, {
				ProductId = 1884207018,
				PurchaseId = "receipt-2",
			})).to.equal(Enum.ProductPurchaseDecision.NotProcessedYet)
			expect(data.ProcessedReceipts["receipt-2"]).to.equal(nil)
			player:Destroy()
		end)
	end)
end
