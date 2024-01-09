local log = require("reactionAPI_scripts.tools.log")

ReactionAPI.Utilities = {}

local function DeepCopy(Table)
    if type(Table) ~= "table" then
        return Table
    end

    local final = setmetatable({}, getmetatable(Table))
    for i, v in pairs(Table) do
        final[DeepCopy(i)] = DeepCopy(v)
    end

    return final
end

ReactionAPI.Utilities.DeepCopy = DeepCopy

ReactionAPI.Utilities.GetTableLength = function(Table)
    local length = 0
    for _, _ in pairs(Table) do
        length = length + 1
    end
    return length
end

if REPENTOGON then
    ReactionAPI.Utilities.AnyPlayerHasCollectible = function(CollectibleID, IgnoreModifiers)
        PlayerManager.AnyoneHasCollectible(CollectibleID)
    end
else
    ReactionAPI.Utilities.AnyPlayerHasCollectible = function(CollectibleID, IgnoreModifiers)
        for playerNum = 0, Game():GetNumPlayers() do
            if Game():GetPlayer(playerNum):HasCollectible(CollectibleID, IgnoreModifiers) then
                return true
            end
        end
        return false
    end
end

if REPENTOGON then
    ReactionAPI.Utilities.AnyPlayerHasTrinket = function(TrinketID, IgnoreModifiers)
        PlayerManager.AnyoneHasTrinket(TrinketID)
    end
else
    ReactionAPI.Utilities.AnyPlayerHasTrinket = function(TrinketID, IgnoreModifiers)
        for playerNum = 0, Game():GetNumPlayers() do
            if Game():GetPlayer(playerNum):HasTrinket(TrinketID, IgnoreModifiers) then
                return true
            end
        end
        return false
    end
end

ReactionAPI.Utilities.AnyPlayerHasTrinket = function(TrinketID, IgnoreModifiers)
    for playerNum = 0, Game():GetNumPlayers() do
        if Game():GetPlayer(playerNum):HasTrinket(TrinketID, IgnoreModifiers) then
            return true
        end
    end
    return false
end

ReactionAPI.Utilities.GetMaxCollectibleID = function ()
    return ReactionAPI.MaxCollectibleID or nil
end

ReactionAPI.Utilities.CanBlindCollectiblesSpawnInTreasureRoom = function()
    return Game():GetLevel():GetStageType() >= StageType.STAGETYPE_REPENTANCE or ReactionAPI.Utilities.AnyPlayerHasTrinket(TrinketType.TRINKET_BROKEN_GLASSES, false)
end

ReactionAPI.Utilities.CheckForPresence = function(PresencePartition, TargetPartition, AllPresent)
    if PresencePartition < 0x00 then
        log.error("An invalid PresencePartition was passed", "CheckForPresence")
        return
    end
    if TargetPartition < 0x00 then
        log.error("An invalid TargetPartition was passed", "CheckForPresence")
        return
    end

    if AllPresent then
        return TargetPartition & PresencePartition == PresencePartition
    else
        return TargetPartition & PresencePartition ~= 0
    end
end

ReactionAPI.Utilities.CheckForAbsence = function(AbsencePartition, TargetPartition, AllAbsent)
    if AbsencePartition < 0x00 then
        log.error("An invalid AbsencePartition was passed", "CheckForAbsence")
        return
    end
    if TargetPartition < 0x00 then
        log.error("An invalid AbsencePartition was passed", "CheckForAbsence")
        return
    end

    if AllAbsent then
        return TargetPartition & AbsencePartition == 0
    else
        return TargetPartition & AbsencePartition ~= AbsencePartition
    end
end