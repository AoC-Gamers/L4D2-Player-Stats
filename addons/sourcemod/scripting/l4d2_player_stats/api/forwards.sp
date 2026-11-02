#if defined _l4d2_player_stats_api_forwards_included
	#endinput
#endif
#define _l4d2_player_stats_api_forwards_included

Handle g_hForwardRoundLive = INVALID_HANDLE;
Handle g_hForwardRoundEnded = INVALID_HANDLE;
Handle g_hForwardPlayerSubstituted = INVALID_HANDLE;

void API_CreateForwards()
{
	g_hForwardRoundLive = CreateGlobalForward("PlayerStats_OnRoundLive", ET_Ignore, Param_Cell);
	g_hForwardRoundEnded = CreateGlobalForward("PlayerStats_OnRoundEnded", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
	g_hForwardPlayerSubstituted = CreateGlobalForward("PlayerStats_OnPlayerSubstituted", ET_Hook, Param_String, Param_Cell, Param_Cell, Param_Cell);
}

void API_CreateNatives()
{
	CreateNative("PlayerStats_IsRoundActive", Native_PlayerStats_IsRoundActive);
	CreateNative("PlayerStats_IsRoundLive", Native_PlayerStats_IsRoundLive);
	CreateNative("PlayerStats_GetRoundId", Native_PlayerStats_GetRoundId);
	CreateNative("PlayerStats_IsRoundPlayerSlotValid", Native_PlayerStats_IsRoundPlayerSlotValid);
	CreateNative("PlayerStats_GetRoundPlayerClient", Native_PlayerStats_GetRoundPlayerClient);
	CreateNative("PlayerStats_GetCurrentModeProperty", Native_PlayerStats_GetCurrentModeProperty);
	CreateNative("PlayerStats_FillRoundKeyValues", Native_PlayerStats_FillRoundKeyValues);
	CreateNative("PlayerStats_FillRoundPlayerKeyValues", Native_PlayerStats_FillRoundPlayerKeyValues);
	CreateNative("PlayerStats_ApplySubstitutionSnapshotToSlot", Native_PlayerStats_ApplySubstitutionSnapshotToSlot);
	CreateNative("PlayerStats_BroadcastRoundStats", Native_PlayerStats_BroadcastRoundStats);
}

void API_FireRoundLive(int roundId)
{
	if (g_hForwardRoundLive == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardRoundLive);
	Call_PushCell(roundId);
	Call_Finish();
}

void API_FireRoundEnded(int roundId, StatsEndType endType, PlayerStatsRoundEndReasonType endReason)
{
	if (g_hForwardRoundEnded == INVALID_HANDLE)
	{
		return;
	}

	Call_StartForward(g_hForwardRoundEnded);
	Call_PushCell(roundId);
	Call_PushCell(endType);
	Call_PushCell(endReason);
	Call_Finish();
}

Action API_FirePlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient)
{
	if (g_hForwardPlayerSubstituted == INVALID_HANDLE)
	{
		return Plugin_Continue;
	}

	Action result = Plugin_Continue;
	Call_StartForward(g_hForwardPlayerSubstituted);
	Call_PushString(substitutionId);
	Call_PushCell(roundId);
	Call_PushCell(slot);
	Call_PushCell(incomingClient);
	Call_Finish(result);
	return result;
}
