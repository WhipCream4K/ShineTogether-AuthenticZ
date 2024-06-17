require "Light/StaticPointLight"
local Network = require "TorchFixAZ_NetworkVariables"
local ServerModData = require "TorchFixAZ_ServerModData"

if isClient() then return end

TorhFixAZ_Server = {}

TorhFixAZ_Server[Network.Module] = {}
local ServerOps = TorhFixAZ_Server[Network.Module]

ServerOps[Network.Commands.onGlowstickFall] = function (player,args)
    
    if args == nil then return end

    local targetID = args.itemID
    local squareX = args.x
    local squareY = args.y
    local squareZ = args.z

    local square = getSquare(squareX,squareY,squareZ)
    if square == nil then
        error("Square is nil. Maybe do something about this.")
        return
    end

    local worldObjects = square:getWorldObjects()
    
    for i=0, worldObjects:size()-1 do

        local worldObject = worldObjects:get(i)
        local item = worldObject:getItem()

        if item ~= nil then

            if item:getID() == targetID then

                -- print("Glowstick has fallen. ID: " .. targetID)
                
                local pointLight = StaticPointLight.createOnServer(squareX, squareY, squareZ, args.r, args.g, args.b, args.radius)

                local serverModData = ServerModData.get()
                serverModData[targetID] = serverModData[targetID] or {}

                local glowstickData = 
                {
                    x = squareX,
                    y = squareY,
                    z = squareZ,
                    item = item,
                    pointLight = pointLight
                }

                serverModData[targetID] = glowstickData
                serverModData.activeGlowsticks = serverModData.activeGlowsticks or {}
                table.insert(serverModData.activeGlowsticks, targetID)
                break
            end
        end
    end

end

ServerOps[Network.Commands.onGlowstickPickup] = function (player,args)
    
    if args == nil then return end

    local targetID = args.itemID

    local serverModData = ServerModData.get()

    local glowstickData = serverModData[targetID]
    if glowstickData == nil then
        return
    end


    if glowstickData.lastCalDelta ~= nil then
        args.lastCalDelta = glowstickData.lastCalDelta
        sendServerCommand(player, TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.onGlowstickPickup, args)
    end


end

ServerOps[Network.Commands.onGlowstickRemovedFromSquare] = function(player, args)
    if args == nil then return end

    local targetID = args.itemID
    
    local serverModData = ServerModData.get()
    
    if serverModData[targetID] == nil then
        return
    end
    
    local pointLight = serverModData[targetID].pointLight
    
    if pointLight == nil then
        return
    end
    
    StaticPointLight.removeOnServer(pointLight)
    serverModData[targetID] = nil
end

local function onClientToServer(module, command, player, args)
    if TorhFixAZ_Server[module] and TorhFixAZ_Server[module][command] then
        TorhFixAZ_Server[module][command](player, args)
    end
end

Events.OnClientCommand.Add(onClientToServer)

return TorhFixAZ_Server

