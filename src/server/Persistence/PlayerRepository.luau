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

local PlayerRepository = {}
PlayerRepository.__index = PlayerRepository

export type PlayerRepository = typeof(setmetatable(
	{} :: {
		_profiles: { [Player]: Profile },
	},
	PlayerRepository
))

local liveStore = ProfileStore.New(GameConfig.ProfileStoreName, DataTemplate)
local playerStore = if RunService:IsStudio() then liveStore.Mock else liveStore

function PlayerRepository.new(): PlayerRepository
	return setmetatable({
		_profiles = {},
	}, PlayerRepository)
end

function PlayerRepository:load(player: Player)
	return Promise.new(function(resolve, reject)
		local profile =
			playerStore:StartSessionAsync(GameConfig.ProfileKeyPrefix .. tostring(player.UserId), {
				Cancel = function()
					return player.Parent ~= Players
				end,
			}) :: Profile?

		if profile == nil then
			reject("profile_session_unavailable")
			return
		end

		profile:AddUserId(player.UserId)
		local migratedData = Migrations.apply(profile.Data :: MutableData)
		profile.Data = migratedData
		profile:Reconcile()

		profile.OnSessionEnd:Connect(function()
			self._profiles[player] = nil
			if player.Parent == Players then
				player:Kick("Your data session ended unexpectedly. Please rejoin.")
			end
		end)

		if player.Parent ~= Players or not profile:IsActive() then
			profile:EndSession()
			reject("player_left_during_profile_load")
			return
		end

		self._profiles[player] = profile
		resolve(profile.Data :: PlayerData)
	end)
end

function PlayerRepository:get(player: Player): PlayerData?
	local profile = self._profiles[player]
	return if profile ~= nil and profile:IsActive() then profile.Data :: PlayerData else nil
end

function PlayerRepository:isReceiptSaved(player: Player, purchaseId: string): boolean
	local profile = self._profiles[player]
	return profile ~= nil
		and profile:IsActive()
		and profile.LastSavedData.ProcessedReceipts[purchaseId] ~= nil
end

function PlayerRepository:saveAndConfirmReceipt(player: Player, purchaseId: string)
	return Promise.new(function(resolve)
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

		local function settle(value: boolean)
			if settled then
				return
			end
			settled = true
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

		profile:Save()
	end)
end

function PlayerRepository:release(player: Player)
	local profile = self._profiles[player]
	self._profiles[player] = nil
	if profile ~= nil and profile:IsActive() then
		profile:EndSession()
	end
end

function PlayerRepository:releaseAll()
	for player in self._profiles do
		self:release(player)
	end
end

return PlayerRepository
