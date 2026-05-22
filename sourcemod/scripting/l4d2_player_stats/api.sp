#if defined _l4d2_player_stats_api_included
	#endinput
#endif
#define _l4d2_player_stats_api_included

Handle g_hForwardRoundFinalized = INVALID_HANDLE;

void API_Init()
{
	RegPluginLibrary("l4d2_player_stats");

	g_hForwardRoundFinalized = CreateGlobalForward("PlayerStats_OnRoundFinalized", ET_Ignore, Param_Cell);

	CreateNative("PlayerStats_IsRoundActive", Native_PlayerStats_IsRoundActive);
	CreateNative("PlayerStats_GetRoundId", Native_PlayerStats_GetRoundId);
	CreateNative("PlayerStats_IsRoundPlayerSlotValid", Native_PlayerStats_IsRoundPlayerSlotValid);
	CreateNative("PlayerStats_GetRoundPlayerClient", Native_PlayerStats_GetRoundPlayerClient);
	CreateNative("PlayerStats_FillRoundKeyValues", Native_PlayerStats_FillRoundKeyValues);
	CreateNative("PlayerStats_FillRoundPlayerKeyValues", Native_PlayerStats_FillRoundPlayerKeyValues);
	CreateNative("PlayerStats_BroadcastRoundStats", Native_PlayerStats_BroadcastRoundStats);
	CreateNative("PlayerStats_BroadcastGameStats", Native_PlayerStats_BroadcastGameStats);
}

void API_FireRoundFinalized(int roundId)
{
	if (g_hForwardRoundFinalized == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardRoundFinalized);
	Call_PushCell(roundId);
	Call_Finish();
}

bool API_IsRoundIdValid(int roundId)
{
	return roundId > 0 && g_Round.id == roundId;
}

bool API_IsCoopMode()
{
	static ConVar cvGameMode = null;
	if (cvGameMode == null)
	{
		cvGameMode = FindConVar("mp_gamemode");
	}

	if (cvGameMode == null)
	{
		return false;
	}

	char gameMode[32];
	cvGameMode.GetString(gameMode, sizeof(gameMode));
	return StrContains(gameMode, "coop", false) != -1;
}

void API_WriteIdentityBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "identity", true))
	{
		return;
	}

	KvSetString(kv, "name", playerData.player.name);
	KvSetNum(kv, "accountid", playerData.player.accountId);
	KvSetNum(kv, "bot", playerData.player.bot ? 1 : 0);
	KvSetNum(kv, "team", playerData.team);

	KvGoBack(kv);
}

void API_WriteCombatBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "combat", true))
	{
		return;
	}

	KvSetNum(kv, "si_damage", playerData.siDamage);
	KvSetNum(kv, "smoker_damage", playerData.smokerDamage);
	KvSetNum(kv, "boomer_damage", playerData.boomerDamage);
	KvSetNum(kv, "hunter_damage", playerData.hunterDamage);
	KvSetNum(kv, "spitter_damage", playerData.spitterDamage);
	KvSetNum(kv, "jockey_damage", playerData.jockeyDamage);
	KvSetNum(kv, "charger_damage", playerData.chargerDamage);
	KvSetNum(kv, "tank_damage", playerData.tankDamage);
	KvSetNum(kv, "witch_damage", playerData.witchDamage);
	KvSetNum(kv, "common_kills", playerData.commonKills);
	KvSetNum(kv, "smoker_kills", playerData.smokerKills);
	KvSetNum(kv, "boomer_kills", playerData.boomerKills);
	KvSetNum(kv, "hunter_kills", playerData.hunterKills);
	KvSetNum(kv, "spitter_kills", playerData.spitterKills);
	KvSetNum(kv, "jockey_kills", playerData.jockeyKills);
	KvSetNum(kv, "charger_kills", playerData.chargerKills);
	KvSetNum(kv, "tank_kills", playerData.tankKills);
	KvSetNum(kv, "ff_given", playerData.ffGiven);

	KvGoBack(kv);
}

void API_WriteSurvivabilityBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "survivability", true))
	{
		return;
	}

	KvSetNum(kv, "deaths", playerData.deaths);
	KvSetNum(kv, "incaps", playerData.incaps);
	KvSetNum(kv, "death_by_survivor", playerData.deathBySurvivor);
	KvSetNum(kv, "death_by_infected_player", playerData.deathByInfectedPlayer);
	KvSetNum(kv, "death_by_infected_ai", playerData.deathByInfectedAI);
	KvSetNum(kv, "incap_by_survivor", playerData.incapBySurvivor);
	KvSetNum(kv, "incap_by_infected_player", playerData.incapByInfectedPlayer);
	KvSetNum(kv, "incap_by_infected_ai", playerData.incapByInfectedAI);

	KvGoBack(kv);
}

void API_WriteSupportBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "support", true))
	{
		return;
	}

	KvSetNum(kv, "heals_given", playerData.healsGiven);
	KvSetNum(kv, "heals_received", playerData.healsReceived);
	KvSetNum(kv, "revives_given", playerData.revivesGiven);
	KvSetNum(kv, "revives_received", playerData.revivesReceived);

	KvGoBack(kv);
}

void API_WriteResourcesBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "resources", true))
	{
		return;
	}

	KvSetNum(kv, "pills_used", playerData.pillsUsed);
	KvSetNum(kv, "adrenaline_used", playerData.adrenalineUsed);
	KvSetNum(kv, "medkits_used", playerData.medkitsUsed);
	KvSetNum(kv, "defibs_used", playerData.defibsUsed);
	KvSetNum(kv, "molotovs_thrown", playerData.molotovsThrown);
	KvSetNum(kv, "pipebombs_thrown", playerData.pipebombsThrown);
	KvSetNum(kv, "vomitjars_thrown", playerData.vomitjarsThrown);

	KvGoBack(kv);
}

void API_WriteModeBlocks(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (playerData.rescuesGiven <= 0 || !API_IsCoopMode())
	{
		return;
	}

	if (!KvJumpToKey(kv, "mode_coop", true))
	{
		return;
	}

	KvSetNum(kv, "rescues_given", playerData.rescuesGiven);
	KvGoBack(kv);
}

void API_WriteRoundTotals(Handle kv)
{
	if (!KvJumpToKey(kv, "totals", true))
	{
		return;
	}

	KvSetNum(kv, "si_damage", g_Round.survivorTotalSiDamage);
	KvSetNum(kv, "tank_damage", g_Round.survivorTotalTankDamage);
	KvSetNum(kv, "witch_damage", g_Round.survivorTotalWitchDamage);
	KvSetNum(kv, "common_kills", g_Round.survivorTotalCommonKills);
	KvSetNum(kv, "ff", g_Round.survivorTotalFF);
	KvSetNum(kv, "deaths", g_Round.survivorTotalDeaths);
	KvSetNum(kv, "incaps", g_Round.survivorTotalIncaps);
	KvSetNum(kv, "heals_given", g_Round.survivorTotalHealsGiven);
	KvSetNum(kv, "revives_given", g_Round.survivorTotalRevivesGiven);

	KvGoBack(kv);
}

void API_WriteRoundPlayersSummary(Handle kv)
{
	if (!KvJumpToKey(kv, "players", true))
	{
		return;
	}

	int outputIndex = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!g_Round.players[slot].active)
		{
			continue;
		}

		char key[8];
		IntToString(outputIndex++, key, sizeof(key));

		if (!KvJumpToKey(kv, key, true))
		{
			continue;
		}

		KvSetNum(kv, "slot", slot);
		API_WriteIdentityBlock(kv, g_Round.players[slot]);
		KvGoBack(kv);
	}

	KvGoBack(kv);
}

void API_WriteRoundPlayerDetail(Handle kv, int slot)
{
	KvSetNum(kv, "slot", slot);
	API_WriteIdentityBlock(kv, g_Round.players[slot]);
	API_WriteCombatBlock(kv, g_Round.players[slot]);
	API_WriteSurvivabilityBlock(kv, g_Round.players[slot]);
	API_WriteSupportBlock(kv, g_Round.players[slot]);
	API_WriteResourcesBlock(kv, g_Round.players[slot]);
	API_WriteModeBlocks(kv, g_Round.players[slot]);
}

public int Native_PlayerStats_IsRoundActive(Handle plugin, int numParams)
{
	return g_Round.active;
}

public int Native_PlayerStats_GetRoundId(Handle plugin, int numParams)
{
	return g_Round.id;
}

public int Native_PlayerStats_IsRoundPlayerSlotValid(Handle plugin, int numParams)
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);
	return API_IsRoundIdValid(roundId) && Stats_IsValidRoundSlot(slot);
}

public int Native_PlayerStats_GetRoundPlayerClient(Handle plugin, int numParams)
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);

	if (!API_IsRoundIdValid(roundId) || !Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return IsValidClient(g_Round.players[slot].player.client) ? g_Round.players[slot].player.client : 0;
}

public int Native_PlayerStats_FillRoundKeyValues(Handle plugin, int numParams)
{
	int roundId = GetNativeCell(1);
	Handle kv = GetNativeCell(2);

	if (!API_IsRoundIdValid(roundId) || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_Round.id);
	API_WriteRoundTotals(kv);
	API_WriteRoundPlayersSummary(kv);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerStats_FillRoundPlayerKeyValues(Handle plugin, int numParams)
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);
	Handle kv = GetNativeCell(3);

	if (!API_IsRoundIdValid(roundId) || !Stats_IsValidRoundSlot(slot) || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "player", true))
	{
		return false;
	}

	API_WriteRoundPlayerDetail(kv, slot);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerStats_BroadcastRoundStats(Handle plugin, int numParams)
{
	Announce_BroadcastRoundSummary();
	return 1;
}

public int Native_PlayerStats_BroadcastGameStats(Handle plugin, int numParams)
{
	Announce_BroadcastRoundSummary();
	return 1;
}
