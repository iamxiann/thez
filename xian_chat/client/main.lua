local chatOpen = false
local nuiReady = false
local queuedMessages = {}
local commandRefreshGeneration = 0
local Corex

local function getCore()
    if Corex then return Corex end

    local ok, core = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)

    if ok and core and core.Functions then
        Corex = core
    end

    return Corex
end

local function notify(message, notificationType)
    local core = getCore()
    if core and core.Functions and core.Functions.Notify then
        core.Functions.Notify(message, notificationType or 'info', 4000)
        return
    end

    TriggerEvent('corex:notify', message, notificationType or 'info', 4000)
end

local function send(action, data)
    if not nuiReady and action == 'message' then
        queuedMessages[#queuedMessages + 1] = data
        return
    end

    SendNUIMessage({ action = action, data = data })
end

local function openChat()
    if chatOpen or IsPauseMenuActive() or IsScreenFadedOut() then return end

    chatOpen = true
    SetNuiFocus(true, true)
    send('open', {})
end

local function refreshCommandSuggestions()
    if not nuiReady or not GetRegisteredCommands then return end

    local registeredCommands = GetRegisteredCommands()
    local suggestions = {}

    for i = 1, #registeredCommands do
        local commandName = registeredCommands[i].name

        if IsAceAllowed(('command.%s'):format(commandName)) then
            suggestions[#suggestions + 1] = {
                name = '/' .. commandName,
                help = ''
            }
        end
    end

    send('suggestions', suggestions)
end

local function scheduleCommandRefresh()
    commandRefreshGeneration += 1
    local generation = commandRefreshGeneration

    SetTimeout(500, function()
        if generation == commandRefreshGeneration then
            refreshCommandSuggestions()
        end
    end)
end

RegisterCommand('xian_chat_open', openChat, false)
RegisterKeyMapping('xian_chat_open', 'Open chat', 'keyboard', 't')

RegisterNUICallback('ready', function(_, cb)
    nuiReady = true
    send('init', {
        fadeDelay = 10000,
        maxMessages = 60,
        playerName = GetPlayerName(PlayerId()),
    })

    for i = 1, #queuedMessages do
        send('message', queuedMessages[i])
    end
    queuedMessages = {}

    refreshCommandSuggestions()
    TriggerServerEvent('chat:init')
    TriggerEvent('chat:addSuggestion', '/chatjob', 'Buka pengaturan warna teks dan outline chat job (boss)')
    cb('ok')
end)

AddEventHandler('onClientResourceStart', function()
    scheduleCommandRefresh()
end)

AddEventHandler('onClientResourceStop', function()
    scheduleCommandRefresh()
end)

RegisterNUICallback('submit', function(data, cb)
    chatOpen = false
    SetNuiFocus(false, false)

    local message = data and data.message
    if type(message) == 'string' and message ~= '' then
        if message:sub(1, 1) == '/' then
            ExecuteCommand(message:sub(2))
        elseif not Config.CommandsOnly then
            TriggerServerEvent('_chat:messageEntered', GetPlayerName(PlayerId()), { 255, 255, 255 }, message, '_global')
        else
            notify('Gunakan /command untuk mengirim pesan.', 'error')
        end
    end

    cb('ok')
end)

RegisterNUICallback('close', function(_, cb)
    chatOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

local function addMessage(message)
    if type(message) == 'string' then message = { args = { message } } end
    send('message', message)
end

exports('addMessage', addMessage)
RegisterNetEvent('chat:addMessage', addMessage)

RegisterNetEvent('chatMessage', function(author, color, text)
    addMessage({ color = color, multiline = true, args = { author, text } })
end)

RegisterNetEvent('chat:addSuggestion', function(name, help, params)
    send('suggestion', { name = name, help = help, params = params })
end)

RegisterNetEvent('chat:addSuggestions', function(suggestions)
    send('suggestions', suggestions)
end)

RegisterNetEvent('chat:removeSuggestion', function(name)
    send('removeSuggestion', { name = name })
end)

RegisterNetEvent('chat:addTemplate', function(id, html)
    send('template', { id = id, html = html })
end)

RegisterNetEvent('chat:clear', function()
    send('clear', {})
end)

RegisterNetEvent('chat:addMode', function(mode)
    send('mode', mode)
end)

RegisterNetEvent('chat:removeMode', function(mode)
    send('removeMode', mode)
end)

CreateThread(function()
    while true do
        if chatOpen then
            DisableControlAction(0, 1, true)
            DisableControlAction(0, 2, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 200, true)
            Wait(0)
        else
            Wait(250)
        end
    end
end)

AddEventHandler('onClientResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        SetNuiFocus(false, false)
    end
end)
