local QBCore = exports['qb-core']:GetCoreObject()

local npcModel = "g_m_m_chicold_01"
local npcCoords = vector4(23.21, -1105.6, 29.8, 140.23)

local weapons = {
    {label = "Pistol", weapon = "weapon_pistol", price = 500},
    {label = "SMG", weapon = "weapon_smg", price = 1500},
    {label = "Knife", weapon = "weapon_knife", price = 250}
}

local ammo = {
    {label = "Pistol Ammo", item = "pistol_ammo", price = 100},
    {label = "SMG Ammo", item = "smg_ammo", price = 150}
}
-- Create NPC + Target
CreateThread(function()
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do Wait(0) end

    local ped = CreatePed(0, npcModel, npcCoords.x, npcCoords.y, npcCoords.z - 1, npcCoords.w, false, true)
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    SetBlockingOfNonTemporaryEvents(ped, true)

    -- qb-target
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

-- 🗺️ Create Blip
CreateThread(function()
    local blip = AddBlipForCoord(npcCoords.x, npcCoords.y, npcCoords.z)

    SetBlipSprite(blip, 110) -- gun icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 1) -- red
    SetBlipAsShortRange(blip, true)

    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Weapon Dealer")
    EndTextCommandSetBlipName(blip)
end)

-- 🟣 World Marker
CreateThread(function()
    while true do
        local sleep = 1000
        local playerPed = PlayerPedId()
        local coords = GetEntityCoords(playerPed)
        local dist = #(coords - vector3(npcCoords.x, npcCoords.y, npcCoords.z))

        if dist < 20.0 then
            sleep = 0

            DrawMarker(
                2, -- marker type (cylinder)
                npcCoords.x, npcCoords.y, npcCoords.z + 0.2,
                0.0, 0.0, 0.0,
                0.0, 0.0, 0.0,
                0.3, 0.3, 0.3,
                255, 0, 0, 150, -- red color
                false, true, 2, false, nil, nil, false
            )
        end

        Wait(sleep)
    end
end)

-- Menu
function OpenWeaponMenu()
    local menu = {
        {
            header = "🔫 Weapon Dealer",
            isMenuHeader = true
        }
    }

    -- Weapons section
    menu[#menu + 1] = {
        header = "⬇️ Weapons",
        isMenuHeader = true
    }

    for _, v in pairs(weapons) do
        menu[#menu + 1] = {
            header = v.label .. " - $" .. v.price,
            txt = "Purchase " .. v.label,
            params = {
                event = "npc_weaponshop:client:buyWeapon",
                args = {
                    weapon = v.weapon,
                    price = v.price
                }
            }
        }
    end

    -- Ammo section
    menu[#menu + 1] = {
        header = "🔋 Ammo",
        isMenuHeader = true
    }

    for _, v in pairs(ammo) do
        menu[#menu + 1] = {
            header = v.label .. " - $" .. v.price,
            txt = "Purchase " .. v.label,
            params = {
                event = "npc_weaponshop:client:buyAmmo",
                args = {
                    item = v.item,
                    price = v.price
                }
            }
        }
    end

    -- Close
    menu[#menu + 1] = {
        header = "Close",
        txt = "",
        params = { event = "" }
    }

    exports['qb-menu']:openMenu(menu)
end
RegisterNetEvent("npc_weaponshop:client:buyAmmo", function(data)
    TriggerServerEvent("npc_weaponshop:server:buyAmmo", data.item, data.price)
end)