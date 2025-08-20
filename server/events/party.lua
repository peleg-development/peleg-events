--- Party Event Server Logic (server-side)
--- Coordinates players, location teleportation, and reward distribution.
local partyEvents = {}

--- Parse vector4 string to coordinates and heading
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

--- Start a Party event:
--- 1) Validates participants, 2) teleports players to party location,
--- 3) starts the party immediately (no countdown)
---@param eventId string Event identifier
local function startPartyEvent(eventId)
    print("^2[Party] Starting event: " .. eventId .. "^7")

    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if not event then
        print("^1[Party] Event not found: " .. eventId .. "^7")
        return
    end

    if #event.participants < 1 then
        print("^1[Party] No participants to start event^7")
        return
    end

    print("^3[Party] Event found with " .. #event.participants .. " participants^7")

    local locationString = event.customSettings and event.customSettings.location or "0.0, 0.0, 0.0, 0.0"
    local partyPos, partyHeading = parseLocation(locationString)

    partyEvents[eventId] = {
        participants = event.participants,
        partyLocation = partyPos,
        partyHeading = partyHeading,
        startedAt = os.time()
    }

    print("^3[Party] Party location: " .. json.encode(partyPos) .. " heading: " .. partyHeading .. "^7")

    for _, participant in pairs(event.participants) do
        print("^3[Party] Teleporting player " .. participant.id .. " to party location^7")
        SetEntityCoords(GetPlayerPed(participant.id), partyPos.x, partyPos.y, partyPos.z, false, false, false, true)
        SetEntityHeading(GetPlayerPed(participant.id), partyHeading)
    end

    Wait(1000)

    print("^2[Party] Starting party immediately^7")

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

    print("^3[Party] Teleporting player " .. playerId .. " to party location^7")
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

    print("^2[Party] Stopping event: " .. eventId .. "^7")

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
                print("^3[Party] Restored player " .. participant.id .. " to original state^7")
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
