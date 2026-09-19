--[[
    COREX Framework - Spawn System
    Handles player spawning and first-time character creation
]]

fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'corex-spawn'
description 'COREX Framework - Player Spawn & Character Creation'
author 'ABUGIZA'
version '1.0.0'

-- Dependencies
dependencies {
    'corex-core',
    'corex-multicharacter',
    'illenium-appearance',
    'ox_lib'
}

-- Shared scripts
shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

-- Server scripts
server_scripts {
    'server/main.lua'
}

-- Client scripts
client_scripts {
    'client/main.lua'
}

