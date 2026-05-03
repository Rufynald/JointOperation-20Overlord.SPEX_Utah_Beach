# Zeus Radio Control

This document explains what `zeusRadioControl.sqf` does, where it should be executed, and where to place your actual mission event code.

## Purpose

`zeusRadioControl.sqf` does two separate jobs:

1. On player clients, it hides radio trigger entries from non-Zeus players.
2. On the server, it validates that the caller is Zeus before running the real event.

That means the script is both:

- a UI filter for players
- a server-side gate for mission logic

This is important for anything large and global, such as:

- `skipTime`
- spawning or deleting vehicles
- moving objects
- enabling triggers
- running mission event chains

## File Structure

Recommended mission layout:

```text
yourMissionFolder\
|-- initServer.sqf
|-- initPlayerLocal.sqf
|-- mission.sqm
|-- description.ext
`-- scripts\
    `-- zeus\
        |-- zeusRadioControl.sqf
        `-- README_zeusRadioControl.md
```

## Where To Execute The Script

### `initServer.sqf`

Run the script on the server:

```sqf
[] execVM "scripts\zeus\zeusRadioControl.sqf";
```

Why:

- This registers `TAG_fnc_requestZeusRadioEventServer`.
- That function receives the radio request and decides whether the event is allowed to run.

### `initPlayerLocal.sqf`

Run the same script on every client:

```sqf
[] execVM "scripts\zeus\zeusRadioControl.sqf";
```

Why:

- This starts the local Zeus watcher.
- That watcher hides `Radio Alpha` / `Radio Bravo` from non-Zeus players.

## What The Script Does

## Client Side

The client half checks:

```sqf
getAssignedCuratorLogic player
```

If the player has no curator logic:

```sqf
1 setRadioMsg "NULL";
2 setRadioMsg "NULL";
```

This removes the visible radio UI entries for that client.

If the player does have curator access, the labels are restored:

```sqf
1 setRadioMsg "Alpha";
2 setRadioMsg "Bravo";
```

This happens continuously, so if curator is assigned later, the menu updates automatically.

## Server Side

The server half waits for the radio trigger to call:

```sqf
[player, "ALPHA"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
```

or:

```sqf
[player, "BRAVO"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
```

When the server receives that request, it checks:

- the caller exists
- the caller is a player
- the caller has curator access

If any of those checks fail, the event is rejected.

If they pass, the script enters the event switch.

## Where To Put The Payload

Your real mission event code belongs inside the server `switch (_eventId) do` block.

Example:

```sqf
switch (_eventId) do {
    case "ALPHA": {
        skipTime 6;

        // Put the Alpha payload here.
    };

    case "BRAVO": {
        skipTime -3;

        // Put the Bravo payload here.
    };
};
```

That block is the payload location.

## Payload Meaning

The payload is the actual effect you want the radio event to perform.

Examples:

- changing time
- spawning AI
- spawning vehicles
- deleting wrecks
- opening doors
- toggling triggers
- setting task states
- starting ambient effects
- running larger mission scripts with `execVM` or `spawn`

## Example Payloads

### Simple time change

```sqf
case "ALPHA": {
    skipTime 6;
};
```

### Time change plus script execution

```sqf
case "ALPHA": {
    skipTime 6;
    [] execVM "scripts\events\startStorm.sqf";
};
```

### Vehicle/object event

```sqf
case "BRAVO": {
    skipTime -3;

    if (!isNull truck_1) then {
        truck_1 setDamage 1;
    };

    if (!isNull gateTrigger) then {
        gateTrigger setTriggerActivation ["ANYPLAYER", "PRESENT", true];
    };
};
```

### Calling an existing mission function

```sqf
case "ALPHA": {
    ["phase2"] call TFO_fnc_startMissionPhase;
};
```

## What Should Not Go In The Trigger

Do not put the big event directly in the radio trigger `On Activation`.

Bad:

```sqf
skipTime 6;
truck_1 setDamage 1;
[] execVM "scripts\events\bigEvent.sqf";
```

Good:

```sqf
[player, "ALPHA"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
```

Why:

- the trigger should only request the event
- the server should decide whether it is allowed
- the server should run the actual mission effect

## Eden Trigger Setup

For a Radio Alpha trigger:

```sqf
[player, "ALPHA"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
```

For a Radio Bravo trigger:

```sqf
[player, "BRAVO"] remoteExecCall ["TAG_fnc_requestZeusRadioEventServer", 2];
```

If you add more radio channels later, extend both:

- the local channel list in `TAG_zeusRadioChannels`
- the server `switch` with a new case

## Why The Script Uses Both Client And Server

The client-side part alone is not enough.

If you only hide the radio UI:

- non-Zeus players do not see the entry
- but the event itself is not truly protected

The server-side part is what makes it authoritative.

If someone somehow sends the request anyway, the server still checks whether they are Zeus.

## One-Time Lock

The script currently uses a lock variable per event ID:

```sqf
private _lockVar = format ["TAG_radioEventLock_%1", _eventId];
```

This means each event can only run once unless you change that behavior.

If you want repeated use, you would remove or redesign the lock logic.

## Customizing Radio Labels

This block controls which radio entries are shown:

```sqf
missionNamespace setVariable ["TAG_zeusRadioChannels", [
    [1, "Alpha"],
    [2, "Bravo"]
]];
```

Examples:

- `1` = Alpha
- `2` = Bravo
- `3` = Charlie
- `4` = Delta

If you add more channels, the labels must match the radio slots you intend to use.

## CfgRemoteExec Note

If your mission or modset restricts remote execution, you may need to whitelist:

```sqf
TAG_fnc_requestZeusRadioEventServer
```

Without that, the trigger request may never reach the server.

## Summary

Use `zeusRadioControl.sqf` like this:

1. Execute it in `initServer.sqf`.
2. Execute it in `initPlayerLocal.sqf`.
3. Keep radio trigger `On Activation` minimal and only send the request.
4. Put your real payload inside the server `case "ALPHA"` / `case "BRAVO"` blocks.

The payload location is the most important part:

```sqf
case "ALPHA": {
    // Put event code here.
};

case "BRAVO": {
    // Put event code here.
};
```
