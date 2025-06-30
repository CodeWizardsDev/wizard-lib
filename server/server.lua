---------------- Main data ----------------
--[[
    These variables define the main Lua files that make up the Wizard Mileage resource.
    They are used for version checking, file integrity, and to ensure all necessary files are present and loaded.
    If you add, remove, or rename Lua files in this resource, update this list accordingly.
    Customers can reference this variable to understand which files are essential for the script to function.
]]--
local luaFileNames = {'client/events.lua', 'client/functions.lua', 'config.lua', 'server/events.lua', 'server/functions.lua', 'server/server.lua'}



AddEventHandler('onResourceStart', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        --checkVersion(GetCurrentResourceName(), logo, prefix, latestVersionUrl, changelogUrl, luaFileNames)
    end
end)