require "HereTheComeConfig"
require "HereTheComeSpawn"

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
        if hourOfDay >= SandboxVars.HereTheyCome.HordeMinHour and hourOfDay <= SandboxVars.HereTheyCome.HordeMaxHour then
            return true
        end
    end
    return false
end

function HTC_isHordeCooldown(last_end_time)
    if last_end_time == nil then
        return false
    end
    local now = HTC_getHoursSinceGameStart() * 60
    print("Last time: " .. tostring(time) .. ", Cooldown:" .. tostring(SandboxVars.HereTheyCome.HordeCooldown) .. ", Now:" .. tostring(now))
    return last_end_time + SandboxVars.HereTheyCome.HordeCooldown > now
end

function HTC_isHordePossible(last_end_time)
    return HTC_isWithinHordeTime() and HTC_isHordeCooldown(last_end_time) == false
end

local function HTC_startHorde(data, hordeNumber)
    local hordeZombieCount = SandboxVars.HereTheyCome.HordeMinZombieCount + ZombRand(SandboxVars.HereTheyCome.HordeZombieIncrement * hordeNumber)
    local effectiveHordeZombieCount = math.min(hordeZombieCount, SandboxVars.HereTheyCome.HordeMaxZombieCount)

    print("Starting Here They Come horde...")
    data.HordeActive = true;
    data.HordeTick = 0;
    data.HordeZombiesRemaining = effectiveHordeZombieCount

    data.HordeAngle = ZombRand(360)
    local players = getOnlinePlayers()
    for i = 1, players:size() do
        local player = players:get(i - 1)
        if player ~= nil then
            local playerLocation = player:getCurrentSquare()
            if playerLocation ~= nil then
                local hordeOrigin = HTC_getPointOnCircle(playerLocation:getX(), playerLocation:getY(),
                        hordeAngle, SandboxVars.HereTheyCome.HordeMinSpawnDistance)
                -- hordeOrigin = getWorld():getCell():getGridSquare(hordeOrigin.x, hordeOrigin.y, 0);
                print("Sending HTCHordeStart to player @ "..tostring(hordeOrigin))
                getWorldSoundManager():addSound(player, hordeOrigin.x, hordeOrigin.y, 0, 400, 10);
                getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(), 200, 10);
                -- getSoundManager():PlayWorldSoundWav("event_sound_02", playerLocation, 1.0, 200.0, 100.0, false);
                sendServerCommand(player, "HTCmodule", "HTCHordeStart", { event_location_X = hordeOrigin.x, event_location_Y = hordeOrigin.y })
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
        if HTC_isHordePossible(data.LastHordeEndTime) then
            print("Checking horde progress...")
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
        if HTC_isHordePossible(data.LastHordeEndTime) then
            print("Starting horde #"..tostring(data.HordeNumber))
            HTC_startHorde(data, data.HordeNumber)
            data.HordeProgress = data.HordeProgress - SandboxVars.HereTheyCome.HordeTriggerThreshold
            data.HordeNumber = data.HordeNumber + 1
        else
            print("Could start horde, but conditions not met.")
        end
    end
end

local function HTC_tick_horde_for_player(player, angle)
    local minSpawnRange = SandboxVars.HereTheyCome.HordeMinSpawnDistance
    local maxSpawnRange = SandboxVars.HereTheyCome.HordeMaxSpawnDistance
    local playerLocation = player:getCurrentSquare()
    HTC_spawnZombieForPlayer(playerLocation:getX(), playerLocation:getY(), angle, minSpawnRange, maxSpawnRange, HTC_SPAWN_CONFIGS)
    if SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
        getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(),
                SandboxVars.HereTheyCome.PulseRange, 10);
    end
end

function HTC_CheckHordeStatus()
    local data = ModData.getOrCreate(HTC_stateKey)
    if data.HordeActive == true then
        if data.HordeZombiesRemaining > 0 then
            if data.HordeTick % SandboxVars.HereTheyCome.HordeZombieSpawnRate == 0 then
                data.HordeZombiesRemaining = data.HordeZombiesRemaining - 1
                local players = getOnlinePlayers();
                for i = 1, players:size() do
                    HTC_tick_horde_for_player(players:get(i - 1), data.HordeAngle)
                end
                print("Remaining zombies to spawn:" .. tostring(data.HordeZombiesRemaining))
            end
            data.HordeTick = data.HordeTick + 1
        else
            HTC_endHorde(data, day)
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