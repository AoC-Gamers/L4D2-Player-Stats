#if defined _l4d2_player_stats_detect_included
	#endinput
#endif
#define _l4d2_player_stats_detect_included

void Detect_Init()
{
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("pills_used", Event_PillsUsed, EventHookMode_Post);
	HookEvent("adrenaline_used", Event_AdrenalineUsed, EventHookMode_Post);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("survivor_rescued", Event_SurvivorRescued, EventHookMode_Post);
}

void Detect_EventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("dmg_health");

	if (damage <= 0 || !IsValidClient(attacker))
	{
		return;
	}

	if (IsValidSurvivor(attacker) && IsValidInfected(victim))
	{
		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			return;
		}

		if (IsValidTank(victim))
		{
			g_Round.players[index].tankDamage += damage;
			g_Round.survivorTotalTankDamage += damage;
		}
		else
		{
			Stats_AddSpecialDamageByClass(index, L4D2_GetPlayerZombieClass(victim), damage);
			g_Round.players[index].siDamage += damage;
			g_Round.survivorTotalSiDamage += damage;
		}

		return;
	}

	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim) && attacker != victim)
	{
		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			return;
		}

		g_Round.players[index].ffGiven += damage;
		g_Round.survivorTotalFF += damage;
	}
}

void Detect_EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidInfected(victim))
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (!IsValidSurvivor(attacker))
		{
			return;
		}

		int attackerIndex = Stats_EnsurePlayerRoundSlot(attacker);
		if (attackerIndex == -1)
		{
			return;
		}

		Stats_AddSpecialKillByClass(attackerIndex, L4D2_GetPlayerZombieClass(victim));
		return;
	}

	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	int index = Stats_EnsurePlayerRoundSlot(victim);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].deaths++;
	g_Round.survivorTotalDeaths++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].deathBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].deathByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].deathByInfectedAI++;
		}
	}
}

void Detect_EventInfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	int infectedType = event.GetInt("gender");
	if (infectedType > 2)
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].commonKills++;
	g_Round.survivorTotalCommonKills++;
}

void Detect_EventInfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int entity = event.GetInt("entityid");
	if (!IsWitchEntity(entity))
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("amount");

	if (damage <= 0 || !IsValidSurvivor(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].witchDamage += damage;
	g_Round.survivorTotalWitchDamage += damage;
}

void Detect_OnIncapacitatedPost(int victim, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	if (inflictor == -1 && damage < 0.0 && damagetype == -1 && weapon == -1)
	{
	}

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!IsValidSurvivor(victim))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(victim);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].incaps++;
	g_Round.survivorTotalIncaps++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].incapBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].incapByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].incapByInfectedAI++;
		}
	}
}

void Detect_EventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	if (weapon[0] == '\0')
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return;
	}

	if (StrEqual(weapon, "molotov", false) || StrEqual(weapon, "weapon_molotov", false))
	{
		g_Round.players[index].molotovsThrown++;
		g_Round.survivorTotalMolotovsThrown++;
		return;
	}

	if (StrEqual(weapon, "pipe_bomb", false) || StrEqual(weapon, "weapon_pipe_bomb", false))
	{
		g_Round.players[index].pipebombsThrown++;
		g_Round.survivorTotalPipebombsThrown++;
		return;
	}

	if (StrEqual(weapon, "vomitjar", false) || StrEqual(weapon, "weapon_vomitjar", false))
	{
		g_Round.players[index].vomitjarsThrown++;
		g_Round.survivorTotalVomitjarsThrown++;
	}
}

void Detect_EventPillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].pillsUsed++;
	g_Round.survivorTotalPillsUsed++;
}

void Detect_EventAdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].adrenalineUsed++;
	g_Round.survivorTotalAdrenalineUsed++;
}

void Detect_EventHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
	{
		return;
	}

	int subject = GetClientOfUserId(event.GetInt("subject"));

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].medkitsUsed++;
	g_Round.players[index].healsGiven++;
	g_Round.survivorTotalMedkitsUsed++;
	g_Round.survivorTotalHealsGiven++;

	if (IsValidSurvivor(subject))
	{
		int subjectIndex = Stats_EnsurePlayerRoundSlot(subject);
		if (subjectIndex != -1)
		{
			g_Round.players[subjectIndex].healsReceived++;
		}
	}
}

void Detect_EventDefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidSurvivor(client))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].defibsUsed++;
	g_Round.survivorTotalDefibsUsed++;
}

void Detect_EventReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	int subject = GetClientOfUserId(event.GetInt("subject"));

	if (IsValidSurvivor(client))
	{
		int index = Stats_EnsurePlayerRoundSlot(client);
		if (index != -1)
		{
			g_Round.players[index].revivesGiven++;
			g_Round.survivorTotalRevivesGiven++;
		}
	}

	if (IsValidSurvivor(subject))
	{
		int subjectIndex = Stats_EnsurePlayerRoundSlot(subject);
		if (subjectIndex != -1)
		{
			g_Round.players[subjectIndex].revivesReceived++;
		}
	}
}

void Detect_EventSurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	int rescuer = GetClientOfUserId(event.GetInt("rescuer"));
	int victim = GetClientOfUserId(event.GetInt("victim"));

	if (IsValidSurvivor(rescuer))
	{
		int rescuerIndex = Stats_EnsurePlayerRoundSlot(rescuer);
		if (rescuerIndex != -1)
		{
			g_Round.players[rescuerIndex].rescuesGiven++;
			g_Round.survivorTotalRescuesGiven++;
		}
	}

	if (IsValidSurvivor(victim))
	{
		int victimIndex = Stats_EnsurePlayerRoundSlot(victim);
		if (victimIndex != -1)
		{
			g_Round.players[victimIndex].rescuesReceived++;
		}
	}
}

void Detect_OnGrabWithTonguePost(int victim, int attacker)
{
	if (!Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].tongueGrabs++;
	g_Round.infectedTotalTongueGrabs++;
}

void Detect_OnPouncedOnSurvivorPost(int victim, int attacker)
{
	if (!Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].hunterPouncesLanded++;
	g_Round.infectedTotalHunterPouncesLanded++;
}

void Detect_OnJockeyRidePost(int victim, int attacker)
{
	if (!Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].jockeyRidesLanded++;
	g_Round.infectedTotalJockeyRidesLanded++;
}

void Detect_OnVomitedUponPost(int victim, int attacker, bool boomerExplosion)
{
	if (boomerExplosion)
	{
		return;
	}

	if (!Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].boomerVomitVictims++;
	g_Round.infectedTotalBoomerVomitVictims++;
}

void Detect_OnPlayerSkillDetected(int eventId, L4D2SkillType type)
{
	if (!g_bPlayerSkillsAvailable || !Stats_IsRoundLive() || !PlayerSkills_IsEventValid(eventId))
	{
		return;
	}

	int actor = PlayerSkills_GetEventClient(eventId, L4D2SkillPlayer_Actor);
	if (!IsValidSurvivor(actor))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		return;
	}

	switch (type)
	{
		case L4D2Skill_HunterSkeet:
		{
			g_Round.players[index].skeets++;
			g_Round.survivorTotalSkeets++;
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			g_Round.players[index].skeetMelees++;
			g_Round.survivorTotalSkeetMelees++;
		}
		case L4D2Skill_HunterDeadstop:
		{
			g_Round.players[index].deadstops++;
			g_Round.survivorTotalDeadstops++;
		}
		case L4D2Skill_BoomerPop:
		{
			g_Round.players[index].boomerPops++;
			g_Round.survivorTotalBoomerPops++;
		}
		case L4D2Skill_ChargerLevel:
		{
			g_Round.players[index].levels++;
			g_Round.survivorTotalLevels++;
		}
		case L4D2Skill_WitchDead:
		{
			if (PlayerSkills_GetEventBool(eventId, L4D2SkillBool_Crown))
			{
				g_Round.players[index].crowns++;
				g_Round.survivorTotalCrowns++;
			}
		}
		case L4D2Skill_SmokerTongueCut:
		{
			g_Round.players[index].tongueCuts++;
			g_Round.survivorTotalTongueCuts++;
		}
		case L4D2Skill_SmokerSelfClear:
		{
			g_Round.players[index].smokerSelfClears++;
			g_Round.survivorTotalSmokerSelfClears++;
		}
		case L4D2Skill_ChargerInstaKill:
		{
			g_Round.players[index].instaKills++;
			g_Round.survivorTotalInstaKills++;
		}
	}
}
