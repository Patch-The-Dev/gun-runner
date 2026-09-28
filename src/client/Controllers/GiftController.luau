--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local GiftController = Knit.CreateController({ Name = "GiftController" })

function GiftController:KnitStart()
	self._service = Knit.GetService("GiftService")
end

function GiftController:GetStatus()
	return self._service:GetStatus()
end

function GiftController:Claim()
	return self._service:Claim()
end

return GiftController
