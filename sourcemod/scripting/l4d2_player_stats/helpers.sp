#if defined _l4d2_player_stats_helpers_included
	#endinput
#endif
#define _l4d2_player_stats_helpers_included

/**
 * @brief Checks whether the plugin is currently enabled.
 *
 * @return               True if the enable ConVar exists and is on.
 */
stock bool Stats_IsEnabled()
{
	return g_cvEnable != null && g_cvEnable.BoolValue;
}

/**
 * @brief Checks whether the current round is active and already live.
 *
 * @return               True if sensitive round statistics should be counted now.
 */
stock bool Stats_IsRoundLive()
{
	return Stats_IsEnabled() && g_Round.active && g_bRoundLive;
}

/**
 * @brief Checks whether there is a round snapshot available to query or print.
 *
 * @return               True if the plugin is enabled and at least one round snapshot exists.
 */
stock bool Stats_HasRoundSnapshot()
{
	return Stats_IsEnabled() && g_Round.id > 0;
}

/**
 * @brief Checks whether a client index is valid and in-game.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is in the valid SourceMod range and connected in-game.
 */
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

/**
 * @brief Checks whether a client is on the survivor team.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is a valid survivor.
 */
stock bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && L4D_GetClientTeam(client) == L4DTeam_Survivor;
}

/**
 * @brief Checks whether a client is on the infected team.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is a valid infected player.
 */
stock bool IsValidInfected(int client)
{
	return IsValidClient(client) && L4D_GetClientTeam(client) == L4DTeam_Infected;
}

/**
 * @brief Classifies the attribution bucket for a damage, incap or death source.
 *
 * @param attacker       Client index of the attacker when available.
 *
 * @return               Attribution type for survivor, infected player or infected AI/other.
 */
stock PlayerStatsAttributionType Stats_GetAttributionType(int attacker)
{
	if (IsValidSurvivor(attacker))
	{
		return PlayerStatsAttribution_Survivor;
	}

	if (IsValidInfected(attacker))
	{
		return IsFakeClient(attacker) ? PlayerStatsAttribution_InfectedAI : PlayerStatsAttribution_InfectedPlayer;
	}

	return PlayerStatsAttribution_InfectedAI;
}

/**
 * @brief Checks whether a client is currently a Tank.
 *
 * @param client         Client index to inspect.
 *
 * @return               True if the client is infected and of Tank class.
 */
stock bool IsValidTank(int client)
{
	return IsValidInfected(client) && L4D2_GetPlayerZombieClass(client) == L4D2ZombieClass_Tank;
}

/**
 * @brief Checks whether an entity is a Witch.
 *
 * @param entity         Entity index to inspect.
 *
 * @return               True if the entity classname matches a Witch variant.
 */
stock bool IsWitchEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "witch", false) != -1;
}

/**
 * @brief Writes a formatted debug line when debug logging is enabled.
 *
 * @param fmt            Format string.
 * @param ...            Format arguments.
 *
 * @noreturn
 */
stock void Stats_Debug(const char[] fmt, any...)
{
	if (g_cvDebug == null || !g_cvDebug.BoolValue)
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogToFileEx(g_sDebugLogPath, "[l4d2_player_stats] %s", buffer);
}

/**
 * @brief Consumes generic event callback metadata when a handler does not need it yet.
 *
 * @param event          SourceMod event handle.
 * @param name           Event name.
 * @param dontBroadcast  Broadcast flag passed by the event system.
 *
 * @noreturn
 */
stock void Stats_ConsumeEventContext(Event event, const char[] name, bool dontBroadcast)
{
	if (event == null && dontBroadcast && name[0] == '\0')
	{
	}
}

/**
 * @brief Returns the typed stats team for a client.
 *
 * @param client         Client index to inspect.
 *
 * @return               PlayerStatsTeam value for the client.
 */
stock PlayerStatsTeam Stats_GetPlayerTeam(int client)
{
	if (!IsValidClient(client))
	{
		return PlayerStatsTeam_None;
	}

	switch (L4D_GetClientTeam(client))
	{
		case L4DTeam_Survivor:
		{
			return PlayerStatsTeam_Survivor;
		}
		case L4DTeam_Infected:
		{
			return PlayerStatsTeam_Infected;
		}
	}

	return PlayerStatsTeam_None;
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
			g_Round.players[index].smokerDamage += damage;
			g_Round.survivorTotalSmokerDamage += damage;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].boomerDamage += damage;
			g_Round.survivorTotalBoomerDamage += damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].hunterDamage += damage;
			g_Round.survivorTotalHunterDamage += damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].spitterDamage += damage;
			g_Round.survivorTotalSpitterDamage += damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].jockeyDamage += damage;
			g_Round.survivorTotalJockeyDamage += damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].chargerDamage += damage;
			g_Round.survivorTotalChargerDamage += damage;
		}
	}
}

/**
 * @brief Adds a kill to the survivor combat split for a special infected class.
 *
 * @param index          Persistent survivor slot index.
 * @param zombieClass    Infected class that died.
 *
 * @noreturn
 */
stock void Stats_AddSpecialKillByClass(int index, L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].smokerKills++;
			g_Round.survivorTotalSmokerKills++;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].boomerKills++;
			g_Round.survivorTotalBoomerKills++;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].hunterKills++;
			g_Round.survivorTotalHunterKills++;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].spitterKills++;
			g_Round.survivorTotalSpitterKills++;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].jockeyKills++;
			g_Round.survivorTotalJockeyKills++;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].chargerKills++;
			g_Round.survivorTotalChargerKills++;
		}
		case L4D2ZombieClass_Tank:
		{
			g_Round.players[index].tankKills++;
			g_Round.survivorTotalTankKills++;
		}
	}
}

/**
 * @brief Resets the runtime client-to-slot mapping table.
 *
 * @noreturn
 */
stock void Stats_ResetRuntimeMappings()
{
	for (int client = 0; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
	{
		g_iPlayerSlotByClient[client] = -1;
	}
}

/**
 * @brief Checks whether a persistent round slot index is valid and active.
 *
 * @param slot           Slot index to inspect.
 *
 * @return               True if the slot is within bounds and currently active.
 */
stock bool Stats_IsValidRoundSlot(int slot)
{
	return slot >= 0 && slot < L4D2_PLAYER_STATS_MAX_SLOTS && g_Round.players[slot].active;
}

/**
 * @brief Assigns a runtime client to an existing persistent slot.
 *
 * @param client         SourceMod client index.
 * @param slot           Persistent slot index.
 *
 * @noreturn
 */
stock void Stats_AssignClientToSlot(int client, int slot)
{
	if (!IsValidClient(client) || !Stats_IsValidRoundSlot(slot))
	{
		return;
	}

	g_iPlayerSlotByClient[client] = slot;
	g_Round.players[slot].player.Capture(client);
	g_Round.players[slot].team = Stats_GetPlayerTeam(client);
}

/**
 * @brief Finds an existing persistent slot matching the client identity.
 *
 * @param client         SourceMod client index.
 *
 * @return               Persistent slot index, or -1 when no match exists.
 */
stock int Stats_FindPersistentSlotForClient(int client)
{
	if (!IsValidClient(client))
	{
		return -1;
	}

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!g_Round.players[slot].active)
		{
			continue;
		}

		if (g_Round.players[slot].player.IsSamePersistentPlayer(client))
		{
			return slot;
		}
	}

	return -1;
}

/**
 * @brief Finds the first free persistent slot in the current round.
 *
 * @return               Free slot index, or -1 when no slot is available.
 */
stock int Stats_FindFreeRoundSlot()
{
	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (!g_Round.players[slot].active)
		{
			return slot;
		}
	}

	return -1;
}

/**
 * @brief Returns the per-round storage slot for a client.
 *
 * @param client         Client index to resolve.
 *
 * @return               Zero-based slot index, or -1 if invalid.
 */
stock int Stats_GetPlayerRoundIndex(int client)
{
	return (client > 0 && client < L4D2_PLAYER_STATS_MAX_PLAYERS && Stats_IsValidRoundSlot(g_iPlayerSlotByClient[client]))
		? g_iPlayerSlotByClient[client]
		: -1;
}

/**
 * @brief Ensures a player's round slot is initialized and captured.
 *
 * @param client         Client index to initialize.
 *
 * @return               Zero-based player slot index, or -1 if invalid.
 */
stock int Stats_EnsurePlayerRoundSlot(int client)
{
	int index = Stats_GetPlayerRoundIndex(client);
	if (index != -1)
	{
		return index;
	}

	index = Stats_FindPersistentSlotForClient(client);
	if (index != -1)
	{
		Stats_AssignClientToSlot(client, index);
		return index;
	}

	index = Stats_FindFreeRoundSlot();
	if (index == -1)
	{
		return -1;
	}

	g_Round.players[index].Reset();
	g_Round.players[index].active = true;
	Stats_AssignClientToSlot(client, index);

	return index;
}

/**
 * @brief Reattaches a runtime client to a persistent slot if one exists, or allocates one.
 *
 * @param client         SourceMod client index.
 *
 * @noreturn
 */
stock void Stats_OnClientPutInServer(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	int slot = Stats_FindPersistentSlotForClient(client);
	if (slot != -1)
	{
		Stats_AssignClientToSlot(client, slot);
	}
}

/**
 * @brief Clears the runtime client binding for a disconnecting player.
 *
 * @param client         SourceMod client index.
 *
 * @noreturn
 */
stock void Stats_OnClientDisconnect(int client)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	int slot = g_iPlayerSlotByClient[client];
	if (Stats_IsValidRoundSlot(slot))
	{
		g_Round.players[slot].player.DetachClient();
	}

	g_iPlayerSlotByClient[client] = -1;
}

/**
 * @brief Moves a persistent slot from a player to a bot replacement.
 *
 * @param event          SourceMod event handle.
 * @param name           Event name.
 * @param dontBroadcast  Broadcast flag passed by the event system.
 *
 * @noreturn
 */
stock void Stats_EventPlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	int player = GetClientOfUserId(event.GetInt("player"));
	int bot = GetClientOfUserId(event.GetInt("bot"));
	if (!IsValidClient(bot))
	{
		return;
	}

	int slot = Stats_GetPlayerRoundIndex(player);
	if (slot == -1)
	{
		slot = Stats_EnsurePlayerRoundSlot(bot);
		return;
	}

	if (player > 0 && player < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		g_iPlayerSlotByClient[player] = -1;
	}

	Stats_AssignClientToSlot(bot, slot);
}

/**
 * @brief Moves a persistent slot from a bot to the player taking over.
 *
 * @param event          SourceMod event handle.
 * @param name           Event name.
 * @param dontBroadcast  Broadcast flag passed by the event system.
 *
 * @noreturn
 */
stock void Stats_EventBotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	int bot = GetClientOfUserId(event.GetInt("bot"));
	int player = GetClientOfUserId(event.GetInt("player"));
	if (!IsValidClient(player))
	{
		return;
	}

	int slot = Stats_GetPlayerRoundIndex(bot);
	if (slot == -1)
	{
		slot = Stats_EnsurePlayerRoundSlot(player);
		return;
	}

	if (bot > 0 && bot < L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		g_iPlayerSlotByClient[bot] = -1;
	}

	Stats_AssignClientToSlot(player, slot);
}
