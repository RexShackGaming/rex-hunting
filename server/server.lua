local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------------
-- give rewards
------------------------------------------
RegisterNetEvent('rex-hunting:server:giverewards', function(rewards)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player or type(rewards) ~= "table" then return end

    for _, itemName in ipairs(rewards) do
        if itemName and RSGCore.Shared.Items[itemName] then
            Player.Functions.AddItem(itemName, 1)
            TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', 1)
        end
    end
end)
