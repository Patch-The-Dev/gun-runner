--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local RequestBudget = require(script.Parent.Parent.Domain.RequestBudget)

local RequestGateService = Knit.CreateService({ Name = "RequestGateService", Client = {} })

function RequestGateService:KnitInit()
	self._budget = RequestBudget.new()
end

function RequestGateService:KnitStart()
	Players.PlayerRemoving:Connect(function(player)
		self._budget:forget(player)
	end)
end

function RequestGateService:Allow(player: Player, category: string): boolean
	return self._budget:allow(player, category)
end

return RequestGateService
