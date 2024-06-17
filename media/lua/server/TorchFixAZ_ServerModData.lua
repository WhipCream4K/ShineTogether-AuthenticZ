local serverModData = {}

serverModData.get = function()
    return ModData.get("TorchFixAZ_Glowstick")
end

local function onGlobalModDataLoad(isNewGame)
    ModData.add("TorchFixAZ_Glowstick",{})
end

Events.OnInitGlobalModData.Add(onGlobalModDataLoad)

return serverModData