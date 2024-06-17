
require "Light/StaticPointLight_Network"

StaticPointLight = StaticPointLight or {}
StaticPointLight.modDataName = "StaticPointLight"

--#region System

local localGetSquare = getSquare

local function activateDeferredPointLights(player)

    local playerModData = player:getModData()[StaticPointLight.modDataName]
    local deferredLights = playerModData.deferredLights

    if deferredLights == nil then return end

    for uniqueID,pointlight in pairs(deferredLights) do
        local square = localGetSquare(pointlight.x, pointlight.y, pointlight.z)
        if playerModData[uniqueID] == nil then
            deferredLights[uniqueID] = nil
        elseif square ~= nil then

            pointlight:setActive(true)
            deferredLights[uniqueID] = nil

            -- Add this light to the active list
            playerModData.activeLights = playerModData.activeLights or {}
            playerModData.activeLights[uniqueID] = pointlight
        end
    end

end

local function updateActiveLights(player)
    
    local playerModData = player:getModData()[StaticPointLight.modDataName]
    local activeLights = playerModData.activeLights

    if activeLights == nil then return end

    for uniqueID,pointlight in pairs(activeLights) do
        local square = localGetSquare(pointlight.x, pointlight.y, pointlight.z)
        if playerModData[uniqueID] == nil then
            activeLights[uniqueID] = nil
        elseif square == nil then

            pointlight:destroy()
            activeLights[uniqueID] = nil

            -- Add this light to the deferred list
            playerModData.deferredLights = playerModData.deferredLights or {}
            playerModData.deferredLights[uniqueID] = pointlight
        end

    end

end

local function onPlayerUpdate(player)

    if player == nil then return end

    local playerModData = player:getModData()[StaticPointLight.modDataName]

    if playerModData == nil then return end

    activateDeferredPointLights(player)
    updateActiveLights(player)
end

local function onFadeToWorld()

    local player = getPlayer()
    sendClientCommand(player, StaticPointLight_Network.Module, StaticPointLight_Network.Commands.requestAll , {})

    Events.OnPlayerUpdate.Add(onPlayerUpdate)
    Events.EveryOneMinute.Remove(onFadeToWorld)

end

local function onPlayerSpawn(index)

    if index == 0 then

        -- always reset the mod data when player spawns
        local character = getSpecificPlayer(index)
        character:getModData()[StaticPointLight.modDataName] = nil
        Events.EveryOneMinute.Add(onFadeToWorld)

    end

end

Events.OnCreatePlayer.Add(onPlayerSpawn)

--#endregion

--#region Component

local function initLight(pointLight,isActive,addToCell)

    -- Get the light's coordinates
    local x, y, z = pointLight.x, pointLight.y, pointLight.z

    -- Create a new light source and set it as active
    local lightSource = IsoLightSource.new(x, y, z, pointLight.r, pointLight.g, pointLight.b, pointLight.radius, -1)

    lightSource:setActive(isActive)

    if addToCell then
        local targetCell = getCell()
        targetCell:addLamppost(lightSource)
    end


    return lightSource
end

local function initModData(player, pointlight, pointlightID)
    local playerModData = player:getModData()
    playerModData[StaticPointLight.modDataName] = playerModData[StaticPointLight.modDataName] or {}

    if getDebug() then
        print("Initializing static pointlight mod data for player: " .. player:getUsername())
    end

    playerModData[StaticPointLight.modDataName][pointlightID] = pointlight

    -- Add this light to the active list
    local modData = playerModData[StaticPointLight.modDataName]
    modData.activeLights = modData.activeLights or {}
    modData.activeLights[pointlightID] = pointlight
end

function StaticPointLight:destroy()
    
    if self.lightSource ~= nil then
        local targetCell = getCell()
        targetCell:removeLamppost(self.lightSource)
        self.lightSource = nil
    end

end

function StaticPointLight:setActive(value)

    if value then
        if self.lightSource == nil then
            self.lightSource = initLight(self, true, true)
        end
    else
        self:destroy()
    end

end

function StaticPointLight:_remove()
    self:destroy()

    local player = getPlayer()
    local playerModData = player:getModData()[StaticPointLight.modDataName]

    playerModData[self.uniqueID] = nil
end

function StaticPointLight:new(x, y, z, r, g, b , radius, uniqueID)

    local o = {}
    setmetatable(o,self)
    self.__index = self

    o.x = x
    o.y = y
    o.z = z
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.uniqueID = uniqueID

    o.lightSource = initLight(o, true, true)

    initModData(getPlayer(), o, uniqueID)

    return o

end

--#endregion


--#region Client

---When using create, it doesn't really create the light but rather it sends command to the server to create
-- server-wide point light at that location
---@param x number
---@param y number
---@param z number
---@param r number
---@param g number
---@param b number
---@param radius number
StaticPointLight.create = function (x,y,z,r, g, b , radius)
    
    local args = {}
    args.x = x
    args.y = y
    args.z = z
    args.r = r
    args.g = g
    args.b = b
    args.radius = radius

    sendClientCommand(getPlayer(), StaticPointLight_Network.Module, StaticPointLight_Network.Commands.createGlobal, args)

end

StaticPointLight.remove = function (light)

    local args = {}
    args.uniqueID = light.uniqueID

    sendClientCommand(getPlayer(), StaticPointLight_Network.Module, StaticPointLight_Network.Commands.removeGlobal , args)
end

--#endregion

return StaticPointLight


