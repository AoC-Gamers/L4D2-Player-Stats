#if defined _l4d2_player_stats_queries_included
	#endinput
#endif
#define _l4d2_player_stats_queries_included

int Queries_GetPlayerSiDamageFromData(PlayerStatsPlayerRoundData playerData)
{
	int total = 0;

	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Smoker))
	{
		total += playerData.combat.smokerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Boomer))
	{
		total += playerData.combat.boomerDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Hunter))
	{
		total += playerData.combat.hunterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Spitter))
	{
		total += playerData.combat.spitterDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Jockey))
	{
		total += playerData.combat.jockeyDamage;
	}
	if (Stats_IsZombieClassEnabledForRound(L4D2ZombieClass_Charger))
	{
		total += playerData.combat.chargerDamage;
	}

	return total;
}

int Queries_GetPlayerSiDamage(int index)
{
	return Queries_GetPlayerSiDamageFromData(g_Round.players[index]);
}

int Queries_GetPlayerDamageScore(int index)
{
	return Queries_GetPlayerSiDamage(index);
}

int Queries_GetPlayerSpecialKills(int index)
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

int Queries_GetPlayerSpecialKillsByClass(int index, L4D2ZombieClassType zombieClass)
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

int Queries_GetPlayerSpecialAssistDamageByClass(int index, L4D2ZombieClassType zombieClass)
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

int Queries_GetPlayerSpecialDamageByClass(int index, L4D2ZombieClassType zombieClass)
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

int Queries_GetTotalSurvivorDamage()
{
	return Queries_GetTotalSurvivorSiDamage();
}

int Queries_GetTotalSurvivorSiDamage()
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

int Queries_GetTotalSurvivorSpecialKills()
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

int Queries_FindTopDamageSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
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

		int score = Queries_GetPlayerDamageScore(slot);
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}

	return bestSlot;
}

int Queries_FindTopCommonSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
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

int Queries_FindTopFFSlot(int excludeA = -1, int excludeB = -1, int excludeC = -1)
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

int Queries_GetDamageRank(int client)
{
	int rank = 1;
	int index = Stats_GetPlayerRoundIndex(client);
	int score = index != -1 ? Queries_GetPlayerDamageScore(index) : 0;

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

		if (Queries_GetPlayerDamageScore(slot) > score)
		{
			rank++;
		}
	}

	return rank;
}

int Queries_GetDamageRankBySlot(int index)
{
	int rank = 1;
	int score = index != -1 ? Queries_GetPlayerDamageScore(index) : 0;

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

		if (Queries_GetPlayerDamageScore(slot) > score)
		{
			rank++;
		}
	}

	return rank;
}

int Queries_GetCommonRank(int client)
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

int Queries_GetCommonRankBySlot(int index)
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

int Queries_GetFFRank(int client)
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

int Queries_GetFFRankBySlot(int index)
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

int Queries_GetPlayerInfectedGrabScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return g_Round.players[slot].infectedGrab.totalDamage;
}

int Queries_GetPlayerInfectedSupportScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return (g_Round.players[slot].infectedSupport.boomerVomitVictims * 1000)
		+ g_Round.players[slot].infectedSupport.spitterDamage;
}

int Queries_CollectSortedInfectedHumanSlots(int[] slots, int maxSlots)
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
		int currentScore = Queries_GetPlayerInfectedGrabScore(currentSlot) + Queries_GetPlayerInfectedSupportScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareScore = Queries_GetPlayerInfectedGrabScore(compareSlot) + Queries_GetPlayerInfectedSupportScore(compareSlot);
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

int Queries_CollectSortedSurvivorSlotsByDamage(int[] slots, int maxSlots)
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
		int keyScore = Queries_GetPlayerDamageScore(key);
		int j = i - 1;

		while (j >= 0)
		{
			int current = slots[j];
			int currentScore = Queries_GetPlayerDamageScore(current);
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

int Queries_GetPlayerUtilityScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	int total = 0;

	if (Queries_ShouldShowMolotovUtility())
	{
		total += g_Round.players[slot].resources.molotovsThrown + g_Round.players[slot].resources.zombiesIgnited;
	}
	if (Queries_ShouldShowPipebombUtility())
	{
		total += g_Round.players[slot].resources.pipebombsThrown;
	}
	if (Queries_ShouldShowVomitjarUtility())
	{
		total += g_Round.players[slot].resources.vomitjarsThrown
			+ g_Round.players[slot].resources.playersBiled
			+ g_Round.players[slot].resources.tanksBiled;
	}

	return total;
}

int Queries_GetPlayerConsumableScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	int total = g_Round.players[slot].resources.pillsUsed + g_Round.players[slot].resources.medkitsUsed;

	if (Queries_ShouldShowAdrenalineConsumable())
	{
		total += g_Round.players[slot].resources.adrenalineUsed;
	}
	if (Queries_ShouldShowDefibConsumable())
	{
		total += g_Round.players[slot].resources.defibsUsed;
	}

	return total;
}

bool Queries_ShouldShowMolotovUtility()
{
	return g_cvConfoglMolotovLimit == null || g_cvConfoglMolotovLimit.IntValue != 0;
}

bool Queries_ShouldShowPipebombUtility()
{
	return g_cvConfoglPipebombLimit == null || g_cvConfoglPipebombLimit.IntValue != 0;
}

bool Queries_ShouldShowVomitjarUtility()
{
	return g_cvConfoglVomitjarLimit == null || g_cvConfoglVomitjarLimit.IntValue != 0;
}

bool Queries_ShouldShowAdrenalineConsumable()
{
	return g_cvConfoglAdrenalineLimit == null || g_cvConfoglAdrenalineLimit.IntValue != 0;
}

bool Queries_ShouldShowDefibConsumable()
{
	return g_cvConfoglRemoveDefib == null || !g_cvConfoglRemoveDefib.BoolValue;
}

int Queries_GetPlayerSupportScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return g_Round.players[slot].support.healsGiven
		+ g_Round.players[slot].support.revivesGiven
		+ g_Round.players[slot].support.rescuesGiven;
}

int Queries_GetPlayerScavengeScore(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return (g_Round.players[slot].scavenge.gascansPoured * 10000)
		+ (g_Round.players[slot].scavenge.gascansDestroyed * 100)
		+ g_Round.players[slot].scavenge.gascansDropped;
}

int Queries_CollectSortedSurvivorSlotsByUtility(int[] slots, int maxSlots)
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
		int currentUtility = Queries_GetPlayerUtilityScore(currentSlot);
		int currentDamage = Queries_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareUtility = Queries_GetPlayerUtilityScore(compareSlot);
			int compareDamage = Queries_GetPlayerDamageScore(compareSlot);
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

int Queries_CollectSortedSurvivorSlotsByConsumables(int[] slots, int maxSlots)
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
		int currentItems = Queries_GetPlayerConsumableScore(currentSlot);
		int currentDamage = Queries_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareItems = Queries_GetPlayerConsumableScore(compareSlot);
			int compareDamage = Queries_GetPlayerDamageScore(compareSlot);
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

int Queries_CollectSortedSurvivorSlotsBySupport(int[] slots, int maxSlots)
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
		int currentSupport = Queries_GetPlayerSupportScore(currentSlot);
		int currentDamage = Queries_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareSupport = Queries_GetPlayerSupportScore(compareSlot);
			int compareDamage = Queries_GetPlayerDamageScore(compareSlot);
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

int Queries_CollectSortedSurvivorSlotsByScavenge(int[] slots, int maxSlots)
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
		int currentScore = Queries_GetPlayerScavengeScore(currentSlot);
		int currentDamage = Queries_GetPlayerDamageScore(currentSlot);
		int j = i - 1;

		while (j >= 0)
		{
			int compareSlot = slots[j];
			int compareScore = Queries_GetPlayerScavengeScore(compareSlot);
			int compareDamage = Queries_GetPlayerDamageScore(compareSlot);
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

stock bool Stats_IsZombieClassEnabledForRound(L4D2ZombieClassType zombieClass)
{
	return Stats_IsZombieClassEnabledForSnapshot(zombieClass, g_Round.meta.isVersusMode, g_Round.meta.siPoolMask);
}
