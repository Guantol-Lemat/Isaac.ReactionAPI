ReactionAPI = RegisterMod("ReactionAPI", 1)

ReactionAPI.ModVersion = "1.0.0"

include("reactionAPI_scripts.tables.enum")

include("reactionAPI_scripts.functions.utilities")

ReactionAPI.cImplementation = ReactionAPI.CollectibleImplementations.SIMPLE

include("reactionAPI_scripts.tables.user_data")

include("reactionAPI_scripts.implementation.collectible.simple")

include("reactionAPI_scripts.functions.api")

include("reactionAPI_scripts.compatibility.cursed_collection")

-- include("reactionAPI_scripts.tools.debug")