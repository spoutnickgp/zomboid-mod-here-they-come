function HTC_get_spawn_outfit(x, y, available_outfits)
    local zone = getZone(x, y, 0)
    local zoneType = "default"
    if zone ~= nil then
        zoneType = getZone(x, y, 0):getType()
    end
    if zoneType == "DeepForest" then
        return available_outfits.DeepForest
    end
    if zoneType == "TownZone" then
        return available_outfits.TownZone
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