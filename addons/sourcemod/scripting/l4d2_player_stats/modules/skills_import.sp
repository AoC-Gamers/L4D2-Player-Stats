#if defined _l4d2_player_stats_modules_skills_import_included
	#endinput
#endif
#define _l4d2_player_stats_modules_skills_import_included

enum struct SkillsImportDeathReceipt
{
	bool active;
	int generation;
	int roundId;
	int mapGeneration;
	int tickId;
	int actorUserid;
	int victimUserid;
	L4D2ApiKillType killType;
	PlayerStatsSkillsStreamType stream;
	int eventId;
}

SkillsImportDeathReceipt g_SkillsImportDeathReceipts[L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY];
int g_iSkillsImportDeathReceiptNext;

void SkillsImport_OnPlayerSkillsLibraryChanged()
{
	g_iPlayerSkillsGeneration++;
	if (g_iPlayerSkillsGeneration <= 0)
	{
		g_iPlayerSkillsGeneration = 1;
	}

	for (int stream = 0; stream < sizeof(g_iPlayerSkillsLedgerNext); stream++)
	{
		g_iPlayerSkillsLedgerNext[stream] = 0;
		for (int i = 0; i < L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY; i++)
		{
			g_iPlayerSkillsLedgerGeneration[stream][i] = 0;
			g_iPlayerSkillsLedgerIds[stream][i] = 0;
			g_iPlayerSkillsLedgerRounds[stream][i] = 0;
		}
	}

	g_iSkillsImportDeathReceiptNext = 0;
	for (int i = 0; i < L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY; i++)
	{
		g_SkillsImportDeathReceipts[i].active = false;
	}
}

PlayerStatsSkillsLedgerResult SkillsImport_ReserveReceived(PlayerStatsSkillsStreamType stream, int id, int &firstRound, int &reservation)
{
	firstRound = g_Round.meta.id;
	reservation = -1;
	if (id <= 0)
	{
		return PlayerStatsSkillsLedger_Marked;
	}
	if (stream < PlayerStatsSkillsStream_SkillEvent || stream > PlayerStatsSkillsStream_BossSession)
	{
		return PlayerStatsSkillsLedger_Overflow;
	}

	for (int i = 0; i < L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY; i++)
	{
		int entryGeneration = g_iPlayerSkillsLedgerGeneration[stream][i];
		if ((entryGeneration == g_iPlayerSkillsGeneration + 1 || entryGeneration == -(g_iPlayerSkillsGeneration + 1))
			&& g_iPlayerSkillsLedgerIds[stream][i] == id)
		{
			firstRound = g_iPlayerSkillsLedgerRounds[stream][i];
			return PlayerStatsSkillsLedger_Duplicate;
		}
	}

	int next = g_iPlayerSkillsLedgerNext[stream];
	if (next < 0 || next >= L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY)
	{
		return PlayerStatsSkillsLedger_Overflow;
	}

	g_iPlayerSkillsLedgerGeneration[stream][next] = -(g_iPlayerSkillsGeneration + 1);
	g_iPlayerSkillsLedgerIds[stream][next] = id;
	g_iPlayerSkillsLedgerRounds[stream][next] = g_Round.meta.id;
	g_iPlayerSkillsLedgerNext[stream] = (next + 1) % L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY;
	reservation = next;
	return PlayerStatsSkillsLedger_Marked;
}

bool SkillsImport_CommitReceived(PlayerStatsSkillsStreamType stream, int id, int reservation)
{
	if (id <= 0)
	{
		return true;
	}
	if (stream < PlayerStatsSkillsStream_SkillEvent || stream > PlayerStatsSkillsStream_BossSession
		|| reservation < 0 || reservation >= L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY)
	{
		return false;
	}

	int token = g_iPlayerSkillsGeneration + 1;
	if (g_iPlayerSkillsLedgerGeneration[stream][reservation] != -token
		|| g_iPlayerSkillsLedgerIds[stream][reservation] != id)
	{
		return false;
	}

	g_iPlayerSkillsLedgerGeneration[stream][reservation] = token;
	return true;
}

void SkillsImport_ReleaseReceived(PlayerStatsSkillsStreamType stream, int id, int reservation)
{
	if (id <= 0 || stream < PlayerStatsSkillsStream_SkillEvent || stream > PlayerStatsSkillsStream_BossSession
		|| reservation < 0 || reservation >= L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY)
	{
		return;
	}

	int token = g_iPlayerSkillsGeneration + 1;
	if (g_iPlayerSkillsLedgerGeneration[stream][reservation] == -token
		&& g_iPlayerSkillsLedgerIds[stream][reservation] == id)
	{
		g_iPlayerSkillsLedgerGeneration[stream][reservation] = 0;
		g_iPlayerSkillsLedgerIds[stream][reservation] = 0;
		g_iPlayerSkillsLedgerRounds[stream][reservation] = 0;
	}
}

void SkillsImport_LogLedgerResult(PlayerStatsSkillsStreamType stream, int id, int firstRound, PlayerStatsSkillsRejectReason reason)
{
	char streamName[24];
	SkillsImport_GetStreamName(stream, streamName, sizeof(streamName));
	char outcome[16];
	strcopy(outcome, sizeof(outcome), reason == PlayerStatsSkillsReject_Duplicate ? "duplicate" : "overflow");
	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills import stream=%s id=%d generation=%d round=%d observed_round=%d result=%s omitted=1",
		streamName,
		id,
		g_iPlayerSkillsGeneration,
		g_Round.meta.id,
		firstRound,
		outcome);
}

StatsSkillsImportResult SkillsImport_ApplyEvent(const StatsSkillsEventObservation observation)
{
	StatsSkillsImportResult result;
	result.Reset();
	result.actorUserid = observation.actorUserid;

	if (observation.stream < PlayerStatsSkillsStream_SkillEvent || observation.stream > PlayerStatsSkillsStream_KillEvent
		|| observation.assistCount < 0
		|| observation.assistCount > L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS)
	{
		result.reason = PlayerStatsSkillsReject_InvalidRecord;
		return result;
	}

	int actor = observation.actorUserid > 0 ? GetClientOfUserId(observation.actorUserid) : 0;
	result.actorClient = actor;
	if (!IsValidSurvivor(actor))
	{
		result.reason = PlayerStatsSkillsReject_InvalidActor;
		SkillsImport_LogRejected(observation.stream, observation.externalId, observation.type, result.reason, observation.actorUserid, actor);
		return result;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		result.reason = PlayerStatsSkillsReject_NoActorSlot;
		SkillsImport_LogRejected(observation.stream, observation.externalId, observation.type, result.reason, observation.actorUserid, actor);
		return result;
	}
	result.actorApplied = true;
	result.actorSlot = index;

	L4D2ApiKillType killType = view_as<L4D2ApiKillType>(observation.stream == PlayerStatsSkillsStream_SkillEvent
		? observation.suppressedKillType
		: observation.type);
	L4D2ZombieClassType zombieClass = SkillsImport_GetZombieClass(killType);
	bool isSiDeath = (observation.stream == PlayerStatsSkillsStream_KillEvent || observation.impliesSiDeath)
		&& zombieClass != L4D2ZombieClass_NotInfected;
	bool duplicateSiDeath = false;
	int matchedEventId = 0;
	PlayerStatsSkillsStreamType matchedStream = PlayerStatsSkillsStream_SkillEvent;
	if (isSiDeath)
	{
		duplicateSiDeath = SkillsImport_MatchCrossStreamDeath(observation, killType, matchedEventId, matchedStream);
		if (duplicateSiDeath)
		{
			char currentStreamName[24];
			char matchedStreamName[24];
			SkillsImport_GetStreamName(observation.stream, currentStreamName, sizeof(currentStreamName));
			SkillsImport_GetStreamName(matchedStream, matchedStreamName, sizeof(matchedStreamName));
			Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills duplicate SI death suppressed. stream=%s event=%d matched_stream=%s matched_event=%d actor_userid=%d victim_userid=%d tick=%d kill_type=%d round=%d mapgen=%d",
				currentStreamName,
				observation.externalId,
				matchedStreamName,
				matchedEventId,
				observation.actorUserid,
				observation.victimUserid,
				observation.tickId,
				killType,
				g_Round.meta.id,
				g_Trace.mapGeneration);
		}
	}
	if (isSiDeath && !duplicateSiDeath)
	{
		Combat_ApplySpecialKillByClass(index, zombieClass);
		SkillsImport_ConsumeAssists(observation, zombieClass, result);
	}

	if (observation.stream == PlayerStatsSkillsStream_KillEvent)
	{
		if (!duplicateSiDeath)
		{
			char killTypeName[32];
			SkillsImport_GetKillTypeName(view_as<L4D2ApiKillType>(observation.type), killTypeName, sizeof(killTypeName));
			Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills kill_event credited. event=%d type=%s actor_userid=%d client=%d slot=%d assists=%d assist_damage=%d",
				observation.externalId,
				killTypeName,
				observation.actorUserid,
				actor,
				index,
				result.assistCount,
				result.assistDamage);
		}
	}
	else if (observation.impliesSiDeath && zombieClass != L4D2ZombieClass_NotInfected)
	{
		char killTypeName[32];
		SkillsImport_GetKillTypeName(killType, killTypeName, sizeof(killTypeName));
		Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills skill_event implied SI death. event=%d credited=%d skill_type=%d kill_type=%s actor_userid=%d client=%d slot=%d assists=%d assist_damage=%d",
			observation.externalId,
			!duplicateSiDeath,
			observation.type,
			killTypeName,
			observation.actorUserid,
			actor,
			index,
			result.assistCount,
			result.assistDamage);
	}
	else
	{
		Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills skill_event did not imply SI death. event=%d skill_type=%d actor_userid=%d client=%d",
			observation.externalId,
			observation.type,
			observation.actorUserid,
			actor);
	}

	return result;
}

bool SkillsImport_MatchCrossStreamDeath(const StatsSkillsEventObservation observation, L4D2ApiKillType killType, int &matchedEventId, PlayerStatsSkillsStreamType &matchedStream)
{
	matchedEventId = 0;
	matchedStream = observation.stream;
	if (observation.tickId <= 0 || observation.actorUserid <= 0 || observation.victimUserid <= 0)
	{
		return false;
	}

	int generation = g_iPlayerSkillsGeneration + 1;
	int roundId = g_Round.meta.id;
	int mapGeneration = g_Trace.mapGeneration;
	for (int i = 0; i < L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY; i++)
	{
		if (!g_SkillsImportDeathReceipts[i].active)
		{
			continue;
		}

		if (g_SkillsImportDeathReceipts[i].generation != generation
			|| g_SkillsImportDeathReceipts[i].roundId != roundId
			|| g_SkillsImportDeathReceipts[i].mapGeneration != mapGeneration)
		{
			g_SkillsImportDeathReceipts[i].active = false;
			continue;
		}

		if (g_SkillsImportDeathReceipts[i].stream != observation.stream
			&& g_SkillsImportDeathReceipts[i].tickId == observation.tickId
			&& g_SkillsImportDeathReceipts[i].actorUserid == observation.actorUserid
			&& g_SkillsImportDeathReceipts[i].victimUserid == observation.victimUserid
			&& g_SkillsImportDeathReceipts[i].killType == killType)
		{
			matchedEventId = g_SkillsImportDeathReceipts[i].eventId;
			matchedStream = g_SkillsImportDeathReceipts[i].stream;
			g_SkillsImportDeathReceipts[i].active = false;
			return true;
		}
	}

	int next = g_iSkillsImportDeathReceiptNext;
	g_iSkillsImportDeathReceiptNext = (next + 1) % L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY;
	g_SkillsImportDeathReceipts[next].active = true;
	g_SkillsImportDeathReceipts[next].generation = generation;
	g_SkillsImportDeathReceipts[next].roundId = roundId;
	g_SkillsImportDeathReceipts[next].mapGeneration = mapGeneration;
	g_SkillsImportDeathReceipts[next].tickId = observation.tickId;
	g_SkillsImportDeathReceipts[next].actorUserid = observation.actorUserid;
	g_SkillsImportDeathReceipts[next].victimUserid = observation.victimUserid;
	g_SkillsImportDeathReceipts[next].killType = killType;
	g_SkillsImportDeathReceipts[next].stream = observation.stream;
	g_SkillsImportDeathReceipts[next].eventId = observation.externalId;
	return false;
}

StatsSkillsImportResult SkillsImport_ApplyBossEvent(const StatsSkillsBossEventObservation observation)
{
	StatsSkillsImportResult result;
	result.Reset();
	result.actorUserid = observation.actorUserid;

	int actor = observation.actorUserid > 0 ? GetClientOfUserId(observation.actorUserid) : 0;
	result.actorClient = actor;
	if (!IsValidSurvivor(actor))
	{
		result.reason = PlayerStatsSkillsReject_InvalidActor;
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because actor did not resolve to a survivor. event=%d type=%d",
			observation.eventId,
			observation.type);
		return result;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		result.reason = PlayerStatsSkillsReject_NoActorSlot;
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because no round slot could be assigned. event=%d type=%d client=%d",
			observation.eventId,
			observation.type,
			actor);
		return result;
	}

	result.actorApplied = true;
	result.actorSlot = index;
	switch (observation.type)
	{
		case L4D2ApiBossEvent_WitchCrown, L4D2ApiBossEvent_WitchDead:
		{
			SkillsImport_AddWitchKill(index);
		}
	}

	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills boss_event credited. event=%d type=%d client=%d slot=%d witch_kills=%d",
		observation.eventId,
		observation.type,
		actor,
		index,
		g_Round.players[index].combat.witchKills);
	return result;
}

StatsSkillsImportResult SkillsImport_ApplyBossSession(const StatsSkillsBossSessionObservation observation)
{
	StatsSkillsImportResult result;
	result.Reset();

	if (observation.entryCount < 0 || observation.entryCount > L4D2_PLAYER_STATS_MAX_SKILLS_BOSS_ENTRIES)
	{
		result.reason = PlayerStatsSkillsReject_InvalidRecord;
		return result;
	}

	for (int i = 0; i < observation.entryCount; i++)
	{
		int userid = observation.entries[i].userid;
		int client = userid > 0 ? GetClientOfUserId(userid) : 0;
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		int index = Stats_EnsurePlayerRoundSlot(client);
		if (index == -1)
		{
			continue;
		}

		int damage = observation.entries[i].damage;
		int shots = observation.entries[i].shots;
		result.entryCount++;
		result.totalDamage += damage;
		result.totalShots += shots;
		switch (observation.type)
		{
			case L4D2Boss_Tank:
			{
				g_Round.players[index].bossDetail.tankDamage += damage;
				g_Round.players[index].bossDetail.tankShots += shots;
			}
			case L4D2Boss_Witch:
			{
				g_Round.players[index].bossDetail.witchDamage += damage;
				g_Round.players[index].bossDetail.witchShots += shots;
			}
		}
	}

	char bossTypeName[16];
	SkillsImport_GetBossTypeName(observation.type, bossTypeName, sizeof(bossTypeName));
	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills boss_session credited. session=%d type=%s entries=%d damage=%d shots=%d",
		observation.sessionId,
		bossTypeName,
		result.entryCount,
		result.totalDamage,
		result.totalShots);
	return result;
}

void SkillsImport_ConsumeAssists(const StatsSkillsEventObservation observation, L4D2ZombieClassType zombieClass, StatsSkillsImportResult result)
{
	if (zombieClass == L4D2ZombieClass_NotInfected)
	{
		return;
	}

	for (int i = 0; i < observation.assistCount; i++)
	{
		int userid = observation.assists[i].userid;
		if (userid <= 0 || userid == observation.actorUserid)
		{
			continue;
		}

		int client = GetClientOfUserId(userid);
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		int index = Stats_EnsurePlayerRoundSlot(client);
		if (index == -1)
		{
			continue;
		}

		int damage = observation.assists[i].damage;
		SkillsImport_AddSpecialKillAssistByClass(index, zombieClass);
		SkillsImport_AddSpecialAssistDamageByClass(index, zombieClass, damage);
		result.assistCount++;
		result.assistDamage += damage;
	}
}

void SkillsImport_AddWitchKill(int index)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	g_Round.players[index].combat.witchKills++;
	g_Round.totals.survivorTotalWitchKills++;
}

void SkillsImport_AddSpecialKillAssistByClass(int index, L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	g_Round.players[index].combatAssists.siKillAssists++;
	g_Round.totals.survivorTotalSiKillAssists++;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combatAssists.smokerKillAssists++;
			g_Round.totals.survivorTotalSmokerKillAssists++;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combatAssists.boomerKillAssists++;
			g_Round.totals.survivorTotalBoomerKillAssists++;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combatAssists.hunterKillAssists++;
			g_Round.totals.survivorTotalHunterKillAssists++;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combatAssists.spitterKillAssists++;
			g_Round.totals.survivorTotalSpitterKillAssists++;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combatAssists.jockeyKillAssists++;
			g_Round.totals.survivorTotalJockeyKillAssists++;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combatAssists.chargerKillAssists++;
			g_Round.totals.survivorTotalChargerKillAssists++;
		}
	}
}

void SkillsImport_AddSpecialAssistDamageByClass(int index, L4D2ZombieClassType zombieClass, int damage)
{
	if (!Stats_IsValidRoundSlot(index) || damage <= 0)
	{
		return;
	}

	g_Round.players[index].combatAssists.siAssistDamage += damage;
	g_Round.totals.survivorTotalSiAssistDamage += damage;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combatAssists.smokerAssistDamage += damage;
			g_Round.totals.survivorTotalSmokerAssistDamage += damage;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combatAssists.boomerAssistDamage += damage;
			g_Round.totals.survivorTotalBoomerAssistDamage += damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combatAssists.hunterAssistDamage += damage;
			g_Round.totals.survivorTotalHunterAssistDamage += damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combatAssists.spitterAssistDamage += damage;
			g_Round.totals.survivorTotalSpitterAssistDamage += damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combatAssists.jockeyAssistDamage += damage;
			g_Round.totals.survivorTotalJockeyAssistDamage += damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combatAssists.chargerAssistDamage += damage;
			g_Round.totals.survivorTotalChargerAssistDamage += damage;
		}
	}
}

L4D2ZombieClassType SkillsImport_GetZombieClass(L4D2ApiKillType type)
{
	switch (type)
	{
		case L4D2ApiKill_SmokerKill: return L4D2ZombieClass_Smoker;
		case L4D2ApiKill_BoomerKill: return L4D2ZombieClass_Boomer;
		case L4D2ApiKill_HunterKill: return L4D2ZombieClass_Hunter;
		case L4D2ApiKill_SpitterKill: return L4D2ZombieClass_Spitter;
		case L4D2ApiKill_JockeyKill: return L4D2ZombieClass_Jockey;
		case L4D2ApiKill_ChargerKill: return L4D2ZombieClass_Charger;
	}

	return L4D2ZombieClass_NotInfected;
}

void SkillsImport_GetKillTypeName(L4D2ApiKillType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2ApiKill_SmokerKill: strcopy(buffer, maxlen, "SmokerKill");
		case L4D2ApiKill_BoomerKill: strcopy(buffer, maxlen, "BoomerKill");
		case L4D2ApiKill_HunterKill: strcopy(buffer, maxlen, "HunterKill");
		case L4D2ApiKill_SpitterKill: strcopy(buffer, maxlen, "SpitterKill");
		case L4D2ApiKill_JockeyKill: strcopy(buffer, maxlen, "JockeyKill");
		case L4D2ApiKill_ChargerKill: strcopy(buffer, maxlen, "ChargerKill");
		default: strcopy(buffer, maxlen, "None");
	}
}

void SkillsImport_GetBossTypeName(L4D2BossType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2Boss_Tank: strcopy(buffer, maxlen, "Tank");
		case L4D2Boss_Witch: strcopy(buffer, maxlen, "Witch");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

void SkillsImport_LogRejected(PlayerStatsSkillsStreamType stream, int eventId, int type, PlayerStatsSkillsRejectReason reason, int actorUserid, int actor)
{
	char streamName[24];
	SkillsImport_GetStreamName(stream, streamName, sizeof(streamName));
	Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills %s because actor did not resolve to a survivor. event=%d type=%d actor_userid=%d client=%d reason=%d",
		streamName,
		eventId,
		type,
		actorUserid,
		actor,
		reason);
}

void SkillsImport_GetStreamName(PlayerStatsSkillsStreamType stream, char[] buffer, int maxlen)
{
	switch (stream)
	{
		case PlayerStatsSkillsStream_SkillEvent: strcopy(buffer, maxlen, "skill_event");
		case PlayerStatsSkillsStream_KillEvent: strcopy(buffer, maxlen, "kill_event");
		case PlayerStatsSkillsStream_BossEvent: strcopy(buffer, maxlen, "boss_event");
		case PlayerStatsSkillsStream_BossSession: strcopy(buffer, maxlen, "boss_session");
		default: strcopy(buffer, maxlen, "unknown");
	}
}
