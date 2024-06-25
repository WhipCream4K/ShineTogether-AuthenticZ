require "Light/PlayerPointLight"
require "TorchFixAZ_Utils"

GlowstickManager = GlowstickManager or {}

local Manager = GlowstickManager

local function primaryOnItemDepleted(player,item)

    Manager.removeLightByItemID(item:getID())
    Manager.removeActiveGlowstick(item:getID())
    Manager.setHandItem("Primary",nil)

end

local function secondaryOnItemDepleted(player,item)

    Manager.removeLightByItemID(item:getID())
    Manager.removeActiveGlowstick(item:getID())
    Manager.setHandItem("Secondary",nil)

end

local function equipLocation(player,item,location,onItemDepleteCallback)
	
	local handItem = Manager.getHandsItem(location)

	if handItem == nil then

		if item ~= nil and TorhFixAZ_utils.isActivatedGlowstick(item) then

			local itemID = item:getID()
			-- playerModData[location] = item

            Manager.setHandItem(location,item)

			local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)

			local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b,TorhFixAZ_utils.getGlowRadius())
			pointLight:setActive(true)

			-- playerModData.pointLights = playerModData.pointLights or {}
			-- playerModData.pointLights[itemID] = pointLight

            Manager.attachLightToItem(item,pointLight)

			local glowstick =
			{
				onItemDepleted = onItemDepleteCallback,
				item = item
			}

            Manager.addActiveGlowstick(itemID,glowstick)
			-- playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
			-- playerModData.activeGlowsticks[itemID] = glowstick
		end
	else if item == nil and handItem ~= nil then

			-- local item = playerModData[location]
			-- local itemID = item:getID()
			-- local pointLight = playerModData.pointLights[itemID]
			-- PlayerPointLight.remove(pointLight)

            local glowstick = Manager.getActiveGlowstickByID(handItem:getID())
            glowstick.onItemDepleted(player,handItem)
        
			-- playerModData.pointLights = playerModData.pointLights or {}
			-- playerModData.pointLights[itemID] = nil

			-- playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
			-- playerModData.activeGlowsticks[itemID] = nil

			-- playerModData[location] = nil
		end
	end

end

Manager.onEquipPrimary = function (player,item)
    
    if not player:isLocalPlayer() then return end
    equipLocation(player,item,"Primary",primaryOnItemDepleted)
end

Manager.onEquipSecondary = function (player,item)
    
    if not player:isLocalPlayer() then return end
    equipLocation(player,item,"Secondary",secondaryOnItemDepleted)

end

Manager.onClothingUpdated = function (player)

    local attachedItems = player:getAttachedItems()

	local currentAttachedItems = {}
	for i = 0, attachedItems:size() - 1 do
		local item = attachedItems:getItemByIndex(i)
		local itemID = item:getID()
		if TorhFixAZ_utils.isActivatedGlowstick(item) then
			currentAttachedItems[itemID] = item
		end
	end

	-- local playerModData = getPlayerModData(player)

	-- playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
	-- playerModData.pointLights = playerModData.pointLights or {}
	-- playerModData.attachedItems = playerModData.attachedItems or {}


	-- local pointLights = playerModData.pointLights
	local activeGlowsticks = Manager.getActiveGlowsticks()
	local attachedGlowsticks = Manager.getAttachedGlowsticks()

	for itemID, glowstick in pairs(attachedGlowsticks) do
		if currentAttachedItems[itemID] == nil then
			-- Remove if exists
			glowstick.onItemDepleted(player,glowstick.item)
		end
	end

	for itemID, currentItem in pairs(currentAttachedItems) do
		if activeGlowsticks[itemID] == nil then
			-- Add if not exists
			local glowstickColor = TorhFixAZ_utils.getGlowstickColor(currentItem)

			local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b, TorhFixAZ_utils.getGlowRadius())
			pointLight:setActive(true)
            Manager.attachLightToItem(currentItem,pointLight)

			-- pointLights[itemID] = pointLight


			local glowstick =
			{
				onItemDepleted = function (player,item)

                    local itemID = item:getID()
                    Manager.removeLightByItemID(itemID)
                    Manager.removeActiveGlowstick(itemID)

					-- local itemID = item:getID()
					-- local playerModData = getPlayerModData(player)
					-- local pointLights = playerModData.pointLights
					-- local activeGlowsticks = playerModData.activeGlowsticks
					-- local attachedItems = playerModData.attachedItems

					-- attachedItems[itemID] = nil
					-- activeGlowsticks[itemID] = nil
					
					-- local pointLight = pointLights[itemID]
					-- PlayerPointLight.remove(pointLight)
					-- pointLights[itemID] = nil

				end,
				item = currentItem
			}
	
			-- activeGlowsticks[itemID] = glowstick
            Manager.addActiveGlowstick(itemID,glowstick)
            Manager.addAttachedGlowstick(itemID,glowstick)
		end
	end

end

Manager.onPlayerUpdate = function (player)
    
	-- local playerModData = getPlayerModData(player)
	local activeGlowsticks = Manager.getActiveGlowsticks()

	if activeGlowsticks == nil then return end

	for itemID, glowstick in pairs(activeGlowsticks) do
		if glowstick.item:getUsedDelta() == 0 then
			glowstick.onItemDepleted(player,glowstick.item)
		end
	end

end

Manager.onFadeToWorld = function ()
    
    local player = getPlayer()

    equipLocation(player,player:getPrimaryHandItem(),"Primary",primaryOnItemDepleted)
    equipLocation(player,player:getSecondaryHandItem(),"Secondary",secondaryOnItemDepleted)

    Manager.onClothingUpdated(player)
    
    Events.EveryOneMinute.Remove(Manager.onFadeToWorld)

end

Manager.onPlayerSpawn = function (index)
    
    if index == 0 then
        
        Events.EveryOneMinute.Add(Manager.onFadeToWorld)

    end

end

Manager.onCorpseCreate = function (corpse)
    
    if instanceof(corpse, "IsoDeadBody") then

        local player = getPlayer()
        if player:getOnlineID() == corpse:getOnlineID() then
            
            -- this corpse is the player's corpse

			local deadBodyModData = corpse:getModData()

			local pointLights = Manager.getLights()

			local x = corpse:getX()
			local y = corpse:getY()
			local z = corpse:getZ()

			deadBodyModData.StaticLights = deadBodyModData.StaticLights or {}

            local staticPointLight = require "Light/StaticPointLight"

			-- Register that if player is picking up this glowstick or corpse, the pointLight will be removed
			for itemID, pointLight in pairs(pointLights) do

				
				local light = staticPointLight.create(x,y,z,pointLight.r,pointLight.g,pointLight.b,pointLight.radius)
				light:setActive(true)
				
				deadBodyModData.StaticLights[itemID] = light

                Manager.removeLightByItemID(itemID)

			end

			corpse:transmitModData()

        end

    end

end

Manager.onPlayerDeath = function (player)

    -- TODO: Update when the corpse is created and the light is still attached to the body of the player
    -- update the glowstick and also remove the light if it's depleted

    local lights = Manager.getLights()

    if lights == nil then return end

    for itemID, pointLight in pairs(lights) do
        Manager.removeLightByItemID(itemID)
    end
    
end

Manager.getActiveGlowsticks = function()
    Manager.activeGlowsticks = Manager.activeGlowsticks or {}
    return Manager.activeGlowsticks
end

Manager.getHandsItem = function (location)
    Manager.handsItem = Manager.handsItem or {}
    return Manager.handsItem[location]
end

Manager.setHandItem = function (location,item)
    Manager.handsItem = Manager.handsItem or {}
    Manager.handsItem[location] = item
end

Manager.getLightByItemID = function (itemID)
    Manager.lights = Manager.lights or {}
    local pointLights = Manager.lights
    return pointLights[itemID]
end

Manager.getLights = function ()
    Manager.lights = Manager.lights or {}
    return Manager.lights
end

Manager.removeLightByItemID = function (itemID)
    Manager.lights = Manager.lights or {}
    local pointLights = Manager.lights
    local pointLight = pointLights[itemID]
    if pointLight ~= nil then
        pointLight:remove()
        pointLights[itemID] = nil
    end
end

Manager.attachLightToItem = function (item,pointLight)
    Manager.lights = Manager.lights or {}
    local pointLights = Manager.lights
    pointLights[item:getID()] = pointLight
end

Manager.getAttachedGlowsticks = function ()
    Manager.attachedGlowsticks = Manager.attachedGlowsticks or {}
    return Manager.attachedGlowsticks
end

Manager.getAttachedGlowstickByID = function (itemID)
    Manager.attachedGlowsticks = Manager.attachedGlowsticks or {}
    local attachedGlowsticks = Manager.attachedGlowsticks
    return attachedGlowsticks[itemID]
end

Manager.addAttachedGlowstick = function (itemID,glowstick)
    Manager.attachedGlowsticks = Manager.attachedGlowsticks or {}
    local attachedGlowsticks = Manager.attachedGlowsticks
    attachedGlowsticks[itemID] = glowstick
end

Manager.removeAttachedGlowstick = function (itemID)
    Manager.attachedGlowsticks = Manager.attachedGlowsticks or {}
    local attachedGlowsticks = Manager.attachedGlowsticks
    attachedGlowsticks[itemID] = nil
end

Manager.addActiveGlowstick = function (itemID,glowstick)
    Manager.activeGlowsticks = Manager.activeGlowsticks or {}
    local activeGlowsticks = Manager.activeGlowsticks
    activeGlowsticks[itemID] = glowstick
end

Manager.getActiveGlowstickByID = function (itemID)
    Manager.activeGlowsticks = Manager.activeGlowsticks or {}
    local activeGlowsticks = Manager.activeGlowsticks
    return activeGlowsticks[itemID]
end

Manager.removeActiveGlowstick = function (itemID)
    Manager.activeGlowsticks = Manager.activeGlowsticks or {}
    local activeGlowsticks = Manager.activeGlowsticks
    activeGlowsticks[itemID] = nil

    if Manager.getAttachedGlowstickByID(itemID) ~= nil then
        Manager.removeAttachedGlowstick(itemID)
    end
end

--#region Manager Create Instance

Events.OnEquipPrimary.Add(Manager.onEquipPrimary)
Events.OnEquipSecondary.Add(Manager.onEquipSecondary)
Events.OnClothingUpdated.Add(Manager.onClothingUpdated)
Events.OnPlayerUpdate.Add(Manager.onPlayerUpdate)
Events.OnCreatePlayer.Add(Manager.onPlayerSpawn)
Events.OnPlayerDeath.Add(Manager.onPlayerDeath)

--#endregion

return GlowstickManager