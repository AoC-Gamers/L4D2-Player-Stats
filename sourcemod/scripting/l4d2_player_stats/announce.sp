#if defined _l4d2_player_stats_announce_included
	#endinput
#endif
#define _l4d2_player_stats_announce_included

void Announce_ReplyCommandPhrase(int client, const char[] phrase)
{
	CReplyToCommand(client, "%t %t", "Tag", phrase);
}

bool Announce_WasCommandInvokedFromChat(int client)
{
	return client > 0 && IsValidClient(client) && GetCmdReplySource() == SM_REPLY_TO_CHAT;
}

void Announce_NotifyConsoleDelivery(int client)
{
	if (!Announce_WasCommandInvokedFromChat(client))
	{
		return;
	}

	Announce_ReplyCommandPhrase(client, "ConsoleDeliveryNotice");
}

void Announce_PrintConsoleLine(int client, const char[] line)
{
	if (client > 0 && IsValidClient(client))
	{
		PrintToConsole(client, "%s", line);
		return;
	}

	PrintToServer("%s", line);
}

void Announce_PrintHelpToConsole(int client)
{
	int phraseTarget = client > 0 ? client : LANG_SERVER;
	char line[192];

	Format(line, sizeof(line), "%T", "HelpHeader", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPCurrent", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPMap", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPRank", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPStats", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPAcc", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPAccDetails", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPUtils", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPItems", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPSupport", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPScavenge", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPHelp", phraseTarget);
	Announce_PrintConsoleLine(client, line);
}

void Announce_GetColumnLabel(char[] buffer, int maxlen, const char[] phrase, int client = LANG_SERVER)
{
	Format(buffer, maxlen, "%T", phrase, client);
}

void Announce_FormatMetricUnitLabel(char[] buffer, int maxlen, const char[] baseLabel, const char[] suffix, bool compact = true)
{
	if (compact)
	{
		Format(buffer, maxlen, "%s%s", baseLabel, suffix);
		return;
	}

	Format(buffer, maxlen, "%s %s", baseLabel, suffix);
}

int Announce_FindLatestHistoryRoundIndex(const char[] mapFilter)
{
	if (mapFilter[0] == '\0')
	{
		return -1;
	}

	for (int i = g_GameHistory.roundCount - 1; i >= 0; i--)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (!StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		if (!g_RoundHistory[i].active || g_RoundHistory[i].roundId <= 0)
		{
			continue;
		}

		return i;
	}

	return -1;
}

bool Announce_LoadHistoricalRoundByMap(const char[] mapFilter)
{
	int index = Announce_FindLatestHistoryRoundIndex(mapFilter);
	if (index < 0)
	{
		return false;
	}

	g_RoundBackup = g_Round;
	g_Round.Reset();
	g_Round.meta.id = g_RoundHistory[index].roundId;
	g_Round.meta.baseMode = g_RoundHistory[index].baseMode;
	g_Round.meta.isVersusMode = g_RoundHistory[index].isVersusMode;
	g_Round.meta.scavengeRoundNumber = g_RoundHistory[index].scavengeRoundNumber;
	g_Round.meta.scavengeInSecondHalf = g_RoundHistory[index].scavengeInSecondHalf;
	g_Round.meta.scavengeItemsGoal = g_RoundHistory[index].scavengeItemsGoal;
	g_Round.meta.scavengeWentOvertime = g_RoundHistory[index].scavengeWentOvertime;
	g_Round.meta.scavengeScoreTied = g_RoundHistory[index].scavengeScoreTied;
	g_Round.meta.siPoolMask = g_RoundHistory[index].siPoolMask;
	g_Round.meta.startedAt = 1.0;
	g_Round.meta.endedAt = 1.0 + float(g_RoundHistory[index].durationSeconds);
	g_Round.meta.storedTankPercent = g_RoundHistory[index].storedTankPercent;
	g_Round.meta.storedWitchPercent = g_RoundHistory[index].storedWitchPercent;
	g_Round.meta.endReason = g_RoundHistory[index].endReason;
	g_Round.meta.historyScope = g_RoundHistory[index].historyScope;
	g_Round.totals = g_RoundHistory[index].totals;
	g_Round.tankVictimCount = g_RoundHistory[index].tankCount;
	g_Round.witchEntityCount = g_RoundHistory[index].witchCount;

	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_SURVIVORS; i++)
	{
		if (!g_RoundHistory[index].players[i].active)
		{
			continue;
		}

		g_Round.players[i].Reset();
		g_Round.players[i].active = true;
		g_Round.players[i].team = PlayerStatsTeam_Survivor;
		strcopy(g_Round.players[i].player.name, sizeof(g_Round.players[i].player.name), g_RoundHistory[index].players[i].name);
		g_Round.players[i].combat = g_RoundHistory[index].players[i].combat;
		g_Round.players[i].resources = g_RoundHistory[index].players[i].resources;
		g_Round.players[i].scavenge = g_RoundHistory[index].players[i].scavenge;
		g_Round.players[i].support = g_RoundHistory[index].players[i].support;
		g_Round.players[i].accuracy = g_RoundHistory[index].players[i].accuracy;
		g_Round.players[i].accuracyDetails = g_RoundHistory[index].players[i].accuracyDetails;
	}

	return true;
}

void Announce_RestoreHistoricalRound()
{
	g_Round = g_RoundBackup;
}

void Announce_GetTitleName(char[] buffer, int maxlen, int baseMode = GAMEMODE_UNKNOWN, int client = LANG_SERVER)
{
	buffer[0] = '\0';

	if (g_Runtime.hasReadyUp && g_cvReadyCfgName != null)
	{
		g_cvReadyCfgName.GetString(buffer, maxlen);
		TrimString(buffer);
		if (buffer[0] != '\0')
		{
			return;
		}
	}

	if (baseMode == GAMEMODE_UNKNOWN)
	{
		baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN
			? g_Round.meta.baseMode
			: g_Runtime.baseMode;
	}

	switch (baseMode)
	{
		case GAMEMODE_COOP:
		{
			Format(buffer, maxlen, "%T", "ModeNameCoop", client);
		}
		case GAMEMODE_VERSUS:
		{
			Format(buffer, maxlen, "%T", "ModeNameVersus", client);
		}
		case GAMEMODE_SCAVENGE:
		{
			Format(buffer, maxlen, "%T", "ModeNameScavenge", client);
		}
		case GAMEMODE_SURVIVAL:
		{
			Format(buffer, maxlen, "%T", "ModeNameSurvival", client);
		}
		default:
		{
			Format(buffer, maxlen, "%T", "ModeNameUnknown", client);
		}
	}
}

bool Announce_BroadcastRoundSummary(int client = 0)
{
	int activeSlots = 0;
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (g_Round.players[slot].active)
		{
			activeSlots++;
		}
	}

	Stats_Debug(PlayerStatsDebug_Announce, "Broadcast summary requested. round=%d active=%d live=%d slots=%d",
		g_Round.meta.id,
		g_Round.meta.active,
		g_Runtime.roundLive,
		activeSlots);

	if (!Stats_HasRoundSnapshot())
	{
		if (client > 0 && IsValidClient(client))
		{
			CPrintToChat(client, "%t %t", "Tag", "StatsUnavailable");
		}
		return false;
	}

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	if (Announce_GetTotalSurvivorDamage() <= 0)
	{
		siMvp = -1;
	}

	if (g_Round.totals.survivorTotalCommonKills <= 0)
	{
		ciMvp = -1;
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		ffLvp = -1;
	}

	if (siMvp == -1 && ciMvp == -1 && ffLvp == -1)
	{
		if (client > 0 && IsValidClient(client))
		{
			CPrintToChat(client, "%t %t", "Tag", "StatsUnavailable");
		}
		return false;
	}

	Announce_PrintRoundSummaryLines(client, siMvp, ciMvp, ffLvp);
	return true;
}

bool Announce_RenderHistoricalRoundSummary(int client, const char[] mapFilter, bool withSummary = true)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	if (withSummary && !Announce_BroadcastRoundSummary(client))
	{
		Announce_RestoreHistoricalRound();
		return false;
	}

	if (client > 0 && IsValidClient(client))
	{
		if (!Announce_RenderRoundConsolePanel(client))
		{
			Announce_RestoreHistoricalRound();
			return false;
		}
	}

	Announce_RestoreHistoricalRound();
	return true;
}

bool Announce_RenderHistoricalAccuracyPanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderAccuracyPanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

bool Announce_RenderHistoricalAccuracyDetailsPanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderAccuracyDetailsPanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

bool Announce_RenderHistoricalUtilitiesPanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderUtilitiesPanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

bool Announce_RenderHistoricalConsumablesPanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderConsumablesPanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

bool Announce_RenderHistoricalSupportPanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderSupportPanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

bool Announce_RenderHistoricalScavengePanel(int client, const char[] mapFilter)
{
	if (!Announce_LoadHistoricalRoundByMap(mapFilter))
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	bool rendered = Announce_RenderScavengePanel(client);
	Announce_RestoreHistoricalRound();
	return rendered;
}

PlayerStatsHistoryScopeType Announce_GetHistoryScopeForFilter(const char[] mapFilter = "")
{
	for (int i = g_GameHistory.roundCount - 1; i >= 0; i--)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (mapFilter[0] != '\0' && !StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		return g_GameHistory.rounds[i].historyScope;
	}

	return g_Runtime.historyScope;
}

int Announce_GetHistoryBaseModeForFilter(const char[] mapFilter = "")
{
	for (int i = g_GameHistory.roundCount - 1; i >= 0; i--)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (mapFilter[0] != '\0' && !StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		return g_GameHistory.rounds[i].baseMode;
	}

	return g_Runtime.baseMode;
}

void Announce_GetHistoryPanelTitle(char[] buffer, int maxlen, PlayerStatsHistoryScopeType historyScope, const char[] mapFilter = "", int client = LANG_SERVER)
{
	char titleName[64];
	Announce_GetTitleName(titleName, sizeof(titleName), Announce_GetHistoryBaseModeForFilter(mapFilter), client);

	switch (historyScope)
	{
		case PlayerStatsHistoryScope_CampaignRun:
		{
			if (mapFilter[0] != '\0')
			{
				Format(buffer, maxlen, "%T", "HistoryTitleCampaignMap", client, titleName, g_GameHistory.seriesId, mapFilter);
			}
			else
			{
				Format(buffer, maxlen, "%T", "HistoryTitleCampaignAll", client, titleName, g_GameHistory.seriesId);
			}
		}
		case PlayerStatsHistoryScope_CompetitiveSeries:
		{
			if (mapFilter[0] != '\0')
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSeriesMap", client, titleName, g_GameHistory.seriesId, mapFilter);
			}
			else
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSeriesAll", client, titleName, g_GameHistory.seriesId);
			}
		}
		case PlayerStatsHistoryScope_ScavengeMatch:
		{
			if (mapFilter[0] != '\0')
			{
				Format(buffer, maxlen, "%T", "HistoryTitleScavengeMap", client, titleName, g_GameHistory.seriesId, mapFilter);
			}
			else
			{
				Format(buffer, maxlen, "%T", "HistoryTitleScavengeAll", client, titleName, g_GameHistory.seriesId);
			}
		}
		case PlayerStatsHistoryScope_SurvivalRuns:
		{
			if (mapFilter[0] != '\0')
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSurvivalMap", client, titleName, g_GameHistory.seriesId, mapFilter);
			}
			else
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSurvivalAll", client, titleName, g_GameHistory.seriesId);
			}
		}
		default:
		{
			if (mapFilter[0] != '\0')
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSessionMap", client, titleName, g_GameHistory.seriesId, mapFilter);
			}
			else
			{
				Format(buffer, maxlen, "%T", "HistoryTitleSessionAll", client, titleName, g_GameHistory.seriesId);
			}
		}
	}
}

bool Announce_ShouldShowHistoryMapColumn(PlayerStatsHistoryScopeType historyScope, const char[] mapFilter = "")
{
	if (mapFilter[0] == '\0')
	{
		return true;
	}

	return historyScope != PlayerStatsHistoryScope_ScavengeMatch
		&& historyScope != PlayerStatsHistoryScope_SurvivalRuns;
}

bool Announce_ShouldShowHistoryRestartsColumn(PlayerStatsHistoryScopeType historyScope)
{
	switch (historyScope)
	{
		case PlayerStatsHistoryScope_CampaignRun, PlayerStatsHistoryScope_CompetitiveSeries, PlayerStatsHistoryScope_ScavengeMatch:
		{
			return true;
		}
	}

	return false;
}

void Announce_GetHistoryRoundColumnLabel(char[] buffer, int maxlen, PlayerStatsHistoryScopeType historyScope)
{
	switch (historyScope)
	{
		case PlayerStatsHistoryScope_SurvivalRuns:
		{
			Announce_GetColumnLabel(buffer, maxlen, "ColumnRun", LANG_SERVER);
		}
		default:
		{
			Announce_GetColumnLabel(buffer, maxlen, "ColumnRound", LANG_SERVER);
		}
	}
}

int Announce_CountHistoryRowsForFilter(const char[] mapFilter = "")
{
	int count = 0;

	for (int i = 0; i < g_GameHistory.roundCount; i++)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (mapFilter[0] != '\0' && !StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		count++;
	}

	return count;
}

int Announce_GetBestHistoryDurationForFilter(const char[] mapFilter = "")
{
	int best = 0;

	for (int i = 0; i < g_GameHistory.roundCount; i++)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (mapFilter[0] != '\0' && !StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		if (g_GameHistory.rounds[i].durationSeconds > best)
		{
			best = g_GameHistory.rounds[i].durationSeconds;
		}
	}

	return best;
}

void Announce_FormatDurationCompact(int durationSeconds, char[] buffer, int maxlen)
{
	int minutes = durationSeconds / 60;
	int seconds = durationSeconds % 60;
	Format(buffer, maxlen, "%dm %02ds", minutes, seconds);
}

void Announce_GetHistorySummaryLine(char[] buffer, int maxlen, PlayerStatsHistoryScopeType historyScope, const char[] mapFilter = "")
{
	int entryCount = Announce_CountHistoryRowsForFilter(mapFilter);

	switch (historyScope)
	{
		case PlayerStatsHistoryScope_CampaignRun:
		{
			Format(buffer, maxlen, "%T", "HistorySummaryCampaign", LANG_SERVER, entryCount);
		}
		case PlayerStatsHistoryScope_CompetitiveSeries:
		{
			Format(buffer, maxlen, "%T", "HistorySummarySeries", LANG_SERVER, entryCount);
		}
		case PlayerStatsHistoryScope_ScavengeMatch:
		{
			Format(buffer, maxlen, "%T", "HistorySummaryScavenge", LANG_SERVER, entryCount);
		}
		case PlayerStatsHistoryScope_SurvivalRuns:
		{
			int bestDuration = Announce_GetBestHistoryDurationForFilter(mapFilter);
			char bestTime[16];
			Announce_FormatDurationCompact(bestDuration, bestTime, sizeof(bestTime));
			Format(buffer, maxlen, "%T", "HistorySummarySurvival", LANG_SERVER, entryCount, bestTime);
		}
		default:
		{
			Format(buffer, maxlen, "%T", "HistorySummaryGeneric", LANG_SERVER, entryCount);
		}
	}
}

bool Announce_RenderGameHistoryPanel(int client = 0, const char[] mapFilter = "")
{
	if (!g_GameHistory.active || g_GameHistory.roundCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableCurrentMode");
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	PlayerStatsHistoryScopeType historyScope = Announce_GetHistoryScopeForFilter(mapFilter);
	int baseMode = Announce_GetHistoryBaseModeForFilter(mapFilter);
	char line[160];
	Announce_GetHistoryPanelTitle(line, sizeof(line), historyScope, mapFilter, Announce_GetPhraseTarget(client));
	ConsolePanel_AddHeaderLine(panel, line);
	Announce_GetHistorySummaryLine(line, sizeof(line), historyScope, mapFilter);
	ConsolePanel_AddHeaderLine(panel, line);

	if (baseMode == GAMEMODE_VERSUS || baseMode == GAMEMODE_SCAVENGE)
	{
		Format(line, sizeof(line), "%T", "HistoryCampaignScore", LANG_SERVER,
			g_GameHistory.lastCampaignScoreA,
			g_GameHistory.lastCampaignScoreB);
		ConsolePanel_AddHeaderLine(panel, line);
	}

	bool showMapColumn = Announce_ShouldShowHistoryMapColumn(historyScope, mapFilter);
	bool showRestartsColumn = Announce_ShouldShowHistoryRestartsColumn(historyScope);
	char roundLabel[12];
	char mapLabel[12];
	char timeLabel[12];
	char siKillsLabel[12];
	char commonLabel[12];
	char deathsLabel[12];
	char incapsLabel[12];
	char kitsLabel[12];
	char pillsLabel[12];
	char restartsLabel[16];
	Announce_GetHistoryRoundColumnLabel(roundLabel, sizeof(roundLabel), historyScope);
	Announce_GetColumnLabel(mapLabel, sizeof(mapLabel), "ColumnMap", LANG_SERVER);
	Announce_GetColumnLabel(timeLabel, sizeof(timeLabel), "ColumnTime", LANG_SERVER);
	Announce_GetColumnLabel(siKillsLabel, sizeof(siKillsLabel), "ColumnSIKills", LANG_SERVER);
	Announce_GetColumnLabel(commonLabel, sizeof(commonLabel), "ColumnCommon", LANG_SERVER);
	Announce_GetColumnLabel(deathsLabel, sizeof(deathsLabel), "ColumnDeaths", LANG_SERVER);
	Announce_GetColumnLabel(incapsLabel, sizeof(incapsLabel), "ColumnIncaps", LANG_SERVER);
	Announce_GetColumnLabel(kitsLabel, sizeof(kitsLabel), "ColumnKits", LANG_SERVER);
	Announce_GetColumnLabel(pillsLabel, sizeof(pillsLabel), "ColumnPills", LANG_SERVER);
	Announce_GetColumnLabel(restartsLabel, sizeof(restartsLabel), "ColumnRestarts", LANG_SERVER);

	ConsoleTable_AddColumn(panel.table, roundLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	if (showMapColumn)
	{
		ConsoleTable_AddColumn(panel.table, mapLabel, 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	}
	ConsoleTable_AddColumn(panel.table, timeLabel, 8, ConsoleTableAlignment_Right, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, siKillsLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, commonLabel, 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, deathsLabel, 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, incapsLabel, 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, kitsLabel, 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, pillsLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	if (showRestartsColumn)
	{
		ConsoleTable_AddColumn(panel.table, restartsLabel, 8, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}

	int displayedRows = 0;
	for (int i = 0; i < g_GameHistory.roundCount; i++)
	{
		if (!g_GameHistory.rounds[i].active)
		{
			continue;
		}

		if (mapFilter[0] != '\0' && !StrEqual(g_GameHistory.rounds[i].map, mapFilter, false))
		{
			continue;
		}

		if (!ConsoleTable_BeginRow(panel.table))
		{
			break;
		}

		char duration[16];
		int minutes = g_GameHistory.rounds[i].durationSeconds / 60;
		int seconds = g_GameHistory.rounds[i].durationSeconds % 60;
		Format(duration, sizeof(duration), "%dm %02ds", minutes, seconds);

		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].roundId);
		if (showMapColumn)
		{
			ConsoleTable_AddStringCell(panel.table, g_GameHistory.rounds[i].map);
		}
		ConsoleTable_AddStringCell(panel.table, duration);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].siKills);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].commonKills);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].deaths);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].incaps);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].kitsUsed);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].pillsUsed);
		if (showRestartsColumn)
		{
			ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].restarts);
		}
		ConsoleTable_EndRow(panel.table);
		displayedRows++;
	}

	if (displayedRows <= 0)
	{
		Announce_ReplyCommandPhrase(client, "HistoryUnavailableFilter");
		return false;
	}

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderAccuracyPanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasAccuracyStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char titleName[64];
	char shotgunLabel[16];
	char smgRifleLabel[16];
	char sniperLabel[16];
	char pistolLabel[16];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(shotgunLabel, sizeof(shotgunLabel), "ColumnShotgun", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(smgRifleLabel, sizeof(smgRifleLabel), "ColumnSmgRifle", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(sniperLabel, sizeof(sniperLabel), "ColumnSniper", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(pistolLabel, sizeof(pistolLabel), "ColumnPistol", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(shotgunLabel, sizeof(shotgunLabel), shotgunLabel, "%");
	Announce_FormatMetricUnitLabel(smgRifleLabel, sizeof(smgRifleLabel), smgRifleLabel, "%");
	Announce_FormatMetricUnitLabel(sniperLabel, sizeof(sniperLabel), sniperLabel, "%");
	Announce_FormatMetricUnitLabel(pistolLabel, sizeof(pistolLabel), pistolLabel, "%");
	Format(line, sizeof(line), "%T", "PanelTitleAccuracyStats", client > 0 ? client : LANG_SERVER, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerStringColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

	char shotgunValues[L4D2_PLAYER_STATS_MAX_SURVIVORS][32];
	char smgRifleValues[L4D2_PLAYER_STATS_MAX_SURVIVORS][32];
	char sniperValues[L4D2_PLAYER_STATS_MAX_SURVIVORS][32];
	char pistolValues[L4D2_PLAYER_STATS_MAX_SURVIVORS][32];

	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		Announce_FormatAccuracyCell(shotgunValues[i], sizeof(shotgunValues[]), g_Round.players[slot].accuracy.shotgunHits, g_Round.players[slot].accuracy.shotgunShots);
		Announce_FormatAccuracyCell(smgRifleValues[i], sizeof(smgRifleValues[]), g_Round.players[slot].accuracy.smgRifleHits, g_Round.players[slot].accuracy.smgRifleShots);
		Announce_FormatAccuracyCell(sniperValues[i], sizeof(sniperValues[]), g_Round.players[slot].accuracy.sniperHits, g_Round.players[slot].accuracy.sniperShots);
		Announce_FormatAccuracyCell(pistolValues[i], sizeof(pistolValues[]), g_Round.players[slot].accuracy.pistolHits, g_Round.players[slot].accuracy.pistolShots);
	}

	Announce_AddMetricStringRow(panel, shotgunLabel, survivorCount,
		shotgunValues[0],
		survivorCount > 1 ? shotgunValues[1] : "",
		survivorCount > 2 ? shotgunValues[2] : "",
		survivorCount > 3 ? shotgunValues[3] : "");
	Announce_AddMetricStringRow(panel, smgRifleLabel, survivorCount,
		smgRifleValues[0],
		survivorCount > 1 ? smgRifleValues[1] : "",
		survivorCount > 2 ? smgRifleValues[2] : "",
		survivorCount > 3 ? smgRifleValues[3] : "");
	Announce_AddMetricStringRow(panel, sniperLabel, survivorCount,
		sniperValues[0],
		survivorCount > 1 ? sniperValues[1] : "",
		survivorCount > 2 ? sniperValues[2] : "",
		survivorCount > 3 ? sniperValues[3] : "");
	Announce_AddMetricStringRow(panel, pistolLabel, survivorCount,
		pistolValues[0],
		survivorCount > 1 ? pistolValues[1] : "",
		survivorCount > 2 ? pistolValues[2] : "",
		survivorCount > 3 ? pistolValues[3] : "");

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderAccuracyDetailsPanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char titleName[64];
	char playerLabel[16];
	char weaponLabel[16];
	char hitsLabel[12];
	char shotsLabel[12];
	char accLabel[12];
	char hsLabel[8];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(playerLabel, sizeof(playerLabel), "ColumnPlayer", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(weaponLabel, sizeof(weaponLabel), "ColumnWeapon", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(hitsLabel, sizeof(hitsLabel), "ColumnHits", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(shotsLabel, sizeof(shotsLabel), "ColumnShots", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(accLabel, sizeof(accLabel), "ColumnAcc", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(hsLabel, sizeof(hsLabel), "ColumnHeadshots", client > 0 ? client : LANG_SERVER);
	Format(line, sizeof(line), "%T", "PanelTitleAccuracyDetails", client > 0 ? client : LANG_SERVER, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, playerLabel, 16, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, weaponLabel, 14, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, hitsLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, shotsLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, accLabel, 5, ConsoleTableAlignment_Right, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, hsLabel, 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	int survivorSlots[8];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	bool hasDetails = false;
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		int detailOrder[PlayerStatsWeaponDetail_Count];
		int detailCount = 0;

		for (int detail = view_as<int>(PlayerStatsWeaponDetail_None) + 1; detail < view_as<int>(PlayerStatsWeaponDetail_Count); detail++)
		{
			int shots = g_Round.players[slot].accuracyDetails.shots[detail];
			if (shots <= 0)
			{
				continue;
			}

			detailOrder[detailCount++] = detail;
		}

		for (int a = 1; a < detailCount; a++)
		{
			int key = detailOrder[a];
			int keyShots = g_Round.players[slot].accuracyDetails.shots[key];
			int keyHits = g_Round.players[slot].accuracyDetails.hits[key];
			int b = a - 1;

			while (b >= 0)
			{
				int current = detailOrder[b];
				int currentShots = g_Round.players[slot].accuracyDetails.shots[current];
				int currentHits = g_Round.players[slot].accuracyDetails.hits[current];
				if (currentShots > keyShots)
				{
					break;
				}

				if (currentShots == keyShots && currentHits >= keyHits)
				{
					break;
				}

				detailOrder[b + 1] = current;
				b--;
			}

			detailOrder[b + 1] = key;
		}

		for (int j = 0; j < detailCount; j++)
		{
			if (!ConsoleTable_BeginRow(panel.table))
			{
				break;
			}

			int detail = detailOrder[j];
			int shots = g_Round.players[slot].accuracyDetails.shots[detail];
			int hits = g_Round.players[slot].accuracyDetails.hits[detail];
			int headshots = g_Round.players[slot].accuracyDetails.headshots[detail];
			char weaponName[32];
			char accuracy[16];
			Stats_GetWeaponDetailName(view_as<PlayerStatsWeaponDetailType>(detail), weaponName, sizeof(weaponName), client > 0 ? client : LANG_SERVER);
			Format(accuracy, sizeof(accuracy), "%d%%", Announce_GetPercent(hits, shots));

			ConsoleTable_AddStringCell(panel.table, j == 0 ? g_Round.players[slot].player.name : "");
			ConsoleTable_AddStringCell(panel.table, weaponName);
			ConsoleTable_AddIntCell(panel.table, hits);
			ConsoleTable_AddIntCell(panel.table, shots);
			ConsoleTable_AddStringCell(panel.table, accuracy);
			ConsoleTable_AddIntCell(panel.table, headshots);
			ConsoleTable_EndRow(panel.table);
			hasDetails = true;
		}
	}

	if (!hasDetails)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderUtilitiesPanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	bool rendered = false;
	rendered = Announce_RenderMolotovPanel(client) || rendered;
	rendered = Announce_RenderBilePanel(client) || rendered;
	rendered = Announce_RenderPipePanel(client) || rendered;

	if (!rendered)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
	}

	return rendered;
}

bool Announce_RenderConsumablesPanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasConsumableStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByConsumables(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char titleName[64];
	char pillsLabel[8];
	char adrLabel[8];
	char kitsLabel[8];
	char defibLabel[8];
	bool showAdrenaline = Announce_ShouldShowAdrenalineConsumable();
	bool showDefib = Announce_ShouldShowDefibConsumable();
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(pillsLabel, sizeof(pillsLabel), "ColumnPills", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(adrLabel, sizeof(adrLabel), "ColumnAdr", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(kitsLabel, sizeof(kitsLabel), "ColumnKits", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(defibLabel, sizeof(defibLabel), "ColumnDefib", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(pillsLabel, sizeof(pillsLabel), pillsLabel, "#");
	Announce_FormatMetricUnitLabel(adrLabel, sizeof(adrLabel), adrLabel, "#");
	Announce_FormatMetricUnitLabel(kitsLabel, sizeof(kitsLabel), kitsLabel, "#");
	Announce_FormatMetricUnitLabel(defibLabel, sizeof(defibLabel), defibLabel, "#");
	Format(line, sizeof(line), "%T", "PanelTitleConsumableStats", client > 0 ? client : LANG_SERVER, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_FormatConsumableTotalsLine(line, sizeof(line), client > 0 ? client : LANG_SERVER, showAdrenaline, showDefib);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, pillsLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.pillsUsed,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.pillsUsed : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.pillsUsed : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.pillsUsed : 0);
	Announce_AddMetricRow(panel, kitsLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.medkitsUsed,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.medkitsUsed : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.medkitsUsed : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.medkitsUsed : 0);

	if (showAdrenaline)
	{
		Announce_AddMetricRow(panel, adrLabel, survivorCount,
			g_Round.players[survivorSlots[0]].resources.adrenalineUsed,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.adrenalineUsed : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.adrenalineUsed : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.adrenalineUsed : 0);
	}

	if (showDefib)
	{
		Announce_AddMetricRow(panel, defibLabel, survivorCount,
			g_Round.players[survivorSlots[0]].resources.defibsUsed,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.defibsUsed : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.defibsUsed : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.defibsUsed : 0);
	}

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderSupportPanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasSupportStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsBySupport(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, client > 0 ? client : LANG_SERVER, "PanelTitleSupportStats", "PanelTotalsSupport",
		g_Round.totals.survivorTotalHealsGiven,
		g_Round.totals.survivorTotalRevivesGiven,
		g_Round.totals.survivorTotalRescuesGiven);

	char healsLabel[16];
	char revLabel[16];
	char rescLabel[16];
	Format(healsLabel, sizeof(healsLabel), "%T", "PanelSupportHeals", client > 0 ? client : LANG_SERVER);
	Format(revLabel, sizeof(revLabel), "%T", "PanelSupportRevives", client > 0 ? client : LANG_SERVER);
	Format(rescLabel, sizeof(rescLabel), "%T", "PanelSupportRescues", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(healsLabel, sizeof(healsLabel), healsLabel, "#");
	Announce_FormatMetricUnitLabel(revLabel, sizeof(revLabel), revLabel, "#");
	Announce_FormatMetricUnitLabel(rescLabel, sizeof(rescLabel), rescLabel, "#");

	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, healsLabel, survivorCount,
		g_Round.players[survivorSlots[0]].support.healsGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].support.healsGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].support.healsGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].support.healsGiven : 0);
	Announce_AddMetricRow(panel, revLabel, survivorCount,
		g_Round.players[survivorSlots[0]].support.revivesGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].support.revivesGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].support.revivesGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].support.revivesGiven : 0);
	Announce_AddMetricRow(panel, rescLabel, survivorCount,
		g_Round.players[survivorSlots[0]].support.rescuesGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].support.rescuesGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].support.rescuesGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].support.rescuesGiven : 0);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderScavengePanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasScavengeStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByScavenge(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, client > 0 ? client : LANG_SERVER, "PanelTitleScavengeStats", "PanelTotalsScavenge",
		g_Round.totals.survivorTotalGascansPoured,
		g_Round.totals.survivorTotalGascansDropped,
		g_Round.totals.survivorTotalGascansDestroyed);

	char pouredLabel[16];
	char droppedLabel[16];
	char destroyedLabel[16];
	char line[128];
	Format(pouredLabel, sizeof(pouredLabel), "%T", "ColumnPoured", client > 0 ? client : LANG_SERVER);
	Format(droppedLabel, sizeof(droppedLabel), "%T", "ColumnDropped", client > 0 ? client : LANG_SERVER);
	Format(destroyedLabel, sizeof(destroyedLabel), "%T", "ColumnDestroyed", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(pouredLabel, sizeof(pouredLabel), pouredLabel, "#");
	Announce_FormatMetricUnitLabel(droppedLabel, sizeof(droppedLabel), droppedLabel, "#");
	Announce_FormatMetricUnitLabel(destroyedLabel, sizeof(destroyedLabel), destroyedLabel, "#");

	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, pouredLabel, survivorCount,
		g_Round.players[survivorSlots[0]].scavenge.gascansPoured,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].scavenge.gascansPoured : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].scavenge.gascansPoured : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].scavenge.gascansPoured : 0);
	Announce_AddMetricRow(panel, droppedLabel, survivorCount,
		g_Round.players[survivorSlots[0]].scavenge.gascansDropped,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].scavenge.gascansDropped : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].scavenge.gascansDropped : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].scavenge.gascansDropped : 0);
	Announce_AddMetricRow(panel, destroyedLabel, survivorCount,
		g_Round.players[survivorSlots[0]].scavenge.gascansDestroyed,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].scavenge.gascansDestroyed : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].scavenge.gascansDestroyed : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].scavenge.gascansDestroyed : 0);

	Format(line, sizeof(line), "%T", "PanelScavengeGoal", client > 0 ? client : LANG_SERVER, g_Round.meta.scavengeItemsGoal);
	ConsolePanel_AddFooterLine(panel, line);
	Format(line, sizeof(line), "%T", g_Round.meta.scavengeInSecondHalf ? "PanelScavengeHalfSecond" : "PanelScavengeHalfFirst", client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddFooterLine(panel, line);
	Format(line, sizeof(line), "%T", g_Round.meta.scavengeWentOvertime ? "PanelScavengeOvertimeYes" : "PanelScavengeOvertimeNo", client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddFooterLine(panel, line);
	Format(line, sizeof(line), "%T", g_Round.meta.scavengeScoreTied ? "PanelScavengeScoreTiedYes" : "PanelScavengeScoreTiedNo", client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddFooterLine(panel, line);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderRoundConsolePanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasCombatStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[128];
	char damageLabel[12];
	char siLabel[12];
	char siKillsLabel[12];
	char tankLabel[12];
	char witchLabel[12];
	char ciLabel[12];
	char ffLabel[12];
	Announce_FormatPanelTitle(line, sizeof(line), client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddHeaderLine(panel, line);
	Announce_GetColumnLabel(damageLabel, sizeof(damageLabel), "ColumnDamage", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(siLabel, sizeof(siLabel), "ColumnSI", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(siKillsLabel, sizeof(siKillsLabel), "ColumnSIKills", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(tankLabel, sizeof(tankLabel), "ColumnTank", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(witchLabel, sizeof(witchLabel), "ColumnWitch", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(ciLabel, sizeof(ciLabel), "ColumnCI", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(ffLabel, sizeof(ffLabel), "ColumnFF", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(damageLabel, sizeof(damageLabel), "ColumnDamageShort", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(siLabel, sizeof(siLabel), siLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(siKillsLabel, sizeof(siKillsLabel), siKillsLabel, "#");
	Announce_FormatMetricUnitLabel(tankLabel, sizeof(tankLabel), tankLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(witchLabel, sizeof(witchLabel), witchLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(ciLabel, sizeof(ciLabel), ciLabel, "#");
	Announce_FormatMetricUnitLabel(ffLabel, sizeof(ffLabel), ffLabel, "dmg", false);

	int totalDamage = Announce_GetTotalSurvivorDamage();
	Format(line, sizeof(line), "%T", "PanelTotalsCombat", client > 0 ? client : LANG_SERVER,
		totalDamage,
		Announce_GetTotalSurvivorSpecialKills(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);
	ConsolePanel_AddHeaderLine(panel, line);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();

	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, damageLabel, survivorCount,
		Announce_GetPlayerDamageScore(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerDamageScore(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerDamageScore(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerDamageScore(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, siLabel, survivorCount,
		Announce_GetPlayerSiDamage(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerSiDamage(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerSiDamage(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerSiDamage(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, siKillsLabel, survivorCount,
		Announce_GetPlayerSpecialKills(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerSpecialKills(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerSpecialKills(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerSpecialKills(survivorSlots[3]) : 0);
	if (showTank)
	{
		Announce_AddMetricRow(panel, tankLabel, survivorCount,
			g_Round.players[survivorSlots[0]].combat.tankDamage,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.tankDamage : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.tankDamage : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.tankDamage : 0);
	}
	if (showWitch)
	{
		Announce_AddMetricRow(panel, witchLabel, survivorCount,
			g_Round.players[survivorSlots[0]].combat.witchDamage,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.witchDamage : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.witchDamage : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.witchDamage : 0);
	}
	Announce_AddMetricRow(panel, ciLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.commonKills,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.commonKills : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.commonKills : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.commonKills : 0);
	Announce_AddMetricRow(panel, ffLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.ffGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.ffGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.ffGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.ffGiven : 0);

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	if (Announce_GetTotalSurvivorDamage() <= 0)
	{
		siMvp = -1;
	}

	if (g_Round.totals.survivorTotalCommonKills <= 0)
	{
		ciMvp = -1;
	}

	Announce_FormatRoundDurationLine(line, sizeof(line));
	ConsolePanel_AddFooterLine(panel, line);

	if (Stats_IsValidRoundSlot(siMvp))
	{
		Announce_FormatMvPDamageConsoleLine(line, sizeof(line), siMvp);
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		Format(line, sizeof(line), "%T", "PanelMVPCommon", client > 0 ? client : LANG_SERVER,
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		Format(line, sizeof(line), "%T", "PanelFFLVPNone", client > 0 ? client : LANG_SERVER);
		ConsolePanel_AddFooterLine(panel, line);
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		Format(line, sizeof(line), "%T", "PanelFFLVP", client > 0 ? client : LANG_SERVER,
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		ConsolePanel_AddFooterLine(panel, line);
	}

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

void Announce_BroadcastRoundConsolePanel()
{
	if (!Stats_HasRoundSnapshot())
	{
		return;
	}

	if (!Announce_HasCombatStats())
	{
		return;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[128];
	Announce_FormatPanelTitle(line, sizeof(line), LANG_SERVER);
	ConsolePanel_AddHeaderLine(panel, line);
	char damageLabel[12];
	char siLabel[12];
	char siKillsLabel[12];
	char tankLabel[12];
	char witchLabel[12];
	char ciLabel[12];
	char ffLabel[12];
	Announce_GetColumnLabel(damageLabel, sizeof(damageLabel), "ColumnDamage", LANG_SERVER);
	Announce_GetColumnLabel(siLabel, sizeof(siLabel), "ColumnSI", LANG_SERVER);
	Announce_GetColumnLabel(siKillsLabel, sizeof(siKillsLabel), "ColumnSIKills", LANG_SERVER);
	Announce_GetColumnLabel(tankLabel, sizeof(tankLabel), "ColumnTank", LANG_SERVER);
	Announce_GetColumnLabel(witchLabel, sizeof(witchLabel), "ColumnWitch", LANG_SERVER);
	Announce_GetColumnLabel(ciLabel, sizeof(ciLabel), "ColumnCI", LANG_SERVER);
	Announce_GetColumnLabel(ffLabel, sizeof(ffLabel), "ColumnFF", LANG_SERVER);
	Announce_GetColumnLabel(damageLabel, sizeof(damageLabel), "ColumnDamageShort", LANG_SERVER);
	Announce_FormatMetricUnitLabel(siLabel, sizeof(siLabel), siLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(siKillsLabel, sizeof(siKillsLabel), siKillsLabel, "#");
	Announce_FormatMetricUnitLabel(tankLabel, sizeof(tankLabel), tankLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(witchLabel, sizeof(witchLabel), witchLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(ciLabel, sizeof(ciLabel), ciLabel, "#");
	Announce_FormatMetricUnitLabel(ffLabel, sizeof(ffLabel), ffLabel, "dmg", false);

	int totalDamage = Announce_GetTotalSurvivorDamage();
	Format(line, sizeof(line), "%T", "PanelTotalsCombat", LANG_SERVER,
		totalDamage,
		Announce_GetTotalSurvivorSpecialKills(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);
	ConsolePanel_AddHeaderLine(panel, line);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();

	Announce_AddMetricPlayerColumns(panel, LANG_SERVER, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, damageLabel, survivorCount,
		Announce_GetPlayerDamageScore(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerDamageScore(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerDamageScore(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerDamageScore(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, siLabel, survivorCount,
		Announce_GetPlayerSiDamage(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerSiDamage(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerSiDamage(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerSiDamage(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, siKillsLabel, survivorCount,
		Announce_GetPlayerSpecialKills(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerSpecialKills(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerSpecialKills(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerSpecialKills(survivorSlots[3]) : 0);
	if (showTank)
	{
		Announce_AddMetricRow(panel, tankLabel, survivorCount,
			g_Round.players[survivorSlots[0]].combat.tankDamage,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.tankDamage : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.tankDamage : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.tankDamage : 0);
	}
	if (showWitch)
	{
		Announce_AddMetricRow(panel, witchLabel, survivorCount,
			g_Round.players[survivorSlots[0]].combat.witchDamage,
			survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.witchDamage : 0,
			survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.witchDamage : 0,
			survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.witchDamage : 0);
	}
	Announce_AddMetricRow(panel, ciLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.commonKills,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.commonKills : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.commonKills : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.commonKills : 0);
	Announce_AddMetricRow(panel, ffLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.ffGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.ffGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.ffGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.ffGiven : 0);

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	if (Announce_GetTotalSurvivorDamage() <= 0)
	{
		siMvp = -1;
	}

	if (g_Round.totals.survivorTotalCommonKills <= 0)
	{
		ciMvp = -1;
	}

	Announce_FormatRoundDurationLine(line, sizeof(line));
	ConsolePanel_AddFooterLine(panel, line);

	if (Stats_IsValidRoundSlot(siMvp))
	{
		Announce_FormatMvPDamageConsoleLine(line, sizeof(line), siMvp);
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		Format(line, sizeof(line), "%T", "PanelMVPCommon", LANG_SERVER,
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		Format(line, sizeof(line), "%T", "PanelFFLVPNone", LANG_SERVER);
		ConsolePanel_AddFooterLine(panel, line);
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		Format(line, sizeof(line), "%T", "PanelFFLVP", LANG_SERVER,
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		ConsolePanel_AddFooterLine(panel, line);
	}

	ConsolePanel_RenderToAudience(panel);
}

bool Announce_BroadcastUtilitiesConsolePanel()
{
	if (!Stats_HasRoundSnapshot())
	{
		return false;
	}

	bool rendered = false;
	rendered = Announce_BroadcastMolotovPanel() || rendered;
	rendered = Announce_BroadcastBilePanel() || rendered;
	rendered = Announce_BroadcastPipePanel() || rendered;
	return rendered;
}

bool Announce_HasMolotovUtilityStats()
{
	return Announce_ShouldShowMolotovUtility()
		&& (g_Round.totals.survivorTotalMolotovsThrown > 0 || g_Round.totals.survivorTotalZombiesIgnited > 0);
}

bool Announce_HasPipebombUtilityStats()
{
	return Announce_ShouldShowPipebombUtility()
		&& g_Round.totals.survivorTotalPipebombsThrown > 0;
}

bool Announce_HasVomitjarUtilityStats()
{
	return Announce_ShouldShowVomitjarUtility()
		&& (g_Round.totals.survivorTotalVomitjarsThrown > 0 || g_Round.totals.survivorTotalPlayersBiled > 0 || g_Round.totals.survivorTotalTanksBiled > 0);
}

void Announce_GetUtilitySurvivorSlots(int[] survivorSlots, int &survivorCount)
{
	survivorCount = Announce_CollectSortedSurvivorSlotsByUtility(survivorSlots, L4D2_PLAYER_STATS_MAX_SURVIVORS);
}

void Announce_AddMetricRow(ConsolePanel panel, const char[] metricLabel, int survivorCount, int valueA, int valueB = 0, int valueC = 0, int valueD = 0)
{
	if (!ConsoleTable_BeginRow(panel.table))
	{
		return;
	}

	ConsoleTable_AddStringCell(panel.table, metricLabel);

	int values[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	values[0] = valueA;
	values[1] = valueB;
	values[2] = valueC;
	values[3] = valueD;

	for (int i = 0; i < survivorCount; i++)
	{
		ConsoleTable_AddIntCell(panel.table, values[i]);
	}

	ConsoleTable_EndRow(panel.table);
}

void Announce_AddMetricStringRow(ConsolePanel panel, const char[] metricLabel, int survivorCount, const char[] valueA, const char[] valueB = "", const char[] valueC = "", const char[] valueD = "")
{
	if (!ConsoleTable_BeginRow(panel.table))
	{
		return;
	}

	ConsoleTable_AddStringCell(panel.table, metricLabel);

	char values[L4D2_PLAYER_STATS_MAX_SURVIVORS][32];
	strcopy(values[0], sizeof(values[]), valueA);
	strcopy(values[1], sizeof(values[]), valueB);
	strcopy(values[2], sizeof(values[]), valueC);
	strcopy(values[3], sizeof(values[]), valueD);

	for (int i = 0; i < survivorCount; i++)
	{
		ConsoleTable_AddStringCell(panel.table, values[i]);
	}

	ConsoleTable_EndRow(panel.table);
}

void Announce_BuildMetricPanel(ConsolePanel panel, int phraseTarget, const char[] titlePhrase, const char[] totalsPhrase, int totalA, int totalB = 0, int totalC = 0)
{
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	char titleName[64];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, phraseTarget);
	Format(line, sizeof(line), "%T", titlePhrase, phraseTarget, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "%T", totalsPhrase, phraseTarget, totalA, totalB, totalC);
	ConsolePanel_AddHeaderLine(panel, line);
}

void Announce_AddMetricPlayerColumns(ConsolePanel panel, int phraseTarget, int[] survivorSlots, int survivorCount)
{
	char metricLabel[16];
	Format(metricLabel, sizeof(metricLabel), "%T", "ColumnMetric", phraseTarget);
	ConsoleTable_AddColumn(panel.table, metricLabel, 12, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < survivorCount; i++)
	{
		ConsoleTable_AddColumn(panel.table, g_Round.players[survivorSlots[i]].player.name, 14, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
}

void Announce_AddMetricPlayerStringColumns(ConsolePanel panel, int phraseTarget, int[] survivorSlots, int survivorCount)
{
	char metricLabel[16];
	Format(metricLabel, sizeof(metricLabel), "%T", "ColumnMetric", phraseTarget);
	ConsoleTable_AddColumn(panel.table, metricLabel, 12, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < survivorCount; i++)
	{
		ConsoleTable_AddColumn(panel.table, g_Round.players[survivorSlots[i]].player.name, 14, ConsoleTableAlignment_Right, ConsoleTableCellType_String);
	}
}

bool Announce_RenderMolotovPanel(int client)
{
	if (!Announce_HasMolotovUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, client > 0 ? client : LANG_SERVER, "PanelTitleMolotovStats", "PanelTotalsMolotov",
		g_Round.totals.survivorTotalMolotovsThrown,
		g_Round.totals.survivorTotalZombiesIgnited);
	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	char ignitedLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", client > 0 ? client : LANG_SERVER);
	Format(ignitedLabel, sizeof(ignitedLabel), "%T", "ColumnIgnited", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_FormatMetricUnitLabel(ignitedLabel, sizeof(ignitedLabel), ignitedLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.molotovsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.molotovsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.molotovsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.molotovsThrown : 0);
	Announce_AddMetricRow(panel, ignitedLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.zombiesIgnited,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.zombiesIgnited : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.zombiesIgnited : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.zombiesIgnited : 0);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderBilePanel(int client)
{
	if (!Announce_HasVomitjarUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, client > 0 ? client : LANG_SERVER, "PanelTitleBileStats", "PanelTotalsBile",
		g_Round.totals.survivorTotalVomitjarsThrown,
		g_Round.totals.survivorTotalPlayersBiled,
		g_Round.totals.survivorTotalTanksBiled);
	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	char playersLabel[16];
	char tankLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", client > 0 ? client : LANG_SERVER);
	Format(playersLabel, sizeof(playersLabel), "%T", "ColumnPlayers", client > 0 ? client : LANG_SERVER);
	Format(tankLabel, sizeof(tankLabel), "%T", "ColumnTank", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_FormatMetricUnitLabel(playersLabel, sizeof(playersLabel), playersLabel, "#");
	Announce_FormatMetricUnitLabel(tankLabel, sizeof(tankLabel), tankLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.vomitjarsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.vomitjarsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.vomitjarsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.vomitjarsThrown : 0);
	Announce_AddMetricRow(panel, playersLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.playersBiled,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.playersBiled : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.playersBiled : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.playersBiled : 0);
	Announce_AddMetricRow(panel, tankLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.tanksBiled,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.tanksBiled : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.tanksBiled : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.tanksBiled : 0);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderPipePanel(int client)
{
	if (!Announce_HasPipebombUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, client > 0 ? client : LANG_SERVER, "PanelTitlePipeStats", "PanelTotalsPipe",
		g_Round.totals.survivorTotalPipebombsThrown);
	Announce_AddMetricPlayerColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", client > 0 ? client : LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.pipebombsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.pipebombsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.pipebombsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.pipebombsThrown : 0);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_BroadcastMolotovPanel()
{
	if (!Announce_HasMolotovUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, LANG_SERVER, "PanelTitleMolotovStats", "PanelTotalsMolotov",
		g_Round.totals.survivorTotalMolotovsThrown,
		g_Round.totals.survivorTotalZombiesIgnited);
	Announce_AddMetricPlayerColumns(panel, LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	char ignitedLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", LANG_SERVER);
	Format(ignitedLabel, sizeof(ignitedLabel), "%T", "ColumnIgnited", LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_FormatMetricUnitLabel(ignitedLabel, sizeof(ignitedLabel), ignitedLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.molotovsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.molotovsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.molotovsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.molotovsThrown : 0);
	Announce_AddMetricRow(panel, ignitedLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.zombiesIgnited,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.zombiesIgnited : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.zombiesIgnited : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.zombiesIgnited : 0);

	ConsolePanel_RenderToAudience(panel);
	return true;
}

bool Announce_BroadcastBilePanel()
{
	if (!Announce_HasVomitjarUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, LANG_SERVER, "PanelTitleBileStats", "PanelTotalsBile",
		g_Round.totals.survivorTotalVomitjarsThrown,
		g_Round.totals.survivorTotalPlayersBiled,
		g_Round.totals.survivorTotalTanksBiled);
	Announce_AddMetricPlayerColumns(panel, LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	char playersLabel[16];
	char tankLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", LANG_SERVER);
	Format(playersLabel, sizeof(playersLabel), "%T", "ColumnPlayers", LANG_SERVER);
	Format(tankLabel, sizeof(tankLabel), "%T", "ColumnTank", LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_FormatMetricUnitLabel(playersLabel, sizeof(playersLabel), playersLabel, "#");
	Announce_FormatMetricUnitLabel(tankLabel, sizeof(tankLabel), tankLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.vomitjarsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.vomitjarsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.vomitjarsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.vomitjarsThrown : 0);
	Announce_AddMetricRow(panel, playersLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.playersBiled,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.playersBiled : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.playersBiled : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.playersBiled : 0);
	Announce_AddMetricRow(panel, tankLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.tanksBiled,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.tanksBiled : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.tanksBiled : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.tanksBiled : 0);

	ConsolePanel_RenderToAudience(panel);
	return true;
}

bool Announce_BroadcastPipePanel()
{
	if (!Announce_HasPipebombUtilityStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = 0;
	Announce_GetUtilitySurvivorSlots(survivorSlots, survivorCount);
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	Announce_BuildMetricPanel(panel, LANG_SERVER, "PanelTitlePipeStats", "PanelTotalsPipe",
		g_Round.totals.survivorTotalPipebombsThrown);
	Announce_AddMetricPlayerColumns(panel, LANG_SERVER, survivorSlots, survivorCount);

	char countLabel[16];
	Format(countLabel, sizeof(countLabel), "%T", "ColumnCount", LANG_SERVER);
	Announce_FormatMetricUnitLabel(countLabel, sizeof(countLabel), countLabel, "#");
	Announce_AddMetricRow(panel, countLabel, survivorCount,
		g_Round.players[survivorSlots[0]].resources.pipebombsThrown,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].resources.pipebombsThrown : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].resources.pipebombsThrown : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].resources.pipebombsThrown : 0);

	ConsolePanel_RenderToAudience(panel);
	return true;
}

void Announce_PrintRoundSummaryLines(int client, int siMvp, int ciMvp, int ffLvp)
{
	if (Stats_IsValidRoundSlot(siMvp))
	{
		char line[256];
		Announce_FormatMvPDamageLine(line, sizeof(line), siMvp, Announce_GetPhraseTarget(client));
		Announce_PrintMessage(client, line, false);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		char line[256];
		Format(line, sizeof(line), "%T", "RoundMVPCommon", Announce_GetPhraseTarget(client),
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		Announce_PrintMessage(client, line, false);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		char line[256];
		Format(line, sizeof(line), "%T", "RoundNoFF", Announce_GetPhraseTarget(client));
		Announce_PrintMessage(client, line, false);
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		char line[256];
		Format(line, sizeof(line), "%T", "RoundLVPFF", Announce_GetPhraseTarget(client),
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		Announce_PrintMessage(client, line, false);
	}
}

void Announce_PrintMessage(int client, const char[] message, bool withTag = true)
{
	if (client > 0 && IsValidClient(client))
	{
		if (withTag)
		{
			CReplyToCommand(client, "%t %s", "Tag", message);
		}
		else
		{
			CReplyToCommand(client, "%s", message);
		}
		return;
	}

	if (withTag)
	{
		CPrintToChatAll("%t %s", "Tag", message);
	}
	else
	{
		CPrintToChatAll("%s", message);
	}
}

bool Announce_ShouldShowTankDamage()
{
	if (g_Round.meta.storedTankPercent >= 0)
	{
		return g_Round.meta.storedTankPercent != 0;
	}

	if (!g_Runtime.hasBossPercents || GetFeatureStatus(FeatureType_Native, "GetStoredTankPercent") == FeatureStatus_Unknown)
	{
		return true;
	}

	int tankPercent = GetStoredTankPercent();
	return tankPercent != 0;
}

bool Announce_ShouldShowWitchDamage()
{
	if (g_Round.meta.storedWitchPercent >= 0)
	{
		return g_Round.meta.storedWitchPercent != 0;
	}

	if (!g_Runtime.hasBossPercents || GetFeatureStatus(FeatureType_Native, "GetStoredWitchPercent") == FeatureStatus_Unknown)
	{
		return true;
	}

	int witchPercent = GetStoredWitchPercent();
	return witchPercent != 0;
}

int Announce_GetPhraseTarget(int client = 0)
{
	return (client > 0 && IsValidClient(client)) ? client : LANG_SERVER;
}

int Announce_GetEncounteredTankCount()
{
	return g_Round.tankVictimCount;
}

int Announce_GetEncounteredWitchCount()
{
	return g_Round.witchEntityCount;
}

void Announce_FormatPanelTitle(char[] buffer, int maxlen, int client = LANG_SERVER)
{
	int tankCount = Announce_GetEncounteredTankCount();
	int witchCount = Announce_GetEncounteredWitchCount();
	char titleName[64];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client);

	if (tankCount > 1 && witchCount > 1)
	{
		Format(buffer, maxlen, "%T", "PanelTitleRoundTankWitch", client, titleName, g_Round.meta.id, tankCount, witchCount);
		return;
	}

	if (tankCount > 1)
	{
		Format(buffer, maxlen, "%T", "PanelTitleRoundTank", client, titleName, g_Round.meta.id, tankCount);
		return;
	}

	if (witchCount > 1)
	{
		Format(buffer, maxlen, "%T", "PanelTitleRoundWitch", client, titleName, g_Round.meta.id, witchCount);
		return;
	}

	Format(buffer, maxlen, "%T", "PanelTitleRound", client, titleName, g_Round.meta.id);
}

void Announce_FormatRoundDurationLine(char[] buffer, int maxlen)
{
	int durationSeconds = 0;

	if (g_Round.meta.startedAt > 0.0)
	{
		float endedAt = g_Round.meta.endedAt > 0.0 ? g_Round.meta.endedAt : GetGameTime();
		float elapsed = endedAt - g_Round.meta.startedAt;
		if (elapsed > 0.0)
		{
			durationSeconds = RoundToFloor(elapsed);
		}
	}

	int minutes = durationSeconds / 60;
	int seconds = durationSeconds % 60;
	char duration[16];
	Format(duration, sizeof(duration), "%dm %02ds", minutes, seconds);
	Format(buffer, maxlen, "%T", "PanelRoundDuration", LANG_SERVER, duration);
}

void Announce_FormatAccuracyCell(char[] buffer, int maxlen, int hits, int shots)
{
	Format(buffer, maxlen, "%d/%d %d%%", hits, shots, Announce_GetPercent(hits, shots));
}

void Announce_FormatMvPDamageLine(char[] buffer, int maxlen, int slot, int phraseTarget = LANG_SERVER)
{
	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();
	int siDamage = Announce_GetPlayerSiDamage(slot);
	int siPercent = Announce_GetPercent(siDamage, Announce_GetTotalSurvivorSiDamage());
	int tankDamage = g_Round.players[slot].combat.tankDamage;
	int tankPercent = Announce_GetPercent(tankDamage, g_Round.totals.survivorTotalTankDamage);
	int tankCount = Announce_GetEncounteredTankCount();
	int witchDamage = g_Round.players[slot].combat.witchDamage;
	int witchPercent = Announce_GetPercent(witchDamage, g_Round.totals.survivorTotalWitchDamage);
	int witchCount = Announce_GetEncounteredWitchCount();

	Format(buffer, maxlen, "%T", "RoundMVPDamageBase", phraseTarget,
		g_Round.players[slot].player.name,
		siDamage,
		siPercent);

	char tankDetail[64];
	char witchDetail[64];
	tankDetail[0] = '\0';
	witchDetail[0] = '\0';

	if (showTank && tankDamage > 0)
	{
		if (tankCount > 1)
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "RoundMVPDamageTankCount", phraseTarget, tankDamage, tankCount);
		}
		else
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "RoundMVPDamageTankPercent", phraseTarget, tankDamage, tankPercent);
		}
	}

	if (showWitch && witchDamage > 0)
	{
		if (witchCount > 1)
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "RoundMVPDamageWitchCount", phraseTarget, witchDamage, witchCount);
		}
		else
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "RoundMVPDamageWitchPercent", phraseTarget, witchDamage, witchPercent);
		}
	}

	if (tankDetail[0] != '\0' && witchDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s {blue}(%s %s).{default}", buffer, tankDetail, witchDetail);
		return;
	}

	if (tankDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s {blue}(%s).{default}", buffer, tankDetail);
		return;
	}

	if (witchDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s {blue}(%s).{default}", buffer, witchDetail);
		return;
	}

	Format(buffer, maxlen, "%s.", buffer);
}

void Announce_FormatMvPDamageConsoleLine(char[] buffer, int maxlen, int slot)
{
	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();
	int siDamage = Announce_GetPlayerSiDamage(slot);
	int siPercent = Announce_GetPercent(siDamage, Announce_GetTotalSurvivorSiDamage());
	int tankDamage = g_Round.players[slot].combat.tankDamage;
	int tankPercent = Announce_GetPercent(tankDamage, g_Round.totals.survivorTotalTankDamage);
	int tankCount = Announce_GetEncounteredTankCount();
	int witchDamage = g_Round.players[slot].combat.witchDamage;
	int witchPercent = Announce_GetPercent(witchDamage, g_Round.totals.survivorTotalWitchDamage);
	int witchCount = Announce_GetEncounteredWitchCount();

	Format(buffer, maxlen, "%T", "PanelMVPDamageBase", LANG_SERVER,
		g_Round.players[slot].player.name,
		siDamage,
		siPercent);

	char tankDetail[48];
	char witchDetail[48];
	tankDetail[0] = '\0';
	witchDetail[0] = '\0';

	if (showTank && tankDamage > 0)
	{
		if (tankCount > 1)
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "PanelMVPDamageTankCount", LANG_SERVER, tankDamage, tankCount);
		}
		else
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "PanelMVPDamageTankPercent", LANG_SERVER, tankDamage, tankPercent);
		}
	}

	if (showWitch && witchDamage > 0)
	{
		if (witchCount > 1)
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "PanelMVPDamageWitchCount", LANG_SERVER, witchDamage, witchCount);
		}
		else
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "PanelMVPDamageWitchPercent", LANG_SERVER, witchDamage, witchPercent);
		}
	}

	if (tankDetail[0] != '\0' && witchDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s (%s %s).", buffer, tankDetail, witchDetail);
		return;
	}

	if (tankDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s (%s).", buffer, tankDetail);
		return;
	}

	if (witchDetail[0] != '\0')
	{
		Format(buffer, maxlen, "%s (%s).", buffer, witchDetail);
		return;
	}

	Format(buffer, maxlen, "%s.", buffer);
}

void Announce_PrintClientRanks(int client)
{
	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return;
	}

	int index = Stats_GetPlayerRoundIndex(client);
	if (index == -1 || !g_Round.players[index].active)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return;
	}

	int damageRank = Announce_GetDamageRank(client);
	int commonRank = Announce_GetCommonRank(client);
	int ffRank = Announce_GetFFRank(client);

	if (damageRank > 0 && Announce_GetTotalSurvivorDamage() > 0)
	{
		CReplyToCommand(client, "%t", "YourRankDamage",
			damageRank,
			Announce_GetPlayerDamageScore(index),
			Announce_GetPercent(Announce_GetPlayerDamageScore(index), Announce_GetTotalSurvivorDamage()));
	}

	if (commonRank > 0 && g_Round.totals.survivorTotalCommonKills > 0)
	{
		CReplyToCommand(client, "%t", "YourRankCommon",
			commonRank,
			g_Round.players[index].combat.commonKills,
			Announce_GetPercent(g_Round.players[index].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
	}

	if (ffRank > 0 && g_Round.totals.survivorTotalFF > 0)
	{
		CReplyToCommand(client, "%t", "YourRankFF",
			ffRank,
			g_Round.players[index].combat.ffGiven,
			Announce_GetPercent(g_Round.players[index].combat.ffGiven, g_Round.totals.survivorTotalFF));
	}
}

bool Announce_RenderGlobalRankPanel(int client)
{
	if (!IsValidSurvivor(client) || !Stats_HasRoundSnapshot())
	{
		return false;
	}

	if (!Announce_HasCombatStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[128];
	char titleName[64];
	char siRankLabel[8];
	char siLabel[12];
	char ciRankLabel[8];
	char commonLabel[12];
	char ffRankLabel[8];
	char ffLabel[12];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client);
	Announce_GetColumnLabel(siRankLabel, sizeof(siRankLabel), "ColumnSIRank", client);
	Announce_GetColumnLabel(siLabel, sizeof(siLabel), "ColumnSI", client);
	Announce_GetColumnLabel(ciRankLabel, sizeof(ciRankLabel), "ColumnCIRank", client);
	Announce_GetColumnLabel(commonLabel, sizeof(commonLabel), "ColumnCommon", client);
	Announce_GetColumnLabel(ffRankLabel, sizeof(ffRankLabel), "ColumnFFRank", client);
	Announce_GetColumnLabel(ffLabel, sizeof(ffLabel), "ColumnFF", client);
	Announce_FormatMetricUnitLabel(siLabel, sizeof(siLabel), siLabel, "dmg", false);
	Announce_FormatMetricUnitLabel(commonLabel, sizeof(commonLabel), commonLabel, "#");
	Announce_FormatMetricUnitLabel(ffLabel, sizeof(ffLabel), ffLabel, "dmg", false);
	Format(line, sizeof(line), "%T", "PanelTitleGlobalRank", client, titleName);
	ConsolePanel_AddHeaderLine(panel, line);

	char playerName[MAX_NAME_LENGTH];
	Format(playerName, sizeof(playerName), "%N", client);
	Format(line, sizeof(line), "%T", "PanelGlobalRankPlayer", client, playerName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerColumns(panel, client, survivorSlots, survivorCount);
	Announce_AddMetricRow(panel, siRankLabel, survivorCount,
		Announce_GetDamageRankBySlot(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetDamageRankBySlot(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetDamageRankBySlot(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetDamageRankBySlot(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, siLabel, survivorCount,
		Announce_GetPlayerDamageScore(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetPlayerDamageScore(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetPlayerDamageScore(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetPlayerDamageScore(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, ciRankLabel, survivorCount,
		Announce_GetCommonRankBySlot(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetCommonRankBySlot(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetCommonRankBySlot(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetCommonRankBySlot(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, commonLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.commonKills,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.commonKills : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.commonKills : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.commonKills : 0);
	Announce_AddMetricRow(panel, ffRankLabel, survivorCount,
		Announce_GetFFRankBySlot(survivorSlots[0]),
		survivorCount > 1 ? Announce_GetFFRankBySlot(survivorSlots[1]) : 0,
		survivorCount > 2 ? Announce_GetFFRankBySlot(survivorSlots[2]) : 0,
		survivorCount > 3 ? Announce_GetFFRankBySlot(survivorSlots[3]) : 0);
	Announce_AddMetricRow(panel, ffLabel, survivorCount,
		g_Round.players[survivorSlots[0]].combat.ffGiven,
		survivorCount > 1 ? g_Round.players[survivorSlots[1]].combat.ffGiven : 0,
		survivorCount > 2 ? g_Round.players[survivorSlots[2]].combat.ffGiven : 0,
		survivorCount > 3 ? g_Round.players[survivorSlots[3]].combat.ffGiven : 0);

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

int Announce_GetPlayerDamageScore(int index)
{
	return Announce_GetPlayerSiDamage(index) + g_Round.players[index].combat.tankDamage + g_Round.players[index].combat.witchDamage;
}

int Announce_GetPlayerSiDamage(int index)
{
	int total = 0;

	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		total += g_Round.players[index].combat.smokerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		total += g_Round.players[index].combat.boomerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		total += g_Round.players[index].combat.hunterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		total += g_Round.players[index].combat.spitterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		total += g_Round.players[index].combat.jockeyDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		total += g_Round.players[index].combat.chargerDamage;
	}

	return total;
}

int Announce_GetPlayerSpecialKills(int index)
{
	int total = 0;

	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		total += g_Round.players[index].combat.smokerKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		total += g_Round.players[index].combat.boomerKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		total += g_Round.players[index].combat.hunterKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		total += g_Round.players[index].combat.spitterKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		total += g_Round.players[index].combat.jockeyKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		total += g_Round.players[index].combat.chargerKills;
	}

	return total;
}

int Announce_GetTotalSurvivorDamage()
{
	return Announce_GetTotalSurvivorSiDamage() + g_Round.totals.survivorTotalTankDamage + g_Round.totals.survivorTotalWitchDamage;
}

int Announce_GetTotalSurvivorSiDamage()
{
	int total = 0;

	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		total += g_Round.totals.survivorTotalSmokerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		total += g_Round.totals.survivorTotalBoomerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		total += g_Round.totals.survivorTotalHunterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		total += g_Round.totals.survivorTotalSpitterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		total += g_Round.totals.survivorTotalJockeyDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		total += g_Round.totals.survivorTotalChargerDamage;
	}

	return total;
}

int Announce_GetTotalSurvivorSpecialKills()
{
	int total = 0;

	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		total += g_Round.totals.survivorTotalSmokerKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		total += g_Round.totals.survivorTotalBoomerKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		total += g_Round.totals.survivorTotalHunterKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		total += g_Round.totals.survivorTotalSpitterKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		total += g_Round.totals.survivorTotalJockeyKills;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		total += g_Round.totals.survivorTotalChargerKills;
	}

	return total;
}

int Announce_GetPercent(int part, int whole)
{
	return L4D2Util_IntToPercentInt(part, whole);
}

int Announce_FindTopDamageSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
{
	int bestSlot = -1;
	int bestScore = -1;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == excludeA || slot == excludeB || slot == excludeC)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		int score = Announce_GetPlayerDamageScore(slot);
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}

	return bestSlot;
}

int Announce_FindTopCommonSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
{
	int bestSlot = -1;
	int bestScore = -1;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == excludeA || slot == excludeB || slot == excludeC)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		int score = g_Round.players[slot].combat.commonKills;
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}

	return bestSlot;
}

int Announce_FindTopFFSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
{
	int bestSlot = -1;
	int bestScore = -1;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == excludeA || slot == excludeB || slot == excludeC)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		int score = g_Round.players[slot].combat.ffGiven;
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}

	return bestSlot;
}

int Announce_CollectSortedSurvivorSlotsByDamage(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot))
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int key = slots[i];
		int keyScore = Announce_GetPlayerDamageScore(key);
		int j = i - 1;

		while (j >= 0)
		{
			int current = slots[j];
			int currentScore = Announce_GetPlayerDamageScore(current);
			if (currentScore > keyScore)
			{
				break;
			}

			if (currentScore == keyScore && g_Round.players[current].combat.commonKills >= g_Round.players[key].combat.commonKills)
			{
				break;
			}

			slots[j + 1] = current;
			j--;
		}

		slots[j + 1] = key;
	}

	return count;
}

bool Announce_HasCombatStats()
{
	return Announce_GetTotalSurvivorDamage() > 0
		|| Announce_GetTotalSurvivorSpecialKills() > 0
		|| g_Round.totals.survivorTotalCommonKills > 0
		|| g_Round.totals.survivorTotalFF > 0;
}

bool Announce_HasAccuracyStats()
{
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (g_Round.players[slot].accuracy.shotgunShots > 0
			|| g_Round.players[slot].accuracy.smgRifleShots > 0
			|| g_Round.players[slot].accuracy.sniperShots > 0
			|| g_Round.players[slot].accuracy.pistolShots > 0)
		{
			return true;
		}
	}

	return false;
}

bool Announce_HasConsumableStats()
{
	return g_Round.totals.survivorTotalPillsUsed > 0
		|| (Announce_ShouldShowAdrenalineConsumable() && g_Round.totals.survivorTotalAdrenalineUsed > 0)
		|| g_Round.totals.survivorTotalMedkitsUsed > 0
		|| (Announce_ShouldShowDefibConsumable() && g_Round.totals.survivorTotalDefibsUsed > 0);
}

bool Announce_HasSupportStats()
{
	return g_Round.totals.survivorTotalHealsGiven > 0
		|| g_Round.totals.survivorTotalRevivesGiven > 0
		|| g_Round.totals.survivorTotalRescuesGiven > 0;
}

bool Announce_HasScavengeStats()
{
	return g_Round.meta.baseMode == GAMEMODE_SCAVENGE
		&& (g_Round.totals.survivorTotalGascansPoured > 0
			|| g_Round.totals.survivorTotalGascansDropped > 0
			|| g_Round.totals.survivorTotalGascansDestroyed > 0);
}

int Announce_GetPlayerUtilityScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	int total = 0;

	if (Announce_ShouldShowMolotovUtility())
	{
		total += g_Round.players[slot].resources.molotovsThrown + g_Round.players[slot].resources.zombiesIgnited;
	}
	if (Announce_ShouldShowPipebombUtility())
	{
		total += g_Round.players[slot].resources.pipebombsThrown;
	}
	if (Announce_ShouldShowVomitjarUtility())
	{
		total += g_Round.players[slot].resources.vomitjarsThrown
			+ g_Round.players[slot].resources.playersBiled
			+ g_Round.players[slot].resources.tanksBiled;
	}

	return total;
}

int Announce_GetPlayerConsumableScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	int total = g_Round.players[slot].resources.pillsUsed + g_Round.players[slot].resources.medkitsUsed;

	if (Announce_ShouldShowAdrenalineConsumable())
	{
		total += g_Round.players[slot].resources.adrenalineUsed;
	}
	if (Announce_ShouldShowDefibConsumable())
	{
		total += g_Round.players[slot].resources.defibsUsed;
	}

	return total;
}

bool Announce_ShouldShowMolotovUtility()
{
	return g_cvConfoglMolotovLimit == null || g_cvConfoglMolotovLimit.IntValue != 0;
}

bool Announce_ShouldShowPipebombUtility()
{
	return g_cvConfoglPipebombLimit == null || g_cvConfoglPipebombLimit.IntValue != 0;
}

bool Announce_ShouldShowVomitjarUtility()
{
	return g_cvConfoglVomitjarLimit == null || g_cvConfoglVomitjarLimit.IntValue != 0;
}

bool Announce_ShouldShowAdrenalineConsumable()
{
	return g_cvConfoglAdrenalineLimit == null || g_cvConfoglAdrenalineLimit.IntValue != 0;
}

bool Announce_ShouldShowDefibConsumable()
{
	return g_cvConfoglRemoveDefib == null || !g_cvConfoglRemoveDefib.BoolValue;
}

void Announce_FormatConsumableTotalsLine(char[] buffer, int maxlen, int phraseTarget, bool showAdrenaline, bool showDefib)
{
	Format(buffer, maxlen, "%T", "PanelTotalsConsumables", phraseTarget,
		g_Round.totals.survivorTotalPillsUsed,
		showAdrenaline ? g_Round.totals.survivorTotalAdrenalineUsed : 0,
		g_Round.totals.survivorTotalMedkitsUsed,
		showDefib ? g_Round.totals.survivorTotalDefibsUsed : 0);
}

int Announce_GetPlayerSupportScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return g_Round.players[slot].support.healsGiven
		+ g_Round.players[slot].support.revivesGiven
		+ g_Round.players[slot].support.rescuesGiven;
}

int Announce_GetPlayerScavengeScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return (g_Round.players[slot].scavenge.gascansPoured * 10000)
		+ (g_Round.players[slot].scavenge.gascansDestroyed * 100)
		+ g_Round.players[slot].scavenge.gascansDropped;
}

int Announce_CollectSortedSurvivorSlotsByUtility(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!g_Round.players[slot].active || g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int currentSlot = slots[i];
		int currentUtility = Announce_GetPlayerUtilityScore(currentSlot);
		int currentDamage = Announce_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareUtility = Announce_GetPlayerUtilityScore(compareSlot);
			int compareDamage = Announce_GetPlayerDamageScore(compareSlot);
			if (compareUtility > currentUtility)
			{
				break;
			}

			if (compareUtility == currentUtility && compareDamage >= currentDamage)
			{
				break;
			}

			slots[j + 1] = compareSlot;
			j--;
		}

		slots[j + 1] = currentSlot;
	}

	return count;
}

int Announce_CollectSortedSurvivorSlotsByConsumables(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!g_Round.players[slot].active || g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int currentSlot = slots[i];
		int currentItems = Announce_GetPlayerConsumableScore(currentSlot);
		int currentDamage = Announce_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareItems = Announce_GetPlayerConsumableScore(compareSlot);
			int compareDamage = Announce_GetPlayerDamageScore(compareSlot);
			if (compareItems > currentItems)
			{
				break;
			}

			if (compareItems == currentItems && compareDamage >= currentDamage)
			{
				break;
			}

			slots[j + 1] = compareSlot;
			j--;
		}

		slots[j + 1] = currentSlot;
	}

	return count;
}

int Announce_CollectSortedSurvivorSlotsBySupport(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!g_Round.players[slot].active || g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int currentSlot = slots[i];
		int currentSupport = Announce_GetPlayerSupportScore(currentSlot);
		int currentDamage = Announce_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareSupport = Announce_GetPlayerSupportScore(compareSlot);
			int compareDamage = Announce_GetPlayerDamageScore(compareSlot);
			if (compareSupport > currentSupport)
			{
				break;
			}

			if (compareSupport == currentSupport && compareDamage >= currentDamage)
			{
				break;
			}

			slots[j + 1] = compareSlot;
			j--;
		}

		slots[j + 1] = currentSlot;
	}

	return count;
}

int Announce_CollectSortedSurvivorSlotsByScavenge(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!g_Round.players[slot].active || g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int currentSlot = slots[i];
		int currentScore = Announce_GetPlayerScavengeScore(currentSlot);
		int currentDamage = Announce_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareScore = Announce_GetPlayerScavengeScore(compareSlot);
			int compareDamage = Announce_GetPlayerDamageScore(compareSlot);
			if (compareScore > currentScore)
			{
				break;
			}

			if (compareScore == currentScore && compareDamage >= currentDamage)
			{
				break;
			}

			slots[j + 1] = compareSlot;
			j--;
		}

		slots[j + 1] = currentSlot;
	}

	return count;
}

int Announce_GetDamageRank(int client)
{
	int rank = 1;
	int index = Stats_GetPlayerRoundIndex(client);
	int score = index != -1 ? Announce_GetPlayerDamageScore(index) : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (Announce_GetPlayerDamageScore(slot) > score)
		{
			rank++;
		}
	}

	return rank;
}

int Announce_GetDamageRankBySlot(int index)
{
	int rank = 1;
	int score = index != -1 ? Announce_GetPlayerDamageScore(index) : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (Announce_GetPlayerDamageScore(slot) > score)
		{
			rank++;
		}
	}

	return rank;
}

int Announce_GetCommonRank(int client)
{
	int rank = 1;
	int index = Stats_GetPlayerRoundIndex(client);
	int score = index != -1 ? g_Round.players[index].combat.commonKills : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (g_Round.players[slot].combat.commonKills > score)
		{
			rank++;
		}
	}

	return rank;
}

int Announce_GetCommonRankBySlot(int index)
{
	int rank = 1;
	int score = index != -1 ? g_Round.players[index].combat.commonKills : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (g_Round.players[slot].combat.commonKills > score)
		{
			rank++;
		}
	}

	return rank;
}

int Announce_GetFFRank(int client)
{
	int rank = 1;
	int index = Stats_GetPlayerRoundIndex(client);
	int score = index != -1 ? g_Round.players[index].combat.ffGiven : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (g_Round.players[slot].combat.ffGiven > score)
		{
			rank++;
		}
	}

	return rank;
}

int Announce_GetFFRankBySlot(int index)
{
	int rank = 1;
	int score = index != -1 ? g_Round.players[index].combat.ffGiven : 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot) || slot == index)
		{
			continue;
		}

		if (g_Round.players[slot].team != PlayerStatsTeam_Survivor)
		{
			continue;
		}

		if (g_Round.players[slot].combat.ffGiven > score)
		{
			rank++;
		}
	}

	return rank;
}
