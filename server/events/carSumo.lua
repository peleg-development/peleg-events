local carSumoEvents = {}

---@param eventId string Event identifier
---@param playerId number Server ID of the player
---@return vector3 pos Position for the player spawn
---@return number heading Heading in degrees for the player/vehicle
local function getCarSumoSpawnPosition(eventId, playerId)
    local event = carSumoEvents[eventId]
    if not event then return Config.Events.CarSumo.spawnLocation, 0.0 end

    local spawnPositions = {
        {pos = vector3(-11.5120, 22.0073, 1504.4935), heading = 209.9631},
        {pos = vector3(-4.4280, 23.4034, 1504.4939), heading = 190.0574},
        {pos = vector3(1.7178, 23.8166, 1504.4944), heading = 174.7335},
        {pos = vector3(8.0009, 22.9259, 1504.4927), heading = 159.9536},
        {pos = vector3(13.4630, 20.2513, 1504.4941), heading = 143.4576},
        {pos = vector3(18.4667, 15.9299, 1504.4933), heading = 126.8784},
        {pos = vector3(21.5028, 11.0771, 1504.4943), heading = 115.9065},
        {pos = vector3(23.5944, 5.3271, 1504.4940), heading = 102.3830},
        {pos = vector3(24.6126, -1.4937, 1504.8906), heading = 39.2772},
        {pos = vector3(22.4916, -7.4461, 1504.4927), heading = 70.9248},
        {pos = vector3(19.8256, -12.9829, 1504.4928), heading = 53.9214},
        {pos = vector3(16.5526, -17.7296, 1504.4937), heading = 44.3995},
        {pos = vector3(11.2689, -21.6249, 1504.4943), heading = 26.4402},
        {pos = vector3(5.5370, -23.8427, 1504.4937), heading = 12.1996},
        {pos = vector3(0.0420, -24.4195, 1504.4949), heading = 6.4356},
        {pos = vector3(-5.5285, -24.1555, 1504.4946), heading = 350.6250},
        {pos = vector3(-10.9660, -21.9485, 1504.4945), heading = 335.9518},
        {pos = vector3(-15.8524, -19.1263, 1504.4935), heading = 329.4368},
        {pos = vector3(-20.0545, -14.3449, 1504.4918), heading = 307.7658},
        {pos = vector3(-22.7496, -7.7381, 1504.4945), heading = 287.0555},
        {pos = vector3(-23.3072, -0.8331, 1504.4939), heading = 278.5499},
        {pos = vector3(-23.6538, 4.5899, 1504.4946), heading = 266.0492},
        {pos = vector3(-21.9295, 11.2284, 1504.4930), heading = 236.4735},
        {pos = vector3(-18.3467, 15.3241, 1504.4926), heading = 227.8479}
    }

    local playerIndex = 1
    for i, participant in pairs(event.participants) do
        if participant.id == playerId then
            playerIndex = i
            break
        end
    end

    local spawnIndex = ((playerIndex - 1) % #spawnPositions) + 1
    local spawnData = spawnPositions[spawnIndex]


    return spawnData.pos, spawnData.heading
end

---@param eventId string Event identifier
---@return string modelName GTA vehicle model name
local function getRandomVehicle(eventId)
    local event = carSumoEvents[eventId]
    local vehicles = event and event.customSettings and event.customSettings.vehicles or Config.Events.CarSumo.defaultVehicles
    if not vehicles or #vehicles == 0 then
        return "adder"
    end
    local randomIndex = math.random(1, #vehicles)
    return vehicles[randomIndex]
end

---@param eventId string Event identifier
---@param center vector3 Arena center position
---@param radius number Arena radius (kept for future tiling logic)
local function createCarSumoPlatform(eventId, center, radius)
    if carSumoEvents[eventId] and carSumoEvents[eventId].platformObjects then
        return
    end

    if not carSumoEvents[eventId] then
        carSumoEvents[eventId] = {}
    end

    carSumoEvents[eventId].platformObjects = {}

    local platformFloor = CreateObject(GetHashKey("stt_prop_stunt_target"), center.x, center.y, center.z - 1.0, true, false, false)
    FreezeEntityPosition(platformFloor, true)
    SetEntityHeading(platformFloor, 0.0)

    table.insert(carSumoEvents[eventId].platformObjects, platformFloor)
end

---@param eventId string Event identifier
local function removeCarSumoPlatform(eventId)
    if carSumoEvents[eventId] and carSumoEvents[eventId].platformObjects then
        for _, obj in pairs(carSumoEvents[eventId].platformObjects) do
            if DoesEntityExist(obj) then
                DeleteEntity(obj)
            end
        end
        carSumoEvents[eventId].platformObjects = nil
    end
end

---@param eventId string Event identifier
local function startCarSumoEvent(eventId)

    local event = exports['peleg-events']:getActiveEvents()[eventId]
    if not event then
        return
    end

    if #event.participants < 2 then
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


    carSumoEvents[eventId] = {
        participants = event.participants,
        alivePlayers = {},
        startedAt = os.time(),
        vehicleDamage = {}
    }

    local eventBucket = 1000 + (tonumber(eventId:match("%d+")) or math.random(1000, 9999))

    for _, participant in pairs(event.participants) do
        SetPlayerRoutingBucket(participant.id, eventBucket)
        Wait(100)
    end

    local center = vector3(0.0, 0.0, 1504.5)
    local radius = 30.0
    createCarSumoPlatform(eventId, center, radius)

    Wait(1000)

    for _, participant in pairs(event.participants) do
        local spawnPos, heading = getCarSumoSpawnPosition(eventId, participant.id)
        local vehicleModel = getRandomVehicle(eventId)
        TriggerClientEvent('peleg-events:spawnCarSumoVehicle', participant.id, eventId, vehicleModel, spawnPos, heading)
        carSumoEvents[eventId].alivePlayers[participant.id] = true

        
        if GetPlayerPed(participant.id) then
            local ped = GetPlayerPed(participant.id)
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle and DoesEntityExist(vehicle) then
                FreezeEntityPosition(vehicle, true)
                TriggerClientEvent('peleg-events:freezeCarSumoVehicle', participant.id, eventId, true)
            else
                FreezeEntityPosition(ped, true)
            end
        end
        
    end

    for _, participant in pairs(event.participants) do
        TriggerClientEvent('peleg-events:carSumoCountdown', participant.id, eventId, Config.Events.CarSumo.countdownDuration)
    end

    SetTimeout(Config.Events.CarSumo.countdownDuration * 1000, function()
        if not carSumoEvents[eventId] then
            return
        end


        for _, participant in pairs(event.participants) do
            if GetPlayerPed(participant.id) then
                local ped = GetPlayerPed(participant.id)
                local vehicle = GetVehiclePedIsIn(ped, false)
                if vehicle and DoesEntityExist(vehicle) then
                    FreezeEntityPosition(vehicle, false)
                    TriggerClientEvent('peleg-events:freezeCarSumoVehicle', participant.id, eventId, false)
                else
                    FreezeEntityPosition(ped, false)
                end
            end
        end

        for _, participant in pairs(event.participants) do
            TriggerClientEvent('peleg-events:hideGlobalEventJoinPanel', participant.id)
            TriggerClientEvent('peleg-events:hideEventJoinPanel', participant.id)
        end

        for _, participant in pairs(event.participants) do
            TriggerClientEvent('peleg-events:carSumoStarted', participant.id, eventId)
        end
    end)

    CreateThread(function()
        while carSumoEvents[eventId] and carSumoEvents[eventId].alivePlayers do
            Wait(1500)
            for playerId, isAlive in pairs(carSumoEvents[eventId].alivePlayers) do
                if isAlive and GetPlayerPed(playerId) then
                    local playerPos = GetEntityCoords(GetPlayerPed(playerId))
                    local fallHeight = 1501.0
                    if playerPos.z < fallHeight then
                        carSumoEvents[eventId].alivePlayers[playerId] = false
                        TriggerClientEvent('peleg-events:explodeCarSumoVehicle', playerId, eventId)
                        local spectatorPos = vector3(0.0, 0.0, 1604.5)
                        SetEntityCoords(GetPlayerPed(playerId), spectatorPos.x, spectatorPos.y, spectatorPos.z, false, false, false, true)
                        FreezeEntityPosition(GetPlayerPed(playerId), true)

                        local killerId = carSumoEvents[eventId].vehicleDamage[playerId]
                        local killerName = "Gravity"
                        if killerId then
                            killerName = GetPlayerName(killerId)
                            TriggerEvent('peleg-events:addKill', eventId, killerId, playerId)
                        end

                        TriggerEvent('peleg-events:playerDied', eventId, playerId)

                        TriggerClientEvent('peleg-events:addKillFeed', -1, {
                            killer = killerName,
                            victim = GetPlayerName(playerId),
                            eventType = "CarSumo"
                        })

                        TriggerClientEvent('peleg-events:playerEliminated', -1, eventId, playerId, GetPlayerName(playerId))

                        local aliveCount = 0
                        local lastAlivePlayer = nil
                        for pid, alive in pairs(carSumoEvents[eventId].alivePlayers) do
                            if alive then
                                aliveCount = aliveCount + 1
                                lastAlivePlayer = pid
                            end
                        end

                        if aliveCount <= 1 then
                            local winnerId = lastAlivePlayer
                            finishEvent(eventId, winnerId)

                            if carSumoEvents[eventId] and carSumoEvents[eventId].participants then
                                for _, participant in pairs(carSumoEvents[eventId].participants) do
                                    TriggerClientEvent('peleg-events:carSumoEventEnded', participant.id, eventId)
                                end
                            end

                            carSumoEvents[eventId] = nil
                            return
                        end
                    end
                end
            end
        end
    end)
end

---@param eventId string Event identifier
---@param playerId number Server ID of the player being eliminated
local function handleCarSumoPlayerDeath(eventId, playerId)
    if not carSumoEvents[eventId] or not carSumoEvents[eventId].alivePlayers[playerId] then
        return
    end

    carSumoEvents[eventId].alivePlayers[playerId] = false

    local spectatorPos = vector3(0.0, 0.0, 1604.5)
    SetEntityCoords(GetPlayerPed(playerId), spectatorPos.x, spectatorPos.y, spectatorPos.z, false, false, false, true)
    FreezeEntityPosition(GetPlayerPed(playerId), true)

    TriggerClientEvent('peleg-events:explodeCarSumoVehicle', playerId, eventId)

    TriggerEvent('peleg-events:playerDied', eventId, playerId)

    TriggerClientEvent('peleg-events:addKillFeed', -1, {
        killer = "Death",
        victim = GetPlayerName(playerId),
        eventType = "CarSumo"
    })

    TriggerClientEvent('peleg-events:playerEliminated', -1, eventId, playerId, GetPlayerName(playerId))

    local aliveCount = 0
    local lastAlivePlayer = nil
    for pid, alive in pairs(carSumoEvents[eventId].alivePlayers) do
        if alive then
            aliveCount = aliveCount + 1
            lastAlivePlayer = pid
        end
    end

    if aliveCount <= 1 then
        local winnerId = lastAlivePlayer
        finishEvent(eventId, winnerId)

        local event = exports['peleg-events']:getActiveEvents()[eventId]
        if event and event.participants then
            for _, participant in pairs(event.participants) do
                TriggerClientEvent('peleg-events:carSumoEventEnded', participant.id, eventId)
            end
        end

        carSumoEvents[eventId] = nil
    end
end

RegisterNetEvent('peleg-events:startCarSumo', function(eventId)
    startCarSumoEvent(eventId)
end)

RegisterNetEvent('peleg-events:carSumoPlayerDied', function(eventId)
    local source = source
    handleCarSumoPlayerDeath(eventId, source)
end)

RegisterNetEvent('peleg-events:carSumoPlayerFell', function(eventId)
    local source = source
    handleCarSumoPlayerDeath(eventId, source)
end)

RegisterNetEvent('peleg-events:carSumoPlayerPushed', function(eventId, victimId)
    local source = source
    local killerName = GetPlayerName(source)
    local victimName = GetPlayerName(victimId)

    TriggerClientEvent('peleg-events:addKillFeed', -1, {
        killer = killerName,
        victim = victimName,
        eventType = "CarSumo"
    })

    handleCarSumoPlayerDeath(eventId, victimId)
end)

RegisterNetEvent('peleg-events:carSumoVehicleDamaged', function(eventId, victimId)
    local source = source
    if carSumoEvents[eventId] then
        carSumoEvents[eventId].vehicleDamage[victimId] = source
    end
end)

RegisterNetEvent('peleg-events:cleanupCarSumo', function(eventId)
    if carSumoEvents[eventId] then
        removeCarSumoPlatform(eventId)

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
                end
            end
        end

        TriggerClientEvent('peleg-events:carSumoEventEnded', -1, eventId)

        carSumoEvents[eventId] = nil
    end
end)
