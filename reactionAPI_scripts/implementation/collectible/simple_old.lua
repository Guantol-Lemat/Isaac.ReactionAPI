-- ReactionAPI.ProfilerStart = 0

local questionMarkPedestalSprite = Sprite()
questionMarkPedestalSprite:Load("gfx/005.100_collectible.anm2", true)
questionMarkPedestalSprite:ReplaceSpritesheet(1, "gfx/items/collectibles/questionmark.png")
questionMarkPedestalSprite:LoadGraphics()

local collectibleResetOccured = false
local collectibleInitialized = false
local poofInitialized = false
local delayPoofReset = false
local isHoldingCollectible = false

local previous_isHoldingCollectible = false

local delayCollectibleReset = false

ReactionAPI.requestedReset = false
ReactionAPI.globalBlindCurse = false

ReactionAPI.bestCollectibleQuality = ReactionAPI.QualityStatus.NO_ITEMS
ReactionAPI.bestCollectibleQualityBlind = ReactionAPI.QualityStatus.NO_ITEMS

local previous_bestCollectibleQuality = ReactionAPI.QualityStatus.NO_ITEMS
local previous_bestCollectibleQualityBlind = ReactionAPI.QualityStatus.NO_ITEMS

ReactionAPI.changed_bestCollectibleQuality = false
ReactionAPI.changed_bestCollectibleQualityBlind = false

ReactionAPI.cQualityPresence = 0x00
ReactionAPI.cBlindQualityPresence = 0x00

local previous_cQualityPresence = 0x00
local previous_cBlindQualityPresence = 0x00

ReactionAPI.changed_cQualityPresence = false
ReactionAPI.changed_cBlindQualityPresence = false

local collectiblePositions = {}
local poofPositions = {}

ReactionAPI.globalCurseOfBlind = true

ReactionAPI.globalBlindConditions = {}

local function IsCurseBlind()
    return (Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND ~= 0) and ReactionAPI.globalCurseOfBlind
end

table.insert(ReactionAPI.globalBlindConditions, IsCurseBlind)

ReactionAPI.blindCollectibleConditions = {}

local function IsBlindPedestal(EntityPickup)
    local pedestalSprite = EntityPickup:GetSprite()
    questionMarkPedestalSprite:SetFrame(pedestalSprite:GetAnimation(), pedestalSprite:GetFrame())
    for i = -70, 0, 2 do
        local qcolor = questionMarkPedestalSprite:GetTexel(Vector(0, i), Vector.Zero, 1, 1)
        local ecolor = pedestalSprite:GetTexel(Vector(0, i), Vector.Zero, 1, 1)
        if qcolor.Red ~= ecolor.Red or qcolor.Green ~= ecolor.Green or qcolor.Blue ~= ecolor.Blue then
            return false
        end
    end
    return true
end

table.insert(ReactionAPI.blindCollectibleConditions, IsBlindPedestal)

local collectibleExecutions = 0

local function CollectibleReset()
    ReactionAPI.bestCollectibleQuality = ReactionAPI.QualityStatus.NO_ITEMS
    ReactionAPI.bestCollectibleQualityBlind = ReactionAPI.QualityStatus.NO_ITEMS
    ReactionAPI.cQualityPresence = 0x00
    ReactionAPI.cBlindQualityPresence = 0x00
    collectibleResetOccured = true
    collectibleInitialized = true
end

local function HandleRequestedResets()
    if not collectibleResetOccured and ReactionAPI.requestedReset and not delayCollectibleReset then
        if collectibleExecutions == 1 then
            CollectibleReset()
        else
            delayCollectibleReset = true
        end
    end
    ReactionAPI.requestedReset = false
end

local function ResetOnPoofedCollectible()
    for _, collectiblePosition in ipairs(collectiblePositions) do
        if collectibleResetOccured then
            break
        end
        for _, poofPosition in ipairs(poofPositions) do
            if collectiblePosition:Distance(poofPosition) == 0.0 then
                CollectibleReset()
                break
            end
        end
    end
end

local function HandlePoofResets()
    if not collectibleResetOccured and poofInitialized then
        if collectibleExecutions == 1 then
            ResetOnPoofedCollectible()
        else
            delayPoofReset = true
        end
    end
end

local function IsCollectibleBlind(EntityPickup)
    for _, condition in ipairs(ReactionAPI.blindCollectibleConditions) do
        if condition(EntityPickup) then
            return true
        end
    end
    return false
end

local function UpdateBlindCollectible(ItemQuality)
    ReactionAPI.cBlindQualityPresence = ReactionAPI.cBlindQualityPresence | 1 << (ItemQuality + 1)
    if ReactionAPI.bestCollectibleQualityBlind < ItemQuality then
        ReactionAPI.bestCollectibleQualityBlind = ItemQuality
    end
end

local function UpdateCollectible(ItemQuality)
    ReactionAPI.cBlindQualityPresence = ReactionAPI.cBlindQualityPresence | 1 << (ItemQuality + 1)
    if ReactionAPI.bestCollectibleQualityBlind < ItemQuality then
        ReactionAPI.bestCollectibleQualityBlind = ItemQuality
    end
    ReactionAPI.cQualityPresence = ReactionAPI.cQualityPresence | 1 << (ItemQuality + 1)
    if ReactionAPI.bestCollectibleQuality < ItemQuality then
        ReactionAPI.bestCollectibleQuality = ItemQuality
    end
end

local function UpdateCollectibleQuality(EntityPickup)
    if EntityPickup.Touched then
        return
    end
    if EntityPickup.SubType > ReactionAPI.MaxCollectibleID then
        ItemQuality = ReactionAPI.QualityStatus.GLITCHED
    else
        ItemQuality = ReactionAPI.CollectibleData[EntityPickup.SubType]
    end
    -- Isaac.DebugString("bestCollectibleQuality: " .. ReactionAPI.bestCollectibleQuality)
    -- Isaac.DebugString("bestCollectibleQualityBlind: " .. ReactionAPI.bestCollectibleQualityBlind)
    -- Isaac.DebugString("ItemQuality: " .. ItemQuality)
    -- Isaac.DebugString("Item ID: " ..EntityPickup.SubType)
    -- Isaac.DebugString("maxID: " .. ReactionAPI.MaxCollectibleID)
    if (ReactionAPI.cQualityPresence & 1 << (ItemQuality + 1)) ~=0 then
        return
    end
    local IsBlind = ReactionAPI.globalBlindCurse or IsCollectibleBlind(EntityPickup)
    if IsBlind then
        UpdateBlindCollectible(ItemQuality)
    else
        UpdateCollectible(ItemQuality)
    end
    -- Isaac.DebugString("bestCollectibleQuality After Update: " .. ReactionAPI.bestCollectibleQuality)
    -- Isaac.DebugString("bestCollectibleQualityBlind After Update: " .. ReactionAPI.bestCollectibleQualityBlind)
end

local function RecordCollectiblePosition(_, EntityPickup)
    -- Isaac.DebugString("Pickup Init")
    collectibleInitialized = true
    table.insert(collectiblePositions, EntityPickup.Position)
end

local function RecordPoofPosition(_, EntityEffect)
    -- Isaac.DebugString("Effect Init")
    poofInitialized = true
    table.insert(poofPositions, EntityEffect.Position)
end 

local function onCollectibleUpdate(_, EntityPickup)
    -- Isaac.DebugString("Pickup Update Has run")
    collectibleExecutions = collectibleExecutions + 1
    -- if collectibleExecutions == 1 then
        -- ReactionAPI.ProfilerStart = Isaac.GetTime()
    -- end
    HandleRequestedResets()
    HandlePoofResets()
    if collectibleInitialized or EntityPickup:IsShopItem() then
        -- Isaac.DebugString("Pickup Update")
        UpdateCollectibleQuality(EntityPickup)
    end
end

local function onFinalUpdate()
    -- Isaac.DebugString("Update Over")
    -- local profilerEnd = Isaac.GetTime() - ReactionAPI.ProfilerStart
    -- Isaac.DebugString("My Executions: " .. collectibleExecutions .. " Time: " .. profilerEnd )
    if collectibleExecutions == 0 then
        ReactionAPI.bestCollectibleQuality = ReactionAPI.QualityStatus.NO_ITEMS
        ReactionAPI.bestCollectibleQualityBlind = ReactionAPI.QualityStatus.NO_ITEMS

        ReactionAPI.cQualityPresence = 0x00
        ReactionAPI.cBlindQualityPresence = 0x00
    end
    collectibleResetOccured = false
    if not delayPoofReset then
        collectibleInitialized = false
        poofInitialized = false
        collectiblePositions = {}
        poofPositions = {}
    end
    collectibleExecutions = 0
    delayPoofReset = false

    previous_isHoldingCollectible = isHoldingCollectible

    ReactionAPI.changed_bestCollectibleQuality = previous_bestCollectibleQuality ~= ReactionAPI.bestCollectibleQuality
    ReactionAPI.changed_bestCollectibleQualityBlind = previous_bestCollectibleQualityBlind ~= ReactionAPI.bestCollectibleQualityBlind

    ReactionAPI.changed_cQualityPresence = previous_cQualityPresence ~= ReactionAPI.cQualityPresence
    ReactionAPI.changed_cBlindQualityPresence = previous_cBlindQualityPresence ~= ReactionAPI.cBlindQualityPresence

    previous_bestCollectibleQuality = ReactionAPI.bestCollectibleQuality
    previous_bestCollectibleQualityBlind = ReactionAPI.bestCollectibleQualityBlind
    -- Isaac.DebugString("Result:" .. ReactionAPI.bestCollectibleQuality)
    -- Isaac.DebugString("Result Blind:" .. ReactionAPI.bestCollectibleQualityBlind)
end

function EvaluateGlobalBlindCurse(EntityPickup)
    for _, condition in ipairs(ReactionAPI.globalBlindConditions) do
        if condition(EntityPickup) then
            ReactionAPI.globalBlindCurse = true
            return
        end
    end
    ReactionAPI.globalBlindCurse = false
end

local function HandleDelayedResets()
    HandleRequestedResets()
    if delayCollectibleReset then
        CollectibleReset()
    end
    delayCollectibleReset = false
end

local function ResetOnCollision(_, EntityPlayer)
    if EntityPlayer.QueuedItem.Item then
        isHoldingCollectible = EntityPlayer.QueuedItem.Item:IsCollectible()
    else
        isHoldingCollectible = false
    end
    if isHoldingCollectible and not previous_isHoldingCollectible then
        CollectibleReset()
    end
end

local function ResetOnNewRoom()
    -- Isaac.DebugString('On New Room')
    CollectibleReset()
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_EFFECT_INIT, RecordPoofPosition, EffectVariant.POOF01)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_INIT, RecordCollectiblePosition, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, onCollectibleUpdate, PickupVariant.PICKUP_COLLECTIBLE)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.IMPORTANT, onFinalUpdate)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, EvaluateGlobalBlindCurse)

ReactionAPI:AddPriorityCallback(ModCallbacks.MC_POST_UPDATE, CallbackPriority.LATE, HandleDelayedResets)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, ResetOnNewRoom)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_PLAYER_UPDATE, ResetOnCollision)
