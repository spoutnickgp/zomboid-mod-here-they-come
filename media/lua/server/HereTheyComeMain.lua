require "HereTheyComeConfig"
require "HereTheyComeSpawn"
require "HereTheyComeHelpers"

local HTC_STATE_KEY = "HTC_State"
local PULSE_VOLUME = 400

local function HTC_ServerSetup()
    print("Setup Server Defaults for Horde Mode")
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if SandboxVars.HereTheyCome.HordeWarnTime == nil then
        SandboxVars.HereTheyCome.HordeWarnTime = 60
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

local function HTC_sendCommandToPlayer(player, data, command)
    local hordeData = {
        intensity = data.HordeIntensity,
        horde_number = data.HordeNumber,
        wave_number = data.HordeWave,
        angle = data.HordeAngle,
        onoff = data.HordeActive,
        progress = data.HordeProgress,
        threshold = SandboxVars.HereTheyCome.HordeTriggerThreshold
    }
    HTC_unicastCommand(player, "HTCmodule", command, hordeData)
end

local function HTC_sendWarnToPlayer(player, data)
    HTC_sendCommandToPlayer(player, data, "HTCHordeWarn")
end

local function HTC_sendStartToPlayer(player, data)
    HTC_sendCommandToPlayer(player, data, "HTCHordeStart")
end

local function HTC_sendStateToPlayer(player, data)
    HTC_sendCommandToPlayer(player, data, "HTCHordeState")
end

local function HTC_sendEndToPlayer(player, data)
    HTC_sendCommandToPlayer(player, data, "HTCHordeEnd")
end

local function HTC_startHordeForPlayer(player, data)
    if player ~= nil then
        local playerLocation = player:getCurrentSquare()
        if playerLocation ~= nil then
            local hordeOrigin = HTC_getPointOnCircle(playerLocation:getX(), playerLocation:getY(),
                    data.HordeAngle, SandboxVars.HereTheyCome.HordeMinSpawnDistance)
            getWorldSoundManager():addSound(player, hordeOrigin.x, hordeOrigin.y, 0, SandboxVars.HereTheyCome.HordeMaxSpawnDistance, 100);
            HTC_sendWarnToPlayer(player, data)
        end
    end
end

function HTC_startHorde(data)
    print("Starting Here they Come horde #" .. tostring(data.HordeNumber))
    data.HordeWarmup = true;
    data.HordeAngle = ZombRand(360);
    data.HordeIntensity = ZombRand(100);
    data.CurrentHordeStartTime = HTC_getHoursSinceGameStart() * 60
    data.HordeActive = true;
    data.HordeWave = 1;

    HTC_callForEachPlayer(HTC_startHordeForPlayer, data)
end

local function HTC_endHorde(data)
    print("Horde finished...")
    data.HordeWarmup = true
    data.HordeActive = false
    data.LastHordeEndTime = HTC_getHoursSinceGameStart() * 60
    HTC_callForEachPlayer(HTC_sendEndToPlayer, data)
end

local function HTC_HordeProgress()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    HTC_callForEachPlayer(HTC_sendStateToPlayer, data)
    if data.HordeActive ~= true then
        if HTC_isHordePossible(data.LastHordeEndTime) then
            local randomMargin = SandboxVars.HereTheyCome.HordeMaxHourlyProgress - SandboxVars.HereTheyCome.HordeMinHourlyProgress
            local progress = SandboxVars.HereTheyCome.HordeMinHourlyProgress + ZombRand(randomMargin)
            data.HordeProgress = data.HordeProgress + progress / 60
        end
    end
end

local function HTC_pulseOnPlayer(player, _)
    local playerLocation = player:getCurrentSquare()
    if playerLocation ~= nil and SandboxVars.HereTheyCome.PulsePlayersDuringHorde then
        getWorldSoundManager():addSound(player,
                playerLocation:getX(),
                playerLocation:getY(),
                playerLocation:getZ(),
                SandboxVars.HereTheyCome.PulseRange,
                PULSE_VOLUME);
    end
end

local function HTC_warmupWaveForPlayer(player, _)
    player:getModData().remainingZombies = 0
end

local function HTC_startWaveForPlayer(player, data)
    local minZombies = SandboxVars.HereTheyCome.HordeWaveMinZombieCount
    local addedZombies = data.HordeIntensity * math.abs(SandboxVars.HereTheyCome.HordeWaveMaxZombieCount - SandboxVars.HereTheyCome.HordeWaveMinZombieCount) * data.HordeNumber / 100
    player:getModData().remainingZombies = minZombies + addedZombies
    HTC_sendStartToPlayer(player, data)
end

local function HTC_tickWaveForPlayer(player, data)
    local minSpawnRange = SandboxVars.HereTheyCome.HordeMinSpawnDistance
    local maxSpawnRange = SandboxVars.HereTheyCome.HordeMaxSpawnDistance

    if player:getModData().remainingZombies ~= nil and player:getModData().remainingZombies > 0 then
        if data.WaveTick % SandboxVars.HereTheyCome.HordeWaveBatchTicks == 0 then
            local spawnedZombies = HTC_spawnZombiesForPlayer(player,
                    data.HordeAngle,
                    minSpawnRange,
                    maxSpawnRange,
                    math.min(player:getModData().remainingZombies, SandboxVars.HereTheyCome.HordeWaveBatchSize),
                    HTC_SPAWN_CONFIGS)
            player:getModData().remainingZombies = player:getModData().remainingZombies - spawnedZombies
        end
    end
end

local function HTC_CheckHordeStatus()
    local data = ModData.getOrCreate(HTC_STATE_KEY)
    if data.HordeActive == true then
        if data.HordeWave <= SandboxVars.HereTheyCome.HordeNumWaves then
            local now = HTC_getHoursSinceGameStart() * 60
            if data.HordeWarmup then
                HTC_callForEachPlayer(HTC_warmupWaveForPlayer, data)
                if data.CurrentHordeStartTime + SandboxVars.HereTheyCome.HordeWarnTime <= now then
                    data.HordeWarmup = false
                    data.CurrentWaveStartTime = now - SandboxVars.HereTheyCome.TimeBetweenWaves
                    data.CurrentPulseStartTime = now - SandboxVars.HereTheyCome.TimeBetweenPulses
                end
            else
                if data.CurrentWaveStartTime + SandboxVars.HereTheyCome.TimeBetweenWaves <= now then
                    data.CurrentWaveStartTime = now
                    -- Exception for last wave
                    if data.HordeWave ~= SandboxVars.HereTheyCome.HordeNumWaves then
                        HTC_callForEachPlayer(HTC_startWaveForPlayer, data)
                    end
                    data.HordeWave = data.HordeWave + 1
                    data.WaveTick = 0
                else
                    HTC_callForEachPlayer(HTC_tickWaveForPlayer, data)
                end
                if data.CurrentPulseStartTime + SandboxVars.HereTheyCome.TimeBetweenPulses <= now then
                    data.CurrentPulseStartTime = now
                    HTC_callForEachPlayer(HTC_pulseOnPlayer, data)
                end
                data.WaveTick = data.WaveTick + 1
            end
        else
            HTC_endHorde(data)
        end
    end
end

if isClient() == false then
    print("Loading Here They Come server module hooks (server_mode: " .. tostring(isServer()) .. ")...")
    Events.OnGameStart.Add(HTC_ServerSetup);
    Events.OnGameTimeLoaded.Add(HTC_ServerSetup);
    Events.EveryOneMinute.Add(HTC_HordeProgress);
    Events.EveryOneMinute.Add(HTC_CheckHordeEligibility);
    Events.OnTick.Add(HTC_CheckHordeStatus);
end