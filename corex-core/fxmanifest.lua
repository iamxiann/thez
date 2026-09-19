fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-core'
description 'COREX Framework - Core Engine for Zombie Survival'
author 'ABUGIZA'
version '2.0.0'

shared_scripts {
    'config.lua',
    'shared/debug.lua',
    'shared/utils.lua',
    'shared/validation.lua',
    'shared/vehicles.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
    'server/players.lua',
    'server/state.lua',
    'server/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/cl_world.lua'
}

dependency 'oxmysql'

server_exports {
    'GetCoreObject',
    'GetPlayer',
    'GetPlayers',
    'GetNearbyPlayers',
    'GetPlayerById',
    'GetMoney',
    'AddMoney',
    'RemoveMoney',
    'HasMoney',
    'GetStat',
    'SetStat',
    'AddStat',
    'SetBusy',
    'TrySetBusy',
    'ClearBusy',
    'IsBusy',
    'SetPlayerState',
    'GetPlayerState',
    'GetPlayersByState',
    'SavePlayer',
    'SetMetaData',
    'GetMetaData',
    'GetVehicleCatalog',
    'GetVehicleDefinition',
    'LoadCharacter'
}

exports {
    'GetCoreObject',
    'IsReady',
    'GetVehicleCatalog',
    'GetVehicleDefinition'
}
