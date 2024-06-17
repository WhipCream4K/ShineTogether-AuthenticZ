require "Light/StaticPointLight"
local Network = require "Light/StaticPointLight_Network"

if isClient() then return end


StaticPointLight_Server = {}

--#region Server ModData

local function getServerModData()
    return ModData.getOrCreate("StaticPointLight")
end

local function onGlobalModDataLoad(isNewGame)
    local serverModData = ModData.getOrCreate("StaticPointLight")
    serverModData = nil
end

Events.OnInitGlobalModData.Add(onGlobalModDataLoad)

--#endregion

local function getRandomID(modData)
    local uniqueID = string.format("%x", ZombRand(0x1000, 0xFFFF))
    while modData[uniqueID] do
        uniqueID = string.format("%x", ZombRand(0x1000, 0xFFFF))
    end
    return uniqueID
end


local ServerPointLight = {}

function ServerPointLight:new( x, y, z, r, g, b, radius, uniqueID)

    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.x = x
    o.y = y
    o.z = z
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.uniqueID = uniqueID

    return o
    
end

StaticPointLight_Server[Network.Module] = {}
local ServerOps = StaticPointLight_Server[Network.Module]

ServerOps[Network.Commands.createGlobal] = function (player, args)
    if args == nil then return end

    local serverModData = getServerModData()
    local newUniqueID = getRandomID(serverModData)

    local light = ServerPointLight:new(args.x, args.y, args.z, args.r, args.g, args.b, args.radius, newUniqueID)

    serverModData[newUniqueID] = light
    args.uniqueID = newUniqueID

    sendServerCommand(Network.Module, Network.Commands.createGlobal, args)

    return light
end

-- StaticPointLight_Server.StaticPointLight.createGlobal = function (player,args)

--     if args == nil then return end

--     local serverModData = getServerModData()
--     local newUniqueID = getRandomID(serverModData)

--     local light = ServerPointLight:new(args.x, args.y, args.z, args.r, args.g, args.b, args.radius, newUniqueID)

--     serverModData[newUniqueID] = light
--     args.uniqueID = newUniqueID

--     sendServerCommand("StaticPointLight", "createGlobal", args)

--     return light

-- end

ServerOps[Network.Commands.removeGlobal] = function (player, args)
    if args == nil then return end

    local serverModData = getServerModData()
    serverModData[args.uniqueID] = nil

    sendServerCommand(Network.Module, Network.Commands.removeGlobal, args)
end

-- StaticPointLight_Server.StaticPointLight.removeGlobal = function (player,args)

--     if args == nil then return end

--     local serverModData = getServerModData()
--     serverModData[args.uniqueID] = nil
    
--     sendServerCommand("StaticPointLight", "removeGlobal", {uniqueID = args.uniqueID})

-- end

ServerOps[Network.Commands.requestAll] = function (player, args)
    local serverModData = getServerModData()
    if serverModData == nil then return end

    sendServerCommand(player, Network.Module, Network.Commands.receiveAll, serverModData)
end

-- StaticPointLight_Server.StaticPointLight.requestAll = function (player, args)
    
--     local serverModData = getServerModData()
--     if serverModData == nil then return end

--     sendServerCommand(player,"StaticPointLight", "receiveAll", serverModData)

-- end


StaticPointLight = StaticPointLight or {}

---This is for when the player doesn't necessarily call to create the light but rather the server
-- creates the light for the player
---@param x number
---@param y number
---@param z number
---@param r number
---@param g number
---@param b number
---@param radius number
StaticPointLight.createOnServer = function (x, y, z, r, g, b , radius)
    
    local args = {}
    args.x = x
    args.y = y
    args.z = z
    args.r = r
    args.g = g
    args.b = b
    args.radius = radius

    -- return StaticPointLight_Server.StaticPointLight.createGlobal(nil,args)
    return ServerOps[Network.Commands.createGlobal](nil, args)

end

StaticPointLight.removeOnServer = function (light)

    local args = {}
    args.uniqueID = light.uniqueID

    -- StaticPointLight_Server.StaticPointLight.removeGlobal(nil,args)
    ServerOps[Network.Commands.removeGlobal](nil, args)
    
end


local function onClientToServer(module, command, player, args)
    if StaticPointLight_Server[module] and StaticPointLight_Server[module][command] then
        StaticPointLight_Server[module][command](player, args)
    end
end

Events.OnClientCommand.Add(onClientToServer)

return StaticPointLight_Server