local function InitCursedCollection()
    if CURCOL then
        local curseOfTheBlight = Isaac.GetCurseIdByName("Curse of Blight")
        local BLIGHT_FLAG = 1 << (curseOfTheBlight - 1)

        local function IsCurseBlight()
            return Game():GetLevel():GetCurses() & BLIGHT_FLAG ~= 0
        end
    
        ReactionAPI:AddBlindCondition(IsCurseBlight, true)
    end
    
    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, InitCursedCollection)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, InitCursedCollection)