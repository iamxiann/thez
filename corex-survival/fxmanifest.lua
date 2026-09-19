fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-survival'
description 'COREX Survival System'
author 'ABUGIZA'
version '1.0.0'

shared_scripts { '@ox_lib/init.lua', 'config.lua' }
client_scripts { 'client/main.lua' }
server_scripts {
    'server/bleeding.lua',
    'server/main.lua'
}

dependencies { 'corex-core', 'ox_lib' }
