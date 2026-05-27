#if defined _l4d2_player_stats_included
	#endinput
#endif
#define _l4d2_player_stats_included

#define LIBRARY_L4D2PLAYERSTATS "l4d2_player_stats"

/**
 * Called after the current round snapshot is finalized.
 *
 * The provided `roundId` remains valid for the finalized snapshot that
 * triggered the forward.
 *
 * @param roundId	Finalized round identifier.
 */
forward void PlayerStats_OnRoundFinalized(int roundId);

/**
 * Called after a survivor slot is substituted by a different human.
 *
 * The provided `substitutionId` remains valid until the fixed-size
 * substitution snapshot buffer overwrites that entry.
 *
 * Return `Plugin_Handled` to stop automatic snapshot rehydration. In that
 * case the incoming player starts with a clean slot unless another plugin
 * explicitly applies a snapshot through a native.
 *
 * @param substitutionId	Stable snapshot identifier in `accountid:timestamp` format.
 * @param roundId			Current round identifier.
 * @param slot				Survivor round slot that was replaced.
 * @param incomingClient	Incoming survivor client that is taking the slot.
 */
forward Action PlayerStats_OnPlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient);

/**
 * Returns whether the current round snapshot is active.
 *
 * @return			True if a round snapshot is active, otherwise false.
 */
native bool PlayerStats_IsRoundActive();

/**
 * Returns the identifier of the current round snapshot.
 *
 * Returns `0` when no round snapshot is available.
 *
 * @return			Current round identifier, or `0` if unavailable.
 */
native int PlayerStats_GetRoundId();

/**
 * Returns whether a player slot is valid for the specified round snapshot.
 *
 * @param roundId		Round identifier to validate against.
 * @param slot			Round slot index.
 * @return				True if the slot exists in that round snapshot.
 */
native bool PlayerStats_IsRoundPlayerSlotValid(int roundId, int slot);

/**
 * Returns the current client index bound to a round slot.
 *
 * This native is only meaningful for the currently active round snapshot.
 * Historical snapshots do not guarantee a live client binding.
 *
 * @param roundId		Round identifier to resolve against.
 * @param slot			Round slot index.
 * @return				Client index, or `0` if unavailable.
 */
native int PlayerStats_GetRoundPlayerClient(int roundId, int slot);

/**
 * Writes the current round snapshot into a KeyValues handle.
 *
 * The target handle is populated with a `round` root block that includes
 * round context and aggregate totals.
 *
 * @param roundId		Round identifier to export.
 * @param kv			KeyValues handle to populate.
 * @return				True on success, otherwise false.
 */
native bool PlayerStats_FillRoundKeyValues(int roundId, Handle kv);

/**
 * Writes a round player snapshot into a KeyValues handle.
 *
 * The target handle is populated with a `player` root block for the specified
 * round slot, including identity and tracked stat domains.
 *
 * @param roundId		Round identifier to export.
 * @param slot			Round slot index to export.
 * @param kv			KeyValues handle to populate.
 * @return				True on success, otherwise false.
 */
native bool PlayerStats_FillRoundPlayerKeyValues(int roundId, int slot, Handle kv);

/**
 * Returns the number of substitution snapshots currently kept in memory.
 *
 * The plugin stores a fixed-size circular buffer and overwrites the oldest
 * snapshots when it becomes full.
 *
 * @return				Current substitution snapshot count.
 */
native int PlayerStats_GetSubstitutionCount();

/**
 * Returns the stable identifier for a substitution snapshot.
 *
 * Snapshots are enumerated from oldest to newest.
 *
 * @param index			Zero-based substitution snapshot index.
 * @param buffer		Output buffer for the snapshot identifier.
 * @param maxlen		Maximum length of the output buffer.
 * @return				True on success, otherwise false.
 */
native bool PlayerStats_GetSubstitutionId(int index, char[] buffer, int maxlen);

/**
 * Writes a substitution snapshot into a KeyValues handle.
 *
 * The target handle is populated with a `substitution` root block that
 * includes snapshot metadata and tracked stat domains for the replaced
 * player.
 *
 * @param substitutionId	Stable substitution snapshot identifier.
 * @param kv				KeyValues handle to populate.
 * @return					True on success, otherwise false.
 */
native bool PlayerStats_FillSubstitutionSnapshotKeyValues(const char[] substitutionId, Handle kv);

/**
 * Applies a stored substitution snapshot to a live round slot.
 *
 * This native is intended for plugins that intercept substitution flow and
 * want to rehydrate a slot manually after returning `Plugin_Handled` from
 * `PlayerStats_OnPlayerSubstituted`.
 *
 * @param substitutionId	Stable substitution snapshot identifier.
 * @param slot				Live round slot to rehydrate.
 * @param client			Incoming survivor client to bind to the slot.
 * @return					True on success, otherwise false.
 */
native bool PlayerStats_ApplySubstitutionSnapshotToSlot(const char[] substitutionId, int slot, int client);

/**
 * Broadcasts the current round summary and round table using the plugin's
 * configured announce/output policy.
 *
 * @noreturn
 */
native void PlayerStats_BroadcastRoundStats();

/**
 * Broadcasts the current game or mission history table using the plugin's
 * configured announce/output policy.
 *
 * @noreturn
 */
native void PlayerStats_BroadcastGameStats();

public SharedPlugin __pl_l4d2_player_stats =
{
	name = LIBRARY_L4D2PLAYERSTATS,
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
	MarkNativeAsOptional("PlayerStats_GetSubstitutionCount");
	MarkNativeAsOptional("PlayerStats_GetSubstitutionId");
	MarkNativeAsOptional("PlayerStats_FillSubstitutionSnapshotKeyValues");
	MarkNativeAsOptional("PlayerStats_ApplySubstitutionSnapshotToSlot");
	MarkNativeAsOptional("PlayerStats_BroadcastRoundStats");
	MarkNativeAsOptional("PlayerStats_BroadcastGameStats");
}
#endif
