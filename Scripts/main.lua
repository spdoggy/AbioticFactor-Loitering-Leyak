local Utils = require("utils")


-- git submodule add https://github.com/igromanru/AFUtils-UE4SS.git ./AFUtils
-- git submodule add https://github.com/igromanru/BaseUtils-UE4SS.git ./AFUtils/BaseUtils
-- git submodule update --init

-- TODO:
-- 1. Leyak Mods
--    a. Look into an additional mode where Leyak is invisible until XRAY'd
--    b. Mode Idea: Distracted Leyak - the Leyak switch targets midway
--    c. Strongly Consider separating this to it's own folder as well
--    d. Prevent Leyak Despawn on look away as long as it is within the limit
--    e. Teleport to player mode if it is > x meters away but less then the limit
-- 2. Complete Night Throne/BlackFogWeather disable feature
-- -- a. Randomize teleport options (bottom of inkwell, jailcell)
-- -- b. Still kinda crashy (weather related?),
-- --    test it on the dedicated server before release day
-- -- c. Stretch goal: actually spawn reaper model
-- 3. Goggles of Seeing for Jackal
--    --     TArray<FBuffDebuffRowHandle> AAbiotic_Character_ParentBP_C.CurrentSetBonuses;   could be useful,
--    need to scan all current buffs

  -- Multiple Modes:
    -- 1. Never stops on look anymore, need to run far enough away or use x-ray
    -- 2. Stops on Look but doesn't despawn
    -- 3. XRay Doesn't Dismiss, just stops and delays it for a bit
    -- 4. Invisible?
    -- 5. nOCLIP

-- ============================================================
-- CONFIG
-- ============================================================
Utils.log("--- BraverLeyak [BRVLYK] MOD LOADING ---\n")
local Config = require("../config")
local ConfigAdmin = require("../config_admin")
local ConfigLeyak = require("../config_leyak")




-- ============================================================
-- CONSTANTS
-- ============================================================
MOD_PREFIX = "[BRVLYK]"


-- ============================================================
-- STATE
-- ============================================================
local GameStateHookFired = false
local GameStateHookNotified = false
local leyak_xray_hold_counter = 0
local leyak_xray_struck_counter = 0
local leyak_status_print = 0
local leyak_was_xrayed = false
local leyak_was_xrayed_by_tower = false
local leyak_dropped_essence = false
local leyak_evaded_by_player = false
local leyak_was_dismissed = false
local leyak_caught_player = false
local leyak_target_name = ""

-- ============================================================
-- INSTANCES
-- ============================================================
local Leyak_NPC = nil -- @ANPC_Leyak_C;
local Leyak_DIR = nil -- @ULeyakDirectorComponent_C;

-- ============================================================
-- UTILITIES
-- ============================================================


-- TODO: Invisibility
-- ---@param actor class AActor*
-- function IsActorValid(actor)
--     if IsNotValid(actor) then return false end

--     local ok, npcData = pcall(function() return actor.NPCData end)
--     if not ok then return false end

--     -- Discard non-level loaded actors
--     if IsValid(npcData) then
--         local ok, levelLoaded = pcall(function()
--             return actor:IsLevelLoaded(false)
--         end)
--         if not ok or not levelLoaded then return false end
--     end

--     return true
-- end

-- function IsActorInvalid(actor)
--     return not IsActorValid(actor)
-- end

-- -- Capture -> re-resolve: the GC-safe way to carry a UObject across an async hop (EIGT / delayed work).
-- --   * A captured WRAPPER can be freed + slot-reused before the callback runs, and IsValid LIES then
-- --     (the GC family; pcall can't catch the resulting native AV - the Crash2-SpawnStressTest stack).
-- --   * So: take the object's PATH while it's alive, then StaticFindObject it at use-time - a freed
-- --     object resolves to nil, never a stale pointer (same defense as ASSETS.GetIfValid).
-- function ObjectPath(obj)
--     if IsNotValid(obj) then return nil end
--     local full
--     pcall(function() full = obj:GetFullName() end)
--     if not full then return nil end
--     return full:match("^%S+ (.+)$") or full -- strip the "ClassName " prefix
-- end

-- function ResolveByPath(path)
--     if not path then return nil end
--     local obj
--     pcall(function() obj = StaticFindObject(path) end)
--     if obj and obj:IsValid() then return obj end
--     return nil
-- end

-- function GetValidMesh(actor)
--     if IsActorInvalid(actor) then return nil end

--     -- pcall'd for the same reason as IsActorValid's NPCData read: this polls captured
--     -- wrappers (the ACTOR_READY WaitFor) and the read must not be the stale-wrapper deref.
--     local okM, mesh = pcall(function() return actor.Mesh end)
--     if not okM or IsNotValid(mesh) then return nil end
--     local ok, world = pcall(function() return mesh:GetWorld() end)
--     if not ok or not world then return nil end

--     return mesh
-- end

-- -- [RENDERER] Fade the whole body via the character master's "Opacity" scalar (1 solid, 0 gone).
-- -- If a fade doesn't show, the material's blend mode doesn't honour Opacity - not this code.

-- function SetMeshOpacity(actor, opacity)
--     local mesh = GetValidMesh(actor)
--     if not mesh then return end
--     pcall(function() mesh:SetScalarParameterValueOnMaterials(FName("Opacity"), opacity) end)
-- end

-- -- Step opacity across `steps` (a list of values), one every `stepMs` (default 500) - e.g.
-- -- { 0.8, 0.6, 0.4, 0.2, 0 } fades out over 2.5s. Each step re-checks validity, so it is safe to
-- -- kick off and let the actor die mid-fade.

-- function FadeMeshOpacity(actor, steps, stepMs)
--     if IsActorInvalid(actor) or not steps then return end
--     stepMs = stepMs or 500
--     for i, o in ipairs(steps) do
--         -- Utils.QueueWork(function()
--         --     if IsActorValid(actor) then SetMeshOpacity(actor, o) end
--         -- end, (i - 1) * stepMs)

--         ExecuteWithDelay(1000, function()
--             if IsActorValid(actor) then SetMeshOpacity(actor, o) end
--         end)
--     end
-- end

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



    player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "---", Enums.MsgColors.green,
        player_controller, false)


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
        local msg = "The Leyak has noticed you.."
        player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.red, msg, Enums.MsgColors.red,
            player_controller, false)
    end


    local msg_out = ""
    if max_key == 1 then
        if msg_fmt[1] == "HELP" or msg_fmt[1] == "help" then
            player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg,
                "Enter brvlyk_help for list of commands",
                Enums.MsgColors.white, player_controller, false)
        end

        if msg_fmt[1] == "brvlyk_help" then
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

        player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, "---", Enums.MsgColors.green,
            player_controller, false)
    end
end

--- Set the Leyak's Move Speed
---@param walk number
---@param sprint number
---@param time_dilation number
local function SetLeyakMoveSpeed(walk, sprint, time_dilation)

    local leyak_director = GetValidLeyakDir()
    if Utils.IsValid(leyak_director) then
        --ExecuteInGameThread(function()
        Utils.log("Setting Leyak MoveFactor: " .. time_dilation)
        local npc = leyak_director.ActiveStalkingNPC.NPCData
        npc.DefaultWalkSpeed_17_311EDFE249A63474E18512B1E0BA66D4 = walk
        npc.DefaultSprintSpeed_18_F44E4C8A4F87079E4A5710984C1DF4EC = sprint
        leyak_director.ActiveStalkingNPC.CustomTimeDilation = time_dilation
        --end)
    end
end

--- Calculate the Leyak's Distance to the target player
---@return number
local function CalcLeyakDistanceToPlayer()
    local dist = 0
    if Leyak_NPC ~= nil then
        Leyak_NPC.ViewedByTarget = false
        leyak_target_name = Leyak_NPC.TargetPlayer.MyPlayerState:GetPlayerName():ToString()
        local leyak_loc = Leyak_NPC:K2_GetActorLocation()
        local player_loc = Leyak_NPC.TargetPlayer:K2_GetActorLocation()
        local x_vector = (leyak_loc.X - player_loc.X) ^ 2
        local y_vector = (leyak_loc.Y - player_loc.Y) ^ 2
        local z_vector = (leyak_loc.Z - player_loc.Z) ^ 2
        dist = math.sqrt(x_vector + y_vector + z_vector)
    end
    return dist
end


---@param leyak ANPC_Leyak_C
local function Handle_LeyakNotifyOnNewObject(leyak)
    Leyak_NPC = leyak
    leyak_xray_struck_counter = 0
    leyak_xray_hold_counter = 0
    leyak_was_xrayed_by_tower = false
    leyak_evaded_by_player = false
    leyak_was_dismissed = false
    leyak_caught_player = false
    leyak_target_name = ""
    local leyak_director = GetValidLeyakDir()

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

        -- Handle Randomization
        if ConfigLeyak.leyak_is_behavior_randomized then
            local dice_roll

            dice_roll = math.random()
            ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket = (dice_roll >= (ConfigLeyak.leyak_random_trinket_pct_failure_chance / 100))

            dice_roll = math.random()
            ConfigLeyak.leyak_is_restricted_by_looking = (dice_roll <= (ConfigLeyak.leyak_random_restrict_on_look_chance / 100))

            dice_roll = math.random()
            ConfigLeyak.leyak_is_dismissed_by_looking = (dice_roll <= (ConfigLeyak.leyak_random_is_dismissed_by_looking_chance / 100))


            if ConfigLeyak.admin_messages_enabled then
                if not ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket then
                    msg = "Leyak is not fooled by the sensory companion!"
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.red)
                else
                    msg = "Leyak will be fooled by the sensory companion!"
                    Utils.AdminMessage(msg, MOD_PREFIX, Enums.MsgColors.blue, Enums.MsgColors.green)
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


local function Handle_TriggerViewedByTarget()
    -- Default overrides all other settings
    if ConfigLeyak.leyak_is_dismissed_by_looking then
        return
    end

    -- TODO
    -- if ConfigLeyak.leyak_can_be_invisible then
    --     FadeMeshOpacity(actor, 0.1, stepMs)
    -- end

    if Leyak_NPC ~= nil then
        local dist = CalcLeyakDistanceToPlayer()
        if ConfigLeyak.log_distance_to_player then
            Utils.log("----------------------")
            Utils.log("Viewed By Target -- Dist to Leyak:" .. dist)
        end

        if ConfigLeyak.leyak_is_dismissed_by_sensory_companion_trinket then
            if doesPlayerHaveBuff(Leyak_NPC.TargetPlayer, Enums.Buffs.Buff_Leyak360) then
                Leyak_NPC.HasBeenXrayed = true
            end
        end

        -- Prevent De-spawn
        Leyak_NPC.ViewedByTarget = false
        Leyak_NPC.DistanceDifferenceToDespawn = ConfigLeyak.DistanceDifferenceToDespawn

        -- Allow Leyak to Damage Even if Being Looked At
        --Leyak_NPC.DealDamageInfront = true
        Leyak_NPC.DamageSphere.SphereRadius = 400
        -- Leyak_NPC.PotentiallyStuck = false
        -- Leyak_NPC.AbsolutelyStuck = false

        -- Dismiss if hit by stationary tower
        if leyak_was_xrayed_by_tower then
            leyak_xray_struck_counter = ConfigLeyak.leyak_xray_dismissal_time + 1
            leyak_was_dismissed = true
        end

        -- Prepare to Dismiss the Leyak if the Max XRAY Time is Exceeded
        -- Otherwise, set the Required Duration to the Max XRAY Time
        if leyak_xray_struck_counter > ConfigLeyak.leyak_xray_dismissal_time then
            SetLeyakMoveSpeed(0.01, 0.01, 0.01)
            Leyak_NPC.RequiredMegalightDuration = 2
            Leyak_NPC.HasBeenXrayed = true
            Leyak_NPC.PrepareLeyakDespawn()
            Leyak_NPC:DropEssence()
            leyak_xray_hold_counter = ConfigLeyak.leyak_is_restricted_by_xray_duration
            leyak_was_dismissed = true
            return
        elseif leyak_xray_struck_counter > ConfigLeyak.leyak_xray_essense_time then
            Leyak_NPC:DropEssence()
        else
            Leyak_NPC.RequiredMegalightDuration = ConfigLeyak.leyak_xray_dismissal_time
        end


        if Leyak_NPC.HasBeenXrayed then
            --TODO - could this allow target switch?
            --ConfigLeyak.TargetPlayer = Leyak_NPC.TargetPlayer
            --Leyak_NPC.TargetPlayer = nil
            leyak_xray_struck_counter = leyak_xray_struck_counter + 1
            Leyak_NPC.HasBeenXrayed = false
            leyak_was_xrayed = true
            leyak_xray_hold_counter = ConfigLeyak.leyak_is_restricted_by_xray_duration

            -- Note: Originally XRAY Restriction was planned to allow the Layak to move if it was set False
            -- i.e allow the Leyak to move even while under the beam, a solution to this has not yet been found
            -- Currently setting leyak_is_restricted_by_xray to false will simply disable:
            --    1. the "stun" of leyak_is_restricted_by_xray_duration
            --    2. additional modifications to move speed, i.e leyak_is_restricted_by_xray_move_speed_factor

            -- TODO Debug
            print("HasBeenXrayed")

            if ConfigLeyak.leyak_is_restricted_by_xray then
                print("leyak_is_restricted_by_xray True")
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_by_xray_move_walk,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_sprint,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_speed_factor)
            elseif ConfigLeyak.leyak_is_restricted_by_looking then
                print("leyak_is_restricted_move_speed_factor")
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_move_walk, ConfigLeyak.leyak_is_restricted_move_sprint,
                    ConfigLeyak.leyak_is_restricted_move_speed_factor)
            else
                print("leyak_nearby_speed_factor")
                SetLeyakMoveSpeed(ConfigLeyak.leyak_nearby_walk, ConfigLeyak.leyak_nearby_sprint,
                    ConfigLeyak.leyak_nearby_speed_factor)
            end
        else          
            if leyak_xray_hold_counter > 0 and ConfigLeyak.leyak_is_restricted_by_xray then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_by_xray_move_walk,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_sprint,
                    ConfigLeyak.leyak_is_restricted_by_xray_move_speed_factor)
                leyak_xray_hold_counter = leyak_xray_hold_counter - 1
                Utils.log("XRAY Hold Counter: " .. leyak_xray_hold_counter)
            elseif ConfigLeyak.leyak_is_restricted_by_looking then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_is_restricted_move_walk, ConfigLeyak.leyak_is_restricted_move_sprint,
                    ConfigLeyak.leyak_is_restricted_move_speed_factor)
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
        -- The system despawned because of the stuck timer, area transition/load, or other internal logic
        -- Reduce the Leyak Cooldown to force another chase immediately
        msg = string.format("%s failed evading the Leyak", leyak_target_name)
        admin_player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, msg, Enums.MsgColors.red,
            player_controller,
            false)
        CooldownReductionMultiplier:set(0.005)
    end
end

local function Handle_TriggerTargetLookedAway()
    if Leyak_NPC ~= nil then
        Leyak_NPC.ViewedByTarget = false

        dist = CalcLeyakDistanceToPlayer()
        if ConfigLeyak.log_distance_to_player then
            Utils.log("----------------------")
            Utils.log("Looked Away--Dist to Leyak:" .. dist)
        end
        Leyak_NPC.PotentiallyStuck = false
        Leyak_NPC.AbsolutelyStuck = false

        -- If Player has successfully evaded, force despawn
        if dist > ConfigLeyak.DistanceDifferenceToDespawn then
            Utils.log("Player too far away, force despawn Leyak")
            leyak_evaded_by_player = true
            SetLeyakMoveSpeed(0.01, 0.01, 0.01)
            Leyak_NPC.RequiredMegalightDuration = 2
            Leyak_NPC.HasBeenXrayed = true
            Leyak_NPC.ViewedByTarget = true
            Leyak_NPC.PrepareLeyakDespawn()
            return
        end

        if leyak_xray_hold_counter > 0 and ConfigLeyak.leyak_is_restricted_by_xray then
            leyak_xray_hold_counter = leyak_xray_hold_counter - 1
        else
            if dist > ConfigLeyak.leyak_stalking_distance then
                SetLeyakMoveSpeed(ConfigLeyak.leyak_stalking_walk, ConfigLeyak.leyak_stalking_sprint,
                    ConfigLeyak.leyak_stalking_speed_factor)
            else
                SetLeyakMoveSpeed(ConfigLeyak.leyak_nearby_walk, ConfigLeyak.leyak_nearby_sprint,
                    ConfigLeyak.leyak_nearby_speed_factor)
            end
        end


        -- TODO: Crashing? Yes
        -- Seems like it is dangerous to try and overwrite one or both of these
        -- Leyak_NPC.StuckStartTime = 0
        -- Leyak_NPC.TimeAllowedToBeStuck = ConfigLeyak.TimeAllowedToBeStuck
    end
end

-- Record if the Leyak was hit by an XRAY Tower or a hand-held light
local function Handle_OnMegalightHit(context, megalight, Tier)
    ml_type = megalight:get():GetFullName():sub(75, 94)
    -- i.e Deployed_Megalight_C_2147469838.MegalightComponent
    --print(ml_type)
    if ml_type == "Deployed_Megalight_C" then
        -- Hit By XRAY Tower
        leyak_was_xrayed_by_tower = true
        leyak_was_dismissed = true
    else -- Item_LightSource_Megalight_C_2147408010.MegalightComponent
        -- No Change
    end
end



-- ============================================================
-- HOOKS
-- ============================================================

local function SetupOnGameStateHooks()
    --void Request_SendTextChatMessage(FString MessageToSend);
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


ToggleKey = Key.F6
ToggleKeyModifiers = {}

-- Setup Debug Hotkeys
if ToggleKey then
    local function BRVLYK_Debug()
        ExecuteInGameThread(function()
            Utils.log("Debug")
            local admin_player = Utils.GetPlayerFromId(ConfigAdmin.admin_id)
            local admin_player_controller = admin_player.MyPlayerController

            Utils.AdminMessage("Message!", MOD_PREFIX, Enums.MsgColors.bg, Enums.MsgColors.red)

            --local admin_player_name = Utils.GetPlayerName(admin_player)
            local admin_player_name = Utils.GetPlayerNameFromID(ConfigAdmin.admin_id)

            -- local msg = string.format("%s Test Message", admin_player_name)
            -- admin_player_controller:Local_DisplayTextChatMessage(MOD_PREFIX, Enums.MsgColors.bg, msg, Enums.MsgColors.green, player_controller, false)
        end)
    end

    RegisterKeyBind(ToggleKey, {}, function()
        BRVLYK_Debug()
    end)
end

Utils.log("Braver Leyak Mod Loaded")
