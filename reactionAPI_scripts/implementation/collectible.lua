local log = require("reactionAPI_scripts.tools.log")
local SharedData = require("reactionAPI_scripts.shared_data")

---------------------------------------------------------------------------------------------------
---------------------------------------------VARIABLES---------------------------------------------
---------------------------------------------------------------------------------------------------

-----------------------------------------------DEBUG-----------------------------------------------

local updateCycle_ProfileTimeStart = Isaac.GetTime()
local numCollectibleUpdates = 0

----------------------------------------------CONTEXT----------------------------------------------

local visible = ReactionAPI.Visibility.VISIBLE
local blind = ReactionAPI.Visibility.BLIND
local absolute = ReactionAPI.Visibility.ABSOLUTE
local filterNEW = ReactionAPI.Filter.NEW
local filterALL = ReactionAPI.Filter.ALL
local resetGLOBAL = ReactionAPI.Reset.GLOBAL
local resetLOCAL = ReactionAPI.Reset.LOCAL

---------------------------------------------CONSTANTS---------------------------------------------

local blindCollectibleSprite = Sprite()
blindCollectibleSprite:Load("gfx/005.100_collectible.anm2", true)
blindCollectibleSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/questionmark.png")
blindCollectibleSprite:LoadGraphics()

-----------------------------------------------FLAGS-----------------------------------------------

local onCollectibleUpdate_FirstExecution = true

---------------------------------------------AUXILIARY---------------------------------------------

local poofPositions = {}
local cachedOptionGroup = {}
local wipedOptionGroups = {}

-----------------------------------------------MAIN------------------------------------------------

local CollectibleData = {
    InRoom = {},
    New = {[visible] = {}, [blind] = {}},
    Blind = {},
    Shop = {},
    Pedestals = {},
    QualityStatus = {
        [visible] = {[filterNEW] = 0x00, [filterALL] = 0x00},
        [blind] = {[filterNEW] = 0x00, [filterALL] = 0x00},
        [absolute] = {[filterNEW] = 0x00, [filterALL] = 0x00}
    },
    BestQuality = {
        [visible] = ReactionAPI.QualityStatus.NO_ITEMS,
        [blind] = ReactionAPI.QualityStatus.NO_ITEMS,
        [absolute] = ReactionAPI.QualityStatus.NO_ITEMS
    }
}

---------------------------------------------------------------------------------------------------
---------------------------------------------FUNCTIONS---------------------------------------------
---------------------------------------------------------------------------------------------------

----------------------------------------------HELPER-----------------------------------------------

local function ShiftCycleData(CycleData)
    table.insert(CycleData, #CycleData + 1,CycleData[1])
    table.remove(CycleData, 1)
    return CycleData
end

----------------------------------------------CHECKS-----------------------------------------------

local function IsTouchedCollectible(EntityPickup) --OnCollectibleUpdate() --HandleShopItems()
    return EntityPickup.Touched or EntityPickup.SubType == 0
end

local function CompareCycleData(TargetEntityIndex, CycleData) --REPENTOGON Only
    if #CollectibleData.InRoom[TargetEntityIndex] ~= #CycleData then
        return false
    end
    for cycleOrder, collectibleID in ipairs(CycleData) do
        if CollectibleData.InRoom[TargetEntityIndex][cycleOrder] ~= collectibleID then
            if SharedData.DEBUG then
                log.print("Difference Found: " .. cycleOrder .. "." .. CollectibleData.InRoom[TargetEntityIndex][cycleOrder] .. "~=" .. collectibleID)
            end
            return false
        end
    end
    return true
end

local function IsNewCollectible(EntityPickup)
    if CollectibleData.InRoom[EntityPickup.Index] == nil then
        return true
    end
    for _, poofPosition in pairs(poofPositions) do
        if EntityPickup.Position:Distance(poofPosition) == 0.0 then
            return true
        end
    end
    return false
end

local function IsBlindCollectible(EntityPickup) --OnCollectibleUpdate()
    if SharedData.GloballyBlind then
        return true
    end
    for _, condition in ipairs(SharedData.CollectibleBlindConditions) do
        if condition(EntityPickup) then
            return true
        end
    end
    return false
end

------------------------------------------------GET------------------------------------------------

local function GetFullCycleData(EntityPickup) -- REPENTOGON only
    local cycleData = {}
    cycleData[1] = EntityPickup.SubType
    for cycleOrder, collectibleId in ipairs(EntityPickup:GetCollectibleCycle()) do
        cycleData[cycleOrder + 1] = collectibleId
    end
    return cycleData
end

local function GetNEWTargetTable(EntityID, EntityExisted, CycleNum)
    local isCycling = CycleNum > 1
    if SharedData.HasCraneGivenPrize and not EntityExisted and not isCycling then
        return SharedData.FakeNewData.cranePrize.New
    end

    local isFlipPedestal = not not SharedData.APIFunctions.GetAlternatePedestal(EntityID)
    if SharedData.WasFlipUsed and isFlipPedestal and not isCycling then
        return SharedData.FakeNewData.flipVisible.New
    else
        return CollectibleData.New
    end
end

------------------------------------------------SET------------------------------------------------

local function SetCollectibleData(EntityPickup)
end

if REPENTOGON then
    SetCollectibleData = function(EntityPickup)
        local didPedestalExist = CollectibleData.Pedestals[EntityPickup.Index] ~= nil
        CollectibleData.Pedestals[EntityPickup.Index] = EntityPickup

        if EntityPickup:IsShopItem() then
            CollectibleData.Shop[EntityPickup.Index] = EntityPickup
        end

        if CollectibleData.InRoom[EntityPickup.Index] == nil then
            CollectibleData.InRoom[EntityPickup.Index] = {}
            CollectibleData.Blind[EntityPickup.Index] = nil

            local isBlind = IsBlindCollectible(EntityPickup)
            if isBlind then
                CollectibleData.Blind[EntityPickup.Index] = EntityPickup
            end

            local cycleData = GetFullCycleData(EntityPickup)
            CollectibleData.InRoom[EntityPickup.Index] = cycleData
            local newDataTable = GetNEWTargetTable(EntityPickup.Index, didPedestalExist, #cycleData)
            for _, collectibleId in ipairs(cycleData) do
                newDataTable[isBlind][collectibleId] = true
            end
            return
        end

        if SharedData.RequestedPickupResets[EntityPickup.Index] then
            SharedData.RequestedPickupResets[EntityPickup.Index] = nil
            local previousIsBlind = CollectibleData.Blind[EntityPickup.Index] ~= nil
            CollectibleData.Blind[EntityPickup.Index] = nil
            local isBlind = IsBlindCollectible(EntityPickup)
            if isBlind then
                CollectibleData.Blind[EntityPickup.Index] = EntityPickup
            end

            local cycleData = GetFullCycleData(EntityPickup)
            CollectibleData.InRoom[EntityPickup.Index] = ShiftCycleData(CollectibleData.InRoom[EntityPickup.Index])
            if CompareCycleData(EntityPickup.Index, cycleData) then
                if previousIsBlind ~= isBlind then
                    local newDataTable = GetNEWTargetTable(EntityPickup.Index, didPedestalExist, #cycleData)
                    for _, collectibleId in ipairs(cycleData) do
                        newDataTable[isBlind][collectibleId] = true
                    end
                end
                return
            end

            CollectibleData.InRoom[EntityPickup.Index] = cycleData
            local newDataTable = GetNEWTargetTable(EntityPickup.Index, didPedestalExist, #cycleData)
            for _, collectibleId in ipairs(cycleData) do
                newDataTable[isBlind][collectibleId] = true
            end
        end
    end
else
    SetCollectibleData = function(EntityPickup)
        local isBlind = nil --NOT INITIALIZED YET

        local didPedestalExist = CollectibleData.Pedestals[EntityPickup.Index] ~= nil
        CollectibleData.Pedestals[EntityPickup.Index] = EntityPickup

        if EntityPickup:IsShopItem() then
            CollectibleData.Shop[EntityPickup.Index] = EntityPickup
        end

        if IsNewCollectible(EntityPickup) or SharedData.RequestedPickupResets[EntityPickup.Index] then
            SharedData.RequestedPickupResets[EntityPickup.Index] = nil
            CollectibleData.InRoom[EntityPickup.Index] = {}
            CollectibleData.Blind[EntityPickup.Index] = nil
        end
        if CollectibleData.Blind[EntityPickup.Index] ~= nil then
            isBlind = true
        else
            isBlind = IsBlindCollectible(EntityPickup)
            if isBlind then
                CollectibleData.Blind[EntityPickup.Index] = EntityPickup
            end
        end

        if CollectibleData.InRoom[EntityPickup.Index][EntityPickup.SubType] == nil then
            local cycleNum = ReactionAPI.Utilities.GetTableLength(CollectibleData.InRoom[EntityPickup.Index]) + 1
            local newDataTable = GetNEWTargetTable(EntityPickup.Index, didPedestalExist, cycleNum)
            newDataTable[isBlind][EntityPickup.SubType] = true
            CollectibleData.InRoom[EntityPickup.Index][EntityPickup.SubType] = ReactionAPI.Utilities.GetTableLength(CollectibleData.InRoom[EntityPickup.Index]) + 1
        end
    end
end

----------------------------------------------PROFILE----------------------------------------------

local function ProfileCollectibleUpdate()
    if numCollectibleUpdates == 0 then
        updateCycle_ProfileTimeStart = Isaac.GetTime()
    end
    numCollectibleUpdates = numCollectibleUpdates + 1
end

local function Print_onCollectibleUpdate_Profile()
    log.print("Completed ReactionAPI Update Cycle in : " .. Isaac.GetTime() - updateCycle_ProfileTimeStart .. " ms with " .. numCollectibleUpdates .. " Executions")
    updateCycle_ProfileTimeStart = Isaac.GetTime()
    numCollectibleUpdates = 0
end

---------------------------------------------CALLBACK----------------------------------------------

local function RequestResetOnMorph(_, EntityPickup) -- REPENTOGON Only
    if EntityPickup.Variant == PickupVariant.PICKUP_COLLECTIBLE then
        ReactionAPI.RequestReset(resetLOCAL, {EntityPickup.Index})
    end
end

local function RecordPoofPosition(_, EntityEffect)
    table.insert(poofPositions, EntityEffect.Position)
end

local function onCollectibleUpdate(_, EntityPickup)
end

if REPENTOGON then
    onCollectibleUpdate = function(_, EntityPickup)
        if SharedData.PROFILE.Enabled then
            ProfileCollectibleUpdate()
        end

        if onCollectibleUpdate_FirstExecution then
            SharedData.HandleRequestedGlobalResets()
        end
        onCollectibleUpdate_FirstExecution = false

        if IsTouchedCollectible(EntityPickup) then
            CollectibleData.Pedestals[EntityPickup.Index] = nil
            CollectibleData.InRoom[EntityPickup.Index] = nil
            CollectibleData.Shop[EntityPickup.Index] = nil
            CollectibleData.Blind[EntityPickup.Index] = nil
            return
        end

        SetCollectibleData(EntityPickup)
    end
else
    onCollectibleUpdate = function(_, EntityPickup)
        ProfileCollectibleUpdate()

        if onCollectibleUpdate_FirstExecution then
            SharedData.HandleRequestedGlobalResets()
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
            CollectibleData.Pedestals[EntityPickup.Index] = nil
            CollectibleData.InRoom[EntityPickup.Index] = nil
            CollectibleData.Shop[EntityPickup.Index] = nil
            CollectibleData.Blind[EntityPickup.Index] = nil
            return
        end

        SetCollectibleData(EntityPickup)
    end
end

if REPENTOGON then
    ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_MORPH, RequestResetOnMorph)
else
    ReactionAPI:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, RecordPoofPosition, EffectVariant.POOF01)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, onCollectibleUpdate, PickupVariant.PICKUP_COLLECTIBLE)

-------------------------------------------DATA HANDLERS-------------------------------------------

local DataHandler = {}

function DataHandler.ResetUpdateLocalVariables()
    onCollectibleUpdate_FirstExecution = true
    poofPositions = {}
    CollectibleData.New = {[visible] = {}, [blind] = {}}
end

function DataHandler.ResetUpdatePersistentVariables()
    cachedOptionGroup = {}
    wipedOptionGroups = {}
    CollectibleData.InRoom = {}
    CollectibleData.Pedestals = {}
    CollectibleData.Blind = {}
    CollectibleData.Shop = {}
end

function DataHandler.HandleNonExistentEntities()
    for pickupID, entity in pairs(CollectibleData.Pedestals) do
        if not entity:Exists() or IsTouchedCollectible(entity) then
            CollectibleData.InRoom[pickupID] = nil
            CollectibleData.Pedestals[pickupID] = nil
            CollectibleData.Blind[pickupID] = nil
            CollectibleData.Shop[pickupID] = nil
        end
    end
end

function DataHandler.GetData()
    return CollectibleData
end