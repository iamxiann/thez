fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'ABUGIZA'
description 'COREX Safe Zones System'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@PolyZone/client.lua', -- PolyZone core (pure-Lua point-in-polygon math, safe to run client+server)
    'config.lua',
    'shared/zones.lua'
}

client_scripts {
    'client/main.lua',
    'client/creator.lua'
}

server_scripts {
    'server/main.lua',
    'server/creator.lua'
}

dependencies {
    'corex-core',
    'PolyZone',
    'ox_lib'
}

exports {
    'IsPlayerInSafeZone',
    'GetPlayerZone',
    'GetSafeZones',
    'IsCoordsInSafeZone',
    'GetSafeZoneDistance'
}
