local menuOpen = false

local function notify(description, notificationType)
    lib.notify({
        title = 'Chat Job',
        description = description,
        type = notificationType,
    })
end

local function closeMenu()
    if not menuOpen then return end
    menuOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeJobSettings' })
end

local function openJobChatSettings()
    if menuOpen then return end

    local settings, errorMessage = lib.callback.await('xian_chat:server:getJobChatSettings', false)
    if not settings then
        notify(errorMessage or 'Pengaturan chat job tidak tersedia.', 'error')
        return
    end

    menuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openJobSettings',
        data = settings,
    })
end

RegisterCommand('chatjob', openJobChatSettings, false)
RegisterNetEvent('xian_chat:client:openJobChatSettings', openJobChatSettings)

RegisterNetEvent('xian_chat:client:updateJobChatStyle', function(style)
    SendNUIMessage({
        action = 'updateJobChatStyle',
        data = style,
    })
end)

RegisterNUICallback('saveJobSettings', function(data, cb)
    if not menuOpen then
        cb({ success = false, message = 'Menu pengaturan tidak sedang terbuka.' })
        return
    end

    local success, message = lib.callback.await('xian_chat:server:saveJobChatSettings', false, data)
    cb({ success = success == true, message = message })

    if success then
        closeMenu()
        notify(message or 'Pengaturan berhasil disimpan.', 'success')
    end
end)

RegisterNUICallback('closeJobSettings', function(_, cb)
    closeMenu()
    cb({ success = true })
end)
