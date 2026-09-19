Config = {}
Config.Debug = false

Config.Hunger = {
    maxValue = 100,
    drainRate = 0.15,
    tickInterval = 30000,
    effectThreshold = 25,
    damageThreshold = 5,
    damageAmount = 3
}

Config.Thirst = {
    maxValue = 100,
    drainRate = 0.20,
    tickInterval = 30000,
    effectThreshold = 25,
    damageThreshold = 5,
    damageAmount = 4
}

Config.Infection = {
    enabled = true,
    biteChance = 0.15,
    growthRate = 0.5,
    growthInterval = 60000,
    stages = {
        { threshold = 25, effects = {'shake'} },
        { threshold = 50, effects = {'shake', 'slowness'} },
        { threshold = 75, effects = {'shake', 'slowness', 'cough', 'screenDistort'} },
        { threshold = 100, effects = {'death'} }
    },
}

Config.Effects = {
    shakeIntensity = 0.3,
    slowMultiplier = 0.7,
    screenDistortStrength = 0.3,
    coughDict = 'mp_player_intdrink',
    coughAnim = 'loop_bottle',
    coughDuration = 2000,
    coughCooldown = 15000,
}

-- =============================================================================
-- Cold (consumed by skill `s_cold` via mods.coldDamage)
-- =============================================================================
-- Cold accumulates as a 0..100 stat (just like hunger/thirst/infection). It
-- ticks UP while in a cold zone, ticks DOWN once the player leaves. Once it
-- crosses Config.Cold.damageThreshold, HP starts dropping every tick.
-- The stat is shown live on the HUD's blue snowflake meter (corex-hud).
-- s_cold halves the rise rate AND halves the HP damage at the threshold.
Config.Cold = {
    enabled            = true,
    tickInterval       = 5000,    -- check every 5s

    -- Stat behaviour
    riseRate           = 4,       -- +N per tick while inside a cold zone
    decayRate          = 6,       -- -N per tick while outside
    damageThreshold    = 70,      -- once cold >= 70, HP starts dropping
    damagePerTick      = 3,       -- HP lost per tick when above the threshold
    maxValue           = 100,

    -- Detection
    altitudeThreshold  = 600.0,   -- meters z; ~Mt Chiliad summit area
    notifyOnEnter      = true,
    notifyOnDamage     = true,

    -- Optional explicit cold polygons. Each entry: { coords = vec3, radius = m, riseBoost = 1.0 }
    ColdZones = {
        -- Example: { coords = vec3(450.0, 5570.0, 780.0), radius = 800.0, riseBoost = 1.0 },
    }
}

-- =============================================================================
-- Bleeding (consumed by skill `s_bleed` via mods.bleedRate, stopped by bandage)
-- =============================================================================
-- A single hit above HitThreshold flips the player into "bleeding". HP then
-- drains at DrainPerTick / bleedRate-mod every TickInterval ms until a bandage
-- (or any health item) is consumed, OR until BleedDurationMs elapses.
Config.Bleed = {
    enabled         = true,
    hitThreshold    = 30,         -- single damage event >= 30 starts a bleed
    maxReportedDamage = 200,      -- reject impossible single-sample health deltas
    healthTolerance = 8,          -- allowed client/server HP sampling drift
    reportCooldown  = 750,        -- rate-limit damage reports per player
    tickInterval    = 5000,       -- 5s between drains
    drainPerTick    = 2,          -- 2 HP lost per tick
    durationMs      = 120000,     -- naturally stops after 2 minutes
    notifyOnStart   = true
}

Config.Items = {
    ['canned_food']  = { stat = 'hunger',    amount = 35 },
    ['raw_meat']     = { stat = 'hunger',    amount = 15,  infectionRisk = 0.10 },
    ['cooked_meat']  = { stat = 'hunger',    amount = 50 },
    ['clean_water']  = { stat = 'thirst',    amount = 40 },
    ['dirty_water']  = { stat = 'thirst',    amount = 20,  infectionRisk = 0.10 },
    ['energy_drink'] = { stat = 'thirst',    amount = 25 },
    ['bread']        = { stat = 'hunger',    amount = 20 },
    ['antidote']     = { stat = 'infection', cure = true },
    ['painkillers']  = { stat = 'infection', pause = 300000 },
    ['antibiotics']  = { stat = 'infection', reduce = 25 },
    ['bandage']      = { stat = 'health',    amount = 25 },
    ['medkit']       = { stat = 'health',    amount = 100, fullHeal = true },
}
