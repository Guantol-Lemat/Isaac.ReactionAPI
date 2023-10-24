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
    DEFAULT = ReactionAPI.QualityStatus.QUALITY_4 + 1
}

ReactionAPI.QualityPartitions = {
    GLITCHED = 0x01,
    QUALITY_0 = 0x02,
    QUALITY_1 = 0x04,
    QUALITY_2 = 0x08,
    QUALITY_3 = 0x10,
    QUALITY_4 = 0x20
}

ReactionAPI.MCMStrings = {
    [ReactionAPI.QualityStatus.NO_ITEMS] = "No Items",
    [ReactionAPI.QualityStatus.GLITCHED] = "Glitched",
    [ReactionAPI.QualityStatus.QUALITY_0] = "Quality 0",
    [ReactionAPI.QualityStatus.QUALITY_1] = "Quality 1",
    [ReactionAPI.QualityStatus.QUALITY_2] = "Quality 2",
    [ReactionAPI.QualityStatus.QUALITY_3] = "Quality 3",
    [ReactionAPI.QualityStatus.QUALITY_4] = "Quality 4",
    [ReactionAPI.Setting.DEFAULT] = "Default"
}