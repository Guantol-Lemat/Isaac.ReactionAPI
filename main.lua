if not REPENTANCE then
    return
end

ReactionAPI = RegisterMod("ReactionAPI", 1)

ReactionAPI.ModVersion = "2.0.0"

include("reactionAPI_scripts.tables.version_history")

include("reactionAPI_scripts.tables.enum")

include("reactionAPI_scripts.functions.utilities")

include("reactionAPI_scripts.tools.glowing_hourglass_manager")

include("reactionAPI_scripts.tables.user_data")

include("reactionAPI_scripts.implementation")

include("reactionAPI_scripts.functions.api")

include("reactionAPI_scripts.compatibility.cursed_collection")

-- include("reactionAPI_scripts.tools.debug")

local LoadedMessage = "ReactionAPI " .. ReactionAPI.ModVersion .. " - Loaded"

Isaac.ConsoleOutput(LoadedMessage .. "\n")
Isaac.DebugString(LoadedMessage)