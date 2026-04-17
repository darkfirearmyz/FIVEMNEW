# qb-mechanic

A full QBCore mechanic job script with repair menu, job whitelist, repair kit requirement, boss menu integration, and player billing.

## Dependencies

| Resource | Required |
|---|---|
| qb-core | ✅ |
| ox_target **or** qb-target | ✅ (one of them) |
| oxmysql | ✅ |
| qb-bossmenu | ✅ (boss menu + society account) |
| qb-inventory | ✅ (for repair_kit item) |

## Installation

1. Drop the `qb-mechanic` folder into your `resources` directory.
2. Add `ensure qb-mechanic` to your `server.cfg` **after** qb-core and your target resource.
3. Add the `repair_kit` item to `qb-core/shared/items.lua`:

```lua
['repair_kit'] = {
    name        = 'repair_kit',
    label       = 'Repair Kit',
    weight      = 1000,
    type        = 'item',
    image       = 'repair_kit.png',
    unique      = false,
    useable     = false,
    shouldClose = false,
    combinable  = nil,
    description = 'A basic vehicle repair kit'
},
```

4. Add the `mechanic` job to your database (or via qb-core jobs config):

```lua
['mechanic'] = {
    label = 'Mechanic',
    defaultDuty = true,
    offDutyPay  = false,
    grades = {
        ['0'] = { name = 'Apprentice',      payment = 50  },
        ['1'] = { name = 'Mechanic',        payment = 80  },
        ['2'] = { name = 'Senior Mechanic', payment = 120 },
        ['3'] = { name = 'Manager',         payment = 160 },
        ['4'] = { name = 'Boss',            payment = 200, isboss = true },
    },
},
```

5. Create the society account in your `qb-management` / `qb-bossmenu` config:

```lua
['society_mechanic'] = { label = 'Mechanic Society', money = 0, type = 'society' },
```

6. Update `Config.ShopZones` and `Config.BossMenuCoords` in `config.lua` to your desired in-game locations.

## Features

- **Repair Menu** — Engine, Body, Tyres, Full Repair with animated progress
- **Job Whitelist** — Only players with the `mechanic` job can open the menu
- **Repair Kit Required** — Consumes one `repair_kit` item per repair
- **Boss Menu** — Integrates with `qb-bossmenu` for hire/fire/balance management
- **Player Billing** — Bill nearby players; funds go to the society account

## Config

Edit `config.lua` to adjust prices, repair values, item name, society account, and shop zone coordinates.
