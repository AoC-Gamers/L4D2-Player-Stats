#if defined _l4d2_player_stats_detect_included
	#endinput
#endif
#define _l4d2_player_stats_detect_included

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
	bool headshot = event.GetInt("hitgroup") == 1;

	if (damage <= 0 || !IsValidClient(attacker))
	{
		return;
	}

	if (IsValidInfected(attacker) && IsValidSurvivor(victim))
	{
		if (!Stats_IsTrackingEnabled() || !Stats_IsCompetitiveMode())
		{
			return;
		}

		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			return;
		}

		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));

		if (IsValidTank(attacker))
		{
			Detect_RecordTankHurt(attacker, victim, damage, weapon);
			return;
		}

		if (!Stats_ShouldCountVictimForDamage(victim, g_cvInfectedValidDamage))
		{
			return;
		}

		switch (L4D2_GetPlayerZombieClass(attacker))
		{
			case L4D2ZombieClass_Smoker:
			{
				g_Round.players[index].infectedGrab.smokerDamage += damage;
				g_Round.players[index].infectedGrab.totalDamage += damage;
				g_Round.totals.infectedTotalSmokerDamage += damage;
				g_Round.totals.infectedTotalGrabDamage += damage;
			}
			case L4D2ZombieClass_Hunter:
			{
				g_Round.players[index].infectedGrab.hunterDamage += damage;
				g_Round.players[index].infectedGrab.totalDamage += damage;
				g_Round.totals.infectedTotalHunterDamage += damage;
				g_Round.totals.infectedTotalGrabDamage += damage;
			}
			case L4D2ZombieClass_Jockey:
			{
				g_Round.players[index].infectedGrab.jockeyDamage += damage;
				g_Round.players[index].infectedGrab.totalDamage += damage;
				g_Round.totals.infectedTotalJockeyDamage += damage;
				g_Round.totals.infectedTotalGrabDamage += damage;
			}
			case L4D2ZombieClass_Charger:
			{
				g_Round.players[index].infectedGrab.chargerDamage += damage;
				g_Round.players[index].infectedGrab.totalDamage += damage;
				g_Round.totals.infectedTotalChargerDamage += damage;
				g_Round.totals.infectedTotalGrabDamage += damage;
			}
			case L4D2ZombieClass_Spitter:
			{
				g_Round.players[index].infectedSupport.spitterDamage += damage;
				g_Round.totals.infectedTotalSpitterDamage += damage;
			}
		}

		return;
	}

	if (IsValidSurvivor(attacker) && IsValidInfected(victim))
	{
		if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled())
		{
			return;
		}

		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			return;
		}

		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		PlayerStatsWeaponFamily family = Stats_GetWeaponFamily(weapon);
		PlayerStatsWeaponDetailType detail = Stats_GetWeaponDetailType(weapon);
		if (family == PlayerStatsWeaponFamily_None)
		{
			family = Stats_GetLastWeaponFamily(attacker);
		}
		if (detail == PlayerStatsWeaponDetail_None)
		{
			detail = Stats_GetLastWeaponDetail(attacker);
		}
		Stats_RecordAccuracyHit(index, family, headshot);
		Stats_RecordAccuracyDetailHit(index, detail, headshot);

		if (!Stats_IsTrackingEnabled())
		{
			return;
		}

		if (IsValidTank(victim))
		{
			Stats_RegisterTankVictim(victim);
			g_Round.players[index].combat.tankDamage += damage;
			g_Round.players[index].combat.tankHits++;
			g_Round.totals.survivorTotalTankDamage += damage;
		}
		else
		{
			Stats_AddSpecialDamageByClass(index, L4D2_GetPlayerZombieClass(victim), damage);
			g_Round.players[index].combat.siDamage += damage;
			g_Round.totals.survivorTotalSiDamage += damage;
		}

		return;
	}

	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim) && attacker != victim)
	{
		if (!Stats_IsTrackingEnabled())
		{
			return;
		}

		int index = Stats_EnsurePlayerRoundSlot(attacker);
		if (index == -1)
		{
			return;
		}

		g_Round.players[index].combat.ffGiven += damage;
		g_Round.totals.survivorTotalFF += damage;
	}
}

void Detect_EventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));

	if (IsValidSurvivor(victim) && IsValidTank(attacker))
	{
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		Detect_RecordTankSurvivorDeath(attacker, victim, weapon);
	}

	if (IsValidInfected(victim))
	{
		if (!IsValidSurvivor(attacker))
		{
			if (IsValidTank(victim))
			{
				Detect_OnTankKilled(victim);
			}
			return;
		}

		int attackerIndex = Stats_EnsurePlayerRoundSlot(attacker);
		if (attackerIndex == -1)
		{
			return;
		}

		L4D2ZombieClassType zombieClass = L4D2_GetPlayerZombieClass(victim);
		if (zombieClass == L4D2ZombieClass_Tank || !g_Runtime.hasPlayerSkills)
		{
			Stats_AddSpecialKillByClass(attackerIndex, zombieClass);
		}
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

	g_Round.players[index].survivability.deaths++;
	g_Round.totals.survivorTotalDeaths++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].survivability.deathBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].survivability.deathByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].survivability.deathByInfectedAI++;
		}
	}
}

void Detect_EventInfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. attacker_userid=%d round=%d",
			name,
			event.GetInt("attacker"),
			g_Round.meta.id);
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. attacker_userid=%d round=%d",
			name,
			event.GetInt("attacker"),
			g_Round.meta.id);
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because attacker did not resolve to a survivor. attacker_userid=%d client=%d round=%d",
			name,
			event.GetInt("attacker"),
			attacker,
			g_Round.meta.id);
		return;
	}

	int infectedType = event.GetInt("gender");
	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. attacker_userid=%d client=%d infected_type=%d round=%d",
			name,
			event.GetInt("attacker"),
			attacker,
			infectedType,
			g_Round.meta.id);
		return;
	}

	g_Round.players[index].combat.commonKills++;
	g_Round.totals.survivorTotalCommonKills++;

	if (g_Round.players[index].combat.commonKills <= 5
		|| g_Round.players[index].combat.commonKills % 25 == 0
		|| g_Round.totals.survivorTotalCommonKills <= 10
		|| g_Round.totals.survivorTotalCommonKills % 100 == 0)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Counted %s as common kill. attacker_userid=%d client=%d slot=%d infected_type=%d player_total=%d round_total=%d",
			name,
			event.GetInt("attacker"),
			attacker,
			index,
			infectedType,
			g_Round.players[index].combat.commonKills,
			g_Round.totals.survivorTotalCommonKills);
	}
}

void Detect_EventInfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled() && !Stats_IsThrowablesEnabled())
	{
		return;
	}

	int entity = event.GetInt("entityid");
	if (!IsWitchEntity(entity))
	{
		return;
	}

	Stats_RegisterWitchEntity(entity);

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int damage = event.GetInt("amount");
	bool headshot = event.GetInt("hitgroup") == 1;

	if (damage <= 0 || !IsValidSurvivor(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	PlayerStatsWeaponFamily family = Stats_GetWeaponFamily(weapon);
	PlayerStatsWeaponDetailType detail = Stats_GetWeaponDetailType(weapon);
	if (family == PlayerStatsWeaponFamily_None)
	{
		family = Stats_GetLastWeaponFamily(attacker);
	}
	if (detail == PlayerStatsWeaponDetail_None)
	{
		detail = Stats_GetLastWeaponDetail(attacker);
	}
	Stats_RecordAccuracyHit(index, family, headshot);
	Stats_RecordAccuracyDetailHit(index, detail, headshot);

	if (!Stats_IsTrackingEnabled())
	{
		return;
	}

	g_Round.players[index].combat.witchDamage += damage;
	g_Round.players[index].combat.witchHits++;
	g_Round.totals.survivorTotalWitchDamage += damage;
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

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].survivability.incaps++;
	g_Round.totals.survivorTotalIncaps++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].survivability.incapBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].survivability.incapByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].survivability.incapByInfectedAI++;
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

	if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled())
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

	PlayerStatsWeaponFamily family = Stats_GetWeaponFamily(weapon);
	PlayerStatsWeaponDetailType detail = Stats_GetWeaponDetailType(weapon);
	if (family == PlayerStatsWeaponFamily_None && detail != PlayerStatsWeaponDetail_None)
	{
		family = Stats_GetWeaponFamilyFromDetail(detail);
	}
	Stats_SetLastWeaponFamily(client, family);
	Stats_SetLastWeaponDetail(client, detail);
	Stats_RecordAccuracyShot(index, family);
	Stats_RecordAccuracyDetailShot(index, detail);

	if (!Stats_IsThrowablesEnabled())
	{
		return;
	}

	char normalized[64];
	if (strncmp(weapon, "weapon_", 7, false) == 0)
	{
		strcopy(normalized, sizeof(normalized), weapon);
	}
	else
	{
		Format(normalized, sizeof(normalized), "weapon_%s", weapon);
	}

	switch (WeaponNameToId(normalized))
	{
		case WEPID_MOLOTOV:
		{
			g_Round.players[index].resources.molotovsThrown++;
			g_Round.totals.survivorTotalMolotovsThrown++;
		}
		case WEPID_PIPE_BOMB:
		{
			g_Round.players[index].resources.pipebombsThrown++;
			g_Round.totals.survivorTotalPipebombsThrown++;
		}
		case WEPID_VOMITJAR:
		{
			g_Round.players[index].resources.vomitjarsThrown++;
			g_Round.totals.survivorTotalVomitjarsThrown++;
		}
	}
}

void Detect_EventPlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !Stats_IsCompetitiveMode())
	{
		return;
	}

	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(victim) || !IsValidTank(attacker))
	{
		return;
	}

	char weapon[64];
	event.GetString("weapon", weapon, sizeof(weapon));
	Detect_RecordTankIncap(attacker, victim, weapon);
}

void Detect_EventPlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive() || !Stats_IsThrowablesEnabled())
	{
		return;
	}

	if (event.GetBool("by_boomer"))
	{
		return;
	}

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].resources.playersBiled++;
	g_Round.totals.survivorTotalPlayersBiled++;
}

void Detect_EventVomitBombTank(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive() || !Stats_IsThrowablesEnabled())
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

	g_Round.players[index].resources.tanksBiled++;
	g_Round.totals.survivorTotalTanksBiled++;
}

void Detect_EventZombieIgnited(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive() || !Stats_IsThrowablesEnabled())
	{
		return;
	}

	if (event.GetBool("fire_ammo"))
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

	if (g_Round.players[index].resources.molotovsThrown <= 0)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no molotov throw is recorded for this survivor in the current half. userid=%d client=%d round=%d",
			name,
			event.GetInt("userid"),
			client,
			g_Round.meta.id);
		return;
	}

	g_Round.players[index].resources.zombiesIgnited++;
	g_Round.totals.survivorTotalZombiesIgnited++;
}

void Detect_EventPillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].resources.pillsUsed++;
	g_Round.totals.survivorTotalPillsUsed++;
}

void Detect_EventAdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].resources.adrenalineUsed++;
	g_Round.totals.survivorTotalAdrenalineUsed++;
}

void Detect_EventHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].resources.medkitsUsed++;
	g_Round.players[index].support.healsGiven++;
	g_Round.totals.survivorTotalMedkitsUsed++;
	g_Round.totals.survivorTotalHealsGiven++;

	if (IsValidSurvivor(subject))
	{
		int subjectIndex = Stats_EnsurePlayerRoundSlot(subject);
		if (subjectIndex != -1)
		{
			g_Round.players[subjectIndex].support.healsReceived++;
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

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].resources.defibsUsed++;
	g_Round.totals.survivorTotalDefibsUsed++;
}

void Detect_EventReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsRoundLive())
	{
		return;
	}

	if (!Stats_IsTrackingEnabled())
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
			g_Round.players[index].support.revivesGiven++;
			g_Round.totals.survivorTotalRevivesGiven++;
		}
	}

	if (IsValidSurvivor(subject))
	{
		int subjectIndex = Stats_EnsurePlayerRoundSlot(subject);
		if (subjectIndex != -1)
		{
			g_Round.players[subjectIndex].support.revivesReceived++;
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

	if (!Stats_IsTrackingEnabled())
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
			g_Round.players[rescuerIndex].support.rescuesGiven++;
			g_Round.totals.survivorTotalRescuesGiven++;
		}
	}

	if (IsValidSurvivor(victim))
	{
		int victimIndex = Stats_EnsurePlayerRoundSlot(victim);
		if (victimIndex != -1)
		{
			g_Round.players[victimIndex].support.rescuesReceived++;
		}
	}
}

void Detect_EventGascanPourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	int userid = event.GetInt("userid");

	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s outside scavenge mode. userid=%d base_mode=%d", name, userid, g_Round.meta.baseMode);
		return;
	}

	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because userid did not resolve to a survivor. userid=%d client=%d", name, userid, client);
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. userid=%d client=%d", name, userid, client);
		return;
	}

	g_Round.players[index].scavenge.gascansPoured++;
	g_Round.totals.survivorTotalGascansPoured++;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge gascan poured. round=%d scav_round=%d second_half=%d client=%d slot=%d player=%s poured=%d total=%d",
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf,
		client,
		index,
		g_Round.players[index].player.name,
		g_Round.players[index].scavenge.gascansPoured,
		g_Round.totals.survivorTotalGascansPoured);
}

void Detect_EventGascanDropped(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	int userid = event.GetInt("userid");

	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s outside scavenge mode. userid=%d base_mode=%d", name, userid, g_Round.meta.baseMode);
		return;
	}

	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because userid did not resolve to a survivor. userid=%d client=%d", name, userid, client);
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. userid=%d client=%d", name, userid, client);
		return;
	}

	g_Round.players[index].scavenge.gascansDropped++;
	g_Round.totals.survivorTotalGascansDropped++;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge gascan dropped. round=%d scav_round=%d second_half=%d client=%d slot=%d player=%s dropped=%d total=%d",
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf,
		client,
		index,
		g_Round.players[index].player.name,
		g_Round.players[index].scavenge.gascansDropped,
		g_Round.totals.survivorTotalGascansDropped);
}

void Detect_EventScavengeGascanDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	int userid = event.GetInt("userid");

	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. userid=%d round=%d", name, userid, g_Round.meta.id);
		return;
	}

	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s outside scavenge mode. userid=%d base_mode=%d", name, userid, g_Round.meta.baseMode);
		return;
	}

	int client = GetClientOfUserId(userid);
	if (!IsValidSurvivor(client))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because userid did not resolve to a survivor. userid=%d client=%d", name, userid, client);
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. userid=%d client=%d", name, userid, client);
		return;
	}

	g_Round.players[index].scavenge.gascansDestroyed++;
	g_Round.totals.survivorTotalGascansDestroyed++;
	Stats_Debug(PlayerStatsDebug_Core, "Scavenge gascan destroyed. round=%d scav_round=%d second_half=%d client=%d slot=%d player=%s destroyed=%d total=%d",
		g_Round.meta.id,
		g_Round.meta.scavengeRoundNumber,
		g_Round.meta.scavengeInSecondHalf,
		client,
		index,
		g_Round.players[index].player.name,
		g_Round.players[index].scavenge.gascansDestroyed,
		g_Round.totals.survivorTotalGascansDestroyed);
}

void Detect_OnGrabWithTonguePost(int victim, int attacker)
{
	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].pressure.tongueGrabs++;
	g_Round.players[index].infectedGrab.tongueGrabs++;
	g_Round.totals.infectedTotalTongueGrabs++;
}

void Detect_OnPouncedOnSurvivorPost(int victim, int attacker)
{
	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].pressure.hunterPouncesLanded++;
	g_Round.players[index].infectedGrab.hunterPounces++;
	g_Round.totals.infectedTotalHunterPouncesLanded++;
}

void Detect_OnJockeyRidePost(int victim, int attacker)
{
	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].pressure.jockeyRidesLanded++;
	g_Round.players[index].infectedGrab.jockeyRides++;
	g_Round.totals.infectedTotalJockeyRidesLanded++;
}

void Detect_OnVomitedUponPost(int victim, int attacker, bool boomerExplosion)
{
	if (boomerExplosion)
	{
		return;
	}

	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !IsValidSurvivor(victim) || !IsValidInfected(attacker))
	{
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(attacker);
	if (index == -1)
	{
		return;
	}

	g_Round.players[index].pressure.boomerVomitVictims++;
	g_Round.players[index].infectedSupport.boomerVomitVictims++;
	g_Round.totals.infectedTotalBoomerVomitVictims++;
}

Action Detect_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !Stats_IsCompetitiveMode())
	{
		return Plugin_Continue;
	}

	if (!IsValidSurvivor(victim) || !IsValidTank(attacker))
	{
		return Plugin_Continue;
	}

	int sessionIndex = Detect_FindActiveTankSessionIndex();
	if (sessionIndex == -1)
	{
		return Plugin_Continue;
	}

	int playerHealth = Stats_GetSurvivorCurrentHealthTotal(victim);
	if (damage >= float(playerHealth) && victim > 0 && victim < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim] = playerHealth;
	}

	return Plugin_Continue;
}

void Detect_OnClientDisconnect(int client)
{
	if (!Stats_IsCompetitiveMode() || client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	int sessionIndex = Detect_FindActiveTankSessionIndex();
	if (sessionIndex == -1)
	{
		return;
	}

	if (g_Round.tankSessions[sessionIndex].currentControllerClient != client)
	{
		return;
	}

	if (!IsFakeClient(client))
	{
		GetClientName(client, g_Round.tankSessions[sessionIndex].lastHumanName, sizeof(g_Round.tankSessions[sessionIndex].lastHumanName));
	}

	int controllerIndex = Detect_EnsureTankControllerIndex(sessionIndex, client);
	if (controllerIndex != -1 && g_Round.tankSessions[sessionIndex].controllers[controllerIndex].startedAt > 0.0 && g_Round.tankSessions[sessionIndex].controllers[controllerIndex].endedAt <= 0.0)
	{
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].endedAt = GetGameTime();
	}

	g_Round.tankSessions[sessionIndex].currentControllerClient = 0;
	g_Round.tankSessions[sessionIndex].endedAsBot = true;
}

void Detect_FinalizeActiveTankSessions()
{
	for (int sessionIndex = 0; sessionIndex < g_Round.tankSessionCount; sessionIndex++)
	{
		if (!g_Round.tankSessions[sessionIndex].active)
		{
			continue;
		}

		Detect_EndTankSession(sessionIndex);
	}
}

void Detect_EventTankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsTrackingEnabled() || !Stats_IsRoundLive() || !Stats_IsCompetitiveMode())
	{
		return;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	Detect_StartTankSession(client);
}

int Detect_FindActiveTankSessionIndex()
{
	for (int i = g_Round.tankSessionCount - 1; i >= 0; i--)
	{
		if (g_Round.tankSessions[i].active)
		{
			return i;
		}
	}

	return -1;
}

int Detect_StartTankSession(int client)
{
	int sessionIndex = Detect_FindActiveTankSessionIndex();
	if (sessionIndex != -1)
	{
		return sessionIndex;
	}

	if (g_Round.tankSessionCount >= L4D2_PLAYER_STATS_MAX_TANK_SESSIONS)
	{
		return -1;
	}

	sessionIndex = g_Round.tankSessionCount++;
	g_Round.tankSessions[sessionIndex].Reset();
	g_Round.tankSessions[sessionIndex].active = true;
	g_Round.tankSessions[sessionIndex].sessionId = sessionIndex + 1;
	g_Round.tankSessions[sessionIndex].startedAt = GetGameTime();
	Detect_SyncTankController(sessionIndex, client);
	return sessionIndex;
}

void Detect_EndTankSession(int sessionIndex)
{
	if (sessionIndex < 0 || sessionIndex >= g_Round.tankSessionCount || !g_Round.tankSessions[sessionIndex].active)
	{
		return;
	}

	if (g_Round.tankSessions[sessionIndex].endedAt <= 0.0)
	{
		g_Round.tankSessions[sessionIndex].endedAt = GetGameTime();
	}

	int controllerIndex = Detect_FindTankControllerIndex(sessionIndex, g_Round.tankSessions[sessionIndex].currentControllerClient);
	if (controllerIndex != -1 && g_Round.tankSessions[sessionIndex].controllers[controllerIndex].endedAt <= 0.0)
	{
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].endedAt = g_Round.tankSessions[sessionIndex].endedAt;
	}

	g_Round.tankSessions[sessionIndex].active = false;
	g_Round.tankSessions[sessionIndex].currentControllerClient = 0;
}

int Detect_FindTankControllerIndex(int sessionIndex, int client)
{
	if (sessionIndex < 0 || sessionIndex >= g_Round.tankSessionCount || client <= 0)
	{
		return -1;
	}

	char name[MAX_NAME_LENGTH];
	if (IsValidClient(client))
	{
		GetClientName(client, name, sizeof(name));
	}
	else
	{
		name[0] = '\0';
	}

	for (int i = 0; i < g_Round.tankSessions[sessionIndex].controllerCount; i++)
	{
		if (!g_Round.tankSessions[sessionIndex].controllers[i].active)
		{
			continue;
		}

		if (name[0] != '\0' && StrEqual(g_Round.tankSessions[sessionIndex].controllers[i].name, name, false))
		{
			return i;
		}
	}

	return -1;
}

int Detect_EnsureTankControllerIndex(int sessionIndex, int client)
{
	int controllerIndex = Detect_FindTankControllerIndex(sessionIndex, client);
	if (controllerIndex != -1)
	{
		return controllerIndex;
	}

	if (g_Round.tankSessions[sessionIndex].controllerCount >= L4D2_PLAYER_STATS_MAX_TANK_CONTROLLERS)
	{
		return -1;
	}

	controllerIndex = g_Round.tankSessions[sessionIndex].controllerCount++;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].Reset();
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].active = true;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].startedAt = GetGameTime();
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].bot = !IsValidClient(client) || IsFakeClient(client);
	Detect_GetTankControllerName(client, g_Round.tankSessions[sessionIndex].lastHumanName, g_Round.tankSessions[sessionIndex].controllers[controllerIndex].name, sizeof(g_Round.tankSessions[sessionIndex].controllers[controllerIndex].name));
	return controllerIndex;
}

void Detect_GetTankControllerName(int client, const char[] lastHumanName, char[] buffer, int maxlen)
{
	if (IsValidClient(client))
	{
		GetClientName(client, buffer, maxlen);
		return;
	}

	if (lastHumanName[0] != '\0')
	{
		strcopy(buffer, maxlen, lastHumanName);
		return;
	}

	strcopy(buffer, maxlen, "Tank");
}

void Detect_SyncTankController(int sessionIndex, int client)
{
	if (sessionIndex < 0 || sessionIndex >= g_Round.tankSessionCount)
	{
		return;
	}

	if (g_Round.tankSessions[sessionIndex].currentControllerClient == client && client > 0)
	{
		return;
	}

	int previousControllerIndex = Detect_FindTankControllerIndex(sessionIndex, g_Round.tankSessions[sessionIndex].currentControllerClient);
	if (previousControllerIndex != -1 && g_Round.tankSessions[sessionIndex].controllers[previousControllerIndex].endedAt <= 0.0)
	{
		g_Round.tankSessions[sessionIndex].controllers[previousControllerIndex].endedAt = GetGameTime();
	}

	if (IsValidClient(client) && !IsFakeClient(client))
	{
		GetClientName(client, g_Round.tankSessions[sessionIndex].lastHumanName, sizeof(g_Round.tankSessions[sessionIndex].lastHumanName));
	}

	g_Round.tankSessions[sessionIndex].currentControllerClient = client;
	Detect_EnsureTankControllerIndex(sessionIndex, client);
}

void Detect_RecordTankAttackCounts(int sessionIndex, int controllerIndex, const char[] weapon)
{
	if (sessionIndex < 0 || controllerIndex < 0)
	{
		return;
	}

	if (StrEqual(weapon, "tank_claw", false))
	{
		g_Round.tankSessions[sessionIndex].punches++;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].punches++;
	}
	else if (StrEqual(weapon, "tank_rock", false))
	{
		g_Round.tankSessions[sessionIndex].rocks++;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].rocks++;
	}
	else
	{
		g_Round.tankSessions[sessionIndex].hittables++;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].hittables++;
	}
}

void Detect_RecordTankHurt(int attacker, int victim, int damage, const char[] weapon)
{
	int sessionIndex = Detect_StartTankSession(attacker);
	if (sessionIndex == -1)
	{
		return;
	}

	Detect_SyncTankController(sessionIndex, attacker);
	int controllerIndex = Detect_EnsureTankControllerIndex(sessionIndex, attacker);
	if (controllerIndex == -1)
	{
		return;
	}

	if (victim > 0
		&& victim < L4D2_PLAYER_STATS_MAX_PLAYERS
		&& g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim] > 0)
	{
		return;
	}

	Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, weapon);

	if (!Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage))
	{
		return;
	}

	g_Round.tankSessions[sessionIndex].totalDamage += damage;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += damage;
}

void Detect_RecordTankIncap(int attacker, int victim, const char[] weapon)
{
	int sessionIndex = Detect_StartTankSession(attacker);
	if (sessionIndex == -1)
	{
		return;
	}

	Detect_SyncTankController(sessionIndex, attacker);
	int controllerIndex = Detect_EnsureTankControllerIndex(sessionIndex, attacker);
	if (controllerIndex == -1)
	{
		return;
	}

	Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, weapon);

	g_Round.tankSessions[sessionIndex].incaps++;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].incaps++;

	if (Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage) && victim > 0 && victim < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		int lastHealth = g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim];
		if (lastHealth > 0)
		{
			g_Round.tankSessions[sessionIndex].totalDamage += lastHealth;
			g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += lastHealth;
			g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim] = 0;
		}
	}
}

bool Detect_IsSurvivorTeamWiped()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		if (IsPlayerAlive(client))
		{
			return false;
		}
	}

	return true;
}

void Detect_RecordTankSurvivorDeath(int attacker, int victim, const char[] weapon)
{
	int sessionIndex = Detect_FindActiveTankSessionIndex();
	if (sessionIndex == -1)
	{
		sessionIndex = Detect_StartTankSession(attacker);
	}
	if (sessionIndex == -1)
	{
		return;
	}

	Detect_SyncTankController(sessionIndex, attacker);
	int controllerIndex = Detect_EnsureTankControllerIndex(sessionIndex, attacker);
	if (controllerIndex == -1)
	{
		return;
	}

	if (victim > 0
		&& victim < L4D2_PLAYER_STATS_MAX_PLAYERS
		&& g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim] > 0)
	{
		Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, weapon);

		if (Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage))
		{
			int lastHealth = g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim];
			g_Round.tankSessions[sessionIndex].totalDamage += lastHealth;
			g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += lastHealth;
		}

		g_Round.tankSessions[sessionIndex].lastHealthByVictim[victim] = 0;
	}

	g_Round.tankSessions[sessionIndex].deaths++;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].deaths++;

	if (Detect_IsSurvivorTeamWiped())
	{
		g_Round.tankSessions[sessionIndex].wipe = true;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].wipe = true;
	}
}

void Detect_OnTankKilled(int victim)
{
	int sessionIndex = Detect_FindActiveTankSessionIndex();
	if (sessionIndex == -1)
	{
		return;
	}

	if (!IsFakeClient(victim))
	{
		GetClientName(victim, g_Round.tankSessions[sessionIndex].lastHumanName, sizeof(g_Round.tankSessions[sessionIndex].lastHumanName));
	}

	Detect_EndTankSession(sessionIndex);
}

void Detect_GetPlayerSkillsKillTypeName(L4D2ApiKillType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2ApiKill_SmokerKill: strcopy(buffer, maxlen, "SmokerKill");
		case L4D2ApiKill_BoomerKill: strcopy(buffer, maxlen, "BoomerKill");
		case L4D2ApiKill_HunterKill: strcopy(buffer, maxlen, "HunterKill");
		case L4D2ApiKill_SpitterKill: strcopy(buffer, maxlen, "SpitterKill");
		case L4D2ApiKill_JockeyKill: strcopy(buffer, maxlen, "JockeyKill");
		case L4D2ApiKill_ChargerKill: strcopy(buffer, maxlen, "ChargerKill");
		default: strcopy(buffer, maxlen, "None");
	}
}

void Detect_GetPlayerSkillsBossTypeName(L4D2BossType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case L4D2Boss_Tank: strcopy(buffer, maxlen, "Tank");
		case L4D2Boss_Witch: strcopy(buffer, maxlen, "Witch");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

int Detect_GetPlayerSkillsEventActorClient(int eventId, bool bossEvent)
{
	Handle kv = CreateKeyValues("player_skills_event");
	if (kv == INVALID_HANDLE)
	{
		return 0;
	}

	bool ok = bossEvent
		? PlayerSkills_FillBossEventKeyValues(eventId, kv)
		: PlayerSkills_FillSkillEventKeyValues(eventId, kv);

	if (!ok)
	{
		delete kv;
		return 0;
	}

	char rootKey[16];
	strcopy(rootKey, sizeof(rootKey), bossEvent ? "boss_event" : "skill_event");

	KvRewind(kv);
	if (!KvJumpToKey(kv, rootKey, false))
	{
		delete kv;
		return 0;
	}

	int userid = KvGetNum(kv, "actor_userid", 0);
	delete kv;
	return userid > 0 ? GetClientOfUserId(userid) : 0;
}

L4D2ZombieClassType Detect_GetZombieClassForPlayerSkillsKillType(L4D2ApiKillType type)
{
	switch (type)
	{
		case L4D2ApiKill_SmokerKill:
		{
			return L4D2ZombieClass_Smoker;
		}
		case L4D2ApiKill_BoomerKill:
		{
			return L4D2ZombieClass_Boomer;
		}
		case L4D2ApiKill_HunterKill:
		{
			return L4D2ZombieClass_Hunter;
		}
		case L4D2ApiKill_SpitterKill:
		{
			return L4D2ZombieClass_Spitter;
		}
		case L4D2ApiKill_JockeyKill:
		{
			return L4D2ZombieClass_Jockey;
		}
		case L4D2ApiKill_ChargerKill:
		{
			return L4D2ZombieClass_Charger;
		}
	}

	return L4D2ZombieClass_NotInfected;
}

L4D2ApiKillType Detect_GetPlayerSkillsSuppressedKillTypeFromSkillEvent(Handle kv)
{
	if (!KvJumpToKey(kv, "properties", false))
	{
		return L4D2ApiKill_None;
	}

	L4D2ApiKillType killType = L4D2ApiKill_None;
	if (KvGetNum(kv, "implies_si_death", 0) > 0)
	{
		killType = view_as<L4D2ApiKillType>(KvGetNum(kv, "suppressed_kill_type_id", 0));
	}

	KvGoBack(kv);
	return killType;
}

void Detect_ConsumePlayerSkillsKillAssists(Handle kv, int actorUserid, L4D2ZombieClassType zombieClass, int &assistCount, int &assistDamage)
{
	assistCount = 0;
	assistDamage = 0;

	if (zombieClass == L4D2ZombieClass_NotInfected || !KvJumpToKey(kv, "assists", false) || !KvGotoFirstSubKey(kv, false))
	{
		return;
	}

	do
	{
		int assistUserid = KvGetNum(kv, "userid", 0);
		if (assistUserid <= 0 || assistUserid == actorUserid)
		{
			continue;
		}

		int assistClient = GetClientOfUserId(assistUserid);
		if (!IsValidSurvivor(assistClient))
		{
			continue;
		}

		int index = Stats_EnsurePlayerRoundSlot(assistClient);
		if (index == -1)
		{
			continue;
		}

		int damage = KvGetNum(kv, "damage", 0);
		Stats_AddSpecialKillAssistByClass(index, zombieClass);
		Stats_AddSpecialAssistDamageByClass(index, zombieClass, damage);
		assistCount++;
		assistDamage += damage;
	}
	while (KvGotoNextKey(kv, false));
}

void Detect_OnPlayerKillDetected(int eventId, L4D2ApiKillType type)
{
	if (!Stats_IsTrackingEnabled() || !g_Runtime.hasPlayerSkills || !Stats_IsRoundLive() || !PlayerSkills_IsKillEventValid(eventId))
	{
		if (Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
		{
			Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event. event=%d type=%d tracking=%d has_skills=%d live=%d valid=%d",
				eventId,
				type,
				Stats_IsTrackingEnabled(),
				g_Runtime.hasPlayerSkills,
				Stats_IsRoundLive(),
				PlayerSkills_IsKillEventValid(eventId));
		}
		return;
	}

	Handle kv = CreateKeyValues("player_skills_kill_event");
	if (kv == INVALID_HANDLE)
	{
		return;
	}

	if (!PlayerSkills_FillKillEventKeyValues(eventId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because FillKillEventKeyValues failed. event=%d type=%d",
			eventId,
			type);
		delete kv;
		return;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "kill_event", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because kill_event root is missing. event=%d type=%d",
			eventId,
			type);
		delete kv;
		return;
	}

	int actorUserid = KvGetNum(kv, "actor_userid", 0);
	int actor = actorUserid > 0 ? GetClientOfUserId(actorUserid) : 0;
	if (!IsValidSurvivor(actor))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because actor did not resolve to a survivor. event=%d type=%d actor_userid=%d client=%d",
			eventId,
			type,
			actorUserid,
			actor);
		delete kv;
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills kill_event because no round slot could be assigned. event=%d type=%d actor_userid=%d client=%d",
			eventId,
			type,
			actorUserid,
			actor);
		delete kv;
		return;
	}

	L4D2ZombieClassType zombieClass = Detect_GetZombieClassForPlayerSkillsKillType(type);
	int assistCount = 0;
	int assistDamage = 0;
	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
		case L4D2ZombieClass_Boomer:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
		case L4D2ZombieClass_Hunter:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
		case L4D2ZombieClass_Spitter:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
		case L4D2ZombieClass_Jockey:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
		case L4D2ZombieClass_Charger:
		{
			Stats_AddSpecialKillByClass(index, zombieClass);
		}
	}

	Detect_ConsumePlayerSkillsKillAssists(kv, actorUserid, zombieClass, assistCount, assistDamage);
	char killTypeName[32];
	Detect_GetPlayerSkillsKillTypeName(type, killTypeName, sizeof(killTypeName));
	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills kill_event credited. event=%d type=%s actor_userid=%d client=%d slot=%d assists=%d assist_damage=%d",
		eventId,
		killTypeName,
		actorUserid,
		actor,
		index,
		assistCount,
		assistDamage);
	delete kv;
}

void Detect_OnPlayerSkillDetected(int eventId, L4D2ApiSkillType type)
{
	if (type == L4D2ApiSkill_None)
	{
		return;
	}

	if (!Stats_IsTrackingEnabled() || !g_Runtime.hasPlayerSkills || !Stats_IsRoundLive() || !PlayerSkills_IsSkillEventValid(eventId))
	{
		if (Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
		{
			Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event. event=%d type=%d tracking=%d has_skills=%d live=%d valid=%d",
				eventId,
				type,
				Stats_IsTrackingEnabled(),
				g_Runtime.hasPlayerSkills,
				Stats_IsRoundLive(),
				PlayerSkills_IsSkillEventValid(eventId));
		}
		return;
	}

	Handle kv = CreateKeyValues("player_skills_skill_event");
	if (kv == INVALID_HANDLE)
	{
		return;
	}

	if (!PlayerSkills_FillSkillEventKeyValues(eventId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because FillSkillEventKeyValues failed. event=%d type=%d",
			eventId,
			type);
		delete kv;
		return;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "skill_event", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because skill_event root is missing. event=%d type=%d",
			eventId,
			type);
		delete kv;
		return;
	}

	int actorUserid = KvGetNum(kv, "actor_userid", 0);
	int actor = actorUserid > 0 ? GetClientOfUserId(actorUserid) : 0;
	if (!IsValidSurvivor(actor))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because actor did not resolve to a survivor. event=%d type=%d actor_userid=%d client=%d",
			eventId,
			type,
			actorUserid,
			actor);
		delete kv;
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills skill_event because no round slot could be assigned. event=%d type=%d actor_userid=%d client=%d",
			eventId,
			type,
			actorUserid,
			actor);
		delete kv;
		return;
	}

	L4D2ApiKillType suppressedKillType = Detect_GetPlayerSkillsSuppressedKillTypeFromSkillEvent(kv);
	L4D2ZombieClassType zombieClass = Detect_GetZombieClassForPlayerSkillsKillType(suppressedKillType);
	if (zombieClass != L4D2ZombieClass_NotInfected)
	{
		Stats_AddSpecialKillByClass(index, zombieClass);
		int assistCount = 0;
		int assistDamage = 0;
		Detect_ConsumePlayerSkillsKillAssists(kv, actorUserid, zombieClass, assistCount, assistDamage);
		char killTypeName[32];
		Detect_GetPlayerSkillsKillTypeName(suppressedKillType, killTypeName, sizeof(killTypeName));
		Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills skill_event implied SI death. event=%d skill_type=%d kill_type=%s actor_userid=%d client=%d slot=%d assists=%d assist_damage=%d",
			eventId,
			type,
			killTypeName,
			actorUserid,
			actor,
			index,
			assistCount,
			assistDamage);
	}
	else
	{
		Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills skill_event did not imply SI death. event=%d skill_type=%d actor_userid=%d client=%d",
			eventId,
			type,
			actorUserid,
			actor);
	}

	delete kv;
}

void Detect_OnPlayerBossEventDetected(int eventId, L4D2ApiBossEventType type)
{
	if (!Stats_IsTrackingEnabled() || !g_Runtime.hasPlayerSkills || !Stats_IsRoundLive() || !PlayerSkills_IsBossEventValid(eventId))
	{
		if (Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
		{
			Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event. event=%d type=%d tracking=%d has_skills=%d live=%d valid=%d",
				eventId,
				type,
				Stats_IsTrackingEnabled(),
				g_Runtime.hasPlayerSkills,
				Stats_IsRoundLive(),
				PlayerSkills_IsBossEventValid(eventId));
		}
		return;
	}

	int actor = Detect_GetPlayerSkillsEventActorClient(eventId, true);
	if (!IsValidSurvivor(actor))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because actor did not resolve to a survivor. event=%d type=%d",
			eventId,
			type);
		return;
	}

	int index = Stats_EnsurePlayerRoundSlot(actor);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_event because no round slot could be assigned. event=%d type=%d client=%d",
			eventId,
			type,
			actor);
		return;
	}

	switch (type)
	{
		case L4D2ApiBossEvent_WitchCrown:
		{
			Stats_AddWitchKill(index);
		}
		case L4D2ApiBossEvent_WitchDead:
		{
			Stats_AddWitchKill(index);
		}
	}

	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills boss_event credited. event=%d type=%d client=%d slot=%d witch_kills=%d",
		eventId,
		type,
		actor,
		index,
		g_Round.players[index].combat.witchKills);
}

void Detect_ConsumePlayerSkillsBossSessionDamageEntries(Handle kv, L4D2BossType type, int &entryCount, int &totalDamage, int &totalShots)
{
	entryCount = 0;
	totalDamage = 0;
	totalShots = 0;

	if (!KvJumpToKey(kv, "damage_entries", false) || !KvGotoFirstSubKey(kv, false))
	{
		return;
	}

	do
	{
		int userid = KvGetNum(kv, "userid", 0);
		int client = userid > 0 ? GetClientOfUserId(userid) : 0;
		if (!IsValidSurvivor(client))
		{
			continue;
		}

		int index = Stats_EnsurePlayerRoundSlot(client);
		if (index == -1)
		{
			continue;
		}

		int damage = KvGetNum(kv, "damage", 0);
		int shots = KvGetNum(kv, "shots", 0);
		entryCount++;
		totalDamage += damage;
		totalShots += shots;
		switch (type)
		{
			case L4D2Boss_Tank:
			{
				g_Round.players[index].bossDetail.tankDamage += damage;
				g_Round.players[index].bossDetail.tankShots += shots;
			}
			case L4D2Boss_Witch:
			{
				g_Round.players[index].bossDetail.witchDamage += damage;
				g_Round.players[index].bossDetail.witchShots += shots;
			}
		}
	}
	while (KvGotoNextKey(kv, false));
}

void Detect_OnPlayerBossSessionFinalized(int sessionId, L4D2BossType type)
{
	if (!Stats_IsTrackingEnabled() || !g_Runtime.hasPlayerSkills || !Stats_IsRoundLive() || !PlayerSkills_IsBossSessionValid(sessionId))
	{
		if (Stats_IsDebugEnabled(PlayerStatsDebug_Detect))
		{
			Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session. session=%d type=%d tracking=%d has_skills=%d live=%d valid=%d",
				sessionId,
				type,
				Stats_IsTrackingEnabled(),
				g_Runtime.hasPlayerSkills,
				Stats_IsRoundLive(),
				PlayerSkills_IsBossSessionValid(sessionId));
		}
		return;
	}

	Handle kv = CreateKeyValues("player_skills_boss_session");
	if (kv == INVALID_HANDLE)
	{
		return;
	}

	if (!PlayerSkills_FillBossSessionKeyValues(sessionId, kv))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session because FillBossSessionKeyValues failed. session=%d type=%d",
			sessionId,
			type);
		delete kv;
		return;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "boss_session", false))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring PlayerSkills boss_session because boss_session root is missing. session=%d type=%d",
			sessionId,
			type);
		delete kv;
		return;
	}

	int entryCount = 0;
	int totalDamage = 0;
	int totalShots = 0;
	Detect_ConsumePlayerSkillsBossSessionDamageEntries(kv, type, entryCount, totalDamage, totalShots);
	char bossTypeName[16];
	Detect_GetPlayerSkillsBossTypeName(type, bossTypeName, sizeof(bossTypeName));
	Stats_Debug(PlayerStatsDebug_Detect, "PlayerSkills boss_session credited. session=%d type=%s entries=%d damage=%d shots=%d",
		sessionId,
		bossTypeName,
		entryCount,
		totalDamage,
		totalShots);
	delete kv;
}
