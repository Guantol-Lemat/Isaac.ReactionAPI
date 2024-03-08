local log = require("reactionAPI_scripts.tools.log")
local SharedData = require("reactionAPI_scripts.shared_data")
local DeepCopy = ReactionAPI.Utilities.DeepCopy
local RightDeepMerge = ReactionAPI.Utilities.RightDeepMerge

---------------------------------------------------------------------------------------------------
---------------------------------------------VARIABLES---------------------------------------------
---------------------------------------------------------------------------------------------------

----------------------------------------------CONTEXT----------------------------------------------

local filterNEW = ReactionAPI.Filter.NEW
local filterALL = ReactionAPI.Filter.ALL

local Crane = ReactionAPI.SlotType.CRANE_GAME

---------------------------------------------CONSTANTS---------------------------------------------

local game = Game()

-----------------------------------------------FLAGS-----------------------------------------------

local checkedCranePrizes = false
SharedData.HasCraneGivenPrize = false

---------------------------------------------AUXILIARY---------------------------------------------

local EIDCraneItemData = {}
-- Behaves exactly like EID.CraneItemType from External Item Description, the slotData[Crane].ItemData variable will be based around this value,
-- however it will diverge from it when Data is supposed to be deleted as that can cause unintended behavior, despite being a necessary step in properly obtaining ItemData

-----------------------------------------------MAIN------------------------------------------------

local SlotData = {
    [Crane] = {
        QualityStatus = {
            [filterNEW] = 0x00,
            [filterALL] = 0x00
        },
        BestQuality = ReactionAPI.QualityStatus.NO_ITEMS,
        ItemData = {},
        InRoom = {},
        New = {}
    }
}

---------------------------------------------------------------------------------------------------
---------------------------------------------FUNCTIONS---------------------------------------------
---------------------------------------------------------------------------------------------------

----------------------------------------------HELPER-----------------------------------------------

------------------------------------------------API------------------------------------------------

function SharedData.APIFunctions.GetSlotBestQuality(SlotType)
    if SlotType > ReactionAPI.SlotType.ALL or SlotType < 1 then
        log.error("Invalid SlotType", "GetSlotBestQuality")
        return nil
    end
    if SlotType == ReactionAPI.SlotType.ALL then
        log.error("SlotType cannot be set to ALL", "GetSlotBestQuality")
        return nil
    end

    return SlotData[SlotType].BestQuality
end

function SharedData.APIFunctions.GetSlotQualityStatus(SlotType, Filter)
    if SlotType > ReactionAPI.SlotType.ALL or SlotType < 1 then
        log.error("Invalid SlotType", "GetSlotQualityStatus")
        return nil
    end
    if SlotType == ReactionAPI.SlotType.ALL then
        log.error("SlotType cannot be set to ALL", "GetSlotQualityStatus")
        return nil
    end

    if Filter then
        return SlotData[SlotType].QualityStatus[Filter]
    end
    return SlotData[SlotType].QualityStatus
end

function SharedData.APIFunctions.GetSlotData(SlotType)
    if SlotType > ReactionAPI.SlotType.ALL or SlotType < 1 then
        log.error("Invalid SlotType", "GetSlotData")
        return nil
    end

    if SlotType < ReactionAPI.SlotType.ALL then
        return SlotData[SlotType]
    end
    return SlotData
end

----------------------------------------------CHECKS-----------------------------------------------

------------------------------------------------GET------------------------------------------------

------------------------------------------------SET------------------------------------------------

local function SetCraneQualityStatus(CraneEntity, IsNew) -- SetQualityStatus()
    local collectibleID = SlotData[Crane].ItemData[CraneEntity.InitSeed]
    if collectibleID then
        local itemQuality = ReactionAPI.CollectibleQuality[collectibleID] or ReactionAPI.QualityStatus.GLITCHED
        if itemQuality > ReactionAPI.QualityStatus.NO_ITEMS then
            SlotData[Crane].QualityStatus[IsNew] = SlotData[Crane].QualityStatus[IsNew] | 1 << (itemQuality + 1)
        end
    end
end

-----------------------------------------------RESET-----------------------------------------------

---------------------------------------------CALLBACK----------------------------------------------

local function CheckForCranePrizes()
    if checkedCranePrizes then
        return
    end
    for _, crane in ipairs(Isaac.FindByType(6, 16, -1, true, false)) do
        if crane:GetSprite():IsEventTriggered("Prize") then
            SharedData.HasCraneGivenPrize = true
            checkedCranePrizes = true
            return
        end
    end
    checkedCranePrizes = true
end

local function RecordUnobtainableData(_, collectibleId, itemPool)
    if itemPool == ItemPoolType.POOL_CRANE_GAME then
        for _, crane in ipairs(Isaac.FindByType(6, 16, -1, true, false)) do
            if not crane:GetSprite():IsPlaying("Broken") then
                if not EIDCraneItemData[tostring(crane.InitSeed)] then
                    SlotData[Crane].InRoom[crane.Index] = nil
                    -- Reset Crane so that it is detected as New
                    EIDCraneItemData[tostring(crane.InitSeed)] = collectibleId
                    break
                end
            end
        end
    end
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, CheckForCranePrizes, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, RecordUnobtainableData)

---------------------------------------------------------------------------------------------------
-------------------------------------------DATA HANDLERS-------------------------------------------
---------------------------------------------------------------------------------------------------

local DataHandler = {}

---------------------------------------------SAVE DATA---------------------------------------------

function DataHandler.SaveRunData()
    ReactionAPI.RunData.CraneItemData = DeepCopy(SlotData[Crane].ItemData)
    ReactionAPI.RunData.EIDCraneItemData = DeepCopy(EIDCraneItemData)
end

function DataHandler.LoadRunData()
    SlotData[Crane].ItemData = RightDeepMerge(DeepCopy(ReactionAPI.RunData.CraneItemData) or {}, SlotData[Crane].ItemData)
    EIDCraneItemData = RightDeepMerge(DeepCopy(ReactionAPI.RunData.EIDCraneItemData) or {}, EIDCraneItemData)
end

function DataHandler.ClearRunDataPostSave()
    SlotData[Crane].ItemData = {}
    EIDCraneItemData = {}
end

------------------------------------------SET ATTRIBUTES-------------------------------------------

function DataHandler.SetCraneData()
    for _, crane in ipairs(Isaac.FindByType(6, 16, -1, true, false)) do
        if crane:GetSprite():IsPlaying("Broken") then
            SlotData[Crane].InRoom[crane.Index] = nil
        else
            if SlotData[Crane].InRoom[crane.Index] == nil then
                SlotData[Crane].New[crane.Index] = true
            end
            SlotData[Crane].InRoom[crane.Index] = crane
        end
        if EIDCraneItemData[tostring(crane.InitSeed)] then
            if crane:GetSprite():IsPlaying("Prize") then
                EIDCraneItemData[tostring(crane.InitSeed)] = nil
            elseif EIDCraneItemData[crane.InitSeed.."Drop"..crane.DropSeed] == nil then
                EIDCraneItemData[crane.InitSeed.."Drop"..crane.DropSeed] = EIDCraneItemData[tostring(crane.InitSeed)]
                -- Pair the Crane Game's new drop seed with the latest collectible ID it's gotten
                -- (fixes Glowing Hour Glass rewinds)
            end
        end
        SlotData[Crane].ItemData[crane.InitSeed.."Drop"..crane.DropSeed] = EIDCraneItemData[crane.InitSeed.."Drop"..crane.DropSeed] or SlotData[Crane].ItemData[crane.InitSeed.."Drop"..crane.DropSeed]
        SlotData[Crane].ItemData[crane.InitSeed] = EIDCraneItemData[crane.InitSeed.."Drop"..crane.DropSeed] or EIDCraneItemData[tostring(crane.InitSeed)] or SlotData[Crane].ItemData[crane.InitSeed.."Drop"..crane.DropSeed] or SlotData[Crane].ItemData[crane.InitSeed]
    end
end

function DataHandler.SetQualityStatus()
    SlotData[Crane].QualityStatus = {
        [filterNEW] = 0x00,
        [filterALL] = 0x00
    }
    for _, craneEntity in pairs(SlotData[Crane].InRoom) do
        SetCraneQualityStatus(craneEntity, filterALL)
        if SlotData[Crane].New[craneEntity.Index] then
            SetCraneQualityStatus(craneEntity, filterNEW)
        end
    end
end

function DataHandler.SetBestQuality()
    SlotData[Crane].BestQuality = SlotData[Crane].QualityStatus[filterALL] == 0x00 and ReactionAPI.QualityStatus.NO_ITEMS or math.floor(math.log(SlotData[Crane].QualityStatus[filterALL], 2)) - 1
end

-----------------------------------------------RESET-----------------------------------------------

function DataHandler.ResetUpdateLocalVariables()
    checkedCranePrizes = false
    SharedData.HasCraneGivenPrize = false
    SlotData[Crane].New = {}
end

function DataHandler.ResetUpdatePersistentVariables()
    SlotData[Crane].InRoom = {}
end

function DataHandler.ResetFloorTrackers()
    EIDCraneItemData = {}
end

function DataHandler.HandleNonExistentEntities()
    for slotID, entity in pairs(SlotData[Crane].InRoom) do
        if not entity:Exists() then
            SlotData[Crane].InRoom[slotID] = nil
        end
    end
end

---------------------------------------------------------------------------------------------------
-----------------------------------------------DEBUG-----------------------------------------------
---------------------------------------------------------------------------------------------------

function SharedData.DEBUG.PrintCraneData()
    log.print("Printing Current Cranes Data:")
    for _, craneEntity in pairs(SlotData[Crane].InRoom) do
        local collectibleID = SlotData[Crane].ItemData[craneEntity.InitSeed.."Drop"..craneEntity.DropSeed] or SlotData[Crane].ItemData[craneEntity.InitSeed]
        log.print("CraneSeed: " .. tostring(craneEntity.InitSeed) .. " CollectibleID: " .. tostring(collectibleID))
        collectibleID = EIDCraneItemData[craneEntity.InitSeed.."Drop"..craneEntity.DropSeed] or EIDCraneItemData[tostring(craneEntity.InitSeed)]
        log.print("EID CraneSeed: " .. tostring(craneEntity.InitSeed) .. " EID CollectibleID: " .. tostring(collectibleID))
    end
    log.print("Printing Full Crane Data:")
    for craneSeed, collectibleId in pairs(SlotData[Crane].ItemData) do
        log.print("CraneSeed: " .. craneSeed .. " CollectibleID: " .. collectibleId)
    end
    for craneSeed, collectibleId in pairs(EIDCraneItemData) do
        log.print("EID CraneSeed: " .. craneSeed .. " EID CollectibleID: " .. collectibleId)
    end
end