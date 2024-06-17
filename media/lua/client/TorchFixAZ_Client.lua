local Network = require "TorchFixAZ_NetworkVariables"

TorhFixAZ_Client = {}
TorhFixAZ_Client[Network.Module] = {}
local ClientOps = TorhFixAZ_Client[Network.Module]

ClientOps[Network.Commands.onGlowstickPickup] = function (args)

    local player = getPlayer()
    local inventory = player:getInventory()
    local targetID = args.itemID

    local targetItem = inventory:getItemById(targetID)

    if targetItem == nil then
        return
    end

    local lastCalDelta = args.lastCalDelta
    targetItem:setUsedDelta(lastCalDelta)
    inventory:setDrawDirty(true)
end

ClientOps[Network.Commands.updateGlowstickDelta] = function (args)
    
    if args == nil then return end

    local updateGlowsticks = args

    for itemID, glowstick in pairs(updateGlowsticks) do

        local square = getSquare(glowstick.x, glowstick.y, glowstick.z)

        if square ~= nil then

            local worldObjects = square:getWorldObjects()
    
            for i=0,worldObjects:size()-1 do
        
                local worldObject = worldObjects:get(i)
                local item = worldObject:getItem()
                if item:getID() == itemID then
                    
                    item:setUsedDelta(glowstick.delta)
                    break
                end

            end
        end

    end


    local floorContainer = ISInventoryPage.GetFloorContainer(0)
    floorContainer:setDrawDirty(true)

end


local function onServerToClient(module, command, args)
    if module == TorhFixAZ_Network.Module and ClientOps[command] then
        ClientOps[command](args)
    end
end

Events.OnServerCommand.Add(onServerToClient)

return TorhFixAZ_Client