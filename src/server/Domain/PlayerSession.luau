--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Trove = require(ReplicatedStorage.Packages.Trove)

local EntitlementTypes = require(ReplicatedStorage.Shared.Types.Entitlements)
local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local RaceSession = require(script.Parent.RaceSession)

type Entitlements = EntitlementTypes.Entitlements
type PlayerData = PlayerDataTypes.PlayerData
type RaceSessionType = RaceSession.RaceSession

local PlayerSession = {}
PlayerSession.__index = PlayerSession

export type PlayerSession = typeof(setmetatable(
	{} :: {
		Player: Player,
		Data: PlayerData,
		Entitlements: Entitlements,
		Trove: typeof(Trove.new()),
		Base: Instance?,
		Race: RaceSessionType?,
		InviteBonusActive: boolean,
	},
	PlayerSession
))

function PlayerSession.new(player: Player, data: PlayerData): PlayerSession
	return setmetatable({
		Player = player,
		Data = data,
		Entitlements = {
			CashMultiplier = 1,
			TargetMultiplier = 1,
			RebirthIncrement = 1,
			ProjectileCount = 1,
			ExplosiveRounds = false,
		},
		Trove = Trove.new(),
		Base = nil,
		Race = nil,
		InviteBonusActive = false,
	}, PlayerSession)
end

function PlayerSession:Destroy()
	self.Race = nil
	self.Base = nil
	self.Trove:Destroy()
end

return PlayerSession
