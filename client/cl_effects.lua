local QBCore = exports['qb-core']:GetCoreObject()

function VerifyEventAndGetConfig(eventName, disease)
    local configDisease = Config.Diseases[disease]
    if not configDisease then return false end
    local effectEvent = configDisease.effectEvent
    if not effectEvent then return false end
    if effectEvent ~= eventName then return false end
    return configDisease
end

function PlayerHasDisease(disease)
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return false end
    local diseases = PlayerData.metadata['diseases']
    if not diseases then return false end
    local disease = diseases[disease]
    if not disease then return false end
    return true
end

local EffectLoopRunning = {}

--  drains hunger and thirst
RegisterNetEvent('mrc-disease:client:PlatypusParasiteEffect', function(data)
    if not data then return end

    local diseaseArg = data.disease
    if not diseaseArg then return end

    local configDisease = VerifyEventAndGetConfig('mrc-disease:client:PlatypusParasiteEffect', diseaseArg) --Verify the event is the correct one
    if not configDisease then return end 
    
    local initialDelay = configDisease.initialDelay
    if not initialDelay then return end

    local delay = configDisease.delay
    if not delay then return end

    if EffectLoopRunning[diseaseArg] then return end
    EffectLoopRunning[diseaseArg] = true

    local effectChance = configDisease.effectChance
    if not effectChance then return end

    CreateThread(function()
        Wait(initialDelay)
        --AnimpostfxPlay('DrugsMichaelAliensFightIn', 0, false)
        --ShakeGameplayCam('FAMILY5_DRUG_TRIP_SHAKE', 0.75)
       
        
        local ped = GetPlayerPed(-1)
        while PlayerHasDisease(diseaseArg) do
            ped = GetPlayerPed(-1)
            local chance = math.random()*100
            if chance <= effectChance then
                --TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
                
                TriggerServerEvent('mrc-disease:server:PlatypusParasiteEffect')
                Wait(3000)
                RemoveParticleFxFromEntity(ped)
            end
            Wait(delay)
        end
        StopGameplayCamShaking(true)
        ClearPedSecondaryTask(ped)
        EffectLoopRunning[diseaseArg] = false
    end)
end)

RegisterNetEvent ('mrc-disease:client:PlatypusParasiteEffectCB', function(data)
    if not data then return end
    local netId = data.infecteePed
    if not netId then return end
    local ped = NetToPed(netId)
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)
    local dict = 'missfam5_blackout'
    local anim = 'vomit'
    RequestAnimDict(dict)
    while not HasAnimDictLoaded(dict) do
        Citizen.Wait(100)
    end

    local pftxDict = 'scr_familyscenem'
    local ptfx = 'scr_trev_amb_puke'
    RequestNamedPtfxAsset(pftxDict)
    while not HasNamedPtfxAssetLoaded(pftxDict) do
        Citizen.Wait(100)
    end
    UseParticleFxAssetNextCall(pftxDict)
    local ptfxHandle = StartParticleFxLoopedOnEntity(ptfx, ped, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
end)

-- Turns the player into a chicken. Plays a smoke particle effect and a chicken sound while not allowing the player to move.
RegisterNetEvent('mrc-disease:client:FoulFungusEffect', function(data)
    if not data then return end

    local diseaseArg = data.disease
    if not diseaseArg then return end

    local configDisease = VerifyEventAndGetConfig('mrc-disease:client:FoulFungusEffect', diseaseArg) --Verify the event is the correct one
    if not configDisease then return end 
    
    local initialDelay = configDisease.initialDelay
    if not initialDelay then return end

    local delay = configDisease.delay
    if not delay then return end

    if EffectLoopRunning[diseaseArg] then return end
    EffectLoopRunning[diseaseArg] = true

    local effectChance = configDisease.effectChance
    if not effectChance then return end

    CreateThread(function()
        Wait(initialDelay)
        --AnimpostfxPlay('DrugsMichaelAliensFightIn', 0, false)
        --ShakeGameplayCam('FAMILY5_DRUG_TRIP_SHAKE', 0.75)
        local dict = 'missfam5_blackout'
        local anim = 'vomit'
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do
            Citizen.Wait(100)
        end

        local pftxDict = 'scr_familyscenem'
        local ptfx = 'scr_trev_amb_puke'
        local model = GetHashKey('a_c_hen')
        RequestNamedPtfxAsset(pftxDict)
        while not HasNamedPtfxAssetLoaded(pftxDict) do
            Citizen.Wait(100)
        end
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(0)
        end
        
        local ped = GetPlayerPed(-1)
        local PlayerData = QBCore.Functions.GetPlayerData()
      
        local dead = false
        while PlayerHasDisease(diseaseArg) do
            local chance = math.random()*100
            if chance <= effectChance  and not dead then
                --TaskPlayAnim(ped, dict, anim, 8.0, 8.0, -1, 0, 0, false, false, false)
                local coords = GetEntityCoords(ped)
                local heading = GetEntityHeading(ped)
                
                local PlayerData = QBCore.Functions.GetPlayerData()
                if not PlayerData then return end
                local metaData = PlayerData.metadata
                if not metaData then return end
                local lastStand = metaData["laststand"]
                if not dead then 
                    if not IsEntityDead(ped) and not lastStand and not IsPedInAnyVehicle(ped, true) then 
                        UseParticleFxAssetNextCall(pftxDict)
                        local ptfxHandle = StartParticleFxLoopedOnEntity(ptfx, GetPlayerPed(-1), 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, false, false, false)
                        local previousModel = GetEntityModel(ped)
                        local health = GetEntityHealth(ped)
                        SetPlayerModel(PlayerId(), model)
                        Wait(1000)
                        ped = GetPlayerPed(-1)
                        local pedNetId = PedToNet(ped)
                        TriggerServerEvent('mrc-disease:server:FoulFungusEffect',{infecteePed = pedNetId})
                        Wait(6000)
                        SetEntityAsNoLongerNeeded(ped)
                        TriggerServerEvent('qb-clothes:loadPlayerSkin')
                        Wait(2000)
                        ped = GetPlayerPed(-1)
                        local pedNetId = PedToNet(ped)                        
                        TriggerServerEvent('mrc-disease:server:FoulFungusEffect',{infecteePed = pedNetId})
                        RemoveParticleFxFromEntity(ped)
                        SetEntityHealth(ped, health)
                        SetPlayerHealthRechargeMultiplier(PlayerId(), 0.001)
                        if health < 151 then 
                            dead = true
                        end
                        
                    end
                else
                    ped = GetPlayerPed(-1)
                    local health = GetEntityHealth(ped)
                    if health > 150 then 
                        dead = false
                    end
                end
            end
            Wait(delay)
        end
        StopGameplayCamShaking(true)
        ClearPedSecondaryTask(ped)
        EffectLoopRunning[diseaseArg] = false
    end)
end)

CreateThread(function()
    while true do 
        local playerped = GetPlayerPed(-1)
        local health = GetEntityHealth(playerped)
        Wait(0)
    end

end)

