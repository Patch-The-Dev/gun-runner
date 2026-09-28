--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

Knit.AddControllers(script.Controllers)

Knit.Start():catch(function(message: unknown)
	error(string.format("Client bootstrap failed: %s", tostring(message)))
end)
