local carSumoVehicles = {}
local currentCarSumoEvent = nil

--- @param eventId string
--- @param vehicleModel string
--- @param spawnPos vector3|table
--- @param heading number
RegisterNetEvent('peleg-events:spawnCarSumoVehicle', function(eventId, vehicleModel, spawnPos, heading)
    local vehicleHash = GetHashKey(vehicleModel)
    RequestModel(vehicleHash)
    local attempts = 0
    while not HasModelLoaded(vehicleHash) and attempts < 100 do
        Wait(10)
        attempts = attempts + 1
    end

    if not HasModelLoaded(vehicleHash) then
        SetModelAsNoLongerNeeded(vehicleHash)
        return
    end

    local vehicle = CreateVehicle(vehicleHash, spawnPos.x, spawnPos.y, spawnPos.z + 1.0, heading, true, true)
    if vehicle and DoesEntityExist(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        SetVehicleEngineOn(vehicle, true, true, false)
        SetVehicleDoorsLocked(vehicle, 1)
        Wait(500)

        local finalVehiclePos = GetEntityCoords(vehicle)
        local finalVehicleHeading = GetEntityHeading(vehicle)
        local ped = PlayerPedId()
        SetPedIntoVehicle(ped, vehicle, -1)

        Wait(100)
        if not IsPedInVehicle(ped, vehicle, false) then
            SetEntityCoords(ped, finalVehiclePos.x, finalVehiclePos.y, finalVehiclePos.z + 2.0, false, false, false, true)
            SetEntityHeading(ped, finalVehicleHeading)
            Wait(200)
            SetPedIntoVehicle(ped, vehicle, -1)
        end
        FreezeEntityPosition(vehicle, true)
        carSumoVehicles[eventId] = vehicle
        currentCarSumoEvent = eventId
        SetModelAsNoLongerNeeded(vehicleHash)
    else
        SetModelAsNoLongerNeeded(vehicleHash)
    end
end)

--- @param eventId string
RegisterNetEvent('peleg-events:explodeCarSumoVehicle', function(eventId)
    local vehicle = carSumoVehicles[eventId]
    if vehicle and DoesEntityExist(vehicle) then
        local ped = PlayerPedId()
        if IsPedInVehicle(ped, vehicle, false) then
            TaskLeaveVehicle(ped, vehicle, 0)
            Wait(100)
        end
        ExplodeVehicle(vehicle, true, false, false)
        carSumoVehicles[eventId] = nil
    end
    if currentCarSumoEvent == eventId then
        currentCarSumoEvent = nil
    end
end)

--- @param eventId string
--- @param freeze boolean
RegisterNetEvent('peleg-events:freezeCarSumoVehicle', function(eventId, freeze)
    local vehicle = carSumoVehicles[eventId]
    if vehicle and DoesEntityExist(vehicle) then
        if freeze then
            SetVehicleEngineOn(vehicle, false, true, true)
        else
            SetVehicleEngineOn(vehicle, true, true, false)
        end
    end
end)

--- @param eventId string
--- @param duration number Seconds
RegisterNetEvent('peleg-events:carSumoCountdown', function(eventId, duration)
    if currentEventId == eventId or joinedEventId == eventId then
        FreezeEntityPosition(PlayerPedId(), true)
        SendNUIMessage({ action = "showCountdown", eventId = eventId, countdown = duration })
    end
end)

--- @param eventId string
RegisterNetEvent('peleg-events:carSumoStarted', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        SendNUIMessage({ action = "hideGlobalEventJoinPanel" })
        SendNUIMessage({ action = "hideEventJoinPanel" })
    end
end)

--- @param eventId string
RegisterNetEvent('peleg-events:carSumoEventEnded', function(eventId)
    if carSumoVehicles[eventId] then
        if DoesEntityExist(carSumoVehicles[eventId]) then
            DeleteEntity(carSumoVehicles[eventId])
        end
        carSumoVehicles[eventId] = nil
    end
    if currentCarSumoEvent == eventId then
        currentCarSumoEvent = nil
    end
end)

local damageTracker = {}

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' and currentCarSumoEvent then
        local victim = data[1]
        local attacker = data[2]
        if DoesEntityExist(victim) and DoesEntityExist(attacker) then
            local victimType = GetEntityType(victim)
            local attackerType = GetEntityType(attacker)
            if victimType == 2 and attackerType == 1 then
                local playerPed = PlayerPedId()
                local playerVehicle = GetVehiclePedIsIn(playerPed, false)
                if victim == playerVehicle then
                    local attackerVehicle = GetVehiclePedIsIn(attacker, false)
                    if attackerVehicle and DoesEntityExist(attackerVehicle) and IsPedAPlayer(attacker) then
                        local attackerPlayerId = NetworkGetPlayerIndexFromPed(attacker)
                        local attackerServerId = GetPlayerServerId(attackerPlayerId)
                        local now = GetGameTimer()
                        local key = attackerServerId
                        if not damageTracker[key] or (now - damageTracker[key]) > 1000 then
                            damageTracker[key] = now
                            TriggerServerEvent('peleg-events:carSumoVehicleDamaged', currentCarSumoEvent, attackerServerId)
                        end
                    end
                end
                if attacker == playerPed then
                    local victimPed = GetPedInVehicleSeat(victim, -1)
                    if victimPed and IsPedAPlayer(victimPed) then
                        local victimPlayerId = NetworkGetPlayerIndexFromPed(victimPed)
                        local victimServerId = GetPlayerServerId(victimPlayerId)
                        local now = GetGameTimer()
                        local key = victimServerId
                        if not damageTracker[key] or (now - damageTracker[key]) > 1000 then
                            damageTracker[key] = now
                            TriggerServerEvent('peleg-events:carSumoVehicleDamaged', currentCarSumoEvent, victimServerId)
                        end
                    end
                end
            end
        end
    end
end)
