require "HereTheyComeConfig"
require "HereTheyComeSpawn"
require "HereTheyComeHelpers"

local HTC_STATE_KEY = "HTC_State"

local function HTC_Setup()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if data.HordeActive == nil then
        data.HordeActive = false
    end
    if data.HordeAngle == nil then
        data.HordeAngle = 0
    end
    if data.HordeIntensity == nil then
        data.HordeIntensity = 0
    end
    if data.HordeNumber == nil then
        data.HordeNumber = 1
    end
    if data.HordeProgress == nil then
        data.HordeProgress = 0
    end
end

local function HTC_getDaysSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) + 7.0 / 24.0
end

local function HTC_getHoursSinceGameStart()
    return math.max(0.0, getWorld():getWorldAgeDays() - (getSandboxOptions():getTimeSinceApo() - 1) * 30) * 24.0 + 7.0
end

local function HTC_isWithinHordeTime()
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

local function HTC_isHordeCooldown(last_end_time)
    if last_end_time == nil then
        return false
    end
    local now = HTC_getHoursSinceGameStart() * 60
    print("Last time: " .. tostring(time) .. ", Cooldown:" .. tostring(SandboxVars.HereTheyCome.HordeCooldown) .. ", Now:" .. tostring(now))
    return last_end_time + SandboxVars.HereTheyCome.HordeCooldown > now
end

local function HTC_isHordePossible(last_end_time)
    return HTC_isWithinHordeTime() and HTC_isHordeCooldown(last_end_time) == false
end

local function HTC_startHorde(data)

    print("Starting Here They Come horde...")
    data.HordeActive = true;
    data.HordeAngle = ZombRand(360)
    data.HordeIntensity = ZombRand(100)
    data.HordeTick = 0;

    local hordeZombieCount = SandboxVars.HereTheyCome.HordeMinZombieCount + data.HordeIntensity * SandboxVars.HereTheyCome.HordeZombieIncrement * data.HordeNumber / 100
    data.HordeZombiesRemaining = math.floor(math.min(hordeZombieCount, SandboxVars.HereTheyCome.HordeMaxZombieCount))

    local players = getOnlinePlayers()
    for i = 0, players:size() - 1 do
        local player = players:get(i)
        if player ~= nil then
            local playerLocation = player:getCurrentSquare()
            if playerLocation ~= nil then
                local hordeOrigin = HTC_getPointOnCircle(playerLocation:getX(), playerLocation:getY(),
                        data.HordeAngle, SandboxVars.HereTheyCome.HordeMinSpawnDistance)
                print("Sending HTCHordeStart to player @ "..tostring(hordeOrigin))
                local hordeOriginLocation = getWorld():getCell():getGridSquare(hordeOrigin.x, hordeOrigin.y, 0);

                if SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
                    getWorldSoundManager():addSound(player, hordeOrigin.x, hordeOrigin.y, 0, SandboxVars.HereTheyCome.HordeMaxSpawnDistance, 10);
                    getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(), SandboxVars.HereTheyCome.PulseRange, 10);
                -- getSoundManager():PlayWorldSoundWav("event_sound_02", playerLocation, 1.0, 400.0, 200.0, false);
                end
                local hordeData = {
                    event_location_X = hordeOrigin.x,
                    event_location_Y = hordeOrigin.y,
                    intensity = data.HordeIntensity,
                    number =  data.HordeNumber,
                    angle = data.HordeAngle,
                    target_zombie_count = data.HordeZombiesRemaining
                }
            sendServerCommand(player, "HTCmodule", "HTCHordeStart", hordeData)
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

local function HTC_HordeProgress()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    local params = {
        onoff = data.HordeActive,
        progress = data.HordeProgress,
        threshold = SandboxVars.HereTheyCome.HordeTriggerThreshold
    }
    -- print("Broadcasting HordeState..." .. tostring(params))
    sendServerCommand("HTCmodule", "HTCHordeState", params)
    if data.HordeActive ~= true then
        if HTC_isHordePossible(data.LastHordeEndTime) then
            local randomMargin = SandboxVars.HereTheyCome.HordeMaxHourlyProgress - SandboxVars.HereTheyCome.HordeMinHourlyProgress
            local progress = SandboxVars.HereTheyCome.HordeMinHourlyProgress + ZombRand(randomMargin)
            data.HordeProgress = data.HordeProgress + progress / 60
        end
    end
end

local function HTC_CheckHordeEligibility()
    local data = ModData.getOrCreate(HTC_STATE_KEY)

    if data.HordeActive ~= true then
        if data.HordeProgress >= SandboxVars.HereTheyCome.HordeTriggerThreshold then
            if HTC_isHordePossible(data.LastHordeEndTime) then
                print("Starting horde #"..tostring(data.HordeNumber))
                HTC_startHorde(data)
                data.HordeProgress = data.HordeProgress - SandboxVars.HereTheyCome.HordeTriggerThreshold
                data.HordeNumber = data.HordeNumber + 1
            else
                print("Could start horde, but conditions not met.")
            end
        end
    end
end

local function HTC_tick_horde_for_player(player, angle)
    local minSpawnRange = SandboxVars.HereTheyCome.HordeMinSpawnDistance
    local maxSpawnRange = SandboxVars.HereTheyCome.HordeMaxSpawnDistance
    local playerLocation = player:getCurrentSquare()
    HTC_spawnZombieForPlayer(player, angle, minSpawnRange, maxSpawnRange, HTC_SPAWN_CONFIGS)
    if SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
        getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(),
                SandboxVars.HereTheyCome.PulseRange, 10);
    end
end

local function HTC_CheckHordeStatus()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if data.HordeActive == true then
        if data.HordeZombiesRemaining > 0 then
            if data.HordeTick % SandboxVars.HereTheyCome.HordeZombieSpawnRate == 0 then
                data.HordeZombiesRemaining = data.HordeZombiesRemaining - 1
                local players = getOnlinePlayers();
                for i = 0, players:size() - 1 do
                    HTC_tick_horde_for_player(players:get(i), data.HordeAngle)
                end
                -- print("Remaining zombies to spawn:" .. tostring(data.HordeZombiesRemaining))
            end
            data.HordeTick = data.HordeTick + 1
        else
            HTC_endHorde(data, day)
        end
    end
end

if isClient() == false then
    Events.OnGameStart.Add(HTC_Setup);
    Events.EveryOneMinute.Add(HTC_HordeProgress);
    Events.EveryOneMinute.Add(HTC_CheckHordeEligibility);
    Events.OnTick.Add(HTC_CheckHordeStatus);
end