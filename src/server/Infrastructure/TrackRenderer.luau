--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RaceTypes = require(ReplicatedStorage.Shared.Types.Race)
local TrackConfig = require(ReplicatedStorage.Shared.Config.TrackConfig)

type TrackPlan = RaceTypes.TrackPlan

local TrackRenderer = {}

local TAGS = table.freeze({
	Gate = "RaceGate",
	Target = "RaceTarget",
	Obstacle = "RaceObstacle",
	Pillar = "RacePillar",
	Evolver = "RaceEvolver",
	Finish = "RaceFinish",
	Checkpoint = "RaceCheckpoint",
	SpeedPad = "RaceSpeedPad",
})

local function createPart(parent: Instance, name: string, size: Vector3, cframe: CFrame): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.Size = size
	part.CFrame = cframe
	part.Parent = parent
	return part
end

local function setOwnership(instance: Instance, userId: number)
	instance:SetAttribute("OwnerUserId", userId)
end

local function resolveOrigin(base: Instance): BasePart?
	local origin = base:FindFirstChild("TrackOrigin", true)
		or base:FindFirstChild("BeginLine", true)
	return if origin ~= nil and origin:IsA("BasePart") then origin else nil
end

function TrackRenderer.render(base: Instance, userId: number, plan: TrackPlan): Model?
	local origin = resolveOrigin(base)
	if origin == nil then
		warn(
			string.format(
				"PlayerBase %s is missing a TrackOrigin or BeginLine BasePart",
				base:GetFullName()
			)
		)
		return nil
	end
	local look = origin.CFrame.LookVector
	local horizontal = Vector3.new(look.X, 0, look.Z)
	if horizontal.Magnitude <= 0.001 then
		warn(string.format("PlayerBase %s has a vertical track origin", base:GetFullName()))
		return nil
	end
	local direction = horizontal.Unit
	local right = Vector3.new(-direction.Z, 0, direction.X)

	local existing = base:FindFirstChild("GeneratedTrack")
	if existing ~= nil then
		existing:Destroy()
	end

	local model = Instance.new("Model")
	model.Name = "GeneratedTrack"
	model:SetAttribute("OwnerUserId", userId)
	model:SetAttribute("Seed", plan.Seed)
	model:SetAttribute("CheckpointCount", #plan.Segments)
	model.Parent = base

	local start = origin.Position + direction * (TrackConfig.SegmentSpacing * 0.75)

	for _, segment in plan.Segments do
		local center = start + direction * ((segment.Index - 1) * TrackConfig.SegmentSpacing)
		local ground = createPart(
			model,
			string.format("Segment_%02d", segment.Index),
			Vector3.new(16, 1, TrackConfig.SegmentSpacing - 1),
			CFrame.lookAt(center, center + direction)
		)
		ground.CanCollide = true

		local checkpointPosition = center
			+ direction * (TrackConfig.SegmentSpacing * 0.4)
			+ Vector3.new(0, 3, 0)
		local checkpoint = createPart(
			model,
			string.format("Checkpoint_%02d", segment.Index),
			Vector3.new(TrackConfig.TrackHalfWidth * 2, 7, TrackConfig.CheckpointThickness),
			CFrame.lookAt(checkpointPosition, checkpointPosition + direction)
		)
		checkpoint.CanCollide = false
		checkpoint.CanQuery = false
		checkpoint.Transparency = 1
		checkpoint:SetAttribute("CheckpointIndex", segment.Index)
		setOwnership(checkpoint, userId)
		CollectionService:AddTag(checkpoint, TAGS.Checkpoint)

		for _, gate in segment.Gates do
			local laneOffset = right * (TrackConfig.LaneOffset * gate.Lane)
			local position = center + laneOffset + Vector3.new(0, 4, 0)
			local part = createPart(
				model,
				"Gate",
				Vector3.new(5, 8, 1),
				CFrame.lookAt(position, position + direction)
			)
			part.CanCollide = false
			part.Transparency = 0.15
			part:SetAttribute("GateId", gate.Id)
			part:SetAttribute("Stat", gate.Stat)
			part:SetAttribute("Delta", gate.Delta)
			part:SetAttribute("ShotStep", gate.ShotStep)
			part:SetAttribute("HasPad", gate.HasPad)
			part:SetAttribute("PadNegative", gate.PadNegative)
			setOwnership(part, userId)
			CollectionService:AddTag(part, TAGS.Gate)

			if gate.HasPad then
				local padCenter = center + laneOffset - direction * 4 + Vector3.new(0, 0.6, 0)
				local pad = createPart(
					model,
					"SpeedPad",
					Vector3.new(5, 0.5, 7),
					CFrame.lookAt(padCenter, padCenter + direction)
				)
				pad.Material = if gate.PadNegative then Enum.Material.Glass else Enum.Material.Metal
				pad:SetAttribute("PadNegative", gate.PadNegative)
				setOwnership(pad, userId)
				CollectionService:AddTag(pad, TAGS.SpeedPad)
			end
		end

		if segment.HasTarget then
			local target = createPart(
				model,
				"Target",
				Vector3.new(3, 3, 1),
				CFrame.lookAt(center + Vector3.new(0, 5, 0), center + direction)
			)
			target.Shape = Enum.PartType.Ball
			target.CanCollide = false
			target:SetAttribute("TargetId", string.format("target-%d", segment.Index))
			setOwnership(target, userId)
			CollectionService:AddTag(target, TAGS.Target)
		end

		if segment.HasObstacle then
			local obstacle = createPart(
				model,
				"Obstacle",
				Vector3.new(3, 3, 10),
				CFrame.lookAt(center + right * TrackConfig.LaneOffset, center + direction)
			)
			obstacle:SetAttribute("ObstacleId", string.format("obstacle-%d", segment.Index))
			setOwnership(obstacle, userId)
			CollectionService:AddTag(obstacle, TAGS.Obstacle)
		end
	end

	local finishStart = start + direction * (#plan.Segments * TrackConfig.SegmentSpacing)
	for index = 1, plan.FinishLength do
		local center = finishStart + direction * ((index - 1) * TrackConfig.SegmentSpacing)
		local ground = createPart(
			model,
			string.format("Finish_%02d", index),
			Vector3.new(16, 1, TrackConfig.SegmentSpacing - 1),
			CFrame.lookAt(center, center + direction)
		)
		ground:SetAttribute("FinishMultiplier", index)

		for lane = -1, 1 do
			local laneOffset = right * (lane * (TrackConfig.TrackHalfWidth - 2.5))
			local pillar = createPart(
				model,
				string.format("FinishPillar_%d_%d", index, lane),
				Vector3.new(3, 8, 3),
				CFrame.new(center + laneOffset + Vector3.new(0, 4, 0))
			)
			pillar:SetAttribute("PillarId", string.format("pillar-%d-%d", index, lane))
			pillar:SetAttribute("RewardMultiplier", index)
			pillar:SetAttribute("Health", 3 + index)
			pillar:SetAttribute("FinishMultiplier", index)
			pillar:SetAttribute("ClaimChest", false)
			local distance = (#plan.Segments + index - 1) * TrackConfig.SegmentSpacing
			pillar:SetAttribute(
				"MinElapsedSeconds",
				distance / TrackConfig.RunnerFastPadSpeed * TrackConfig.MinimumFinishTimeScale
			)
			setOwnership(pillar, userId)
			CollectionService:AddTag(pillar, TAGS.Pillar)
			CollectionService:AddTag(pillar, TAGS.Finish)
		end
	end

	local portalCenter = finishStart + direction * (plan.FinishLength * TrackConfig.SegmentSpacing)
	local portal = createPart(
		model,
		"FinishPortal",
		Vector3.new(16, 10, 2),
		CFrame.lookAt(portalCenter + Vector3.new(0, 5, 0), portalCenter + direction)
	)
	portal.Transparency = 0.45
	portal.CanCollide = false
	portal:SetAttribute("FinishMultiplier", plan.FinishLength + 1)
	portal:SetAttribute("ClaimChest", true)
	local portalDistance = (#plan.Segments + plan.FinishLength) * TrackConfig.SegmentSpacing
	portal:SetAttribute(
		"MinElapsedSeconds",
		portalDistance / TrackConfig.RunnerFastPadSpeed * TrackConfig.MinimumFinishTimeScale
	)
	setOwnership(portal, userId)
	CollectionService:AddTag(portal, TAGS.Finish)

	if plan.HasEvolver then
		local evolverCenter = finishStart - direction * (TrackConfig.SegmentSpacing * 0.45)
		for tier, multiplier in TrackConfig.EvolverMultipliers do
			local offset = (tier - 2) * 5
			local pad = createPart(
				model,
				string.format("Evolver_%d", tier),
				Vector3.new(4, 1, 4),
				CFrame.new(evolverCenter + right * offset + Vector3.new(0, 0.6, 0))
			)
			pad:SetAttribute("Tier", tier)
			pad:SetAttribute("Multiplier", multiplier)
			pad:SetAttribute(
				"RequiredTargets",
				math.ceil(
					plan.TargetCount
						* (tier / #TrackConfig.EvolverMultipliers)
						* TrackConfig.EvolverTargetRatio
				)
			)
			setOwnership(pad, userId)
			CollectionService:AddTag(pad, TAGS.Evolver)
		end
	end

	return model
end

return table.freeze(TrackRenderer)
