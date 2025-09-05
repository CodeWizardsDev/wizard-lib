require("config")
---------------- RemoveItem ----------------
--[[
    This event adds an item to the player's inventory.
    It checks if the item and amount are valid, then uses the configured inventory script to add the item.
    Customers can use this event to manage vehicle maintenance items in players' inventories.
]]--
RegisterNetEvent('wizard-lib:server:removeItem')
AddEventHandler('wizard-lib:server:removeItem', function(item, amount)
    local src = source
    if not item then return end
    if not amount then return end
    if Cfg.InventoryScript == 'ox' then
        exports.ox_inventory:RemoveItem(src, item, amount)
    elseif Cfg.InventoryScript == 'codem' then
        exports['codem-inventory']:RemoveItem(src, item, amount)
    elseif Cfg.InventoryScript == 'quasar' then
        exports['qs-inventory']:RemoveItem(src, item, amount)
    elseif Cfg.InventoryScript == 'qb' then
        exports['qb-inventory']:RemoveItem(src, item, amount, false, 'wizard-mileage:Vehicle maintenance')
    elseif Cfg.InventoryScript == 'esx' then
        local ESX = exports["es_extended"]:getSharedObject()
        local xPlayer = ESX.GetPlayerFromId(src)
        xPlayer.removeInventoryItem(item, amount)
    end
end)