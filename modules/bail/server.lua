BailRegistry = {}
local BailWarnings = {}

function AddBailToRegistry(bail, ignoreSync, insertSQL)
    if not bail.identifier then
        dprint("Bail missing target")
        return
    end
    if BailRegistry[bail.identifier] then
        dprint("Bail already exists for identifier: " .. bail.identifier)
        return
    end
    BailRegistry[bail.identifier] = {
        source = GetSourceFromIdentifier(bail.identifier),
        identifier = bail.identifier,
        name = bail.name,
        image = bail.image,
        issuer = bail.issuer,
        reward = bail.reward,
        description = bail.description,
        startdate = bail.startdate,
        completiondate = bail.completiondate,
        nextcompliance = bail.nextcompliance,
        lastcompliance = bail.lastcompliance,
        status = bail.status or "compliant",
    }
    if insertSQL then
        MySQL.Async.execute("INSERT INTO pickle_bailbounty_bail (identifier, name, image, issuer, reward, description, status, startdate, completiondate, nextcompliance, lastcompliance) VALUES (@identifier, @name, @image, @issuer, @reward, @description, @status, @startdate, @completiondate, @nextcompliance, @lastcompliance)", {
            ["@identifier"] = bail.identifier,
            ["@name"] = bail.name,
            ["@image"] = bail.image,
            ["@issuer"] = bail.issuer,
            ["@reward"] = bail.reward,
            ["@description"] = bail.description,
            ["@status"] = bail.status,
            ["@startdate"] = bail.startdate and os.date("%Y-%m-%d %H:%M:%S", bail.startdate) or nil,
            ["@completiondate"] = bail.completiondate and os.date("%Y-%m-%d %H:%M:%S", bail.completiondate) or nil,
            ["@nextcompliance"] = bail.nextcompliance and os.date("%Y-%m-%d %H:%M:%S", bail.nextcompliance) or nil,
            ["@lastcompliance"] = bail.lastcompliance and os.date("%Y-%m-%d %H:%M:%S", bail.lastcompliance) or nil,
        }, function(rowsChanged)
            dprint("Inserted bail into SQL: " .. rowsChanged)
        end)
    end
    if ignoreSync then return end
    TriggerClientEvent("pickle_bailbounty:addbail", -1, bail.identifier, BailRegistry[bail.identifier])
end

function RemoveBailFromRegistry(identifier, ignoreSync)
    if not BailRegistry[identifier] then
        dprint("Bail does not exist for identifier: " .. identifier)
        return
    end
    BailRegistry[identifier] = nil
    MySQL.Async.execute("DELETE FROM pickle_bailbounty_bail WHERE identifier = @identifier", {
        ["@identifier"] = identifier,
    }, function(rowsChanged)
        dprint("Deleted bail from SQL: " .. rowsChanged)
    end)
    if ignoreSync then return end
    TriggerClientEvent("pickle_bailbounty:removebail", -1, identifier, GetSourceFromIdentifier(identifier))
end

function GetBailStatus(index, params)
    local bail = BailRegistry[index]
    local extraData = {}
    if not bail then return end
    if params.onlyPlayer then
        if string.sub(bail.identifier, 1, 4) == "npc:" then return end
        if params.requireOnline then
            extraData.source = GetSourceFromIdentifier(bail.identifier)
            if not extraData.source then return end
        end
    end
    return bail, extraData
end

function DoesBailRequireCheckIn(bail)
    if not bail.nextcompliance then return false end
    return (bail.nextcompliance - os.time()) < 86400
end

function UpdateBail(identifier, bail, noSQL)
    BailRegistry[identifier] = bail
    local event = function()
        TriggerClientEvent("pickle_bailbounty:updatebail", -1, identifier, BailRegistry[identifier])
    end
    if noSQL then event() return end
    MySQL.Async.execute("UPDATE pickle_bailbounty_bail SET status = @status, startdate = @startdate, completiondate = @completiondate, nextcompliance = @nextcompliance, lastcompliance = @lastcompliance WHERE identifier = @identifier", {
        ["@identifier"] = identifier,
        ["@status"] = bail.status,
        ["@startdate"] = bail.startdate and os.date("%Y-%m-%d %H:%M:%S", bail.startdate) or nil,
        ["@completiondate"] = bail.completiondate and os.date("%Y-%m-%d %H:%M:%S", bail.completiondate) or nil,
        ["@nextcompliance"] = bail.nextcompliance and os.date("%Y-%m-%d %H:%M:%S", bail.nextcompliance) or nil,
        ["@lastcompliance"] = bail.lastcompliance and os.date("%Y-%m-%d %H:%M:%S", bail.lastcompliance) or nil,
    }, function(rowsChanged)
        event()
    end)
end

RegisterNetEvent("pickle_bailbounty:placeBail", function(data)
    local source = source
    local permissions = GetPlayerPermissions(source)
    if not permissions.bailPlacement then
        return ShowNotification(source, _L("no_permission_bailplace"))
    end
    local target = data.source
    local identifier = GetIdentifier(target)
    if not identifier then
        return ShowNotification(source, _L("no_player_near"))
    end
    if BailRegistry[identifier] then
        return ShowNotification(source, _L("bail_already_exists"))
    end
    local bail = {
        identifier = identifier,
        name = GetPlayerCharacterName(target),
        image = data.image,
        issuer = GetIdentifier(source),
        reward = data.penalty * Config.BailOfficers.bountyRewardMultiplier,
        description = data.description,
        startdate = os.time(),
        completiondate = os.time() + (data.length * 86400),
        nextcompliance = (os.time() + 86400),
        lastcompliance = os.time(),
        status = "compliant",
    }
    AddBailToRegistry(bail, false, true)
    ShowNotification(source, "Bail placed on " .. bail.name .. " for " .. NumberWithCommas(data.penalty))
end)

RegisterNetEvent('pickle_bailbounty:clearBail', function(target)
    local bail = BailRegistry[target]
    if not bail then return end
    local permissions = GetPlayerPermissions(source)
    if not permissions.bailManage then
        return ShowNotification(source, _L("no_permission_bailmanage"))
    end
    ShowNotification(source, _L("bail_cleared", bail.name))
    RemoveBailFromRegistry(target, false)
end)

RegisterNetEvent("pickle_bailbounty:revokeBail", function(target, selfRemove)
    local source = source
    if selfRemove then
        if not Config.Bail.tracker.removal.enabled then return end
        target = GetIdentifier(source)
        ShowNotification(source, _L("tracker_removed"))
        local removeData = {
            coords = GetEntityCoords(GetPlayerPed(source)), 
            name = GetPlayerCharacterName(source), 
            source = source, 
            identifier = target,
        }
        Config.Bail.tracker.onTrackerRemoval.server(removeData)
        TriggerClientEvent("pickle_bailbounty:trackerRemoved", source, removeData)
    else
        local permissions = GetPlayerPermissions(source)
        if not permissions.bailManage then
            return ShowNotification(source, _L("no_permission_bailmanage"))
        end
    end
    local bail = BailRegistry[target]
    if not bail then return end
    RemoveBailFromRegistry(target, false)
    AddBountyToRegistry({
        target = bail.identifier,
        targetname = bail.name,
        issuer = bail.issuer,
        name = bail.name,
        image = bail.image,
        reward = bail.reward,
        description = bail.description,
        datetime = os.time(),
        risk = 3,
    }, false, true)
    if not selfRemove then
        ShowNotification(source, _L("bail_revoked", bail.name))
    end
end)

RegisterNetEvent("pickle_bailbounty:completeParoleCheckin", function()
    local source = source
    local identifier = GetIdentifier(source)
    if not identifier then return end
    local bail = BailRegistry[identifier]
    if not bail then return end
    bail.lastcompliance = os.time()
    local nextDate = bail.startdate
    repeat
        nextDate = nextDate + 86400
    until nextDate > bail.lastcompliance
    bail.nextcompliance = nextDate + 86400
    bail.status = "compliant"
    UpdateBail(identifier, bail)
end)

RegisterCallback("pickle_bailbounty:getBailInfo", function(source, cb, target)
    local target = target or GetIdentifier(source)
    local bail, data = GetBailStatus(target, {onlyPlayer = true, requireOnline = true})
    if not bail then return cb() end
    cb({
        startdate = bail.startdate and os.date("%m/%d/%Y %H:%M:%S", bail.startdate) or _L("bail_registry_never"),
        completiondate = bail.completiondate and os.date("%m/%d/%Y %H:%M:%S", bail.completiondate) or _L("bail_registry_never"),
        lastcompliance = bail.lastcompliance and os.date("%m/%d/%Y %H:%M:%S", bail.lastcompliance) or _L("bail_registry_never"),
        checkIn = DoesBailRequireCheckIn(bail),
    })
end)

function GetTimeLeft(timeLeft)
    local hours = math.floor(timeLeft / 3600)
    local minutes = math.floor((timeLeft % 3600) / 60)
    return string.format(_L("time_left"), hours, minutes)
end

CreateThread(function() 
    Wait(1000)
    while true do 
        for k,v in pairs(BailRegistry) do
            local bail, data = GetBailStatus(k, {onlyPlayer = true, requireOnline = true})
            if bail then
                local currentTime = os.time()
                local nextcompliance = bail.nextcompliance
                local timeLeft = nextcompliance - currentTime
                if currentTime > nextcompliance then
                    print("BA", currentTime, nextcompliance)
                    RemoveBailFromRegistry(k)
                    AddBountyToRegistry({
                        target = bail.identifier,
                        targetname = bail.name,
                        issuer = bail.issuer,
                        name = bail.name,
                        image = bail.image,
                        reward = bail.reward,
                        description = bail.description,
                        datetime = os.time(),
                        risk = 3,
                    }, false, true)
                else
                    local notifyTime = Config.Bail.notifyTime * 3600
                    local bailWarning = BailWarnings[k] or 0
                    if timeLeft < notifyTime and os.time() > bailWarning then 
                        local formatTimeLeft = GetTimeLeft(timeLeft)
                        ShowNotification(data.source, _L("bail_registry_compliance_notice_1", formatTimeLeft))
                        ShowNotification(data.source, _L("bail_registry_compliance_notice_2"))
                        BailWarnings[k] = os.time() + (Config.Bail.reminderInterval * 60)
                    end
                end
            end
        end
        Wait(60 * 1000)
    end
end)

CreateThread(function() 
    Wait(1000)
    while true do
        local BailPlayers = {} 
        for k,v in pairs(BailRegistry) do
            local bail, data = GetBailStatus(k, {onlyPlayer = true, requireOnline = true})
            if bail then
                local ped = GetPlayerPed(data.source)
                local coords = GetEntityCoords(ped)
                BailPlayers[data.source] = {coords = coords, name = GetPlayerCharacterName(data.source)}
            end
        end
        TriggerClientEvent("pickle_bailbounty:updateBailPlayers", -1, BailPlayers)
        Wait(5000)
    end
end)