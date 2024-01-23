local font = Font()
font:Load("font/luaminioutlined.fnt")
local screenSize
local screenCenter
local renderedLines = 4
local TEXT_X_DEFAULT = 260
local TEXT_Y_DEFAULT = 292
local TEXT_X = TEXT_X_DEFAULT
local TEXT_Y = TEXT_Y_DEFAULT
local LINE_HEIGHT = font:GetLineHeight()
local TEXT_COLOR = KColor(1, 1, 1, 1)

local postRenderCalls = 0
local dataFetched = false
local lineOffset = 10

local cBestVisibleQuality
local cBestBlindQuality
local cQualityStatus
local collectiblesInRoom
local newCollectibles
local blindPedestals
local shopItems

local craneBestQuality
local craneQualityStatus

local flipBestQuality
local flipQualityStatus

local visible = ReactionAPI.Visibility.VISIBLE
local blind = ReactionAPI.Visibility.BLIND
local absolute = ReactionAPI.Visibility.ABSOLUTE
local newOnly = ReactionAPI.Filter.NEW
local all = ReactionAPI.Filter.ALL

local debugLines = {
    [ReactionAPI.QualityStatus.NO_ITEMS] = "NO_ITEMS",
    [ReactionAPI.QualityStatus.GLITCHED] = "GLITCHED",
    [ReactionAPI.QualityStatus.QUALITY_0] = "QUALITY_0",
    [ReactionAPI.QualityStatus.QUALITY_1] = "QUALITY_1",
    [ReactionAPI.QualityStatus.QUALITY_2] = "QUALITY_2",
    [ReactionAPI.QualityStatus.QUALITY_3] = "QUALITY_3",
    [ReactionAPI.QualityStatus.QUALITY_4] = "QUALITY_4"
}

local DebugCommand = {
    Rich = function ()
        Isaac.DebugString("You are now rich")
        Isaac.ExecuteCommand('giveitem c416')
        for i = 1, 10 do
        Isaac.ExecuteCommand('giveitem c18')
        end
    end,
    cSpawn = function ()
        Isaac.DebugString("Pickup Spawned")
        Isaac.ExecuteCommand('spawn 5.100.1')
    end,
    cSpawnRand = function ()
        Isaac.DebugString("Pickup Spawned")
        Isaac.ExecuteCommand('spawn 5.100')
    end,
    Restock = function ()
        Isaac.DebugString("Restocked")
        Isaac.ExecuteCommand('restock')
    end,
    ToggleBlind = function ()
        if Game():GetLevel():GetCurses() & LevelCurse.CURSE_OF_BLIND == 0 then
            Game():GetLevel():AddCurse(LevelCurse.CURSE_OF_BLIND, false)
        else
            Game():GetLevel():RemoveCurses(LevelCurse.CURSE_OF_BLIND)
        end
    end
}

local Keybinds = {
    [Keyboard.KEY_F3] = DebugCommand.cSpawnRand,
    [Keyboard.KEY_F4] = DebugCommand.cSpawn,
    [Keyboard.KEY_F5] = DebugCommand.Rich,
    [Keyboard.KEY_F6] = DebugCommand.Restock,
    [Keyboard.KEY_F7] = DebugCommand.ToggleBlind
}

local function FetchData()
    local collectibleData = ReactionAPI.GetCollectibleData()

    cBestVisibleQuality = collectibleData.BestQuality[ReactionAPI.Visibility.VISIBLE]
    cBestBlindQuality = collectibleData.BestQuality[ReactionAPI.Visibility.BLIND]
    cQualityStatus = collectibleData.QualityStatus
    collectiblesInRoom = collectibleData.InRoom
    newCollectibles = collectibleData.New
    blindPedestals = collectibleData.Blind
    shopItems = collectibleData.Shop

    local craneData = ReactionAPI.GetSlotData(ReactionAPI.SlotType.CRANE_GAME)
    craneBestQuality = craneData.BestQuality
    craneQualityStatus = craneData.QualityStatus

    local flipData = ReactionAPI.GetFlipData()
    flipBestQuality = flipData.BestQuality
    flipQualityStatus = flipData.QualityStatus

    dataFetched = true
end

local function getScreenSize()
    if REPENTANCE then
        return Vector(Isaac.GetScreenWidth(), Isaac.GetScreenHeight())
    end

    -- ab+ / based off of code from kilburn
    local room = Game():GetRoom()
    local pos = room:WorldToScreenPosition(Vector(0,0)) - room:GetRenderScrollOffset() - Game().ScreenShakeOffset

    local rx = pos.X + 60 * 26 / 40
    local ry = pos.Y + 140 * (26 / 40)

    return Vector(rx * 2 + 13 * 26, ry * 2 + 7 * 26)
end

local function IncreaseLine()
    TEXT_Y = TEXT_Y + lineOffset
    renderedLines = renderedLines + 1
end

local function ResetPrintedTextPosition()
    local renderAtBottom = true
    local yOffset = 0 -- from top or bottom

    screenSize = getScreenSize()
    screenCenter = (screenSize.X / 2)
    TEXT_Y = renderAtBottom and screenSize.Y - (10 * renderedLines) - yOffset or yOffset
end

local function PrintBestQuality()
    local visibleCollectibleQualityString = "Visible Collectible Quality:" .. debugLines[cBestVisibleQuality]
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(visibleCollectibleQualityString) / 2)
    font:DrawString(visibleCollectibleQualityString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()

    local blindCollectibleQualityString = "Blind Collectible Quality:" .. debugLines[cBestBlindQuality]
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(blindCollectibleQualityString) / 2)
    font:DrawString(blindCollectibleQualityString, TEXT_X, TEXT_Y - LINE_HEIGHT , TEXT_COLOR)

    IncreaseLine()
end

local function PrintQualityStatus()
    local qualityPresenceString = "CollectiblePresence: 0x"
    for i = 0, 5 do
        if cQualityStatus[visible][all] & (1 << i) ~= 0 then
            qualityPresenceString = qualityPresenceString .. "1"
        else
            qualityPresenceString = qualityPresenceString .. "0"
        end
    end
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(qualityPresenceString) / 2)
    font:DrawString(qualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()

    local blindQualityPresenceString = "BlindCollectiblePresence: 0x"
    for i = 0, 5 do
        if cQualityStatus[blind][all] & (1 << i) ~= 0 then
            blindQualityPresenceString = blindQualityPresenceString .. "1"
        else
            blindQualityPresenceString = blindQualityPresenceString .. "0"
        end
    end
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(blindQualityPresenceString) / 2)
    font:DrawString(blindQualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()

    local absoluteQualityPresenceString = "AbsoluteCollectiblePresence: 0x"
    for i = 0, 5 do
        if cQualityStatus[absolute][all] & (1 << i) ~= 0 then
            absoluteQualityPresenceString = absoluteQualityPresenceString .. "1"
        else
            absoluteQualityPresenceString = absoluteQualityPresenceString .. "0"
        end
    end
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(absoluteQualityPresenceString) / 2)
    font:DrawString(absoluteQualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()
end

local function PrintCraneQualityStatus()
    local qualityPresenceString = "CranePresence: 0x"
    for i = 0, 5 do
        if craneQualityStatus[all] & (1 << i) ~= 0 then
            qualityPresenceString = qualityPresenceString .. "1"
        else
            qualityPresenceString = qualityPresenceString .. "0"
        end
    end
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(qualityPresenceString) / 2)
    font:DrawString(qualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()
end

local function PrintFlipQualityStatus()
    local qualityPresenceString = "FlipPresence: 0x"
    for i = 0, 5 do
        if flipQualityStatus[all] & (1 << i) ~= 0 then
            qualityPresenceString = qualityPresenceString .. "1"
        else
            qualityPresenceString = qualityPresenceString .. "0"
        end
    end
    TEXT_X = (screenCenter) - (font:GetStringWidthUTF8(qualityPresenceString) / 2)
    font:DrawString(qualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)

    IncreaseLine()
end

local function DebugPrintPresenceList()
    Isaac.DebugString("Presence List:")
    for pickupID, _ in pairs(collectiblesInRoom) do
        for collectibleID, cycleOrder in pairs(collectiblesInRoom[pickupID]) do
            Isaac.DebugString("PickupID: " .. pickupID .. ", CollectibleID: " .. collectibleID .. ", IsBlind:" .. tostring(blindPedestals[pickupID] ~= nil) .. ", Cycle Order: " .. cycleOrder  .. ", CollectibleName: " .. Isaac.GetItemConfig():GetCollectible(collectibleID).Name)
        end
    end
end

local function DebugPrintNewCollectibles()
    Isaac.DebugString("New Collectibles:")
    for collectibleID, _ in pairs(newCollectibles[visible]) do
        Isaac.DebugString("CollectibleID: " .. collectibleID .. ", IsBlind:" .. tostring(false) .. ", CollectibleName: " .. Isaac.GetItemConfig():GetCollectible(collectibleID).Name)
    end
    for collectibleID, _ in pairs(newCollectibles[blind]) do
        Isaac.DebugString("CollectibleID: " .. collectibleID .. ", IsBlind:" .. tostring(true) .. ", CollectibleName: " .. Isaac.GetItemConfig():GetCollectible(collectibleID).Name)
    end
end

local function DebugPrintBlindPedestals()
    Isaac.DebugString("Blind Pedestals:")
    for pickupID, _ in pairs(blindPedestals) do
        Isaac.DebugString("PickupID: " .. pickupID)
    end
end

local function DebugPrintShopItems()
    Isaac.DebugString("Shop Items:")
    for pickupID, _ in pairs(shopItems) do
        Isaac.DebugString("PickupID: " .. pickupID)
    end
end

local function NewCollectiblesSpawned()
    return (ReactionAPI.Utilities.GetTableLength(newCollectibles[visible]) > 0 or ReactionAPI.Utilities.GetTableLength(newCollectibles[blind]) > 0) and postRenderCalls % 2 == 0 -- Print only once every Update
end

local function DebugText()
    ResetPrintedTextPosition()
    postRenderCalls = postRenderCalls >= 1 and 0 or postRenderCalls + 1
    if dataFetched then --To avoid Errors on Startup
        -- PrintBestQuality()
        PrintQualityStatus()
        PrintCraneQualityStatus()
        PrintFlipQualityStatus()
        renderedLines = 4
        if NewCollectiblesSpawned() then
            DebugPrintPresenceList()
            DebugPrintNewCollectibles()
            DebugPrintBlindPedestals()
            DebugPrintShopItems()
        end
    end
end

DebugCommand.PrintDebugData = function ()
    if dataFetched then
        DebugPrintPresenceList()
        DebugPrintNewCollectibles()
        DebugPrintBlindPedestals()
        DebugPrintShopItems()
    end
end

Keybinds[Keyboard.KEY_O] = DebugCommand.PrintDebugData

local function ResetOnExit()
    cBestVisibleQuality, cBestBlindQuality, cQualityStatus,collectiblesInRoom, newCollectibles, blindPedestals, shopItems = nil
    dataFetched = false
end

local function KeybindManager()
    for key, command in pairs(Keybinds) do
        if Input.IsButtonTriggered(key, 0) then
            command()
        end
    end
end

local function onExecuteCmd(cmd, parameters)
    if cmd == 'maxID' then
        Isaac.ConsoleOutput(ReactionAPI.MaxCollectibleID)
    elseif cmd == 'CollectibleData' then
        Isaac.ConsoleOutput(ReactionAPI.CollectibleQuality[tonumber(parameters)])
    end
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_UPDATE, FetchData)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_RENDER, DebugText)

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, ResetOnExit)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_RENDER, KeybindManager)

ReactionAPI:AddCallback(ModCallbacks.MC_EXECUTE_CMD, onExecuteCmd)

local firstInitEpiphany = true

local function DebugEpiphany()
    if firstInitEpiphany and Epiphany then
        local turnoverID = Isaac.GetItemIdByName('Turnover')
        local debugString = "giveitem c" .. turnoverID

        DebugCommand.GiveTurnover = function ()
            Isaac.ExecuteCommand(debugString)
        end
        Keybinds[Keyboard.KEY_F9] = DebugCommand.GiveTurnover
    end
    firstInitEpiphany = false
    -- ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugEpiphany)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugEpiphany)

local firstInitCursed = true

local function DebugCursedCollection()
    if firstInitCursed and CURCOL then
        local curseOfTheBlight = Isaac.GetCurseIdByName("Curse of Blight")
        local BLIGHT_FLAG = 1 << (curseOfTheBlight - 1)

        DebugCommand.ToggleBlight = function ()
            if Game():GetLevel():GetCurses() & BLIGHT_FLAG == 0 then
                Game():GetLevel():AddCurse(BLIGHT_FLAG, false)
            else
                Game():GetLevel():RemoveCurses(BLIGHT_FLAG)
            end
        end

        Keybinds[Keyboard.KEY_F8] = DebugCommand.ToggleBlight
    end
    firstInitCursed = false
    -- ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugCursedCollection)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugCursedCollection)