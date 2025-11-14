fx_version 'cerulean'
game 'gta5'

lua54 'yes'

name 'MOJO Performonitor'
author 'MOJO Development'
version '5.0.0'

shared_script 'config.lua'

server_scripts {
    'server_bridge.lua'
}

-- NOT: Artık client tarafında inject yok, scriptler kendi inject lua'sını kullanıyor
