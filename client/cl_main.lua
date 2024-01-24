
local QBCore = exports['qb-core']:GetCoreObject()

function dump(o) 
    if type(o) == 'table' then
        local s = '{ '
        for k,v in pairs(o) do
            if type(k) ~= 'number' then k = '"'..k..'"' end
            s = s .. '['..k..'] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end
--------------------------------------------------------------Polyzone--------------------------------------------------------------
local infectedZones = {}
local inZone = false
local myZone = nil
function CreateInitialInfectionPolyzone(locationIndex)
    if infectedZones[locationIndex] then return end
    local configLocation = Config.Locations[locationIndex]
    if not configLocation then return end
    local coords_v4 = configLocation.coords
    if not coords_v4 then return end
    
    local coords = vector3(coords_v4.x, coords_v4.y, coords_v4.z)
    if not coords then return end
    local heading = coords_v4.w
    if not heading then return end
    local length = configLocation.length
    if not length then return end
    local width = configLocation.width
    if not width then return end
    
    local zone = BoxZone:Create(coords, length, width, {
        name = 'infectedlocation_' .. locationIndex,
        heading = heading,
        minZ = coords.z - 1.0,
        maxZ = coords.z + 5.0,
        debugPoly = Config.DebugPoly
    })
    zone:onPlayerInOut(function(isPointInside, point)
        if isPointInside then
            if inZone then return end
            local pedNetId = NetworkGetNetworkIdFromEntity(PlayerPedId())
            local data = {locationIndex = locationIndex, infecteePed = pedNetId, infectorPed = pedNetId}
            QBCore.Functions.TriggerCallback('mrc-disease:cb:InfectPlayer', function(disease)
                local configDisease = Config.Diseases[disease]
                if not configDisease then return end
                local effectEvent = configDisease.effectEvent
                if not effectEvent then return end
                local data = {disease = disease}
                TriggerEvent(effectEvent, data)
            end, data)
            inZone = true
        else
            inZone = false
        end
    end)
    infectedZones[locationIndex] = zone
end



--{infectorPed = infectorPed, infectRadius = infectRadius}
RegisterNetEvent('mrc-disease:client:SetupPlayerInfectedZone', function(data)
    if not data then return end
    local infectorPed = data.infectorPed
    if not infectorPed then return end
    local size = data.infectRadius
    if not size then return end
    local rebuild = data.rebuild

    local ped = NetToPed(infectorPed)
    if not ped then return end

    local id = 'player-'.. ped
    local entityZone = infectedZones[ped]
    if entityZone and rebuild then 
        if entityZone then entityZone:destroy() end
        entityZone = nil
    end
    if entityZone then return end

    entityZone = EntityZone:Create(ped, {
        name = "infectedPlayer_" .. ped,
        scale = {size * 2.5, size, 1.5},
        useZ = true,
        debugPoly = Config.DebugPoly,
    })

    entityZone:onPlayerInOut(function(isPointInside, point)
        if isPointInside then 
            if inZone then return end
            local infecteePed = PedToNet(PlayerPedId())
            if not infecteePed then return end
            if infectorPed == infecteePed then return end
            local data = {infecteePed = infecteePed, infectorPed = infectorPed}
            QBCore.Functions.TriggerCallback('mrc-disease:cb:InfectPlayer', function(disease)
                --trigger config client event
                local configDisease = Config.Diseases[disease]
                if not configDisease then return end
                local effectEvent = configDisease.effectEvent
                if not effectEvent then return end
                local data = {disease = disease}
                TriggerEvent(effectEvent, data)
            end, data)
            inZone = true
        else
            inZone = false
        end
    end)
    infectedZones[id] = entityZone
end)

RegisterNetEvent('mrc-disease:client:RemovePlayerInfectedZone', function(data)
    if not data then return end
    local infectorPed = data.infectorPed
    if not infectorPed then return end
    local ped = NetToPed(infectorPed)
    if not ped then return end
    local id = 'player-'.. ped
    local entityZone = infectedZones[id]
    if not entityZone then return end
    entityZone:destroy()
    infectedZones[id] = nil
end)

RegisterNetEvent('mrc-disease:client:SetupDiseaseLocations', function(data)
    local locations = data.locations
    if not locations then return end
    for k, _ in pairs(locations) do
        CreateInitialInfectionPolyzone(k)
    end
end)

function IsInfectedWith(PlayerData, disease)
    if not PlayerData then return end
    local metadata = PlayerData.metadata
    if not metadata then return end
    local diseases = metadata['diseases']
    if not diseases then return end
    return diseases[disease]
   
end

RegisterNetEvent('mrc-disease:client:AttemptToCure', function(data)--{item = 'hemostat'}
    if not data then return end
    local item = data.item
    if not item then return end
    local cureItemConfig = Config.CureItems[item]
    if not cureItemConfig then return end

    local cures = cureItemConfig.cures
    if not cures then return end

    --Check all players in the area
    CreateThread(function()
        local PlayerData = QBCore.Functions.GetPlayerData()
        for disease, isCure in pairs(cures) do 
            if IsInfectedWith(PlayerData, disease) then 
                --progressbar and send to server
                QBCore.Functions.Progressbar('TryingToCureDisease', 'Attempting to cure yourself', 1500, false, true, {
                    disableMovement = true,
                    disableCarMovement = true,
                    disableMouse = false,
                    disableCombat = true
                    }, {}, {}, {}, function()
                        local playerPed = PlayerPedId()
                        local pedNetId = NetworkGetNetworkIdFromEntity(playerPed)
                        TriggerServerEvent('mrc-disease:server:AttemptToCure', {disease = disease, target = 'self', pedNetId = pedNetId, item = item})
                        -- This code runs if the progress bar completes successfully
                    end, function()
                        -- This code runs if the progress bar gets cancelled
                end)
                return 
            else
                local closestPlayer, closestDistance = QBCore.Functions.GetClosestPlayer()
                if closestPlayer == -1 or closestDistance > 3.0 then
                    QBCore.Functions.Notify('No players nearby', 'error')
                    return
                end
                local closestPlayerData = QBCore.Functions.GetPlayerData(closestPlayer)
                if not closestPlayerData then return end
                if IsInfectedWith(closestPlayerData, disease) then 
                    QBCore.Functions.Progressbar('TryingToCureDisease', 'Attempting to cure player', 1500, false, true, {
                        disableMovement = true,
                        disableCarMovement = true,
                        disableMouse = false,
                        disableCombat = true
                        }, {}, {}, {}, function()
                            local playerPed = GetPlayerPed(closestPlayer)
                            local pedNetId = NetworkGetNetworkIdFromEntity(playerPed)
                            TriggerServerEvent('mrc-disease:server:AttemptToCure', {disease = disease, target = 'other', pedNetId = pedNetId, item = item})
                        end, function()
                            -- This code runs if the progress bar gets cancelled
                    end)
                    return 
                end
            end
        end
    end)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    for k, v in pairs(infectedZones) do
        v:destroy()
    end
end)

function LoadPlayerDiseases()
    local infecteePed = NetworkGetNetworkIdFromEntity(PlayerPedId())
    if not infecteePed then return end
    local sendData = {infecteePed = infecteePed}
    QBCore.Functions.TriggerCallback('mrc-disease:cb:OnPlayerLoaded', function(diseases)
        --trigger config client event
        for k, v in pairs(diseases) do
            local configDisease = Config.Diseases[k]
            if not configDisease then return end
            local effectEvent = configDisease.effectEvent
            if not effectEvent then return end
            local data = {disease = k}
            TriggerEvent(effectEvent, data)
        end
    end, sendData)
end

-- Sets the playerdata when spawned
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    CreateThread(function()
        Wait(2000)
        LoadPlayerDiseases()
    end)
end)

AddEventHandler('onResourceStart', function(resourceName)    
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    CreateThread(function()
        Wait(1000)
        LoadPlayerDiseases()
    end)
end)



