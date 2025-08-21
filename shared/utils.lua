local _print = print
print = function(...)
    if Config.Debug then
        _print(...)
    end
end

-- Framework detection and utility functions
Framework = {}

---@param framework string The framework to detect (esx, qbcore, standalone)
---@return table|nil The framework object or nil if not found
function Framework.Detect(framework)
    if framework == "auto" or framework == "esx" then
        if GetResourceState('es_extended') == 'started' then
            return exports['es_extended']:getSharedObject()
        end
    end
    
    if framework == "auto" or framework == "qbcore" then
        if GetResourceState('qb-core') == 'started' then
            return exports['qb-core']:GetCoreObject()
        end
    end
    
    return nil
end

---@param playerId number The player ID
---@return string|nil The player's license identifier
function Framework.GetPlayerLicense(playerId)
    for _, identifier in pairs(GetPlayerIdentifiers(playerId)) do
        if string.find(identifier, "license:") then
            return identifier
        end
    end
    return nil
end
