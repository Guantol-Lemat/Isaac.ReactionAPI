ReactionAPI.Interface = {}

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param Type ReactionAPI.Visibility @can be nil
--- @return ReactionAPI.QualityStatus
--- @see ReactionAPI.Visibility
--- @see ReactionAPI.QualityStatus
--- @usage if ReactionAPI.Interface.cGetBestQuality(ReactionAPI.Visibility.VISIBLE) >= ReactionAPI.QualityStatus.QUALITY_3 then
--              WePoggin()
--         end
ReactionAPI.Interface.cGetBestQuality = ReactionAPI.GetCollectibleBestQuality

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param Visibility ReactionAPI.Visibility @can be nil
--- @param Filter ReactionAPI.Filter @can be nil
--- @return table or integer @an integer is returned if both Visibility and Filter are ~= nil
--- @see ReactionAPI.Visibility
--- @usage cQualityStatus = ReactionAPI.Interface.cGetQualityStatus()
--         cVisibleQualityStatus = ReactionAPI.Interface.cGetQualityStatus(ReactionAPI.Visibility.VISIBLE)
--         cNewQualityStatus = ReactionAPI.Interface.cGetQualityStatus(nil, ReactionAPI.Visibility.NEW) 
--         cNewAbsoluteQualityStatus = ReactionAPI.Interface.cGetQualityStatus(ReactionAPI.Visibility.ABSOLUTE, ReactionAPI.Visibility.NEW)
ReactionAPI.Interface.cGetQualityStatus = ReactionAPI.GetCollectibleQualityStatus

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--  This function returns 4 tables each needed to understand the full situation in the current room
--- @return table
--- @usage collectibleData = ReactionAPI.Interface.GetCollectibleData()
ReactionAPI.Interface.GetCollectibleData = ReactionAPI.GetCollectibleData

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--  If there are multiple flags set in the partition and the AllPresent parameter can be set to true so that the function will only return true if all Qualities are present
--- @param PresencePartition ReactionAPI.QualityPartitions @if nil then the function will throw an ERROR and return nil
--- @param Visibility ReactionAPI.Visibility @default ReactionAPI.Visibility.VISIBLE
--- @param Filter ReactionAPI.Filter @default false
--- @param AllPresent boolean @default false
--- @return boolean
--- @see ReactionAPI.QualityPartitions
--- @see ReactionAPI.Visibility
--- @usage local partition = ReactionAPI.QualityPartitions.QUALITY_0 | ReactionAPI.QualityPartitions.QUALITY_1
--         if ReactionAPI.Interface.cCheckForPresence(partition, ReactionAPI.VISIBLE, false, false) then
--              --[[ custom code ]]
--         end
ReactionAPI.Interface.cCheckForPresence = ReactionAPI.CheckForCollectiblePresence

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--  If there are multiple flags set in the partition then the AllAbsent parameter can be set to true so that the function will only return true if all Qualities are present
--- @param AbsencePartition ReactionAPI.QualityPartitions @if nil then the function will throw an ERROR and return nil
--- @param Visibility ReactionAPI.Visibility @default ReactionAPI.Visibility.VISIBLE
--- @param Filter ReactionAPI.Filter @default false
--- @param AllAbsent boolean @default false
--- @return boolean
--- @see ReactionAPI.QualityPartitions
--- @see ReactionAPI.Visibility
--- @usage local partition = ReactionAPI.QualityPartitions.QUALITY_3 | ReactionAPI.QualityPartitions.QUALITY_4
--         if ReactionAPI.Interface.cCheckForAbsence(partition, ReactionAPI.VISIBLE, false, true) then
--              --[[ custom code ]]
--         end
ReactionAPI.Interface.cCheckForAbsence = ReactionAPI.CheckForCollectibleAbsence

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param SlotType ReactionAPI.SlotType @cannot be ALL, returns nil if not set
--- @return ReactionAPI.QualityStatus
--- @see ReactionAPI.SlotType
--- @see ReactionAPI.QualityStatus
ReactionAPI.Interface.slotGetBestQuality = ReactionAPI.GetSlotBestQuality

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param SlotType ReactionAPI.SlotType @cannot be ALL, returns nil if not set
--- @param Filter ReactionAPI.Filter @can be nil
--- @return table or integer @an integer is returned if Filter is ~= nil
--- @see ReactionAPI.SlotType
--- @see ReactionAPI.Filter
ReactionAPI.Interface.slotGetQualityStatus = ReactionAPI.GetSlotQualityStatus

--- This function should be called during MC_POST_UPDATE, with a priority that is not IMPORTANT or LATE
--  Calling this function anywhere else might lead to the retrieval of incorrect data
--- @param SlotType ReactionAPI.SlotType
--- @return table
ReactionAPI.Interface.GetSlotData = ReactionAPI.GetSlotData

--- Adds a condition, represented by a function that determines whether on that a collectible should be considered Blind
--  The Function must return a boolean
--  When the function is added as Global it is evaluated once, and if evaluated as true, it will cause All collectibles to be considered Blind
--  When the function is not added as Global it is evaluated for every collectible in the Room, and if evaluated as true, it will cause the single Collectible to be considered Blind
--- @param Function function @if the type of Function is not function then an ERROR will be thrown and nothing will be added
--- @param Global boolean @default true
--- @usage function IsCurseBlind()
--              return Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0
--         end
--         ReactionAPI.Interface.AddBlindCondition(IsCurseBlind, true)
ReactionAPI.Interface.AddBlindCondition = ReactionAPI.AddBlindCondition

--- Allows to set the variable that dictates whether or not Curse of The Blind should be evaluated as a Global Blind Condition
--  This variable uses tickets to determine how many mods are currently requesting that Curse of The Blind is not evaluated as a Global Blind Condition
--  Only when there are no tickets will the Curse return to be a Global Condition
--- @param IsGlobal boolean @default true
--- @param TicketID any @if nil then the function will throw an ERROR and the ticket will not be added/removed
--- @usage if (condition) then
--             ReactionAPI.Interface.SetIsCurseOfBlindGlobal(false, "MyModTicket")
--         else
--             ReactionAPI.Interface.SetIsCurseOfBlindGlobal(true, "MyModTicket")
--         end
ReactionAPI.Interface.SetIsCurseOfBlindGlobal = ReactionAPI.SetIsCurseOfBlindGlobal

--- Allows to set whether or not the function that determines if a Collectible is Blind, should perform any type of optimization to avoid a significant slowdowns
--  Should be used only if the optimization interferes with your mod's behavior
--  For reference the optimization prevents the main part of the function from being executed when the player is not in a Treasure room in an Alt Path Floor
--  This function also uses a Tickets to determine how many mods are currently requesting that the function should not perform any kind of optimization
--- @param Answer boolean @default true
--- @param TicketID any @if nil then the function will throw an ERROR and the ticket will not be added/removed
--- @usage if (condition) then
--             ReactionAPI.Interface.ShouldIsBlindPedestalBeOptimized(false, "MyModTicket")
--         else
--             ReactionAPI.Interface.ShouldIsBlindPedestalBeOptimized(true, "MyModTicket")
--         end
ReactionAPI.Interface.ShouldIsBlindPedestalBeOptimized = ReactionAPI.ShouldIsBlindPedestalBeOptimized

--- Blind Data is updated every LATE MC_POST_UPDATE, this is means that by design the Data collected by reaction API is using the
--  evaluation from the previous update rather than the current one.
--- @return table
ReactionAPI.Interface.GetBlindData = ReactionAPI.GetBlindData

--- Should be used if your mod is initializing new collectibles or rerolling already existing ones and the implemented detection systems Fails to either delete or reset them in the collectiblesInRoom table
--  If you are morphing an item in order to try and create a "Cycling" Item effect (Like Glitched Crow or Tainted Isaac) then you should not Request a Reset
--  You can also specify if a reset needs to be global (all items are deleted and recalculated) or if a specific pedestal needs to be reset
--  Out of the two the second method is preferred for both performance and compatibility with other mods, unless you are deleting/rerolling all pedestal, in which case a global reset is better
--- @param Global boolean @default true
--- @param EntityIDs table @can be nil if Global == true else the function will throw an ERROR and no reset will occur
--- @usage --[[ code that generates or changes an Item]]
--         itemsChanged = {25, 67, 300} -- Get Item Ids using EntityPickup.Index
--         if ReactionAPI then
--              ReactionAPI.Interface.RequestReset(false, itemsChanged)
--         end
ReactionAPI.Interface.RequestReset = ReactionAPI.RequestReset