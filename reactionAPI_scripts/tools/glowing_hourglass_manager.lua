local DEBUG = true

local log = require("reactionAPI_scripts.tools.log")
local game = Game()

local hasCursedDoorDamageBeenTaken = false
local wasNewStage = false
local hasGameStarted = false

local glowingHourglassTransactions = {}
local previousStageHourglassGameState = {
    Time = 0,
    Type = ReactionAPI.HourglassStateType.State_Null
}

local function HandleGlowingHourglassTransactions()
    print("Handling Transactions")
    if not hasGameStarted then
        print("Game Hasn't Started")
        return
    end
    print("Game Has Started")
    local shouldOverwriteHealthState = not (hasCursedDoorDamageBeenTaken and game:GetRoom():GetType() == RoomType.ROOM_CURSE)
    local updateType = nil
    hasCursedDoorDamageBeenTaken = false
    local isNewStage = not (game:GetLevel():GetStateFlag(LevelStateFlag.STATE_LEVEL_START_TRIGGERED))
    local transactionCount = #glowingHourglassTransactions

    ------------------------------------HANDLE NEW SESSIONS------------------------------------

    if transactionCount <= 0 then
        print("In new Session")
        if ReactionAPI.Utilities.CanStartTrueCoop() then
            table.insert(glowingHourglassTransactions, game.TimeCounter)
            previousStageHourglassGameState = {
                Time = game.TimeCounter,
                Type = ReactionAPI.HourglassStateType.State_Null
            }
            updateType = ReactionAPI.HourglassUpdate.New_Session
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
            wasNewStage = false
        else
            table.insert(glowingHourglassTransactions, game.TimeCounter)
            previousStageHourglassGameState = {
                Time = game.TimeCounter,
                Type = ReactionAPI.HourglassStateType.Session_Start
            }
            updateType = ReactionAPI.HourglassUpdate.New_Continued_Session
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
            wasNewStage = false
        end
        return
    end

    ----------------------------------HANDLE ROOM TRANSITIONS----------------------------------

    if game.TimeCounter > glowingHourglassTransactions[transactionCount] then
        print("In Transitions")
        if isNewStage then
            if previousStageHourglassGameState.Type == ReactionAPI.HourglassStateType.State_Null then
                glowingHourglassTransactions = {game.TimeCounter}
                transactionCount = 1
                updateType = ReactionAPI.HourglassUpdate.New_Absolute_Stage
                Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount, updateType)
                wasNewStage = true
            else
                table.insert(glowingHourglassTransactions, game.TimeCounter)
                updateType = ReactionAPI.HourglassUpdate.New_Stage
                Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType)
                wasNewStage = true
            end
        else
            if transactionCount >= 2 then
                glowingHourglassTransactions = {glowingHourglassTransactions[transactionCount]}
                transactionCount = 1
            end
            table.insert(glowingHourglassTransactions, game.TimeCounter)
            if not game:GetRoom():IsClear() then
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = ReactionAPI.HourglassStateType.Transition_To_Uncleared_Room
                }
                -- If you go to an uncleared room right before leaving, the state is saved
                -- and in the case that you revert to the previous Floor you will end up
                -- in the uncleared room when returning
            else
                previousStageHourglassGameState = {
                    Time = game.TimeCounter,
                    Type = ReactionAPI.HourglassStateType.Transition_To_Cleared_Room
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
            updateType = ReactionAPI.HourglassUpdate.New
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount + 1, updateType, shouldOverwriteHealthState)
            wasNewStage = false
        end
        return
    end

    --------------------------------------HANDLE REWINDS---------------------------------------

    print("In Rewinds")

    if wasNewStage then
        glowingHourglassTransactions = {previousStageHourglassGameState.Time}
        if previousStageHourglassGameState.Type == ReactionAPI.HourglassStateType.State_Null then
            updateType = ReactionAPI.HourglassUpdate.Failed_Stage_Return
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        elseif previousStageHourglassGameState.Type == ReactionAPI.HourglassStateType.Transition_To_Cleared_Room then
            glowingHourglassTransactions = {previousStageHourglassGameState.Time}
            updateType = ReactionAPI.HourglassUpdate.Previous_Stage_Penultimate_Room
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        else
            glowingHourglassTransactions = {previousStageHourglassGameState.Time}
            updateType = ReactionAPI.HourglassUpdate.Previous_Stage_Last_Room
            Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, 1, updateType)
        end
        wasNewStage = false
        return
    end
    -- In the unlikely situation that you can go trough multiple floors without ever leaving their
    -- respective starting room you will be transported back to the last "previous Floor State"
    -- even if it was at Basement 1 and you are currently at Sheol

    wasNewStage = false

    if transactionCount == 1 then
        updateType = ReactionAPI.HourglassUpdate.Reverted
        Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, updateType, transactionCount, updateType)
        return
    end

    glowingHourglassTransactions = {game.TimeCounter}
    Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, ReactionAPI.HourglassUpdate.Deleted, transactionCount)
end

local function HandleGlowingHourglassPreClearState()
    local transactionCount = #glowingHourglassTransactions
    Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, ReactionAPI.HourglassUpdate.Save_Pre_Room_Clear_State, transactionCount)
end

local function HandleGlowingHourglassPlayerHealthState(_, _, _, DamageFlags)
    if DamageFlags & DamageFlag.DAMAGE_CURSED_DOOR ~= 0 and not hasCursedDoorDamageBeenTaken then
        local transactionCount = #glowingHourglassTransactions
        hasCursedDoorDamageBeenTaken = true
        Isaac.RunCallbackWithParam(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, ReactionAPI.HourglassUpdate.Save_Pre_Curse_Damage_Health, transactionCount)
    end
end

local function onGameStart()
    hasGameStarted = true
    HandleGlowingHourglassTransactions()
end

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_NEW_ROOM, CallbackPriority.IMPORTANT, HandleGlowingHourglassTransactions)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_GAME_STARTED, CallbackPriority.LATE, onGameStart)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_PRE_SPAWN_CLEAN_AWARD, CallbackPriority.IMPORTANT, HandleGlowingHourglassPreClearState)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, CallbackPriority.IMPORTANT, HandleGlowingHourglassPlayerHealthState, EntityType.ENTITY_PLAYER)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, function()
    hasCursedDoorDamageBeenTaken = false
    wasNewStage = false
    glowingHourglassTransactions = {}
    hasGameStarted = false
end)

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

    local function PrintOnDeletedGHTransaction(_, TransactionID)
        log.print("Deleted Glowing Hourglass Transaction: " .. TransactionID)
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

    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHTransaction, ReactionAPI.HourglassUpdate.New)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnDeletedGHTransaction, ReactionAPI.HourglassUpdate.Deleted)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnRevertedGHTransaction, ReactionAPI.HourglassUpdate.Reverted)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHSession, ReactionAPI.HourglassUpdate.New_Session)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnContinuedGHSession, ReactionAPI.HourglassUpdate.Continued_Session)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHFloor, ReactionAPI.HourglassUpdate.New_Stage)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnNewGHAbsoluteFloor, ReactionAPI.HourglassUpdate.New_Absolute_Stage)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreviousStageLastRoom, ReactionAPI.HourglassUpdate.Previous_Stage_Last_Room)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreviousStagePenultimateRoom, ReactionAPI.HourglassUpdate.Previous_Stage_Penultimate_Room)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnFailedStageReturn, ReactionAPI.HourglassUpdate.Failed_Stage_Return)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreRoomClear, ReactionAPI.HourglassUpdate.Save_Pre_Room_Clear_State)
    ReactionAPI:AddCallback(ReactionAPI.ModCallbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, PrintOnPreCursedDoorDamage, ReactionAPI.HourglassUpdate.Save_Pre_Curse_Damage_Health)
end
