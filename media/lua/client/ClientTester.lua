
require "TorchFixAZ_utils"
require "Hotbar/ISHotbar"

local function onKeyPressed(key)
    
    if key == Keyboard.KEY_F9 then
        -- local player = getPlayer()
        -- local attachedItems = player:getAttachedItems()
        -- for i=0,attachedItems:size()-1 do
        --     local item = attachedItems:getItemByIndex(i)
        --     if TorhFixAZ_utils.isActivatedGlowstick(item) then
        --         local attachedLocation = attachedItems:getLocation(item)
        --         print("Glowstick attached to: " .. attachedLocation)
        --         break
        --     end
        -- end

        -- local zombieList = getCell():getZombieList()
        -- for i=0,zombieList:size()-1 do
        --     local zombie = zombieList:get(i)
        --     local zombieInv = zombie:getInventory()
        --     local glowstick = zombieInv:AddItem("AuthenticGlowstick_Green_On")
        --     zombie:setAttachedItem("Belt Left",glowstick)
        --     local zombieID = zombie:getOnlineID()
        --     print("Zombie ID: " .. zombieID)
        -- end

        -- print("Num active players " .. getNumActivePlayers())
        -- sendClientCommand(getPlayer(), 'PlayerPointLight', 'zombieTester', nil)
        
        local luaFileCount = getLoadedLuaCount()
        for i=0,luaFileCount-1 do
            local fileName = getLoadedLua(i)
            reloadLuaFile(fileName)
        end

        sendClientCommand(getPlayer(), 'PlayerPointLight', 'zombieTester', nil)

    end
end





Events.OnKeyPressed.Add(onKeyPressed)