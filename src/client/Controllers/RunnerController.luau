--!strict

local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Knit = require(script.Parent.Parent.KnitClient)
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
	self._wasRunning = false
	self._floorRaycastParams = RaycastParams.new()
	self._floorRaycastParams.FilterType = Enum.RaycastFilterType.Exclude
	self._floorRaycastParams.RespectCanCollide = true
end

function RunnerController:KnitStart()
	self._trove:Add(RunService.RenderStepped:Connect(function()
		self:_step()
	end))
	self._trove:Add(Store.Changed:Connect(function(state)
		self:_setInputBound(state.Race.State == "Running")
	end))
	self:_setInputBound(Store:getState().Race.State == "Running")
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

function RunnerController:_getRunSpeed(
	character: Model,
	humanoid: Humanoid?,
	root: BasePart
): number
	if humanoid == nil or humanoid.FloorMaterial == Enum.Material.Air then
		return TrackConfig.RunnerSpeed
	end

	local raycastParams = self._floorRaycastParams
	raycastParams.FilterDescendantsInstances = { character }
	local rayLength = humanoid.HipHeight + root.Size.Y / 2 + 2
	local result = Workspace:Raycast(root.Position, Vector3.new(0, -rayLength, 0), raycastParams)
	local floor = if result ~= nil then result.Instance else nil
	if
		floor == nil
		or not CollectionService:HasTag(floor, "RaceSpeedPad")
		or floor:GetAttribute("OwnerUserId") ~= LOCAL_PLAYER.UserId
	then
		return TrackConfig.RunnerSpeed
	end

	return if floor:GetAttribute("PadNegative") == true
		then TrackConfig.RunnerSlowPadSpeed
		else TrackConfig.RunnerFastPadSpeed
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
		or character == nil
		or root == nil
		or not root:IsA("BasePart")
	then
		if self._wasRunning then
			self:_restoreCharacter(humanoid)
			self._wasRunning = false
		end
		return
	end

	local forward = horizontalUnit(direction)
	if forward == nil then
		return
	end
	self._wasRunning = true
	local right = Vector3.new(-forward.Z, 0, forward.X)
	local lateral = (if self._rightHeld then 1 else 0) - (if self._leftHeld then 1 else 0)
	local moveDirection = (forward + right * lateral)
	if moveDirection.Magnitude > 0.001 then
		moveDirection = moveDirection.Unit
	end

	if humanoid ~= nil then
		humanoid.AutoRotate = false
	end

	local speed = self:_getRunSpeed(character, humanoid, root)
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
