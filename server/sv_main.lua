local QBCore = exports['qb-core']:GetCoreObject()

local LocationsWithDisease = {}
local PlayersWithDisease = {}

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

function PickADiseaseForLocation(locationIndex)
    local configLocation = Config.Locations[locationIndex]
    if not configLocation then return end
    local diseases = configLocation.possibleDiseases
    if not diseases then return end
    local randomDiseaseIndex = math.random(1, #diseases)
    local diseaseName = diseases[randomDiseaseIndex]
    if not diseaseName then return end
    return diseaseName
end

function GetLocationDisease(locationIndex)
    local locationDisease = LocationsWithDisease[locationIndex]
    if not locationDisease then
        locationDisease = PickADiseaseForLocation(locationIndex)
        LocationsWithDisease[locationIndex] = locationDisease
    end
    return locationDisease
end

function PickLocationsWithDisease()
    local locationArray = {}
    local min = Config.MinLocations
    for locationIndex, _ in pairs(Config.Locations) do
        locationArray[#locationArray + 1] = locationIndex
    end
    for i = 1, min do
        local randomIndex = math.random(1, #locationArray)
        local locationIndex = locationArray[randomIndex]
        table.remove(locationArray, randomIndex)
        GetLocationDisease(locationIndex)
        
    end
    return LocationsWithDisease
end

function SavePlayerDiseaseMeta(src, disease)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local playerMeta = Player.PlayerData.metadata['diseases'] or {}
    if not disease then return false end
    playerMeta[disease] = true
    Player.Functions.SetMetaData('diseases', playerMeta)
    Player.Functions.Save()
end

function InfectPlayerFromLocation(src, infecteePed, locationIndex )
    local disease = GetLocationDisease(locationIndex)
    if not disease then return false end    
    local playerDiseases = PlayersWithDisease[infecteePed] or {}
    local configDiseases = Config.Diseases[disease]
    if not configDiseases then return false end
    local chance = math.random() * 100 <= configDiseases.infectChance
    if not chance then return false end
    playerDiseases[disease] = true
    playerDiseases.src = src
    PlayersWithDisease[infecteePed] = playerDiseases
    SavePlayerDiseaseMeta(src, disease)
    return disease
end

function InfectPlayerFromPlayer(src, infecteePed, infectorPed)
    local infectorDiseases = PlayersWithDisease[infectorPed]
    if not infectorDiseases then return false end
    local playerDiseases = PlayersWithDisease[infecteePed] or {}
    playerDiseases.src = src
    local pickedDisease = nil
    for disease, _ in pairs(infectorDiseases) do        
        if disease ~= 'src' then 
            local configDiseases = Config.Diseases[disease]
            if configDiseases then                 
                --get random disease chance from config, if it passes, infect the player
                local chance = math.random() * 100 <= configDiseases.infectChance
                if chance then 
                    playerDiseases[disease] = true
                    SavePlayerDiseaseMeta(src, disease)
                    pickedDisease = disease
                    break
                end
            else
                --this should never happen
                print('mrc-disease: configDiseases is nil for disease: ' .. tostring(disease))                
            end
        end
    end    
    PlayersWithDisease[infecteePed] = playerDiseases
    return pickedDisease
end


--{locationIndex = locationIndex, pedNetId = pedNetId}
QBCore.Functions.CreateCallback('mrc-disease:cb:InfectPlayer', function(source, cb, data)
    local src = source

    if not data then return end
    local locationIndex = data.locationIndex
    local infecteePed = data.infecteePed
    local infectorPed = data.infectorPed
    if not infecteePed or not infectorPed then return end

    
    local disease = nil
    --we could add an item check here to see do various things
    --example would be a mask that prevents infection
    --or a vaccine that prevents infection. <--Copilot gave me this one
    
    if locationIndex then 
        if infecteePed ~= infectorPed then
            --src is probably cheating
            return
        else
            disease = InfectPlayerFromLocation(src, infecteePed, locationIndex)
        end
    else
        if infecteePed == infectorPed then
            --src is probably cheating
            return
        else
           disease = InfectPlayerFromPlayer(src, infecteePed, infectorPed)           
        end
    end
    -- if no disease was picked, player is not infected
    if not disease then return end
    -- get disease from config 
    local configDisease = Config.Diseases[disease]
    if not configDisease then return end
    -- get infect radius from config
    local infectRadius = configDisease.playerInfectionRadius
    if not infectRadius then return end
    
    TriggerClientEvent('mrc-disease:client:SetupPlayerInfectedZone', -1, {infectorPed = infecteePed, infectRadius = infectRadius})
    cb(disease)
end)

function CurePlayer(src, disease)
    if PlayersWithDisease[pedNetId] and PlayersWithDisease[pedNetId][disease] then
        PlayersWithDisease[pedNetId][disease] = nil
    end
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local playerMeta = Player.PlayerData.metadata['diseases'] or {}
    playerMeta[disease] = nil
    Player.Functions.SetMetaData('diseases', playerMeta)
    Player.Functions.Save()
end

--{disease = disease, target = 'self', pedNetId = pedNetId, item = item}
RegisterServerEvent('mrc-disease:server:AttemptToCure', function(data)
    if not data then return end
    local src = source
    local disease = data.disease
    local target = data.target
    local pedNetId = data.pedNetId
    local item = data.item
    
    if not src or not disease or not target or not pedNetId or not item then return end

    --check if player has item that can cure disease
    local configCureItem = Config.CureItems[item]
    if not configCureItem then return end
    if not configCureItem.cures[disease] then return end 
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local hasItem = Player.Functions.GetItemByName(item)
    if not hasItem then return end  

    if target == 'self' then 
        if pedNetId ~= src then
            --src is probably cheating
            return
        end
        if not Player.Functions.RemoveItem(item, 1) then return end
        CurePlayer(src, disease)
    elseif target == 'other' then
        if pedNetId == src then
            --src is probably cheating
            return
        end
        --check if player is in range of pedNetId
        local pedCoords = GetEntityCoords(NetworkGetEntityFromNetworkId(pedNetId))
        local playerCoords = GetEntityCoords(GetPlayerPed(src))
        local distance = #(pedCoords - playerCoords)
        if distance > 2.0 then return end
        if not Player.Functions.RemoveItem(item, 1) then return end
        CurePlayer(pedNetId, disease)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)    
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    CreateThread(function()
        Wait(1000)
        local locations = PickLocationsWithDisease()
        local data = {locations = locations}
        TriggerClientEvent('mrc-disease:client:SetupDiseaseLocations', -1, data)
    end)
end)

QBCore.Functions.CreateCallback('mrc-disease:cb:OnPlayerLoaded', function(source, cb, data)
    --get player diseases from metadata and add them to PlayersWithDisease
    local src = source
    if not src then return end
    local infecteePed = data.infecteePed
    if not infecteePed then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    local data = {locations = LocationsWithDisease}
    TriggerClientEvent('mrc-disease:client:SetupDiseaseLocations', src, data)

    local playerMeta = Player.PlayerData.metadata['diseases']
    if not playerMeta then return end
    local playerDiseases = {}
    for disease, _ in pairs(playerMeta) do
        local configDisease = Config.Diseases[disease]
        if configDisease then
            local infectRadius = configDisease.playerInfectionRadius
            if infectRadius then 
                playerDiseases[disease] = true
                TriggerClientEvent('mrc-disease:client:SetupPlayerInfectedZone', -1, {infectorPed = infecteePed, infectRadius = infectRadius})
            end
        end
    end
    PlayersWithDisease[infecteePed] = playerDiseases
    cb(playerDiseases)
end)