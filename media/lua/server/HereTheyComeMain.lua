-- local HTC_spawnables = {"AirCrew","AmbulanceDriver","ArmyCamoDesert","ArmyCamoGreen","ArmyServiceUniform","Bandit","BaseballFan_KY","BaseballFan_Rangers","BaseballFan_Z","BaseballPlayer_KY","BaseballPlayer_Rangers","BaseballPlayer_Z","Bathrobe","Bedroom","Biker","Bowling","BoxingBlue","BoxingRed","Camper","Chef","Classy","Cook_Generic","Cook_IceCream","Cook_Spiffos","Cyclist","Doctor","DressLong","DressNormal","DressShort","Farmer","Fireman","FiremanFullSuit","FitnessInstructor","Fossoil","Gas2Go","Generic_Skirt","Generic01","Generic02","Generic03","Generic04","Generic05","GigaMart_Employee","Golfer","HazardSuit","Hobbo","HospitalPatient","Jackie_Jaye","Joan","Jockey04","Jockey05","Kate","Kirsty_Kormick","Mannequin1","Mannequin2","Nurse","OfficeWorkerSkirt","Party","Pharmacist","Police","PoliceState","Postal","PrivateMilitia","Punk","Ranger","Redneck","Rocker","Santa","SantaGreen","ShellSuit_Black","ShellSuit_Blue","ShellSuit_Green","ShellSuit_Pink","ShellSuit_Teal","Ski Spiffo","SportsFan","StreetSports","StripperBlack","StripperPink","Student","Survivalist","Survivalist02","Survivalist03","Swimmer","Teacher","ThunderGas","TinFoilHat","Tourist","Trader","TutorialMom","Varsity","Waiter_Classy","Waiter_Diner","Waiter_Market","Waiter_PileOCrepe","Waiter_PizzaWhirled","Waiter_Restaurant","Waiter_Spiffo","Waiter_TachoDelPancho","WaiterStripper","Young","Bob","ConstructionWorker","Dean","Duke","Fisherman","Frank_Hemingway","Ghillie","Groom","HockeyPsycho","Hunter","Inmate","InmateEscaped","InmateKhaki","Jewelry","Jockey01","Jockey02","Jockey03","Jockey06","John","Judge_Matt_Hass","MallSecurity","Mayor_West_point","McCoys","Mechanic","MetalWorker","OfficeWorker","PokerDealer","PoliceRiot","Priest","PrisonGuard","Rev_Peter_Watts","Raider","Security","Sir_Twiggy","Thug","TutorialDad","Veteran","Waiter_TacoDelPancho","Woodcut"};
local HTC_spawnables = { "AirCrew" };
local HTC_stateKey = "HTC_State"

function HTC_Setup()
    local data = ModData.getOrCreate(HTC_stateKey)
    if data.HordeActive == nil then
        data.HordeActive = false
    end
end

function HTC_getDaysSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) + 7.0 / 24.0
end

function HTC_getHoursSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) * 24.0 + 7.0
end

function HTC_isWithinHordeTime()
    local age = HTC_getDaysSinceGameStart()
    local day = math.floor(age)
    local hourOfDay = getGameTime():getHour() % 24

    if day >= SandboxVars.HereTheyCome.HordeFirstDay then
        if hourOfDay >= SandboxVars.HereTheyCome.HordeMinHour and hourOfDay < SandboxVars.HereTheyCome.HordeMaxHour then
            return true
        end
    end
    return false
end

function HTC_isHordeCooldown(time)
    if time == nil then
        return true
    end
    local now = HTC_getHoursSinceGameStart() * 60
    print("Last time: " .. tostring(time) .. ", Cooldown:" .. tostring(SandboxVars.HereTheyCome.HordeCooldown) .. ", Now:" .. tostring(now))
    return time + SandboxVars.HereTheyCome.HordeCooldown < now
end

local function HTC_startHorde(data, hordeNumber)
    local hordeZombieCount = SandboxVars.HereTheyCome.HordeMinZombieCount + ZombRand(SandboxVars.HereTheyCome.HordeZombieIncrement * hordeNumber)
    local effectiveHordeZombieCount = math.min(hordeZombieCount, SandboxVars.HereTheyCome.HordeMaxZombieCount)

    print("Starting Here They Come horde...")
    data.HordeActive = true;
    data.HordeTick = 0;
    data.HordeZombiesRemaining = effectiveHordeZombieCount

    sendServerCommand("HTCmodule", "HTCHordeStart", { })
    local players = getOnlinePlayers()
    for i = 1, players:size() do
        local player = players:get(i - 1)
        if player ~= nil then
            local playerLocation = player:getCurrentSquare()
            if playerLocation ~= nil then
                local zombieOrigin = HTC_getRandomDistancePointFrom(
                        playerLocation:getX(), playerLocation:getY(),
                        SandboxVars.HereTheyCome.HordeMinSpawnDistance)
                HTC_AlarmPlayer(player, zombieOrigin)
            end
        end
    end
end

local function HTC_endHorde(data)
    print("Horde finished...")
    data.HordeActive = false
    data.LastHordeEndTime = HTC_getHoursSinceGameStart() * 60
    sendServerCommand("HTCmodule", "HTCHordeEnd", { })
end

function HTC_getRandomDistantPointFrom(x, y, distance)
    local newX = x + ZombRand(2 * distance) - distance;
    local newY = y + ZombRand(2 * distance) - distance;
    return getWorld():getCell():getGridSquare(newX, newY, 0);
end

-- When start, alarm everyone online
function HTC_AlarmPlayer(player, gridSquare)
    local rAlarmIndex = ZombRand(10);
    local rAlarmText = "IGUI_PlayerText_HNWarning0" .. tostring(rAlarmIndex);
    player:Say(getText(rAlarmText));
    local rAlarmSound = "zombierand" .. tostring(ZombRand(10));
    -- local rAlarmMusic = "zombierand"..tostring(ZombRand(10));
    local aZed = getSoundManager():playServerSound(rAlarmSound, gridSquare);
    getSoundManager():PlayAsMusic(rAlarmSound, aZed, false, 0);

    local playerLocation = player:getCurrentSquare();
    getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(), 200, 10);
    aZed:setVolume(0.1);
end

function HTC_HordeProgress()
    local data = ModData.getOrCreate(HTC_stateKey)
    if data.HordeProgress == nil then
        data.HordeProgress = 0
    end
    if data.HordeActive == nil then
        data.HordeActive = false
    end
    local params = {
        onoff = data.HordeActive,
        progress = data.HordeProgress,
        threshold = SandboxVars.HereTheyCome.HordeTriggerThreshold
    }
    print("Broadcasting HordeState..." .. tostring(params))
    sendServerCommand("HTCmodule", "HTCHordeState", params)
    if data.HordeActive ~= true then
        if HTC_isWithinHordeTime() and HTC_isHordeCooldown(data.LastHordeEndTime) then
            local randomMargin = SandboxVars.HereTheyCome.HordeMaxHourlyProgress - SandboxVars.HereTheyCome.HordeMinHourlyProgress
            local progress = SandboxVars.HereTheyCome.HordeMinHourlyProgress + ZombRand(randomMargin)
            data.HordeProgress = data.HordeProgress + progress / 60
        end
    end
end

function HTC_CheckHordeEligibility()
    local data = ModData.getOrCreate(HTC_stateKey)

    if data.HordeNumber == nil then
        data.HordeNumber = 1
    end

    if data.HordeProgress == nil then
        data.HordeProgress = 0
    end

    if data.HordeProgress >= SandboxVars.HereTheyCome.HordeTriggerThreshold then
        if HTC_isWithinHordeTime() and HTC_isHordeCooldown(data.LastHordeEndTime) then
            data.HordeProgress = data.HordeProgress - SandboxVars.HereTheyCome.HordeTriggerThreshold
            HTC_startHorde(data, data.HordeNumber)
            data.HordeNumber = data.HordeNumber + 1
        else
            print("Could start horde, but conditions not met.")
        end
    end
    -- print("Game age in days:" ..tostring(day)..", game age in hours:"..tostring(age * 24))
end

function HTC_CheckHordeStatus()
    local data = ModData.getOrCreate(HTC_stateKey)
    if data.HordeActive == true then
        if data.HordeZombiesRemaining > 0 then
            if data.HordeTick % SandboxVars.HereTheyCome.HordeZombieSpawnRate == 0 then
                data.HordeZombiesRemaining = data.HordeZombiesRemaining - 1
                local players = getOnlinePlayers();
                for i = 1, players:size() do
                    local spawnRange = SandboxVars.HereTheyCome.HordeMinSpawnDistance
                    HTC_spawnZombieForPlayer(players:get(i - 1), spawnRange)
                end
            end
            print("Remaining zombies to spawn:" .. tostring(data.HordeZombiesRemaining))
            data.HordeTick = data.HordeTick + 1
        else
            HTC_endHorde(data, day)
        end
    end
end

function HTC_spawnZombieForPlayer(player, spawnRange)
    local MAX_ATTEMPTS = 100;
    local outfit = "AirCrew"
    local playerLocation = player:getCurrentSquare();
    local spawnLocationX = 0;
    local spawnLocationY = 0;
    local validSpawnFound = false;

    if playerLocation ~= nil then
        for _ = 0, MAX_ATTEMPTS do
            spawnLocationX = playerLocation:getX() + ZombRand(2 * spawnRange) - spawnRange;
            spawnLocationY = playerLocation:getY() + ZombRand(2 * spawnRange) - spawnRange;
            local spawnSpace = getWorld():getCell():getGridSquare(spawnLocationX, spawnLocationY, 0);
            if spawnSpace then
                local isSafehouse = SafeHouse.getSafeHouse(spawnSpace);
                if spawnSpace:isSafeToSpawn() and spawnSpace:isOutside() and isSafehouse == nil then
                    validSpawnFound = true;
                    break
                end
            end
        end
    end
    if validSpawnFound == true then
        print("Success finding a place for zombie to spawn. x: " .. tostring(spawnLocationX) .. " y: " .. tostring(spawnLocationY))
        local zombies = addZombiesInOutfit(spawnLocationX, spawnLocationY, 0, 1, outfit, 50, false, false, false, false, 1.5);
        if SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
            getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(),
                    SandboxVars.HereTheyCome.PulseRange
            , 10);
        end
        for i = 1, zombies:size() do
            local zombie = zombies:get(i - 1)
            -- local zombieModData = zombies:get(i-1).getModData().getOrCreate(HTC_State)
            zombie:pathToCharacter(player)
        end
    end
end

local function HTC_onClientCommand(module, command, player, args)
    if module ~= "HTCmodule" then
        print("module is not HTCmodule");
        return
    end
    -- print("Client command: "..command)
    if command == "HTCHordeStateRequest" then

    end
end

if isClient() == false then
    Events.OnGameStart.Add(HTC_Setup);
    Events.EveryOneMinute.Add(HTC_HordeProgress);
    Events.EveryOneMinute.Add(HTC_CheckHordeEligibility);
    Events.OnTick.Add(HTC_CheckHordeStatus);
    Events.OnClientCommand.Add(HTC_onClientCommand);
end