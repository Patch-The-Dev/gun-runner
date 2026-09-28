--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddServices(script.Services)

Knit.Start():catch(function(message: unknown)
	error(string.format("Server bootstrap failed: %s", tostring(message)))
end)
