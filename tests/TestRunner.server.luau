--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)

local results = TestEZ.TestBootstrap:run({
	script.Parent.shared,
	script.Parent.server,
})

if results.failureCount > 0 then
	error(string.format("%d tests failed", results.failureCount))
end
