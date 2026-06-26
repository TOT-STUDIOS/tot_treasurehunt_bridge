Config = {}

-- Framework Configuration
Config.Framework = 'auto' -- 'esx', 'qbcore', 'standalone', 'auto' (auto-detect)

-- Target System Configuration  
Config.TargetSystem = 'auto' -- 'ox_target', 'qb-target', 'auto' (auto-detect)

-- Inventory System Configuration
Config.InventorySystem = 'auto' -- 'ox_inventory', 'qb-inventory', 'auto' (auto-detect)

-- Notification Settings
Config.Notifications = {
    position = 'top-right',
    duration = 5000
}

-- Debug Mode
Config.Debug = false

-- Global print override to respect Config.Debug
local originalPrint = print
function print(...)
    if Config and Config.Debug then
        originalPrint(...)
    else
        -- Still print critical resource errors/warnings so administrators know if setup is broken
        local args = {...}
        if #args > 0 and type(args[1]) == 'string' then
            local lowerArg = args[1]:lower()
            if lowerArg:find('error') or lowerArg:find('warning') or lowerArg:find('fail') then
                originalPrint(...)
            end
        end
    end
end
