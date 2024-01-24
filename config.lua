

Config = {}
Config.DebugPoly = false


Config.MinLocations = 1

Config.Locations = {
    ["dingybathroom1"] = {
        coords = vector4(-1807.92, -845.19, 6.81, 307.66),
        length = 10,
        width = 10,
        infectChance = 100,
        possibleDiseases = {
            'platypus_parasite',
            'foul_fungus',
            'valcano_virus',
        },
    }
}

Config.Diseases = {
    platypus_parasite = {
        label = 'Tape Worm',
        infectChance = 50, -- in percent
        initialDelay = 10000, -- in milliseconds
        delay = 10000, -- in milliseconds
        effectEvent = 'mrc-disease:client:PlatypusParasiteEffect', -- must be client
        effectChance = 100, -- in percent
        playerInfectionRadius = 2.0, -- in meters

    },
    foul_fungus = {
        label = 'Chicken Pox',
        initialDelay = 10000, -- in milliseconds
        delay = 10000, -- in milliseconds
        infectChance = 50, -- in percent
        effectEvent = 'mrc-disease:client:FoulFungusEffect', -- must be client
        effectChance = 100, -- in percent
        playerInfectionRadius = 2.0, -- in meters
    },
    valcano_virus = {
        label = 'Fever',
        infectChance = 50, -- in percent
        initialDelay = 10000, -- in milliseconds
        delay = 10000, -- in milliseconds
        effectEvent = 'mrc-disease:client:ValcanoVirusEffect', -- must be client
        effectChance = 100, -- in percent
        playerInfectionRadius = 2.0, -- in meters
    },
}

Config.CureItems = {
    hemostat = {
        cures = {
            platypus_parasite = true,
        },
    },
    foul_cream = {
        cures = {
            foul_fungus = true,
        },
    },
    cup_of_ice_water = {
        cures = {
            valcano_virus = true,
        },
    },
}