local isUIOpen = false
currentEventId = nil
local isInEvent = false
local infiniteAmmo = false
local globalJoinPanelVisible = false
local eventJoinPanelVisible = false
local currentJoinEventId = nil
joinedEventId = nil

--- @param type string Notification type: success|error|warning|info
--- @param message string Notification message
local function showNotification(type, message)
    SendNUIMessage({ action = "showGlobalNotification", type = type, message = message })
end

--- @param enabled boolean Whether to show the UI
local function toggleUI(enabled)
    isUIOpen = enabled
    SetNuiFocus(enabled, enabled)
    SendNUIMessage({ action = "setVisible", visible = enabled })
end

RegisterNetEvent('peleg-events:openUI', function()
    toggleUI(true)
    TriggerServerEvent('peleg-events:getActiveEvents')
end)

--- @param type string
--- @param message string
RegisterNetEvent('peleg-events:notification', function(type, message)
    showNotification(type, message)
end)

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

RegisterNetEvent('peleg-events:hideEventJoinPanel', function()
    eventJoinPanelVisible = false
    currentJoinEventId = nil
    SendNUIMessage({ action = "hideEventJoinPanel" })
end)

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

RegisterNetEvent('peleg-events:hideGlobalEventJoinPanel', function()
    globalJoinPanelVisible = false
    currentJoinEventId = nil
    SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
end)

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

--- @param events table
RegisterNetEvent('peleg-events:activeEventsData', function(events)
    SendNUIMessage({
        action = "updateEvents",
        events = events,
        currentPlayerId = GetPlayerServerId(PlayerId())
    })
end)

--- @param eventId string
RegisterNetEvent('peleg-events:eventCreated', function(eventId)
    currentEventId = eventId
    SendNUIMessage({ action = "eventCreated", eventId = eventId })
end)

--- @param eventId string
--- @param playerId number
--- @param playerName string
RegisterNetEvent('peleg-events:playerJoined', function(eventId, playerId, playerName)
    if playerId == GetPlayerServerId(PlayerId()) then
        joinedEventId = eventId
        isInEvent = true
        if globalJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateGlobalEventJoinPanel", hasJoined = true })
        elseif eventJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateEventJoinPanel", hasJoined = true })
        end
        
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

--- @param eventId string
--- @param playerId number
RegisterNetEvent('peleg-events:playerLeft', function(eventId, playerId)
    if playerId == GetPlayerServerId(PlayerId()) then
        if joinedEventId == eventId then 
            joinedEventId = nil 
            isInEvent = false
        end
        if globalJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateGlobalEventJoinPanel", hasJoined = false })
        elseif eventJoinPanelVisible and currentJoinEventId == eventId then
            SendNUIMessage({ action = "updateEventJoinPanel", hasJoined = false })
        end
    end

    SendNUIMessage({ action = "playerLeft", eventId = eventId, playerId = playerId })
end)

--- @param eventId string
--- @param playerId number
--- @param playerName string
RegisterNetEvent('peleg-events:playerEliminated', function(eventId, playerId, playerName)
    SendNUIMessage({ action = "playerEliminated", eventId = eventId, playerId = playerId, playerName = playerName })
end)



RegisterNetEvent('peleg-events:carSumoStarted', function(eventId)
    if currentEventId == eventId then
        isInEvent = true
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


--- @param scoreboardData {eventId:string, eventType:string, players:table, duration:number}
RegisterNetEvent('peleg-events:showScoreboard', function(scoreboardData)
    isInEvent = false
    currentEventId = nil
    joinedEventId = nil
    SendNUIMessage({
        action = "showScoreboard",
        eventId = scoreboardData.eventId,
        eventType = scoreboardData.eventType,
        players = scoreboardData.players,
        duration = scoreboardData.duration
    })
end)

--- @param killsData {kills:number, isVisible:boolean}
RegisterNetEvent('peleg-events:updateKillsCounter', function(killsData)
    SendNUIMessage({ action = "updateKillsCounter", kills = killsData.kills, isVisible = killsData.isVisible })
end)

RegisterNetEvent('peleg-events:hideKillsCounter', function()
    SendNUIMessage({ action = "hideKillsCounter" })
end)

--- @param killData {killer:string, victim:string, eventType:string}
RegisterNetEvent('peleg-events:addKillFeed', function(killData)
    SendNUIMessage({ action = "addKillFeed", killer = killData.killer, victim = killData.victim, eventType = killData.eventType })
end)

RegisterNUICallback('closeUI', function(_, cb)
    toggleUI(false)
    cb('ok')
end)

RegisterNUICallback('createEvent', function(data, cb)
    TriggerServerEvent('peleg-events:createEvent', data.eventType, data.maxPlayers, data.rewardType, data.rewardData, data.customSettings)
    cb('ok')
end)

RegisterNUICallback('joinEvent', function(data, cb)
    TriggerServerEvent('peleg-events:joinEvent', data.eventId)
    cb('ok')
end)

RegisterNUICallback('leaveEvent', function(data, cb)
    TriggerServerEvent('peleg-events:leaveEvent', data.eventId)
    cb('ok')
end)

RegisterNUICallback('startEvent', function(data, cb)
    TriggerServerEvent('peleg-events:startEvent', data.eventId)
    cb('ok')
end)

RegisterNUICallback('stopEvent', function(data, cb)
    TriggerServerEvent('peleg-events:stopEvent', data.eventId)
    cb('ok')
end)

RegisterNUICallback('refreshEvents', function(_, cb)
    TriggerServerEvent('peleg-events:getActiveEvents')
    cb('ok')
end)

--- @param data {focus:boolean, cursor:boolean}
RegisterNUICallback('setNuiFocus', function(data, cb)
    SetNuiFocus(data.focus, data.cursor)
    cb('ok')
end)

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

CreateThread(function()
    while true do
        if (globalJoinPanelVisible and currentJoinEventId) or (eventJoinPanelVisible and currentJoinEventId) then
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
        else
            Wait(1500)
        end
    end
end)