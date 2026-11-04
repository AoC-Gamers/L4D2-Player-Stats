#if defined _l4d2_player_stats_inputs_player_skills_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_player_skills_included

StatsSkillsImportResult Input_PlayerSkillsSkillDetected(int eventId, L4D2ApiSkillType type)
{
	StatsSkillsImportResult result;
	result.Reset();
	int reservation = -1;
	if (!Input_PlayerSkillsReserve(PlayerStatsSkillsStream_SkillEvent, eventId, result, reservation))
	{
		return result;
	}
	if (type == L4D2ApiSkill_None)
	{
		if (!Input_PlayerSkillsCommit(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result))
		{
			return result;
		}
		result.reason = PlayerStatsSkillsReject_NotApplicable;
		return result;
	}

	if (!Input_PlayerSkillsCheckContext(PlayerStatsSkillsStream_SkillEvent, eventId, type, result))
	{
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}
	if (!Input_PlayerSkillsNativePairAvailable("PlayerSkills_IsSkillEventValid", "PlayerSkills_FillSkillEventKeyValues"))
	{
		result.reason = PlayerStatsSkillsReject_NativeUnavailable;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}

	bool valid = PlayerSkills_IsSkillEventValid(eventId);
	if (!valid)
	{
		Input_PlayerSkillsLogGateFailure(PlayerStatsSkillsStream_SkillEvent, eventId, type, false);
		result.reason = PlayerStatsSkillsReject_InvalidEvent;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}

	Handle kv = CreateKeyValues("player_skills_skill_event");
	if (kv == INVALID_HANDLE)
	{
		result.reason = PlayerStatsSkillsReject_KeyValuesAllocation;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}
	if (!PlayerSkills_FillSkillEventKeyValues(eventId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because FillSkillEventKeyValues failed. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_FillFailed;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "skill_event", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because skill_event root is missing. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_RootMissing;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}

	StatsSkillsEventObservation observation;
	observation.stream = PlayerStatsSkillsStream_SkillEvent;
	observation.externalId = eventId;
	observation.type = type;
	observation.actorUserid = KvGetNum(kv, "actor_userid", 0);
	observation.victimUserid = KvGetNum(kv, "victim_userid", 0);
	observation.tickId = GetGameTickCount();
	observation.suppressedKillType = L4D2ApiKill_None;
	observation.impliesSiDeath = false;
	observation.assistCount = 0;

	if (KvJumpToKey(kv, "properties", false))
	{
		observation.impliesSiDeath = KvGetNum(kv, "implies_si_death", 0) > 0;
		if (observation.impliesSiDeath)
		{
			observation.suppressedKillType = KvGetNum(kv, "suppressed_kill_type_id", 0);
		}
		KvGoBack(kv);
	}

	if (observation.impliesSiDeath
		&& SkillsImport_GetZombieClass(view_as<L4D2ApiKillType>(observation.suppressedKillType)) != L4D2ZombieClass_NotInfected
		&& !Input_PlayerSkillsReadAssists(kv, observation))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because assists exceed the supported payload limit. event=%d type=%d limit=%d",
			eventId,
			type,
			L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS);
		delete kv;
		result.reason = PlayerStatsSkillsReject_TooManyEntries;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result);
		return result;
	}

	delete kv;
	if (!Input_PlayerSkillsCommit(PlayerStatsSkillsStream_SkillEvent, eventId, reservation, result))
	{
		return result;
	}
	return SkillsImport_ApplyEvent(observation);
}

StatsSkillsImportResult Input_PlayerSkillsKillDetected(int eventId, L4D2ApiKillType type)
{
	StatsSkillsImportResult result;
	result.Reset();
	int reservation = -1;
	if (!Input_PlayerSkillsReserve(PlayerStatsSkillsStream_KillEvent, eventId, result, reservation))
	{
		return result;
	}
	if (!Input_PlayerSkillsCheckContext(PlayerStatsSkillsStream_KillEvent, eventId, type, result))
	{
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}
	if (!Input_PlayerSkillsNativePairAvailable("PlayerSkills_IsKillEventValid", "PlayerSkills_FillKillEventKeyValues"))
	{
		result.reason = PlayerStatsSkillsReject_NativeUnavailable;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}

	bool valid = PlayerSkills_IsKillEventValid(eventId);
	if (!valid)
	{
		Input_PlayerSkillsLogGateFailure(PlayerStatsSkillsStream_KillEvent, eventId, type, false);
		result.reason = PlayerStatsSkillsReject_InvalidEvent;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}

	Handle kv = CreateKeyValues("player_skills_kill_event");
	if (kv == INVALID_HANDLE)
	{
		result.reason = PlayerStatsSkillsReject_KeyValuesAllocation;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}
	if (!PlayerSkills_FillKillEventKeyValues(eventId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because FillKillEventKeyValues failed. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_FillFailed;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "kill_event", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because kill_event root is missing. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_RootMissing;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}

	StatsSkillsEventObservation observation;
	observation.stream = PlayerStatsSkillsStream_KillEvent;
	observation.externalId = eventId;
	observation.type = type;
	observation.actorUserid = KvGetNum(kv, "actor_userid", 0);
	observation.victimUserid = KvGetNum(kv, "victim_userid", 0);
	observation.tickId = GetGameTickCount();
	observation.suppressedKillType = L4D2ApiKill_None;
	observation.impliesSiDeath = false;
	observation.assistCount = 0;
	if (SkillsImport_GetZombieClass(type) != L4D2ZombieClass_NotInfected && !Input_PlayerSkillsReadAssists(kv, observation))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because assists exceed the supported payload limit. event=%d type=%d limit=%d",
			eventId,
			type,
			L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS);
		delete kv;
		result.reason = PlayerStatsSkillsReject_TooManyEntries;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result);
		return result;
	}

	delete kv;
	if (!Input_PlayerSkillsCommit(PlayerStatsSkillsStream_KillEvent, eventId, reservation, result))
	{
		return result;
	}
	return SkillsImport_ApplyEvent(observation);
}

StatsSkillsImportResult Input_PlayerSkillsBossEventDetected(int eventId, L4D2ApiBossEventType type)
{
	StatsSkillsImportResult result;
	result.Reset();
	int reservation = -1;
	if (!Input_PlayerSkillsReserve(PlayerStatsSkillsStream_BossEvent, eventId, result, reservation))
	{
		return result;
	}
	if (!Input_PlayerSkillsCheckContext(PlayerStatsSkillsStream_BossEvent, eventId, type, result))
	{
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}
	if (!Input_PlayerSkillsNativePairAvailable("PlayerSkills_IsBossEventValid", "PlayerSkills_FillBossEventKeyValues"))
	{
		result.reason = PlayerStatsSkillsReject_NativeUnavailable;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}

	bool valid = PlayerSkills_IsBossEventValid(eventId);
	if (!valid)
	{
		Input_PlayerSkillsLogGateFailure(PlayerStatsSkillsStream_BossEvent, eventId, type, false);
		result.reason = PlayerStatsSkillsReject_InvalidEvent;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}

	Handle kv = CreateKeyValues("player_skills_boss_event");
	if (kv == INVALID_HANDLE)
	{
		result.reason = PlayerStatsSkillsReject_KeyValuesAllocation;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}
	if (!PlayerSkills_FillBossEventKeyValues(eventId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because FillBossEventKeyValues failed. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_FillFailed;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "boss_event", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because boss_event root is missing. event=%d type=%d", eventId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_RootMissing;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result);
		return result;
	}

	StatsSkillsBossEventObservation observation;
	observation.eventId = eventId;
	observation.type = type;
	observation.actorUserid = KvGetNum(kv, "actor_userid", 0);
	delete kv;
	if (!Input_PlayerSkillsCommit(PlayerStatsSkillsStream_BossEvent, eventId, reservation, result))
	{
		return result;
	}
	return SkillsImport_ApplyBossEvent(observation);
}

StatsSkillsImportResult Input_PlayerSkillsBossSessionFinalized(int sessionId, L4D2BossType type)
{
	StatsSkillsImportResult result;
	result.Reset();
	int reservation = -1;
	if (!Input_PlayerSkillsReserve(PlayerStatsSkillsStream_BossSession, sessionId, result, reservation))
	{
		return result;
	}
	if (!Input_PlayerSkillsCheckContext(PlayerStatsSkillsStream_BossSession, sessionId, type, result))
	{
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}
	if (!Input_PlayerSkillsNativePairAvailable("PlayerSkills_IsBossSessionValid", "PlayerSkills_FillBossSessionKeyValues"))
	{
		result.reason = PlayerStatsSkillsReject_NativeUnavailable;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}

	bool valid = PlayerSkills_IsBossSessionValid(sessionId);
	if (!valid)
	{
		Input_PlayerSkillsLogGateFailure(PlayerStatsSkillsStream_BossSession, sessionId, type, false);
		result.reason = PlayerStatsSkillsReject_InvalidEvent;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}

	Handle kv = CreateKeyValues("player_skills_boss_session");
	if (kv == INVALID_HANDLE)
	{
		result.reason = PlayerStatsSkillsReject_KeyValuesAllocation;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}
	if (!PlayerSkills_FillBossSessionKeyValues(sessionId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session because FillBossSessionKeyValues failed. session=%d type=%d", sessionId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_FillFailed;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "boss_session", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session because boss_session root is missing. session=%d type=%d", sessionId, type);
		delete kv;
		result.reason = PlayerStatsSkillsReject_RootMissing;
		Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
		return result;
	}

	StatsSkillsBossSessionObservation observation;
	observation.sessionId = sessionId;
	observation.type = type;
	observation.entryCount = 0;
	if (KvJumpToKey(kv, "damage_entries", false) && KvGotoFirstSubKey(kv, false))
	{
		do
		{
			if (observation.entryCount >= L4D2_PLAYER_STATS_MAX_SKILLS_BOSS_ENTRIES)
			{
				Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session because damage entries exceed the supported payload limit. session=%d type=%d limit=%d",
					sessionId,
					type,
					L4D2_PLAYER_STATS_MAX_SKILLS_BOSS_ENTRIES);
				delete kv;
				result.reason = PlayerStatsSkillsReject_TooManyEntries;
				Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result);
				return result;
			}

			int i = observation.entryCount++;
			observation.entries[i].userid = KvGetNum(kv, "userid", 0);
			observation.entries[i].damage = KvGetNum(kv, "damage", 0);
			observation.entries[i].shots = KvGetNum(kv, "shots", 0);
		}
		while (KvGotoNextKey(kv, false));
	}

	delete kv;
	if (!Input_PlayerSkillsCommit(PlayerStatsSkillsStream_BossSession, sessionId, reservation, result))
	{
		return result;
	}
	return SkillsImport_ApplyBossSession(observation);
}

bool Input_PlayerSkillsReserve(PlayerStatsSkillsStreamType stream, int id, StatsSkillsImportResult result, int &reservation)
{
	reservation = -1;
	if (id <= 0)
	{
		return true;
	}

	int firstRound;
	PlayerStatsSkillsLedgerResult ledgerResult = SkillsImport_ReserveReceived(stream, id, firstRound, reservation);
	if (ledgerResult == PlayerStatsSkillsLedger_Marked)
	{
		return true;
	}

	if (ledgerResult == PlayerStatsSkillsLedger_Duplicate)
	{
		result.reason = PlayerStatsSkillsReject_Duplicate;
	}
	else
	{
		result.reason = PlayerStatsSkillsReject_LedgerOverflow;
	}
	SkillsImport_LogLedgerResult(stream, id, firstRound, result.reason);
	return false;
}

void Input_PlayerSkillsResolveReservation(PlayerStatsSkillsStreamType stream, int id, int reservation, StatsSkillsImportResult result)
{
	// Tracking-off and non-live callbacks are consumed; transient failures release the reservation for retry.
	if (result.reason == PlayerStatsSkillsReject_TrackingDisabled || result.reason == PlayerStatsSkillsReject_RoundNotLive)
	{
		StatsSkillsImportResult ignored;
		ignored.Reset();
		Input_PlayerSkillsCommit(stream, id, reservation, ignored);
		return;
	}

	SkillsImport_ReleaseReceived(stream, id, reservation);
}

bool Input_PlayerSkillsCommit(PlayerStatsSkillsStreamType stream, int id, int reservation, StatsSkillsImportResult result)
{
	if (SkillsImport_CommitReceived(stream, id, reservation))
	{
		return true;
	}

	result.reason = PlayerStatsSkillsReject_LedgerOverflow;
	SkillsImport_LogLedgerResult(stream, id, g_Round.meta.id, result.reason);
	return false;
}

bool Input_PlayerSkillsCheckContext(PlayerStatsSkillsStreamType stream, int eventId, int type, StatsSkillsImportResult result)
{
	if (!Stats_IsTrackingEnabled())
	{
		result.reason = PlayerStatsSkillsReject_TrackingDisabled;
		Input_PlayerSkillsLogGateFailure(stream, eventId, type, false);
		return false;
	}
	if (!g_Runtime.hasPlayerSkills)
	{
		result.reason = PlayerStatsSkillsReject_LibraryUnavailable;
		Input_PlayerSkillsLogGateFailure(stream, eventId, type, false);
		return false;
	}
	if (!Stats_IsRoundLive())
	{
		result.reason = PlayerStatsSkillsReject_RoundNotLive;
		Input_PlayerSkillsLogGateFailure(stream, eventId, type, false);
		return false;
	}
	return true;
}

bool Input_PlayerSkillsNativePairAvailable(const char[] validNative, const char[] fillNative)
{
	return GetFeatureStatus(FeatureType_Native, validNative) == FeatureStatus_Available
		&& GetFeatureStatus(FeatureType_Native, fillNative) == FeatureStatus_Available;
}

bool Input_PlayerSkillsReadAssists(Handle kv, StatsSkillsEventObservation observation)
{
	if (!KvJumpToKey(kv, "assists", false) || !KvGotoFirstSubKey(kv, false))
	{
		return true;
	}

	do
	{
		if (observation.assistCount >= L4D2_PLAYER_STATS_MAX_SKILLS_ASSISTS)
		{
			return false;
		}

		int i = observation.assistCount++;
		observation.assists[i].userid = KvGetNum(kv, "userid", 0);
		observation.assists[i].damage = KvGetNum(kv, "damage", 0);
	}
	while (KvGotoNextKey(kv, false));

	return true;
}

void Input_PlayerSkillsLogGateFailure(PlayerStatsSkillsStreamType stream, int eventId, int type, bool valid)
{
	char streamName[24];
	SkillsImport_GetStreamName(stream, streamName, sizeof(streamName));
	Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills %s. event=%d type=%d tracking=%d has_skills=%d live=%d valid=%d",
		streamName,
		eventId,
		type,
		Stats_IsTrackingEnabled(),
		g_Runtime.hasPlayerSkills,
		Stats_IsRoundLive(),
		valid);
}
