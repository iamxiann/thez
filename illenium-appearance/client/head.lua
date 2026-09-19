local headMenuId = "illenium_appearance_head_menu"

local function getHeadMenuConfig()
    return Config.HeadMenu or {}
end

local function getHeadMenuCommand()
    return getHeadMenuConfig().Command or "headmenu"
end

local function notify(notifyType, description)
    lib.notify({
        title = "Head Menu",
        description = description,
        type = notifyType,
        position = Config.NotifyOptions.position
    })
end

local function requestTargetId()
    local response = lib.inputDialog("Head Menu", {
        {
            type = "number",
            label = "Player ID",
            required = true,
            min = 1
        }
    })

    return response and tonumber(response[1])
end

local function waitForHeadBlend(ped)
    local timeout = GetGameTimer() + 1000

    while not HasPedHeadBlendFinished(ped) and GetGameTimer() < timeout do
        Wait(0)
    end
end

RegisterNetEvent("illenium-appearance:client:openHeadMenu", function(targetId, headList)
    if not headList or #headList == 0 then
        notify("error", "Player ini tidak memiliki head yang terdaftar di config.")
        return
    end

    local options = {}
    for i = 1, #headList do
        local head = headList[i]

        options[#options + 1] = {
            title = head.label,
            description = ("Model: %s | Head: %s"):format(head.modelName, head.index),
            onSelect = function()
                TriggerServerEvent(
                    "illenium-appearance:server:applyHeadBlend",
                    targetId,
                    head.modelName,
                    head.index
                )
            end
        }
    end

    lib.registerContext({
        id = headMenuId,
        title = ("Head Menu - Player %s"):format(targetId),
        options = options
    })

    lib.showContext(headMenuId)
end)

RegisterNetEvent("illenium-appearance:client:headMenuNotify", function(success, message)
    notify(success and "success" or "error", message)
end)

RegisterCommand(getHeadMenuCommand(), function(_, args)
    local targetId = tonumber(args[1])

    if not targetId then
        targetId = requestTargetId()
    end

    if not targetId then
        notify("error", ("Gunakan: /%s [playerID]"):format(getHeadMenuCommand()))
        return
    end

    TriggerServerEvent("illenium-appearance:server:requestHeadMenu", targetId)
end, false)

RegisterNetEvent("illenium-appearance:client:applyHeadBlend", function(headIndex, modelName, label, saveOnApply)
    headIndex = tonumber(headIndex)
    if not headIndex then return end

    local ped = cache.ped
    if not client.isPedFreemodeModel(ped) then
        notify("error", "Addon head hanya bisa dipakai untuk freemode ped.")
        return
    end

    if modelName and GetEntityModel(ped) ~= joaat(modelName) then
        notify("error", ("Head ini hanya untuk model %s."):format(modelName))
        return
    end

    local currentBlend = exports["illenium-appearance"]:getPedHeadBlend(ped) or {}

    SetPedHeadBlendData(
        ped,
        headIndex,
        headIndex,
        0,
        currentBlend.skinFirst or 0,
        currentBlend.skinSecond or currentBlend.skinFirst or 0,
        currentBlend.skinThird or 0,
        currentBlend.shapeMix or 0.0,
        currentBlend.skinMix or 0.0,
        0.0,
        false
    )
    waitForHeadBlend(ped)

    if saveOnApply then
        local appearance = exports["illenium-appearance"]:getPedAppearance(ped)
        TriggerServerEvent("illenium-appearance:server:saveAppearance", appearance)
    end

    notify("success", ("%s berhasil dipasang."):format(label or ("Head " .. headIndex)))
end)
