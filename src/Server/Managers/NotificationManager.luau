-- Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Packages
local Packages = ReplicatedStorage.Packages
local BridgeNet2 = require(Packages.BridgeNet2)

--
local NotificationManager = {
	NotifyNormalEvent = BridgeNet2.ReferenceBridge("NotifyNormal"),
	NotifyChatEvent = BridgeNet2.ReferenceBridge("NotifyChat"),
}

return NotificationManager
