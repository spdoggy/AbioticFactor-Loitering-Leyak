# AbioticFactor-Loitering-Leyak

## Mod Description

Makes the Leyak much more persistent, and adds several new behavior modes that can be combined.


### Further Reading - README.md and config_leyak.lua
 
See the README.md file for more summary, and see the config_leyak.lua file for a full explanation of each new setting.

This mod is intended to be installed by the Host Player or on a Dedicated Server install running UE4SS.
Note that I have not tested cross-play functionality, but I hope it will work for all players.

https://www.nexusmods.com/abioticfactor/mods/305


## Requirements

- UE4SS: https://www.nexusmods.com/abioticfactor/mods/35


## Installation

Be sure to install UE4SS first (UE4SS: https://www.nexusmods.com/abioticfactor/mods/35)

The entire mod folder should be placed into the players /ue4ss/Mods folder of your AbioticFactor installation.

i.e Windows:
`C:\Program Files (x86)\Steam\steamapps\common\AbioticFactor\AbioticFactor\Binaries\Win64\ue4ss\Mods`

Dedicated Server:
`/AbioticFactor/Binaries/Win64/ue4ss/Mods`

Linux example:
`/home/sp/.steam/debian-installation/steamapps/common/AbioticFactor/AbioticFactor/Binaries/Win64/ue4ss/Mods`


## Configuration

This mod provides a small number of commands via in-game chat box that can configure some settings in real time
without having to edit the config_leyak.lua and reboot the game server.

To use any of these text chat commands, the hosts/server-admin will need to modify the config_admin.lua file
that comes with this mod and add in their own display name (as it would appear in-game) and their SteamID/GameTag/etc.
The mod uses name/id to differentiate from regular players sending messages over chat.

Additionally, if ```admin_messages_enabled``` is true in the ```config_leyak.lua``` file, the mod will send Leyak status messages back
to the valid admin using the text chat box. i.e when a new Leyak is spawned, what behavior mode the Leyak is in, who it is stalking, etc.

### Chat Commands:

```
===========================================================================================
help                   - Remind the user about the "lleyak_help" command
------------------------------------------------------------------------------------------
lleyak_help            - Print a list of text commands for this mod to the in-game chat box
------------------------------------------------------------------------------------------
ToggleLeyakVoice       - Toggle Leyak Random Voice On/Off
------------------------------------------------------------------------------------------
tlv                    - Toggle Leyak Random Voice On/Off (shorthand)
------------------------------------------------------------------------------------------
SetLeyakCooldown #     - Override the default Leyak cooldown to the new number specified, 
                         i.e SetLeyakCooldown 30 to set it to 30 secs
------------------------------------------------------------------------------------------
slc #                  - Shorthand command for SetLeyakCooldown, 
                         i.e slc 400 to set Leyak default cooldown to 400 secs
------------------------------------------------------------------------------------------
glc                    - Shorthand command for displaying the current Leyak cooldown setting.
                         Prints the current value to the chat.
------------------------------------------------------------------------------------------
players_are_too_scared - Disables most of this mod's features and returns
                         the Leyak to base-game functionality
------------------------------------------------------------------------------------------
players_are_not_scared_enough - Un-does the "players_are_too_scared",
                         and sets Leyak behavior to randomized
===========================================================================================
```


## Features

Features implemented so far:

01. Movement Settings
02. Viewed by Player Behavior Tweaks
03. XRAY Settings
04. Sensory Companion Trinket Settings
05. Distance-to-Despawn
06. Essence Settings
07. Player Evasion Logic / Follow Across Loading/Area-Transition
08. Drop Rate Settings for Leyak Essence
09. Leyak invisible until XRAY'd
10. New behaviors can be gated until players reach a certain world event


### New Behavior Modes

1. ```leyak_is_dismissed_by_looking```
The default behavior, overrides all others

2. ```leyak_is_restricted_by_looking```
The Leyak does NOT disappear when being viewed by the target player!
Depending on the ```leyak_is_restricted_move_speed_factor``` and related settings, the Leyak will 
continue to advance forwards at the player. The ```leyak_is_restricted_move_speed_factor``` can be set to 0
if desired to cause the Leyak to freeze in-place during this mode.

3. ```leyak_is_dismissed_by_sensory_companion_trinket```
Gives the Sensory Companion trinket the ability to both stun and make the Leyak disappear.

4. ```leyak_is_invisible```
Makes the Leyak invisible to ALL players, until hit with any X-RAY beam.
The leyak will continue to give off sound cues to give the player hints at where it could be.

5. Not Dismissed by XRAY / ```leyak_xray_dismissal_time```
There are controls to prevent the Leyak from immediately de-spawning when hit by a hand-held XRAY lamp.
These settings also control how long players must hit the Leyak with a hand-held XRAY lamp to dismiss her (or the trinket
if that is enabled). Setting leyak_xray_dismissal_time above ~ 5000 or 6000 will mean that the hand-held XRAY lamp will
(generally) completely drain it's battery before the Leyak would disappear. Not to be confused with the base defense Tower X-RAY.
The base defense Tower Defense X-RAY turret will always still immediately make the Leyak disappear. 

The XRAY dismissal time is randomized between a min/max setting value, see 
```leyak_xray_dismissal_time_min```, ```leyak_xray_dismissal_time_max``` in the ```config_leyak.lua``` file to control it.

6. ```leyak_is_restricted_by_xray_duration```
The Leyak will be temporarily frozen in place by a hand-held XRAY lamp for [leyak_is_restricted_by_xray_duration] 
seconds of time. Players will then have to make an escape of at least [DistanceDifferenceToDespawn] meters away to actually
get rid of the Leyak or she will continue the hunt. Teammates can help keep the leyak under X-RAY while the target escapes.

7. Player Evasion Mechanics
The player must reach a safe distance now to safely escape the Leyak, or the hunt will restart. If the Leyak de-spawns or 
gets stuck for any other reason, the hunt will also re-start. So just running across a loading screen to the next zone
won't always work! Current Valid Escape Conditions are:
```
- Player gets more than [DistanceDifferenceToDespawn] meters from the leyak
- leyak_was_dismissed (disappears) by any XRAY (or trinket)
- leyak entered combat state for a grab attack
- Any despawn during the default behavior mode (i.e playing with normal settings and the leyak is dismissed by looking)
```

8. RANDOM!
Randomizes choice between the new Leyak behavior modes! Keep the players guessing.

- Setting [leyak_is_behavior_randomized] true will randomly override the following:
- ```leyak_is_dismissed_by_looking```
- ```leyak_is_restricted_by_looking```
- ```leyak_is_dismissed_by_sensory_companion_trinket```
- ```leyak_is_invisible```

- See Randomization section in ```config_leyak.lua``` to configure the percent chance of each mode.


## Future Improvement Ideas

01. Leyak no-clip mode (TBD: This made the Leyak emerge out of the floor under the players feet in some cases!)
02. Teleport to player if lost
03. Target Switch to another player during active hunt
04. Control DrainPerTick on the Hand-Held X-RAY Lamp
05. A mechanic to let players temporarily obtain the "Buff_LeyakSafetyZone"
