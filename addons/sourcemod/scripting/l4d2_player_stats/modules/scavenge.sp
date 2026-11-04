#if defined _l4d2_player_stats_modules_scavenge_included
	#endinput
#endif
#define _l4d2_player_stats_modules_scavenge_included

PlayerStatsScavengeApplyResult Scavenge_ApplyObjective(const StatsObjectiveRecord observation)
{
	char eventName[40];
	Scavenge_GetObjectiveEventName(observation.type, eventName, sizeof(eventName));
	int userid = observation.userid;

	if (!Stats_IsRoundLive())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because round is not live. userid=%d round=%d", eventName, userid, g_Round.meta.id);
		return PlayerStatsScavengeApply_RoundNotLive;
	}

	if (!Stats_IsTrackingEnabled())
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because tracking is disabled. userid=%d round=%d", eventName, userid, g_Round.meta.id);
		return PlayerStatsScavengeApply_TrackingDisabled;
	}

	if (!Stats_IsMode(GAMEMODE_SCAVENGE))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s outside scavenge mode. userid=%d base_mode=%d", eventName, userid, g_Round.meta.baseMode);
		return PlayerStatsScavengeApply_WrongMode;
	}

	int client = observation.client;
	if (!IsValidSurvivor(client))
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because userid did not resolve to a survivor. userid=%d client=%d", eventName, userid, client);
		return observation.validPayload ? PlayerStatsScavengeApply_InvalidActor : PlayerStatsScavengeApply_InvalidPayload;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no round slot could be assigned. userid=%d client=%d", eventName, userid, client);
		return PlayerStatsScavengeApply_NoSlot;
	}

	switch (observation.type)
	{
		case PlayerStatsScavengeObjective_Poured:
		{
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
		case PlayerStatsScavengeObjective_Dropped:
		{
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
		case PlayerStatsScavengeObjective_Destroyed:
		{
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
		default:
		{
			return PlayerStatsScavengeApply_InvalidPayload;
		}
	}

	return PlayerStatsScavengeApply_Applied;
}

void Scavenge_GetObjectiveEventName(PlayerStatsScavengeObjectiveType type, char[] buffer, int maxlen)
{
	switch (type)
	{
		case PlayerStatsScavengeObjective_Poured: strcopy(buffer, maxlen, "gascan_pour_completed");
		case PlayerStatsScavengeObjective_Dropped: strcopy(buffer, maxlen, "gascan_dropped");
		case PlayerStatsScavengeObjective_Destroyed: strcopy(buffer, maxlen, "scavenge_gas_can_destroyed");
		default: strcopy(buffer, maxlen, "unknown_scavenge_objective");
	}
}
