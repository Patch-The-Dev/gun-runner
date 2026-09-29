--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local EntitlementPolicy = require(script.Parent.Parent.Domain.EntitlementPolicy)
local EntitlementTypes = require(ReplicatedStorage.Shared.Types.Entitlements)
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

type Entitlements = EntitlementTypes.Entitlements

local EntitlementService = Knit.CreateService({
	Name = "EntitlementService",
	Client = { EntitlementsChanged = Knit.CreateSignal() },
})

function EntitlementService:KnitInit()
	self._requests = Knit.GetService("RequestGateService")
	self._data = Knit.GetService("DataService")
	self._states = {} :: { [Player]: Entitlements }
	self._ownerships = {} :: { [Player]: { [number]: boolean } }
	self._loading = {} :: { [Player]: boolean }
	self._loadVersion = {} :: { [Player]: number }
	self._retryCount = {} :: { [Player]: number }
end

function EntitlementService:KnitStart()
	self._data.SessionAdded:Connect(function(player)
		self:_load(player)
	end)
	self._data.SessionRemoving:Connect(function(player)
		self._states[player] = nil
		self._ownerships[player] = nil
		self._loading[player] = nil
		self._loadVersion[player] = nil
		self._retryCount[player] = nil
	end)

	for _, player in Players:GetPlayers() do
		if self._data:GetSession(player) ~= nil then
			self:_load(player)
		end
	end

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(
		function(player, _gamePassId, purchased)
			if purchased then
				self:_load(player, true)
			end
		end
	)
end

function EntitlementService:_publish(player: Player, state: Entitlements)
	local session = self._data:GetSession(player)
	if session ~= nil then
		session.Entitlements = table.clone(state)
		self._data:PublishSnapshot(player)
	end
	self.Client.EntitlementsChanged:Fire(player, table.clone(state))
end

function EntitlementService:_load(player: Player, force: boolean?)
	if player.Parent ~= Players or self._data:GetSession(player) == nil then
		return
	end
	if self._loading[player] and not force then
		return
	end

	local loadVersion = (self._loadVersion[player] or 0) + 1
	self._loadVersion[player] = loadVersion
	self._loading[player] = true

	local jobs = {}
	for gamePassId in ProductConfig.GamePasses do
		table.insert(
			jobs,
			Promise.new(function(resolve)
				for attempt = 1, 3 do
					local success, ownsPass = pcall(
						MarketplaceService.UserOwnsGamePassAsync,
						MarketplaceService,
						player.UserId,
						gamePassId
					)
					if success then
						resolve({ Id = gamePassId, Success = true, Owns = ownsPass == true })
						return
					end
					if attempt < 3 then
						task.wait(attempt)
					end
				end
				warn(
					string.format(
						"Game pass %d lookup failed for %s after 3 attempts",
						gamePassId,
						player.Name
					)
				)
				resolve({ Id = gamePassId, Success = false })
			end)
		)
	end

	Promise.all(jobs)
		:andThen(function(results)
			if player.Parent ~= Players or self._loadVersion[player] ~= loadVersion then
				return
			end

			local ownerships, failed =
				EntitlementPolicy.merge(self._ownerships[player] or {}, results)
			self._ownerships[player] = ownerships
			local state = EntitlementPolicy.build(ownerships)
			self._states[player] = state
			self:_publish(player, state)
			if failed then
				local retryCount = math.min((self._retryCount[player] or 0) + 1, 5)
				self._retryCount[player] = retryCount
				task.delay(math.min(60, 5 * 2 ^ (retryCount - 1)), function()
					if self._loadVersion[player] == loadVersion then
						self:_load(player)
					end
				end)
			else
				self._retryCount[player] = 0
			end
		end)
		:finally(function()
			if self._loadVersion[player] == loadVersion then
				self._loading[player] = nil
			end
		end)
end

function EntitlementService:Get(player: Player): Entitlements
	return self._states[player] or EntitlementPolicy.build({})
end

function EntitlementService.Client:GetSnapshot(player: Player): Entitlements?
	if not self.Server._requests:Allow(player, "Read") then
		return nil
	end
	return self.Server:Get(player)
end

return EntitlementService
