--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Signal = require(ReplicatedStorage.Packages.Signal)

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)

type PlayerSnapshot = PlayerDataTypes.PlayerSnapshot
type RaceSnapshot = RaceTypes.RaceSnapshot

export type ClientState = {
	Profile: PlayerSnapshot?,
	Race: RaceSnapshot,
}

export type ClientStore = {
	Changed: typeof(Signal.new()),
	_state: ClientState,
	getState: (self: ClientStore) -> ClientState,
	setProfile: (self: ClientStore, profile: PlayerSnapshot) -> (),
	setRace: (self: ClientStore, race: RaceSnapshot) -> (),
	destroy: (self: ClientStore) -> (),
}

local DEFAULT_RACE: RaceSnapshot = {
	State = "Idle",
	RunCash = 0,
	RunTargets = 0,
	TargetsCollected = 0,
	FinishMultiplier = 1,
	Direction = nil,
	Weapon = nil,
}

local ClientStore = {}
ClientStore.__index = ClientStore

local function freezeProfile(profile: PlayerSnapshot): PlayerSnapshot
	return table.freeze({
		Currencies = table.freeze(table.clone(profile.Currencies)),
		Rebirths = profile.Rebirths,
		Upgrades = table.freeze(table.clone(profile.Upgrades)),
		Weapons = table.freeze({
			Owned = table.freeze(table.clone(profile.Weapons.Owned)),
			Equipped = profile.Weapons.Equipped,
		}),
		Entitlements = table.freeze(table.clone(profile.Entitlements)),
	})
end

local function freezeRace(race: RaceSnapshot): RaceSnapshot
	return table.freeze({
		State = race.State,
		RunCash = race.RunCash,
		RunTargets = race.RunTargets,
		TargetsCollected = race.TargetsCollected,
		FinishMultiplier = race.FinishMultiplier,
		Direction = race.Direction,
		Weapon = if race.Weapon ~= nil then table.freeze(table.clone(race.Weapon)) else nil,
	})
end

local function freezeState(profile: PlayerSnapshot?, race: RaceSnapshot): ClientState
	return table.freeze({ Profile = profile, Race = race })
end

function ClientStore.new(): ClientStore
	local self = setmetatable({
		Changed = Signal.new(),
		_state = freezeState(nil, freezeRace(DEFAULT_RACE)),
	}, ClientStore)
	return (self :: unknown) :: ClientStore
end

function ClientStore.getState(self: ClientStore): ClientState
	return self._state
end

function ClientStore.setProfile(self: ClientStore, profile: PlayerSnapshot)
	self._state = freezeState(freezeProfile(profile), self._state.Race)
	self.Changed:Fire(self._state)
end

function ClientStore.setRace(self: ClientStore, race: RaceSnapshot)
	self._state = freezeState(self._state.Profile, freezeRace(race))
	self.Changed:Fire(self._state)
end

function ClientStore.destroy(self: ClientStore)
	self.Changed:Destroy()
end

return ClientStore.new()
