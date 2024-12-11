function GetAllPlayers(source, ignoreSelf)
    local players = {}
    for _, player in ipairs(GetPlayers()) do
        if not source or not ignoreSelf or tonumber(player) ~= tonumber(source) then
            table.insert(players, {
                source = tonumber(player),
                identifier = GetIdentifier(player),
                name = GetPlayerCharacterName(player),
            })
        end
    end
    return players
end

function GetPlayerPermissions(source)
    return {
        bountyHunter = CheckPermission(source, Config.BountyHunters.permissions),
        bailPlacement = CheckPermission(source, Config.BailOfficers.permissions.placement),
        bailManage = CheckPermission(source, Config.BailOfficers.permissions.management),
    }
end

function ResyncPermissions(source)
    local permissions = GetPlayerPermissions(source)
    TriggerClientEvent("pickle_bailbounty:resyncPermissions", source, permissions)
end

function GetExtraQueries(source, extraQueries)
    local queries = {}
    if extraQueries["nearbyPlayers"] then
        queries["nearbyPlayers"] = GetNearbyPlayers(source)
    end
    return queries
end

function GetNearbyPlayers(source)
    local players = GetAllPlayers(source, true)
    local nearbyPlayers = {}
    local sourceCoords = GetEntityCoords(GetPlayerPed(source))
    for i=1, #players do 
        local target = players[i].source
        local targetCoords = GetEntityCoords(GetPlayerPed(target))
        local distance = #(sourceCoords - targetCoords)
        if distance < 5.0 and tonumber(target) ~= tonumber(source) then
            table.insert(nearbyPlayers, players[i])
        end
    end
    return nearbyPlayers
end

RegisterCallback("pickle_bailbounty:getPlayers", function(source, cb, ignoreSelf)
    cb(GetAllPlayers(source, ignoreSelf))
end)

RegisterCallback("pickle_bailbounty:getNearbyPlayers", function(source, cb)
    cb(GetNearbyPlayers(source))
end)

RegisterCallback("pickle_bailbounty:getPermissions", function(source, cb, extraQueries)
    local permissions = GetPlayerPermissions(source)
    cb(permissions, GetExtraQueries(source, extraQueries))
end)

RegisterNetEvent("pickle_bailbounty:initializePlayer", function()
    local identifier = GetIdentifier(source)
    local bail = BailRegistry[identifier]
    if bail then
        bail.source = source
        UpdateBail(identifier, bail, true)
    end
    local bounty = BountyRegistry[identifier]
    if bounty then
        bounty.source = source
        UpdateBounty(identifier, bounty)
    end
    TriggerClientEvent("pickle_bailbounty:initializePlayer", source, {
        identifier = GetIdentifier(source),
        bounties = BountyRegistry,
        bailRegistry = BailRegistry,
        permissions = GetPlayerPermissions(source),
    })
end)

AddEventHandler("weaponDamageEvent", function(sender, data)
    if not Config.TazerPermissions.enabled then return end
    if data.weaponType == 911657153 or data.weaponType == GetHashKey("WEAPON_STUNGUN") then
        if CheckPermission(tonumber(sender), Config.TazerPermissions) then
            return
        end
        if not BountyHunters[tonumber(sender)] then
            return CancelEvent()
        end
        local ped = GetPlayerPed(tonumber(sender))
        local coords = GetEntityCoords(ped)
        local currentBounty = nil
        for k,v in pairs(BountyInfo) do
            local target
            if v.source then
                target = GetPlayerPed(v.source)
            elseif v.netId then
                target = NetworkGetEntityFromNetworkId(v.netId)
                local targetCoords = GetEntityCoords(target)
                local distance = #(coords - targetCoords)
                print(source, distance)
                if distance < 10.0 then 
                    currentBounty = v
                end
            end
        end
        if not currentBounty then return CancelEvent() end
    end
end)

MySQL.ready(function()
    MySQL.Sync.execute([[CREATE TABLE IF NOT EXISTS pickle_bailbounty_bounties (
        target VARCHAR(255) PRIMARY KEY NOT NULL,
        targetname VARCHAR(255) NOT NULL,
        image VARCHAR(255) NOT NULL,
        issuer VARCHAR(255) NOT NULL,
        reward INT NOT NULL,
        description TEXT NOT NULL,
        datetime DATETIME DEFAULT CURRENT_TIMESTAMP,
        sentence INT DEFAULT 0
    )]], {})
    MySQL.Sync.execute([[CREATE TABLE IF NOT EXISTS pickle_bailbounty_bail (
        identifier VARCHAR(255) PRIMARY KEY NOT NULL,
        name VARCHAR(255) NOT NULL,
        image VARCHAR(255) NOT NULL,
        issuer VARCHAR(255) NOT NULL,
        reward INT NOT NULL,
        description TEXT NOT NULL,
        status VARCHAR(255) DEFAULT 'compliant',
        startdate DATETIME DEFAULT CURRENT_TIMESTAMP,
        completiondate DATETIME NOT NULL,
        nextcompliance DATETIME DEFAULT NULL,
        lastcompliance DATETIME DEFAULT NULL,
        sentence INT DEFAULT 0
    )]], {})
    MySQL.Async.fetchAll("SELECT * FROM pickle_bailbounty_bounties", {}, function(bounties)
        for _, bounty in ipairs(bounties) do
            AddBountyToRegistry({
                target = bounty.target,
                targetname = bounty.targetname,
                image = bounty.image,
                issuer = bounty.issuer,
                reward = bounty.reward,
                description = bounty.description,
                datetime = bounty.datetime and math.floor(bounty.datetime / 1000) or nil,
                sentence = bounty.sentence,
            }, true)
        end
    end)
    MySQL.Async.fetchAll("SELECT * FROM pickle_bailbounty_bail", {}, function(bail)
        for _, bail in ipairs(bail) do
            AddBailToRegistry({
                identifier = bail.identifier,
                name = bail.name,
                image = bail.image,
                issuer = bail.issuer,
                reward = bail.reward,
                description = bail.description,
                status = bail.status,
                startdate = bail.startdate and math.floor(bail.startdate / 1000) or nil,
                completiondate = bail.completiondate and math.floor(bail.completiondate / 1000) or nil,
                nextcompliance = bail.nextcompliance and math.floor(bail.nextcompliance / 1000) or nil,
                lastcompliance = bail.lastcompliance and math.floor(bail.lastcompliance / 1000) or nil,
                sentence = bail.sentence
            }, true)
        end
    end)
end)