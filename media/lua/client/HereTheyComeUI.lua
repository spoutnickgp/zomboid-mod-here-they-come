function HTC_IndicatorInitialise()
		if getPlayer() == nil then
				return
		end
		getPlayer():getModData().HTC_Indicator = HTC_IndicatorNew(getCore():getScreenWidth() - 210, 12, 32, 32, Texture.getSharedTexture("media/ui/Moodle_HNzombie.png"));
		HTC_IndicatorUpdate();
end

function HTC_IndicatorNew(x, y, width, height, texture)
     local self = {};
     self.image = ISImage:new( x, y, width, height, texture);
     self.image:initialise();
     self.image:setVisible(false);
     self.image:addToUIManager();
     return self
end

function HTC_onServerCommand(module, command, args)
	if module ~= "HTCmodule" then
		print("module is not HTCmodule");
		return
	end
	print("Server command: "..command)
	if command == "HTCHordeStart" then
		getPlayer():getModData().HTC_HordeState = true
		local rAlarmIndex = ZombRand(3);
		local rAlarmText = "IGUI_PlayerText_HTCYell0"..tostring(rAlarmIndex);
		getPlayer():Say(getText(rAlarmText));
		print("Attempting to play sound at "..tostring(args["event_location_X"])..","..tostring(args["event_location_Y"]))
		local square = getWorld():getCell():getGridSquare(args["event_location_X"], args["event_location_Y"], 0);
		if square ~= nil then
			local audio = getSoundManager():PlayWorldSoundWav("event_sound_02", square, 1.0, 200.0, 100.0, false);
		end
	end

	if command == "HTCHordeEnd" then
		getPlayer():getModData().HTC_HordeState = false
	end

	if command == "HTCHordeState" then
		getPlayer():getModData().HTC_HordeState = args["onoff"]
		print("Horde State: progress="..tostring(args["progress"]).."/"..tostring(args["threshold"])..". Horde is "..tostring(getPlayer():getModData().HTC_HordeState))
		HTC_IndicatorUpdate()
	end
end

function HTC_IndicatorUpdate()
 		if getPlayer() == nil then
 				return
 		end
 		local indicator = getPlayer():getModData().HTC_Indicator;
 		if indicator ~= nil then
			if getPlayer():getModData().HTC_HordeState == true then
				indicator.image:setVisible(true);
			else
				indicator.image:setVisible(false);
			end
 		end
end

function HTC_requestHordeState()
	sendClientCommand("HTCmodule", "HTCHordeStateRequest", {})
end

if isClient() == true then
	Events.OnGameStart.Add(HTC_IndicatorInitialise);
	Events.EveryOneMinute.Add(HTC_IndicatorUpdate);
	Events.EveryOneMinute.Add(HTC_requestHordeState);
	Events.OnServerCommand.Add(HTC_onServerCommand);
end
