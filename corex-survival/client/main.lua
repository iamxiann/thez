local Corex = nil
local isReady = false

local currentHunger = 100
local currentThirst = 100
local currentInfection = 0

local effectsActive = false
local infectionPaused = false

local function InitCore()
    local success, core = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)
    if not success or not core or not core.Functions then return false end
    Corex = core
    return true
end

local function OnCoreReady()
    Corex.Functions.WaitForPlayerData(15000)

    local metadata = Corex.Functions.GetMetaData()
    if metadata then
        currentHunger = metadata.hunger or 100
        currentThirst = metadata.thirst or 100
        currentInfection = metadata.infection or 0
    end

    isReady = true
    print('[COREX-SURVIVAL] ^2Survival system initialized^0')
end

if not InitCore() then
    AddEventHandler('corex:client:coreReady', function(coreObj)
        if coreObj and coreObj.Functions and not Corex then
            Corex = coreObj
            OnCoreReady()
        end
    end)
    CreateThread(function()
        Wait(15000)
        if not Corex then
            print('[COREX-SURVIVAL] ^1Core init timed out^0')
        end
    end)
else
    CreateThread(function()
        OnCoreReady()
    end)
end

local function GetInfectionStage(level)
    local activeStage = nil
    for _, stage in ipairs(Config.Infection.stages) do
        if level >= stage.threshold then
            activeStage = stage
        end
    end
    return activeStage
end

local function HasEffect(stage, effectName)
    if not stage or not stage.effects then return false end
    for _, eff in ipairs(stage.effects) do
        if eff == effectName then return true end
    end
    return false
end

-- StateBag listeners for stat synchronization
CreateThread(function()
    while not Corex do Wait(100) end

    while not NetworkIsPlayerActive(PlayerId()) do
        Wait(100)
    end

    local serverId = GetPlayerServerId(PlayerId())
    local playerBag = ('player:%s'):format(serverId)

    AddStateBagChangeHandler('metadata', playerBag, function(_, _, value)
        if not value then return end
        currentHunger = value.hunger or currentHunger
        currentThirst = value.thirst or currentThirst
        currentInfection = value.infection or currentInfection
    end)
end)

-- Hunger/Thirst drain tick
CreateThread(function()
    while not isReady do Wait(500) end

    while true do
        Wait(Config.Hunger.tickInterval)

        if not Corex.Functions.IsAlive() then goto continue end

        TriggerServerEvent('corex-survival:server:drainTick')

        ::continue::
    end
end)

-- Low stat effects: screen fx and health damage
CreateThread(function()
    while not isReady do Wait(500) end

    while true do
        Wait(1000)

        if not Corex.Functions.IsAlive() then goto continue end

        local ped = Corex.Functions.GetPed()

        if currentHunger <= Config.Hunger.damageThreshold then
            ApplyDamageToPed(ped, Config.Hunger.damageAmount, false)
        end

        if currentThirst <= Config.Thirst.damageThreshold then
            ApplyDamageToPed(ped, Config.Thirst.damageAmount, false)
        end

        -- Screen effect for low hunger/thirst
        if currentHunger <= Config.Hunger.effectThreshold or currentThirst <= Config.Thirst.effectThreshold then
            local intensity = 1.0 - (math.min(currentHunger, currentThirst) / Config.Hunger.effectThreshold)
            SetTimecycleModifier('hud_def_desat_cold')
            SetTimecycleModifierStrength(math.min(0.6, intensity * 0.6))
        elseif currentInfection <= 0 then
            ClearTimecycleModifier()
        end

        ::continue::
    end
end)

-- Infection effects loop
CreateThread(function()
    while not isReady do Wait(500) end

    local appliedStageIdx = nil

    while true do
        Wait(1000)

        if not Corex.Functions.IsAlive() or currentInfection <= 0 then
            if effectsActive then
                ClearTimecycleModifier()
                ResetPedMovementClipset(Corex.Functions.GetPed(), 0.0)
                StopGameplayCamShaking(true)
                effectsActive = false
                appliedStageIdx = nil
            end
            goto continue
        end

        effectsActive = true
        local stage = GetInfectionStage(currentInfection)
        if not stage then goto continue end
        local ped = Corex.Functions.GetPed()

        -- Shake and clipset naturally decay; reapply only when the stage
        -- actually changes to avoid spamming natives each tick.
        local stageChanged = appliedStageIdx ~= stage.threshold
        appliedStageIdx = stage.threshold

        if HasEffect(stage, 'shake') and stageChanged then
            ShakeGameplayCam('SMALL_EXPLOSION_SHAKE', Config.Effects.shakeIntensity)
        end

        if HasEffect(stage, 'slowness') then
            SetPedMoveRateOverride(ped, Config.Effects.slowMultiplier)
        elseif stageChanged then
            ResetPedMovementClipset(ped, 0.0)
        end

        if HasEffect(stage, 'screenDistort') and stageChanged then
            SetTimecycleModifier('drug_flying_base')
            SetTimecycleModifierStrength(Config.Effects.screenDistortStrength)
        end

        ::continue::
    end
end)

-- Cough animation (separate thread with cooldown)
CreateThread(function()
    while not isReady do Wait(500) end

    local lastCough = 0

    while true do
        Wait(2000)

        if not Corex.Functions.IsAlive() or currentInfection <= 0 then
            goto continue
        end

        local stage = GetInfectionStage(currentInfection)
        if not stage or not HasEffect(stage, 'cough') then goto continue end

        local now = GetGameTimer()
        if now - lastCough < Config.Effects.coughCooldown then goto continue end

        lastCough = now
        local ped = Corex.Functions.GetPed()

        local success = pcall(function()
            RequestAnimDict(Config.Effects.coughDict)
            local loadStart = GetGameTimer()
            while not HasAnimDictLoaded(Config.Effects.coughDict) do
                Wait(10)
                if GetGameTimer() - loadStart > 3000 then return end
            end
            TaskPlayAnim(ped, Config.Effects.coughDict, Config.Effects.coughAnim, 4.0, 4.0, Config.Effects.coughDuration, 49, 0, false, false, false)
            RemoveAnimDict(Config.Effects.coughDict)
        end)

        ::continue::
    end
end)

-- ---------------------------------------------------------------------------
-- Regen-gate state (declared up-here so handlers below can reference it).
-- The actual gate-flip logic + per-frame blocker thread sit further down.
-- ---------------------------------------------------------------------------
local activeDamageStates = { cold = false, bleeding = false }
local gate = { enabled = false, lastHp = 200 }
local respawnGraceUntil = 0
local RESPAWN_FULL_HEALTH = 200
local RESPAWN_DAMAGE_GRACE_MS = 5000

RegisterNetEvent('corex-survival:client:applyHealthDelta', function(amount)
    if not isReady then return end
    local delta = tonumber(amount) or 0
    if delta < 0 and GetGameTimer() < respawnGraceUntil then return end
    local ped = Corex.Functions.GetPed()
    if not ped or ped == 0 then return end
    local current = GetEntityHealth(ped)
    local clamped = math.max(0, math.min(200, current + delta))
    SetEntityHealth(ped, clamped)
    -- Sync the regen-gate snapshot so intentional heals (bandage / medkit /
    -- antidote bonus) AND intentional damage (cold / bleed tick) both pass
    -- through cleanly without being reverted by the per-frame blocker.
    gate.lastHp = clamped
end)

RegisterNetEvent('corex-survival:client:zombieHit', function()
    if not isReady or not Config.Infection.enabled then return end
    if currentInfection > 0 then return end

    -- Server is authoritative for the bite-chance roll (so corex-skills can
    -- apply biteChance / biteImmunity modifiers without the client cheating).
    -- We just report the hit; the server decides infection.
    TriggerServerEvent('corex-survival:server:zombieHit')
end)

-- ---------------------------------------------------------------------------
-- Bleeding detection — watch HP delta, report big hits to server
-- ---------------------------------------------------------------------------
-- Track HP per frame. If HP drops by more than Config.Bleed.hitThreshold in
-- a single frame, that's a "big hit" and we ask the server to start a bleed.
-- Server re-validates so a bad client can't trigger this falsely.
CreateThread(function()
    while not isReady do Wait(500) end
    local lastHp = nil
    while true do
        Wait(250)
        local ped = PlayerPedId()
        local hp = ped ~= 0 and GetEntityHealth(ped) or 0
        local canReport = Config.Bleed and Config.Bleed.enabled
            and ped ~= 0 and hp > 100 and Corex.Functions.IsAlive()

        if canReport and lastHp then
            local delta = lastHp - hp
            if delta >= (Config.Bleed.hitThreshold or 30) then
                TriggerServerEvent('corex-survival:server:reportHit', lastHp, hp)
            end
        end
        -- Death, reconnect and respawn all establish a fresh baseline instead
        -- of comparing the new ped against a stale health sample.
        lastHp = hp
    end
end)

-- ---------------------------------------------------------------------------
-- Cold zone detection — periodic coords report to the server
-- ---------------------------------------------------------------------------
-- Cheap altitude check + periodic coords post. Server decides damage so the
-- s_cold skill modifier can be applied authoritatively.
CreateThread(function()
    while not isReady do Wait(1000) end
    while true do
        local interval = (Config.Cold and Config.Cold.tickInterval) or 8000
        Wait(interval)
        if Config.Cold and Config.Cold.enabled and Corex.Functions.IsAlive() then
            local ped = PlayerPedId()
            local coords = GetEntityCoords(ped)
            TriggerServerEvent('corex-survival:server:reportColdCheck', coords)
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Health-regen gate (HARD blocker)
-- ---------------------------------------------------------------------------
-- The vanilla `SetPlayerHealthRechargeMultiplier` native turned out not to
-- fully disable regen — HP still ticked back up while the player was
-- freezing. So we run a manual blocker as the source of truth:
--
--   * `gate.enabled` flips ON whenever cold ≥ damage-threshold OR the player
--     is bleeding.
--   * A per-frame thread snapshots the player's HP. If HP went UP between
--     frames and the gate is enabled, we revert it to the previous value.
--   * Intentional heals (bandage / medkit / cold damage = negative delta)
--     come through `applyHealthDelta` — that handler updates the snapshot
--     itself so legitimate heals aren't reverted.
--
-- This works regardless of what's trying to regen — vanilla GTA, third-
-- party scripts, custom regen — all are clamped while damage is active.
-- (`activeDamageStates` and `gate` are declared near the top of the file
-- so the applyHealthDelta handler — which fires before this block executes
-- at load time — can update gate.lastHp without a nil-index error.)

local function ApplyRegenGate()
    local anyActive = activeDamageStates.cold or activeDamageStates.bleeding
    if anyActive ~= gate.enabled then
        gate.enabled = anyActive
        local ped = PlayerPedId()
        if ped and ped ~= 0 then
            gate.lastHp = GetEntityHealth(ped)
        end
        if Config.Debug then
            print(('^3[COREX-SURVIVAL]^7 regen-gate %s (cold=%s bleed=%s lastHp=%d)^0'):format(
                anyActive and 'ENABLED' or 'disabled',
                tostring(activeDamageStates.cold),
                tostring(activeDamageStates.bleeding),
                gate.lastHp))
        end
    end
end

local function IsRespawnGraceActive()
    return GetGameTimer() < respawnGraceUntil
end

-- COREX uses its own spawn pipeline, so the stock playerSpawned event is not
-- guaranteed to run after a death. Reset both the local damage flags and the
-- native health state at the two explicit COREX respawn boundaries instead.
local function ResetRespawnDamageState(ensureFullHealth)
    activeDamageStates.cold = false
    activeDamageStates.bleeding = false
    gate.enabled = false
    respawnGraceUntil = GetGameTimer() + RESPAWN_DAMAGE_GRACE_MS

    -- The regen blocker writes zero while damage is active. Restore GTA's
    -- defaults explicitly so those native values cannot leak across death.
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 0.5)

    local ped = PlayerPedId()
    if ped and ped ~= 0 and DoesEntityExist(ped) then
        if ensureFullHealth then
            SetEntityMaxHealth(ped, RESPAWN_FULL_HEALTH)
            SetEntityHealth(ped, RESPAWN_FULL_HEALTH)
            ClearPedBloodDamage(ped)
            gate.lastHp = RESPAWN_FULL_HEALTH
        else
            gate.lastHp = GetEntityHealth(ped)
        end
    else
        gate.lastHp = RESPAWN_FULL_HEALTH
    end

    return not gate.enabled
        and not activeDamageStates.cold
        and not activeDamageStates.bleeding
        and (not ensureFullHealth or gate.lastHp == RESPAWN_FULL_HEALTH)
end

RegisterNetEvent('corex-death:client:prepareRespawn', function()
    return ResetRespawnDamageState(false)
end)

RegisterNetEvent('corex-death:client:respawnFinished', function()
    return ResetRespawnDamageState(true)
end)

-- ALWAYS-RUNNING blocker. Ticks every frame regardless of gate state — when
-- the gate is open, lastHp tracks HP normally; the moment the gate flips
-- on, the next frame catches any vanilla regen and reverts. While the gate
-- is on we also hammer the recharge native so engine regen stays disabled.
--
-- DEATH SAFETY: on the first frame after a respawn (dead → alive transition)
-- we always overwrite lastHp with the new full HP. Otherwise lastHp would
-- still hold the pre-death value (likely 0 or very low) and the blocker
-- would immediately murder the freshly-respawned player back to that value
-- — the "death loop" the user reported.
CreateThread(function()
    while not isReady do Wait(500) end
    local wasDead = true   -- start as 'dead' so first alive frame resets

    while true do
        local ped = PlayerPedId()
        if ped ~= 0 then
            local isDead = IsEntityDead(ped) or IsPedFatallyInjured(ped)

            if isDead then
                wasDead = true
            else
                local hp = GetEntityHealth(ped)

                -- Respawn / first alive frame: reset the snapshot. Without
                -- this the blocker would try to clamp the new full HP back
                -- down to the value the player had when they died.
                if wasDead then
                    wasDead = false
                    gate.lastHp = hp
                    if Config.Debug then
                        print(('^3[COREX-SURVIVAL]^7 respawn detected, resetting gate.lastHp=%d^0'):format(hp))
                    end
                elseif gate.enabled then
                    -- Lock engine regen every frame.
                    SetPlayerHealthRechargeMultiplier(PlayerId(), 0.0)
                    SetPlayerHealthRechargeLimit(PlayerId(), 0.0)

                    if hp > gate.lastHp then
                        SetEntityHealth(ped, gate.lastHp)
                    else
                        gate.lastHp = hp
                    end
                else
                    gate.lastHp = hp
                end
            end
        end
        Wait(0)
    end
end)

-- Bleed start/stop fire from the server. Toggle the regen gate.
RegisterNetEvent('corex-survival:client:onBleedStart', function()
    if IsRespawnGraceActive() then return end
    activeDamageStates.bleeding = true
    ApplyRegenGate()
end)
RegisterNetEvent('corex-survival:client:onBleedStop', function()
    activeDamageStates.bleeding = false
    ApplyRegenGate()
end)

-- Cold drives the gate via two paths:
--   1) state-bag change handler (instant reaction when cold value changes)
--   2) a 1-second poll on the player's metadata (insurance if the handler
--      ever misses an update, e.g. when entering scope or reconnecting).
-- We OR them together so as long as one path sees cold ≥ threshold, the
-- gate engages.
CreateThread(function()
    while not Corex do Wait(200) end
    while not NetworkIsPlayerActive(PlayerId()) do Wait(200) end
    local serverId = GetPlayerServerId(PlayerId())
    local playerBag = ('player:%s'):format(serverId)

    local function setColdActive(active)
        if active and IsRespawnGraceActive() then
            active = false
        end
        if active ~= activeDamageStates.cold then
            activeDamageStates.cold = active
            ApplyRegenGate()
        end
    end

    AddStateBagChangeHandler('cold', playerBag, function(_, _, value)
        local v = tonumber(value) or 0
        local threshold = (Config.Cold and Config.Cold.damageThreshold) or 70
        setColdActive(v >= threshold)
    end)

    -- Polling fallback — reads the state-bag (or metadata) directly. The
    -- state-bag handler should normally fire first, but if for any reason
    -- the bag isn't subscribed to (timing, scope, dropout), this loop keeps
    -- the gate honest.
    CreateThread(function()
        while true do
            Wait(1000)
            if isReady and Corex and Corex.Functions and Corex.Functions.GetMetaData then
                local meta = Corex.Functions.GetMetaData()
                local cold = (meta and tonumber(meta.cold)) or 0
                local threshold = (Config.Cold and Config.Cold.damageThreshold) or 70
                setColdActive(cold >= threshold)
            end
        end
    end)
end)

-- Optional cosmetic FX. The server fires these on enter/leave; we only do a
-- light timecycle tweak so the player visibly knows they're in a cold zone.
RegisterNetEvent('corex-survival:client:onColdEnter', function()
    SetTimecycleModifier('CAMERA_secuirity_FUZZ')
    SetTimecycleModifierStrength(0.25)
end)
RegisterNetEvent('corex-survival:client:onColdLeave', function()
    ClearTimecycleModifier()
end)

local ITEM_USE_PROGRESS = {
    food = {
        duration = 3500,
        label = 'Eating...',
        anim = { dict = 'anim@scripted@island@special_peds@pavel@hs4_pavel_ig5_caviar_p1', clip = 'base_idle' }
    },
    drink = {
        duration = 3000,
        label = 'Drinking...',
        anim = { dict = 'amb@world_human_drinking@coffee@male@idle_a', clip = 'idle_c' }
    },
    antidote = {
        duration = 4000,
        label = 'Using antidote...',
        anim = { dict = 'anim@amb@nightclub@peds@', clip = 'amb_medic_standing_timeofdeath_base' }
    },
    painkillers = {
        duration = 4000,
        label = 'Using painkillers...',
        anim = { dict = 'anim@amb@nightclub@peds@', clip = 'amb_medic_standing_timeofdeath_base' }
    },
    antibiotics = {
        duration = 4000,
        label = 'Using antibiotics...',
        anim = { dict = 'anim@amb@nightclub@peds@', clip = 'amb_medic_standing_timeofdeath_base' }
    },
    bandage = {
        duration = 4000,
        label = 'Using bandage...',
        anim = { dict = 'anim@amb@nightclub@peds@', clip = 'amb_medic_standing_timeofdeath_base' }
    },
    medkit = {
        duration = 6000,
        label = 'Using medkit...',
        anim = { dict = 'anim@amb@nightclub@peds@', clip = 'amb_medic_standing_timeofdeath_base' }
    }
}

local function GetItemUseProgress(itemName, itemConfig)
    if itemName == 'bandage' or itemName == 'medkit' or itemName == 'antidote' or itemName == 'painkillers' or itemName == 'antibiotics' then
        return ITEM_USE_PROGRESS[itemName]
    end

    if itemConfig.stat == 'hunger' then
        return ITEM_USE_PROGRESS.food
    end

    if itemConfig.stat == 'thirst' then
        return ITEM_USE_PROGRESS.drink
    end

    return ITEM_USE_PROGRESS[itemName]
end

RegisterNetEvent('corex-inventory:client:useItem', function(itemName, itemData)
    if not isReady then return end

    local itemConfig = Config.Items[itemName]
    if not itemConfig then return end

    local progress = GetItemUseProgress(itemName, itemConfig)
    TriggerEvent('corex-inventory:client:close')

    local completed = lib.progressBar({
        duration = progress.duration,
        label = progress.label,
        useWhileDead = false,
        canCancel = true,
        disable = {
            move = false,
            car = false,
            combat = true,
            mouse = false
        },
        anim = progress.anim
    })

    if completed then
        TriggerServerEvent('corex-survival:server:useItem', itemName)
    else
        TriggerEvent('ox_lib:notify', { description = 'Action canceled.', type = 'error' })
    end
end)

-- Compatibility fallback for resources that still emit the stock spawn event.
-- The explicit COREX lifecycle events above remain the authoritative path.
AddEventHandler('playerSpawned', function()
    SetTimeout(500, function()
        ResetRespawnDamageState(false)
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    -- Restore vanilla regen so the player isn't stuck without it if the
    -- resource crashes or is hot-reloaded.
    SetPlayerHealthRechargeMultiplier(PlayerId(), 1.0)
    SetPlayerHealthRechargeLimit(PlayerId(), 0.5)

    ClearTimecycleModifier()
    StopGameplayCamShaking(true)
    ResetPedMovementClipset(Corex.Functions.GetPed(), 0.0)

    effectsActive = false
    isReady = false
end)
