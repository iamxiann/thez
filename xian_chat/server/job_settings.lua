local RESOURCE_NAME = GetCurrentResourceName()
local SETTINGS_FILE = 'chatjob.json'
local styles = {}
local savedStyles = {}

local function loadSavedStyles()
    local content = LoadResourceFile(RESOURCE_NAME, SETTINGS_FILE)
    if not content or content == '' then return end

    local ok, data = pcall(json.decode, content)
    if ok and type(data) == 'table' then
        savedStyles = data
        return
    end

    print(('[%s] %s tidak valid; pengaturan default akan digunakan.'):format(RESOURCE_NAME, SETTINGS_FILE))
end

local function saveStyles()
    local content = json.encode(savedStyles)
    local ok, errorMessage = pcall(SaveResourceFile, RESOURCE_NAME, SETTINGS_FILE, content, -1)
    if not ok then
        print(('[%s] Gagal menulis %s: %s'):format(RESOURCE_NAME, SETTINGS_FILE, tostring(errorMessage)))
        return false
    end

    local writtenContent = LoadResourceFile(RESOURCE_NAME, SETTINGS_FILE)
    if writtenContent ~= content then
        print(('[%s] Verifikasi penulisan %s gagal.'):format(RESOURCE_NAME, SETTINGS_FILE))
        return false
    end

    return true
end

loadSavedStyles()

local function normalizeHex(value)
    if type(value) ~= 'string' then return nil end

    local hex = value:lower()
    if hex:match('^#%x%x%x%x%x%x$') then return hex end
    return nil
end

local function getPlayerJob(src)
    local player = exports['corex-core']:GetPlayer(src)
    local playerData = player and (player.PlayerData or player)
    local job = playerData and playerData.job
    if not job or type(job.name) ~= 'string' then return nil end
    return job
end

local function isBoss(job)
    if job.isboss == true or job.isBoss == true then return true end
    return job.grade and (job.grade.isboss == true or job.grade.isBoss == true) or false
end

local function getDefaultStyle(jobName)
    local config = Config.JobChats and Config.JobChats[jobName]
    if not config then return nil end

    return {
        label = tostring(config.Label or jobName):sub(1, 32),
        textColor = normalizeHex(config.TextColor) or '#ffffff',
        outlineColor = normalizeHex(config.OutlineColor) or normalizeHex(config.TextColor) or '#42b883',
    }
end

local function loadStyle(jobName)
    if styles[jobName] then return styles[jobName] end

    local style = getDefaultStyle(jobName)
    if not style then return nil end

    local stored = savedStyles[jobName]
    if type(stored) == 'table' then
        style.textColor = normalizeHex(stored.textColor) or style.textColor
        style.outlineColor = normalizeHex(stored.outlineColor) or style.outlineColor
    end

    styles[jobName] = style
    return style
end

exports('GetJobChatStyle', function(jobName)
    return loadStyle(jobName)
end)

lib.callback.register('xian_chat:server:getJobChatSettings', function(src)
    local job = getPlayerJob(src)
    if not job or not isBoss(job) then return nil, 'Hanya boss yang dapat membuka pengaturan chat job.' end

    local style = loadStyle(job.name)
    if not style then return nil, 'Job ini tidak memiliki channel chat yang dapat diatur.' end

    return {
        jobName = job.name,
        label = style.label,
        textColor = style.textColor,
        outlineColor = style.outlineColor,
    }
end)

lib.callback.register('xian_chat:server:saveJobChatSettings', function(src, data)
    local job = getPlayerJob(src)
    if not job or not isBoss(job) then return false, 'Kamu tidak memiliki izin untuk mengubah pengaturan ini.' end
    if type(data) ~= 'table' then return false, 'Data pengaturan tidak valid.' end

    local style = loadStyle(job.name)
    if not style then return false, 'Job ini tidak memiliki channel chat yang dapat diatur.' end

    local textColor = normalizeHex(data.textColor)
    local outlineColor = normalizeHex(data.outlineColor)
    if not textColor or not outlineColor then return false, 'Format warna tidak valid.' end

    local previous = savedStyles[job.name]
    savedStyles[job.name] = {
        textColor = textColor,
        outlineColor = outlineColor,
    }

    if not saveStyles() then
        savedStyles[job.name] = previous
        return false, 'Gagal menyimpan pengaturan ke chatjob.json.'
    end

    style.textColor = textColor
    style.outlineColor = outlineColor

    TriggerClientEvent('xian_chat:client:updateJobChatStyle', -1, {
        jobName = job.name,
        textColor = textColor,
        outlineColor = outlineColor,
    })

    return true, 'Warna chat ' .. style.label .. ' berhasil disimpan.'
end)
