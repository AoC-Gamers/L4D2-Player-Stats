#if defined _l4d2_player_stats_included
	#endinput
#endif
#define _l4d2_player_stats_included

forward void PlayerStats_OnRoundFinalized(int roundId);

native bool PlayerStats_IsRoundActive();
native int PlayerStats_GetRoundId();
native bool PlayerStats_IsRoundPlayerSlotValid(int roundId, int slot);
native int PlayerStats_GetRoundPlayerClient(int roundId, int slot);
native bool PlayerStats_FillRoundKeyValues(int roundId, Handle kv);
native bool PlayerStats_FillRoundPlayerKeyValues(int roundId, int slot, Handle kv);
native void PlayerStats_BroadcastRoundStats();
native void PlayerStats_BroadcastGameStats();

public SharedPlugin __pl_l4d2_player_stats =
{
	name = "l4d2_player_stats",
	file = "l4d2_player_stats.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_player_stats_SetNTVOptional()
{
	MarkNativeAsOptional("PlayerStats_IsRoundActive");
	MarkNativeAsOptional("PlayerStats_GetRoundId");
	MarkNativeAsOptional("PlayerStats_IsRoundPlayerSlotValid");
	MarkNativeAsOptional("PlayerStats_GetRoundPlayerClient");
	MarkNativeAsOptional("PlayerStats_FillRoundKeyValues");
	MarkNativeAsOptional("PlayerStats_FillRoundPlayerKeyValues");
	MarkNativeAsOptional("PlayerStats_BroadcastRoundStats");
	MarkNativeAsOptional("PlayerStats_BroadcastGameStats");
}
#endif
