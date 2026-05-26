#if defined _l4d2_player_stats_rounds_included
	#endinput
#endif
#define _l4d2_player_stats_rounds_included

int g_iRoundSerial = 0;

void Round_StartNewSnapshot(PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	g_Round.Reset();
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

	Stats_Debug(PlayerStatsDebug_Core, "Round started. round=%d base_mode=%d history_scope=%d versus_context=%d team_size=%d si_pool_mask=%d scav_round=%d second_half=%d",
		g_Round.meta.id,
		g_Round.meta.baseMode,
		g_Round.meta.historyScope,
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
	g_Round.Reset();
	g_Runtime.roundLive = false;
	Stats_ResetRuntimeMappings();
}

void Round_EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsEnabled())
	{
		return;
	}

	if (!Stats_ShouldHandleRoundStartEvent(name))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring non-canonical round start event. event=%s signal=%d",
			name,
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
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start while mode context is still unknown. event=%s", name);
		return;
	}

	if (!Stats_IsModeEnabledForBaseMode(context.baseMode))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start in disabled mode. event=%s base_mode=%d", name, context.baseMode);
		return;
	}

	if (context.baseMode == GAMEMODE_SCAVENGE)
	{
		Series_OnScavengeRoundStartBoundary();
	}

	if (g_Round.meta.active)
	{
		if (context.baseMode == GAMEMODE_SCAVENGE)
		{
			Stats_RefreshScavengeRoundMetaState(g_Round.meta);
		}

		Stats_Debug(PlayerStatsDebug_Core, "Ignoring round start because a snapshot is already active. event=%s round=%d", name, g_Round.meta.id);
		return;
	}

	Round_StartNewSnapshot(context, policy);
}

void Round_EventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (g_Runtime.baseMode == GAMEMODE_VERSUS)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring generic round end event in Versus. event=%s", name);
		return;
	}

	if (!Stats_ShouldHandleRoundEndEvent(name))
	{
		Stats_Debug(PlayerStatsDebug_Core, "Ignoring non-canonical round end event. event=%s signal=%d",
			name,
			g_Runtime.roundEndSignal);
		return;
	}

	PlayerStatsRoundEndReasonType endReason = StrEqual(name, "scavenge_round_finished", false)
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

	if (g_Round.meta.active)
	{
		g_Round.meta.scavengeInSecondHalf = true;
	}
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

	Round_FinalizeActiveSnapshot("scavenge_match_finished", PlayerStatsRoundEndReason_ScavengeMatchFinished, true);
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

void Round_MarkLive(const char[] reason, int client = 0)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_Runtime.roundLive)
	{
		return;
	}

	g_Runtime.roundLive = true;
	Stats_PrimeCurrentRoundPlayers();

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
	if (!Stats_IsEnabled() || !g_Round.meta.active)
	{
		return;
	}

	Stats_RefreshScavengeRoundMetaState(g_Round.meta);
	g_Round.meta.active = false;
	g_Round.meta.endReason = endReason;
	if (g_Round.meta.endedAt <= 0.0)
	{
		g_Round.meta.endedAt = GetGameTime();
	}
	g_Runtime.roundLive = false;

	Stats_Debug(PlayerStatsDebug_Core, "Round finalized. reason=%s round=%d scav_round=%d second_half=%d si=%d ci=%d ff=%d",
		reason,
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf,
		Announce_GetTotalSurvivorSiDamage(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);

	if (Stats_IsHistoryEnabled())
	{
		Series_RecordRound();
	}

	API_FireRoundFinalized(g_Round.meta.id);

	if (broadcast && Stats_IsTrackingAnnounceEnabled())
	{
		if (Announce_BroadcastRoundSummary())
		{
			Announce_BroadcastRoundConsolePanel();
		}
	}

	if (broadcast && Stats_IsThrowablesAnnounceEnabled())
	{
		Announce_BroadcastUtilitiesConsolePanel();
	}
}
