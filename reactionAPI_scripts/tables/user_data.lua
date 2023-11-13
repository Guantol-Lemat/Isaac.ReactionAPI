local json = require("json")

ReactionAPI.UserSettings = {
    Version = ReactionAPI.ModVersion,
    cImplementation = ReactionAPI.cImplementation,
    cOptimizeIsBlindPedestal = true,
    cEternalBlindOverwrite = ReactionAPI.QualityStatus.QUALITY_2,
    cVanilla = {},
    cModded = {}
}

ReactionAPI.CollectibleData = {}

if ReactionAPI:HasData() then
    local loadedData = json.decode(ReactionAPI:LoadData())
    ReactionAPI.UserSettings.cImplementation = loadedData["cImplementation"] or ReactionAPI.UserSettings.cImplementation
end

ReactionAPI.cImplementation = ReactionAPI.UserSettings.cImplementation

ReactionAPI.MaxCollectibleID = 0

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
                ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
            elseif ReactionAPI.UserSettings["cVanilla"][collectibleID] == ReactionAPI.Setting.IGNORE then
                ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
            else
                ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.UserSettings["cVanilla"][collectibleID]
            end
        end
    end

    for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            if ReactionAPI.UserSettings["cModded"][collectible.Name] then
                if ReactionAPI.UserSettings["cModded"][collectible.Name] == ReactionAPI.Setting.DEFAULT then
                    ReactionAPI.CollectibleData[collectible.ID] = collectible.Quality
                elseif ReactionAPI.UserSettings["cModded"][collectible.Name] == ReactionAPI.Setting.IGNORE then
                    ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                else
                    ReactionAPI.CollectibleData[collectible.ID] = ReactionAPI.UserSettings["cModded"][collectible.Name]
                end
            end
        end
    end
end

local function InitItemData()
    for collectibleID = 1, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
        end
    end    
end

local function InitModData()

    ReactionAPI.MaxCollectibleID = GetMaxCollectibleID()

    ReactionAPI.CollectibleData[0] = ReactionAPI.QualityStatus.NO_ITEMS

    if ModConfigMenu then
        InitUserData()
        InitItemDataMCM() 
        MCM:InitModConfigMenu()
    else
        InitUserData()
        InitItemData()
    end

    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)       
end

local function SaveSettings()
    ReactionAPI:SaveData(json.encode(ReactionAPI.UserSettings))
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveSettings)