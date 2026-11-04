#if defined _l4d2_player_stats_modules_utility_included
	#endinput
#endif
#define _l4d2_player_stats_modules_utility_included

PlayerStatsUtilityApplyResult Utility_ApplyAction(const StatsUtilityRecord observation)
{
	if (!Stats_IsRoundLive())
	{
		return PlayerStatsUtilityApply_RoundNotLive;
	}

	if (!Stats_IsThrowablesEnabled())
	{
		return PlayerStatsUtilityApply_ThrowablesDisabled;
	}

	if (observation.type == PlayerStatsUtilityAction_PlayerNowIt && observation.byBoomer)
	{
		return PlayerStatsUtilityApply_BoomerAttributed;
	}

	if (observation.type == PlayerStatsUtilityAction_ZombieIgnited && observation.fireAmmo)
	{
		return PlayerStatsUtilityApply_FireAmmo;
	}

	if (observation.type < PlayerStatsUtilityAction_PlayerNowIt || observation.type > PlayerStatsUtilityAction_ZombieIgnited)
	{
		return PlayerStatsUtilityApply_InvalidObservation;
	}

	if (!observation.validPayload)
	{
		return PlayerStatsUtilityApply_InvalidPayload;
	}

	int client = observation.client;
	if (!IsValidSurvivor(client))
	{
		return PlayerStatsUtilityApply_InvalidActor;
	}

	int index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return PlayerStatsUtilityApply_NoSlot;
	}

	switch (observation.type)
	{
		case PlayerStatsUtilityAction_PlayerNowIt:
		{
			g_Round.players[index].resources.playersBiled++;
			g_Round.totals.survivorTotalPlayersBiled++;
		}
		case PlayerStatsUtilityAction_VomitBombTank:
		{
			g_Round.players[index].resources.tanksBiled++;
			g_Round.totals.survivorTotalTanksBiled++;
		}
		case PlayerStatsUtilityAction_ZombieIgnited:
		{
			if (g_Round.players[index].resources.molotovsThrown <= 0)
			{
				Stats_Debug(PlayerStatsDebug_Detect, "Ignoring %s because no molotov throw is recorded for this survivor in the current half. userid=%d client=%d round=%d",
					"zombie_ignited",
					observation.userid,
					client,
					g_Round.meta.id);
				return PlayerStatsUtilityApply_NoMolotovRecorded;
			}

			g_Round.players[index].resources.zombiesIgnited++;
			g_Round.totals.survivorTotalZombiesIgnited++;
		}
	}

	return PlayerStatsUtilityApply_Applied;
}

PlayerStatsUtilityThrowResult Utility_ApplyThrow(const StatsShotRecord observation, int index)
{
	if (!Stats_IsThrowablesEnabled())
	{
		return PlayerStatsUtilityThrow_Disabled;
	}

	if (!Stats_IsValidRoundSlot(index))
	{
		return PlayerStatsUtilityThrow_InvalidSlot;
	}

	char normalized[64];
	if (strncmp(observation.weapon, "weapon_", 7, false) == 0)
	{
		strcopy(normalized, sizeof(normalized), observation.weapon);
	}
	else
	{
		Format(normalized, sizeof(normalized), "weapon_%s", observation.weapon);
	}

	switch (WeaponNameToId(normalized))
	{
		case WEPID_MOLOTOV:
		{
			g_Round.players[index].resources.molotovsThrown++;
			g_Round.totals.survivorTotalMolotovsThrown++;
			return PlayerStatsUtilityThrow_MolotovApplied;
		}
		case WEPID_PIPE_BOMB:
		{
			g_Round.players[index].resources.pipebombsThrown++;
			g_Round.totals.survivorTotalPipebombsThrown++;
			return PlayerStatsUtilityThrow_PipeBombApplied;
		}
		case WEPID_VOMITJAR:
		{
			g_Round.players[index].resources.vomitjarsThrown++;
			g_Round.totals.survivorTotalVomitjarsThrown++;
			return PlayerStatsUtilityThrow_VomitjarApplied;
		}
	}

	return PlayerStatsUtilityThrow_NotThrowable;
}
