local function getHeadMenuConfig()
    return Config.HeadMenu or {}
end

local function isHeadMenuEnabled()
    return getHeadMenuConfig().Enabled ~= false
end

local function notify(source, success, message)
    TriggerClientEvent("illenium-appearance:client:headMenuNotify", source, success, message)
end

local function isAceAllowed(source, ace)
    return type(ace) == "string" and ace ~= "" and IsPlayerAceAllowed(source, ace)
end

local function isAdmin(source)
    local menuConfig = getHeadMenuConfig()

    if isAceAllowed(source, menuConfig.Ace) then
        return true
    end

    local aces = menuConfig.Aces or Config.HeadMenuAces or Config.Aces or {}
    if type(aces) == "string" then
        return isAceAllowed(source, aces)
    end

    for i = 1, #aces do
        if isAceAllowed(source, aces[i]) then
            return true
        end
    end

    return false
end

local function getIdentifierMap(source)
    local identifiers = {}

    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        identifiers[identifier] = true
    end

    return identifiers
end

local function parseModelKey(modelKey)
    local modelName, overlayKey = tostring(modelKey):match("^([^^]+)%^(.+)$")
    return modelName or tostring(modelKey), overlayKey
end

local function getHeadIdentifiers(headConfig)
    if type(headConfig) ~= "table" then
        return {}
    end

    if type(headConfig.identifiers) == "table" then
        return headConfig.identifiers
    end

    return headConfig
end

local function hasMatchingIdentifier(headConfig, identifiers)
    local allowedIdentifiers = getHeadIdentifiers(headConfig)

    for i = 1, #allowedIdentifiers do
        if identifiers[allowedIdentifiers[i]] then
            return true
        end
    end

    return false
end

local function getHeadLabel(headConfig, headIndex, modelName)
    if type(headConfig) == "table" and type(headConfig.label) == "string" then
        return headConfig.label
    end

    return ("Head %s (%s)"):format(headIndex, modelName)
end

local function findHeadConfig(modelName, headIndex)
    headIndex = tonumber(headIndex)
    if not modelName or not headIndex or type(Config.HeadBlend) ~= "table" then
        return
    end

    for modelKey, modelHeads in pairs(Config.HeadBlend) do
        local configuredModelName = parseModelKey(modelKey)

        if configuredModelName == modelName and type(modelHeads) == "table" then
            return modelHeads[headIndex] or modelHeads[tostring(headIndex)]
        end
    end
end

local function canPlayerUseHead(playerId, modelName, headIndex)
    local headConfig = findHeadConfig(modelName, headIndex)
    if not headConfig then
        return false, "Entry head tidak ditemukan di config."
    end

    if not hasMatchingIdentifier(headConfig, getIdentifierMap(playerId)) then
        return false, "Player ini tidak memiliki identifier untuk head tersebut."
    end

    return true, nil, getHeadLabel(headConfig, headIndex, modelName)
end

local function getAllowedHeadsForPlayer(playerId)
    local identifiers = getIdentifierMap(playerId)
    local heads = {}

    if type(Config.HeadBlend) ~= "table" then
        return heads
    end

    for modelKey, modelHeads in pairs(Config.HeadBlend) do
        local modelName = parseModelKey(modelKey)

        if type(modelHeads) == "table" then
            for headIndex, headConfig in pairs(modelHeads) do
                local numericHeadIndex = tonumber(headIndex)

                if numericHeadIndex and hasMatchingIdentifier(headConfig, identifiers) then
                    heads[#heads + 1] = {
                        label = getHeadLabel(headConfig, numericHeadIndex, modelName),
                        modelName = modelName,
                        index = numericHeadIndex
                    }
                end
            end
        end
    end

    table.sort(heads, function(a, b)
        if a.modelName == b.modelName then
            return a.index < b.index
        end

        return a.modelName < b.modelName
    end)

    return heads
end

RegisterNetEvent("illenium-appearance:server:requestHeadMenu", function(targetId)
    local src = source
    targetId = tonumber(targetId)

    if not isHeadMenuEnabled() then
        notify(src, false, "Head menu sedang dinonaktifkan.")
        return
    end

    if not isAdmin(src) then
        notify(src, false, "Kamu tidak memiliki akses admin.")
        return
    end

    if not targetId or not GetPlayerName(targetId) then
        notify(src, false, "Player ID tidak ditemukan.")
        return
    end

    local heads = getAllowedHeadsForPlayer(targetId)
    if #heads == 0 then
        notify(src, false, "Player ini tidak memiliki identifier untuk head mana pun.")
        return
    end

    TriggerClientEvent("illenium-appearance:client:openHeadMenu", src, targetId, heads)
end)

RegisterNetEvent("illenium-appearance:server:applyHeadBlend", function(targetId, modelName, headIndex)
    local src = source
    targetId = tonumber(targetId)
    headIndex = tonumber(headIndex)

    if not isAdmin(src) then
        notify(src, false, "Kamu tidak memiliki akses admin.")
        return
    end

    if not targetId or not GetPlayerName(targetId) then
        notify(src, false, "Player target sudah disconnect.")
        return
    end

    local allowed, reason, label = canPlayerUseHead(targetId, modelName, headIndex)
    if not allowed then
        notify(src, false, reason)
        return
    end

    TriggerClientEvent(
        "illenium-appearance:client:applyHeadBlend",
        targetId,
        headIndex,
        modelName,
        label,
        getHeadMenuConfig().SaveOnApply == true
    )

    notify(src, true, ("Head berhasil diapply ke Player %s."):format(targetId))
end)

_G.IlleniumAppearanceCanSaveHead = function(playerId, appearance)
    if type(appearance) ~= "table" or type(appearance.headBlend) ~= "table" then
        return true
    end

    local modelName = appearance.model
    if type(modelName) ~= "string" then
        return true
    end

    for _, key in ipairs({ "shapeFirst", "shapeSecond", "shapeThird" }) do
        local headIndex = tonumber(appearance.headBlend[key])

        if headIndex and headIndex > 45 then
            local allowed = canPlayerUseHead(playerId, modelName, headIndex)
            if not allowed then
                return false
            end
        end
    end

    return true
end
