function HTC_getDaysSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) + 7.0 / 24.0
end

function HTC_getHoursSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) * 24.0 + 7.0
end

function HTC_getSpawnOutfit(x, y, available_outfits)
    local zone = getZone(x, y, 0)
    local zoneType = "default"
    if zone ~= nil then
        zoneType = getZone(x, y, 0):getType()
    end
    if zoneType == "Nav" then
        return available_outfits.Nav
    end
    if zoneType == "Forest" then
        return available_outfits.Forest
    end
    if zoneType == "DeepForest" then
        return available_outfits.DeepForest
    end
    if zoneType == "TownZone" then
        return available_outfits.TownZone
    end
    if zoneType == "Farm" then
        return available_outfits.Farm
    end
    if zoneType == "Vegitation" then
        return available_outfits.Vegitation
    end
    if zoneType == "TrailerPark" then
        return available_outfits.TrailerPark
    end
    return available_outfits.Default
end

function HTC_getPointOnCircle(x, y, angle, distance)
    return {
        x = math.floor(x + math.cos(math.rad(angle)) * distance),
        y = math.floor(y + math.sin(math.rad(angle)) * distance)
    }
end

function HTC_getDirectionFromAngle(angle)
    return "DIR_" .. tostring(math.floor(angle % 360 / 8))
end

function HTC_getNumPlayers()
    if isServer() then
        local players = getOnlinePlayers();
        return players:size()
    else
        return 1
    end
end

function HTC_callForEachPlayer(callable, data)
    if isServer() then
        local players = getOnlinePlayers();
        for i = 0, players:size() - 1 do
            callable(players:get(i), data)
        end
    else
        callable(getPlayer(), data)
    end
end