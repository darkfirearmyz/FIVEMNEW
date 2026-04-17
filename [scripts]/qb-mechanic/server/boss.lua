local QBCore = exports['qb-core']:GetCoreObject()

-- Society account balance check (optional helper for bossmenu integration)
-- QBCore's built-in qb-bossmenu handles hire/fire/balance natively.
-- Add custom server-side boss logic here if needed.

QBCore.Functions.CreateCallback('qb-mechanic:server:getSocietyBalance', function(source, cb)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player or not Player.PlayerData.job.isboss then
        cb(0) return
    end
    -- Requires qb-management or equivalent
    TriggerEvent('qb-bossmenu:server:GetAccountMoney', Config.SocietyAccount, function(amount)
        cb(amount or 0)
    end)
end)
