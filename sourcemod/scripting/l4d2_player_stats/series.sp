#if defined _l4d2_player_stats_series_included
	#endinput
#endif
#define _l4d2_player_stats_series_included

int g_iSeriesSerial = 0;

void Series_Init()
{
	g_GameHistory.Reset();
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
	Series_UpdateCampaignScores();

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
	Series_EnsureActive();
}

void Series_UpdateCampaignScores()
{
	int mode = L4D_GetGameModeType();
	if (mode != GAMEMODE_VERSUS && mode != GAMEMODE_SCAVENGE)
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
	return g_Round.totals.survivorTotalSmokerKills
		+ g_Round.totals.survivorTotalBoomerKills
		+ g_Round.totals.survivorTotalHunterKills
		+ g_Round.totals.survivorTotalSpitterKills
		+ g_Round.totals.survivorTotalJockeyKills
		+ g_Round.totals.survivorTotalChargerKills;
}

void Series_ShiftEntriesLeft()
{
	for (int i = 1; i < L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS; i++)
	{
		g_GameHistory.rounds[i - 1] = g_GameHistory.rounds[i];
	}

	g_GameHistory.rounds[L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS - 1].Reset();
	if (g_GameHistory.roundCount > 0)
	{
		g_GameHistory.roundCount--;
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
	GetCurrentMap(g_GameHistory.rounds[entryIndex].map, sizeof(g_GameHistory.rounds[entryIndex].map));
	g_GameHistory.rounds[entryIndex].durationSeconds = Series_GetCurrentRoundDurationSeconds();
	g_GameHistory.rounds[entryIndex].siKills = Series_GetCurrentRoundSpecialKills();
	g_GameHistory.rounds[entryIndex].commonKills = g_Round.totals.survivorTotalCommonKills;
	g_GameHistory.rounds[entryIndex].deaths = g_Round.totals.survivorTotalDeaths;
	g_GameHistory.rounds[entryIndex].incaps = g_Round.totals.survivorTotalIncaps;
	g_GameHistory.rounds[entryIndex].kitsUsed = g_Round.totals.survivorTotalMedkitsUsed;
	g_GameHistory.rounds[entryIndex].pillsUsed = g_Round.totals.survivorTotalPillsUsed;
	g_GameHistory.rounds[entryIndex].restarts = g_GameHistory.restartCount;
	Series_UpdateCampaignScores();

	Stats_Debug(PlayerStatsDebug_Core, "Game round recorded. series=%d round=%d map=%s duration=%d scoreA=%d scoreB=%d",
		g_GameHistory.seriesId,
		g_GameHistory.rounds[entryIndex].roundId,
		g_GameHistory.rounds[entryIndex].map,
		g_GameHistory.rounds[entryIndex].durationSeconds,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);
}

void Series_OnMapStart()
{
	Series_EnsureActive();

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
	Series_EnsureActive();
	Series_UpdateCampaignScores();

	Stats_Debug(PlayerStatsDebug_Core, "Campaign scores cleared. newCampaign=%d scoreA=%d scoreB=%d",
		newCampaign,
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);

	if (newCampaign || (g_GameHistory.lastCampaignScoreA == 0 && g_GameHistory.lastCampaignScoreB == 0))
	{
		Series_ResetAll(newCampaign ? "clear_team_scores_new_campaign" : "clear_team_scores_zero_scores");
		return;
	}
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
