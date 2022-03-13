function HTC_getRandomDistancePointFrom(x, y, distance)
    local newX = x + ZombRand(2 * distance) - distance;
    local newY = y + ZombRand(2 * distance) - distance;
    return {
        x = newX,
        y = newY
    }
end

function HTC_getPointOnCircle(x, y, angle, distance)
    return {
        x = x + math.cos(math.rad(angle)) * distance,
        y = y + math.sin(math.rad(angle)) * distance
    }
end

function HTC_spawnZombieAt(spawnLocationX, spawnLocationY, outfit)
    print("Success finding a place for zombie to spawn. x: " .. tostring(spawnLocationX) .. " y: " .. tostring(spawnLocationY))
    local zombies = addZombiesInOutfit(spawnLocationX, spawnLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
    for i = 1, zombies:size() do
        local zombie = zombies:get(i - 1)
        -- local zombieModData = zombies:get(i-1).getModData().getOrCreate(HTC_State)
        zombie:pathToCharacter(player)
    end
    return zombies
end

function HTC_spawnZombieForPlayer(fromX, fromY, baseAngle, minSpawnRange, maxSpawnRange, available_outfits)
    local MAX_ATTEMPTS = 100;
    local spawnLocationX = 0;
    local spawnLocationY = 0;
    local validSpawnFound = false;

    for _ = 0, MAX_ATTEMPTS do
        local offsetAngle = ZombRand(SandboxVars.HereTheyCome.HordeDirectionMaxAngle) - SandboxVars.HereTheyCome.HordeDirectionMaxAngle / 2
        local offsetRange = ZombRand(maxSpawnRange - minSpawnRange)
        print("Effective Spawn Angle:"..tostring(baseAngle + offsetAngle))
        local pos = HTC_getPointOnCircle(fromX, fromY, baseAngle + offsetAngle, minSpawnRange + offsetRange)
        spawnLocationX = math.floor(pos.x)
        spawnLocationY = math.floor(pos.y)
        local spawnSpace = getWorld():getCell():getGridSquare(spawnLocationX, spawnLocationY, 0);
        print("Searching spawn location for zombie "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
        if spawnSpace then
            local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
            if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
                validSpawnFound = true;
                break
            end
        end
    end
    if validSpawnFound == true then
        print(#available_outfits)
        local outfit = available_outfits[ZombRand(#available_outfits) + 1]
        print("Spawning zombie of type "..outfit.." at location "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
        HTC_spawnZombieAt(spawnLocationX, spawnLocationY, outfit)

    end
end
