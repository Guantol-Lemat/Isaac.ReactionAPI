local log = require("reactionAPI_scripts.tools.log")
local json = require("json")
local SharedData = require("reactionAPI_scripts.shared_data")
local DeepCopy = ReactionAPI.Utilities.DeepCopy
local RightDeepMerge = ReactionAPI.Utilities.RightDeepMerge

---------------------------------------------------------------------------------------------------
---------------------------------------------VARIABLES---------------------------------------------
---------------------------------------------------------------------------------------------------

-----------------------------------------------DEBUG-----------------------------------------------

SharedData.DEBUG = {Enabled = false}
SharedData.PROFILE = {Enabled = false}

----------------------------------------------CONTEXT----------------------------------------------

local evaluateGlobally = true
local evaluatePerCollectible = false
local visible = ReactionAPI.Visibility.VISIBLE
local blind = ReactionAPI.Visibility.BLIND
local absolute = ReactionAPI.Visibility.ABSOLUTE
local filterNEW = ReactionAPI.Filter.NEW
local filterALL = ReactionAPI.Filter.ALL
local resetGLOBAL = ReactionAPI.Reset.GLOBAL
local resetLOCAL = ReactionAPI.Reset.LOCAL

local Crane = ReactionAPI.SlotType.CRANE_GAME

-----------------------------------------------FLAGS-----------------------------------------------

SharedData.GloballyBlind = false
SharedData.CurseOfBlind = false -- ONLY FOR REPENTOGON
local isCurseOfBlindNotGlobal_Tickets = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT
local shouldIsBlindPedestalNotOptimize_Tickets = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT

local requestedGlobalReset = false -- API EXPOSED -- WRITE ONLY
local performedGlobalReset = false
SharedData.RequestedPickupResets = {} -- API EXPOSED -- WRITE ONLY

local initializeCollectibleIdLater = false
local updateFlipData = false
local wasFlipUsed = false

local newFloor = false

---------------------------------------------AUXILIARY---------------------------------------------

local flipData = {} -- Not the Actual Definition, defined here so that CopyRunData can work
local flipFloorData = {}
local flipRoomData = {}
local flipInitSeedData = {}
-- This variable stores all the InitSeeds that a specific EntityPickup has had in this room, as well as the Current Init Seed
-- This is so that when the player exits the flipData for the all the InitSeed, except for the current one is wiped
-- This is to solve the problem of Diplopia Items being considered flip items.
local markFlipItemForDeletion = {}
local flipMaxIndex = -1
local lastFrameGridChecked = 0
local lastInitializedCollectibleData = {
    CollectibleId = nil,
    SpawnTime = nil,
    GridIdx = nil,
    InitSeed = nil
}

local newLevelStage = LevelStage.STAGE_NULL
local newLevelStageType = StageType.STAGETYPE_ORIGINAL

local hourglassRewindState = {}
local hourglassPhantomRewindState = {}
local previousHourglassUpdateType = GHManager.HourglassUpdate.New_Session

local defaultRunData = {
    CraneItemData = {},
    EIDCraneItemData = {},
    EIDFlipItemData = {},
    NewFloor = false,
    NewLevelStage = LevelStage.STAGE_NULL,
    NewLevelStageType = StageType.STAGETYPE_ORIGINAL
}

ReactionAPI.RunData = DeepCopy(defaultRunData)
-- This is a Global Variable whose only purpose is to pass some local variables to the Save Function.

function ReactionAPI.CopyRunData()
    ReactionAPI.RunData.NewFloor = newFloor
    ReactionAPI.RunData.NewLevelStage = newLevelStage
    ReactionAPI.RunData.NewLevelStageType = newLevelStageType
    local flipFloorDataTable = {}
    for listIndex, roomData in pairs(flipFloorData) do
        local roomContent = {}
        for initSeed, flipItemData in pairs(roomData) do
            table.insert(roomContent, {initSeed, flipItemData})
        end
        table.insert(flipFloorDataTable, {listIndex, roomContent})
    end
    ReactionAPI.RunData.EIDFlipItemData = flipFloorDataTable or {}
end
-- This function is only called when exiting the game and RunData needs to be saved.
-- Though it may be Global in scope it doesn't matter, as it is called just before saving
-- and this data is only read on Run Startup (which reloads the Save File) before reading the data.

-----------------------------------------------MAIN------------------------------------------------

--[[local]] flipData = { -- API EXPOSED -- READ ONLY
    QualityStatus = {
        [filterNEW] = 0x00,
        [filterALL] = 0x00
    },
    BestQuality = {
        [filterNEW] = ReactionAPI.QualityStatus.NO_ITEMS,
        [filterALL] = ReactionAPI.QualityStatus.NO_ITEMS
    },
    ItemData = {},
    InRoom = {},
    New = {}
}

local fakeNewData = { -- API EXPOSED -- READ ONLY
    cranePrize = {
        New = {[visible] = {}, [blind] = {}},
        QualityStatus = {
            [visible] = {[filterNEW] = 0x00, [filterALL] = 0x00},
            [blind] = {[filterNEW] = 0x00, [filterALL] = 0x00},
            [absolute] = {[filterNEW] = 0x00, [filterALL] = 0x00}
        }
    },
    flipVisible = {
        New = {[visible] = {}, [blind] = {}},
        QualityStatus = {
            [visible] = {[filterNEW] = 0x00, [filterALL] = 0x00},
            [blind] = {[filterNEW] = 0x00, [filterALL] = 0x00},
            [absolute] = {[filterNEW] = 0x00, [filterALL] = 0x00}
        }
    },
    flipShadow = {
        New = {},
        QualityStatus = {
            [filterNEW] = 0x00,
            [filterALL] = 0x00
        }
    }
}

-------------------------------------------CUSTOM RULES--------------------------------------------

SharedData.CollectibleBlindConditions = {} -- API EXPOSED -- WRITE ONLY -- PERSISTENT
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
        return CollectibleData.BestQuality[Visibility]
    else
        return CollectibleData.BestQuality
    end
end

function ReactionAPI.GetCollectibleQualityStatus(IsBlind, NewOnly)
    if IsBlind ~= nil then
        if NewOnly ~= nil then
            return CollectibleData.QualityStatus[IsBlind][NewOnly]
        end
        return CollectibleData.QualityStatus[IsBlind]
    else
        if NewOnly ~= nil then
            local convertedOutput = {[visible] = CollectibleData.QualityStatus[visible][NewOnly], [blind] = CollectibleData.QualityStatus[blind][NewOnly], [absolute] = CollectibleData.QualityStatus[absolute][NewOnly]}
            return convertedOutput
        end
    end
    return CollectibleData.QualityStatus
end

function ReactionAPI.GetCollectibleData()
    return CollectibleData
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
        return CollectibleData.QualityStatus[IsBlind][CheckNewOnly] & PresencePartition == PresencePartition
    else
        return CollectibleData.QualityStatus[IsBlind][CheckNewOnly] & PresencePartition ~= 0
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
        return CollectibleData.QualityStatus[IsBlind][CheckNewOnly] & AbsencePartition == 0
    else
        return CollectibleData.QualityStatus[IsBlind][CheckNewOnly] & AbsencePartition ~= AbsencePartition
    end
end

function ReactionAPI.GetFlipBestQuality(Filter)
    if Filter ~= nil then
        return flipData.BestQuality[Filter]
    else
        return flipData.BestQuality
    end
end

function ReactionAPI.GetFlipQualityStatus(Filter)
    if Filter then
        return flipData.QualityStatus[Filter]
    end
    return flipData.QualityStatus
end

function ReactionAPI.GetFlipData()
    return flipData
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
        table.insert(SharedData.CollectibleBlindConditions, 1, Function)
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
        if isCurseOfBlindNotGlobal_Tickets[TicketID] == nil then
            return
        end
        isCurseOfBlindNotGlobal_Tickets[TicketID] = nil
        Isaac.DebugString("[SetIsCurseOfBlindGlobal] Ticket: " .. TicketID .. " Removed")
    else
        if isCurseOfBlindNotGlobal_Tickets[TicketID] == true then
            return
        end
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
        if shouldIsBlindPedestalNotOptimize_Tickets[TicketID] == nil then
            return
        end
        shouldIsBlindPedestalNotOptimize_Tickets[TicketID] = nil
        Isaac.DebugString("[ShouldIsBlindPedestalBeOptimized] Ticket: " .. TicketID .. " Removed")
    else
        if shouldIsBlindPedestalNotOptimize_Tickets[TicketID] == true then
            return
        end
        shouldIsBlindPedestalNotOptimize_Tickets[TicketID] = true
        Isaac.DebugString("[ShouldIsBlindPedestalBeOptimized] Ticket: " .. TicketID .. " Added")
    end
end

function ReactionAPI.GetBlindData()
    local BlindData = {
        IsGloballyBlind = SharedData.GloballyBlind,
        IsCurseOfBlind = curseOfBlind,
    }
    return BlindData
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
            SharedData.RequestedPickupResets[entityID] = true
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
    return (game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0) and IsCurseOfBlindGlobal()
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
            if game:GetRoom():GetType() ~= RoomType.ROOM_TREASURE then
                return false
            end
        end
        return CompareWithQuestionMarkSprite(EntityPickup:GetSprite())
    end
end

ReactionAPI.AddBlindCondition(IsBlindPedestal, evaluatePerCollectible)

----------------------------------------------CHECKS-----------------------------------------------

local function EvaluateGloballyBlindConditions() --onLatePostUpdate()
    for _, condition in ipairs(isGloballyBlindConditions) do
        if condition() then
            if SharedData.GloballyBlind == true then
                return
            else
                SharedData.GloballyBlind = true
                ReactionAPI.RequestReset(resetGLOBAL)
                return
            end
        end
    end
    if SharedData.GloballyBlind == false then
        return
    else
        SharedData.GloballyBlind = false
        ReactionAPI.RequestReset(resetGLOBAL)
    end
end

local function IsDeathCertificateDimension()
end

if REPENTOGON then
    IsDeathCertificateDimension = function()
        return game:GetLevel():GetDimension() == Dimension.DEATH_CERTIFICATE
    end
else
    IsDeathCertificateDimension = function()
        return game:GetLevel():GetCurrentRoomDesc().Data.Name == 'Death Certificate'
    end
end

------------------------------------------------SET------------------------------------------------

local function AssignFlipItems() -- Not actual Definition, used so that LoadRunData works
end

local function SetCollectibleQualityStatus(CollectibleID, IsBlind, IsNew) -- SetQualityStatus()
    local itemQuality = ReactionAPI.CollectibleQuality[CollectibleID] or ReactionAPI.QualityStatus.GLITCHED
    if itemQuality > ReactionAPI.QualityStatus.NO_ITEMS then
        cQualityStatus[IsBlind][IsNew] = cQualityStatus[IsBlind][IsNew] | 1 << (itemQuality + 1)
    end
end

local function SetFlipQualityStatus(PedestalEntity, IsNew) -- SetQualityStatus()
    local collectibleID = flipData.ItemData[PedestalEntity.Index]
    if collectibleID then
        local itemQuality = ReactionAPI.CollectibleQuality[collectibleID] or ReactionAPI.QualityStatus.GLITCHED
        if itemQuality > ReactionAPI.QualityStatus.NO_ITEMS then
            flipData.QualityStatus[IsNew] = flipData.QualityStatus[IsNew] | 1 << (itemQuality + 1)
        end
    end
end

local function SetQualityStatus() --onPostUpdate()
    -- COLLECTIBLES --

    cQualityStatus = {
        [visible] = {[filterNEW] = 0x00, [filterALL] = 0x00},
        [blind] = {[filterNEW] = 0x00, [filterALL] = 0x00},
        [absolute] = {[filterNEW] = 0x00, [filterALL] = 0x00}
    }
    for pickupID, _ in pairs(collectiblesInRoom) do
        local isBlind = blindPedestals[pickupID] ~= nil
        if REPENTOGON then
            for _, collectibleID in pairs(collectiblesInRoom[pickupID]) do
                SetCollectibleQualityStatus(collectibleID, isBlind, filterALL)
            end
        else
            for collectibleID, _ in pairs(collectiblesInRoom[pickupID]) do
                SetCollectibleQualityStatus(collectibleID, isBlind, filterALL)
            end
        end
    end
    for collectibleID, _ in pairs(newCollectibles[visible]) do
        SetCollectibleQualityStatus(collectibleID, visible, filterNEW)
    end
    for collectibleID, _ in pairs(newCollectibles[blind]) do
        SetCollectibleQualityStatus(collectibleID, blind, filterNEW)
    end

    -- CRANES --

    -- SLOT --

    flipData.QualityStatus = {
        [filterNEW] = 0x00,
        [filterALL] = 0x00
    }
    for _, pedestalEntity in pairs(flipData.InRoom) do
        SetFlipQualityStatus(pedestalEntity, filterALL)
        if flipData.New[pedestalEntity.Index] then
            SetFlipQualityStatus(pedestalEntity, filterNEW)
        end
    end
end

local function SetAbsoluteQualityStatus() --onPostUpdate()
    cQualityStatus[absolute][filterNEW] = cQualityStatus[visible][filterNEW] | cQualityStatus[blind][filterNEW]
    cQualityStatus[absolute][filterALL] = cQualityStatus[visible][filterALL] | cQualityStatus[blind][filterALL]
end

local function SetBestQuality() --onPostUpdate()
    CollectibleData.BestQuality[visible] = cQualityStatus[visible][filterALL] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(cQualityStatus[visible][filterALL], 2)) - 1
    CollectibleData.BestQuality[blind] = cQualityStatus[blind][filterALL] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(cQualityStatus[blind][filterALL], 2)) - 1
    CollectibleData.BestQuality[absolute] = math.max(CollectibleData.BestQuality[visible], CollectibleData.BestQuality[blind])

    flipData.BestQuality[filterALL] = flipData.QualityStatus[filterALL] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(flipData.QualityStatus[filterALL], 2)) - 1
    flipData.BestQuality[filterNEW] = flipData.QualityStatus[filterNEW] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(flipData.QualityStatus[filterNEW], 2)) - 1
end

local function SetGloballyBlindTickets() --onPostUpdate()
    ReactionAPI.SetIsCurseOfBlindGlobal(not IsDeathCertificateDimension(), "DeathCertificateDimension")
end

-----------------------------------------------RESET-----------------------------------------------

local function ResetUpdateLocalVariables() --onLatePostUpdate()
    wasFlipUsed = false
    performedGlobalReset = false
    flipData.New = {}
    fakeNewData = {
        cranePrize = {
            New = { [visible] = {}, [blind] = {} },
            QualityStatus = {
                [visible] = { [filterNEW] = 0x00, [filterALL] = 0x00 },
                [blind] = { [filterNEW] = 0x00, [filterALL] = 0x00 },
                [absolute] = { [filterNEW] = 0x00, [filterALL] = 0x00 }
            }
        },
        flipVisible = {
            New = { [visible] = {}, [blind] = {} },
            QualityStatus = {
                [visible] = { [filterNEW] = 0x00, [filterALL] = 0x00 },
                [blind] = { [filterNEW] = 0x00, [filterALL] = 0x00 },
                [absolute] = { [filterNEW] = 0x00, [filterALL] = 0x00 }
            }
        },
        flipShadow = {
            New = {},
            QualityStatus = {
                [filterNEW] = 0x00,
                [filterALL] = 0x00
            }
        }
    }
end --Reset Variables that get reset at the end of every Update cycle

local function ResetUpdatePersistentVariables() --FullReset()
end --Reset Variables that persist at the end of an Update cycle

local function PostCompletedReset() --FullReset()
    requestedGlobalReset = false
    performedGlobalReset = true
    SharedData.RequestedPickupResets = {}
end

local function ResetFloorTrackers()
    flipFloorData = {}
end

local function ResetCraneDataOnPermanentNewLevel()
    local level = game:GetLevel()
    if newFloor and level:GetStage() == newLevelStage and level:GetStageType() == newLevelStageType then
        slotData[Crane].ItemData = ReactionAPI.Utilities.DeepCopy(EIDCraneItemData)
    end
    newFloor = false
end

local function FullReset()  --onLatePostUpdate() --ResetOnNewRoom() --HandleRequestedGlobalResets()
    ResetUpdatePersistentVariables()
    PostCompletedReset()
end

local function ClearMarkedFlipItems()
    for listIndex, _ in pairs(markFlipItemForDeletion) do
        for entityID, _ in ipairs(markFlipItemForDeletion[listIndex]) do
            if not flipFloorData[listIndex] then
                break
            end
            for initSeed, _ in pairs(flipInitSeedData[listIndex][entityID].AllInitSeeds) do
                flipFloorData[listIndex][initSeed] = nil
            end
        end
    end
end

local function ClearOldFlipInitSeeds()
    for roomListIndex, _ in pairs(flipInitSeedData) do
        for entityPickupID, _ in pairs(flipInitSeedData[roomListIndex]) do
            for initSeed, _ in pairs(flipInitSeedData[roomListIndex][entityPickupID].AllInitSeeds) do
                if not initSeed == flipInitSeedData[roomListIndex][entityPickupID].CurrentInitSeed then
                    flipFloorData[roomListIndex][initSeed] = nil
                end
            end
        end
    end
end

---------------------------------------------HANDLERS----------------------------------------------

function SharedData.HandleRequestedGlobalResets() --OnCollectibleUpdate()
    if requestedGlobalReset and not performedGlobalReset then
        FullReset()
    end
end

local function HandleNonExistentEntities() --onPostUpdate()
end

local function HandleOverwriteFunctions() --onPostUpdate()
    for _, overwrite in pairs(overwriteFunctions) do
        local operations = overwrite()
        for _, operation in ipairs(operations) do
            opCodes[operation.code](operation.args)
        end
    end
end

local function HandleRequestedPickupResets() --onLatePostUpdate()
    for _, pickupID in pairs(SharedData.RequestedPickupResets) do
        roomPedestals[pickupID] = nil
        collectiblesInRoom[pickupID] = nil
        blindPedestals[pickupID] = nil
        shopItems[pickupID] = nil
    end
    SharedData.RequestedPickupResets = {}
end

---------------------------------------------CALLBACK----------------------------------------------

local function onPostUpdate()
    HandleNonExistentEntities()
    SetCraneData()
    SetQualityStatus()
    HandleOverwriteFunctions()
    SetAbsoluteQualityStatus()
    SetBestQuality()
    Print_onCollectibleUpdate_Profile()
end

local function onLatePostUpdate()
    SetGloballyBlindTickets()
    EvaluateGloballyBlindConditions()
    curseOfBlind = game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0
    if requestedGlobalReset then
        FullReset()
    else
        ResetUpdateLocalVariables()
    end
    HandleRequestedPickupResets()
end

local function ResetOnNewRoom()
    FullReset()
    ResetCraneDataOnPermanentNewLevel()
end

local function ResetOnExit()
    FullReset()
end

local function ResetOnNewFloor()
    ResetFloorTrackers()
    newFloor = true
    newLevelStage = game:GetLevel():GetStage()
    newLevelStageType = game:GetLevel():GetStageType()
end

local function LoadRunData(_, IsContinued)
    if IsContinued and ReactionAPI:HasData() then
        local loadedData = json.decode(ReactionAPI:LoadData())
        ReactionAPI.RunData = loadedData["RunData"] or DeepCopy(defaultRunData)
    else
        ReactionAPI.RunData = DeepCopy(defaultRunData)
    end
    newFloor = ReactionAPI.RunData.NewFloor or defaultRunData.NewFloor
    newLevelStage = ReactionAPI.RunData.NewLevelStage or defaultRunData.NewLevelStage
    newLevelStageType = ReactionAPI.RunData.NewLevelStageType or defaultRunData.NewLevelStageType
    local flipFloorDataTable = {}
    for _, roomData in ipairs(ReactionAPI.RunData.EIDFlipItemData) do
        local roomContent = {}
        for _, flipItemData in ipairs(roomData[2]) do
            roomContent[flipItemData[1]] = flipItemData[2]
        end
        flipFloorDataTable[roomData[1]] = roomContent
    end

    flipFloorData = RightDeepMerge(flipFloorDataTable, flipFloorData)
    AssignFlipItems()
    hourglassRewindState.flipFloorData = DeepCopy(flipFloorData)
end

local function ClearRunDataPreSave()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}
    hourglassRewindState = {}
    hourglassPhantomRewindState = {}
end

local function ClearRunDataPostSave()
    flipFloorData = {}
    newFloor = false
    newLevelStage = LevelStage.STAGE_NULL
    newLevelStageType = StageType.STAGETYPE_ORIGINAL
end

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.IMPORTANT, onPostUpdate)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, onLatePostUpdate)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ResetOnNewRoom)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ResetOnExit)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, ResetOnNewFloor)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, LoadRunData)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, CallbackPriority.IMPORTANT, ClearRunDataPreSave)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_PRE_GAME_EXIT, CallbackPriority.LATE, ClearRunDataPostSave)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, function() wasFlipUsed = true end, CollectibleType.COLLECTIBLE_FLIP)

---------------------------------------------------------------------------------------------------
------------------------------------------FLIP FUNCTIONS-------------------------------------------
---------------------------------------------------------------------------------------------------

-- Code related to Flip Items are in their own section because they're a pain in the a** to handle
-- and if I were to merge it with the main code it's going to be harder to maintain

local function HandleFlipItems(_, selectedCollectible, itemPool)
    local curFrame = Isaac.GetFrameCount()
		local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
		if curFrame == lastInitializedCollectibleData.SpawnTime then
			if initializeCollectibleIdLater then lastInitializedCollectibleData.CollectibleId = selectedCollectible
			elseif updateFlipData and lastInitializedCollectibleData.CollectibleId then
				if flipFloorData[curRoomIndex] == nil then
					flipFloorData[curRoomIndex] = {}
				end
				flipFloorData[curRoomIndex][lastInitializedCollectibleData.InitSeed] = {
                    CollectibleId = selectedCollectible,
                    GridIdx = lastInitializedCollectibleData.GridIdx
                }
			end
		end

	initializeCollectibleIdLater = false
	updateFlipData = false
end

local function HandleInvalidFlipItems(_, entity)
    -- Only pedestals with indexes that were present at room load can be flip pedestals
    -- Fixes shop restock machines and Diplopia... mostly. At least while you're in the room.

    if entity:GetData()["ReactAPI_FlipItemID"] and entity.Index > flipMaxIndex then
        local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
        local gridPos = game:GetRoom():GetGridIndex(entity.Position)
        local flipEntry = flipFloorData[curRoomIndex] and flipFloorData[curRoomIndex][entity.InitSeed]
        -- only wipe the data if the grid index matches (so Diplopia pedestals don't)
        if flipEntry and gridPos == flipEntry.GridIdx then
            flipFloorData[curRoomIndex][entity.InitSeed] = nil
        end
        entity:GetData()["ReactAPI_FlipItemID"] = nil
    end
end

local function CheckFlipGridIndexes(_, ActiveUsed)
    lastFrameGridChecked = Isaac.GetFrameCount()
    local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
    if flipFloorData[curRoomIndex] then
        local pedestals = Isaac.FindByType(5, 100, -1, true, false)
        for _, pedestal in ipairs(pedestals) do
            local flipEntry = flipFloorData[curRoomIndex][pedestal.InitSeed]
            if flipEntry then
                local gridPos = game:GetRoom():GetGridIndex(pedestal.Position)
                flipEntry.GridIdx = gridPos
                if ActiveUsed == CollectibleType.COLLECTIBLE_FLIP then
                    if flipData.InRoom[pedestal.Index] then
                        -- don't swap a flip shadow with an empty pedestal!
                        if pedestal.SubType == CollectibleType.COLLECTIBLE_NULL then
                            flipFloorData[curRoomIndex][pedestal.InitSeed] = nil
                        else
                            flipFloorData[curRoomIndex][pedestal.InitSeed].CollectibleId = pedestal.SubType
                        end
                    end
                end
            end
        end
    end
end

local function SetupPostGetCollectible(_, entityType, variant, subtype, gridIndex)
    updateFlipData = false
    if entityType == EntityType.ENTITY_SLOT and variant == SlotVariant.HOME_CLOSET_PLAYER then
        lastInitializedCollectibleData = {
            CollectibleId = 688,
            SpawnTime = Isaac.GetFrameCount(),
            GridIdx = gridIndex,
            InitSeed = nil
        }
    elseif entityType == EntityType.ENTITY_PICKUP then
        lastInitializedCollectibleData = {
            CollectibleId = nil,
            SpawnTime = Isaac.GetFrameCount(),
            GridIdx = gridIndex,
            InitSeed = nil
        }
        -- Pedestals in need of a random item will call GET_COLLECTIBLE; fixed pedestals (Knife Piece 1) will not
        if subtype == CollectibleType.COLLECTIBLE_NULL then
            initializeCollectibleIdLater = true
        else
            lastInitializedCollectibleData.CollectibleId = subtype
        end
    end
end

local function postPickupInitFlip(_, entity)
    initializeCollectibleIdLater = false
    updateFlipData = true
    lastInitializedCollectibleData.InitSeed = entity.InitSeed

    local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
    local gridPos = game:GetRoom():GetGridIndex(entity.Position)

    -- Update a Flip item's init seed after D6 rerolls or using Flip (aka Grid Index didn't change, Init Seed did)
    if flipFloorData[curRoomIndex] and not flipFloorData[curRoomIndex][entity.InitSeed] then
        -- Check if any Flip pedestals have changed grid indexes (fixes bugs with Greed shops)
        if lastFrameGridChecked ~= Isaac.GetFrameCount() then
            CheckFlipGridIndexes()
        end
        --[[
        for k,v in pairs(flipFloorData[curRoomIndex]) do
            if v.GridIdx == gridPos then
                flipFloorData[curRoomIndex][entity.InitSeed] = v
                flipFloorData[curRoomIndex][k] = nil
                break
            end
        end
        ]]
        -- Causes Deletion of Some flipFloorData when multiple diplopia items are present
        -- when it otherwise shouldn't
    end
    -- Give this new entity its Flip Item data if possible
    local flipEntry = flipFloorData[curRoomIndex] and flipFloorData[curRoomIndex][entity.InitSeed]
    if flipEntry then
        entity:GetData()["ReactAPI_FlipItemID"] = flipEntry.CollectibleId
    end
end

AssignFlipItems = function()
    flipMaxIndex = -1
    local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
    if flipFloorData[curRoomIndex] then
        local pedestals = Isaac.FindByType(5, 100, -1, true, false)
        for _, pedestal in ipairs(pedestals) do
            local flipEntry = flipFloorData[curRoomIndex][pedestal.InitSeed]
            if flipEntry then
                if pedestal.Index > flipMaxIndex then flipMaxIndex = pedestal.Index end

                if not flipRoomData[pedestal.InitSeed] then
                    flipRoomData[pedestal.InitSeed] = pedestal.Index
                    flipData.InRoom[pedestal.Index] = pedestal
                    flipData.New[pedestal.Index] = true
                elseif pedestal.Index < flipRoomData[pedestal.InitSeed] then
                    flipData.InRoom[flipRoomData[pedestal.InitSeed]] = nil
                    flipRoomData[pedestal.InitSeed] = pedestal.Index
                    flipData.InRoom[pedestal.Index] = pedestal
                    flipData.New[pedestal.Index] = true
                end
                -- This code block prevents Diplopia Items from being considered Flip Items
                -- The item with the lowest Index is the first to have ever been spawned and
                -- hence it is the one generated naturally rather than being being generated
                -- by Diplopia
            end
        end
    end
end

local function AssignFlipItemsOnNewRoom()
    flipData.ItemData = {}
    flipData.InRoom = {}
    flipRoomData = {}
    initializeCollectibleIdLater = false
    updateFlipData = false
    AssignFlipItems()
end

local function onNewFloor()
    flipFloorData = {}
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_LEVEL, onNewFloor)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_ROOM_ENTITY_SPAWN, SetupPostGetCollectible)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, HandleFlipItems)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, HandleInvalidFlipItems, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_USE_ITEM, CheckFlipGridIndexes, CollectibleType.COLLECTIBLE_FLIP)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, postPickupInitFlip, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, AssignFlipItemsOnNewRoom)

-----------------------------------------MY ADDITIONS----------------------------------------------

local function SetFlipData(_, EntityPickup)
    if not flipData.InRoom[EntityPickup.Index] then
        return
    end

    local roomListIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex

    if EntityPickup.SubType == CollectibleType.COLLECTIBLE_NULL then
        if not markFlipItemForDeletion[roomListIndex] then
            markFlipItemForDeletion[roomListIndex] = {}
        end
        markFlipItemForDeletion[roomListIndex][EntityPickup.Index] = EntityPickup
    end

    if not flipInitSeedData[roomListIndex] then
        flipInitSeedData[roomListIndex] = {}
        flipInitSeedData[roomListIndex][EntityPickup.Index] = {}
        flipInitSeedData[roomListIndex][EntityPickup.Index].AllInitSeeds = {}
        flipInitSeedData[roomListIndex][EntityPickup.Index].CurrentInitSeed = nil
    end

    if not flipInitSeedData[roomListIndex][EntityPickup.Index] then
        flipInitSeedData[roomListIndex][EntityPickup.Index] = {}
        flipInitSeedData[roomListIndex][EntityPickup.Index].AllInitSeeds = {}
        flipInitSeedData[roomListIndex][EntityPickup.Index].CurrentInitSeed = nil
    end

    local PreviousInitSeed = flipInitSeedData[roomListIndex][EntityPickup.Index].CurrentInitSeed

    if PreviousInitSeed and PreviousInitSeed ~= EntityPickup.InitSeed then
        if flipFloorData[roomListIndex] then
            flipFloorData[roomListIndex][EntityPickup.InitSeed] = DeepCopy(flipFloorData[roomListIndex][PreviousInitSeed])
        end
        -- Update or Create the entry in flipFloorData for the New Init Seed
        -- This is done because in the original EID code if there are Diplopia Items the usage of
        -- Flip doesn't create or update the entry for the new InitSeed of the Flipped Item
    end
    flipInitSeedData[roomListIndex][EntityPickup.Index].AllInitSeeds[EntityPickup.InitSeed] = true
    flipInitSeedData[roomListIndex][EntityPickup.Index].CurrentInitSeed = EntityPickup.InitSeed

    if not flipFloorData[roomListIndex] then
        return
    end
    local flipEntry = flipFloorData[roomListIndex][EntityPickup.InitSeed]

    if not flipEntry then
        flipData.InRoom[EntityPickup.Index] = nil
        flipData.ItemData[EntityPickup.Index] = nil
        return
    end

    flipData.ItemData[EntityPickup.Index] = flipEntry.CollectibleId
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, SetFlipData, PickupVariant.PICKUP_COLLECTIBLE)

---------------------------------------------------------------------------------------------------
----------------------------------------HOURGLASS FUNCTIONS----------------------------------------
---------------------------------------------------------------------------------------------------

local function OnHourglassNewSession()
    hourglassRewindState.flipFloorData = DeepCopy(flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassContinuedSession()
    hourglassRewindState.flipFloorData = DeepCopy(flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassNewState()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    hourglassRewindState.flipFloorData = DeepCopy(flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassNewWarpedState()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    if hourglassPhantomRewindState then
        hourglassRewindState = DeepCopy(hourglassPhantomRewindState)
    end
    hourglassPhantomRewindState = {}
    hourglassPhantomRewindState.flipFloorData = DeepCopy(flipFloorData)
end

local function OnHourglassRewindPrevious()
    markFlipItemForDeletion = {}
    flipInitSeedData = {}

    flipFloorData = DeepCopy(hourglassRewindState.flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassRewindCurrent()
    markFlipItemForDeletion = {}
    flipInitSeedData = {}

    flipFloorData = DeepCopy(hourglassRewindState.flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassNewStage()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    if hourglassPhantomRewindState and previousHourglassUpdateType ~= GHManager.HourglassUpdate.New_Stage then
        hourglassRewindState = DeepCopy(hourglassPhantomRewindState)
    end
    hourglassPhantomRewindState = {}
    hourglassPhantomRewindState.flipFloorData = DeepCopy(flipFloorData)
end

local function OnHourglassAbsoluteStage()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    hourglassRewindState.flipFloorData = DeepCopy(flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassStageRewindLast()
    markFlipItemForDeletion = {}
    flipInitSeedData = {}

    flipFloorData = DeepCopy(hourglassRewindState.flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassStageRewindPenultimate()
    markFlipItemForDeletion = {}
    flipInitSeedData = {}

    flipFloorData = DeepCopy(hourglassRewindState.flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassFailedStageRewind()
    markFlipItemForDeletion = {}
    flipInitSeedData = {}

    flipFloorData = DeepCopy(hourglassRewindState.flipFloorData)
    hourglassPhantomRewindState = nil
end

local function OnHourglassRoomClear()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    hourglassPhantomRewindState = {}
    hourglassPhantomRewindState.flipFloorData = DeepCopy(flipFloorData)
end

local function OnHourglassCurseDoorDamage()
    ClearMarkedFlipItems()
    markFlipItemForDeletion = {}
    ClearOldFlipInitSeeds()
    flipInitSeedData = {}

    hourglassPhantomRewindState = {}
    hourglassPhantomRewindState.flipFloorData = DeepCopy(flipFloorData)
end

local function CaptureHourglassUpdateType(_, _, UpdateType)
    previousHourglassUpdateType = UpdateType
end

ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassNewState, GHManager.HourglassUpdate.New_State)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassNewWarpedState, GHManager.HourglassUpdate.New_State_Warped)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassRewindPrevious, GHManager.HourglassUpdate.Rewind_Previous_Room)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassRewindCurrent, GHManager.HourglassUpdate.Rewind_Current_Room)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassNewSession, GHManager.HourglassUpdate.New_Session)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassContinuedSession, GHManager.HourglassUpdate.Continued_Session)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassNewStage, GHManager.HourglassUpdate.New_Stage)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassAbsoluteStage, GHManager.HourglassUpdate.New_Absolute_Stage)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassStageRewindLast, GHManager.HourglassUpdate.Previous_Stage_Last_Room)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassStageRewindPenultimate, GHManager.HourglassUpdate.Previous_Stage_Penultimate_Room)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassFailedStageRewind, GHManager.HourglassUpdate.Failed_Stage_Return)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassRoomClear, GHManager.HourglassUpdate.Save_Pre_Room_Clear_State)
ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, OnHourglassCurseDoorDamage, GHManager.HourglassUpdate.Save_Pre_Curse_Damage_Health)

ReactionAPI:AddCallback(GHManager.Callbacks.ON_GLOWING_HOURGLASS_GAME_STATE_UPDATE, CaptureHourglassUpdateType)

---------------------------------------------------------------------------------------------------
----------------------------------------OVERWRITE FUNCTIONS----------------------------------------
---------------------------------------------------------------------------------------------------

------------------------------------------COMPATIBILITY--------------------------------------------

local removedApplyOverwrite = false
local eternalCandleID

local function TaintedTreasureCompatibility()
    eternalCandleID = eternalCandleID or Isaac.GetItemIdByName('Eternal Candle')
    if ReactionAPI.Utilities.AnyPlayerHasCollectible(eternalCandleID, false) and (game:GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0) then
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
    if removedApplyOverwrite then
        return
    end
    if TaintedTreasure then
        table.insert(overwriteFunctions, 1, TaintedTreasureCompatibility)
    end
    removedApplyOverwrite = true
--    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, ApplyOverwrite)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ApplyOverwrite)

---------------------------------------------------------------------------------------------------
-----------------------------------------------DEBUG-----------------------------------------------
---------------------------------------------------------------------------------------------------

if DEBUG then

    ------------------------------------------TICKETS----------------------------------------------

    local function DebugPrintGlobalBlindTickets()
        log.print("GlobalBlind Tickets:")
        for ID, _ in pairs(isCurseOfBlindNotGlobal_Tickets) do
            log.print("Id: " .. ID)
        end
    end

    local function DebugPrintBlindOptimizeTickets()
        log.print("BlindOptimize Tickets:")
        for ID, _ in pairs(isCurseOfBlindNotGlobal_Tickets) do
            log.print("Id: " .. ID)
        end
    end

    local function DebugPrintTickets()
        DebugPrintGlobalBlindTickets()
        DebugPrintBlindOptimizeTickets()
    end

    local function DebugPrintTicketResults()
        log.print("IsCurseOfBlind: " .. tostring(IsCurseOfBlind()))
        log.print("IsBlindPedestalOptimized: " .. tostring(ReactionAPI.UserSettings.cOptimizeIsBlindPedestal and ShouldIsBlindPedestalBeOptimized()))
    end

    -------------------------------------------CRANE-----------------------------------------------

    ---------------------------------------------FLIP----------------------------------------------

    local function DebugPrintFlipData()
        local pedestals = Isaac.FindByType(5, 100, -1, true, false)
        local curRoomIndex = game:GetLevel():GetCurrentRoomDesc().ListIndex
        log.print("Printing Flip Data: ")
        for _, pedestal in ipairs(pedestals) do
            local flipEntry = flipFloorData[curRoomIndex] and flipFloorData[curRoomIndex][pedestal.InitSeed]
            if flipEntry then
                log.print("PickupId: " .. pedestal.Index .. " InitSeed " .. pedestal.InitSeed .. " EID FlipData: " .. tostring(flipEntry.CollectibleId))
                log.print("PickupId: " .. pedestal.Index .. " InitSeed " .. pedestal.InitSeed .. " FlipData: " .. tostring(flipData.ItemData[pedestal.Index]))
                log.print("PickupId: " .. pedestal.Index .. " InitSeed " .. pedestal.InitSeed .. " Is Flip Item: " .. tostring(not not flipData.InRoom[pedestal.Index]))
            end
        end
    end

    local function DebugPrintFlipItems()
        for entityIndex, entity in pairs(flipData.InRoom) do
            log.print("Flip Pedestal ID: " .. entityIndex .. " , InitSeed: " .. entity.InitSeed)
        end
    end

    ------------------------------------KEYBIND FUNCTIONS------------------------------------------

    local function PrintTicketDebug()
        DebugPrintTickets()
        DebugPrintTicketResults()
    end

    local function PrintCraneDebug()
        DebugPrintCraneData()
    end

    local function PrintFlipDebug()
        DebugPrintFlipData()
        DebugPrintFlipItems()
    end

    local function PrintHourglassDebug()
        ReactionAPI.DebugPrintHourglassTransaction()
    end

    ----------------------------------------KEYBINDS-----------------------------------------------

    local Keybinds = {
        [Keyboard.KEY_1] = PrintTicketDebug,
        [Keyboard.KEY_2] = PrintCraneDebug,
        [Keyboard.KEY_3] = PrintFlipDebug,
        [Keyboard.KEY_4] = PrintHourglassDebug
    }

    local function KeybindManager()
        for key, command in pairs(Keybinds) do
            if Input.IsButtonTriggered(key, 0) then
                command()
            end
        end
    end

    ReactionAPI:AddCallback(ModCallbacks.MC_POST_RENDER, KeybindManager)
end

