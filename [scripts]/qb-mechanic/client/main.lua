local QBCore = exports['qb-core']:GetCoreObject()
local isMenuOpen = false

-- ─────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────

local function IsMechanic()
    local Player = QBCore.Functions.GetPlayerData()
    return Player.job and Player.job.name == Config.Job
end

local function GetClosestVehicle()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool('CVehicle')
    local closest, closestDist = nil, 10.0

    for _, v in ipairs(vehicles) do
        local dist = #(playerCoords - GetEntityCoords(v))
        if dist < closestDist and v ~= GetVehiclePedIsIn(playerPed, false) then
            closest = v
            closestDist = dist
        end
    end
    return closest
end

-- ─────────────────────────────────────────────
-- NUI Callbacks
-- ─────────────────────────────────────────────

RegisterNUICallback('repairPart', function(data, cb)
    local vehicle = GetClosestVehicle()
    if not vehicle then
        QBCore.Functions.Notify('No vehicle nearby', 'error')
        cb({ ok = false })
        return
    end

    -- Consume repair kit
    QBCore.Functions.TriggerCallback('qb-mechanic:server:hasItem', function(hasIt)
        if not hasIt then
            QBCore.Functions.Notify('You need a repair kit', 'error')
            cb({ ok = false })
            return
        end

        local part = data.part
        -- Animate
        TaskTurnPedToFaceEntity(PlayerPedId(), vehicle, 1000)
        RequestAnimDict('mini@repair')
        while not HasAnimDictLoaded('mini@repair') do Wait(10) end
        TaskPlayAnim(PlayerPedId(), 'mini@repair', 'fixing_a_ped', 8.0, -8.0, 3000, 1, 0, false, false, false)

        Wait(3000)

        if part == 'engine' then
            SetVehicleEngineHealth(vehicle, Config.RepairValues.engine)
        elseif part == 'body' then
            SetVehicleBodyHealth(vehicle, Config.RepairValues.body)
        elseif part == 'tyres' then
            for i = 0, 5 do
                SetVehicleTyreFixed(vehicle, i)
            end
        elseif part == 'full' then
            SetVehicleEngineHealth(vehicle, Config.RepairValues.engine)
            SetVehicleBodyHealth(vehicle, Config.RepairValues.body)
            for i = 0, 5 do SetVehicleTyreFixed(vehicle, i) end
        end

        TriggerServerEvent('qb-mechanic:server:removeItem', Config.RepairItem)
        QBCore.Functions.Notify('Vehicle repaired!', 'success')
        cb({ ok = true })
    end)
end)

RegisterNUICallback('billPlayer', function(data, cb)
    TriggerServerEvent('qb-mechanic:server:billPlayer', data.targetId, data.part)
    cb({ ok = true })
end)

RegisterNUICallback('closeMenu', function(_, cb)
    isMenuOpen = false
    SetNuiFocus(false, false)
    cb({ ok = true })
end)

-- ─────────────────────────────────────────────
-- Open repair menu
-- ─────────────────────────────────────────────

local function OpenRepairMenu()
    if not IsMechanic() then
        QBCore.Functions.Notify('You are not a mechanic', 'error')
        return
    end

    local vehicle = GetClosestVehicle()
    if not vehicle then
        QBCore.Functions.Notify('No vehicle nearby to repair', 'error')
        return
    end

    -- Get nearby players for billing dropdown
    local nearbyPlayers = {}
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    for _, playerId in ipairs(GetActivePlayers()) do
        local ped = GetPlayerPed(playerId)
        if playerId ~= PlayerId() then
            local dist = #(playerCoords - GetEntityCoords(ped))
            if dist < 10.0 then
                table.insert(nearbyPlayers, {
                    id     = GetPlayerServerId(playerId),
                    name   = GetPlayerName(playerId),
                })
            end
        end
    end

    -- Vehicle health info
    local engineHealth = math.floor(GetVehicleEngineHealth(vehicle))
    local bodyHealth   = math.floor(GetVehicleBodyHealth(vehicle))

    isMenuOpen = true
    SetNuiFocus(true, true)
    SendNUIMessage({
        action        = 'openMenu',
        prices        = Config.RepairPrices,
        engineHealth  = engineHealth,
        bodyHealth    = bodyHealth,
        nearbyPlayers = nearbyPlayers,
    })
end

-- ─────────────────────────────────────────────
-- ox_target / qb-target zones
-- ─────────────────────────────────────────────

CreateThread(function()
    -- Small delay to ensure targets resource is ready
    Wait(1000)

    for _, zone in ipairs(Config.ShopZones) do
        if GetResourceState('ox_target') == 'started' then
            exports.ox_target:addSphereZone({
                coords   = zone.coords,
                radius   = Config.TargetDistance,
                options  = {
                    {
                        label   = 'Open Repair Menu',
                        icon    = 'fas fa-wrench',
                        onSelect = function() OpenRepairMenu() end,
                        canInteract = function() return IsMechanic() end,
                    }
                }
            })
        elseif GetResourceState('qb-target') == 'started' then
            exports['qb-target']:AddCircleZone(
                'mechanic_shop_' .. _, zone.coords, Config.TargetDistance,
                { name = 'mechanic_shop_' .. _, debugPoly = false },
                {
                    options = {
                        {
                            type     = 'client',
                            event    = 'qb-mechanic:client:openRepairMenu',
                            icon     = 'fas fa-wrench',
                            label    = 'Open Repair Menu',
                            job      = Config.Job,
                        }
                    },
                    distance = Config.TargetDistance,
                }
            )
        end
    end
end)

RegisterNetEvent('qb-mechanic:client:openRepairMenu', function()
    OpenRepairMenu()
end)

-- ─────────────────────────────────────────────
-- ESC to close
-- ─────────────────────────────────────────────

CreateThread(function()
    while true do
        Wait(0)
        if isMenuOpen and IsControlJustReleased(0, 200) then
            isMenuOpen = false
            SetNuiFocus(false, false)
            SendNUIMessage({ action = 'closeMenu' })
        end
    end
end)
