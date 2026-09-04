local Utils = require("utils")


-- TODO:
-- 1. Other Leyak Mods
--    a. Mode Idea: Distracted Leyak - the Leyak switch targets midway
--    b. Teleport to player mode if it is > x meters away but less then the limit
--    c. No-clip
--    d. Let users define their own custom voice sounds for Leyak


-- ============================================================
-- CONFIG
-- ============================================================
Utils.log("--- Loitering Leyak [LLEYAK] MOD LOADING ---\n")
local Config = require("../config")
local ConfigAdmin = require("../config_admin")
local ConfigLeyak = require("../config_leyak")

-- ============================================================
-- CONSTANTS
-- ============================================================
MOD_PREFIX = "[LLEYAK]"


-- ============================================================
-- STATE
-- ============================================================
local GameStateHookFired = false
local GameStateHookNotified = false
local leyak_xray_hold_counter = 0
local leyak_xray_struck_counter = 0
local leyak_was_xrayed = false
local leyak_was_xrayed_by_tower = false
local leyak_was_xrayed_by_lamp = false
local leyak_was_xrayed_by_trinket = false
local leyak_dropped_essence_check = false
local leyak_evaded_by_player = false
local leyak_was_dismissed = false
local leyak_caught_player = false
local leyak_target_name = ""
local leyak_is_invisible = false
local leyak_sound_cue_started = false
local leyak_recently_spoke = false

-- ============================================================
-- INSTANCES
-- ============================================================
local Leyak_NPC = nil -- @ANPC_Leyak_C;
local Leyak_DIR = nil -- @ULeyakDirectorComponent_C;

-- ============================================================
-- UTILITIES
-- ============================================================

-- Return true if a player has a matching named Buff
---@param player AAbiotic_PlayerCharacter_C
---@param buff_name string
---@return boolean
local function doesPlayerHaveBuff(player, buff_name)
    local buff_map = player.BuffDebuffComponent.CurrentBuffs -- @TArray<FBuffDebuffEntry> CurrentBuffs;
    local has_the_buff = false
    buff_map:ForEach(function(index, value)
        local buff_debuff_name = value:get().BuffRow.RowName:ToString()
        if buff_debuff_name == buff_name then
            has_the_buff = true
        end
    end)
    return has_the_buff
end

--- Get the Leyak AI Director
---@return ULeyakDirectorComponent_C
local function GetValidLeyakDir()
    if Leyak_DIR and Utils.IsValid(Leyak_DIR) then
        return Leyak_DIR
    elseif Leyak_NPC then
        Leyak_DIR = Leyak_NPC.LinkedLeyakDirector
        return Leyak_DIR
    else
        Leyak_DIR = Utils.GetLeyakAiDirector()
        return Leyak_DIR
    end
end

--- Get the Leyak
---@return ANPC_Leyak_C
local function GetValidLeyak()
    if Leyak_NPC and Utils.IsValid(Leyak_NPC) then
        return Leyak_NPC
    else
        Leyak_NPC = Utils.GetLeyak()
        return Leyak_NPC
    end
end


-- ============================================================
-- FUNCTIONS
-- ============================================================

-- Server Side Supported
local function Handle_Request_SendTextChatMessage(Context, MessageToSend)
    Utils.log(">>>> Handle_Request_SendTextChatMessage Fired! <<< ")
    if not Context then return end
    local player_controller = Context:get() -- AAbioticPlayerController

    local steam_display_name = player_controller.MyPlayerCharacter.MyPlayerState:GetPlayerName():ToString()
    local message = MessageToSend:get():ToString()
    local msg_fmt = Utils.split_str(message, " ")

    local max_key = 0
    for k in pairs(msg_fmt) do
        if k ~= nil then
            max_key = k
        end
    end

    -- Get/Set Leyak Cooldown
    if (msg_fmt[1] == "SetLeyakCooldown" or msg_fmt[1] == "slc" or msg_fmt[1] == "glc") and max_key == 1 then
        Utils.log("Get Leyak Cooldown Command Detected")
        local get_cool = ConfigLeyak.leyak_cooldown

        local msg = string.format("Leyak Cooldown is: %.2f seconds", get_cool)
        Utils.PlayCtrlTextChatMessage(player_controller, msg, MOD_PREFIX, Enums.MsgColors.bg, Enums.MsgColors.red)
    elseif (msg_fmt[1] == "SetLeyakCooldown" or msg_fmt[1] == "slc") and max_key == 2 then
        Utils.log("Change Leyak Cooldown Command Detected")
        if steam_display_name ~= ConfigAdmin.admin_name then
            return
        end
        local new_cool = msg_fmt[2]
        ConfigLeyak.leyak_cooldown = new_cool
        local leyak_director = GetValidLeyakDir()
        if Utils.IsValid(leyak_director) then
            leyak_director.LeyakCooldown = new_cool
        end

        local msg = string.format("New Leyak Cooldown is: %.2f seconds", new_cool)
        Utils.PlayCtrlTextChatMessage(player_controller, msg, MOD_PREFIX, Enums.MsgColors.bg, Enums.MsgColors.red)
    end



    if (msg_fmt[1] == "players_are_too_scared") and max_key == 1 then
        if steam_display_name ~= ConfigAdmin.admin_name then
            return
        end
        ConfigLeyak.leyak_is_dismissed_by_looking = true
        local msg = "The Leyak is feeling shy again.."
        player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.red, msg, Enums.MsgColors.green,
            player_controller, false)
    end

    if (msg_fmt[1] == "players_are_not_scared_enough") and max_key == 1 then
        if steam_display_name ~= ConfigAdmin.admin_name then
            return
        end
        ConfigLeyak.leyak_is_dismissed_by_looking = false
        ConfigLeyak.leyak_is_behavior_randomized = true
        local msg = "The Leyak has noticed you.."
        player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.red, msg, Enums.MsgColors.red,
            player_controller, false)
    end

    if (msg_fmt[1] == "tls" or msg_fmt[1] == "tlv" or msg_fmt[1] == "ToggleLeyakVoice") and max_key == 1 then
        if steam_display_name ~= ConfigAdmin.admin_name then
            return
        end
        ConfigLeyak.leyak_use_random_voice = not ConfigLeyak.leyak_use_random_voice
        
        if ConfigLeyak.leyak_use_random_voice then
            msg = "Leyak random voice: ENABLED"
            player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.green, msg, Enums.MsgColors.green,
            player_controller, false)
        else
            local msg = "Leyak random voice: DISABLED"
            player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.red, msg, Enums.MsgColors.red,
            player_controller, false)
        end
        
        
    end

    local msg_out = ""
    if max_key == 1 then
        if msg_fmt[1] == "HELP" or msg_fmt[1] == "help" then
            player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg,
                "Enter lleyak_help for list of commands",
                Enums.MsgColors.white, player_controller, false)
        end

        if msg_fmt[1] == "lleyak_help" then
            local delay = 4000
            if steam_display_name == ConfigAdmin.admin_name then
                player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg,
                    "Supported Admin Commands:",
                    Enums.MsgColors.white, player_controller, false)
                player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "slc",
                    Enums.MsgColors.green,
                    player_controller, false)
                player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "slc new_cooldown",
                    Enums.MsgColors.green,
                    player_controller, false)
                player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "tls",
                    Enums.MsgColors.green,
                    player_controller, false)

                delay = delay + 2000
                ExecuteWithDelay(delay, function()
                    player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg,
                        "players_are_too_scared",
                        Enums.MsgColors.green, player_controller, false)
                    player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg,
                        "players_are_not_scared_enough",
                        Enums.MsgColors.green, player_controller, false)
                end)
            end
            delay = delay + 2000
            ExecuteWithDelay(delay, function()
                -- player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "Supported Player Commands:", Enums.MsgColors.white, player_controller, false)
                -- TBD, No Player Supported Commands at this time
            end)
        end
    end
    player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "-----", Enums.MsgColors.white, player_controller, false)
end

--- Set the Leyak's Move Speed
---@param walk number
---@param sprint number
---@param time_dilation number
local function SetLeyakMoveSpeed(walk, sprint, time_dilation)

    local leyak_director = GetValidLeyakDir()
    if Utils.IsValid(leyak_director) then
        if ConfigLeyak.log_distance_to_player then
            Utils.log("Setting Leyak MoveFactor: " .. time_dilation)
        end
        local npc = leyak_director.ActiveStalkingNPC.NPCData
        npc.DefaultWalkSpeed_17_311EDFE249A63474E18512B1E0BA66D4 = walk
        npc.DefaultSprintSpeed_18_F44E4C8A4F87079E4A5710984C1DF4EC = sprint
        leyak_director.ActiveStalkingNPC.CustomTimeDilation = time_dilation
    end
end

--- Calculate the Leyak's Distance to the target player
---@return number
local function CalcLeyakDistanceToPlayer()
    local dist = 0
    local leyak_npc = GetValidLeyak()
    if Utils.IsValid(leyak_npc) then
        leyak_npc.ViewedByTarget = false
        leyak_target_name = leyak_npc.TargetPlayer.MyPlayerState:GetPlayerName():ToString()
        local leyak_loc = leyak_npc:K2_GetActorLocation()
        local player_loc = leyak_npc.TargetPlayer:K2_GetActorLocation()
        local x_vector = (leyak_loc.X - player_loc.X) ^ 2
        local y_vector = (leyak_loc.Y - player_loc.Y) ^ 2
        local z_vector = (leyak_loc.Z - player_loc.Z) ^ 2
        dist = math.sqrt(x_vector + y_vector + z_vector)
    end
    return dist
end

---Set the Leyak Invisible by temporarily setting and invalid target,
---then forcing a player visibility update.
---@param override_xray_status boolean -- Ignore if Leyak was previously X-RAY'd
local function SetLeyakInvisible(override_xray_status)
    local leyak_npc = GetValidLeyak()
    if Utils.IsValid(leyak_npc) then
        override_xray_status = override_xray_status or false
        if override_xray_status then
            leyak_npc.HasBeenXrayed = false
        elseif leyak_npc.HasBeenXrayed then
            return
        end

        leyak_is_invisible = true
        local playing = 0 ---@cast playing EAudioComponentPlayState
        leyak_npc:StartedSpeaking(playing)
        leyak_npc:UpdateBreathingAudio(playing)
        leyak_npc:OnCharacterSpeakingStart()
        leyak_npc.bHidden = true
        --local save_target = leyak_npc.TargetPlayer
        --local fake_target
        --local faked_target = StaticConstructObject(ConsoleClass, GameViewport, 0, 0, 0, nil, false, false, nil)

        --leyak_npc.TargetPlayer = fake_target
        --leyak_npc:UpdateLeyakVisibility()
        --leyak_npc:UpdateLeyakVisibility()
        --leyak_npc.TargetPlayer = save_target

    end
end

--- Check if new behavior modes for Leyak are gated behind story events
--- Returns true at least one the required events in the 
--- or true if the limit_behavior setting is turned off
--- Otherwise false
--- @return boolean
local function WorldEventFlagsAllowLeyak()
    if ConfigLeyak.leyak_limit_behavior_until_world_flags then
        for k, v in pairs(ConfigLeyak.world_flags_required) do
            if Utils.WorldHasEventOccurred(v) then
                return true
            end
        end
        return false
    else
        return true
    end
end

--- Randomly Play voice Lines from the ConfigLeyak if conditions are right
local function LeyakDoRandomSpeech()
    if ConfigLeyak.leyak_use_random_voice and not leyak_recently_spoke then

        -- No dialog if the settings disabled not speaking while invisible
        if leyak_is_invisible and not ConfigLeyak.leyak_use_random_voice_while_invisible then
            return
        end

        local leyak_npc = GetValidLeyak()
        if Utils.IsValid(leyak_npc) then            
            leyak_recently_spoke = true
            local dice_roll_speak = math.random()
            if dice_roll_speak <= (ConfigLeyak.leyak_use_random_voice_freq/100) then
                local random_voice = ConfigLeyak.leyak_random_voice_lines[math.random( #ConfigLeyak.leyak_random_voice_lines)]  
                vol = ConfigLeyak.leyak_random_voice_volume
                Utils.PlaySoundAtActor(random_voice.path, leyak_npc, vol, random_voice.pitch, true)
            end
            local speak_delay = 1000 + math.floor(ConfigLeyak.leyak_random_voice_time_between_sec * 1000.0)
            ExecuteWithDelay(speak_delay, function()
                leyak_recently_spoke = false
            end)
        end
    end
end

local function LeyakCheckInvisibleSoundCue()
    local leyak_npc = GetValidLeyak()
    -- Limit to one loop instance per spawn
    if leyak_sound_cue_started then
        return
    end
    leyak_sound_cue_started = true
    -- Check if Leyak is still invisible and not under and XRAY or evade conditions
    if Utils.IsValid(leyak_npc) and leyak_is_invisible then
        -- Play an idle every 1 second while conditions warrant it
        LoopAsync(1500, function()
            if leyak_was_xrayed then
                return true
            elseif leyak_was_xrayed_by_tower then
                return true
            elseif leyak_was_xrayed_by_lamp then
                return true
            elseif leyak_was_xrayed_by_trinket then
                return true
            elseif leyak_evaded_by_player then
                return true
            elseif leyak_was_dismissed then
                return true
            elseif leyak_caught_player then
                return true
            elseif not leyak_is_invisible then
                return true
            end
            local leyak_npc = GetValidLeyak()

            if Utils.IsValid(leyak_npc) then
                if leyak_npc.HasBeenXrayed then
                    return true
                end
                -- Otherwise give player a location sound cue
                local idle_id = math.random(1, 18)
                local snd_path = string.format("/Game/Audio/Monsters/Leyak/s_leyak_idle_%02d.s_leyak_idle_%02d", idle_id, idle_id)
                -- Choose 01 to 18 idle noises..
                local location = leyak_npc:K2_GetActorLocation()
                local dist = CalcLeyakDistanceToPlayer()
                local rotation = {}
                local vol = (1000/dist) + 0.7
                local pitch = 1.0
                local start_at = 0.0
                --Utils.PlaySoundAtLocation(snd_path, location, rotation, vol, pitch, start_at)
                Utils.Broadcast_PlaySoundAtLocation(snd_path, location, vol, pitch)
                
                return false
            else
                return true
            end

        end)

    else
        return
    end
end


---@param leyak ANPC_Leyak_C
local function Handle_LeyakNotifyOnNewObject(leyak)
    Leyak_NPC = leyak
    leyak_xray_struck_counter = 0
    leyak_xray_hold_counter = 0
    leyak_was_xrayed_by_tower = false
    leyak_was_xrayed_by_lamp = false
    leyak_evaded_by_player = false
    leyak_was_dismissed = false
    leyak_caught_player = false
    leyak_was_xrayed = false
    leyak_target_name = ""
    leyak_dropped_essence_check = false
    leyak_sound_cue_started = false
    leyak_recently_spoke = false

    GetValidLeyakDir()

    ExecuteWithDelay(5000, function()
        -- Record how far away the Leyak is from target
        local dist = CalcLeyakDistanceToPlayer()
        if ConfigLeyak.log_distance_to_player then
            Utils.log("----------------------")
            Utils.log("Spawned -- Dist to Leyak:" .. dist)
        end

        -- Enter Stalking Mode Speed
        SetLeyakMoveSpeed(ConfigLeyak.leyak_stalking_walk, ConfigLeyak.leyak_stalking_sprint,
            ConfigLeyak.leyak_stalking_speed_factor)
        
        -- Restore Default XRAY Duration
        Leyak_NPC.RequiredMegalightDuration = 3.0

        -- Set the Evade Distance
        Leyak_NPC.DistanceDifferenceToDespawn = ConfigLeyak.DistanceDifferenceToDespawn

        -- Record the Target Player Name
        leyak_target_name = leyak.TargetPlayer.MyPlayerState:GetPlayerName():ToString()

        -- New XRAY Duration from Min/Max Range
        ConfigLeyak.leyak_xray_dismissal_time = math.random(
            ConfigLeyak.leyak_xray_dismissal_time_min, ConfigLeyak.leyak_xray_dismissal_time_max
        )

        if ConfigLeyak.admin_messages_enabled then
            local msg = string.format("Leyak [leyak_xray_dismissal_time] = %.1f ", ConfigLeyak.leyak_xray_dismissal_time)
            Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
        end

        -- Force it back to stock-Leyak if world does not meet required event flags
        if not WorldEventFlagsAllowLeyak() then
            ConfigLeyak.leyak_is_dismissed_by_looking = true
            if ConfigLeyak.admin_messages_enabled then
                msg = string.format("The Leyak is gated behind world event flags. Behave normal and follow %s (Leyak Default/Base Game Behavior)",
                    leyak_target_name)
                Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
            end
            return
        end

        -- Handle Randomization
        if ConfigLeyak.leyak_is_behavior_randomized then
            local dice_roll

            dice_roll = math.random()
            ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket = (dice_roll >= (ConfigLeyak.leyak_random_trinket_pct_failure_chance / 100))

            dice_roll = math.random()
            ConfigLeyak.leyak_is_restricted_by_looking = (dice_roll <= (ConfigLeyak.leyak_random_restrict_on_look_chance / 100))

            dice_roll = math.random()
            ConfigLeyak.leyak_is_dismissed_by_looking = (dice_roll <= (ConfigLeyak.leyak_random_is_dismissed_by_looking_chance / 100))

            dice_roll = math.random()
            ConfigLeyak.leyak_is_invisible = (dice_roll <= (ConfigLeyak.leyak_random_is_invisible_chance / 100))
            if ConfigLeyak.leyak_is_invisible then
                SetLeyakInvisible(true)
                LeyakCheckInvisibleSoundCue()
                leyak_sound_cue_started = true
            end

            if ConfigLeyak.admin_messages_enabled then
                if not ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket then
                    msg = "Leyak is not fooled by the sensory companion!"
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.red)
                else
                    msg = "Leyak will be fooled by the sensory companion!"
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
                end

                if ConfigLeyak.leyak_is_invisible then
                    msg = "Leyak is invisible to the player!"
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.red)
                end

                if ConfigLeyak.leyak_is_dismissed_by_looking then
                    msg = string.format(
                    "The Leyak is feeling shy, but has noticed %s ([leyak_is_dismissed_by_looking] = true)",
                        leyak_target_name)
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
                else
                    if ConfigLeyak.leyak_is_restricted_by_looking then
                        msg = string.format(
                        "The Leyak is feeling lonely..and has noticed %s (Leyak is only slowed by viewing)",
                            leyak_target_name)
                        Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
                    else
                        msg = string.format("The Leyak has noticed %s (Leyak is not slowed in any way by viewing!)",
                            leyak_target_name)
                        Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.red)
                    end
                end
            end
        else
            if ConfigLeyak.admin_messages_enabled then
                msg = string.format("The Leyak is totally normal and following %s (Leyak Default/Base Game Behavior)",
                    leyak_target_name)
                Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
            end
        end
    end)
end

---Control X-RAY Leyak essence drop rates
---@param leyak ANPC_Leyak_C
local function leyak_drop_essence(leyak)
    -- Only Roll for Drop Once (combined methods)
    if leyak_dropped_essence_check then
        return
    end

    local dice_roll
    dice_roll = math.random()
    if leyak_was_xrayed_by_tower then
        if (dice_roll <= (ConfigLeyak.leyak_xray_essence_tower_drop_rate / 100)) then
            leyak:DropEssence()
        end
    elseif leyak_was_xrayed_by_lamp then
        if (dice_roll <= (ConfigLeyak.leyak_xray_essence_hlamp_drop_rate / 100)) then
            leyak:DropEssence()
        end
    elseif leyak_was_xrayed_by_trinket then
        if (dice_roll <= (ConfigLeyak.leyak_xray_essence_trnkt_drop_rate / 100)) then
            leyak:DropEssence()
        end
    else
        -- Fail Safe: Always
        leyak:DropEssence()
    end
    leyak_dropped_essence_check = true
end

local function Handle_TriggerViewedByTarget()
    -- Default overrides all other settings
    if ConfigLeyak.leyak_is_dismissed_by_looking then
        return
    end

    local leyak_npc = GetValidLeyak()
    if Utils.IsValid(leyak_npc) then
        local dist = CalcLeyakDistanceToPlayer()
        if ConfigLeyak.log_distance_to_player then
            Utils.log("----------------------")
            Utils.log("Viewed By Target -- Dist to Leyak:" .. dist)
        end

        if ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket then
            if doesPlayerHaveBuff(leyak_npc.TargetPlayer, Enums.Buffs.Buff_Leyak360) then
                leyak_npc.HasBeenXrayed = true
                leyak_was_xrayed_by_trinket = true
                leyak_is_invisible = false
            end
        end

        -- Prevent De-spawn
        leyak_npc.ViewedByTarget = false
        leyak_npc.DistanceDifferenceToDespawn = ConfigLeyak.DistanceDifferenceToDespawn

        -- Extend Reach to allow Leyak to damage even if being viewed
        leyak_npc.DamageSphere.SphereRadius = 400

        -- Attempt Speech
        LeyakDoRandomSpeech()

        -- Dismiss if hit by stationary X-RAY defense tower
        if leyak_was_xrayed_by_tower then
            leyak_xray_struck_counter = ConfigLeyak.leyak_xray_dismissal_time + 1
            leyak_was_dismissed = true
            leyak_is_invisible = false
        end

        -- Prepare to Dismiss the Leyak if the Max XRAY Time is Exceeded
        -- Otherwise, set the Required Duration to the Max XRAY Time
        if leyak_xray_struck_counter > ConfigLeyak.leyak_xray_dismissal_time then
            SetLeyakMoveSpeed(0.01, 0.01, 0.01)
            leyak_npc.RequiredMegalightDuration = 2
            leyak_npc.HasBeenXrayed = true
            leyak_is_invisible = false
            leyak_npc.PrepareLeyakDespawn()
            leyak_drop_essence(leyak_npc)
            leyak_xray_hold_counter = ConfigLeyak.leyak_is_restricted_by_xray_duration
            leyak_was_dismissed = true
            return
        elseif leyak_xray_struck_counter > ConfigLeyak.leyak_xray_essence_time then
            leyak_drop_essence(leyak_npc)
        else
            leyak_npc.RequiredMegalightDuration = ConfigLeyak.leyak_xray_dismissal_time
        end


        if leyak_npc.HasBeenXrayed then
            leyak_npc.PotentiallyStuck = false
            leyak_npc.AbsolutelyStuck = false
            leyak_xray_struck_counter = leyak_xray_struck_counter + 1
            leyak_is_invisible = false
            leyak_npc.HasBeenXrayed = false
            leyak_was_xrayed = true
            leyak_xray_hold_counter = ConfigLeyak.leyak_is_restricted_by_xray_duration

            -- Note: Originally XRAY Restriction was planned to allow the Layak to move if it was set False
            -- i.e allow the Leyak to move even while under the beam, a solution to this has not yet been found
            -- Currently setting leyak_is_restricted_by_xray to false will simply disable:
            --    1. the "stun" of leyak_is_restricted_by_xray_duration
            --    2. additional modifications to move speed, i.e leyak_is_restricted_by_xray_move_speed_factor
            if ConfigLeyak.leyak_is_restricted_by_xray then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_by_xray_move_walk,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_sprint,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_speed_factor)
            elseif ConfigLeyak.leyak_is_restricted_by_looking then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_move_walk, ConfigLeyak.leyak_is_restricted_move_sprint,
                    ConfigLeyak.leyak_is_restricted_move_speed_factor)
            elseif leyak_is_invisible and dist <= ConfigLeyak.leyak_invisible_distance then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_invisible_walk, ConfigLeyak.leyak_invisible_sprint,
                    ConfigLeyak.leyak_invisible_speed_factor)
                leyak_npc.HasBeenXrayed = true
                local playing = 0 ---@cast playing EAudioComponentPlayState
                leyak_npc:StartedSpeaking(playing)
                leyak_npc:UpdateBreathingAudio(playing)
                leyak_npc:OnCharacterSpeakingStart()
                leyak_npc.HasBeenXrayed = false
            else
                SetLeyakMoveSpeed(ConfigLeyak.leyak_nearby_walk, ConfigLeyak.leyak_nearby_sprint,
                    ConfigLeyak.leyak_nearby_speed_factor)
            end
        else          
            if leyak_xray_hold_counter > 0 and ConfigLeyak.leyak_is_restricted_by_xray then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_by_xray_move_walk,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_sprint,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_speed_factor)
                leyak_xray_hold_counter = leyak_xray_hold_counter - 1
                if ConfigLeyak.log_distance_to_player then
                    Utils.log("XRAY Hold Counter: " .. leyak_xray_hold_counter)
                end
                -- [TODO] [Bugged] Sometimes entering combat state X-RAY stunned,
                -- locks the leyak in combat mode
            elseif ConfigLeyak.leyak_is_restricted_by_looking then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_move_walk, ConfigLeyak.leyak_is_restricted_move_sprint,
                    ConfigLeyak.leyak_is_restricted_move_speed_factor)
            elseif leyak_is_invisible and dist <= ConfigLeyak.leyak_invisible_distance then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_invisible_walk, ConfigLeyak.leyak_invisible_sprint,
                    ConfigLeyak.leyak_invisible_speed_factor)
                leyak_npc.HasBeenXrayed = true
                local playing = 0 ---@cast playing EAudioComponentPlayState
                leyak_npc:StartedSpeaking(playing)
                leyak_npc:UpdateBreathingAudio(playing)
                leyak_npc:OnCharacterSpeakingStart()
                leyak_npc.HasBeenXrayed = false
            else
                SetLeyakMoveSpeed(ConfigLeyak.leyak_nearby_walk, ConfigLeyak.leyak_nearby_sprint,
                    ConfigLeyak.leyak_nearby_speed_factor)
            end
        end
    end
end


local function Handle_ToggleCombatStateFX()
    -- Indicate the Leyak caught the player
    leyak_caught_player = true
end

local function Handle_SetLeyakOnCooldown(context, CooldownReductionMultiplier)
    leyak_director = context:get()
    admin_player = Utils.GetPlayerFromId(ConfigAdmin.admin_id)
    admin_player_controller = admin_player.MyPlayerController

    if leyak_evaded_by_player or leyak_was_dismissed or leyak_caught_player or ConfigLeyak.leyak_is_dismissed_by_looking then
        -- Player Success
        -- If the player evaded, dismissed via XRAY, or was caught, do not trigger a new event
        msg = string.format("%s Successfully Evaded the Leyak", leyak_target_name)
        admin_player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, msg, Enums.MsgColors.green,
            player_controller,
            false)
    else
        -- Player Failure
        -- The system de-spawned the Leyak because of the stuck timer, area transition/load, or other internal logic
        -- Reduce the Leyak Cooldown to force another chase immediately
        msg = string.format("%s failed evading the Leyak", leyak_target_name)
        admin_player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, msg, Enums.MsgColors.red,
            player_controller,
            false)
        CooldownReductionMultiplier:set(0.005)
    end
end

local function Handle_TriggerTargetLookedAway()
    local leyak_npc = GetValidLeyak()
    if Utils.IsValid(leyak_npc) then
        leyak_npc.ViewedByTarget = false

        LeyakDoRandomSpeech()

        dist = CalcLeyakDistanceToPlayer()
        if ConfigLeyak.log_distance_to_player then
            Utils.log("----------------------")
            Utils.log("Looked Away--Dist to Leyak:" .. dist)
        end
        leyak_npc.PotentiallyStuck = false
        leyak_npc.AbsolutelyStuck = false

        -- If Player has successfully evaded, force despawn
        if dist > ConfigLeyak.DistanceDifferenceToDespawn then
            if ConfigLeyak.log_distance_to_player then
                Utils.log("Player too far away, force despawn Leyak")
            end
            leyak_evaded_by_player = true
            SetLeyakMoveSpeed(0.01, 0.01, 0.01)
            leyak_npc.RequiredMegalightDuration = 2
            leyak_npc.HasBeenXrayed = true
            leyak_npc.ViewedByTarget = true
            leyak_npc.PrepareLeyakDespawn()
            return
        end

        -- Attempt Speech
        LeyakDoRandomSpeech()

        if leyak_xray_hold_counter > 0 and ConfigLeyak.leyak_is_restricted_by_xray then
            leyak_xray_hold_counter = leyak_xray_hold_counter - 1
        else
            if dist > ConfigLeyak.leyak_stalking_distance then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_stalking_walk, ConfigLeyak.leyak_stalking_sprint,
                    ConfigLeyak.leyak_stalking_speed_factor)
            elseif leyak_is_invisible and dist <= ConfigLeyak.leyak_invisible_distance then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_invisible_walk, ConfigLeyak.leyak_invisible_sprint,
                    ConfigLeyak.leyak_invisible_speed_factor)
                leyak_npc.HasBeenXrayed = true
                local playing = 0 ---@cast playing EAudioComponentPlayState
                leyak_npc:StartedSpeaking(playing)
                leyak_npc:UpdateBreathingAudio(playing)
                leyak_npc:OnCharacterSpeakingStart()
                leyak_npc.HasBeenXrayed = false
            else
                SetLeyakMoveSpeed(ConfigLeyak.leyak_nearby_walk, ConfigLeyak.leyak_nearby_sprint,
                    ConfigLeyak.leyak_nearby_speed_factor)
            end
        end
    end
end

-- Record if the Leyak was hit by an XRAY Tower or a hand-held light
local function Handle_OnMegalightHit(context, megalight, Tier)
    ml_type = megalight:get():GetFullName():sub(75, 94)
    -- i.e Deployed_Megalight_C_2147469838.MegalightComponent
    if ml_type == "Deployed_Megalight_C" then
        -- Hit By XRAY Tower
        leyak_was_xrayed_by_tower = true
        leyak_was_dismissed = true
        leyak_xray_struck_counter = ConfigLeyak.leyak_xray_dismissal_time + 1
        SetLeyakMoveSpeed(0.01, 0.01, 0.01)
        local leyak_npc = GetValidLeyak()
        if Utils.IsValid(leyak_npc) then
            leyak_npc.RequiredMegalightDuration = 2
            leyak_npc.HasBeenXrayed = true
            leyak_is_invisible = false
            -- Force Despawn and Handle Drop now, otherwise
            -- normal X-RAY logic will always drop essence
            leyak_npc.PrepareLeyakDespawn()
            leyak_drop_essence(leyak_npc)
        end
        leyak_xray_hold_counter = ConfigLeyak.leyak_is_restricted_by_xray_duration
    else -- Item_LightSource_Megalight_C_2147408010.MegalightComponent
        leyak_was_xrayed_by_tower = false
        leyak_was_xrayed_by_lamp = true
         -- No Change
    end
end



-- ============================================================
-- HOOKS
-- ============================================================

local function SetupOnGameStateHooks()

    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Meta/Abiotic_PlayerController.Abiotic_PlayerController_C:Request_SendTextChatMessage",
            Handle_Request_SendTextChatMessage
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_Request_SendTextChatMessage")
        end
    end)

    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Characters/NPCs/NPC_Leyak.NPC_Leyak_C:TriggerViewedByTarget",
            Handle_TriggerViewedByTarget
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_TriggerViewedByTarget")
        end
    end)


    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Characters/NPCs/NPC_Leyak.NPC_Leyak_C:TriggerTargetLookedAway",
            Handle_TriggerTargetLookedAway
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_TriggerTargetLookedAway")
        end
    end)

    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Characters/NPCs/NPC_Leyak.NPC_Leyak_C:OnMegalightHit",
            Handle_OnMegalightHit
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_OnMegalightHit")
        end
    end)

    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Characters/NPCs/NPC_Leyak.NPC_Leyak_C:ToggleCombatStateFX",
            Handle_ToggleCombatStateFX
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_ToggleCombatStateFX")
        end
    end)

    ExecuteWithDelay(2500, function()
        local okHook, errHook = pcall(RegisterHook,
            "/Game/Blueprints/Environment/Systems/LeyakDirectorComponent.LeyakDirectorComponent_C:SetLeyakOnCooldown",
            Handle_SetLeyakOnCooldown
        )
        if not okHook then
            Utils.error(string.format("Hook registration failed: %s", tostring(errHook)))
        else
            Utils.log("Hook registration success: Handle_SetLeyakOnCooldown")
        end
    end)

    -- New Leyak Just Dropped. Config the instance
    NotifyOnNewObject("/Game/Blueprints/Characters/NPCs/NPC_Leyak.NPC_Leyak_C", function(leyak)
        Handle_LeyakNotifyOnNewObject(leyak)
    end)

    -- Handle new Leyak Director
    NotifyOnNewObject("/Game/Blueprints/Environment/Systems/LeyakDirectorComponent.LeyakDirectorComponent_C", function(leyak_director)
        ExecuteWithDelay(5000, function()
            ExecuteInGameThread(function()
                Leyak_DIR = leyak_director
                leyak_director.LeyakCooldown = ConfigLeyak.leyak_cooldown
            end)
        end)
    end)
end


-- ============================================================
-- INIT
-- ============================================================


local function OnGameState(world)
    GameStateHookFired = true

    if not world:IsValid() then return end
    Utils.WorldCache(world)
    local fullName = world:GetFullName()
    local mapName = fullName and fullName:match("/Game/Maps/([^%.]+)")
    if not mapName then
        return
    end

    if not GameStateHookNotified then
        GameStateHookNotified = true
        SetupOnGameStateHooks()
    end
end



-- ReceiveBeginPlay
local function OnGameStateHook(Context)
    Utils.log("[MitB] Abiotic_Survival_GameState:ReceiveBeginPlay fired")

    local gameState = Context:get()
    if not gameState:IsValid() then return end

    local world = gameState:GetWorld()
    if world and world:IsValid() then
        OnGameState(world)
    end
end



-- PollForHooks
local function PollForHooks(attempts)
    attempts = attempts or 0

    if GameStateHookFired then return end

    ExecuteInGameThread(function()
        local base = FindFirstOf("GameStateBase")
        if not base:IsValid() then
            if attempts < 100 then
                ExecuteWithDelay(100, function()
                    PollForMissedHook(attempts + 1)
                end)
            else
                Log.Error("GameStateBase never found after %d attempts", attempts + 1)
            end
            return
        end

        -- Register hook once any GameState exists (even main menu)
        if not hookRegistered then
            local ok = pcall(RegisterHook,
                "/Game/Blueprints/Meta/Abiotic_Survival_GameState.Abiotic_Survival_GameState_C:ReceiveBeginPlay",
                OnGameStateHook
            )
            if ok then
                hookRegistered = true
                Utils.log("Hook registered")
            end
        end

        -- If already in gameplay map, handle current map manually
        local gameState = FindFirstOf("Abiotic_Survival_GameState_C")
        if gameState:IsValid() then
            Utils.log("Gameplay GameState found, invoking OnGameState")
            local world = gameState:GetWorld()
            if world and world:IsValid() then
                OnGameState(world)
            end
        end
    end)
end

-- Define Hooks
PollForHooks()

-- Completed
Utils.log("Loitering Leyak Mod Loaded")


-- Debug
ToggleKey = Key.F6
ToggleKeyModifiers = {}
if ToggleKey then
    local function ModDebugKey()
        ExecuteInGameThread(function()
            -- Test Stuff Here
        end)
    end


    RegisterKeyBind(ToggleKey, ToggleKeyModifiers, function()
        ModDebugKey()
    end)
end


