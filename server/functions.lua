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

local DISCORD_WEBHOOK =
"https://discord.com/api/webhooks/1362732245181268008/itWD66HWiWREvISdm6hjpjplzZ3EZlLLVNPQzTv0nDWiIAzkCPF92cHukUgfs3KP23mR"

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

function AddOwnedVehicle(source, plate, model)
    local xPlayer = GetPlayer(source)
    MySQL.Async.execute("INSERT INTO owned_vehicles (owner, plate, vehicle) VALUES (@owner, @plate, @vehicle);", {
        ['@owner'] = xPlayer.identifier,
        ['@plate'] = string.upper(plate),
        ['@vehicle'] = json.encode({
            plate = string.upper(plate),
            model = joaat(model),
        }),
    })
end

function SendDiscordLog(data)
    local embed = {
        {
            color = 15158332, -- rojo
            title = "📦 Devolución de Item",
            description = "Un administrador ha devuelto un item a un jugador.",
            fields = {
                {
                    name = "👮 Admin",
                    value = string.format(
                        "**ID:** %s\n**Discord:** <@%s>",
                        data.adminId,
                        data.adminDiscord
                    ),
                    inline = true
                },
                {
                    name = "🎯 Jugador",
                    value = string.format(
                        "**ID:** %s\n**Identifier:** %s",
                        data.targetId,
                        data.targetIdentifier
                    ),
                    inline = true
                },
                {
                    name = "📦 Item",
                    value = string.format(
                        "**Nombre:** %s\n**Tipo:** %s\n**Modelo:** %s\n**Cantidad:** %s\n**Matrícula:** %s",
                        data.itemTitle,
                        data.itemType,
                        data.itemModel,
                        data.itemAmount,
                        data.itemPlate
                    ),
                    inline = false
                },
                {
                    name = "📝 Motivo",
                    value = data.reason or "Sin motivo",
                    inline = false
                }
            },
            footer = {
                text = os.date("%d/%m/%Y %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(
        DISCORD_WEBHOOK,
        function() end,
        "POST",
        json.encode({ embeds = embed }),
        { ["Content-Type"] = "application/json" }
    )
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
