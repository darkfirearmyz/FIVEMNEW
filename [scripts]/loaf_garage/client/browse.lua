browsing = false

function TakeOutVehicle(args)
    local garage, data, spawnLocation = args.garage, args.data, vector4(args.spawnLocation.x, args.spawnLocation.y, args.spawnLocation.z, args.spawnLocation.w)

    local vehicles = GetGamePool("CVehicle")
    for _, vehicle in pairs(vehicles) do
        local plate = Entity(vehicle).state.plate or GetVehicleNumberPlateText(vehicle)
        if plate:gsub(" ", "") == data.plate:gsub(" ", "") then
            TriggerEvent("loaf_garage:ping_out", GetEntityCoords(vehicle), plate)
            DoScreenFadeIn(0)
            return Notify(Strings["already_out"])
        end
    end

    LoadModel(data.vehicle.model)
    lib.TriggerCallback("loaf_garage:take_out", function(success, vehicle)
        if not success then
            return DoScreenFadeIn(0)
        end

        DoScreenFadeOut(0)
        if not Config.SpawnServer then
            LoadModel(vehicle)
            vehicle = CreateVehicle(vehicle, spawnLocation.xyz, spawnLocation.w, true, true)
            Wait(500)
            TriggerServerEvent("loaf_garage:set_plate", NetworkGetNetworkIdFromEntity(vehicle), data.plate)
        else
            local timer = GetGameTimer() + 5000
            while not DoesEntityExist(NetworkGetEntityFromNetworkId(vehicle)) do
                Wait(50)
                if timer < GetGameTimer() then
                    print("vehicle does not exist, aborting\nsetting Config.SpawnServer to false should fix this.")
                    return DoScreenFadeIn(0)
                end
            end

            vehicle = NetworkGetEntityFromNetworkId(vehicle)

            timer = GetGameTimer() + 5000
            while NetworkGetEntityOwner(vehicle) ~= PlayerId() do
                Wait(50)
                if timer < GetGameTimer() then
                    print("could not take control of vehicle: aborting\nsetting Config.SpawnServer to false should fix this.")
                    return DoScreenFadeIn(0)
                end
            end
        end

        SetVehicleOnGroundProperly(vehicle)
        TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        SetVehicleFixed(vehicle)

        if Config.Passive then
            TogglePassive(true, vehicle)
            SetTimeout(5000, function()
                TogglePassive(false)
            end)
        end

        SetVehicleNumberPlateText(vehicle, data.plate)

        if ESX then
            ESXSetVehicleProperties(vehicle, data.vehicle)
        elseif QBCore then
            QBCore.Functions.SetVehicleProperties(vehicle, json.decode(data.mods))
            TriggerEvent("vehiclekeys:client:SetOwner", QBCore.Functions.GetPlate(vehicle))
        end

        if GetResourceState("LegacyFuel") == "started" then
            if data.fuel then
                exports.LegacyFuel:SetFuel(vehicle, data.fuel)
            elseif data.vehicle.fuel then
                exports.LegacyFuel:SetFuel(vehicle, data.vehicle.fuel)
            end
        end

        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        SetVehRadioStation(vehicle, "OFF")

        if data.damages then
            local damages = json.decode(data.damages)
            SetTimeout(250, function()
                SetVehicleFixed(vehicle)
                Wait(50)
                SetDamages(vehicle, damages)
            end)
        end

        Wait(1000)
        DoScreenFadeIn(1000)
    end, garage, data.plate, spawnLocation, args.impound)
end
RegisterNetEvent("loaf_garage:take_out_vehicle", TakeOutVehicle)

function VehicleVisibleGarage(vehicleJob, garage)
    local garageData = Config.Garages[garage]

    if not garageData then
        return false
    end

    if Config.Framework == "qb" then
        return true
    end

    if garageData.jobs == "all" or not garageData.jobs then
        return true
    elseif garageData.jobs == "civ" then
        if vehicleJob == "" or not vehicleJob or vehicleJob == "civ" then
            return true
        end
    elseif type(garageData.jobs) == "table" and IsInTable(garageData.jobs, vehicleJob) then
        return true
    end

    return false
end

function SelectVehicleMenu(garage, spawnLocation, impound)
    local vehiclesMenu = {
        {
            header = Strings["select_vehicle"],
            isMenuHeader = true
        }
    }

    local vehicleTypes
    if impound then
        vehicleTypes = Config.Impounds[garage].vehicleTypes
    else
        vehicleTypes = Config.Garages[garage].vehicleTypes
    end

    for _, vehicle in pairs(lib.TriggerCallbackSync("loaf_garage:fetch_vehicles")) do
        if (not impound and ((Config.IndependentGarage and vehicle.garage ~= garage) or not VehicleVisibleGarage(vehicle.job, garage))) or not IsInTable(vehicleTypes, vehicle.type) then
            goto continue
        end

        vehicle.vehicle = json.decode(vehicle.vehicle)
        local params = {}
        if (impound and not vehicle.stored) or (not impound and vehicle.stored) then
            params = {
                event = "loaf_garage:take_out_vehicle",
                args = {
                    garage = garage,
                    spawnLocation = spawnLocation,
                    data = vehicle,
                    impound = impound
                }
            }
        end

        table.insert(vehiclesMenu, {
            header = Strings[vehicle.stored and "take_out" or "impounded"]:format(GetVehicleLabel(vehicle.vehicle.model), vehicle.vehicle.plate),
            params = params,
            isMenuHeader = next(params) == nil,
            id = #vehiclesMenu
        })

        ::continue::
    end

    if Config.MenuSystem == "esx" then
        OpenESXBrowse(vehiclesMenu)
    elseif Config.MenuSystem == "qb" then
        exports["qb-menu"]:openMenu(vehiclesMenu)
    elseif Config.MenuSystem == "zf" then
        exports["zf_context"]:openMenu(vehiclesMenu)
    end
end

function SelectVehicleBrowse(garage, spawnLocation, impound)
    if browsing then
        return
    end
    browsing = true

    local vehicleTypes
    if impound then
        vehicleTypes = Config.Impounds[garage].vehicleTypes
    else
        vehicleTypes = Config.Garages[garage].vehicleTypes
    end

    local previousCoords, previousHeading = GetEntityCoords(PlayerPedId()), GetEntityHeading(PlayerPedId())

    local vehicles = lib.TriggerCallbackSync("loaf_garage:fetch_vehicles")
    local browseVehicles, currentVehicle = {}, 1
    for _, vehicle in pairs(vehicles) do
        if (not impound and ((Config.IndependentGarage and vehicle.garage ~= garage) or not VehicleVisibleGarage(vehicle.job, garage))) or not IsInTable(vehicleTypes, vehicle.type) then
            goto continue
        end

        vehicle.vehicle = json.decode(vehicle.vehicle)
        if (impound and not vehicle.stored) or (not impound and vehicle.stored) then
            table.insert(browseVehicles, vehicle)
        end

        ::continue::
    end

    if #browseVehicles == 0 then
        browsing = false
        if impound then
            return Notify(Strings["no_impounded"])
        else
            return Notify(Strings["no_vehicles"])
        end
    end

    FadeOut()
    TriggerEvent("qb-anticheat:client:ToggleDecorate", true)
    SetEntityVisible(PlayerPedId(), false, 0)
    SetEntityCoordsNoOffset(PlayerPedId(), spawnLocation.xyz)
    Wait(500)

    lib.TriggerCallbackSync("loaf_garage:enter_routing_bucket")

    if Config.TargetSystem and not impound and Config.GarageStyle == "parking" then
        for location, coords in pairs(Config.Garages[garage].parkingLots) do
            local name = garage .. "_" .. location
            if Config.TargetSystem == "qtarget" or Config.TargetSystem == "qb-target" then
                exports[Config.TargetSystem]:RemoveZone(name)
            end
        end
    end

    local vehicle
    local function RefreshVehicle()
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end

        local vehicleData = browseVehicles[currentVehicle]
        if (impound and not vehicleData.stored) or (not impound and vehicleData.stored) then
            AddTextEntry(GetCurrentResourceName().."browse", Strings["browsing_tip"]:format(Strings["browsing_takeout"]:format(GetVehicleLabel(vehicleData.vehicle.model), vehicleData.plate)))
        else
            AddTextEntry(GetCurrentResourceName().."browse", Strings["browsing_tip"]:format(Strings["browsing_impounded"]:format(GetVehicleLabel(vehicleData.vehicle.model), vehicleData.plate)))
        end
        BeginTextCommandDisplayHelp(GetCurrentResourceName().."browse")
        EndTextCommandDisplayHelp(0, true, false, 0)

        vehicle = CreateLocalVehicle(browseVehicles[currentVehicle], spawnLocation)
    end

    RefreshVehicle()

    FadeIn()
    local takeOut
    local pressTimer = 0
    while true do
        Wait(0)

        local previous = currentVehicle
        DisableControlAction(0, 75, true) -- disable exiting vehicle
        if DoesEntityExist(vehicle) and GetVehiclePedIsUsing(PlayerPedId()) ~= vehicle then -- if the player for some reason exits the vehicle, tp them back inside
            TaskWarpPedIntoVehicle(PlayerPedId(), vehicle, -1)
        end

        if IsDisabledControlJustReleased(0, 194) then -- backspace
            break
        elseif IsDisabledControlJustReleased(0, 191) and ((impound and not browseVehicles[currentVehicle].stored) or (not impound and browseVehicles[currentVehicle].stored)) then -- enter
            takeOut = true
            break
        elseif (IsDisabledControlJustReleased(0, 189) or IsDisabledControlPressed(0, 189)) and pressTimer <= GetGameTimer() then -- left
            pressTimer = GetGameTimer() + 250
            if browseVehicles[currentVehicle - 1] then
                currentVehicle -= 1
            else
                currentVehicle = #browseVehicles
            end
        elseif (IsDisabledControlJustReleased(0, 190) or IsDisabledControlPressed(0, 190)) and pressTimer <= GetGameTimer() then -- right
            pressTimer = GetGameTimer() + 250
            if browseVehicles[currentVehicle + 1] then
                currentVehicle += 1
            else
                currentVehicle = 1
            end
        end

        if previous ~= currentVehicle then
            RefreshVehicle()
        end
    end

    ClearHelp(true)
    TriggerServerEvent("loaf_garage:exit_bucket")
    FadeOut()
    SetEntityVisible(PlayerPedId(), true, 0)
    TriggerEvent("qb-anticheat:client:ToggleDecorate", false)
    ReloadGarages()
    DeleteEntity(vehicle)

    if not takeOut then
        SetEntityCoordsNoOffset(PlayerPedId(), previousCoords)
        SetEntityHeading(PlayerPedId(), previousHeading)
        FadeIn()
    else
        Wait(1000)
        TakeOutVehicle({
            garage = garage,
            data = browseVehicles[currentVehicle],
            spawnLocation = spawnLocation,
            impound = impound
        })
    end

    browsing = false
end

function BrowseVehicles(garage, spawnLocation, impound)
    if IsPedInAnyVehicle(PlayerPedId(), true) then
        return
    end

    if not impound then
        local garageData = Config.Garages[garage]
        if not garageData and garage ~= "property" then
            return
        end

        if not spawnLocation or type(spawnLocation) ~= "vector4" then
            spawnLocation = garageData.spawn
        end
    end

    if Config.BrowseStyle == "menu" then
        SelectVehicleMenu(garage, spawnLocation, impound)
    elseif Config.BrowseStyle == "browse" then
        SelectVehicleBrowse(garage, spawnLocation, impound)
    end
end
exports("BrowseVehicles", BrowseVehicles)
