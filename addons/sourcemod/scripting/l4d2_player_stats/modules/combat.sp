#if defined _l4d2_player_stats_modules_combat_included
	#endinput
#endif
#define _l4d2_player_stats_modules_combat_included

void Combat_ApplyCommonKill(int index)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	g_Round.players[index].combat.commonKills++;
	g_Round.totals.survivorTotalCommonKills++;
}

void Combat_ApplySpecialKillByClass(int index, L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combat.smokerKills++;
			g_Round.totals.survivorTotalSmokerKills++;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combat.boomerKills++;
			g_Round.totals.survivorTotalBoomerKills++;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combat.hunterKills++;
			g_Round.totals.survivorTotalHunterKills++;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combat.spitterKills++;
			g_Round.totals.survivorTotalSpitterKills++;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combat.jockeyKills++;
			g_Round.totals.survivorTotalJockeyKills++;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combat.chargerKills++;
			g_Round.totals.survivorTotalChargerKills++;
		}
		case L4D2ZombieClass_Tank:
		{
			g_Round.players[index].combat.tankKills++;
			g_Round.totals.survivorTotalTankKills++;
		}
	}
}

PlayerStatsWitchCombatResult Combat_ApplyWitchDamage(const StatsWitchDamageRecord record)
{
	if (!Stats_IsTrackingEnabled())
	{
		return PlayerStatsWitchCombat_TrackingDisabled;
	}

	if (record.quantityBasis != PlayerStatsDamageBasis_InfectedHurtAmount
		|| record.amount <= 0
		|| !Stats_IsValidRoundSlot(record.roundSlot)
		|| !IsValidSurvivor(record.attackerClient))
	{
		return PlayerStatsWitchCombat_InvalidRecord;
	}

	g_Round.players[record.roundSlot].combat.witchDamage += record.amount;
	g_Round.players[record.roundSlot].combat.witchHits++;
	g_Round.totals.survivorTotalWitchDamage += record.amount;
	return PlayerStatsWitchCombat_Applied;
}

/**
 * @brief Adds survivor damage to its SI or Tank combat counters.
 *
 * The caller has already applied the accuracy view in its original order.
 */
PlayerStatsDamageRouteResult Combat_ApplySurvivorDamage(const StatsPlayerHurtObservation observation, int index)
{
	if (!Stats_IsTrackingEnabled())
	{
		return PlayerStatsDamageRoute_AccuracyOnly;
	}

	if (observation.quantityBasis != PlayerStatsDamageBasis_PlayerHurtDmgHealth
		|| observation.damage <= 0
		|| !Stats_IsValidRoundSlot(index))
	{
		return PlayerStatsDamageRoute_InvalidRecord;
	}

	if (IsValidTank(observation.victimClient))
	{
		Stats_RegisterTankVictim(observation.victimClient);
		g_Round.players[index].combat.tankDamage += observation.damage;
		g_Round.players[index].combat.tankHits++;
		g_Round.totals.survivorTotalTankDamage += observation.damage;
	}
	else
	{
		Stats_AddSpecialDamageByClass(index, L4D2_GetPlayerZombieClass(observation.victimClient), observation.damage);
		g_Round.players[index].combat.siDamage += observation.damage;
		g_Round.totals.survivorTotalSiDamage += observation.damage;
	}

	return PlayerStatsDamageRoute_Applied;
}

/**
 * @brief Adds survivor-to-survivor damage to the attacker's FF counters.
 */
PlayerStatsDamageRouteResult Combat_ApplyFriendlyFire(const StatsPlayerHurtObservation observation)
{
	if (!Stats_IsTrackingEnabled())
	{
		return PlayerStatsDamageRoute_TrackingDisabled;
	}

	int index = Stats_EnsurePlayerRoundSlot(observation.attackerClient);
	if (index == -1)
	{
		return PlayerStatsDamageRoute_NoSlot;
	}

	g_Round.players[index].combat.ffGiven += observation.damage;
	g_Round.totals.survivorTotalFF += observation.damage;
	return PlayerStatsDamageRoute_Applied;
}

/**
 * @brief Adds damage to the survivor combat split for a special infected class.
 *
 * @param index          Persistent survivor slot index.
 * @param zombieClass    Infected class that received the damage.
 * @param damage         Damage to add.
 *
 * @noreturn
 */
stock void Stats_AddSpecialDamageByClass(int index, L4D2ZombieClassType zombieClass, int damage)
{
	if (!Stats_IsValidRoundSlot(index) || damage <= 0)
	{
		return;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combat.smokerDamage += damage;
			g_Round.totals.survivorTotalSmokerDamage += damage;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combat.boomerDamage += damage;
			g_Round.totals.survivorTotalBoomerDamage += damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combat.hunterDamage += damage;
			g_Round.totals.survivorTotalHunterDamage += damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combat.spitterDamage += damage;
			g_Round.totals.survivorTotalSpitterDamage += damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combat.jockeyDamage += damage;
			g_Round.totals.survivorTotalJockeyDamage += damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combat.chargerDamage += damage;
			g_Round.totals.survivorTotalChargerDamage += damage;
		}
	}
}
