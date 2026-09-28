--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local GameConfig = require(ReplicatedStorage.Shared.Config.GameConfig)
local TaggedBinder = require(ReplicatedStorage.Shared.Util.TaggedBinder)

local WorldInteractionService =
	Knit.CreateService({ Name = "WorldInteractionService", Client = {} })

local function playerFromHit(hit: BasePart): Player?
	local model = hit:FindFirstAncestorOfClass("Model")
	return if model ~= nil then Players:GetPlayerFromCharacter(model) else nil
end

local function asTouchPart(instance: Instance): BasePart?
	if instance:IsA("BasePart") then
		return instance
	end
	return instance:FindFirstChildWhichIsA("BasePart", true)
end

function WorldInteractionService:KnitInit()
	self._progression = Knit.GetService("ProgressionService")
	self._race = Knit.GetService("RaceService")
	self._weapons = Knit.GetService("WeaponService")
	self._data = Knit.GetService("DataService")
	self._base = Knit.GetService("BaseService")
	self._trove = Trove.new()
	self._touches = {} :: { [Player]: { [Instance]: number } }
end

function WorldInteractionService:KnitStart()
	self._data.SessionRemoving:Connect(function(player)
		self._touches[player] = nil
	end)

	self:_bind("RaceStart", function(player, instance)
		if self._base:OwnsInstance(player, instance) then
			self._race:StartRace(player)
		end
	end)
	self:_bind("RaceCheckpoint", function(player, instance)
		self._race:HandleCheckpointTouched(player, instance)
	end)
	self:_bind("RaceGate", function(player, instance)
		self._race:HandleGateTouched(player, instance)
	end)
	self:_bind("RaceObstacle", function(player, instance)
		self._race:HandleObstacleTouched(player, instance)
	end)
	self:_bind("RaceEvolver", function(player, instance)
		self._race:HandleEvolverTouched(player, instance)
	end)
	self:_bind("RaceFinish", function(player, instance)
		self._race:HandleFinishTouched(player, instance)
	end)
	self:_bind("UpgradePad", function(player, instance)
		local upgradeId = instance:GetAttribute("UpgradeId")
		if type(upgradeId) == "string" then
			self._progression:BuyUpgrade(player, upgradeId)
		end
	end)
	self:_bind("WeaponPad", function(player, instance)
		local weaponId = instance:GetAttribute("WeaponId")
		if type(weaponId) == "string" then
			self._weapons:PurchaseWeapon(player, weaponId)
		end
	end)
	self:_bind("BaseFallZone", function(player, instance)
		if self._base:OwnsInstance(player, instance) then
			self._race:CancelRace(player)
			self._base:TeleportToBase(player)
		end
	end)
	self:_bind("MarketPortal", function(player, instance)
		if self._base:OwnsInstance(player, instance) then
			self._race:CancelRace(player)
			self._base:TeleportToMarker(player, "MarketSpawn")
		end
	end)
end

function WorldInteractionService:_allowTouch(player: Player, instance: Instance): boolean
	local now = os.clock()
	local playerTouches = self._touches[player]
	if playerTouches == nil then
		playerTouches = setmetatable({}, { __mode = "k" }) :: { [Instance]: number }
		self._touches[player] = playerTouches
	end
	local previous = playerTouches[instance]
	if previous ~= nil and now - previous < GameConfig.TouchDebounceSeconds then
		return false
	end
	playerTouches[instance] = now
	return true
end

function WorldInteractionService:_bind(tag: string, callback: (Player, Instance) -> ())
	self._trove:Add(TaggedBinder.new(tag, function(instance)
		local part = asTouchPart(instance)
		if part == nil then
			return nil
		end
		local connection = part.Touched:Connect(function(hit)
			local player = playerFromHit(hit)
			if player ~= nil and self:_allowTouch(player, instance) then
				callback(player, instance)
			end
		end)
		return function()
			connection:Disconnect()
		end
	end))
end

return WorldInteractionService
