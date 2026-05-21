0 spawn {

	/*
	Unconscious Spectator script v1.2
	
	Put in/have as the onPlayerRespawn.sqf file, will only work on initial spawn if respawnOnStart = 0 OR 1, NOT -1
	Check the comments left behind the sections for customization options
	
	Contact Jman (@jman0805) if issues pop up
	*/

	sleep 1;
	[false] call ace_spectator_fnc_setSpectator;
	_uid = str (getPlayerUID player);
	deleteMarker _uid;
	_deathSpectate = false; // Keep at false if you have 'select respawn position' enabled to stop spectating after death (otherwise the respawn button may not appear)

	sleep 3;

	if (vehicleVarName player != "zeus") then { // change zeus to whatever is the zeus variable

		// First array [] is for allowed units/modes, second is for removing/disallowing units/modes
		[[player],(allUnits select {_x != player})] call ace_spectator_fnc_updateUnits; // which units to allow spectating of (replace [player] with allPlayers for more freedom)
		[[1,2], [0]] call ace_spectator_fnc_updateCameraModes; // what camera modes to allow (0: freecam, 1: first person, 2: third person)
		[[-2,-1], [0,1,2,3,4,5,6,7]] call ace_spectator_fnc_updateVisionModes; // vision modes (-2: normal, -1: NV, 0: white, 1: black, 2: green, 3: black/green, 4: red, 5: black/red, 6: white/red, 7: red/green/white)

		while {alive player} do {

			waitUntil {sleep 1; !alive player || (player getVariable ["ace_isUnconscious",false] && [player] call ace_medical_status_fnc_hasStableVitals == false)}; // checks if player is dead or unconscious and unstable
			
			if (_deathSpectate || alive player) then { // only enable spectator in case of death when death spectating is enabled
			
				[[player],(allUnits select {_x != player})] call ace_spectator_fnc_updateUnits; // updated list of allowed targets
				sleep 1;
				[true, false, false] call ace_spectator_fnc_setSpectator; // turn on spectator, allow exiting using esc
				[1, player] call ace_spectator_fnc_setCameraAttributes; // force player into FP mode initially to prevent freecam
				
				if (alive player) then { // non-updating unconscious marker creation, you can change things if you so desire
					_marker = createMarker [_uid, player];
					_marker setMarkerType "loc_heal";
					_marker setMarkerColor "ColorCIV";
				};
				
				waitUntil {sleep 1; player getVariable ["ace_isUnconscious",false] == false}; // wait until player regains consciousness (could be swapped to stability)

				if (_deathSpectate) then {
					if ([player] call ace_medical_status_fnc_hasStableVitals) then {
						[false] call ace_spectator_fnc_setSpectator;
					};
					deleteMarker _uid;
				} else {
					[false] call ace_spectator_fnc_setSpectator;
					deleteMarker _uid;
				};
			};
		};
	};
};