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
	Changed: Signal.Signal<ClientState>,
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

local function cloneState(state: ClientState): ClientState
	return {
		Profile = state.Profile,
		Race = state.Race,
	}
end

function ClientStore.new(): ClientStore
	local self = setmetatable({
		Changed = Signal.new(),
		_state = {
			Profile = nil,
			Race = DEFAULT_RACE,
		},
	}, ClientStore)
	return self :: ClientStore
end

function ClientStore:getState(): ClientState
	return self._state
end

function ClientStore:setProfile(profile: PlayerSnapshot)
	self._state = {
		Profile = profile,
		Race = self._state.Race,
	}
	self.Changed:Fire(cloneState(self._state))
end

function ClientStore:setRace(race: RaceSnapshot)
	self._state = {
		Profile = self._state.Profile,
		Race = race,
	}
	self.Changed:Fire(cloneState(self._state))
end

function ClientStore:destroy()
	self.Changed:Destroy()
end

return ClientStore.new()
