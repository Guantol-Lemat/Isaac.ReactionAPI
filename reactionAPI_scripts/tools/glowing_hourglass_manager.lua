local DEBUG = false

local json = require("json")
local log = require("reactionAPI_scripts.tools.log")

local version = 1.0

-----------------------------------------------SETUP-----------------------------------------------

if GHManager then
    if GHManager.Version >= version then
        return
    else
        print("Older version of Glowing Hourglass Manager detected")
        print("Removing Glowing Hourglass Manager v" .. GHManager.Version)
        GHManager.Utilities:RemoveAllCallbacks()
    end
end


print("Initializing Glowing Hourglass Manager v" .. version)

GHManager = {
    Mod = RegisterMod("GlowingHourglassManager", 1),
    Version = version,
    Utilities = {},
    Callbacks = {}
}

local addedModCallbacks = {}

function GHManager.Mod:AddCallback(modCallback, callbackFunction, callbackArguments)
    Isaac.AddCallback(GHManager.Mod, modCallback, callbackFunction, callbackArguments)
    table.insert(addedModCallbacks, {
        Callback = modCallback,
        Function = callbackFunction,
    })
end

function GHManager.Mod:AddPriorityCallback(modCallback, callbackPriority, callbackFunction, callbackArguments)
    Isaac.AddPriorityCallback(GHManager.Mod, modCallback, callbackPriority, callbackFunction, callbackArguments)
    table.insert(addedModCallbacks, {
        Callback = modCallback,
        Function = callbackFunction,
    })
end

function GHManager.Utilities:RemoveAllCallbacks()
    for _, callbackData in pairs(addedModCallbacks) do
        Isaac.RemoveCallback(GHManager.Mod, callbackData.Callback, callbackData.Function)
    end
end

-----------------------------------------------ENUMS-----------------------------------------------

GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE = {}

GHManager.HourglassUpdate = {
    New_State = 1,
    New_State_Warped = 2,
    Rewind_Previous_Room = 3,
    Rewind_Current_Room = 4,
    New_Session = 5,
    Continued_Session = 6,
    New_Stage = 7,
    New_Absolute_Stage = 8,
    Previous_Stage_Last_Room = 9,
    Previous_Stage_Penultimate_Room = 10,
    Failed_Stage_Return = 11,
    Save_Pre_Room_Clear_State = 12,
    Save_Pre_Curse_Damage_Health = 13
}

GHManager.HourglassStateType = {
    State_Null = 0,
    Transition_To_Cleared_Room = 1,
    Transition_To_Uncleared_Room = 2,
    Cleared_Room = 3,
    Forget_Me_Now = 4,
    Session_Start = 5
}

---------------------------------------------VARIABLES---------------------------------------------

local game = Game()

local hasCursedDoorDamageBeenTaken = false
local wasNewStage = false
local wasPreviousFloorStateNull = false

local glowingHourglassTransactions = {}
local previousStageHourglassGameState = {
    Time = 0,
    Type = GHManager.HourglassStateType.State_Null
}

---------------------------------------------SAVE DATA---------------------------------------------

local ModReference = ReactionAPI

local defaultManagerData = {
    RewindStateType = GHManager.HourglassStateType.Session_Start
}

function GHManager:SaveManagerData(SaveDataTable)
    SaveDataTable.GHManagerData = {}
    SaveDataTable.GHManagerData.RewindStateType = previousStageHourglassGameState.Type
end

local function LoadGHManagerData(IsContinued)
    local GHManagerData = {}
    if IsContinued and ModReference:HasData() then
        local loadedData = json.decode(ModReference:LoadData())
        GHManagerData = loadedData["GHManagerData"] or defaultManagerData
    else
        GHManagerData = defaultManagerData
    end
    previousStageHourglassGameState.Type = GHManagerData.RewindStateType
end

---------------------------------------------UTILITIES---------------------------------------------

if REPENTOGON then
    GHManager.Utilities.CanStartTrueCoop = function()
        return Isaac.CanStartTrueCoop()
    end
else
    GHManager.Utilities.CanStartTrueCoop = function()
        return previousStageHourglassGameState.Type == GHManager.HourglassStateType.State_Null
    end
end

GHManager.Utilities.CanRewindToHome = function()
    return GHManager.Utilities.CanStartTrueCoop() and game:GetLevel():GetStage() == LevelStage.STAGE1_1
    -- The game only cares that LevelStage is 1, and that the CanStartTrueCoop flag is true, so even if you
    -- obtain a Forget Me Now in the first stage or go to Downpour/Dross I and, somehow keep the
    -- CanStartTrueCoop flag set to true, you will be taken to Home when you use Glowing Hourglass
    -- (R key also resets the CanStartTrueCoop flag to true)
end

---------------------------------------------------------------------------------------------------
-----------------------------------------------MAIN------------------------------------------------
---------------------------------------------------------------------------------------------------

local function HandleGlowingHourglassTransactions()
    local level = game:GetLevel()
    local shouldOverwriteHealthState = not (hasCursedDoorDamageBeenTaken and (game:GetRoom():GetType() == RoomType.ROOM_CURSE or level:GetRoomByIdx(level:GetPreviousRoomIndex()).Data.Type == RoomType.ROOM_CURSE))
    local updateType = nil
    hasCursedDoorDamageBeenTaken = false
    local isNewStage = not (game:GetLevel():GetStateFlag(LevelStateFlag.STATE_LEVEL_START_TRIGGERED))
    local transactionCount = #glowingHourglassTransactions

    ------------------------------------HANDLE NEW SESSIONS------------------------------------

    -- MC_POST_GAME_STARTED is not needed for New Sessions since we can figure out if the run IsContinued by checking if
    -- transactionCount <= 0 and isNewStage for a New Run and transactionCount <= 0 and not isNewStage for Continued Runs
    if transactionCount <= 0 then
        if isNewStage then
            table.insert(glowingHourglassTransactions, game.TimeCounter)
            previousStageHourglassGameState = {
                Time = game.TimeCounter,
                Type = GHManager.HourglassStateType.State_Null
            }
            updateType = GHManager.HourglassUpdate.New_Session
            Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
            wasNewStage = false
        else
            if not REPENTOGON then
                LoadGHManagerData(true)
            end
            if GHManager.Utilities.CanStartTrueCoop() then
                table.insert(glowingHourglassTransactions, game.TimeCounter)
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = GHManager.HourglassStateType.State_Null
                }
                updateType = GHManager.HourglassUpdate.New_Session
                Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
                wasNewStage = false
            else
                table.insert(glowingHourglassTransactions, game.TimeCounter)
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = GHManager.HourglassStateType.Session_Start
                }
                updateType = GHManager.HourglassUpdate.Continued_Session
                Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
                wasNewStage = false
            end
        end
        return
    end

    ----------------------------------HANDLE ROOM TRANSITIONS----------------------------------

    if game.TimeCounter > glowingHourglassTransactions[transactionCount] then
        if isNewStage then
            if previousStageHourglassGameState.Type == GHManager.HourglassStateType.State_Null then
                glowingHourglassTransactions = {game.TimeCounter}
                transactionCount = 1
                updateType = GHManager.HourglassUpdate.New_Absolute_Stage
                Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount, updateType)
                wasNewStage = true
            else
                table.insert(glowingHourglassTransactions, game.TimeCounter)
                updateType = GHManager.HourglassUpdate.New_Stage
                Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
                wasNewStage = true
            end
        else
            wasPreviousFloorStateNull = previousStageHourglassGameState.Type == GHManager.HourglassStateType.State_Null
            if transactionCount >= 2 then
                glowingHourglassTransactions = {glowingHourglassTransactions[transactionCount]}
                transactionCount = 1
            end
            table.insert(glowingHourglassTransactions, game.TimeCounter)

            if not game:GetRoom():IsClear() or game:GetRoom():IsFirstVisit() then
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = GHManager.HourglassStateType.Transition_To_Uncleared_Room
                }
                -- If you go to an uncleared room right before leaving, the state is saved
                -- and in the case that you revert to the previous Floor you will end up
                -- in the uncleared room when returning
            else
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = GHManager.HourglassStateType.Transition_To_Cleared_Room
                }
                -- If you go trough a cleared right before leaving, the state is saved to
                -- the moment you made the Room Transition but if you return to the previous
                -- floor you will be sent to the previous room relative to when you left
                -- this is regardless of if the previous room is Cleared or Not, so for
                -- example: you created a Trap Door in the starting room -> you go fight
                -- the Boss, but instead of killing it you escape using the Fool -> you
                -- exit the Stage. if you use Glowing Hourglass right after, you will
                -- be taken to the Boss Fight of the previous floor.
            end
            if level.LeaveDoor == -1 then
                updateType = GHManager.HourglassUpdate.New_State_Warped
            else
                updateType = GHManager.HourglassUpdate.New_State
            end
            -- Technically to detect a Warp you need to check for level.LeaveDoor == -1 and level.EnterDoor ~= -1
            -- but that extra is needed to account for Stage Transitions, and since we already account for them there
            -- is no need
            Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType, shouldOverwriteHealthState)
            wasNewStage = false
        end
        return
    end

    --------------------------------------HANDLE REWINDS---------------------------------------

    if wasNewStage then
        if previousStageHourglassGameState.Type == GHManager.HourglassStateType.State_Null then
            updateType = GHManager.HourglassUpdate.Failed_Stage_Return
            Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        elseif previousStageHourglassGameState.Type == GHManager.HourglassStateType.Transition_To_Cleared_Room then
            glowingHourglassTransactions = {previousStageHourglassGameState.Time}
            updateType = GHManager.HourglassUpdate.Previous_Stage_Penultimate_Room
            Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        else
            glowingHourglassTransactions = {previousStageHourglassGameState.Time}
            updateType = GHManager.HourglassUpdate.Previous_Stage_Last_Room
            Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        end
        wasNewStage = false
        return
    end
    -- In the unlikely situation that you can go trough multiple floors without ever leaving their
    -- respective starting room you will be transported back to the last "previous Floor State"
    -- even if it was at Basement 1 and you are currently at Sheol

    wasNewStage = false
    if wasPreviousFloorStateNull then
        previousStageHourglassGameState.Type = GHManager.HourglassStateType.State_Null
    end

    if transactionCount == 1 then
        updateType = GHManager.HourglassUpdate.Rewind_Current_Room
        Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount, updateType)
        return
    end

    glowingHourglassTransactions = {game.TimeCounter}
    updateType = GHManager.HourglassUpdate.Rewind_Previous_Room
    Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount, updateType, nil, wasPreviousFloorStateNull)
end

local function HandleGlowingHourglassPreClearState()
    previousStageHourglassGameState = {
        Time = game.TimeCounter,
        Type = GHManager.HourglassStateType.Cleared_Room
    }
    local transactionCount = #glowingHourglassTransactions
    Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, GHManager.HourglassUpdate.Save_Pre_Room_Clear_State, transactionCount)
end

local function HandleGlowingHourglassPlayerHealthState(_, _, _, DamageFlags)
    if DamageFlags & DamageFlag.DAMAGE_CURSED_DOOR ~= 0 and not hasCursedDoorDamageBeenTaken then
        local transactionCount = #glowingHourglassTransactions
        hasCursedDoorDamageBeenTaken = true
        Isaac.RunCallbackWithParam(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, GHManager.HourglassUpdate.Save_Pre_Curse_Damage_Health, transactionCount)
    end
end

local function ResetPreviousFloorStateToNull()
    previousStageHourglassGameState = {
        Time = game.TimeCounter,
        Type = GHManager.HourglassStateType.State_Null
    }
end

local function SetPreviousFloorStateToForget()
    if previousStageHourglassGameState.Type == GHManager.HourglassStateType.State_Null then
        return
    end
    previousStageHourglassGameState.Type = GHManager.HourglassStateType.Forget_Me_Now
    -- The game doesn't save the state when using forget me now, but instead it causes
    -- the previous floor rewind to become of Last_Room type, even when it would otherwise
    -- be of Penultimate_Room type, Unless it the Stage Return Fails.
end

local function ResetHourglassStateOnExit()
    hasCursedDoorDamageBeenTaken = false
    wasNewStage = false
    glowingHourglassTransactions = {}
end

GHManager.Mod:AddPriorityCallback(ModCallbacks.MC_POST_NEW_ROOM, CallbackPriority.IMPORTANT, HandleGlowingHourglassTransactions)

GHManager.Mod:AddPriorityCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, CallbackPriority.IMPORTANT, HandleGlowingHourglassPreClearState)

GHManager.Mod:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.IMPORTANT, HandleGlowingHourglassPlayerHealthState, EntityType.ENTITY_PLAYER)

GHManager.Mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, ResetPreviousFloorStateToNull, CollectibleType.COLLECTIBLE_R_KEY)

GHManager.Mod:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, SetPreviousFloorStateToForget, CollectibleType.COLLECTIBLE_FORGET_ME_NOW)

GHManager.Mod:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ResetHourglassStateOnExit)

if DEBUG then
    function ReactionAPI.DebugPrintHourglassTransaction()
        for transactionID, transactionTime in ipairs(glowingHourglassTransactions) do
            log.print("TransactionID: " .. transactionID .. ", Time: " .. transactionTime)
        end
    end

    ---------------------------------------CUSTOM CALLBACKS----------------------------------------

    local function PrintOnNewGHTransaction(_, TransactionID)
        log.print("New Glowing Hourglass Transaction: " .. TransactionID)
    end

    local function PrintOnNewGHWarpedTransaction(_, TransactionID)
        log.print("New Glowing Hourglass Warp: " .. TransactionID)
    end

    local function PrintOnDeletedGHTransaction(_, TransactionID, _, _, WasPreviousFloorStateNull)
        log.print("Deleted Glowing Hourglass Transaction: " .. TransactionID)
        log.print("Was Previous Floor State Null: " .. tostring(WasPreviousFloorStateNull))
    end

    local function PrintOnRevertedGHTransaction(_, TransactionID)
        log.print("Reverted Glowing Hourglass Transaction: " .. TransactionID)
    end

    local function PrintOnNewGHSession(_, TransactionID)
        log.print("New Glowing Hourglass Session: " .. TransactionID)
    end

    local function PrintOnContinuedGHSession(_, TransactionID)
        log.print("Continued Glowing Hourglass Session: " .. TransactionID)
    end

    local function PrintOnNewGHFloor(_, TransactionID)
        log.print("New Glowing Hourglass Floor: " .. TransactionID)
    end

    local function PrintOnNewGHAbsoluteFloor(_, TransactionID)
        log.print("New Glowing Hourglass Absolute Floor: " .. TransactionID)
    end

    local function PrintOnPreviousStageLastRoom(_, TransactionID)
        log.print("Previous Floor, Last Room: " .. TransactionID)
    end

    local function PrintOnPreviousStagePenultimateRoom(_, TransactionID)
        log.print("Previous Floor, Penultimate Room: " .. TransactionID)
    end

    local function PrintOnFailedStageReturn(_, TransactionID)
        log.print("Failed to Return to Previous Floor: " .. TransactionID)
    end

    local function PrintOnPreRoomClear(_, TransactionID)
        log.print("Pre Room Clear: " .. TransactionID)
    end

    local function PrintOnPreCursedDoorDamage(_, TransactionID)
        log.print("Pre Cursed Door Damage: " .. TransactionID)
    end

    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHTransaction, GHManager.HourglassUpdate.New_State)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHWarpedTransaction, GHManager.HourglassUpdate.New_State_Warped)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnDeletedGHTransaction, GHManager.HourglassUpdate.Rewind_Previous_Room)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnRevertedGHTransaction, GHManager.HourglassUpdate.Rewind_Current_Room)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHSession, GHManager.HourglassUpdate.New_Session)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnContinuedGHSession, GHManager.HourglassUpdate.Continued_Session)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHFloor, GHManager.HourglassUpdate.New_Stage)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHAbsoluteFloor, GHManager.HourglassUpdate.New_Absolute_Stage)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreviousStageLastRoom, GHManager.HourglassUpdate.Previous_Stage_Last_Room)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreviousStagePenultimateRoom, GHManager.HourglassUpdate.Previous_Stage_Penultimate_Room)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnFailedStageReturn, GHManager.HourglassUpdate.Failed_Stage_Return)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreRoomClear, GHManager.HourglassUpdate.Save_Pre_Room_Clear_State)
    ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreCursedDoorDamage, GHManager.HourglassUpdate.Save_Pre_Curse_Damage_Health)
end
