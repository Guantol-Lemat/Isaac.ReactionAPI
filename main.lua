ReactionAPI = RegisterMod("ReactionAPI", 1)

ReactionAPI.ModVersion = "1.0.0"

include("reactionAPI_scripts.tables.enum")

ReactionAPI.cImplementation = ReactionAPI.CollectibleImplementations.SIMPLE

include("reactionAPI_scripts.tables.user_data")

include("reactionAPI_scripts.implementation.collectible.simple")

--[[
if ReactionAPI.cImplementation == ReactionAPI.CollectibleImplementations.SIMPLE then
    include("reactionAPI_scripts.implementation.collectible.simple")
elseif ReactionAPI.cImplementation == ReactionAPI.CollectibleImplementations.PRESENCE_LIST then
    include("reactionAPI_scripts.implementation.collectible.presence_list")
end

]]

-- include("reactionAPI_scripts.compatibility.epiphany")

include("reactionAPI_scripts.compatibility.cursed_collection")

include("reactionAPI_scripts.compatibility.tainted_treasure")

include("reactionAPI_scripts.tools.debug")