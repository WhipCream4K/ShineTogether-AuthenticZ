
TorhFixAZ_utils = {}

local workingGlowSticksData = {}
workingGlowSticksData["AuthenticGlowstick_Blue_On"] = { 0.0, 0.0, 1.0 }
workingGlowSticksData["AuthenticGlowstick_Red_On"] = { 1.0, 0.0, 0.0 }
workingGlowSticksData["AuthenticGlowstick_Green_On"] = { 0.0, 1.0, 0.0 }
workingGlowSticksData["AuthenticGlowstick_Purple_On"] = { 1.0, 0.0, 1.0 }
workingGlowSticksData["AuthenticGlowstick_Yellow_On"] = { 1.0, 1.0, 0.0 }
workingGlowSticksData["AuthenticGlowstick_Orange_On"] = { 1.0, 0.50, 0.0 }
workingGlowSticksData["AuthenticGlowstick_Pink_On"] = { 1.0, 0.0, 0.25 }
workingGlowSticksData["AuthenticGlowstick_White_On"] = { 0.0, 0.0, 0.0 }

TorhFixAZ_utils.getGlowstickColor = function(item)

    local outColor = {}
    local glowstickColor = workingGlowSticksData[item:getType()]

    if glowstickColor == nil then
        return {
            r = 1.0,
            g = 1.0,
            b = 1.0
        }
    end

    outColor.r = glowstickColor[1]
    outColor.g = glowstickColor[2]
    outColor.b = glowstickColor[3]

    return outColor
end

TorhFixAZ_utils.isActivatedGlowstick = function (item)
    return workingGlowSticksData[item:getType()] ~= nil
end

TorhFixAZ_utils.getGlowRadius = function()
    return 4
end

return TorhFixAZ_utils