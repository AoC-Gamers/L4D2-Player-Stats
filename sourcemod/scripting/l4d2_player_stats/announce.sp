#if defined _l4d2_player_stats_announce_included
	#endinput
#endif
#define _l4d2_player_stats_announce_included

void Announce_Init()
{
	RegConsoleCmd("sm_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_stats", Command_Stats, "Print the current survivor round summary.");
	RegConsoleCmd("sm_mvpme", Command_MVPMe, "Print the client's current MVP-related ranks.");
}

Action Command_MVP(int client, int args)
{
	Announce_BroadcastRoundSummary(client);
	return Plugin_Handled;
}

Action Command_Stats(int client, int args)
{
	if (client == 0)
	{
		Announce_RenderRoundConsolePanel(0);
		return Plugin_Handled;
	}

	Announce_BroadcastRoundSummary(client);
	return Plugin_Handled;
}

Action Command_MVPMe(int client, int args)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}

	Announce_PrintClientRanks(client);
	return Plugin_Handled;
}

void Announce_BroadcastRoundSummary(int client = 0)
{
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
	Format(line, sizeof(line), "L4D2 Player Stats - Round %d", g_Round.id);
	ConsolePanel_AddHeaderLine(panel, line);

	int totalDamage = Announce_GetTotalSurvivorDamage();
	Format(line, sizeof(line), "Totals: DMG %d | CI %d | FF %d",
		totalDamage,
		g_Round.survivorTotalCommonKills,
		g_Round.survivorTotalFF);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "DMG", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Tank", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Witch", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
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
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].siDamage);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].tankDamage);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].witchDamage);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].commonKills);
		ConsoleTable_AddIntCell(panel.table, g_Round.players[slot].ffGiven);
		ConsoleTable_EndRow(panel.table);
	}

	int siMvp = Announce_FindTopDamageSlot();
	int ciMvp = Announce_FindTopCommonSlot();
	int ffLvp = Announce_FindTopFFSlot();

	if (Stats_IsValidRoundSlot(siMvp))
	{
		Format(line, sizeof(line), "SI MVP: %s (%d, %d%%)",
			g_Round.players[siMvp].player.name,
			Announce_GetPlayerDamageScore(siMvp),
			Announce_GetPercent(Announce_GetPlayerDamageScore(siMvp), totalDamage));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		Format(line, sizeof(line), "CI MVP: %s (%d, %d%%)",
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].commonKills,
			Announce_GetPercent(g_Round.players[ciMvp].commonKills, g_Round.survivorTotalCommonKills));
		ConsolePanel_AddFooterLine(panel, line);
	}

	if (g_Round.survivorTotalFF <= 0)
	{
		ConsolePanel_AddFooterLine(panel, "FF LVP: none");
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		Format(line, sizeof(line), "FF LVP: %s (%d, %d%%)",
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].ffGiven,
			Announce_GetPercent(g_Round.players[ffLvp].ffGiven, g_Round.survivorTotalFF));
		ConsolePanel_AddFooterLine(panel, line);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Announce_PrintRoundSummaryLines(int client, int siMvp, int ciMvp, int ffLvp)
{
	if (Stats_IsValidRoundSlot(siMvp))
	{
		int totalDamage = Announce_GetTotalSurvivorDamage();
		int percent = Announce_GetPercent(Announce_GetPlayerDamageScore(siMvp), totalDamage);

		Announce_PrintPhrase(client, "RoundMVPDamage",
			g_Round.players[siMvp].player.name,
			Announce_GetPlayerDamageScore(siMvp),
			percent,
			g_Round.players[siMvp].siDamage,
			g_Round.players[siMvp].tankDamage,
			g_Round.players[siMvp].witchDamage);
	}

	if (Stats_IsValidRoundSlot(ciMvp))
	{
		int percent = Announce_GetPercent(g_Round.players[ciMvp].commonKills, g_Round.survivorTotalCommonKills);

		Announce_PrintPhrase(client, "RoundMVPCommon",
			g_Round.players[ciMvp].player.name,
			g_Round.players[ciMvp].commonKills,
			percent);
	}

	if (g_Round.survivorTotalFF <= 0)
	{
		Announce_PrintPhrase(client, "RoundNoFF");
	}
	else if (Stats_IsValidRoundSlot(ffLvp))
	{
		int percent = Announce_GetPercent(g_Round.players[ffLvp].ffGiven, g_Round.survivorTotalFF);

		Announce_PrintPhrase(client, "RoundLVPFF",
			g_Round.players[ffLvp].player.name,
			g_Round.players[ffLvp].ffGiven,
			percent);
	}
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

	if (commonRank > 0 && g_Round.survivorTotalCommonKills > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "YourRankCommon",
			commonRank,
			g_Round.players[index].commonKills,
			Announce_GetPercent(g_Round.players[index].commonKills, g_Round.survivorTotalCommonKills));
	}

	if (ffRank > 0 && g_Round.survivorTotalFF > 0)
	{
		CPrintToChat(client, "%t %t", "Tag", "YourRankFF",
			ffRank,
			g_Round.players[index].ffGiven,
			Announce_GetPercent(g_Round.players[index].ffGiven, g_Round.survivorTotalFF));
	}
}

void Announce_PrintPhrase(int client, const char[] phrase, any ...)
{
	char buffer[256];
	VFormat(buffer, sizeof(buffer), phrase, 3);

	if (client > 0 && IsValidClient(client))
	{
		CPrintToChat(client, "%t %s", "Tag", buffer);
		return;
	}

	CPrintToChatAll("%t %s", "Tag", buffer);
}

int Announce_GetPlayerDamageScore(int index)
{
	return g_Round.players[index].siDamage + g_Round.players[index].tankDamage + g_Round.players[index].witchDamage;
}

int Announce_GetTotalSurvivorDamage()
{
	return g_Round.survivorTotalSiDamage + g_Round.survivorTotalTankDamage + g_Round.survivorTotalWitchDamage;
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

		int score = g_Round.players[slot].commonKills;
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

		int score = g_Round.players[slot].ffGiven;
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

			if (currentScore == keyScore && g_Round.players[current].commonKills >= g_Round.players[key].commonKills)
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

int Announce_GetCommonRank(int client)
{
	int rank = 1;
	int index = Stats_GetPlayerRoundIndex(client);
	int score = index != -1 ? g_Round.players[index].commonKills : 0;

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

		if (g_Round.players[slot].commonKills > score)
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
	int score = index != -1 ? g_Round.players[index].ffGiven : 0;

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

		if (g_Round.players[slot].ffGiven > score)
		{
			rank++;
		}
	}

	return rank;
}
