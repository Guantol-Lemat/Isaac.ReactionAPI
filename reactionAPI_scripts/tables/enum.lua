if not REPENTOGON then
    SlotVariant = SlotVariant or {}
    SlotVariant.HOME_CLOSET_PLAYER = 14
end

Music.SILENCE = Music.SILENCE or Isaac.GetMusicIdByName("ReactionAPISilence")

GridRooms.ROOM_MOMS_HEART_MAUSOLEUM_IDX = -10
GridRooms.ROOM_THE_BEAST_IDX = -10


if not REPENTOGON then
	BossType = BossType or {}
	BossType.MOM = 6
    BossType.MOM_MAUSOLEUM = 89
	BossType.MOMS_HEART = 8
    BossType.MOMS_HEART_MAUSOLEUM = 90
    BossType.IT_LIVES = 25
    BossType.SATAN = 24
    BossType.ISAAC = 39
    BossType.THE_LAMB = 54
    BossType.BLUE_BABY = 40
    BossType.MEGA_SATAN = 55
    BossType.HUSH = 63
    BossType.DELIRIUM = 70
    BossType.MOTHER = 88
    BossType.DOGMA = 99
    BossType.THE_BEAST = 100
    BossType.ULTRA_GREED = 62
    BossType.ULTRA_GREEDIER = 71
end

ReactionAPI.QualityStatus = {
    NO_ITEMS = -2,
    GLITCHED = -1,
    QUALITY_0 = 0,
    QUALITY_1 = 1,
    QUALITY_2 = 2,
    QUALITY_3 = 3,
    QUALITY_4 = 4
}

ReactionAPI.QualityPartitions = {
    GLITCHED = 0x01,
    QUALITY_0 = 0x02,
    QUALITY_1 = 0x04,
    QUALITY_2 = 0x08,
    QUALITY_3 = 0x10,
    QUALITY_4 = 0x20
}

ReactionAPI.SlotType = {
    CRANE_GAME = 1,
    ALL = 2
}

ReactionAPI.Setting = {
    DO_NOT = ReactionAPI.QualityStatus.QUALITY_0 - 1,
    IGNORE = ReactionAPI.QualityStatus.QUALITY_4 + 1,
    DEFAULT = ReactionAPI.QualityStatus.QUALITY_4 + 2
}

ReactionAPI.OpCodes = {
    NOP = 0,
    SET = 1,
    CLEAR = 2
}

ReactionAPI.Visibility = {
    VISIBLE = false,
    BLIND = true,
    ABSOLUTE = 1
}

ReactionAPI.Filter = {
    NEW = true,
    ALL = false
}

ReactionAPI.Reset = {
    GLOBAL = true,
    LOCAL = false
}

ReactionAPI.Music = {
    Scenario = {
        SILENCE = 0,
        NO_UNTRACKED_CASES = 1
    }
}

ReactionAPI.MCMStrings = {
    cOptimizeIsBlindPedestal = {
        [true] = "Performance",
        [false] = "Accuracy"
    },
    cOptimizeIsBlindPedestalDescription = {
        [true] = "[Performance]: Reduce Lag to a Minimum at the cost of inaccuracies in the detection of Blind Items",
        [false] = "[Accuracy]: Correctly Detect whether an Item is Blind or not at the Cost of Frame Drops on Item Generation, Item Pickup and Item Rerolls"
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