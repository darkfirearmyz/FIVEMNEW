local vehicleLabels = {
    --[[
        [hash key] = "display name",
    --]]
    -- tip: `spawn name` will get converted to the hash key!

    [`jesko`] = "Koenigsegg Jesko",
    [`jesko2020x`] = "Jesko 2020",
}

function GetVehicleLabel(model)
    if vehicleLabels[model] then
        return vehicleLabels[model]
    end

    return GetLabelText(GetDisplayNameFromVehicleModel(model))
end
