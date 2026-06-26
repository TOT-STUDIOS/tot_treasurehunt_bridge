-- Target Bridge System (Client-side only)
if not IsDuplicityVersion() then
    Bridge.Target = {}
    Bridge.TargetName = nil
    
    -- Auto-detect target system
    local function DetectTarget()
        if Config.TargetSystem == 'auto' then
            if GetResourceState('ox_target') == 'started' then
                return 'ox_target'
            elseif GetResourceState('qb-target') == 'started' then
                return 'qb-target'
            else
                return 'none'
            end
        else
            return Config.TargetSystem
        end
    end
    
    -- Initialize target system
    -- Initialize target system
    local function InitTarget()
        Bridge.TargetName = DetectTarget()
        
        if Bridge.TargetName == 'ox_target' then
            Bridge.AddTargetEntity = function(entity, options)
                exports.ox_target:addLocalEntity(entity, options)
            end
            
            Bridge.RemoveTargetEntity = function(entity, label)
                exports.ox_target:removeLocalEntity(entity, label)
            end
            
            Bridge.AddTargetModel = function(models, options)
                exports.ox_target:addModel(models, options)
            end
            
            Bridge.RemoveTargetModel = function(models, label)
                exports.ox_target:removeModel(models, label)
            end
            
            Bridge.AddTargetCoords = function(coords, options)
                return exports.ox_target:addBoxZone({
                    coords = coords,
                    size = options.size or vec3(2, 2, 2),
                    rotation = options.rotation or 0,
                    options = options
                })
            end
            
            Bridge.RemoveZone = function(id)
                exports.ox_target:removeZone(id)
            end
            
            Bridge.DisableTarget = function()
                exports.ox_target:disableTargeting(true)
            end
            
            Bridge.EnableTarget = function()
                exports.ox_target:disableTargeting(false)
            end
            
        elseif Bridge.TargetName == 'qb-target' then
            Bridge.AddTargetEntity = function(entity, options)
                local qbOptions = {}
                for i, option in ipairs(options) do
                    qbOptions[#qbOptions + 1] = {
                        type = 'client',
                        event = option.onSelect and 'tot_treasurehunt:client:targetCallback' or nil,
                        action = option.onSelect,
                        icon = option.icon,
                        label = option.label,
                        canInteract = option.canInteract
                    }
                end
                
                exports['qb-target']:AddTargetEntity(entity, {
                    options = qbOptions,
                    distance = options.distance or 2.5
                })
            end
            
            Bridge.RemoveTargetEntity = function(entity, label)
                exports['qb-target']:RemoveTargetEntity(entity, label)
            end
            
            Bridge.AddTargetModel = function(models, options)
                local qbOptions = {}
                for i, option in ipairs(options) do
                    qbOptions[#qbOptions + 1] = {
                        type = 'client',
                        event = option.onSelect and 'tot_treasurehunt:client:targetCallback' or nil,
                        action = option.onSelect,
                        icon = option.icon,
                        label = option.label,
                        canInteract = option.canInteract
                    }
                end
                
                exports['qb-target']:AddTargetModel(models, {
                    options = qbOptions,
                    distance = options.distance or 2.5
                })
            end
            
            Bridge.RemoveTargetModel = function(models, label)
                exports['qb-target']:RemoveTargetModel(models, label)
            end
            
            Bridge.AddTargetCoords = function(coords, options)
                local qbOptions = {}
                for i, option in ipairs(options) do
                    qbOptions[#qbOptions + 1] = {
                        type = 'client',
                        event = option.onSelect and 'tot_treasurehunt:client:targetCallback' or nil,
                        action = option.onSelect,
                        icon = option.icon,
                        label = option.label,
                        canInteract = option.canInteract
                    }
                end
                
                return exports['qb-target']:AddBoxZone('treasurehunt_' .. math.random(1000, 9999), coords, 
                    options.size and options.size.x or 2.0, 
                    options.size and options.size.y or 2.0, {
                    name = 'treasurehunt_' .. math.random(1000, 9999),
                    heading = options.rotation or 0,
                    debugPoly = false,
                    minZ = coords.z - 1.0,
                    maxZ = coords.z + 1.0,
                }, {
                    options = qbOptions,
                    distance = options.distance or 2.5
                })
            end
            
            Bridge.RemoveZone = function(id)
                exports['qb-target']:RemoveZone(id)
            end
            
            Bridge.DisableTarget = function()
                exports['qb-target']:AllowTargeting(false)
            end
            
            Bridge.EnableTarget = function()
                exports['qb-target']:AllowTargeting(true)
            end
            
        else
            Bridge.AddTargetEntity = function(entity, options) end
            Bridge.RemoveTargetEntity = function(entity, label) end
            Bridge.AddTargetModel = function(models, options) end
            Bridge.RemoveTargetModel = function(models, label) end
            Bridge.AddTargetCoords = function(coords, options) return nil end
            Bridge.RemoveZone = function(id) end
            Bridge.DisableTarget = function() end
            Bridge.EnableTarget = function() end
        end
        
        if Config.Debug then
            print(('[tot_treasurehunt] Target system loaded: %s'):format(Bridge.TargetName))
        end
    end
    
    -- Add target interaction handler for qb-target compatibility
    RegisterNetEvent('tot_treasurehunt:client:targetCallback', function(data)
        if data.action then
            data.action(data)
        end
    end)
    
    -- Initialize target system
    CreateThread(function()
        while not Bridge.FrameworkName do
            Wait(100)
        end
        InitTarget()
    end)

else -- Server side
    Bridge.Target = {}
    Bridge.TargetName = 'server' -- Placeholder for server side
end


