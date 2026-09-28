--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PlayerSession = require(script.Parent.Parent.Domain.PlayerSession)
type PlayerSessionType = PlayerSession.PlayerSession

local BaseService = Knit.CreateService({ Name = "BaseService", Client = {} })

local function resetBase(base: Instance)
	base:SetAttribute("OwnerUserId", 0)
	base:SetAttribute("RaceActive", false)
	local generatedTrack = base:FindFirstChild("GeneratedTrack")
	if generatedTrack ~= nil then
		generatedTrack:Destroy()
	end
end

local function getMarker(base: Instance, markerName: string): BasePart?
	local marker = base:FindFirstChild(markerName, true)
	return if marker ~= nil and marker:IsA("BasePart") then marker else nil
end

function BaseService:KnitInit()
	self._data = Knit.GetService("DataService")
	self._owned = {} :: { [Player]: Instance }
	self._waiting = {} :: { [Player]: PlayerSessionType }
end

function BaseService:KnitStart()
	self._data.SessionAdded:Connect(function(player, session: PlayerSessionType)
		self:_attachSession(player, session)
	end)
	self._data.SessionRemoving:Connect(function(player)
		self._waiting[player] = nil
		self:ReleaseBase(player)
	end)
	CollectionService:GetInstanceAddedSignal("PlayerBase"):Connect(function()
		self:_assignWaitingPlayers()
	end)

	for _, player in Players:GetPlayers() do
		local session = self._data:GetSession(player)
		if session ~= nil then
			self:_attachSession(player, session)
		end
	end
end

function BaseService:_attachSession(player: Player, session: PlayerSessionType)
	if self._owned[player] ~= nil then
		return
	end

	local base = self:_claimBase(player)
	if base == nil then
		self._waiting[player] = session
		return
	end

	self:_assignBase(player, session, base)
end

function BaseService:_assignBase(player: Player, session: PlayerSessionType, base: Instance)
	self._waiting[player] = nil
	session.Base = base
	self._owned[player] = base

	session.Trove:Connect(player.CharacterAdded, function(character)
		task.defer(function()
			self:TeleportToBase(player, character)
		end)
	end)
	if player.Character ~= nil then
		task.defer(function()
			self:TeleportToBase(player, player.Character)
		end)
	end
end

function BaseService:_assignWaitingPlayers()
	for _, player in Players:GetPlayers() do
		local session = self._waiting[player]
		if session ~= nil and self._owned[player] == nil then
			local base = self:_claimBase(player)
			if base == nil then
				return
			end
			self:_assignBase(player, session, base)
		end
	end
end

function BaseService:_claimBase(player: Player): Instance?
	local bases = CollectionService:GetTagged("PlayerBase")
	table.sort(bases, function(a, b)
		return a.Name < b.Name
	end)
	for _, base in bases do
		if (base:GetAttribute("OwnerUserId") or 0) == 0 then
			resetBase(base)
			base:SetAttribute("OwnerUserId", player.UserId)
			return base
		end
	end
	return nil
end

function BaseService:GetBase(player: Player): Instance?
	return self._owned[player]
end

function BaseService:OwnsBase(player: Player, base: Instance): boolean
	return self._owned[player] == base and base:GetAttribute("OwnerUserId") == player.UserId
end

function BaseService:OwnsInstance(player: Player, instance: Instance): boolean
	local base = self._owned[player]
	return base ~= nil
		and instance:IsDescendantOf(base)
		and base:GetAttribute("OwnerUserId") == player.UserId
end

function BaseService:TeleportToMarker(
	player: Player,
	markerName: string,
	characterOverride: Model?
): boolean
	local base = self._owned[player]
	local marker = if base ~= nil then getMarker(base, markerName) else nil
	local character = characterOverride or player.Character
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil
	if marker == nil or root == nil or not root:IsA("BasePart") then
		return false
	end
	root.CFrame = marker.CFrame + Vector3.new(0, 3, 0)
	return true
end

function BaseService:TeleportToBase(player: Player, characterOverride: Model?): boolean
	return self:TeleportToMarker(player, "Spawn", characterOverride)
end

function BaseService:ReleaseBase(player: Player)
	local base = self._owned[player]
	if base ~= nil then
		resetBase(base)
	end
	self._owned[player] = nil
	task.defer(function()
		self:_assignWaitingPlayers()
	end)
end

return BaseService
