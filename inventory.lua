-- Inventory Bridge System
if IsDuplicityVersion() then -- Server side
    Bridge.Inventory = {}
    Bridge.InventoryName = nil
    
    -- Auto-detect inventory system
    local function DetectInventory()
        if Config.InventorySystem == 'auto' then
            if GetResourceState('ox_inventory') == 'started' then
                if Config.Debug then print('[tot_treasurehunt] Auto-detected: ox_inventory') end
                return 'ox_inventory'
            elseif GetResourceState('qb-inventory') == 'started' then
                if Config.Debug then print('[tot_treasurehunt] Auto-detected: qb-inventory') end
                return 'qb-inventory'
            elseif Bridge.FrameworkName == 'esx' then
                if Config.Debug then print('[tot_treasurehunt] Auto-detected: esx_default') end
                return 'esx_default'
            elseif Bridge.FrameworkName == 'qbcore' then
                if Config.Debug then print('[tot_treasurehunt] Auto-detected: qb_default') end
                return 'qb_default'
            else
                if Config.Debug then print('[tot_treasurehunt] Auto-detected: standalone') end
                return 'standalone'
            end
        else
            if Config.Debug then print('[tot_treasurehunt] Manual config: ' .. Config.InventorySystem) end
            return Config.InventorySystem
        end
    end
    
    -- Initialize inventory
    -- Initialize inventory
    local function InitInventory()
        Bridge.InventoryName = DetectInventory()
        
        if Bridge.InventoryName == 'ox_inventory' then
            Bridge.AddItem = function(source, item, count, metadata)
                local lowerItem = string.lower(item)
                local success = exports.ox_inventory:AddItem(source, lowerItem, count or 1, metadata or {})
                return success ~= nil and success ~= false
            end
            
            Bridge.RemoveItem = function(source, item, count, metadata)
                return exports.ox_inventory:RemoveItem(source, string.lower(item), count or 1, metadata)
            end
            
            Bridge.GetItemCount = function(source, item)
                return exports.ox_inventory:GetItemCount(source, string.lower(item))
            end
            
            Bridge.CanCarryItem = function(source, item, count)
                local lowerItem = string.lower(item)
                if string.find(lowerItem, 'weapon_') then
                    return true
                end
                return exports.ox_inventory:CanCarryItem(source, lowerItem, count or 1)
            end
            
        elseif Bridge.InventoryName == 'qb-inventory' then
            Bridge.AddItem = function(source, item, count, metadata)
                return exports['qb-inventory']:AddItem(source, item, count or 1, false, metadata or {})
            end
            
            Bridge.RemoveItem = function(source, item, count, metadata)
                return exports['qb-inventory']:RemoveItem(source, item, count or 1, false, metadata)
            end
            
            Bridge.GetItemCount = function(source, item)
                local items = exports['qb-inventory']:GetItemsByName(source, item)
                local count = 0
                for _, itemData in pairs(items or {}) do
                    count = count + itemData.amount
                end
                return count
            end
            
            Bridge.CanCarryItem = function(source, item, count)
                return exports['qb-inventory']:CanAddItem(source, item, count or 1)
            end
            
        elseif Bridge.InventoryName == 'esx_default' then
            Bridge.AddItem = function(source, item, count, metadata)
                local player = Bridge.GetPlayer(source)
                if not player then return false end
                count = count or 1
                local lowerItem = string.lower(item)
                if string.sub(lowerItem, 1, 7) == 'weapon_' then
                    player.addWeapon(item, 0)
                    return true
                else
                    local success = player.addInventoryItem(item, count)
                    return success ~= nil
                end
            end
            
            Bridge.RemoveItem = function(source, item, count, metadata)
                local player = Bridge.GetPlayer(source)
                if not player then return false end
                count = count or 1
                local lowerItem = string.lower(item)
                if string.sub(lowerItem, 1, 7) == 'weapon_' then
                    player.removeWeapon(item)
                    return true
                else
                    player.removeInventoryItem(item, count)
                    return true
                end
            end
            
            Bridge.GetItemCount = function(source, item)
                local player = Bridge.GetPlayer(source)
                if not player then return 0 end
                local lowerItem = string.lower(item)
                if string.sub(lowerItem, 1, 7) == 'weapon_' then
                    return player.hasWeapon(item) and 1 or 0
                else
                    local invItem = player.getInventoryItem(item)
                    return invItem and invItem.count or 0
                end
            end
            
            Bridge.CanCarryItem = function(source, item, count)
                local player = Bridge.GetPlayer(source)
                if not player then return false end
                local lowerItem = string.lower(item)
                if string.sub(lowerItem, 1, 7) == 'weapon_' then
                    return true
                end
                return player.canCarryItem(item, count or 1)
            end
            
        elseif Bridge.InventoryName == 'qb_default' then
            Bridge.AddItem = function(source, item, count, metadata)
                local player = Bridge.GetPlayer(source)
                return player and player.Functions.AddItem(item, count or 1, false, metadata or {}) or false
            end
            
            Bridge.RemoveItem = function(source, item, count, metadata)
                local player = Bridge.GetPlayer(source)
                return player and player.Functions.RemoveItem(item, count or 1, false) or false
            end
            
            Bridge.GetItemCount = function(source, item)
                local player = Bridge.GetPlayer(source)
                if not player then return 0 end
                local itemData = player.Functions.GetItemByName(item)
                return itemData and itemData.amount or 0
            end
            
            Bridge.CanCarryItem = function(source, item, count)
                local player = Bridge.GetPlayer(source)
                return player and true or false
            end
            
        else
            Bridge.AddItem = function(source, item, count, metadata)
                return true
            end
            
            Bridge.RemoveItem = function(source, item, count, metadata)
                return true
            end
            
            Bridge.GetItemCount = function(source, item)
                return 999
            end
            
            Bridge.CanCarryItem = function(source, item, count)
                return true
            end
        end
        
        if Config.Debug then
            print(('[tot_treasurehunt] Inventory system loaded: %s'):format(Bridge.InventoryName))
        end
    end
    
    -- Initialize on resource start
    InitInventory()
    
    -- Register usable items
    local function RegisterUsableItems()
        if Config.Debug then
            print('[tot_treasurehunt] Registering usable items for inventory: ' .. tostring(Bridge.InventoryName))
            print('[tot_treasurehunt] Framework: ' .. tostring(Bridge.FrameworkName))
        end
        
        if Bridge.InventoryName == 'ox_inventory' then
            if Config.Debug then
                print('[tot_treasurehunt] Registering items via ox_inventory hook')
            end
            exports.ox_inventory:registerHook('usingItem', function(payload)
                local itemName = payload.item and payload.item.name or payload.itemName
                local source = payload.source
                
                if Config.Debug then
                    print('[tot_treasurehunt] ox_inventory item used: ' .. tostring(itemName) .. ' by player ' .. tostring(source))
                end
                
                if not itemName then return end
                
                if itemName == 'treasure_map' then
                    TriggerClientEvent('tot_treasurehunt:client:mapItemUsed', source)
                    return false -- Don't consume item
                elseif itemName == 'compass' then
                    TriggerClientEvent('tot_treasurehunt:client:compassItemUsed', source)
                    return false -- Don't consume item
                elseif itemName == 'garden_shovel' then
                    TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
                    return false -- Don't consume item
                elseif itemName == 'chest_scanner' then
                    TriggerClientEvent('tot_treasurehunt:client:useScanner', source)
                    return false -- Don't consume item

                elseif itemName == 'shovel' then
                    TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
                    return false -- Don't consume item
                end
            end)
            
        elseif Bridge.InventoryName == 'esx_default' and Bridge.Framework then
            if Config.Debug then
                print('[tot_treasurehunt] Registering items via ESX RegisterUsableItem')
            end
            Bridge.Framework.RegisterUsableItem('treasure_map', function(source)
                if Config.Debug then
                    print('[tot_treasurehunt] treasure_map used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:mapItemUsed', source)
            end)
            
            Bridge.Framework.RegisterUsableItem('compass', function(source)
                if Config.Debug then
                    print('[tot_treasurehunt] compass used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:compassItemUsed', source)
            end)
            
            Bridge.Framework.RegisterUsableItem('garden_shovel', function(source)
                if Config.Debug then
                    print('[tot_treasurehunt] garden_shovel used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
            end)
            
            Bridge.Framework.RegisterUsableItem('chest_scanner', function(source)
                TriggerClientEvent('tot_treasurehunt:client:useScanner', source)
            end)
            
            
            Bridge.Framework.RegisterUsableItem('shovel', function(source)
                TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
            end)
            
        elseif (Bridge.InventoryName == 'qb_default' or Bridge.InventoryName == 'qb-inventory') and Bridge.Framework then
            if Config.Debug then
                print('[tot_treasurehunt] Registering items via QBCore CreateUseableItem')
            end
            Bridge.Framework.Functions.CreateUseableItem('treasure_map', function(source, item)
                if Config.Debug then
                    print('[tot_treasurehunt] treasure_map used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:mapItemUsed', source)
            end)
            
            Bridge.Framework.Functions.CreateUseableItem('compass', function(source, item)
                if Config.Debug then
                    print('[tot_treasurehunt] compass used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:compassItemUsed', source)
            end)
            
            Bridge.Framework.Functions.CreateUseableItem('garden_shovel', function(source, item)
                if Config.Debug then
                    print('[tot_treasurehunt] garden_shovel used by player ' .. source)
                end
                TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
            end)
            
            Bridge.Framework.Functions.CreateUseableItem('chest_scanner', function(source, item)
                TriggerClientEvent('tot_treasurehunt:client:useScanner', source)
            end)
            
            
            Bridge.Framework.Functions.CreateUseableItem('shovel', function(source, item)
                TriggerClientEvent('tot_treasurehunt:client:useShovel', source)
            end)
        else
            if Config.Debug then
                print('[tot_treasurehunt] WARNING: No matching inventory system found!')
                print('[tot_treasurehunt] Bridge.InventoryName: ' .. tostring(Bridge.InventoryName))
                print('[tot_treasurehunt] Bridge.Framework: ' .. tostring(Bridge.Framework))
            end
        end
        
        if Config.Debug then
            print('[tot_treasurehunt] Usable items registration complete')
        end
    end
    
    -- Wait a bit before registering items to ensure framework is loaded
    SetTimeout(1000, RegisterUsableItems)

else -- Client side
    Bridge.Inventory = {}
    Bridge.InventoryName = nil
    
    -- Auto-detect inventory system
    local function DetectInventory()
        if Config.InventorySystem == 'auto' then
            if GetResourceState('ox_inventory') == 'started' then
                return 'ox_inventory'
            elseif GetResourceState('qb-inventory') == 'started' then
                return 'qb-inventory'
            elseif Bridge.FrameworkName == 'esx' then
                return 'esx_default'
            elseif Bridge.FrameworkName == 'qbcore' then
                return 'qb_default'
            else
                return 'standalone'
            end
        else
            return Config.InventorySystem
        end
    end
    
    -- Initialize inventory
    CreateThread(function()
        while not Bridge.FrameworkName do
            Wait(100)
        end
        
        Bridge.InventoryName = DetectInventory()
        
        if Config.Debug then
            print(('[tot_treasurehunt] Client Inventory system loaded: %s'):format(Bridge.InventoryName))
        end
    end)
end


