---------------------------------------------------------------------------------------------------
---------------------------------------------VARIABLES---------------------------------------------
---------------------------------------------------------------------------------------------------

-----------------------------------------------DEBUG-----------------------------------------------

local PROFILE = false
local updateCycle_ProfileTimeStart = Isaac.GetTime()
local numCollectibleUpdates = 0

----------------------------------------------CONTEXT----------------------------------------------

local evaluateGlobally = true
local evaluatePerCollectible = false
local visible = ReactionAPI.Context.Visibility.VISIBLE
local blind = ReactionAPI.Context.Visibility.BLIND
local absolute = ReactionAPI.Context.Visibility.ABSOLUTE
local newPickupsOnly = ReactionAPI.Context.Filter.NEW
local everyPickup = ReactionAPI.Context.Filter.ALL
local global = true

---------------------------------------------CONSTANTS---------------------------------------------

local blindCollectibleSprite = Sprite()
blindCollectibleSprite:Load("gfx/005.100_collectible.anm2", true)
blindCollectibleSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/questionmark.png")
blindCollectibleSprite:LoadGraphics()

-----------------------------------------------FLAGS-----------------------------------------------

local globallyBlind = false
local curseOfBlind = false -- ONLY FOR REPENTOGON
local isCurseOfBlindNotGlobal_Tickets = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT
local shouldIsBlindPedestalNotOptimize_Tickets = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT

local onCollectibleUpdate_FirstExecution = true
local requestedGlobalReset = false -- API EXPOSED -- WRITE ONLY
local delayRequestedGlobalReset = false
local requestedPickupResets = {} -- API EXPOSED -- WRITE ONLY

---------------------------------------------AUXILIARY---------------------------------------------

local poofPositions = {}
local cachedOptionGroup = {}
local wipedOptionGroups = {}
local roomPedestals = {}
local blindPedestals = {} -- API EXPOSED -- READ ONLY
local shopItems = {} -- API EXPOSED -- READ ONLY
local newCollectibles = {[visible] = {}, [blind] = {}} -- API EXPOSED -- READ ONLY

-----------------------------------------------MAIN------------------------------------------------

local collectiblesInRoom = {} -- API EXPOSED -- READ ONLY

local cQualityStatus = { -- API EXPOSED --READ ONLY
    [visible] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00},
    [blind] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00},
    [absolute] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00}
}

local cBestQuality = { -- API EXPOSED -- READ ONLY
    [visible] = ReactionAPI.QualityStatus.NO_ITEMS,
    [blind] = ReactionAPI.QualityStatus.NO_ITEMS,
    [absolute] = ReactionAPI.QualityStatus.NO_ITEMS
}

-------------------------------------------CUSTOM RULES--------------------------------------------

local isCollectibleBlindConditions = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT
local isGloballyBlindConditions = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT
local overwriteFunctions = {} -- PERSISTENT

---------------------------------------------------------------------------------------------------
---------------------------------------------FUNCTIONS---------------------------------------------
---------------------------------------------------------------------------------------------------

----------------------------------------------HELPER-----------------------------------------------

local function OpCodeSET(args)
    cQualityStatus[args.isBlind][args.isNew] = cQualityStatus[args.isBlind][args.isNew] | args.partition
end

local function OpCodeCLEAR(args)
    cQualityStatus[args.isBlind][args.isNew] = cQualityStatus[args.isBlind][args.isNew] & ~(args.partition)
end

local opCodes = {
    [ReactionAPI.OpCodes.NOP] = function() end,
    [ReactionAPI.OpCodes.SET] = OpCodeSET,
    [ReactionAPI.OpCodes.CLEAR] = OpCodeCLEAR
}

------------------------------------------------API------------------------------------------------

function ReactionAPI.GetCollectibleBestQuality(Visibility)
    if Visibility ~= nil then
        return cBestQuality[Visibility]
    else
        return cBestQuality
    end
end

function ReactionAPI.GetCollectibleQualityStatus(IsBlind, NewOnly)
    if IsBlind ~= nil then
        if NewOnly ~= nil then
            return cQualityStatus[IsBlind][NewOnly]
        end
        return cQualityStatus[IsBlind]
    else
        if NewOnly ~= nil then
            local convertedOutput = {[visible] = cQualityStatus[visible][NewOnly], [blind] = cQualityStatus[blind][NewOnly], [absolute] = cQualityStatus[absolute][NewOnly]}
            return convertedOutput
        end
    end
    return cQualityStatus
end

function ReactionAPI.GetCollectibleData()
    return collectiblesInRoom, newCollectibles, blindPedestals, shopItems
end

function ReactionAPI.CheckForCollectiblePresence(PresencePartition, IsBlind, CheckNewOnly, AllPresent)
    IsBlind = false or IsBlind
    CheckNewOnly = false or CheckNewOnly
    AllPresent = false or AllPresent
    if PresencePartition <= 0x00 or PresencePartition >= 1 << (ReactionAPI.QualityStatus.QUALITY_4 + 2) then
        local errorMessage = "[ERROR in ReactionAPI.CheckForCollectiblePresence]: an invalid PresencePartition was passed"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if AllPresent then
        return cQualityStatus[IsBlind][CheckNewOnly] & PresencePartition == PresencePartition
    else
        return cQualityStatus[IsBlind][CheckNewOnly] & PresencePartition ~= 0
    end
end

function ReactionAPI.CheckForCollectibleAbsence(AbsencePartition, IsBlind, CheckNewOnly, AllAbsent)
    IsBlind = false or IsBlind
    CheckNewOnly = false or CheckNewOnly
    AllAbsent = AllAbsent == nil and true or AllAbsent
    if AbsencePartition <= 0x00 or AbsencePartition >= 1 << (ReactionAPI.QualityStatus.QUALITY_4 + 2) then
        local errorMessage = "[ERROR in ReactionAPI.CheckForCollectibleAbsence]: an invalid AbsencePartition was passed"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if AllAbsent then
        return cQualityStatus[IsBlind][CheckNewOnly] & AbsencePartition == 0
    else
        return cQualityStatus[IsBlind][CheckNewOnly] & AbsencePartition ~= AbsencePartition
    end
end

function ReactionAPI.AddBlindCondition(Function, Global)
    Global = Global == nil and true or Global
    if type(Function) ~= "function" then
        local errorMessage = "[ERROR in ReactionAPI.AddBlindCondition]: no Function was passed"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if Global then
        table.insert(isGloballyBlindConditions, 1, Function)
    else
        table.insert(isCollectibleBlindConditions, 1, Function)
    end
end

function ReactionAPI.SetIsCurseOfBlindGlobal(IsGlobal, TicketID)
    IsGlobal = IsGlobal == nil and true or IsGlobal
    if TicketID == nil then
        local errorMessage = "[ERROR in ReactionAPI.SetIsCurseOfBlindGlobal]: no TicketID was passed"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if IsGlobal then
        isCurseOfBlindNotGlobal_Tickets[TicketID] = nil
        Isaac.DebugString("[SetIsCurseOfBlindGlobal] Ticket: " .. TicketID .. " Removed")
    else
        isCurseOfBlindNotGlobal_Tickets[TicketID] = true
        Isaac.DebugString("[SetIsCurseOfBlindGlobal] Ticket: " .. TicketID .. " Added")
    end
end

function ReactionAPI.ShouldIsBlindPedestalBeOptimized(Answer, TicketID)
    Answer = Answer == nil and true or Answer
    if TicketID == nil then
        local errorMessage = "[ERROR in ReactionAPI.ShouldIsBlindPedestalBeOptimized]: no TicketID was passed"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if Answer then
        shouldIsBlindPedestalNotOptimize_Tickets[TicketID] = nil
        Isaac.DebugString("[ShouldIsBlindPedestalBeOptimized] Ticket: " .. TicketID .. " Removed")
    else
        shouldIsBlindPedestalNotOptimize_Tickets[TicketID] = true
        Isaac.DebugString("[ShouldIsBlindPedestalBeOptimized] Ticket: " .. TicketID .. " Added")
    end
end

function ReactionAPI.RequestReset(Global, EntityIDs)
    Global = Global == nil and true or Global
    if not Global and type(EntityIDs) ~= "table" then
        local errorMessage = "[ERROR in ReactionAPI.RequestReset]: no EntityIDs were passed on a non global request"
        Isaac.ConsoleOutput(errorMessage .. "\n")
        Isaac.DebugString(errorMessage)
        return
    end

    if Global then
        requestedGlobalReset = true
    else
        for _, entityID in ipairs(EntityIDs) do
            requestedPickupResets[entityID] = true
        end
    end
end

--------------------------------------VANILLA BLIND CONDITIONS-------------------------------------

local function IsCurseOfBlindGlobal()
    for _, _ in pairs(isCurseOfBlindNotGlobal_Tickets) do
        return false
    end
    return true
end

local function IsCurseOfBlind()
    return (Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0) and IsCurseOfBlindGlobal()
end

ReactionAPI.AddBlindCondition(IsCurseOfBlind, evaluateGlobally)

local function ShouldIsBlindPedestalBeOptimized()
    for _, _ in pairs(shouldIsBlindPedestalNotOptimize_Tickets) do
        return false
    end
    return true
end

local function CompareWithQuestionMarkSprite(CollectibleSprite)
    blindCollectibleSprite:SetFrame(CollectibleSprite:GetAnimation(), CollectibleSprite:GetFrame())
    for i = -70, 0, 2 do
        local qcolor = blindCollectibleSprite:GetTexel(Vector(0, i), Vector.Zero, 1, 1)
        local ecolor = CollectibleSprite:GetTexel(Vector(0, i), Vector.Zero, 1, 1)
        if qcolor.Red ~= ecolor.Red or qcolor.Green ~= ecolor.Green or qcolor.Blue ~= ecolor.Blue then
            return false
        end
    end
    return true
end

local function IsBlindPedestal(EntityPickup)
end

if REPENTOGON then
    IsBlindPedestal = function(EntityPickup)
        if curseOfBlind then
            if EntityPickup:IsBlind() then
                return true
            end
            return CompareWithQuestionMarkSprite(EntityPickup:GetSprite())
        end
        return EntityPickup:IsBlind()
    end
else
    IsBlindPedestal = function(EntityPickup)
        if ReactionAPI.UserSettings.cOptimizeIsBlindPedestal and ShouldIsBlindPedestalBeOptimized() then
            if not ReactionAPI.Utilities.CanBlindCollectiblesSpawnInTreasureRoom() then
                return false
            end
            if Game():GetRoom():GetType() ~= RoomType.ROOM_TREASURE then
                return false
            end
        end
        return CompareWithQuestionMarkSprite(EntityPickup:GetSprite())
    end
end

ReactionAPI.AddBlindCondition(IsBlindPedestal, evaluatePerCollectible)

----------------------------------------------CHECKS-----------------------------------------------

local function IsTouchedCollectible(EntityPickup) --OnCollectibleUpdate() --HandleShopItems()
    return EntityPickup.Touched or EntityPickup.SubType == 0
end

local function IsNewCollectible(EntityPickup) --OnCollectibleUpdate()
    if collectiblesInRoom[EntityPickup.Index] == nil then
        return true
    end
    for _, poofPosition in pairs(poofPositions) do
        if EntityPickup.Position:Distance(poofPosition) == 0.0 then
            return true
        end
    end
    return false
end

local function HasResetBeenRequested(EntityPickup) --OnCollectibleUpdate()
    return requestedPickupResets[EntityPickup.Index] ~= nil
end

local function IsBlindCollectible(EntityPickup) --OnCollectibleUpdate()
    if globallyBlind then
        return true
    end
    for _, condition in ipairs(isCollectibleBlindConditions) do
        if condition(EntityPickup) then
            return true
        end
    end
    return false
end

local function EvaluateGloballyBlindConditions() --OnLatePostUpdate()
    for _, condition in ipairs(isGloballyBlindConditions) do
        if condition() then
            if globallyBlind == true then
                return
            else
                globallyBlind = true
                ReactionAPI.RequestReset(global)
                return
            end
        end
    end
    if globallyBlind == false then
        return
    else
        globallyBlind = false
        ReactionAPI.RequestReset(global)
    end
end

local function IsDeathCertificateDimension()
end

if REPENTOGON then
    IsDeathCertificateDimension = function()
        return Game():GetLevel():GetDimension() == Dimension.DEATH_CERTIFICATE
    end
else
    IsDeathCertificateDimension = function()
        return Game():GetLevel():GetCurrentRoomDesc().Data.Name == 'Death Certificate'
    end
end

------------------------------------------------SET------------------------------------------------

local function SetCollectibleQualityStatus(CollectibleID, IsBlind, IsNew) --SetQualityStatus()
    ItemQuality = ReactionAPI.CollectibleData[CollectibleID] or ReactionAPI.QualityStatus.GLITCHED
    if ItemQuality > ReactionAPI.QualityStatus.NO_ITEMS then
        cQualityStatus[IsBlind][IsNew] = cQualityStatus[IsBlind][IsNew] | 1 << (ItemQuality + 1)
    end
end

local function SetQualityStatus() --OnPostUpdate()
    cQualityStatus = {
        [visible] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00},
        [blind] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00},
        [absolute] = {[newPickupsOnly] = 0x00, [everyPickup] = 0x00}
    }
    for pickupID, _ in pairs(collectiblesInRoom) do
        local isBlind = blindPedestals[pickupID] ~= nil
        for collectibleID, _ in pairs(collectiblesInRoom[pickupID]) do
            SetCollectibleQualityStatus(collectibleID, isBlind, everyPickup)
        end
    end
    for collectibleID, _ in pairs(newCollectibles[visible]) do
        SetCollectibleQualityStatus(collectibleID, visible, newPickupsOnly)
    end
    for collectibleID, _ in pairs(newCollectibles[blind]) do
        SetCollectibleQualityStatus(collectibleID, blind, newPickupsOnly)
    end
end

local function SetAbsoluteQualityStatus() --OnPostUpdate()
    cQualityStatus[absolute][newPickupsOnly] = cQualityStatus[visible][newPickupsOnly] | cQualityStatus[blind][newPickupsOnly]
    cQualityStatus[absolute][everyPickup] = cQualityStatus[visible][everyPickup] | cQualityStatus[blind][everyPickup]
end

local function SetBestCollectibleQuality() --OnPostUpdate()
    cBestQuality[visible] = cQualityStatus[visible][everyPickup] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(cQualityStatus[visible][everyPickup], 2)) - 1
    cBestQuality[blind] = cQualityStatus[blind][everyPickup] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(cQualityStatus[blind][everyPickup], 2)) - 1
    cBestQuality[absolute] = math.max(cBestQuality[visible], cBestQuality[blind])
end

local function SetGloballyBlindTickets() --OnPostUpdate()
    ReactionAPI.SetIsCurseOfBlindGlobal(not IsDeathCertificateDimension(), "DeathCertificateDimension")
end

-----------------------------------------------RESET-----------------------------------------------

local function ResetUpdateLocalVariables() --OnLatePostUpdate() --FullReset()
    onCollectibleUpdate_FirstExecution = true
    poofPositions = {}
    newCollectibles = {[visible] = {}, [blind] = {}}
end --Reset Variables that get reset at the end of every Update cycle

local function ResetUpdatePersistentVariables() --FullReset()
    cachedOptionGroup = {}
    wipedOptionGroups = {}
    roomPedestals = {}
    blindPedestals = {}
    shopItems = {}
    collectiblesInRoom = {}
end --Reset Variables that persist at the end of an Update cycle

local function PostCompletedReset() --FullReset()
    requestedGlobalReset = false
    delayRequestedGlobalReset = false
    requestedPickupResets = {}
end

local function FullReset()  --OnLatePostUpdate() --ResetOnNewRoom() --HandleRequestedGlobalResets()
    ResetUpdateLocalVariables()
    ResetUpdatePersistentVariables()

    PostCompletedReset()
end

---------------------------------------------HANDLERS----------------------------------------------

local function HandleRequestedGlobalResets() --OnCollectibleUpdate()
    if onCollectibleUpdate_FirstExecution then
        FullReset()
    else
        delayRequestedGlobalReset = true
    end
end

local function HandleNonExistentPedestals() --OnPostUpdate()
    for pickupID, entity in pairs(roomPedestals) do
        if not entity:Exists() or IsTouchedCollectible(entity) then
            roomPedestals[pickupID] = nil
            shopItems[pickupID] = nil
            collectiblesInRoom[pickupID] = nil
            blindPedestals[pickupID] = nil
        end
    end
end

local function HandleOverwriteFunctions() --OnPostUpdate()
    for _, overwrite in pairs(overwriteFunctions) do
        local operations = overwrite()
        for _, operation in ipairs(operations) do
            opCodes[operation.code](operation.args)
        end
    end
end

local function HandleRequestedPickupResets() --OnLatePostUpdate()
    for _, pickupID in pairs(requestedPickupResets) do
        roomPedestals[pickupID] = nil
        collectiblesInRoom[pickupID] = nil
        blindPedestals[pickupID] = nil
        shopItems[pickupID] = nil
    end
end

----------------------------------------------PROFILE----------------------------------------------

local function ProfileCollectibleUpdate()
end

if PROFILE then
    ProfileCollectibleUpdate = function()
        if numCollectibleUpdates == 0 then
            updateCycle_ProfileTimeStart = Isaac.GetTime()
        end
        numCollectibleUpdates = numCollectibleUpdates + 1
    end
end

local function PrintCollectibleUpdateProfile()
end

if PROFILE then
    PrintCollectibleUpdateProfile = function()
        Isaac.DebugString("Completed ReactionAPI Update Cycle in : " .. Isaac.GetTime() - updateCycle_ProfileTimeStart .. " ms with " .. numCollectibleUpdates .. " Executions")
        updateCycle_ProfileTimeStart = Isaac.GetTime()
        numCollectibleUpdates = 0
    end
end

---------------------------------------------CALLBACK----------------------------------------------

local function RecordPoofPosition(_, EntityEffect)
    table.insert(poofPositions, EntityEffect.Position)
end

local function OnCollectibleUpdate(_, EntityPickup)
    ProfileCollectibleUpdate()
    if requestedGlobalReset then
        HandleRequestedGlobalResets()
    end
    onCollectibleUpdate_FirstExecution = false

    local cachedGroup = cachedOptionGroup[EntityPickup.Index]
    local group = cachedGroup or EntityPickup.OptionsPickupIndex
    local isGrouped = group > 0

    if isGrouped and cachedGroup == nil then
        cachedOptionGroup[EntityPickup.Index] = EntityPickup.OptionsPickupIndex
    end

    if IsTouchedCollectible(EntityPickup) or wipedOptionGroups[group] then
        if isGrouped then
            wipedOptionGroups[group] = true
        end
        roomPedestals[EntityPickup.Index] = nil
        collectiblesInRoom[EntityPickup.Index] = nil
        shopItems[EntityPickup.Index] = nil
        blindPedestals[EntityPickup.Index] = nil
        return
    end

    local isBlind = nil --NOT INITIALIZED YET

    roomPedestals[EntityPickup.Index] = EntityPickup

    if EntityPickup:IsShopItem() then
        shopItems[EntityPickup.Index] = EntityPickup
    end

    if IsNewCollectible(EntityPickup) or HasResetBeenRequested(EntityPickup) then
        collectiblesInRoom[EntityPickup.Index] = {}
        blindPedestals[EntityPickup.Index] = nil
    end
    if blindPedestals[EntityPickup.Index] ~= nil then
        isBlind = true
    else
        isBlind = IsBlindCollectible(EntityPickup)
        if isBlind then
            blindPedestals[EntityPickup.Index] = EntityPickup
        end
    end

    if collectiblesInRoom[EntityPickup.Index][EntityPickup.SubType] == nil then
        newCollectibles[isBlind][EntityPickup.SubType] = true
        collectiblesInRoom[EntityPickup.Index][EntityPickup.SubType] = ReactionAPI.Utilities.GetTableLength(collectiblesInRoom[EntityPickup.Index]) + 1
    end
end

local function OnPostUpdate()
    HandleNonExistentPedestals()
    SetQualityStatus()
    HandleOverwriteFunctions()
    SetAbsoluteQualityStatus()
    SetBestCollectibleQuality()
    PrintCollectibleUpdateProfile()
end

local function OnLatePostUpdate()
    SetGloballyBlindTickets()
    EvaluateGloballyBlindConditions()
    curseOfBlind = Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0
    if delayRequestedGlobalReset or requestedGlobalReset then
        FullReset()
    else
        ResetUpdateLocalVariables()
    end
    HandleRequestedPickupResets()
end

local function ResetOnNewRoom()
    FullReset()
end

local function ResetOnExit()
    FullReset()
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, RecordPoofPosition, EffectVariant.POOF01)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, OnCollectibleUpdate, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.IMPORTANT, OnPostUpdate)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, OnLatePostUpdate)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ResetOnNewRoom)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ResetOnExit)

---------------------------------------------------------------------------------------------------
----------------------------------------OVERWRITE FUNCTIONS----------------------------------------
---------------------------------------------------------------------------------------------------

------------------------------------------COMPATIBILITY--------------------------------------------

local eternalCandleID

local function TaintedTreasureCompatibility()
    eternalCandleID = eternalCandleID or Isaac.GetItemIdByName('Eternal Candle')
    if ReactionAPI.Utilities.AnyPlayerHasCollectible(eternalCandleID, false) and (Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0) then
        if ReactionAPI.UserSettings.cEternalBlindOverwrite == ReactionAPI.Setting.DO_NOT then
            return {}
        end
        local partition = 1 << (ReactionAPI.UserSettings.cEternalBlindOverwrite + 1)
        for _, _ in pairs(newCollectibles[blind]) do
            return {
                {code = ReactionAPI.OpCodes.SET, args = {isBlind = false, isNew = false, partition = partition}},
                {code = ReactionAPI.OpCodes.SET, args = {isBlind = false, isNew = true, partition = partition}}
            }
        end
        for _,_ in pairs(blindPedestals) do
            return {
                {code = ReactionAPI.OpCodes.SET, args = {isBlind = false, isNew = false, partition = partition}}
            }
        end
        return {}
    end
    return {}
end
local function ApplyOverwrite()
    if TaintedTreasure then
        table.insert(overwriteFunctions, 1, TaintedTreasureCompatibility)
    end
    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, ApplyOverwrite)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ApplyOverwrite)

---------------------------------------------------------------------------------------------------
-----------------------------------------------DEBUG-----------------------------------------------
---------------------------------------------------------------------------------------------------

----------------------------------------------TICKETS----------------------------------------------

local function DebugPrintGlobalBlindTickets()
    Isaac.DebugString("GlobalBlind Tickets:")
    for ID, _ in pairs(isCurseOfBlindNotGlobal_Tickets) do
        Isaac.DebugString("Id: " .. ID)
    end
end

local function DebugPrintBlindOptimizeTickets()
    Isaac.DebugString("BlindOptimize Tickets:")
    for ID, _ in pairs(isCurseOfBlindNotGlobal_Tickets) do
        Isaac.DebugString("Id: " .. ID)
    end
end

local function DebugPrintTickets()
    DebugPrintGlobalBlindTickets()
    DebugPrintBlindOptimizeTickets()
end

-- CHECKS

local function DebugPrintChecks()
    Isaac.DebugString("IsCurseOfBlind: " .. tostring(IsCurseOfBlind()))
    Isaac.DebugString("IsBlindPedestalOptimized: " .. tostring(ReactionAPI.UserSettings.cOptimizeIsBlindPedestal and ShouldIsBlindPedestalBeOptimized()))
end

local function PrintDebug()
    DebugPrintTickets()
    DebugPrintChecks()
end

-- ReactionAPI:AddCallback(ModCallbacks.MC_POST_UPDATE, PrintDebug)
