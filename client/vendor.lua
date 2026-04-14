local RSGCore = exports['rsg-core']:GetCoreObject()
local vendorPeds = {}

CreateThread(function()
    for _, vendor in ipairs(Config.Vendors) do
        local model = GetHashKey(vendor.pedModel)
        RequestModel(model)
        while not HasModelLoaded(model) do
            Wait(10)
        end

        local ped = CreatePed(model, vendor.coords.x, vendor.coords.y, vendor.coords.z - 1.0, vendor.coords.w, false, false)
        SetRandomOutfitVariation(ped, true)
        SetEntityAsMissionEntity(ped, true, true)
        SetBlockingOfNonTemporaryEvents(ped, true)
        FreezeEntityPosition(ped, true)
        TaskStandStill(ped, -1)

        vendorPeds[#vendorPeds + 1] = ped

        exports.ox_target:addLocalEntity(ped, {
            {
                name = 'vendor_shop',
                label = 'Open Shop',
                icon = 'fa-solid fa-store',
                distance = 2.0,
                onSelect = function()
                    OpenVendorMenu(vendor.items)
                end
            },
            {
                name = 'vendor_sell',
                label = 'Sell Items',
                icon = 'fa-solid fa-hand-holding-dollar',
                distance = 2.0,
                onSelect = function()
                    OpenSellMenu(vendor.items)
                end
            }
        })
    end
end)

function OpenVendorMenu(vendorItems)
    local stockData = lib.callback.await('rex-hunting:server:getStock', false)
    local options = {}

    for _, item in ipairs(vendorItems) do
        if item.canBuy then
            local stock = stockData[item.name] or 0
            table.insert(options, {
                title = item.label,
                description = string.format('Price: $%d | Stock: %d', item.buyPrice, stock),
                icon = "nui://"..Config.Image..item.name..".png" or 'box',
                disabled = stock <= 0,
                onSelect = function()
                    local input = lib.inputDialog('Buy ' .. item.label, {
                        { type = 'number', label = 'Amount', default = 1, min = 1, max = stock }
                    })
                    if input then
                        TriggerServerEvent('rex-hunting:server:buyItem', item.name, input[1])
                    end
                end
            })
        end
    end

    lib.registerContext({
        id = 'vendor_shop_menu',
        title = 'Vendor Shop',
        options = options
    })
    lib.showContext('vendor_shop_menu')
end

function OpenSellMenu(vendorItems)
    local PlayerData = RSGCore.Functions.GetPlayerData()
    local inventory = PlayerData.items or {}
    local options = {}

    for _, invItem in ipairs(inventory) do
        if invItem then
            for _, vendorItem in ipairs(vendorItems) do
                if vendorItem.name == invItem.name and vendorItem.canSell then
                    table.insert(options, {
                        title = invItem.label,
                        description = string.format('Sell Price: $%d | You have: %d', vendorItem.sellPrice, invItem.amount),
                        icon = "nui://"..Config.Image..invItem.image or 'box',
                        onSelect = function()
                            local input = lib.inputDialog('Sell ' .. invItem.label, {
                                { type = 'number', label = 'Amount', default = 1, min = 1, max = invItem.amount }
                            })
                            if input then
                                TriggerServerEvent('rex-hunting:server:sellItem', invItem.name, input[1])
                            end
                        end
                    })
                    break
                end
            end
        end
    end

    if #options == 0 then
        lib.notify({ title = 'Vendor', description = 'No items to sell', type = 'inform' })
        return
    end

    lib.registerContext({
        id = 'vendor_sell_menu',
        title = 'Sell Items',
        options = options
    })
    lib.showContext('vendor_sell_menu')
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for _, ped in ipairs(vendorPeds) do
            DeleteEntity(ped)
        end
    end
end)
