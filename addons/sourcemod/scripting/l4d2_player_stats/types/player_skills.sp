#if defined _l4d2_player_stats_player_skills_types_included
	#endinput
#endif
#define _l4d2_player_stats_player_skills_types_included

#define L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS 8
#define L4D2_PLAYER_STATS_MAX_SKILLS_BOSS_ENTRIES 33
#define L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY 256

enum PlayerStatsSkillsStreamType
{
	PlayerStatsSkillsStream_SkillEvent = 0,
	PlayerStatsSkillsStream_KillEvent,
	PlayerStatsSkillsStream_BossEvent,
	PlayerStatsSkillsStream_BossSession
}

enum PlayerStatsSkillsRejectReason
{
	PlayerStatsSkillsReject_None = 0,
	PlayerStatsSkillsReject_NotApplicable,
	PlayerStatsSkillsReject_TrackingDisabled,
	PlayerStatsSkillsReject_LibraryUnavailable,
	PlayerStatsSkillsReject_RoundNotLive,
	PlayerStatsSkillsReject_NativeUnavailable,
	PlayerStatsSkillsReject_InvalidId,
	PlayerStatsSkillsReject_InvalidEvent,
	PlayerStatsSkillsReject_KeyValuesAllocation,
	PlayerStatsSkillsReject_FillFailed,
	PlayerStatsSkillsReject_RootMissing,
	PlayerStatsSkillsReject_TooManyEntries,
	PlayerStatsSkillsReject_InvalidActor,
	PlayerStatsSkillsReject_NoActorSlot,
	PlayerStatsSkillsReject_InvalidRecord,
	PlayerStatsSkillsReject_Duplicate,
	PlayerStatsSkillsReject_LedgerOverflow
}

enum PlayerStatsSkillsLedgerResult
{
	PlayerStatsSkillsLedger_Marked = 0,
	PlayerStatsSkillsLedger_Duplicate,
	PlayerStatsSkillsLedger_Overflow
}

enum struct StatsSkillsAssistEntry
{
	int userid;
	int damage;
}

enum struct StatsSkillsEventObservation
{
	PlayerStatsSkillsStreamType stream;
	int externalId;
	int type;
	int actorUserid;
	int victimUserid;
	int tickId;
	int suppressedKillType;
	bool impliesSiDeath;
	int assistCount;
	StatsSkillsAssistEntry assists[L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS];
}

enum struct StatsSkillsBossEventObservation
{
	int eventId;
	L4D2ApiBossEventType type;
	int actorUserid;
}

enum struct StatsSkillsBossDamageEntry
{
	int userid;
	int damage;
	int shots;
}

enum struct StatsSkillsBossSessionObservation
{
	int sessionId;
	L4D2BossType type;
	int entryCount;
	StatsSkillsBossDamageEntry entries[L4D2_PLAYER_STATS_MAX_SKILLS_BOSS_ENTRIES];
}

enum struct StatsSkillsImportResult
{
	PlayerStatsSkillsRejectReason reason;
	bool actorApplied;
	int actorUserid;
	int actorClient;
	int actorSlot;
	int assistCount;
	int assistDamage;
	int entryCount;
	int totalDamage;
	int totalShots;

	void Reset()
	{
		this.reason = PlayerStatsSkillsReject_None;
		this.actorApplied = false;
		this.actorUserid = 0;
		this.actorClient = 0;
		this.actorSlot = -1;
		this.assistCount = 0;
		this.assistDamage = 0;
		this.entryCount = 0;
		this.totalDamage = 0;
		this.totalShots = 0;
	}
}
