Config = {}

Config.Job = 'mechanic'

-- Repair item required to open repair menu
Config.RepairItem = 'repair_kit'

-- Repair costs deducted from player's bill (society account)
Config.RepairPrices = {
    engine  = 500,
    body    = 300,
    tyres   = 150,
    full    = 1200,
}

-- How much health each repair restores (0.0 - 1000.0)
Config.RepairValues = {
    engine  = 1000.0,
    body    = 1000.0,
    tyres   = 100.0, -- per tyre
}

-- ox_target / qb-target interaction distance
Config.TargetDistance = 3.0

-- Garage / shop location (where target zones are placed)
Config.ShopZones = {
    {
        coords = vector3(726.6, -1085.0, 22.2), -- Legion Square garage (example)
        heading = 0.0,
        label = 'Mechanic Shop',
    },
}

-- Boss menu location
Config.BossMenuCoords = vector3(726.6, -1085.0, 22.2)

-- Society account name (for billing)
Config.SocietyAccount = 'society_mechanic'

-- Billing settings
Config.BillLabel = 'Mechanic Services'

-- Job grades
Config.Grades = {
    [0] = 'Apprentice',
    [1] = 'Mechanic',
    [2] = 'Senior Mechanic',
    [3] = 'Manager',
    [4] = 'Boss',
}
