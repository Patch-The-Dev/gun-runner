--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SocialService = game:GetService("SocialService")

local CommonTypes = require(ReplicatedStorage.Shared.Types.Common)
local Knit = require(script.Parent.Parent.KnitClient)
local Promise = require(ReplicatedStorage.Packages.Promise)

local LOCAL_PLAYER = Players.LocalPlayer

local InviteController = Knit.CreateController({ Name = "InviteController" })

function InviteController:PromptInvite()
	return Promise.new(function(resolve, reject)
		local canInviteSuccess, canInvite = pcall(function()
			return SocialService:CanSendGameInviteAsync(LOCAL_PLAYER)
		end)
		if not canInviteSuccess then
			reject(canInvite)
			return
		end
		if not canInvite then
			local result: CommonTypes.ActionResult = { ok = false, error = "invite_unavailable" }
			resolve(result)
			return
		end

		local promptSuccess, promptError = pcall(function()
			SocialService:PromptGameInvite(LOCAL_PLAYER)
		end)
		if not promptSuccess then
			reject(promptError)
			return
		end

		local result: CommonTypes.ActionResult = { ok = true }
		resolve(result)
	end)
end

return InviteController
