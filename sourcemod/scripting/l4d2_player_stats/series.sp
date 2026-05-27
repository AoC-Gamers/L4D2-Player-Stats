#if defined _l4d2_player_stats_series_included
	#endinput
#endif
#define _l4d2_player_stats_series_included

int g_iSeriesSerial = 0;

void Series_ResetRoundSnapshots()
{
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS; i++)
	{
		g_RoundHistory[i].Reset();
	}
}

void Series_EnsureActive()
{
	if (g_GameHistory.active)
	{
		return;
	}

	g_GameHistory.Reset();
	g_GameHistory.active = true;
	g_GameHistory.seriesId = ++g_iSeriesSerial;

	Stats_Debug(PlayerStatsDebug_Core, "Game series started. series=%d scoreA=%d scoreB=%d",
		g_GameHistory.seriesId,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);
}

void Series_ResetAll(const char[] reason)
{
	Stats_Debug(PlayerStatsDebug_Core, "Game series reset. reason=%s previous_series=%d rounds=%d scoreA=%d scoreB=%d",
		reason,
		g_GameHistory.seriesId,
		g_GameHistory.roundCount,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);

	g_GameHistory.Reset();
	Series_ResetRoundSnapshots();
	Series_EnsureActive();
}

void Series_UpdateCampaignScores()
{
	int baseMode = Stats_GetModeBase();
	if (baseMode != GAMEMODE_VERSUS && baseMode != GAMEMODE_SCAVENGE)
	{
		g_GameHistory.lastCampaignScoreA = 0;
		g_GameHistory.lastCampaignScoreB = 0;
		return;
	}

	int scores[2];
	scores[0] = 0;
	scores[1] = 0;

	L4D2_GetVersusCampaignScores(scores);
	g_GameHistory.lastCampaignScoreA = scores[0];
	g_GameHistory.lastCampaignScoreB = scores[1];
}

int Series_GetCurrentRoundDurationSeconds()
{
	if (g_Round.meta.startedAt <= 0.0)
	{
		return 0;
	}

	float endedAt = g_Round.meta.endedAt > 0.0 ? g_Round.meta.endedAt : GetGameTime();
	float elapsed = endedAt - g_Round.meta.startedAt;
	return elapsed > 0.0 ? RoundToFloor(elapsed) : 0;
}

int Series_GetCurrentRoundSpecialKills()
{
	return Announce_GetTotalSurvivorSpecialKills();
}

void Series_ShiftEntriesLeft()
{
	for (int i = 1; i < L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS; i++)
	{
		g_GameHistory.rounds[i - 1] = g_GameHistory.rounds[i];
		g_RoundHistory[i - 1] = g_RoundHistory[i];
	}

	g_GameHistory.rounds[L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS - 1].Reset();
	g_RoundHistory[L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS - 1].Reset();
	if (g_GameHistory.roundCount > 0)
	{
		g_GameHistory.roundCount--;
	}
}

void Series_CaptureHistoricalRoundSnapshot(int entryIndex)
{
	g_RoundHistory[entryIndex].Reset();
	g_RoundHistory[entryIndex].active = true;
	g_RoundHistory[entryIndex].roundId = g_Round.meta.id;
	g_RoundHistory[entryIndex].baseMode = g_Round.meta.baseMode;
	g_RoundHistory[entryIndex].isVersusMode = g_Round.meta.isVersusMode;
	g_RoundHistory[entryIndex].scavengeRoundNumber = g_Round.meta.scavengeRoundNumber;
	g_RoundHistory[entryIndex].scavengeInSecondHalf = g_Round.meta.scavengeInSecondHalf;
	g_RoundHistory[entryIndex].scavengeItemsGoal = g_Round.meta.scavengeItemsGoal;
	g_RoundHistory[entryIndex].scavengeWentOvertime = g_Round.meta.scavengeWentOvertime;
	g_RoundHistory[entryIndex].scavengeScoreTied = g_Round.meta.scavengeScoreTied;
	g_RoundHistory[entryIndex].siPoolMask = g_Round.meta.siPoolMask;
	g_RoundHistory[entryIndex].durationSeconds = Series_GetCurrentRoundDurationSeconds();
	g_RoundHistory[entryIndex].storedTankPercent = g_Round.meta.storedTankPercent;
	g_RoundHistory[entryIndex].storedWitchPercent = g_Round.meta.storedWitchPercent;
	g_RoundHistory[entryIndex].tankCount = g_Round.tankVictimCount;
	g_RoundHistory[entryIndex].witchCount = g_Round.witchEntityCount;
	g_RoundHistory[entryIndex].endReason = g_Round.meta.endReason;
	g_RoundHistory[entryIndex].historyScope = g_Round.meta.historyScope;
	g_RoundHistory[entryIndex].totals = g_Round.totals;
	g_RoundHistory[entryIndex].tankSessionCount = g_Round.tankSessionCount;

	for (int tankIndex = 0; tankIndex < L4D2_PLAYER_STATS_MAX_TANK_SESSIONS; tankIndex++)
	{
		g_RoundHistory[entryIndex].tankSessions[tankIndex] = g_Round.tankSessions[tankIndex];
	}

	int historicalIndex = 0;
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && historicalIndex < L4D2_PLAYER_STATS_MAX_HISTORICAL_PLAYERS; slot++)
	{
		if (!g_Round.players[slot].active)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor && g_Round.players[slot].team != PlayerStatsTeam_Infected)
		{
			continue;
		}

		g_RoundHistory[entryIndex].players[historicalIndex].active = true;
		g_RoundHistory[entryIndex].players[historicalIndex].bot = g_Round.players[slot].player.bot;
		g_RoundHistory[entryIndex].players[historicalIndex].team = g_Round.players[slot].team;
		strcopy(g_RoundHistory[entryIndex].players[historicalIndex].name, sizeof(g_RoundHistory[entryIndex].players[historicalIndex].name), g_Round.players[slot].player.name);
		g_RoundHistory[entryIndex].players[historicalIndex].combat = g_Round.players[slot].combat;
		g_RoundHistory[entryIndex].players[historicalIndex].resources = g_Round.players[slot].resources;
		g_RoundHistory[entryIndex].players[historicalIndex].scavenge = g_Round.players[slot].scavenge;
		g_RoundHistory[entryIndex].players[historicalIndex].support = g_Round.players[slot].support;
		g_RoundHistory[entryIndex].players[historicalIndex].infectedGrab = g_Round.players[slot].infectedGrab;
		g_RoundHistory[entryIndex].players[historicalIndex].infectedSupport = g_Round.players[slot].infectedSupport;
		g_RoundHistory[entryIndex].players[historicalIndex].skills = g_Round.players[slot].skills;
		g_RoundHistory[entryIndex].players[historicalIndex].accuracy = g_Round.players[slot].accuracy;
		g_RoundHistory[entryIndex].players[historicalIndex].accuracyDetails = g_Round.players[slot].accuracyDetails;
		historicalIndex++;
	}
}

void Series_RecordRound()
{
	if (!Stats_IsEnabled() || g_Round.meta.id <= 0)
	{
		return;
	}

	Series_EnsureActive();

	if (g_GameHistory.roundCount >= L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS)
	{
		Series_ShiftEntriesLeft();
	}

	int entryIndex = g_GameHistory.roundCount++;
	g_GameHistory.rounds[entryIndex].Reset();
	g_GameHistory.rounds[entryIndex].active = true;
	g_GameHistory.rounds[entryIndex].roundId = g_Round.meta.id;
	g_GameHistory.rounds[entryIndex].baseMode = g_Round.meta.baseMode;
	g_GameHistory.rounds[entryIndex].historyScope = g_Round.meta.historyScope;
	GetCurrentMap(g_GameHistory.rounds[entryIndex].map, sizeof(g_GameHistory.rounds[entryIndex].map));
	g_GameHistory.rounds[entryIndex].durationSeconds = Series_GetCurrentRoundDurationSeconds();
	g_GameHistory.rounds[entryIndex].siKills = Series_GetCurrentRoundSpecialKills();
	g_GameHistory.rounds[entryIndex].commonKills = g_Round.totals.survivorTotalCommonKills;
	g_GameHistory.rounds[entryIndex].deaths = g_Round.totals.survivorTotalDeaths;
	g_GameHistory.rounds[entryIndex].incaps = g_Round.totals.survivorTotalIncaps;
	g_GameHistory.rounds[entryIndex].kitsUsed = g_Round.totals.survivorTotalMedkitsUsed;
	g_GameHistory.rounds[entryIndex].pillsUsed = g_Round.totals.survivorTotalPillsUsed;
	g_GameHistory.rounds[entryIndex].restarts = g_GameHistory.restartCount;
	g_GameHistory.rounds[entryIndex].restartSource = g_GameHistory.restartSource;
	g_GameHistory.rounds[entryIndex].endReason = g_Round.meta.endReason;
	Series_CaptureHistoricalRoundSnapshot(entryIndex);
	g_GameHistory.restartCount = 0;
	g_GameHistory.restartSource = PlayerStatsRestartSource_None;
	g_GameHistory.pendingScavengeMatchReset = false;
	Series_UpdateCampaignScores();

	Stats_Debug(PlayerStatsDebug_Core, "Game round recorded. series=%d round=%d map=%s duration=%d end_reason=%d restarts=%d restart_source=%d scoreA=%d scoreB=%d",
		g_GameHistory.seriesId,
		g_GameHistory.rounds[entryIndex].roundId,
		g_GameHistory.rounds[entryIndex].map,
		g_GameHistory.rounds[entryIndex].durationSeconds,
		g_GameHistory.rounds[entryIndex].endReason,
		g_GameHistory.rounds[entryIndex].restarts,
		g_GameHistory.rounds[entryIndex].restartSource,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);
}

void Series_OnMapStart()
{
	Series_EnsureActive();

	int baseMode = Stats_GetModeBase();
	if (baseMode != GAMEMODE_VERSUS && baseMode != GAMEMODE_SCAVENGE)
	{
		return;
	}

	if (!L4D_IsFirstMapInScenario())
	{
		return;
	}

	Series_UpdateCampaignScores();
	if (g_GameHistory.roundCount > 0 && g_GameHistory.lastCampaignScoreA == 0 && g_GameHistory.lastCampaignScoreB == 0)
	{
		Series_ResetAll("first_map_zero_campaign_scores");
	}
}

void Series_OnClearTeamScores(bool newCampaign)
{
	int baseMode = Stats_GetModeBase();
	if (baseMode != GAMEMODE_VERSUS && baseMode != GAMEMODE_SCAVENGE)
	{
		return;
	}

	Series_EnsureActive();
	g_GameHistory.lastCampaignScoreA = 0;
	g_GameHistory.lastCampaignScoreB = 0;

	Stats_Debug(PlayerStatsDebug_Core, "Campaign scores cleared. newCampaign=%d series=%d rounds=%d",
		newCampaign,
		g_GameHistory.seriesId,
		g_GameHistory.roundCount);

	if (!newCampaign)
	{
		return;
	}

	if (g_GameHistory.roundCount <= 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Skipping clear_team_scores reset because no rounds are recorded yet. series=%d",
			g_GameHistory.seriesId);
		return;
	}

	Series_ResetAll("clear_team_scores_new_campaign");
}

void Series_OnSetCampaignScoresPost(int scoreA, int scoreB)
{
	Series_EnsureActive();
	g_GameHistory.lastCampaignScoreA = scoreA;
	g_GameHistory.lastCampaignScoreB = scoreB;

	Stats_Debug(PlayerStatsDebug_Core, "Campaign scores updated. series=%d scoreA=%d scoreB=%d",
		g_GameHistory.seriesId,
		scoreA,
		scoreB);
}

void Series_EventVotePassed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsMode(GAMEMODE_VERSUS) && !Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		return;
	}

	char details[128];
	event.GetString("details", details, sizeof(details));

	if (!StrEqual(details, "#L4D_vote_passed_restart_game", false)
		&& !StrEqual(details, "#L4D_vote_passed_versus_level_restart", false))
	{
		return;
	}

	Series_MarkPendingRestart(PlayerStatsRestartSource_VotePassed, "vote_passed");
	Stats_Debug(PlayerStatsDebug_Core, "Competitive restart vote passed. details=%s round=%d",
		details,
		g_Round.meta.id);
}

void Series_MarkPendingRestart(PlayerStatsRestartSourceType source, const char[] reason)
{
	if (!Stats_IsMode(GAMEMODE_VERSUS) && !Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		return;
	}

	Series_EnsureActive();
	g_GameHistory.restartCount++;
	g_GameHistory.restartSource = source;

	Stats_Debug(PlayerStatsDebug_Core, "Pending restart registered. series=%d pending_restarts=%d source=%d reason=%s round=%d",
		g_GameHistory.seriesId,
		g_GameHistory.restartCount,
		g_GameHistory.restartSource,
		reason,
		g_Round.meta.id);
}

void Series_OnScavengeRoundHalftime()
{
	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		return;
	}

	Series_EnsureActive();
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge halftime observed. series=%d round=%d", g_GameHistory.seriesId, g_Round.meta.id);
}

void Series_OnScavengeRoundStartBoundary()
{
	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		return;
	}

	if (!g_GameHistory.pendingScavengeMatchReset)
	{
		return;
	}

	Series_ResetAll("scavenge_match_finished_new_round");
}

void Series_OnScavengeMatchFinished()
{
	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		return;
	}

	Series_EnsureActive();
	Series_UpdateCampaignScores();
	g_GameHistory.pendingScavengeMatchReset = true;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge match finished. series=%d round=%d scoreA=%d scoreB=%d",
		g_GameHistory.seriesId,
		g_Round.meta.id,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);
}
