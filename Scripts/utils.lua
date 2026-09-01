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
local Leyak_NPC = nil -- @ANPC_Leyak_C;
local Leyak_DIR = nil -- @ULeyakDirectorComponent_C;
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

-- Get the AI Director
function Utils.GetAiDirector()
    if Utils.IsValid(AIDirectorCache) then
        return AIDirectorCache
    end
    local gameMode = Utils.GetGameMode() ---@cast gameMode AAbiotic_Survival_GameMode_C
    if Utils.IsValid(gameMode) and gameMode.AI_Director then
        AIDirectorCache = gameMode.AI_Director
    end
    return AIDirectorCache
end

---Get the Leyak AI Director
---@return ULeyakDirectorComponent_C
function Utils.GetLeyakAiDirector()
    local ai_director = Utils.GetAiDirector()
    if Utils.IsValid(ai_director) then
        return ai_director.LeyakDirectorComponent
    end
    
    Utils.error("[GetLeyakAiDirector]: Failed to get AiDirector")
    return CreateInvalidObject() ---@type ULeyakDirectorComponent_C
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

---Send a text chat message to the admin player only
---@param msg string Message to Send
---@param msg_prefix string Prefix of Message to Send, i.e name of the Mod
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
---@param msg_prefix string Prefix of Message to Send, i.e name of the Mod
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



return Utils