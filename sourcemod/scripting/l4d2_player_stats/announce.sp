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
	Format(line, sizeof(line), "%T", "HelpCommandMVPRank", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPAcc", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPUtils", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPItems", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPSupport", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPScavenge", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPInfect", phraseTarget);
	Announce_PrintConsoleLine(client, line);
	Format(line, sizeof(line), "%T", "HelpCommandMVPTank", phraseTarget);
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

bool Announce_RequireCompetitiveModeForCommand(int client)
{
	if (Stats_IsCompetitiveMode())
	{
		return true;
	}

	Announce_ReplyCommandPhrase(client, "CompetitiveCommandOnly");
	return false;
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
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, client > 0 ? client : LANG_SERVER);
	Format(line, sizeof(line), "%T", "PanelTitleAccuracyStats", client > 0 ? client : LANG_SERVER, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "%T", "PanelLegendAccuracyHitsShotsPercent", client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerStringColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

	PlayerStatsWeaponDetailType groupedDetails[][5] =
	{
		{ PlayerStatsWeaponDetail_PumpShotgun, PlayerStatsWeaponDetail_Autoshotgun, PlayerStatsWeaponDetail_ChromeShotgun, PlayerStatsWeaponDetail_SpasShotgun, PlayerStatsWeaponDetail_None },
		{ PlayerStatsWeaponDetail_Smg, PlayerStatsWeaponDetail_SmgSilenced, PlayerStatsWeaponDetail_SmgMp5, PlayerStatsWeaponDetail_None, PlayerStatsWeaponDetail_None },
		{ PlayerStatsWeaponDetail_Rifle, PlayerStatsWeaponDetail_RifleAk47, PlayerStatsWeaponDetail_RifleDesert, PlayerStatsWeaponDetail_RifleSg552, PlayerStatsWeaponDetail_RifleM60 },
		{ PlayerStatsWeaponDetail_HuntingRifle, PlayerStatsWeaponDetail_SniperMilitary, PlayerStatsWeaponDetail_SniperAwp, PlayerStatsWeaponDetail_SniperScout, PlayerStatsWeaponDetail_None },
		{ PlayerStatsWeaponDetail_Pistol, PlayerStatsWeaponDetail_Magnum, PlayerStatsWeaponDetail_None, PlayerStatsWeaponDetail_None, PlayerStatsWeaponDetail_None }
	};
	static const char groupPhraseKeys[][] =
	{
		"ColumnShotgun",
		"ColumnSmgGroup",
		"ColumnRifleGroup",
		"ColumnSniper",
		"ColumnPistol"
	};
	static const char groupTotalPhraseKeys[][] =
	{
		"ColumnShotgunTotal",
		"ColumnSmgTotal",
		"ColumnRifleTotal",
		"ColumnSniperTotal",
		"ColumnPistolTotal"
	};

	bool hasRows = false;
	for (int groupIndex = 0; groupIndex < sizeof(groupedDetails); groupIndex++)
	{
		bool showGroup = false;
		for (int i = 0; i < survivorCount && !showGroup; i++)
		{
			int slot = survivorSlots[i];
			for (int detailIndex = 0; detailIndex < sizeof(groupedDetails[]); detailIndex++)
			{
				PlayerStatsWeaponDetailType detail = groupedDetails[groupIndex][detailIndex];
				if (detail == PlayerStatsWeaponDetail_None)
				{
					continue;
				}

				if (g_Round.players[slot].accuracyDetails.shots[detail] > 0)
				{
					showGroup = true;
					break;
				}
			}
		}

		if (!showGroup)
		{
			continue;
		}

		char groupLabel[24];
		Announce_GetColumnLabel(groupLabel, sizeof(groupLabel), groupPhraseKeys[groupIndex], client > 0 ? client : LANG_SERVER);
		Format(line, sizeof(line), "[%s]", groupLabel);
		ConsolePanel_AddHeaderLine(panel, line);

		for (int detailIndex = 0; detailIndex < sizeof(groupedDetails[]); detailIndex++)
		{
			PlayerStatsWeaponDetailType detail = groupedDetails[groupIndex][detailIndex];
			if (detail == PlayerStatsWeaponDetail_None)
			{
				continue;
			}

			bool showDetail = false;
			for (int i = 0; i < survivorCount; i++)
			{
				int slot = survivorSlots[i];
				if (g_Round.players[slot].accuracyDetails.shots[detail] > 0)
				{
					showDetail = true;
					break;
				}
			}

			if (!showDetail)
			{
				continue;
			}

			char detailLabel[24];
			char valueA[32], valueB[32], valueC[32], valueD[32];
			bool clampToShots = Stats_GetWeaponFamilyFromDetail(detail) == PlayerStatsWeaponFamily_Shotgun;
			Stats_GetWeaponDetailName(detail, detailLabel, sizeof(detailLabel));
			Announce_FormatAccuracyCell(valueA, sizeof(valueA),
				g_Round.players[survivorSlots[0]].accuracyDetails.hits[detail],
				g_Round.players[survivorSlots[0]].accuracyDetails.shots[detail],
				clampToShots);
			if (survivorCount > 1)
			{
				Announce_FormatAccuracyCell(valueB, sizeof(valueB),
					g_Round.players[survivorSlots[1]].accuracyDetails.hits[detail],
					g_Round.players[survivorSlots[1]].accuracyDetails.shots[detail],
					clampToShots);
			}
			if (survivorCount > 2)
			{
				Announce_FormatAccuracyCell(valueC, sizeof(valueC),
					g_Round.players[survivorSlots[2]].accuracyDetails.hits[detail],
					g_Round.players[survivorSlots[2]].accuracyDetails.shots[detail],
					clampToShots);
			}
			if (survivorCount > 3)
			{
				Announce_FormatAccuracyCell(valueD, sizeof(valueD),
					g_Round.players[survivorSlots[3]].accuracyDetails.hits[detail],
					g_Round.players[survivorSlots[3]].accuracyDetails.shots[detail],
					clampToShots);
			}

			Announce_AddMetricStringRow(panel, detailLabel, survivorCount, valueA, valueB, valueC, valueD);
			hasRows = true;
		}

		char totalLabel[24];
		char totalA[32], totalB[32], totalC[32], totalD[32];
		Announce_GetColumnLabel(totalLabel, sizeof(totalLabel), groupTotalPhraseKeys[groupIndex], client > 0 ? client : LANG_SERVER);
		Announce_FormatAccuracyCell(totalA, sizeof(totalA),
			Announce_GetPlayerAccuracyGroupHits(survivorSlots[0], groupIndex),
			Announce_GetPlayerAccuracyGroupShots(survivorSlots[0], groupIndex),
			groupIndex == 0);
		if (survivorCount > 1)
		{
			Announce_FormatAccuracyCell(totalB, sizeof(totalB),
				Announce_GetPlayerAccuracyGroupHits(survivorSlots[1], groupIndex),
				Announce_GetPlayerAccuracyGroupShots(survivorSlots[1], groupIndex),
				groupIndex == 0);
		}
		if (survivorCount > 2)
		{
			Announce_FormatAccuracyCell(totalC, sizeof(totalC),
				Announce_GetPlayerAccuracyGroupHits(survivorSlots[2], groupIndex),
				Announce_GetPlayerAccuracyGroupShots(survivorSlots[2], groupIndex),
				groupIndex == 0);
		}
		if (survivorCount > 3)
		{
			Announce_FormatAccuracyCell(totalD, sizeof(totalD),
				Announce_GetPlayerAccuracyGroupHits(survivorSlots[3], groupIndex),
				Announce_GetPlayerAccuracyGroupShots(survivorSlots[3], groupIndex),
				groupIndex == 0);
		}

		Announce_AddMetricStringRow(panel, totalLabel, survivorCount, totalA, totalB, totalC, totalD);
	}

	if (!hasRows)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	if (client > 0)
	{
		ConsolePanel_RenderToClient(panel, client);
	}
	else
	{
		ConsolePanel_RenderToAudience(panel);
	}
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

int Announce_GetPlayerInfectedGrabScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return g_Round.players[slot].infectedGrab.totalDamage;
}

int Announce_GetPlayerInfectedSupportScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return (g_Round.players[slot].infectedSupport.boomerVomitVictims * 1000)
		+ g_Round.players[slot].infectedSupport.spitterDamage;
}

int Announce_GetInfectedAiAggregateGrabDamage()
{
	int total = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot)
			|| g_Round.players[slot].team != PlayerStatsTeam_Infected
			|| !g_Round.players[slot].player.bot)
		{
			continue;
		}

		total += g_Round.players[slot].infectedGrab.totalDamage;
	}

	return total;
}

bool Announce_HasInfectedGrabStats()
{
	return g_Round.totals.infectedTotalGrabDamage > 0
		|| g_Round.totals.infectedTotalTongueGrabs > 0
		|| g_Round.totals.infectedTotalHunterPouncesLanded > 0
		|| g_Round.totals.infectedTotalJockeyRidesLanded > 0;
}

bool Announce_HasInfectedSupportStats()
{
	return g_Round.totals.infectedTotalBoomerVomitVictims > 0
		|| g_Round.totals.infectedTotalSpitterDamage > 0;
}

bool Announce_HasTankStats()
{
	for (int i = 0; i < g_Round.tankSessionCount; i++)
	{
		if (g_Round.tankSessions[i].sessionId > 0)
		{
			return true;
		}
	}

	return false;
}

int Announce_CollectSortedInfectedHumanSlots(int[] slots, int maxSlots)
{
	int count = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS && count < maxSlots; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot)
			|| g_Round.players[slot].team != PlayerStatsTeam_Infected
			|| g_Round.players[slot].player.bot)
		{
			continue;
		}

		slots[count++] = slot;
	}

	for (int i = 1; i < count; i++)
	{
		int currentSlot = slots[i];
		int currentScore = Announce_GetPlayerInfectedGrabScore(currentSlot) + Announce_GetPlayerInfectedSupportScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareScore = Announce_GetPlayerInfectedGrabScore(compareSlot) + Announce_GetPlayerInfectedSupportScore(compareSlot);
			if (compareScore > currentScore)
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

bool Announce_HasInfectedAiAggregate()
{
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!Stats_IsValidRoundSlot(slot)
			|| g_Round.players[slot].team != PlayerStatsTeam_Infected
			|| !g_Round.players[slot].player.bot)
		{
			continue;
		}

		if (g_Round.players[slot].infectedGrab.totalDamage > 0
			|| g_Round.players[slot].infectedGrab.tongueGrabs > 0
			|| g_Round.players[slot].infectedGrab.hunterPounces > 0
			|| g_Round.players[slot].infectedGrab.jockeyRides > 0
			|| g_Round.players[slot].infectedSupport.boomerVomitVictims > 0
			|| g_Round.players[slot].infectedSupport.spitterDamage > 0)
		{
			return true;
		}
	}

	return false;
}

void Announce_PrintInfectedSummaryLines(int client, int[] infectedSlots, int infectedCount)
{
	if (!Announce_WasCommandInvokedFromChat(client) || infectedCount <= 0)
	{
		return;
	}

	int bestGrabSlot = -1;
	int bestSupportSlot = -1;

	for (int i = 0; i < infectedCount; i++)
	{
		int slot = infectedSlots[i];
		if (bestGrabSlot == -1 || Announce_GetPlayerInfectedGrabScore(slot) > Announce_GetPlayerInfectedGrabScore(bestGrabSlot))
		{
			bestGrabSlot = slot;
		}

		if (bestSupportSlot == -1 || Announce_GetPlayerInfectedSupportScore(slot) > Announce_GetPlayerInfectedSupportScore(bestSupportSlot))
		{
			bestSupportSlot = slot;
		}
	}

	if (Stats_IsValidRoundSlot(bestGrabSlot) && Announce_GetPlayerInfectedGrabScore(bestGrabSlot) > 0)
	{
		CReplyToCommand(client, "%t", "RoundMVPInfected",
			g_Round.players[bestGrabSlot].player.name,
			g_Round.players[bestGrabSlot].infectedGrab.totalDamage);
	}

	if (Stats_IsValidRoundSlot(bestSupportSlot) && Announce_GetPlayerInfectedSupportScore(bestSupportSlot) > 0)
	{
		CReplyToCommand(client, "%t", "RoundSupportInfected",
			g_Round.players[bestSupportSlot].player.name,
			g_Round.players[bestSupportSlot].infectedSupport.boomerVomitVictims,
			g_Round.players[bestSupportSlot].infectedSupport.spitterDamage);
	}
}

bool Announce_RenderInfectedPanels(int client = 0)
{
	if (!Announce_RequireCompetitiveModeForCommand(client))
	{
		return false;
	}

	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasInfectedGrabStats() && !Announce_HasInfectedSupportStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	int infectedSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int infectedCount = Announce_CollectSortedInfectedHumanSlots(infectedSlots, sizeof(infectedSlots));
	bool includeAi = Announce_HasInfectedAiAggregate();
	int columnCount = infectedCount + (includeAi ? 1 : 0);
	if (columnCount <= 0)
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	Announce_PrintInfectedSummaryLines(client, infectedSlots, infectedCount);

	bool rendered = false;
	int phraseTarget = client > 0 ? client : LANG_SERVER;
	char columnNames[L4D2_PLAYER_STATS_MAX_SURVIVORS + 1][MAX_NAME_LENGTH];

	for (int i = 0; i < infectedCount; i++)
	{
		strcopy(columnNames[i], sizeof(columnNames[]), g_Round.players[infectedSlots[i]].player.name);
	}
	if (includeAi)
	{
		Format(columnNames[infectedCount], sizeof(columnNames[]), "%T", "ColumnAI", phraseTarget);
	}

	if (Announce_HasInfectedGrabStats())
	{
		ConsolePanel panel;
		Announce_BuildMetricPanel(panel, phraseTarget, "PanelTitleInfectedGrab", "PanelTotalsInfectedGrab",
			g_Round.totals.infectedTotalGrabDamage,
			g_Round.totals.infectedTotalTongueGrabs,
			g_Round.totals.infectedTotalHunterPouncesLanded + g_Round.totals.infectedTotalJockeyRidesLanded);

		char totalLabel[16];
		char smokerLabel[16];
		char hunterLabel[16];
		char jockeyLabel[16];
		char chargerLabel[16];
		char tongueLabel[16];
		char pounceLabel[16];
		char rideLabel[16];
		Format(totalLabel, sizeof(totalLabel), "%T", "ColumnTotal", phraseTarget);
		Format(smokerLabel, sizeof(smokerLabel), "%T", "ColumnSmoker", phraseTarget);
		Format(hunterLabel, sizeof(hunterLabel), "%T", "ColumnHunter", phraseTarget);
		Format(jockeyLabel, sizeof(jockeyLabel), "%T", "ColumnJockey", phraseTarget);
		Format(chargerLabel, sizeof(chargerLabel), "%T", "ColumnCharger", phraseTarget);
		Format(tongueLabel, sizeof(tongueLabel), "%T", "ColumnTongues", phraseTarget);
		Format(pounceLabel, sizeof(pounceLabel), "%T", "ColumnPounces", phraseTarget);
		Format(rideLabel, sizeof(rideLabel), "%T", "ColumnRides", phraseTarget);
		Announce_FormatMetricUnitLabel(totalLabel, sizeof(totalLabel), totalLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(smokerLabel, sizeof(smokerLabel), smokerLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(hunterLabel, sizeof(hunterLabel), hunterLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(jockeyLabel, sizeof(jockeyLabel), jockeyLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(chargerLabel, sizeof(chargerLabel), chargerLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(tongueLabel, sizeof(tongueLabel), tongueLabel, "#");
		Announce_FormatMetricUnitLabel(pounceLabel, sizeof(pounceLabel), pounceLabel, "#");
		Announce_FormatMetricUnitLabel(rideLabel, sizeof(rideLabel), rideLabel, "#");

		int values[L4D2_PLAYER_STATS_MAX_SURVIVORS + 1];
		Announce_AddNamedMetricIntColumns(panel, phraseTarget, columnNames, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.totalDamage;
		if (includeAi) values[infectedCount] = Announce_GetInfectedAiAggregateGrabDamage();
		Announce_AddMetricRowValues(panel, totalLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.smokerDamage;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.smokerDamage; }
		Announce_AddMetricRowValues(panel, smokerLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.hunterDamage;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.hunterDamage; }
		Announce_AddMetricRowValues(panel, hunterLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.jockeyDamage;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.jockeyDamage; }
		Announce_AddMetricRowValues(panel, jockeyLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.chargerDamage;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.chargerDamage; }
		Announce_AddMetricRowValues(panel, chargerLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.tongueGrabs;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.tongueGrabs; }
		Announce_AddMetricRowValues(panel, tongueLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.hunterPounces;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.hunterPounces; }
		Announce_AddMetricRowValues(panel, pounceLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedGrab.jockeyRides;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedGrab.jockeyRides; }
		Announce_AddMetricRowValues(panel, rideLabel, values, columnCount);

		ConsolePanel_RenderToClient(panel, client);
		rendered = true;
	}

	if (Announce_HasInfectedSupportStats())
	{
		ConsolePanel panel;
		Announce_BuildMetricPanel(panel, phraseTarget, "PanelTitleInfectedSupport", "PanelTotalsInfectedSupport",
			g_Round.totals.infectedTotalBoomerVomitVictims,
			g_Round.totals.infectedTotalSpitterDamage);

		char boomerLabel[16];
		char spitLabel[16];
		Format(boomerLabel, sizeof(boomerLabel), "%T", "ColumnBoomerHits", phraseTarget);
		Format(spitLabel, sizeof(spitLabel), "%T", "ColumnSpit", phraseTarget);
		Announce_FormatMetricUnitLabel(boomerLabel, sizeof(boomerLabel), boomerLabel, "#");
		Announce_FormatMetricUnitLabel(spitLabel, sizeof(spitLabel), spitLabel, "dmg", false);

		int values[L4D2_PLAYER_STATS_MAX_SURVIVORS + 1];
		Announce_AddNamedMetricIntColumns(panel, phraseTarget, columnNames, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedSupport.boomerVomitVictims;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedSupport.boomerVomitVictims; }
		Announce_AddMetricRowValues(panel, boomerLabel, values, columnCount);

		for (int i = 0; i < infectedCount; i++) values[i] = g_Round.players[infectedSlots[i]].infectedSupport.spitterDamage;
		if (includeAi) { values[infectedCount] = 0; for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++) if (Stats_IsValidRoundSlot(slot) && g_Round.players[slot].team == PlayerStatsTeam_Infected && g_Round.players[slot].player.bot) values[infectedCount] += g_Round.players[slot].infectedSupport.spitterDamage; }
		Announce_AddMetricRowValues(panel, spitLabel, values, columnCount);

		ConsolePanel_RenderToClient(panel, client);
		rendered = true;
	}

	return rendered;
}

void Announce_GetMetricTimeCell(char[] buffer, int maxlen, float startedAt, float endedAt)
{
	float finish = endedAt > 0.0 ? endedAt : GetGameTime();
	int duration = startedAt > 0.0 && finish > startedAt ? RoundToFloor(finish - startedAt) : 0;
	Format(buffer, maxlen, "%dm %02ds", duration / 60, duration % 60);
}

void Announce_AddNamedMetricStringColumns(ConsolePanel panel, int phraseTarget, char[][] names, int count)
{
	char metricLabel[16];
	Format(metricLabel, sizeof(metricLabel), "%T", "ColumnMetric", phraseTarget);
	ConsoleTable_AddColumn(panel.table, metricLabel, 12, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < count; i++)
	{
		ConsoleTable_AddColumn(panel.table, names[i], 14, ConsoleTableAlignment_Right, ConsoleTableCellType_String);
	}
}

void Announce_AddNamedMetricIntColumns(ConsolePanel panel, int phraseTarget, char[][] names, int count)
{
	char metricLabel[16];
	Format(metricLabel, sizeof(metricLabel), "%T", "ColumnMetric", phraseTarget);
	ConsoleTable_AddColumn(panel.table, metricLabel, 12, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < count; i++)
	{
		ConsoleTable_AddColumn(panel.table, names[i], 14, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
}

bool Announce_RenderTankPanels(int client = 0)
{
	if (!Announce_RequireCompetitiveModeForCommand(client))
	{
		return false;
	}

	if (!Stats_HasRoundSnapshot())
	{
		Announce_ReplyCommandPhrase(client, "RoundSnapshotUnavailable");
		return false;
	}

	if (!Announce_HasTankStats())
	{
		Announce_ReplyCommandPhrase(client, "StatsUnavailable");
		return false;
	}

	bool rendered = false;
	int phraseTarget = client > 0 ? client : LANG_SERVER;

	for (int sessionIndex = 0; sessionIndex < g_Round.tankSessionCount; sessionIndex++)
	{
		if (g_Round.tankSessions[sessionIndex].sessionId <= 0)
		{
			continue;
		}

		int controllerCount = g_Round.tankSessions[sessionIndex].controllerCount;
		if (controllerCount <= 0)
		{
			continue;
		}

		ConsolePanel panel;
		ConsolePanel_Reset(panel);
		ConsolePanel_SetWidth(panel, 100);
		ConsolePanel_EnableSafeAscii(panel, false);

		char line[128];
		char titleName[64];
		Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, phraseTarget);
		Format(line, sizeof(line), "%T", "PanelTitleTankStats", phraseTarget, titleName, g_Round.meta.id, g_Round.tankSessions[sessionIndex].sessionId);
		ConsolePanel_AddHeaderLine(panel, line);
		Format(line, sizeof(line), "%T", "PanelTotalsTank", phraseTarget,
			g_Round.tankSessions[sessionIndex].totalDamage,
			g_Round.tankSessions[sessionIndex].incaps,
			g_Round.tankSessions[sessionIndex].deaths);
		ConsolePanel_AddHeaderLine(panel, line);

		char controllerNames[L4D2_PLAYER_STATS_MAX_TANK_CONTROLLERS][MAX_NAME_LENGTH];
		for (int i = 0; i < controllerCount; i++)
		{
			strcopy(controllerNames[i], sizeof(controllerNames[]), g_Round.tankSessions[sessionIndex].controllers[i].name);
		}

		Announce_AddNamedMetricStringColumns(panel, phraseTarget, controllerNames, controllerCount);

		char timeA[16], timeB[16], timeC[16], timeD[16];
		timeA[0] = '\0'; timeB[0] = '\0'; timeC[0] = '\0'; timeD[0] = '\0';
		if (controllerCount > 0) Announce_GetMetricTimeCell(timeA, sizeof(timeA), g_Round.tankSessions[sessionIndex].controllers[0].startedAt, g_Round.tankSessions[sessionIndex].controllers[0].endedAt);
		if (controllerCount > 1) Announce_GetMetricTimeCell(timeB, sizeof(timeB), g_Round.tankSessions[sessionIndex].controllers[1].startedAt, g_Round.tankSessions[sessionIndex].controllers[1].endedAt);
		if (controllerCount > 2) Announce_GetMetricTimeCell(timeC, sizeof(timeC), g_Round.tankSessions[sessionIndex].controllers[2].startedAt, g_Round.tankSessions[sessionIndex].controllers[2].endedAt);
		if (controllerCount > 3) Announce_GetMetricTimeCell(timeD, sizeof(timeD), g_Round.tankSessions[sessionIndex].controllers[3].startedAt, g_Round.tankSessions[sessionIndex].controllers[3].endedAt);

		char timeLabel[16], dmgLabel[16], incapLabel[16], deathLabel[16], wipeLabel[16], punchLabel[16], rockLabel[16], hitLabel[16];
		Format(timeLabel, sizeof(timeLabel), "%T", "ColumnTime", phraseTarget);
		Format(dmgLabel, sizeof(dmgLabel), "%T", "ColumnDamageShort", phraseTarget);
		Format(incapLabel, sizeof(incapLabel), "%T", "ColumnIncaps", phraseTarget);
		Format(deathLabel, sizeof(deathLabel), "%T", "ColumnDeaths", phraseTarget);
		Format(wipeLabel, sizeof(wipeLabel), "%T", "ColumnWipe", phraseTarget);
		Format(punchLabel, sizeof(punchLabel), "%T", "ColumnPunches", phraseTarget);
		Format(rockLabel, sizeof(rockLabel), "%T", "ColumnRocks", phraseTarget);
		Format(hitLabel, sizeof(hitLabel), "%T", "ColumnHittables", phraseTarget);
		Announce_FormatMetricUnitLabel(dmgLabel, sizeof(dmgLabel), dmgLabel, "dmg", false);
		Announce_FormatMetricUnitLabel(incapLabel, sizeof(incapLabel), incapLabel, "#");
		Announce_FormatMetricUnitLabel(deathLabel, sizeof(deathLabel), deathLabel, "#");
		Announce_FormatMetricUnitLabel(punchLabel, sizeof(punchLabel), punchLabel, "#");
		Announce_FormatMetricUnitLabel(rockLabel, sizeof(rockLabel), rockLabel, "#");
		Announce_FormatMetricUnitLabel(hitLabel, sizeof(hitLabel), hitLabel, "#");

		Announce_AddMetricStringRow(panel, timeLabel, controllerCount, timeA, timeB, timeC, timeD);
		Announce_AddMetricRow(panel, dmgLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].damage,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].damage : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].damage : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].damage : 0);
		Announce_AddMetricRow(panel, incapLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].incaps,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].incaps : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].incaps : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].incaps : 0);
		Announce_AddMetricRow(panel, deathLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].deaths,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].deaths : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].deaths : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].deaths : 0);
		Announce_AddMetricRow(panel, wipeLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].wipe ? 1 : 0,
			controllerCount > 1 ? (g_Round.tankSessions[sessionIndex].controllers[1].wipe ? 1 : 0) : 0,
			controllerCount > 2 ? (g_Round.tankSessions[sessionIndex].controllers[2].wipe ? 1 : 0) : 0,
			controllerCount > 3 ? (g_Round.tankSessions[sessionIndex].controllers[3].wipe ? 1 : 0) : 0);
		Announce_AddMetricRow(panel, punchLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].punches,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].punches : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].punches : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].punches : 0);
		Announce_AddMetricRow(panel, rockLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].rocks,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].rocks : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].rocks : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].rocks : 0);
		Announce_AddMetricRow(panel, hitLabel, controllerCount,
			g_Round.tankSessions[sessionIndex].controllers[0].hittables,
			controllerCount > 1 ? g_Round.tankSessions[sessionIndex].controllers[1].hittables : 0,
			controllerCount > 2 ? g_Round.tankSessions[sessionIndex].controllers[2].hittables : 0,
			controllerCount > 3 ? g_Round.tankSessions[sessionIndex].controllers[3].hittables : 0);

		ConsolePanel_RenderToClient(panel, client);
		rendered = true;
	}

	return rendered;
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
	char siLabel[24];
	char tankLabel[24];
	char witchLabel[24];
	char ciLabel[24];
	char ffLabel[24];
	Announce_FormatPanelTitle(line, sizeof(line), client > 0 ? client : LANG_SERVER);
	ConsolePanel_AddHeaderLine(panel, line);
	Announce_GetColumnLabel(siLabel, sizeof(siLabel), "ColumnSpecialInfected", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(tankLabel, sizeof(tankLabel), "ColumnTank", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(witchLabel, sizeof(witchLabel), "ColumnWitch", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(ciLabel, sizeof(ciLabel), "ColumnCommonInfected", client > 0 ? client : LANG_SERVER);
	Announce_GetColumnLabel(ffLabel, sizeof(ffLabel), "ColumnFriendlyFire", client > 0 ? client : LANG_SERVER);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();
	bool hasDetailedKills = g_Runtime.hasPlayerSkills;
	if (hasDetailedKills)
	{
		int totalDamage = Announce_GetTotalSurvivorDamage();
		Format(line, sizeof(line), "%T", "PanelTotalsCombat", client > 0 ? client : LANG_SERVER,
			totalDamage,
			Announce_GetTotalSurvivorSpecialKills(),
			g_Round.totals.survivorTotalCommonKills,
			g_Round.totals.survivorTotalFF);
		ConsolePanel_AddHeaderLine(panel, line);
		Format(line, sizeof(line), "%T", "PanelLegendSiDamageKillBossDamageShots", client > 0 ? client : LANG_SERVER);
		ConsolePanel_AddHeaderLine(panel, line);
	}
	else if (showTank || showWitch)
	{
		Format(line, sizeof(line), "%T", "PanelLegendBossDamageHit", client > 0 ? client : LANG_SERVER);
		ConsolePanel_AddHeaderLine(panel, line);
	}

	if (hasDetailedKills)
	{
		Announce_AddMetricPlayerStringColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

		char siA[32], siB[32], siC[32], siD[32];
		char tankA[32], tankB[32], tankC[32], tankD[32];
		char witchA[32], witchB[32], witchC[32], witchD[32];
		char ciA[16], ciB[16], ciC[16], ciD[16];
		char ffA[16], ffB[16], ffC[16], ffD[16];

		Announce_FormatDamageKillCell(siA, sizeof(siA), Announce_GetPlayerSiDamage(survivorSlots[0]), Announce_GetPlayerSpecialKills(survivorSlots[0]));
		Announce_FormatDamageShotsCell(tankA, sizeof(tankA), g_Round.players[survivorSlots[0]].bossDetail.tankDamage, g_Round.players[survivorSlots[0]].bossDetail.tankShots);
		Announce_FormatDamageShotsCell(witchA, sizeof(witchA), g_Round.players[survivorSlots[0]].bossDetail.witchDamage, g_Round.players[survivorSlots[0]].bossDetail.witchShots);
		Announce_FormatIntCell(ciA, sizeof(ciA), g_Round.players[survivorSlots[0]].combat.commonKills);
		Announce_FormatIntCell(ffA, sizeof(ffA), g_Round.players[survivorSlots[0]].combat.ffGiven);

		if (survivorCount > 1)
		{
			Announce_FormatDamageKillCell(siB, sizeof(siB), Announce_GetPlayerSiDamage(survivorSlots[1]), Announce_GetPlayerSpecialKills(survivorSlots[1]));
			Announce_FormatDamageShotsCell(tankB, sizeof(tankB), g_Round.players[survivorSlots[1]].bossDetail.tankDamage, g_Round.players[survivorSlots[1]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchB, sizeof(witchB), g_Round.players[survivorSlots[1]].bossDetail.witchDamage, g_Round.players[survivorSlots[1]].bossDetail.witchShots);
			Announce_FormatIntCell(ciB, sizeof(ciB), g_Round.players[survivorSlots[1]].combat.commonKills);
			Announce_FormatIntCell(ffB, sizeof(ffB), g_Round.players[survivorSlots[1]].combat.ffGiven);
		}
		if (survivorCount > 2)
		{
			Announce_FormatDamageKillCell(siC, sizeof(siC), Announce_GetPlayerSiDamage(survivorSlots[2]), Announce_GetPlayerSpecialKills(survivorSlots[2]));
			Announce_FormatDamageShotsCell(tankC, sizeof(tankC), g_Round.players[survivorSlots[2]].bossDetail.tankDamage, g_Round.players[survivorSlots[2]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchC, sizeof(witchC), g_Round.players[survivorSlots[2]].bossDetail.witchDamage, g_Round.players[survivorSlots[2]].bossDetail.witchShots);
			Announce_FormatIntCell(ciC, sizeof(ciC), g_Round.players[survivorSlots[2]].combat.commonKills);
			Announce_FormatIntCell(ffC, sizeof(ffC), g_Round.players[survivorSlots[2]].combat.ffGiven);
		}
		if (survivorCount > 3)
		{
			Announce_FormatDamageKillCell(siD, sizeof(siD), Announce_GetPlayerSiDamage(survivorSlots[3]), Announce_GetPlayerSpecialKills(survivorSlots[3]));
			Announce_FormatDamageShotsCell(tankD, sizeof(tankD), g_Round.players[survivorSlots[3]].bossDetail.tankDamage, g_Round.players[survivorSlots[3]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchD, sizeof(witchD), g_Round.players[survivorSlots[3]].bossDetail.witchDamage, g_Round.players[survivorSlots[3]].bossDetail.witchShots);
			Announce_FormatIntCell(ciD, sizeof(ciD), g_Round.players[survivorSlots[3]].combat.commonKills);
			Announce_FormatIntCell(ffD, sizeof(ffD), g_Round.players[survivorSlots[3]].combat.ffGiven);
		}

		Announce_AddMetricStringRow(panel, siLabel, survivorCount, siA, siB, siC, siD);
		if (showTank)
		{
			Announce_AddMetricStringRow(panel, tankLabel, survivorCount, tankA, tankB, tankC, tankD);
		}
		if (showWitch)
		{
			Announce_AddMetricStringRow(panel, witchLabel, survivorCount, witchA, witchB, witchC, witchD);
		}
		Announce_AddMetricStringRow(panel, ciLabel, survivorCount, ciA, ciB, ciC, ciD);
		Announce_AddMetricStringRow(panel, ffLabel, survivorCount, ffA, ffB, ffC, ffD);
	}
	else
	{
		Announce_AddMetricPlayerStringColumns(panel, client > 0 ? client : LANG_SERVER, survivorSlots, survivorCount);

		char siA[16], siB[16], siC[16], siD[16];
		char tankA[32], tankB[32], tankC[32], tankD[32];
		char witchA[32], witchB[32], witchC[32], witchD[32];
		char ciA[16], ciB[16], ciC[16], ciD[16];
		char ffA[16], ffB[16], ffC[16], ffD[16];

		Announce_FormatIntCell(siA, sizeof(siA), Announce_GetPlayerSiDamage(survivorSlots[0]));
		Announce_FormatDamageHitCell(tankA, sizeof(tankA), g_Round.players[survivorSlots[0]].combat.tankDamage, g_Round.players[survivorSlots[0]].combat.tankHits);
		Announce_FormatDamageHitCell(witchA, sizeof(witchA), g_Round.players[survivorSlots[0]].combat.witchDamage, g_Round.players[survivorSlots[0]].combat.witchHits);
		Announce_FormatIntCell(ciA, sizeof(ciA), g_Round.players[survivorSlots[0]].combat.commonKills);
		Announce_FormatIntCell(ffA, sizeof(ffA), g_Round.players[survivorSlots[0]].combat.ffGiven);

		if (survivorCount > 1)
		{
			Announce_FormatIntCell(siB, sizeof(siB), Announce_GetPlayerSiDamage(survivorSlots[1]));
			Announce_FormatDamageHitCell(tankB, sizeof(tankB), g_Round.players[survivorSlots[1]].combat.tankDamage, g_Round.players[survivorSlots[1]].combat.tankHits);
			Announce_FormatDamageHitCell(witchB, sizeof(witchB), g_Round.players[survivorSlots[1]].combat.witchDamage, g_Round.players[survivorSlots[1]].combat.witchHits);
			Announce_FormatIntCell(ciB, sizeof(ciB), g_Round.players[survivorSlots[1]].combat.commonKills);
			Announce_FormatIntCell(ffB, sizeof(ffB), g_Round.players[survivorSlots[1]].combat.ffGiven);
		}
		if (survivorCount > 2)
		{
			Announce_FormatIntCell(siC, sizeof(siC), Announce_GetPlayerSiDamage(survivorSlots[2]));
			Announce_FormatDamageHitCell(tankC, sizeof(tankC), g_Round.players[survivorSlots[2]].combat.tankDamage, g_Round.players[survivorSlots[2]].combat.tankHits);
			Announce_FormatDamageHitCell(witchC, sizeof(witchC), g_Round.players[survivorSlots[2]].combat.witchDamage, g_Round.players[survivorSlots[2]].combat.witchHits);
			Announce_FormatIntCell(ciC, sizeof(ciC), g_Round.players[survivorSlots[2]].combat.commonKills);
			Announce_FormatIntCell(ffC, sizeof(ffC), g_Round.players[survivorSlots[2]].combat.ffGiven);
		}
		if (survivorCount > 3)
		{
			Announce_FormatIntCell(siD, sizeof(siD), Announce_GetPlayerSiDamage(survivorSlots[3]));
			Announce_FormatDamageHitCell(tankD, sizeof(tankD), g_Round.players[survivorSlots[3]].combat.tankDamage, g_Round.players[survivorSlots[3]].combat.tankHits);
			Announce_FormatDamageHitCell(witchD, sizeof(witchD), g_Round.players[survivorSlots[3]].combat.witchDamage, g_Round.players[survivorSlots[3]].combat.witchHits);
			Announce_FormatIntCell(ciD, sizeof(ciD), g_Round.players[survivorSlots[3]].combat.commonKills);
			Announce_FormatIntCell(ffD, sizeof(ffD), g_Round.players[survivorSlots[3]].combat.ffGiven);
		}

		Announce_AddMetricStringRow(panel, siLabel, survivorCount, siA, siB, siC, siD);
		if (showTank)
		{
			Announce_AddMetricStringRow(panel, tankLabel, survivorCount, tankA, tankB, tankC, tankD);
		}
		if (showWitch)
		{
			Announce_AddMetricStringRow(panel, witchLabel, survivorCount, witchA, witchB, witchC, witchD);
		}
		Announce_AddMetricStringRow(panel, ciLabel, survivorCount, ciA, ciB, ciC, ciD);
		Announce_AddMetricStringRow(panel, ffLabel, survivorCount, ffA, ffB, ffC, ffD);
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

bool Announce_RenderSiKillAssistBreakdownPanel(int client = 0)
{
	if (!g_Runtime.hasPlayerSkills || !Stats_HasRoundSnapshot() || !Announce_HasCombatStats())
	{
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

	int phraseTarget = client > 0 ? client : LANG_SERVER;
	char line[160];
	char titleName[64];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, phraseTarget);
	Format(line, sizeof(line), "%T", "PanelTitleSiKillAssistBreakdown", phraseTarget, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "%T", "PanelLegendDamageKillAssistDamage", phraseTarget);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerStringColumns(panel, phraseTarget, survivorSlots, survivorCount);

	L4D2ZombieClassType classes[6] =
	{
		L4D2ZombieClass_Smoker,
		L4D2ZombieClass_Boomer,
		L4D2ZombieClass_Hunter,
		L4D2ZombieClass_Spitter,
		L4D2ZombieClass_Jockey,
		L4D2ZombieClass_Charger
	};
	static const char labels[][] =
	{
		"Smoker",
		"Boomer",
		"Hunter",
		"Spitter",
		"Jockey",
		"Charger"
	};

	for (int classIndex = 0; classIndex < sizeof(classes); classIndex++)
	{
		if (!Stats_IsZombieClassEnabledForRound(classes[classIndex]))
		{
			continue;
		}

		char cellA[32], cellB[32], cellC[32], cellD[32];
		Announce_FormatDamageKillAssistCell(cellA, sizeof(cellA),
			Announce_GetPlayerSpecialDamageByClass(survivorSlots[0], classes[classIndex]),
			Announce_GetPlayerSpecialKillsByClass(survivorSlots[0], classes[classIndex]),
			Announce_GetPlayerSpecialAssistDamageByClass(survivorSlots[0], classes[classIndex]));

		if (survivorCount > 1)
		{
			Announce_FormatDamageKillAssistCell(cellB, sizeof(cellB),
				Announce_GetPlayerSpecialDamageByClass(survivorSlots[1], classes[classIndex]),
				Announce_GetPlayerSpecialKillsByClass(survivorSlots[1], classes[classIndex]),
				Announce_GetPlayerSpecialAssistDamageByClass(survivorSlots[1], classes[classIndex]));
		}
		if (survivorCount > 2)
		{
			Announce_FormatDamageKillAssistCell(cellC, sizeof(cellC),
				Announce_GetPlayerSpecialDamageByClass(survivorSlots[2], classes[classIndex]),
				Announce_GetPlayerSpecialKillsByClass(survivorSlots[2], classes[classIndex]),
				Announce_GetPlayerSpecialAssistDamageByClass(survivorSlots[2], classes[classIndex]));
		}
		if (survivorCount > 3)
		{
			Announce_FormatDamageKillAssistCell(cellD, sizeof(cellD),
				Announce_GetPlayerSpecialDamageByClass(survivorSlots[3], classes[classIndex]),
				Announce_GetPlayerSpecialKillsByClass(survivorSlots[3], classes[classIndex]),
				Announce_GetPlayerSpecialAssistDamageByClass(survivorSlots[3], classes[classIndex]));
		}

		Announce_AddMetricStringRow(panel, labels[classIndex], survivorCount, cellA, cellB, cellC, cellD);
	}

	ConsolePanel_RenderToClient(panel, client);
	return true;
}

bool Announce_RenderBossDamageDetailPanel(int client = 0)
{
	if (!g_Runtime.hasPlayerSkills || !Stats_HasRoundSnapshot() || !Announce_HasCombatStats())
	{
		return false;
	}

	int survivorSlots[L4D2_PLAYER_STATS_MAX_SURVIVORS];
	int survivorCount = Announce_CollectSortedSurvivorSlotsByDamage(survivorSlots, sizeof(survivorSlots));
	if (survivorCount <= 0)
	{
		return false;
	}

	bool showTank = false;
	bool showWitch = false;
	for (int i = 0; i < survivorCount; i++)
	{
		int slot = survivorSlots[i];
		if (g_Round.players[slot].bossDetail.tankDamage > 0 || g_Round.players[slot].bossDetail.tankShots > 0)
		{
			showTank = true;
		}
		if (g_Round.players[slot].bossDetail.witchDamage > 0 || g_Round.players[slot].bossDetail.witchShots > 0)
		{
			showWitch = true;
		}
	}

	if (!showTank && !showWitch)
	{
		return false;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	int phraseTarget = client > 0 ? client : LANG_SERVER;
	char line[160];
	char titleName[64];
	char tankLabel[24];
	char witchLabel[24];
	Announce_GetTitleName(titleName, sizeof(titleName), GAMEMODE_UNKNOWN, phraseTarget);
	Announce_GetColumnLabel(tankLabel, sizeof(tankLabel), "ColumnTank", phraseTarget);
	Announce_GetColumnLabel(witchLabel, sizeof(witchLabel), "ColumnWitch", phraseTarget);
	Format(line, sizeof(line), "%T", "PanelTitleBossDamageDetail", phraseTarget, titleName, g_Round.meta.id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "%T", "PanelLegendDamageShots", phraseTarget);
	ConsolePanel_AddHeaderLine(panel, line);

	Announce_AddMetricPlayerStringColumns(panel, phraseTarget, survivorSlots, survivorCount);

	char tankA[32], tankB[32], tankC[32], tankD[32];
	char witchA[32], witchB[32], witchC[32], witchD[32];

	if (showTank)
	{
		Announce_FormatDamageShotsCell(tankA, sizeof(tankA), g_Round.players[survivorSlots[0]].bossDetail.tankDamage, g_Round.players[survivorSlots[0]].bossDetail.tankShots);
		if (survivorCount > 1)
		{
			Announce_FormatDamageShotsCell(tankB, sizeof(tankB), g_Round.players[survivorSlots[1]].bossDetail.tankDamage, g_Round.players[survivorSlots[1]].bossDetail.tankShots);
		}
		if (survivorCount > 2)
		{
			Announce_FormatDamageShotsCell(tankC, sizeof(tankC), g_Round.players[survivorSlots[2]].bossDetail.tankDamage, g_Round.players[survivorSlots[2]].bossDetail.tankShots);
		}
		if (survivorCount > 3)
		{
			Announce_FormatDamageShotsCell(tankD, sizeof(tankD), g_Round.players[survivorSlots[3]].bossDetail.tankDamage, g_Round.players[survivorSlots[3]].bossDetail.tankShots);
		}
		Announce_AddMetricStringRow(panel, tankLabel, survivorCount, tankA, tankB, tankC, tankD);
	}

	if (showWitch)
	{
		Announce_FormatDamageShotsCell(witchA, sizeof(witchA), g_Round.players[survivorSlots[0]].bossDetail.witchDamage, g_Round.players[survivorSlots[0]].bossDetail.witchShots);
		if (survivorCount > 1)
		{
			Announce_FormatDamageShotsCell(witchB, sizeof(witchB), g_Round.players[survivorSlots[1]].bossDetail.witchDamage, g_Round.players[survivorSlots[1]].bossDetail.witchShots);
		}
		if (survivorCount > 2)
		{
			Announce_FormatDamageShotsCell(witchC, sizeof(witchC), g_Round.players[survivorSlots[2]].bossDetail.witchDamage, g_Round.players[survivorSlots[2]].bossDetail.witchShots);
		}
		if (survivorCount > 3)
		{
			Announce_FormatDamageShotsCell(witchD, sizeof(witchD), g_Round.players[survivorSlots[3]].bossDetail.witchDamage, g_Round.players[survivorSlots[3]].bossDetail.witchShots);
		}
		Announce_AddMetricStringRow(panel, witchLabel, survivorCount, witchA, witchB, witchC, witchD);
	}

	if (client > 0)
	{
		ConsolePanel_RenderToClient(panel, client);
	}
	else
	{
		ConsolePanel_RenderToAudience(panel);
	}
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
	char siLabel[24];
	char tankLabel[24];
	char witchLabel[24];
	char ciLabel[24];
	char ffLabel[24];
	Announce_GetColumnLabel(siLabel, sizeof(siLabel), "ColumnSpecialInfected", LANG_SERVER);
	Announce_GetColumnLabel(tankLabel, sizeof(tankLabel), "ColumnTank", LANG_SERVER);
	Announce_GetColumnLabel(witchLabel, sizeof(witchLabel), "ColumnWitch", LANG_SERVER);
	Announce_GetColumnLabel(ciLabel, sizeof(ciLabel), "ColumnCommonInfected", LANG_SERVER);
	Announce_GetColumnLabel(ffLabel, sizeof(ffLabel), "ColumnFriendlyFire", LANG_SERVER);

	bool showTank = Announce_ShouldShowTankDamage();
	bool showWitch = Announce_ShouldShowWitchDamage();
	bool hasDetailedKills = g_Runtime.hasPlayerSkills;
	if (hasDetailedKills)
	{
		int totalDamage = Announce_GetTotalSurvivorDamage();
		Format(line, sizeof(line), "%T", "PanelTotalsCombat", LANG_SERVER,
			totalDamage,
			Announce_GetTotalSurvivorSpecialKills(),
			g_Round.totals.survivorTotalCommonKills,
			g_Round.totals.survivorTotalFF);
		ConsolePanel_AddHeaderLine(panel, line);
		Format(line, sizeof(line), "%T", "PanelLegendSiDamageKillBossDamageShots", LANG_SERVER);
		ConsolePanel_AddHeaderLine(panel, line);
	}
	else if (showTank || showWitch)
	{
		Format(line, sizeof(line), "%T", "PanelLegendBossDamageHit", LANG_SERVER);
		ConsolePanel_AddHeaderLine(panel, line);
	}

	if (hasDetailedKills)
	{
		Announce_AddMetricPlayerStringColumns(panel, LANG_SERVER, survivorSlots, survivorCount);

		char siA[32], siB[32], siC[32], siD[32];
		char tankA[32], tankB[32], tankC[32], tankD[32];
		char witchA[32], witchB[32], witchC[32], witchD[32];
		char ciA[16], ciB[16], ciC[16], ciD[16];
		char ffA[16], ffB[16], ffC[16], ffD[16];

		Announce_FormatDamageKillCell(siA, sizeof(siA), Announce_GetPlayerSiDamage(survivorSlots[0]), Announce_GetPlayerSpecialKills(survivorSlots[0]));
		Announce_FormatDamageShotsCell(tankA, sizeof(tankA), g_Round.players[survivorSlots[0]].bossDetail.tankDamage, g_Round.players[survivorSlots[0]].bossDetail.tankShots);
		Announce_FormatDamageShotsCell(witchA, sizeof(witchA), g_Round.players[survivorSlots[0]].bossDetail.witchDamage, g_Round.players[survivorSlots[0]].bossDetail.witchShots);
		Announce_FormatIntCell(ciA, sizeof(ciA), g_Round.players[survivorSlots[0]].combat.commonKills);
		Announce_FormatIntCell(ffA, sizeof(ffA), g_Round.players[survivorSlots[0]].combat.ffGiven);

		if (survivorCount > 1)
		{
			Announce_FormatDamageKillCell(siB, sizeof(siB), Announce_GetPlayerSiDamage(survivorSlots[1]), Announce_GetPlayerSpecialKills(survivorSlots[1]));
			Announce_FormatDamageShotsCell(tankB, sizeof(tankB), g_Round.players[survivorSlots[1]].bossDetail.tankDamage, g_Round.players[survivorSlots[1]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchB, sizeof(witchB), g_Round.players[survivorSlots[1]].bossDetail.witchDamage, g_Round.players[survivorSlots[1]].bossDetail.witchShots);
			Announce_FormatIntCell(ciB, sizeof(ciB), g_Round.players[survivorSlots[1]].combat.commonKills);
			Announce_FormatIntCell(ffB, sizeof(ffB), g_Round.players[survivorSlots[1]].combat.ffGiven);
		}
		if (survivorCount > 2)
		{
			Announce_FormatDamageKillCell(siC, sizeof(siC), Announce_GetPlayerSiDamage(survivorSlots[2]), Announce_GetPlayerSpecialKills(survivorSlots[2]));
			Announce_FormatDamageShotsCell(tankC, sizeof(tankC), g_Round.players[survivorSlots[2]].bossDetail.tankDamage, g_Round.players[survivorSlots[2]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchC, sizeof(witchC), g_Round.players[survivorSlots[2]].bossDetail.witchDamage, g_Round.players[survivorSlots[2]].bossDetail.witchShots);
			Announce_FormatIntCell(ciC, sizeof(ciC), g_Round.players[survivorSlots[2]].combat.commonKills);
			Announce_FormatIntCell(ffC, sizeof(ffC), g_Round.players[survivorSlots[2]].combat.ffGiven);
		}
		if (survivorCount > 3)
		{
			Announce_FormatDamageKillCell(siD, sizeof(siD), Announce_GetPlayerSiDamage(survivorSlots[3]), Announce_GetPlayerSpecialKills(survivorSlots[3]));
			Announce_FormatDamageShotsCell(tankD, sizeof(tankD), g_Round.players[survivorSlots[3]].bossDetail.tankDamage, g_Round.players[survivorSlots[3]].bossDetail.tankShots);
			Announce_FormatDamageShotsCell(witchD, sizeof(witchD), g_Round.players[survivorSlots[3]].bossDetail.witchDamage, g_Round.players[survivorSlots[3]].bossDetail.witchShots);
			Announce_FormatIntCell(ciD, sizeof(ciD), g_Round.players[survivorSlots[3]].combat.commonKills);
			Announce_FormatIntCell(ffD, sizeof(ffD), g_Round.players[survivorSlots[3]].combat.ffGiven);
		}

		Announce_AddMetricStringRow(panel, siLabel, survivorCount, siA, siB, siC, siD);
		if (showTank)
		{
			Announce_AddMetricStringRow(panel, tankLabel, survivorCount, tankA, tankB, tankC, tankD);
		}
		if (showWitch)
		{
			Announce_AddMetricStringRow(panel, witchLabel, survivorCount, witchA, witchB, witchC, witchD);
		}
		Announce_AddMetricStringRow(panel, ciLabel, survivorCount, ciA, ciB, ciC, ciD);
		Announce_AddMetricStringRow(panel, ffLabel, survivorCount, ffA, ffB, ffC, ffD);
	}
	else
	{
		Announce_AddMetricPlayerStringColumns(panel, LANG_SERVER, survivorSlots, survivorCount);

		char siA[16], siB[16], siC[16], siD[16];
		char tankA[32], tankB[32], tankC[32], tankD[32];
		char witchA[32], witchB[32], witchC[32], witchD[32];
		char ciA[16], ciB[16], ciC[16], ciD[16];
		char ffA[16], ffB[16], ffC[16], ffD[16];

		Announce_FormatIntCell(siA, sizeof(siA), Announce_GetPlayerSiDamage(survivorSlots[0]));
		Announce_FormatDamageHitCell(tankA, sizeof(tankA), g_Round.players[survivorSlots[0]].combat.tankDamage, g_Round.players[survivorSlots[0]].combat.tankHits);
		Announce_FormatDamageHitCell(witchA, sizeof(witchA), g_Round.players[survivorSlots[0]].combat.witchDamage, g_Round.players[survivorSlots[0]].combat.witchHits);
		Announce_FormatIntCell(ciA, sizeof(ciA), g_Round.players[survivorSlots[0]].combat.commonKills);
		Announce_FormatIntCell(ffA, sizeof(ffA), g_Round.players[survivorSlots[0]].combat.ffGiven);

		if (survivorCount > 1)
		{
			Announce_FormatIntCell(siB, sizeof(siB), Announce_GetPlayerSiDamage(survivorSlots[1]));
			Announce_FormatDamageHitCell(tankB, sizeof(tankB), g_Round.players[survivorSlots[1]].combat.tankDamage, g_Round.players[survivorSlots[1]].combat.tankHits);
			Announce_FormatDamageHitCell(witchB, sizeof(witchB), g_Round.players[survivorSlots[1]].combat.witchDamage, g_Round.players[survivorSlots[1]].combat.witchHits);
			Announce_FormatIntCell(ciB, sizeof(ciB), g_Round.players[survivorSlots[1]].combat.commonKills);
			Announce_FormatIntCell(ffB, sizeof(ffB), g_Round.players[survivorSlots[1]].combat.ffGiven);
		}
		if (survivorCount > 2)
		{
			Announce_FormatIntCell(siC, sizeof(siC), Announce_GetPlayerSiDamage(survivorSlots[2]));
			Announce_FormatDamageHitCell(tankC, sizeof(tankC), g_Round.players[survivorSlots[2]].combat.tankDamage, g_Round.players[survivorSlots[2]].combat.tankHits);
			Announce_FormatDamageHitCell(witchC, sizeof(witchC), g_Round.players[survivorSlots[2]].combat.witchDamage, g_Round.players[survivorSlots[2]].combat.witchHits);
			Announce_FormatIntCell(ciC, sizeof(ciC), g_Round.players[survivorSlots[2]].combat.commonKills);
			Announce_FormatIntCell(ffC, sizeof(ffC), g_Round.players[survivorSlots[2]].combat.ffGiven);
		}
		if (survivorCount > 3)
		{
			Announce_FormatIntCell(siD, sizeof(siD), Announce_GetPlayerSiDamage(survivorSlots[3]));
			Announce_FormatDamageHitCell(tankD, sizeof(tankD), g_Round.players[survivorSlots[3]].combat.tankDamage, g_Round.players[survivorSlots[3]].combat.tankHits);
			Announce_FormatDamageHitCell(witchD, sizeof(witchD), g_Round.players[survivorSlots[3]].combat.witchDamage, g_Round.players[survivorSlots[3]].combat.witchHits);
			Announce_FormatIntCell(ciD, sizeof(ciD), g_Round.players[survivorSlots[3]].combat.commonKills);
			Announce_FormatIntCell(ffD, sizeof(ffD), g_Round.players[survivorSlots[3]].combat.ffGiven);
		}

		Announce_AddMetricStringRow(panel, siLabel, survivorCount, siA, siB, siC, siD);
		if (showTank)
		{
			Announce_AddMetricStringRow(panel, tankLabel, survivorCount, tankA, tankB, tankC, tankD);
		}
		if (showWitch)
		{
			Announce_AddMetricStringRow(panel, witchLabel, survivorCount, witchA, witchB, witchC, witchD);
		}
		Announce_AddMetricStringRow(panel, ciLabel, survivorCount, ciA, ciB, ciC, ciD);
		Announce_AddMetricStringRow(panel, ffLabel, survivorCount, ffA, ffB, ffC, ffD);
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
	if (hasDetailedKills)
	{
		Announce_RenderSiKillAssistBreakdownPanel(0);
		Announce_RenderBossDamageDetailPanel(0);
	}
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

void Announce_AddMetricRowValues(ConsolePanel panel, const char[] metricLabel, int[] values, int valueCount)
{
	if (!ConsoleTable_BeginRow(panel.table))
	{
		return;
	}

	ConsoleTable_AddStringCell(panel.table, metricLabel);

	for (int i = 0; i < valueCount; i++)
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

void Announce_FormatDamageKillCell(char[] buffer, int maxlen, int damage, int kills)
{
	Format(buffer, maxlen, "%d/%d", damage, kills);
}

void Announce_FormatDamageHitCell(char[] buffer, int maxlen, int damage, int hits)
{
	Format(buffer, maxlen, "%d/%d", damage, hits);
}

void Announce_FormatDamageShotsCell(char[] buffer, int maxlen, int damage, int shots)
{
	Format(buffer, maxlen, "%d/%d", damage, shots);
}

void Announce_FormatIntCell(char[] buffer, int maxlen, int value)
{
	Format(buffer, maxlen, "%d", value);
}

void Announce_FormatDamageKillAssistCell(char[] buffer, int maxlen, int damage, int kills, int assistDamage)
{
	Format(buffer, maxlen, "%d/%d/%d", damage, kills, assistDamage);
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
	ConsoleTable_AddColumn(panel.table, metricLabel, 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < survivorCount; i++)
	{
		ConsoleTable_AddColumn(panel.table, g_Round.players[survivorSlots[i]].player.name, 14, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	}
}

void Announce_AddMetricPlayerStringColumns(ConsolePanel panel, int phraseTarget, int[] survivorSlots, int survivorCount)
{
	char metricLabel[16];
	Format(metricLabel, sizeof(metricLabel), "%T", "ColumnMetric", phraseTarget);
	ConsoleTable_AddColumn(panel.table, metricLabel, 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

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

int Announce_GetDisplayAccuracyHits(int hits, int shots, bool clampToShots = false)
{
	if (!clampToShots || shots <= 0 || hits <= shots)
	{
		return hits;
	}

	return shots;
}

int Announce_GetDisplayAccuracyPercent(int hits, int shots, bool clampToShots = false)
{
	return Announce_GetPercent(Announce_GetDisplayAccuracyHits(hits, shots, clampToShots), shots);
}

void Announce_FormatAccuracyCell(char[] buffer, int maxlen, int hits, int shots, bool clampToShots = false)
{
	int displayHits = Announce_GetDisplayAccuracyHits(hits, shots, clampToShots);
	Format(buffer, maxlen, "%d/%d %d%%", displayHits, shots, Announce_GetDisplayAccuracyPercent(hits, shots, clampToShots));
}

int Announce_GetPlayerAccuracyGroupHits(int slot, int groupIndex)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	switch (groupIndex)
	{
		case 0:
		{
			return g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_PumpShotgun]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_Autoshotgun]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_ChromeShotgun]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SpasShotgun];
		}
		case 1:
		{
			return g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_Smg]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SmgSilenced]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SmgMp5];
		}
		case 2:
		{
			return g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_Rifle]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_RifleAk47]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_RifleDesert]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_RifleSg552]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_RifleM60];
		}
		case 3:
		{
			return g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_HuntingRifle]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SniperMilitary]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SniperAwp]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_SniperScout];
		}
		case 4:
		{
			return g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_Pistol]
				+ g_Round.players[slot].accuracyDetails.hits[PlayerStatsWeaponDetail_Magnum];
		}
	}

	return 0;
}

int Announce_GetPlayerAccuracyGroupShots(int slot, int groupIndex)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	switch (groupIndex)
	{
		case 0:
		{
			return g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_PumpShotgun]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_Autoshotgun]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_ChromeShotgun]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SpasShotgun];
		}
		case 1:
		{
			return g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_Smg]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SmgSilenced]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SmgMp5];
		}
		case 2:
		{
			return g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_Rifle]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_RifleAk47]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_RifleDesert]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_RifleSg552]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_RifleM60];
		}
		case 3:
		{
			return g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_HuntingRifle]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SniperMilitary]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SniperAwp]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_SniperScout];
		}
		case 4:
		{
			return g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_Pistol]
				+ g_Round.players[slot].accuracyDetails.shots[PlayerStatsWeaponDetail_Magnum];
		}
	}

	return 0;
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
	int tankShots = g_Round.players[slot].bossDetail.tankShots;
	int witchDamage = g_Round.players[slot].combat.witchDamage;
	int witchPercent = Announce_GetPercent(witchDamage, g_Round.totals.survivorTotalWitchDamage);
	int witchCount = Announce_GetEncounteredWitchCount();
	int witchShots = g_Round.players[slot].bossDetail.witchShots;

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
		if (g_Runtime.hasPlayerSkills && tankShots > 0)
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "RoundMVPDamageTankShots", phraseTarget, tankDamage, tankShots);
		}
		else if (tankCount > 1)
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
		if (g_Runtime.hasPlayerSkills && witchShots > 0)
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "RoundMVPDamageWitchShots", phraseTarget, witchDamage, witchShots);
		}
		else if (witchCount > 1)
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
	int tankShots = g_Round.players[slot].bossDetail.tankShots;
	int witchDamage = g_Round.players[slot].combat.witchDamage;
	int witchPercent = Announce_GetPercent(witchDamage, g_Round.totals.survivorTotalWitchDamage);
	int witchCount = Announce_GetEncounteredWitchCount();
	int witchShots = g_Round.players[slot].bossDetail.witchShots;

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
		if (g_Runtime.hasPlayerSkills && tankShots > 0)
		{
			Format(tankDetail, sizeof(tankDetail), "%T", "PanelMVPDamageTankShots", LANG_SERVER, tankDamage, tankShots);
		}
		else if (tankCount > 1)
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
		if (g_Runtime.hasPlayerSkills && witchShots > 0)
		{
			Format(witchDetail, sizeof(witchDetail), "%T", "PanelMVPDamageWitchShots", LANG_SERVER, witchDamage, witchShots);
		}
		else if (witchCount > 1)
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

int Announce_GetPlayerSpecialKillsByClass(int index, L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return g_Round.players[index].combat.smokerKills;
		}
		case L4D2ZombieClass_Boomer:
		{
			return g_Round.players[index].combat.boomerKills;
		}
		case L4D2ZombieClass_Hunter:
		{
			return g_Round.players[index].combat.hunterKills;
		}
		case L4D2ZombieClass_Spitter:
		{
			return g_Round.players[index].combat.spitterKills;
		}
		case L4D2ZombieClass_Jockey:
		{
			return g_Round.players[index].combat.jockeyKills;
		}
		case L4D2ZombieClass_Charger:
		{
			return g_Round.players[index].combat.chargerKills;
		}
	}

	return 0;
}

int Announce_GetPlayerSpecialAssistDamageByClass(int index, L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return g_Round.players[index].combatAssists.smokerAssistDamage;
		}
		case L4D2ZombieClass_Boomer:
		{
			return g_Round.players[index].combatAssists.boomerAssistDamage;
		}
		case L4D2ZombieClass_Hunter:
		{
			return g_Round.players[index].combatAssists.hunterAssistDamage;
		}
		case L4D2ZombieClass_Spitter:
		{
			return g_Round.players[index].combatAssists.spitterAssistDamage;
		}
		case L4D2ZombieClass_Jockey:
		{
			return g_Round.players[index].combatAssists.jockeyAssistDamage;
		}
		case L4D2ZombieClass_Charger:
		{
			return g_Round.players[index].combatAssists.chargerAssistDamage;
		}
	}

	return 0;
}

int Announce_GetPlayerSpecialDamageByClass(int index, L4D2ZombieClassType zombieClass)
{
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return g_Round.players[index].combat.smokerDamage;
		}
		case L4D2ZombieClass_Boomer:
		{
			return g_Round.players[index].combat.boomerDamage;
		}
		case L4D2ZombieClass_Hunter:
		{
			return g_Round.players[index].combat.hunterDamage;
		}
		case L4D2ZombieClass_Spitter:
		{
			return g_Round.players[index].combat.spitterDamage;
		}
		case L4D2ZombieClass_Jockey:
		{
			return g_Round.players[index].combat.jockeyDamage;
		}
		case L4D2ZombieClass_Charger:
		{
			return g_Round.players[index].combat.chargerDamage;
		}
	}

	return 0;
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
