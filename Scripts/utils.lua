-- Note: Refer to the following to setup Lua syntax
-- https://docs.ue4ss.com/guides/using-custom-lua-bindings



-- ============================================================
-- CONFIG
-- ============================================================

local Config = require("../config")
local ConfigAdmin = require("../config_admin")
local Enums = require("enums")
local Utils = {}


-- ============================================================
-- INSTANCES
-- ============================================================
local TheWorld = CreateInvalidObject() ---@cast WorldCache UWorld
local LeyakNpcCache = CreateInvalidObject() -- @ANPC_Leyak_C;
local LeyakDirectorCache = CreateInvalidObject() -- @ULeyakDirectorComponent_C;
local AIDirectorCache = CreateInvalidObject() ---@cast AIDirectorCache AAbiotic_AIDirector_C

-- ============================================================
-- UTILITIES
-- ============================================================

---Determine if obj is valid
---@param obj UObject|any
---@return boolean
function Utils.IsValid(obj)
    return obj ~= nil and obj.IsValid ~= nil and obj:IsValid()
end


---Cache the world object
---@param world UWorld
function Utils.WorldCache(world)
    if Utils.IsValid(world) then
        TheWorld = world
    end
end

---Debug Logging
function Utils.log(message)
    if Config.Debug then
        print(message)
    end
end


---Error Logging
function Utils.error(message)
    print("Error: " .. message)
end

---Log a Vector
---@param vector FVector
---@param actor_name string
function Utils.log_vector(vector, actor_name)
    if Config.Debug then
        if actor_name then
            print(string.format("%s@X/Y/Z: %f, %f, %f", actor_name, vector.X, vector.Y, vector.Z))
        else
            print(string.format("X/Y/Z: %f, %f, %f", vector.X, vector.Y, vector.Z))
        end
    end
end

-- Split a str based on the separator character
---@param inputstr string
---@param sep string
---@return table
function Utils.split_str(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local tbl = {}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(tbl, str)
    end
    return tbl
end


---Get World.AuthorityGameMode
---@return AGameModeBase
function Utils.GetGameMode()
    if Utils.IsValid(TheWorld) and TheWorld.AuthorityGameMode then
        return TheWorld.AuthorityGameMode
    end
    return CreateInvalidObject() ---@type AGameModeBase
end

---Get the AI Director
---@return AAbiotic_AIDirector_C
function Utils.GetAiDirector()
    if Utils.IsValid(AIDirectorCache) then
        return AIDirectorCache
    end
    local gameMode = Utils.GetGameMode() ---@cast gameMode AAbiotic_Survival_GameMode_C
    if Utils.IsValid(gameMode) and gameMode.AI_Director then
        AIDirectorCache = gameMode.AI_Director
        return AIDirectorCache
    end

    Utils.error("[GetAiDirector]: Failed to get AiDirector")
    return CreateInvalidObject() ---@type AAbiotic_AIDirector_C
end

---Get the Leyak AI Director
---@return ULeyakDirectorComponent_C
function Utils.GetLeyakAiDirector()
    if Utils.IsValid(LeyakDirectorCache) then
        return LeyakDirectorCache
    end

    local ai_director = Utils.GetAiDirector()
    if Utils.IsValid(ai_director) then
        return ai_director.LeyakDirectorComponent
    end

    Utils.error("[GetLeyakAiDirector]: Failed to get AiDirector")
    return CreateInvalidObject() ---@type ULeyakDirectorComponent_C
end

---Get the current Leyak_NPC
---@return ANPC_Leyak_C
function Utils.GetLeyak()
    if Utils.IsValid(LeyakNpcCache) then
        return LeyakNpcCache
    end

    local ai_director = Utils.GetAiDirector()
    if Utils.IsValid(ai_director) then
        LeyakNpcCache = ai_director.ActiveLeyak
        return LeyakNpcCache
    end

    Utils.error("[GetLeyak]: Failed to get Leyak")
    return CreateInvalidObject() ---@type ANPC_Leyak_C
end

---Find a PlayerState object by the player_id
---@param player_id string|FString
---@return AAbiotic_PlayerState_C
function Utils.GetPlayerStateFromID(player_id)
    if type(player_id) == "userdata" and player_id:type() == "FString" then
        player_id = player_id:ToString()
    end
    
    if type(player_id) == "string" and player_id ~= "" then
        if Utils.IsValid(TheWorld) then
            local gameState = TheWorld.GameState ---@type AGameStateBase
            if Utils.IsValid(gameState) and gameState.PlayerArray then
                for i = 1, #gameState.PlayerArray do
                    local playerState = gameState.PlayerArray[i] ---@cast playerState AAbiotic_PlayerState_C
                    if playerState.UniquePlayerID and playerState.UniquePlayerID:ToString() == player_id then
                        return playerState
                    end
                end
            end
        end
    end
    return CreateInvalidObject() ---@type AAbiotic_PlayerState_C
end

---Find a player by the player_id
---@param player_id FString|string
---@return AAbiotic_PlayerCharacter_C
function Utils.GetPlayerFromId(player_id)
    local playerState = Utils.GetPlayerStateFromID(player_id)
    if Utils.IsValid(playerState) and playerState.PawnPrivate then
        return playerState.PawnPrivate ---@type AAbiotic_PlayerCharacter_C
    end
    return CreateInvalidObject() ---@type AAbiotic_PlayerCharacter_C
end

---Lookup a player name by the player_id
---@param player_id FString|string
---@return string
function Utils.GetPlayerNameFromID(player_id)
    local playerState = Utils.GetPlayerStateFromID(player_id)
    if Utils.IsValid(playerState) then
        return playerState:GetPlayerName():ToString() ---@type string
    end
    return ""
end

---Lookup a player name for a valid PlayerChar
---@param player AAbiotic_PlayerCharacter_C
---@return string
function Utils.GetPlayerName(player)
    if Utils.IsValid(player) then
        return player.MyPlayerState:GetPlayerName():ToString()
    end
    return ""
end

---Get the Admin Player from ConfigAdmin
---@return AAbiotic_PlayerCharacter_C
function Utils.GetAdminPlayer()
    msg_prefix = msg_prefix or ""
    local admin_player = Utils.GetPlayerFromId(ConfigAdmin.admin_id)

    if Utils.IsValid(admin_player.MyPlayerController) then
        return admin_player
    end
    return CreateInvalidObject() ---@type AAbiotic_PlayerCharacter_C
end

---Send a text chat message to the admin player only
---@param msg string Message to Send
---@param msg_prefix FString|string Prefix of Message to Send, i.e name of the Mod
---@param prefix_color table Message prefix color
---@param msg_color table Message color
function Utils.AdminMessage(msg, msg_prefix, prefix_color,  msg_color)
    msg_prefix = msg_prefix or ""
    local admin_player = Utils.GetPlayerFromId(ConfigAdmin.admin_id)
    if Utils.IsValid(admin_player.MyPlayerController) then
        local admin_player_controller = admin_player.MyPlayerController    
        admin_player_controller:Local_DisplayTextChatMessage(msg_prefix, prefix_color, msg, msg_color, admin_player_controller, false)
        Utils.log(msg_prefix .. msg)
    end
end

---Send a text chat message to the player, Overload of Local_DisplayTextChatMessage
---@param player_controller AAbiotic_PlayerController_C Player message recipient (direct via PlayerController)
---@param msg string Message to Send
---@param msg_prefix string|FString Prefix of Message to Send, i.e name of the Mod
---@param prefix_color table Message prefix color
---@param msg_color table Message color
function Utils.PlayCtrlTextChatMessage(player_controller, msg, msg_prefix, prefix_color,  msg_color)
    msg_prefix = msg_prefix or ""
    if Utils.IsValid(player_controller) then
        player_controller:Local_DisplayTextChatMessage(msg_prefix, prefix_color, msg, msg_color, player_controller, false)
        Utils.log(msg_prefix .. msg)
    end
end

---Send a text chat message to the player, Overload of Local_DisplayTextChatMessage
---@param player AAbiotic_PlayerCharacter_C Player message recipient (via PlayerCharacter)
---@param msg string Message to Send
---@param msg_prefix string Prefix of Message to Send, i.e name of the Mod
---@param prefix_color table Message prefix color
---@param msg_color table Message color
function Utils.PlayTextChatMessage(player, msg, msg_prefix, prefix_color,  msg_color)
    msg_prefix = msg_prefix or ""

    if Utils.IsValid(player) then
        local player_controller = player.MyPlayerController
        if Utils.IsValid(player_controller) then
            Utils.PlayCtrlTextChatMessage(player_controller, msg, msg_prefix, prefix_color,  msg_color)
        end
    end
end

Utils.AssetCache = {}

function Utils.LoadAssets(path, callback)

    local obj = StaticFindObject(path)
    if obj and Utils.IsValid(obj) then
        Utils.AssetCache[path] = obj
        callback(obj)
        return
    end


    -- drop the invalid wrapper before reloading
    -- if cached then ASSETS.Cache[path] = nil end 

    -- Already loading: park the callback
    -- if ASSETS.Loading[path] then
    --     ASSETS.Waiters[path] = ASSETS.Waiters[path] or {}
    --     table.insert(ASSETS.Waiters[path], callback)
    --     return
    -- end

    -- ASSETS.Loading[path] = true
    -- ASSETS.Waiters[path] = { callback }

    ExecuteInGameThread(function()
        -- Freeze breadcrumb (SETTINGS.DEBUG_FREEZE_TRACE reporting; see TickManager).
        --   * A cold LoadAsset here is a BLOCKING load - if the process hangs inside it,
        --     the watchdog names the asset.
        -- STATE.LastWork = "EIGT LoadAsset " .. path
        -- STATE.LastWorkDone = false

        local asset, found, loaded = LoadAsset(path)
        -- STATE.LastWorkDone = true

        if found and loaded and Utils.IsValid(asset) then
            Utils.AssetCache[path] = asset

            -- COLD LOAD: we got here only because the cache and StaticFindObject both missed,
            -- so this asset genuinely wasn't resident. Logging the path makes GC measurable -
            -- the same path cold-loading twice in one session means it was collected in
            -- between, which is what AssetKeeper exists to prevent. UE4SS's own "Asset loaded"
            -- line carries no path, so it can't tell a first load from a re-load.
            Utils.log("ASSETS cold-load: " .. path)
        else
            Utils.error("ASSETS failed to load: " .. path)
            Utils.AssetCache[path] = nil
        end

        -- local waiters = ASSETS.Waiters[path] or {}
        -- ASSETS.Loading[path] = nil
        -- ASSETS.Waiters[path] = nil
        local waiters = {path}
        -- STATE.LastWork = "EIGT LoadAsset-cb " .. path
        -- STATE.LastWorkDone = false
        for _, cb in ipairs(waiters) do
            local ok, err = pcall(callback, path)
            if not ok then
                Utils.error("ASSETS callback error: " .. tostring(err))
            end
        end
        --STATE.LastWorkDone = true
    end)
end


function LoadAsync(paths, finalCallback)
    local remaining = #paths
    local results = {}

    if remaining == 0 then
        finalCallback(results)
        return
    end

    for _, path in ipairs(paths) do
        Utils.LoadAssets(path, function(asset)
            results[path] = asset
            remaining = remaining - 1
            if remaining == 0 then
                finalCallback(results)
            end
        end)
    end
end


function Utils.PlaySFX(snd_path, player, volume, start_delay, stop_delay)


    LoadAsync({ snd_path }, function()
        local gs = StaticFindObject("/Script/Engine.Default__GameplayStatics")

        -- local gs = GetGameplayStatics()
        local world = TheWorld
        
        --local sound = GetIfValid(snd_path)
        local sound = StaticFindObject(snd_path)
        if sound and Utils.IsValid(sound) then
    
            --player:Client_Play2DSoundEffect(sound)
            --player:Client_UpdateUISound(TEnumAsByte<E_ResultState::Type> State, class USoundBase* Sound);

            if not Utils.IsValid(sound) then return end

                if stop_delay then
                    local comp
                    -- (World, Sound, Vol, Pitch, StartTime, Concurrency, bPersistAcrossLevel, bAutoDestroy)
                    pcall(function() comp = gs:CreateSound2D(world, sound, volume, 1.0, 0.0, nil, false, false) end)
                    if Utils.IsValid(comp) then
                        pcall(function() comp:Play(0.0) end)
                        ExecuteWithDelay(stop_delay, function()
                            pcall(function() comp:Stop(0.0) end)
                        end)
                    end
                else
                    -- (World, Sound, Vol, Pitch, StartTime, Concurrency, OwningController, bIsUISound)
                    pcall(function() 
                        gs:PlaySound2D(world, sound, volume, 1.0, 0.0, nil, nil, true)
                    end)
                end
        end
    end)
end

---Play Sound at Locating using GameplayStatics
function Utils.PlaySoundAtLocation(snd_path, location, rotation, vol, pitch, start_time)
    LoadAsync({ snd_path }, function()
        local gs = StaticFindObject("/Script/Engine.Default__GameplayStatics")
        local world = TheWorld
        local sound = StaticFindObject(snd_path)
        if sound and Utils.IsValid(sound) then            
            gs:PlaySoundAtLocation(world, sound, location, rotation, vol, pitch, start_time, nil, nil, nil, nil)
        end
    end)
end

return Utils