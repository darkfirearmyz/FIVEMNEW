fx_version "cerulean"
game "gta5"
version "2.0.8"
lua54 "yes"

shared_script {
    "config/*.lua",
    "shared/*.lua"
}

client_script "client/**.lua"

server_script {
    "@mysql-async/lib/MySQL.lua",
    "server/*.lua",
    "escrow/server.lua"
}

dependency {
    "loaf_lib"
    -- "VehicleDeformation" -- https://github.com/Kiminaze/VehicleDeformation
}

escrow_ignore {
    "config/*.lua",
    "shared/*.lua",

    "client/*.lua",
    "client/**.lua",

    "server/*.lua",
}

dependency '/assetpacks'