fx_version 'cerulean'
game 'gta5'

name 'tot_treasurehunt_bridge'
author 'Vedhaanthan'
version '1.0.0'
description 'Framework compatibility bridge for Treasure Hunt'

lua54 'yes'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'framework.lua',
    'inventory.lua',
    'target.lua',
    'notify.lua'
}

server_scripts {
    'framework.lua',
    'inventory.lua',
    'notify.lua',
    'target.lua'
}

dependencies {
    'ox_lib'
}
