--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Promise = require(ReplicatedStorage.Packages.Promise)

local EntitlementTypes = require(ReplicatedStorage.Shared.Types.Entitlements)
local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

type Entitlements = EntitlementTypes.Entitlements
type GamePassEffect = ProductConfig.GamePassEffect

local EntitlementService = Knit.CreateService({
	Name = "EntitlementService",
	Client = { EntitlementsChanged = Knit.CreateSignal() },
})

local function createDefault(): Entitlements
	return {
		CashMultiplier = 1,
		TargetMultiplier = 1,
		RebirthIncrement = 1,
		ProjectileCount = 1,
		ExplosiveRounds = false,
	}
end

local function applyEffect(state: Entitlements, effect: GamePassEffect)
	state.CashMultiplier += effect.CashBonus or 0
	state.TargetMultiplier += effect.TargetBonus or 0
	state.RebirthIncrement += effect.RebirthBonus or 0
	state.ProjectileCount = math.max(state.ProjectileCount, effect.ProjectileCount or 1)
	state.ExplosiveRounds = state.ExplosiveRounds or effect.ExplosiveRounds == true
end

function EntitlementService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._states = {} :: { [Player]: Entitlements }
	self._loading = {} :: { [Player]: boolean }
	self._loadVersion = {} :: { [Player]: number }
end

function EntitlementService:KnitStart()
	self._data.SessionAdded:Connect(function(player)
		self:_load(player)
	end)
	self._data.SessionRemoving:Connect(function(player)
		self._states[player] = nil
		self._loading[player] = nil
		self._loadVersion[player] = nil
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
	if self._loading[player] and not force then
		return
	end

	local loadVersion = (self._loadVersion[player] or 0) + 1
	self._loadVersion[player] = loadVersion
	self._loading[player] = true

	local jobs = {}
	for gamePassId, effect in ProductConfig.GamePasses do
		table.insert(
			jobs,
			Promise.new(function(resolve)
				local success, ownsPass = pcall(
					MarketplaceService.UserOwnsGamePassAsync,
					MarketplaceService,
					player.UserId,
					gamePassId
				)
				if not success then
					warn(
						string.format(
							"Failed to check game pass %d for %s",
							gamePassId,
							player.Name
						)
					)
					resolve({ Success = false })
					return
				end
				resolve({ Success = true, Effect = if ownsPass then effect else nil })
			end)
		)
	end

	Promise.all(jobs)
		:andThen(function(results)
			if player.Parent ~= Players or self._loadVersion[player] ~= loadVersion then
				return
			end

			local state = createDefault()
			for _, result in results do
				if result.Success ~= true then
					return
				end
				if result.Effect ~= nil then
					applyEffect(state, result.Effect)
				end
			end

			self._states[player] = state
			self:_publish(player, state)
		end)
		:finally(function()
			if self._loadVersion[player] == loadVersion then
				self._loading[player] = nil
			end
		end)
end

function EntitlementService:Get(player: Player): Entitlements
	return self._states[player] or createDefault()
end

function EntitlementService.Client:GetSnapshot(player: Player): Entitlements
	return self.Server:Get(player)
end

return EntitlementService
