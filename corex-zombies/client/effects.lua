-- ═══════════════════════════════════════════════════════════════
-- COREX Zombies · Effects (lights, eye glow, vignette, heartbeat,
--                           safe-zone exit cue)
--
-- All rendering + screen fx that make the zombies feel scary.
-- Thread is adaptive: Wait(0) only when something is drawing,
-- Wait(250) when idle. Guarded by on-screen / distance checks so
-- we don't light-cast every zombie in the world.
-- ═══════════════════════════════════════════════════════════════

ZX = ZX or {}
ZX.Effects = {}

-- Public flag: set by main.lua's safe-zone exit handler; effects
-- thread picks it up and draws the tint overlay for exitCue.duration.
local exitCueUntil = 0

local function Cfg() return (Config and Config.Fear) or {} end

-- The live activeZombies collection is owned by main.lua.
-- One pass per render tick: reuse each live zombie's position for lights,
-- eye glow, nearest-distance vignette and heartbeat population.
local function DrawZombieEffects(playerCoords, now)
    local cfg = Cfg()
    local lightMap = cfg.lightDraw
    local lightMax2 = (cfg.lightDrawMaxDist or 40.0) ^ 2
    local eyeColor = cfg.eyeGlowColor
    if eyeColor and cfg.eyeGlowNightOnly then
        local hour = GetClockHours()
        if hour < 22 and hour >= 5 then eyeColor = nil end
    end
    local eyeMax2 = (cfg.eyeGlowMaxDist or 25.0) ^ 2
    local heartbeatMax2 = (cfg.heartbeatRadius or 20.0) ^ 2
    local best2, count = math.huge, 0

    for _, z in ipairs(activeZombies) do
        if not z.isDead and DoesEntityExist(z.entity) then
            local coords = GetEntityCoords(z.entity)
            local dx, dy, dz = coords.x - playerCoords.x, coords.y - playerCoords.y, coords.z - playerCoords.z
            local distance2 = dx * dx + dy * dy + dz * dz
            if distance2 < best2 then best2 = distance2 end
            if distance2 <= heartbeatMax2 then count = count + 1 end

            local td = z.typeData
            local color = td and td.lightColor
            local light = color and lightMap and lightMap[td.id or '']
            local drawLight = light and distance2 <= lightMax2
            local drawEyes = eyeColor and distance2 <= eyeMax2
            if (drawLight or drawEyes) and IsEntityOnScreen(z.entity) then
                if drawLight then
                    local intensity = light.intensity or 6.0
                    if td.id == 'electric' then
                        local flicker = math.sin(now * 0.015) * 0.3 + math.sin(now * 0.037) * 0.2
                        intensity = intensity * (1.0 + flicker)
                    end
                    DrawLightWithRange(coords.x, coords.y, coords.z + 0.9,
                        color.r or 255, color.g or 255, color.b or 255,
                        light.range or 4.0, intensity)
                end
                if drawEyes then
                    local head = GetPedBoneCoords(z.entity, 0x796E, 0.0, 0.08, 0.0)
                    if head then
                        DrawLightWithRange(head.x, head.y, head.z,
                            eyeColor.r, eyeColor.g, eyeColor.b,
                            cfg.eyeGlowRange or 1.2, cfg.eyeGlowIntensity or 3.0)
                    end
                end
            end
        end
    end

    if cfg.fearVignetteEnabled == false then return 0, count end
    local maxD = cfg.vignetteMaxDist or 30.0
    if best2 >= maxD * maxD then return 0, count end
    local best = math.sqrt(best2)
    local startD = cfg.vignetteStartDist or 5.0
    local maxA = cfg.vignetteMaxAlpha or 64
    if best <= startD then return maxA, count end
    local t = (maxD - best) / (maxD - startD)
    return math.floor(maxA * t), count
end

-- Heartbeat pulse modifier added on top of the base fear vignette.
-- Returns (addAlpha, audioIntensity 0-1) — caller applies both.
local function ComputeHeartbeat(count, now)
    local cfg = Cfg()
    local minCount = cfg.heartbeatMinZombies or 3

    if count < minCount then return 0, 0.0 end

    -- Sin oscillation at ~1.1 Hz base, faster as count grows (up to 1.8 Hz).
    local rate = math.min(1.8, 1.1 + (count - minCount) * 0.1)
    local phase = (now * rate * 0.001) % (2 * math.pi)
    local pulse = (math.sin(phase) + 1) * 0.5   -- 0..1

    -- Heartbeat adds up to 32 extra alpha on top of fear vignette.
    return math.floor(pulse * 32), math.min(1.0, (count - minCount) / 6)
end

-- Trigger the safe-zone exit overlay for `Config.Fear.exitCue.duration`.
function ZX.Effects.StartExitCue()
    local cfg = Cfg()
    local d = (cfg.exitCue and cfg.exitCue.duration) or 3000
    exitCueUntil = GetGameTimer() + d
end

-- Render pass ────────────────────────────────────────────────────
CreateThread(function()
    while not Corex or not Corex.Functions do Wait(500) end

    while true do
        -- No active zombies AND no exit cue → idle slow tick.
        local hasZombies = activeZombies and #activeZombies > 0
        local now = GetGameTimer()
        local hasExitCue = now < exitCueUntil
        if not hasZombies and not hasExitCue then
            Wait(250)
            goto continue
        end

        local baseAlpha, heartbeatCount = 0, 0
        if hasZombies then
            local playerCoords = GetEntityCoords(PlayerPedId())
            baseAlpha, heartbeatCount = DrawZombieEffects(playerCoords, now)
        end

        local fearEnabled = Cfg().fearVignetteEnabled ~= false
        local hbAlpha, hbIntensity = 0, 0.0
        if hasZombies then
            hbAlpha, hbIntensity = ComputeHeartbeat(heartbeatCount, now)
        end
        local fearAlpha = math.max(baseAlpha, baseAlpha + hbAlpha)
        if fearEnabled and fearAlpha > 0 then
            local cfg = Cfg()
            local c = cfg.vignetteColor or { r = 90, g = 10, b = 10 }
            DrawRect(0.5, 0.5, 2.0, 2.0, c.r, c.g, c.b, fearAlpha)
        end

        -- Exit cue overlay (desaturated warm tint, 3s).
        if hasExitCue then
            local cfg = Cfg()
            local tc = (cfg.exitCue and cfg.exitCue.tintColor) or { r = 40, g = 30, b = 30, a = 45 }
            DrawRect(0.5, 0.5, 2.0, 2.0, tc.r, tc.g, tc.b, tc.a or 45)
        end

        -- Drive heartbeat audio via audio.lua when pulse is significant.
        if hbIntensity > 0.2 and ZX.Audio and ZX.Audio.PlayHeartbeat then
            ZX.Audio.PlayHeartbeat(hbIntensity, now)
        end

        local renderWait = Cfg().renderWaitMs
        Wait(renderWait ~= nil and renderWait or 0)
        ::continue::
    end
end)

-- Hook safe-zone exit to trigger exit cue + distant moan.
AddEventHandler('corex-zones:client:leftSafeZone', function(zone)
    ZX.Effects.StartExitCue()
    if ZX.Audio and ZX.Audio.PlayDistantMoan then
        local cfg = (Config and Config.Fear and Config.Fear.exitCue) or {}
        SetTimeout(cfg.moanDelayMs or 800, function()
            ZX.Audio.PlayDistantMoan()
        end)
    end
end)
