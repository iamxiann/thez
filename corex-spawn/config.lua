--[[
    COREX Spawn - Configuration
]]

Config = {}
Config.Debug = false

-------------------------------------------------
-- Spawn Settings
-------------------------------------------------

-- موقع السبون للاعبين الجدد (أول مرة)  
Config.FirstSpawnLocation = {
    x = -1366.5393,
    y = 56.6998,
    z = 54.0984,
    heading = 97.3085
}


-- موقع السبون العادي (بعد الموت أو إعادة الاتصال)
Config.DefaultSpawnLocation = {
    x = -1366.5393,
    y = 56.6998,
    z = 54.0984,
    heading = 97.3085
}

-- هل يتم حفظ آخر موقع للاعب؟
Config.SaveLastLocation = true

-- الكاميرا يتم حسابها تلقائياً بناءً على موقع اللاعب

-------------------------------------------------
-- Character Model Defaults
-------------------------------------------------
Config.DefaultMaleModel = 'mp_m_freemode_01'

