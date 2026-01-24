local sendAddItemWebhook = "https://discord.com/api/webhooks/your_webhook_url"
local returnItemWebhook = "https://discord.com/api/webhooks/your_webhook_url"
local coinsAddWebhook = "https://discord.com/api/webhooks/your_webhook_url"
local coinsRemoveWebhook = "https://discord.com/api/webhooks/your_webhook_url"
local deleteItemWebhook = "https://discord.com/api/webhooks/your_webhook_url"

local ESX = nil
local QBCore = nil
local ESXVer = Config.ESXVer
local FrameWork = nil

if Config.FrameWork == "auto" then
    if GetResourceState('es_extended') == 'started' then
        if ESXVer == 'new' then
            ESX = exports['es_extended']:getSharedObject()
            FrameWork = 'esx'
        else
            ESX = nil
            while ESX == nil do
                TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
                Citizen.Wait(0)
            end
        end
    elseif GetResourceState('qb-core') == 'started' then
        QBCore = exports['qb-core']:GetCoreObject()
        FrameWork = 'qb'
    else
        print("[INIT] ===NO SUPPORTED FRAMEWORK FOUND===")
    end
elseif Config.FrameWork == "esx" and GetResourceState('es_extended') == 'started' then
    if ESXVer == 'new' then
        ESX = exports['es_extended']:getSharedObject()
        FrameWork = 'esx'
    else
        ESX = nil
        while ESX == nil do
            TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
            Citizen.Wait(0)
        end
    end
elseif Config.FrameWork == "qb" and GetResourceState('qb-core') == 'started' then
    QBCore = exports['qb-core']:GetCoreObject()
    FrameWork = 'qb'
else
    print("[INIT] ===NO SUPPORTED FRAMEWORK FOUND===")
end

function GetPlayerItems(discordId, cb)
    if Config.StandaloneMode then
        local query = [[
            SELECT
                p.id,
                p.title,
                p.description,
                p.image,
                p.category,
                p.model,
                p.type,
                p.icon,
                up.quantity as amount
            FROM devolutions_user_purchases up
            JOIN devolutions_products p ON up.product_id = p.id
            WHERE up.discord_id = ?
        ]]

        exports.oxmysql:fetch(query, { discordId }, function(result)
            local items = {}
            if result then
                for _, item in ipairs(result) do
                    table.insert(items, {
                        id = item.id,
                        name = item.title,
                        type = item.type or "Item",
                        icon = item.icon or "fas fa-box",
                        category = item.category or "default",
                        model = item.model or "",
                        description = item.description or "",
                        image = item.image or "",
                        amount = item.amount or 1
                    })
                end
            end
            cb(items)
        end)
    else
        exports.oxmysql:fetch("SELECT purchases FROM pts_users WHERE discord_id = ?", { discordId }, function(result)
            local items = {}

            if not result or not result[1] or not result[1].purchases then
                cb(items)
                return
            end

            local success, purchases = pcall(function() return json.decode(result[1].purchases) end)
            if not success or type(purchases) ~= "table" then
                cb(items)
                return
            end

            local productIds = {}
            for k, _ in pairs(purchases) do table.insert(productIds, k) end
            if #productIds == 0 then
                cb(items)
                return
            end

            local quotedIds = {}
            for _, id in ipairs(productIds) do
                table.insert(quotedIds, "'" .. id .. "'")
            end
            local placeholders = table.concat(quotedIds, ",")

            exports.oxmysql:fetch("SELECT * FROM pts_products WHERE id IN (" .. placeholders .. ")", {},
                function(products)
                    if products then
                        for _, product in ipairs(products) do
                            local quantity = purchases[tostring(product.id)] or 1
                            local categoryConfig = Config.Categories[product.category] or Config.Categories["default"]
                            local productType = categoryConfig.type
                            local productIcon = categoryConfig.icon
                            local productModel = ""

                            if product.commands then
                                local _, cmdModel = product.commands:match("pts_(%w+)%s+(.+)")
                                if cmdModel then
                                    productModel = cmdModel:gsub('^"', ''):gsub('"%]$', '')
                                end
                            end

                            table.insert(items, {
                                id = product.id,
                                name = product.title,
                                type = productType,
                                icon = productIcon,
                                category = categoryConfig.label,
                                model = productModel,
                                description = product.description,
                                image = product.image,
                                amount = quantity
                            })
                        end
                    end

                    cb(items)
                end)
        end)
    end
end

-- function GetPlayerItems(playerIdentifier, cb)
--     exports.oxmysql:fetch("SELECT * FROM muhaddil_devolutions WHERE player_identifier = ?", { playerIdentifier },
--         function(result)
--             local items = {}
--             if result then
--                 for _, v in ipairs(result) do
--                     table.insert(items, {
--                         id = v.item_id,
--                         name = v.title,
--                         type = v.type,
--                         model = v.model,
--                         description = v.description,
--                         image = v.image,
--                         amount = v.amount,
--                         date = v.date
--                     })
--                 end
--             end
--             cb(items)
--         end)
-- end

exports('GetPlayerItems', GetPlayerItems)

function AddPlayerItem(playerIdentifier, itemData, discordId, src)
    playerIdentifier = playerIdentifier or 'a'

    if Config.StandaloneMode then
        exports.oxmysql:fetch("SELECT * FROM devolutions_user_purchases WHERE discord_id = ? AND product_id = ?",
            { discordId, itemData.itemId },
            function(result)
                if result and result[1] then
                    local newQuantity = result[1].quantity + (itemData.amount or 1)
                    exports.oxmysql:execute("UPDATE devolutions_user_purchases SET quantity = ? WHERE id = ?",
                        { newQuantity, result[1].id },
                        function()
                            sendAddItemWebhook(src, playerIdentifier, discordId, itemData)
                        end
                    )
                else
                    exports.oxmysql:execute(
                        "INSERT INTO devolutions_user_purchases (identifier, discord_id, product_id, quantity) VALUES (?, ?, ?, ?)",
                        { playerIdentifier, discordId, itemData.itemId, itemData.amount or 1 },
                        function()
                            sendAddItemWebhook(src, playerIdentifier, discordId, itemData)
                        end
                    )
                end
            end
        )
    else
        -- Modo pickle-store (código original)
        exports.oxmysql:fetch("SELECT purchases FROM pts_users WHERE discord_id = ?", { discordId }, function(result)
            local purchases = {}

            if result and result[1] and result[1].purchases then
                local success, decoded = pcall(function() return json.decode(result[1].purchases) end)
                if success and type(decoded) == "table" then
                    purchases = decoded
                else
                    print("[AddPlayerItem] Error al decodificar purchases JSON")
                end
            else
                print("[AddPlayerItem] No se encontraron purchases previos para este jugador")
            end

            local currentAmount = purchases[tostring(itemData.itemId)] or 0
            purchases[tostring(itemData.itemId)] = currentAmount + (itemData.amount or 1)

            local jsonPurchases = json.encode(purchases)

            exports.oxmysql:execute("UPDATE pts_users SET purchases = ? WHERE discord_id = ?",
                { jsonPurchases, discordId },
                function()
                    sendAddItemWebhook(src, playerIdentifier, discordId, itemData)
                end
            )
        end)
    end
end

function sendAddItemWebhook(src, playerIdentifier, discordId, itemData)
    local adminDiscord = src and GetDiscordId(src) or "SYSTEM"
    local adminId = src or "SYSTEM"

    local embed = {
        {
            color = 15158332,
            title = "➕ Producto Añadido",
            description = "Un administrador ha añadido un producto a un jugador.",
            fields = {
                {
                    name = "👮 Admin",
                    value = string.format("**ID:** %s\n**Discord:** <@%s>", adminId, adminDiscord),
                    inline = true
                },
                {
                    name = "🎯 Jugador",
                    value = string.format("**Identificador:** %s\n**Discord:** <@%s>", playerIdentifier, discordId),
                    inline = true
                },
                {
                    name = "📦 Item",
                    value = string.format("**Nombre:** %s\n**Tipo:** %s\n**Modelo:** %s\n**Cantidad:** %s",
                        itemData.title or "N/A", itemData.type or "N/A", itemData.model or "N/A", itemData.amount or 1),
                    inline = false
                },
            },
            footer = {
                text = os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(sendAddItemWebhook, function() end, "POST", json.encode({ embeds = embed }),
        { ["Content-Type"] = "application/json" })
end

exports('AddPlayerItem', AddPlayerItem)

function GetAllPlayersWithItems(callback)
    local players = {}
    local totalPlayers = #GetPlayers()

    if totalPlayers == 0 then
        callback(players)
        return
    end

    local processed = 0

    for _, playerId in ipairs(GetPlayers()) do
        local license2 = GetIdentifier(playerId)
        local discordId = "Desconocido"

        for _, id in ipairs(GetPlayerIdentifiers(playerId)) do
            if string.find(id, "discord:") then
                discordId = string.gsub(id, "discord:", "")
            end
        end

        if license2 then
            exports.oxmysql:fetch("SELECT firstname, lastname FROM users WHERE identifier = ?", { license2 },
                function(userResult)
                    local username = "Desconocido"
                    if userResult[1] then
                        username = (userResult[1].firstname or "") .. " " .. (userResult[1].lastname or "")
                    end

                    GetPlayerItems(discordId, function(items)
                        table.insert(players, {
                            id = playerId,
                            name = username,
                            license = license2,
                            discord = discordId,
                            items = items
                        })

                        processed = processed + 1
                        if processed >= totalPlayers then
                            callback(players)
                        end
                    end)
                end)
        else
            table.insert(players, {
                id = playerId,
                name = "Desconocido",
                license = "Desconocido",
                discord = discordId,
                items = {}
            })

            processed = processed + 1
            if processed >= totalPlayers then
                callback(players)
            end
        end
    end
end

RegisterServerEvent("admin:getProducts")
AddEventHandler("admin:getProducts", function(src)
    local query = Config.StandaloneMode and "SELECT * FROM devolutions_products" or "SELECT * FROM pts_products"

    exports.oxmysql:fetch(query, {}, function(result)
        local products = {}
        if result then
            for _, product in ipairs(result) do
                if Config.StandaloneMode then
                    table.insert(products, {
                        id = product.id,
                        title = product.title,
                        description = product.description,
                        image = product.image,
                        type = product.type or "Item",
                        icon = product.icon or "fas fa-box",
                        model = product.model or "",
                        category = product.category or "default"
                    })
                else
                    local categoryConfig = Config.Categories[product.category] or Config.Categories["default"]
                    local productType = categoryConfig.type
                    local productIcon = categoryConfig.icon
                    local productModel = ""

                    if product.commands then
                        local _, cmdModel = product.commands:match("pts_(%w+)%s+(.+)")
                        if cmdModel then
                            productModel = cmdModel:gsub('^"', ''):gsub('"%]$', '')
                        end
                    end

                    table.insert(products, {
                        id = product.id,
                        title = product.title,
                        description = product.description,
                        image = product.image,
                        type = productType,
                        icon = productIcon,
                        model = productModel,
                        category = categoryConfig.label
                    })
                end
            end
        end

        TriggerClientEvent("admin:productsResult", src, products)
    end)
end)

RegisterServerEvent("admin:getPlayers")
AddEventHandler("admin:getPlayers", function(src)
    GetAllPlayersWithItems(function(players)
        TriggerClientEvent("admin:updatePlayers", src, players)
    end)
end)

RegisterServerEvent("admin:searchOfflinePlayer")
AddEventHandler("admin:searchOfflinePlayer", function(data, clientCallback)
    local src = source
    local discordId = data.discordId

    if not discordId or discordId == "" then
        TriggerClientEvent("admin:searchResult", src, { success = false, characters = {} })
        return
    end

    exports.oxmysql:fetch("SELECT license FROM user_identifiers WHERE discord = ?", { discordId },
        function(result)
            if not result or not result[1] then
                TriggerClientEvent("admin:searchResult", src, { success = false, characters = {} })
                return
            end

            local baseLicense = result[1].license:gsub("license:", "")

            exports.oxmysql:fetch(
                "SELECT identifier, firstname, lastname FROM users WHERE identifier LIKE ?",
                { "char%" .. baseLicense },
                function(characters)
                    if not characters or #characters == 0 then
                        TriggerClientEvent("admin:searchResult", src, { success = false, characters = {} })
                        return
                    end

                    local charactersWithItems = {}
                    local processed = 0

                    for _, char in ipairs(characters) do
                        GetPlayerItems(discordId, function(items)
                            local slotNumber = char.identifier:match("^char(%d+):")
                            local slotLabel = "Personaje"

                            if slotNumber then
                                slotLabel = "Personaje " .. slotNumber
                            end

                            table.insert(charactersWithItems, {
                                identifier = char.identifier,
                                slotLabel = slotLabel,
                                firstname = char.firstname or "Desconocido",
                                lastname = char.lastname or "",
                                items = items,
                                discord = discordId
                            })

                            processed = processed + 1
                            if processed == #characters then
                                TriggerClientEvent("admin:searchResult", src,
                                    { success = true, characters = charactersWithItems })
                            end
                        end)
                    end
                end)
        end)
end)

RegisterServerEvent("admin:getOfflineItems")
AddEventHandler("admin:getOfflineItems", function(data)
    local src = source
    local discordId = data.discordId

    if not discordId then
        TriggerClientEvent("admin:offlineItemsResult", src, {})
        return
    end

    GetPlayerItems(discordId, function(items)
        TriggerClientEvent("admin:offlineItemsResult", src, items)
    end)
end)

RegisterServerEvent("admin:addItem")
AddEventHandler("admin:addItem", function(data)
    local src = source
    local playerIdentifier = data.playerIdentifier

    if not playerIdentifier then
        TriggerClientEvent("admin:itemAdded", src, { success = false })
        return
    end

    AddPlayerItem(playerIdentifier, {
        itemId = data.itemId,
        title = data.title,
        type = data.type,
        model = data.model,
        description = data.description,
        image = data.image,
        amount = data.amount
    }, data.discordId, src)

    Citizen.Wait(200)

    TriggerClientEvent("admin:itemAdded", src, { success = true, identifier = playerIdentifier })

    GetAllPlayersWithItems(function(players)
        TriggerClientEvent("admin:updatePlayers", src, players)
    end)
end)

local NumberCharset = {}
local Charset = {}

for i = 48, 57 do table.insert(NumberCharset, string.char(i)) end
for i = 65, 90 do table.insert(Charset, string.char(i)) end
for i = 97, 122 do table.insert(Charset, string.char(i)) end

function GetRandomNumber(length)
    Citizen.Wait(0)
    math.randomseed(GetGameTimer())
    if length > 0 then
        return GetRandomNumber(length - 1) .. NumberCharset[math.random(1, #NumberCharset)]
    else
        return ''
    end
end

function GetRandomLetter(length)
    Citizen.Wait(0)
    math.randomseed(GetGameTimer())
    if length > 0 then
        return GetRandomLetter(length - 1) .. Charset[math.random(1, #Charset)]
    else
        return ''
    end
end

function GenerateRandomPlate()
    return string.upper(GetRandomLetter(3) .. ' ' .. GetRandomNumber(3))
end

RegisterServerEvent("admin:returnItem")
AddEventHandler("admin:returnItem", function(data)
    local adminSrc = source
    local playerIdentifier = data.playerIdentifier
    local itemId = tostring(data.itemId)
    local reason = data.reason or "Sin motivo"
    local isOffline = data.isOffline or false

    if not playerIdentifier or not itemId then
        print("[RETURN ITEM] Error: playerIdentifier o itemId no proporcionados")
        return
    end

    local adminDiscord = GetDiscordId(adminSrc)

    GetPlayerItems(data.discordId, function(items)
        local plate = nil
        local targetItem = nil
        for _, item in ipairs(items) do
            if tostring(item.id) == itemId then
                targetItem = item
                break
            end
        end

        if not targetItem then
            print(("[RETURN ITEM] No se encontró el item %s para %s"):format(itemId, playerIdentifier))
            return
        end

        local VEHICLE_CATEGORIES = {
            ["Coches"] = true,
            ["Helicópteros"] = true,
            ["Barcos"] = true,
            ["Caravanas"] = true
        }

        local itemName = targetItem.name
        if itemName == "Vehículo exclusivo" or itemName == "Copia vehículo exclusivo" then
            local inputModel = data.model
            local finalModel = (inputModel and inputModel ~= "") and inputModel or targetItem.model
            if finalModel and finalModel ~= "" then
                plate = GenerateRandomPlate()
                AddOwnedVehicle(playerIdentifier, plate, finalModel)
            else
                print("[RETURN] Falta el modelo para vehículo exclusivo.")
            end
        elseif itemName == "Matrícula personalizada" then
            local oldPlate = data.oldPlate
            local newPlate = data.newPlate

            if oldPlate and newPlate and oldPlate ~= "" and newPlate ~= "" then
                UpdateVehiclePlate(playerIdentifier, oldPlate, newPlate)
            else
                print("[RETURN] Faltan datos de matrículas.")
            end
        elseif VEHICLE_CATEGORIES[targetItem.category] then
            plate = GenerateRandomPlate()
            AddOwnedVehicle(playerIdentifier, plate, targetItem.model)
        elseif targetItem.category == "Verificación" or (targetItem.name and string.find(string.lower(targetItem.name), "verificación")) then
            local username = data.username
            local network = targetItem.model

            if username and username ~= "" and network and network ~= "" then
                exports["lb-phone"]:ToggleVerified(network, username, true)
            end
        end

        local title = "📦 Devolución de Item"
        local description = "Un administrador ha devuelto un item a un jugador."
        local color = 15158332

        local itemFieldValue = string.format(
            "**Nombre:** %s\n**Tipo:** %s\n**Modelo:** %s\n**Cantidad:** %s",
            targetItem.name or "N/A",
            targetItem.type or "N/A",
            targetItem.model or "N/A",
            targetItem.amount or 1
        )

        if plate then
            itemFieldValue = itemFieldValue .. string.format("\n**Matrícula:** %s", plate)
        end

        local embed = {
            {
                color = color,
                title = title,
                description = description,
                fields = {
                    {
                        name = "👮 Admin",
                        value = string.format("**ID:** %s\n**Discord:** <@%s>", adminSrc, adminDiscord),
                        inline = true
                    },
                    {
                        name = "🎯 Jugador",
                        value = string.format("**Identificador:** %s\n**Discord:** <@%s>", playerIdentifier,
                            data.discordId),
                        inline = true
                    },
                    {
                        name = "📦 Item",
                        value = itemFieldValue,
                        inline = false
                    },
                    {
                        name = "📝 Motivo",
                        value = reason,
                        inline = false
                    }
                },
                footer = {
                    text = os.date("%d/%m/%Y %H:%M:%S")
                }
            }
        }

        PerformHttpRequest(returnItemWebhook, function() end, "POST", json.encode({ embeds = embed }),
            { ["Content-Type"] = "application/json" })

        Citizen.Wait(200)
        GetAllPlayersWithItems(function(players)
            TriggerClientEvent("admin:updatePlayers", adminSrc, players)
        end)
    end)
end)

RegisterServerEvent("admin:getPCoins")
AddEventHandler("admin:getPCoins", function(data)
    local src = source
    local discordId = data.discordId

    if not discordId or discordId == "---" or discordId == "Desconocido" then
        TriggerClientEvent("admin:pCoinsResult", src, { pCoins = 0 })
        return
    end

    exports.oxmysql:fetch("SELECT coins FROM pts_users WHERE discord_id = ?", { discordId },
        function(result)
            local pCoins = 0
            if result and result[1] and result[1].coins then
                pCoins = result[1].coins
            end
            TriggerClientEvent("admin:pCoinsResult", src, { pCoins = pCoins })
        end)
end)

RegisterServerEvent("admin:managePCoins")
AddEventHandler("admin:managePCoins", function(data)
    local src = source
    local discordId = data.discordId
    local playerIdentifier = data.playerIdentifier
    local amount = data.amount or 0
    local action = data.action or "add"
    local reason = data.reason or "Sin motivo"

    if not discordId or discordId == "---" or discordId == "Desconocido" then
        TriggerClientEvent("admin:pCoinsUpdated", src, { success = false })
        return
    end

    if amount <= 0 then
        TriggerClientEvent("admin:pCoinsUpdated", src, { success = false })
        return
    end

    exports.oxmysql:fetch("SELECT coins FROM pts_users WHERE discord_id = ?", { discordId },
        function(result)
            local currentPCoins = 0
            if result and result[1] and result[1].coins then
                currentPCoins = result[1].coins
            end

            local newBalance = currentPCoins
            if action == "add" then
                newBalance = currentPCoins + amount
            elseif action == "remove" then
                newBalance = math.max(0, currentPCoins - amount)
            end

            exports.oxmysql:execute("UPDATE pts_users SET coins = ? WHERE discord_id = ?", { newBalance, discordId },
                function()
                    local adminDiscord = GetDiscordId(src)

                    local webhook = action == "add" and coinsAddWebhook or coinsRemoveWebhook
                    local title = action == "add" and "💰 pCoins Añadidos" or "💸 pCoins Removidos"
                    local color = action == "add" and 3066993 or 15158332

                    local embed = {
                        {
                            color = color,
                            title = title,
                            description = string.format("Un administrador ha %s pCoins.",
                                action == "add" and "añadido" or "removido"),
                            fields = {
                                {
                                    name = "👮 Admin",
                                    value = string.format("**ID:** %s\n**Discord:** <@%s>", src, adminDiscord),
                                    inline = true
                                },
                                {
                                    name = "🎯 Jugador",
                                    value = string.format("**Identificador:** %s\n**Discord:** <@%s>", playerIdentifier,
                                        discordId),
                                    inline = true
                                },
                                {
                                    name = "💰 Cambio",
                                    value = string.format(
                                        "**Cantidad:** %s pCoins\n**Balance anterior:** %s\n**Balance nuevo:** %s",
                                        amount, currentPCoins, newBalance),
                                    inline = false
                                },
                                {
                                    name = "📝 Motivo",
                                    value = reason,
                                    inline = false
                                }
                            },
                            footer = {
                                text = os.date("%d/%m/%Y %H:%M:%S")
                            }
                        }
                    }

                    PerformHttpRequest(webhook, function() end, "POST", json.encode({ embeds = embed }),
                        { ["Content-Type"] = "application/json" })

                    TriggerClientEvent("admin:pCoinsUpdated", src, { success = true, newBalance = newBalance })
                end)
        end)
end)

RegisterServerEvent("admin:deleteItem")
AddEventHandler("admin:deleteItem", function(data)
    local src = source
    local discordId = data.discordId
    local itemId = tostring(data.itemId)
    local reason = data.reason or "Sin motivo"

    if not discordId or not itemId then
        TriggerClientEvent("admin:itemDeleted", src, { success = false })
        return
    end

    if Config.StandaloneMode then
        exports.oxmysql:fetch(
            "SELECT up.*, p.title, p.type, p.model FROM devolutions_user_purchases up JOIN devolutions_products p ON up.product_id = p.id WHERE up.discord_id = ? AND up.product_id = ?",
            { discordId, itemId },
            function(result)
                if not result or not result[1] then
                    TriggerClientEvent("admin:itemDeleted", src, { success = false })
                    return
                end

                local purchase = result[1]

                exports.oxmysql:execute("DELETE FROM devolutions_user_purchases WHERE id = ?", { purchase.id },
                    function()
                        local adminDiscord = GetDiscordId(src)
                        local playerIdentifier = data.playerIdentifier or "N/A"

                        local embed = {
                            {
                                color = 15158332,
                                title = "🗑️ Producto Eliminado",
                                description = "Un administrador ha eliminado un producto de un jugador.",
                                fields = {
                                    {
                                        name = "👮 Admin",
                                        value = string.format("**ID:** %s\n**Discord:** <@%s>", src, adminDiscord),
                                        inline = true
                                    },
                                    {
                                        name = "🎯 Jugador",
                                        value = string.format("**Identificador:** %s\n**Discord:** <@%s>",
                                            playerIdentifier, discordId),
                                        inline = true
                                    },
                                    {
                                        name = "📦 Item Eliminado",
                                        value = string.format(
                                            "**Nombre:** %s\n**Tipo:** %s\n**Modelo:** %s\n**Cantidad:** %s",
                                            purchase.title, purchase.type, purchase.model, purchase.quantity),
                                        inline = false
                                    },
                                    {
                                        name = "📝 Motivo",
                                        value = reason,
                                        inline = false
                                    }
                                },
                                footer = {
                                    text = os.date("%d/%m/%Y %H:%M:%S")
                                }
                            }
                        }

                        PerformHttpRequest(deleteItemWebhook, function() end, "POST", json.encode({ embeds = embed }),
                            { ["Content-Type"] = "application/json" })

                        TriggerClientEvent("admin:itemDeleted", src, { success = true })

                        Citizen.Wait(200)
                        GetAllPlayersWithItems(function(players)
                            TriggerClientEvent("admin:updatePlayers", src, players)
                        end)
                    end)
            end
        )
    else
        exports.oxmysql:fetch("SELECT purchases FROM pts_users WHERE discord_id = ?", { discordId },
            function(result)
                if not result or not result[1] or not result[1].purchases then
                    TriggerClientEvent("admin:itemDeleted", src, { success = false })
                    return
                end

                local success, purchases = pcall(function() return json.decode(result[1].purchases) end)
                if not success or type(purchases) ~= "table" then
                    TriggerClientEvent("admin:itemDeleted", src, { success = false })
                    return
                end

                local itemName = "Desconocido"
                local itemAmount = purchases[itemId] or 0

                exports.oxmysql:fetch("SELECT * FROM pts_products WHERE id = ?", { itemId },
                    function(productResult)
                        if productResult and productResult[1] then
                            local product = productResult[1]
                            local categoryConfig = Config.Categories[product.category] or Config.Categories["default"]
                            local productType = categoryConfig.type
                            local productModel = ""

                            if product.commands then
                                local _, cmdModel = product.commands:match("pts_(%w+)%s+(.+)")
                                if cmdModel then
                                    productModel = cmdModel:gsub('^"', ''):gsub('"%]$', '')
                                end
                            end

                            itemName = product.title

                            local itemInfo = {
                                title = product.title,
                                type = productType,
                                model = productModel,
                                amount = itemAmount
                            }

                            purchases[itemId] = nil
                            local jsonPurchases = json.encode(purchases)

                            exports.oxmysql:execute("UPDATE pts_users SET purchases = ? WHERE discord_id = ?",
                                { jsonPurchases, discordId },
                                function()
                                    local adminDiscord = GetDiscordId(src)

                                    playerIdentifier = data.playerIdentifier or "N/A"

                                    local embed = {
                                        {
                                            color = 15158332,
                                            title = "🗑️ Producto Eliminado",
                                            description = "Un administrador ha eliminado un producto de un jugador.",
                                            fields = {
                                                {
                                                    name = "👮 Admin",
                                                    value = string.format("**ID:** %s\n**Discord:** <@%s>", src,
                                                        adminDiscord),
                                                    inline = true
                                                },
                                                {
                                                    name = "🎯 Jugador",
                                                    value = string.format("**Identificador:** %s\n**Discord:** <@%s>",
                                                        playerIdentifier, discordId),
                                                    inline = true
                                                },
                                                {
                                                    name = "📦 Item Eliminado",
                                                    value = string.format(
                                                        "**Nombre:** %s\n**Tipo:** %s\n**Modelo:** %s\n**Cantidad:** %s",
                                                        itemInfo.title, itemInfo.type, itemInfo.model, itemInfo.amount),
                                                    inline = false
                                                },
                                                {
                                                    name = "📝 Motivo",
                                                    value = reason,
                                                    inline = false
                                                }
                                            },
                                            footer = {
                                                text = os.date("%d/%m/%Y %H:%M:%S")
                                            }
                                        }
                                    }

                                    PerformHttpRequest(deleteItemWebhook, function() end, "POST", json.encode({ embeds = embed }),
                                        { ["Content-Type"] = "application/json" })

                                    TriggerClientEvent("admin:itemDeleted", src, { success = true })

                                    Citizen.Wait(200)
                                    GetAllPlayersWithItems(function(players)
                                        TriggerClientEvent("admin:updatePlayers", src, players)
                                    end)
                                end)
                        end
                    end)
            end)
    end
end)

RegisterServerEvent("admin:createProduct")
AddEventHandler("admin:createProduct", function(data)
    local src = source

    if not Config.StandaloneMode then
        TriggerClientEvent("admin:productCreated", src,
            { success = false, message = "Solo disponible en modo standalone" })
        return
    end

    exports.oxmysql:execute(
        "INSERT INTO devolutions_products (title, description, image, category, model, type, icon) VALUES (?, ?, ?, ?, ?, ?, ?)",
        { data.title, data.description, data.image, data.category, data.model, data.type, data.icon },
        function(result)
            if result then
                TriggerClientEvent("admin:productCreated", src, { success = true, id = result })

                -- Recargar productos
                TriggerEvent("admin:getProducts", src)
            else
                TriggerClientEvent("admin:productCreated", src, { success = false, message = "Error al crear producto" })
            end
        end
    )
end)
