local function InitTaintedTreasure()
    if TaintedTreasure then
        local eternalCandleID = Isaac.GetItemIdByName('Eternal Candle')
        local ticketID = "TaintedTreasureCompatibility"
        local cachedIsEternalCurseOfBlind = false

        local function IsEternalCurseOfBlind()
            return ReactionAPI.Utilities.AnyPlayerHasCollectible(eternalCandleID, false) and (Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0)
        end

        local function UpdateTickets()
            if IsEternalCurseOfBlind() then
                if cachedIsEternalCurseOfBlind == true then
                    return
                end
                ReactionAPI.SetIsCurseOfBlindGlobal(false, ticketID)
                ReactionAPI.ShouldIsBlindPedestalBeOptimized(false, ticketID)
                cachedIsEternalCurseOfBlind = true
                return
            end
            if cachedIsEternalCurseOfBlind == false then
                return
            end
            ReactionAPI.SetIsCurseOfBlindGlobal(true, ticketID)
            ReactionAPI.ShouldIsBlindPedestalBeOptimized(true, ticketID)
            cachedIsEternalCurseOfBlind = false
        end

        ReactionAPI:AddCallback(ModCallbacks.MC_POST_UPDATE, UpdateTickets)
    end

    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_GAME_STARTED, InitTaintedTreasure)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitTaintedTreasure) -- MC_POST_NEW_ROOM decided it didn't like this function