local ESX = nil
local QBCore = nil
local ESXVer = Config.ESXVer
local FrameWork = nil

if Config.FrameWork == "auto" then
    if GetResourceState('es_extended') == 'started' then
        if ESXVer == 'new' then
            ESX = exports['es_extended']:getSharedObject()
            FrameWork = 'esx'
            print('===ESX FRAMEWORK DETECTED===')
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
    print('===NO SUPPORTED FRAMEWORK FOUND===')
end

function GetDiscordId(src)
    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find("discord:") then
            return id:gsub("discord:", "")
        end
    end
    return "No vinculado"
end

function GetPlayer(source)
    if FrameWork == 'esx' then
        return ESX.GetPlayerFromId(source)
    elseif FrameWork == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    end
end

function GetIdentifier(source)
    if FrameWork == "esx" then
        local xPlayer = GetPlayer(source)
        return xPlayer and xPlayer.identifier or nil
    elseif FrameWork == "qb" then
        local Player = GetPlayer(source)
        return Player and Player.PlayerData.citizenid or nil
    end
end

function GetIdentifiersAll(src)
    local identifiers = {
        identifier = nil,
        discord = "No vinculado"
    }

    for _, id in ipairs(GetPlayerIdentifiers(src)) do
        if id:find("license:") then
            identifiers.identifier = id
        elseif id:find("discord:") then
            identifiers.discord = id:gsub("discord:", "")
        end
    end

    return identifiers
end

function AddOwnedVehicle(identifier, plate, model)
    local vehicleProps = {
        plate = string.upper(plate),
        model = joaat(model)
    }

    MySQL.insert("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (?, ?, ?)", {
        identifier,
        string.upper(plate),
        json.encode(vehicleProps)
    })
end

function hasPermission(src)
    if not Config.RestricToAdmins then
        return true
    end

    if FrameWork == 'qb' then
        for _, group in ipairs(Config.AllowedGroups.qb) do
            if QBCore.Functions.HasPermission(src, group) then
                return true
            end
        end
    end

    if FrameWork == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(src)
        if xPlayer then
            for _, group in ipairs(Config.AllowedGroups.esx) do
                if xPlayer.getGroup() == group then
                    return true
                end
            end
        end
    end

    for _, aceGroup in ipairs(Config.AllowedGroups.ace) do
        if IsPlayerAceAllowed(src, aceGroup) then
            return true
        end
    end

    return false
end

RegisterNetEvent("devolutions:start", function()
    local src = source
    if hasPermission(src) then
        TriggerEvent("admin:getPlayers", src)
        TriggerEvent("admin:getProducts", src)
    else
        print(("muhaddil-devolutions: El jugador %s intentó acceder al panel sin permisos."):format(src))
    end
end)

function UpdateVehiclePlate(identifier, oldPlate, newPlate)
    local oldPlate = string.upper(oldPlate)
    local newPlate = string.upper(newPlate)

    MySQL.query("SELECT vehicle FROM owned_vehicles WHERE plate = ? AND owner = ?", { oldPlate, identifier },
        function(result)
            if result and result[1] then
                local vehicleProps = json.decode(result[1].vehicle)
                vehicleProps.plate = newPlate

                MySQL.update("UPDATE owned_vehicles SET plate = ?, vehicle = ? WHERE plate = ? AND owner = ?", {
                    newPlate, json.encode(vehicleProps), oldPlate, identifier
                }, function(affected)
                    if affected > 0 then
                        if GetResourceState('jg-mechanic') == 'started' then
                            pcall(function() exports["jg-mechanic"]:vehiclePlateUpdated(oldPlate, newPlate) end)
                        end
                    end
                end)
            end
        end)
end

if FrameWork == 'esx' then
    RegisterNetEvent('esx:playerLoaded', function(player, xPlayer, isNew)
        local src = player
        local identifiers = GetPlayerIdentifiers(src)
        local license, steam, discord, xbl, live, ip = "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"
        local steam_name = GetPlayerName(src)

        for _, id in pairs(identifiers) do
            if string.find(id, "license:") then
                license = id
            elseif string.find(id, "steam:") then
                steam = id
            elseif string.find(id, "discord:") then
                discord = id:gsub("discord:", "")
            elseif string.find(id, "xbl:") then
                xbl = id
            elseif string.find(id, "live:") then
                live = id
            elseif string.find(id, "ip:") then
                ip = "Disabled for privacy"
            end
        end

        MySQL.Async.execute([[
        INSERT INTO user_identifiers (license, steam, discord, xbl, live, ip, steam_name)
        VALUES (@license, @steam, @discord, @xbl, @live, @ip, @steam_name)
        ON DUPLICATE KEY UPDATE
            steam = @steam,
            discord = @discord,
            xbl = @xbl,
            live = @live,
            ip = @ip,
            steam_name = @steam_name
    ]], {
            ["@license"] = license,
            ["@steam"] = steam,
            ["@discord"] = discord,
            ["@xbl"] = xbl,
            ["@live"] = live,
            ["@ip"] = ip,
            ["@steam_name"] = steam_name
        })
    end)
end

if FrameWork == 'qb' then
    RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
        local src = source
        local identifiers = GetPlayerIdentifiers(src)
        local license, steam, discord, xbl, live, ip = "N/A", "N/A", "N/A", "N/A", "N/A", "N/A"
        local steam_name = GetPlayerName(src)

        for _, id in pairs(identifiers) do
            if string.find(id, "license:") then
                license = id
            elseif string.find(id, "steam:") then
                steam = id
            elseif string.find(id, "discord:") then
                discord = id:gsub("discord:", "")
            elseif string.find(id, "xbl:") then
                xbl = id
            elseif string.find(id, "live:") then
                live = id
            elseif string.find(id, "ip:") then
                ip = "Disabled for privacy"
            end
        end

        MySQL.Async.execute([[
        INSERT INTO user_identifiers (license, steam, discord, xbl, live, ip, steam_name)
        VALUES (@license, @steam, @discord, @xbl, @live, @ip, @steam_name)
        ON DUPLICATE KEY UPDATE
            steam = @steam,
            discord = @discord,
            xbl = @xbl,
            live = @live,
            ip = @ip,
            steam_name = @steam_name
    ]], {
            ["@license"] = license,
            ["@steam"] = steam,
            ["@discord"] = discord,
            ["@xbl"] = xbl,
            ["@live"] = live,
            ["@ip"] = ip,
            ["@steam_name"] = steam_name
        })
    end)
end