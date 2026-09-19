if not Framework.Corex() then return end

function Framework.UpdatePlayerData()
    local metadata = LocalPlayer.state.metadata or {}
    client.identifier = LocalPlayer.state.identifier
    client.job = metadata.job or { name = 'unemployed', grade = { level = 0 }, onduty = false }
    client.gang = metadata.gang or { name = 'none', grade = { level = 0 } }
end

function Framework.GetPlayerGender()
    local charinfo = (LocalPlayer.state.metadata or {}).charinfo
    if charinfo and tonumber(charinfo.gender) then
        return tonumber(charinfo.gender) == 1 and 'Female' or 'Male'
    end
    return client.getPedModel(PlayerPedId()) == 'mp_f_freemode_01' and 'Female' or 'Male'
end

function Framework.HasTracker()
    return (LocalPlayer.state.metadata or {}).tracker == true
end

function Framework.CheckPlayerMeta()
    local metadata = LocalPlayer.state.metadata or {}
    return LocalPlayer.state.lifecycleState == 'dead' or metadata.isdead or metadata.inlaststand or metadata.ishandcuffed
end

function Framework.IsPlayerAllowed(identifier)
    return identifier == LocalPlayer.state.identifier
end

function Framework.GetRankInputValues() return {} end
function Framework.GetJobGrade() return client.job.grade.level end
function Framework.GetGangGrade() return client.gang.grade.level end
function Framework.CachePed() end
function Framework.RestorePlayerArmour()
    local armour = (LocalPlayer.state.metadata or {}).armor
    if type(armour) == 'number' then SetPedArmour(PlayerPedId(), armour) end
end

Framework.UpdatePlayerData()

local characterCreatedCallback

local savingCharacter = false
local characterSaved = false

-- Called before NUI closes: a failed/timeout save leaves the editor available.
function Framework.SaveCharacter(appearance)
    if not characterCreatedCallback then return nil end
    if savingCharacter then return false end
    savingCharacter = true
    local ok, saved = pcall(lib.callback.await, 'illenium-appearance:server:saveCharacter', false, appearance)
    savingCharacter = false
    characterSaved = ok and saved == true
    if not characterSaved then
        lib.notify({ title = 'Appearance', description = 'Appearance gagal disimpan. Silakan coba lagi.', type = 'error' })
    end
    return characterSaved
end

function Framework.FinishCharacterCreation()
    if not characterCreatedCallback then return false end
    if not characterSaved then return true end
    local callback = characterCreatedCallback
    characterCreatedCallback = nil
    characterSaved = false
    callback()
    return true
end

exports('CreateCharacter', function(onSubmit)
    -- Cfx deserializes callbacks passed through exports as callable tables.
    local callbackType = type(onSubmit)
    local callbackMeta = callbackType == 'table' and getmetatable(onSubmit)
    if callbackType ~= 'function' and (type(callbackMeta) ~= 'table' or type(callbackMeta.__call) ~= 'function') then
        return false
    end
    if characterCreatedCallback then return false end
    Framework.UpdatePlayerData()
    characterCreatedCallback = onSubmit
    characterSaved = false
    local ok, opened = pcall(InitializeCharacter, Framework.GetGender(true), function() end)
    if not ok or opened == false then
        characterCreatedCallback = nil
        characterSaved = false
        SetNuiFocus(false, false)
        TriggerServerEvent('illenium-appearance:server:ResetRoutingBucket')
        print('[ILLENIUM] Character editor failed: ' .. tostring(ok and 'opening timed out' or opened))
        return false
    end
    return true
end)

AddEventHandler('corex:client:onCharacterSpawned', function(appearancePending)
    CreateThread(function()
        local deadline = GetGameTimer() + 10000
        while (not LocalPlayer.state.isLoggedIn or not LocalPlayer.state.metadata) and GetGameTimer() < deadline do
            Wait(50)
        end
        if not LocalPlayer.state.isLoggedIn or not LocalPlayer.state.metadata then
            lib.notify({ title = 'Appearance', description = 'Data karakter belum siap. Silakan reconnect.', type = 'error' })
            return
        end
        if appearancePending then
            local opened = exports['illenium-appearance']:CreateCharacter(function()
                Framework.UpdatePlayerData()
            end)
            if not opened then
                lib.notify({ title = 'Appearance', description = 'Editor gagal dibuka. Silakan reconnect untuk mencoba lagi.', type = 'error' })
            end
        else
            InitAppearance()
        end
    end)
end)
