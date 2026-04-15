local QBCore = exports['qb-core']:GetCoreObject()

RegisterNetEvent"npc_weaponshop:server:buyWeapon", function(weapon, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local cash = Player.Functions.GetMoney("cash")

    if cash >= price then
        Player.Functions.RemoveMoney("cash", price)

        -- Give weapon as item (recommended for QBCore)
        Player.Functions.AddItem(weapon, 1)

        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[weapon], "add")

        TriggerClientEvent('QBCore:Notify', src, "You bought a " .. weapon, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough cash!", "error")
    end
    RegisterNetEvent("npc_weaponshop:server:buyAmmo", function(item, price)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)

    if not Player then return end

    local cash = Player.Functions.GetMoney("cash")

    if cash >= price then
        Player.Functions.RemoveMoney("cash", price)

        Player.Functions.AddItem(item, 1)

        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[item], "add")
        TriggerClientEvent('QBCore:Notify', src, "You bought " .. item, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough cash!", "error")
    end)