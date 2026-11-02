#if defined _l4d2_player_stats_damage_resolve_included
	#endinput
#endif
#define _l4d2_player_stats_damage_resolve_included

PlayerStatsWitchHurtResolveResult Damage_ResolveWitchHurt(const StatsInfectedHurtObservation observation, StatsWitchDamageRecord record)
{
	if (!Stats_IsRoundLive())
	{
		return PlayerStatsWitchHurt_RoundNotLive;
	}

	if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled() && !Stats_IsThrowablesEnabled())
	{
		return PlayerStatsWitchHurt_FeaturesDisabled;
	}

	if (!IsWitchEntity(observation.entity))
	{
		return PlayerStatsWitchHurt_NotWitch;
	}

	Stats_RegisterWitchEntity(observation.entity);
	if (!observation.validPayload)
	{
		return PlayerStatsWitchHurt_InvalidPayload;
	}

	if (observation.amount <= 0)
	{
		return PlayerStatsWitchHurt_InvalidDamage;
	}

	int attacker = observation.attackerClient;
	if (!IsValidSurvivor(attacker))
	{
		return PlayerStatsWitchHurt_InvalidAttacker;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return PlayerStatsWitchHurt_NoSlot;
	}

	record.quantityBasis = PlayerStatsDamageBasis_InfectedHurtAmount;
	record.entity = observation.entity;
	record.attackerUserid = observation.attackerUserid;
	record.attackerClient = attacker;
	record.amount = observation.amount;
	record.roundSlot = index;
	record.headshot = observation.hitgroup == 1;
	record.family = Stats_GetWeaponFamily(observation.weapon);
	record.detail = Stats_GetWeaponDetailType(observation.weapon);
	if (record.family == PlayerStatsWeaponFamily_None)
	{
		record.family = Stats_GetLastWeaponFamily(attacker);
	}
	if (record.detail == PlayerStatsWeaponDetail_None)
	{
		record.detail = Stats_GetLastWeaponDetail(attacker);
	}

	return PlayerStatsWitchHurt_Ready;
}

PlayerStatsDamageRouteResult Damage_ProcessSurvivorOutgoing(const StatsPlayerHurtObservation observation)
{
	if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled())
	{
		return PlayerStatsDamageRoute_FeaturesDisabled;
	}

	int index = Stats_EnsurePlayerRoundSlot(observation.attackerClient);
	if (index == -1)
	{
		return PlayerStatsDamageRoute_NoSlot;
	}

	PlayerStatsWeaponFamily family = Stats_GetWeaponFamily(observation.weapon);
	PlayerStatsWeaponDetailType detail = Stats_GetWeaponDetailType(observation.weapon);
	if (family == PlayerStatsWeaponFamily_None)
	{
		family = Stats_GetLastWeaponFamily(observation.attackerClient);
	}
	if (detail == PlayerStatsWeaponDetail_None)
	{
		detail = Stats_GetLastWeaponDetail(observation.attackerClient);
	}

	Accuracy_ApplyPlayerHurtHit(index, family, detail, observation.hitgroup == 1);
	return Combat_ApplySurvivorDamage(observation, index);
}

PlayerStatsDamageRouteResult Damage_ProcessFriendlyFire(const StatsPlayerHurtObservation observation)
{
	return Combat_ApplyFriendlyFire(observation);
}

PlayerStatsInfectedDamageApplyResult Damage_ProcessInfectedOutgoing(const StatsPlayerHurtObservation observation, int index, L4D2ZombieClassType attackerClass)
{
	StatsInfectedDamageRecord record;
	record.quantityBasis = observation.quantityBasis;
	record.attackerClass = attackerClass;
	record.roundSlot = index;
	record.damage = observation.damage;
	return Infected_ApplySurvivorDamage(record);
}

stock int Stats_GetValidDamagePolicy(ConVar cvar)
{
	return cvar != null ? cvar.IntValue : view_as<int>(PlayerStatsValidDamage_ExcludeIncap) | view_as<int>(PlayerStatsValidDamage_ExcludeLedge);
}


stock bool Stats_ShouldCountVictimForDamage(int victim, ConVar cvar)
{
	if (!IsValidSurvivor(victim))
	{
		return false;
	}

	int policy = Stats_GetValidDamagePolicy(cvar);
	if ((policy & view_as<int>(PlayerStatsValidDamage_ExcludeIncap)) != 0 && Stats_IsSurvivorIncapacitated(victim))
	{
		return false;
	}

	if ((policy & view_as<int>(PlayerStatsValidDamage_ExcludeLedge)) != 0 && Stats_IsSurvivorHanging(victim))
	{
		return false;
	}

	return true;
}


stock bool Stats_IsSurvivorIncapacitated(int client)
{
	return IsValidSurvivor(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}


stock bool Stats_IsSurvivorHanging(int client)
{
	return IsValidSurvivor(client) && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}


stock int Stats_GetSurvivorCurrentHealthTotal(int client)
{
	if (!IsValidSurvivor(client))
	{
		return 0;
	}

	float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int total = GetClientHealth(client) + RoundToFloor(tempHealth);
	return total > 0 ? total : 0;
}
