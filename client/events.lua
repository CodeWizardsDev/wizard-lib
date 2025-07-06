RegisterNetEvent('wizard-tracker:client:notify')
AddEventHandler('wizard-tracker:client:notify', function(scriptname, message, type, defIcon)
    Notify(scriptname, message, type, defIcon)
end)