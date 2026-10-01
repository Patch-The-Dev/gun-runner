--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local Promise = require(ReplicatedStorage.Packages.Promise)

local DataTemplate = require(script.Parent.DataTemplate)
local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local Migrations = require(script.Parent.Migrations)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)

type PlayerData = PlayerDataTypes.PlayerData
type MutableData = { [string | number]: unknown }

type AfterSaveSignal = {
	Connect: (self: AfterSaveSignal, callback: (PlayerData) -> ()) -> RBXScriptConnection,
}

type SessionEndSignal = {
	Connect: (self: SessionEndSignal, callback: () -> ()) -> RBXScriptConnection,
}

type Profile = {
	Data: unknown,
	LastSavedData: PlayerData,
	AddUserId: (self: Profile, userId: number) -> (),
	Reconcile: (self: Profile) -> (),
	EndSession: (self: Profile) -> (),
	Save: (self: Profile) -> (),
	IsActive: (self: Profile) -> boolean,
	OnAfterSave: AfterSaveSignal,
	OnSessionEnd: SessionEndSignal,
}

export type Store = {
	StartSessionAsync: (self: Store, key: string, options: { Cancel: () -> boolean }) -> Profile?,
}

type Load = { Cancelled: boolean }

local PlayerRepository = {}
PlayerRepository.__index = PlayerRepository

export type PlayerRepository = typeof(setmetatable(
	{} :: {
		_profiles: { [Player]: Profile },
		_store: Store,
		_loads: { [Player]: Load },
		_closing: boolean,
		_confirmationSeconds: number,
	},
	PlayerRepository
))

local liveStore = ProfileStore.New(GameConfig.ProfileStoreName, DataTemplate)
local playerStore = if RunService:IsStudio() then liveStore.Mock else liveStore

function PlayerRepository.new(store: Store?, confirmationSeconds: number?): PlayerRepository
	return setmetatable({
		_profiles = {},
		_store = store or ((playerStore :: unknown) :: Store),
		_loads = {},
		_closing = false,
		_confirmationSeconds = confirmationSeconds or GameConfig.ReceiptConfirmationSeconds,
	}, PlayerRepository)
end

function PlayerRepository.load(self: PlayerRepository, player: Player)
	if self._closing or self._loads[player] ~= nil or self._profiles[player] ~= nil then
		return Promise.reject("profile_load_unavailable")
	end
	local load: Load = { Cancelled = false }
	self._loads[player] = load
	return Promise.new(function(resolve, reject, onCancel)
		onCancel(function()
			load.Cancelled = true
		end)
		local profile: Profile? = nil
		local succeeded, result = pcall(function(): PlayerData
			local acquired = self._store:StartSessionAsync(
				GameConfig.ProfileKeyPrefix .. tostring(player.UserId),
				{
					Cancel = function()
						return self._closing or load.Cancelled or player.Parent ~= Players
					end,
				}
			)
			profile = acquired
			if acquired == nil then
				error("profile_session_unavailable")
			end
			acquired:AddUserId(player.UserId)
			acquired.Data = Migrations.apply(acquired.Data :: MutableData)
			acquired:Reconcile()
			if
				self._closing
				or load.Cancelled
				or player.Parent ~= Players
				or not acquired:IsActive()
			then
				error("player_left_during_profile_load")
			end
			acquired.OnSessionEnd:Connect(function()
				if self._profiles[player] == acquired then
					self._profiles[player] = nil
				end
				if not self._closing and player.Parent == Players then
					player:Kick("Your data session ended unexpectedly. Please rejoin.")
				end
			end)
			self._profiles[player] = acquired
			return acquired.Data :: PlayerData
		end)
		if not succeeded then
			local acquired = profile
			if acquired ~= nil then
				local released, releaseError = pcall(function()
					if acquired:IsActive() then
						acquired:EndSession()
					end
				end)
				if not released then
					warn(`Profile cleanup failed: {tostring(releaseError)}`)
				end
			end
		end
		self._loads[player] = nil
		if succeeded then
			resolve(result)
		else
			reject(result)
		end
	end)
end

function PlayerRepository.get(self: PlayerRepository, player: Player): PlayerData?
	local profile = self._profiles[player]
	return if profile ~= nil and profile:IsActive() then profile.Data :: PlayerData else nil
end

function PlayerRepository.isReceiptSaved(
	self: PlayerRepository,
	player: Player,
	purchaseId: string
): boolean
	local profile = self._profiles[player]
	return profile ~= nil
		and profile:IsActive()
		and profile.LastSavedData.ProcessedReceipts[purchaseId] ~= nil
end

function PlayerRepository.saveAndConfirmReceipt(
	self: PlayerRepository,
	player: Player,
	purchaseId: string
)
	return Promise.new(function(resolve, _, onCancel)
		local profile = self._profiles[player]
		if profile == nil or not profile:IsActive() then
			resolve(false)
			return
		end
		if profile.LastSavedData.ProcessedReceipts[purchaseId] ~= nil then
			resolve(true)
			return
		end

		local settled = false
		local afterSaveConnection: RBXScriptConnection?
		local sessionEndConnection: RBXScriptConnection?
		local timeoutThread: thread?

		local function settle(value: boolean)
			if settled then
				return
			end
			settled = true
			if timeoutThread ~= nil and timeoutThread ~= coroutine.running() then
				task.cancel(timeoutThread)
			end
			if afterSaveConnection ~= nil then
				afterSaveConnection:Disconnect()
			end
			if sessionEndConnection ~= nil then
				sessionEndConnection:Disconnect()
			end
			resolve(value)
		end

		afterSaveConnection = profile.OnAfterSave:Connect(function(lastSavedData)
			if lastSavedData.ProcessedReceipts[purchaseId] ~= nil then
				settle(true)
			end
		end)
		sessionEndConnection = profile.OnSessionEnd:Connect(function()
			settle(false)
		end)

		onCancel(function()
			settle(false)
		end)
		timeoutThread = task.delay(self._confirmationSeconds, function()
			settle(false)
		end)
		local saved = pcall(profile.Save, profile)
		if not saved then
			settle(false)
		end
	end)
end

function PlayerRepository.release(self: PlayerRepository, player: Player)
	local load = self._loads[player]
	if load ~= nil then
		load.Cancelled = true
	end
	local profile = self._profiles[player]
	self._profiles[player] = nil
	if profile ~= nil and profile:IsActive() then
		profile:EndSession()
	end
end

function PlayerRepository.releaseAll(self: PlayerRepository)
	for player in self._profiles do
		local released, releaseError = pcall(function()
			self:release(player)
			return true
		end)
		if not released then
			warn(`Profile release failed for user {player.UserId}: {tostring(releaseError)}`)
		end
	end
end

function PlayerRepository.beginClose(self: PlayerRepository)
	self._closing = true
	for _, load in self._loads do
		load.Cancelled = true
	end
end

function PlayerRepository.close(self: PlayerRepository, deadline: number)
	self:beginClose()
	self:releaseAll()
	while next(self._loads) ~= nil and os.clock() < deadline do
		task.wait(0.05)
	end
	-- Late loads also observe _closing and release any acquired session themselves.
	self:releaseAll()
	if next(self._loads) ~= nil then
		warn("Profile loads exceeded the shutdown deadline")
	end
end

return PlayerRepository
