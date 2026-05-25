#if defined _l4d2_player_stats_rounds_included
	#endinput
#endif
#define _l4d2_player_stats_rounds_included

int g_iRoundSerial = 0;

void Round_Init()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavengeMatchFinished, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_PostNoCopy);
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

	PlayerStatsModeContextData context;
	PlayerStatsLifecyclePolicyData policy;
	Stats_BuildCurrentModeContext(context);
	Stats_GetLifecyclePolicyForContext(context, policy);

	g_Round.Reset();
	g_Round.meta.id = ++g_iRoundSerial;
	g_Round.meta.active = true;
	g_Round.meta.startedAt = GetGameTime();
	Stats_ApplyModeContextToRoundMeta(g_Round.meta, context, policy);
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

	char baseModeName[24];
	char historyScopeName[24];
	char contextName[32];
	Stats_GetModeBaseName(g_Round.meta.baseMode, baseModeName, sizeof(baseModeName));
	Stats_GetHistoryScopeName(g_Round.meta.historyScope, historyScopeName, sizeof(historyScopeName));
	Stats_GetVersusContextName(g_Round.meta.versusContext, contextName, sizeof(contextName));
	Stats_Debug(PlayerStatsDebug_Core, "Round started. round=%d base=%s history=%s context=%s team_size=%d si_pool_mask=%d",
		g_Round.meta.id,
		baseModeName,
		historyScopeName,
		contextName,
		g_Round.meta.versusTeamSize,
		g_Round.meta.siPoolMask);
}

void Round_EventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (g_Runtime.baseMode == PlayerStatsModeBase_Versus)
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
	if (g_Runtime.baseMode != PlayerStatsModeBase_Versus)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("versus_mode_round_end", PlayerStatsRoundEndReason_VersusModeRoundEnd, true);
}

void Round_OnScavengeRoundHalftime()
{
	if (g_Runtime.baseMode != PlayerStatsModeBase_Scavenge)
	{
		return;
	}

	Stats_Debug(PlayerStatsDebug_Core, "Scavenge halftime reached. round=%d active=%d live=%d",
		g_Round.meta.id,
		g_Round.meta.active,
		g_Runtime.roundLive);
}

void Round_OnScavengeMatchFinished()
{
	if (g_Runtime.baseMode != PlayerStatsModeBase_Scavenge)
	{
		return;
	}

	Round_FinalizeActiveSnapshot("scavenge_match_finished", PlayerStatsRoundEndReason_ScavengeMatchFinished, true);
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
	if (!Stats_IsEnabled() || !g_Round.meta.active)
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

void Round_FinalizeActiveSnapshot(const char[] reason, PlayerStatsRoundEndReasonType endReason, bool broadcast)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active)
	{
		return;
	}

	g_Round.meta.active = false;
	g_Round.meta.endReason = endReason;
	if (g_Round.meta.endedAt <= 0.0)
	{
		g_Round.meta.endedAt = GetGameTime();
	}
	g_Runtime.roundLive = false;

	Stats_Debug(PlayerStatsDebug_Core, "Round finalized. reason=%s round=%d si=%d ci=%d ff=%d",
		reason,
		g_Round.meta.id,
		Announce_GetTotalSurvivorSiDamage(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);

	Series_RecordRound();

	if (broadcast)
	{
		Announce_BroadcastRoundSummary();
		Announce_BroadcastRoundConsolePanel();
		API_FireRoundFinalized(g_Round.meta.id);
	}
}
