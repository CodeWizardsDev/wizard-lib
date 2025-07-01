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
else
    QBCore = exports['qb-core']:GetCoreObject()
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
