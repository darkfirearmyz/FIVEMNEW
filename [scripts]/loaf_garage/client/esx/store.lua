if Config.Framework ~= "esx" then
    return
end

while not loaded do
    Wait(500)
end

function StoreVehicle(garage, vehicle)
    if browsing then
        return
    end

    if type(vehicle) ~= "number" or not DoesEntityExist(vehicle) then
        vehicle = GetVehiclePedIsUsing(PlayerPedId())
    end

    if not DoesEntityExist(vehicle) then
        return
    end

    local props = ESX.Game.GetVehicleProperties(vehicle)

    props.plate = Entity(vehicle).state.plate or GetVehicleNumberPlateText(vehicle)

    if GetResourceState("LegacyFuel") == "started" then
        props.fuel = exports.LegacyFuel:GetFuel(vehicle)
    end

    local stored, reason = lib.TriggerCallbackSync("loaf_garage:store_vehicle", garage, props, GetDamages(vehicle))

    if not stored then
        Notify(Strings[reason])
        return
    end

    DeleteEntity(vehicle)

    local garageData = Config.Garages[garage]

    for _, v in pairs(garageData.vehicleTypes) do
        if v == "boat" then
            SetEntityCoordsNoOffset(PlayerPedId(), garageData.retrieve.x, garageData.retrieve.y, garageData.retrieve.z, false, false, false)
            return
        end
    end
end

exports("StoreVehicle", StoreVehicle)
