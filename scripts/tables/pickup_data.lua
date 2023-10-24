local json = require("json")

ReactionAPI.CollectibleData = {}

ReactionAPI.SavedSettings = {
    Version = ReactionAPI.ModVersion,
    cVanilla = {},
    cModded = {}
}

ReactionAPI.MaxCollectibleID = 0

function GetMaxCollectibleID()
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

local function InitSaveData()
    if ReactionAPI:HasData() then
        local loadedData = json.decode(ReactionAPI:LoadData()) 

        ReactionAPI.SavedSettings["cVanilla"] = loadedData["cVanilla"]

        for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do -- Future Proofs Vanilla Collectibles
            if not loadedData["cVanilla"][collectibleID] then
                ReactionAPI.SavedSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.DEFAULT
            end
        end

        ReactionAPI.SavedSettings["cModded"] = loadedData["cModded"] -- Needed so that settings are not erased when mods are disabled

        for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
            local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
            if collectible then
                if not loadedData["cModded"][collectible.Name] then
                    ReactionAPI.SavedSettings["cModded"][collectible.Name] = ReactionAPI.Setting.DEFAULT
                end
            end
        end
    else
        for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do
            ReactionAPI.SavedSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.DEFAULT
        end
    
        for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
            local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
            if collectible then
                ReactionAPI.SavedSettings["cModded"][collectible.Name] = ReactionAPI.Setting.DEFAULT
            end
        end        
    end    
end

local function InitItemDataMCM()
    for collectibleID = 1, CollectibleType.NUM_COLLECTIBLES-1 do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            if ReactionAPI.SavedSettings["cVanilla"][collectibleID] == ReactionAPI.Setting.DEFAULT then
                ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
            else
                ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.SavedSettings["cVanilla"][collectibleID]
            end
        end
    end

    for collectibleID = CollectibleType.NUM_COLLECTIBLES, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            if ReactionAPI.SavedSettings["cModded"][collectible.Name] then
                if ReactionAPI.SavedSettings["cModded"][collectible.Name] == ReactionAPI.Setting.DEFAULT then
                    ReactionAPI.CollectibleData[collectible.ID] = collectible.Quality
                else
                    ReactionAPI.CollectibleData[collectible.ID] = ReactionAPI.SavedSettings["cModded"][collectible.Name]
                end
            end
        end
    end  
end

local function InitModConfigMenu()
    local CategoryName = "ReactionAPI"

    ModConfigMenu.UpdateCategory(CategoryName, {
        Info = {"ReactionAPI Settings.",}
    })

    --Info

    ModConfigMenu.AddText(CategoryName, "Info", function() return "ReactionAPI" end)
    ModConfigMenu.AddSpace(CategoryName, "Info")
    ModConfigMenu.AddText(CategoryName, "Info", function() return "Version " .. ReactionAPI.ModVersion end)
    ModConfigMenu.AddSpace(CategoryName, "Info")
    ModConfigMenu.AddText(CategoryName, "Info", function() return "by Guantol" end)

    --Create Vanilla Settings

    for collectibleID = 1,CollectibleType.NUM_COLLECTIBLES-1 do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        local lastID = math.ceil(collectibleID / 100) * 100
        local firstID = lastID - 99

        if lastID >= CollectibleType.NUM_COLLECTIBLES-1 then
            lastID = CollectibleType.NUM_COLLECTIBLES-1
        end

        local subcategoryName = firstID .. "-" .. lastID

        if collectibleID % 100 == 1 then
            ModConfigMenu.AddText(CategoryName, subcategoryName, function() return "Customize settings for Vanilla items" end)
        end

        if collectible then
            ModConfigMenu.AddSetting(CategoryName, subcategoryName,
            {
                Type = ModConfigMenu.OptionType.NUMBER,
                CurrentSetting = function()
                    return ReactionAPI.SavedSettings["cVanilla"][collectibleID]
                end,
                Minimum = ReactionAPI.QualityStatus.QUALITY_0,
                Maximum = ReactionAPI.Setting.DEFAULT,
                Display = function()
                    local choice = ReactionAPI.MCMStrings[ReactionAPI.SavedSettings["cVanilla"][collectibleID]]
                    return collectibleID .. '' .. collectible.Name .. ': ' .. choice
                end,
                OnChange = function(currentSetting)
                    if currentSetting == ReactionAPI.Setting.DEFAULT then
                        ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
                    else
                        ReactionAPI.CollectibleData[collectibleID] = currentSetting
                    end
                    ReactionAPI.SavedSettings["cVanilla"][collectibleID] = currentSetting
                    ReactionAPI.requestedReset = true
                end,
                Info = {collectible.Name .. " (Quality ".. collectible.Quality .. ")"}
            })
        end
    end

    --Create Modded Settings

    for collectibleID = CollectibleType.NUM_COLLECTIBLES,ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        local lastID = math.ceil(collectibleID / 100) * 100
        local firstID = lastID - 99

        if math.floor((collectibleID - 1) / 100) == math.floor((CollectibleType.NUM_COLLECTIBLES - 1) / 100) then
            firstID = CollectibleType.NUM_COLLECTIBLES
        end
        if lastID >= ReactionAPI.MaxCollectibleID then
            lastID = ReactionAPI.MaxCollectibleID
        end

        local subcategoryName = firstID .. "-" .. lastID

        if collectibleID % 100 == 1 or collectibleID == CollectibleType.NUM_COLLECTIBLES then
            ModConfigMenu.AddText(CategoryName, subcategoryName, function() return "Customize settings for Modded items" end)
        end

        if collectible then --Technically not necessary, but just in case
            ModConfigMenu.AddSetting(CategoryName, subcategoryName,
            {
                Type = ModConfigMenu.OptionType.NUMBER,
                CurrentSetting = function()
                    return ReactionAPI.SavedSettings["cModded"][collectible.Name]
                end,
                Minimum = ReactionAPI.QualityStatus.QUALITY_0,
                Maximum = ReactionAPI.Setting.DEFAULT,
                Display = function()
                    local choice = ReactionAPI.MCMStrings[ReactionAPI.SavedSettings["cModded"][collectible.Name]]
                    return collectibleID .. ' ' .. collectible.Name .. ': ' .. choice
                end,
                OnChange = function(currentNum)
                    if currentNum == ReactionAPI.Setting.DEFAULT then
                        ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
                    else
                        ReactionAPI.CollectibleData[collectibleID] = currentNum
                    end
                    ReactionAPI.SavedSettings["cModded"][collectible.Name] = currentNum
                    ReactionAPI.requestedReset = true
                end,
                Info = {collectible.Name .. " (Quality ".. collectible.Quality .. ")"}
            })            
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

    print("InitItemData")
    
    if ModConfigMenu then
        InitSaveData()
        InitItemDataMCM() 
        InitModConfigMenu()
    else
        InitSaveData()
        InitItemData()
    end

    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)       
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, InitModData)