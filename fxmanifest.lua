
fx_version 'cerulean'
games { 'gta5' }

shared_scripts {
    'config.lua',
}

server_scripts {
	'server/*.lua',
}
client_scripts {
    '@PolyZone/client.lua',
    '@PolyZone/BoxZone.lua',
    '@PolyZone/EntityZone.lua',
    '@PolyZone/CircleZone.lua',
    '@PolyZone/ComboZone.lua',	
	'client/*.lua',
}

dependencies {
	'qb-core',
	'qb-target',
}

