fx_version 'cerulean'
games { 'gta5' }

author 'The_Hs5'

description 'Library for my FIVEM scripts:)'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/functions.lua',
}

server_scripts {
    'server/functions.lua',
    'server/events.lua',
}

ox_libs {
	'notify',
	'progressBar',
}

lua54 'yes'
