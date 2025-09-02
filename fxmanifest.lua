fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'mu-vision'
author 'Mufler'
description 'Freecam cinematic tool (F9) — zoom, rotate, move. Qbox/QBCore compatible (standalone).'
version '1.0.0'

client_scripts {
    'config.lua',
    'client/main.lua'
}

-- Standalone; no server files needed.
-- Works with any framework (qbox, qbcore, esx) because it is client-only.
-- No dependencies. Optional: ox_lib for key mapping description (not required).
