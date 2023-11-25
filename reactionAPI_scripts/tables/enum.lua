ReactionAPI.QualityStatus = {
    NO_ITEMS = -2,
    GLITCHED = -1,
    QUALITY_0 = 0,
    QUALITY_1 = 1,
    QUALITY_2 = 2,
    QUALITY_3 = 3,
    QUALITY_4 = 4
}

ReactionAPI.Setting = {
    DO_NOT = ReactionAPI.QualityStatus.QUALITY_0 - 1,
    IGNORE = ReactionAPI.QualityStatus.QUALITY_4 + 1,
    DEFAULT = ReactionAPI.QualityStatus.QUALITY_4 + 2
}

ReactionAPI.QualityPartitions = {
    GLITCHED = 0x01,
    QUALITY_0 = 0x02,
    QUALITY_1 = 0x04,
    QUALITY_2 = 0x08,
    QUALITY_3 = 0x10,
    QUALITY_4 = 0x20
}

ReactionAPI.CollectibleImplementations = {
    SIMPLE = 1,
    SYNERGY_RULES = 2
}

ReactionAPI.OpCodes = {
    NOP = 0,
    SET = 1,
    CLEAR = 2
}

ReactionAPI.Context = {
    Visibility = {
        VISIBLE = false,
        BLIND = true,
        ABSOLUTE = 1
    },
    Filter = {
        NEW = true,
        ALL = false
    }
}

ReactionAPI.MCMStrings = {
    cImplementation = {
        [ReactionAPI.CollectibleImplementations.SIMPLE] = "Simple",
        [ReactionAPI.CollectibleImplementations.SYNERGY_RULES] = "Synergy Rules"
    },
    cOptimizeIsBlindPedestal = {
        [true] = "Performance",
        [false] = "Accuracy"
    },
    cOptimizeIsBlindPedestalDescription = {
        [true] = "[Performance]: Reduce Lag to a Minimum at the cost of inaccuracies in the detection of Blind Items",
        [false] = "[Accuracy]: Correctly Detect whether an Item is Blind or not at the Cost of Frame Drops on Item Generation, Item Pickup and Item Rerolls"
    },
    cImplementationDescription = {
        [ReactionAPI.CollectibleImplementations.SIMPLE] = "Keeps a List of Items present in the current room, and obtains the Best Quality from that",
        [ReactionAPI.CollectibleImplementations.SYNERGY_RULES] = "Like Simple, but Determines Quality based on Synergy Rules \n (This is Done Individually for each Player)"
    },
    cEternalBlindOverwrite = {
        [ReactionAPI.Setting.DO_NOT] = "Don't React",
        [ReactionAPI.QualityStatus.QUALITY_0] = "Quality 0",
        [ReactionAPI.QualityStatus.QUALITY_1] = "Quality 1",
        [ReactionAPI.QualityStatus.QUALITY_2] = "Quality 2",
        [ReactionAPI.QualityStatus.QUALITY_3] = "Quality 3",
        [ReactionAPI.QualityStatus.QUALITY_4] = "Quality 4",
    },
    QualityStatus = {
        [ReactionAPI.QualityStatus.NO_ITEMS] = "No Items",
        [ReactionAPI.QualityStatus.GLITCHED] = "Glitched",
        [ReactionAPI.QualityStatus.QUALITY_0] = "Quality 0",
        [ReactionAPI.QualityStatus.QUALITY_1] = "Quality 1",
        [ReactionAPI.QualityStatus.QUALITY_2] = "Quality 2",
        [ReactionAPI.QualityStatus.QUALITY_3] = "Quality 3",
        [ReactionAPI.QualityStatus.QUALITY_4] = "Quality 4",
        [ReactionAPI.Setting.IGNORE] = "Ignore",
        [ReactionAPI.Setting.DEFAULT] = "Default"
    }
}