#if defined _l4d2_player_stats_modules_tank_included
	#endinput
#endif
#define _l4d2_player_stats_modules_tank_included

void Detect_OnClientDisconnect(int client)
{
	Damage_AdvanceTankVictimLife(client, GetClientUserId(client), "client_disconnect");
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
	Damage_InvalidateTankOperationsForSession(sessionIndex, "session_closed");

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
	int previousControllerClient = g_Round.tankSessions[sessionIndex].currentControllerClient;
	if (previousControllerClient > 0)
	{
		Damage_InvalidateTankOperationsForClient(previousControllerClient, "controller_changed");
	}
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

void Detect_RecordTankHurt(const StatsPlayerHurtObservation observation, StatsTraceContext traceContext)
{
	int attacker = observation.attackerClient;
	int victim = observation.victimClient;
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

	int operationIndex = -1;
	int damageId = 0;
	PlayerStatsTankDamageResolveResult resolve = Damage_ResolveTankTerminal(victim, observation.victimUserid, attacker, observation.attackerUserid, traceContext, operationIndex, damageId);
	Trace_TankDamageResolution(traceContext, "player_hurt", resolve, damageId);
	if (resolve == PlayerStatsTankDamageResolve_AlreadyApplied)
	{
		return;
	}
	if (resolve == PlayerStatsTankDamageResolve_Ambiguous || resolve == PlayerStatsTankDamageResolve_Stale)
	{
		Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, observation.weapon);
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=%s route=player_hurt victim=%d/%d attacker=%d/%d tick=%d",
			resolve == PlayerStatsTankDamageResolve_Ambiguous ? "ambiguous_terminal" : "stale_terminal",
			victim,
			observation.victimUserid,
			attacker,
			observation.attackerUserid,
			GetGameTickCount());
		return;
	}

	int damage = observation.damage;
	if (resolve == PlayerStatsTankDamageResolve_Ready)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[operationIndex];
		sessionIndex = operation.sessionIndex;
		controllerIndex = operation.controllerIndex;
		damage = operation.healthBefore;
	}

	Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, observation.weapon);

	bool damageCounted = Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage);
	if (!damageCounted)
	{
		Damage_RecordTankHurtReceipt(observation, sessionIndex, controllerIndex, false, 0, traceContext);
		return;
	}

	g_Round.tankSessions[sessionIndex].totalDamage += damage;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += damage;
	Damage_RecordTankHurtReceipt(observation, sessionIndex, controllerIndex, true, damage, traceContext);
}

void Detect_RecordTankIncap(int attacker, int victim, int attackerUserid, int victimUserid, const char[] weapon, StatsTraceContext traceContext)
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

	int operationIndex = -1;
	int damageId = 0;
	PlayerStatsTankDamageResolveResult resolve = Damage_ResolveTankTerminal(victim, victimUserid, attacker, attackerUserid, traceContext, operationIndex, damageId);
	Trace_TankDamageResolution(traceContext, "player_incapacitated_start", resolve, damageId);
	if (resolve == PlayerStatsTankDamageResolve_AlreadyApplied)
	{
		g_Round.tankSessions[sessionIndex].incaps++;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].incaps++;
		return;
	}

	Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, weapon);

	g_Round.tankSessions[sessionIndex].incaps++;
	g_Round.tankSessions[sessionIndex].controllers[controllerIndex].incaps++;

	if (resolve == PlayerStatsTankDamageResolve_Ready)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[operationIndex];
		sessionIndex = operation.sessionIndex;
		controllerIndex = operation.controllerIndex;
		if (Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage))
		{
			g_Round.tankSessions[sessionIndex].totalDamage += operation.healthBefore;
			g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += operation.healthBefore;
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

void Detect_RecordTankSurvivorDeath(int attacker, int victim, int attackerUserid, int victimUserid, const char[] weapon, StatsTraceContext traceContext)
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

	int operationIndex = -1;
	int damageId = 0;
	PlayerStatsTankDamageResolveResult resolve = Damage_ResolveTankTerminal(victim, victimUserid, attacker, attackerUserid, traceContext, operationIndex, damageId);
	Trace_TankDamageResolution(traceContext, "player_death", resolve, damageId);
	if (resolve == PlayerStatsTankDamageResolve_Ready)
	{
		Detect_RecordTankAttackCounts(sessionIndex, controllerIndex, weapon);

		if (Stats_ShouldCountVictimForDamage(victim, g_cvTankValidDamage))
		{
			PlayerStatsTankDamageOperation operation;
			operation = g_Round.tankDamageOperations[operationIndex];
			sessionIndex = operation.sessionIndex;
			controllerIndex = operation.controllerIndex;
			g_Round.tankSessions[sessionIndex].totalDamage += operation.healthBefore;
			g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += operation.healthBefore;
		}
	}
	else if (resolve == PlayerStatsTankDamageResolve_AlreadyApplied)
	{
		// A same-tick hurt or incapacitation already applied this Tank impact.
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
