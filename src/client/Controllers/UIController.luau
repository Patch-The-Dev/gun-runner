--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)
local Trove = require(ReplicatedStorage.Packages.Trove)

local MoneyFormatter = require(ReplicatedStorage.Shared.Domain.MoneyFormatter)
local Store = require(script.Parent.Parent.State.ClientStore)
local TaggedBinder = require(ReplicatedStorage.Shared.Util.TaggedBinder)

local UIController = Knit.CreateController({ Name = "UIController" })

local function setTaggedText(tag: string, text: string)
	for _, instance in CollectionService:GetTagged(tag) do
		if instance:IsA("TextLabel") or instance:IsA("TextButton") then
			instance.Text = text
		end
	end
end

local function asButton(instance: Instance): GuiButton?
	return if instance:IsA("GuiButton") then instance else nil
end

local function warnAction(action: string, message: unknown)
	warn(string.format("%s failed: %s", action, tostring(message)))
end

function UIController:KnitInit()
	self._trove = Trove.new()
end

function UIController:_render()
	local state = Store:getState()
	local profile = state.Profile
	if profile ~= nil then
		setTaggedText("CashLabel", MoneyFormatter.format(profile.Currencies.Cash))
		setTaggedText("TargetLabel", MoneyFormatter.format(profile.Currencies.Targets))
		setTaggedText("RebirthLabel", tostring(profile.Rebirths))
	end
	setTaggedText("RaceCashLabel", MoneyFormatter.format(state.Race.RunCash))
	setTaggedText("RaceTargetLabel", MoneyFormatter.format(state.Race.RunTargets))
	setTaggedText("RaceTargetsCollectedLabel", tostring(state.Race.TargetsCollected))
end

function UIController:_bindButtons()
	local progression = Knit.GetController("ProgressionController")
	local shop = Knit.GetController("ShopController")
	local gifts = Knit.GetController("GiftController")
	local invites = Knit.GetController("InviteController")

	self._trove:Add(TaggedBinder.new("UpgradePurchaseButton", function(instance)
		local button = asButton(instance)
		local upgradeId = instance:GetAttribute("UpgradeId")
		if button == nil or type(upgradeId) ~= "string" then
			return nil
		end
		local connection = button.Activated:Connect(function()
			progression:BuyUpgrade(upgradeId):catch(function(message: unknown)
				warnAction("Upgrade purchase", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("RebirthButton", function(instance)
		local button = asButton(instance)
		if button == nil then
			return nil
		end
		local connection = button.Activated:Connect(function()
			progression:BuyRebirth():catch(function(message: unknown)
				warnAction("Rebirth purchase", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("WeaponPurchaseButton", function(instance)
		local button = asButton(instance)
		local weaponId = instance:GetAttribute("WeaponId")
		if button == nil or type(weaponId) ~= "string" then
			return nil
		end
		local connection = button.Activated:Connect(function()
			shop:PurchaseWeapon(weaponId):catch(function(message: unknown)
				warnAction("Weapon purchase", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("WeaponEquipButton", function(instance)
		local button = asButton(instance)
		local weaponId = instance:GetAttribute("WeaponId")
		if button == nil or type(weaponId) ~= "string" then
			return nil
		end
		local connection = button.Activated:Connect(function()
			shop:EquipWeapon(weaponId):catch(function(message: unknown)
				warnAction("Weapon equip", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("DeveloperProductButton", function(instance)
		local button = asButton(instance)
		local productId = instance:GetAttribute("ProductId")
		if button == nil or type(productId) ~= "number" then
			return nil
		end
		local connection = button.Activated:Connect(function()
			shop:PromptDeveloperProduct(productId)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("GamePassButton", function(instance)
		local button = asButton(instance)
		local gamePassId = instance:GetAttribute("GamePassId")
		if button == nil or type(gamePassId) ~= "number" then
			return nil
		end
		local connection = button.Activated:Connect(function()
			shop:PromptGamePass(gamePassId)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("GiftClaimButton", function(instance)
		local button = asButton(instance)
		if button == nil then
			return nil
		end
		local connection = button.Activated:Connect(function()
			gifts:Claim():catch(function(message: unknown)
				warnAction("Gift claim", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))

	self._trove:Add(TaggedBinder.new("InviteButton", function(instance)
		local button = asButton(instance)
		if button == nil then
			return nil
		end
		local connection = button.Activated:Connect(function()
			invites:PromptInvite():catch(function(message: unknown)
				warnAction("Invite prompt", message)
			end)
		end)
		return function()
			connection:Disconnect()
		end
	end))
end

function UIController:KnitStart()
	self._trove:Add(Store.Changed:Connect(function()
		self:_render()
	end))

	for _, tag in
		{
			"CashLabel",
			"TargetLabel",
			"RebirthLabel",
			"RaceCashLabel",
			"RaceTargetLabel",
			"RaceTargetsCollectedLabel",
		}
	do
		self._trove:Add(CollectionService:GetInstanceAddedSignal(tag):Connect(function()
			self:_render()
		end))
	end

	self:_bindButtons()
	self:_render()
end

return UIController
