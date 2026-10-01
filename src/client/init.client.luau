--!strict

local Knit = require(script.KnitClient)

Knit.AddControllers(script.Controllers)

Knit.Start():catch(function(message: unknown)
	error(string.format("Client bootstrap failed: %s", tostring(message)))
end)
