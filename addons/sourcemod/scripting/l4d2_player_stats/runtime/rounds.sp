#if defined _l4d2_player_stats_runtime_rounds_included
	#endinput
#endif
#define _l4d2_player_stats_runtime_rounds_included

int g_iRoundSerial = 0;

enum StatsRoundLifecyclePhase
{
	StatsRoundLifecyclePhase_Idle = 0,
	StatsRoundLifecyclePhase_Open,
	StatsRoundLifecyclePhase_Closing,
	StatsRoundLifecyclePhase_Finalized
}

StatsRoundLifecyclePhase g_RoundLifecyclePhase = StatsRoundLifecyclePhase_Idle;
int g_iPendingMatchEndedRoundId;
int g_iPendingMatchEndedMapGeneration;
PlayerStatsRoundEndReasonType g_PendingMatchEndReason = PlayerStatsRoundEndReason_None;

void Round_StartNewSnapshot(PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	Substitutions_InvalidatePendingTransitions();
	g_Round.Reset();
	g_bRoundClosing = false;
	g_RoundLifecyclePhase = StatsRoundLifecyclePhase_Open;
	g_iPendingMatchEndedRoundId = 0;
	g_iPendingMatchEndedMapGeneration = 0;
	g_PendingMatchEndReason = PlayerStatsRoundEndReason_None;
	g_Round.meta.id = ++g_iRoundSerial;
	g_Round.meta.active = true;
	g_Round.meta.startedAt = GetGameTime();
	Stats_ApplyModeContextToRoundMeta(g_Round.meta, context, policy);
	Stats_RefreshScavengeRoundMetaState(g_Round.meta);
	g_Round.meta.storedTankPercent = (g_Runtime.hasBossPercents && GetFeatureStatus(FeatureType_Native, "GetStoredTankPercent") != FeatureStatus_Unknown)
		? GetStoredTankPercent()
		: -1;
	g_Round.meta.storedWitchPercent = (g_Runtime.hasBossPercents && GetFeatureStatus(FeatureType_Native, "GetStoredWitchPercent") != FeatureStatus_Unknown)
		? GetStoredWitchPercent()
		: -1;
	g_Runtime.roundLive = false;

	if (g_Round.meta.roundLiveSignal == PlayerStatsRoundLiveSignal_Immediate)
	{
		Round_MarkLive("immediate");
	}

	Stats_Debug(PlayerStatsDebug_Core, "Round started. round=%d base_mode=%d series_scope=%d versus_context=%d team_size=%d si_pool_mask=%d scav_round=%d second_half=%d",
		g_Round.meta.id,
		g_Round.meta.baseMode,
		g_Round.meta.seriesScope,
		g_Round.meta.versusContext,
		g_Round.meta.versusTeamSize,
		g_Round.meta.siPoolMask,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf);
}

bool Round_TryBootstrapCurrentModeRound(const char[] reason)
{
	if (!Stats_IsEnabled() || g_Round.meta.active)
	{
		return false;
	}

	PlayerStatsModeContextData context;
	PlayerStatsLifecyclePolicyData policy;
	Stats_BuildCurrentModeContext(context);
	Stats_GetLifecyclePolicyForContext(context, policy);

	if (context.baseMode == GAMEMODE_UNKNOWN
		|| !Stats_IsModeEnabledForBaseMode(context.baseMode)
		|| policy.roundStartSignal != PlayerStatsRoundStartSignal_GenericRoundStart)
	{
		return false;
	}

	Round_StartNewSnapshot(context, policy);
	Stats_Debug(PlayerStatsDebug_Core, "Bootstrapped round snapshot. reason=%s round=%d", reason, g_Round.meta.id);
	return true;
}

void Round_ResetAll(const char[] reason = "unspecified")
{
	Stats_Debug(PlayerStatsDebug_Core, "Round reset. reason=%s previous_round=%d active=%d live=%d",
		reason,
		g_Round.meta.id,
		g_Round.meta.active,
		g_Runtime.roundLive);
	Substitutions_InvalidatePendingTransitions();
	g_Round.Reset();
	g_bRoundClosing = false;
	g_RoundLifecyclePhase = StatsRoundLifecyclePhase_Idle;
	g_iPendingMatchEndedRoundId = 0;
	g_iPendingMatchEndedMapGeneration = 0;
	g_PendingMatchEndReason = PlayerStatsRoundEndReason_None;
	g_Runtime.roundLive = false;
	Stats_ResetRuntimeMappings();
}

void Round_OnStartSignal(StatsLifecycleSignal signal)
{
	if (signal.signalClass != StatsLifecycleSignalClass_Start)
	{
		return;
	}

	if (!Stats_IsEnabled())
	{
		return;
	}

	if (!Stats_ShouldHandleRoundStartEvent(signal.name))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring non-canonical round start event. event=%s signal=%d",
			signal.name,
			g_Runtime.roundStartSignal);
		return;
	}

	if (g_Runtime.baseMode == GAMEMODE_UNKNOWN)
	{
		if (!g_Runtime.hasLeft4DHooks && LibraryExists(LIBRARY_LEFT4DHOOKS))
		{
			g_Runtime.hasLeft4DHooks = true;
		}
		if (!g_Runtime.hasReadyUp && LibraryExists(LIBRARY_READYUP))
		{
			g_Runtime.hasReadyUp = true;
		}
		Stats_RefreshModeContext();
	}

	PlayerStatsModeContextData context;
	PlayerStatsLifecyclePolicyData policy;
	Stats_BuildCurrentModeContext(context);
	Stats_GetLifecyclePolicyForContext(context, policy);

	if (context.baseMode == GAMEMODE_UNKNOWN)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start while mode context is still unknown. event=%s", signal.name);
		return;
	}

	if (!Stats_IsModeEnabledForBaseMode(context.baseMode))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start in disabled mode. event=%s base_mode=%d", signal.name, context.baseMode);
		return;
	}

	if (g_Round.meta.active)
	{
		if (context.baseMode == GAMEMODE_SCAVENGE)
		{
			Stats_RefreshScavengeRoundMetaState(g_Round.meta);
		}

		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start because a snapshot is already active. event=%s round=%d", signal.name, g_Round.meta.id);
		return;
	}

	Round_StartNewSnapshot(context, policy);
}

void Round_OnEndSignal(StatsLifecycleSignal signal)
{
	if (signal.signalClass != StatsLifecycleSignalClass_End)
	{
		return;
	}

	if (g_Runtime.baseMode == GAMEMODE_VERSUS)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring generic round end event in Versus. event=%s", signal.name);
		return;
	}

	if (!Stats_ShouldHandleRoundEndEvent(signal.name))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring non-canonical round end event. event=%s signal=%d",
			signal.name,
			g_Runtime.roundEndSignal);
		return;
	}

	PlayerStatsRoundEndReasonType endReason = StrEqual(signal.name, "scavenge_round_finished", false)
		? PlayerStatsRoundEndReason_ScavengeRoundFinished
		: PlayerStatsRoundEndReason_GenericRoundEnd;
	Round_FinalizeActiveSnapshot("round_end", endReason, true);
}

void Round_OnEndVersusModeRoundPost()
{
	if (g_Runtime.baseMode != GAMEMODE_VERSUS)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("versus_mode_round_end", PlayerStatsRoundEndReason_VersusModeRoundEnd, true);
}

void Round_OnVersusMatchFinished()
{
	if (g_Runtime.baseMode != GAMEMODE_VERSUS)
	{
		return;
	}

	if (g_Round.meta.active)
	{
		if (g_RoundLifecyclePhase == StatsRoundLifecyclePhase_Closing)
		{
			Round_QueueMatchEndedDuringClose(PlayerStatsRoundEndReason_VersusMatchFinished);
			return;
		}

		Round_FinalizeActiveSnapshot("versus_match_finished", PlayerStatsRoundEndReason_VersusMatchFinished, true);
		return;
	}

	Round_FireMatchEndedForLastSnapshot(PlayerStatsRoundEndReason_VersusMatchFinished);
}

void Round_OnScavengeRoundHalftime()
{
	if (g_Runtime.baseMode != GAMEMODE_SCAVENGE)
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Core, "Scavenge halftime reached. round=%d active=%d live=%d",
		g_Round.meta.id,
		g_Round.meta.active,
		g_Runtime.roundLive);

	Round_FinalizeActiveSnapshot("scavenge_round_halftime", PlayerStatsRoundEndReason_ScavengeRoundHalftime, true);
}

void Round_OnScavengeOvertime()
{
	if (g_Runtime.baseMode != GAMEMODE_SCAVENGE || !g_Round.meta.active)
	{
		return;
	}

	g_Round.meta.scavengeWentOvertime = true;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge overtime reached. round=%d scav_round=%d",
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber);
}

void Round_OnScavengeScoreTied()
{
	if (g_Runtime.baseMode != GAMEMODE_SCAVENGE || !g_Round.meta.active)
	{
		return;
	}

	g_Round.meta.scavengeScoreTied = true;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge score tied observed. round=%d scav_round=%d",
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber);
}

void Round_OnScavengeMatchFinished()
{
	if (g_Runtime.baseMode != GAMEMODE_SCAVENGE)
	{
		return;
	}

	if (g_Round.meta.active)
	{
		if (g_RoundLifecyclePhase == StatsRoundLifecyclePhase_Closing)
		{
			Round_QueueMatchEndedDuringClose(PlayerStatsRoundEndReason_ScavengeMatchFinished);
			return;
		}

		Round_FinalizeActiveSnapshot("scavenge_match_finished", PlayerStatsRoundEndReason_ScavengeMatchFinished, true);
		return;
	}

	Round_FireMatchEndedForLastSnapshot(PlayerStatsRoundEndReason_ScavengeMatchFinished);
}

void Round_OnMissionLost()
{
	if (g_Runtime.baseMode != GAMEMODE_COOP)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("mission_lost", PlayerStatsRoundEndReason_MissionLost, true);
}

void Round_OnMapTransition()
{
	if (g_Runtime.baseMode != GAMEMODE_COOP)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("map_transition", PlayerStatsRoundEndReason_MapTransition, true);
}

void Round_OnFinaleWin()
{
	if (g_Runtime.baseMode != GAMEMODE_COOP)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("finale_win", PlayerStatsRoundEndReason_FinaleWin, true);
}

void Round_QueueMatchEndedDuringClose(PlayerStatsRoundEndReasonType endReason)
{
	int roundId = g_Round.meta.id;
	int mapGeneration = g_Trace.mapGeneration;
	if (g_iPendingMatchEndedRoundId == roundId
		&& g_iPendingMatchEndedMapGeneration == mapGeneration
		&& g_PendingMatchEndReason == endReason)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Duplicate match-end signal queued during close. round=%d map_generation=%d end_reason=%d",
			roundId, mapGeneration, endReason);
		return;
	}

	if (g_iPendingMatchEndedRoundId != 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Replacing stale queued match-end signal. old_round=%d new_round=%d old_reason=%d new_reason=%d",
			g_iPendingMatchEndedRoundId, roundId, g_PendingMatchEndReason, endReason);
	}

	g_iPendingMatchEndedRoundId = roundId;
	g_iPendingMatchEndedMapGeneration = mapGeneration;
	g_PendingMatchEndReason = endReason;
	Stats_Debug(PlayerStatsDebug_Core, "Match-end signal queued during close. round=%d map_generation=%d end_reason=%d",
		roundId, mapGeneration, endReason);
}

void Round_FireMatchEndedForSnapshot(int roundId, int mapGeneration, PlayerStatsRoundEndReasonType endReason)
{
	if (!Stats_IsEnabled() || roundId <= 0)
	{
		return;
	}

	if (g_Trace.mapGeneration != mapGeneration)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Queued match-end signal discarded after map change. round=%d saved_map_generation=%d current_map_generation=%d end_reason=%d",
			roundId, mapGeneration, g_Trace.mapGeneration, endReason);
		return;
	}

	if (g_Runtime.lastMatchEndedRoundId == roundId && g_Runtime.lastMatchEndReason == endReason)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Duplicate match-ended forward suppressed. round=%d map_generation=%d end_reason=%d",
			roundId, mapGeneration, endReason);
		return;
	}

	g_Runtime.lastMatchEndedRoundId = roundId;
	g_Runtime.lastMatchEndReason = endReason;
	Stats_Debug(PlayerStatsDebug_Core, "Match-ended forward dispatch. round=%d map_generation=%d end_reason=%d",
		roundId, mapGeneration, endReason);
	API_FireRoundEnded(roundId, StatsEndType_Match, endReason);
}

void Round_MarkLive(const char[] reason, int client = 0)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_Runtime.roundLive)
	{
		return;
	}

	g_Runtime.roundLive = true;
	Stats_PrimeCurrentRoundPlayers();
	API_FireRoundLive(g_Round.meta.id);

	if (client > 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Round is live. round=%d reason=%s client=%d", g_Round.meta.id, reason, client);
		return;
	}

	Stats_Debug(PlayerStatsDebug_Core, "Round is live. round=%d reason=%s", g_Round.meta.id, reason);
}

void Round_OnReadyUpLive()
{
	Round_MarkLive("readyup_live");
}

void Round_OnFirstSurvivorLeftSafeArea(int client)
{
	if (!Stats_IsEnabled())
	{
		return;
	}

	if (!g_Round.meta.active)
	{
		Round_TryBootstrapCurrentModeRound("first_survivor_left_safe_area");
	}

	if (!g_Round.meta.active)
	{
		return;
	}

	if (g_Runtime.hasReadyUp)
	{
		Stats_Debug(PlayerStatsDebug_Core, "First survivor left safe area but readyup is present. round=%d client=%d live=%d",
			g_Round.meta.id,
			client,
			g_Runtime.roundLive);
		return;
	}

	Round_MarkLive("left_safe_area", client);
}

void Round_RefreshLiveState()
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_Runtime.roundLive)
	{
		return;
	}

	switch (g_Round.meta.roundLiveSignal)
	{
		case PlayerStatsRoundLiveSignal_Immediate:
		{
			Round_MarkLive("immediate_refresh");
		}
		case PlayerStatsRoundLiveSignal_SafeArea, PlayerStatsRoundLiveSignal_ReadyUpOrSafeArea:
		{
			if (g_Runtime.baseMode == GAMEMODE_VERSUS && g_Runtime.hasReadyUp)
			{
				return;
			}

			if (!g_Runtime.hasLeft4DHooks)
			{
				return;
			}

			if (L4D_HasAnySurvivorLeftSafeAreaStock())
			{
				Round_MarkLive("safe_area_refresh");
			}
		}
	}
}

void Round_FinalizeActiveSnapshot(const char[] reason, PlayerStatsRoundEndReasonType endReason, bool broadcast)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_RoundLifecyclePhase != StatsRoundLifecyclePhase_Open)
	{
		return;
	}

	int finalizedRoundId = g_Round.meta.id;
	int finalizedMapGeneration = g_Trace.mapGeneration;
	StatsRoundLifecyclePhase previousPhase = g_RoundLifecyclePhase;
	int pendingTankResolved = 0;
	int pendingTankDiscarded = 0;

	// Block ordinary writes before resolving or discarding captured operations.
	// Keep the snapshot active until those operations have been handled.
	g_RoundLifecyclePhase = StatsRoundLifecyclePhase_Closing;
	g_bRoundClosing = true;
	g_Runtime.roundLive = false;
	Stats_Debug(PlayerStatsDebug_Core, "Round close entered. round=%d map_generation=%d phase=%d end_reason=%d",
		finalizedRoundId, finalizedMapGeneration, g_RoundLifecyclePhase, endReason);
	Stats_RefreshScavengeRoundMetaState(g_Round.meta);
	Damage_FinalizeTankOperationsForRoundClose(finalizedRoundId, finalizedMapGeneration, pendingTankResolved, pendingTankDiscarded);
	Stats_Debug(PlayerStatsDebug_Detect, "Tank pending operations finalized. round=%d map_generation=%d resolved=%d discarded=%d",
		finalizedRoundId, finalizedMapGeneration, pendingTankResolved, pendingTankDiscarded);
	int tankSessionsClosed = 0;
	for (int sessionIndex = 0; sessionIndex < g_Round.tankSessionCount; sessionIndex++)
	{
		if (g_Round.tankSessions[sessionIndex].active)
		{
			tankSessionsClosed++;
		}
	}
	Detect_FinalizeActiveTankSessions();
	Stats_Debug(PlayerStatsDebug_Detect, "Tank sessions closed for round. round=%d map_generation=%d sessions=%d",
		finalizedRoundId, finalizedMapGeneration, tankSessionsClosed);

	g_Round.meta.active = false;
	g_Round.meta.endReason = endReason;
	if (g_Round.meta.endedAt <= 0.0)
	{
		g_Round.meta.endedAt = GetGameTime();
	}
	g_RoundLifecyclePhase = StatsRoundLifecyclePhase_Finalized;

	Stats_Debug(PlayerStatsDebug_Core, "Round snapshot frozen. reason=%s round=%d map_generation=%d phase_before=%d tank_pending_resolved=%d tank_pending_discarded=%d scav_round=%d second_half=%d si=%d ci=%d ff=%d",
		reason,
		finalizedRoundId,
		finalizedMapGeneration,
		previousPhase,
		pendingTankResolved,
		pendingTankDiscarded,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf,
		Queries_GetTotalSurvivorSiDamage(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);

	StatsEndType endType = StatsEndType_Round;
	if (g_Round.meta.hasRoundHalves
		&& (endReason == PlayerStatsRoundEndReason_VersusModeRoundEnd
			|| endReason == PlayerStatsRoundEndReason_ScavengeRoundHalftime
			|| endReason == PlayerStatsRoundEndReason_ScavengeRoundFinished))
	{
		endType = StatsEndType_Half;
	}
	if (endReason == PlayerStatsRoundEndReason_ScavengeMatchFinished
		|| endReason == PlayerStatsRoundEndReason_VersusMatchFinished)
	{
		endType = StatsEndType_Match;
	}
	if (endType == StatsEndType_Match)
	{
		g_Runtime.lastMatchEndedRoundId = g_Round.meta.id;
		g_Runtime.lastMatchEndReason = endReason;
	}
	int queuedMatchRoundId = g_iPendingMatchEndedRoundId;
	int queuedMatchMapGeneration = g_iPendingMatchEndedMapGeneration;
	PlayerStatsRoundEndReasonType queuedMatchEndReason = g_PendingMatchEndReason;
	if (queuedMatchRoundId == finalizedRoundId && queuedMatchMapGeneration == finalizedMapGeneration)
	{
		g_iPendingMatchEndedRoundId = 0;
		g_iPendingMatchEndedMapGeneration = 0;
		g_PendingMatchEndReason = PlayerStatsRoundEndReason_None;
	}
	else
	{
		if (queuedMatchRoundId != 0)
		{
			Stats_Debug(PlayerStatsDebug_Core, "Queued match-end signal discarded for stale close context. queued_round=%d closing_round=%d queued_map_generation=%d closing_map_generation=%d end_reason=%d",
				queuedMatchRoundId,
				finalizedRoundId,
				queuedMatchMapGeneration,
				finalizedMapGeneration,
				queuedMatchEndReason);
		}
		queuedMatchRoundId = 0;
		g_iPendingMatchEndedRoundId = 0;
		g_iPendingMatchEndedMapGeneration = 0;
		g_PendingMatchEndReason = PlayerStatsRoundEndReason_None;
	}
	Stats_Debug(PlayerStatsDebug_Core, "Round ended forward dispatch. round=%d end_type=%d end_reason=%d", finalizedRoundId, endType, endReason);
	API_FireRoundEnded(finalizedRoundId, endType, endReason);
	if (g_Round.meta.id != finalizedRoundId
		|| g_Trace.mapGeneration != finalizedMapGeneration
		|| g_RoundLifecyclePhase != StatsRoundLifecyclePhase_Finalized
		|| g_Round.meta.active
		|| g_Round.meta.endReason != endReason
		|| !g_bRoundClosing)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Round post-forward work skipped. expected_round=%d current_round=%d expected_map_generation=%d current_map_generation=%d phase=%d",
			finalizedRoundId,
			g_Round.meta.id,
			finalizedMapGeneration,
			g_Trace.mapGeneration,
			g_RoundLifecyclePhase);
		return;
	}
	if (queuedMatchRoundId != 0)
	{
		Round_FireMatchEndedForSnapshot(queuedMatchRoundId, queuedMatchMapGeneration, queuedMatchEndReason);
		if (g_Round.meta.id != finalizedRoundId
			|| g_Trace.mapGeneration != finalizedMapGeneration
			|| g_RoundLifecyclePhase != StatsRoundLifecyclePhase_Finalized
			|| g_Round.meta.active
			|| g_Round.meta.endReason != endReason
			|| !g_bRoundClosing)
		{
			Stats_Debug(PlayerStatsDebug_Core, "Round presentation skipped after match forward. expected_round=%d current_round=%d expected_map_generation=%d current_map_generation=%d phase=%d",
				finalizedRoundId,
				g_Round.meta.id,
				finalizedMapGeneration,
				g_Trace.mapGeneration,
				g_RoundLifecyclePhase);
			return;
		}
	}

	if (broadcast && Stats_IsTrackingAnnounceEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Core, "Round presentation dispatch. round=%d end_type=%d", finalizedRoundId, endType);
		if (Announce_BroadcastRoundSummary())
		{
			Announce_BroadcastAutomaticRoundPanelsToHumans();
		}
	}
	Stats_Debug(PlayerStatsDebug_Core, "Round finalization complete. round=%d end_type=%d", finalizedRoundId, endType);

}

void Round_FireMatchEndedForLastSnapshot(PlayerStatsRoundEndReasonType endReason)
{
	if (!Stats_IsEnabled() || g_Round.meta.id <= 0)
	{
		return;
	}

	int matchRoundId = g_Round.meta.id;
	Round_FireMatchEndedForSnapshot(matchRoundId, g_Trace.mapGeneration, endReason);
}

stock int Stats_GetScavengeRoundNumber()
{
	return Stats_IsMode(GAMEMODE_SCAVENGE) ? GameRules_GetProp("m_nRoundNumber") : 0;
}


stock bool Stats_IsScavengeSecondHalf()
{
	return Stats_IsMode(GAMEMODE_SCAVENGE) ? view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound")) : false;
}


stock void Stats_RefreshScavengeRoundMetaState(PlayerStatsRoundMetaData meta)
{
	if (meta.baseMode != GAMEMODE_SCAVENGE)
	{
		meta.scavengeRoundNumber = 0;
		meta.scavengeInSecondHalf = false;
		meta.scavengeItemsGoal = 0;
		meta.scavengeWentOvertime = false;
		meta.scavengeScoreTied = false;
		return;
	}

	meta.scavengeRoundNumber = Stats_GetScavengeRoundNumber();
	meta.scavengeInSecondHalf = Stats_IsScavengeSecondHalf();
	meta.scavengeItemsGoal = GameRules_GetProp("m_nScavengeItemsGoal");
}


stock bool Stats_ShouldHandleRoundStartEvent(const char[] eventName)
{
	switch (g_Runtime.roundStartSignal)
	{
		case PlayerStatsRoundStartSignal_ScavengeRoundStart:
		{
			return StrEqual(eventName, "scavenge_round_start", false);
		}
		case PlayerStatsRoundStartSignal_GenericRoundStart:
		{
			return StrEqual(eventName, "round_start", false);
		}
	}

	return false;
}


stock bool Stats_ShouldHandleRoundEndEvent(const char[] eventName)
{
	switch (g_Runtime.roundEndSignal)
	{
		case PlayerStatsRoundEndSignal_ScavengeRoundFinished:
		{
			return StrEqual(eventName, "scavenge_round_finished", false);
		}
		case PlayerStatsRoundEndSignal_GenericRoundEnd:
		{
			return StrEqual(eventName, "round_end", false);
		}
	}

	return false;
}


stock void Stats_RegisterTankVictim(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	int userid = GetClientUserId(client);
	if (userid <= 0)
	{
		return;
	}

	for (int i = 0; i < g_Round.tankVictimCount; i++)
	{
		if (g_Round.tankVictimUserIds[i] == userid)
		{
			return;
		}
	}

	if (g_Round.tankVictimCount >= L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES)
	{
		return;
	}

	g_Round.tankVictimUserIds[g_Round.tankVictimCount++] = userid;
}


stock void Stats_RegisterWitchEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return;
	}

	for (int i = 0; i < g_Round.witchEntityCount; i++)
	{
		if (g_Round.witchEntityIds[i] == entity)
		{
			return;
		}
	}

	if (g_Round.witchEntityCount >= L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES)
	{
		return;
	}

	g_Round.witchEntityIds[g_Round.witchEntityCount++] = entity;
}
