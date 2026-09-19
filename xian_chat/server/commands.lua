local chatDisabled = Config.DisableGlobalChat or false

local function getPlayer(src)
    return exports['corex-core']:GetPlayer(src)
end

local function notify(src, message, notificationType)
    TriggerClientEvent('corex:notify', src, message, notificationType or 'info', 4000)
end

local function trim(value)
    return (value or ''):match('^%s*(.-)%s*$')
end

local function getMessage(args, rawCommand, command)
    if type(rawCommand) == 'string' and rawCommand ~= '' then
        local rawName, message = rawCommand:match('^%s*/?([^%s]+)%s*(.*)$')
        if rawName and rawName:lower() == command:lower() then
            return trim(message)
        end
    end

    return trim(args and args.text)
end

local function getCharacterName(src)
    local player = getPlayer(src)
    if player and type(player.name) == 'string' and player.name ~= '' then
        return player.name
    end

    local playerData = player and player.PlayerData
    local charinfo = playerData and playerData.charinfo

    if charinfo then
        local firstName = charinfo.firstname or charinfo.firstName
        local lastName = charinfo.lastname or charinfo.lastName
        local fullName = trim(('%s %s'):format(firstName or '', lastName or ''))

        if fullName ~= '' then
            return fullName
        end
    end

    return GetPlayerName(src) or 'Unknown'
end

local function hasAdminPermission(src)
    for _, group in ipairs(Config.AdminGroups or { 'god', 'admin' }) do
        if IsPlayerAceAllowed(tostring(src), group) then
            return true
        end
    end

    return false
end

local function hasJobPermission(src, cfg)
    if cfg.Permission == 'user' then return true end

    if cfg.Permission == 'admin' then
        return hasAdminPermission(src)
    end

    if cfg.Permission == 'job' then
        local player = getPlayer(src)
        if not player then return false end
        local playerData = player.PlayerData or player
        local job = playerData.job
        if type(job) ~= 'table' or type(job.name) ~= 'string' then return false end
        local playerJob = job.name
        if not cfg.AllowedJobs then return false end
        for _, job in ipairs(cfg.AllowedJobs) do
            if playerJob == job then return true end
        end
        return false
    end

    return false
end

-- Global and job-restricted messages share the theme's message card markup.

local function sendGlobalOOC(src, message)
    local name = getCharacterName(src)
    exports.xian_chat:addMessage(-1, {
        template = '<p class="message-wrapper role-message" style="--role-color: #c9ccd3"><span class="author role-label">GLOBAL OOC</span><span>{0}</span></p>',
        args = { name .. ': ' .. message }
    })
end

local function sendGlobalAdminMessage(src, message)
    local name = getCharacterName(src)
    local chatMessage = {
        template = '<p class="message-wrapper role-message" style="--role-color: rgb(252, 165, 165)"><span class="author role-label">ADMIN</span><span>{0}</span></p>',
        args = { name .. ': ' .. message }
    }

    for _, player in ipairs(GetPlayers()) do
        local target = tonumber(player)
        if target and hasAdminPermission(target) then
            exports.xian_chat:addMessage(target, chatMessage)
        end
    end
end

local function sendGlobalJobMessage(src, message, jobName)
    local name = getCharacterName(src)
    local style = exports.xian_chat:GetJobChatStyle(jobName)
    if not style then return end

    exports.xian_chat:addMessage(-1, {
        template = string.format('<p class="message-wrapper role-message job-message" data-job="%s" style="--role-color: %s; --job-outline: %s"><span class="job-message-header"><span class="author job-message-author">{0}</span><span class="job-message-badge">%s</span></span><span class="job-message-body">{1}</span></p>', jobName, style.textColor, style.outlineColor, style.label),
        args = { name, message }
    })
end

local function sendGlobalGOV(src, message) sendGlobalJobMessage(src, message, 'gov') end
local function sendGlobalEMS(src, message) sendGlobalJobMessage(src, message, 'ambulance') end
local function sendGlobalPOL(src, message) sendGlobalJobMessage(src, message, 'police') end
local function sendGlobalMEC(src, message) sendGlobalJobMessage(src, message, 'mechanic') end
local function sendGlobalREST(src, message) sendGlobalJobMessage(src, message, 'resto') end
local function sendGlobalNC(src, message) sendGlobalJobMessage(src, message, 'nightclub') end

local lastRoleplayMessage = {}

local function send3DText(src, messageType, message)
    if src < 1 then return end

    local now = GetGameTimer()
    if now - (lastRoleplayMessage[src] or 0) < Config.ThreeDText.Cooldown then return end
    lastRoleplayMessage[src] = now

    local sourcePed = GetPlayerPed(src)
    if sourcePed == 0 then return end

    message = message:gsub('[%c]', ' '):sub(1, Config.ThreeDText.MaxLength)
    local sourceCoords = GetEntityCoords(sourcePed)
    local sourceBucket = GetPlayerRoutingBucket(src)
    local characterName = getCharacterName(src)

    for _, playerId in ipairs(GetPlayers()) do
        local target = tonumber(playerId)
        if target and GetPlayerRoutingBucket(target) == sourceBucket then
            local targetPed = GetPlayerPed(target)
            if targetPed ~= 0 then
                local targetCoords = GetEntityCoords(targetPed)
                if #(sourceCoords - targetCoords) <= Config.ThreeDText.SyncDistance then
                    TriggerClientEvent('xian_chat:client:show3DText', target, src, messageType, message, characterName, Config.ThreeDText.Duration)
                end
            end
        end
    end
end

AddEventHandler('playerDropped', function()
    lastRoleplayMessage[source] = nil
end)

local function sendMe(src, message)
    send3DText(src, 'me', message)
end

local function sendDo(src, message)
    send3DText(src, 'do', message)
end

-- === Shared command registration ===

local function registerCommand(cfg, sendFn, help)
    if not (cfg and cfg.Enabled) then return end

    lib.addCommand(cfg.Command, {
        help = help,
        params = {
            { name = 'text', help = 'Pesan', type = 'longString', optional = false }
        },
        restricted = cfg.Permission == 'admin' and 'group.admin' or false
    }, function(src, args, rawCommand)
        if chatDisabled then
            notify(src, 'Chat sedang dinonaktifkan.', 'error')
            return
        end

        if not hasJobPermission(src, cfg) then
            notify(src, 'Kamu tidak memiliki izin untuk command ini.', 'error')
            return
        end

        local msg = getMessage(args, rawCommand, cfg.Command)
        if not msg or msg == '' then return end

        sendFn(src, msg)
    end)
end

registerCommand(Config.OOC, sendGlobalOOC, 'Kirim pesan Global OOC')
registerCommand(Config.ADM, sendGlobalAdminMessage, 'Kirim pengumuman global ADMIN')
registerCommand(Config.GOV, sendGlobalGOV, 'Kirim pesan Global GOVERNMENT')
registerCommand(Config.EMS, sendGlobalEMS, 'Kirim pesan Global EMS')
registerCommand(Config.POL, sendGlobalPOL, 'Kirim pesan Global POLICE')
registerCommand(Config.MEC, sendGlobalMEC, 'Kirim pesan Global MECHANIC')
registerCommand(Config.REST, sendGlobalREST, 'Kirim pesan Global RESTAURANT')
registerCommand(Config.NC, sendGlobalNC, 'Kirim pesan Global NIGHTCLUB')
registerCommand(Config.ME, sendMe, 'Tampilkan teks 3D ME di atas kepala')
registerCommand(Config.DO, sendDo, 'Tampilkan teks 3D DO di atas kepala')

lib.addCommand('togglechat', {
    help = 'Aktifkan / nonaktifkan global chat',
    restricted = 'group.admin'
}, function(src)
    chatDisabled = not chatDisabled
    exports.xian_chat:addMessage(-1, {
        template = '<p class="message-wrapper role-message" style="--role-color: #facc15"><span class="author role-label">SYSTEM</span><span>Global chat sekarang {0}.</span></p>',
        args = { chatDisabled and 'OFF' or 'ON' }
    })
end)
