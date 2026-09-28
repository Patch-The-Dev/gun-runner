--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local InviteService = Knit.CreateService({ Name = "InviteService", Client = {} })

function InviteService:KnitInit()
	self._data = Knit.GetService("DataService")
end

function InviteService:KnitStart()
	SocialService.GameInvitePromptClosed:Connect(function(player)
		if not player:IsA("Player") then
			return
		end
		local session = self._data:GetSession(player)
		if session ~= nil then
			session.InviteBonusActive = true
		end
	end)
end

return InviteService
