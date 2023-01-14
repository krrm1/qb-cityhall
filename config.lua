Config = Config or {}

Config.UseTarget = GetConvar('UseTarget', 'false') == 'true' -- Use qb-target interactions (don't change this, go to your server.cfg and add `setr UseTarget true` to use this and just that from true to false or the other way around)

Config.Cityhalls = {
    { -- Cityhall 1
        coords = vector3(236.75, -408.69, 47.92),
        showBlip = true,
        blipData = {
            sprite = 487,
            display = 4,
            scale = 0.65,
            colour = 0,
            title = "City Services"
        },
        licenses = {
            ["id_card"] = {
                label = "ID Card",
                cost = 50,
            },
            ["driver_license"] = {
                label = "Driver License",
                cost = 144,
                metadata = "driver"
            },
            ["weaponlicense"] = {
                label = "Weapon License",
                cost = 1000,
                metadata = "weapon"
            },
        },
        jobs = {
            ["trucker"] = "Trucker",
            ["taxi"] = "Taxi",
            ["tow"] = "Tow Truck",
            ["reporter"] = "News Reporter",
            ["garbage"] = "Garbage Collector",
            ["bus"] = "Bus Driver",
            ["hotdog"] = "Hot Dog Stand"
        }
        
    },
}

Config.Peds = {
    -- Cityhall Ped
    {
        model = 'a_m_y_business_02',
        coords = vector4(236.48, -409.33, 46.92, 343.56),
        scenario = 'WORLD_HUMAN_STAND_MOBILE',
        cityhall = true,
        zoneOptions = { -- Used for when UseTarget is false
            length = 3.0,
            width = 3.0,
            debugPoly = false
        }
    },
}
