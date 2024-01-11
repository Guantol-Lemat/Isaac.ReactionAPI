local MCM = {}

local function ResetItemQualityToDEFAULT()
    for collectibleID = 1, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible then
            ReactionAPI.CollectibleQuality[collectibleID] = collectible.Quality
            if collectibleID < CollectibleType.NUM_COLLECTIBLES then
                ReactionAPI.UserSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.DEFAULT
            else
                ReactionAPI.UserSettings["cModded"][collectible.Name] = ReactionAPI.Setting.DEFAULT
            end
        end
    end
end

local function SetQuestItemsToIGNORE()
    for collectibleID = 1, ReactionAPI.MaxCollectibleID do
        local collectible = Isaac.GetItemConfig():GetCollectible(collectibleID)
        if collectible and collectible:HasTags(ItemConfig.TAG_QUEST) then
            ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
            if collectibleID < CollectibleType.NUM_COLLECTIBLES then
                ReactionAPI.UserSettings["cVanilla"][collectibleID] = ReactionAPI.Setting.IGNORE
            else
                ReactionAPI.UserSettings["cModded"][collectible.Name] = ReactionAPI.Setting.IGNORE
            end
        end
    end
end

function MCM:InitModConfigMenu()
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

    --General

    ModConfigMenu.AddText(CategoryName, "General", function() return "Customize general settings" end)
    ModConfigMenu.AddSpace(CategoryName, "General")
    --[[
    ModConfigMenu.AddSetting(CategoryName, "General", {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function ()
            return ReactionAPI.UserSettings.cImplementation
        end,
        Minimum = ReactionAPI.CollectibleImplementations.SIMPLE,
        Maximum = ReactionAPI.CollectibleImplementations.SIMPLE,
        Display = function()
            local choice = ReactionAPI.MCMStrings["cImplementation"][ReactionAPI.UserSettings.cImplementation]
            return 'Collectible Implementation: ' .. choice
        end,
        OnChange = function(currentSetting)
            ReactionAPI.UserSettings.cImplementation = currentSetting
        end,
        Info = function () return ReactionAPI.MCMStrings["cImplementationDescription"][ReactionAPI.UserSettings.cImplementation] end
        })
    ModConfigMenu.AddText(CategoryName, "General", function() return "Restart is Required for changes to be applied" end)
--]]
    ModConfigMenu.AddSetting(CategoryName, "General", {
        Type = ModConfigMenu.OptionType.BOOLEAN,
        CurrentSetting = function ()
            return ReactionAPI.UserSettings.cOptimizeIsBlindPedestal
        end,
        Display = function()
            local choice = ReactionAPI.MCMStrings["cOptimizeIsBlindPedestal"][ReactionAPI.UserSettings.cOptimizeIsBlindPedestal]
            return "IsBlind" .. ': ' .. choice
        end,
        OnChange = function(currentSetting)
            ReactionAPI.UserSettings.cOptimizeIsBlindPedestal = currentSetting
        end,
        Info = function () return ReactionAPI.MCMStrings["cOptimizeIsBlindPedestalDescription"][ReactionAPI.UserSettings.cOptimizeIsBlindPedestal] end
    })

    --MODS General

    if TaintedTreasure then
        ModConfigMenu.AddSpace(CategoryName, "General")
        ModConfigMenu.AddText(CategoryName, "General", function() return "Tainted Treasure Rooms" end)

        ModConfigMenu.AddSetting(CategoryName, "General",
        {
                    Type = ModConfigMenu.OptionType.NUMBER,
                    CurrentSetting = function()
                        return ReactionAPI.UserSettings.cEternalBlindOverwrite
                    end,
                    Minimum = ReactionAPI.Setting.DO_NOT,
                    Maximum = ReactionAPI.QualityStatus.QUALITY_4,
                    Display = function()
                        local choice = ReactionAPI.MCMStrings.cEternalBlindOverwrite[ReactionAPI.UserSettings.cEternalBlindOverwrite]
                        return 'Eternal Blind Reaction: ' .. choice
                    end,
                    OnChange = function(currentSetting)
                        ReactionAPI.UserSettings.cEternalBlindOverwrite = currentSetting
                    end,
                    Info = {"If you have the Item \"Eternal Candle\" and stumble upon Curse Of The Blind, then Isaac will act as if there was a Visible Item with the specified Quality"}
        })
    end

    --Buttons

    ModConfigMenu.AddSpace(CategoryName, "General")
    ModConfigMenu.AddSetting(CategoryName, "General",
    {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return 0
        end,
        Minimum = 0,
        Maximum = 0,
        Display = function()
            return 'Set All Items to DEFAULT'
        end,
        OnChange = function(currentSetting)
            ResetItemQualityToDEFAULT()
        end,
        Info = {"Press Any Directional Input to Reset all Item Qualities to DEFAULT"}
    })
    ModConfigMenu.AddSetting(CategoryName, "General",
    {
        Type = ModConfigMenu.OptionType.NUMBER,
        CurrentSetting = function()
            return 0
        end,
        Minimum = 0,
        Maximum = 0,
        Display = function()
            return 'Set All "Quest" Items to IGNORE'
        end,
        OnChange = function(currentSetting)
            SetQuestItemsToIGNORE()
        end,
        Info = {"Press Any Directional Input to set all Items with the \"Quest\" TAG to IGNORE"}
    })

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
                    return ReactionAPI.UserSettings["cVanilla"][collectibleID]
                end,
                Minimum = ReactionAPI.QualityStatus.QUALITY_0,
                Maximum = ReactionAPI.Setting.DEFAULT,
                Display = function()
                    local choice = ReactionAPI.MCMStrings["QualityStatus"][ReactionAPI.UserSettings["cVanilla"][collectibleID]]
                    return collectibleID .. '' .. collectible.Name .. ': ' .. choice
                end,
                OnChange = function(currentSetting)
                    if currentSetting == ReactionAPI.Setting.DEFAULT then
                        ReactionAPI.CollectibleQuality[collectibleID] = collectible.Quality
                    elseif currentSetting == ReactionAPI.Setting.IGNORE then
                        ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                    else
                        ReactionAPI.CollectibleQuality[collectibleID] = currentSetting
                    end
                    ReactionAPI.UserSettings["cVanilla"][collectibleID] = currentSetting
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
                    return ReactionAPI.UserSettings["cModded"][collectible.Name]
                end,
                Minimum = ReactionAPI.QualityStatus.QUALITY_0,
                Maximum = ReactionAPI.Setting.DEFAULT,
                Display = function()
                    local choice = ReactionAPI.MCMStrings["QualityStatus"][ReactionAPI.UserSettings["cModded"][collectible.Name]]
                    return collectibleID .. ' ' .. collectible.Name .. ': ' .. choice
                end,
                OnChange = function(currentSetting)
                    if currentSetting == ReactionAPI.Setting.DEFAULT then
                        ReactionAPI.CollectibleQuality[collectibleID] = collectible.Quality
                    elseif currentSetting == ReactionAPI.Setting.IGNORE then
                        ReactionAPI.CollectibleQuality[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                    else
                        ReactionAPI.CollectibleQuality[collectibleID] = currentSetting
                    end
                    ReactionAPI.UserSettings["cModded"][collectible.Name] = currentSetting
                end,
                Info = {collectible.Name .. " (Quality ".. collectible.Quality .. ")"}
            })            
        end
    end
end

return MCM