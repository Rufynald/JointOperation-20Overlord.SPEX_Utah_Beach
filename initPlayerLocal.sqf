[] spawn {
    waitUntil { !isNull player };
    sleep 3;

    if (isNull (getAssignedCuratorLogic player)) then {
        1 setRadioMsg "NULL"; // hides Radio Alpha
        2 setRadioMsg "NULL"; // hides Radio Bravo
    };
};
[] execVM "scripts\zeus\zeusRadioControl.sqf";
