Config = {}

Config.FrameWork = "auto" -- auto, esx, qb
Config.ESXVer = "new" -- new, old
Config.AllowedGroups = {
    qb = { "admin", "god" },         -- QBCore roles
    esx = { "admin", "superadmin" }, -- ESX groups
    ace = { "bedconfigurator" }      -- ACE permissions
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
