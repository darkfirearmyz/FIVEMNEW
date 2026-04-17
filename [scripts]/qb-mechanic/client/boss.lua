local QBCore = exports['qb-core']:GetCoreObject()

local function IsBoss()
    local Player = QBCore.Functions.GetPlayerData()
    return Player.job and Player.job.name == Config.Job and Player.job.isboss
end

-- Boss menu target
CreateThread(function()
    Wait(1500)

    local opts = {
        {
            label       = 'Boss Menu',
            icon        = 'fas fa-briefcase',
            onSelect    = function()
                if not IsBoss() then
                    QBCore.Functions.Notify('You are not the boss', 'error')
                    return
                end
                TriggerEvent('qb-bossmenu:client:OpenMenu')
            end,
            canInteract = function() return IsBoss() end,
        }
    }

    if GetResourceState('ox_target') == 'started' then
        exports.ox_target:addSphereZone({
            coords  = Config.BossMenuCoords,
            radius  = 1.5,
            options = opts,
        })
    elseif GetResourceState('qb-target') == 'started' then
        exports['qb-target']:AddCircleZone(
            'mechanic_boss', Config.BossMenuCoords, 1.5,
            { name = 'mechanic_boss', debugPoly = false },
            {
                options = {
                    {
                        type  = 'client',
                        event = 'qb-mechanic:client:openBossMenu',
                        icon  = 'fas fa-briefcase',
                        label = 'Boss Menu',
                        job   = Config.Job,
                    }
                },
                distance = 1.5,
            }
        )
    end
end)

RegisterNetEvent('qb-mechanic:client:openBossMenu', function()
    if not IsBoss() then return end
    TriggerEvent('qb-bossmenu:client:OpenMenu')
end)
