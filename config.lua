Config = {}

Config.Debug = true

Config.Language = "en" -- Language to use.

Config.RenderDistance = 20.0 -- Scenario display Radius.

Config.InteractDistance = 1.5 -- Interact Radius

Config.UseTarget = true -- When set to true, it'll use targeting instead of key-presses to interact.

Config.NoModelTargeting = true -- When set to true and using Target, it'll spawn a small invisible prop so you can third-eye when no entity is defined.

Config.XPEnabled = true -- Enables the XP feature for adding and checking XP Levels.

Config.InventoryLimit = false -- If using ESX 1.1, this must be on if using a limit-based inventory.

Config.TazerPermissions = { -- If you want your tazers to keep working, please add jobs that are allowed to use them here.
    enabled = true, -- If you REALLY REALLY don't want this to be blocked, set this to false.
    jobs = {
        ["police"] = 0, -- Any person with the job police can use a tazer at rank 0 and above.
    },
}

Config.JailEvent = function(source, time) -- This is the server-side event that is triggered when a player is jailed.
    -- source: The player's server ID.
    -- time: The time the player is jailed for.
    if GetResourceState("rcore_prison") == "started" then 
        exports['rcore_prison']:Jail(source, time, "Parole Violation")
    elseif GetResourceState("pickle_prisons") == "started" then 
        exports.pickle_prisons:JailPlayer(source, time, "default")
    end
end

Config.NPCBounties = {
    enabled = true,
    generateCooldown = 30, -- Cooldown in seconds for generating a new NPC bounty (this is skipped during server start).
    maxNPCBounties = 10, -- Maximum amount of NPC bounties that can be available at once.
    rewardRange = {1000, 5000}, -- Minimum and maximum reward for NPC bounties.
    maxDistance = 200.0, -- Maximum distance from the player a spawned NPC bounty can be before it fails the mission.
    maxDrivingTime = 180, -- Maximum time in seconds the NPC bounty can be driving before it stops the car to get out and run / shoot.
    maxStopTime = 10, -- Time in seconds the NPC bounty can be stopped for before it gets out and runs / shoots.
    blip = {
        labelPrefix = "Bounty:", -- Prefix for the blip label. Bounty: NAME_HERE
        sprite = 378,
        color = 1,
        scale = 0.8,
        rngOffset = {0, 100}, -- Range for how far the blip can be offset from the center of the radius. Good for making people search for the target.
        radius = { color = 1, alpha = 127, size = 100.0}
    },
    locations = {
        { coords = vector3(-58.4249, -146.6452, 56.3418), heading = 76.4960 },
        { coords = vector3(-1447.3141, 23.2402, 51.5750), heading = 192.1936 },
        { coords = vector3(-37.2097, -1727.6027, 28.2856), heading = 293.2387 },
        { coords = vector3(76.4134, -1381.3384, 28.2774), heading = 33.1264 },
        { coords = vector3(-652.7582, -758.3394, 24.9323), heading = 356.7576 },
    },
    vehicles = { `adder`, `blista`, `asea`, `emperor`, `fugitive` }, -- Vehicles that can be spawned for NPC bounties. Use `model_name` for models.
    weapons = { `WEAPON_PISTOL`, `WEAPON_KNIFE` }, -- Weapons that can be used by NPC bounties. Use `WEAPON_NAME` for weapons.
    chaseScenarioChances = { -- Chances for each scenario to happen after a chase. Do not delete any of these entries.
        ["fleeFoot"] = 0.6, -- Chance of the NPC fleeing on foot. 0.4 means 40% chance.
        ["meleeAttack"] = 0.3, -- Chance of the NPC fleeing in a vehicle. 0.6 means 60% chance.
        ["firearmAttack"] = 0.1, -- Chance of the NPC fleeing in a vehicle. 0.6 means 60% chance.
    },
    -- For peds, please ONLY USE "", as we need to use the ped model name to find the appropriate image name.
    characters = {
        male = {
            peds = {"g_m_y_pologoon_02", "g_m_m_armgoon_01", "g_m_y_lost_03" },
            firstnames = {"John", "Michael", "David", "James", "Robert", "William", "Joseph", "Charles", "Thomas", "Christopher", "Daniel", "Matthew", "Anthony", "Mark", "Donald", "Steven", "Paul", "Andrew", "Joshua", "Kenneth"},
        },
        female = {
            peds = {"g_f_y_vagos_01", "g_f_y_families_01", "g_f_y_ballas_01" },
            firstnames = {"Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Susan", "Jessica", "Sarah", "Karen", "Nancy", "Margaret", "Lisa", "Betty", "Dorothy", "Sandra", "Ashley", "Kimberly", "Donna", "Emily"},
        },
        lastnames = {"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez", "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin"},
    },
    riskLevels = { -- Risk levels for NPC bounties. You cannot add higher or lower risk levels. Do not delete any of these entries.
        [1] = { -- Low Risk
            -- Risk settings:
            rewardMultiplier = 0.5, -- Multiplier for rewards when setting bounties. 0.5 means 50% of the reward amount.
            riskChance = 0.6, -- Chance of the NPC being a low-risk target. 0.6 means 60% chance.
            crimes = {"Petty Theft", "Vandalism", "Public Intoxication", "Loitering", "Trespassing", "Disturbing the Peace", "Jaywalking", "Speeding"},
            -- Combat scenario chances:
            firearmAttack = 0.05, -- Chance of the NPC using a firearm attack. 0.05 means 5% chance.
            meleeAttack = 0.1, -- Chance of the NPC using a melee attack. 0.1 means 10% chance.
            fleeVehicle = 0.2, -- Chance of the NPC fleeing in a vehicle. 0.2 means 20% chance.
            fleeFoot = 0.6, -- Chance of the NPC fleeing on foot. 0.6 means 60% chance.
        },
        [2] = { -- Medium Risk
            -- Risk settings:
            rewardMultiplier = 0.75, -- Multiplier for rewards when setting bounties. 0.75 means 75% of the reward amount.
            riskChance = 0.3, -- Chance of the NPC being a medium-risk target. 0.3 means 30% chance.
            crimes = {"Assault", "Battery", "Grand Theft Auto", "Burglary", "Robbery", "Drug Possession", "Drug Trafficking", "Arson", "Kidnapping"},
            -- Combat scenario chances:
            firearmAttack = 0.1, -- Chance of the NPC using a firearm attack. 0.1 means 10% chance.
            meleeAttack = 0.2, -- Chance of the NPC using a melee attack. 0.2 means 20% chance.
            fleeVehicle = 0.4, -- Chance of the NPC fleeing in a vehicle. 0.4 means 40% chance.
            fleeFoot = 0.4, -- Chance of the NPC fleeing on foot. 0.4 means 40% chance.
        },
        [3] = { -- High Risk
            -- Risk settings:
            rewardMultiplier = 1.0, -- Multiplier for rewards when setting bounties. 1.0 means 100% of the reward amount.
            riskChance = 0.1, -- Chance of the NPC being a high-risk target. 0.1 means 10% chance.
            crimes = {"Attempted Murder", "Attempted Murder of an LEO", "Bank Robbery", "Credit Fraud"},
            -- Combat scenario chances:
            firearmAttack = 0.3, -- Chance of the NPC using a firearm attack. 0.3 means 30% chance.
            meleeAttack = 0.4, -- Chance of the NPC using a melee attack. 0.4 means 40% chance.
            fleeVehicle = 0.3, -- Chance of the NPC fleeing in a vehicle. 0.2 means 30% chance.
            fleeFoot = 0.0, -- Chance of the NPC fleeing on foot. 0.1 means 10% chance.
        },
    },
}

Config.PlayerBounties = {
    blip = {
        enabled = true, -- This helps the bounty hunter get a hint of where the player is, disable it by setting to false.
        refreshTime = 5, -- Every x seconds, refresh the area position of the bounty target.
        labelPrefix = "Bounty:", -- Prefix for the blip label. Bounty: NAME_HERE
        sprite = 378,
        color = 1,
        scale = 0.8,
        radius = { color = 1, alpha = 127, size = 400.0 }
    },
}

Config.BountyHunters = {
    backupRewardFactor = 0.5, -- This is how much is deducted from the hunter's reward and given to the person who ended up turning them in (Natural multiplayer reward). 0.0 = 0%, 1.0 = 100%
    blip = { -- This will display at each duty location.
        label = "Bottom Dollar Bounties",
        sprite = 119,
        color = 5,
        scale = 0.8,
    },
    dutyLocations = {
        -- Downtown LS (MXC Bottom Dollar Bounties MLO)
        {coords = vector3(482.6396, -922.4514, 27.1091), heading = 185.7823, blip = true},
    },
    cellLocations = {
        -- Downtown LS (MXC Bottom Dollar Bounties MLO)
        {coords = vector3(477.9416, -915.9977, 26.4090), heading = 90.8748},
    },
    loadout = {
        {name = "WEAPON_STUNGUN", loadoutType = "weapon"},
    },
    outfits = {
        male = {
            ['bproof_1'] = 63,
            ['bproof_2'] = 0,
        },
        female = {
            ['bproof_1'] = 63,
            ['bproof_2'] = 0,
        }
    },
    permissions = {
        ignorePermissions = true, -- Set to true to allow anyone to become a bounty hunter.
        jobs = {
            ["bountyhunter"] = 0, -- Any person with the job bountyhunter can accept bounties at rank 0 and above.
        }
    }
}

Config.BailOfficers = {
    maximumBailLength = 7, -- Maximum days the person will be out on bail. If they comply with all 7 days, they will be released from bail.
    maximumBailAmount = 10000, -- Maximum bail amount that can be set.
    bountyRewardMultiplier = 0.85, -- Multiplier for bounty rewards when setting bail. 0.85 means 85% of the bail amount.
    custodyRewardFactor = 1.5, -- This is how much the reward amount given to bounty hunters is multiplied for turning over a bounty to a bail officer.
    custodyRewardOfficer = 500, -- This is the amount given to the officer for turning over a bounty.
    permissions = {
        placement = {
            jobs = {
                ["police"] = 0, -- Any person with the job police can place bails and see ankle monitors at rank 0 and above.
            }
        },
        management = {
            jobs = {
                ["police"] = 4, -- Any person with the job police can revoke / clear bails at rank 4 and above.
            }
        }
    }
}

Config.Bail = {
    notifyTime = 24, -- When there is (x) hours left, notify the player with a warning to visit the parole officer once every (reminderInterval) minutes.
    reminderInterval = 30, -- When notifying while under (notifyTime), do it every (x) minutes.
    tracker = {
        removal = {
            enabled = true,
            command = "removetracker", -- Command to remove the tracker.
            weapons = { "WEAPON_KNIFE", "WEAPON_SWITCHBLADE" } -- Weapons that can be used to remove the tracker.
        },
        onTrackerRemoval = { -- This will trigger the below callback if the player removes the tracker.
            client = function(data)
                -- Client-side function to run when the tracker is removed.
                -- Use this for alerts, notifications, etc.
                -- data: { coords = vector3(x, y, z), name = "Character Name", source = playerId, identifier = "char1:blahblahblah" }
            end,
            server = function(data)
                -- Server-side function to run when the tracker is removed.
                -- Use this for alerts, notifications, etc.
                -- data: { coords = vector3(x, y, z), name = "Character Name", source = playerId, identifier = "char1:blahblahblah" }
            end
        },
        blip = {
            color = 5,
            sprite = 459,
            scale = 0.8,
            label = "Ankle Monitor",
        },
        prop = {
            boneId = 0xCC4D,
            model = `prop_ar_ring_01`,
            offset = vector3(0.01, 0.05, -0.005),
            rotation = vector3(-180.0, 90.0, 90.0),
        }
    },
    paroleOfficers = {
        { 
            coords = vector3(447.2832, -973.2751, 30.6893),
            heading = 190.4484,
            model = {hash = "s_m_y_cop_01", modelType = "ped", animation = { dict = "timetable@ron@ig_5_p3", name = "ig_5_p3_base" } },
            blip = {
                enabled = true,
                label = "Parole Office",
                sprite = 475,
                color = 5,
                scale = 0.8,
            }
        }
    },
    paroleMissions = {
        {
            label = "Littering Cleanup",
            description = "(%s / %s) Clean up the streets by picking up litter.", -- TWO %s IS REQUIRED. You must use the first %s for the current progress and the second %s for the total progress.
            pointsRequired = 5, -- Amount of points required to complete the mission. This will be overrided if over the amount of points in the points table.
            blip = { 
                enabled = true,
                label = "Parole Requirement: Litter Cleanup", 
                category = 1,
                coords = vector3(6.7037, -154.8534, 56.2178), 
                sprite = 318, 
                color = 5, 
                scale = 0.8,
                radius = { color = 5, alpha = 127, size = 20.0} 
            },
            points = {
                { label = "Pickup Litter", coords = vector3(7.7405, -159.0079, 56.1640), zOffset = 1.0, heading = 247.1249, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(25.2710, -163.0202, 55.7089), zOffset = 1.0, heading = 249.9383, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(16.3565, -162.8304, 55.9348), zOffset = 1.0, heading = 75.0355, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(12.5163, -161.8073, 56.0322), zOffset = 1.0, heading = 247.1249, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(6.7037, -154.8534, 56.2178), zOffset = 1.0, heading = 249.9383, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(-0.2918, -156.1621, 56.3658), zOffset = 1.0, heading = 75.0355, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(-7.0962, -153.0651, 56.5264), zOffset = 1.0, heading = 247.1249, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(-18.0787, -150.7282, 56.7860), zOffset = 1.0, heading = 249.9383, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(-26.2488, -146.7720, 56.9589), zOffset = 1.0, heading = 75.0355, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
                { label = "Pickup Litter", coords = vector3(-33.0669, -141.5078, 57.1016), zOffset = 1.0, heading = 75.0355, model = { hash = `prop_rub_litter_05`, modelType = "prop" } },
            },
            pointAction = function(pointData)
                -- Return true if the point action is successful. Return false if the point action is not successful.
                local ped = PlayerPedId()
                PlayAnim(ped, "random@domestic", "pickup_low", 8.0, -8.0, -1, 1, 0, 0, 0, 0)
                Wait(700)
                SetTimeout(700, function()
                    ClearPedTasks(ped)
                end)
                return true
            end
        },
    }
}