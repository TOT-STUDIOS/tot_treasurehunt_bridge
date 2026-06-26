-- Notification Bridge System
if IsDuplicityVersion() then -- Server side
    Bridge.Notify = {}
    
    -- Send notification to specific player
    Bridge.Notify.Player = function(source, message, type, duration)
        TriggerClientEvent('tot_treasurehunt:client:notify', source, message, type, duration)
    end
    
    -- Send notification to all players
    Bridge.Notify.All = function(message, type, duration)
        TriggerClientEvent('tot_treasurehunt:client:notify', -1, message, type, duration)
    end
    
else -- Client side
    Bridge.Notify = {}
    
    -- Send notification and progress bar initialization
    local function InitNotify()
        -- Try ox_lib first (most universal)
        if GetResourceState('ox_lib') == 'started' and lib then
            Bridge.Notify.Send = function(message, type, duration)
                lib.notify({
                    title = 'Treasure Hunt',
                    description = message,
                    type = type or 'info',
                    duration = duration or Config.Notifications.duration,
                    position = Config.Notifications.position or 'top-right'
                })
            end
            
        -- ESX notifications
        elseif Bridge.FrameworkName == 'esx' and GetResourceState('esx_notify') == 'started' then
            Bridge.Notify.Send = function(message, type, duration)
                exports['esx_notify']:Notify(type or 'info', duration or Config.Notifications.duration, message)
            end
            
        elseif Bridge.FrameworkName == 'esx' and Bridge.Framework then
            Bridge.Notify.Send = function(message, type, duration)
                Bridge.Framework.ShowNotification(message)
            end
            
        -- QBCore notifications
        elseif Bridge.FrameworkName == 'qbcore' and GetResourceState('qb-notify') == 'started' then
            Bridge.Notify.Send = function(message, type, duration)
                exports['qb-notify']:Alert('Treasure Hunt', message, duration or Config.Notifications.duration, type or 'info')
            end
            
        elseif Bridge.FrameworkName == 'qbcore' and Bridge.Framework then
            Bridge.Notify.Send = function(message, type, duration)
                Bridge.Framework.Functions.Notify(message, type or 'info', duration or Config.Notifications.duration)
            end
            
        -- Fallback to chat message
        else
            Bridge.Notify.Send = function(message, type, duration)
                type = type or 'info'
                local color = {r = 255, g = 255, b = 255}
                if type == 'error' then
                    color = {r = 255, g = 0, b = 0}
                elseif type == 'success' then
                    color = {r = 0, g = 255, b = 0}
                elseif type == 'warning' then
                    color = {r = 255, g = 165, b = 0}
                end
                
                TriggerEvent('chat:addMessage', {
                    color = color,
                    multiline = true,
                    args = {'[Treasure Hunt]', message}
                })
            end
        end

        -- Determine ProgressBar function
        if GetResourceState('ox_lib') == 'started' and lib then
            -- Use ox_lib progress bar
            Bridge.ProgressBar = function(data)
                return lib.progressBar({
                    duration = data.duration,
                    label = data.label,
                    useWhileDead = false,
                    canCancel = data.canCancel or true,
                    disable = data.disable or {
                        car = true,
                        move = true,
                        combat = true
                    },
                    anim = data.anim or {
                        dict = 'random@domestic',
                        clip = 'pickup_low',
                        flag = 1
                    },
                    prop = data.prop or nil
                })
            end
            
        elseif Bridge.FrameworkName == 'qbcore' and GetResourceState('progressbar') == 'started' then
            -- Use QBCore progress bar
            Bridge.ProgressBar = function(data)
                local finished = false
                local success = false
                
                exports['progressbar']:Progress({
                    name = data.name or 'treasurehunt_progress',
                    duration = data.duration,
                    label = data.label,
                    useWhileDead = false,
                    canCancel = data.canCancel or true,
                    controlDisables = data.disable or {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true
                    },
                    animation = data.anim or {
                        animDict = 'random@domestic',
                        anim = 'pickup_low',
                        flags = 1
                    },
                    prop = data.prop or nil
                }, function(cancelled)
                    finished = true
                    success = not cancelled
                end)
                
                -- Wait for progress to finish
                while not finished do
                    Wait(10)
                end
                
                return success
            end
            
        elseif Bridge.FrameworkName == 'esx' and GetResourceState('esx_progressbar') == 'started' then
            -- Use ESX progress bar
            Bridge.ProgressBar = function(data)
                local finished = false
                local success = false
                
                exports['esx_progressbar']:Progressbar(data.label, data.duration, {
                    FreezePlayer = true,
                    onFinish = function()
                        finished = true
                        success = true
                    end,
                    onCancel = function()
                        finished = true
                        success = false
                    end
                })
                
                -- Wait for progress to finish
                while not finished do
                    Wait(10)
                end
                
                return success
            end
            
        else
            -- Fallback: simple wait with animation
            Bridge.ProgressBar = function(data)
                if data.anim then
                    local ped = PlayerPedId()
                    if data.anim.dict and data.anim.clip then
                        RequestAnimDict(data.anim.dict)
                        while not HasAnimDictLoaded(data.anim.dict) do
                            Wait(10)
                        end
                        TaskPlayAnim(ped, data.anim.dict, data.anim.clip, 8.0, 8.0, -1, data.anim.flag or 1, 0, false, false, false)
                    end
                end
                
                local startTime = GetGameTimer()
                while GetGameTimer() - startTime < data.duration do
                    if data.canCancel and IsControlJustPressed(0, 200) then -- ESC key
                        if data.anim then
                            StopAnimTask(PlayerPedId(), data.anim.dict, data.anim.clip, 1.0)
                        end
                        return false
                    end
                    Wait(10)
                end
                
                if data.anim then
                    StopAnimTask(PlayerPedId(), data.anim.dict, data.anim.clip, 1.0)
                end
                
                return true
            end
        end
    end
    
    -- Initialize bindings once framework is loaded
    CreateThread(function()
        while not Bridge.FrameworkName do
            Wait(10)
        end
        InitNotify()
    end)
    
    -- Notification type shortcuts
    Bridge.Notify.Success = function(message, duration)
        if Bridge.Notify.Send then
            Bridge.Notify.Send(message, 'success', duration)
        end
    end
    
    -- Notification type shortcuts (continued)
    Bridge.Notify.Error = function(message, duration)
        if Bridge.Notify.Send then
            Bridge.Notify.Send(message, 'error', duration)
        end
    end
    
    Bridge.Notify.Warning = function(message, duration)
        if Bridge.Notify.Send then
            Bridge.Notify.Send(message, 'warning', duration)
        end
    end
    
    Bridge.Notify.Info = function(message, duration)
        if Bridge.Notify.Send then
            Bridge.Notify.Send(message, 'info', duration)
        end
    end
    
    -- Register notification event
    RegisterNetEvent('tot_treasurehunt:client:notify', function(message, type, duration)
        if Bridge.Notify.Send then
            Bridge.Notify.Send(message, type, duration)
        end
    end)
end


