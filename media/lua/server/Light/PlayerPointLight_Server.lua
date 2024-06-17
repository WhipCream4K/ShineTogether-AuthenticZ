require "Light/PlayerPointLight"
local Network = require "Light/PlayerPointLight_Network"

if isClient() then return end


--#region Server ModData

local function getServerModData()
    return ModData.get("PlayerPointLight")
end

local function onGlobalModDataLoad(isNewGame)
    local serverModData = ModData.getOrCreate("PlayerPointLight")
    serverModData = nil
end

Events.OnInitGlobalModData.Add(onGlobalModDataLoad)

--#endregion


local ServerPointLight = {}

-- Struct for server-side point lights
function ServerPointLight:new( playerID, r, g, b, radius )
    local o = {}
    setmetatable(o, self)
    self.__index = self

    o.playerID = playerID
    o.r = r
    o.g = g
    o.b = b
    o.radius = radius
    o.isActive = false

    return o
end

PlayerPointLight_Server = {}
PlayerPointLight_Server[Network.Module] = {}
local ServerOps = PlayerPointLight_Server[Network.Module]

ServerOps[Network.Commands.createRemotePointLight] = function (player,args)

    local playerID = args.playerID
    local r = args.r
    local g = args.g
    local b = args.b
    local radius = args.radius

    local modData = getServerModData()
    modData[playerID] = modData[playerID] or {}
    modData[playerID][args.index] = ServerPointLight:new(playerID, r, g, b, radius)

    -- print("Create remote point light for playerID: " .. playerID)
    -- print("r: " .. r)
    -- print("g: " .. g)
    -- print("b: " .. b)
    -- print("radius: " .. radius)

    sendServerCommand(Network.Module, Network.Commands.createRemotePointLight, args)

end

ServerOps[Network.Commands.removeRemotePointLight] = function (player,args)

    local playerID = args.playerID
    local index = args.index

    local modData = getServerModData()
    if modData[playerID] == nil then return end
    if modData[playerID][index] == nil then return end

    modData[playerID][index] = nil

    -- print("Remove remote point light for playerID: " .. playerID)
    -- print("index: " .. index)

    sendServerCommand(Network.Module, Network.Commands.removeRemotePointLight, args)

end

ServerOps[Network.Commands.setRemoteActive] = function (player,args)

    local playerID = args.playerID
    local index = args.index
    local active = args.value

    local modData = getServerModData()
    if modData[playerID] == nil then return end
    if modData[playerID][index] == nil then return end

    modData[playerID][index].isActive = active

    -- print("Set remote active for playerID: " .. playerID)
    -- print("index: " .. index)
    -- print("value: " .. tostring(active))

    sendServerCommand(Network.Module, Network.Commands.setRemoteActive, args)

end

ServerOps[Network.Commands.requestAllPointLights] = function (player,args)

    local modData = getServerModData()

    -- print("Request all point lights")

    sendServerCommand(player,Network.Module, Network.Commands.receiveAllPointLights, modData)

end


local function onClientCommand(module, command, player, args)
    if PlayerPointLight_Server[module] and PlayerPointLight_Server[module][command] then
        PlayerPointLight_Server[module][command](player, args)
    end
end


local function onServerStepUpdate()
    
    local modData = getServerModData()
    if modData == nil then return end

    for playerID, pointLights in pairs(modData) do
        local player = getPlayerByOnlineID(playerID)
        if player == nil then
            modData[playerID] = nil
            -- print("Player " .. playerID .. " not found, removing point lights")
        end
    end

end

Events.EveryOneMinute.Add(onServerStepUpdate)
Events.OnClientCommand.Add(onClientCommand)

return PlayerPointLight_Server