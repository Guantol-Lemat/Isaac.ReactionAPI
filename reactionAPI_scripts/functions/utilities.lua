local log = require("reactionAPI_scripts.tools.log")
local music = require("reactionAPI_scripts.tables.music")

local game = Game()

ReactionAPI.Utilities = {}

local function DeepCopy(Table)
    if type(Table) ~= "table" then
        return Table
    end

    local final = setmetatable({}, getmetatable(Table))
    for i, v in pairs(Table) do
        final[DeepCopy(i)] = DeepCopy(v)
    end

    return final
end

ReactionAPI.Utilities.DeepCopy = DeepCopy

local function LeftDeepMerge(Table1, Table2)
    Table1 = DeepCopy(Table1)

    setmetatable(Table1, getmetatable(Table1))

    for key, value in pairs(Table2) do
        if type(value) == "table" and type(Table1[key]) == "table" then
            Table1[key] = LeftDeepMerge(Table1[key], value)
        else
            if Table1[key] == nil then
                Table1[key] = value
            end
        end
    end

    return Table1
end

ReactionAPI.Utilities.LeftDeepMerge = LeftDeepMerge

local function RightDeepMerge(Table1, Table2)
    Table1 = DeepCopy(Table1)

    setmetatable(Table1, getmetatable(Table2))

    for key, value in pairs(Table2) do
        if type(value) == "table" and type(Table1[key]) == "table" then
            Table1[key] = RightDeepMerge(Table1[key], value)
        else
            Table1[key] = value
        end
    end

    return Table1
end

ReactionAPI.Utilities.RightDeepMerge = RightDeepMerge

ReactionAPI.Utilities.GetTableLength = function(Table)
    local length = 0
    for _, _ in pairs(Table) do
        length = length + 1
    end
    return length
end

if REPENTOGON then
    ReactionAPI.Utilities.AnyPlayerHasCollectible = function(CollectibleID, IgnoreModifiers)
        PlayerManager.AnyoneHasCollectible(CollectibleID)
    end
else
    ReactionAPI.Utilities.AnyPlayerHasCollectible = function(CollectibleID, IgnoreModifiers)
        for playerNum = 0, game:GetNumPlayers() do
            if game:GetPlayer(playerNum):HasCollectible(CollectibleID, IgnoreModifiers) then
                return true
            end
        end
        return false
    end
end

if REPENTOGON then
    ReactionAPI.Utilities.AnyPlayerHasTrinket = function(TrinketID, IgnoreModifiers)
        PlayerManager.AnyoneHasTrinket(TrinketID)
    end
else
    ReactionAPI.Utilities.AnyPlayerHasTrinket = function(TrinketID, IgnoreModifiers)
        for playerNum = 0, game:GetNumPlayers() do
            if game:GetPlayer(playerNum):HasTrinket(TrinketID, IgnoreModifiers) then
                return true
            end
        end
        return false
    end
end

if REPENTOGON then
    ReactionAPI.Utilities.GetDimension = function()
        return game:GetLevel():GetDimension()
    end
else
    ReactionAPI.Utilities.GetDimension = function()
        local level = game:GetLevel()
        local roomIndex = level:GetCurrentRoomIndex()

        for i = 0, 2 do
            if GetPtrHash(level:GetRoomByIdx(roomIndex, i)) == GetPtrHash(level:GetRoomByIdx(roomIndex, -1)) then
                return i
            end
        end

        return nil
    end
end

local function GetBossMusic(room, stageType, BossID)
    if BossID == BossType.ULTRA_GREED then
        if room:IsClear() then
            return Music.MUSIC_BOSS_OVER
        end
        return Music.MUSIC_ULTRAGREED_BOSS
    end

    if BossID == BossType.HUSH then
        if room:IsClear() then
            return Music.MUSIC_BOSS_OVER
        end
        if #Isaac.FindByType(EntityType.ENTITY_HUSH) > 0 then
            return Music.MUSIC_HUSH_BOSS
        end
        return Music.MUSIC_BLUEBABY_BOSS
    end

    if room:GetAliveBossesCount() > 0 then
        local specificBossMusic = music.BossMusic[BossID]
        if specificBossMusic then
            return specificBossMusic
        end
        local defaultBossMusic = music.BossMusicDefault[stageType]
        return defaultBossMusic[room:GetDecorationSeed() % (#defaultBossMusic + 1)]
    end

    return Music.MUSIC_BOSS_OVER
end

local function GetStageMusic(stage, stageType)

    if Isaac.GetChallenge() == Challenge.CHALLENGE_DELETE_THIS then
		local seeds = game:GetSeeds()
		local stageSeed = seeds:GetStageSeed(stage)
		return music.RandomMusic[stageSeed % (#music.RandomMusic + 1)]
	end

    local chapter_music_table = game:IsGreedMode() and music.ChapterMusicGreed or music.ChapterMusic
    local chapter_music = chapter_music_table[stage] or music.ChapterMusicDefault
    return chapter_music[stageType] or chapter_music[StageType.STAGETYPE_ORIGINAL] or Music.MUSIC_TITLE_REPENTANCE
end

ReactionAPI.Utilities.GetCurrentRoomMusic = function(UntrackedCasesOnly)
	local level = game:GetLevel()
	local stage = level:GetStage()
	local stageType = level:GetStageType()
    local room = game:GetRoom()
    local roomDesc = level:GetCurrentRoomDesc()
    local roomType = room:GetType()
    local isRepStage = stageType == StageType.STAGETYPE_REPENTANCE or stageType == StageType.STAGETYPE_REPENTANCE_B
    local isCurseOfLabyrinth = (level:GetCurses() & LevelCurse.CURSE_OF_LABYRINTH) == LevelCurse.CURSE_OF_LABYRINTH

    if room:IsAmbushActive() then
        if roomType == RoomType.ROOM_BOSSRUSH then
            return {
                CurrentTrack = Music.MUSIC_BOSS_RUSH
            }
        elseif roomType == RoomType.ROOM_CHALLENGE then
            return {
                CurrentTrack = Music.MUSIC_CHALLENGE_FIGHT
            }
        end
    end

    if room:IsAmbushDone() then
        return {
            CurrentTrack = Music.MUSIC_BOSS_OVER
        }
    end

    if UntrackedCasesOnly then
        if room:GetBossID() == BossType.HUSH then
            if #Isaac.FindByType(EntityType.ENTITY_HUSH) > 0 then
                return {
                    CurrentTrack = Music.MUSIC_HUSH_BOSS
                }
            end
        end

        if roomType == RoomType.ROOM_TREASURE and room:IsFirstVisit() then
            return {
                CurrentTrack = GetStageMusic(stage, stageType)
            }
        end
        return {
            SpecialScenario = ReactionAPI.Music.Scenario.NO_UNTRACKED_CASES,
            CurrentTrack = GetStageMusic(stage, stageType)
        }
    end

    if roomDesc.SurpriseMiniboss then
        if room:IsClear() then
			return Music.MUSIC_BOSS_OVER
        end
		return Music.MUSIC_CHALLENGE_FIGHT
    end

    if ReactionAPI.Utilities.GetDimension() == 2 then
        return {
            CurrentTrack = Music.MUSIC_DARK_CLOSET
        }
    end

    if level:IsAscent() then
        return {
            CurrentTrack = Music.MUSIC_REVERSE_GENESIS
        }
    end

    if ReactionAPI.Utilities.GetDimension() == 1 and room:IsMirrorWorld() then
        if stageType == StageType.STAGETYPE_REPENTANCE then
            return {
                CurrentTrack = Music.MUSIC_DOWNPOUR_REVERSE
            }
        elseif stageType == StageType.STAGETYPE_REPENTANCE_B then
            return {
                CurrentTrack = Music.MUSIC_DROSS_REVERSE
            }
        end
    end

    if ReactionAPI.Utilities.GetDimension() == 1 and room:HasCurseMist() then
        for _, mothersShadowEntity in ipairs(Isaac.FindByType(EntityType.ENTITY_MOTHERS_SHADOW)) do
            local sprite = mothersShadowEntity:GetSprite()
            if not sprite:IsPlaying() then
                if #Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, CollectibleType.COLLECTIBLE_KNIFE_PIECE_2) > 0 then
                    return {
                        CurrentTrack = Music.MUSIC_MINESHAFT_AMBIENT
                    }
                end
                return {
                    CurrentTrack = Music.MUSIC_MOTHERS_SHADOW_INTRO,
                    Queue = {Music.MUSIC_MINESHAFT_ESCAPE}
                }
            elseif sprite:IsPlaying("Appear") then
                return {
                    CurrentTrack = Music.MUSIC_MOTHERS_SHADOW_INTRO,
                    Queue = {Music.MUSIC_MINESHAFT_ESCAPE}
                }
            end
            return {
                CurrentTrack = Music.MUSIC_MINESHAFT_ESCAPE
            }
        end
        return {
            CurrentTrack = Music.MUSIC_MINESHAFT_AMBIENT
        }
    end

    if (stage == LevelStage.STAGE3_2 or (stage == LevelStage.STAGE3_1 and isCurseOfLabyrinth)) and isRepStage then
        if game:GetStateFlag(GameStateFlag.STATE_MAUSOLEUM_HEART_KILLED) then
            if room:GetBossID() == BossType.MOMS_HEART then
                return {
                    SpecialScenario = ReactionAPI.Music.Scenario.SILENCE,
                    CurrentTrack = Music.SILENCE
                }
            end
            return {
                CurrentTrack = Music.MUSIC_BOSS_OVER_TWISTED
            }
        end
    end

    if room:GetBossID() > 0 then
        return {
            CurrentTrack = GetBossMusic(room, stageType, room:GetBossID())
        }
    end

    if stage == LevelStage.STAGE8 then -- Dogma and Beast Rooms return a BossID of 0
        if roomDesc.Data.Variant == 1000 then -- Dogma Room
            if not room:IsClear() then
                return {
                    CurrentTrack = music.BossMusic[BossType.DOGMA]
                }
            end
        end
        if roomDesc.Data.Variant == 666 then -- Beast Room
            return {
                CurrentTrack = music.BossMusic[BossType.THE_BEAST]
            }
        end
    end

    if roomType == RoomType.ROOM_SHOP then
		if (game:IsGreedMode() or stage ~= LevelStage.STAGE4_3) then
			return {
                CurrentTrack = Music.MUSIC_SHOP_ROOM
            }
		else
			return {
                CurrentTrack = GetStageMusic(stage, stageType)
            }
		end
    end

    if roomType == RoomType.ROOM_BOSS then
        if room:IsClear() then
            return {
                CurrentTrack = Music.MUSIC_BOSS_OVER
            }
        end
        local defaultBossMusic = music.BossMusicDefault[stageType]
        return {
            CurrentTrack = defaultBossMusic[room:GetDecorationSeed() % (#defaultBossMusic + 1)]
        }
    end

    if roomType == RoomType.ROOM_MINIBOSS then
        if room:IsClear() then
            return {
                CurrentTrack = Music.MUSIC_BOSS_OVER
            }
        end
        return {
            CurrentTrack = Music.MUSIC_CHALLENGE_FIGHT
        }
    end

    local specialRoomMusic = music.SpecialRoomMusic[roomType]
    if specialRoomMusic then
        return  {
            CurrentTrack = specialRoomMusic
        }
    end

    return {
        CurrentTrack = GetStageMusic(stage, stageType)
    }
end

ReactionAPI.Utilities.GetSoundtrackMenuMusic = function()
    if MMC and MMC.Initialised then
        local stageTrack = ReactionAPI.Utilities.GetCurrentRoomMusic()
        if stageTrack.SpecialScenario == ReactionAPI.Music.Scenario.SILENCE then
            return stageTrack
        end
        if SoundtrackSongList then
            local soundtrackMenuMusic = {}
            stageTrack.CurrentTrack = finddefaultsongindexbyID(MMC.GetCorrectedTrackNum(stageTrack.CurrentTrack))
            soundtrackMenuMusic.CurrentTrack = findsongbydefaultIndex(stageTrack.CurrentTrack, false, false)
            if stageTrack.Queue then
                soundtrackMenuMusic.Queue = {}
                for queueOrder, track in ipairs(stageTrack.Queue) do
                    track = finddefaultsongindexbyID(MMC.GetCorrectedTrackNum(track))
                    soundtrackMenuMusic.Queue[queueOrder] = findsongbydefaultIndex(track, false, false)
                end
            end
            return soundtrackMenuMusic
        end
    end
    return {
        CurrentTrack = Music.MUSIC_NULL
    }
end

ReactionAPI.Utilities.GetMaxCollectibleID = function ()
    return ReactionAPI.MaxCollectibleID or nil
end

ReactionAPI.Utilities.CanBlindCollectiblesSpawnInTreasureRoom = function()
    return game:GetLevel():GetStageType() >= StageType.STAGETYPE_REPENTANCE or ReactionAPI.Utilities.AnyPlayerHasTrinket(TrinketType.TRINKET_BROKEN_GLASSES, false)
end

ReactionAPI.Utilities.CheckForPresence = function(PresencePartition, TargetPartition, AllPresent)
    if PresencePartition < 0x00 then
        log.error("An invalid PresencePartition was passed", "CheckForPresence")
        return
    end
    if TargetPartition < 0x00 then
        log.error("An invalid TargetPartition was passed", "CheckForPresence")
        return
    end

    if AllPresent then
        return TargetPartition & PresencePartition == PresencePartition
    else
        return TargetPartition & PresencePartition ~= 0
    end
end

ReactionAPI.Utilities.CheckForAbsence = function(AbsencePartition, TargetPartition, AllAbsent)
    if AbsencePartition < 0x00 then
        log.error("An invalid AbsencePartition was passed", "CheckForAbsence")
        return
    end
    if TargetPartition < 0x00 then
        log.error("An invalid AbsencePartition was passed", "CheckForAbsence")
        return
    end

    if AllAbsent then
        return TargetPartition & AbsencePartition == 0
    else
        return TargetPartition & AbsencePartition ~= AbsencePartition
    end
end