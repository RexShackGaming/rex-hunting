local RSGCore = exports['rsg-core']:GetCoreObject()

------------------------------------
-- skinning workings and reward
------------------------------------
CreateThread(function()
    while true do
        Wait(2)
        local size = GetNumberOfEvents(0)
        if size > 0 then
            for index = 0, size - 1 do
                local event = GetEventAtIndex(0, index)
                if event == 1376140891 then
                    local view = exports['rex-hunting']:DataViewNativeGetEventData(0, index, 3)
                    local pedGathered = view['2']
                    local ped = view['0']
                    local model = GetEntityModel(pedGathered)
                    -- bool to let you know if animation/longpress was enacted.
                    local bool_unk = view['4']
                    -- ensure the player who enacted the event is the one who gets the rewards
                    local playerPed = PlayerPedId()
                    local playergate = playerPed == ped
                    -- process animal
                    for i = 1, #Config.Animals do
                        if model and Config.Animals ~= nil and playergate and bool_unk == 1 then
                            local chosenmodel = Config.Animals[i].modelhash
                            if model == chosenmodel then
                                local rewarditem1 = Config.Animals[i].rewarditem1
                                local rewarditem2 = Config.Animals[i].rewarditem2
                                local rewarditem3 = Config.Animals[i].rewarditem3
                                local rewarditem4 = Config.Animals[i].rewarditem4
                                local rewarditem5 = Config.Animals[i].rewarditem5
                                Wait(1000)
                                local holding = Citizen.InvokeNative(0xD806CD2A4F2C2996, cache.ped)
                                if holding then
                                    DeleteEntity(holding)
                                end
                                TriggerServerEvent('rex-hunting:server:giverewards', {
                                    rewarditem1,
                                    rewarditem2,
                                    rewarditem3,
                                    rewarditem4,
                                    rewarditem5
                                })
                                Wait(1000)
                                if Config.Animals[i].skinable and Config.DeleteCarcass then
                                    DeletePed(pedGathered)
                                end
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)
