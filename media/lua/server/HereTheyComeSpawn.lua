
function HTC_spawnZombieAt(player, spawnLocationX, spawnLocationY, outfit)
    local zombies = addZombiesInOutfit(spawnLocationX, spawnLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
    for i = 1, zombies:size() do
        local zombie = zombies:get(i - 1)
        local zData = zombie:getModData()
        zData.isHordeZombie = true
        zData.x = player:getCurrentSquare():getX()
        zData.y = player:getCurrentSquare():getY()
        zData.z = player:getCurrentSquare():getZ()
        zombie:setTarget(player)
        zombie:spotted(player, true)
        zombie:pathToCharacter(player)
    end
    return zombies
end

function HTC_spawnZombiesForPlayer(player, baseAngle, minSpawnRange, maxSpawnRange, numZombies, available_outfits)
    local MAX_ATTEMPTS = 100;
    local spawnLocationX = 0;
    local spawnLocationY = 0;
    local spawnCount = 0;

    local playerLocation = player:getCurrentSquare()
    if playerLocation == nil then
        return
    end
    for _ = 0, math.max(MAX_ATTEMPTS, numZombies) do
        local offsetAngle = ZombRand(SandboxVars.HereTheyCome.HordeDirectionMaxAngle) - SandboxVars.HereTheyCome.HordeDirectionMaxAngle / 2
        local offsetRange = ZombRand(maxSpawnRange - minSpawnRange)
        local pos = HTC_getPointOnCircle(playerLocation:getX(), playerLocation:getY(), baseAngle + offsetAngle, minSpawnRange + offsetRange)
        spawnLocationX = pos.x
        spawnLocationY = pos.y
        local spawnSpace = getWorld():getCell():getGridSquare(spawnLocationX, spawnLocationY, 0);
        print("Searching spawn location for zombie "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
        if spawnSpace ~= nil then
            local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
            if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil and spawnCount < numZombies then
                local selectedOutfits = HTC_getSpawnOutfit(spawnLocationX, spawnLocationY, available_outfits)
                local outfit = selectedOutfits[ZombRand(#selectedOutfits) + 1]
                print("Spawning zombie of type "..outfit.." at location "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
                HTC_spawnZombieAt(player, spawnLocationX, spawnLocationY, outfit)
                spawnCount = spawnCount + 1
            end
        end
    end
end