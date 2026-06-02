#if defined _l4d2_player_stats_api_included
	#endinput
#endif
#define _l4d2_player_stats_api_included

Handle g_hForwardRoundLive = INVALID_HANDLE;
Handle g_hForwardRoundEnded = INVALID_HANDLE;
Handle g_hForwardPlayerSubstituted = INVALID_HANDLE;

void API_CreateForwards()
{
	g_hForwardRoundLive = CreateGlobalForward("PlayerStats_OnRoundLive", ET_Ignore, Param_Cell);
	g_hForwardRoundEnded = CreateGlobalForward("PlayerStats_OnRoundEnded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardPlayerSubstituted = CreateGlobalForward("PlayerStats_OnPlayerSubstituted", ET_Hook, Param_String, Param_Cell, Param_Cell, Param_Cell);
}

void API_CreateNatives()
{
	CreateNative("PlayerStats_IsRoundActive", Native_PlayerStats_IsRoundActive);
	CreateNative("PlayerStats_IsRoundLive", Native_PlayerStats_IsRoundLive);
	CreateNative("PlayerStats_GetRoundId", Native_PlayerStats_GetRoundId);
	CreateNative("PlayerStats_IsRoundPlayerSlotValid", Native_PlayerStats_IsRoundPlayerSlotValid);
	CreateNative("PlayerStats_GetRoundPlayerClient", Native_PlayerStats_GetRoundPlayerClient);
	CreateNative("PlayerStats_GetCurrentModeProperty", Native_PlayerStats_GetCurrentModeProperty);
	CreateNative("PlayerStats_FillRoundKeyValues", Native_PlayerStats_FillRoundKeyValues);
	CreateNative("PlayerStats_FillRoundPlayerKeyValues", Native_PlayerStats_FillRoundPlayerKeyValues);
	CreateNative("PlayerStats_ApplySubstitutionSnapshotToSlot", Native_PlayerStats_ApplySubstitutionSnapshotToSlot);
	CreateNative("PlayerStats_BroadcastRoundStats", Native_PlayerStats_BroadcastRoundStats);
}

void API_FireRoundLive(int roundId)
{
	if (g_hForwardRoundLive == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardRoundLive);
	Call_PushCell(roundId);
	Call_Finish();
}

void API_FireRoundEnded(int roundId, StatsEndType endType, PlayerStatsRoundEndReasonType endReason)
{
	if (g_hForwardRoundEnded == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardRoundEnded);
	Call_PushCell(roundId);
	Call_PushCell(endType);
	Call_PushCell(endReason);
	Call_Finish();
}

Action API_FirePlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient)
{
	if (g_hForwardPlayerSubstituted == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(g_hForwardPlayerSubstituted);
	Call_PushString(substitutionId);
	Call_PushCell(roundId);
	Call_PushCell(slot);
	Call_PushCell(incomingClient);
	Call_Finish(result);
	return result;
}

bool API_IsRoundIdValid(int roundId)
{
	return roundId > 0 && g_Round.meta.id == roundId;
}

bool API_IsRoundCoopMode()
{
	return g_Round.meta.baseMode == GAMEMODE_COOP;
}

void API_WriteRoundContextBlock(Handle kv)
{
	if (!KvJumpToKey(kv, "context", true))
	{
		return;
	}

	KvSetNum(kv, "base_mode", g_Round.meta.baseMode);
	KvSetNum(kv, "is_versus", g_Round.meta.isVersusMode ? 1 : 0);
	KvSetNum(kv, "has_bosses", g_Round.meta.hasBosses ? 1 : 0);
	KvSetNum(kv, "has_round_halves", g_Round.meta.hasRoundHalves ? 1 : 0);
	KvSetNum(kv, "scavenge_round_number", g_Round.meta.scavengeRoundNumber);
	KvSetNum(kv, "second_half", g_Round.meta.scavengeInSecondHalf ? 1 : 0);
	KvSetNum(kv, "scavenge_items_goal", g_Round.meta.scavengeItemsGoal);
	KvSetNum(kv, "scavenge_overtime", g_Round.meta.scavengeWentOvertime ? 1 : 0);
	KvSetNum(kv, "scavenge_score_tied", g_Round.meta.scavengeScoreTied ? 1 : 0);
	KvSetNum(kv, "series_scope", g_Round.meta.seriesScope);
	KvSetNum(kv, "survivor_limit", g_Round.meta.configuredSurvivorLimit);
	KvSetNum(kv, "infected_limit", g_Round.meta.configuredPlayerZombieLimit);
	KvSetNum(kv, "si_pool_mask", g_Round.meta.siPoolMask);
	KvSetNum(kv, "enabled_si_classes", g_Round.meta.enabledSiClassCount);
	KvSetNum(kv, "team_size", g_Round.meta.versusTeamSize);
	KvSetNum(kv, "versus_context", g_Round.meta.versusContext);
	KvSetNum(kv, "round_start_signal", g_Round.meta.roundLiveSignal);
	KvSetNum(kv, "round_end_signal", g_Round.meta.roundEndSignal);
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
	KvSetNum(kv, "tank_hits", playerData.combat.tankHits);
	KvSetNum(kv, "witch_damage", playerData.combat.witchDamage);
	KvSetNum(kv, "witch_hits", playerData.combat.witchHits);
	KvSetNum(kv, "common_kills", playerData.combat.commonKills);
	KvSetNum(kv, "smoker_kills", playerData.combat.smokerKills);
	KvSetNum(kv, "boomer_kills", playerData.combat.boomerKills);
	KvSetNum(kv, "hunter_kills", playerData.combat.hunterKills);
	KvSetNum(kv, "spitter_kills", playerData.combat.spitterKills);
	KvSetNum(kv, "jockey_kills", playerData.combat.jockeyKills);
	KvSetNum(kv, "charger_kills", playerData.combat.chargerKills);
	KvSetNum(kv, "tank_kills", playerData.combat.tankKills);
	KvSetNum(kv, "witch_kills", playerData.combat.witchKills);
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

void API_WriteCombatAssistsBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "combat_assists", true))
	{
		return;
	}

	KvSetNum(kv, "si_kill_assists", playerData.combatAssists.siKillAssists);
	KvSetNum(kv, "si_assist_damage", playerData.combatAssists.siAssistDamage);
	KvSetNum(kv, "smoker_kill_assists", playerData.combatAssists.smokerKillAssists);
	KvSetNum(kv, "boomer_kill_assists", playerData.combatAssists.boomerKillAssists);
	KvSetNum(kv, "hunter_kill_assists", playerData.combatAssists.hunterKillAssists);
	KvSetNum(kv, "spitter_kill_assists", playerData.combatAssists.spitterKillAssists);
	KvSetNum(kv, "jockey_kill_assists", playerData.combatAssists.jockeyKillAssists);
	KvSetNum(kv, "charger_kill_assists", playerData.combatAssists.chargerKillAssists);
	KvSetNum(kv, "smoker_assist_damage", playerData.combatAssists.smokerAssistDamage);
	KvSetNum(kv, "boomer_assist_damage", playerData.combatAssists.boomerAssistDamage);
	KvSetNum(kv, "hunter_assist_damage", playerData.combatAssists.hunterAssistDamage);
	KvSetNum(kv, "spitter_assist_damage", playerData.combatAssists.spitterAssistDamage);
	KvSetNum(kv, "jockey_assist_damage", playerData.combatAssists.jockeyAssistDamage);
	KvSetNum(kv, "charger_assist_damage", playerData.combatAssists.chargerAssistDamage);

	KvGoBack(kv);
}

void API_WriteBossDetailBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "boss_detail", true))
	{
		return;
	}

	KvSetNum(kv, "tank_damage", playerData.bossDetail.tankDamage);
	KvSetNum(kv, "tank_shots", playerData.bossDetail.tankShots);
	KvSetNum(kv, "witch_damage", playerData.bossDetail.witchDamage);
	KvSetNum(kv, "witch_shots", playerData.bossDetail.witchShots);

	KvGoBack(kv);
}

void API_WriteInfectedGrabBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "infected_grab", true))
	{
		return;
	}

	KvSetNum(kv, "smoker_damage", playerData.infectedGrab.smokerDamage);
	KvSetNum(kv, "hunter_damage", playerData.infectedGrab.hunterDamage);
	KvSetNum(kv, "jockey_damage", playerData.infectedGrab.jockeyDamage);
	KvSetNum(kv, "charger_damage", playerData.infectedGrab.chargerDamage);
	KvSetNum(kv, "total_damage", playerData.infectedGrab.totalDamage);
	KvSetNum(kv, "tongue_grabs", playerData.infectedGrab.tongueGrabs);
	KvSetNum(kv, "hunter_pounces", playerData.infectedGrab.hunterPounces);
	KvSetNum(kv, "jockey_rides", playerData.infectedGrab.jockeyRides);

	KvGoBack(kv);
}

void API_WriteInfectedSupportBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "infected_support", true))
	{
		return;
	}

	KvSetNum(kv, "boomer_vomit_victims", playerData.infectedSupport.boomerVomitVictims);
	KvSetNum(kv, "spitter_damage", playerData.infectedSupport.spitterDamage);

	KvGoBack(kv);
}

void API_WriteItemsBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "items", true))
	{
		return;
	}

	KvSetNum(kv, "pills_used", playerData.resources.pillsUsed);
	KvSetNum(kv, "adrenaline_used", playerData.resources.adrenalineUsed);
	KvSetNum(kv, "medkits_used", playerData.resources.medkitsUsed);
	KvSetNum(kv, "defibs_used", playerData.resources.defibsUsed);

	KvGoBack(kv);
}

void API_WriteScavengeBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "scavenge", true))
	{
		return;
	}

	KvSetNum(kv, "gascans_poured", playerData.scavenge.gascansPoured);
	KvSetNum(kv, "gascans_dropped", playerData.scavenge.gascansDropped);
	KvSetNum(kv, "gascans_destroyed", playerData.scavenge.gascansDestroyed);

	KvGoBack(kv);
}

void API_WriteUtilitiesBlock(Handle kv, PlayerStatsPlayerRoundData playerData)
{
	if (!KvJumpToKey(kv, "utils", true))
	{
		return;
	}

	KvSetNum(kv, "molotovs_thrown", playerData.resources.molotovsThrown);
	KvSetNum(kv, "pipebombs_thrown", playerData.resources.pipebombsThrown);
	KvSetNum(kv, "vomitjars_thrown", playerData.resources.vomitjarsThrown);
	KvSetNum(kv, "zombies_ignited", playerData.resources.zombiesIgnited);
	KvSetNum(kv, "players_biled", playerData.resources.playersBiled);
	KvSetNum(kv, "tanks_biled", playerData.resources.tanksBiled);

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

	API_WriteAccuracyFamilyBlock(kv, "shotgun",
		playerData.accuracy.shotgunShots,
		playerData.accuracy.shotgunHits,
		playerData.accuracy.shotgunHeadshots,
		playerData,
		4,
		PlayerStatsWeaponDetail_PumpShotgun,
		PlayerStatsWeaponDetail_Autoshotgun,
		PlayerStatsWeaponDetail_ChromeShotgun,
		PlayerStatsWeaponDetail_SpasShotgun,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None);
	API_WriteAccuracyFamilyBlock(kv, "smg_rifle",
		playerData.accuracy.smgRifleShots,
		playerData.accuracy.smgRifleHits,
		playerData.accuracy.smgRifleHeadshots,
		playerData,
		8,
		PlayerStatsWeaponDetail_Smg,
		PlayerStatsWeaponDetail_SmgSilenced,
		PlayerStatsWeaponDetail_SmgMp5,
		PlayerStatsWeaponDetail_Rifle,
		PlayerStatsWeaponDetail_RifleAk47,
		PlayerStatsWeaponDetail_RifleDesert,
		PlayerStatsWeaponDetail_RifleSg552,
		PlayerStatsWeaponDetail_RifleM60);
	API_WriteAccuracyFamilyBlock(kv, "sniper",
		playerData.accuracy.sniperShots,
		playerData.accuracy.sniperHits,
		playerData.accuracy.sniperHeadshots,
		playerData,
		4,
		PlayerStatsWeaponDetail_HuntingRifle,
		PlayerStatsWeaponDetail_SniperMilitary,
		PlayerStatsWeaponDetail_SniperAwp,
		PlayerStatsWeaponDetail_SniperScout,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None);
	API_WriteAccuracyFamilyBlock(kv, "pistol",
		playerData.accuracy.pistolShots,
		playerData.accuracy.pistolHits,
		playerData.accuracy.pistolHeadshots,
		playerData,
		2,
		PlayerStatsWeaponDetail_Pistol,
		PlayerStatsWeaponDetail_Magnum,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None,
		PlayerStatsWeaponDetail_None);

	KvGoBack(kv);
}

void API_WriteAccuracyFamilyBlock(Handle kv, const char[] familyName, int shots, int hits, int headshots, PlayerStatsPlayerRoundData playerData, int detailCount,
	PlayerStatsWeaponDetailType detailA,
	PlayerStatsWeaponDetailType detailB,
	PlayerStatsWeaponDetailType detailC,
	PlayerStatsWeaponDetailType detailD,
	PlayerStatsWeaponDetailType detailE,
	PlayerStatsWeaponDetailType detailF,
	PlayerStatsWeaponDetailType detailG,
	PlayerStatsWeaponDetailType detailH)
{
	if (!KvJumpToKey(kv, familyName, true))
	{
		return;
	}

	KvSetNum(kv, "shots", shots);
	KvSetNum(kv, "hits", hits);
	KvSetNum(kv, "headshots", headshots);

	if (KvJumpToKey(kv, "details", true))
	{
		PlayerStatsWeaponDetailType details[8];
		details[0] = detailA;
		details[1] = detailB;
		details[2] = detailC;
		details[3] = detailD;
		details[4] = detailE;
		details[5] = detailF;
		details[6] = detailG;
		details[7] = detailH;

		for (int i = 0; i < detailCount && i < sizeof(details); i++)
		{
			API_WriteAccuracyDetailEntry(kv, playerData, details[i]);
		}

		KvGoBack(kv);
	}

	KvGoBack(kv);
}

void API_WriteAccuracyDetailEntry(Handle kv, PlayerStatsPlayerRoundData playerData, PlayerStatsWeaponDetailType detail)
{
	if (detail <= PlayerStatsWeaponDetail_None || detail >= PlayerStatsWeaponDetail_Count)
	{
		return;
	}

	char key[32];
	switch (detail)
	{
		case PlayerStatsWeaponDetail_PumpShotgun: strcopy(key, sizeof(key), "pump");
		case PlayerStatsWeaponDetail_Autoshotgun: strcopy(key, sizeof(key), "auto");
		case PlayerStatsWeaponDetail_ChromeShotgun: strcopy(key, sizeof(key), "chrome");
		case PlayerStatsWeaponDetail_SpasShotgun: strcopy(key, sizeof(key), "spas");
		case PlayerStatsWeaponDetail_Smg: strcopy(key, sizeof(key), "smg");
		case PlayerStatsWeaponDetail_SmgSilenced: strcopy(key, sizeof(key), "silenced_smg");
		case PlayerStatsWeaponDetail_SmgMp5: strcopy(key, sizeof(key), "mp5");
		case PlayerStatsWeaponDetail_Rifle: strcopy(key, sizeof(key), "rifle");
		case PlayerStatsWeaponDetail_RifleAk47: strcopy(key, sizeof(key), "ak47");
		case PlayerStatsWeaponDetail_RifleDesert: strcopy(key, sizeof(key), "desert_rifle");
		case PlayerStatsWeaponDetail_RifleSg552: strcopy(key, sizeof(key), "sg552");
		case PlayerStatsWeaponDetail_RifleM60: strcopy(key, sizeof(key), "m60");
		case PlayerStatsWeaponDetail_HuntingRifle: strcopy(key, sizeof(key), "hunting");
		case PlayerStatsWeaponDetail_SniperMilitary: strcopy(key, sizeof(key), "military");
		case PlayerStatsWeaponDetail_SniperAwp: strcopy(key, sizeof(key), "awp");
		case PlayerStatsWeaponDetail_SniperScout: strcopy(key, sizeof(key), "scout");
		case PlayerStatsWeaponDetail_Pistol: strcopy(key, sizeof(key), "pistol");
		case PlayerStatsWeaponDetail_Magnum: strcopy(key, sizeof(key), "magnum");
		default: return;
	}

	if (!KvJumpToKey(kv, key, true))
	{
		return;
	}

	KvSetNum(kv, "shots", playerData.accuracyDetails.shots[detail]);
	KvSetNum(kv, "hits", playerData.accuracyDetails.hits[detail]);
	KvSetNum(kv, "headshots", playerData.accuracyDetails.headshots[detail]);
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
	API_WriteCombatAssistsBlock(kv, g_Round.players[slot]);
	API_WriteBossDetailBlock(kv, g_Round.players[slot]);
	API_WriteSurvivabilityBlock(kv, g_Round.players[slot]);
	API_WriteSupportBlock(kv, g_Round.players[slot]);
	API_WriteInfectedGrabBlock(kv, g_Round.players[slot]);
	API_WriteInfectedSupportBlock(kv, g_Round.players[slot]);
	API_WriteScavengeBlock(kv, g_Round.players[slot]);
	API_WriteItemsBlock(kv, g_Round.players[slot]);
	API_WriteUtilitiesBlock(kv, g_Round.players[slot]);
	API_WriteAccuracyBlock(kv, g_Round.players[slot]);
	API_WriteModeBlocks(kv, g_Round.players[slot]);
}

int API_FindSubstitutionSnapshotById(const char[] substitutionId)
{
	for (int offset = 1; offset <= g_iSubstitutionSnapshotCount; offset++)
	{
		int slot = (g_iSubstitutionSnapshotNext - offset + L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS) % L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS;
		if (slot == -1 || !g_SubstitutionSnapshots[slot].active)
		{
			continue;
		}

		if (StrEqual(g_SubstitutionSnapshots[slot].substitutionId, substitutionId, false))
		{
			return slot;
		}
	}

	return -1;
}

public int Native_PlayerStats_IsRoundActive(Handle plugin, int numParams)
{
	return g_Round.meta.active;
}

public int Native_PlayerStats_IsRoundLive(Handle plugin, int numParams)
{
	return g_Runtime.roundLive;
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

public int Native_PlayerStats_GetCurrentModeProperty(Handle plugin, int numParams)
{
	StatsModeProperty property = view_as<StatsModeProperty>(GetNativeCell(1));

	switch (property)
	{
		case StatsModeProperty_BaseMode:
		{
			return g_Runtime.baseMode;
		}
		case StatsModeProperty_HasBosses:
		{
			return g_Runtime.hasBosses;
		}
		case StatsModeProperty_HasRoundHalves:
		{
			return g_Runtime.hasRoundHalves;
		}
		case StatsModeProperty_SeriesScope:
		{
			return g_Runtime.seriesScope;
		}
		case StatsModeProperty_EnabledSiClassCount:
		{
			return g_Runtime.enabledSiClassCount;
		}
		case StatsModeProperty_VersusTeamSize:
		{
			return g_Runtime.versusTeamSize;
		}
		case StatsModeProperty_RoundEndSignal:
		{
			return g_Runtime.roundEndSignal;
		}
		case StatsModeProperty_RoundStartSignal:
		{
			return g_Runtime.roundLiveSignal;
		}
		case StatsModeProperty_RestartPolicy:
		{
			return g_Runtime.restartPolicy;
		}
	}

	return 0;
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

public int Native_PlayerStats_ApplySubstitutionSnapshotToSlot(Handle plugin, int numParams)
{
	char substitutionId[64];
	GetNativeString(1, substitutionId, sizeof(substitutionId));

	int slot = GetNativeCell(2);
	int client = GetNativeCell(3);
	int snapshotIndex = API_FindSubstitutionSnapshotById(substitutionId);
	if (snapshotIndex == -1)
	{
		return false;
	}

	return Stats_RestoreSubstitutionSnapshotToSlot(snapshotIndex, slot, client);
}

public int Native_PlayerStats_BroadcastRoundStats(Handle plugin, int numParams)
{
	Announce_BroadcastRoundSummary();
	return 1;
}
