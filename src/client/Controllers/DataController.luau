--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local PlayerDataTypes = require(ReplicatedStorage.Shared.Types.PlayerData)
local Store = require(script.Parent.Parent.State.ClientStore)

type PlayerSnapshot = PlayerDataTypes.PlayerSnapshot

local DataController = Knit.CreateController({ Name = "DataController" })

function DataController:KnitInit()
	self._trove = Trove.new()
end

function DataController:KnitStart()
	local service = Knit.GetService("DataService")

	self._trove:Add(service.SnapshotChanged:Connect(function(snapshot: PlayerSnapshot)
		Store:setProfile(snapshot)
	end))

	service
		:GetSnapshot()
		:andThen(function(snapshot: PlayerSnapshot?)
			if snapshot ~= nil then
				Store:setProfile(snapshot)
			end
		end)
		:catch(function(message: unknown)
			warn(string.format("Failed to fetch initial profile snapshot: %s", tostring(message)))
		end)
end

function DataController:GetStore()
	return Store
end

return DataController
