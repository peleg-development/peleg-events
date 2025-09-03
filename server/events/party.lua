local partyEvents = {}

---@param locationString string Vector4 string in format "x, y, z, heading"
---@return vector3 pos Position coordinates
---@return number heading Heading in degrees
local function parseLocation(locationString)
    local parts = {}
    for part in locationString:gmatch("[^,]+") do
        table.insert(parts, tonumber(part:match("^%s*(.-)%s*$")))
    end
    
    if #parts >= 4 then
        return vector3(parts[1], parts[2], parts[3]), parts[4]
    else
        return vector3(0.0, 0.0, 0.0), 0.0
    end
end

---@param eventId string Event identifier
local function startPartyEvent(eventId)

    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if not event then
        return
    end

    if #event.participants < 1 then
        return
    end


    local locationString = event.customSettings and event.customSettings.location or "0.0, 0.0, 0.0, 0.0"
    local partyPos, partyHeading = parseLocation(locationString)

    partyEvents[eventId] = {
        participants = event.participants,
        partyLocation = partyPos,
        partyHeading = partyHeading,
        startedAt = os.time()
    }


    for _, participant in pairs(event.participants) do
        SetEntityCoords(GetPlayerPed(participant.id), partyPos.x, partyPos.y, partyPos.z, false, false, false, true)
        SetEntityHeading(GetPlayerPed(participant.id), partyHeading)
    end

    Wait(1000)


    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:hideGlobalEventJoinPanel', participant.id)
        TriggerClientEvent('peleg-events:hideEventJoinPanel', participant.id)
        TriggerClientEvent('peleg-events:partyStarted', participant.id, eventId)
    end
end

--- Teleport player to party location when they join
---@param eventId string Event identifier
---@param playerId number Player ID
local function teleportPlayerToParty(eventId, playerId)
    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if not event then
        return
    end

    local locationString = event.customSettings and event.customSettings.location or "0.0, 0.0, 0.0, 0.0"
    local partyPos, partyHeading = parseLocation(locationString)

    SetEntityCoords(GetPlayerPed(playerId), partyPos.x, partyPos.y, partyPos.z, false, false, false, true)
    SetEntityHeading(GetPlayerPed(playerId), partyHeading)
    
    TriggerClientEvent('peleg-events:partyStarted', playerId, eventId)
end

--- Stop a Party event and distribute rewards
---@param eventId string Event identifier
local function stopPartyEvent(eventId)
    if not partyEvents[eventId] then
        return
    end


    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if event and event.participants then
        for _, participant in pairs(event.participants) do
            if GetPlayerPed(participant.id) then
                SetEntityCoords(GetPlayerPed(participant.id),
                    participant.originalPosition.x,
                    participant.originalPosition.y,
                    participant.originalPosition.z,
                    false, false, false, true)

                SetPlayerRoutingBucket(participant.id, participant.originalBucket or 0)

                TriggerClientEvent('peleg-events:restorePlayerHealth', participant.id)
            end
        end

        TriggerClientEvent('peleg-events:partyEventEnded', -1, eventId)
    end

    partyEvents[eventId] = nil
end

RegisterNetEvent('peleg-events:startParty', function(eventId)
    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if event then
        event.status = "active"
        event.startedAt = os.time()
    end
    startPartyEvent(eventId)
end)

RegisterNetEvent('peleg-events:playerJoinedParty', function(eventId, playerId)
    teleportPlayerToParty(eventId, playerId)
end)

RegisterNetEvent('peleg-events:stopParty', function(eventId)
    stopPartyEvent(eventId)
end)

RegisterNetEvent('peleg-events:cleanupParty', function(eventId)
    stopPartyEvent(eventId)
end)
