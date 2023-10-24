local json = require("json")

local function SaveSettings()
    Isaac.DebugString("Attempted Save")
    ReactionAPI:SaveData(json.encode(ReactionAPI.SavedSettings))
end

ReactionAPI:AddCallback(ModCallbacks.MC_PRE_GAME_EXIT, SaveSettings)

-- SavedSettings gets Loaded and Modified in pickup_data.lua