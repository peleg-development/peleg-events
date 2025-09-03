local currentPartyEvent = nil

---@param eventId string
RegisterNetEvent('peleg-events:partyStarted', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        currentPartyEvent = eventId
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
        print("^3[Client] Party event started^7")
    end
end)

---@param eventId string
RegisterNetEvent('peleg-events:partyEventEnded', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        currentPartyEvent = nil
        isInEvent = false
        
        if currentEventId == eventId then
            currentEventId = nil
        end
        if joinedEventId == eventId then
            joinedEventId = nil
        end
        
        print("^3[Client] Party event ended^7")
    end
end)
