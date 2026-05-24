#if defined _l4d2_player_stats_announce_included
	#endinput
#endif
#define _l4d2_player_stats_announce_included

void Announce_Init()
{
	RegConsoleCmd("sm_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_mvp_rank", Command_MVPRank, "Print the client's current MVP ranks in chat and the global rank table in console.");
}

Action Command_MVP(int client, int args)
{
	Announce_BroadcastRoundSummary(client);

	if (client > 0 && IsValidClient(client))
	{
		Announce_RenderRoundConsolePanel(client);
	}

	return Plugin_Handled;
}

Action Command_MVPRank(int client, int args)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}

	Announce_PrintClientRanks(client);
	Announce_RenderGlobalRankPanel(client);
	return Plugin_Handled;
}

void Announce_BroadcastRoundSummary(int client = 0)
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
		return;
	}

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	if (siMvp == -1 && ciMvp == -1 && ffLvp == -1)
	{
		if (client > 0 && IsValidClient(client))
		{
			CPrintToChat(client, "%t %t", "Tag", "StatsUnavailable");
		}
		return;
	}

	Announce_PrintRoundSummaryLines(client, siMvp, ciMvp, ffLvp);
}

void Announce_RenderGameHistoryPanel(int client = 0)
{
	if (!g_GameHistory.active || g_GameHistory.roundCount <= 0)
	{
		ConsolePanel_PrintMessage(client, "[l4d2_player_stats] No game history available.");
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[160];
	Format(line, sizeof(line), "General data per game round -- Series %d", g_GameHistory.seriesId);
	ConsolePanel_AddHeaderLine(panel, line);

	Format(line, sizeof(line), "Campaign Score A/B: %d / %d",
		g_GameHistory.lastCampaignScoreA,
		g_GameHistory.lastCampaignScoreB);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Round", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Map", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Time", 8, ConsoleTableAlignment_Right, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "SI K", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Common", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Deaths", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Incaps", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Kits", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Pills", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Restarts", 8, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	for (int i = 0; i < g_GameHistory.roundCount; i++)
	{
		if (!g_GameHistory.rounds[i].active)
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
		ConsoleTable_AddStringCell(panel.table, g_GameHistory.rounds[i].map);
		ConsoleTable_AddStringCell(panel.table, duration);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].siKills);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].commonKills);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].deaths);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].incaps);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].kitsUsed);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].pillsUsed);
		ConsoleTable_AddIntCell(panel.table, g_GameHistory.rounds[i].restarts);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Announce_RenderRoundConsolePanel(int client = 0)
{
	if (!Stats_HasRoundSnapshot())
	{
		ConsolePanel_PrintMessage(client, "[l4d2_player_stats] No round snapshot available.");
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 78);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[128];
	Announce_FormatPanelTitle(line, sizeof(line));
	ConsolePanel_AddHeaderLine(panel, line);

	int totalDamage = Announce_GetTotalSurvivorDamage();
	Format(line, sizeof(line), "Totals: DMG %d | SI K %d | CI %d | FF %d",
		totalDamage,
		Announce_GetTotalSurvivorSpecialKills(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);
	ConsolePanel_AddHeaderLine(panel, line);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();

	ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "DMG", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI K", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	if (showTank)
	{
		ConsoleTable_AddColumn(panel.table, "Tank", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
	if (showWitch)
	{
		ConsoleTable_AddColumn(panel.table, "Witch", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
	ConsoleTable_AddColumn(panel.table, "CI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "FF", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	int survivorSlots[8];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		if (!ConsoleTable_BeginRow(panel.table))
		{
			break;
		}

		ConsoleTable_AddStringCell(panel.table, g_Round.players[slot].player.name);
		ConsoleTable_AddIntCell(panel.table, Announce_GetPlayerDamageScore(slot));
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.siDamage);
		ConsoleTable_AddIntCell(panel.table, Announce_GetPlayerSpecialKills(slot));
		if (showTank)
		{
			ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.tankDamage);
		}
		if (showWitch)
		{
			ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.witchDamage);
		}
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.commonKills);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.ffGiven);
		ConsoleTable_EndRow(panel.table);
	}

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	Announce_FormatRoundDurationLine(line, sizeof(line));
	ConsolePanel_AddFooterLine(panel, line);

	if (Stats_IsValidRoundSlot(siMvp))
	{
		Format(line, sizeof(line), "%T", "RoundMVPDamageBase", LANG_SERVER,
			g_Round.players[siMvp].player.name,
			g_Round.players[siMvp].combat.siDamage,
			Announce_GetPercent(g_Round.players[siMvp].combat.siDamage, g_Round.totals.survivorTotalSiDamage));
		CRemoveTags(line, sizeof(line));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		Format(line, sizeof(line), "CI MVP: %s (%d, %d%%)",
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		ConsolePanel_AddFooterLine(panel, "FF LVP: none");
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		Format(line, sizeof(line), "FF LVP: %s (%d, %d%%)",
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		ConsolePanel_AddFooterLine(panel, line);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Announce_BroadcastRoundConsolePanel()
{
	if (!Stats_HasRoundSnapshot())
	{
		return;
	}

	Announce_RenderRoundConsolePanel(0);

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 78);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[128];
	Announce_FormatPanelTitle(line, sizeof(line));
	ConsolePanel_AddHeaderLine(panel, line);

	int totalDamage = Announce_GetTotalSurvivorDamage();
	Format(line, sizeof(line), "Totals: DMG %d | SI K %d | CI %d | FF %d",
		totalDamage,
		Announce_GetTotalSurvivorSpecialKills(),
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);
	ConsolePanel_AddHeaderLine(panel, line);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();

	ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "DMG", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI K", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	if (showTank)
	{
		ConsoleTable_AddColumn(panel.table, "Tank", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
	if (showWitch)
	{
		ConsoleTable_AddColumn(panel.table, "Witch", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
	ConsoleTable_AddColumn(panel.table, "CI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "FF", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	int survivorSlots[8];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		if (!ConsoleTable_BeginRow(panel.table))
		{
			break;
		}

		ConsoleTable_AddStringCell(panel.table, g_Round.players[slot].player.name);
		ConsoleTable_AddIntCell(panel.table, Announce_GetPlayerDamageScore(slot));
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.siDamage);
		ConsoleTable_AddIntCell(panel.table, Announce_GetPlayerSpecialKills(slot));
		if (showTank)
		{
			ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.tankDamage);
		}
		if (showWitch)
		{
			ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.witchDamage);
		}
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.commonKills);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.ffGiven);
		ConsoleTable_EndRow(panel.table);
	}

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	Announce_FormatRoundDurationLine(line, sizeof(line));
	ConsolePanel_AddFooterLine(panel, line);

	if (Stats_IsValidRoundSlot(siMvp))
	{
		Format(line, sizeof(line), "%T", "RoundMVPDamageBase", LANG_SERVER,
			g_Round.players[siMvp].player.name,
			g_Round.players[siMvp].combat.siDamage,
			Announce_GetPercent(g_Round.players[siMvp].combat.siDamage, g_Round.totals.survivorTotalSiDamage));
		CRemoveTags(line, sizeof(line));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		Format(line, sizeof(line), "CI MVP: %s (%d, %d%%)",
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		ConsolePanel_AddFooterLine(panel, "FF LVP: none");
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		Format(line, sizeof(line), "FF LVP: %s (%d, %d%%)",
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		ConsolePanel_AddFooterLine(panel, line);
	}

	ConsolePanel_RenderToAudience(panel);
}

void Announce_PrintRoundSummaryLines(int client, int siMvp, int ciMvp, int ffLvp)
{
	if (Stats_IsValidRoundSlot(siMvp))
	{
		char line[256];
		Announce_FormatMvPDamageLine(line, sizeof(line), siMvp, Announce_GetPhraseTarget(client));
		Announce_PrintMessage(client, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		char line[256];
		Format(line, sizeof(line), "{blue}MVP CI:{default} {olive}%s {blue}con {green}%d {blue}common kills [{green}%d{blue}].{default}",
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].combat.commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
		Announce_PrintMessage(client, line);
	}

	if (g_Round.totals.survivorTotalFF <= 0)
	{
		Announce_PrintMessage(client, "{blue}LVP FF: no hubo friendly fire.{default}");
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		char line[256];
		Format(line, sizeof(line), "{blue}LVP FF:{default} {olive}%s {blue}con {green}%d {blue}de FF [{green}%d{blue}].{default}",
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].combat.ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].combat.ffGiven, g_Round.totals.survivorTotalFF));
		Announce_PrintMessage(client, line);
	}
}

void Announce_PrintMessage(int client, const char[] message)
{
	if (client > 0 && IsValidClient(client))
	{
		CPrintToChat(client, "%t %s", "Tag", message);
		return;
	}

	CPrintToChatAll("%t %s", "Tag", message);
}

bool Announce_ShouldShowTankDamage()
{
	if (!g_bBossPercentsAvailable || GetFeatureStatus(FeatureType_Native, "GetStoredTankPercent") == FeatureStatus_Unknown)
	{
		return true;
	}

	int tankPercent = GetStoredTankPercent();
	return tankPercent != 0;
}

bool Announce_ShouldShowWitchDamage()
{
	if (!g_bBossPercentsAvailable || GetFeatureStatus(FeatureType_Native, "GetStoredWitchPercent") == FeatureStatus_Unknown)
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

void Announce_FormatPanelTitle(char[] buffer, int maxlen)
{
	int tankCount = Announce_GetEncounteredTankCount();
	int witchCount = Announce_GetEncounteredWitchCount();

	if (tankCount > 1 && witchCount > 1)
	{
		Format(buffer, maxlen, "L4D2 Player Stats - Round %d | Tank x%d | Witch x%d",
			g_Round.meta.id,
			tankCount,
			witchCount);
		return;
	}

	if (tankCount > 1)
	{
		Format(buffer, maxlen, "L4D2 Player Stats - Round %d | Tank x%d",
			g_Round.meta.id,
			tankCount);
		return;
	}

	if (witchCount > 1)
	{
		Format(buffer, maxlen, "L4D2 Player Stats - Round %d | Witch x%d",
			g_Round.meta.id,
			witchCount);
		return;
	}

	Format(buffer, maxlen, "L4D2 Player Stats - Round %d", g_Round.meta.id);
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
	Format(buffer, maxlen, "Round Duration: %dm %02ds", minutes, seconds);
}

void Announce_FormatMvPDamageLine(char[] buffer, int maxlen, int slot, int phraseTarget = LANG_SERVER)
{
	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();
	int siDamage = g_Round.players[slot].combat.siDamage;
	int siPercent = Announce_GetPercent(siDamage, g_Round.totals.survivorTotalSiDamage);
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

	if (showTank)
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

	if (showWitch)
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

	if (showTank && showWitch)
	{
		Format(buffer, maxlen, "%s (%s, %s).", buffer, tankDetail, witchDetail);
		return;
	}

	if (showTank)
	{
		Format(buffer, maxlen, "%s (%s).", buffer, tankDetail);
		return;
	}

	if (showWitch)
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
		CPrintToChat(client, "%t %t", "Tag", "StatsUnavailable");
		return;
	}

	int index = Stats_GetPlayerRoundIndex(client);
	if (index == -1 || !g_Round.players[index].active)
	{
		CPrintToChat(client, "%t %t", "Tag", "StatsUnavailable");
		return;
	}

	int damageRank = Announce_GetDamageRank(client);
	int commonRank = Announce_GetCommonRank(client);
	int ffRank = Announce_GetFFRank(client);

	if (damageRank > 0 && Announce_GetTotalSurvivorDamage() > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "YourRankDamage",
			damageRank,
			Announce_GetPlayerDamageScore(index),
			Announce_GetPercent(Announce_GetPlayerDamageScore(index), Announce_GetTotalSurvivorDamage()));
	}

	if (commonRank > 0 && g_Round.totals.survivorTotalCommonKills > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "YourRankCommon",
			commonRank,
			g_Round.players[index].combat.commonKills,
			Announce_GetPercent(g_Round.players[index].combat.commonKills, g_Round.totals.survivorTotalCommonKills));
	}

	if (ffRank > 0 && g_Round.totals.survivorTotalFF > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "YourRankFF",
			ffRank,
			g_Round.players[index].combat.ffGiven,
			Announce_GetPercent(g_Round.players[index].combat.ffGiven, g_Round.totals.survivorTotalFF));
	}
}

void Announce_RenderGlobalRankPanel(int client)
{
	if (!IsValidSurvivor(client) || !Stats_HasRoundSnapshot())
	{
		return;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 78);
	ConsolePanel_EnableSafeAscii(panel, true);

	char line[128];
	Format(line, sizeof(line), "L4D2 Player Stats - Global Rank");
	ConsolePanel_AddHeaderLine(panel, line);

	Format(line, sizeof(line), "Player: %N | Round %d", client, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Player", 16, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "SI#", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "CI#", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "CI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "FF#", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "FF", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	int survivorSlots[8];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		if (!ConsoleTable_BeginRow(panel.table))
		{
			break;
		}

		ConsoleTable_AddStringCell(panel.table, g_Round.players[slot].player.name);
		ConsoleTable_AddIntCell(panel.table, Announce_GetDamageRankBySlot(slot));
		ConsoleTable_AddIntCell(panel.table, Announce_GetPlayerDamageScore(slot));
		ConsoleTable_AddIntCell(panel.table, Announce_GetCommonRankBySlot(slot));
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.commonKills);
		ConsoleTable_AddIntCell(panel.table, Announce_GetFFRankBySlot(slot));
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].combat.ffGiven);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

int Announce_GetPlayerDamageScore(int index)
{
	return g_Round.players[index].combat.siDamage + g_Round.players[index].combat.tankDamage + g_Round.players[index].combat.witchDamage;
}

int Announce_GetPlayerSpecialKills(int index)
{
	return g_Round.players[index].combat.smokerKills
		+ g_Round.players[index].combat.boomerKills
		+ g_Round.players[index].combat.hunterKills
		+ g_Round.players[index].combat.spitterKills
		+ g_Round.players[index].combat.jockeyKills
		+ g_Round.players[index].combat.chargerKills;
}

int Announce_GetTotalSurvivorDamage()
{
	return g_Round.totals.survivorTotalSiDamage + g_Round.totals.survivorTotalTankDamage + g_Round.totals.survivorTotalWitchDamage;
}

int Announce_GetTotalSurvivorSpecialKills()
{
	return g_Round.totals.survivorTotalSmokerKills
		+ g_Round.totals.survivorTotalBoomerKills
		+ g_Round.totals.survivorTotalHunterKills
		+ g_Round.totals.survivorTotalSpitterKills
		+ g_Round.totals.survivorTotalJockeyKills
		+ g_Round.totals.survivorTotalChargerKills;
}

int Announce_GetPercent(int part, int whole)
{
	if (part <= 0 || whole <= 0)
	{
		return 0;
	}

	return RoundToNearest((float(part) / float(whole)) * 100.0);
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
