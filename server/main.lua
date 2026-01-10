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

MySQL.ready(function()
    local queries = {
        [[
            CREATE TABLE IF NOT EXISTS muhaddil_devolutions (
                id INT AUTO_INCREMENT PRIMARY KEY,
                player_identifier VARCHAR(255) NOT NULL,
                item_id VARCHAR(255) NOT NULL,
                title VARCHAR(255) NOT NULL,
                type VARCHAR(100),
                model VARCHAR(100),
                description LONGTEXT,
                image LONGTEXT,
                amount INT NOT NULL DEFAULT 1,
                date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
        ]]
    }

    for _, query in ipairs(queries) do
        MySQL.query.await(query)
    end
end)

function GetPlayerItems(discordId, cb)
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

        exports.oxmysql:fetch("SELECT * FROM pts_products WHERE id IN (" .. placeholders .. ")", {}, function(products)
            if products then
                for _, product in ipairs(products) do
                    local quantity = purchases[tostring(product.id)] or 1
                    local productType = "Item"
                    local productModel = ""

                    if product.commands then
                        local cmdType, cmdModel = product.commands:match("pts_(%w+)%s+(.+)")
                        if cmdType then
                            productModel = cmdModel or ""
                            productModel = productModel:gsub('^"', ''):gsub('"%]$', '')
                        end
                    end

                    table.insert(items, {
                        id = product.id,
                        name = product.title,
                        type = productType,
                        category = product.category,
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

function AddPlayerItem(playerIdentifier, itemData, discordId)
    playerIdentifier = playerIdentifier or 'a'

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

        exports.oxmysql:execute("UPDATE pts_users SET purchases = ? WHERE discord_id = ?", { jsonPurchases, discordId },
            function(affectedRows)
            end)
    end)
end

exports('AddPlayerItem', AddPlayerItem)

function RemovePlayerItem(playerIdentifier, itemId)
    exports.oxmysql:execute("DELETE FROM muhaddil_devolutions WHERE player_identifier = ? AND item_id = ?",
        { playerIdentifier, itemId })
end

exports('RemovePlayerItem', RemovePlayerItem)

function UpdatePlayerItemAmount(playerIdentifier, itemId, amount)
    exports.oxmysql:execute("UPDATE muhaddil_devolutions SET amount = ? WHERE player_identifier = ? AND item_id = ?",
        { amount, playerIdentifier, itemId })
end

exports('UpdatePlayerItemAmount', UpdatePlayerItemAmount)

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
    exports.oxmysql:fetch("SELECT * FROM pts_products", {},
        function(result)
            local products = {}
            if result then
                for _, product in ipairs(result) do
                    local productType = "Item"
                    local productModel = ""

                    if product.commands then
                        local commands = product.commands
                        local category = product.category
                        local cmdType, cmdModel = commands:match("pts_(%w+)%s+(.+)")

                        if cmdType then
                            if category == "Coches" then
                                productType = "Coche"
                            elseif category == "Helicopteros" then
                                productType = "Helicoptero"
                            elseif category == "Peds" then
                                productType = "Peds"
                            elseif category == "Vehículos exclusivos" then
                                productType = "Vehículo exclusivo"
                            else
                                productType = "Item"
                            end

                            productModel = cmdModel or ""
                            productModel = productModel:gsub('^"', ''):gsub('"%]$', '')
                        end
                    end

                    table.insert(products, {
                        id = product.id,
                        title = product.title,
                        description = product.description,
                        image = product.image,
                        type = productType,
                        model = productModel,
                        category = product.category
                    })
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
    }, data.discordId)

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
    local plate = "N/A"

    if not playerIdentifier or not itemId then
        print("[RETURN ITEM] Error: playerIdentifier o itemId no proporcionados")
        return
    end

    local adminDiscord = GetDiscordId(adminSrc)

    GetPlayerItems(data.discordId, function(items)
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

        if not isOffline then
            local xTarget = nil
            for _, playerId in ipairs(GetPlayers()) do
                local identifier = GetIdentifier(playerId)
                if identifier == playerIdentifier then
                    xTarget = playerId
                    break
                end
            end

            if xTarget then
                if targetItem.category == "Coches" then
                    plate = GenerateRandomPlate()
                    AddOwnedVehicle(xTarget, plate, targetItem.model)
                elseif targetItem.category == "Item" then
                    TriggerEvent('esx:addInventoryItem', xTarget, targetItem.model, targetItem.amount)
                elseif targetItem.category == "Dinero" then
                    TriggerEvent('esx:addMoney', xTarget, targetItem.amount)
                elseif targetItem.category == "Banco" then
                    TriggerEvent('esx:addBank', xTarget, targetItem.amount)
                end
            else
                print("[RETURN ITEM] Jugador no está online, será tratado como offline")
            end
        else
            print("[RETURN ITEM] Devolución marcada como offline")
        end

        SendDiscordLog({
            adminId = adminSrc,
            adminDiscord = adminDiscord,
            targetIdentifier = playerIdentifier,
            itemTitle = targetItem.name,
            itemType = targetItem.type,
            itemModel = targetItem.model or "N/A",
            itemAmount = targetItem.amount or 1,
            reason = reason,
            isOffline = isOffline,
            itemPlate = plate
        })

        Citizen.Wait(200)
        GetAllPlayersWithItems(function(players)
            TriggerClientEvent("admin:updatePlayers", adminSrc, players)
            print("[RETURN ITEM] Lista de jugadores actualizada")
        end)
    end)
end)
