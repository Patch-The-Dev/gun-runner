--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Knit selects its implementation at runtime. Use the client API for analysis.
local Knit =
	require(ReplicatedStorage.Packages.Knit) :: typeof(require(ReplicatedStorage.Packages.Knit.KnitClient))

return Knit
