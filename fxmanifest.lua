fx_version "cerulean"
game "gta5"
author "Pickle Mods"
version "v1.1.1"

ui_page "web/dist/index.html"

this_is_a_map 'yes'

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'

files {
	"web/dist/index.html",
	"web/dist/images/*.*",
	"web/dist/assets/**/*.*",
	"web/dist/debug.js",
}

shared_scripts {
	"@ox_lib/init.lua",
	"config.lua",
	"locales/locale.lua",
    "locales/translations/*.lua",
	"modules/**/shared.lua",
    "core/shared.lua"
}

client_scripts {
	"bridge/**/**/client.lua",
	"modules/**/client.lua",
    "core/client.lua"
}

server_scripts {
	"@mysql-async/lib/MySQL.lua",
	"bridge/**/**/server.lua",
	"modules/**/server.lua",
}

lua54 'yes'

escrow_ignore {
	"config.lua",
	"_INSTALL/**/*.*",
	"bridge/**/**/*.*",
	"bridge/**/*.*",
    "locales/locale.lua",
    "locales/translations/*.lua",
}