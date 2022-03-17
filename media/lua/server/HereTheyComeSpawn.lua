
function HTC_spawnZombieAt(player, spawnLocationX, spawnLocationY, outfit)
    print("Success finding a place for zombie to spawn. x: " .. tostring(spawnLocationX) .. " y: " .. tostring(spawnLocationY))
    local zombies = addZombiesInOutfit(spawnLocationX, spawnLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
    for i = 1, zombies:size() do
        local zombie = zombies:get(i - 1)
        -- local zombieModData = zombies:get(i-1).getModData().getOrCreate(HTC_State)
        zombie:pathToCharacter(player)
    end
    return zombies
end

function HTC_spawnZombieForPlayer(player, baseAngle, minSpawnRange, maxSpawnRange, available_outfits)
    local MAX_ATTEMPTS = 100;
    local spawnLocationX = 0;
    local spawnLocationY = 0;
    local validSpawnFound = false;

    for _ = 0, MAX_ATTEMPTS do
        local offsetAngle = ZombRand(SandboxVars.HereTheyCome.HordeDirectionMaxAngle) - SandboxVars.HereTheyCome.HordeDirectionMaxAngle / 2
        local offsetRange = ZombRand(maxSpawnRange - minSpawnRange)
        local pos = HTC_getPointOnCircle(player:getCurrentSquare():getX(), player:getCurrentSquare():getY(), baseAngle + offsetAngle, minSpawnRange + offsetRange)
        spawnLocationX = pos.x
        spawnLocationY = pos.y
        local spawnSpace = getWorld():getCell():getGridSquare(spawnLocationX, spawnLocationY, 0);
        print("Searching spawn location for zombie "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
        if spawnSpace ~= nil then
            local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
            if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
                validSpawnFound = true;
                break
            end
        end
    end
    if validSpawnFound == true then
        local selectedOutfits = HTC_getSpawnOutfit(spawnLocationX, spawnLocationY, available_outfits)
        local outfit = selectedOutfits[ZombRand(#selectedOutfits) + 1]
        print("Spawning zombie of type "..outfit.." at location "..tostring(spawnLocationX)..", "..tostring(spawnLocationY))
        HTC_spawnZombieAt(player, spawnLocationX, spawnLocationY, outfit)
    end
end