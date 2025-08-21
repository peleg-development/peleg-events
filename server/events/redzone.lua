--- Redzone Event Server Logic (server-side)
--- Coordinates players, zone shrinking, weapon distribution, elimination logic, and cleanup.
local redzoneEvents = {}

--- Get a random spawn position from predefined locations for a player
---@param eventId string Event identifier
---@param usedPositions table Table of already used positions
---@param zoneCenter vector3 Center of the zone
---@param zoneRadius number Current radius of the zone
---@return vector3 pos Random position from config locations
local function getRandomSpawnPosition(eventId, usedPositions, zoneCenter, zoneRadius)
    local spawnLocations = Config.Events.Redzone.spawnLocations
    if not spawnLocations or #spawnLocations == 0 then
        return zoneCenter
    end
    
    local availablePositions = {}
    for _, pos in pairs(spawnLocations) do
        local distance = #(pos - zoneCenter)
        if distance <= zoneRadius then
            local isUsed = false
            for _, usedPos in pairs(usedPositions) do
                if #(pos - usedPos) < 5.0 then
                    isUsed = true
                    break
                end
            end
            if not isUsed then
                table.insert(availablePositions, pos)
            end
        end
    end
    
    if #availablePositions == 0 then
        local fallbackPositions = {}
        for _, pos in pairs(spawnLocations) do
            local distance = #(pos - zoneCenter)
            if distance <= zoneRadius then
                table.insert(fallbackPositions, pos)
            end
        end
        
        if #fallbackPositions > 0 then
            local randomIndex = math.random(1, #fallbackPositions)
            return fallbackPositions[randomIndex]
        else
            return zoneCenter
        end
    end
    
    local randomIndex = math.random(1, #availablePositions)
    return availablePositions[randomIndex]
end

--- Select a random weapon for the player based on event custom settings or defaults
---@param eventId string Event identifier
---@return string weaponName GTA weapon name
local function getRandomWeapon(eventId)
    local event = redzoneEvents[eventId]
    local eventData = exports['peleg-events']:getActiveEvents()[eventId]
    
    local weapons = Config.Events.Redzone.defaultWeapons
    if eventData and eventData.customSettings and eventData.customSettings.weapons and #eventData.customSettings.weapons > 0 then
        weapons = eventData.customSettings.weapons
    end
    
    if not weapons or #weapons == 0 then
        return "WEAPON_PISTOL"
    end
    
    local randomIndex = math.random(1, #weapons)
    return weapons[randomIndex]
end

--- Start a Redzone match:
--- 1) Validates participants, 2) creates/assigns routing bucket, 3) spawns players,
--- 4) performs countdown, 5) starts zone shrinking, 6) begins elimination loop
---@param eventId string Event identifier
local function startRedzoneEvent(eventId)
    print("^2[Redzone] Starting event: " .. eventId .. "^7")

    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if not event then
        print("^1[Redzone] Event not found: " .. eventId .. "^7")
        return
    end

    if #event.participants < 2 then
        print("^1[Redzone] Not enough players to start event (need at least 2)^7")
        for _, participant in pairs(event.participants) do
            if GetPlayerPed(participant.id) then
                SetEntityCoords(GetPlayerPed(participant.id),
                    participant.originalPosition.x,
                    participant.originalPosition.y,
                    participant.originalPosition.z,
                    false, false, false, true)
                SetPlayerRoutingBucket(participant.id, participant.originalBucket or 0)
            end
        end
        return
    end

    print("^3[Redzone] Event found with " .. #event.participants .. " participants^7")

    local zoneBaseSize = event.customSettings and event.customSettings.zoneBaseSize or 200.0
    local zoneChangeSpeed = event.customSettings and event.customSettings.zoneChangeSpeed or 1.0

    redzoneEvents[eventId] = {
        participants = event.participants,
        alivePlayers = {},
        startedAt = os.time(),
        zoneCenter = Config.Events.Redzone.zoneCenter,
        zoneRadius = zoneBaseSize,
        zoneChangeSpeed = zoneChangeSpeed,
        zoneShrinkInterval = 16,
        damageInterval = 2000,
        lastDamageTime = 0,
        usedSpawnPositions = {},
        zoneShrinkStartTime = GetGameTimer(),
        zoneShrinkDuration = 300000
    }

    local eventBucket = 2000 + (tonumber(eventId:match("%d+")) or math.random(1000, 9999))
    print("^3[Redzone] Using bucket: " .. eventBucket .. " for event: " .. eventId .. "^7")

    for _, participant in pairs(event.participants) do
        print("^3[Redzone] Moving player " .. participant.id .. " to bucket " .. eventBucket .. "^7")
        SetPlayerRoutingBucket(participant.id, eventBucket)
        Wait(100)
    end

    Wait(1000)

    for _, participant in pairs(event.participants) do
        local spawnPos = getRandomSpawnPosition(eventId, redzoneEvents[eventId].usedSpawnPositions, redzoneEvents[eventId].zoneCenter, redzoneEvents[eventId].zoneRadius)
        table.insert(redzoneEvents[eventId].usedSpawnPositions, spawnPos)
        print("^3[Redzone] Setting up player " .. participant.id .. " at " .. json.encode(spawnPos) .. "^7")
        
        TriggerClientEvent('peleg-events:spawnRedzonePlayer', participant.id, eventId, spawnPos)
        redzoneEvents[eventId].alivePlayers[participant.id] = true

        SetTimeout(1000, function()
            if GetPlayerPed(participant.id) then
                FreezeEntityPosition(GetPlayerPed(participant.id), true)
                print("^3[Redzone] Player frozen for player " .. participant.id .. "^7")
            end
        end)
    end

    print("^3[Redzone] Starting countdown for " .. Config.Events.Redzone.countdownDuration .. " seconds^7")
    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:redzoneCountdown', participant.id, eventId, Config.Events.Redzone.countdownDuration)
    end

    SetTimeout(Config.Events.Redzone.countdownDuration * 1000, function()
        if not redzoneEvents[eventId] then
            return
        end

        print("^2[Redzone] Countdown finished, starting event^7")

        for _, participant in pairs(event.participants) do
            if GetPlayerPed(participant.id) then
                FreezeEntityPosition(GetPlayerPed(participant.id), false)
                print("^2[Redzone] Player unfrozen for player " .. participant.id .. "^7")
            end
        end

        for _, participant in pairs(event.participants) do
            TriggerClientEvent('peleg-events:hideGlobalEventJoinPanel', participant.id)
            TriggerClientEvent('peleg-events:hideEventJoinPanel', participant.id)
        end

        for _, participant in pairs(event.participants) do
            local weapon = getRandomWeapon(eventId)
            TriggerClientEvent('peleg-events:giveRedzoneWeapon', participant.id, eventId, weapon)
            TriggerClientEvent('peleg-events:redzoneStarted', participant.id, eventId)
        end

        redzoneEvents[eventId].lastDamageTime = GetGameTimer()
    end)

    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:startRedzoneShrinking', participant.id, eventId, redzoneEvents[eventId].zoneCenter, zoneBaseSize, redzoneEvents[eventId].zoneShrinkDuration)
    end
    
    CreateThread(function()
        while redzoneEvents[eventId] and redzoneEvents[eventId].alivePlayers do
            Wait(redzoneEvents[eventId].damageInterval)
            
            if not redzoneEvents[eventId] then break end
            
            local currentTime = GetGameTimer()
            local elapsedTime = currentTime - redzoneEvents[eventId].zoneShrinkStartTime
            local shrinkProgress = math.min(elapsedTime / redzoneEvents[eventId].zoneShrinkDuration, 1.0)
            
            local initialRadius = zoneBaseSize
            local finalRadius = 10.0
            local newRadius = initialRadius - (shrinkProgress * (initialRadius - finalRadius))
            
            redzoneEvents[eventId].zoneRadius = newRadius
            
            for playerId, isAlive in pairs(redzoneEvents[eventId].alivePlayers) do
                if isAlive and GetPlayerPed(playerId) then
                    local playerPos = GetEntityCoords(GetPlayerPed(playerId))
                    local distance = #(playerPos - redzoneEvents[eventId].zoneCenter)
                    
                    if distance > redzoneEvents[eventId].zoneRadius then
                        local damage = 15
                        TriggerClientEvent('peleg-events:damageRedzonePlayer', playerId, eventId, damage)
                    end
                end
            end
        end
    end)
end

--- Eliminate a player in the Redzone event, switch to spectator, emit feeds, and finalize if last player remains
---@param eventId string Event identifier
---@param playerId number Server ID of the player being eliminated
local function handleRedzonePlayerDeath(eventId, playerId)
    if not redzoneEvents[eventId] or not redzoneEvents[eventId].alivePlayers[playerId] then
        return
    end

    redzoneEvents[eventId].alivePlayers[playerId] = false

    local spectatorPos = vector3(
        redzoneEvents[eventId].zoneCenter.x,
        redzoneEvents[eventId].zoneCenter.y,
        redzoneEvents[eventId].zoneCenter.z + Config.Events.Redzone.spectatorHeight
    )
    SetEntityCoords(GetPlayerPed(playerId), spectatorPos.x, spectatorPos.y, spectatorPos.z, false, false, false, true)
    FreezeEntityPosition(GetPlayerPed(playerId), true)

    TriggerClientEvent('peleg-events:removeRedzoneWeapon', playerId, eventId)

    TriggerEvent('peleg-events:playerDied', eventId, playerId)

    print("^3[Server] Adding kill feed: Zone killed " .. GetPlayerName(playerId) .. " in Redzone^7")
    TriggerClientEvent('peleg-events:addKillFeed', -1, {
        killer = "Zone",
        victim = GetPlayerName(playerId),
        eventType = "Redzone"
    })

    TriggerClientEvent('peleg-events:playerEliminated', -1, eventId, playerId, GetPlayerName(playerId))

    local aliveCount = 0
    local lastAlivePlayer = nil
    for pid, alive in pairs(redzoneEvents[eventId].alivePlayers) do
        if alive then
            aliveCount = aliveCount + 1
            lastAlivePlayer = pid
        end
    end

    if aliveCount <= 1 then
        local winnerId = lastAlivePlayer
        print("^2[Redzone] Event finished! Winner: " .. winnerId .. " (" .. GetPlayerName(winnerId) .. ")^7")
        print("^2[Redzone] Calling finishEvent for event: " .. eventId .. " with winner: " .. winnerId .. "^7")
        
        TriggerEvent('peleg-events:cleanupRedzone', eventId)
        finishEvent(eventId, winnerId)

        redzoneEvents[eventId] = nil
    end
end

--- Revive player after redzone event ends
---@param playerId number Server ID of the player to revive
local function revivePlayerAfterRedzone(playerId)
    if not GetPlayerPed(playerId) then
        return
    end
    
    local ped = GetPlayerPed(playerId)
    TriggerServerEvent('txsv:req:healMyself')

    NetworkResurrectLocalPlayer(GetEntityCoords(ped), GetEntityHeading(ped), true, false)
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    ClearPedBloodDamage(ped)
    ClearPedTasksImmediately(ped)
    
    FreezeEntityPosition(ped, false)
    
end

RegisterNetEvent('peleg-events:startRedzone', function(eventId)
    startRedzoneEvent(eventId)
end)

RegisterNetEvent('peleg-events:redzonePlayerDied', function(eventId)
    local source = source
    handleRedzonePlayerDeath(eventId, source)
end)

--- Event handler: the source player killed a victim; logs a kill feed entry and eliminates the victim
RegisterNetEvent('peleg-events:redzonePlayerKilled', function(eventId, victimId)
    local source = source
    local killerName = GetPlayerName(source)
    local victimName = GetPlayerName(victimId)

    print("^3[Server] Player " .. killerName .. " killed " .. victimName .. " in Redzone^7")

    TriggerClientEvent('peleg-events:addKillFeed', -1, {
        killer = killerName,
        victim = victimName,
        eventType = "Redzone"
    })

    handleRedzonePlayerDeath(eventId, victimId)
    
    TriggerEvent('peleg-events:addKill', eventId, source, victimId)
end)

RegisterNetEvent('peleg-events:redzoneKillReward', function(eventId)
    local source = source
    if redzoneEvents[eventId] and redzoneEvents[eventId].alivePlayers[source] then
        TriggerClientEvent('peleg-events:giveFullArmor', source, eventId)
        print("^3[Server] Gave full armor to player " .. GetPlayerName(source) .. " for kill^7")
    end
end)

RegisterNetEvent('peleg-events:cleanupRedzone', function(eventId)
    if redzoneEvents[eventId] then
        print("^3[Redzone] Cleaning up event: " .. eventId .. "^7")

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

                    FreezeEntityPosition(GetPlayerPed(participant.id), false)
                    
                    revivePlayerAfterRedzone(participant.id)
                    
                    TriggerClientEvent('peleg-events:hideKillsCounter', participant.id)
                end
            end
        end

        TriggerClientEvent('peleg-events:redzoneEventEnded', -1, eventId)

        redzoneEvents[eventId] = nil
    end
end)
