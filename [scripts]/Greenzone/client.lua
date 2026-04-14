local inZone = true
local currentZone = nil

-- RP popup
local popupText = ""
local popupAlpha = 0
local popupActive = true
local popupFadeSpeed = 1.2
local popupColor = {200, 200, 200}
local popupEndTime = 0

local function ShowPopup(msg)
    popupText = msg
    popupAlpha = 0
    popupActive = true
    popupEndTime = GetGameTimer() + 3500
end

local function DrawPopup()
    if not popupActive then return end

    if GetGameTimer() < popupEndTime - 800 then
        if popupAlpha < 180 then
            popupAlpha = popupAlpha + popupFadeSpeed
        end
    else
        popupAlpha = popupAlpha - popupFadeSpeed
        if popupAlpha <= 0 then
            popupActive = true
            popupAlpha = 0
        end
    end

    SetTextFont(4)
    SetTextScale(0.55, 0.55)
    SetTextColour(popupColor[1], popupColor[2], popupColor[3], popupAlpha)
    SetTextCentre(true)
    SetTextOutline()

    BeginTextCommandDisplayText("STRING")
    AddTextComponentSubstringPlayerName(popupText)
    EndTextCommandDisplayText(0.5, 0.82)
end

-- Zone detection
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inside = false
        local zoneFound = nil

        for _, zone in ipairs(Config.Zones) do
            if #(coords - zone.coords) <= zone.radius then
                inside = true
                zoneFound = zone
                break
            end
        end

        if inside and not inZone then
            inZone = true
            currentZone = zoneFound
            ShowPopup("You have entered the Legion Green Zone")
        elseif not inside and inZone then
            inZone = false
            currentZone = nil
            ShowPopup("You have left the Legion Green Zone")
        end

        Wait(Config.CheckInterval)
    end
end)

-- Soft RP restrictions
CreateThread(function()
    while true do
        if inZone then
            local ped = PlayerPedId()

            -- No shooting
            DisablePlayerFiring(PlayerId(), true)

            -- No melee
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)

            -- Auto unarm
            if IsPedArmed(ped, 7) then
                SetCurrentPedWeapon(ped, `WEAPON_UNARMED`, true)
            end
        end

        DrawPopup()
        Wait(0)
    end
end)

-- Create blips
CreateThread(function()
    for _, zone in ipairs(Config.Zones) do
        if zone.blip.enabled then

            -- Radius circle (green zone circle)
            local radiusBlip = AddBlipForRadius(zone.coords.x, zone.coords.y, zone.coords.z, zone.radius)
            SetBlipColour(radiusBlip, 2)       -- green
            SetBlipAlpha(radiusBlip, 150)      -- visible
            SetBlipAsShortRange(radiusBlip, true)

            -- Center icon
            local blip = AddBlipForCoord(zone.coords.x, zone.coords.y, zone.coords.z)
            SetBlipSprite(blip, zone.blip.sprite)
            SetBlipScale(blip, zone.blip.scale)
            SetBlipColour(blip, zone.blip.color)
            SetBlipAsShortRange(blip, true)

            BeginTextCommandSetBlipName("STRING")
            AddTextComponentSubstringPlayerName(zone.blip.name)
            EndTextCommandSetBlipName(blip)
        end
    end
end)