Config = Config or {}

-- Master switch for every command below (toggle in-game with /togglechat, admin only)
Config.DisableGlobalChat = false

-- Only messages sent through registered /commands are allowed.
Config.CommandsOnly = true

Config.ChatInitCooldown = 5000

-- Groups checked via IsPlayerAceAllowed for Permission = "admin"
Config.AdminGroups = { 'god', 'admin', 'helper', 'trial' }

-- Tampilan kartu chat per job. Nilai yang diubah boss melalui /chatjob
-- disimpan secara persisten dan akan menimpa default di bawah ini.
Config.JobChats = {
    gov = { Label = 'PEMERINTAH', TextColor = '#4ade80', OutlineColor = '#4ade80' },
    police = { Label = 'POLISI', TextColor = '#60a5fa', OutlineColor = '#60a5fa' },
    ambulance = { Label = 'EMS', TextColor = '#f87171', OutlineColor = '#f87171' },
    mechanic = { Label = 'MEKANIK', TextColor = '#fb923c', OutlineColor = '#fb923c' },
    resto = { Label = 'RESTO', TextColor = '#facc15', OutlineColor = '#facc15' },
    nightclub = { Label = 'NIGHTCLUB', TextColor = '#facc15', OutlineColor = '#facc15' },
}

-- /ooc - global out-of-character chat
Config.OOC = {
    Enabled = true,
    Command = 'ooc',
    TextColor = { 255, 255, 255 },       -- RGB
    BackgroundColor = { 0, 0, 0, 200 },  -- RGBA (alpha 0-255)
    Permission = 'user',                 -- "user" | "admin" | "job"
}

-- /adm - global admin announcement
Config.ADM = {
    Enabled = true,
    Command = 'adm',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 127, 29, 29, 220 },
    Permission = 'admin',
}

Config.GOV = {
    Enabled = true,
    Command = 'gov',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'gov' },
}

Config.POL = {
    Enabled = true,
    Command = 'pol',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'police' },
}

Config.EMS = {
    Enabled = true,
    Command = 'ems',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'ambulance' },
}

Config.MEC = {
    Enabled = true,
    Command = 'mec',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'mechanic' },
}

Config.REST = {
    Enabled = true,
    Command = 'rest',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'resto' },
}

Config.NC = {
    Enabled = true,
    Command = 'club',
    TextColor = { 255, 255, 255 },
    BackgroundColor = { 0, 0, 0, 200 },
    Permission = 'job',
    AllowedJobs = { 'nightclub' },
}

-- /me & /do - native 3D text above the character's head.
Config.ThreeDText = {
    Duration = 7000,
    FadeDuration = 900,
    Cooldown = 700,
    DrawDistance = 20.0,
    SyncDistance = 30.0,
    MaxLength = 180,
    MaxPerPlayer = 1,
    Height = 0.22,
    StackSpacing = 0.14,
    Scale = 0.34,
    MeColor = { 196, 139, 255, 255 },
    DoColor = { 92, 200, 255, 255 },
}

Config.ME = {
    Enabled = true,
    Command = 'me',
    Permission = 'user',
}

Config.DO = {
    Enabled = true,
    Command = 'do',
    Permission = 'user',
}
