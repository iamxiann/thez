local HEAD_BONE_ID = 31086
local bubbles = {}

local function getHeadCoords(ped)
    local bone = GetPedBoneIndex(ped, HEAD_BONE_ID)
    if bone ~= -1 then
        local coords = GetWorldPositionOfEntityBone(ped, bone)
        return vector3(coords.x, coords.y, coords.z + Config.ThreeDText.Height)
    end

    local coords = GetEntityCoords(ped)
    return vector3(coords.x, coords.y, coords.z + 1.2)
end

RegisterNetEvent('xian_chat:client:show3DText', function(serverId, messageType, message, name, duration)
    if type(serverId) ~= 'number' or type(message) ~= 'string' or type(name) ~= 'string' then return end
    if messageType ~= 'me' and messageType ~= 'do' then return end

    bubbles[serverId] = {
        serverId = serverId,
        type = messageType,
        text = message,
        name = name,
        expiresAt = GetGameTimer() + math.min(tonumber(duration) or Config.ThreeDText.Duration, 15000),
    }
end)

CreateThread(function()
    while true do
        if not next(bubbles) then
            Wait(300)
        else
            Wait(0)
            local now = GetGameTimer()
            local localCoords = GetEntityCoords(PlayerPedId())
            local visible = {}

            for serverId, bubble in pairs(bubbles) do
                if now >= bubble.expiresAt then
                    bubbles[serverId] = nil
                else
                    local player = GetPlayerFromServerId(serverId)
                    local ped = player ~= -1 and GetPlayerPed(player) or 0

                    if ped ~= 0 and DoesEntityExist(ped) then
                        local pedCoords = GetEntityCoords(ped)
                        local distance = #(localCoords - pedCoords)

                        if distance <= Config.ThreeDText.DrawDistance then
                            local headCoords = getHeadCoords(ped)
                            local onScreen, screenX, screenY = World3dToScreen2d(headCoords.x, headCoords.y, headCoords.z)

                            if onScreen then
                                local remaining = bubble.expiresAt - now
                                visible[#visible + 1] = {
                                    serverId = serverId,
                                    type = bubble.type,
                                    text = bubble.text,
                                    name = bubble.name,
                                    x = screenX,
                                    y = screenY,
                                    scale = math.max(0.5, math.min(1.15, 8.0 / math.max(distance, 1.0))),
                                    opacity = math.min(1.0, remaining / Config.ThreeDText.FadeDuration),
                                }
                            end
                        end
                    end
                end
            end

            SendNUIMessage({
                action = 'updateRoleplayBubbles',
                data = visible,
            })
        end
    end
end)

RegisterCommand('clear', function()
    TriggerEvent('chat:clear')
end, false)
