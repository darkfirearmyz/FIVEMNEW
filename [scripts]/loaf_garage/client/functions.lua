-- passive mode (no collision)
local passive = false

RegisterNetEvent("loaf_garage:passive", function(vehicle)
    if not Config.Passive then
        return
    end

    if not passive then
        ResetEntityAlpha(vehicle)
        for _, veh in pairs(GetGamePool("CVehicle")) do
            if veh ~= vehicle then
                ResetEntityAlpha(veh)
                SetEntityNoCollisionEntity(vehicle, veh, true)
                SetEntityNoCollisionEntity(veh, vehicle, true)
            end
        end
        return
    end

    while passive do
        for _, veh in pairs(GetGamePool("CVehicle")) do
            if veh ~= vehicle and veh ~= GetVehiclePedIsUsing(PlayerPedId()) then
                SetEntityAlpha(veh, 153, false)
                SetEntityNoCollisionEntity(vehicle, veh, false)
                SetEntityNoCollisionEntity(veh, vehicle, false)
            end
        end
        Wait(0)
    end
end)

function TogglePassive(toggle, vehicle)
    passive = toggle == true

    TriggerEvent("loaf_garage:passive", vehicle)
end

-- load markers, blips etc
function HasAccessGarage(garage)
    local garageData = Config.Garages[garage]
    if not garageData then
        return false
    end

    if garageData.jobs == "civ" or garageData.jobs == "all" or not garageData.jobs then
        return true
    elseif type(garageData.jobs) == "table" and IsInTable(garageData.jobs, GetJob()) then
        return true
    end

    return false
end

function ReloadGarages()
    for garage, data in pairs(Config.Garages) do
        if not HasAccessGarage(garage) then
            if data.blip then
                lib.RemoveBlip(data.blip)
                data.blip = nil
            end
            if data.marker then
                lib.RemoveMarker(data.marker)
                data.marker = nil
            end
            if data.storeMarker then
                lib.RemoveMarker(data.storeMarker)
                data.storeMarker = nil
            end

            if Config.GarageStyle == "parking" and (Config.TargetSystem == "qtarget" or Config.TargetSystem == "qb-target") then
                for location, coords in pairs(data.parkingLots) do
                    local name = garage .. "_" .. location
                    exports[Config.TargetSystem]:RemoveZone(name)
                end
            end

            goto continue
        end

        if not data.blip and not data.disableBlip then
            data.blip = lib.AddBlip({
                coords = data.retrieve,
                sprite = Config.Blip.garage.sprite,
                color = Config.Blip.garage.color,
                scale = Config.Blip.garage.scale,
                label = Strings["garage_blip"]
            })
        end

        if Config.GarageStyle == "garage" or IsInTable(data.vehicleTypes, "boat") then
            if not data.marker then
                data.marker = lib.AddMarker({
                    coords = data.retrieve,
                    type = 1,
                    callbackData = {
                        press = garage
                    },
                    key = "primary",
                    text = Strings["browse_vehicles"],
                }, nil, nil, BrowseVehicles)
            end

            if not data.storeMarker then
                data.storeMarker = lib.AddMarker({
                    coords = data.store,
                    scale = vector3(5.0, 5.0, 0.5),
                    type = 1,
                    callbackData = {
                        press = garage
                    },
                    key = "primary",
                    text = Strings["store_vehicle"],
                }, nil, nil, StoreVehicle)
            end
        elseif Config.GarageStyle == "parking" then
            if Config.TargetSystem == "qtarget" or Config.TargetSystem == "qb-target" then
                for location, coords in pairs(data.parkingLots) do
                    local name = garage .. "_" .. location
                    exports[Config.TargetSystem]:RemoveZone(name)

                    exports[Config.TargetSystem]:AddBoxZone(name, coords.xyz - vector3(0.0, 0.0, 1.0), 5.9, 3.2, {
                            name = name,
                            heading = coords.w,
                            debugPoly = Config.DebugPoly,
                            minZ = coords.z - 1.0,
                            maxZ = coords.z + 2.0,
                        }, {
                        options = {
                            {
                                icon = "fas fa-parking",
                                label = Strings["store_vehicle"],
                                action = function(entity)
                                    local vehicle = IsPedInAnyVehicle(PlayerPedId()) and GetVehiclePedIsIn(PlayerPedId()) or entity
                                    StoreVehicle(garage, vehicle)
                                end,
                                canInteract = function(entity)
                                    return ( IsPedInAnyVehicle(PlayerPedId()) or IsEntityAVehicle(entity) )
                                end
                            },
                            {
                                icon = "fas fa-car",
                                label = Strings["browse_vehicles"],
                                action = function()
                                    BrowseVehicles(garage, coords)
                                end,
                                canInteract = function(entity)
                                    return not IsEntityAVehicle(entity) and not IsPedInAnyVehicle(PlayerPedId())
                                end
                            },
                        },
                        distance = 3.0,
                    })
                end
            end
        end

        ::continue::
    end

    if not Config.Impound.enabled then
        return
    end
    for impound, data in pairs(Config.Impounds) do
        if not data.blip and not data.disableBlip then
            data.blip = lib.AddBlip({
                coords = data.retrieve,
                sprite = Config.Blip.impound.sprite,
                color = Config.Blip.impound.color,
                scale = Config.Blip.impound.scale,
                label = Strings["impound_blip"]
            })
        end

        if Config.TargetSystem and Config.AlwaysTarget then
            local name = "loaf_garage_impound_" .. impound

            exports.qtarget:AddBoxZone(name, data.retrieve.xyz - vector3(0.0, 0.0, 0.5), 2.0, 2.0, {
                name = name,
                debugPoly = Config.DebugPoly,
                minZ = data.retrieve.z - 1.0,
                maxZ = data.retrieve.z + 1.0,
            }, {
            options = {
                {
                    icon = "fas fa-car",
                    label = Strings["browse_impound"],
                    action = function()
                        BrowseVehicles(impound, data.spawn, true)
                    end,
                    canInteract = function(entity)
                        return not IsPedInAnyVehicle(PlayerPedId())
                    end
                },
            },
            distance = 3.0,
        })
        elseif not data.marker then

            data.marker = lib.AddMarker({
                coords = data.retrieve,
                type = 1,
                callbackData = {},
                key = "primary",
                text = Strings["browse_impound"],
            }, nil, nil, function()
                BrowseVehicles(impound, data.spawn, true)
            end)
        end
    end
end

-- damages
function SetDamages(vehicle, damages)
    if not Config.SaveDamages or not DoesEntityExist(vehicle) then
        return
    end

    if damages.bodyHealth then
        SetVehicleBodyHealth(vehicle, damages.bodyHealth)
    end
    if damages.engineHealth then
        SetVehicleEngineHealth(vehicle, damages.engineHealth)
    end
    if damages.dirtLevel then
        SetVehicleDirtLevel(vehicle, damages.dirtLevel)
    end
    if damages.deformation and GetResourceState("VehicleDeformation") == "started" then
        exports.VehicleDeformation:SetVehicleDeformation(vehicle, damages.deformation)
    end
    if damages.burstTires then
        for _, v in pairs(damages.burstTires) do
            SetVehicleTyreBurst(vehicle, v, true, 1000.0)
        end
    end
    if damages.damagedWindows then
        for _, v in pairs(damages.damagedWindows) do
            if v == 0 then
                PopOutVehicleWindscreen(vehicle)
            end
            SmashVehicleWindow(vehicle, v)
        end
    end
    if damages.brokenDoors then
        for _, v in pairs(damages.brokenDoors) do
            SetVehicleDoorBroken(vehicle, v, true)
        end
    end
end

function GetDamages(vehicle)
    if not Config.SaveDamages then
        return nil
    end

    local burstTires = {}
    for _, v in pairs({0, 1, 2, 3, 4, 5, 45, 47}) do
        if IsVehicleTyreBurst(vehicle, v, false) then
            table.insert(burstTires, v)
        end
    end

    local damagedWindows = {}
    for i = 0, 7 do
        if not IsVehicleWindowIntact(vehicle, i) then
            table.insert(damagedWindows, i)
        end
    end

    local brokenDoors = {}
    for i = 0, 5 do
        if IsVehicleDoorDamaged(vehicle, i) then
            table.insert(brokenDoors, i)
        end
    end

    local deformation
    if GetResourceState("VehicleDeformation") == "started" then
        deformation = exports.VehicleDeformation:GetVehicleDeformation(vehicle)
    end

    return {
        engineHealth = GetVehicleEngineHealth(vehicle),
        bodyHealth = GetVehicleBodyHealth(vehicle),
        dirtLevel = GetVehicleDirtLevel(vehicle),
        deformation = deformation,
        burstTires = burstTires,
        damagedWindows = damagedWindows,
        brokenDoors = brokenDoors
    }
end

-- misc functions
function IsInTable(t, v)
    for _, value in pairs(t) do
        if value == v then
            return true
        end
    end
    return false
end

function LoadModel(model)
    local loaded = lib.LoadModel(model)
    return loaded.model or model
end

function FadeOut(ms)
    DoScreenFadeOut(ms or 500)
    while IsScreenFadingOut() do
        Wait(0)
    end
end

function FadeIn(ms)
    DoScreenFadeIn(ms or 500)
    while IsScreenFadingIn() do
        Wait(0)
    end
end

function CreateLocalVehicle(data, spawnLocation)
    local vehicleProperties = data.vehicle
    local model = LoadModel(vehicleProperties.model)

    local vehicle = CreateVehicle(model, spawnLocation.xyz, spawnLocation.w, false, false)
    if ESX then
        ESXSetVehicleProperties(vehicle, vehicleProperties)
    elseif QBCore then
        QBCore.Functions.SetVehicleProperties(vehicle, json.decode(data.mods))
    end
    SetVehicleOnGroundProperly(vehicle)
    if data.damages then
        local damages = json.decode(data.damages)
        SetTimeout(250, function()
            SetVehicleFixed(vehicle)
            Wait(50)
            SetDamages(vehicle, damages)
        end)
    end

    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
    SetVehRadioStation(vehicle, "OFF")
    TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
    SetVehicleEngineOn(vehicle, true, true, true)
    SetVehicleHandbrake(vehicle, true)
    FreezeEntityPosition(vehicle, true)

    return vehicle
end