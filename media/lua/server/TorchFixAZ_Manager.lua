require "Light/StaticPointlight"
require "TorchFixAZ_NetworkVariables"
local utils = require "TorchFixAZ_utils"
local ServerModData = require "TorchFixAZ_ServerModData"

if isClient() then return end

TorhFixAZ_Manager = {}

-- This value has been tested to be at 120 ticks per minute in game time
-- although it might varied depending on the game's performance
TorhFixAZ_Manager.TickCountPerMinute = 120

TorhFixAZ_Manager.Epsilon = 1e-5

local function removeGlowstickData(item)

    local itemID = item:getID()
    local serverModData = ServerModData.get()
    local glowstickData = serverModData[itemID]

    if glowstickData ~= nil then

        local pointLight = glowstickData.pointLight
        if pointLight ~= nil then
            StaticPointLight.removeOnServer(pointLight)
        end

        serverModData[itemID] = nil
    end

end

local function removeWorldActiveGlowstick(x,y,z,worldItemGlowstick)
    
    local glowstickItem = worldItemGlowstick:getItem()
    removeGlowstickData(glowstickItem)

    -- replace the glowstick with blank glowstick

    glowstickItem:setJobDelta(0.0)

    local square = getSquare(x, y, z)

    -- add blank glowstick to square
    -- TODO: Maybe change the blank glowstick string to compensate for the mod's name
    local blankGlowstick = InventoryItemFactory.CreateItem("AuthenticZLite.AuthenticGlowstick_Blank")

    local itemWorldPosX = worldItemGlowstick:getWorldPosX()
    local itemWorldPosY = worldItemGlowstick:getWorldPosY()
    local itemWorldPosZ = worldItemGlowstick:getWorldPosZ()

    local xOff = itemWorldPosX - x
    local yOff = itemWorldPosY - y
    local zOff = itemWorldPosZ - z

    square:AddWorldInventoryItem(blankGlowstick, xOff, yOff, zOff)

    -- remove from square
    square:transmitRemoveItemFromSquareOnServer(worldItemGlowstick)
    square:removeWorldObject(worldItemGlowstick)
    glowstickItem:setWorldItem(nil)

end

local function removeActiveGlowstick(item)
    removeGlowstickData(item)
end

local function registerGlowstickItem(x,y,z,glowstickItem,shouldCreatePointLight)
    
    local itemID = glowstickItem:getID()

    local serverModData = ServerModData.get()

    if serverModData[itemID] == nil then

        local glowstickData =
        {
            x = x,
            y = y,
            z = z,
            item = glowstickItem,
        }

        local glowstickColor = utils.getGlowstickColor(glowstickItem)
        
        if shouldCreatePointLight then

            local pointLight = StaticPointLight.createOnServer(
                glowstickData.x, glowstickData.y, glowstickData.z, 
                glowstickColor.r, glowstickColor.g, glowstickColor.b,
                utils.getGlowRadius())
            
            glowstickData.pointLight = pointLight
        end
        
        serverModData[itemID] = glowstickData
    else

        serverModData[itemID].item = glowstickItem

    end

    serverModData.activeGlowsticks = serverModData.activeGlowsticks or {}
    table.insert(serverModData.activeGlowsticks, itemID)

end

TorhFixAZ_Manager.onLoadGridsquare = function (square)
    
    local worldInventory = square:getWorldObjects()

    for i=0, worldInventory:size()-1 do
        local worldObject = worldInventory:get(i)
        local glowstickItem = worldObject:getItem()
        if glowstickItem ~= nil then

            if utils.isActivatedGlowstick(glowstickItem) then

                -- print("Found a activated glowstick!")
                -- print("Vanila ID: " .. glowstickItem:getID())
                -- print("The glowstick is at " .. square:getX() .. ", " .. square:getY() .. ", " .. square:getZ() .. ".")
                
                registerGlowstickItem(square:getX(), square:getY(), square:getZ(), glowstickItem, true)

            end
        end
    end


    -- TODO: Maybe add for every glowsticks that is in containers, update the glowstick's delta

    -- -- Find every glowsticks that are inside containers
    -- local squareObjects = square:getObjects()
    -- for i = 0 , squareObjects:size() - 1 do
    --     local object = squareObjects:get(i)
    --     local containerCount = object:getContainerCount()
    --     for j = 0, containerCount - 1 do
    --         local container = object:getContainerByIndex(j)
    --         local items = container:getItems()
    --         for k = 0, items:size() - 1 do
    --             local item = items:get(k)
    --             if item ~= nil then
    --                 if utils.isActivatedGlowstick(item) then
    --                     print("Found a activated glowstick inside a container!")
    --                     print("Object index: " .. i)
    --                     print("Container type: " .. container:getType())
    --                     print("Container index: " .. j)
    --                     registerGlowstickItem(square:getX(), square:getY(), square:getZ(), item, false)


    --                     local serverModData = ServerModData.get()
    --                     local glowstickData = serverModData[item:getID()]
    --                 end
    --             end
    --         end
    --     end
    
    -- end


end

local function isSquareLoaded(x,y,z)
    return getSquare(x,y,z) ~= nil
end

local function calculateRemainingDelta(item, leaveTime, minutes)

    local totalPastMinute = minutes

    if leaveTime ~= nil then
        totalPastMinute = math.floor((getGameTime():getWorldAgeHours() - leaveTime) * 60)
    end

    local itemUseDelta = item:getUseDelta()
    local totalDepletion = itemUseDelta * ( (TorhFixAZ_Manager.TickCountPerMinute / item:getTicksPerEquipUse()) * totalPastMinute)

    return item:getUsedDelta() - totalDepletion
    
end

TorhFixAZ_Manager.onOneMinute = function ()
    
    local glowstickData = ServerModData.get()
    if glowstickData == nil then
        return
    end

    if glowstickData.activeGlowsticks == nil then
        return
    end

    local subtractions = {}
    local clientUpdateGlowsticks = {}

    for index, glowstickID in ipairs(glowstickData.activeGlowsticks) do
        
        local glowstick = glowstickData[glowstickID]

        if glowstick ~= nil then

            if isSquareLoaded(glowstick.x,glowstick.y,glowstick.z) then

                local item = glowstick.item
                local remainingDelta = calculateRemainingDelta(item,glowstick.leaveTime,1)
                item:setUsedDelta(remainingDelta)

                if remainingDelta <= TorhFixAZ_Manager.Epsilon then

                    local worldItem = item:getWorldItem()
                    if worldItem ~= nil then
                        removeWorldActiveGlowstick(glowstick.x,glowstick.y,glowstick.z,worldItem)
                    end

                    table.insert(subtractions,index)

                else
                    
                    glowstick.lastCalDelta = remainingDelta

                    local glowstickData = {
                        x = glowstick.x,
                        y = glowstick.y,
                        z = glowstick.z,
                        delta = remainingDelta
                    }

                    clientUpdateGlowsticks[glowstickID] = glowstickData

                end

            else
    
                -- Add the time that the glowstick was left unseen from server
                glowstick.leaveTime = getGameTime():getWorldAgeHours()

                table.insert(subtractions,index)
                -- print("Glowstick has been left unseen.")
                
            end

        else

            table.insert(subtractions,index)

        end

    end

    if #clientUpdateGlowsticks > 0 then
        sendServerCommand(TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.updateGlowstickDelta, clientUpdateGlowsticks)
    end

    -- Apply subtractions (backward to avoid index shifts)
    for i = #subtractions, 1, -1 do
        table.remove(glowstickData.activeGlowsticks,subtractions[i])
    end

end

Events.EveryOneMinute.Add(TorhFixAZ_Manager.onOneMinute)
Events.LoadGridsquare.Add(TorhFixAZ_Manager.onLoadGridsquare)

return TorhFixAZ_Manager