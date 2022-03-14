local SOUND_OFFSET_RANGE = 10
local NUM_TEXT_LINES = 3
local WARNING_DISPLAY_THRESHOLD = 20
local function HTC_IndicatorNew(x, y, width, height, texture)
    local self = {};
    self.image = ISImage:new(x, y, width, height, texture);
    self.image:initialise();
    self.image:setVisible(false);
    self.image:addToUIManager();
    return self
end

local function HTC_IndicatorUpdate()
    if getPlayer() == nil then
        return
    end
    local warning_indicator = getPlayer():getModData().HTC_Indicator_Warning;
    local active_indicator = getPlayer():getModData().HTC_Indicator_Active;
    if warning_indicator ~= nil and active_indicator ~= nil then
        if getPlayer():getModData().HTC_HordeState == true then
            active_indicator.image:setVisible(true);
            warning_indicator.image:setVisible(false);
        else
            active_indicator.image:setVisible(false);
            if getPlayer():getModData().HTC_HordeProgress ~= nil and getPlayer():getModData().HTC_HordeProgress >= WARNING_DISPLAY_THRESHOLD then
                warning_indicator.image:setVisible(true);
            else
                warning_indicator.image:setVisible(false);
            end
        end
    end
end

local function HTC_IndicatorInitialise()
    if getPlayer() == nil then
        return
    end
    getPlayer():getModData().HTC_Indicator_Warning = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/HTC_warning_horde.png"));
    getPlayer():getModData().HTC_Indicator_Active = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/HTC_active_horde.png"));
    HTC_IndicatorUpdate();
end

local function HTC_getPointOnCircle(x, y, angle, distance)
    return {
        x = math.floor(x + math.cos(math.rad(angle)) * distance),
        y = math.floor(y + math.sin(math.rad(angle)) * distance)
    }
end

local function HTC_getTriggerReactionText(angle, variation)
    local direction_text = getText("IGUI_PlayerText_HTCDirection_" .. math.floor(angle % 360 / 45)) + 1
    local preText = getText("IGUI_PlayerText_HTCReactionPre0" .. tostring(variation))
    local postText =  getText("IGUI_PlayerText_HTCReactionPost0" .. tostring(variation))
    return preText .. direction_text .. postText
end


local function HTC_onServerCommand(module, command, args)
    if module ~= "HTCmodule" then
        print("module is not HTCmodule");
        return
    end
    print("Server command: " .. command)
    if command == "HTCHordeStart" then
        getPlayer():getModData().HTC_HordeState = true

        local rand = ZombRand(NUM_TEXT_LINES)
        local angle = args["angle"]
        local text = HTC_getTriggerReactionText(angle, rand)
        getPlayer():Say(text);
        print("Attempting to play sound at " .. tostring(args["event_location_X"]) .. "," .. tostring(args["event_location_Y"]))
        local soundOrigin = HTC_getPointOnCircle(getPlayer():getX(), getPlayer():getY(), angle, SOUND_OFFSET_RANGE)
        local originSquare = getWorld():getCell():getGridSquare(soundOrigin.x, soundOrigin.y, 0)
        if originSquare ~= nil then
            print("event_sound_0"..tostring(rand))
            getSoundManager():PlayWorldSoundWav("event_sound_0"..tostring(rand), originSquare, 1.0, 1000.0, 300.0, false);
        end
    end

    if command == "HTCHordeEnd" then
        getPlayer():getModData().HTC_HordeState = false
    end

    if command == "HTCHordeState" then
        getPlayer():getModData().HTC_HordeState = args["onoff"]
        getPlayer():getModData().HTC_HordeProgress = args["progress"] / math.max(1, args["threshold"]) * 100
        print("Horde State: progress=" .. tostring(args["progress"]) .. "/" .. tostring(args["threshold"]) .. ". Horde is " .. tostring(getPlayer():getModData().HTC_HordeState))
        HTC_IndicatorUpdate()
    end
end

if isClient() == true then
    Events.OnGameStart.Add(HTC_IndicatorInitialise);
    Events.EveryOneMinute.Add(HTC_IndicatorUpdate);
    Events.OnServerCommand.Add(HTC_onServerCommand);
end
