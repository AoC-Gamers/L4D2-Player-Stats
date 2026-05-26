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
		return;
	}

	if (!Stats_IsTrackingEnabled())
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

	g_Round.players[index].combat.commonKills++;
	g_Round.totals.survivorTotalCommonKills++;
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
	g_Round.totals.infectedTotalBoomerVomitVictims++;
}

void Detect_OnPlayerSkillDetected(int eventId, L4D2SkillType type)
{
	if (!Stats_IsTrackingEnabled() || !g_Runtime.hasPlayerSkills || !Stats_IsRoundLive() || !PlayerSkills_IsEventValid(eventId))
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

	if (!Stats_IsSkillTypeEnabledForRound(type))
	{
		return;
	}

	switch (type)
	{
		case L4D2Skill_HunterSkeet:
		{
			g_Round.players[index].skills.skeets++;
			g_Round.totals.survivorTotalSkeets++;
		}
		case L4D2Skill_HunterSkeetMelee:
		{
			g_Round.players[index].skills.skeetMelees++;
			g_Round.totals.survivorTotalSkeetMelees++;
		}
		case L4D2Skill_HunterDeadstop:
		{
			g_Round.players[index].skills.deadstops++;
			g_Round.totals.survivorTotalDeadstops++;
		}
		case L4D2Skill_BoomerPop:
		{
			g_Round.players[index].skills.boomerPops++;
			g_Round.totals.survivorTotalBoomerPops++;
		}
		case L4D2Skill_ChargerLevel:
		{
			g_Round.players[index].skills.levels++;
			g_Round.totals.survivorTotalLevels++;
		}
		case L4D2Skill_WitchDead:
		{
			if (PlayerSkills_GetEventBool(eventId, L4D2SkillBool_Crown))
			{
				g_Round.players[index].skills.crowns++;
				g_Round.totals.survivorTotalCrowns++;
			}
		}
		case L4D2Skill_SmokerTongueCut:
		{
			g_Round.players[index].skills.tongueCuts++;
			g_Round.totals.survivorTotalTongueCuts++;
		}
		case L4D2Skill_SmokerSelfClear:
		{
			g_Round.players[index].skills.smokerSelfClears++;
			g_Round.totals.survivorTotalSmokerSelfClears++;
		}
		case L4D2Skill_ChargerInstaKill:
		{
			g_Round.players[index].skills.instaKills++;
			g_Round.totals.survivorTotalInstaKills++;
		}
	}
}
