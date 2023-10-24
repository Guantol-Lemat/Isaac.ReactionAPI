local font = Font()
font:Load("font/luaminioutlined.fnt")
local TEXT_X = 260
local TEXT_Y = 292
local LINE_HEIGHT = font:GetLineHeight()
local TEXT_COLOR = KColor(1, 1, 1, 1)

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
    Restock = function ()
        Isaac.DebugString("Restocked")
        Isaac.ExecuteCommand('restock')        
    end,
    EnableBlind = function ()
        Game():GetLevel():AddCurse(LevelCurse.CURSE_OF_BLIND, false)
    end,
    DisableBlind = function ()
        Game():GetLevel():RemoveCurses(LevelCurse.CURSE_OF_BLIND)
    end
}

local Keybinds = {
    [Keyboard.KEY_F3] = DebugCommand.Rich,
    [Keyboard.KEY_F4] = DebugCommand.cSpawn,
    [Keyboard.KEY_F5] = DebugCommand.Restock,
    [Keyboard.KEY_F6] = DebugCommand.EnableBlind,
    [Keyboard.KEY_F7] = DebugCommand.DisableBlind
}

local function DebugText()
    font:DrawString("Collectible Quality:" .. debugLines[ReactionAPI.bestCollectibleQuality], TEXT_X, TEXT_Y - LINE_HEIGHT, TEXT_COLOR)
    font:DrawString("Blind Collectible Quality:" .. debugLines[ReactionAPI.bestCollectibleQualityBlind], TEXT_X, TEXT_Y - LINE_HEIGHT + 10 , TEXT_COLOR)
    local qualityPresenceString = "CollectiblePresence: 0x"
    for i = 0, 5 do
        if (ReactionAPI.cQualityPresence & (1 << i)) ~= 0 then
            qualityPresenceString = qualityPresenceString .. "1"
        else
            qualityPresenceString = qualityPresenceString .. "0"
        end
    end
    font:DrawString(qualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT + 20 , TEXT_COLOR)
    local blindQualityPresenceString = "BlindCollectiblePresence: 0x"
    for i = 0, 5 do
        if (ReactionAPI.cBlindQualityPresence & (1 << i)) ~= 0 then
            blindQualityPresenceString = blindQualityPresenceString .. "1"
        else
            blindQualityPresenceString = blindQualityPresenceString .. "0"
        end
    end
    font:DrawString(blindQualityPresenceString, TEXT_X, TEXT_Y - LINE_HEIGHT + 30 , TEXT_COLOR)
end

local function DebugCursedCollection()
    if CURCOL then
        local curseOfTheBlight = Isaac.GetCurseIdByName("Curse of Blight")
        local BLIGHT_FLAG = 1 << (curseOfTheBlight - 1)

        DebugCommand.EnableBlight = function ()
            Game():GetLevel():AddCurse(BLIGHT_FLAG, false)
        end
    
        DebugCommand.DisableBlight = function ()
            Game():GetLevel():RemoveCurses(BLIGHT_FLAG)
        end

        Keybinds[Keyboard.KEY_F8] = DebugCommand.EnableBlight
        Keybinds[Keyboard.KEY_F9] = DebugCommand.DisableBlight
    end

    ReactionAPI:RemoveCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugCursedCollection)
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, DebugCursedCollection)

local function KeybindManager()
    for key, command in pairs(Keybinds) do
        if Input.IsButtonTriggered(key, 0) then
            command()
        end
    end
end

local function onExecuteCmd(cmd, parameters)
    if cmd == 'maxID' then
        print(ReactionAPI.MaxCollectibleID)
    elseif cmd == 'CollectibleData' then
        print(ReactionAPI.CollectibleData[tonumber(parameters)])
    end
end

ReactionAPI:AddCallback(ModCallbacks.MC_POST_RENDER, DebugText)

ReactionAPI:AddCallback(ModCallbacks.MC_POST_RENDER, KeybindManager)

ReactionAPI:AddCallback(ModCallbacks.MC_EXECUTE_CMD, onExecuteCmd)