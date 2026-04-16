CreateThread(function()
    if Config.Framework ~= "esx" then
        return
    end

    local export, ESX = pcall(function()
        return exports.es_extended:getSharedObject()
    end)
    if not export then
        TriggerEvent("esx:getSharedObject", function(obj)
            ESX = obj
        end)
    end

    function Notify(source, msg)
        TriggerClientEvent("esx:showNotification", source, msg)
    end

    function GetIdentifier(source)
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        return xPlayer.identifier
    end

    function PayMoney(source, amount)
        local xPlayer = ESX.GetPlayerFromId(source)
        if xPlayer.getMoney() >= amount then
            xPlayer.removeMoney(amount)
            return true
        elseif xPlayer.getAccount("bank").money >= amount then
            xPlayer.removeAccountMoney("bank", amount)
            return true
        end
        return false
    end

    function FetchVehicles(cb, source)
        MySQL.Async.fetchAll("SELECT `plate`, `vehicle`, `type`, `job`, `stored`, `damages`, `garage` FROM `owned_vehicles` WHERE `owner`=@identifier", {
            ["@identifier"] = GetIdentifier(source)
        }, function(vehicles)
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
        MySQL.Async.fetchScalar("SELECT `vehicle` FROM `owned_vehicles` WHERE `owner`=@identifier AND `plate`=@plate AND `stored`=@impounded", {
            ["@identifier"] = GetIdentifier(source),
            ["@plate"] = plate,
            ["@impounded"] = impounded and 0 or 1
        }, function(vehicleProps)
            if not vehicleProps then
                return cb(false)
            end

            if impounded then
                if not PayMoney(source, Config.Impound.price) then
                    Notify(source, Strings["no_money"])
                    return cb(false)
                end
            end

            if impounded and not Config.SetImpoundedRetrieve then
                MySQL.Async.execute("UPDATE `owned_vehicles` SET `stored`=1 WHERE `owner`=@identifier AND `plate`=@plate", {
                    ["@identifier"] = GetIdentifier(source),
                    ["@plate"] = plate
                })
            end

            if Config.SetImpoundedRetrieve then
                MySQL.Async.execute("UPDATE `owned_vehicles` SET `stored`=0 WHERE `owner`=@identifier AND `plate`=@plate", {
                    ["@identifier"] = GetIdentifier(source),
                    ["@plate"] = plate
                })
            end
            
            local model = json.decode(vehicleProps).model
            if Config.SpawnServer then
                local vehicle = SpawnVehicle(source, model, spawnLocation)
                Entity(vehicle).state.plate = plate
                cb(true, NetworkGetNetworkIdFromEntity(vehicle))
            else
                cb(true, model)
            end
        end)
    end

    function StoreVehicle(cb, source, garage, props, damages)
        local garageData = Config.Garages[garage]
        if not garageData and garage ~= "property" then
            return cb(false, "not_your_vehicle")
        end

        MySQL.Async.fetchAll("SELECT `vehicle`, `type`, `job` FROM `owned_vehicles` WHERE `plate`=@plate AND `owner`=@identifier", {
            ["@plate"] = props.plate,
            ["@identifier"] = GetIdentifier(source)
        }, function(res)
            if not res or not res[1] then 
                return cb(false, "not_your_vehicle") 
            end

            local vehicle, vehicleType, vehicleJob = res[1].vehicle, res[1].type, res[1].job
            vehicle = json.decode(vehicle)
            if props.model ~= vehicle.model then 
                return cb(false, "wrong_model")  -- possible cheater
            end

            if garage ~= "property" and not IsInTable(garageData.vehicleTypes, vehicleType) then
                return cb(false, "invalid_vehicletype")
            end

            if garage ~= "property" and not HasAccessGarage(vehicleJob, garage) then
                return cb(false, "invalid_job")
            end

            MySQL.Async.execute("UPDATE `owned_vehicles` SET `vehicle`=@props, `damages`=@damages, `garage`=@garage, `stored`=1 WHERE `plate`=@plate", {
                ["@props"] = json.encode(props),
                ["@damages"] = damages and json.encode(damages) or "[]",
                ["@garage"] = garage,
                ["@plate"] = props.plate
            }, function()
                cb(true)
            end)
        end)
    end
end)
