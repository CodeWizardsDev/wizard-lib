require("config")
lib.locale()
---------------- Send Debug Message ----------------
--[[
    This function prints debug messages to the server console if debugging is enabled in the Cfg.
    It is used throughout the script to help with troubleshooting and to provide detailed logs
    about script actions, database queries, and server events. Customers can enable or disable
    debug output by setting Cfg.Debug to true or false in the config file.
]]--
function debug(debugstats, scriptname, data)
    if debugstats then print("^7[^6" .. scriptname .. "^7] ^5" .. data) end
end



---------------- Update Checker ----------------
--[[
    This function fetches the content of a URL using either cURL or PerformHttpRequest.
    It returns the response body if the request is successful (HTTP status code 200).
    If cURL is enabled via the convar "use_curl", it uses cURL to fetch the URL.
    Otherwise, it falls back to PerformHttpRequest for compatibility with FiveM's HTTP request system.
    Customers can use this function to retrieve external data, such as version information or changelogs.
]]--
function fetchUrl(url)
    local response = {}
    local res, code = nil, nil
    if GetConvar("use_curl", "false") == "true" then
        local handle = io.popen("curl -s " .. url)
        if handle then
            local result = handle:read("*a")
            handle:close()
            return result
        end
    else
        local done = false
        PerformHttpRequest(url, function(statusCode, body, headers)
            res = statusCode == 200
            code = statusCode
            response[1] = body
            done = true
        end)
        while not done do
            Citizen.Wait(0)
        end
    end
    if res and code == 200 then
        return response[1]
    else
        return nil
    end
end

--[[
    This function compares two version strings (v1 and v2) and returns:
    - -1 if v1 < v2
    - 0 if v1 == v2
    - 1 if v1 > v2
    It splits the version strings into numeric components and compares them one by one.
    Customers can use this function to check if their script version is up to date compared to the latest version.
]]
function compareVersions(v1, v2)
    local function splitVersion(v)
        local t = {}
        for num in string.gmatch(v, "%d+") do
            table.insert(t, tonumber(num))
        end
        return t
    end
    local v1t = splitVersion(v1)
    local v2t = splitVersion(v2)
    for i = 1, math.max(#v1t, #v2t) do
        local n1 = v1t[i] or 0
        local n2 = v2t[i] or 0
        if n1 < n2 then
            return -1
        elseif n1 > n2 then
            return 1
        end
    end
    return 0
end

--[[
    This function checks if the specified Lua files are loaded in the current resource.
    It takes a resource name and a list of Lua file names, and returns a table indicating
    whether each file is loaded (true) or not (false).
    If the resource path cannot be determined, it prints an error message.
    Customers can use this function to verify that all necessary Lua files are loaded correctly.
]]--
function AreLuaFilesLoaded(resourceName, luaFileNames)
    local resourcePath = GetResourcePath(resourceName)
    if resourcePath then
        local loadedFiles = {}
        for _, luaFileName in ipairs(luaFileNames) do
            local fileExists = LoadResourceFile(resourceName, luaFileName) ~= nil
            loadedFiles[luaFileName] = fileExists
        end
        return loadedFiles
    else
        print("Script name is changed! please use the main script name to support me:(")
        return nil
    end
end

--[[
    This function checks the current script version against the latest version available online.
    It fetches the latest version and changelog from GitHub, compares it with the current version,
    and prints a message to the server console indicating whether the script is up to date or outdated.
    If the script is outdated, it also prints the latest version and changelog.
    Customers can use this function to ensure they are running the latest version of the " .. prefix .. " script.
]]
function checkVersion(resourceName, logo, prefix, latestVersionUrl, changelogUrl, luaFileNames)
    local currentVersion = GetResourceMetadata(resourceName, "version", 0)
    local latestVersion = fetchUrl(latestVersionUrl)

    local logo2 = (logo .. "\n\nCodeWizards Version Checker\n")
    
    if not latestVersion then
        print(logo2 .. "\n\n^7[^6" .. prefix .. "^7] ^8Failed to fetch latest version info.\n")
        return
    end
    latestVersion = latestVersion:gsub("%s+", "")

    if compareVersions(currentVersion, latestVersion) < 0 then
        print(logo2 .. "\n\n^7[^6" .. prefix .. "^7] ^5Your script version ^2(" .. currentVersion .. ") ^5is outdated. Latest version is ^2" .. latestVersion)
        local changelog = fetchUrl(changelogUrl)
        if changelog then
            print("^7[^6" .. prefix .. "^7] ^5Change log:^7\n" .. changelog .. "\n")
        else
            print("^7[^6" .. prefix .. "^7] ^8Failed to fetch changelog.\n")
        end
    else
        print(logo2 .. "\n\n                 ^5Script is up to date. Version: ^2" .. currentVersion .. "\n")
    end
    local results = AreLuaFilesLoaded(resourceName, luaFileNames)
    if results then
    for luaFileName, isLoaded in pairs(results) do
        if isLoaded then
            print("                   ^5The file '" .. luaFileName .. "' is loaded.^0")
        else
            print("                   ^8The file '" .. luaFileName .. "' is NOT loaded.^0")
        end
    end
    print("\n\n")
    end
end



---------------- Framework initialize ----------------
--[[
    This section initializes the framework (ESX or ND or QBCore or QBox) based on the Config settings.
    It sets up player data and job checks, and registers events for player loading.
    The CheckJob function returns the player's job name, grade, duty status, payment and checks if player is boss for use in service actions.
    The CheckGang function returns the player's gang name, grade and checks if player is boss for use in service actions.
]]--
if Cfg.FrameWork == 'esx' then
    ESX = exports["es_extended"]:getSharedObject()
    FW = 'esx'

    function CheckJob(src)
        local Player = ESX.GetPlayerFromId(src)
        if Player then
            Job = Player.job.name
            Grade = Player.job.grade
            return Job, Grade
        else
            debug(Cfg.Debug, "Wizard Lib", "Can't get the job information of player with id " .. src)
            return "unemployed", "0"
        end
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
    FW = 'nd'

    function CheckJob(src)
        local Player = NDCore.getPlayer(src)
        if Player then
            Job = Player.job
            Grade = Player.jobInfo.rank
            return Job, Grade
        else
            return "unemployed", "0"
        end
    end
else
    QBCore = exports['qb-core']:GetCoreObject()
    FW = 'qbcore'

    function CheckJob(src)
        Player = QBCore.Functions.GetPlayer(src)
        if Player then
            Job = Player.PlayerData.job.name
            Grade = Player.PlayerData.job.grade.level
            return Job, Grade
        else
            debug(Cfg.Debug, "Wizard Lib", "Can't get the job information of player with id " .. src)
            return "unemployed", "0"
        end
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
function Notify(src, script, message, type, defIcon)
    TriggerClientEvent('wizard-tracker:client:notify', src, script, message, type, defIcon)
end



---------------- Perm checker ----------------
--[[
    This function checks if the given player is an perm based on the configured permission.
    It is used to restrict access to perm-only features, such as the vehicle database or maintenance overrides.
    Returns true if the player has the required ace permission, otherwise returns false.
]]--
local function hasPerm(source, perm)
    local src = source
    if IsPlayerAceAllowed(src, perm) then
        return true
    end
    return false
end

--[[
    This event checks if the player has a permission and returns the result to the client.
    It uses the hasPerm function to determine if the player has the required ace permission.
    Customers can use this event to restrict access to certain features based on permission status.
]]--
RegisterNetEvent('wizard-lib:server:hasPerm')
AddEventHandler('wizard-lib:server:hasPerm', function(cbId, perm)
    local src = source
    local perm = hasPerm(src, perm)
    TriggerClientEvent('wizard-lib:client:hasPermCallback', src, cbId, perm)
end)


---------------- Check Inventory For Item ----------------
--[[
    Checks if the player has a specific inventory item, depending on the configured inventory system.
    Supports: ox_inventory, codem-inventory, qs-inventory, qb-core, es_extended.
    Returns true if the item is found, false otherwise.
    @param item (string): The item name to check for.
    @return (boolean): True if the player has the item, false otherwise.
]]--
function checkInventoryItem(id, item)
    local hasItem = false
    if Cfg.InventoryScript == 'ox' then
        hasItem = exports.ox_inventory:Search(id, 'count', item) > 0
    elseif Cfg.InventoryScript == 'codem' then
        hasItem = exports['codem-inventory']:HasItem(id, item, 1)
    elseif Cfg.InventoryScript == 'quasar' then
        local PlayerInv = exports['qs-inventory']:GetInventory(id)
        for _, itemData in pairs(PlayerInv) do
            if itemData.name == item and itemData.amount > 0 then
                hasItem = true
                break
            end
        end
    elseif Cfg.InventoryScript == 'qb' then
        QBCore = exports['qb-core']:GetCoreObject()
        local Player = QBCore.Functions.GetPlayer(id)
        for _, v in pairs(Player.items) do
            if v.name == item then
                hasItem = true
                break
            end
        end
    elseif Cfg.InventoryScript == 'esx' then
        ESX = exports['es_extended']:getSharedObject()
        local inventory = ESX.GetPlayerFromId(id).inventory
        for _, v in pairs(inventory) do
            if v.name == item and v.count > 0 then
                hasItem = true
                break
            end
        end
    end
    return hasItem
end


---------------- Inventory initialize ----------------
--[[
    This section initializes the inventory system based on the configured inventory script.
    It creates usable items for vehicle maintenance parts, allowing players to use these items
    to perform maintenance tasks on their vehicles.
    Customers can modify the item names and behaviors in the config file to suit their server's needs.
]]--
if Cfg.InventoryScript == 'ox' then
    function CreateUseableItem()
    end
elseif Cfg.InventoryScript == 'qb' then
    function CreateUseableItem(itemName, eType, event, eData)
        QBCore.Functions.CreateUseableItem(itemName, function(source, item)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player.Functions.GetItemByName(item.name) then return end
            if eType == 'client' then
                TriggerClientEvent(event, source, eData)
            elseif eType == 'server' then
                TriggerEvent(event, eData)
            end
        end)
    end
elseif Cfg.InventoryScript == 'quasar' then
    function CreateUseableItem(itemName, eType, event, eData)
        exports['qs-inventory']:CreateUsableItem(itemName, function(source, item)
            if eType == 'client' then
                TriggerClientEvent(event, source, eData)
            elseif eType == 'server' then
                TriggerEvent(event, eData)
            end
        end)
    end
elseif Cfg.InventoryScript == 'esx' then
    function CreateUseableItem(itemName, eType, event, eData)
        ESX.RegisterUsableItem(itemName, function(source)
            if eType == 'client' then
                TriggerClientEvent(event, source, eData)
            elseif eType == 'server' then
                TriggerEvent(event, eData)
            end
        end)
    end
end


---------------- Inventory initialize ----------------
function GetPlayersByJob(jobName, requesterJob, requesterGrade)
    local players = {}
    for _, playerId in pairs(GetPlayers()) do
        local playerJob, playerGrade = CheckJob(playerId)
        local playerName = GetPlayerName(playerId)

        if playerJob == jobName then
            table.insert(players, {id = playerId, job = playerJob, grade = playerGrade, name = playerName})
        elseif Config.AllowedJobs[requesterJob] and Config.AllowedJobs[requesterJob].TrackOthers then
            -- If allowed to track others, include players with other jobs
            table.insert(players, {id = playerId, job = playerJob, grade = playerGrade, name = playerName})
        end
    end
    return players
end