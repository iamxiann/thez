fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'xian_chat'
description 'Standalone Corex chat with job messages, autocomplete, and emoji picker.'
version '1.0.0'
author 'xian'

nui_callback_strict_mode 'true'
ui_page 'web/index.html'

provide 'chat'

dependencies {
    'ox_lib',
    'corex-core',
}

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
}

client_scripts {
    'client/main.lua',
    'client/job_settings.lua',
    'client/rp_commands.lua',
}

server_scripts {
    'server/chat.lua',
    'server/user.lua',
    'server/job_settings.lua',
    'server/commands.lua',
}

files {
    'web/**',
    'theme/icons/**',
}
