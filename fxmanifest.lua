fx_version 'cerulean'
games { 'gta5' }

author 'The_Hs5'

description 'Library for my FIVEM scripts:)'
version '1.1.0'

shared_scripts {
	'@ox_lib/init.lua',
    'config.lua'
}

client_scripts {
    'client/functions.lua',
    'client/events.lua',
    'client/ini.lua'
}

server_scripts {
    'server/functions.lua',
    'server/events.lua',
    'server/server.lua',
    'server/ini.lua'
}

files {
    'locales/*.json'
}

lua54 'yes'