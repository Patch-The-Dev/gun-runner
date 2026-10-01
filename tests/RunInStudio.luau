--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local TestEZ = require(ReplicatedStorage.DevPackages.TestEZ)
local tests = ServerScriptService.Tests
local results = TestEZ.TestBootstrap:run({ tests.shared, tests.server })

print(
	`{results.successCount} passed, {results.failureCount} failed, {results.skippedCount} skipped`
)
if results.failureCount > 0 or results.skippedCount > 0 then
	print("GUN_RUNNER_TESTS_FAIL")
end
assert(results.failureCount == 0, string.format("%d Gun Runner tests failed", results.failureCount))
assert(results.skippedCount == 0, "Gun Runner tests were skipped")
print("GUN_RUNNER_TESTS_PASS")
