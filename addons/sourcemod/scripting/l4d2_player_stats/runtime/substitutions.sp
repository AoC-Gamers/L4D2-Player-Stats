#if defined _l4d2_player_stats_runtime_substitutions_included
	#endinput
#endif
#define _l4d2_player_stats_runtime_substitutions_included

PlayerStatsSubstitutionSnapshotData g_SubstitutionSnapshots[L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS];
PlayerStatsPendingSubstitutionData g_PendingSubstitutions[L4D2_PLAYER_STATS_MAX_PLAYERS];
int g_iSubstitutionTransitionSerial[L4D2_PLAYER_STATS_MAX_PLAYERS];
int g_iSubstitutionSnapshotCount = 0;
int g_iSubstitutionSnapshotNext = 0;
int g_iSubstitutionSnapshotSerial = 0;
int g_iSubstitutionGenerationSerial = 0;

void Substitutions_ResetAll()
{
	g_iSubstitutionSnapshotCount = 0;
	g_iSubstitutionSnapshotNext = 0;
	g_iSubstitutionSnapshotSerial = 0;
	g_iSubstitutionGenerationSerial = 0;
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS; i++)
	{
		g_SubstitutionSnapshots[i].Reset();
	}
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_PLAYERS; slot++)
	{
		g_PendingSubstitutions[slot].Reset();
		g_iSubstitutionTransitionSerial[slot] = 0;
	}
}

void Substitutions_InvalidatePendingTransitions()
{
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_PLAYERS; slot++)
	{
		Stats_AdvanceSubstitutionSlotSerial(slot);
		g_PendingSubstitutions[slot].Reset();
	}
}

stock void Stats_SubtractPlayerRoundDataFromTotals(PlayerStatsPlayerRoundData playerData)
{
	g_Round.totals.survivorTotalSiDamage -= playerData.combat.siDamage;
	g_Round.totals.survivorTotalSmokerDamage -= playerData.combat.smokerDamage;
	g_Round.totals.survivorTotalBoomerDamage -= playerData.combat.boomerDamage;
	g_Round.totals.survivorTotalHunterDamage -= playerData.combat.hunterDamage;
	g_Round.totals.survivorTotalSpitterDamage -= playerData.combat.spitterDamage;
	g_Round.totals.survivorTotalJockeyDamage -= playerData.combat.jockeyDamage;
	g_Round.totals.survivorTotalChargerDamage -= playerData.combat.chargerDamage;
	g_Round.totals.survivorTotalTankDamage -= playerData.combat.tankDamage;
	g_Round.totals.survivorTotalWitchDamage -= playerData.combat.witchDamage;
	g_Round.totals.survivorTotalCommonKills -= playerData.combat.commonKills;
	g_Round.totals.survivorTotalSmokerKills -= playerData.combat.smokerKills;
	g_Round.totals.survivorTotalBoomerKills -= playerData.combat.boomerKills;
	g_Round.totals.survivorTotalHunterKills -= playerData.combat.hunterKills;
	g_Round.totals.survivorTotalSpitterKills -= playerData.combat.spitterKills;
	g_Round.totals.survivorTotalJockeyKills -= playerData.combat.jockeyKills;
	g_Round.totals.survivorTotalChargerKills -= playerData.combat.chargerKills;
	g_Round.totals.survivorTotalSiKillAssists -= playerData.combatAssists.siKillAssists;
	g_Round.totals.survivorTotalSmokerKillAssists -= playerData.combatAssists.smokerKillAssists;
	g_Round.totals.survivorTotalBoomerKillAssists -= playerData.combatAssists.boomerKillAssists;
	g_Round.totals.survivorTotalHunterKillAssists -= playerData.combatAssists.hunterKillAssists;
	g_Round.totals.survivorTotalSpitterKillAssists -= playerData.combatAssists.spitterKillAssists;
	g_Round.totals.survivorTotalJockeyKillAssists -= playerData.combatAssists.jockeyKillAssists;
	g_Round.totals.survivorTotalChargerKillAssists -= playerData.combatAssists.chargerKillAssists;
	g_Round.totals.survivorTotalSiAssistDamage -= playerData.combatAssists.siAssistDamage;
	g_Round.totals.survivorTotalSmokerAssistDamage -= playerData.combatAssists.smokerAssistDamage;
	g_Round.totals.survivorTotalBoomerAssistDamage -= playerData.combatAssists.boomerAssistDamage;
	g_Round.totals.survivorTotalHunterAssistDamage -= playerData.combatAssists.hunterAssistDamage;
	g_Round.totals.survivorTotalSpitterAssistDamage -= playerData.combatAssists.spitterAssistDamage;
	g_Round.totals.survivorTotalJockeyAssistDamage -= playerData.combatAssists.jockeyAssistDamage;
	g_Round.totals.survivorTotalChargerAssistDamage -= playerData.combatAssists.chargerAssistDamage;
	g_Round.totals.survivorTotalTankKills -= playerData.combat.tankKills;
	g_Round.totals.survivorTotalWitchKills -= playerData.combat.witchKills;
	g_Round.totals.survivorTotalFF -= playerData.combat.ffGiven;
	g_Round.totals.survivorTotalDeaths -= playerData.survivability.deaths;
	g_Round.totals.survivorTotalIncaps -= playerData.survivability.incaps;
	g_Round.totals.survivorTotalHealsGiven -= playerData.support.healsGiven;
	g_Round.totals.survivorTotalRevivesGiven -= playerData.support.revivesGiven;
	g_Round.totals.survivorTotalRescuesGiven -= playerData.support.rescuesGiven;
	g_Round.totals.infectedTotalTongueGrabs -= playerData.infectedGrab.tongueGrabs;
	g_Round.totals.infectedTotalHunterPouncesLanded -= playerData.infectedGrab.hunterPounces;
	g_Round.totals.infectedTotalJockeyRidesLanded -= playerData.infectedGrab.jockeyRides;
	g_Round.totals.infectedTotalBoomerVomitVictims -= playerData.infectedSupport.boomerVomitVictims;
	g_Round.totals.infectedTotalSmokerDamage -= playerData.infectedGrab.smokerDamage;
	g_Round.totals.infectedTotalHunterDamage -= playerData.infectedGrab.hunterDamage;
	g_Round.totals.infectedTotalJockeyDamage -= playerData.infectedGrab.jockeyDamage;
	g_Round.totals.infectedTotalChargerDamage -= playerData.infectedGrab.chargerDamage;
	g_Round.totals.infectedTotalGrabDamage -= playerData.infectedGrab.totalDamage;
	g_Round.totals.infectedTotalSpitterDamage -= playerData.infectedSupport.spitterDamage;
	g_Round.totals.survivorTotalPillsUsed -= playerData.resources.pillsUsed;
	g_Round.totals.survivorTotalAdrenalineUsed -= playerData.resources.adrenalineUsed;
	g_Round.totals.survivorTotalMedkitsUsed -= playerData.resources.medkitsUsed;
	g_Round.totals.survivorTotalDefibsUsed -= playerData.resources.defibsUsed;
	g_Round.totals.survivorTotalMolotovsThrown -= playerData.resources.molotovsThrown;
	g_Round.totals.survivorTotalPipebombsThrown -= playerData.resources.pipebombsThrown;
	g_Round.totals.survivorTotalVomitjarsThrown -= playerData.resources.vomitjarsThrown;
	g_Round.totals.survivorTotalZombiesIgnited -= playerData.resources.zombiesIgnited;
	g_Round.totals.survivorTotalPlayersBiled -= playerData.resources.playersBiled;
	g_Round.totals.survivorTotalTanksBiled -= playerData.resources.tanksBiled;
	g_Round.totals.survivorTotalGascansPoured -= playerData.scavenge.gascansPoured;
	g_Round.totals.survivorTotalGascansDropped -= playerData.scavenge.gascansDropped;
	g_Round.totals.survivorTotalGascansDestroyed -= playerData.scavenge.gascansDestroyed;
}
stock void Stats_AddPlayerRoundDataToTotals(PlayerStatsPlayerRoundData playerData)
{
	g_Round.totals.survivorTotalSiDamage += playerData.combat.siDamage;
	g_Round.totals.survivorTotalSmokerDamage += playerData.combat.smokerDamage;
	g_Round.totals.survivorTotalBoomerDamage += playerData.combat.boomerDamage;
	g_Round.totals.survivorTotalHunterDamage += playerData.combat.hunterDamage;
	g_Round.totals.survivorTotalSpitterDamage += playerData.combat.spitterDamage;
	g_Round.totals.survivorTotalJockeyDamage += playerData.combat.jockeyDamage;
	g_Round.totals.survivorTotalChargerDamage += playerData.combat.chargerDamage;
	g_Round.totals.survivorTotalTankDamage += playerData.combat.tankDamage;
	g_Round.totals.survivorTotalWitchDamage += playerData.combat.witchDamage;
	g_Round.totals.survivorTotalCommonKills += playerData.combat.commonKills;
	g_Round.totals.survivorTotalSmokerKills += playerData.combat.smokerKills;
	g_Round.totals.survivorTotalBoomerKills += playerData.combat.boomerKills;
	g_Round.totals.survivorTotalHunterKills += playerData.combat.hunterKills;
	g_Round.totals.survivorTotalSpitterKills += playerData.combat.spitterKills;
	g_Round.totals.survivorTotalJockeyKills += playerData.combat.jockeyKills;
	g_Round.totals.survivorTotalChargerKills += playerData.combat.chargerKills;
	g_Round.totals.survivorTotalSiKillAssists += playerData.combatAssists.siKillAssists;
	g_Round.totals.survivorTotalSmokerKillAssists += playerData.combatAssists.smokerKillAssists;
	g_Round.totals.survivorTotalBoomerKillAssists += playerData.combatAssists.boomerKillAssists;
	g_Round.totals.survivorTotalHunterKillAssists += playerData.combatAssists.hunterKillAssists;
	g_Round.totals.survivorTotalSpitterKillAssists += playerData.combatAssists.spitterKillAssists;
	g_Round.totals.survivorTotalJockeyKillAssists += playerData.combatAssists.jockeyKillAssists;
	g_Round.totals.survivorTotalChargerKillAssists += playerData.combatAssists.chargerKillAssists;
	g_Round.totals.survivorTotalSiAssistDamage += playerData.combatAssists.siAssistDamage;
	g_Round.totals.survivorTotalSmokerAssistDamage += playerData.combatAssists.smokerAssistDamage;
	g_Round.totals.survivorTotalBoomerAssistDamage += playerData.combatAssists.boomerAssistDamage;
	g_Round.totals.survivorTotalHunterAssistDamage += playerData.combatAssists.hunterAssistDamage;
	g_Round.totals.survivorTotalSpitterAssistDamage += playerData.combatAssists.spitterAssistDamage;
	g_Round.totals.survivorTotalJockeyAssistDamage += playerData.combatAssists.jockeyAssistDamage;
	g_Round.totals.survivorTotalChargerAssistDamage += playerData.combatAssists.chargerAssistDamage;
	g_Round.totals.survivorTotalTankKills += playerData.combat.tankKills;
	g_Round.totals.survivorTotalWitchKills += playerData.combat.witchKills;
	g_Round.totals.survivorTotalFF += playerData.combat.ffGiven;
	g_Round.totals.survivorTotalDeaths += playerData.survivability.deaths;
	g_Round.totals.survivorTotalIncaps += playerData.survivability.incaps;
	g_Round.totals.survivorTotalHealsGiven += playerData.support.healsGiven;
	g_Round.totals.survivorTotalRevivesGiven += playerData.support.revivesGiven;
	g_Round.totals.survivorTotalRescuesGiven += playerData.support.rescuesGiven;
	g_Round.totals.infectedTotalTongueGrabs += playerData.infectedGrab.tongueGrabs;
	g_Round.totals.infectedTotalHunterPouncesLanded += playerData.infectedGrab.hunterPounces;
	g_Round.totals.infectedTotalJockeyRidesLanded += playerData.infectedGrab.jockeyRides;
	g_Round.totals.infectedTotalBoomerVomitVictims += playerData.infectedSupport.boomerVomitVictims;
	g_Round.totals.infectedTotalSmokerDamage += playerData.infectedGrab.smokerDamage;
	g_Round.totals.infectedTotalHunterDamage += playerData.infectedGrab.hunterDamage;
	g_Round.totals.infectedTotalJockeyDamage += playerData.infectedGrab.jockeyDamage;
	g_Round.totals.infectedTotalChargerDamage += playerData.infectedGrab.chargerDamage;
	g_Round.totals.infectedTotalGrabDamage += playerData.infectedGrab.totalDamage;
	g_Round.totals.infectedTotalSpitterDamage += playerData.infectedSupport.spitterDamage;
	g_Round.totals.survivorTotalPillsUsed += playerData.resources.pillsUsed;
	g_Round.totals.survivorTotalAdrenalineUsed += playerData.resources.adrenalineUsed;
	g_Round.totals.survivorTotalMedkitsUsed += playerData.resources.medkitsUsed;
	g_Round.totals.survivorTotalDefibsUsed += playerData.resources.defibsUsed;
	g_Round.totals.survivorTotalMolotovsThrown += playerData.resources.molotovsThrown;
	g_Round.totals.survivorTotalPipebombsThrown += playerData.resources.pipebombsThrown;
	g_Round.totals.survivorTotalVomitjarsThrown += playerData.resources.vomitjarsThrown;
	g_Round.totals.survivorTotalZombiesIgnited += playerData.resources.zombiesIgnited;
	g_Round.totals.survivorTotalPlayersBiled += playerData.resources.playersBiled;
	g_Round.totals.survivorTotalTanksBiled += playerData.resources.tanksBiled;
	g_Round.totals.survivorTotalGascansPoured += playerData.scavenge.gascansPoured;
	g_Round.totals.survivorTotalGascansDropped += playerData.scavenge.gascansDropped;
	g_Round.totals.survivorTotalGascansDestroyed += playerData.scavenge.gascansDestroyed;
}
stock void Stats_ResetRoundSlotForReplacement(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return;
	}

	Stats_SubtractPlayerRoundDataFromTotals(g_Round.players[slot]);
	Stats_ClearSlotRuntimeBindings(slot);
	g_Round.players[slot].Reset();
}
stock void Stats_BuildSubstitutionId(int accountId, int timestamp, char[] buffer, int maxlen)
{
	Format(buffer, maxlen, "%d:%d", accountId, timestamp);
}
stock bool Stats_StoreSubstitutionSnapshot(int slot, char[] substitutionId, int maxlen)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		if (maxlen > 0)
		{
			substitutionId[0] = '\0';
		}
		return false;
	}

	int timestamp = GetTime();
	PlayerStatsSubstitutionSnapshotData snapshot;
	snapshot.Reset();
	snapshot.active = true;
	snapshot.restored = false;
	g_iSubstitutionGenerationSerial++;
	if (g_iSubstitutionGenerationSerial <= 0)
	{
		g_iSubstitutionGenerationSerial = 1;
	}
	snapshot.generation = g_iSubstitutionGenerationSerial;
	snapshot.accountId = g_Round.players[slot].player.accountId;
	snapshot.timestamp = timestamp;
	snapshot.roundId = g_Round.meta.id;
	snapshot.slot = slot;
	snapshot.baseMode = g_Round.meta.baseMode;
	GetCurrentMap(snapshot.map, sizeof(snapshot.map));
	Stats_BuildSubstitutionId(snapshot.accountId, snapshot.timestamp, snapshot.substitutionId, sizeof(snapshot.substitutionId));
	while (Stats_FindSubstitutionSnapshotById(snapshot.substitutionId) != -1)
	{
		snapshot.timestamp = timestamp + ++g_iSubstitutionSnapshotSerial;
		Stats_BuildSubstitutionId(snapshot.accountId, snapshot.timestamp, snapshot.substitutionId, sizeof(snapshot.substitutionId));
	}
	snapshot.player = g_Round.players[slot];
	snapshot.player.player.DetachClient();
	snapshot.player.player.bot = false;

	int writeIndex = g_iSubstitutionSnapshotNext;
	g_SubstitutionSnapshots[writeIndex] = snapshot;
	g_iSubstitutionSnapshotNext = (g_iSubstitutionSnapshotNext + 1) % L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS;
	if (g_iSubstitutionSnapshotCount < L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS)
	{
		g_iSubstitutionSnapshotCount++;
	}

	strcopy(substitutionId, maxlen, snapshot.substitutionId);
	return true;
}
int Stats_FindSubstitutionSnapshotById(const char[] substitutionId)
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
stock int Stats_FindRestorableSubstitutionSnapshotIndex(int accountId, int roundId, int slot)
{
	if (accountId <= 0 || roundId <= 0 || slot < 0)
	{
		return -1;
	}

	for (int offset = 1; offset <= g_iSubstitutionSnapshotCount; offset++)
	{
		int snapshotIndex = (g_iSubstitutionSnapshotNext - offset + L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS) % L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS;
		if (!g_SubstitutionSnapshots[snapshotIndex].active || g_SubstitutionSnapshots[snapshotIndex].restored)
		{
			continue;
		}

		if (g_SubstitutionSnapshots[snapshotIndex].accountId != accountId
			|| g_SubstitutionSnapshots[snapshotIndex].roundId != roundId
			|| g_SubstitutionSnapshots[snapshotIndex].slot != slot)
		{
			continue;
		}

		return snapshotIndex;
	}

	return -1;
}

stock int Stats_AdvanceSubstitutionSlotSerial(int slot)
{
	if (slot < 0 || slot >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return 0;
	}

	g_iSubstitutionTransitionSerial[slot]++;
	if (g_iSubstitutionTransitionSerial[slot] <= 0)
	{
		g_iSubstitutionTransitionSerial[slot] = 1;
	}

	return g_iSubstitutionTransitionSerial[slot];
}

stock int Stats_BeginSubstitutionTransition(int slot, int snapshotIndex, int incomingClient)
{
	if (slot < 0 || slot >= L4D2_PLAYER_STATS_MAX_PLAYERS || !IsValidClient(incomingClient))
	{
		return 0;
	}

	int transitionSerial = Stats_AdvanceSubstitutionSlotSerial(slot);
	PlayerStatsPendingSubstitutionData transition;
	transition.Reset();
	transition.active = true;
	transition.transitionSerial = transitionSerial;
	transition.callbackActive = true;
	transition.roundId = g_Round.meta.id;
	transition.snapshotIndex = snapshotIndex;
	transition.incomingClient = incomingClient;
	transition.incomingUserid = GetClientUserId(incomingClient);
	transition.incomingAccountId = GetSteamAccountID(incomingClient);

	if (snapshotIndex >= 0 && snapshotIndex < L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS
		&& g_SubstitutionSnapshots[snapshotIndex].active)
	{
		transition.snapshotGeneration = g_SubstitutionSnapshots[snapshotIndex].generation;
		strcopy(transition.substitutionId, sizeof(transition.substitutionId), g_SubstitutionSnapshots[snapshotIndex].substitutionId);
	}

	g_PendingSubstitutions[slot] = transition;
	return transition.transitionSerial;
}

stock void Stats_MarkSubstitutionForwardReturned(int slot, int transitionSerial)
{
	if (slot < 0 || slot >= L4D2_PLAYER_STATS_MAX_PLAYERS
		|| !g_PendingSubstitutions[slot].active
		|| g_PendingSubstitutions[slot].transitionSerial != transitionSerial)
	{
		return;
	}

	g_PendingSubstitutions[slot].callbackActive = false;
}

stock bool Stats_IsSubstitutionTransitionCurrent(int slot, int transitionSerial, int snapshotIndex, bool requireSlotBinding = true, bool allowPriorSnapshot = false)
{
	if (slot < 0 || slot >= L4D2_PLAYER_STATS_MAX_PLAYERS
		|| transitionSerial <= 0
		|| g_iSubstitutionTransitionSerial[slot] != transitionSerial
		|| !g_PendingSubstitutions[slot].active
		|| g_PendingSubstitutions[slot].transitionSerial != transitionSerial
		|| g_PendingSubstitutions[slot].roundId <= 0
		|| !g_Round.meta.active
		|| g_Round.meta.id != g_PendingSubstitutions[slot].roundId
		|| (requireSlotBinding && !g_PendingSubstitutions[slot].callbackActive && !Stats_IsValidRoundSlot(slot))
		|| (!allowPriorSnapshot && snapshotIndex != g_PendingSubstitutions[slot].snapshotIndex)
		|| snapshotIndex < 0
		|| snapshotIndex >= L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS)
	{
		return false;
	}

	if (!IsValidClient(g_PendingSubstitutions[slot].incomingClient)
		|| GetClientUserId(g_PendingSubstitutions[slot].incomingClient) != g_PendingSubstitutions[slot].incomingUserid
		|| (g_PendingSubstitutions[slot].incomingAccountId > 0
			&& GetSteamAccountID(g_PendingSubstitutions[slot].incomingClient) != g_PendingSubstitutions[slot].incomingAccountId))
	{
		return false;
	}

	if (!requireSlotBinding && !g_PendingSubstitutions[slot].callbackActive && g_Round.players[slot].active)
	{
		return false;
	}

	if (requireSlotBinding && !g_PendingSubstitutions[slot].callbackActive
		&& (Stats_GetPlayerRoundIndex(g_PendingSubstitutions[slot].incomingClient) != slot
			|| g_Round.players[slot].player.client != g_PendingSubstitutions[slot].incomingClient))
	{
		return false;
	}

	int transitionSnapshotIndex = g_PendingSubstitutions[slot].snapshotIndex;
	if (transitionSnapshotIndex < 0 || transitionSnapshotIndex >= L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS
		|| !g_SubstitutionSnapshots[transitionSnapshotIndex].active
		|| g_SubstitutionSnapshots[transitionSnapshotIndex].restored
		|| g_SubstitutionSnapshots[transitionSnapshotIndex].generation != g_PendingSubstitutions[slot].snapshotGeneration
		|| g_SubstitutionSnapshots[transitionSnapshotIndex].roundId != g_PendingSubstitutions[slot].roundId
		|| g_SubstitutionSnapshots[transitionSnapshotIndex].slot != slot
		|| !StrEqual(g_SubstitutionSnapshots[transitionSnapshotIndex].substitutionId, g_PendingSubstitutions[slot].substitutionId, false))
	{
		return false;
	}

	return g_SubstitutionSnapshots[snapshotIndex].active
		&& !g_SubstitutionSnapshots[snapshotIndex].restored
		&& g_SubstitutionSnapshots[snapshotIndex].roundId == g_PendingSubstitutions[slot].roundId
		&& g_SubstitutionSnapshots[snapshotIndex].slot == slot;
}

stock bool Stats_RestoreSubstitutionSnapshotToSlot(int snapshotIndex, int slot, int client, bool allowUnbound = false, bool allowPriorSnapshot = true, bool requireIncomingAccount = false)
{
	if (snapshotIndex < 0 || snapshotIndex >= L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS
		|| slot < 0 || slot >= L4D2_PLAYER_STATS_MAX_PLAYERS
		|| !g_SubstitutionSnapshots[snapshotIndex].active
		|| g_SubstitutionSnapshots[snapshotIndex].restored
		|| !g_Round.meta.active
		|| g_Round.meta.id != g_SubstitutionSnapshots[snapshotIndex].roundId
		|| slot != g_SubstitutionSnapshots[snapshotIndex].slot
		|| !IsValidClient(client))
	{
		return false;
	}

	if (!Stats_IsSubstitutionTransitionCurrent(slot, g_PendingSubstitutions[slot].transitionSerial, snapshotIndex, !allowUnbound, allowPriorSnapshot)
		|| g_PendingSubstitutions[slot].incomingClient != client
		|| (!allowUnbound && !g_PendingSubstitutions[slot].callbackActive && !Stats_IsValidRoundSlot(slot)))
	{
		return false;
	}

	if (requireIncomingAccount
		&& g_SubstitutionSnapshots[snapshotIndex].accountId != g_PendingSubstitutions[slot].incomingAccountId)
	{
		return false;
	}

	// Mark first so a reentrant native call cannot add the snapshot twice.
	g_SubstitutionSnapshots[snapshotIndex].restored = true;
	g_PendingSubstitutions[slot].active = false;
	if (g_Round.players[slot].active)
	{
		// A manual restore may arrive after the incoming player has already contributed.
		Stats_SubtractPlayerRoundDataFromTotals(g_Round.players[slot]);
	}
	g_Round.players[slot] = g_SubstitutionSnapshots[snapshotIndex].player;
	g_Round.players[slot].active = true;
	Stats_AddPlayerRoundDataToTotals(g_Round.players[slot]);
	Stats_AssignClientToSlot(client, slot);
	return true;
}
void Substitutions_OnPlayerBotReplace(int player, int bot)
{
	if (!IsValidClient(bot))
	{
		return;
	}

	int slot = Stats_GetPlayerRoundIndex(player);
	if (slot == -1)
	{
		slot = Stats_EnsurePlayerRoundSlot(bot);
		return;
	}

	Stats_AdvanceSubstitutionSlotSerial(slot);

	if (player > 0 && player < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		g_Runtime.playerSlotByClient[player] = -1;
	}

	Stats_AssignBotToSlotPreserveIdentity(bot, slot);
}
void Substitutions_OnBotPlayerReplace(int bot, int player)
{
	if (!IsValidClient(player))
	{
		return;
	}

	int slot = Stats_GetPlayerRoundIndex(bot);
	if (slot == -1)
	{
		slot = Stats_EnsurePlayerRoundSlot(player);
		return;
	}

	if (g_Round.players[slot].player.IsSamePersistentPlayer(player))
	{
		Stats_AdvanceSubstitutionSlotSerial(slot);
		if (bot > 0 && bot < L4D2_PLAYER_STATS_MAX_PLAYERS)
		{
			g_Runtime.playerSlotByClient[bot] = -1;
		}
		Stats_AssignClientToSlot(player, slot);
		return;
	}

	if (bot > 0 && bot < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		g_Runtime.playerSlotByClient[bot] = -1;
	}

	char substitutionId[64];
	Stats_StoreSubstitutionSnapshot(slot, substitutionId, sizeof(substitutionId));
	Stats_ResetRoundSlotForReplacement(slot);
	int snapshotIndex = Stats_FindSubstitutionSnapshotById(substitutionId);
	int transitionSerial = Stats_BeginSubstitutionTransition(slot, snapshotIndex, player);
	if (transitionSerial == 0)
	{
		g_Round.players[slot].active = true;
		Stats_AssignClientToSlot(player, slot);
		return;
	}

	int roundId = g_Round.meta.id;
	Action substitutionAction = API_FirePlayerSubstituted(substitutionId, roundId, slot, player);
	Stats_MarkSubstitutionForwardReturned(slot, transitionSerial);
	if (!Stats_IsSubstitutionTransitionCurrent(slot, transitionSerial, snapshotIndex, false))
	{
		return;
	}

	if (substitutionAction >= Plugin_Handled)
	{
		g_Round.players[slot].active = true;
		Stats_AssignClientToSlot(player, slot);
		return;
	}

	int restoreIndex = Stats_FindRestorableSubstitutionSnapshotIndex(GetSteamAccountID(player), roundId, slot);
	if (restoreIndex != -1 && Stats_RestoreSubstitutionSnapshotToSlot(restoreIndex, slot, player, true, true, true))
	{
		return;
	}

	g_Round.players[slot].active = true;
	Stats_AssignClientToSlot(player, slot);
}
