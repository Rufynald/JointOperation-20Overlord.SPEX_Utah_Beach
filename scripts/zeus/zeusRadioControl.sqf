/*
    zeusRadioControl.sqf

    Run on the server and on each client.
    Example:
    - initServer.sqf: [] execVM "scripts\zeus\zeusRadioControl.sqf";
    - initPlayerLocal.sqf: [] execVM "scripts\zeus\zeusRadioControl.sqf";

    In each Radio Trigger On Activation, use:
    [player, "ALPHA"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
    [player, "BRAVO"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];

    Edit the event switch on the server section to do your real mission work.
*/

if (isServer) then {
    TAG_fnc_requestZeusRadioEventServer = {
        params [
            ["_caller", objNull, [objNull]],
            ["_eventId", "", [""]]
        ];

        if (!isServer) exitWith {};
        if (isNull _caller) exitWith {};
        if (!isPlayer _caller) exitWith {};
        if (isNull (getAssignedCuratorLogic _caller)) exitWith {
            ["Zeus only."] remoteExecCall ["hint", _caller];
        };

        _eventId = toUpper _eventId;

        private _lockVar = format ["TAG_radioEventLock_%1", _eventId];
        if (missionNamespace getVariable [_lockVar, false]) exitWith {
            ["This radio event has already been used."] remoteExecCall ["hint", _caller];
        };

        missionNamespace setVariable [_lockVar, true, true];

        switch (_eventId) do {
            case "ALPHA": {
                // Example: server-authoritative time change / big event
                skipTime 6;

                // Put your real event code here.
                // Example:
                // { _x setDamage 1; } forEach [veh1, veh2];
                // someTrigger setTriggerActivation ["ANYPLAYER", "PRESENT", true];
            };

            case "BRAVO": {
                // Example second event
                skipTime -3;

                // Put your real event code here.
            };

            default {
                missionNamespace setVariable [_lockVar, false, true];
                ["Unknown radio event."] remoteExecCall ["hint", _caller];
            };
        };
    };
};

if (!hasInterface) exitWith {};

if (missionNamespace getVariable ["TAG_zeusRadioWatcherStarted", false]) exitWith {};
missionNamespace setVariable ["TAG_zeusRadioWatcherStarted", true];

missionNamespace setVariable ["TAG_zeusRadioChannels", [
    [1, "Alpha"],
    [2, "Bravo"]
]];

TAG_fnc_hasCuratorAccessLocal = {
    if (!hasInterface) exitWith {false};
    if (isNull player) exitWith {false};

    !isNull (getAssignedCuratorLogic player)
};

TAG_fnc_applyZeusRadioStateLocal = {
    private _showRadios = [] call TAG_fnc_hasCuratorAccessLocal;
    private _radioChannels = missionNamespace getVariable ["TAG_zeusRadioChannels", []];

    {
        _x params ["_channel", "_label"];
        _channel setRadioMsg (["NULL", _label] select _showRadios);
    } forEach _radioChannels;
};

[] spawn {
    waitUntil {
        sleep 0.2;
        !isNull player
    };

    private _lastState = -1;

    while {true} do {
        private _hasCuratorAccess = [] call TAG_fnc_hasCuratorAccessLocal;

        if (_hasCuratorAccess isNotEqualTo _lastState) then {
            [] call TAG_fnc_applyZeusRadioStateLocal;
            _lastState = _hasCuratorAccess;
        };

        sleep 1;
    };
};
