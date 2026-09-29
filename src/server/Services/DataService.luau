--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Signal = require(ReplicatedStorage.Packages.Signal)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local PlayerRepository = require(script.Parent.Parent.Persistence.PlayerRepository)
local PlayerSession = require(script.Parent.Parent.Domain.PlayerSession)

type PlayerData = PlayerDataTypes.PlayerData
type PlayerSnapshot = PlayerDataTypes.PlayerSnapshot
type PlayerSessionType = PlayerSession.PlayerSession

local DataService = Knit.CreateService({
	Name = "DataService",
	Client = {
		SnapshotChanged = Knit.CreateSignal(),
	},
})

DataService.SessionAdded = Signal.new()
DataService.SessionRemoving = Signal.new()

function DataService:KnitInit()
	self._requests = Knit.GetService("RequestGateService")
	self._repository = PlayerRepository.new()
	self._sessions = {} :: { [Player]: PlayerSessionType }
	self._loading = {} :: { [Player]: boolean }
	self._trove = Trove.new()
end

function DataService:KnitStart()
	self._trove:Connect(Players.PlayerAdded, function(player)
		self:_loadPlayer(player)
	end)
	self._trove:Connect(Players.PlayerRemoving, function(player)
		self:_removePlayer(player)
	end)

	for _, player in Players:GetPlayers() do
		self:_loadPlayer(player)
	end

	game:BindToClose(function()
		self._repository:releaseAll()
	end)
end

function DataService:_loadPlayer(player: Player)
	if self._sessions[player] ~= nil or self._loading[player] then
		return
	end
	self._loading[player] = true

	self._repository
		:load(player)
		:andThen(function(data: PlayerData)
			self._loading[player] = nil
			if player.Parent ~= Players then
				self._repository:release(player)
				return
			end
			if self._sessions[player] ~= nil then
				self._repository:release(player)
				return
			end
			local session = PlayerSession.new(player, data)
			self._sessions[player] = session
			self.SessionAdded:Fire(player, session)
			self:PublishSnapshot(player)
		end)
		:catch(function(message: unknown)
			self._loading[player] = nil
			warn(string.format("Profile load failed for %s: %s", player.Name, tostring(message)))
			if player.Parent == Players then
				player:Kick("Your data could not be loaded. Please rejoin.")
			end
		end)
end

function DataService:_removePlayer(player: Player)
	self._loading[player] = nil
	local session = self._sessions[player]
	if session ~= nil then
		self.SessionRemoving:Fire(player, session)
		session:Destroy()
		self._sessions[player] = nil
	end
	self._repository:release(player)
end

function DataService:GetSession(player: Player): PlayerSessionType?
	return self._sessions[player]
end

function DataService:GetData(player: Player): PlayerData?
	local session = self._sessions[player]
	return if session ~= nil then session.Data else nil
end

function DataService:GetSnapshot(player: Player): PlayerSnapshot?
	local session = self._sessions[player]
	if session == nil then
		return nil
	end
	local data = session.Data
	return {
		Currencies = table.clone(data.Currencies),
		Rebirths = data.Rebirths,
		Upgrades = table.clone(data.Upgrades),
		Weapons = {
			Owned = table.clone(data.Weapons.Owned),
			Equipped = data.Weapons.Equipped,
		},
		Entitlements = table.clone(session.Entitlements),
	}
end

function DataService:PublishSnapshot(player: Player)
	local snapshot = self:GetSnapshot(player)
	if snapshot ~= nil then
		self.Client.SnapshotChanged:Fire(player, snapshot)
	end
end

function DataService:ConfirmReceiptSaved(player: Player, purchaseId: string)
	return self._repository:saveAndConfirmReceipt(player, purchaseId)
end

function DataService.Client:GetSnapshot(player: Player): PlayerSnapshot?
	if not self.Server._requests:Allow(player, "Read") then
		return nil
	end
	return self.Server:GetSnapshot(player)
end

return DataService
