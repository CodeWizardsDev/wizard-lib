---------------- Framework initialize ----------------
if GetResourceState('es_extended') == "started" then
    ESX = exports["es_extended"]:getSharedObject()
    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
	    ESX.PlayerData = xPlayer
	    ESX.PlayerLoaded = true
        TriggerEvent("wizard-lib:client:getupdate")
        TriggerServerEvent("wizard-lib:server:getupdate")
    end)
    function ChkJb()
        ESX = exports["es_extended"]:getSharedObject()
        return ESX.GetPlayerData().job.name, ESX.GetPlayerData().job.grade
    end
elseif GetResourceState('qb-core') == "started" or GetResourceState('qbx_core') == "started" then
    QBCore = exports['qb-core']:GetCoreObject()
    RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
    AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
        TriggerEvent("wizard-lib:client:getupdate")
        TriggerServerEvent("wizard-lib:server:getupdate")
    end)
    function ChkJb()
        local Player = QBCore.Functions.GetPlayerData()
        return Player.job.name, Player.job.grade.level
    end
end


GetPlayerRoutingBucket()

---------------- Functions ----------------
local function Notify(message, type)
    if not message or not type then return end
    
    local notifyConfig = {
        wizard = function() exports['wizard-notify']:Send('Wizard Mileage', message, 5000, type) end,
        okok = function() exports['okokNotify']:Alert('Wizard Mileage', message, 5000, type, false) end,
        qbx = function() exports.qbx_core:Notify(message, type, 5000) end,
        qb = function() TriggerEvent('QBCore:Notify', source, message, type) end,
        esx = function() exports['esx_notify']:Notify(message, type, 5000, 'Wizard Mileage') end,
        ox = function() lib.notify{title = 'Wizard Mileage', description = message, type = type} end
    }
    
    local notifyFunc = notifyConfig[Config.Notify]
    if notifyFunc then notifyFunc() end
end
local function TriggerAdminCallback(cb)
    local cbId = math.random(100000, 999999)
    adminCallbacks[cbId] = cb
    TriggerServerEvent('wizard_vehiclemileage:server:isAdmin', cbId)
end


---------------- Net Events ----------------
RegisterNetEvent('wizard_vehiclemileage:client:isAdminCallback')
AddEventHandler('wizard_vehiclemileage:client:isAdminCallback', function(cbId, isAdmin)
    if adminCallbacks[cbId] then
        adminCallbacks[cbId](isAdmin)
        adminCallbacks[cbId] = nil
    end
end)



---------------- Exports ----------------
exports('Notify', function(message, type)
    Notify(message, type)
end)
exports('CheckJob', function()
    local job, grade = ChkJb()
    return job, grade
end)
exports('isAdmin', function()
    TriggerAdminCallback(function(isAdmin)
        return isAdmin
    end)
end)