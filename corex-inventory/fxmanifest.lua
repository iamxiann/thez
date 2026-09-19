fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-inventory'
description 'COREX Framework - Inventory System'
author 'ABUGIZA'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua',
    'shared/items.lua',
    'shared/weapons.lua',
    'shared/shops.lua'
}

server_scripts {
    'server/stacking.lua',
    'server/sorting.lua',
    'server/main.lua'
}

client_scripts {
    'client/main.lua',
    'client/rental_bicycle.lua',
    'client/weapons.lua',
    'client/shops.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'html/images/*.png'
}

dependencies {
    'corex-core',
    'ox_lib',
    'ox_target'
}
