require "Light/PlayerPointLight_Network"
PlayerPointLight = PlayerPointLight or {}
PlayerPointLight.modDataName = "PlayerPointLight"


--#region System

local localGetSquare = getSquare

local function deferredPointLights(playerID,pointLights)
    
    local player = getPlayer()
    local playerModData = player:getModData()[PlayerPointLight.modDataName]

    playerModData.deferredLights = playerModData.deferredLights or {}

    playerModData.deferredLights[playerID] = pointLights

    for _, pointLight in pairs(pointLights) do
        pointLight:destroy()
    end

end

local function removePointLights(pointLights)
    
    -- handle player disconnected
    for _, pointLight in ipairs(pointLights) do
        pointLight:_remove()
    end

end

local function activateDeferredPointLights(player)

    local playerModData = player:getModData()[PlayerPointLight.modDataName]

    local deferredLights = playerModData.deferredLights
    if deferredLights == nil then return end

    for playerID, pointLights in pairs(deferredLights) do
        
        local targetPlayer = getPlayerByOnlineID(playerID)
        if targetPlayer == nil then
            removePointLights(pointLights)
        else
            
            local playerX = targetPlayer:getX()
            local playerY = targetPlayer:getY()
            local playerZ = targetPlayer:getZ()

            -- check if this player is loaded in this client or not
            local square = localGetSquare(playerX, playerY, playerZ)
            if square ~= nil then
                
                -- reverse loop to avoid index remapping
                for index, pointLight in pairs(pointLights) do 
                    if playerModData[playerID] == nil or playerModData[playerID][index] == nil then
                        deferredLights[playerID][index] = nil
                    else
                        pointLight:update(false)

                        -- Add the point light to the active point lights
                        playerModData.activeLights = playerModData.activeLights or {}
                        playerModData.activeLights[playerID] = playerModData.activeLights[playerID] or {}
                        playerModData.activeLights[playerID][index] = pointLight
                    end
                end

                deferredLights[playerID] = nil

            end

        end

    end

end

local function updateActivePointLights(player)
    
    local playerModData = player:getModData()[PlayerPointLight.modDataName]

    local activeLights = playerModData.activeLights
    if activeLights == nil then return end

    for playerID, pointLights in pairs(activeLights) do

        local targetPlayer = getPlayerByOnlineID(playerID)
        if targetPlayer == nil then
            removePointLights(pointLights)
        else

            local playerX = targetPlayer:getX()
            local playerY = targetPlayer:getY()
            local playerZ = targetPlayer:getZ()

            -- check if this player is loaded in this client or not

            local square = localGetSquare(playerX, playerY, playerZ)
            if square ~= nil then
                
                -- reverse loop to avoid index remapping
                for index, pointLight in pairs(pointLights) do
                    if playerModData[playerID] == nil or playerModData[playerID][index] == nil then
                        activeLights[playerID][index] = nil
                    else
                        if pointLight:isActive() then
                            pointLight:update(targetPlayer:isPlayerMoving())
                        else
                            pointLight:destroy()
                        end
                    end
                end

            else

                deferredPointLights(playerID,pointLights)
                activeLights[playerID] = nil

            end

        end

    end

end

local function onPlayerUpdate(player)
    
    if player == nil then return end

    local playerModData = player:getModData()[PlayerPointLight.modDataName]
    if playerModData == nil then return end

    activateDeferredPointLights(player)
    updateActivePointLights(player)

end


local function onFadeToWorld()
    
    -- request all currently active point lights
    local player = getPlayer()
    sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.requestAllPointLights, {})

    Events.OnPlayerUpdate.Add(onPlayerUpdate)
    Events.EveryOneMinute.Remove(onFadeToWorld)

end

local function onPlayerSpawn(index)

    if index == 0 then

        local character = getSpecificPlayer(index)
        character:getModData()[PlayerPointLight.modDataName] = nil
        -- create a static light for bound inspection
        PlayerPointLight.staticLight = IsoLightSource.new(0, 0, 0, 1, 1, 1, 1, -1)

        Events.EveryOneMinute.Add(onFadeToWorld)
    end

end

Events.OnCreatePlayer.Add(onPlayerSpawn)

--#endregion



local function initLight(pointLight, isActive,addToCell)
    -- Get the player by their online ID
    local player = getPlayerByOnlineID(pointLight.playerID)
    if player == nil then
        return
    end

    -- Get the player's coordinates
    local x, y, z = player:getX(), player:getY(), player:getZ()

    -- Create a new light source and set it as active
    local lightSource = IsoLightSource.new(x, y, z, pointLight.r, pointLight.g, pointLight.b, pointLight.radius, -1)

    lightSource:setActive(isActive)

    if addToCell then
        local targetCell = getCell()
        targetCell:addLamppost(lightSource)
    end


    return lightSource
end

local function initModData(pointLight, player)

    -- Ensure the modData table exists for the player
    local modDataName = PlayerPointLight.modDataName
    local playerModData = player:getModData()
    playerModData[modDataName] = playerModData[modDataName] or {}

    -- Ensure the player's online ID exists in the modData table
    local playerOnlineID = pointLight.playerID
    playerModData[modDataName][playerOnlineID] = playerModData[modDataName][playerOnlineID] or {}


    -- Add the point light to the player's modData table
    pointLight.index = #playerModData[modDataName][playerOnlineID] + 1
    table.insert(playerModData[modDataName][playerOnlineID], pointLight)


    -- Add the point light to the deferredLights table that needs to be activated
    playerModData[modDataName].deferredLights = playerModData[modDataName].deferredLights or {}
    local deferredLights = playerModData[modDataName].deferredLights
    deferredLights[playerOnlineID] = deferredLights[playerOnlineID] or {}
    deferredLights[playerOnlineID][pointLight.index] = pointLight
end


function PlayerPointLight:new(playerID,r,g,b,radius)

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.playerID = playerID
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.lightSource = nil
    o.isActiveCallback = nil
    o.currentActive = false
    o.isRemoteActive = false
    o.index = 0

    initModData(o,getPlayer()) -- ModData will only save at the player that is currently playing

    return o

end

function PlayerPointLight:registerIsActiveCallback(isActive)
    self.isActiveCallback = isActive
end

---This function removes the point light from the game world and the local ModData.
-- DON'T CALL THIS FUNCTION DIRECTLY, USE PlayerPointLight.removePointLight(pointLight) INSTEAD
function PlayerPointLight:_remove()
    self:destroy()

    -- remove point light from local ModData
    local player = getPlayer()

    -- garuntee to be not nil
    local modData = player:getModData()[PlayerPointLight.modDataName]
    modData[self.playerID][self.index] = nil
end

function PlayerPointLight:destroy()

    if self.lightSource ~= nil then
        local targetCell = getCell()
        targetCell:removeLamppost(self.lightSource)
        self.lightSource = nil
    end

end

function PlayerPointLight:update(isMoving)

    if isMoving then
        self:destroy()
        self.lightSource = initLight(self,true,true)
    else
        if self.lightSource == nil then
            self.lightSource = initLight(self,true,true)
        end
    end
end

---This function sets the active state of the point light.
-- and sends a command to the server to set the active state of the point light in the global ModData.
---@param value boolean
function PlayerPointLight:setActive(value)

    local player = getPlayer()
    local playerID = player:getOnlineID()

    if self.playerID ~= playerID then
        self.isRemoteActive = value
        return
    end

    self.currentActive = value

    sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.setRemoteActive,
    {
        playerID = self.playerID,
        index = self.index,
        value = value
    })

end

function PlayerPointLight:isActive()

    local player = getPlayer()

    if self.playerID ~= player:getOnlineID() then
        return self.isRemoteActive
    end

    -- if this is client player then we use the callback
    if self.isActiveCallback ~= nil then
        local currentActive = self.isActiveCallback(self)
        if currentActive ~= self.currentActive then
            self:setActive(currentActive)
        end
    end

    return self.currentActive
end

---This function tests whether the current point light is within the bounds of the client player.
-- It checks if the light source exists and if the player is within the light source's bounds.
-- Returns true if the point light is in bounds, false otherwise.
---@param pointLight table
---@return boolean
PlayerPointLight.isInBounds = function (pointLight)
    
    if PlayerPointLight.staticLight ~= nil then

        local light = PlayerPointLight.staticLight

        local parent = getPlayerByOnlineID(pointLight.playerID)

        if parent == nil then
            return false
        end

        local x = parent:getX()
        local y = parent:getY()
        local z = parent:getZ()

        light:setX(x)
        light:setY(y)
        light:setZ(z)

        return light:isInBounds()

    end

    return false

end

---This function creates a new point light with the specified color and radius.
---@param r number
---@param g number
---@param b number
---@param radius number
---@return table
PlayerPointLight.create = function (r,g,b,radius)

    -- Get the current player
    local player = getPlayer()
    local playerID = player:getOnlineID()

    local pointLight = PlayerPointLight:new(playerID,r,g,b,radius)

    -- Prepare the arguments for the client command
    local args = {}
    args.playerID = playerID
    args.r = r
    args.g = g
    args.b = b
    args.radius = radius
    args.index = pointLight.index

    sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.createRemotePointLight, args)

    return pointLight
end

---This function removes the specified point light from the game world and the local ModData.
-- and sends a command to the server to remove the point light from the global ModData.
---@param pointLight table
PlayerPointLight.remove = function (pointLight)

    local player = getPlayer()

    if pointLight == nil then
        return
    end

    pointLight:_remove()

    -- if the point light is not the client player's point light, send a command to the server to remove the point light
    if pointLight.playerID == player:getOnlineID() then
        sendClientCommand(player, PlayerPointLight_Network.Module, PlayerPointLight_Network.Commands.removeRemotePointLight,
        {
            playerID = pointLight.playerID,
            index = pointLight.index
        })
    end
end

return PlayerPointLight