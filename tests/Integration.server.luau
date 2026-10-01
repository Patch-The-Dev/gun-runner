local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StudioTestService = game:GetService("StudioTestService")
local arguments = StudioTestService:GetTestArgs()
if type(arguments) ~= "table" or arguments.suite ~= "GunRunnerIntegration" then
	return
end
local ServerScriptService = game:GetService("ServerScriptService")
local errors = {}
local errorConnection = game:GetService("ScriptContext").Error:Connect(function(message, _, source)
	if
		source
		and (source:IsDescendantOf(ServerScriptService) or source:IsDescendantOf(ReplicatedStorage))
	then
		table.insert(errors, message)
	end
end)
ServerScriptService.Server.Enabled = true
local checks = 0
local function check(condition, message)
	checks += 1
	assert(condition, message)
end
local function awaitCondition(predicate, message, seconds)
	local deadline = os.clock() + (seconds or 20)
	repeat
		if predicate() then
			return
		end
		task.wait()
	until os.clock() >= deadline
	error(message)
end
local status = Instance.new("RemoteEvent")
status.Name = "RuntimeIntegrationStatus"
status.Parent = ReplicatedStorage
local replies = {}
local connection = status.OnServerEvent:Connect(function(player, phase, detail)
	replies[player] = { phase = phase, detail = detail }
end)
local floor = Instance.new("Part")
floor.Name = "IntegrationGround"
floor.Size = Vector3.new(1000, 1, 1000)
floor.Anchored = true
floor.Parent = workspace
local spawn = Instance.new("SpawnLocation")
spawn.Anchored = true
spawn.Position = Vector3.new(0, 2, 50)
spawn.Parent = workspace
local success, failure = pcall(function()
	local Knit = require(ReplicatedStorage.Packages.Knit)
	local started, startError = Knit.OnStart():await()
	check(started, tostring(startError))
	awaitCondition(function()
		return #Players:GetPlayers() == 2
	end, "Two test clients did not join", 75)
	local players = Players:GetPlayers()
	local dataService = Knit.GetService("DataService")
	awaitCondition(function()
		return dataService:GetData(players[1]) ~= nil and dataService:GetData(players[2]) ~= nil
	end, "Actual player profiles did not load")
	for _, player in players do
		awaitCondition(function()
			return replies[player] and replies[player].phase == "ready"
		end, "Production client did not start", 45)
		check(replies[player].detail == true, "Client bootstrap or snapshot failed")
	end
	local function phase(player, name)
		replies[player] = nil
		status:FireClient(player, name)
		awaitCondition(function()
			return replies[player] and replies[player].phase == name
		end, "Client did not finish " .. name)
		check(replies[player].detail == true, "Client rejected " .. name)
	end
	local first = dataService:GetData(players[1])
	local second = dataService:GetData(players[2])
	local startingCash, startingTargets = first.Currencies.Cash, first.Currencies.Targets
	local otherCash, otherTargets = second.Currencies.Cash, second.Currencies.Targets
	phase(players[1], "claim")
	check(
		first.Currencies.Cash > startingCash and first.Currencies.Targets > startingTargets,
		"Gift did not commit both balances"
	)
	local paidCash, paidTargets = first.Currencies.Cash, first.Currencies.Targets
	phase(players[1], "replay")
	check(
		first.Currencies.Cash == paidCash and first.Currencies.Targets == paidTargets,
		"Duplicate gift changed balances"
	)
	check(
		second.Currencies.Cash == otherCash and second.Currencies.Targets == otherTargets,
		"Gift changed another player's profile"
	)
	phase(players[2], "invalid")
	first.ProcessedReceipts["integration-receipt"] = os.time()
	local confirmed, saved =
		dataService:ConfirmReceiptSaved(players[1], "integration-receipt"):await()
	check(confirmed and saved, "Mock ProfileStore receipt save was not confirmed")
	check(
		dataService._repository:isReceiptSaved(players[1], "integration-receipt"),
		"Receipt confirmation preceded actual saved data"
	)
	for _, player in players do
		phase(player, "health")
	end
	check(#errors == 0, "Unhandled server error: " .. tostring(errors[1]))
end)
errorConnection:Disconnect()
connection:Disconnect()
status:Destroy()
spawn:Destroy()
floor:Destroy()
if success then
	print(`GUN_RUNNER_RESULT:{arguments.runId}:PASS:{checks}`)
else
	warn(`GUN_RUNNER_RESULT:{arguments.runId}:FAIL:{failure}`)
end
StudioTestService:EndTest({ passed = checks, error = if success then nil else tostring(failure) })
