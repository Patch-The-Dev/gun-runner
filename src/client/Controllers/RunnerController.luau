--!strict

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local Store = require(script.Parent.Parent.State.ClientStore)
local TrackConfig = require(ReplicatedStorage.Shared.Config.TrackConfig)

local LOCAL_PLAYER = Players.LocalPlayer
local ACTION_LEFT = "GunRunner_RaceLeft"
local ACTION_RIGHT = "GunRunner_RaceRight"

local RunnerController = Knit.CreateController({ Name = "RunnerController" })

local function horizontalUnit(vector: Vector3): Vector3?
	local horizontal = Vector3.new(vector.X, 0, vector.Z)
	return if horizontal.Magnitude > 0.001 then horizontal.Unit else nil
end

function RunnerController:KnitInit()
	self._trove = Trove.new()
	self._leftHeld = false
	self._rightHeld = false
	self._bound = false
end

function RunnerController:KnitStart()
	self._trove:Add(RunService.RenderStepped:Connect(function()
		self:_step()
	end))
	self._trove:Add(Store.Changed:Connect(function(state)
		self:_setInputBound(state.Race.State == "Running")
	end))
end

function RunnerController:_setInputBound(shouldBind: boolean)
	if shouldBind == self._bound then
		return
	end
	self._bound = shouldBind
	if not shouldBind then
		ContextActionService:UnbindAction(ACTION_LEFT)
		ContextActionService:UnbindAction(ACTION_RIGHT)
		self._leftHeld = false
		self._rightHeld = false
		return
	end

	ContextActionService:BindAction(ACTION_LEFT, function(_, inputState)
		self._leftHeld = inputState ~= Enum.UserInputState.End
			and inputState ~= Enum.UserInputState.Cancel
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.A, Enum.KeyCode.Left)
	ContextActionService:BindAction(ACTION_RIGHT, function(_, inputState)
		self._rightHeld = inputState ~= Enum.UserInputState.End
			and inputState ~= Enum.UserInputState.Cancel
		return Enum.ContextActionResult.Sink
	end, true, Enum.KeyCode.D, Enum.KeyCode.Right)
end

function RunnerController:_restoreCharacter(humanoid: Humanoid?)
	if humanoid ~= nil then
		humanoid.AutoRotate = true
	end
	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		camera.CameraType = Enum.CameraType.Custom
	end
end

function RunnerController:_step()
	local state = Store:getState()
	local direction = state.Race.Direction
	local character = LOCAL_PLAYER.Character
	local humanoid = if character ~= nil then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character ~= nil then character:FindFirstChild("HumanoidRootPart") else nil

	if
		state.Race.State ~= "Running"
		or direction == nil
		or root == nil
		or not root:IsA("BasePart")
	then
		self:_restoreCharacter(humanoid)
		return
	end

	local forward = horizontalUnit(direction)
	if forward == nil then
		return
	end
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local lateral = (if self._rightHeld then 1 else 0) - (if self._leftHeld then 1 else 0)
	local moveDirection = (forward + right * lateral)
	if moveDirection.Magnitude > 0.001 then
		moveDirection = moveDirection.Unit
	end

	local speed = TrackConfig.RunnerSpeed
	if humanoid ~= nil then
		humanoid.AutoRotate = false
		if humanoid.FloorMaterial == Enum.Material.Metal then
			speed = TrackConfig.RunnerFastPadSpeed
		elseif humanoid.FloorMaterial == Enum.Material.Glass then
			speed = TrackConfig.RunnerSlowPadSpeed
		end
	end

	root.AssemblyLinearVelocity =
		Vector3.new(moveDirection.X * speed, root.AssemblyLinearVelocity.Y, moveDirection.Z * speed)
	root.CFrame = CFrame.lookAt(root.Position, root.Position + forward)

	local camera = Workspace.CurrentCamera
	if camera ~= nil then
		camera.CameraType = Enum.CameraType.Scriptable
		local focus = root.Position + forward * 8 + Vector3.new(0, 2, 0)
		local cameraPosition = root.Position - forward * 16 + Vector3.new(0, 8, 0)
		camera.CFrame = CFrame.lookAt(cameraPosition, focus)
	end
end

return RunnerController
