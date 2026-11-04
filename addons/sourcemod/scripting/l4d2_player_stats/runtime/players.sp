#if defined _l4d2_player_stats_runtime_players_included
	#endinput
#endif
#define _l4d2_player_stats_runtime_players_included

/**
 * @brief Resets the runtime client-to-slot mapping table.
 *
 * @noreturn
 */
stock void Stats_ResetRuntimeMappings()
{
	for (int client = 0; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
	{
		g_Runtime.playerSlotByClient[client] = -1;
		g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
		g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
	}
}

stock void Stats_SetLastWeaponFamily(int client, PlayerStatsWeaponFamily family)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	g_Runtime.lastWeaponFamilyByClient[client] = family;
}

stock PlayerStatsWeaponFamily Stats_GetLastWeaponFamily(int client)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return PlayerStatsWeaponFamily_None;
	}

	return g_Runtime.lastWeaponFamilyByClient[client];
}

stock void Stats_SetLastWeaponDetail(int client, PlayerStatsWeaponDetailType detail)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	g_Runtime.lastWeaponDetailByClient[client] = detail;
}

stock PlayerStatsWeaponDetailType Stats_GetLastWeaponDetail(int client)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return PlayerStatsWeaponDetail_None;
	}

	return g_Runtime.lastWeaponDetailByClient[client];
}

/**
 * @brief Removes a runtime client binding while preserving each slot's identity and statistics.
 *
 * @param client         SourceMod client index.
 *
 * @noreturn
 */
stock void Stats_ClearClientRuntimeBinding(int client)
{
	if (client <= 0 || client >= L4D2_PLAYER_STATS_MAX_PLAYERS)
	{
		return;
	}

	for (int slot = 0; slot < L4D2_PLAYER_STATS_MAX_SLOTS; slot++)
	{
		if (g_Round.players[slot].player.client == client)
		{
			g_Round.players[slot].player.DetachClient();
		}
	}

	g_Runtime.playerSlotByClient[client] = -1;
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

	int displacedClient = g_Round.players[slot].player.client;
	if (displacedClient != client)
	{
		Stats_ClearClientRuntimeBinding(displacedClient);
	}

	Stats_ClearClientRuntimeBinding(client);
	g_Runtime.playerSlotByClient[client] = slot;
	g_Round.players[slot].player.Capture(client);
	g_Round.players[slot].team = Stats_GetPlayerTeam(client);
}

stock void Stats_AssignBotToSlotPreserveIdentity(int bot, int slot)
{
	if (!IsValidClient(bot) || !Stats_IsValidRoundSlot(slot))
	{
		return;
	}

	int displacedClient = g_Round.players[slot].player.client;
	if (displacedClient != bot)
	{
		Stats_ClearClientRuntimeBinding(displacedClient);
	}

	Stats_ClearClientRuntimeBinding(bot);
	g_Runtime.playerSlotByClient[bot] = slot;
	g_Round.players[slot].player.client = bot;
	g_Round.players[slot].player.userid = GetClientUserId(bot);
	g_Round.players[slot].player.bot = true;
	g_Round.players[slot].player.character = (L4D_GetClientTeam(bot) == L4DTeam_Survivor)
		? GetEntProp(bot, Prop_Send, "m_survivorCharacter")
		: -1;
	g_Round.players[slot].team = Stats_GetPlayerTeam(bot);
}

stock void Stats_ClearSlotRuntimeBindings(int slot)
{
	for (int client = 1; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
	{
		if (g_Runtime.playerSlotByClient[client] != slot
			&& g_Round.players[slot].player.client != client)
		{
			continue;
		}

		Stats_ClearClientRuntimeBinding(client);
		g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
		g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
	}
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
	return (client > 0 && client < L4D2_PLAYER_STATS_MAX_PLAYERS && Stats_IsValidRoundSlot(g_Runtime.playerSlotByClient[client]))
		? g_Runtime.playerSlotByClient[client]
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
	Stats_Debug(PlayerStatsDebug_Detect, "Assigned new round slot. client=%d slot=%d team=%d",
		client,
		index,
		g_Round.players[index].team);

	return index;
}

/**
 * @brief Initializes round slots for currently connected players.
 *
 * @noreturn
 */
stock void Stats_PrimeCurrentRoundPlayers()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (!IsValidClient(client))
		{
			continue;
		}

		PlayerStatsTeam team = Stats_GetPlayerTeam(client);
		if (team == PlayerStatsTeam_None)
		{
			continue;
		}

		Stats_EnsurePlayerRoundSlot(client);
	}
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

	Stats_SetLastWeaponFamily(client, PlayerStatsWeaponFamily_None);
	Stats_SetLastWeaponDetail(client, PlayerStatsWeaponDetail_None);

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

	Stats_ClearClientRuntimeBinding(client);
	g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
	g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
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
	return IsValidClientIndex(client) && IsClientInGame(client);
}


/**
 * @brief Returns the typed L4D team for a client.
 *
 * @param client         Client index to inspect.
 *
 * @return               Team enum, or L4DTeam_Unassigned if invalid.
 */
stock L4DTeam GetClientL4DTeam(int client)
{
	return IsValidClient(client) ? L4D_GetClientTeam(client) : L4DTeam_Unassigned;
}


/**
 * @brief Checks whether a client belongs to the requested L4D team.
 *
 * @param client         Client index to inspect.
 * @param team           Target L4D team.
 *
 * @return               True if the client is valid and belongs to that team.
 */
stock bool IsClientOnTeam(int client, L4DTeam team)
{
	return GetClientL4DTeam(client) == team;
}


/**
 * @brief Returns the typed zombie class for an infected client.
 *
 * @param client         Client index to inspect.
 *
 * @return               Zombie class enum, or NotInfected when unavailable.
 */
stock L4D2ZombieClassType GetClientZombieClass(int client)
{
	return IsValidInfected(client) ? L4D2_GetPlayerZombieClass(client) : L4D2ZombieClass_NotInfected;
}


/**
 * @brief Checks whether an infected client matches a specific zombie class.
 *
 * @param client         Client index to inspect.
 * @param zombieClass    Target zombie class.
 *
 * @return               True if the client is infected and matches the class.
 */
stock bool IsValidZombieClass(int client, L4D2ZombieClassType zombieClass)
{
	return IsValidInfected(client) && GetClientZombieClass(client) == zombieClass;
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
	return IsClientOnTeam(client, L4DTeam_Survivor);
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
	return IsClientOnTeam(client, L4DTeam_Infected);
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
	return IsValidZombieClass(client, L4D2ZombieClass_Tank);
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

	switch (GetClientL4DTeam(client))
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
