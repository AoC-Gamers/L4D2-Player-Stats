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
	CreateNative("PlayerStats_MarkRestart", Native_PlayerStats_MarkRestart);
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
	return roundId > 0 && g_Round.meta.id == roundId;
}

bool API_IsRoundCoopMode()
{
	return g_Round.meta.baseMode == PlayerStatsModeBase_Coop;
}

void API_WriteRoundContextBlock(Handle kv)
{
	if (!KvJumpToKey(kv, "context", true))
	{
		return;
	}

	char baseModeName[24];
	char historyScopeName[24];
	char contextName[32];
	Stats_GetModeBaseName(g_Round.meta.baseMode, baseModeName, sizeof(baseModeName));
	Stats_GetHistoryScopeName(g_Round.meta.historyScope, historyScopeName, sizeof(historyScopeName));
	Stats_GetVersusContextName(g_Round.meta.versusContext, contextName, sizeof(contextName));

	KvSetNum(kv, "base_mode", g_Round.meta.baseMode);
	KvSetString(kv, "base_mode_name", baseModeName);
	KvSetNum(kv, "is_versus", g_Round.meta.isVersusMode ? 1 : 0);
	KvSetNum(kv, "history_scope", g_Round.meta.historyScope);
	KvSetString(kv, "history_scope_name", historyScopeName);
	KvSetNum(kv, "survivor_limit", g_Round.meta.configuredSurvivorLimit);
	KvSetNum(kv, "infected_limit", g_Round.meta.configuredPlayerZombieLimit);
	KvSetNum(kv, "si_pool_mask", g_Round.meta.siPoolMask);
	KvSetNum(kv, "enabled_si_classes", g_Round.meta.enabledSiClassCount);
	KvSetNum(kv, "team_size", g_Round.meta.versusTeamSize);
	KvSetNum(kv, "versus_context", g_Round.meta.versusContext);
	KvSetString(kv, "versus_context_name", contextName);
	KvSetNum(kv, "round_start_signal", g_Round.meta.roundStartSignal);
	KvSetNum(kv, "round_end_signal", g_Round.meta.roundEndSignal);
	KvSetNum(kv, "round_live_signal", g_Round.meta.roundLiveSignal);
	KvSetNum(kv, "restart_policy", g_Round.meta.restartPolicy);
	KvSetNum(kv, "end_reason", g_Round.meta.endReason);

	KvGoBack(kv);
}

void API_WriteIdentityBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "identity", true))
	{
		return;
	}

	KvSetNum(kv, "userid", playerData.player.userid);
	KvSetNum(kv, "accountid", playerData.player.accountId);
	KvSetString(kv, "name", playerData.player.name);
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

	int filteredSiDamage = 0;
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		filteredSiDamage += playerData.combat.smokerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		filteredSiDamage += playerData.combat.boomerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		filteredSiDamage += playerData.combat.hunterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		filteredSiDamage += playerData.combat.spitterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		filteredSiDamage += playerData.combat.jockeyDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		filteredSiDamage += playerData.combat.chargerDamage;
	}

	KvSetNum(kv, "si_damage", filteredSiDamage);
	KvSetNum(kv, "smoker_damage", playerData.combat.smokerDamage);
	KvSetNum(kv, "boomer_damage", playerData.combat.boomerDamage);
	KvSetNum(kv, "hunter_damage", playerData.combat.hunterDamage);
	KvSetNum(kv, "spitter_damage", playerData.combat.spitterDamage);
	KvSetNum(kv, "jockey_damage", playerData.combat.jockeyDamage);
	KvSetNum(kv, "charger_damage", playerData.combat.chargerDamage);
	KvSetNum(kv, "tank_damage", playerData.combat.tankDamage);
	KvSetNum(kv, "witch_damage", playerData.combat.witchDamage);
	KvSetNum(kv, "common_kills", playerData.combat.commonKills);
	KvSetNum(kv, "smoker_kills", playerData.combat.smokerKills);
	KvSetNum(kv, "boomer_kills", playerData.combat.boomerKills);
	KvSetNum(kv, "hunter_kills", playerData.combat.hunterKills);
	KvSetNum(kv, "spitter_kills", playerData.combat.spitterKills);
	KvSetNum(kv, "jockey_kills", playerData.combat.jockeyKills);
	KvSetNum(kv, "charger_kills", playerData.combat.chargerKills);
	KvSetNum(kv, "tank_kills", playerData.combat.tankKills);
	KvSetNum(kv, "ff_given", playerData.combat.ffGiven);

	KvGoBack(kv);
}

void API_WriteSurvivabilityBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "survivability", true))
	{
		return;
	}

	KvSetNum(kv, "deaths", playerData.survivability.deaths);
	KvSetNum(kv, "incaps", playerData.survivability.incaps);
	KvSetNum(kv, "death_by_survivor", playerData.survivability.deathBySurvivor);
	KvSetNum(kv, "death_by_infected_player", playerData.survivability.deathByInfectedPlayer);
	KvSetNum(kv, "death_by_infected_ai", playerData.survivability.deathByInfectedAI);
	KvSetNum(kv, "incap_by_survivor", playerData.survivability.incapBySurvivor);
	KvSetNum(kv, "incap_by_infected_player", playerData.survivability.incapByInfectedPlayer);
	KvSetNum(kv, "incap_by_infected_ai", playerData.survivability.incapByInfectedAI);

	KvGoBack(kv);
}

void API_WriteSupportBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "support", true))
	{
		return;
	}

	KvSetNum(kv, "heals_given", playerData.support.healsGiven);
	KvSetNum(kv, "heals_received", playerData.support.healsReceived);
	KvSetNum(kv, "revives_given", playerData.support.revivesGiven);
	KvSetNum(kv, "revives_received", playerData.support.revivesReceived);

	KvGoBack(kv);
}

void API_WriteResourcesBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "resources", true))
	{
		return;
	}

	KvSetNum(kv, "pills_used", playerData.resources.pillsUsed);
	KvSetNum(kv, "adrenaline_used", playerData.resources.adrenalineUsed);
	KvSetNum(kv, "medkits_used", playerData.resources.medkitsUsed);
	KvSetNum(kv, "defibs_used", playerData.resources.defibsUsed);
	KvSetNum(kv, "molotovs_thrown", playerData.resources.molotovsThrown);
	KvSetNum(kv, "pipebombs_thrown", playerData.resources.pipebombsThrown);
	KvSetNum(kv, "vomitjars_thrown", playerData.resources.vomitjarsThrown);

	KvGoBack(kv);
}

void API_WriteAccuracyBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "accuracy", true))
	{
		return;
	}

	KvSetNum(kv, "shotgun_shots", playerData.accuracy.shotgunShots);
	KvSetNum(kv, "shotgun_hits", playerData.accuracy.shotgunHits);
	KvSetNum(kv, "shotgun_headshots", playerData.accuracy.shotgunHeadshots);
	KvSetNum(kv, "smg_rifle_shots", playerData.accuracy.smgRifleShots);
	KvSetNum(kv, "smg_rifle_hits", playerData.accuracy.smgRifleHits);
	KvSetNum(kv, "smg_rifle_headshots", playerData.accuracy.smgRifleHeadshots);
	KvSetNum(kv, "sniper_shots", playerData.accuracy.sniperShots);
	KvSetNum(kv, "sniper_hits", playerData.accuracy.sniperHits);
	KvSetNum(kv, "sniper_headshots", playerData.accuracy.sniperHeadshots);
	KvSetNum(kv, "pistol_shots", playerData.accuracy.pistolShots);
	KvSetNum(kv, "pistol_hits", playerData.accuracy.pistolHits);
	KvSetNum(kv, "pistol_headshots", playerData.accuracy.pistolHeadshots);

	KvGoBack(kv);
}

void API_WriteModeBlocks(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (playerData.support.rescuesGiven <= 0 || !API_IsRoundCoopMode())
	{
		return;
	}

	if (!KvJumpToKey(kv, "mode_coop", true))
	{
		return;
	}

	KvSetNum(kv, "rescues_given", playerData.support.rescuesGiven);
	KvGoBack(kv);
}

void API_WriteRoundTotals(Handle kv)
{
	if (!KvJumpToKey(kv, "totals", true))
	{
		return;
	}

	KvSetNum(kv, "si_damage", Announce_GetTotalSurvivorSiDamage());
	KvSetNum(kv, "tank_damage", g_Round.totals.survivorTotalTankDamage);
	KvSetNum(kv, "witch_damage", g_Round.totals.survivorTotalWitchDamage);
	KvSetNum(kv, "common_kills", g_Round.totals.survivorTotalCommonKills);
	KvSetNum(kv, "ff", g_Round.totals.survivorTotalFF);
	KvSetNum(kv, "deaths", g_Round.totals.survivorTotalDeaths);
	KvSetNum(kv, "incaps", g_Round.totals.survivorTotalIncaps);
	KvSetNum(kv, "heals_given", g_Round.totals.survivorTotalHealsGiven);
	KvSetNum(kv, "revives_given", g_Round.totals.survivorTotalRevivesGiven);

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
	API_WriteAccuracyBlock(kv, g_Round.players[slot]);
	API_WriteModeBlocks(kv, g_Round.players[slot]);
}

public int Native_PlayerStats_IsRoundActive(Handle plugin, int numParams)
{
	return g_Round.meta.active;
}

public int Native_PlayerStats_GetRoundId(Handle plugin, int numParams)
{
	return g_Round.meta.id;
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

	KvSetNum(kv, "id", g_Round.meta.id);
	API_WriteRoundContextBlock(kv);
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

	API_WriteRoundContextBlock(kv);
	API_WriteRoundPlayerDetail(kv, slot);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

public int Native_PlayerStats_MarkRestart(Handle plugin, int numParams)
{
	PlayerStatsRestartSourceType source = view_as<PlayerStatsRestartSourceType>(GetNativeCell(1));
	Series_MarkPendingRestart(source, "native_mark_restart");
	return true;
}

public int Native_PlayerStats_BroadcastRoundStats(Handle plugin, int numParams)
{
	Announce_BroadcastRoundSummary();
	return 1;
}

public int Native_PlayerStats_BroadcastGameStats(Handle plugin, int numParams)
{
	Announce_RenderGameHistoryPanel(0);
	return 1;
}
