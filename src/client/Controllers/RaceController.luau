--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)
local Store = require(script.Parent.Parent.State.ClientStore)

type RaceSnapshot = RaceTypes.RaceSnapshot

local RaceController = Knit.CreateController({ Name = "RaceController" })

function RaceController:KnitInit()
	self._trove = Trove.new()
end

function RaceController:KnitStart()
	local service = Knit.GetService("RaceService")
	self._trove:Add(service.RaceChanged:Connect(function(snapshot: RaceSnapshot)
		Store:setRace(snapshot)
	end))

	service
		:GetSnapshot()
		:andThen(function(snapshot: RaceSnapshot?)
			if snapshot ~= nil then
				Store:setRace(snapshot)
			end
		end)
		:catch(function(message: unknown)
			warn(string.format("Failed to fetch initial race state: %s", tostring(message)))
		end)
end

return RaceController
