local currentRedzoneEvent = nil
local redzoneZoneBlip = nil
local redzoneZoneRadius = 200.0
local redzoneZoneCenter = vector3(850.0, 100.0, 1500.0)
local currentRedzoneWeapon = nil
local infiniteAmmo = false
local zoneUpdateThread = nil

--- Spawn player in Redzone event
---@param eventId string
---@param spawnPos vector3
RegisterNetEvent('peleg-events:spawnRedzonePlayer', function(eventId, spawnPos)
    if currentEventId == eventId or joinedEventId == eventId then
        currentRedzoneEvent = eventId
        SetEntityCoords(PlayerPedId(), spawnPos.x, spawnPos.y, spawnPos.z, false, false, false, true)
        
        -- Clear all weapons when joining redzone
        local ped = PlayerPedId()
        RemoveAllPedWeapons(ped, true)
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        
        if redzoneZoneBlip and DoesBlipExist(redzoneZoneBlip) then
            RemoveBlip(redzoneZoneBlip)
        end
        
        redzoneZoneBlip = AddBlipForRadius(redzoneZoneCenter.x, redzoneZoneCenter.y, redzoneZoneCenter.z, redzoneZoneRadius)
        SetBlipRotation(redzoneZoneBlip, 0)
        SetBlipColour(redzoneZoneBlip, 1)
        SetBlipAlpha(redzoneZoneBlip, 128)
        SetBlipDisplay(redzoneZoneBlip, 4)
        SetBlipAsShortRange(redzoneZoneBlip, false)
        
        print("^3[Client] Spawned at " .. json.encode(spawnPos) .. " for Redzone event^7")
    end
end)

--- Give weapon to player for Redzone event
---@param eventId string
---@param weapon string
RegisterNetEvent('peleg-events:giveRedzoneWeapon', function(eventId, weapon)
    if currentEventId == eventId or joinedEventId == eventId then
        currentRedzoneWeapon = weapon
        local ped = PlayerPedId()
        
        RemoveAllPedWeapons(ped, true)
        GiveWeaponToPed(ped, GetHashKey(weapon), 9999, false, true)
        SetPedInfiniteAmmo(ped, true, GetHashKey(weapon))
        SetPedInfiniteAmmoClip(ped, true)
        
        infiniteAmmo = true
        print("^3[Client] Given weapon " .. weapon .. " for Redzone event^7")
    end
end)

--- Remove weapon from player when event ends
---@param eventId string
RegisterNetEvent('peleg-events:removeRedzoneWeapon', function(eventId)
        local ped = PlayerPedId()
        RemoveAllPedWeapons(ped, true)
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        SetPedInfiniteAmmo(ped, false, GetHashKey("WEAPON_UNARMED"))
        SetPedInfiniteAmmoClip(ped, false)
        
        currentRedzoneWeapon = nil
        infiniteAmmo = false
        print("^3[Client] Removed weapons for Redzone event^7")
 
end)

--- Give full armor to player after kill
---@param eventId string
RegisterNetEvent('peleg-events:giveFullArmor', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        local ped = PlayerPedId()
        SetPedArmour(ped, 100)
        print("^3[Client] Given full armor for kill^7")
    end
end)

--- Start smooth zone shrinking
---@param eventId string
---@param center vector3
---@param initialRadius number
---@param shrinkDuration number
RegisterNetEvent('peleg-events:startRedzoneShrinking', function(eventId, center, initialRadius, shrinkDuration)
    if currentEventId == eventId or joinedEventId == eventId then
        redzoneZoneCenter = center
        redzoneZoneRadius = initialRadius
        
        if redzoneZoneBlip and DoesBlipExist(redzoneZoneBlip) then
            RemoveBlip(redzoneZoneBlip)
        end
        
        redzoneZoneBlip = AddBlipForRadius(center.x, center.y, center.z, initialRadius)
        SetBlipRotation(redzoneZoneBlip, 0)
        SetBlipColour(redzoneZoneBlip, 1)
        SetBlipAlpha(redzoneZoneBlip, 128)
        SetBlipDisplay(redzoneZoneBlip, 4)
        SetBlipAsShortRange(redzoneZoneBlip, false)
        
        if zoneUpdateThread then
            zoneUpdateThread = nil
        end
        
        zoneUpdateThread = CreateThread(function()
            local startTime = GetGameTimer()
            local finalRadius = 10.0
            
            while currentRedzoneEvent == eventId and (currentEventId == eventId or joinedEventId == eventId) do
                Wait(0)
                local elapsedTime = GetGameTimer() - startTime
                local progress = math.min(elapsedTime / shrinkDuration, 1.0)
                
                redzoneZoneRadius = initialRadius - (progress * (initialRadius - finalRadius))
                
                if redzoneZoneBlip and DoesBlipExist(redzoneZoneBlip) then
                    RemoveBlip(redzoneZoneBlip)
                end
                
                redzoneZoneBlip = AddBlipForRadius(center.x, center.y, center.z, redzoneZoneRadius)
                SetBlipRotation(redzoneZoneBlip, 0)
                SetBlipColour(redzoneZoneBlip, 1)
                SetBlipAlpha(redzoneZoneBlip, 128)
                SetBlipDisplay(redzoneZoneBlip, 4)
                SetBlipAsShortRange(redzoneZoneBlip, false)
                
                DrawMarker(
                    28, -- Sphere marker type
                    center.x, center.y, center.z, -- Position
                    0.0, 0.0, 0.0, -- Direction
                    0.0, 0.0, 0.0, -- Rotation
                    redzoneZoneRadius, redzoneZoneRadius, redzoneZoneRadius, -- Scale (same as blip radius)
                    255, 0, 0, 100, -- Red color with alpha
                    false, -- Bob up and down
                    false, -- Face camera
                    2, -- p19
                    false, -- Rotate
                    nil, -- Texture dictionary
                    nil, -- Texture name
                    false -- Draw on entities
                )
            end
        end)
        
        print("^3[Client] Started zone shrinking: center=" .. json.encode(center) .. ", radius=" .. initialRadius .. "^7")
    end
end)

--- Damage player when outside zone
---@param eventId string
---@param damage number
RegisterNetEvent('peleg-events:damageRedzonePlayer', function(eventId, damage)
    if currentEventId == eventId or joinedEventId == eventId then
        local ped = PlayerPedId()
        local health = GetEntityHealth(ped)
        local newHealth = health - damage
        
        if newHealth <= 0 then
            newHealth = 0
        end
        
        SetEntityHealth(ped, newHealth)
        
        if newHealth <= 0 then
            TriggerServerEvent('peleg-events:redzonePlayerDied', eventId)
        end
    end
end)

--- Handle Redzone start
---@param eventId string
RegisterNetEvent('peleg-events:redzoneStarted', function(eventId)
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
        
        SendNUIMessage({ type = "redzoneStarted", eventId = eventId })
        print("^3[Client] Redzone event started^7")
    end
end)

--- Restore player health and armor
RegisterNetEvent('peleg-events:restorePlayerHealth', function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, 200)
    SetPedArmour(ped, 0)
    print("^3[Client] Player health restored^7")
end)

--- Cleanup Redzone when event ends
---@param eventId string
RegisterNetEvent('peleg-events:redzoneEventEnded', function(eventId)
    if currentEventId == eventId or joinedEventId == eventId then
        if redzoneZoneBlip and DoesBlipExist(redzoneZoneBlip) then
            RemoveBlip(redzoneZoneBlip)
            redzoneZoneBlip = nil
        end
        
        local blip = GetFirstBlipInfoId(4)
        while blip ~= 0 do
            if DoesBlipExist(blip) then
                RemoveBlip(blip)
            end
            blip = GetNextBlipInfoId(4)
        end
        
        if zoneUpdateThread then
            zoneUpdateThread = nil
        end
        
        -- Hide kills UI when event ends
        SendNUIMessage({ action = "hideKillsCounter" })
        
        local ped = PlayerPedId()
        RemoveAllPedWeapons(ped, true)
        SetCurrentPedWeapon(ped, GetHashKey("WEAPON_UNARMED"), true)
        SetPedInfiniteAmmo(ped, false, GetHashKey("WEAPON_UNARMED"))
        SetPedInfiniteAmmoClip(ped, false)
        
        SetEntityHealth(ped, 200)
        SetPedArmour(ped, 0)
        
        currentRedzoneEvent = nil
        currentRedzoneWeapon = nil
        infiniteAmmo = false
        isInEvent = false
        
        if currentEventId == eventId then
            currentEventId = nil
        end
        if joinedEventId == eventId then
            joinedEventId = nil
        end
        
        print("^3[Client] Redzone event ended^7")
    end
end)

--- Track kills for Redzone damage events
local killTracker = {}

AddEventHandler('gameEventTriggered', function(eventName, data)
    if eventName == 'CEventNetworkEntityDamage' and currentRedzoneEvent then
        local victim = data[1]
        local attacker = data[2]
        local isDead = data[4]
        local weapon = data[5]
        local isMelee = data[10]
        
        if isDead and DoesEntityExist(victim) and DoesEntityExist(attacker) then
            local victimType = GetEntityType(victim)
            local attackerType = GetEntityType(attacker)
            
            if victimType == 1 and attackerType == 1 and IsPedAPlayer(victim) and IsPedAPlayer(attacker) then
                local playerPed = PlayerPedId()
                
                if attacker == playerPed then
                    local victimPlayerId = NetworkGetPlayerIndexFromPed(victim)
                    local victimServerId = GetPlayerServerId(victimPlayerId)
                    local now = GetGameTimer()
                    local key = victimServerId
                    
                    if not killTracker[key] or (now - killTracker[key]) > 1000 then
                        killTracker[key] = now
                        TriggerServerEvent('peleg-events:redzonePlayerKilled', currentRedzoneEvent, victimServerId)
                        TriggerServerEvent('peleg-events:redzoneKillReward', currentRedzoneEvent)
                        print("^3[Client] Killed player " .. victimServerId .. " in Redzone^7")
                    end
                end
            end
        end
    end
end)

--- Maintain infinite ammo and monitor player death
CreateThread(function()
    while true do
        Wait(1000)
        if infiniteAmmo and currentRedzoneWeapon then
            local ped = PlayerPedId()
            local weaponHash = GetHashKey(currentRedzoneWeapon)
            
            if HasPedGotWeapon(ped, weaponHash, false) then
                SetPedInfiniteAmmo(ped, true, weaponHash)
                SetPedInfiniteAmmoClip(ped, true)
            end
        end
        
        if currentRedzoneEvent and (currentEventId == currentRedzoneEvent or joinedEventId == currentRedzoneEvent) then
            local ped = PlayerPedId()
            if IsEntityDead(ped) then
                TriggerServerEvent('peleg-events:redzonePlayerDied', currentRedzoneEvent)
                print("^3[Client] Player died in Redzone event^7")
            end
        end
    end
end)

