local module = {}

local chapter_music = {}
local chapter_music_greed = {}

chapter_music[LevelStage.STAGE1_1] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_BASEMENT,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_CELLAR,
	[StageType.STAGETYPE_AFTERBIRTH] = Music.MUSIC_BURNING_BASEMENT,
	[StageType.STAGETYPE_REPENTANCE] = Music.MUSIC_DOWNPOUR,
	[StageType.STAGETYPE_REPENTANCE_B] = Music.MUSIC_DROSS,
}

chapter_music[LevelStage.STAGE1_2] = chapter_music[LevelStage.STAGE1_1]

chapter_music[LevelStage.STAGE2_1] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_CAVES,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_CATACOMBS,
	[StageType.STAGETYPE_AFTERBIRTH] = Music.MUSIC_FLOODED_CAVES,
	[StageType.STAGETYPE_REPENTANCE] = Music.MUSIC_MINES,
	[StageType.STAGETYPE_REPENTANCE_B] = Music.MUSIC_ASHPIT,
}

chapter_music[LevelStage.STAGE2_2] = chapter_music[LevelStage.STAGE2_1]

chapter_music[LevelStage.STAGE3_1] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_DEPTHS,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_NECROPOLIS,
	[StageType.STAGETYPE_AFTERBIRTH] = Music.MUSIC_DANK_DEPTHS,
	[StageType.STAGETYPE_REPENTANCE] = Music.MUSIC_MAUSOLEUM,
	[StageType.STAGETYPE_REPENTANCE_B] = Music.MUSIC_GEHENNA,
}	

chapter_music[LevelStage.STAGE3_2] = chapter_music[LevelStage.STAGE3_1]

chapter_music[LevelStage.STAGE4_1] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_WOMB_UTERO,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_UTERO,
	[StageType.STAGETYPE_AFTERBIRTH] = Music.MUSIC_SCARRED_WOMB,
	[StageType.STAGETYPE_REPENTANCE] = Music.MUSIC_CORPSE,
	[StageType.STAGETYPE_REPENTANCE_B] = Music.MUSIC_MORTIS,
}

chapter_music[LevelStage.STAGE4_2] = chapter_music[LevelStage.STAGE4_1]

chapter_music[LevelStage.STAGE4_3] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_BLUE_WOMB,
}

chapter_music[LevelStage.STAGE5] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_SHEOL,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_CATHEDRAL,
	[StageType.STAGETYPE_AFTERBIRTH] = Music.MUSIC_DARK_ROOM,
}

chapter_music[LevelStage.STAGE6] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_DARK_ROOM,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_CHEST,
}

chapter_music[LevelStage.STAGE7] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_VOID,
}

chapter_music[LevelStage.STAGE8] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_ISAACS_HOUSE,
	[StageType.STAGETYPE_WOTL] = Music.MUSIC_ISAACS_HOUSE,
}

chapter_music_greed[LevelStage.STAGE1_GREED] = chapter_music[LevelStage.STAGE1_1]
chapter_music_greed[LevelStage.STAGE2_GREED] = chapter_music[LevelStage.STAGE2_1]
chapter_music_greed[LevelStage.STAGE3_GREED] = chapter_music[LevelStage.STAGE3_1]
chapter_music_greed[LevelStage.STAGE4_GREED] = chapter_music[LevelStage.STAGE4_1]
chapter_music_greed[LevelStage.STAGE5_GREED] = chapter_music[LevelStage.STAGE5]

chapter_music_greed[LevelStage.STAGE6_GREED] = {
	[StageType.STAGETYPE_ORIGINAL] = Music.MUSIC_SHOP_ROOM,
}

chapter_music_greed[LevelStage.STAGE7_GREED] = chapter_music_greed[LevelStage.STAGE6_GREED]

local chapter_music_default = chapter_music[LevelStage.STAGE1_1]

local random_music = { --this is for the "DELETE THIS" challenge
	[0] = Music.MUSIC_BASEMENT,
	[1] = Music.MUSIC_CELLAR,
	[2] = Music.MUSIC_BURNING_BASEMENT,
	[3] = Music.MUSIC_DOWNPOUR,
	[4] = Music.MUSIC_DROSS,
	[5] = Music.MUSIC_CAVES,
	[6] = Music.MUSIC_CATACOMBS,
	[7] = Music.MUSIC_FLOODED_CAVES,
	[8] = Music.MUSIC_MINES,
	[9] = Music.MUSIC_ASHPIT,
	[10] = Music.MUSIC_DEPTHS,
	[11] = Music.MUSIC_NECROPOLIS,
	[12] = Music.MUSIC_DANK_DEPTHS,
	[13] = Music.MUSIC_MAUSOLEUM,
	[14] = Music.MUSIC_GEHENNA,
	[15] = Music.MUSIC_WOMB_UTERO,
	[16] = Music.MUSIC_UTERO,
	[17] = Music.MUSIC_SCARRED_WOMB,
	[18] = Music.MUSIC_CORPSE,
	[19] = Music.MUSIC_BLUE_WOMB,
	[20] = Music.MUSIC_SHEOL,
	[21] = Music.MUSIC_CATHEDRAL,
	[22] = Music.MUSIC_DARK_ROOM,
	[23] = Music.MUSIC_CHEST,
	[24] = Music.MUSIC_VOID,
	--Music.MUSIC_MORTIS
}

local special_room_music = {
	[RoomType.ROOM_SECRET] = Music.MUSIC_SECRET_ROOM,
	[RoomType.ROOM_SUPERSECRET] = Music.MUSIC_SECRET_ROOM2,
	[RoomType.ROOM_LIBRARY] = Music.MUSIC_LIBRARY_ROOM,
	[RoomType.ROOM_DEVIL] = Music.MUSIC_DEVIL_ROOM,
	[RoomType.ROOM_ANGEL] = Music.MUSIC_ANGEL_ROOM,
	[RoomType.ROOM_PLANETARIUM] = Music.MUSIC_PLANETARIUM,
	[RoomType.ROOM_ULTRASECRET] = Music.MUSIC_SECRET_ROOM_ALT_ALT,
	[RoomType.ROOM_SECRET_EXIT] = Music.MUSIC_BOSS_OVER
}

local boss_music_default = {
	[StageType.STAGETYPE_ORIGINAL] = {
		[0] = Music.MUSIC_BOSS,
		[1] = Music.MUSIC_BOSS2
	},
	[StageType.STAGETYPE_WOTL] = {
		[0] = Music.MUSIC_BOSS,
		[1] = Music.MUSIC_BOSS2
	},
	[StageType.STAGETYPE_AFTERBIRTH] = {
		[0] = Music.MUSIC_BOSS,
		[1] = Music.MUSIC_BOSS2
	},
	[StageType.STAGETYPE_GREEDMODE] = {
		[0] = Music.MUSIC_BOSS,
		[1] = Music.MUSIC_BOSS2
	},
	[StageType.STAGETYPE_REPENTANCE] = {
		[0] = Music.MUSIC_BOSS3
	},
	[StageType.STAGETYPE_REPENTANCE_B] = {
		[0] = Music.MUSIC_BOSS3
	},
}

local boss_music = {
	[BossType.MOM] = Music.MUSIC_MOM_BOSS,
	[BossType.MOM_MAUSOLEUM] = Music.MUSIC_MOM_BOSS,
	[BossType.MOMS_HEART] = Music.MUSIC_MOMS_HEART_BOSS,
	[BossType.MOMS_HEART_MAUSOLEUM] = Music.MUSIC_MOMS_HEART_BOSS,
	[BossType.IT_LIVES] = Music.MUSIC_MOMS_HEART_BOSS,
	[BossType.SATAN] = Music.MUSIC_SATAN_BOSS,
	[BossType.ISAAC] = Music.MUSIC_ISAAC_BOSS,
	[BossType.THE_LAMB] = Music.MUSIC_DARKROOM_BOSS,
	[BossType.BLUE_BABY] = Music.MUSIC_BLUEBABY_BOSS,
	[BossType.MEGA_SATAN] = Music.MUSIC_SATAN_BOSS,
	[BossType.HUSH] = Music.MUSIC_HUSH_BOSS,
	[BossType.DELIRIUM] = Music.MUSIC_VOID_BOSS,
	[BossType.MOTHER] = Music.MUSIC_MOTHER_BOSS,
	[BossType.DOGMA] = Music.MUSIC_DOGMA_BOSS,
	[BossType.THE_BEAST] = Music.MUSIC_BEAST_BOSS,
	[BossType.ULTRA_GREED] = Music.MUSIC_ULTRAGREED_BOSS,
	[BossType.ULTRA_GREEDIER] = Music.MUSIC_ULTRAGREED_BOSS
}

module.ChapterMusic = chapter_music
module.ChapterMusicGreed = chapter_music_greed
module.ChapterMusicDefault = chapter_music_default
module.RandomMusic = random_music
module.SpecialRoomMusic = special_room_music
module.BossMusicDefault = boss_music_default
module.BossMusic = boss_music

return module