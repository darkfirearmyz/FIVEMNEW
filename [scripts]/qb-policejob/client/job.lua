-- Variables
local currentGarage = 0
local inFingerprint = false
local FingerPrintSessionId = nil
local inStash = false
local inTrash = false
local inArmoury = false
local inHelicopter = false
local inImpound = false
local inGarage = false
local inEvidence = false

-- ADDED: Armoury Thread
local function armoury()
    CreateThread(function()
        while true do
            Wait(0)
            if inArmoury and PlayerJob.type == 'leo' then
                if PlayerJob.onduty then sleep = 5 end
                if IsControlJustReleased(0, 38) then
                    TriggerEvent('police:client:openArmory')
                    break
                end
            else
                break
            end
        end
    end)
end

-- ADDED: Armoury Event
RegisterNetEvent('police:client:openArmory', function()
    local items = {
        { name = "weapon_pistol", price = 0, amount = 1, info = {}, type = "weapon", slot = 1 },
        { name = "weapon_stungun", price = 0, amount = 1, info = {}, type = "weapon", slot = 2 },
        { name = "handcuffs", price = 0, amount = 5, info = {}, type = "item", slot = 3 },
        { name = "radio", price = 0, amount = 1, info = {}, type = "item", slot = 4 },
    }

    TriggerServerEvent("inventory:server:OpenInventory", "shop", "police_armory", {
        label = "Police Armoury",
        items = items
    })
end)

-- EXISTING CODE CONTINUES...

-- ADD THIS inside NON qb-target zone section
-- Armoury Zone
local armouryZones = {}
for i = 1, #Config.Locations['armory'] do
    local v = Config.Locations['armory'][i]
    armouryZones[#armouryZones + 1] = BoxZone:Create(
        vector3(v.x, v.y, v.z), 1.5, 1.5, {
            name = 'armoury_zone',
            debugPoly = false,
            minZ = v.z - 1,
            maxZ = v.z + 1,
        })
end

local armouryCombo = ComboZone:Create(armouryZones, { name = 'armouryCombo', debugPoly = false })
armouryCombo:onPlayerInOut(function(isPointInside)
    if isPointInside then
        inArmoury = true
        if PlayerJob.type == 'leo' and PlayerJob.onduty then
            exports['qb-core']:DrawText("Press [E] Armoury", 'left')
            armoury()
        end
    else
        inArmoury = false
        exports['qb-core']:HideText()
    end
end)

-- ADD THIS inside qb-target section if using it
-- Armoury qb-target
for i = 1, #Config.Locations['armory'] do
    local v = Config.Locations['armory'][i]
    exports['qb-target']:AddCircleZone('PoliceArmoury_' .. i, vector3(v.x, v.y, v.z), 1.0, {
        name = 'PoliceArmoury_' .. i,
        useZ = true,
        debugPoly = false,
    }, {
        options = {
            {
                type = 'client',
                event = 'police:client:openArmory',
                icon = 'fas fa-archive',
                label = "Open Armoury",
                jobType = 'leo',
            },
        },
        distance = 1.5
    })
end
