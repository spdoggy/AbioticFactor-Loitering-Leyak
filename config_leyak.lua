return {

    -- ============================================================
    -- New Behavior Mode Flags
    -- ============================================================

    -- Nominal Leyak Cooldown (Seconds), Base Game Default is 900
    leyak_cooldown = 900,

    -- Randomizes choice between new Leyak behavior modes
    -- Setting this true will randomly override the following:
    --  1. leyak_is_dismissed_by_looking
    --  2. leyak_is_restricted_by_looking
    --  3. leyak_is_dismissed_by_sensory_companion_trinket
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

    -- TODO: Not Yet Implemented
    leyak_can_be_invisible = true,

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
    leyak_xray_essence_tower_drop_rate = 5,

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


    -- ============================================================
    -- Move Speed Settings
    -- ============================================================

    -- Move Speeds when Leyak is being viewed AND leyak_is_restricted_by_looking == true
    leyak_is_restricted_move_walk = 400,
    leyak_is_restricted_move_sprint = 400,
    leyak_is_restricted_move_speed_factor = 0.1,

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


    -- ============================================================
    -- Debug Settings
    -- ============================================================
    admin_messages_enabled = true,
    log_distance_to_player = false,


}
