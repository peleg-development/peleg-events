Config = {}

-- Event System Configuration
Config.AuthorizedLicenses = {
    "license:1ce314a6a960deaba431fd40484c4726de96fbb8", -- Replace with actual authorized licenses
    "license:0987654321fedcba"
}

Config.Events = {
    CarSumo = {
        name = "Car Sumo",
        description = "Fight to the death in cars above the sky!",
        maxPlayers = 16,
        minPlayers = 2,
        defaultReward = {
            type = "money",
            data = { amount = 5000 }
        },
        spawnLocation = vector3(0.0, 0.0, 1500.0), -- Sky ring location
        ringRadius = 120.0, -- Increased platform size
        fallHeight = 1200.0,
        countdownDuration = 10,
        defaultVehicles = {
            "adder",
            "zentorno", 
            "t20",
            "osiris",
            "entityxf",
            "fmj",
            "prototipo",
            "reaper",
            "sultanrs",
            "banshee",
            "bullet",
            "cheetah",
            "comet2",
            "coquette",
            "feltzer2",
            "rapidgt"
        },
        spawnPositions = {
            -- Predefined spawn positions around the ring for better distribution
            vector3(0.0, 120.0, 1500.0),   -- North
            vector3(120.0, 0.0, 1500.0),   -- East
            vector3(0.0, -120.0, 1500.0),  -- South
            vector3(-120.0, 0.0, 1500.0),  -- West
            vector3(84.85, 84.85, 1500.0), -- Northeast
            vector3(84.85, -84.85, 1500.0), -- Southeast
            vector3(-84.85, -84.85, 1500.0), -- Southwest
            vector3(-84.85, 84.85, 1500.0),  -- Northwest
            vector3(60.0, 103.92, 1500.0),   -- North-Northeast
            vector3(103.92, 60.0, 1500.0),   -- East-Northeast
            vector3(103.92, -60.0, 1500.0),  -- East-Southeast
            vector3(60.0, -103.92, 1500.0),  -- South-Southeast
            vector3(-60.0, -103.92, 1500.0), -- South-Southwest
            vector3(-103.92, -60.0, 1500.0), -- West-Southwest
            vector3(-103.92, 60.0, 1500.0),  -- West-Northwest
            vector3(-60.0, 103.92, 1500.0)   -- North-Northwest
        }
    },
    
    Redzone = {
        name = "Redzone",
        description = "Last man standing in the redzone!",
        maxPlayers = 32,
        minPlayers = 2,
        defaultReward = {
            type = "money",
            data = { amount = 10000 }
        },
        spawnLocations = {
            -- r=180 (8)
            vector3(-1942.205, 3124.381, 32.810169),
            vector3(-1994.926, 3251.660, 32.810169),
            vector3(-2122.205, 3304.381, 32.810169),
            vector3(-2249.484, 3251.660, 32.810169),
            vector3(-2302.205, 3124.381, 32.810169),
            vector3(-2249.484, 2997.102, 32.810169),
            vector3(-2122.205, 2944.381, 32.810169),
            vector3(-1994.926, 2997.102, 32.810169),
    
            -- r=130 (8) (offset)
            vector3(-2002.101, 3174.130, 32.810169),
            vector3(-2072.456, 3244.485, 32.810169),
            vector3(-2171.954, 3244.485, 32.810169),
            vector3(-2242.309, 3174.130, 32.810169),
            vector3(-2242.309, 3074.632, 32.810169),
            vector3(-2171.954, 3004.277, 32.810169),
            vector3(-2072.456, 3004.277, 32.810169),
            vector3(-2002.101, 3074.632, 32.810169),
    
            -- r=90 (8)
            vector3(-2032.205, 3124.381, 32.810169),
            vector3(-2058.565, 3188.021, 32.810169),
            vector3(-2122.205, 3214.381, 32.810169),
            vector3(-2185.845, 3188.021, 32.810169),
            vector3(-2212.205, 3124.381, 32.810169),
            vector3(-2185.845, 3060.741, 32.810169),
            vector3(-2122.205, 3034.381, 32.810169),
            vector3(-2058.565, 3060.741, 32.810169),
    
            -- r=45 (8) (offset)
            vector3(-2080.630, 3141.602, 32.810169),
            vector3(-2104.984, 3165.956, 32.810169),
            vector3(-2139.426, 3165.956, 32.810169),
            vector3(-2163.780, 3141.602, 32.810169),
            vector3(-2163.780, 3107.160, 32.810169),
            vector3(-2139.426, 3082.807, 32.810169),
            vector3(-2104.984, 3082.807, 32.810169),
            vector3(-2080.630, 3107.160, 32.810169)
        },
        zoneCenter = vector3(-2122.205, 3124.3811, 32.810169),
        zoneRadius = 200.0,
        spectatorHeight = 100.0,
        countdownDuration = 10,
        defaultWeapons = {
            "WEAPON_PISTOL",
            "WEAPON_SMG",
            "WEAPON_CARBINERIFLE",
            "WEAPON_PUMPSHOTGUN",
            "WEAPON_SNIPERRIFLE"
        }
    },
    
    Party = {
        name = "Party",
        description = "Join the party at the host's location!",
        maxPlayers = 999999,
        minPlayers = 1,
        defaultReward = {
            type = "money",
            data = { amount = 1000 }
        },
        countdownDuration = 0
    }
}

-- UI Configuration
Config.UI = {
    colors = {
        primary = "#3B82F6",
        secondary = "#1F2937",
        success = "#10B981",
        danger = "#EF4444",
        warning = "#F59E0B"
    }
}

-- Framework Detection
Config.Framework = "auto" -- auto, esx, qbcore, standalone


Config.Debug = false