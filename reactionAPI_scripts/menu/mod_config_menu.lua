local MCM = {}

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
    ModConfigMenu.AddText(CategoryName, "Info", function() return "Visit the Documentation Page" end)
    ModConfigMenu.AddText(CategoryName, "Info", function() return "for more info on each Implementation" end)

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
                        ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
                    elseif currentSetting == ReactionAPI.Setting.IGNORE then
                        ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                    else
                        ReactionAPI.CollectibleData[collectibleID] = currentSetting
                    end
                    ReactionAPI.UserSettings["cVanilla"][collectibleID] = currentSetting
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
                        ReactionAPI.CollectibleData[collectibleID] = collectible.Quality
                    elseif currentSetting == ReactionAPI.Setting.IGNORE then
                        ReactionAPI.CollectibleData[collectibleID] = ReactionAPI.QualityStatus.NO_ITEMS
                    else
                        ReactionAPI.CollectibleData[collectibleID] = currentSetting
                    end
                    ReactionAPI.UserSettings["cModded"][collectible.Name] = currentSetting
                    ReactionAPI.requestedReset = true
                end,
                Info = {collectible.Name .. " (Quality ".. collectible.Quality .. ")"}
            })            
        end
    end
end

return MCM