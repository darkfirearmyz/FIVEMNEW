local QBCore = exports['qb-core']:GetCoreObject()

-- ─────────────────────────────────────────────
-- Check if player has repair kit
-- ─────────────────────────────────────────────

QBCore.Functions.CreateCallback('qb-mechanic:server:hasItem', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then cb(false) return end
    local item = Player.Functions.GetItemByName(Config.RepairItem)
    cb(item ~= nil and item.amount > 0)
end)

-- ─────────────────────────────────────────────
-- Remove repair kit after use
-- ─────────────────────────────────────────────

RegisterNetEvent('qb-mechanic:server:removeItem', function(itemName)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    Player.Functions.RemoveItem(itemName, 1)
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[itemName], 'remove')
end)

-- ─────────────────────────────────────────────
-- Bill a nearby player
-- ─────────────────────────────────────────────

RegisterNetEvent('qb-mechanic:server:billPlayer', function(targetId, part)
    local src    = source
    local mech   = QBCore.Functions.GetPlayer(src)
    local target = QBCore.Functions.GetPlayer(tonumber(targetId))

    if not mech or not target then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end

    -- Verify caller is mechanic
    if mech.PlayerData.job.name ~= Config.Job then
        TriggerClientEvent('QBCore:Notify', src, 'You are not a mechanic', 'error')
        return
    end

    local amount = Config.RepairPrices[part]
    if not amount then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid repair type', 'error')
        return
    end

    -- Deduct from target, add to society
    target.Functions.RemoveMoney('bank', amount, 'mechanic-bill')
    TriggerEvent('qb-bossmenu:server:AddAccountMoney', Config.SocietyAccount, amount)

    TriggerClientEvent('QBCore:Notify', src,
        'Billed $' .. amount .. ' to ' .. target.PlayerData.charinfo.firstname, 'success')
    TriggerClientEvent('QBCore:Notify', target.PlayerData.source,
        'You were billed $' .. amount .. ' for mechanic services', 'primary')
end)
