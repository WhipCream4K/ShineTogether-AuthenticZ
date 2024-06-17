require "Light/StaticPointLight"
local Network = require "Light/StaticPointLight_Network"

if not isClient() then return end

StaticPointLight_Client = {}

StaticPointLight_Client[Network.Module] = {}
local ClientOps = StaticPointLight_Client[Network.Module]

ClientOps[Network.Commands.createGlobal] = function (args)
    if args == nil then 
        return 
    end

    local player = getPlayer()
    local playerModData = player:getModData()[StaticPointLight.modDataName]
    if playerModData == nil then
        StaticPointLight:new(args.x, args.y, args.z, args.r, args.g, args.b, args.radius, args.uniqueID)
    else
        if playerModData[args.uniqueID] == nil then
            StaticPointLight:new(args.x, args.y, args.z, args.r, args.g, args.b, args.radius, args.uniqueID)
        end
    end

end

ClientOps[Network.Commands.removeGlobal] = function (args)
    if args == nil then return end

    local player = getPlayer()
    local playerModData = player:getModData()[StaticPointLight.modDataName]

    if playerModData == nil or playerModData[args.uniqueID] == nil then
        return
    end

    local pointlight = playerModData[args.uniqueID]
    pointlight:_remove()
end

ClientOps[Network.Commands.receiveAll] = function (args)
    
    if args == nil then return end

    local player = getPlayer()
    local modData = player:getModData()
    modData[StaticPointLight.modDataName] = modData[StaticPointLight.modDataName] or {}

    modData = modData[StaticPointLight.modDataName]

    for uniqueID, light in pairs(args) do
        if modData[uniqueID] == nil then
            StaticPointLight:new(light.x, light.y, light.z, light.r, light.g, light.b, light.radius, uniqueID)
        end
    end

    if getDebug() then
        print("Received all static point lights from server.")
    end

end

local function onServerToClient(module, command, args)
    if StaticPointLight_Client[module] and StaticPointLight_Client[module][command] then
        StaticPointLight_Client[module][command](args)
    end
end

Events.OnServerCommand.Add(onServerToClient)

return StaticPointLight_Client