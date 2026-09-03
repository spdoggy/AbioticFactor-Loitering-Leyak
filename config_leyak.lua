return {

    -- ============================================================
    -- New Behavior Mode Flags
    -- ============================================================

    -- Nominal Leyak Cooldown (Seconds), Base Game Default is 900
    leyak_cooldown = 900,

    -- Locks the new leyak behaviors until at least ONE of the events 
    -- in the following list is true. The default setting for this list is to
    -- gate the new Leyak modes behind the acquisition of the hand-held XRAY lamp.
    leyak_limit_behavior_until_world_flags = true,
    world_flags_required = {
        "Labs_XRay_FixitAll",
        "Security_Entered",
    },
    
    -- Randomizes choice between new Leyak behavior modes
    -- Setting this true will randomly override the following:
    --  1. leyak_is_dismissed_by_looking
    --  2. leyak_is_restricted_by_looking
    --  3. leyak_is_dismissed_by_sensory_companion_trinket
    --  4. leyak_is_invisible
    -- See Randomization section below to configure chance of each mode
    leyak_is_behavior_randomized = true,

    -- Dismissal on viewing
    -- Returns the Leyak to her base-game default behavior, Overrides all other settings below
    -- i.e the Leyak will eventually disappear after being viewed by the player
    leyak_is_dismissed_by_looking = false,

    -- The Leyak will be frozen in place when viewed by the player
    -- (but will not disappear if leyak_is_restricted_by_looking == false)
    leyak_is_restricted_by_looking = true,

    -- The Leyak will have restricted movement when hit by any XRAY device
    -- Additionally, freeze/slow the Leyak in place for [leyak_is_restricted_by_xray_duration]
    leyak_is_restricted_by_xray = true,

    -- Duration the XRAY slows or holds the Leyak in place.
    -- Allows players to reach [DistanceDifferenceToDespawn] escape distance,
    -- especially when [leyak_xray_dismissal_time] is set high
    leyak_is_restricted_by_xray_duration = 200,

    -- Leyak will be invisible to the target player until hit by X-RAY
    leyak_is_invisible = false,

    -- XRAY Dismissal Time.
    -- Controls how long the Leyak needs to be hit by a hand-held XRAY lamp to disappear
    -- [leyak_xray_dismissal_time_max] will be overwritten with a random value between 
    -- the min/max range. Default: 3.
    -- Not to be confused with the X-RAY Defense Tower, which will ALWAYS IMMEDIATELY dismiss.
    -- Set the mix/max range to very high to disable XRAY dismissal (i.e 10000) and
    -- encourage players to run away or juggle stunning the leyak while dealing with other 
    -- combatants in the area.
    -- If disabling, be sure to set the [leyak_xray_essence_time] below to a reasonable
    -- value to allow players to collect Leyak Essence 
    leyak_xray_dismissal_time_max = 10000,
    leyak_xray_dismissal_time_min = 500,
    leyak_xray_dismissal_time = 10000,

    -- Leyak Essence Drop Time.
    -- Make the Leyak drop and essence after X amount of time under any XRAY beam,
    -- even if the Leyak has not yet de-spawned.
    -- !Warning: [leyak_xray_dismissal_time_max] must be a reasonable value 
    -- when [leyak_xray_dismissal_time] is set to a very large value, 
    -- otherwise lack of dismissal by XRAY will prevent players from
    -- collecting Leyak Essence for progression
    leyak_xray_essence_time = 100,

    -- Leyak Essence Drop Rate Settings
    -- Configure Leyak % Chance to Drop Essence (100 = Always, 0 = Never)
    -- Allows limiting nuisance drops from towers/lamps
    -- !Warning: Setting both tower and hlamp to 0 will block player progression in labs!

    -- Percent Chance to Drop Essence on hit by XRAY Tower
    leyak_xray_essence_tower_drop_rate = 25,

    -- Percent Chance to Drop Essence on hit by hand-held XRAY Lamp
    leyak_xray_essence_hlamp_drop_rate = 5,

    -- Percent Chance to Drop Essence when stunned by Sensory Companion Trinket
    leyak_xray_essence_trnkt_drop_rate = 5,

    -- Distance the player must run to escape the Leyak
    -- If the leyak de-spawns/is-stuck for any reason then 
    -- a new encounter will immediately be spawned to continue hunting.
    -- Current Valid Escape Conditions are:
    -- 1. Player is more than DistanceDifferenceToDespawn meters from leyak [leyak_evaded_by_player]
    -- 2. leyak_was_dismissed [HasBeenXrayed == true]
    -- 3. leyak entered combat state for grab attack [leyak_caught_player == true]
    -- 4. Any despawn during default behavior mode [leyak_is_dismissed_by_looking == true]
    DistanceDifferenceToDespawn = 8000.0,

    -- Leyak will be dismissed by the sensory companion trinket,
    -- i.e behave functionally equivalent being hit by a hand-held XRAY lamp
    leyak_is_dismissed_by_sensory_companion_trinket = true,

    -- ============================================================
    -- Randomization
    -- ============================================================

    -- Random % chance of Sensor Companion trinket not working
    leyak_random_trinket_pct_failure_chance = 10,
    -- Random % chance of Leyak movement being restricted upon viewing
    leyak_random_restrict_on_look_chance = 50,
    -- Random % chance of Leyak being dismissed upon viewing
    leyak_random_is_dismissed_by_looking_chance = 10,
    -- Random % chance of Leyak being invisible until X-RAY'd
    leyak_random_is_invisible_chance = 10,


    -- ============================================================
    -- Move Speed Settings
    -- ============================================================

    -- Move Speeds when Leyak is being viewed AND leyak_is_restricted_by_looking == true
    leyak_is_restricted_move_walk = 400,
    leyak_is_restricted_move_sprint = 400,
    leyak_is_restricted_move_speed_factor = 0.3,

    -- Move Speeds after Leyak has been hit by an XRAY and leyak_is_restricted_by_xray == true
    -- Lasts for [leyak_is_restricted_by_xray_duration] time.  Set to zero to freeze Leyak in place.
    leyak_is_restricted_by_xray_move_walk = 0.0,
    leyak_is_restricted_by_xray_move_sprint = 0.0,
    leyak_is_restricted_by_xray_move_speed_factor = 0.0,
 
    -- Move speeds when Leyak is nearby but the player has looked away
    -- i.e when not viewing the Leyak and leyak_is_restricted_by_looking == true
    leyak_nearby_walk = 400,
    leyak_nearby_sprint = 400,
    leyak_nearby_speed_factor = 1.5,

    -- Gives Leyak a Big Speed Boost when greater than [leyak_stalking_distance] away from player.
    leyak_stalking_distance = 2500,
    leyak_stalking_walk = 1000,
    leyak_stalking_sprint = 300,
    leyak_stalking_speed_factor = 7,

    -- Slows the Leyak when invisible and less than than [leyak_invisible_distance] away from player.
    leyak_invisible_distance = 1000,
    leyak_invisible_walk = 50,
    leyak_invisible_sprint = 50,
    leyak_invisible_speed_factor = 0.5,


    -- ============================================================
    -- Silly Stuff
    -- ============================================================
    -- Enable or Disable random voices
    leyak_use_random_voice = true,

    -- Leyak can still randomly speak dialog while using the new invisibility mode
    leyak_use_random_voice_while_invisible = true,

    -- Volume for Leyak's Random Voice Dialogue
    leyak_random_voice_volume = 3,

    -- How many seconds to wait between trying to speak voice lines
    leyak_random_voice_time_between_sec = 5,

    -- Controls the randomization element for how often to speak voice lines.
    -- How often to succeed at speaking lines every [leyak_random_voice_time_between_sec] seconds
    --      100 = Always succeeds, 50 = Half of the time, 0 = Never
    --
    -- Example: try to speak every 5 seconds but only succeed at 1/4, effectively this should 
    -- try to make the leyak speak a voice line every ~20 seconds, 
    -- but could be shorter or longer depending on randomization:
    --      leyak_random_voice_time_between_sec = 5,
    --      leyak_use_random_voice_freq = 25.0,
    --
    --   
    leyak_use_random_voice_freq = 25.0,

    -- Voice Line List
    -- Example: Play a Coworker Voice line at 1.3 x NormalPitch        
    --  {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_01.s_cm_idle_01"},
    --
    leyak_random_voice_lines = {
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_01.s_cm_idle_01"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_02.s_cm_idle_02"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_03.s_cm_idle_03"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_04.s_cm_idle_04"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_05.s_cm_idle_05"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_06.s_cm_idle_06"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_07.s_cm_idle_07"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_08.s_cm_idle_08"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_09.s_cm_idle_09"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_10.s_cm_idle_10"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_11.s_cm_idle_11"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_12.s_cm_idle_12"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_13.s_cm_idle_13"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_idle_14.s_cm_idle_14"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_01.s_cm_ty_01"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_02.s_cm_ty_02"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_03.s_cm_ty_03"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_04.s_cm_ty_04"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_05.s_cm_ty_05"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_06.s_cm_ty_06"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_07.s_cm_ty_07"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_08.s_cm_ty_08"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_09.s_cm_ty_09"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_10.s_cm_ty_10"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_11.s_cm_ty_11"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_12.s_cm_ty_12"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_01.s_cm_ty_01"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_02.s_cm_ty_02"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_03.s_cm_ty_03"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_04.s_cm_ty_04"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_05.s_cm_ty_05"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_06.s_cm_ty_06"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_07.s_cm_ty_07"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_08.s_cm_ty_08"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_09.s_cm_ty_09"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_10.s_cm_ty_10"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_11.s_cm_ty_11"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_ty_12.s_cm_ty_12"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_01.s_cm_bye_01"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_02.s_cm_bye_02"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_03.s_cm_bye_03"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_04.s_cm_bye_04"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_05.s_cm_bye_05"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_06.s_cm_bye_06"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_07.s_cm_bye_07"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_08.s_cm_bye_08"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_09.s_cm_bye_09"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_10.s_cm_bye_10"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_11.s_cm_bye_11"},
        {pitch = 1.3, path = "/Game/Audio/Monsters/CM/s_cm_bye_12.s_cm_bye_12"},
    },


    -- ============================================================
    -- Debug Settings
    -- ============================================================
    admin_messages_enabled = true,
    log_distance_to_player = false,


}
