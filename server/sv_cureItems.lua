local QBCore = exports['qb-core']:GetCoreObject()


CreateThread(function()
    local CureItems = Config.CureItems
    if not CureItems then return end

    for itemName, v in pairs(CureItems) do
        QBCore.Functions.CreateUseableItem(itemName , function(source, item)
            local Player = QBCore.Functions.GetPlayer(source)
            if not Player then return end
            if not Player.Functions.GetItemByName(itemName) then return end
            TriggerClientEvent('mrc-disease:client:AttemptToCure', source, {item = itemName})
        end)
    end
end)


