fx_version 'cerulean'
game 'gta5'

author 'Peleg'
description 'Standalone Event System with Car Sumo, Redzone, and Party Events'
version '1.0.0'

shared_scripts {
    'shared/config.lua',
    'shared/utils.lua'
}

client_scripts {
    'client/main.lua',
    'client/events/carSumo.lua',
    'client/events/redzone.lua',
    'client/events/party.lua',
    'client/ui.lua'
}

server_scripts {
    'server/main.lua',
    'server/events/carSumo.lua',
    'server/events/redzone.lua',
    'server/events/party.lua',
    'server/rewards.lua'
}

ui_page 'ui/dist/index.html'

files {
    'ui/dist/index.html',
    'ui/dist/**/*'
}

