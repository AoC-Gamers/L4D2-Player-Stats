#if defined _l4d2_player_stats_inputs_natives_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_natives_included

int Input_NativePlayerStats_IsRoundActive()
{
	return g_Round.meta.active;
}

int Input_NativePlayerStats_IsRoundLive()
{
	return g_Runtime.roundLive;
}

int Input_NativePlayerStats_GetRoundId()
{
	return g_Round.meta.id;
}

int Input_NativePlayerStats_IsRoundPlayerSlotValid()
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);
	return API_IsRoundIdValid(roundId) && Stats_IsValidRoundSlot(slot);
}

int Input_NativePlayerStats_GetRoundPlayerClient()
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);

	if (!API_IsRoundIdValid(roundId) || !Stats_IsValidRoundSlot(slot))
	{
		return 0;
	}

	return IsValidClient(g_Round.players[slot].player.client) ? g_Round.players[slot].player.client : 0;
}

int Input_NativePlayerStats_GetCurrentModeProperty()
{
	StatsModeProperty property = view_as<StatsModeProperty>(GetNativeCell(1));

	switch (property)
	{
		case StatsModeProperty_BaseMode:
		{
			return g_Runtime.baseMode;
		}
		case StatsModeProperty_HasBosses:
		{
			return g_Runtime.hasBosses;
		}
		case StatsModeProperty_HasRoundHalves:
		{
			return g_Runtime.hasRoundHalves;
		}
		case StatsModeProperty_SeriesScope:
		{
			return g_Runtime.seriesScope;
		}
		case StatsModeProperty_EnabledSiClassCount:
		{
			return g_Runtime.enabledSiClassCount;
		}
		case StatsModeProperty_VersusTeamSize:
		{
			return g_Runtime.versusTeamSize;
		}
		case StatsModeProperty_RoundEndSignal:
		{
			return g_Runtime.roundEndSignal;
		}
		case StatsModeProperty_RoundStartSignal:
		{
			return g_Runtime.roundLiveSignal;
		}
		case StatsModeProperty_RestartPolicy:
		{
			return g_Runtime.restartPolicy;
		}
	}

	return 0;
}

int Input_NativePlayerStats_FillRoundKeyValues()
{
	int roundId = GetNativeCell(1);
	Handle kv = GetNativeCell(2);

	if (!API_IsRoundIdValid(roundId) || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", true))
	{
		return false;
	}

	KvSetNum(kv, "id", g_Round.meta.id);
	API_WriteRoundContextBlock(kv);
	API_WriteRoundTotals(kv);
	API_WriteRoundPlayersSummary(kv);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

int Input_NativePlayerStats_FillRoundPlayerKeyValues()
{
	int roundId = GetNativeCell(1);
	int slot = GetNativeCell(2);
	Handle kv = GetNativeCell(3);

	if (!API_IsRoundIdValid(roundId) || !Stats_IsValidRoundSlot(slot) || kv == INVALID_HANDLE)
	{
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "player", true))
	{
		return false;
	}

	API_WriteRoundContextBlock(kv);
	API_WriteRoundPlayerDetail(kv, slot);

	KvGoBack(kv);
	KvRewind(kv);
	return true;
}

int Input_NativePlayerStats_ApplySubstitutionSnapshotToSlot()
{
	char substitutionId[64];
	GetNativeString(1, substitutionId, sizeof(substitutionId));

	int slot = GetNativeCell(2);
	int client = GetNativeCell(3);
	int snapshotIndex = Stats_FindSubstitutionSnapshotById(substitutionId);
	if (snapshotIndex == -1)
	{
		return false;
	}

	return Stats_RestoreSubstitutionSnapshotToSlot(snapshotIndex, slot, client);
}

int Input_NativePlayerStats_BroadcastRoundStats()
{
	Announce_BroadcastRoundSummary();
	return 1;
}
