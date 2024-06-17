require "Light/PlayerPointLight"
require "TorchFixAZ_utils"
require "TorchFixAZ_NetworkVariables"

local function getPlayerModData(player)
	local modData = player:getModData()
	modData.AuthenticZ_Glowstick = modData.AuthenticZ_Glowstick or {}
	return modData.AuthenticZ_Glowstick
end

local function glowstickUpdate(player)

	local playerModData = getPlayerModData(player)
	local activeGlowsticks = playerModData.activeGlowsticks

	if activeGlowsticks == nil then return end

	for itemID, glowstick in pairs(activeGlowsticks) do
		if glowstick.item:getUsedDelta() == 0 then
			glowstick.onItemDepleted(player,glowstick.item)
		end
	end
end

local function equipLocation(player,item,location,onItemDepleteCallback)
	
	local playerModData = getPlayerModData(player)

	if playerModData[location] == nil then

		if item ~= nil and TorhFixAZ_utils.isActivatedGlowstick(item) then

			local itemID = item:getID()
			playerModData[location] = item

			local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)

			local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b,TorhFixAZ_utils.getGlowRadius())
			pointLight:setActive(true)

			playerModData.pointLights = playerModData.pointLights or {}
			playerModData.pointLights[itemID] = pointLight

			local glowstick =
			{
				onItemDepleted = onItemDepleteCallback,
				item = item
			}

			playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
			playerModData.activeGlowsticks[itemID] = glowstick
		end
	else if item == nil and playerModData[location] then

			local item = playerModData[location]
			local itemID = item:getID()
			local pointLight = playerModData.pointLights[itemID]
			PlayerPointLight.remove(pointLight)

			playerModData.pointLights = playerModData.pointLights or {}
			playerModData.pointLights[itemID] = nil

			playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
			playerModData.activeGlowsticks[itemID] = nil

			playerModData[location] = nil
		end
	end

end

local function primaryOnItemDepleted(player,item)

	local itemID = item:getID()
	local playerModData = getPlayerModData(player)
	local pointLight = playerModData.pointLights[itemID]

	PlayerPointLight.remove(pointLight)
	playerModData.pointLights[itemID] = nil

	playerModData.activeGlowsticks[itemID] = nil

	playerModData["Primary"] = nil

end

local function secondaryOnItemDepleted(player,item)

	local itemID = item:getID()
	local playerModData = getPlayerModData(player)
	local pointLight = playerModData.pointLights[itemID]

	PlayerPointLight.remove(pointLight)
	playerModData.pointLights[itemID] = nil

	playerModData.activeGlowsticks[itemID] = nil

	playerModData["Secondary"] = nil

end

local function onEquipPrimary(player,item)

	-- if the player is not the local player, return
	if player:getOnlineID() ~= getPlayer():getOnlineID() then return end

	local rightHandItem = player:getPrimaryHandItem()

	if rightHandItem ~= item then return end

	equipLocation(player,item,"Primary",primaryOnItemDepleted)
end

local function onEquipSecondary(player,item)

	-- if the player is not the local player, return
	if player:getOnlineID() ~= getPlayer():getOnlineID() then return end

	local leftHandItem = player:getSecondaryHandItem()

	if item ~= leftHandItem then return end

	equipLocation(player,item,"Secondary",secondaryOnItemDepleted)
end



-- update attached items
local function onClothingUpdated(player)
	
	local attachedItems = player:getAttachedItems()

	local currentAttachedItems = {}
	for i = 0, attachedItems:size() - 1 do
		local item = attachedItems:getItemByIndex(i)
		local itemID = item:getID()
		if TorhFixAZ_utils.isActivatedGlowstick(item) then
			currentAttachedItems[itemID] = item
		end
	end

	local playerModData = getPlayerModData(player)

	playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
	playerModData.pointLights = playerModData.pointLights or {}
	playerModData.attachedItems = playerModData.attachedItems or {}


	local pointLights = playerModData.pointLights
	local activeGlowsticks = playerModData.activeGlowsticks
	local attachedItems = playerModData.attachedItems

	for itemID, glowstick in pairs(attachedItems) do
		if currentAttachedItems[itemID] == nil then
			-- Remove item
			attachedItems[itemID].onItemDepleted(player,attachedItems[itemID].item)
		end
	end

	for itemID, currentItem in pairs(currentAttachedItems) do
		if activeGlowsticks[itemID] == nil then
			-- Add item
			local glowstickColor = TorhFixAZ_utils.getGlowstickColor(currentItem)

			local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b, TorhFixAZ_utils.getGlowRadius())
			pointLight:setActive(true)
			pointLights[itemID] = pointLight


			local glowstick =
			{
				onItemDepleted = function (player,item)

					local itemID = item:getID()
					local playerModData = getPlayerModData(player)
					local pointLights = playerModData.pointLights
					local activeGlowsticks = playerModData.activeGlowsticks
					local attachedItems = playerModData.attachedItems

					attachedItems[itemID] = nil
					activeGlowsticks[itemID] = nil
					
					local pointLight = pointLights[itemID]
					PlayerPointLight.remove(pointLight)
					pointLights[itemID] = nil

				end,
				item = currentItem
			}
	
			activeGlowsticks[itemID] = glowstick
			attachedItems[itemID] = glowstick

		end
	end

end

local function checkGlowstick(player,item,location,onItemDepleteCallback)

	local playerModData = getPlayerModData(player)
	
	if item ~= nil and TorhFixAZ_utils.isActivatedGlowstick(item) then

		local itemID = item:getID()
		local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)
		local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b,TorhFixAZ_utils.getGlowRadius())
		pointLight:setActive(true)

		playerModData.pointLights = playerModData.pointLights or {}
		playerModData.pointLights[itemID] = pointLight

		local glowstick =
		{
			onItemDepleted = onItemDepleteCallback,
			item = item
		}

		playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}
		playerModData.activeGlowsticks[itemID] = glowstick

		playerModData[location] = item
	end

end

local function checkAttached(player)

	local playerModData = getPlayerModData(player)
	local attachedItems = player:getAttachedItems()

	playerModData.activeGlowsticks = playerModData.activeGlowsticks or {}

	for i = 0, attachedItems:size() - 1 do

		local item = attachedItems:getItemByIndex(i)
		local itemID = item:getID()
		if TorhFixAZ_utils.isActivatedGlowstick(item) then

			local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)
			local pointLight = PlayerPointLight.create(glowstickColor.r, glowstickColor.g, glowstickColor.b, TorhFixAZ_utils.getGlowRadius())
			pointLight:setActive(true)

			playerModData.activeGlowsticks[itemID] = {
				item = item,
				onItemDepleted = function (player,item)

					local playerModData = getPlayerModData(player)
					local itemID = item:getID()

					local pointLight = playerModData.pointLights[itemID]
					PlayerPointLight.remove(pointLight)
					playerModData.pointLights[itemID] = nil

					playerModData.activeGlowsticks[itemID] = nil
				end
			}

			playerModData.pointLights = playerModData.pointLights or {}
			playerModData.pointLights[itemID] = pointLight
		end
	end
end

---This function is reserved for the future where I decide to use OnContainerUpdate event
-- That only triggers if there are more than 2 players in the server
---@param worldItem any
local function onItemDropToFloor(worldItem)
	
	local player = getPlayer()
	if player == nil then
		return
	end

	if instanceof(worldItem, "IsoWorldInventoryObject") then

		local square = worldItem:getSquare()

		local worldObjects = square:getWorldObjects()

		print("Item is being dropped to the floor!")

		if worldObjects:contains(worldItem) then

			local item = worldItem:getItem()
			if TorhFixAZ_utils.isActivatedGlowstick(item) then

				print("Activated glowstick is being dropped!")
		
				local square = worldItem:getSquare()
				local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)
		
		
				local args = {}
				args.x = square:getX()
				args.y = square:getY()
				args.z = square:getZ()
				args.r = glowstickColor.r
				args.g = glowstickColor.g
				args.b = glowstickColor.b
				args.radius = TorhFixAZ_utils.getGlowRadius()
				args.itemID = item:getID()
				
				sendClientCommand(player, TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.onGlowstickFall, args)

			end
		end

	end



end

local function onItemFall(item)
	
	local player = getPlayer()
	if player == nil then
		return
	end

	if TorhFixAZ_utils.isActivatedGlowstick(item) then

		local worldItem = item:getWorldItem()
		local square = worldItem:getSquare()
		local glowstickColor = TorhFixAZ_utils.getGlowstickColor(item)

		local args = {}
		args.x = square:getX()
		args.y = square:getY()
		args.z = square:getZ()
		args.r = glowstickColor.r
		args.g = glowstickColor.g
		args.b = glowstickColor.b
		args.radius = TorhFixAZ_utils.getGlowRadius()
		args.itemID = item:getID()

		-- print("Glowstick has fallen. ID: " .. args.itemID)
		
		sendClientCommand(player, TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.onGlowstickFall, args)

	end
end

local function onItemRemovedFromSquare(item)
	
	-- Deactivate the static point light of the glowstick
	local player = getPlayer()
	if player == nil then
		return
	end

	if TorhFixAZ_utils.isActivatedGlowstick(item) then

		local itemContainer = item:getContainer()
		
		if  itemContainer:isInCharacterInventory(player) then

			-- ask server how much delta is left of the glowstick
			sendClientCommand(player, TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.onGlowstickPickup, {itemID = item:getID()})
		end

		sendClientCommand(player, TorhFixAZ_Network.Module, TorhFixAZ_Network.Commands.onGlowstickRemovedFromSquare, {itemID = item:getID()})
	end

end


local function checkSpawnWithGlowsticks(player)
	

	checkGlowstick(player,player:getPrimaryHandItem(),"Primary",primaryOnItemDepleted)
	checkGlowstick(player,player:getSecondaryHandItem(),"Secondary",secondaryOnItemDepleted)

	checkAttached(player)

end

local function onFadeToWorld()
	
	local player = getPlayer()

	-- check if player is currently having a glowstick in equipped
	checkSpawnWithGlowsticks(player)

	Events.OnPlayerUpdate.Add(glowstickUpdate);
	Events.OnClothingUpdated.Add(onClothingUpdated)
	Events.OnEquipPrimary.Add(onEquipPrimary)
	Events.OnEquipSecondary.Add(onEquipSecondary)
	Events.onItemFall.Add(onItemFall)
	Events.onItemRemovedFromSquare.Add(onItemRemovedFromSquare)

	Events.EveryOneMinute.Remove(onFadeToWorld)
end

local function onPlayerSpawn(index)

	if index == 0 then

		local character = getSpecificPlayer(index)
		local modData = character:getModData()
		modData.AuthenticZ_Glowstick = nil
	
		Events.EveryOneMinute.Add(onFadeToWorld)
	end

end


Events.OnCreatePlayer.Add(onPlayerSpawn)