if Config.Framework ~= "qb" then
    return
end

while not QBCore do
    Wait(500)
    QBCore = exports["qb-core"]:GetCoreObject()
end

while not LocalPlayer.state.isLoggedIn do
    Wait(500)
end

local playerJob = QBCore.Functions.GetPlayerData().job

function Notify(msg)
    QBCore.Functions.Notify(msg)
end

function GetJob()
    return playerJob.name
end

loaded = true

RegisterNetEvent("QBCore:Client:OnJobUpdate", function(jobInfo)
    playerJob = jobInfo
    ReloadGarages()
end)
