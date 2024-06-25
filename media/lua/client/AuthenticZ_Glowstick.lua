require "TorchFixAZ_utils"
require "TorchFixAZ_NetworkVariables"

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


local function onFadeToWorld()

	Events.onItemFall.Add(onItemFall)
	Events.onItemRemovedFromSquare.Add(onItemRemovedFromSquare)

	Events.EveryOneMinute.Remove(onFadeToWorld)
end


local function onPlayerSpawn(index)

	if index == 0 then
		Events.EveryOneMinute.Add(onFadeToWorld)
	end

end

Events.OnCreatePlayer.Add(onPlayerSpawn)