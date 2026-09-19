--[[
    COREX Spawn - Client Side
    Handles player spawning and character creation UI
    Functional Lua | No OOP | Zombie Survival Optimized
]]

local Corex = nil
local isUIOpen = false
local playerLoaded = false
local hasSpawned = false
local spawnInProgress = false
local savedSkin = nil
local spawnReadySent = false
local currentSpawnId
local readyThreadId
local spawnManagerGuardInstalled = false

-- Wait for corex-core
CreateThread(function()
    local attempts = 0
    while not Corex or not Corex.Functions do
        Wait(100)
        attempts = attempts + 1
        local success, core = pcall(function()
            return exports['corex-core']:GetCoreObject()
        end)
        if success and core then
            Corex = core
        end
        if attempts >= 100 then
            print('[COREX-SPAWN] ^1Failed to connect to corex-core^0')
            return
        end
    end
    print('[COREX-SPAWN] ^2Connected to corex-core^0')
end)

-- Wait for statebag (isLoggedIn) before proceeding
local function WaitForStateBag()
    local timeout = 0
    while not LocalPlayer.state.isLoggedIn and timeout < 100 do
        Wait(100)
        timeout = timeout + 1
    end
    return LocalPlayer.state.isLoggedIn == true
end

local function ResolveSpawnGroundZ(x, y, z)
    local probeHeights = { 0.0, 1.0, 2.0, 5.0, 10.0, 25.0, 50.0 }

    for _, offset in ipairs(probeHeights) do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, z + offset, false)
        if found then
            return groundZ
        end
    end

    return nil
end

local function InstallSpawnManagerGuard()
    local ok = pcall(function()
        exports.spawnmanager:setAutoSpawnCallback(function()
            if Config.Debug then
                print('[COREX-SPAWN] ^3Blocked default spawnmanager auto-respawn^0')
            end
        end)
    end)

    if ok then
        spawnManagerGuardInstalled = true
    end

    pcall(function()
        exports.spawnmanager:setAutoSpawn(false)
    end)
end

local function NormalizePlayerState()
    local ped = PlayerPedId()


    ClearFocus()

    if DoesEntityExist(ped) then
        ResetEntityAlpha(ped)
        SetEntityVisible(ped, true, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        SetEntityInvincible(ped, false)
    end

    SetPlayerInvincible(PlayerId(), false)
    SetPlayerControl(PlayerId(), true, 0)

    if NetworkSetInSpectatorMode then
        NetworkSetInSpectatorMode(false, ped)
    end
end

local function ScheduleSpawnStateNormalization()
    CreateThread(function()
        NormalizePlayerState()
        Wait(250)
        NormalizePlayerState()
        Wait(1000)
        NormalizePlayerState()
        Wait(2000)
        NormalizePlayerState()
    end)
end

local function HoldPlayerBehindLoadingScreen()
    if Corex and Corex.Functions and Corex.Functions.ScreenFadeOut then
        pcall(Corex.Functions.ScreenFadeOut, 0)
    else
        pcall(DoScreenFadeOut, 0)
    end

    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        SetEntityVisible(ped, false, false)
        FreezeEntityPosition(ped, true)
    end

    SetPlayerControl(PlayerId(), false, 0)

    ClearFocus()
end

local function PlacePlayerAtSpawn(spawn, options)
    options = options or {}

    local ped = Corex.Functions.GetPed()
    if not DoesEntityExist(ped) then
        return false
    end

    local heading = spawn.heading or spawn.w or 0.0
    local targetZ = spawn.z + (options.zOffset or 0.0)
    local allowGroundSnap = options.allowGroundSnap ~= false

    SetEntityVisible(ped, false, false)
    Corex.Functions.FreezeEntity(ped, true)
    SetEntityLoadCollisionFlag(ped, true)
    RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
    NewLoadSceneStartSphere(spawn.x, spawn.y, spawn.z, 25.0, 0)

    -- Collision must be checked around the destination, not the old ped position.
    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, targetZ, false, false, false)
    SetEntityHeading(ped, heading)

    local collisionLoaded = false
    for _ = 1, 50 do
        Wait(100)
        RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
        if HasCollisionLoadedAroundEntity(ped) then
            collisionLoaded = true
            break
        end
    end

    if allowGroundSnap then
        local groundZ = ResolveSpawnGroundZ(spawn.x, spawn.y, spawn.z)
        if groundZ then
            targetZ = groundZ + 0.03
        elseif collisionLoaded then
            targetZ = spawn.z - 0.05
        end
    end

    SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, targetZ, false, false, false)
    SetEntityHeading(ped, heading)

    for _ = 1, 20 do
        Wait(100)

        if allowGroundSnap then
            local coords = Corex.Functions.GetCoords(ped)
            local currentGroundZ = ResolveSpawnGroundZ(coords.x, coords.y, coords.z)
            if currentGroundZ and math.abs(coords.z - currentGroundZ) > 0.08 then
                SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, currentGroundZ + 0.03, false, false, false)
                SetEntityHeading(ped, heading)
            end
        end

        if not IsEntityInAir(ped) and not IsPedFalling(ped) then
            break
        end
    end

    if allowGroundSnap and (IsEntityInAir(ped) or IsPedFalling(ped)) then
        SetEntityCoordsNoOffset(ped, spawn.x, spawn.y, spawn.z - 0.15, false, false, false)
        SetEntityHeading(ped, heading)
    end

    collisionLoaded = HasCollisionLoadedAroundEntity(ped)

    -- CRITICAL: do NOT flip visibility unless collision is actually loaded.
    -- Revealing the ped in an un-streamed world causes the
    -- virginia-october-hydrogen crash (GameSkeleton::RunUpdate null deref
    -- on the first physics tick against null collision). If the initial
    -- 5-second wait timed out, run a second 3-second fallback window
    -- that keeps re-requesting collision. If still not loaded, keep the
    -- ped hidden + frozen and return false — the caller must keep the
    -- loading screen up and retry.
    if not collisionLoaded then
        print('[COREX-SPAWN] ^3Collision not ready after primary wait — entering fallback window^0')
        for _ = 1, 30 do
            Wait(100)
            RequestCollisionAtCoord(spawn.x, spawn.y, spawn.z)
            if HasCollisionLoadedAroundEntity(ped) then
                collisionLoaded = true
                break
            end
        end
    end

    NewLoadSceneStop()

    if not collisionLoaded then
        print('[COREX-SPAWN] ^1Collision still not ready — keeping ped hidden, caller must retry^0')
        -- Force screen black so the user doesn't see the void.
        if Corex and Corex.Functions and Corex.Functions.ScreenFadeOut then
            pcall(Corex.Functions.ScreenFadeOut, 0)
        else
            pcall(DoScreenFadeOut, 0)
        end
        -- Leave ped hidden + frozen (already done at lines 132-133).
        return false
    end

    SetEntityVisible(ped, true, false)
    Corex.Functions.FreezeEntity(ped, false)
    return true
end

local function SendSpawnReady()
    if spawnReadySent or not playerLoaded or not currentSpawnId or readyThreadId == currentSpawnId then return end
    local spawnId = currentSpawnId
    readyThreadId = spawnId
    CreateThread(function()
        while currentSpawnId == spawnId and playerLoaded and not spawnReadySent do
            local ped = PlayerPedId()
            if DoesEntityExist(ped) and HasCollisionLoadedAroundEntity(ped) and not IsPedFalling(ped) and not IsEntityInAir(ped) then
                local coords = Corex.Functions.GetCoords(ped)
                TriggerServerEvent('corex-spawn:server:markSpawnReady', {
                    x = coords.x, y = coords.y, z = coords.z, heading = coords.w
                }, spawnId)
            end
            Wait(2000)
        end
        if readyThreadId == spawnId then readyThreadId = nil end
    end)
end

RegisterNetEvent('corex-spawn:client:spawnConfirmed', function(spawnId)
    if spawnId ~= currentSpawnId or not playerLoaded or spawnReadySent then return end
    spawnReadySent = true
    TriggerEvent('corex-spawn:client:spawnCompleted')
end)

-- Disable auto spawn on resource start and load player data
AddEventHandler('onClientResourceStart', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    InstallSpawnManagerGuard()

    print('[COREX-SPAWN] ^3Resource started^0')

    CreateThread(function()
        -- Tell FiveM we'll shut the NUI loading screen down manually.
        if SetManualShutdownLoadingScreenNui then
            pcall(SetManualShutdownLoadingScreenNui, true)
        end

        Wait(1500)

        -- REMOVED: premature ShutdownLoadingScreenNui / ShutdownLoadingScreen here.
        -- Closing the loading screen before PlacePlayerAtSpawn verified collision
        -- exposes the player to an un-streamed world and is the root cause of
        -- the virginia-october-hydrogen crash at respawn moment. The screen is
        -- now only closed INSIDE the corex-spawn:client:spawnPlayer handler,
        -- after HasCollisionLoadedAroundEntity is confirmed true.

        if not LocalPlayer.state.isLoggedIn then
            TriggerServerEvent('corex:server:loadPlayer')
            print('[COREX-SPAWN] ^2Requested player load^0')
        end
    end)
end)

AddEventHandler('onClientMapStart', function()
    InstallSpawnManagerGuard()

    CreateThread(function()
        Wait(1000)
        InstallSpawnManagerGuard()
    end)
end)

CreateThread(function()
    Wait(3000)
    InstallSpawnManagerGuard()
end)

CreateThread(function()
    Wait(20000)
    while true do
        if playerLoaded or isUIOpen or spawnInProgress or LocalPlayer.state.characterSelection then
            Wait(5000)
            goto continue
        end
        print('[COREX-SPAWN] ^1Spawn flow stalled; keeping player hidden and retrying safely^0')
        HoldPlayerBehindLoadingScreen()

        if LocalPlayer.state.isLoggedIn then
            TriggerServerEvent('corex-spawn:server:checkPlayer')
        else
            TriggerServerEvent('corex:server:loadPlayer')
        end

        Wait(5000)
        ::continue::
    end
end)

-- Death handling moved to corex-death resource

AddEventHandler('corex-spawn:client:reapplySkin', function()
    local appearance = lib.callback.await('illenium-appearance:server:getAppearance', false)
    if appearance then
        savedSkin = appearance
        ApplySkinToPlayer(appearance)
    end
end)

RegisterNetEvent('corex-spawn:client:clearSpawnFlags', function()
    currentSpawnId = nil
    spawnReadySent = false
    hasSpawned = false
    playerLoaded = false
end)

local function SpawnPlayer(data)
    data = data or {}

    -- Wait for Corex to be available
    local waitTime = 0
    while (not Corex or not Corex.Functions) and waitTime < 10000 do
        Wait(100)
        waitTime = waitTime + 100
    end
    
    if not Corex or not Corex.Functions then
        print('[COREX-SPAWN] ^1ERROR: Corex not available!^0')
        return
    end

    -- CRITICAL: Wait for statebag to ensure metadata (hunger, thirst, etc.) is synced
    if not WaitForStateBag() then
        print('[COREX-SPAWN] ^3WARN: StateBag not ready, proceeding anyway^0')
    end
    
    if data.spawnId == currentSpawnId and playerLoaded then
        SendSpawnReady()
        return
    end
    currentSpawnId = data.spawnId
    spawnReadySent = false

    -- Handle resource restart - player already spawned in world
    if data.isResourceRestart then
        local ped = Corex.Functions.GetPed()
        if Corex.Functions.DoesEntityExist(ped) and not Corex.Functions.IsDead(ped) then
            local coords = Corex.Functions.GetCoords(ped)
            if coords.z > 0.0 then
                if data.skin then
                    savedSkin = data.skin
                    ApplySkinToPlayer(data.skin, { skipModelLoad = true })
                end
                playerLoaded = true
                hasSpawned = true
                SendSpawnReady()
                return
            end
        end
    end
    
    -- Skip if already spawned (prevent duplicates)
    if hasSpawned and playerLoaded and not data.isRespawn then
        return
    end

    spawnReadySent = false
    if data.isRespawn then
        hasSpawned = false
        playerLoaded = false
        TriggerEvent('corex-death:client:prepareRespawn')
    end

    Corex.Functions.ScreenFadeOut(500)
    Wait(1000)
    
    local spawn = data.isNew and Config.FirstSpawnLocation or Config.DefaultSpawnLocation

    if data.position then
        spawn = data.position
    end
    
    local modelName = Config.DefaultMaleModel
    if data.isNew and data.playerData and data.playerData.metadata.gender == 'female' then
        modelName = Config.DefaultFemaleModel or 'mp_f_freemode_01'
    end
    if data.skin and data.skin.model then
        modelName = data.skin.model
    end
    
    LoadAndSetPlayerModel(modelName)
    Wait(500)

    if data.isRespawn then
        local heading = spawn.heading or spawn.w or 0.0
        Corex.Functions.Resurrect(vector4(spawn.x, spawn.y, spawn.z, heading))
        Wait(100)
    end
    
    local ped = Corex.Functions.GetPed()
    local spawnPlaced = PlacePlayerAtSpawn(spawn, {
        allowGroundSnap = not data.isNew,
        zOffset = data.isNew and 0.03 or 0.0
    })

    -- If collision never loaded, PlacePlayerAtSpawn returns false and keeps
    -- the ped hidden + frozen behind a black screen. Schedule a retry and
    -- abort this spawn attempt. The watchdog keeps the player hidden and
    -- asks the server to retry instead of revealing an un-streamed world.
    if not spawnPlaced then
        print('[COREX-SPAWN] ^1Spawn aborted — collision never loaded. Scheduling retry in 2s.^0')
        CreateThread(function()
            Wait(2000)
            if not playerLoaded and not isUIOpen and not spawnInProgress then
                TriggerServerEvent('corex-spawn:server:checkPlayer')
            end
        end)
        return
    end

    Wait(500)

    hasSpawned = true
    
    if data.isNew then
        SetPedDefaultComponentVariation(ped)

        if ShutdownLoadingScreenNui then pcall(ShutdownLoadingScreenNui) end
        if ShutdownLoadingScreen then pcall(ShutdownLoadingScreen) end

        SetEntityVisible(ped, true, false)
        Corex.Functions.FreezeEntity(ped, true)
        Corex.Functions.SetPlayerControl(true)

        Corex.Functions.ScreenFadeIn(500)
        Wait(500)

        isUIOpen = true
        local opened = exports['illenium-appearance']:CreateCharacter(function()
            savedSkin = exports['illenium-appearance']:getPedAppearance(PlayerPedId())
            isUIOpen = false
            playerLoaded = true
            NormalizePlayerState()
            SendSpawnReady()
        end)
        if not opened then
            print('[COREX-SPAWN] ^1Illenium character creator gagal dibuka^0')
            isUIOpen = false
            hasSpawned = false
            HoldPlayerBehindLoadingScreen()
        end
    else
        if data.skin then
            savedSkin = data.skin
            ApplySkinToPlayer(data.skin, { skipModelLoad = true })
        end

        if data.isRespawn then
            ClearPedBloodDamage(ped)
            SetEntityHealth(ped, 200)
        end

        if ShutdownLoadingScreenNui then pcall(ShutdownLoadingScreenNui) end
        if ShutdownLoadingScreen then pcall(ShutdownLoadingScreen) end

        SetEntityVisible(ped, true, false)
        ResetEntityAlpha(ped)
        SetEntityCollision(ped, true, true)
        SetEntityInvincible(ped, false)

        Corex.Functions.FreezeEntity(ped, false)
        Corex.Functions.SetPlayerControl(true)

        ClearFocus()

        if SwitchInPlayer then
            pcall(SwitchInPlayer, ped)
        end

        ScheduleSpawnStateNormalization()

        Corex.Functions.ScreenFadeIn(500)
        TriggerEvent('corex-death:client:respawnFinished')

        playerLoaded = true
        SendSpawnReady()
    end
end

RegisterNetEvent('corex-spawn:client:spawnPlayer', function(data)
    if LocalPlayer.state.characterSelection then
        print('[COREX-SPAWN] Spawn blocked while character selection is active')
        return
    end
    TriggerEvent('corex-multicharacter:client:closeForSpawn')
    if spawnInProgress or isUIOpen then return end
    spawnInProgress = true
    local ok, err = xpcall(function()
        SpawnPlayer(data)
    end, debug.traceback)
    spawnInProgress = false
    if not ok then
        isUIOpen = false
        print('[COREX-SPAWN] ^1Spawn failed: ' .. tostring(err) .. '^0')
        HoldPlayerBehindLoadingScreen()
    end
end)

function LoadAndSetPlayerModel(modelName)
    if not Corex.Functions.LoadModel(modelName, 5000) then 
        if Config.Debug then
            print('^1[COREX-SPAWN] Failed to load model: "' .. modelName .. '"')
        end
        return
    end
    local modelHash = GetHashKey(modelName)
    SetPlayerModel(PlayerId(), modelHash)
    Corex.Functions.SetModelAsNoLongerNeeded(modelHash)

    local ped = Corex.Functions.GetPed()
    SetPedDefaultComponentVariation(ped)

    return ped
end

function ApplySkinToPlayer(skinData, options)
    if not skinData then return end
    if options and options.skipModelLoad then
        exports['illenium-appearance']:setPedAppearance(PlayerPedId(), skinData)
    else
        exports['illenium-appearance']:setPlayerAppearance(skinData)
    end
end

AddEventHandler('onResourceStop', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    NormalizePlayerState()
end)

RegisterNetEvent('corex-spawn:client:requestPosition', function()
    if not playerLoaded or not spawnReadySent or isUIOpen then return end
    
    local coords = Corex.Functions.GetCoords()
    
    TriggerServerEvent('corex-spawn:server:savePosition', {
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = coords.w
    })
end)
