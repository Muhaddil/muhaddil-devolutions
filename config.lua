Config = {}

Config.FrameWork = "auto" -- auto, esx, qb
Config.ESXVer = "new" -- new, old
Config.AutoVersionChecker = true -- Automatically checks for updates on resource start
Config.AllowedGroups = {
    qb = { "admin", "god" },         -- QBCore roles
    esx = { "admin", "superadmin" }, -- ESX groups
    ace = { "bedconfigurator" }      -- ACE permissions
}

Config.StandaloneMode = false -- If true, the script will run in standalone mode, without using pickle-store // https://picklemods.com/package/6664832

Config.Tables = {
    Products = Config.StandaloneMode and "devolutions_products" or "pts_products",
    UserPurchases = Config.StandaloneMode and "devolutions_user_purchases" or "pts_users"
}

Config.Categories = {
    ["Coches"] = { 
        label = "Coches",
        type = "Coche", 
        icon = "fas fa-car" 
    },
    ["Helicopteros"] = { 
        label = "Helicópteros",
        type = "Helicóptero", 
        icon = "fas fa-helicopter" 
    },
    ["Barcos"] = { 
        label = "Barcos",
        type = "Barco", 
        icon = "fas fa-ship" 
    },
    ["Caravanas"] = { 
        label = "Caravanas",
        type = "Caravana", 
        icon = "fas fa-trailer" 
    },
    ["Peds"] = { 
        label = "Personajes",
        type = "Ped", 
        icon = "fas fa-user-friends" 
    },
    ["Vehículos exclusivos"] = { 
        label = "Vehículos Exclusivos",
        type = "Vehículo Exclusivo", 
        icon = "fas fa-crown" 
    },
    ["Negocios"] = { 
        label = "Negocios",
        type = "Negocio", 
        icon = "fas fa-briefcase" 
    },
    ["Casas"] = { 
        label = "Casas",
        type = "Casa", 
        icon = "fas fa-home" 
    },
    ["Extras"] = { 
        label = "Extras",
        type = "Extra", 
        icon = "fas fa-plus-circle" 
    },
    ["Interiores"] = { 
        label = "Interiores",
        type = "Interior", 
        icon = "fas fa-couch" 
    },
    ["Organizaciones Criminales"] = { 
        label = "Organizaciones Criminales",
        type = "Org. Criminal", 
        icon = "fas fa-skull" 
    },
    ["Redes Sociales"] = { 
        label = "Verificación",
        type = "Verificación", 
        icon = "fas fa-check-circle" 
    },
    ["default"] = {
        label = "Otros",
        type = "Item",
        icon = "fas fa-box"
    }
}
