#if defined _l4d2_player_stats_modules_infected_included
	#endinput
#endif
#define _l4d2_player_stats_modules_infected_included

PlayerStatsInfectedDamageApplyResult Infected_ApplySurvivorDamage(const StatsInfectedDamageRecord observation)
{
	if (observation.quantityBasis != PlayerStatsDamageBasis_PlayerHurtDmgHealth
		|| observation.damage <= 0
		|| !Stats_IsValidRoundSlot(observation.roundSlot))
	{
		return PlayerStatsInfectedDamage_InvalidRecord;
	}

	switch (observation.attackerClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[observation.roundSlot].infectedGrab.smokerDamage += observation.damage;
			g_Round.players[observation.roundSlot].infectedGrab.totalDamage += observation.damage;
			g_Round.totals.infectedTotalSmokerDamage += observation.damage;
			g_Round.totals.infectedTotalGrabDamage += observation.damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[observation.roundSlot].infectedGrab.hunterDamage += observation.damage;
			g_Round.players[observation.roundSlot].infectedGrab.totalDamage += observation.damage;
			g_Round.totals.infectedTotalHunterDamage += observation.damage;
			g_Round.totals.infectedTotalGrabDamage += observation.damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[observation.roundSlot].infectedGrab.jockeyDamage += observation.damage;
			g_Round.players[observation.roundSlot].infectedGrab.totalDamage += observation.damage;
			g_Round.totals.infectedTotalJockeyDamage += observation.damage;
			g_Round.totals.infectedTotalGrabDamage += observation.damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[observation.roundSlot].infectedGrab.chargerDamage += observation.damage;
			g_Round.players[observation.roundSlot].infectedGrab.totalDamage += observation.damage;
			g_Round.totals.infectedTotalChargerDamage += observation.damage;
			g_Round.totals.infectedTotalGrabDamage += observation.damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[observation.roundSlot].infectedSupport.spitterDamage += observation.damage;
			g_Round.totals.infectedTotalSpitterDamage += observation.damage;
		}
		default:
		{
			return PlayerStatsInfectedDamage_UnmappedClass;
		}
	}

	return PlayerStatsInfectedDamage_Applied;
}

PlayerStatsControlApplyResult Infected_ApplyControl(const StatsControlRecord observation)
{
	if (observation.type == PlayerStatsControl_BoomerVomit && observation.boomerExplosion)
	{
		return PlayerStatsControlApply_BoomerExplosion;
	}

	if (!Stats_IsTrackingEnabled())
	{
		return PlayerStatsControlApply_TrackingDisabled;
	}

	if (!Stats_IsRoundLive())
	{
		return PlayerStatsControlApply_RoundNotLive;
	}

	if (!IsValidSurvivor(observation.victim))
	{
		return PlayerStatsControlApply_InvalidVictim;
	}

	if (!IsValidInfected(observation.attacker))
	{
		return PlayerStatsControlApply_InvalidAttacker;
	}

	int index = Stats_EnsurePlayerRoundSlot(observation.attacker);
	if (index == -1)
	{
		return PlayerStatsControlApply_NoSlot;
	}

	switch (observation.type)
	{
		case PlayerStatsControl_TongueGrab:
		{
			g_Round.players[index].pressure.tongueGrabs++;
			g_Round.players[index].infectedGrab.tongueGrabs++;
			g_Round.totals.infectedTotalTongueGrabs++;
		}
		case PlayerStatsControl_HunterPounce:
		{
			g_Round.players[index].pressure.hunterPouncesLanded++;
			g_Round.players[index].infectedGrab.hunterPounces++;
			g_Round.totals.infectedTotalHunterPouncesLanded++;
		}
		case PlayerStatsControl_JockeyRide:
		{
			g_Round.players[index].pressure.jockeyRidesLanded++;
			g_Round.players[index].infectedGrab.jockeyRides++;
			g_Round.totals.infectedTotalJockeyRidesLanded++;
		}
		case PlayerStatsControl_BoomerVomit:
		{
			g_Round.players[index].pressure.boomerVomitVictims++;
			g_Round.players[index].infectedSupport.boomerVomitVictims++;
			g_Round.totals.infectedTotalBoomerVomitVictims++;
		}
		default:
		{
			return PlayerStatsControlApply_InvalidObservation;
		}
	}

	return PlayerStatsControlApply_Applied;
}
