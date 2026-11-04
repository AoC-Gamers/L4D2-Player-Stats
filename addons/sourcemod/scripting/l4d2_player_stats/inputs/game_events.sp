#if defined _l4d2_player_stats_inputs_game_events_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_game_events_included

StatsTankSpawnResult Input_TankSpawn(Event event)
{
	StatsTankSpawnResult result;
	result.Reset();

	if (!Stats_IsTrackingEnabled())
	{
		result.type = StatsTankSpawnResult_TrackingDisabled;
		return result;
	}

	if (!Stats_IsRoundLive())
	{
		result.type = StatsTankSpawnResult_RoundNotLive;
		return result;
	}

	if (!Stats_IsCompetitiveMode())
	{
		result.type = StatsTankSpawnResult_WrongMode;
		return result;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	bool hadActiveSession = Detect_FindActiveTankSessionIndex() != -1;
	result.sessionIndex = Detect_StartTankSession(client);
	if (result.sessionIndex == -1)
	{
		result.type = StatsTankSpawnResult_SessionCapacity;
	}
	else if (hadActiveSession)
	{
		result.type = StatsTankSpawnResult_ExistingSession;
	}
	else
	{
		result.type = StatsTankSpawnResult_NewSession;
	}

	return result;
}

void Input_PlayerSpawn(Event event)
{
	if (event == null)
	{
		return;
	}

	int userid = event.GetInt("userid");
	int client = userid > 0 ? GetClientOfUserId(userid) : 0;
	if (!IsValidClient(client))
	{
		return;
	}

	Damage_AdvanceTankVictimLife(client, userid, "player_spawn");
}

void Input_IncapacitatedPost(int victim, int attacker)
{
	StatsIncapacitationObservation observation;
	observation.victim = victim;
	observation.attacker = attacker;
	Detect_ProcessIncapacitatedPost(observation);
}

void Input_RoundStart(Event event, const char[] name)
{
	char objective[64];
	event.GetString("objective", objective, sizeof(objective));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] timelimit=%d fraglimit=%d objective=%s", name, event.GetInt("timelimit"), event.GetInt("fraglimit"), objective);

	StatsLifecycleSignal signal;
	signal.signalClass = StatsLifecycleSignalClass_Start;
	strcopy(signal.name, sizeof(signal.name), name);
	Round_OnStartSignal(signal);
}

void Input_RoundEnd(Event event, const char[] name)
{
	char message[128];
	event.GetString("message", message, sizeof(message));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] winner=%d reason=%d message=%s time=%.1f", name, event.GetInt("winner"), event.GetInt("reason"), message, event.GetFloat("time"));

	StatsLifecycleSignal signal;
	signal.signalClass = StatsLifecycleSignalClass_End;
	strcopy(signal.name, sizeof(signal.name), name);
	Round_OnEndSignal(signal);
}

void Input_ScavengeRoundStart(Event event, const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s] round=%d firsthalf=%d", name, event.GetInt("round"), event.GetBool("firsthalf"));

	StatsLifecycleSignal signal;
	signal.signalClass = StatsLifecycleSignalClass_Start;
	strcopy(signal.name, sizeof(signal.name), name);
	Round_OnStartSignal(signal);
}

void Input_ScavengeRoundFinished(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);

	StatsLifecycleSignal signal;
	signal.signalClass = StatsLifecycleSignalClass_End;
	strcopy(signal.name, sizeof(signal.name), name);
	Round_OnEndSignal(signal);
}

void Input_MapTransition(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_OnMapTransition();
}

void Input_FinaleWin(Event event, const char[] name)
{
	char mapName[64];
	event.GetString("map_name", mapName, sizeof(mapName));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] map_name=%s difficulty=%d", name, mapName, event.GetInt("difficulty"));
	Round_OnFinaleWin();
}

void Input_MissionLost(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_OnMissionLost();
}

void Input_ScavengeRoundHalftime(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_OnScavengeRoundHalftime();
}

void Input_ScavengeMatchFinished(Event event, const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s] winners=%d", name, event.GetInt("winners"));
	Round_OnScavengeMatchFinished();
}

void Input_VersusMatchFinished(Event event, const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s] winners=%d", name, event.GetInt("winners"));
	Round_OnVersusMatchFinished();
}

void Input_ScavengeOvertime(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_OnScavengeOvertime();
}

void Input_ScavengeScoreTied(const char[] name)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_OnScavengeScoreTied();
}

StatsWeaponFireResult Input_WeaponFire(Event event)
{
	StatsShotRecord observation;
	StatsWeaponFireResult result;
	int index = -1;

	Input_ReadWeaponFire(event, observation);
	result.route = Accuracy_ApplyShot(observation, index);
	result.throwable = PlayerStatsUtilityThrow_NotEvaluated;

	if (result.route == PlayerStatsShotRoute_ReadyForUtility)
	{
		result.throwable = Utility_ApplyThrow(observation, index);
	}

	return result;
}

void Input_ReadWeaponFire(Event event, StatsShotRecord observation)
{
	observation.userid = 0;
	observation.client = 0;
	observation.validPayload = false;
	observation.weapon[0] = '\0';

	if (event == null)
	{
		return;
	}

	observation.userid = event.GetInt("userid");
	observation.validPayload = observation.userid > 0;
	if (observation.validPayload)
	{
		observation.client = GetClientOfUserId(observation.userid);
	}

	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
}

StatsWitchHurtResult Input_InfectedHurt(Event event, StatsTraceContext traceContext)
{
	StatsInfectedHurtObservation observation;
	StatsWitchDamageRecord record;
	StatsWitchHurtResult result;

	Input_ReadInfectedHurt(event, observation);
	result.resolution = Damage_ResolveWitchHurt(observation, record);
	result.accuracy = PlayerStatsAccuracy_NotEvaluated;
	result.combat = PlayerStatsWitchCombat_NotEvaluated;
	if (result.resolution != PlayerStatsWitchHurt_Ready)
	{
		Trace_WitchResult(traceContext, observation.entity, result);
		return result;
	}

	result.accuracy = Accuracy_ApplyWitchHit(record);
	result.combat = Combat_ApplyWitchDamage(record);
	Trace_WitchResult(traceContext, observation.entity, result);
	return result;
}

void Input_ReadInfectedHurt(Event event, StatsInfectedHurtObservation observation)
{
	observation.entity = 0;
	observation.attackerUserid = 0;
	observation.attackerClient = 0;
	observation.amount = 0;
	observation.hitgroup = 0;
	observation.validPayload = event != null;
	observation.weapon[0] = '\0';

	if (event == null)
	{
		return;
	}

	observation.entity = event.GetInt("entityid");
	observation.attackerUserid = event.GetInt("attacker");
	if (observation.attackerUserid > 0)
	{
		observation.attackerClient = GetClientOfUserId(observation.attackerUserid);
	}
	observation.amount = event.GetInt("amount");
	observation.hitgroup = event.GetInt("hitgroup");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
}

void Input_ReadPlayerHurt(Event event, StatsPlayerHurtObservation observation)
{
	observation.quantityBasis = PlayerStatsDamageBasis_PlayerHurtDmgHealth;
	observation.victimUserid = 0;
	observation.victimClient = 0;
	observation.attackerUserid = 0;
	observation.attackerClient = 0;
	observation.damage = 0;
	observation.hitgroup = 0;
	observation.weapon[0] = '\0';

	if (event == null)
	{
		return;
	}

	observation.victimUserid = event.GetInt("userid");
	observation.victimClient = GetClientOfUserId(observation.victimUserid);
	observation.attackerUserid = event.GetInt("attacker");
	observation.attackerClient = GetClientOfUserId(observation.attackerUserid);
	observation.damage = event.GetInt("dmg_health");
	observation.hitgroup = event.GetInt("hitgroup");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
}

PlayerStatsScavengeApplyResult Input_ScavengeGascanPoured(Event event, StatsTraceContext traceContext)
{
	StatsObjectiveRecord observation;
	Input_ReadScavengeObjective(event, PlayerStatsScavengeObjective_Poured, observation);
	PlayerStatsScavengeApplyResult result = Scavenge_ApplyObjective(observation);
	Trace_ScavengeResult(traceContext, observation.type, result);
	return result;
}

PlayerStatsScavengeApplyResult Input_ScavengeGascanDropped(Event event, StatsTraceContext traceContext)
{
	StatsObjectiveRecord observation;
	Input_ReadScavengeObjective(event, PlayerStatsScavengeObjective_Dropped, observation);
	PlayerStatsScavengeApplyResult result = Scavenge_ApplyObjective(observation);
	Trace_ScavengeResult(traceContext, observation.type, result);
	return result;
}

PlayerStatsScavengeApplyResult Input_ScavengeGascanDestroyed(Event event, StatsTraceContext traceContext)
{
	StatsObjectiveRecord observation;
	Input_ReadScavengeObjective(event, PlayerStatsScavengeObjective_Destroyed, observation);
	PlayerStatsScavengeApplyResult result = Scavenge_ApplyObjective(observation);
	Trace_ScavengeResult(traceContext, observation.type, result);
	return result;
}

void Input_ReadScavengeObjective(Event event, PlayerStatsScavengeObjectiveType type, StatsObjectiveRecord observation)
{
	observation.type = type;
	observation.userid = 0;
	observation.client = 0;
	observation.validPayload = event != null;

	if (event == null)
	{
		return;
	}

	observation.userid = event.GetInt("userid");
	observation.validPayload = observation.userid > 0;
	if (observation.validPayload)
	{
		observation.client = GetClientOfUserId(observation.userid);
	}
}

PlayerStatsSurvivorApplyStatus Input_SurvivorPillsUsed(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_PillsUsed, observation);
	return Survivor_ApplyAction(observation, result);
}

PlayerStatsSurvivorApplyStatus Input_SurvivorAdrenalineUsed(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_AdrenalineUsed, observation);
	return Survivor_ApplyAction(observation, result);
}

PlayerStatsSurvivorApplyStatus Input_SurvivorHealSuccess(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_HealSuccess, observation);
	return Survivor_ApplyAction(observation, result);
}

PlayerStatsSurvivorApplyStatus Input_SurvivorDefibrillatorUsed(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_DefibrillatorUsed, observation);
	return Survivor_ApplyAction(observation, result);
}

PlayerStatsSurvivorApplyStatus Input_SurvivorReviveSuccess(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_ReviveSuccess, observation);
	return Survivor_ApplyAction(observation, result);
}

PlayerStatsSurvivorApplyStatus Input_SurvivorRescued(Event event, StatsSurvivorActionResult result)
{
	StatsSurvivorActionRecord observation;
	Input_ReadSurvivorAction(event, PlayerStatsSurvivorAction_Rescued, observation);
	return Survivor_ApplyAction(observation, result);
}

void Input_ReadSurvivorAction(Event event, PlayerStatsSurvivorActionType type, StatsSurvivorActionRecord observation)
{
	observation.type = type;
	observation.actorUserid = 0;
	observation.actorClient = 0;
	observation.actorPayloadValid = false;
	observation.recipientUserid = 0;
	observation.recipientClient = 0;
	observation.hasRecipient = type == PlayerStatsSurvivorAction_HealSuccess
		|| type == PlayerStatsSurvivorAction_ReviveSuccess
		|| type == PlayerStatsSurvivorAction_Rescued;
	observation.recipientPayloadValid = false;

	if (event == null)
	{
		return;
	}

	char actorField[16];
	strcopy(actorField, sizeof(actorField), type == PlayerStatsSurvivorAction_Rescued ? "rescuer" : "userid");
	observation.actorUserid = event.GetInt(actorField);
	observation.actorPayloadValid = observation.actorUserid > 0;
	if (observation.actorPayloadValid)
	{
		observation.actorClient = GetClientOfUserId(observation.actorUserid);
	}

	if (!observation.hasRecipient)
	{
		return;
	}

	char recipientField[16];
	strcopy(recipientField, sizeof(recipientField), type == PlayerStatsSurvivorAction_Rescued ? "victim" : "subject");
	observation.recipientUserid = event.GetInt(recipientField);
	observation.recipientPayloadValid = observation.recipientUserid > 0;
	if (observation.recipientPayloadValid)
	{
		observation.recipientClient = GetClientOfUserId(observation.recipientUserid);
	}
}

PlayerStatsUtilityApplyResult Input_UtilityPlayerNowIt(Event event, StatsTraceContext traceContext)
{
	StatsUtilityRecord observation;
	Input_ReadUtilityAction(event, PlayerStatsUtilityAction_PlayerNowIt, observation);
	PlayerStatsUtilityApplyResult result = Utility_ApplyAction(observation);
	Trace_UtilityResult(traceContext, observation.type, result);
	return result;
}

PlayerStatsUtilityApplyResult Input_UtilityVomitBombTank(Event event, StatsTraceContext traceContext)
{
	StatsUtilityRecord observation;
	Input_ReadUtilityAction(event, PlayerStatsUtilityAction_VomitBombTank, observation);
	PlayerStatsUtilityApplyResult result = Utility_ApplyAction(observation);
	Trace_UtilityResult(traceContext, observation.type, result);
	return result;
}

PlayerStatsUtilityApplyResult Input_UtilityZombieIgnited(Event event, StatsTraceContext traceContext)
{
	StatsUtilityRecord observation;
	Input_ReadUtilityAction(event, PlayerStatsUtilityAction_ZombieIgnited, observation);
	PlayerStatsUtilityApplyResult result = Utility_ApplyAction(observation);
	Trace_UtilityResult(traceContext, observation.type, result);
	return result;
}

void Input_ReadUtilityAction(Event event, PlayerStatsUtilityActionType type, StatsUtilityRecord observation)
{
	observation.type = type;
	observation.userid = 0;
	observation.client = 0;
	observation.validPayload = false;
	observation.byBoomer = false;
	observation.fireAmmo = false;

	if (event == null)
	{
		return;
	}

	switch (type)
	{
		case PlayerStatsUtilityAction_PlayerNowIt:
		{
			observation.byBoomer = event.GetBool("by_boomer");
			observation.userid = event.GetInt("attacker");
		}
		case PlayerStatsUtilityAction_VomitBombTank:
		{
			observation.userid = event.GetInt("userid");
		}
		case PlayerStatsUtilityAction_ZombieIgnited:
		{
			observation.fireAmmo = event.GetBool("fire_ammo");
			observation.userid = event.GetInt("userid");
		}
		default:
		{
			return;
		}
	}

	observation.validPayload = observation.userid > 0;
	if (observation.validPayload)
	{
		observation.client = GetClientOfUserId(observation.userid);
	}
}
