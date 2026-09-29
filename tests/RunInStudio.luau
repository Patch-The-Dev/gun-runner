--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)
local tests = ServerScriptService.Tests
local results = TestEZ.TestBootstrap:run({ tests.shared, tests.server })

assert(results.failureCount == 0, string.format("%d Gun Runner tests failed", results.failureCount))
print("GUN_RUNNER_TESTS_PASS")
