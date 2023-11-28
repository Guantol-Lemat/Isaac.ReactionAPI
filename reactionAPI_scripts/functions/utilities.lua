ReactionAPI.Utilities = {}

ReactionAPI.Utilities.GetTableLength = function(Table)
    local length = 0
    for _, _ in pairs(Table) do
        length = length + 1
    end
    return length
end

ReactionAPI.Utilities.AnyPlayerHasCollectible = function(CollectibleID, IgnoreModifiers)
    for playerNum = 0, Game():GetNumPlayers() do
        if Game():GetPlayer(playerNum):HasCollectible(CollectibleID, IgnoreModifiers) then
            return true
        end
    end
    return false
end

ReactionAPI.Utilities.GetMaxCollectibleID = function ()
    return ReactionAPI.MaxCollectibleID or nil
end

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