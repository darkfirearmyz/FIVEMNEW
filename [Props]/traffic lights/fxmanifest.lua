fx_version 'cerulean'
game 'gta5'

author 'YourName'
description 'Custom traffic lights & level crossing props'
version '1.0.0'

this_is_a_map 'yes'

files {
    'stream/*.ydr',  -- models (meshes)
    'stream/*.ytd',  -- textures
    'stream/*.ytyp'  -- optional: archetype definitions
}

data_file 'DLC_ITYP_REQUEST' 'stream/*.ytyp'