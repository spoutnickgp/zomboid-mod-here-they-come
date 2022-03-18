local SOUND_OFFSET_RANGE = 5
local NUM_TEXT_LINES = 3
local SAFE_DISPLAY_THRESHOLD = 20
local WARNING_DISPLAY_THRESHOLD = 80

local function HTC_ClientSetup()
    print("Setup Client Defaults for Horde Mode")
    if getPlayer() == nil then
        return
    end
    if getPlayer():getModData().HTC_HordeRand == nil then
        getPlayer():getModData().HTC_HordeRand = 1
    end

    if getPlayer():getModData().HTC_HordeState == nil then
        getPlayer():getModData().HTC_HordeState = false
    end
    getPlayer():getModData().HTC_Indicator_Safe = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/HTC_safe_horde.png"));
    getPlayer():getModData().HTC_Indicator_Warning = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/HTC_warning_horde.png"));
    getPlayer():getModData().HTC_Indicator_Active = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/HTC_active_horde.png"));
    HTC_IndicatorUpdate();
end

function HTC_IndicatorNew(x, y, width, height, texture)
    local self = {};
    self.image = ISImage:new(x, y, width, height, texture);
    self.image:initialise();
    self.image:setVisible(false);
    self.image:addToUIManager();
    return self
end

function HTC_IndicatorUpdate()
    if getPlayer() == nil then
        return
    end
    local safe_indicator = getPlayer():getModData().HTC_Indicator_Safe;
    local warning_indicator = getPlayer():getModData().HTC_Indicator_Warning;
    local active_indicator = getPlayer():getModData().HTC_Indicator_Active;
    if safe_indicator == nil or warning_indicator == nil or active_indicator == nil then
        return
    end
    if getPlayer():getModData().HTC_HordeState == true then
        active_indicator.image:setVisible(true);
        warning_indicator.image:setVisible(false);
        safe_indicator.image:setVisible(false);
    else
        active_indicator.image:setVisible(false);
        if getPlayer():getModData().HTC_HordeProgress ~= nil then
            if getPlayer():getModData().HTC_HordeProgress >= SAFE_DISPLAY_THRESHOLD then
                safe_indicator.image:setVisible(true);
                warning_indicator.image:setVisible(false);
            end
            if getPlayer():getModData().HTC_HordeProgress >= WARNING_DISPLAY_THRESHOLD then
                safe_indicator.image:setVisible(false);
                warning_indicator.image:setVisible(true);
            end
        end
    end
end

local function HTC_getPointOnCircle(x, y, angle, distance)
    return {
        x = math.floor(x + math.cos(math.rad(angle)) * distance),
        y = math.floor(y + math.sin(math.rad(angle)) * distance)
    }
end

local function HTC_displayWarningText(angle, variation)
    local direction_text = getText("IGUI_PlayerText_HTCDirection_" .. math.floor(angle % 360 / 45))
    local preText = getText("IGUI_PlayerText_HTCWarmupReactionPre_0" .. tostring(variation))
    local postText =  getText("IGUI_PlayerText_HTCWarmupReactionPost_0" .. tostring(variation))
    local text =preText .. direction_text .. postText
    getPlayer():Say(text);
end

local function HTC_playWarningSound(angle, variation)
    local soundOrigin = HTC_getPointOnCircle(getPlayer():getX(), getPlayer():getY(), angle, SOUND_OFFSET_RANGE)
    local originSquare = getWorld():getCell():getGridSquare(soundOrigin.x, soundOrigin.y, 0)
    if originSquare ~= nil then
        getSoundManager():PlayWorldSoundWav("event_sound_0"..tostring(variation), originSquare, 1.0, 400.0, 300.0, false);
    end
end

local function HTC_onCommand(module, command, args)
    if module ~= "HTCmodule" then
        return
    end
    if command == "HTCHordeWarn" then
        getPlayer():getModData().HTC_HordeRand = ZombRand(NUM_TEXT_LINES) + 1
        HTC_playWarningSound(args["angle"], getPlayer():getModData().HTC_HordeRand)
        HTC_displayWarningText(args["angle"], getPlayer():getModData().HTC_HordeRand)
    end
    if command == "HTCHordeStart" then
        getPlayer():getModData().HTC_HordeState = true
        getPlayer():Say(getText("IGUI_PlayerText_HTCStartReaction"));
    end

    if command == "HTCHordeEnd" then
        getPlayer():getModData().HTC_HordeState = false
    end

    if command == "HTCHordeState" then
        getPlayer():getModData().HTC_HordeState = args["onoff"]
        print("Horde State="..tostring(getPlayer():getModData().HTC_HordeState)..", progress=" .. tostring(args["progress"]) .. "/" .. tostring(args["threshold"]))
        getPlayer():getModData().HTC_HordeProgress = args["progress"] / math.max(1, args["threshold"]) * 100
        HTC_IndicatorUpdate()
    end
end

local function HTC_onServerCommand(module, command, args)
    HTC_onCommand(module, command, args)
end

local function HTC_onClientCommand(module, command, player, args)
    HTC_onCommand(module, command, args)
end

if isServer() == false then
    print("Loading Here They Come client module hooks (client_mode: "..tostring(isClient())..")...")
    Events.OnGameStart.Add(HTC_ClientSetup);
    Events.OnGameStart.Add(HTC_IndicatorInitialise);
    Events.EveryOneMinute.Add(HTC_IndicatorUpdate);
    if isClient() == false then
        Events.OnClientCommand.Add(HTC_onClientCommand);
    else
        Events.OnServerCommand.Add(HTC_onServerCommand);
    end

end
