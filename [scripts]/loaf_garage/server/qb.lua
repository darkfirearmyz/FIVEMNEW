local QBVehicleTypes = {
    boat = {
        "boats"
    },
    plane = {
        "planes"
    }
}

CreateThread(function()
    if Config.Framework ~= "qb" then
        return
    end

    local QBCore = exports["qb-core"]:GetCoreObject()

    function Notify(source, message)
        TriggerClientEvent("QBCore:Notify", source, message)
    end

    function GetIdentifier(source)
        return QBCore.Functions.GetPlayer(source)?.PlayerData.citizenid
    end

    function PayMoney(source, amount)
        local qPlayer = QBCore.Functions.GetPlayer(source)
        if qPlayer?.Functions.GetMoney("cash") >= amount then
            qPlayer.Functions.RemoveMoney("cash", amount, "loaf-billing")
            return true
        elseif qPlayer?.Functions.GetMoney("bank") >= amount then
            qPlayer.Functions.RemoveMoney("bank", amount, "loaf-billing")
            return true
        end

        return false
    end

    local function IsInTable(t, value)
        for k, v in pairs(t) do
            if v == value then
                return true
            end
        end
        return false
    end

    function FetchVehicles(cb, source)
        MySQL.Async.fetchAll("SELECT * FROM `player_vehicles` WHERE `citizenid`=@identifier", {
            ["@identifier"] = GetIdentifier(source)
        }, function(vehicles)
            for _, v in pairs(vehicles) do
                v.stored = v.state == 1

                local props = json.decode(v.mods)
                props.plate = v.plate

                local vehicleData = QBCore.Shared.Vehicles[v.vehicle]
                if vehicleData then
                    if IsInTable(QBVehicleTypes.plane, vehicleData.category) then
                        v.type = "plane"
                    elseif IsInTable(QBVehicleTypes.boat, vehicleData.category) then
                        v.type = "boat"
                    else
                        v.type = "car"
                    end
                    props.model = vehicleData.hash
                else
                    print("^1[ERROR]^0: The vehicle " .. v.vehicle .. " is not in the vehicles.lua file in qb-core/shared!")
                    props.model = tonumber(v.hash)
                    v.type = v.type or "car"
                end

                v.vehicle = json.encode(props)
                v.job = ""
            end
            cb(vehicles)
        end)
    end

    function TakeOutVehicle(cb, source, plate, spawnLocation, impounded)
        for _, vehicle in pairs(GetAllVehicles()) do
            if Entity(vehicle).state.plate == plate then
                TriggerClientEvent("loaf_garage:ping_out", source, GetEntityCoords(vehicle), plate)
                Notify(source, Strings["already_out"])
                return cb(false)
            end
        end
        MySQL.Async.fetchScalar("SELECT `hash` FROM `player_vehicles` WHERE `citizenid`=@identifier AND `plate`=@plate AND `state`=@impounded", {
            ["@identifier"] = GetIdentifier(source),
            ["@plate"] = plate,
            ["@impounded"] = impounded and 0 or 1
        }, function(model)
            if not model then
                return cb(false)
            end

            if impounded then
                if not PayMoney(source, Config.Impound.price) then
                    Notify(source, Strings["no_money"])
                    return cb(false)
                end
            end

            if impounded and not Config.SetImpoundedRetrieve then
                MySQL.Async.execute("UPDATE `player_vehicles` SET `state`=1 WHERE `citizenid`=@identifier AND `plate`=@plate", {
                    ["@identifier"] = GetIdentifier(source),
                    ["@plate"] = plate
                })
            end

            if Config.SetImpoundedRetrieve then
                MySQL.Async.execute("UPDATE `player_vehicles` SET `state`=0 WHERE `citizenid`=@identifier AND `plate`=@plate", {
                    ["@identifier"] = GetIdentifier(source),
                    ["@plate"] = plate
                })
            end

            if Config.SpawnServer then
                local vehicle = SpawnVehicle(source, tonumber(model), spawnLocation)
                Entity(vehicle).state.plate = plate
                cb(true, NetworkGetNetworkIdFromEntity(vehicle))
            else
                cb(true, tonumber(model))
            end
        end)
    end

    function StoreVehicle(cb, source, garage, props, damages)
        local garageData = Config.Garages[garage]
        if not garageData and garage ~= "property" then
            return cb(false, "not_your_vehicle")
        end

        local plate, fuel = props.plate, props.fuel
        props.plate = nil
        props.fuel = nil

        MySQL.Async.execute("UPDATE `player_vehicles` SET `mods`=@props, `damages`=@damages, `garage`=@garage, `state`=1 WHERE `plate`=@plate AND `citizenid`=@identifier", {
            ["@props"] = json.encode(props),
            ["@damages"] = damages and json.encode(damages) or "[]",
            ["@garage"] = garage,
            ["@plate"] = plate,
            ["@identifier"] = GetIdentifier(source)
        }, function(changed)
            if changed ~= 1 then
                return cb(false, "not_your_vehicle")
            end

            if fuel then
                MySQL.Async.execute("UPDATE `player_vehicles` SET `fuel`=@fuel WHERE `plate`=@plate", {
                    ["@fuel"] = fuel,
                    ["@plate"] = plate
                })
            end

            cb(true)
        end)
    end
end)