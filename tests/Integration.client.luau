local Players = game:GetService("Players")
local client = Players.LocalPlayer.PlayerScripts:WaitForChild("Client")
local errors = {}
local errorConnection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
	if
		source
		and (
			source:IsDescendantOf(game:GetService("ReplicatedStorage"))
			or source == client
			or source:IsDescendantOf(client)
		)
	then
		table.insert(errors, message)
	end
end)
script.Destroying:Connect(function()
	errorConnection:Disconnect()
end)
client.Enabled = true
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)
local status = ReplicatedStorage:WaitForChild("RuntimeIntegrationStatus", 60)
assert(status, "Runtime test status remote is missing")
local started, startError = Knit.OnStart():await()
assert(started, tostring(startError))
local snapshot
local deadline = os.clock() + 30
repeat
	snapshot = Knit.GetController("DataController"):GetStore():getState().Profile
	if snapshot ~= nil then
		break
	end
	task.wait(0.5)
until os.clock() >= deadline
status.OnClientEvent:Connect(function(phase)
	local success, failure = pcall(function()
		assert(#errors == 0, "Unhandled client error: " .. tostring(errors[1]))
		if phase == "health" then
			assert(#errors == 0, "Client reported an unhandled error")
		elseif phase == "claim" then
			local before =
				Knit.GetController("DataController"):GetStore():getState().Profile.Currencies.Cash
			assert(Knit.GetService("GiftService"):Claim():expect().ok, "First gift was rejected")
			local endsAt = os.clock() + 10
			repeat
				if
					Knit.GetController("DataController")
						:GetStore()
						:getState().Profile.Currencies.Cash > before
				then
					break
				end
				task.wait()
			until os.clock() >= endsAt
			assert(
				Knit.GetController("DataController"):GetStore():getState().Profile.Currencies.Cash
					> before,
				"Gift snapshot did not reach the client controller"
			)
		elseif phase == "replay" then
			assert(
				not Knit.GetService("GiftService"):Claim():expect().ok,
				"Duplicate gift was accepted"
			)
		elseif phase == "invalid" then
			assert(
				not Knit.GetService("WeaponService")
					:FireWeapon({ direction = Vector3.new(0 / 0, 0, 0) })
					:expect(),
				"Invalid aim was accepted"
			)
		else
			error("Unknown test phase")
		end
	end)
	if not success then
		warn(failure)
	end
	status:FireServer(phase, success)
end)
status:FireServer("ready", snapshot ~= nil and #errors == 0)
