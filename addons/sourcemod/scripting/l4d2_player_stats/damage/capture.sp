#if defined _l4d2_player_stats_damage_capture_included
	#endinput
#endif
#define _l4d2_player_stats_damage_capture_included

void Damage_AdvanceTankVictimLife(int client, int userid, const char[] reason)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	if (userid > 0 && g_Runtime.tankLifeUseridByClient[client] != userid)
	{
		g_Runtime.tankLifeEpochByClient[client]++;
		g_Runtime.tankLifeUseridByClient[client] = userid;
	}
	else if (userid > 0)
	{
		g_Runtime.tankLifeEpochByClient[client]++;
	}

	Damage_InvalidateTankOperationsForClient(client, reason);
}

void Damage_InvalidateTankOperationsForClient(int client, const char[] reason)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[i];
		if (operation.state == PlayerStatsTankDamageOperation_Empty
			|| (operation.victimClient != client && operation.attackerClient != client))
		{
			continue;
		}

		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=%s op=%d round=%d victim=%d/%d attacker=%d/%d",
			reason,
			i,
			operation.roundId,
			operation.victimClient,
			operation.victimUserid,
			operation.attackerClient,
			operation.attackerUserid);
		g_Round.tankDamageOperations[i].Reset();
	}
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_PLAYERS; i++)
	{
		PlayerStatsTankHurtReceipt receipt;
		receipt = g_Round.tankHurtReceipts[i];
		if (receipt.state != PlayerStatsTankHurtReceipt_Empty && (receipt.victimClient == client || receipt.attackerClient == client))
		{
			Stats_Debug(PlayerStatsDebug_Detect,
				"tank_hurt_receipt discarded reason=%s victim=%d/%d attacker=%d/%d",
				reason,
				receipt.victimClient,
				receipt.victimUserid,
				receipt.attackerClient,
				receipt.attackerUserid);
			g_Round.tankHurtReceipts[i].Reset();
		}
	}
}

void Damage_InvalidateTankOperationsForSession(int sessionIndex, const char[] reason)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[i];
		if (operation.state == PlayerStatsTankDamageOperation_Empty || operation.sessionIndex != sessionIndex)
		{
			continue;
		}

		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=%s op=%d round=%d session=%d victim=%d/%d attacker=%d/%d",
			reason,
			i,
			operation.roundId,
			sessionIndex,
			operation.victimClient,
			operation.victimUserid,
			operation.attackerClient,
			operation.attackerUserid);
		g_Round.tankDamageOperations[i].Reset();
	}
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_PLAYERS; i++)
	{
		if (g_Round.tankHurtReceipts[i].state != PlayerStatsTankHurtReceipt_Empty
			&& g_Round.tankHurtReceipts[i].sessionIndex == sessionIndex)
		{
			g_Round.tankHurtReceipts[i].Reset();
		}
	}
}

void Damage_FinalizeTankOperationsForRoundClose(int roundId, int mapGeneration, int &resolved, int &discarded)
{
	resolved = 0;
	discarded = 0;
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[i];
		if (operation.state == PlayerStatsTankDamageOperation_Empty)
		{
			continue;
		}

		if (operation.state == PlayerStatsTankDamageOperation_Applied
			&& operation.runId == g_Trace.runId && operation.roundId == roundId && operation.mapGeneration == mapGeneration)
		{
			resolved++;
		}
		else
		{
			discarded++;
			Stats_Debug(PlayerStatsDebug_Detect,
				"tank_damage_operation discarded reason=%s op=%d saved_round=%d closing_round=%d saved_mapgen=%d closing_mapgen=%d tick=%d",
				operation.runId != g_Trace.runId || operation.roundId != roundId || operation.mapGeneration != mapGeneration ? "closing_context_mismatch" : "closing_without_terminal_evidence",
				i,
				operation.roundId,
				roundId,
				operation.mapGeneration,
				mapGeneration,
				operation.tick);
		}
		g_Round.tankDamageOperations[i].Reset();
	}
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_PLAYERS; i++)
	{
		g_Round.tankHurtReceipts[i].Reset();
	}
}

void Damage_RecordTankHurtReceipt(const StatsPlayerHurtObservation observation, int sessionIndex, int controllerIndex, bool damageCounted, int damageApplied, StatsTraceContext traceContext)
{
	int victim = observation.victimClient;
	if (victim <= 0 || victim >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	int tick = GetGameTickCount();
	PlayerStatsTankHurtReceipt receipt;
	receipt = g_Round.tankHurtReceipts[victim];
	if (receipt.state != PlayerStatsTankHurtReceipt_Empty && receipt.tick == tick)
	{
		g_Round.tankHurtReceipts[victim].state = PlayerStatsTankHurtReceipt_Ambiguous;
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_hurt_receipt discarded reason=multiple_hurts_same_tick round=%d tick=%d victim=%d/%d prior_attacker=%d/%d attacker=%d/%d",
			traceContext.roundId,
			tick,
			victim,
			observation.victimUserid,
			receipt.attackerClient,
			receipt.attackerUserid,
			observation.attackerClient,
			observation.attackerUserid);
		return;
	}

	g_Round.tankHurtReceipts[victim].Reset();
	g_Round.tankHurtReceipts[victim].state = PlayerStatsTankHurtReceipt_Recorded;
	g_Round.tankHurtReceipts[victim].runId = traceContext.runId;
	g_Round.tankHurtReceipts[victim].mapGeneration = traceContext.mapGeneration;
	g_Round.tankHurtReceipts[victim].roundId = traceContext.roundId;
	g_Round.tankHurtReceipts[victim].tick = tick;
	g_Round.tankHurtReceipts[victim].victimClient = victim;
	g_Round.tankHurtReceipts[victim].victimUserid = observation.victimUserid;
	g_Round.tankHurtReceipts[victim].attackerClient = observation.attackerClient;
	g_Round.tankHurtReceipts[victim].attackerUserid = observation.attackerUserid;
	g_Round.tankHurtReceipts[victim].sessionIndex = sessionIndex;
	g_Round.tankHurtReceipts[victim].sessionId = g_Round.tankSessions[sessionIndex].sessionId;
	g_Round.tankHurtReceipts[victim].controllerIndex = controllerIndex;
	g_Round.tankHurtReceipts[victim].damageApplied = damageApplied;
	g_Round.tankHurtReceipts[victim].damageCounted = damageCounted;
}

int Damage_StoreTankOperation(const StatsSdkDamageObservation observation, int victim, int victimUserid, int attacker, int attackerUserid, int sessionIndex, int controllerIndex, int healthBefore, PlayerStatsTankDamageOperationState state)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		if (g_Round.tankDamageOperations[i].state != PlayerStatsTankDamageOperation_Empty)
		{
			continue;
		}

		PlayerStatsTankDamageOperation operation;
		operation.Reset();
		operation.state = state;
		operation.runId = observation.context.runId;
		operation.mapGeneration = observation.context.mapGeneration;
		operation.roundId = observation.context.roundId;
		operation.signalId = observation.context.signalId;
		operation.damageId = Trace_NextDamageId();
		operation.tick = GetGameTickCount();
		operation.victimClient = victim;
		operation.victimUserid = victimUserid;
		operation.victimLifeEpoch = g_Runtime.tankLifeEpochByClient[victim];
		operation.attackerClient = attacker;
		operation.attackerUserid = attackerUserid;
		operation.sessionIndex = sessionIndex;
		operation.sessionId = g_Round.tankSessions[sessionIndex].sessionId;
		operation.controllerIndex = controllerIndex;
		operation.healthBefore = healthBefore;
		g_Round.tankDamageOperations[i] = operation;
		return i;
	}

	return -1;
}

bool Damage_ReconcileRecentTankHurt(const StatsSdkDamageObservation observation, int healthBefore, int sessionIndex, int controllerIndex, StatsSdkDamageCaptureResult captureResult)
{
	int victim = observation.victimClient;
	int attacker = observation.attackerClient;
	if (victim <= 0 || victim >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return false;
	}

	PlayerStatsTankHurtReceipt receipt;
	receipt = g_Round.tankHurtReceipts[victim];
	if (receipt.state == PlayerStatsTankHurtReceipt_Empty || receipt.tick != GetGameTickCount()
		|| receipt.victimUserid != GetClientUserId(victim) || receipt.attackerClient != attacker
		|| receipt.attackerUserid != GetClientUserId(attacker))
	{
		return false;
	}

	if (receipt.state == PlayerStatsTankHurtReceipt_Ambiguous)
	{
		int operationIndex = Damage_StoreTankOperation(observation, victim, receipt.victimUserid, attacker, receipt.attackerUserid, sessionIndex, controllerIndex, healthBefore, PlayerStatsTankDamageOperation_Applied);
		captureResult.status = StatsSdkDamageCapture_AmbiguousReceipt;
		captureResult.operationIndex = operationIndex;
		captureResult.healthBefore = healthBefore;
		captureResult.hasHealthBefore = true;
		if (operationIndex >= 0)
		{
			captureResult.operationState = view_as<StatsSdkDamageOperationState>(g_Round.tankDamageOperations[operationIndex].state);
			captureResult.damageId = g_Round.tankDamageOperations[operationIndex].damageId;
		}
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=late_capture_hurt_ambiguous round=%d tick=%d victim=%d/%d attacker=%d/%d",
			observation.context.roundId,
			receipt.tick,
			victim,
			receipt.victimUserid,
			attacker,
			receipt.attackerUserid);
		return true;
	}

	bool receiptMatches = receipt.runId == observation.context.runId
		&& receipt.mapGeneration == observation.context.mapGeneration
		&& receipt.roundId == observation.context.roundId
		&& receipt.sessionIndex == sessionIndex
		&& receipt.sessionId == g_Round.tankSessions[sessionIndex].sessionId
		&& receipt.controllerIndex == controllerIndex
		&& g_Round.tankSessions[sessionIndex].active
		&& g_Round.tankSessions[sessionIndex].currentControllerClient == attacker;
	if (!receiptMatches)
	{
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=late_capture_identity_mismatch round=%d tick=%d victim=%d/%d attacker=%d/%d",
			observation.context.roundId,
			receipt.tick,
			victim,
			receipt.victimUserid,
			attacker,
			receipt.attackerUserid);
		captureResult.status = StatsSdkDamageCapture_IdentityMismatch;
		return true;
	}

	if (receipt.damageCounted)
	{
		int damageToReplace = receipt.damageApplied;
		g_Round.tankSessions[sessionIndex].totalDamage -= damageToReplace;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage -= damageToReplace;
		if (g_Round.tankSessions[sessionIndex].totalDamage < 0)
		{
			g_Round.tankSessions[sessionIndex].totalDamage = 0;
		}
		if (g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage < 0)
		{
			g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage = 0;
		}
		g_Round.tankSessions[sessionIndex].totalDamage += healthBefore;
		g_Round.tankSessions[sessionIndex].controllers[controllerIndex].damage += healthBefore;
		g_Round.tankHurtReceipts[victim].damageApplied = healthBefore;
	}

	int operationIndex = Damage_StoreTankOperation(observation, victim, receipt.victimUserid, attacker, receipt.attackerUserid, sessionIndex, controllerIndex, healthBefore, PlayerStatsTankDamageOperation_Applied);
	captureResult.status = StatsSdkDamageCapture_Reconciled;
	captureResult.operationIndex = operationIndex;
	captureResult.healthBefore = healthBefore;
	captureResult.hasHealthBefore = true;
	if (operationIndex >= 0)
	{
		captureResult.operationState = view_as<StatsSdkDamageOperationState>(g_Round.tankDamageOperations[operationIndex].state);
		captureResult.damageId = g_Round.tankDamageOperations[operationIndex].damageId;
	}

	Stats_Debug(PlayerStatsDebug_Detect,
		"tank_damage_operation resolved reason=late_sdk_reconciled round=%d tick=%d victim=%d/%d attacker=%d/%d prior_damage=%d replacement=%d counted=%d",
		observation.context.roundId,
		GetGameTickCount(),
		victim,
		receipt.victimUserid,
		attacker,
		receipt.attackerUserid,
		receipt.damageApplied,
		healthBefore,
		receipt.damageCounted);
	return true;
}

StatsSdkDamageCaptureResult Damage_CaptureLegacyTankTerminal(const StatsSdkDamageObservation observation)
{
	StatsSdkDamageCaptureResult captureResult;
	captureResult.Reset();
	if (!Stats_IsTrackingEnabled())
	{
		captureResult.status = StatsSdkDamageCapture_TrackingDisabled;
		return captureResult;
	}
	if (!Stats_IsRoundLive())
	{
		captureResult.status = StatsSdkDamageCapture_RoundNotLive;
		return captureResult;
	}
	if (!Stats_IsCompetitiveMode())
	{
		captureResult.status = StatsSdkDamageCapture_WrongMode;
		return captureResult;
	}
	if (g_bRoundClosing)
	{
		captureResult.status = StatsSdkDamageCapture_RoundClosing;
		return captureResult;
	}

	int victim = observation.victimClient;
	int attacker = observation.attackerClient;
	if (!IsValidSurvivor(victim))
	{
		captureResult.status = StatsSdkDamageCapture_InvalidVictim;
		return captureResult;
	}
	if (!IsValidTank(attacker))
	{
		captureResult.status = StatsSdkDamageCapture_InvalidAttacker;
		return captureResult;
	}
	if (Stats_IsSurvivorIncapacitated(victim))
	{
		captureResult.status = StatsSdkDamageCapture_VictimIncapacitated;
		return captureResult;
	}

	int victimUserid = GetClientUserId(victim);
	int attackerUserid = GetClientUserId(attacker);
	if (victimUserid <= 0 || attackerUserid <= 0)
	{
		captureResult.status = StatsSdkDamageCapture_InvalidUserid;
		return captureResult;
	}

	int playerHealth = Stats_GetSurvivorCurrentHealthTotal(victim);
	captureResult.healthBefore = playerHealth;
	captureResult.hasHealthBefore = true;
	if (playerHealth <= 0 || observation.damage < float(playerHealth))
	{
		captureResult.status = StatsSdkDamageCapture_NotTerminalDamage;
		return captureResult;
	}

	int sessionIndex = Detect_StartTankSession(attacker);
	if (sessionIndex == -1)
	{
		captureResult.status = StatsSdkDamageCapture_SessionCapacity;
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=session_capacity victim=%d/%d attacker=%d/%d",
			victim,
			victimUserid,
			attacker,
			attackerUserid);
		return captureResult;
	}
	Detect_SyncTankController(sessionIndex, attacker);

	int controllerIndex = Detect_EnsureTankControllerIndex(sessionIndex, attacker);
	if (controllerIndex == -1)
	{
		captureResult.status = StatsSdkDamageCapture_ControllerCapacity;
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=controller_capacity round=%d session=%d victim=%d/%d attacker=%d/%d",
			g_Round.meta.id,
			sessionIndex,
			victim,
			victimUserid,
			attacker,
			attackerUserid);
		return captureResult;
	}
	if (Damage_ReconcileRecentTankHurt(observation, playerHealth, sessionIndex, controllerIndex, captureResult))
	{
		return captureResult;
	}

	if (g_Runtime.tankLifeUseridByClient[victim] != victimUserid)
	{
		g_Runtime.tankLifeUseridByClient[victim] = victimUserid;
		g_Runtime.tankLifeEpochByClient[victim]++;
	}

	int tick = GetGameTickCount();
	int freeOperation = -1;
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		PlayerStatsTankDamageOperation existing;
		existing = g_Round.tankDamageOperations[i];
		if (existing.state == PlayerStatsTankDamageOperation_Empty)
		{
			if (freeOperation == -1)
			{
				freeOperation = i;
			}
			continue;
		}

		if (existing.tick != tick)
		{
			g_Round.tankDamageOperations[i].Reset();
			if (freeOperation == -1)
			{
				freeOperation = i;
			}
			continue;
		}

		if (existing.victimClient == victim && existing.victimUserid == victimUserid)
		{
			g_Round.tankDamageOperations[i].state = PlayerStatsTankDamageOperation_Ambiguous;
			captureResult.status = StatsSdkDamageCapture_Collision;
			captureResult.operationState = StatsSdkDamageOperation_Ambiguous;
			captureResult.operationIndex = i;
			captureResult.damageId = existing.damageId;
			Stats_Debug(PlayerStatsDebug_Detect,
				"tank_damage_operation discarded reason=collision_same_victim_tick round=%d tick=%d victim=%d/%d prior_attacker=%d/%d attacker=%d/%d",
				g_Round.meta.id,
				tick,
				victim,
				victimUserid,
				existing.attackerClient,
				existing.attackerUserid,
				attacker,
				attackerUserid);
			return captureResult;
		}
	}

	if (freeOperation == -1)
	{
		captureResult.status = StatsSdkDamageCapture_OperationCapacity;
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation discarded reason=capacity round=%d tick=%d victim=%d/%d attacker=%d/%d",
			g_Round.meta.id,
			tick,
			victim,
			victimUserid,
			attacker,
			attackerUserid);
		return captureResult;
	}

	PlayerStatsTankDamageOperation operation;
	operation.Reset();
	operation.state = PlayerStatsTankDamageOperation_Pending;
	operation.runId = observation.context.runId;
	operation.mapGeneration = observation.context.mapGeneration;
	operation.roundId = observation.context.roundId;
	operation.signalId = observation.context.signalId;
	operation.damageId = Trace_NextDamageId();
	operation.tick = tick;
	operation.victimClient = victim;
	operation.victimUserid = victimUserid;
	operation.victimLifeEpoch = g_Runtime.tankLifeEpochByClient[victim];
	operation.attackerClient = attacker;
	operation.attackerUserid = attackerUserid;
	operation.sessionIndex = sessionIndex;
	operation.sessionId = g_Round.tankSessions[sessionIndex].sessionId;
	operation.controllerIndex = controllerIndex;
	operation.healthBefore = playerHealth;
	g_Round.tankDamageOperations[freeOperation] = operation;
	captureResult.status = StatsSdkDamageCapture_CapturedPending;
	captureResult.operationState = StatsSdkDamageOperation_Pending;
	captureResult.operationIndex = freeOperation;
	captureResult.damageId = operation.damageId;

	Stats_Debug(PlayerStatsDebug_Detect,
		"tank_damage_operation captured reason=terminal_candidate op=%d run=%d mapgen=%d round=%d tick=%d victim=%d/%d life=%d attacker=%d/%d session=%d/%d controller=%d health=%d sdk_damage=%.1f",
		freeOperation,
		operation.runId,
		operation.mapGeneration,
		operation.roundId,
		operation.tick,
		operation.victimClient,
		operation.victimUserid,
		operation.victimLifeEpoch,
		operation.attackerClient,
		operation.attackerUserid,
		operation.sessionIndex,
		operation.sessionId,
		operation.controllerIndex,
		operation.healthBefore,
		observation.damage);
	return captureResult;
}

PlayerStatsTankDamageResolveResult Damage_ResolveTankTerminal(int victimClient, int victimUserid, int attackerClient, int attackerUserid, StatsTraceContext traceContext, int &operationIndex, int &damageId)
{
	operationIndex = -1;
	damageId = 0;
	if (victimClient <= 0 || victimClient >= L4D2_PLAYER_STATS_MAX_PLAYERS || attackerClient <= 0 || attackerClient >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return PlayerStatsTankDamageResolve_None;
	}

	int tick = GetGameTickCount();
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_TANK_DAMAGE_OPERATIONS; i++)
	{
		PlayerStatsTankDamageOperation operation;
		operation = g_Round.tankDamageOperations[i];
		if (operation.state == PlayerStatsTankDamageOperation_Empty)
		{
			continue;
		}
		if (operation.tick != tick
			|| operation.runId != traceContext.runId
			|| operation.mapGeneration != traceContext.mapGeneration
			|| operation.roundId != traceContext.roundId)
		{
			Stats_Debug(PlayerStatsDebug_Detect,
				"tank_damage_operation discarded reason=tick_or_context_expired op=%d saved_round=%d event_round=%d saved_tick=%d event_tick=%d",
				i,
				operation.roundId,
				traceContext.roundId,
				operation.tick,
				tick);
			g_Round.tankDamageOperations[i].Reset();
			continue;
		}
		if (operation.victimClient != victimClient || operation.victimUserid != victimUserid)
		{
			continue;
		}

		operationIndex = i;
		damageId = operation.damageId;
		if (operation.state == PlayerStatsTankDamageOperation_Ambiguous)
		{
			return PlayerStatsTankDamageResolve_Ambiguous;
		}

		bool identityMatches = operation.attackerClient == attackerClient
			&& operation.attackerUserid == attackerUserid
			&& operation.victimLifeEpoch == g_Runtime.tankLifeEpochByClient[victimClient]
			&& g_Runtime.tankLifeUseridByClient[victimClient] == victimUserid
			&& IsValidSurvivor(victimClient)
			&& IsValidTank(attackerClient)
			&& GetClientUserId(victimClient) == victimUserid
			&& GetClientUserId(attackerClient) == attackerUserid
			&& operation.sessionIndex >= 0
			&& operation.sessionIndex < g_Round.tankSessionCount
			&& g_Round.tankSessions[operation.sessionIndex].active
			&& g_Round.tankSessions[operation.sessionIndex].sessionId == operation.sessionId
			&& g_Round.tankSessions[operation.sessionIndex].currentControllerClient == attackerClient
			&& operation.controllerIndex >= 0
			&& operation.controllerIndex < g_Round.tankSessions[operation.sessionIndex].controllerCount;

		if (!identityMatches || g_bRoundClosing)
		{
			g_Round.tankDamageOperations[i].Reset();
			Stats_Debug(PlayerStatsDebug_Detect,
				"tank_damage_operation discarded reason=%s op=%d round=%d tick=%d victim=%d/%d attacker=%d/%d",
				g_bRoundClosing ? "round_closing" : "identity_mismatch",
				i,
				operation.roundId,
				tick,
				victimClient,
				victimUserid,
				attackerClient,
				attackerUserid);
			return PlayerStatsTankDamageResolve_Stale;
		}

		if (operation.state == PlayerStatsTankDamageOperation_Applied)
		{
			return PlayerStatsTankDamageResolve_AlreadyApplied;
		}

		g_Round.tankDamageOperations[i].state = PlayerStatsTankDamageOperation_Applied;
		Stats_Debug(PlayerStatsDebug_Detect,
			"tank_damage_operation resolved reason=corroborated op=%d round=%d tick=%d victim=%d/%d attacker=%d/%d session=%d/%d health=%d",
			i,
			operation.roundId,
			tick,
			victimClient,
			victimUserid,
			attackerClient,
			attackerUserid,
			operation.sessionIndex,
			operation.sessionId,
			operation.healthBefore);
		return PlayerStatsTankDamageResolve_Ready;
	}

	return PlayerStatsTankDamageResolve_None;
}
