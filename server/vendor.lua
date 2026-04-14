local RSGCore = exports['rsg-core']:GetCoreObject()
local stockFile = 'vendor_stock.json'
local stockData = {}

local function LoadStock()
    local file = LoadResourceFile(GetCurrentResourceName(), stockFile)
    if file then
        stockData = json.decode(file) or {}
    else
        stockData = {}
        for _, vendor in ipairs(Config.Vendors) do
            for _, item in ipairs(vendor.items) do
                if item.canBuy then
                    stockData[item.name] = item.initialStock or 10
                end
            end
        end
        SaveResourceFile(GetCurrentResourceName(), stockFile, json.encode(stockData), -1)
    end
end

local function SaveStock()
    SaveResourceFile(GetCurrentResourceName(), stockFile, json.encode(stockData), -1)
end

CreateThread(function()
    Wait(1000)
    LoadStock()
end)

lib.callback.register('rex-hunting:server:getStock', function()
    return stockData
end)

RegisterNetEvent('rex-hunting:server:buyItem', function(itemName, amount)
    local src = source
    if type(itemName) ~= 'string' or type(amount) ~= 'number' or amount <= 0 then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemConfig
    for _, vendor in ipairs(Config.Vendors) do
        for _, item in ipairs(vendor.items) do
            if item.name == itemName and item.canBuy then
                itemConfig = item
                break
            end
        end
    end

    if not itemConfig then return end

    local currentStock = stockData[itemName] or 0
    if currentStock < amount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Vendor', description = 'Not enough stock', type = 'error' })
        return
    end

    local totalPrice = itemConfig.buyPrice * amount
    local cash = Player.Functions.GetMoney('cash')

    if cash < totalPrice then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Vendor', description = 'Not enough cash', type = 'error' })
        return
    end

    Player.Functions.RemoveMoney('cash', totalPrice, 'vendor-purchase')
    Player.Functions.AddItem(itemName, amount)
    stockData[itemName] = currentStock - amount
    SaveStock()

    TriggerClientEvent('ox_lib:notify', src, { title = 'Vendor', description = string.format('Bought %dx %s for $%d', amount, itemConfig.label, totalPrice), type = 'success' })
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add', amount)
end)

RegisterNetEvent('rex-hunting:server:sellItem', function(itemName, amount)
    local src = source
    if type(itemName) ~= 'string' or type(amount) ~= 'number' or amount <= 0 then return end

    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local itemConfig
    for _, vendor in ipairs(Config.Vendors) do
        for _, item in ipairs(vendor.items) do
            if item.name == itemName and item.canSell then
                itemConfig = item
                break
            end
        end
    end

    if not itemConfig then return end

    local playerItem = Player.Functions.GetItemByName(itemName)
    if not playerItem or playerItem.amount < amount then
        TriggerClientEvent('ox_lib:notify', src, { title = 'Vendor', description = 'Not enough items', type = 'error' })
        return
    end

    local currentStock = stockData[itemName] or 0
    local dynamicPrice = itemConfig.sellPrice

    -- Increase sell price when stock is low (vendor pays more for items they need)
    if itemConfig.stockBasedPrice then
        local stockRatio = currentStock / (itemConfig.maxStock or 50)
        if stockRatio < 0.25 then
            dynamicPrice = math.floor(dynamicPrice * 1.5)
        elseif stockRatio < 0.5 then
            dynamicPrice = math.floor(dynamicPrice * 1.25)
        end
    end

    local totalPrice = dynamicPrice * amount

    Player.Functions.RemoveItem(itemName, amount)
    Player.Functions.AddMoney('cash', totalPrice, 'vendor-sale')
    stockData[itemName] = currentStock + amount
    SaveStock()

    TriggerClientEvent('ox_lib:notify', src, { title = 'Vendor', description = string.format('Sold %dx %s for $%d', amount, itemConfig.label, totalPrice), type = 'success' })
    TriggerClientEvent('rsg-inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'remove', amount)
end)

RegisterCommand('resetvendorstock', function(source)
    if source ~= 0 then return end

    for _, vendor in ipairs(Config.Vendors) do
        for _, item in ipairs(vendor.items) do
            if item.canBuy then
                stockData[item.name] = item.initialStock or 10
            end
        end
    end
    SaveStock()
    print('[rex-hunting] Vendor stock reset to initial values')
end, false)
