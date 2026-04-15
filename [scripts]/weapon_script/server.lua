local QBCore = exports['qb-core']:GetCoreObject()

-- Buy Weapon
RegisterNetEvent("npc_weaponshop:server:buyWeapon", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    print("BUY WEAPON EVENT TRIGGERED:", data.weapon)

    if Player.Functions.GetMoney("cash") >= data.price then
        Player.Functions.RemoveMoney("cash", data.price)

        Player.Functions.AddItem(data.weapon, 1)

        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.weapon], "add")
        TriggerClientEvent('QBCore:Notify', src, "Purchased " .. data.weapon, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough cash", "error")
    end
end)

-- Buy Ammo
RegisterNetEvent("npc_weaponshop:server:buyAmmo", function(data)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    print("BUY AMMO EVENT TRIGGERED:", data.item)

    if Player.Functions.GetMoney("cash") >= data.price then
        Player.Functions.RemoveMoney("cash", data.price)

        Player.Functions.AddItem(data.item, 1)

        TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[data.item], "add")
        TriggerClientEvent('QBCore:Notify', src, "Purchased " .. data.item, "success")
    else
        TriggerClientEvent('QBCore:Notify', src, "Not enough cash", "error")
    end
end)