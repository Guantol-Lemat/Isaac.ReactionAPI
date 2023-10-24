--- It is Suggested that this function is only used during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param isBlind boolean @default false
--- @return ReactionAPI.QualityStatus
--- @see ReactionAPI.QualityStatus
--- @usage if ReactionAPI:GetCollectibleQuality() >= ReactionAPI.QualityStatus.QUALITY_3 then
--              WePoggin()
--         end
function ReactionAPI:GetCollectibleQuality(isBlind)
    if isBlind then
        return ReactionAPI.bestCollectibleQualityBlind
    else
        return ReactionAPI.bestCollectibleQuality
    end
end

--- It is Suggested that this function is only used during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--- @param isBlind boolean @default false
--- @return boolean
--- @usage if ReactionAPI:HasCollectibleQualityChanged and ReactionAPI:GetCollectibleQuality() < ReactionAPI.QualityStatus.QUALITY_3 then
--              DeactivatePoggin()
--         end
function ReactionAPI:HasCollectibleQualityChanged(isBlind)
    if isBlind then
        return ReactionAPI.changed_bestCollectibleQualityBlind
    else
        return ReactionAPI.changed_bestCollectibleQuality
    end
end

--- Checks that at least a specific item of the quality specified in Partition is present in the room
--  Should be used during MC_POST_UPDATE, so that data is accurate to that of the current frame
--  If the partition is meant to identify multiple qualities then the All parameter can be used to check if All the qualities are present (true), or if only at least one of the qualities is present (false) 
--- @param isBlind boolean @default false
--- @param Partition ReactionAPI.QualityPartitions
--- @param All boolean @default false
--- @return boolean
--- @see ReactionAPI.QualityPartitions
--- @usage local partition = ReactionAPI.QualityPartitions.QUALITY_3 | ReactionAPI.QualityPartitions.QUALITY_4
--         if ReactionAPI.CheckForPresence(false, partition, false) then
--              --[[ custom code ]]
--         end
function ReactionAPI:CheckForPresence(isBlind, Partition, All)
    if isBlind then
        if All then
            return ReactionAPI.cBlindQualityPresence & Partition == Partition
        else
            return ReactionAPI.cBlindQualityPresence & Partition ~= 0
        end
    else
        if All then
            return ReactionAPI.cQualityPresence & Partition == Partition
        else
            return ReactionAPI.cQualityPresence & Partition ~= 0
        end
    end
end

--- Checks if a specific it item of the quality specified in Partition is not present in the room
--  Should be used during MC_POST_UPDATE, so that data is accurate to that of the current frame
--  Everything that this function does can also be achieved by negating the previous function, however it has been introduced to improve readability by making the intention clear.
--- @param isBlind boolean @default false
--- @param Partition ReactionAPI.QualityPartitions
--- @param All boolean @default true
--- @return boolean
--- @see ReactionAPI.QualityPartitions
--- @usage local whitelist = ReactionAPI.QualityPartitions.QUALITY_0 | ReactionAPI.QualityPartitions.QUALITY_1
--         local blacklist = ReactionAPI.QualityPartitions.QUALITY_3 | ReactionAPI.QualityPartitions.QUALITY_4
--         if ReactionAPI.CheckforPresence(false, whitelist, false) and ReactionAPI.CheckForAbsence(false, blacklist, true) then
--              --[[ custom code ]]
--         end
function ReactionAPI:CheckForAbsence(isBlind, Partition, All)
    if isBlind then
        if not All then
            return ReactionAPI.cBlindQualityPresence & Partition ~= Partition
        else
            return ReactionAPI.cBlindQualityPresence & Partition == 0
        end
    else
        if not All then
            return ReactionAPI.cQualityPresence & Partition ~= Partition
        else
            return ReactionAPI.cQualityPresence & Partition == 0
        end
    end
end

--- Checks if the QualityStatus of collectibles has changed
--  you can use the BitFlag variable to detect changes in the Presence BitFlag (true) or to simply to detect if the BestQuality has changed
--- @param isBlind boolean @default false
--- @param BitFlag boolean @default false
--- @return boolean
function ReactionAPI:HasCollectibleStatusChanged(isBlind, BitFlag)
    if BitFlag then
        if isBlind then
            return ReactionAPI.changed_cBlindQualityPresence
        else
            return ReactionAPI.changed_cQualityPresence
        end
    else
        if isBlind then
            return ReactionAPI.changed_bestCollectibleQualityBlind
        else
            return ReactionAPI.changed_bestCollectibleQuality
        end
    end
end

--- Adds a condition, represented by a function that returns a boolean value that determines if a collectible should be considered Blind
--  When the function is added as Global it is evaluated once, and if true will cause All collectibles to be considered Blind
--  When the function is not added as Global it is evaluated as many times as the number of Collectibles in the room, and if true will cause the single Collectible to be considered Blind
--- @param Function function
--- @param Global boolean
--- @usage function IsCurseBlind()
--              return Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0
--         end
--         ReactionAPI:AddBlindCondition(IsCurseBlind, true)
function ReactionAPI:AddBlindCondition(Function, Global)
    if Global then
        table.insert(ReactionAPI.globalBlindConditions, 1, Function)
    else
        table.insert(ReactionAPI.blindCollectibleConditions, 1, Function)
    end
end

--- Allows to set the variable that dictates whether or not Curse of The Blind should be evaluated as a Global Blind Condition
--- @param Status boolean
function ReactionAPI:SetCurseOfBlindGlobalStatus(Status)
    ReactionAPI.globalCurseOfBlind = Status
end

--- Should be used if your mod is initializing new collectibles and the implemented detection systems Fails to enforce a Reset of the ReactionAPI.QualityStatus
--  A good example of this is the Epiphany Turnover Shops that do not get detected when created because the EntityEffect is not in the same Position as the Collectible
--  Reset Fails can only be detected if the new items are of Lower Quality than the previous ReactionAPI.QualityStatus
--  If you are morphing an item in order to try and create a "Cycling" Item effect (Like Glitched Crow or Tainted Isaac) then you should not Request a Reset 
--- @usage --[[ code that generates or changes an Item ]]
--         if ReactionAPI then
--              ReactionAPI:RequestReset()
--         end
function ReactionAPI:RequestReset()
    ReactionAPI.requestedReset = true
end

--- Simple Function that gives you the ID of the last collectible
--  Any collectible that is initialized with an ID higher than this is a Glitched Item
--- @return integer
function ReactionAPI:GetMaxCollectibleID()
    return ReactionAPI.MaxCollectibleID
end