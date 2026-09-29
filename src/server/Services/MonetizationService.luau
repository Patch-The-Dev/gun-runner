--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

local MonetizationService = Knit.CreateService({ Name = "MonetizationService", Client = {} })

local function pruneReceipts(receipts: { [string]: number }, protectedPurchaseId: string?)
	local now = os.time()
	local entries: { { Key: string, Timestamp: number } } = {}
	for key, timestamp in receipts do
		if now - timestamp > GameConfig.ReceiptRetentionSeconds then
			receipts[key] = nil
		else
			table.insert(entries, { Key = key, Timestamp = timestamp })
		end
	end

	if #entries <= GameConfig.MaxProcessedReceipts then
		return
	end
	table.sort(entries, function(a, b)
		return a.Timestamp < b.Timestamp
	end)
	local removeCount = #entries - GameConfig.MaxProcessedReceipts
	for _, entry in entries do
		if removeCount <= 0 then
			break
		end
		if entry.Key ~= protectedPurchaseId then
			receipts[entry.Key] = nil
			removeCount -= 1
		end
	end
end

function MonetizationService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._economy = Knit.GetService("EconomyService")
end

function MonetizationService:KnitStart()
	MarketplaceService.ProcessReceipt = function(receiptInfo)
		return self:_processReceipt(receiptInfo)
	end
end

function MonetizationService:_processReceipt(receiptInfo): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return self:_processReceiptForPlayer(player, receiptInfo)
end

function MonetizationService:_processReceiptForPlayer(
	player: Player,
	receiptInfo
): Enum.ProductPurchaseDecision
	local data = self._data:GetData(player)
	if data == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local product = ProductConfig.DeveloperProducts[receiptInfo.ProductId]
	if product == nil then
		warn(string.format("Unknown developer product %d", receiptInfo.ProductId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end

	local purchaseId = tostring(receiptInfo.PurchaseId)
	if data.ProcessedReceipts[purchaseId] == nil then
		if not self._economy:Award(player, product.Currency, product.Amount, false) then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		data.ProcessedReceipts[purchaseId] = os.time()
		pruneReceipts(data.ProcessedReceipts, purchaseId)
		self._data:PublishSnapshot(player)
	end

	local awaitSuccess, persisted = self._data:ConfirmReceiptSaved(player, purchaseId):await()
	if awaitSuccess and persisted == true then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

return MonetizationService
