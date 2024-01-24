local QBCore = exports['qb-core']:GetCoreObject()



function PlayerHasDisease(src, disease)
    local Player = QBCore.Functions.GetPlayer(source)
    if not Player then return false end
    local PlayerData = Player.PlayerData
    if not PlayerData then return false end
    local diseases = PlayerData.metadata['diseases']
    if not diseases then return false end
    local disease = diseases[disease]
    if not disease then return false end
    return Player
end

RegisterNetEvent('mrc-disease:server:PlatypusParasiteEffect', function()
    local src = source
    if not src then return end

    local disease = 'platypus_parasite'
    local Player = PlayerHasDisease(src, disease)
    if not Player then return end
    --drain hunger and thirst
    local PlayerData = Player.PlayerData
    local hunger = PlayerData.metadata['hunger']
    local thirst = PlayerData.metadata['thirst']
    local newHunger = hunger - 10
    local newThirst = thirst - 10
    if newHunger < 0 then newHunger = 0 end
    if newThirst < 0 then newThirst = 0 end
    Player.Functions.SetMetaData('hunger', newHunger)
    Player.Functions.SetMetaData('thirst', newThirst)
    TriggerClientEvent('hud:client:UpdateNeeds', src, newHunger, newThirst)
    local PlayerPed = GetPlayerPed(src)
    local netId = NetworkGetNetworkIdFromEntity(PlayerPed)
    local coords = GetEntityCoords(PlayerPed)
    local heading = GetEntityHeading(PlayerPed)
    local dict = 'missfam5_blackout'
    local anim = 'vomit'
    
    TriggerClientEvent('mrc-disease:client:PlatypusParasiteEffectCB', -1, {infecteePed = netId})
    TaskPlayAnimAdvanced(PlayerPed, dict, anim, coords.x, coords.y, coords.z, 0.0, 0.0, heading, 8.0, 8.0, 6000, 31, 0.4, 0, 0)

end)


RegisterNetEvent('mrc-disease:server:FoulFungusEffect', function(data)
    if not data then return end 
    local infecteePed = data.infecteePed
    if not infecteePed then return end
    local src = source
    if not src then return end
    local disease = 'foul_fungus'
    local Player = PlayerHasDisease(src, disease)
    if not Player then return end


    --update entity polyzone for new player ped
    local configDisease = Config.Diseases[disease]
    if not configDisease then return end
    local infectRadius = configDisease.playerInfectionRadius
    if not infectRadius then return end
    TriggerClientEvent('mrc-disease:client:SetupPlayerInfectedZone', -1, {infectorPed = infecteePed, infectRadius = infectRadius, rebuild = true})

end)