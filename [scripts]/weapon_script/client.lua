local QBCore = exports['qb-core']:GetCoreObject()

local npcModel = "g_m_y_lost_03"
local npcCoords = vector4(-34.88, -1510.55, 30.39, 359.68)

local weapons = {
    {label = "Combat Pistol", weapon = "WEAPON_COMBATPISTOL", price = 5000000},
    {label = "SMG", weapon = "weapon_smg", price = 1500000},
    {label = "Double-Action Revolver", weapon = "WEAPON_DOUBLEACTION", price = 2250000}
    {label = "Assault Rifle", weapon = "WEAPON_ASSAULTRIFLE", price = 50000000}
}

local ammo = {
    {label = "Pistol Ammo", item = "pistol_ammo", price = 100, amount = 250},
    {label = "SMG Ammo", item = "smg_ammo", price = 150, amount = 250},
    {label = "Revolver Ammo", item = "pistol_ammo", price = 120, amount = 250},
    {label = "Rifle Ammo", item = "rifle_ammo", price = 300, amount = 250}
}
-- events

RegisterNetEvent("npc_weaponshop:client:giveAmmo", function(weapon)
    local ped = PlayerPedId()
    local weaponHash = GetHashKey(weapon)

    -- Give weapon to ped (ensures it's equipped)
    GiveWeaponToPed(ped, weaponHash, 0, false, true)

    -- Add ammo
    AddAmmoToPed(ped, weaponHash, 250)

    -- Optional: equip it immediately
    SetCurrentPedWeapon(ped, weaponHash, true)
end)

-- Create NPC
CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(0) end

    local ped = CreatePed(0, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1, npcCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    exports['qb-target']:AddTargetEntity(ped, {
        options = {
            {
                label = "Open Weapon Shop",
                icon = "fas fa-gun",
                action = function()
                    OpenWeaponMenu()
                end
            }
        },
        distance = 2.5
    })
end)

-- Blip
CreateThread(function()
    local blip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)

    SetBlipSprite(blip, 110)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 4)
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Weapon Dealer")
    EndTextCommandSetBlipName(blip)
end)

-- Marker
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local dist = #(coords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))

        if dist < 20.0 then
            sleep = 0
            DrawMarker(2, npcCoords.x, npcCoords.y, npcCoords.z + 0.2,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                0.3, 0.3, 0.3,
                255, 0, 0, 150,
                false, true, 2, false, nil, nil, false
            )
        end

        Wait(sleep)
    end
end)

-- Menu
function OpenWeaponMenu()
    local menu = {
        {header = "🔫 Weapon Dealer", isMenuHeader = true},
        {header = "⬇️ Weapons", isMenuHeader = true},
    }

    for _, v in pairs(weapons) do
        menu[#menu + 1] = {
            header = v.label .. " - $" .. v.price,
            txt = "Purchase " .. v.label,
            params = {
                isServer = true,
                event = "npc_weaponshop:server:buyWeapon",
                args = {
                    weapon = v.weapon,
                    price = v.price
                }
            }
        }
    end

    menu[#menu + 1] = {header = "🔋 Ammo", isMenuHeader = true}

    for _, v in pairs(ammo) do
        menu[#menu + 1] = {
            header = v.label .. " - $" .. v.price,
            txt = "Get 100 ammo",
            params = {
                isServer = true,
                event = "npc_weaponshop:server:buyAmmo",
                args = {
                    item = v.item,
                    price = v.price,
                    amount = v.amount -- ✅ THIS is the fix
                }
            }
        }
    end

    menu[#menu + 1] = {
        header = "Close",
        params = { event = "" }
    }

    exports['qb-menu']:openMenu(menu)
end