-- Bridge system for framework compatibility
if IsDuplicityVersion() then -- Server side
    Bridge = {}
    Bridge.Framework = nil
    Bridge.FrameworkName = nil
    
    -- Auto-detect framework
    local function DetectFramework()
        if Config.Framework == 'auto' then
            if GetResourceState('es_extended') == 'started' then
                return 'esx'
            elseif GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
                return 'qbcore'
            else
                return 'standalone'
            end
        else
            return Config.Framework
        end
    end
    
    -- Initialize framework
    -- Initialize framework
    local function InitFramework()
        Bridge.FrameworkName = DetectFramework()
        
        if Bridge.FrameworkName == 'esx' then
            Bridge.Framework = exports['es_extended']:getSharedObject()
            
            Bridge.GetPlayer = function(source)
                return Bridge.Framework.GetPlayerFromId(source)
            end
            
            Bridge.GetIdentifier = function(source)
                local player = Bridge.Framework.GetPlayerFromId(source)
                return player and player.identifier or nil
            end
            
            Bridge.GetMoney = function(source, account)
                local player = Bridge.Framework.GetPlayerFromId(source)
                if not player then return 0 end
                account = account or 'money'
                if account == 'money' or account == 'cash' then
                    return player.getMoney() or 0
                elseif account == 'bank' then
                    return player.getAccount('bank').money or 0
                end
                return player.getMoney() or 0
            end
            
            Bridge.RemoveMoney = function(source, amount, account, reason)
                local player = Bridge.Framework.GetPlayerFromId(source)
                if not player then return false end
                account = account or 'money'
                if account == 'money' or account == 'cash' then
                    player.removeMoney(amount)
                elseif account == 'bank' then
                    player.removeAccountMoney('bank', amount)
                end
                return true
            end
            
            Bridge.AddMoney = function(source, amount, account, reason)
                local player = Bridge.Framework.GetPlayerFromId(source)
                if not player then return false end
                account = account or 'money'
                if account == 'money' or account == 'cash' then
                    player.addMoney(amount)
                elseif account == 'bank' then
                    player.addAccountMoney('bank', amount)
                end
                return true
            end
            
        elseif Bridge.FrameworkName == 'qbcore' then
            Bridge.Framework = exports['qb-core']:GetCoreObject() or exports['qbx_core']:GetCoreObject()
            
            Bridge.GetPlayer = function(source)
                return Bridge.Framework.Functions.GetPlayer(source)
            end
            
            Bridge.GetIdentifier = function(source)
                local player = Bridge.Framework.Functions.GetPlayer(source)
                return player and player.PlayerData.citizenid or nil
            end
            
            Bridge.GetMoney = function(source, account)
                local player = Bridge.Framework.Functions.GetPlayer(source)
                if not player then return 0 end
                account = account or 'cash'
                if account == 'money' then account = 'cash' end
                return player.PlayerData.money[account] or 0
            end
            
            Bridge.RemoveMoney = function(source, amount, account, reason)
                local player = Bridge.Framework.Functions.GetPlayer(source)
                if not player then return false end
                account = account or 'cash'
                if account == 'money' then account = 'cash' end
                reason = reason or 'Treasure Hunt'
                return player.Functions.RemoveMoney(account, amount, reason)
            end
            
            Bridge.AddMoney = function(source, amount, account, reason)
                local player = Bridge.Framework.Functions.GetPlayer(source)
                if not player then return false end
                account = account or 'cash'
                if account == 'money' then account = 'cash' end
                reason = reason or 'Treasure Hunt Refund'
                return player.Functions.AddMoney(account, amount, reason)
            end
            
        elseif Bridge.FrameworkName == 'standalone' then
            Bridge.Framework = nil
            
            Bridge.GetPlayer = function(source)
                return {
                    source = source,
                    identifier = GetPlayerIdentifiers(source)[1] or 'unknown'
                }
            end
            
            Bridge.GetIdentifier = function(source)
                return GetPlayerIdentifiers(source)[1] or 'unknown'
            end
            
            Bridge.GetMoney = function(source, account)
                return 99999
            end
            
            Bridge.RemoveMoney = function(source, amount, account, reason)
                return true
            end
            
            Bridge.AddMoney = function(source, amount, account, reason)
                return true
            end
        end
        
        if Config.Debug then
            print(('[tot_treasurehunt] Framework loaded: %s'):format(Bridge.FrameworkName))
            print(('[tot_treasurehunt] Framework object: %s'):format(tostring(Bridge.Framework)))
        end
    end
    
    -- Initialize on resource start
    InitFramework()
    
else -- Client side
    Bridge = {}
    Bridge.Framework = nil
    Bridge.FrameworkName = nil
    Bridge.PlayerLoaded = false
    Bridge.PlayerData = {}
    
    -- Auto-detect framework
    local function DetectFramework()
        if Config.Framework == 'auto' then
            if GetResourceState('es_extended') == 'started' then
                return 'esx'
            elseif GetResourceState('qb-core') == 'started' or GetResourceState('qbx_core') == 'started' then
                return 'qbcore'
            else
                return 'standalone'
            end
        else
            return Config.Framework
        end
    end
    
    -- Initialize framework
    local function InitFramework()
        Bridge.FrameworkName = DetectFramework()
        
        if Bridge.FrameworkName == 'esx' then
            Bridge.Framework = exports['es_extended']:getSharedObject()
            
            -- Hot-reload support
            if Bridge.Framework.IsPlayerLoaded and Bridge.Framework.IsPlayerLoaded() then
                Bridge.PlayerLoaded = true
                Bridge.PlayerData = Bridge.Framework.GetPlayerData()
            end
            
            -- ESX events
            RegisterNetEvent('esx:playerLoaded', function(xPlayer)
                Bridge.PlayerLoaded = true
                Bridge.PlayerData = xPlayer
            end)
            
            RegisterNetEvent('esx:setJob', function(job)
                if Bridge.PlayerData then
                    Bridge.PlayerData.job = job
                end
            end)
            
        elseif Bridge.FrameworkName == 'qbcore' then
            Bridge.Framework = exports['qb-core']:GetCoreObject() or exports['qbx_core']:GetCoreObject()
            
            -- Hot-reload support
            if LocalPlayer and LocalPlayer.state and LocalPlayer.state.isLoggedIn then
                Bridge.PlayerLoaded = true
                Bridge.PlayerData = Bridge.Framework.Functions.GetPlayerData()
            end
            
            -- QBCore events
            RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
                Bridge.PlayerLoaded = true
                Bridge.PlayerData = Bridge.Framework.Functions.GetPlayerData()
            end)
            
            RegisterNetEvent('QBCore:Player:SetPlayerData', function(val)
                Bridge.PlayerData = val
            end)
            
        elseif Bridge.FrameworkName == 'standalone' then
            Bridge.Framework = nil
            Bridge.PlayerLoaded = true
            Bridge.PlayerData = { source = GetPlayerServerId(PlayerId()) }
        end
        
        if Config.Debug then
            print(('[tot_treasurehunt] Client Framework loaded: %s'):format(Bridge.FrameworkName))
        end
    end
    
    -- Initialize framework immediately on script start
    InitFramework()
    
    -- Get player data
    Bridge.GetPlayerData = function()
        return Bridge.PlayerData
    end
    
    -- Check if player is loaded
    Bridge.IsPlayerLoaded = function()
        return Bridge.PlayerLoaded
    end
end

-- Exports
exports('GetBridge', function()
    return Bridge
end)
