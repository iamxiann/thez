local Corex = nil

local function Notify(src, message, ntype, duration)
    TriggerClientEvent('ox_lib:notify', src, { description = message, type = ntype or 'info', duration = duration })
end

local infectionTimers = {}
local painkillerTimers = {}
local lastDrainTick = {}
local lastUseItem = {}
local USE_ITEM_COOLDOWN = 500

-- Pull modifiers from corex-skills if it's running. Returns a neutral table
-- when the resource is missing so callers can multiply blindly.
local NEUTRAL_MODS = {
    infectionGrowth = 1.0, hungerDrain = 1.0, thirstDrain = 1.0,
    biteChance = 1.0, plagueResist = 0.0, biteImmunity = false,
    bandageHeal = 1.0, antibioticPower = 1.0
}

local function GetSkillMods(src)
    local ok, mods = pcall(function()
        return exports['corex-skills']:GetModifiers(src)
    end)
    if ok and type(mods) == 'table' then return mods end
    return NEUTRAL_MODS
end

local function InitCore()
    local success, core = pcall(function()
        return exports['corex-core']:GetCoreObject()
    end)
    if not success or not core or not core.Functions then return false end
    Corex = core
    return true
end

local function OnCoreReady()
    if Config.Debug then print('[COREX-SURVIVAL] ^2Server survival system initialized^0') end
end

if not InitCore() then
    AddEventHandler('corex:server:coreReady', function(coreObj)
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
    OnCoreReady()
end

local function SyncStat(source, statName, value)
    local pState = Player(source).state
    if not pState then return end
    pState:set(statName, value, true)
end

local function GetStat(source, statName)
    if not Corex then return 0 end
    return Corex.Functions.GetStat(source, statName) or 0
end

local function SetStat(source, statName, value)
    if not Corex then return false end
    return Corex.Functions.SetStat(source, statName, value)
end

local function StartInfectionGrowth(source)
    -- Marker only — a single consolidated thread below ticks all infected players.
    -- Previously this spawned one CreateThread per infected player; at 20 infected
    -- players that was 20 independent scheduler entries. Now it's one.
    infectionTimers[source] = true
end

local function StopInfectionGrowth(source)
    infectionTimers[source] = nil
end

-- Consolidated infection tick — single thread iterates all infected players.
CreateThread(function()
    while not Corex do Wait(500) end

    while true do
        Wait(Config.Infection.growthInterval)

        for source, active in pairs(infectionTimers) do
            if active then
                local player = Corex.Functions.GetPlayer(source)
                if not player then
                    infectionTimers[source] = nil
                elseif not painkillerTimers[source] then
                    local infection = GetStat(source, 'infection')
                    if infection <= 0 then
                        infectionTimers[source] = nil
                    else
                        -- Skill modifier: hardened-immunity branch slows infection growth.
                        local mods = GetSkillMods(source)
                        local growth = Config.Infection.growthRate * (mods.infectionGrowth or 1.0)
                        local newInfection = math.min(100, infection + growth)
                        SetStat(source, 'infection', newInfection)

                        if newInfection >= 100 then
                            Corex.Functions.SetPlayerHealth(source, 0)
                            Notify(source, 'The infection has consumed you...', 'error', 5000)
                            infectionTimers[source] = nil
                        end
                    end
                end
            end
        end
    end
end)

local function StartPainkillerTimer(source, duration)
    painkillerTimers[source] = true

    CreateThread(function()
        Wait(duration)
        painkillerTimers[source] = nil
        local player = Corex.Functions.GetPlayer(source)
        if player then
            Notify(source, 'Painkillers are wearing off...', 'warning', 3000)
        end
    end)
end

-- Anti-cheat: minimum interval between drain ticks (80% of configured interval)
local MIN_DRAIN_INTERVAL = Config.Hunger.tickInterval * 0.8

RegisterNetEvent('corex-survival:server:drainTick', function()
    local src = source
    if not Corex then return end

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local now = Corex.Functions.GetGameTimer()
    if lastDrainTick[src] and (now - lastDrainTick[src]) < MIN_DRAIN_INTERVAL then
        return
    end
    lastDrainTick[src] = now

    local hunger = GetStat(src, 'hunger')
    local thirst = GetStat(src, 'thirst')

    -- Skill modifier: iron-stomach / camel-body slow hunger and thirst drain.
    local mods = GetSkillMods(src)
    local newHunger = math.max(0, hunger - Config.Hunger.drainRate * (mods.hungerDrain or 1.0))
    local newThirst = math.max(0, thirst - Config.Thirst.drainRate * (mods.thirstDrain or 1.0))

    SetStat(src, 'hunger', newHunger)
    SetStat(src, 'thirst', newThirst)
end)

local lastZombieHit = {}
local ZOMBIE_HIT_COOLDOWN = 2000

RegisterNetEvent('corex-survival:server:zombieHit', function()
    local src = source
    if not Corex or not Config.Infection.enabled then return end

    local now = Corex.Functions.GetGameTimer()
    if lastZombieHit[src] and (now - lastZombieHit[src]) < ZOMBIE_HIT_COOLDOWN then return end
    lastZombieHit[src] = now

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local currentInfection = GetStat(src, 'infection')
    if currentInfection > 0 then return end

    -- Bite chance roll happens here (server-authoritative). Skills can either
    -- multiply biteChance (1.0 → 0.5 with s_plague) or grant biteImmunity
    -- (s_immunity), in which case bites never cause infection.
    local mods = GetSkillMods(src)
    if mods.biteImmunity then
        Notify(src, 'You shrugged off the bite.', 'info', 2500)
        return
    end

    local effectiveChance = (Config.Infection.biteChance or 0) * (mods.biteChance or 1.0)
    if math.random() > effectiveChance then
        return
    end

    local startValue = Config.Infection.growthRate
    SetStat(src, 'infection', startValue)
    Notify(src, 'You have been infected!', 'error', 5000)
    StartInfectionGrowth(src)
end)

RegisterNetEvent('corex-survival:server:useItem', function(itemName)
    local src = source
    if not Corex then return end
    if type(itemName) ~= 'string' then return end

    local now = Corex.Functions.GetGameTimer()
    if lastUseItem[src] and (now - lastUseItem[src]) < USE_ITEM_COOLDOWN then return end
    lastUseItem[src] = now

    local player = Corex.Functions.GetPlayer(src)
    if not player then return end

    local itemConfig = Config.Items[itemName]
    if not itemConfig then return end

    -- Read crafted-quality metadata BEFORE consumption so we can scale the
    -- effect. Items crafted with k_solid / k_master carry a qualityBonus.
    local craftQuality = 0.0
    local metaOk, meta = pcall(function()
        return exports['corex-inventory']:GetItemMeta(src, itemName)
    end)
    if metaOk and type(meta) == 'table' and tonumber(meta.qualityBonus) then
        craftQuality = tonumber(meta.qualityBonus) or 0.0
    end
    local qualityMul = 1.0 + craftQuality   -- 1.0 = vanilla; 1.30 with k_solid; 1.495 stacked

    local removeOk, removed = pcall(function()
        return exports['corex-inventory']:RemoveItem(src, itemName, 1)
    end)

    if not removeOk or not removed then
        Notify(src, 'You do not have this item', 'error', 2000)
        return
    end

    if itemConfig.stat == 'hunger' then
        -- qualityMul scales food crafted with k_solid / k_master (more nutritious).
        local current = GetStat(src, 'hunger')
        local amount = math.floor((tonumber(itemConfig.amount) or 0) * qualityMul)
        local newVal = math.min(Config.Hunger.maxValue, current + amount)
        SetStat(src, 'hunger', newVal)
        Notify(src, 'Hunger restored (+' .. amount .. ')', 'success', 2000)

    elseif itemConfig.stat == 'thirst' then
        local current = GetStat(src, 'thirst')
        local amount = math.floor((tonumber(itemConfig.amount) or 0) * qualityMul)
        local newVal = math.min(Config.Thirst.maxValue, current + amount)
        SetStat(src, 'thirst', newVal)
        Notify(src, 'Thirst restored (+' .. amount .. ')', 'success', 2000)

    elseif itemConfig.stat == 'health' then
        if itemConfig.fullHeal then
            Corex.Functions.SetPlayerHealth(src, 200)
            Notify(src, 'Fully healed', 'success', 2000)
        else
            -- Skill modifier: field-medic / bandageHeal scales heal amount.
            -- Quality multiplier (k_solid / k_master) stacks on top.
            local mods = GetSkillMods(src)
            local amount = math.floor((tonumber(itemConfig.amount) or 0) * (mods.bandageHeal or 1.0) * qualityMul)
            TriggerClientEvent('corex-survival:client:applyHealthDelta', src, amount)
            Notify(src, 'Health restored (+' .. amount .. ')', 'success', 2000)
        end
        -- Any health item also stops an active bleed (consumed by s_bleed system).
        TriggerEvent('corex-survival:server:onBandageUsed', src)

    elseif itemConfig.stat == 'infection' then
        if itemConfig.cure then
            -- Capture old infection BEFORE wiping it so the XP award knows
            -- whether this was a meaningful save (>= 50%).
            local oldInfection = GetStat(src, 'infection')
            SetStat(src, 'infection', 0)
            StopInfectionGrowth(src)
            painkillerTimers[src] = nil
            Notify(src, 'Infection cured!', 'success', 3000)
            TriggerEvent('corex-survival:server:onInfectionCured', src, oldInfection)

        elseif itemConfig.pause then
            StartPainkillerTimer(src, itemConfig.pause)
            Notify(src, 'Painkillers active - infection paused', 'info', 3000)

        elseif itemConfig.reduce then
            -- Skill modifier: pharmacist / antibioticPower scales the cure amount.
            -- Stacks with quality bonus from the crafter.
            local mods = GetSkillMods(src)
            local reduce = math.floor((tonumber(itemConfig.reduce) or 0) * (mods.antibioticPower or 1.0) * qualityMul)
            local current = GetStat(src, 'infection')
            local newVal = math.max(0, current - reduce)
            SetStat(src, 'infection', newVal)
            if newVal <= 0 then
                StopInfectionGrowth(src)
                if current >= 50 then
                    TriggerEvent('corex-survival:server:onInfectionCured', src, current)
                end
            end
            Notify(src, 'Infection reduced (-' .. reduce .. ')', 'success', 3000)
        end
    end

    if itemConfig.infectionRisk and Config.Infection.enabled then
        local roll = math.random()
        if roll <= itemConfig.infectionRisk then
            local currentInfection = GetStat(src, 'infection')
            if currentInfection <= 0 then
                SetStat(src, 'infection', Config.Infection.growthRate)
                Notify(src, 'You feel sick...', 'warning', 4000)
                StartInfectionGrowth(src)
            end
        end
    end
end)

-- Player ready: start infection growth if already infected
AddEventHandler('corex:server:playerReady', function(source, player)
    if not Config.Infection.enabled then return end

    local infection = player.metadata and player.metadata.infection or 0
    if infection > 0 then
        StartInfectionGrowth(source)
    end
end)

-- =============================================================================
-- Bleeding subsystem (skill: s_bleed -> mods.bleedRate)
-- =============================================================================
-- A single damage event >= Config.Bleed.hitThreshold flips the player into
-- "bleeding". HP drains over time until either:
--   * Config.Bleed.durationMs elapses, OR
--   * the player consumes a health item (bandage / medkit) — handled in the
--     useItem handler above where we already detect itemConfig.stat='health'.
-- bleedRate modifier scales the time between drain ticks (lower = stops faster).
local coldState = {}  -- [src] = { lastTickAt, inZoneAt, notifiedDamage }
local bleedState = BleedingState.New()
local bleedingPlayers = bleedState.players  -- [src] = { startedAt = ms, lastDrainAt = ms }

local function StartBleeding(src)
    if not Config.Bleed or not Config.Bleed.enabled then return end
    if not BleedingState.Start(bleedState, src, GetGameTimer()) then return end
    if Config.Bleed.notifyOnStart and Corex and Corex.Functions then
        Notify(src, 'You are bleeding — find a bandage!', 'error', 4500)
    end
    TriggerClientEvent('corex-survival:client:onBleedStart', src)
end

local function StopBleeding(src, silent)
    if not BleedingState.Stop(bleedState, src) then return end
    if not silent and Corex and Corex.Functions then
        Notify(src, 'Bleeding has stopped.', 'success', 3000)
    end
    TriggerClientEvent('corex-survival:client:onBleedStop', src)
end

local function ResetPlayerDamageState(src)
    src = tonumber(src)
    if not src then return false end

    local wasBleeding = BleedingState.IsBleeding(bleedState, src)
    StopBleeding(src, true)
    BleedingState.Reset(bleedState, src)
    coldState[src] = nil

    SetStat(src, 'cold', 0)
    SetStat(src, 'bleeding', 0)
    SyncStat(src, 'cold', 0)
    SyncStat(src, 'bleeding', 0)

    -- Force both client flags off even when the server table was already
    -- empty, which is exactly the stale-client case seen after a reconnect.
    if not wasBleeding then
        TriggerClientEvent('corex-survival:client:onBleedStop', src)
    end
    TriggerClientEvent('corex-survival:client:onColdLeave', src)
    return true, wasBleeding
end

exports('ResetPlayerDamageState', ResetPlayerDamageState)

-- The client supplies two HP samples. The server verifies the reported final
-- sample against the authoritative ped health and rate-limits accepted reports.
RegisterNetEvent('corex-survival:server:reportHit', function(beforeHealth, afterHealth)
    local src = source
    if not Config.Bleed or not Config.Bleed.enabled then return end

    local ped = GetPlayerPed(src)
    if not ped or ped == 0 then return end
    local serverHealth = GetEntityHealth(ped)
    local valid = BleedingState.ValidateDamageReport(
        beforeHealth,
        afterHealth,
        serverHealth,
        Config.Bleed.hitThreshold or 30,
        Config.Bleed.maxReportedDamage or 200,
        Config.Bleed.healthTolerance or 8,
        serverHealth > 100
    )
    if not valid then return end
    if not BleedingState.AcceptReport(
        bleedState, src, GetGameTimer(), Config.Bleed.reportCooldown or 750
    ) then return end
    StartBleeding(src)
end)

-- Bleed tick: drains HP for everyone currently bleeding.
CreateThread(function()
    while not Corex do Wait(500) end
    while true do
        Wait(1500)
        if not Config.Bleed or not Config.Bleed.enabled then
            -- check again later in case it gets toggled
            Wait(5000)
        else
            local now = GetGameTimer()
            for src, st in pairs(bleedingPlayers) do
                local ped = GetPlayerPed(src)
                if not ped or ped == 0 or GetEntityHealth(ped) <= 100 then
                    StopBleeding(src, true)
                elseif (now - st.startedAt) > (Config.Bleed.durationMs or 120000) then
                    StopBleeding(src, false)
                else
                    local mods = GetSkillMods(src)
                    local rate = mods.bleedRate or 1.0  -- lower = drains slower & ends sooner
                    local effectiveTick = (Config.Bleed.tickInterval or 5000) / math.max(0.1, rate)
                    if (now - st.lastDrainAt) >= effectiveTick then
                        st.lastDrainAt = now
                        local drain = math.floor((Config.Bleed.drainPerTick or 2) * rate)
                        if drain > 0 then
                            TriggerClientEvent('corex-survival:client:applyHealthDelta', src, -drain)
                        end
                    end
                end
            end
        end
    end
end)

-- Stop bleed automatically when the player consumes any health item.
-- (Wired into the existing useItem handler.)
AddEventHandler('corex-survival:server:onBandageUsed', function(src)
    StopBleeding(src, false)
end)

-- corex-death emits this local server event for every normal and emergency death.
-- Clearing here prevents a reconnect/respawn from inheriting a stale bleed.
AddEventHandler('corex-spawn:server:playerDied', function(src)
    ResetPlayerDamageState(src)
end)

-- =============================================================================
-- Cold subsystem (skill: s_cold -> mods.coldDamage)
-- =============================================================================
-- Cold is a 0..100 stat (mirrors hunger/thirst/infection). It rises while
-- the player is in a cold zone, decays while they're out. When it crosses
-- Config.Cold.damageThreshold, HP starts dropping. The HUD's blue snowflake
-- meter is driven by the existing 'cold' state-bag key, so just keeping the
-- stat updated server-side is enough for the visual.
local function IsInColdArea(coords)
    if not Config.Cold or not Config.Cold.enabled then return false, 1.0 end
    if not coords then return false, 1.0 end
    if coords.z and coords.z >= (Config.Cold.altitudeThreshold or 600.0) then
        return true, 1.0
    end
    for _, zone in ipairs(Config.Cold.ColdZones or {}) do
        local zc = zone.coords
        if zc then
            local dx, dy, dz = coords.x - zc.x, coords.y - zc.y, (coords.z or 0) - (zc.z or 0)
            local r = zone.radius or 100.0
            if (dx*dx + dy*dy + dz*dz) <= (r * r) then
                return true, (zone.riseBoost or 1.0)
            end
        end
    end
    return false, 1.0
end

RegisterNetEvent('corex-survival:server:reportColdCheck', function(coords)
    local src = source
    if not Config.Cold or not Config.Cold.enabled then return end
    if type(coords) ~= 'vector3' and type(coords) ~= 'table' then return end

    local now = GetGameTimer()
    local st = coldState[src] or { lastTickAt = 0, inZoneAt = nil, notifiedDamage = false }
    coldState[src] = st

    -- Server-side rate limit: ignore reports faster than the configured tick.
    if (now - st.lastTickAt) < ((Config.Cold.tickInterval or 5000) - 500) then return end
    st.lastTickAt = now

    local inCold, riseBoost = IsInColdArea(coords)
    local mods = GetSkillMods(src)
    local coldMul = mods.coldDamage or 1.0   -- s_cold = 0.5 → halves rise + damage

    local cur = GetStat(src, 'cold') or 0
    local maxVal = Config.Cold.maxValue or 100

    if inCold then
        -- Entering / staying in cold zone: stat ticks UP (slower with s_cold).
        if not st.inZoneAt then
            st.inZoneAt = now
            if Config.Cold.notifyOnEnter and Corex and Corex.Functions then
                Notify(src, 'You are entering a cold area...', 'warning', 3500)
            end
            TriggerClientEvent('corex-survival:client:onColdEnter', src)
        end
        local rise = math.max(1, math.floor((Config.Cold.riseRate or 4) * coldMul * (riseBoost or 1.0)))
        local newVal = math.min(maxVal, cur + rise)
        SetStat(src, 'cold', newVal)

        -- Above the damage threshold? HP starts dropping (also halved by s_cold).
        if newVal >= (Config.Cold.damageThreshold or 70) then
            local dmg = math.max(1, math.floor((Config.Cold.damagePerTick or 3) * coldMul))
            TriggerClientEvent('corex-survival:client:applyHealthDelta', src, -dmg)
            if not st.notifiedDamage and Config.Cold.notifyOnDamage and Corex and Corex.Functions then
                Notify(src, 'You are freezing! Find shelter!', 'error', 4000)
                st.notifiedDamage = true
            end
        end
    else
        -- Out of cold: the stat decays to zero so the HUD meter empties.
        if cur > 0 then
            local newVal = math.max(0, cur - (Config.Cold.decayRate or 6))
            SetStat(src, 'cold', newVal)
        end
        if st.inZoneAt then
            st.inZoneAt = nil
            st.notifiedDamage = false
            TriggerClientEvent('corex-survival:client:onColdLeave', src)
        end
    end
end)

-- Cleanup on player drop
AddEventHandler('playerDropped', function()
    local src = source
    infectionTimers[src] = nil
    painkillerTimers[src] = nil
    lastDrainTick[src] = nil
    lastUseItem[src] = nil
    lastZombieHit[src] = nil
    BleedingState.Reset(bleedState, src)
    coldState[src] = nil
end)

-- Admin commands
RegisterCommand('setstat', function(source, args)
    local src = source
    if src > 0 and not (Corex.Functions.IsPlayerAceAllowed(src, 'corex.admin') or Corex.Functions.IsPlayerAceAllowed(src, 'corex.survival.admin')) then return end

    local targetId = tonumber(args[1])
    local statName = args[2]
    local value = tonumber(args[3])

    if not targetId or not statName or not value then
        if src > 0 then
            Notify(src, 'Usage: /setstat [id] [hunger/thirst/infection] [value]', 'info')
        else
            print('Usage: setstat [id] [hunger/thirst/infection] [value]')
        end
        return
    end

    if not Corex.Functions.GetPlayer(targetId) then
        local msg = 'Player ' .. targetId .. ' not found'
        if src > 0 then Notify(src, msg, 'error') else print(msg) end
        return
    end

    local success = SetStat(targetId, statName, value)
    if success then
        local msg = 'Set ' .. statName .. ' to ' .. value .. ' for player ' .. targetId
        if src > 0 then Notify(src, msg, 'success') else print(msg) end

        if statName == 'infection' then
            if value > 0 then
                StartInfectionGrowth(targetId)
            else
                StopInfectionGrowth(targetId)
                painkillerTimers[targetId] = nil
            end
        end
    end
end, true)

exports('GetPlayerHunger', function(source) return GetStat(source, 'hunger') end)
exports('GetPlayerThirst', function(source) return GetStat(source, 'thirst') end)
exports('GetPlayerInfection', function(source) return GetStat(source, 'infection') end)
exports('SetPlayerHunger', function(source, value) return SetStat(source, 'hunger', value) end)
exports('SetPlayerThirst', function(source, value) return SetStat(source, 'thirst', value) end)
exports('SetPlayerInfection', function(source, value)
    local result = SetStat(source, 'infection', value)
    if result then
        if value > 0 then
            StartInfectionGrowth(source)
        else
            StopInfectionGrowth(source)
        end
    end
    return result
end)
exports('IsInfectionPaused', function(source) return painkillerTimers[source] == true end)

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    infectionTimers = {}
    painkillerTimers = {}
    lastDrainTick = {}
    lastUseItem = {}
end)
