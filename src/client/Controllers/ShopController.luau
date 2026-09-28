--!strict

local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ProductConfig = require(ReplicatedStorage.Shared.Config.ProductConfig)

local LOCAL_PLAYER = Players.LocalPlayer

local ShopController = Knit.CreateController({ Name = "ShopController" })

function ShopController:KnitStart()
	self._service = Knit.GetService("WeaponService")
end

function ShopController:PurchaseWeapon(weaponId: string)
	return self._service:PurchaseWeapon({ weaponId = weaponId })
end

function ShopController:EquipWeapon(weaponId: string)
	return self._service:EquipWeapon({ weaponId = weaponId })
end

function ShopController:PromptDeveloperProduct(productId: number): boolean
	if ProductConfig.DeveloperProducts[productId] == nil then
		return false
	end
	MarketplaceService:PromptProductPurchase(LOCAL_PLAYER, productId)
	return true
end

function ShopController:PromptGamePass(gamePassId: number): boolean
	if ProductConfig.GamePasses[gamePassId] == nil then
		return false
	end
	MarketplaceService:PromptGamePassPurchase(LOCAL_PLAYER, gamePassId)
	return true
end

return ShopController
