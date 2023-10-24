local function InitEpiphany()
    if Epiphany then
        local function onNewTurnoverShop()
            ReactionAPI:RequestReset()
        end
    
        Epiphany:AddExtraCallback(Epiphany.ExtraCallbacks.TURNOVER_POST_CREATE_SHOP, onNewTurnoverShop)
    end
    
    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, InitEpiphany)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, InitEpiphany)