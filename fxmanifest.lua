fx_version 'cerulean'
game 'gta5'
lua54 'yes'

author 'Muhaddil'
description 'Devolutions System'
version '1.0.0'

ui_page 'web/index.html'

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'
}

client_script 'client/*'

server_script {
    '@oxmysql/lib/MySQL.lua',
    'server/*'
}

files {
    'web/*',
}

dependencies {
    'ox_lib',
    'oxmysql'
}