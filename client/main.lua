local isAdminPanelOpen = false

function toggleAdminPanel()
    isAdminPanelOpen = not isAdminPanelOpen
    SetNuiFocus(isAdminPanelOpen, isAdminPanelOpen)
    SendNUIMessage({
        type = "ui",
        status = isAdminPanelOpen
    })
    if isAdminPanelOpen then
        TriggerServerEvent("devolutions:start")
    end
end

RegisterCommand("storepanel", function()
    toggleAdminPanel()
end, false)

RegisterNUICallback("closePanel", function(data, cb)
    if isAdminPanelOpen then
        isAdminPanelOpen = false
        SetNuiFocus(false, false)
        SendNUIMessage({ type = "ui", status = false })
    end
    cb("ok")
end)

RegisterNUICallback("returnItem", function(data, cb)
    TriggerServerEvent("admin:returnItem", data)
    cb("ok")
end)

RegisterNUICallback("addItem", function(data, cb)
    TriggerServerEvent("admin:addItem", data)
    cb("ok")
end)

RegisterNUICallback("searchOfflinePlayer", function(data, cb)
    TriggerServerEvent("admin:searchOfflinePlayer", data)
    cb("ok")
end)

RegisterNUICallback("getOfflineItems", function(data, cb)
    TriggerServerEvent("admin:getOfflineItems", data)
    cb("ok")
end)

RegisterNUICallback("getProducts", function(data, cb)
    TriggerServerEvent("admin:getProducts")
    cb("ok")
end)

RegisterNetEvent("admin:searchResult")
AddEventHandler("admin:searchResult", function(result)
    SendNUIMessage({
        type = "searchResult",
        data = result
    })
end)

RegisterNetEvent("admin:offlineItemsResult")
AddEventHandler("admin:offlineItemsResult", function(items)
    SendNUIMessage({
        type = "offlineItems",
        items = items
    })
end)

RegisterNetEvent("admin:updatePlayers")
AddEventHandler("admin:updatePlayers", function(players)
    SendNUIMessage({
        type = "playersData",
        players = players
    })
end)

RegisterNetEvent("admin:itemAdded")
AddEventHandler("admin:itemAdded", function(data)
    SendNUIMessage({
        type = "itemAdded",
        data = data
    })
end)

RegisterNetEvent("admin:productsResult")
AddEventHandler("admin:productsResult", function(products)
    SendNUIMessage({
        type = "productsData",
        products = products
    })
end)

RegisterNUICallback("getPCoins", function(data, cb)
    TriggerServerEvent("admin:getPCoins", data)
    cb("ok")
end)

RegisterNUICallback("managePCoins", function(data, cb)
    TriggerServerEvent("admin:managePCoins", data)
    cb("ok")
end)

RegisterNUICallback("deleteItem", function(data, cb)
    TriggerServerEvent("admin:deleteItem", data)
    cb("ok")
end)

RegisterNetEvent("admin:pCoinsResult")
AddEventHandler("admin:pCoinsResult", function(data)
    SendNUIMessage({
        type = "pCoinsData",
        pCoins = data.pCoins
    })
end)

RegisterNetEvent("admin:pCoinsUpdated")
AddEventHandler("admin:pCoinsUpdated", function(data)
    SendNUIMessage({
        type = "pCoinsUpdated",
        success = data.success,
        newBalance = data.newBalance
    })
end)

RegisterNetEvent("admin:itemDeleted")
AddEventHandler("admin:itemDeleted", function(data)
    SendNUIMessage({
        type = "itemDeleted",
        success = data.success
    })
end)

RegisterNUICallback("createProduct", function(data, cb)
    TriggerServerEvent("admin:createProduct", data)
    cb("ok")
end)

RegisterNetEvent("admin:productCreated")
AddEventHandler("admin:productCreated", function(data)
    SendNUIMessage({
        type = "productCreated",
        success = data.success,
        message = data.message,
        id = data.id
    })
end)
