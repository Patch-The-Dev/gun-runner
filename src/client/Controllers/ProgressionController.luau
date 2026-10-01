--!strict

local Knit = require(script.Parent.Parent.KnitClient)

local ProgressionController = Knit.CreateController({ Name = "ProgressionController" })

function ProgressionController:KnitStart()
	self._service = Knit.GetService("ProgressionService")
end

function ProgressionController:BuyUpgrade(upgradeId: string)
	return self._service:BuyUpgrade({ upgradeId = upgradeId })
end

function ProgressionController:BuyRebirth()
	return self._service:BuyRebirth()
end

return ProgressionController
