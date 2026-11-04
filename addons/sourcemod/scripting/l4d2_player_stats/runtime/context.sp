#if defined _l4d2_player_stats_runtime_context_included
	#endinput
#endif
#define _l4d2_player_stats_runtime_context_included

stock int Stats_GetModeBase()
{
	if (!g_Runtime.hasLeft4DHooks)
	{
		return GAMEMODE_UNKNOWN;
	}

	return L4D_GetGameModeType();
}

stock bool Stats_IsMode(int gameMode)
{
	return Stats_GetModeBase() == gameMode;
}

stock int Stats_GetConfiguredSurvivorLimit()
{
	return g_cvSurvivorLimit != null ? g_cvSurvivorLimit.IntValue : 0;
}

stock int Stats_GetConfiguredPlayerZombieLimit()
{
	return g_cvMaxPlayerZombies != null ? g_cvMaxPlayerZombies.IntValue : 0;
}

stock bool Stats_IsCompetitiveMode()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return baseMode == GAMEMODE_VERSUS || baseMode == GAMEMODE_SCAVENGE;
}

stock bool Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsCompetitiveMode() || Stats_GetConfiguredPlayerZombieLimit() <= 0)
	{
		return false;
	}

	ConVar limit = null;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			limit = g_cvVersusSmokerLimit;
		}
		case L4D2ZombieClass_Boomer:
		{
			limit = g_cvVersusBoomerLimit;
		}
		case L4D2ZombieClass_Hunter:
		{
			limit = g_cvVersusHunterLimit;
		}
		case L4D2ZombieClass_Spitter:
		{
			limit = g_cvVersusSpitterLimit;
		}
		case L4D2ZombieClass_Jockey:
		{
			limit = g_cvVersusJockeyLimit;
		}
		case L4D2ZombieClass_Charger:
		{
			limit = g_cvVersusChargerLimit;
		}
		default:
		{
			return true;
		}
	}

	return limit == null || limit.IntValue > 0;
}

stock int Stats_GetEnabledSiPoolMask()
{
	int mask = view_as<int>(PlayerStatsSiPool_None);

	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Smoker))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Smoker);
	}
	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Boomer))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Boomer);
	}
	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Hunter))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Hunter);
	}
	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Spitter))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Spitter);
	}
	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Jockey))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Jockey);
	}
	if (Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Charger))
	{
		mask |= view_as<int>(PlayerStatsSiPool_Charger);
	}

	return mask;
}

stock int Stats_CountEnabledSiClassesFromMask(int mask)
{
	int count = 0;

	if ((mask & view_as<int>(PlayerStatsSiPool_Smoker)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerStatsSiPool_Boomer)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerStatsSiPool_Hunter)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerStatsSiPool_Spitter)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerStatsSiPool_Jockey)) != 0)
	{
		count++;
	}
	if ((mask & view_as<int>(PlayerStatsSiPool_Charger)) != 0)
	{
		count++;
	}

	return count;
}

stock PlayerStatsVersusContextType Stats_ClassifyVersusContext(int survivorLimit, int playerZombieLimit, int enabledSiClassCount)
{
	if (survivorLimit <= 0 || playerZombieLimit <= 0 || survivorLimit != playerZombieLimit || enabledSiClassCount <= 0)
	{
		return PlayerStatsVersusContext_None;
	}

	switch (survivorLimit)
	{
		case 1:
		{
			return PlayerStatsVersusContext_Versus1v1;
		}
		case 2:
		{
			return PlayerStatsVersusContext_Versus2v2;
		}
		case 3:
		{
			return PlayerStatsVersusContext_Versus3v3;
		}
		case 4:
		{
			return PlayerStatsVersusContext_Versus4v4;
		}
	}

	return PlayerStatsVersusContext_CustomTeamVersus;
}

stock void Stats_BuildCurrentModeContext(PlayerStatsModeContextData context)
{
	context.Reset();
	context.baseMode = Stats_GetModeBase();
	context.isVersusMode = context.baseMode == GAMEMODE_VERSUS || context.baseMode == GAMEMODE_SCAVENGE;
	context.hasReadyUp = g_Runtime.hasReadyUp;
	context.configuredSurvivorLimit = Stats_GetConfiguredSurvivorLimit();
	context.configuredPlayerZombieLimit = Stats_GetConfiguredPlayerZombieLimit();

	switch (context.baseMode)
	{
		case GAMEMODE_COOP, GAMEMODE_VERSUS:
		{
			context.hasBosses = true;
		}
		case GAMEMODE_SCAVENGE, GAMEMODE_SURVIVAL:
		{
			context.hasBosses = false;
		}
		default:
		{
			context.hasBosses = false;
		}
	}

	context.hasRoundHalves =
		(context.baseMode == GAMEMODE_VERSUS || context.baseMode == GAMEMODE_SCAVENGE)
		&& context.configuredPlayerZombieLimit > 0;

	if (!context.isVersusMode)
	{
		return;
	}

	context.siPoolMask = Stats_GetEnabledSiPoolMask();
	context.enabledSiClassCount = Stats_CountEnabledSiClassesFromMask(context.siPoolMask);
	context.versusTeamSize = context.configuredSurvivorLimit == context.configuredPlayerZombieLimit
		? context.configuredSurvivorLimit
		: 0;
	context.versusContext = Stats_ClassifyVersusContext(
		context.configuredSurvivorLimit,
		context.configuredPlayerZombieLimit,
		context.enabledSiClassCount);
}

stock void Stats_GetLifecyclePolicyForContext(PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	policy.Reset();
	policy.baseMode = context.baseMode;

	switch (context.baseMode)
	{
		case GAMEMODE_COOP:
		{
			policy.seriesScope = PlayerStatsSeriesScope_CampaignRun;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_SafeArea;
			policy.restartPolicy = PlayerStatsRestartPolicy_CoopFailureOrTransition;
		}
		case GAMEMODE_VERSUS:
		{
			policy.seriesScope = PlayerStatsSeriesScope_VersusMatch;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = context.hasReadyUp
				? PlayerStatsRoundLiveSignal_ReadyUpOrSafeArea
				: PlayerStatsRoundLiveSignal_SafeArea;
			policy.restartPolicy = PlayerStatsRestartPolicy_CompetitiveVoteOrAdmin;
		}
		case GAMEMODE_SCAVENGE:
		{
			policy.seriesScope = PlayerStatsSeriesScope_ScavengeMatch;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_ScavengeRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_ScavengeRoundFinished;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_Immediate;
			policy.restartPolicy = PlayerStatsRestartPolicy_ScavengeVoteOrAdmin;
		}
		case GAMEMODE_SURVIVAL:
		{
			policy.seriesScope = PlayerStatsSeriesScope_SurvivalRuns;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_Immediate;
			policy.restartPolicy = PlayerStatsRestartPolicy_SurvivalRunReset;
		}
		default:
		{
			policy.seriesScope = PlayerStatsSeriesScope_CurrentMap;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_Immediate;
			policy.restartPolicy = PlayerStatsRestartPolicy_None;
		}
	}
}

stock void Stats_ApplyModeContextToRuntime(PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	g_Runtime.baseMode = context.baseMode;
	g_Runtime.hasBosses = context.hasBosses;
	g_Runtime.hasRoundHalves = context.hasRoundHalves;
	g_Runtime.configuredSurvivorLimit = context.configuredSurvivorLimit;
	g_Runtime.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	g_Runtime.siPoolMask = context.siPoolMask;
	g_Runtime.enabledSiClassCount = context.enabledSiClassCount;
	g_Runtime.versusTeamSize = context.versusTeamSize;
	g_Runtime.versusContext = context.versusContext;
	g_Runtime.seriesScope = policy.seriesScope;
	g_Runtime.roundStartSignal = policy.roundStartSignal;
	g_Runtime.roundEndSignal = policy.roundEndSignal;
	g_Runtime.roundLiveSignal = policy.roundLiveSignal;
	g_Runtime.restartPolicy = policy.restartPolicy;
}

stock void Stats_ApplyModeContextToRoundMeta(PlayerStatsRoundMetaData meta, PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	meta.baseMode = context.baseMode;
	meta.isVersusMode = context.isVersusMode;
	meta.hasBosses = context.hasBosses;
	meta.hasRoundHalves = context.hasRoundHalves;
	meta.configuredSurvivorLimit = context.configuredSurvivorLimit;
	meta.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	meta.siPoolMask = context.siPoolMask;
	meta.enabledSiClassCount = context.enabledSiClassCount;
	meta.versusTeamSize = context.versusTeamSize;
	meta.versusContext = context.versusContext;
	meta.seriesScope = policy.seriesScope;
	meta.roundStartSignal = policy.roundStartSignal;
	meta.roundEndSignal = policy.roundEndSignal;
	meta.roundLiveSignal = policy.roundLiveSignal;
	meta.restartPolicy = policy.restartPolicy;
}

stock void Stats_RefreshModeContext()
{
	PlayerStatsModeContextData context;
	PlayerStatsLifecyclePolicyData policy;
	Stats_BuildCurrentModeContext(context);
	Stats_GetLifecyclePolicyForContext(context, policy);
	Stats_ApplyModeContextToRuntime(context, policy);

	Stats_Debug(PlayerStatsDebug_Core, "Mode context refreshed. base_mode=%d series_scope=%d versus_context=%d team_size=%d survivor_limit=%d infected_limit=%d si_pool_mask=%d enabled_si=%d bosses=%d round_halves=%d", g_Runtime.baseMode, g_Runtime.seriesScope, g_Runtime.versusContext, g_Runtime.versusTeamSize, g_Runtime.configuredSurvivorLimit, g_Runtime.configuredPlayerZombieLimit, g_Runtime.siPoolMask, g_Runtime.enabledSiClassCount, g_Runtime.hasBosses, g_Runtime.hasRoundHalves);
}

/**
 * @brief Checks whether the plugin is currently enabled.
 *
 * @return               True if the enable ConVar exists and is on.
 */
stock bool Stats_IsEnabled()
{
	return g_cvEnable != null && g_cvEnable.BoolValue;
}


stock bool Stats_HasFeatureFlag(ConVar cvar, PlayerStatsFeatureFlag flag)
{
	return cvar != null && (cvar.IntValue & view_as<int>(flag)) != 0;
}


stock int Stats_GetGamemodeFlag(int baseMode)
{
	switch (baseMode)
	{
		case GAMEMODE_COOP:
		{
			return view_as<int>(PlayerStatsGamemode_Coop);
		}
		case GAMEMODE_VERSUS:
		{
			return view_as<int>(PlayerStatsGamemode_Versus);
		}
		case GAMEMODE_SCAVENGE:
		{
			return view_as<int>(PlayerStatsGamemode_Scavenge);
		}
		case GAMEMODE_SURVIVAL:
		{
			return view_as<int>(PlayerStatsGamemode_Survival);
		}
	}

	return 0;
}


stock bool Stats_IsModeEnabledForBaseMode(int baseMode)
{
	if (!Stats_IsEnabled())
	{
		return false;
	}

	if (baseMode == GAMEMODE_UNKNOWN || g_cvGamemode == null)
	{
		return true;
	}

	return (g_cvGamemode.IntValue & Stats_GetGamemodeFlag(baseMode)) != 0;
}


stock bool Stats_IsTrackingEnabled()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return Stats_IsModeEnabledForBaseMode(baseMode) && Stats_HasFeatureFlag(g_cvTracking, PlayerStatsFeature_Enable);
}


stock bool Stats_IsTrackingAnnounceEnabled()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return Stats_IsModeEnabledForBaseMode(baseMode) && Stats_HasFeatureFlag(g_cvTracking, PlayerStatsFeature_Announce);
}


stock bool Stats_IsAccuracyEnabled()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return Stats_IsModeEnabledForBaseMode(baseMode) && Stats_HasFeatureFlag(g_cvAccuracy, PlayerStatsFeature_Enable);
}


stock bool Stats_IsThrowablesEnabled()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return Stats_IsModeEnabledForBaseMode(baseMode) && Stats_HasFeatureFlag(g_cvThrowables, PlayerStatsFeature_Enable);
}


stock bool Stats_IsThrowablesAnnounceEnabled()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return Stats_IsModeEnabledForBaseMode(baseMode) && Stats_HasFeatureFlag(g_cvThrowables, PlayerStatsFeature_Announce);
}


/**
 * @brief Checks whether the current round is active and already live.
 *
 * @return               True if sensitive round statistics should be counted now.
 */
stock bool Stats_IsRoundLive()
{
	return Stats_IsEnabled() && g_Round.meta.active && g_Runtime.roundLive && !g_bRoundClosing;
}


/**
 * @brief Checks whether there is a round snapshot available to query or print.
 *
 * @return               True if the plugin is enabled and at least one round snapshot exists.
 */
stock bool Stats_HasRoundSnapshot()
{
	return Stats_IsEnabled() && g_Round.meta.id > 0;
}
