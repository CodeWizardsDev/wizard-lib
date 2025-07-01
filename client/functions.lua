require("config")
lib.locale()
---------------- Framework initialize ----------------
--[[
    This section initializes the framework (ESX or ND or QBCore or QBox) based on the Config settings.
    It sets up player data and job checks, and registers events for player loading.
    The CheckJob function returns the player's job name, grade, duty status, payment and checks if player is boss for use in service actions.
    The CheckGang function returns the player's gang name, grade and checks if player is boss for use in service actions.
]]--
if Cfg.FrameWork == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()

    RegisterNetEvent('esx:playerLoaded')
    AddEventHandler('esx:playerLoaded', function(xPlayer)
        ESX.PlayerData = xPlayer
        ESX.PlayerLoaded = true
    end)

    -- Returns the player's job name and grade
    function CheckJob()
        local xPlayer = ESX.GetPlayerData()
        local JobData = xPlayer.job
        return JobData.name, JobData.grade, 'unknown', 'unknown', 'unknown'
    end

    function CheckGang()
        local Player = QBCore.Functions.GetPlayerData()
        local GangData = Player.gang
        return 'unknown', 'unknown', 'unknown'
    end
elseif Cfg.FrameWork == 'nd' then
    local nd_core = exports["ND_Core"]

    NDCore = setmetatable({}, {
        __index = function(self, index)
            self[index] = function(...)
                return nd_core[index](nil, ...)
            end

            return self[index]
        end
    })

    RegisterNetEvent("ND:characterLoaded", function(char)
        player = char
    end)
    RegisterNetEvent("ND:updateCharacter", function(char)
        player = char
    end)

    -- Returns the player's job name and grade
    function CheckJob()
        local player = NDCore.getPlayer()
        return player.job, player.jobInfo.rank, 'unknown', 'unknown', 'unknown'
    end

    function CheckGang()
        local Player = QBCore.Functions.GetPlayerData()
        local GangData = Player.gang
        return 'unknown', 'unknown', 'unknown'
    end
else
    QBCore = exports['qb-core']:GetCoreObject()

    RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
    AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
    end)

    -- Returns the player's job name and grade
    function CheckJob()
        local Player = QBCore.Functions.GetPlayerData()
        local JobData = Player.job
        return JobData.name, JobData.grade.level, JobData.onduty, JobData.payment, JobData.isboss
    end

    function CheckGang()
        local Player = QBCore.Functions.GetPlayerData()
        local GangData = Player.gang
        return GangData.name, GangData.grade.level, GangData.isboss
    end
end


---------------- Notification ----------------
--[[
    Notify function for sending messages to the player using the configured notification system.
    This function supports multiple notification resources (wizard-notify, okokNotify, qbx_core, qb, esx_notify, ox_lib).
    It will automatically use the one selected in your Cfg.Notify setting.
    Params:
        message (string): The message to display to the player.
        type (string): The type of notification (e.g., "success", "error", "info", "warning").
]]--
function Notify(script, message, type, defIcon)
    if not message or not type then return end -- Don't send empty notifications

    -- Table of supported notification systems and their respective function calls
    local notifyConfig = {
        default = function()
            BeginTextCommandThefeedPost("STRING")
            AddTextComponentSubstringPlayerName(message or "NO INPUT")
            EndTextCommandThefeedPostMessagetext(defIcon or "CHAR_MILSITE", defIcon or "CHAR_MILSITE", false, 4, script or "Code Wizards", "")
            EndTextCommandThefeedPostTicker(false, false)
        end,

        wizard = function() exports['wizard-notify']:Send(script or "Code Wizards", message or "NO INPUT", 5000, type) end,
        okok = function() exports['okokNotify']:Alert(script or "Code Wizards", message or "NO INPUT", 5000, type, false) end,
        qbx = function() exports.qbx_core:Notify(message or "NO INPUT", type, 5000) end,
        qb = function() TriggerEvent('QBCore:Notify', source, message or "NO INPUT", type) end,
        esx = function() exports['esx_notify']:Notify(message or "NO INPUT", type, 5000, script or "Code Wizards") end,
        ox = function() lib.notify{title = script or "Code Wizards", description = message or "NO INPUT", type = type} end
    }

    -- Select and call the correct notification function based on config
    local notifyFunc = notifyConfig[Cfg.Notify]
    if notifyFunc then notifyFunc() end
end


---------------- Permission Checker ----------------
--[[
    Triggers an permission callback to check if the current player has a permission.
    This is used for permission-only features.
    The callback is stored in a table with a unique ID, so when the server responds,
    the correct callback can be executed.
    @param cb (function): The function to call with the permission status (true/false).
]]--
local permCallbacks = {}
function TriggerPermCallback(perm, cb)
    local cbId = math.random(100000, 999999) -- Generate a unique callback ID
    permCallbacks[cbId] = cb                -- Store the callback for later use
    TriggerServerEvent('wizard-lib:server:hasPerm', cbId, perm) -- Ask the server to check permission status
end

--[[
    Perm checking callback.
    This event is triggered by the server to return the result of an perm check.
    It looks up the callback function by its unique ID and calls it with the perm status (true/false).
    After calling, it removes the callback from the table to prevent memory leaks.
    @param cbId (number): The unique callback ID.
    @param hasPerm (boolean): Whether the player has a permission.
]]--
RegisterNetEvent('wizard-lib:client:hasPermCallback')
AddEventHandler('wizard-lib:client:hasPermCallback', function(cbId, hasPerm)
    if permCallbacks[cbId] then
        permCallbacks[cbId](hasPerm)
        permCallbacks[cbId] = nil
    end
end)



---------------- Check Script Status ----------------
--[[
    Checks for script updates and notifies the player in chat.
    Waits until the isOutdated flag is set, then displays a message
    if the script is outdated or up to date.
    Params:
        isOutdated (bool): Whether the script is outdated (set by server)
        currentVersion (string): Current script version
        latestVersion (string): Latest available version
]]--
local isOutdated = nil
function updateCheck(scriptName, colorRGB, isOutdated, currentVersion, latestVersion)
    if isOutdated then
        -- Notify player that their script is outdated
        TriggerEvent('chat:addMessage', {
            color = colorRGB,
            args = {
                scriptName,
                ("^5Your script version ^2(%s) ^5is outdated. Latest version is ^2%s"):format(currentVersion, latestVersion)
            }
        })
    else
        -- Notify player that their script is up to date
        TriggerEvent('chat:addMessage', {
            color = colorRGB,
            args = {scriptName, "^5Script is up to date"}
        })
    end
end



---------------- Get Vehicle Plate ----------------
--[[
    Gets the license plate text of a vehicle entity.
    Returns "UNKNOWN" if the entity does not exist.
    @param vehicle (entity): The vehicle entity to check.
    @return (string): The vehicle's license plate text, or "UNKNOWN" if not found.
]]--
function GetVehiclePlate(vehicle)
    return DoesEntityExist(vehicle) and GetVehicleNumberPlateText(vehicle) or "UNKNOWN"
end



---------------- Calculates Distance ----------------
--[[
    Calculates the distance between two 3D vectors (positions).
    Used to determine how far a vehicle has traveled between updates.
    @param vec1 (vector3): The first position.
    @param vec2 (vector3): The second position.
    @return (number): The distance between the two positions.
]]--
function getDistance(vec1, vec2)
    if not vec1 or not vec2 then return 0 end -- Return 0 if either position is missing
    if type(vec1) == 'vector3' and type(vec2) == 'vector3' then
        return #(vec1 - vec2)
    end
    local dx, dy, dz = vec1.x - vec2.x, vec1.y - vec2.y, vec1.z - vec2.z
    return math.sqrt(dx * dx + dy * dy + dz * dz)
end



---------------- Convert Distance ----------------
--[[
    Converts a distance in meters to either miles or kilometers, depending on config file.
    Used for displaying mileage in the preferred unit for your server.
    @param meters (number): The distance in meters.
    @return (number): The converted distance (miles or kilometers).
]]--
function convertDistance(meters)
    -- If Cfg.Unit is "imperial", convert meters to miles. Otherwise, convert to kilometers.
    return Cfg.Unit == "imperial" and meters * 0.000621371 or meters / 1000
end



---------------- Convert Speed ----------------
--[[
    Converts a speed in m/s to either mph or km/h, depending on config file.
    Used for displaying speed in the preferred unit for your server.
    @param m/s (number): The speed in m/s.
    @return (number): The converted speed (mph or km/h).
]]--
function convertSpeed(mps)
    -- If Cfg.Unit is "imperial", convert m/s to mph. Otherwise, convert to km/h.
    return Cfg.Unit == "imperial" and mps * 2.2369 or mps * 3.6
end



---------------- Play Animation ----------------
--[[
    Plays an animation on the specified player ped.
    Requests and loads the animation dictionary, then plays the animation with the given parameters.
    Waits until the animation dictionary is loaded before playing.
    Params:
        playerPed (entity): The player ped to play the animation on
        animDict (string): The animation dictionary to load
        animation (string): The animation name to play
        duration (number): The duration of the animation
        flag (number): The animation flag to use
]]--
function PlayAnimation(playerPed, animDict, animation, duration, flag)
    RequestAnimDict(animDict)
    while not HasAnimDictLoaded(animDict) do
        Wait(300)
    end
    TaskPlayAnim(playerPed, animDict, animation, 8.0, -8.0, duration, flag, 0, false, false, false)
end



---------------- Show Progressbar ----------------
--[[
    Shows a progress bar to the player using the configured progress bar system.
    Supports both 'qb' and 'ox' progress bar libraries, depending on your Cfg.ProgressBar setting.
    Params:
        duration (number): How long the progress bar should last (in ms).
        label (string): The text label to show on the progress bar.
        config (table): Additional settings (e.g., Cancelable, FreezePlayer, FreezeCar).
    Returns:
        true if the progress bar was started (qb), or the result of lib.progressBar (ox).
]]--
function DisplayProgressBar(duration, label, config)
    if Cfg.ProgressBar == 'qb' then
        -- QBCore progress bar
        QBCore.Functions.Progressbar(
            "vehicle_maintenance",           -- Unique key for this progress bar
            label,                          -- Text to display
            duration,                       -- Duration in ms
            false,                          -- Not a repeating bar
            Cfg.Cancelable,              -- Can the player cancel?
            {
                disableMovement = Cfg.FreezePlayer,
                disableCarMovement = Cfg.FreezeCar,
                disableMouse = false,
                disableCombat = true,
            },
            {}, {}, {},                     -- Animation and prop tables (unused here)
            function() end,                 -- On success (empty)
            function() end                  -- On cancel (empty)
        )
        return true
    elseif Cfg.ProgressBar == 'ox' then
        -- ox_lib progress bar
        return lib.progressBar({
            duration = duration,
            label = label,
            useWhileDead = false,
            canCancel = Cfg.Cancelable,
            disable = {
                car = Cfg.FreezeCar,
                move = Cfg.FreezePlayer
            }
        })
    end
end



---------------- Check Inventory For Item ----------------
--[[
    Checks if the player has a specific inventory item, depending on the configured inventory system.
    Supports: ox_inventory, codem-inventory, qs-inventory, qb-core, es_extended.
    Returns true if the item is found, false otherwise.
    @param item (string): The item name to check for.
    @return (boolean): True if the player has the item, false otherwise.
]]--
function checkInventoryItem(item)
    local hasItem = false
    if Cfg.InventoryScript == 'ox' then
        hasItem = exports.ox_inventory:Search('count', item) > 0
    elseif Cfg.InventoryScript == 'codem' then
        hasItem = exports['codem-inventory']:HasItem(item, 1)
    elseif Cfg.InventoryScript == 'quasar' then
        local PlayerInv = exports['qs-inventory']:getUserInventory()
        for _, itemData in pairs(PlayerInv) do
            if itemData.name == item and itemData.amount > 0 then
                hasItem = true
                break
            end
        end
    elseif Cfg.InventoryScript == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
        local Player = core.Functions.GetPlayerData()
        for _, v in pairs(Player.items) do
            if v.name == item then
                hasItem = true
                break
            end
        end
    elseif Cfg.InventoryScript == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        local inventory = core.GetPlayerData().inventory
        for _, v in pairs(inventory) do
            if v.name == item and v.count > 0 then
                hasItem = true
                break
            end
        end
    end
    return hasItem
end



---------------- Get Closest Vehicle ----------------
--[[
    Finds the closest vehicle to the player within a given distance.
    Useful for service actions and part changes.
    @param maxDistance (number): The maximum distance to search for vehicles (default: 5.0).
    @return (vehicle, number): The closest vehicle entity and its distance from the player.
]]--
function GetClosestVehicle(maxDistance)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local vehicles = GetGamePool("CVehicle")
    local closestDistance = maxDistance or 5.0
    local closestVehicle = 0
    for _, veh in ipairs(vehicles) do
        local distance = #(playerCoords - GetEntityCoords(veh))
        if distance < closestDistance then
            closestDistance = distance
            closestVehicle = veh
        end
    end
    return closestVehicle, closestDistance
end



---------------- Request Prop ----------------
--[[
    Requests the model name and returns with model hash.
    @param modelNmae (string): The name of the model to request and load
    @return (modelHash): The HashKey of the modelName
]]--
function RequestProp(modelNmae)
    if not IsModelValid(modelNmae) then
        print("^1ERROR: Model not found: " .. modelNmae)
        return
    end
    local modelHash = GetHashKey(modelNmae)
    RequestModel(modelHash)
    while not HasModelLoaded(modelHash) do
        Wait(300)
    end
    return modelHash
end



---------------- Load Scaleform ----------------
--[[
    Requests the scaleform and returns with the loaded scaleform
    @param modelNmae (string): The name of the scaleform to request and load
    @return (scaleform): The loaded scaleform
]]--
function LoadScaleForm(scaleformName)
    local scaleform = RequestScaleformMovie(scaleformName)
    while not HasScaleformMovieLoaded(scaleform) do
        Wait(300)
    end
    return scaleform
end
