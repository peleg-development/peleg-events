local isUIOpen = false
currentEventId = nil
local isInEvent = false
local infiniteAmmo = false
local globalJoinPanelVisible = false
local eventJoinPanelVisible = false
local currentJoinEventId = nil
joinedEventId = nil

--- Show a notification in the NUI
--- @param type string Notification type: success|error|warning|info
--- @param message string Notification message
local function showNotification(type, message)
    SendNUIMessage({ action = "showGlobalNotification", type = type, message = message })
end

--- Toggle the main Events UI
--- @param enabled boolean Whether to show the UI
local function toggleUI(enabled)
    isUIOpen = enabled
    SetNuiFocus(enabled, enabled)
    SendNUIMessage({ action = "setVisible", visible = enabled })
end

--- Block inventory during events
--- @param blocked boolean Whether to block inventory access
local function blockInventory(blocked)
    if blocked then
        -- QB-Core inventory blocking
        if GetResourceState('qb-inventory') == 'started' then
            exports['qb-inventory']:SetInventoryBlocked(true)
        end
        
        -- ox_inventory blocking
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:SetInventoryBlocked(true)
        end
        
        -- qs-inventory blocking
        if GetResourceState('qs-inventory') == 'started' then
            exports['qs-inventory']:SetInventoryBlocked(true)
        end
    else
        -- QB-Core inventory unblocking
        if GetResourceState('qb-inventory') == 'started' then
            exports['qb-inventory']:SetInventoryBlocked(false)
        end
        
        -- ox_inventory unblocking
        if GetResourceState('ox_inventory') == 'started' then
            exports.ox_inventory:SetInventoryBlocked(false)
        end
        
        -- qs-inventory unblocking
        if GetResourceState('qs-inventory') == 'started' then
            exports['qs-inventory']:SetInventoryBlocked(false)
        end
    end
end

--- Open the UI and refresh events
RegisterNetEvent('peleg-events:openUI', function()
    toggleUI(true)
    TriggerServerEvent('peleg-events:getActiveEvents')
end)

--- Proxy for small toast notifications
--- @param type string
--- @param message string
RegisterNetEvent('peleg-events:notification', function(type, message)
    showNotification(type, message)
end)

--- Show per-event join panel
--- @param data {event: table, deadline: number}
RegisterNetEvent('peleg-events:showEventJoinPanel', function(data)
    eventJoinPanelVisible = true
    currentJoinEventId = data.event.id
    SendNUIMessage({
        action = "showEventJoinPanel",
        event = data.event,
        deadline = data.deadline,
        hasJoined = (joinedEventId == data.event.id)
    })
end)

--- Hide per-event join panel
RegisterNetEvent('peleg-events:hideEventJoinPanel', function()
    eventJoinPanelVisible = false
    currentJoinEventId = nil
    SendNUIMessage({ action = "hideEventJoinPanel" })
end)

--- Show global join panel
--- @param data {event: table, deadline: number}
RegisterNetEvent('peleg-events:showGlobalEventJoinPanel', function(data)
    globalJoinPanelVisible = true
    currentJoinEventId = data.event.id
    SendNUIMessage({
        action = "showGlobalEventJoinPanel",
        event = data.event,
        deadline = data.deadline,
        hasJoined = (joinedEventId == data.event.id)
    })
end)

--- Hide global join panel
RegisterNetEvent('peleg-events:hideGlobalEventJoinPanel', function()
    globalJoinPanelVisible = false
    currentJoinEventId = nil
    SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
end)

--- Give vehicle keys based on detected framework
--- @param vehicle number Vehicle entity id
RegisterNetEvent('peleg-events:giveVehicleKeys', function(vehicle)
    local ESX = Framework.Detect("esx")
    if ESX then
        SetVehicleHasBeenOwnedByPlayer(vehicle, true)
        SetVehicleNeedsToBeHotwired(vehicle, false)
        return
    end

    local QBCore = Framework.Detect("qbcore")
    if QBCore then
        TriggerEvent('vehiclekeys:client:SetOwner', GetVehicleNumberPlateText(vehicle))
        return
    end

    SetVehicleHasBeenOwnedByPlayer(vehicle, true)
    SetVehicleNeedsToBeHotwired(vehicle, false)
end)

--- Receive active events list from server
--- @param events table
RegisterNetEvent('peleg-events:activeEventsData', function(events)
    SendNUIMessage({
        action = "updateEvents",
        events = events,
        currentPlayerId = GetPlayerServerId(PlayerId())
    })
end)

--- Client acknowledgment that event was created
--- @param eventId string
RegisterNetEvent('peleg-events:eventCreated', function(eventId)
    currentEventId = eventId
    SendNUIMessage({ action = "eventCreated", eventId = eventId })
end)

--- A player joined the event; update UI state
--- @param eventId string
--- @param playerId number
--- @param playerName string
RegisterNetEvent('peleg-events:playerJoined', function(eventId, playerId, playerName)
    if playerId == GetPlayerServerId(PlayerId()) then
        joinedEventId = eventId
        isInEvent = true
        
        -- Block inventory when joining event
        blockInventory(true)
        
        if globalJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateGlobalEventJoinPanel", hasJoined = true })
        elseif eventJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateEventJoinPanel", hasJoined = true })
        end
        
        -- Hide any join panels when player joins an event
        if globalJoinPanelVisible or eventJoinPanelVisible then
            globalJoinPanelVisible = false
            eventJoinPanelVisible = false
            currentJoinEventId = nil
            SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
            SendNUIMessage({ action = "hideEventJoinPanel" })
        end
    end

    SendNUIMessage({ action = "playerJoined", eventId = eventId, playerId = playerId, playerName = playerName })
end)

--- A player left the event; update UI state
--- @param eventId string
--- @param playerId number
RegisterNetEvent('peleg-events:playerLeft', function(eventId, playerId)
    if playerId == GetPlayerServerId(PlayerId()) then
        if joinedEventId == eventId then 
            joinedEventId = nil 
            isInEvent = false
            
            -- Unblock inventory when leaving event
            blockInventory(false)
        end
        if globalJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateGlobalEventJoinPanel", hasJoined = false })
        elseif eventJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateEventJoinPanel", hasJoined = false })
        end
    end

    SendNUIMessage({ action = "playerLeft", eventId = eventId, playerId = playerId })
end)

--- A player was eliminated; push to feed
--- @param eventId string
--- @param playerId number
--- @param playerName string
RegisterNetEvent('peleg-events:playerEliminated', function(eventId, playerId, playerName)
    SendNUIMessage({ action = "playerEliminated", eventId = eventId, playerId = playerId, playerName = playerName })
end)



RegisterNetEvent('peleg-events:carSumoStarted', function(eventId)
    if currentEventId == eventId then
        isInEvent = true
        
        -- Block inventory when event starts
        blockInventory(true)
        
        FreezeEntityPosition(PlayerPedId(), false)
        if globalJoinPanelVisible or eventJoinPanelVisible then
            globalJoinPanelVisible = false
            eventJoinPanelVisible = false
            currentJoinEventId = nil
            SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
            SendNUIMessage({ action = "hideEventJoinPanel" })
        end
        SendNUIMessage({ type = "carSumoStarted", eventId = eventId })
    end
end)

RegisterNetEvent('peleg-events:redzoneCountdown', function(eventId, duration)
    if currentEventId == eventId or joinedEventId == eventId then
        SendNUIMessage({ action = "showCountdown", eventId = eventId, countdown = duration })
    end
end)

RegisterNetEvent('peleg-events:redzoneStarted', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        isInEvent = true
        
        -- Block inventory when event starts
        blockInventory(true)
        
        if globalJoinPanelVisible or eventJoinPanelVisible then
            globalJoinPanelVisible = false
            eventJoinPanelVisible = false
            currentJoinEventId = nil
            SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
            SendNUIMessage({ action = "hideEventJoinPanel" })
        end
        SendNUIMessage({ type = "redzoneStarted", eventId = eventId })
    end
end)

--- Car Sumo event ended for this client
--- @param eventId string
RegisterNetEvent('peleg-events:carSumoEventEnded', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        isInEvent = false
        currentEventId = nil
        joinedEventId = nil
        
        -- Unblock inventory when event ends
        blockInventory(false)
        
        print("^3[Client] Car Sumo event ended^7")
    end
end)

--- Redzone event ended for this client
--- @param eventId string
RegisterNetEvent('peleg-events:redzoneEventEnded', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        isInEvent = false
        currentEventId = nil
        joinedEventId = nil
        
        -- Unblock inventory when event ends
        blockInventory(false)
        
        print("^3[Client] Redzone event ended^7")
    end
end)

--- Show scoreboard and reset local event state
--- @param scoreboardData {eventId:string, eventType:string, players:table, duration:number}
RegisterNetEvent('peleg-events:showScoreboard', function(scoreboardData)
    isInEvent = false
    currentEventId = nil
    joinedEventId = nil
    
    -- Unblock inventory when event ends
    blockInventory(false)
    
    SendNUIMessage({
        action = "showScoreboard",
        eventId = scoreboardData.eventId,
        eventType = scoreboardData.eventType,
        players = scoreboardData.players,
        duration = scoreboardData.duration
    })
end)

--- Update kills counter UI
--- @param killsData {kills:number, isVisible:boolean}
RegisterNetEvent('peleg-events:updateKillsCounter', function(killsData)
    SendNUIMessage({ action = "updateKillsCounter", kills = killsData.kills, isVisible = killsData.isVisible })
end)

--- Hide kills counter UI
RegisterNetEvent('peleg-events:hideKillsCounter', function()
    SendNUIMessage({ action = "hideKillsCounter" })
end)

--- Add entry to kill feed UI
--- @param killData {killer:string, victim:string, eventType:string}
RegisterNetEvent('peleg-events:addKillFeed', function(killData)
    SendNUIMessage({ action = "addKillFeed", killer = killData.killer, victim = killData.victim, eventType = killData.eventType })
end)

--- NUI: close UI
RegisterNUICallback('closeUI', function(_, cb)
    toggleUI(false)
    cb('ok')
end)

--- NUI: create event
RegisterNUICallback('createEvent', function(data, cb)
    TriggerServerEvent('peleg-events:createEvent', data.eventType, data.maxPlayers, data.rewardType, data.rewardData, data.customSettings)
    cb('ok')
end)

--- NUI: join event
RegisterNUICallback('joinEvent', function(data, cb)
    TriggerServerEvent('peleg-events:joinEvent', data.eventId)
    cb('ok')
end)

--- NUI: leave event
RegisterNUICallback('leaveEvent', function(data, cb)
    TriggerServerEvent('peleg-events:leaveEvent', data.eventId)
    cb('ok')
end)

--- NUI: start event (host)
RegisterNUICallback('startEvent', function(data, cb)
    TriggerServerEvent('peleg-events:startEvent', data.eventId)
    cb('ok')
end)

--- NUI: stop event (host)
RegisterNUICallback('stopEvent', function(data, cb)
    TriggerServerEvent('peleg-events:stopEvent', data.eventId)
    cb('ok')
end)

--- NUI: refresh active events list
RegisterNUICallback('refreshEvents', function(_, cb)
    TriggerServerEvent('peleg-events:getActiveEvents')
    cb('ok')
end)

--- NUI: set focus
--- @param data {focus:boolean, cursor:boolean}
RegisterNUICallback('setNuiFocus', function(data, cb)
    SetNuiFocus(data.focus, data.cursor)
    cb('ok')
end)

--- NUI: get current position
RegisterNUICallback('getCurrentPosition', function(_, cb)
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    cb({
        x = coords.x,
        y = coords.y,
        z = coords.z,
        heading = heading
    })
end)



--- Party started for this client
--- @param eventId string
RegisterNetEvent('peleg-events:partyStarted', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        isInEvent = true
        
        -- Block inventory when event starts
        blockInventory(true)
        
        FreezeEntityPosition(PlayerPedId(), false)
        if globalJoinPanelVisible or eventJoinPanelVisible then
            globalJoinPanelVisible = false
            eventJoinPanelVisible = false
            currentJoinEventId = nil
            SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
            SendNUIMessage({ action = "hideEventJoinPanel" })
        end
        SendNUIMessage({ type = "partyStarted", eventId = eventId })
    end
end)

--- Background thread: apply infinite ammo when enabled
CreateThread(function()
    while true do
        Wait(0)
        if infiniteAmmo then
            local ped = PlayerPedId()
            local _, weapon = GetCurrentPedWeapon(ped, true)
            if weapon ~= GetHashKey("WEAPON_UNARMED") then
                SetPedInfiniteAmmo(ped, true, weapon)
                SetPedInfiniteAmmoClip(ped, true)
            end
        end
    end
end)

--- Background thread: detect player death while in an event
CreateThread(function()
    while true do
        Wait(1000)
        if isInEvent and currentEventId then
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                TriggerServerEvent('peleg-events:carSumoPlayerDied', currentEventId)
                TriggerServerEvent('peleg-events:redzonePlayerDied', currentEventId)
            end
        end
    end
end)

--- Background thread: keybind logic for join/leave and dismiss panels
--- Uses: G (control 47) to Join/Leave; H (control 74) to Dismiss panels
CreateThread(function()
    while true do
        Wait(0)
        if IsControlJustPressed(0, 47) then
            if globalJoinPanelVisible and currentJoinEventId then
                if joinedEventId == currentJoinEventId then
                    TriggerServerEvent('peleg-events:leaveEvent', currentJoinEventId)
                else
                    TriggerServerEvent('peleg-events:joinEvent', currentJoinEventId)
                end
            elseif eventJoinPanelVisible and currentJoinEventId then
                if joinedEventId == currentJoinEventId then
                    TriggerServerEvent('peleg-events:leaveEvent', currentJoinEventId)
                else
                    TriggerServerEvent('peleg-events:joinEvent', currentJoinEventId)
                end
            end
        end
        if IsControlJustPressed(0, 74) then
            if globalJoinPanelVisible then
                globalJoinPanelVisible = false
                currentJoinEventId = nil
                SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
            elseif eventJoinPanelVisible then
                eventJoinPanelVisible = false
                currentJoinEventId = nil
                SendNUIMessage({ action = "hideEventJoinPanel" })
            end
        end
    end
end)
