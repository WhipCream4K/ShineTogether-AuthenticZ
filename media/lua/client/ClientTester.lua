
require "TorchFixAZ_utils"

local function getPlayerModData(player)
	local modData = player:getModData()
	modData.AuthenticZ_Glowstick = modData.AuthenticZ_Glowstick or {}
	return modData.AuthenticZ_Glowstick
end

local function onKeyPressed(key)
    
    if key == Keyboard.KEY_F9 then
        
        local player = getPlayer()
        -- local item = player:getPrimaryHandItem()

        -- -- item:setUsedDelta(0.002)
        -- print("Tick per equip use: " .. item:getTicksPerEquipUse())
        -- print("Time multiplier: " .. getGameTime():getMultiplier())
        -- print("Tick: " .. item:getTicks())
        local playerModData = getPlayerModData(player)

        if playerModData.TempGlowstick ~= nil then
            local worldItem = playerModData.TempGlowstick
            
            local floorContainer = ISInventoryPage.GetFloorContainer(0)

            local item = worldItem:getItem()
            item:setUsedDelta(0.002)

            floorContainer:setDrawDirty(true)

            -- local targetSquare = worldItem:getSquare()

            -- targetSquare:setDrawDirty(true)
            -- targetSquare:setHasBeenLooted(true)
        
            -- targetSquare:transmitRemoveItemFromSquare(worldItem)
            -- targetSquare:removeWorldObject(worldItem)

            -- local item = worldItem:getItem()
            -- item:setWorldItem(nil)

            playerModData.TempGlowstick = nil
            print("Temp Glowstick removed.")
        end
        

    end
end

local function onKeyPressed2(key)
    if key == Keyboard.KEY_F9 then

        local player = getPlayer()
        local primaryItem = player:getPrimaryHandItem()

        if TorhFixAZ_utils.isActivatedGlowstick(primaryItem) then
            
            primaryItem:setUsedDelta(0.006)

        end

    end

    if key == Keyboard.KEY_F10 then

        sendClientCommand(getPlayer(), "Glowstick", TorhFixAZ_Network.Commands.testItemDelta, {})
        
        -- local player = getPlayer()
        -- local primaryItem = player:getPrimaryHandItem()
            
        -- print("Glowstick Full type: " .. primaryItem:getFullType())

    end
end

local playerTick = 0

local function OnPlayerUpdate(player)
    
    playerTick = playerTick + getGameTime():getMultiplier()

end

local function EveryOneMinute()
    
    -- local player = getPlayer()
    -- local item = player:getPrimaryHandItem()

    -- if item ~= nil then
    --     print("Item Tick: " .. item:getTicks())
    -- end

    print("Player Tick: " .. playerTick)
    playerTick = 0
    

end

-- Events.OnPlayerUpdate.Add(OnPlayerUpdate)
-- Events.EveryOneMinute.Add(EveryOneMinute)
Events.OnKeyPressed.Add(onKeyPressed2)