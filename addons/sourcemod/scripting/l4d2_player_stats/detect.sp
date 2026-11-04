#if defined _l4d2_player_stats_detect_included
	#endinput
#endif
#define _l4d2_player_stats_detect_included

void Detect_ProcessPlayerHurt(const StatsPlayerHurtObservation observation, StatsTraceContext traceContext)
{
	if (!Stats_IsRoundLive())
	{
		Trace_EventResult(traceContext, "player_hurt", "round_not_live");
		return;
	}

	int victim = observation.victimClient;
	int attacker = observation.attackerClient;
	int damage = observation.damage;

	if (damage <= 0 || !IsValidClient(attacker))
	{
		Trace_EventResult(traceContext, "player_hurt", damage <= 0 ? "nonpositive_damage" : "invalid_attacker");
		return;
	}

	if (IsValidInfected(attacker) && IsValidSurvivor(victim))
	{
		if (!Stats_IsTrackingEnabled() || !Stats_IsCompetitiveMode())
		{
			Trace_EventResult(traceContext, "player_hurt", !Stats_IsTrackingEnabled() ? "tracking_disabled" : "wrong_mode");
			return;
		}

		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			Trace_EventResult(traceContext, "player_hurt", "attacker_no_slot");
			return;
		}

		if (IsValidTank(attacker))
		{
			Detect_RecordTankHurt(observation, traceContext);
			Trace_EventResult(traceContext, "player_hurt", "tank_hurt_recorded");
			return;
		}

		if (!Stats_ShouldCountVictimForDamage(victim, g_cvInfectedValidDamage))
		{
			Trace_EventResult(traceContext, "player_hurt", "victim_filtered");
			return;
		}

		Damage_ProcessInfectedOutgoing(observation, index, L4D2_GetPlayerZombieClass(attacker));
		Trace_EventResult(traceContext, "player_hurt", "infected_damage_routed");

		return;
	}

	if (IsValidSurvivor(attacker) && IsValidInfected(victim))
	{
		Damage_ProcessSurvivorOutgoing(observation);
		Trace_EventResult(traceContext, "player_hurt", "survivor_damage_routed");
		return;
	}

	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim) && attacker != victim)
	{
		Damage_ProcessFriendlyFire(observation);
		Trace_EventResult(traceContext, "player_hurt", "friendly_fire_routed");
		return;
	}

	Trace_EventResult(traceContext, "player_hurt", "no_matching_route");
}

void Detect_ProcessPlayerDeath(const StatsPlayerDeathObservation observation, StatsTraceContext traceContext)
{
	if (!Stats_IsRoundLive())
	{
		Trace_EventResult(traceContext, "player_death", "round_not_live");
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Trace_EventResult(traceContext, "player_death", "tracking_disabled");
		return;
	}

	int victim = GetClientOfUserId(observation.victimUserid);
	int attacker = GetClientOfUserId(observation.attackerUserid);

	bool tankSurvivorDeath = IsValidSurvivor(victim) && IsValidTank(attacker);
	if (tankSurvivorDeath)
	{
		Detect_RecordTankSurvivorDeath(attacker, victim, observation.attackerUserid, observation.victimUserid, observation.weapon, traceContext);
	}
	if (IsValidSurvivor(victim))
	{
		Damage_AdvanceTankVictimLife(victim, observation.victimUserid, "player_death");
	}

	if (IsValidInfected(victim))
	{
		if (!IsValidSurvivor(attacker))
		{
			if (IsValidTank(victim))
			{
				Detect_OnTankKilled(victim);
				Trace_EventResult(traceContext, "player_death", "tank_kill_routed");
				return;
			}
			Trace_EventResult(traceContext, "player_death", "infected_death_without_survivor_attacker");
			return;
		}

		int attackerIndex = Stats_EnsurePlayerRoundSlot(attacker);
		if (attackerIndex == -1)
		{
			Trace_EventResult(traceContext, "player_death", "attacker_no_slot");
			return;
		}

		L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
		if (zombieClass == L4D2ZombieClass_Tank || !g_Runtime.hasPlayerSkills)
		{
			Combat_ApplySpecialKillByClass(attackerIndex, zombieClass);
			Trace_EventResult(traceContext, "player_death", "special_kill_routed");
			return;
		}
		Trace_EventResult(traceContext, "player_death", "skills_owns_special_kill");
		return;
	}

	if (!IsValidSurvivor(victim))
	{
		Trace_EventResult(traceContext, "player_death", "victim_not_survivor");
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(victim);
	if (index == -1)
	{
		Trace_EventResult(traceContext, "player_death", "victim_no_slot");
		return;
	}

	Survivor_ApplyDeath(index, attacker);
	Trace_EventResult(traceContext, "player_death", tankSurvivorDeath ? "tank_survivor_death_applied" : "survivor_death_applied");
}

void Detect_ProcessInfectedDeath(const StatsInfectedDeathObservation observation, StatsTraceContext traceContext)
{
	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. attacker_userid=%d round=%d",
			observation.eventName,
			observation.attackerUserid,
			g_Round.meta.id);
		Trace_EventResult(traceContext, observation.eventName, "round_not_live");
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. attacker_userid=%d round=%d",
			observation.eventName,
			observation.attackerUserid,
			g_Round.meta.id);
		Trace_EventResult(traceContext, observation.eventName, "tracking_disabled");
		return;
	}

	int attacker = GetClientOfUserId(observation.attackerUserid);
	if (!IsValidSurvivor(attacker))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because attacker did not resolve to a survivor. attacker_userid=%d client=%d round=%d",
			observation.eventName,
			observation.attackerUserid,
			attacker,
			g_Round.meta.id);
		Trace_EventResult(traceContext, observation.eventName, "attacker_not_survivor");
		return;
	}

	int infectedType = observation.infectedType;
	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. attacker_userid=%d client=%d infected_type=%d round=%d",
			observation.eventName,
			observation.attackerUserid,
			attacker,
			infectedType,
			g_Round.meta.id);
		Trace_EventResult(traceContext, observation.eventName, "attacker_no_slot");
		return;
	}

	Combat_ApplyCommonKill(index);

	if (g_Round.players[index].combat.commonKills <= 5
		|| g_Round.players[index].combat.commonKills % 25 == 0
		|| g_Round.totals.survivorTotalCommonKills <= 10
		|| g_Round.totals.survivorTotalCommonKills % 100 == 0)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Counted %s as common kill. attacker_userid=%d client=%d slot=%d infected_type=%d player_total=%d round_total=%d",
			observation.eventName,
			observation.attackerUserid,
			attacker,
			index,
			infectedType,
			g_Round.players[index].combat.commonKills,
			g_Round.totals.survivorTotalCommonKills);
	}

	Trace_EventResult(traceContext, observation.eventName, "common_kill_applied");
}

void Detect_ProcessIncapacitatedPost(const StatsIncapacitationObservation observation)
{
	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		return;
	}

	if (!IsValidSurvivor(observation.victim))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(observation.victim);
	if (index == -1)
	{
		return;
	}

	Survivor_ApplyIncap(index, observation.attacker);
}

void Detect_ProcessPlayerIncapacitatedStart(const StatsPlayerIncapacitatedStartObservation observation, StatsTraceContext traceContext)
{
	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !Stats_IsCompetitiveMode())
	{
		Trace_EventResult(traceContext, "player_incapacitated_start",
			!Stats_IsTrackingEnabled() ? "tracking_disabled" : (!Stats_IsRoundLive() ? "round_not_live" : "wrong_mode"));
		return;
	}

	int victim = GetClientOfUserId(observation.victimUserid);
	int attacker = GetClientOfUserId(observation.attackerUserid);
	if (!IsValidSurvivor(victim) || !IsValidTank(attacker))
	{
		Trace_EventResult(traceContext, "player_incapacitated_start", !IsValidSurvivor(victim) ? "invalid_victim" : "attacker_not_tank");
		return;
	}

	Detect_RecordTankIncap(attacker, victim, observation.attackerUserid, observation.victimUserid, observation.weapon, traceContext);
	Trace_EventResult(traceContext, "player_incapacitated_start", "tank_incap_recorded");
}
