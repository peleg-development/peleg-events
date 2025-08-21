local activeEvents = {}
local playerData = {}
local eventKills = {}
local eventStartTimes = {}

--- Get the length of a table
---@param t table
---@return number
local function getTableLength(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

--- Check if a player is authorized
--- @param playerId number
--- @return boolean
local function isPlayerAuthorized(playerId)
    local license = Framework.GetPlayerLicense(playerId)
    if not license then return false end
    for _, authorizedLicense in pairs(Config.AuthorizedLicenses) do
        if license == authorizedLicense then
            return true
        end
    end
    return false
end

--- Get active event data
--- @param eventId string
--- @return table|nil
local function getActiveEvent(eventId)
    return activeEvents[eventId]
end

--- Set active event data
--- @param eventId string
--- @param eventData table
local function setActiveEvent(eventId, eventData)
    activeEvents[eventId] = eventData
end

--- Remove an active event
--- @param eventId string
local function removeActiveEvent(eventId)
    activeEvents[eventId] = nil
    eventKills[eventId] = nil
    eventStartTimes[eventId] = nil
end

--- Add a kill for a killer within an event
--- @param eventId string
--- @param killerId number
--- @param victimId number
local function addKill(eventId, killerId, victimId)
    print("^3[Main] addKill called: eventId=" .. tostring(eventId) .. ", killerId=" .. tostring(killerId) .. " (type: " .. type(killerId) .. "), victimId=" .. tostring(victimId) .. "^7")
    
    if not eventKills[eventId] then
        eventKills[eventId] = {}
    end
    if not eventKills[eventId][killerId] then
        eventKills[eventId][killerId] = 0
    end
    eventKills[eventId][killerId] = eventKills[eventId][killerId] + 1
    print("^3[Main] Updated kills for event " .. tostring(eventId) .. ": " .. json.encode(eventKills[eventId]) .. "^7")
    print("^3[Main] Killer " .. tostring(killerId) .. " now has " .. tostring(eventKills[eventId][killerId]) .. " kills^7")
    TriggerClientEvent('peleg-events:updateKillsCounter', killerId, { kills = eventKills[eventId][killerId], isVisible = true })
end

--- Build event statistics
--- @param eventId string
--- @return table|nil
local function getEventStats(eventId)
    print("^3[Main] getEventStats called for event: " .. tostring(eventId) .. "^7")
    local event = getActiveEvent(eventId)
    if not event then 
        print("^1[Main] Event not found in getEventStats^7")
        return nil 
    end

    local stats = { eventId = eventId, eventType = event.type, players = {}, duration = 0 }
    local currentTime = os.time()
    local startTime = eventStartTimes[eventId] or currentTime
    stats.duration = currentTime - startTime

    local kills = eventKills[eventId] or {}
    print("^3[Main] Kills data for event " .. eventId .. ": " .. json.encode(kills) .. "^7")
    print("^3[Main] Event participants: " .. #event.participants .. "^7")
    print("^3[Main] Kills data type: " .. type(kills) .. "^7")
    print("^3[Main] Kills keys: " .. json.encode({}) .. "^7")
    for k, v in pairs(kills) do
        print("^3[Main] Kill key: " .. tostring(k) .. " (type: " .. type(k) .. "), value: " .. tostring(v) .. "^7")
    end
    
    for _, participant in pairs(event.participants) do
        local playerKills = kills[participant.id] or 0
        local timeAlive = participant.deathTime and (participant.deathTime - startTime) or stats.duration
        local playerName = GetPlayerName(participant.id) or "Unknown Player"
        print("^3[Main] Player " .. participant.id .. " (" .. playerName .. "): " .. playerKills .. " kills, deathTime=" .. tostring(participant.deathTime) .. "^7")
        print("^3[Main] Looking for kills[" .. tostring(participant.id) .. "] (type: " .. type(participant.id) .. ")^7")
        table.insert(stats.players, {
            id = participant.id,
            name = playerName,
            kills = playerKills,
            timeAlive = timeAlive,
            rank = 1,
            isWinner = participant.id == event.winnerId
        })
    end

    table.sort(stats.players, function(a, b)
        if a.kills ~= b.kills then
            return a.kills > b.kills
        end
        return a.timeAlive > b.timeAlive
    end)

    for i, player in ipairs(stats.players) do
        player.rank = i
    end

    return stats
end

--- Check if a player is in an event
--- @param playerId number
--- @param eventId string
--- @return boolean
local function isPlayerInEvent(playerId, eventId)
    local event = getActiveEvent(eventId)
    if not event then return false end
    for _, participant in pairs(event.participants) do
        if participant.id == playerId then
            return true
        end
    end
    return false
end

--- Check if a player is in any active event
--- @param playerId number
--- @return boolean
local function isPlayerInAnyEvent(playerId)
    for eventId, event in pairs(activeEvents) do
        if event.status == "active" or event.status == "waiting" then
            for _, participant in pairs(event.participants) do
                if participant.id == playerId then
                    return true
                end
            end
        end
    end
    return false
end

--- Add a player to an event
--- @param playerId number
--- @param eventId string
--- @param data table|nil
--- @return boolean, string|nil
local function addPlayerToEvent(playerId, eventId, data)
    local event = getActiveEvent(eventId)
    if not event then return false end
    if event.type ~= "Party" and #event.participants >= event.maxPlayers then
        return false, "Event is full"
    end

    local playerName = GetPlayerName(playerId)
    local pdata = {
        id = playerId,
        name = playerName,
        joinedAt = os.time(),
        originalPosition = GetEntityCoords(GetPlayerPed(playerId)),
        originalHealth = GetEntityHealth(GetPlayerPed(playerId)),
        originalArmor = GetPedArmour(GetPlayerPed(playerId)),
        originalBucket = GetPlayerRoutingBucket(playerId)
    }

    if data then
        for key, value in pairs(data) do
            pdata[key] = value
        end
    end

    table.insert(event.participants, pdata)
    return true
end

--- Remove a player from an event
--- @param playerId number
--- @param eventId string
local function removePlayerFromEvent(playerId, eventId)
    local event = getActiveEvent(eventId)
    if not event then return end
    for i, participant in pairs(event.participants) do
        if participant.id == playerId then
            table.remove(event.participants, i)
            break
        end
    end
end

--- Create an event (by id)
--- @param eventId string
--- @param eventType string
--- @param hostId number
--- @param maxPlayers number
--- @param rewardType string
--- @param rewardData table
--- @param customSettings table|nil
--- @return table
local function createEventById(eventId, eventType, hostId, maxPlayers, rewardType, rewardData, customSettings)
    local hostName = GetPlayerName(hostId)
    local eventData = {
        id = eventId,
        type = eventType,
        hostId = hostId,
        hostName = hostName,
        maxPlayers = maxPlayers,
        participants = {},
        status = "waiting",
        rewardType = rewardType,
        rewardData = rewardData,
        config = customSettings or {},
        createdAt = os.time()
    }
    setActiveEvent(eventId, eventData)
    eventKills[eventId] = {}
    print("^2[Server] Event created: " .. eventId .. " by " .. hostName .. "^7")
    return eventData
end

--- Start an event
--- @param eventId string
local function startEvent(eventId)
    local event = getActiveEvent(eventId)
    if not event then return end
    if #event.participants < event.minPlayers then
        TriggerClientEvent('peleg-events:notification', event.hostId, 'error', 'Not enough players to start the event')
        return
    end

    event.status = "active"
    event.startedAt = os.time()
    eventStartTimes[eventId] = os.time()

    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:updateKillsCounter', participant.id, { kills = 0, isVisible = true })
    end

    if event.type == "CarSumo" then
        TriggerEvent('peleg-events:startCarSumo', eventId)
    elseif event.type == "Redzone" then
        TriggerEvent('peleg-events:startRedzone', eventId)
    elseif event.type == "Party" then
        TriggerEvent('peleg-events:startParty', eventId)
    end

    print("^2[Server] Event started: " .. eventId .. "^7")
end

--- Create an event (auto id)
--- @param eventType string
--- @param hostId number
--- @param maxPlayers number|nil
--- @param rewardType string|nil
--- @param rewardData table|nil
--- @param customSettings table|nil
--- @return string|nil, string|nil
local function createEvent(eventType, hostId, maxPlayers, rewardType, rewardData, customSettings)
    local eventId = "event_" .. os.time() .. "_" .. math.random(1000, 9999)
    local eventConfig = Config.Events[eventType]
    if not eventConfig then
        return nil, "Invalid event type"
    end

    local finalRewardType = rewardType or eventConfig.defaultReward.type
    local finalRewardData = rewardData or eventConfig.defaultReward.data

    local legacyReward = 0
    if finalRewardType == "money" then
        legacyReward = finalRewardData.amount or 0
    elseif finalRewardType == "item" then
        legacyReward = 1000
    elseif finalRewardType == "vehicle" then
        legacyReward = 5000
    end

    local eventData = {
        id = eventId,
        type = eventType,
        hostId = hostId,
        hostName = GetPlayerName(hostId),
        maxPlayers = maxPlayers or eventConfig.maxPlayers,
        minPlayers = eventConfig.minPlayers,
        reward = legacyReward,
        rewardType = finalRewardType,
        rewardData = finalRewardData,
        status = "waiting",
        participants = {},
        createdAt = os.time(),
        config = eventConfig,
        customSettings = customSettings or {}
    }

    setActiveEvent(eventId, eventData)
    eventKills[eventId] = {}
    return eventId
end

--- Finish an event and distribute rewards
--- @param eventId string
--- @param winnerId number|nil
function finishEvent(eventId, winnerId)
    print("^3[Main] finishEvent called: eventId=" .. tostring(eventId) .. ", winnerId=" .. tostring(winnerId) .. "^7")
    local event = getActiveEvent(eventId)
    if not event then
        print("^1[Main] Event not found in finishEvent^7")
        return
    end

    event.status = "finished"
    event.winnerId = winnerId
    event.finishedAt = os.time()

    local stats = getEventStats(eventId)
    if not stats then
        print("^1[Main] Failed to get event stats^7")
        return
    end
    print("^3[Main] Event stats generated successfully^7")

    Citizen.CreateThread(function()
        Wait(2500)
    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:showScoreboard', participant.id, stats)
        TriggerClientEvent('peleg-events:hideKillsCounter', participant.id)
        if winnerId then
            local winnerName = GetPlayerName(winnerId)
            local winnerData = {
                eventId = eventId,
                eventType = event.type,
                winnerName = winnerName,
                winnerId = winnerId,
                reward = { type = event.rewardType, data = event.rewardData },
                participants = #event.participants
            }
            TriggerClientEvent('peleg-events:showWinnerUI', participant.id, winnerData)
        end
    end
end)

    if winnerId then
        local success, message = exports['peleg-events']:GiveReward(winnerId, event.rewardType, event.rewardData)
        if success then
            TriggerClientEvent('peleg-events:notification', winnerId, 'success', 'You won the event! ' .. message)
        else
            TriggerClientEvent('peleg-events:notification', winnerId, 'error', 'Failed to give reward: ' .. message)
        end
    end

    for _, participant in pairs(event.participants) do
        if GetPlayerPed(participant.id) then
            SetEntityCoords(GetPlayerPed(participant.id), participant.originalPosition.x, participant.originalPosition.y, participant.originalPosition.z, false, false, false, true)
            SetPlayerRoutingBucket(participant.id, participant.originalBucket or 0)
            FreezeEntityPosition(GetPlayerPed(participant.id), false)
            TriggerClientEvent('peleg-events:hideKillsCounter', participant.id)
        end
    end

    if event.type == "CarSumo" then
        TriggerEvent('peleg-events:cleanupCarSumo', eventId)
    elseif event.type == "Redzone" then
        TriggerEvent('peleg-events:cleanupRedzone', eventId)
    elseif event.type == "Party" then
        TriggerEvent('peleg-events:cleanupParty', eventId)
    end

    SetTimeout(5000, function()
        removeActiveEvent(eventId)
    end)
end

RegisterCommand('events', function(source)
    if not isPlayerAuthorized(source) then
        TriggerClientEvent('peleg-events:notification', source, 'error', 'You are not authorized to use this command')
        return
    end
    TriggerClientEvent('peleg-events:openUI', source)
end, false)

RegisterNetEvent('peleg-events:createEvent', function(eventType, maxPlayers, rewardType, rewardData, customSettings)
    local src = source
    if not isPlayerAuthorized(src) then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'You are not authorized to create events')
        return
    end

    -- Allow multiple events per host
    -- for _, event in pairs(activeEvents) do
    --     if event.hostId == src and event.status == "waiting" then
    --         TriggerClientEvent('peleg-events:notification', src, 'error', 'You already have an active event')
    --         return
    --     end
    -- end

    local eventId, err = createEvent(eventType, src, maxPlayers, rewardType, rewardData, customSettings)
    if not eventId then
        TriggerClientEvent('peleg-events:notification', src, 'error', err or 'Failed to create event')
        return
    end
    TriggerClientEvent('peleg-events:notification', src, 'success', 'Event created successfully!')
    TriggerClientEvent('peleg-events:notification', -1, 'info', GetPlayerName(src) .. ' created a ' .. eventType .. ' event!')
    TriggerClientEvent('peleg-events:eventCreated', src, eventId)

    local eventData = getActiveEvent(eventId)
    if eventData then
        -- Send join panel to all players except those already in an event
        for _, playerId in pairs(GetPlayers()) do
            if not isPlayerInAnyEvent(playerId) then
                TriggerClientEvent('peleg-events:showGlobalEventJoinPanel', playerId, {
                    event = {
                        id = eventId,
                        type = eventData.type,
                        hostName = eventData.hostName,
                        hostId = eventData.hostId,
                        maxPlayers = eventData.maxPlayers,
                        currentPlayers = #eventData.participants,
                        reward = eventData.reward,
                        rewardType = eventData.rewardType,
                        rewardData = eventData.rewardData,
                        config = eventData.config
                    },
                    deadline = 300
                })
            end
        end
    end
end)

RegisterNetEvent('peleg-events:joinEvent', function(eventId)
    local src = source
    local event = getActiveEvent(eventId)
    if not event then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Event not found')
        return
    end
    if event.status ~= "waiting" and event.status ~= "active" then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Event is not accepting participants')
        return
    end
    if isPlayerInEvent(src, eventId) then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'You are already in this event')
        return
    end
    
    if isPlayerInAnyEvent(src) then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'You are already in another event')
        return
    end

    local ok, err = addPlayerToEvent(src, eventId)
    if not ok then
        TriggerClientEvent('peleg-events:notification', src, err or 'Failed to join event')
        return
    end

    TriggerClientEvent('peleg-events:notification', src, 'success', 'Joined event successfully!')
    TriggerClientEvent('peleg-events:playerJoined', -1, eventId, src, GetPlayerName(src))
    TriggerClientEvent('peleg-events:notification', event.hostId, 'info', GetPlayerName(src) .. ' joined your event!')
    
    if event.type == "Party" then
        TriggerEvent('peleg-events:playerJoinedParty', eventId, src)
    end
end)

RegisterNetEvent('peleg-events:leaveEvent', function(eventId)
    local src = source
    local event = getActiveEvent(eventId)
    if not event then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Event not found')
        return
    end
    if not isPlayerInEvent(src, eventId) then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'You are not in this event')
        return
    end

    removePlayerFromEvent(src, eventId)

    for _, participant in pairs(event.participants) do
        if participant.id == src then
            SetEntityCoords(GetPlayerPed(src), participant.originalPosition.x, participant.originalPosition.y, participant.originalPosition.z, false, false, false, true)
            SetPlayerRoutingBucket(src, participant.originalBucket or 0)
            FreezeEntityPosition(GetPlayerPed(src), false)
            break
        end
    end

    TriggerClientEvent('peleg-events:notification', src, 'success', 'Left event successfully')
    TriggerClientEvent('peleg-events:playerLeft', -1, eventId, src)
end)

RegisterNetEvent('peleg-events:declineEvent', function()
    local src = source
    TriggerClientEvent('peleg-events:hideGlobalEventJoinPanel', src)
end)

RegisterNetEvent('peleg-events:startEvent')
AddEventHandler('peleg-events:startEvent', function(eventId)
    local src = source
    local event = getActiveEvent(eventId)
    if not event then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Event not found')
        return
    end
    if event.hostId ~= src then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Only the host can start the event')
        return
    end
    startEvent(eventId)
end)

RegisterNetEvent('peleg-events:stopEvent')
AddEventHandler('peleg-events:stopEvent', function(eventId)
    local src = source
    local event = getActiveEvent(eventId)
    if not event then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Event not found')
        return
    end
    if event.hostId ~= src then
        TriggerClientEvent('peleg-events:notification', src, 'error', 'Only the host can stop the event')
        return
    end
    
    if event.type == "Party" then
        -- Party events can be stopped regardless of status
        TriggerEvent('peleg-events:stopParty', eventId)
        event.status = "finished"
        event.finishedAt = os.time()
        
        for _, participant in pairs(event.participants) do
            if event.rewardType == "money" and event.rewardData then
                TriggerClientEvent('peleg-events:notification', participant.id, 'success', 'You received $' .. event.rewardData.amount .. ' from the party!')
            else
                TriggerClientEvent('peleg-events:notification', participant.id, 'success', 'You received a reward from the party!')
            end
        end
        
        TriggerClientEvent('peleg-events:notification', src, 'success', 'Party event stopped and rewards distributed')
    else
        -- For other event types, check if they are active
        if event.status ~= "active" then
            TriggerClientEvent('peleg-events:notification', src, 'error', 'Event is not active')
            return
        end
        
        -- Handle stopping other event types here
        finishEvent(eventId)
    end
end)

RegisterNetEvent('peleg-events:getActiveEvents', function()
    local src = source
    local events = {}
    for eventId, event in pairs(activeEvents) do
        if event.status == "waiting" or (event.status == "active" and event.type == "Party") then
            table.insert(events, {
                id = eventId,
                type = event.type,
                hostName = event.hostName,
                hostId = event.hostId,
                maxPlayers = event.maxPlayers,
                currentPlayers = #event.participants,
                reward = event.reward,
                rewardType = event.rewardType,
                rewardData = event.rewardData,
                config = event.config,
                status = event.status
            })
        end
    end
    TriggerClientEvent('peleg-events:activeEventsData', src, events)
end)

exports('getActiveEvents', function()
    return activeEvents
end)

exports('isPlayerAuthorized', isPlayerAuthorized)
exports('createEvent', createEvent)
exports('finishEvent', finishEvent)

RegisterNetEvent('peleg-events:addKill', function(eventId, killerId, victimId)
    addKill(eventId, killerId, victimId)
end)

RegisterNetEvent('peleg-events:playerDied', function(eventId, playerId)
    print("^3[Main] playerDied event received: eventId=" .. tostring(eventId) .. ", playerId=" .. tostring(playerId) .. "^7")
    local event = getActiveEvent(eventId)
    if not event then 
        print("^1[Main] Event not found in playerDied handler^7")
        return 
    end
    for _, participant in pairs(event.participants) do
        if participant.id == playerId then
            participant.deathTime = os.time()
            print("^3[Main] Set deathTime for player " .. playerId .. " to " .. os.time() .. "^7")
            break
        end
    end
end)
