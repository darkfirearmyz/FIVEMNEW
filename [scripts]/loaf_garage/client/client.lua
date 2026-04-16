CreateThread(function()
    while not loaded do 
        Wait(500)
    end
    lib = exports.loaf_lib:GetLib()

    Config.Garages["property"] = {
        retrieve = vector3(8000.0, 8000.0, 8000.0),
        spawn = vector4(8000.0, 8000.0, 8000.0, 0.0),
        store = vector3(8000.0, 8000.0, 8000.0),

        jobs = "civ",
        vehicleTypes = {"car"},
        parkingLots = {},
        disableBlip = true
    }

    ReloadGarages()

    RegisterNetEvent("loaf_garage:ping_out", function(coords, plate)
        if not Config.PingAlreadyOut then
            return
        end
    
        local blip = lib.AddBlip({
            coords = coords,
            sprite = 225,
            color = 3,
            scale = 0.8,
            label = plate
        })
        SetBlipRoute(lib.GetBlip(blip).blip, true)
        Notify(Strings["ping"])

        Wait(30000)
        
        lib.RemoveBlip(blip)
    end)
end)