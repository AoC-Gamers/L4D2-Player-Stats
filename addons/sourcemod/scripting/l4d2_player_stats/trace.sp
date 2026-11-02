#if defined _l4d2_player_stats_trace_included
	#endinput
#endif
#define _l4d2_player_stats_trace_included

enum struct StatsLifecycleTraceSnapshot
{
	int roundId;
	bool active;
	bool live;
	PlayerStatsRoundEndReasonType endReason;
	bool scavengeOvertime;
	bool scavengeScoreTied;
	int matchEndedRoundId;
	PlayerStatsRoundEndReasonType matchEndReason;
}

enum struct StatsRuntimeTraceSnapshot
{
	int roundId;
	bool roundActive;
	bool roundLive;
	PlayerStatsRoundEndReasonType endReason;
	int baseMode;
	int versusContext;
	int seriesScope;
	int policy;
	int libraries;
	int survivorLimit;
	int playerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
}

enum StatsApiTraceKind
{
	StatsApiTrace_IsRoundActive = 0,
	StatsApiTrace_IsRoundLive,
	StatsApiTrace_GetRoundId,
	StatsApiTrace_IsRoundPlayerSlotValid,
	StatsApiTrace_GetRoundPlayerClient,
	StatsApiTrace_GetCurrentModeProperty,
	StatsApiTrace_FillRoundKeyValues,
	StatsApiTrace_FillRoundPlayerKeyValues,
	StatsApiTrace_ApplySubstitutionSnapshot,
	StatsApiTrace_BroadcastRoundStats,
	StatsApiTrace_Count
}

enum StatsCommandTraceKind
{
	StatsCommandTrace_MVP = 0,
	StatsCommandTrace_Rank,
	StatsCommandTrace_Acc,
	StatsCommandTrace_Utils,
	StatsCommandTrace_Items,
	StatsCommandTrace_Support,
	StatsCommandTrace_Scavenge,
	StatsCommandTrace_Help,
	StatsCommandTrace_Infect,
	StatsCommandTrace_Tank,
	StatsCommandTrace_Count
}

StatsTraceState g_Trace;
int g_iWeaponFireTraceMapGeneration = -1;
int g_iWeaponFireTraceOrdinal;
int g_iDamageSerial;
int g_iApiTraceMapGeneration = -1;
int g_iApiTraceOrdinals[StatsApiTrace_Count];
int g_iCommandTraceMapGeneration = -1;
int g_iCommandTraceOrdinals[StatsCommandTrace_Count];
int g_iDetectEventTraceMapGeneration = -1;
int g_iDetectEventTraceOrdinals[4];

enum StatsDetectEventTraceKind
{
	StatsDetectEventTrace_PlayerHurt = 0,
	StatsDetectEventTrace_PlayerDeath,
	StatsDetectEventTrace_PlayerIncapacitatedStart,
	StatsDetectEventTrace_InfectedDeath
}

enum StatsSdkDamageCaptureStatus
{
	StatsSdkDamageCapture_NotEvaluated = 0,
	StatsSdkDamageCapture_TrackingDisabled,
	StatsSdkDamageCapture_RoundNotLive,
	StatsSdkDamageCapture_WrongMode,
	StatsSdkDamageCapture_RoundClosing,
	StatsSdkDamageCapture_InvalidVictim,
	StatsSdkDamageCapture_InvalidAttacker,
	StatsSdkDamageCapture_VictimIncapacitated,
	StatsSdkDamageCapture_InvalidUserid,
	StatsSdkDamageCapture_NotTerminalDamage,
	StatsSdkDamageCapture_SessionCapacity,
	StatsSdkDamageCapture_ControllerCapacity,
	StatsSdkDamageCapture_Reconciled,
	StatsSdkDamageCapture_AmbiguousReceipt,
	StatsSdkDamageCapture_IdentityMismatch,
	StatsSdkDamageCapture_Collision,
	StatsSdkDamageCapture_OperationCapacity,
	StatsSdkDamageCapture_CapturedPending
}

enum StatsSdkDamageOperationState
{
	StatsSdkDamageOperation_Empty = 0,
	StatsSdkDamageOperation_Pending,
	StatsSdkDamageOperation_Applied,
	StatsSdkDamageOperation_Ambiguous
}

enum struct StatsSdkDamageCaptureResult
{
	StatsSdkDamageCaptureStatus status;
	StatsSdkDamageOperationState operationState;
	int operationIndex;
	int damageId;
	int healthBefore;
	bool hasHealthBefore;

	void Reset()
	{
		this.status = StatsSdkDamageCapture_NotEvaluated;
		this.operationState = StatsSdkDamageOperation_Empty;
		this.operationIndex = -1;
		this.damageId = 0;
		this.healthBefore = 0;
		this.hasHealthBefore = false;
	}
}

int g_iSdkDamageTraceMapGeneration = -1;
int g_iSdkDamageTraceOrdinal;
int g_iTankResolutionTraceMapGeneration = -1;
int g_iTankResolutionTraceOrdinals[3];

bool Trace_ShouldSampleTankResolution(StatsTraceContext context, const char[] source, int &index)
{
	if (g_iTankResolutionTraceMapGeneration != context.mapGeneration)
	{
		g_iTankResolutionTraceMapGeneration = context.mapGeneration;
		for (int i = 0; i < sizeof(g_iTankResolutionTraceOrdinals); i++)
		{
			g_iTankResolutionTraceOrdinals[i] = 0;
		}
	}

	if (StrEqual(source, "player_hurt"))
	{
		index = 0;
	}
	else if (StrEqual(source, "player_incapacitated_start"))
	{
		index = 1;
	}
	else if (StrEqual(source, "player_death"))
	{
		index = 2;
	}
	else
	{
		return false;
	}

	g_iTankResolutionTraceOrdinals[index]++;
	int ordinal = g_iTankResolutionTraceOrdinals[index];
	return ordinal <= 16 || (ordinal - 16) % 128 == 0;
}

void Trace_TankDamageResolution(StatsTraceContext context, const char[] source, PlayerStatsTankDamageResolveResult result, int damageId)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	bool significant = result != PlayerStatsTankDamageResolve_None;
	int sampleIndex;
	if (!significant && !Trace_ShouldSampleTankResolution(context, source, sampleIndex))
	{
		return;
	}

	char reason[32];
	switch (result)
	{
		case PlayerStatsTankDamageResolve_Ready: strcopy(reason, sizeof(reason), "applied");
		case PlayerStatsTankDamageResolve_AlreadyApplied: strcopy(reason, sizeof(reason), "already_applied");
		case PlayerStatsTankDamageResolve_Ambiguous: strcopy(reason, sizeof(reason), "ambiguous");
		case PlayerStatsTankDamageResolve_Stale: strcopy(reason, sizeof(reason), "stale");
		case PlayerStatsTankDamageResolve_ReconciledLateCapture: strcopy(reason, sizeof(reason), "reconciled_late_capture");
		default: strcopy(reason, sizeof(reason), "no_operation");
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=%s stage=resolve consumer=tank reason=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		damageId,
		source,
		reason);
}

bool Trace_ShouldSampleSdkDamage(StatsTraceContext context)
{
	if (g_iSdkDamageTraceMapGeneration != context.mapGeneration)
	{
		g_iSdkDamageTraceMapGeneration = context.mapGeneration;
		g_iSdkDamageTraceOrdinal = 0;
	}

	g_iSdkDamageTraceOrdinal++;
	return g_iSdkDamageTraceOrdinal <= 16 || (g_iSdkDamageTraceOrdinal - 16) % 128 == 0;
}

void Trace_SdkDamageCaptureResult(StatsTraceContext context, StatsSdkDamageCaptureResult result, float sdkDamage)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}
	bool significant = result.status >= StatsSdkDamageCapture_SessionCapacity;
	if (!significant && !Trace_ShouldSampleSdkDamage(context))
	{
		return;
	}

	char reason[32];
	Trace_GetSdkDamageCaptureReason(result.status, reason, sizeof(reason));
	char state[16];
	Trace_GetSdkDamageOperationState(result.operationState, state, sizeof(state));
	char health[16];
	if (result.hasHealthBefore)
	{
		IntToString(result.healthBefore, health, sizeof(health));
	}
	else
	{
		strcopy(health, sizeof(health), "na");
	}

	int damageId = result.damageId > 0 ? result.damageId : context.damageId;
	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=sdk_on_take_damage stage=capture consumer=tank reason=%s sdk_damage=%.1f health_before=%s operation=%d state=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		damageId,
		reason,
		sdkDamage,
		health,
		result.operationIndex,
		state);
}

void Trace_GetSdkDamageCaptureReason(StatsSdkDamageCaptureStatus status, char[] buffer, int maxlen)
{
	switch (status)
	{
		case StatsSdkDamageCapture_TrackingDisabled: strcopy(buffer, maxlen, "tracking_disabled");
		case StatsSdkDamageCapture_RoundNotLive: strcopy(buffer, maxlen, "round_not_live");
		case StatsSdkDamageCapture_WrongMode: strcopy(buffer, maxlen, "wrong_mode");
		case StatsSdkDamageCapture_RoundClosing: strcopy(buffer, maxlen, "round_closing");
		case StatsSdkDamageCapture_InvalidVictim: strcopy(buffer, maxlen, "invalid_victim");
		case StatsSdkDamageCapture_InvalidAttacker: strcopy(buffer, maxlen, "invalid_attacker");
		case StatsSdkDamageCapture_VictimIncapacitated: strcopy(buffer, maxlen, "victim_incapacitated");
		case StatsSdkDamageCapture_InvalidUserid: strcopy(buffer, maxlen, "invalid_userid");
		case StatsSdkDamageCapture_NotTerminalDamage: strcopy(buffer, maxlen, "not_terminal_damage");
		case StatsSdkDamageCapture_SessionCapacity: strcopy(buffer, maxlen, "session_capacity");
		case StatsSdkDamageCapture_ControllerCapacity: strcopy(buffer, maxlen, "controller_capacity");
		case StatsSdkDamageCapture_Reconciled: strcopy(buffer, maxlen, "late_sdk_reconciled");
		case StatsSdkDamageCapture_AmbiguousReceipt: strcopy(buffer, maxlen, "hurt_ambiguous");
		case StatsSdkDamageCapture_IdentityMismatch: strcopy(buffer, maxlen, "hurt_identity_mismatch");
		case StatsSdkDamageCapture_Collision: strcopy(buffer, maxlen, "same_victim_tick_collision");
		case StatsSdkDamageCapture_OperationCapacity: strcopy(buffer, maxlen, "operation_capacity");
		case StatsSdkDamageCapture_CapturedPending: strcopy(buffer, maxlen, "terminal_candidate_captured");
		default: strcopy(buffer, maxlen, "not_evaluated");
	}
}

void Trace_GetSdkDamageOperationState(StatsSdkDamageOperationState state, char[] buffer, int maxlen)
{
	switch (state)
	{
		case StatsSdkDamageOperation_Pending: strcopy(buffer, maxlen, "pending");
		case StatsSdkDamageOperation_Applied: strcopy(buffer, maxlen, "applied");
		case StatsSdkDamageOperation_Ambiguous: strcopy(buffer, maxlen, "ambiguous");
		default: strcopy(buffer, maxlen, "empty");
	}
}

bool Trace_ShouldSampleDetectEvent(StatsTraceContext context, const char[] source)
{
	if (g_iDetectEventTraceMapGeneration != context.mapGeneration)
	{
		g_iDetectEventTraceMapGeneration = context.mapGeneration;
		for (int i = 0; i < sizeof(g_iDetectEventTraceOrdinals); i++)
		{
			g_iDetectEventTraceOrdinals[i] = 0;
		}
	}

	StatsDetectEventTraceKind kind;
	if (StrEqual(source, "player_hurt"))
	{
		kind = StatsDetectEventTrace_PlayerHurt;
	}
	else if (StrEqual(source, "player_death"))
	{
		kind = StatsDetectEventTrace_PlayerDeath;
	}
	else if (StrEqual(source, "player_incapacitated_start"))
	{
		kind = StatsDetectEventTrace_PlayerIncapacitatedStart;
	}
	else
	{
		kind = StatsDetectEventTrace_InfectedDeath;
	}

	int index = view_as<int>(kind);
	g_iDetectEventTraceOrdinals[index]++;
	int ordinal = g_iDetectEventTraceOrdinals[index];
	return ordinal <= 16 || (ordinal - 16) % 128 == 0;
}

bool Trace_ShouldSampleApi(StatsTraceContext context, StatsApiTraceKind kind)
{
	if (g_iApiTraceMapGeneration != context.mapGeneration)
	{
		g_iApiTraceMapGeneration = context.mapGeneration;
		for (int i = 0; i < view_as<int>(StatsApiTrace_Count); i++)
		{
			g_iApiTraceOrdinals[i] = 0;
		}
	}

	int index = view_as<int>(kind);
	if (index < 0 || index >= view_as<int>(StatsApiTrace_Count))
	{
		return false;
	}

	g_iApiTraceOrdinals[index]++;
	int ordinal = g_iApiTraceOrdinals[index];
	return ordinal <= 8 || (ordinal - 8) % 128 == 0;
}

bool Trace_ShouldSampleCommand(StatsTraceContext context, StatsCommandTraceKind kind)
{
	if (g_iCommandTraceMapGeneration != context.mapGeneration)
	{
		g_iCommandTraceMapGeneration = context.mapGeneration;
		for (int i = 0; i < view_as<int>(StatsCommandTrace_Count); i++)
		{
			g_iCommandTraceOrdinals[i] = 0;
		}
	}

	int index = view_as<int>(kind);
	if (index < 0 || index >= view_as<int>(StatsCommandTrace_Count))
	{
		return false;
	}

	g_iCommandTraceOrdinals[index]++;
	int ordinal = g_iCommandTraceOrdinals[index];
	return ordinal <= 8 || (ordinal - 8) % 128 == 0;
}

void Trace_ApiResult(StatsTraceContext context, const char[] source, const char[] outcome, StatsApiTraceKind kind, bool sampled)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Api) || (sampled && !Trace_ShouldSampleApi(context, kind)))
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Api,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=call consumer=api reason=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		outcome);
}

void Trace_CommandResult(StatsTraceContext context, const char[] source, StatsCommandTraceKind kind, Action result)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Announce) || !Trace_ShouldSampleCommand(context, kind))
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Announce,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=dispatch consumer=announce reason=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		result == Plugin_Handled ? "handled" : "unexpected_result");
}

bool Trace_ShouldSampleWeaponFire(StatsTraceContext context)
{
	if (g_iWeaponFireTraceMapGeneration != context.mapGeneration)
	{
		g_iWeaponFireTraceMapGeneration = context.mapGeneration;
		g_iWeaponFireTraceOrdinal = 0;
	}

	g_iWeaponFireTraceOrdinal++;
	return g_iWeaponFireTraceOrdinal <= 16 || (g_iWeaponFireTraceOrdinal - 16) % 128 == 0;
}

void Trace_Init()
{
	g_Trace.runId = GetURandomInt();
	if (g_Trace.runId == 0)
	{
		g_Trace.runId = 1;
	}

	g_Trace.mapGeneration = 0;
	g_Trace.signalSerial = 0;
	g_iDamageSerial = 0;
}

void Trace_AdvanceMapGeneration()
{
	g_Trace.mapGeneration++;
	if (g_Trace.mapGeneration <= 0)
	{
		g_Trace.mapGeneration = 1;
	}
}

StatsTraceContext Trace_BeginSignal()
{
	g_Trace.signalSerial++;
	if (g_Trace.signalSerial <= 0)
	{
		g_Trace.signalSerial = 1;
	}

	StatsTraceContext context;
	context.runId = g_Trace.runId;
	context.mapGeneration = g_Trace.mapGeneration;
	context.roundId = g_Round.meta.id;
	context.signalId = g_Trace.signalSerial;
	context.damageId = 0;
	return context;
}

int Trace_NextDamageId()
{
	g_iDamageSerial++;
	if (g_iDamageSerial <= 0)
	{
		g_iDamageSerial = 1;
	}
	return g_iDamageSerial;
}

void Trace_CaptureLifecycleSnapshot(StatsLifecycleTraceSnapshot snapshot)
{
	snapshot.roundId = g_Round.meta.id;
	snapshot.active = g_Round.meta.active;
	snapshot.live = g_Runtime.roundLive;
	snapshot.endReason = g_Round.meta.endReason;
	snapshot.scavengeOvertime = g_Round.meta.scavengeWentOvertime;
	snapshot.scavengeScoreTied = g_Round.meta.scavengeScoreTied;
	snapshot.matchEndedRoundId = g_Runtime.lastMatchEndedRoundId;
	snapshot.matchEndReason = g_Runtime.lastMatchEndReason;
}

void Trace_LifecycleResult(StatsTraceContext context, const char[] source, StatsLifecycleTraceSnapshot before)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	bool changed = before.roundId != g_Round.meta.id
		|| before.active != g_Round.meta.active
		|| before.live != g_Runtime.roundLive
		|| before.endReason != g_Round.meta.endReason
		|| before.scavengeOvertime != g_Round.meta.scavengeWentOvertime
		|| before.scavengeScoreTied != g_Round.meta.scavengeScoreTied
		|| before.matchEndedRoundId != g_Runtime.lastMatchEndedRoundId
		|| before.matchEndReason != g_Runtime.lastMatchEndReason;

	char reason[24];
	strcopy(reason, sizeof(reason), changed ? "state_changed" : "no_state_change");
	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=result consumer=round reason=%s pre=%d,%d,%d post=%d,%d,%d,%d match=%d:%d>%d:%d scav=%d%d>%d%d",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		reason,
		before.active,
		before.live,
		before.endReason,
		g_Round.meta.id,
		g_Round.meta.active,
		g_Runtime.roundLive,
		g_Round.meta.endReason,
		before.matchEndedRoundId,
		before.matchEndReason,
		g_Runtime.lastMatchEndedRoundId,
		g_Runtime.lastMatchEndReason,
		before.scavengeOvertime,
		before.scavengeScoreTied,
		g_Round.meta.scavengeWentOvertime,
		g_Round.meta.scavengeScoreTied);
}

void Trace_CaptureRuntimeSnapshot(StatsRuntimeTraceSnapshot snapshot)
{
	snapshot.roundId = g_Round.meta.id;
	snapshot.roundActive = g_Round.meta.active;
	snapshot.roundLive = g_Runtime.roundLive;
	snapshot.endReason = g_Round.meta.endReason;
	snapshot.baseMode = g_Runtime.baseMode;
	snapshot.versusContext = g_Runtime.versusContext;
	snapshot.seriesScope = g_Runtime.seriesScope;
	snapshot.policy = view_as<int>(g_Runtime.roundStartSignal)
		| (view_as<int>(g_Runtime.roundEndSignal) << 4)
		| (view_as<int>(g_Runtime.roundLiveSignal) << 8)
		| (view_as<int>(g_Runtime.restartPolicy) << 12);
	snapshot.libraries = (g_Runtime.hasLeft4DHooks ? 1 : 0)
		| (g_Runtime.hasReadyUp ? 2 : 0)
		| (g_Runtime.hasConfogl ? 4 : 0)
		| (g_Runtime.hasPlayerSkills ? 8 : 0)
		| (g_Runtime.hasBossPercents ? 16 : 0);
	snapshot.survivorLimit = g_Runtime.configuredSurvivorLimit;
	snapshot.playerZombieLimit = g_Runtime.configuredPlayerZombieLimit;
	snapshot.siPoolMask = g_Runtime.siPoolMask;
	snapshot.enabledSiClassCount = g_Runtime.enabledSiClassCount;
}

void Trace_RuntimeLifecycleResult(StatsTraceContext context, const char[] source, StatsRuntimeTraceSnapshot before)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	StatsRuntimeTraceSnapshot after;
	Trace_CaptureRuntimeSnapshot(after);
	bool roundChanged = before.roundId != after.roundId
		|| before.roundActive != after.roundActive
		|| before.roundLive != after.roundLive
		|| before.endReason != after.endReason;
	bool modeChanged = before.baseMode != after.baseMode
		|| before.versusContext != after.versusContext
		|| before.seriesScope != after.seriesScope;
	bool configChanged = before.policy != after.policy
		|| before.libraries != after.libraries
		|| before.survivorLimit != after.survivorLimit
		|| before.playerZombieLimit != after.playerZombieLimit
		|| before.siPoolMask != after.siPoolMask
		|| before.enabledSiClassCount != after.enabledSiClassCount;
	bool changed = roundChanged || modeChanged || configChanged;

	char reason[24];
	strcopy(reason, sizeof(reason), changed ? "state_changed" : "no_state_change");
	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=result consumer=runtime reason=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		reason);

	if (!changed)
	{
		return;
	}

	if (roundChanged)
	{
		Stats_Debug(PlayerStatsDebug_Detect,
			"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=state consumer=runtime reason=state_changed rid=%d>%d state=%d/%d/%d>%d/%d/%d",
			context.runId,
			context.mapGeneration,
			context.roundId,
			context.signalId,
			source,
			before.roundId,
			after.roundId,
			before.roundActive,
			before.roundLive,
			before.endReason,
			after.roundActive,
			after.roundLive,
			after.endReason);
	}
	if (modeChanged)
	{
		Stats_Debug(PlayerStatsDebug_Detect,
			"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=mode consumer=runtime reason=state_changed mode=%d/%d/%d>%d/%d/%d",
			context.runId,
			context.mapGeneration,
			context.roundId,
			context.signalId,
			source,
			before.baseMode,
			before.versusContext,
			before.seriesScope,
			after.baseMode,
			after.versusContext,
			after.seriesScope);
	}
	if (configChanged)
	{
		Stats_Debug(PlayerStatsDebug_Detect,
			"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=policy consumer=runtime reason=state_changed pol=%x>%x lib=%x>%x",
			context.runId,
			context.mapGeneration,
			context.roundId,
			context.signalId,
			source,
			before.policy,
			after.policy,
			before.libraries,
			after.libraries);
		Stats_Debug(PlayerStatsDebug_Detect,
			"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=limits consumer=runtime reason=state_changed cfg=%d/%d/%x/%d>%d/%d/%x/%d",
			context.runId,
			context.mapGeneration,
			context.roundId,
			context.signalId,
			source,
			before.survivorLimit,
			before.playerZombieLimit,
			before.siPoolMask,
			before.enabledSiClassCount,
			after.survivorLimit,
			after.playerZombieLimit,
			after.siPoolMask,
			after.enabledSiClassCount);
	}
}

void Trace_ClientBindingResult(StatsTraceContext context, const char[] source, int client, int userid, int teamBefore, int teamAfter, int slotBefore, int slotAfter)
{
	char reason[24];
	strcopy(reason, sizeof(reason), teamBefore != teamAfter || slotBefore != slotAfter ? "state_changed" : "no_state_change");
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=identity consumer=players reason=%s client=%d userid=%d team=%d>%d slot=%d>%d",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		reason,
		client,
		userid,
		teamBefore,
		teamAfter,
		slotBefore,
		slotAfter);
}

void Trace_SubstitutionBoundary(StatsTraceContext context, const char[] source, int roundBefore, int roundAfter,
	int sourceClient, int sourceUserid, int targetClient, int targetUserid,
	int sourceSlotBefore, int targetSlotBefore, int sourceSlotAfter, int targetSlotAfter)
{
	bool changed = roundBefore != roundAfter
		|| sourceSlotBefore != sourceSlotAfter
		|| targetSlotBefore != targetSlotAfter;
	char reason[24];
	strcopy(reason, sizeof(reason), changed ? "state_changed" : "no_state_change");

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=0 source=%s stage=identity consumer=substitution reason=%s round=%d>%d from=%d:%d slot=%d>%d to=%d:%d slot=%d>%d",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		source,
		reason,
		roundBefore,
		roundAfter,
		sourceClient,
		sourceUserid,
		sourceSlotBefore,
		sourceSlotAfter,
		targetClient,
		targetUserid,
		targetSlotBefore,
		targetSlotAfter);
}

stock bool Stats_IsDebugEnabled(PlayerStatsDebugCategory category)
{
	if (g_cvDebug == null)
	{
		return false;
	}

	int mask = g_cvDebug.IntValue;
	return (mask & view_as<int>(category)) != 0;
}

stock void Stats_Debug(PlayerStatsDebugCategory category, const char[] fmt, any...)
{
	if (!Stats_IsDebugEnabled(category))
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
	LogToFileEx(g_sDebugLogPath, "tick=%d %s", GetGameTickCount(), buffer);
}

void Trace_ScavengeResult(StatsTraceContext context, PlayerStatsScavengeObjectiveType type, PlayerStatsScavengeApplyResult result)
{
	char source[32];
	switch (type)
	{
		case PlayerStatsScavengeObjective_Poured: strcopy(source, sizeof(source), "gascan_pour_completed");
		case PlayerStatsScavengeObjective_Dropped: strcopy(source, sizeof(source), "gascan_dropped");
		case PlayerStatsScavengeObjective_Destroyed: strcopy(source, sizeof(source), "scavenge_gascan_destroyed");
		default: strcopy(source, sizeof(source), "scavenge_unknown");
	}

	char reason[32];
	switch (result)
	{
		case PlayerStatsScavengeApply_Applied: strcopy(reason, sizeof(reason), "applied");
		case PlayerStatsScavengeApply_InvalidPayload: strcopy(reason, sizeof(reason), "invalid_payload");
		case PlayerStatsScavengeApply_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case PlayerStatsScavengeApply_TrackingDisabled: strcopy(reason, sizeof(reason), "tracking_disabled");
		case PlayerStatsScavengeApply_WrongMode: strcopy(reason, sizeof(reason), "wrong_mode");
		case PlayerStatsScavengeApply_InvalidActor: strcopy(reason, sizeof(reason), "invalid_actor");
		case PlayerStatsScavengeApply_NoSlot: strcopy(reason, sizeof(reason), "no_slot");
		default: strcopy(reason, sizeof(reason), "unknown");
	}

	Trace_Result(context, source, "apply", "scavenge", reason);
}

void Trace_UtilityResult(StatsTraceContext context, PlayerStatsUtilityActionType type, PlayerStatsUtilityApplyResult result)
{
	if (type == PlayerStatsUtilityAction_ZombieIgnited && result == PlayerStatsUtilityApply_Applied)
	{
		return;
	}

	char source[24];
	switch (type)
	{
		case PlayerStatsUtilityAction_PlayerNowIt: strcopy(source, sizeof(source), "player_now_it");
		case PlayerStatsUtilityAction_VomitBombTank: strcopy(source, sizeof(source), "vomit_bomb_tank");
		case PlayerStatsUtilityAction_ZombieIgnited: strcopy(source, sizeof(source), "zombie_ignited");
		default: strcopy(source, sizeof(source), "utility_unknown");
	}

	char reason[32];
	switch (result)
	{
		case PlayerStatsUtilityApply_Applied: strcopy(reason, sizeof(reason), "applied");
		case PlayerStatsUtilityApply_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case PlayerStatsUtilityApply_ThrowablesDisabled: strcopy(reason, sizeof(reason), "throwables_disabled");
		case PlayerStatsUtilityApply_BoomerAttributed: strcopy(reason, sizeof(reason), "boomer_attributed");
		case PlayerStatsUtilityApply_FireAmmo: strcopy(reason, sizeof(reason), "fire_ammo");
		case PlayerStatsUtilityApply_InvalidPayload: strcopy(reason, sizeof(reason), "invalid_payload");
		case PlayerStatsUtilityApply_InvalidActor: strcopy(reason, sizeof(reason), "invalid_actor");
		case PlayerStatsUtilityApply_NoSlot: strcopy(reason, sizeof(reason), "no_slot");
		case PlayerStatsUtilityApply_NoMolotovRecorded: strcopy(reason, sizeof(reason), "no_molotov_recorded");
		case PlayerStatsUtilityApply_InvalidObservation: strcopy(reason, sizeof(reason), "invalid_observation");
		default: strcopy(reason, sizeof(reason), "unknown");
	}

	Trace_Result(context, source, "apply", "utility", reason);
}

void Trace_WitchResult(StatsTraceContext context, int entity, StatsWitchHurtResult result)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect)
		|| result.resolution == PlayerStatsWitchHurt_NotWitch
		|| !IsWitchEntity(entity))
	{
		return;
	}

	char reason[32];
	switch (result.resolution)
	{
		case PlayerStatsWitchHurt_Ready:
		{
			switch (result.combat)
			{
				case PlayerStatsWitchCombat_Applied: strcopy(reason, sizeof(reason), "applied");
				case PlayerStatsWitchCombat_TrackingDisabled: strcopy(reason, sizeof(reason), "tracking_disabled");
				case PlayerStatsWitchCombat_InvalidRecord: strcopy(reason, sizeof(reason), "invalid_record");
				default: strcopy(reason, sizeof(reason), "not_applied");
			}
		}
		case PlayerStatsWitchHurt_InvalidPayload: strcopy(reason, sizeof(reason), "invalid_payload");
		case PlayerStatsWitchHurt_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case PlayerStatsWitchHurt_FeaturesDisabled: strcopy(reason, sizeof(reason), "features_disabled");
		case PlayerStatsWitchHurt_InvalidDamage: strcopy(reason, sizeof(reason), "invalid_damage");
		case PlayerStatsWitchHurt_InvalidAttacker: strcopy(reason, sizeof(reason), "invalid_attacker");
		case PlayerStatsWitchHurt_NoSlot: strcopy(reason, sizeof(reason), "no_slot");
		default: strcopy(reason, sizeof(reason), "unknown");
	}

	Trace_Result(context, "infected_hurt", "resolve_apply", "witch", reason);
}

void Trace_SkillsImportResult(StatsTraceContext context, PlayerStatsSkillsStreamType stream, int externalId, int type, StatsSkillsImportResult result)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	char source[32];
	switch (stream)
	{
		case PlayerStatsSkillsStream_SkillEvent: strcopy(source, sizeof(source), "player_skills_skill");
		case PlayerStatsSkillsStream_KillEvent: strcopy(source, sizeof(source), "player_skills_kill");
		case PlayerStatsSkillsStream_BossEvent: strcopy(source, sizeof(source), "player_skills_boss_event");
		case PlayerStatsSkillsStream_BossSession: strcopy(source, sizeof(source), "player_skills_boss_session");
		default: strcopy(source, sizeof(source), "player_skills_unknown");
	}

	char reason[32];
	switch (result.reason)
	{
		case PlayerStatsSkillsReject_None: strcopy(reason, sizeof(reason), "accepted");
		case PlayerStatsSkillsReject_NotApplicable: strcopy(reason, sizeof(reason), "not_applicable");
		case PlayerStatsSkillsReject_TrackingDisabled: strcopy(reason, sizeof(reason), "tracking_disabled");
		case PlayerStatsSkillsReject_LibraryUnavailable: strcopy(reason, sizeof(reason), "library_unavailable");
		case PlayerStatsSkillsReject_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case PlayerStatsSkillsReject_NativeUnavailable: strcopy(reason, sizeof(reason), "native_unavailable");
		case PlayerStatsSkillsReject_InvalidId: strcopy(reason, sizeof(reason), "invalid_id");
		case PlayerStatsSkillsReject_InvalidEvent: strcopy(reason, sizeof(reason), "invalid_event");
		case PlayerStatsSkillsReject_KeyValuesAllocation: strcopy(reason, sizeof(reason), "keyvalues_allocation");
		case PlayerStatsSkillsReject_FillFailed: strcopy(reason, sizeof(reason), "fill_failed");
		case PlayerStatsSkillsReject_RootMissing: strcopy(reason, sizeof(reason), "root_missing");
		case PlayerStatsSkillsReject_TooManyEntries: strcopy(reason, sizeof(reason), "too_many_entries");
		case PlayerStatsSkillsReject_InvalidActor: strcopy(reason, sizeof(reason), "invalid_actor");
		case PlayerStatsSkillsReject_NoActorSlot: strcopy(reason, sizeof(reason), "no_actor_slot");
		case PlayerStatsSkillsReject_InvalidRecord: strcopy(reason, sizeof(reason), "invalid_record");
		case PlayerStatsSkillsReject_Duplicate: strcopy(reason, sizeof(reason), "duplicate");
		case PlayerStatsSkillsReject_LedgerOverflow: strcopy(reason, sizeof(reason), "ledger_overflow");
		default: strcopy(reason, sizeof(reason), "unknown");
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=%s stage=import consumer=skills_import reason=%s id=%d type=%d actor_applied=%d slot=%d assists=%d entries=%d damage_total=%d shots=%d",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		context.damageId,
		source,
		reason,
		externalId,
		type,
		result.actorApplied,
		result.actorSlot,
		result.assistCount,
		result.entryCount,
		result.totalDamage,
		result.totalShots);
}

void Trace_ControlResult(StatsTraceContext context, PlayerStatsControlType type, PlayerStatsControlApplyResult result)
{
	char source[32];
	switch (type)
	{
		case PlayerStatsControl_TongueGrab: strcopy(source, sizeof(source), "tongue_grab_post");
		case PlayerStatsControl_HunterPounce: strcopy(source, sizeof(source), "hunter_pounce_post");
		case PlayerStatsControl_JockeyRide: strcopy(source, sizeof(source), "jockey_ride_post");
		case PlayerStatsControl_BoomerVomit: strcopy(source, sizeof(source), "vomited_upon_post");
		default: strcopy(source, sizeof(source), "infected_control_unknown");
	}

	char reason[32];
	switch (result)
	{
		case PlayerStatsControlApply_Applied: strcopy(reason, sizeof(reason), "applied");
		case PlayerStatsControlApply_BoomerExplosion: strcopy(reason, sizeof(reason), "boomer_explosion");
		case PlayerStatsControlApply_TrackingDisabled: strcopy(reason, sizeof(reason), "tracking_disabled");
		case PlayerStatsControlApply_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case PlayerStatsControlApply_InvalidVictim: strcopy(reason, sizeof(reason), "invalid_victim");
		case PlayerStatsControlApply_InvalidAttacker: strcopy(reason, sizeof(reason), "invalid_attacker");
		case PlayerStatsControlApply_NoSlot: strcopy(reason, sizeof(reason), "no_slot");
		case PlayerStatsControlApply_InvalidObservation: strcopy(reason, sizeof(reason), "invalid_observation");
		default: strcopy(reason, sizeof(reason), "unknown");
	}

	Trace_Result(context, source, "apply", "infected_control", reason);
}

void Trace_WeaponFireResult(StatsTraceContext context, StatsWeaponFireResult result)
{
	bool sampled = Trace_ShouldSampleWeaponFire(context);
	if (!sampled || !Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	char route[32];
	switch (result.route)
	{
		case PlayerStatsShotRoute_ReadyForUtility: strcopy(route, sizeof(route), "ready_for_utility");
		case PlayerStatsShotRoute_RoundNotLive: strcopy(route, sizeof(route), "round_not_live");
		case PlayerStatsShotRoute_FeaturesDisabled: strcopy(route, sizeof(route), "features_disabled");
		case PlayerStatsShotRoute_InvalidPayload: strcopy(route, sizeof(route), "invalid_payload");
		case PlayerStatsShotRoute_InvalidActor: strcopy(route, sizeof(route), "invalid_actor");
		case PlayerStatsShotRoute_EmptyWeapon: strcopy(route, sizeof(route), "empty_weapon");
		case PlayerStatsShotRoute_NoSlot: strcopy(route, sizeof(route), "no_slot");
		default: strcopy(route, sizeof(route), "unknown");
	}

	char throwable[32];
	switch (result.throwable)
	{
		case PlayerStatsUtilityThrow_NotEvaluated: strcopy(throwable, sizeof(throwable), "not_evaluated");
		case PlayerStatsUtilityThrow_Disabled: strcopy(throwable, sizeof(throwable), "disabled");
		case PlayerStatsUtilityThrow_InvalidSlot: strcopy(throwable, sizeof(throwable), "invalid_slot");
		case PlayerStatsUtilityThrow_NotThrowable: strcopy(throwable, sizeof(throwable), "not_throwable");
		case PlayerStatsUtilityThrow_MolotovApplied: strcopy(throwable, sizeof(throwable), "molotov_applied");
		case PlayerStatsUtilityThrow_PipeBombApplied: strcopy(throwable, sizeof(throwable), "pipebomb_applied");
		case PlayerStatsUtilityThrow_VomitjarApplied: strcopy(throwable, sizeof(throwable), "vomitjar_applied");
		default: strcopy(throwable, sizeof(throwable), "unknown");
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=weapon_fire stage=resolve_apply consumer=accuracy_utility route=%s throwable=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		context.damageId,
		route,
		throwable);
}

void Trace_SurvivorActionResult(StatsTraceContext context, PlayerStatsSurvivorActionType type, PlayerStatsSurvivorApplyStatus status, StatsSurvivorActionResult result)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	char source[32];
	switch (type)
	{
		case PlayerStatsSurvivorAction_PillsUsed: strcopy(source, sizeof(source), "pills_used");
		case PlayerStatsSurvivorAction_AdrenalineUsed: strcopy(source, sizeof(source), "adrenaline_used");
		case PlayerStatsSurvivorAction_HealSuccess: strcopy(source, sizeof(source), "heal_success");
		case PlayerStatsSurvivorAction_DefibrillatorUsed: strcopy(source, sizeof(source), "defibrillator_used");
		case PlayerStatsSurvivorAction_ReviveSuccess: strcopy(source, sizeof(source), "revive_success");
		case PlayerStatsSurvivorAction_Rescued: strcopy(source, sizeof(source), "survivor_rescued");
		default: strcopy(source, sizeof(source), "survivor_action_unknown");
	}

	char outcome[16];
	switch (status)
	{
		case PlayerStatsSurvivorApply_Rejected: strcopy(outcome, sizeof(outcome), "rejected");
		case PlayerStatsSurvivorApply_Partial: strcopy(outcome, sizeof(outcome), "partial");
		case PlayerStatsSurvivorApply_Applied: strcopy(outcome, sizeof(outcome), "applied");
		default: strcopy(outcome, sizeof(outcome), "unknown");
	}

	char gateReason[32];
	Trace_GetSurvivorRejectReason(result.gateReason, gateReason, sizeof(gateReason));
	char actorReason[32];
	Trace_GetSurvivorRejectReason(result.actorReason, actorReason, sizeof(actorReason));
	char recipientReason[32];
	Trace_GetSurvivorRejectReason(result.recipientReason, recipientReason, sizeof(recipientReason));

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=%s stage=apply consumer=survivor outcome=%s gate=%s actor=%s recipient=%s actor_applied=%d recipient_applied=%d",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		context.damageId,
		source,
		outcome,
		gateReason,
		actorReason,
		recipientReason,
		result.actorApplied,
		result.recipientApplied);
}

void Trace_GetSurvivorRejectReason(PlayerStatsSurvivorRejectReason reason, char[] buffer, int maxlen)
{
	switch (reason)
	{
		case PlayerStatsSurvivorReject_None: strcopy(buffer, maxlen, "none");
		case PlayerStatsSurvivorReject_NotEvaluated: strcopy(buffer, maxlen, "not_evaluated");
		case PlayerStatsSurvivorReject_InvalidObservation: strcopy(buffer, maxlen, "invalid_observation");
		case PlayerStatsSurvivorReject_RoundNotLive: strcopy(buffer, maxlen, "round_not_live");
		case PlayerStatsSurvivorReject_TrackingDisabled: strcopy(buffer, maxlen, "tracking_disabled");
		case PlayerStatsSurvivorReject_InvalidActorPayload: strcopy(buffer, maxlen, "invalid_actor_payload");
		case PlayerStatsSurvivorReject_InvalidActor: strcopy(buffer, maxlen, "invalid_actor");
		case PlayerStatsSurvivorReject_InvalidRecipientPayload: strcopy(buffer, maxlen, "invalid_recipient_payload");
		case PlayerStatsSurvivorReject_InvalidRecipient: strcopy(buffer, maxlen, "invalid_recipient");
		case PlayerStatsSurvivorReject_ActorNoSlot: strcopy(buffer, maxlen, "actor_no_slot");
		case PlayerStatsSurvivorReject_RecipientNoSlot: strcopy(buffer, maxlen, "recipient_no_slot");
		default: strcopy(buffer, maxlen, "unknown");
	}
}

void Trace_Result(StatsTraceContext context, const char[] source, const char[] stage, const char[] consumer, const char[] reason)
{
	if (!Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"trace run=%d mapgen=%d round=%d signal=%d damage=%d source=%s stage=%s consumer=%s reason=%s",
		context.runId,
		context.mapGeneration,
		context.roundId,
		context.signalId,
		context.damageId,
		source,
		stage,
		consumer,
		reason);
}

void Trace_TankSpawnResult(StatsTraceContext context, StatsTankSpawnResult result)
{
	char reason[32];
	switch (result.type)
	{
		case StatsTankSpawnResult_TrackingDisabled: strcopy(reason, sizeof(reason), "tracking_disabled");
		case StatsTankSpawnResult_RoundNotLive: strcopy(reason, sizeof(reason), "round_not_live");
		case StatsTankSpawnResult_WrongMode: strcopy(reason, sizeof(reason), "wrong_mode");
		case StatsTankSpawnResult_ExistingSession: strcopy(reason, sizeof(reason), "existing_session");
		case StatsTankSpawnResult_NewSession: strcopy(reason, sizeof(reason), "new_session");
		case StatsTankSpawnResult_SessionCapacity: strcopy(reason, sizeof(reason), "session_capacity");
		default: strcopy(reason, sizeof(reason), "not_evaluated");
	}

	Trace_Result(context, "tank_spawn", "adapt", "tank_session", reason);
}

void Trace_EventResult(StatsTraceContext context, const char[] source, const char[] reason)
{
	if (context.signalId <= 0 || !Stats_IsDebugEnabled(PlayerStatsDebug_Detect) || !Trace_ShouldSampleDetectEvent(context, source))
	{
		return;
	}

	Trace_Result(context, source, "result", "detect", reason);
}
