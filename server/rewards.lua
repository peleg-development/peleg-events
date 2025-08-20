-- Rewards System for Peleg Events
local Rewards = {}

-- Framework detection
local ESX = nil
local QBCore = nil

CreateThread(function()
    if GetResourceState('es_extended') == 'started' then
        ESX = exports['es_extended']:getSharedObject()
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
    end
end)

---@param playerId number The player ID
---@param rewardType string The type of reward (money, item, vehicle)
---@param rewardData table The reward data
---@return boolean success Whether the reward was given successfully
---@return string message Success or error message
function Rewards.GiveReward(playerId, rewardType, rewardData)
    if not GetPlayerPed(playerId) then
        return false, "Player not found"
    end
    
    if rewardType == "money" then
        return Rewards.GiveMoney(playerId, rewardData.amount)
    elseif rewardType == "item" then
        return Rewards.GiveItem(playerId, rewardData.item, rewardData.amount)
    elseif rewardType == "vehicle" then
        return Rewards.GiveVehicle(playerId, rewardData.vehicle, rewardData.plate)
    else
        return false, "Invalid reward type"
    end
end

---@param playerId number The player ID
---@param amount number The amount of money
---@return boolean success Whether the money was given successfully
---@return string message Success or error message
function Rewards.GiveMoney(playerId, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.addMoney(amount)
            return true, "Money given successfully"
        else
            return false, "ESX player not found"
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            Player.Functions.AddMoney('cash', amount)
            return true, "Money given successfully"
        else
            return false, "QB player not found"
        end
    else
        return false, "No framework detected"
    end
end

---@param playerId number The player ID
---@param itemName string The item name
---@param amount number The amount of items
---@return boolean success Whether the item was given successfully
---@return string message Success or error message
function Rewards.GiveItem(playerId, itemName, amount)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            xPlayer.addInventoryItem(itemName, amount)
            return true, "Item given successfully"
        else
            return false, "ESX player not found"
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            -- Check which inventory system is being used
            if GetResourceState('ox_inventory') == 'started' then
                -- ox_inventory
                exports.ox_inventory:AddItem(playerId, itemName, amount)
                return true, "Item given successfully (ox_inventory)"
            elseif GetResourceState('qs-inventory') == 'started' then
                -- qs-inventory
                exports['qs-inventory']:AddItem(playerId, itemName, amount)
                return true, "Item given successfully (qs-inventory)"
            else
                -- Default QB inventory
                Player.Functions.AddItem(itemName, amount)
                TriggerClientEvent('inventory:client:ItemBox', playerId, QBCore.Shared.Items[itemName], "add")
                return true, "Item given successfully (qb-inventory)"
            end
        else
            return false, "QB player not found"
        end
    else
        return false, "No framework detected"
    end
end

---@param playerId number The player ID
---@param vehicleModel string The vehicle model
---@param plate string The license plate (optional)
---@return boolean success Whether the vehicle was given successfully
---@return string message Success or error message
function Rewards.GiveVehicle(playerId, vehicleModel, plate)
    if ESX then
        local xPlayer = ESX.GetPlayerFromId(playerId)
        if xPlayer then
            -- ESX Garage system
            if GetResourceState('esx_garage') == 'started' then
                -- Add to ESX garage database
                MySQL.Async.execute('INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle)', {
                    ['@owner'] = xPlayer.identifier,
                    ['@plate'] = plate or GeneratePlate(),
                    ['@vehicle'] = json.encode({model = GetHashKey(vehicleModel), plate = plate or GeneratePlate()})
                })
                return true, "Vehicle added to garage successfully"
            else
                return false, "ESX garage not found"
            end
        else
            return false, "ESX player not found"
        end
    elseif QBCore then
        local Player = QBCore.Functions.GetPlayer(playerId)
        if Player then
            -- QB Garage system
            if GetResourceState('qb-garage') == 'started' then
                -- Add to QB garage database
                MySQL.Async.execute('INSERT INTO player_vehicles (license, citizenid, vehicle, hash, mods, plate, state) VALUES (@license, @citizenid, @vehicle, @hash, @mods, @plate, @state)', {
                    ['@license'] = Player.PlayerData.license,
                    ['@citizenid'] = Player.PlayerData.citizenid,
                    ['@vehicle'] = vehicleModel,
                    ['@hash'] = GetHashKey(vehicleModel),
                    ['@mods'] = '{}',
                    ['@plate'] = plate or GeneratePlate(),
                    ['@state'] = 1
                })
                return true, "Vehicle added to garage successfully"
            else
                return false, "QB garage not found"
            end
        else
            return false, "QB player not found"
        end
    else
        return false, "No framework detected"
    end
end

---@return string A randomly generated license plate
function GeneratePlate()
    local plate = ""
    for i = 1, 8 do
        if i <= 3 then
            plate = plate .. string.char(math.random(65, 90)) -- A-Z
        else
            plate = plate .. math.random(0, 9) -- 0-9
        end
    end
    return plate
end

-- Export the rewards system
exports('GiveReward', Rewards.GiveReward)
exports('GiveMoney', Rewards.GiveMoney)
exports('GiveItem', Rewards.GiveItem)
exports('GiveVehicle', Rewards.GiveVehicle)

return Rewards
