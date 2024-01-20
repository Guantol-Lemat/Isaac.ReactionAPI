local json = require("json")
local DeepCopy = ReactionAPI.Utilities.DeepCopy

local removedInitModData = false

ReactionAPI.ConfigVersion = "1.0.0"

local firstStart = true

ReactionAPI.DefaultUserSettings = {
    Version = ReactionAPI.ModVersion,
    ConfigVersion = ReactionAPI.ConfigVersion,
--    cImplementation = ReactionAPI.cImplementation,
    cOptimizeIsBlindPedestal = true,
    cEternalBlindOverwrite = ReactionAPI.QualityStatus.QUALITY_2,
    cVanilla = {},
    cModded = {}
}

ReactionAPI.UserSettings = DeepCopy(ReactionAPI.DefaultUserSettings)

ReactionAPI.CollectibleQuality = {}

--[[

if ReactionAPI:HasData() then
    local loadedData = json.decode(ReactionAPI:LoadData())
    ReactionAPI.UserSettings.cImplementation = loadedData["cImplementation"] or ReactionAPI.UserSettings.cImplementation
end

]]

ReactionAPI.cImplementation = ReactionAPI.UserSettings.cImplementation

ReactionAPI.MaxCollectibleID = nil

local MCM = include("reactionAPI_scripts.menu.mod_config_menu")

local function GetMaxCollectibleID()
    local id = CollectibleType.NUM_COLLECTIBLES-1
    local step = 16
    while step > 0 do
        if Isaac.GetItemConfig():GetCollectible(id+step) ~= nil then
            id = id + step
        else
            step = step // 2
        end
    end

    return id
end

local function InitUserData()
    if ReactionAPI:HasData() then
        local loadedData = json.decode(ReactionAPI:LoadData())
        ReactionAPI.UserSettings.cOptimizeIsBlindPedestal = loadedData["cOptimizeIsBlindPedestal"] or ReactionAPI.UserSettings.cOptimizeIsBlindPedestal
        ReactionAPI.UserSettings.cEternalBlindOverwrite = loadedData["cEternalBlindOverwrite"] or ReactionAPI.UserSettings.cEternalBlindOverwrite

        ReactionAPI.UserSettings["cVanilla"] = loadedData["cVanilla"] or ReactionAPI.UserSettings["cVanilla"]

        for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do -- Future Proofs Vanilla Collectibles
            if not loadedData["cVanilla"][collectibleID] then
                ReactionAPI.UserSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.DEFAULT
            end
        end

        ReactionAPI.UserSettings["cModded"] = loadedData["cModded"] or ReactionAPI.UserSettings["cModded"] -- Needed so that settings are not erased when mods are disabled

        for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
            local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
            if collectible then
                if not loadedData["cModded"][collectible.Name] then
                    ReactionAPI.UserSettings["cModded"][collectible.Name] = ReactionAPI.Setting.DEFAULT
                end
            end
        end
    else
        for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do
            ReactionAPI.UserSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.DEFAULT
        end

        for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
            local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
            if collectible then
                ReactionAPI.UserSettings["cModded"][collectible.Name] = ReactionAPI.Setting.DEFAULT
            end
        end
    end
end

local function InitItemDataMCM()
    for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            if ReactionAPI.UserSettings["cVanilla"][collectibleID] == ReactionAPI.Setting.DEFAULT then
                ReactionAPI.CollectibleQuality[collectibleID] = collectible.Quality
            elseif ReactionAPI.UserSettings["cVanilla"][collectibleID] == ReactionAPI.Setting.IGNORE then
                ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
            else
                ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.UserSettings["cVanilla"][collectibleID]
            end
        end
    end

    for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            if ReactionAPI.UserSettings["cModded"][collectible.Name] then
                if ReactionAPI.UserSettings["cModded"][collectible.Name] == ReactionAPI.Setting.DEFAULT then
                    ReactionAPI.CollectibleQuality[collectible.ID] = collectible.Quality
                elseif ReactionAPI.UserSettings["cModded"][collectible.Name] == ReactionAPI.Setting.IGNORE then
                    ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                else
                    ReactionAPI.CollectibleQuality[collectible.ID] = ReactionAPI.UserSettings["cModded"][collectible.Name]
                end
            end
        end
    end
end

local function InitItemData()
    for collectibleID = 1, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            ReactionAPI.CollectibleQuality[collectibleID] = collectible.Quality
        end
    end
end

local function InitSaveData()
    if firstStart then
        firstStart = false
        return
    end
    ReactionAPI.UserSettings = DeepCopy(ReactionAPI.DefaultUserSettings)
    if ModConfigMenu then
        InitUserData()
        InitItemDataMCM()
    else
        InitUserData()
        InitItemData()
    end
end

local function InitModData()
    if removedInitModData then
        return
    end

    ReactionAPI.MaxCollectibleID = GetMaxCollectibleID()

    ReactionAPI.CollectibleQuality[0] = ReactionAPI.QualityStatus.NO_ITEMS

    if ModConfigMenu then
        InitUserData()
        InitItemDataMCM()
        MCM:InitModConfigMenu()
    else
        InitUserData()
        InitItemData()
    end

    ReactionAPI:AddCallback(ModCallbacks.MC_POST_GAME_STARTED, InitSaveData)
    removedInitModData = true
--    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)
end

local function SaveSettings()
    ReactionAPI.CopyRunData()
    ReactionAPI.UserSettings.RunData = DeepCopy(ReactionAPI.RunData)
    ReactionAPI.CopyGHManagerData()
    ReactionAPI.UserSettings.GHManagerData = DeepCopy(ReactionAPI.GHManagerData)
    ReactionAPI:SaveData(json.encode(ReactionAPI.UserSettings))
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveSettings)