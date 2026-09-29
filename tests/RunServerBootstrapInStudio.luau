--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Knit = require(ReplicatedStorage.Packages.Knit)
Knit.AddServices(ServerScriptService.Server.Services)

local started, result = Knit.Start():await()
assert(started, string.format("Gun Runner server bootstrap failed: %s", tostring(result)))
assert(Knit.GetService("RequestGateService") ~= nil, "RequestGateService was not loaded")
print("GUN_RUNNER_SERVER_BOOTSTRAP_PASS")
