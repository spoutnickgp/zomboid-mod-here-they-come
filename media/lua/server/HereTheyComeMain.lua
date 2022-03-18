require "HereTheyComeConfig"
require "HereTheyComeSpawn"
require "HereTheyComeHelpers"

local HTC_STATE_KEY = "HTC_State"

local function HTC_ServerSetup()
    print("Setup Server Defaults for Horde Mode")
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if SandboxVars.HereTheyCome.HordeZombieWarnTime == nil then
        SandboxVars.HereTheyCome.HordeZombieWarnTime = 60
    end
    if data.HordeWarmup == nil then
        data.HordeWarmup = false
    end
    if data.CurrentHordeStartTime == nil then
        data.CurrentHordeStartTime = HTC_getHoursSinceGameStart() * 60
    end
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
    if data.HordeTick == nil then
        data.HordeTick = 0
    end
    if data.LastHordeEndTime == nil then
        data.LastHordeEndTime = -SandboxVars.HereTheyCome.HordeCooldown
    end
end

local function HTC_sendCommand(player, module, command, params)
    if isServer() == true then
        if player ~= nil then
            sendServerCommand(player, module, command, params)
        else
            sendServerCommand(module, command, params)
        end
    else
        sendClientCommand(module, command, params)
    end
end

local function HTC_broadcastCommand(module, command, params)
    HTC_sendCommand(nil, module, command, params)
end

local function HTC_unicastCommand(player, module, command, params)
    HTC_sendCommand(player, module, command, params)
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
    return last_end_time + SandboxVars.HereTheyCome.HordeCooldown > now
end

local function HTC_isHordePossible(last_end_time)
    return HTC_isWithinHordeTime() and HTC_isHordeCooldown(last_end_time) == false
end

local function HTC_CheckHordeEligibility()
    local data = ModData.getOrCreate(HTC_STATE_KEY)

    if data.HordeActive ~= true then
        if data.HordeProgress >= SandboxVars.HereTheyCome.HordeTriggerThreshold then
            --print("Last time: " .. tostring(data.LastHordeEndTime) ..
            --        ", Cooldown:" .. tostring(SandboxVars.HereTheyCome.HordeCooldown) ..
            --        ", Now:" .. tostring(HTC_getHoursSinceGameStart()))
            if HTC_isHordePossible(data.LastHordeEndTime) then
                HTC_startHorde(data)
                data.HordeProgress = data.HordeProgress - SandboxVars.HereTheyCome.HordeTriggerThreshold
                data.HordeNumber = data.HordeNumber + 1
                --else
                --  print("Could start horde, but conditions not met.")
            end
        end
    end
end

local function HTC_warnPlayer(player, data)
    local hordeData = {
        intensity = data.HordeIntensity,
        number = data.HordeNumber,
        angle = data.HordeAngle,
        target_zombie_count = data.HordeZombiesRemaining
    }
    HTC_unicastCommand(player, "HTCmodule", "HTCHordeWarn", hordeData)
end

local function HTC_startHordeForPlayer(player, data)
    if player ~= nil then
        local playerLocation = player:getCurrentSquare()
        if playerLocation ~= nil then
            local hordeOrigin = HTC_getPointOnCircle(playerLocation:getX(), playerLocation:getY(),
                    data.HordeAngle, SandboxVars.HereTheyCome.HordeMinSpawnDistance)
            getWorldSoundManager():addSound(player, hordeOrigin.x, hordeOrigin.y, 0, SandboxVars.HereTheyCome.HordeMaxSpawnDistance, 100);
            local hordeData = {
                event_location_X = hordeOrigin.x,
                event_location_Y = hordeOrigin.y,
                intensity = data.HordeIntensity,
                number = data.HordeNumber,
                angle = data.HordeAngle,
                target_zombie_count = data.HordeZombiesRemaining
            }
            HTC_unicastCommand(player, "HTCmodule", "HTCHordeStart", hordeData)
        end
    end
end

function HTC_startHorde(data)
    print("Starting Here they Come horde #" .. tostring(data.HordeNumber))
    data.HordeWarmup = true;
    data.HordeAngle = ZombRand(360);
    data.HordeIntensity = ZombRand(100);
    data.HordeTick = 0;
    data.CurrentHordeStartTime = HTC_getHoursSinceGameStart() * 60
    data.HordeActive = true;

    local hordeZombieCount = SandboxVars.HereTheyCome.HordeMinZombieCount + data.HordeIntensity * SandboxVars.HereTheyCome.HordeZombieIncrement * data.HordeNumber / 100
    data.HordeZombiesRemaining = math.floor(math.min(hordeZombieCount, SandboxVars.HereTheyCome.HordeMaxZombieCount))
    HTC_callForeEachPlayer(HTC_warnPlayer, data)
end

local function HTC_endHorde(data)
    print("Horde finished...")
    data.HordeWarmup = true
    data.HordeActive = false
    data.LastHordeEndTime = HTC_getHoursSinceGameStart() * 60
    HTC_broadcastCommand("HTCmodule", "HTCHordeEnd", { })
end

local function HTC_HordeProgress()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    local params = {
        onoff = data.HordeActive,
        progress = data.HordeProgress,
        threshold = SandboxVars.HereTheyCome.HordeTriggerThreshold
    }
    -- print("Broadcasting HordeState...")
    HTC_broadcastCommand("HTCmodule", "HTCHordeState", params)
    if data.HordeActive ~= true then
        if HTC_isHordePossible(data.LastHordeEndTime) then
            local randomMargin = SandboxVars.HereTheyCome.HordeMaxHourlyProgress - SandboxVars.HereTheyCome.HordeMinHourlyProgress
            local progress = SandboxVars.HereTheyCome.HordeMinHourlyProgress + ZombRand(randomMargin)
            data.HordeProgress = data.HordeProgress + progress / 60
        end
    end
end

local function HTC_pulseOnPlayer(player, range)
    local playerLocation = player:getCurrentSquare()
    if playerLocation ~= nil and SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
        getWorldSoundManager():addSound(player, playerLocation:getX(), playerLocation:getY(), playerLocation:getZ(), range, 100);
    end
end

local function HTC_tickHordeForPlayer(player, data)
    local minSpawnRange = SandboxVars.HereTheyCome.HordeMinSpawnDistance
    local maxSpawnRange = SandboxVars.HereTheyCome.HordeMaxSpawnDistance
    HTC_spawnZombieForPlayer(player, data.HordeAngle, minSpawnRange, maxSpawnRange, HTC_SPAWN_CONFIGS)
    if data.HordeTick % SandboxVars.HereTheyCome.PulseFrequency == 0 then
        HTC_pulseOnPlayer(player, SandboxVars.HereTheyCome.PulseRange)
    end
end

local function HTC_CheckHordeStatus()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if data.HordeActive == true then
        if data.HordeZombiesRemaining > 0 then
            if data.HordeWarmup then
                local now = HTC_getHoursSinceGameStart() * 60
                if data.CurrentHordeStartTime + SandboxVars.HereTheyCome.HordeZombieWarnTime <= now then
                    data.HordeWarmup = false
                    HTC_callForeEachPlayer(HTC_startHordeForPlayer, data)
                end
            else
                if data.HordeTick % SandboxVars.HereTheyCome.HordeZombieSpawnRate == 0 then
                    data.HordeZombiesRemaining = data.HordeZombiesRemaining - 1
                    HTC_callForeEachPlayer(HTC_tickHordeForPlayer, data)
                    print("Remaining zombies to spawn:" .. tostring(data.HordeZombiesRemaining))
                end
            end
            data.HordeTick = data.HordeTick + 1
        else
            HTC_endHorde(data, day)
        end
    end
end

if isClient() == false then
    print("Loading Here They Come server module hooks (server_mode: " .. tostring(isServer()) .. ")...")
    Events.OnGameStart.Add(HTC_ServerSetup);
    Events.OnGameTimeLoaded.Add(HTC_ServerSetup);
    -- Events.OnServerStarted.Add(HTC_ServerSetup);
    Events.EveryOneMinute.Add(HTC_HordeProgress);
    Events.EveryOneMinute.Add(HTC_CheckHordeEligibility);
    Events.OnTick.Add(HTC_CheckHordeStatus);
end