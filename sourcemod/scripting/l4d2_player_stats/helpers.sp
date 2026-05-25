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
	return Stats_IsEnabled() && g_Round.meta.active && g_Runtime.roundLive;
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

stock PlayerStatsModeBaseType Stats_GetModeBase()
{
	switch (L4D_GetGameModeType())
	{
		case GAMEMODE_COOP:
		{
			return PlayerStatsModeBase_Coop;
		}
		case GAMEMODE_VERSUS:
		{
			return PlayerStatsModeBase_Versus;
		}
		case GAMEMODE_SCAVENGE:
		{
			return PlayerStatsModeBase_Scavenge;
		}
		case GAMEMODE_SURVIVAL:
		{
			return PlayerStatsModeBase_Survival;
		}
	}

	return PlayerStatsModeBase_Unknown;
}

stock bool Stats_IsSecondHalfOfRound()
{
	return InSecondHalfOfRound();
}

stock bool Stats_IsCoopMode()
{
	return Stats_GetModeBase() == PlayerStatsModeBase_Coop;
}

stock bool Stats_IsVersusMode()
{
	return Stats_GetModeBase() == PlayerStatsModeBase_Versus;
}

stock bool Stats_IsScavengeMode()
{
	return Stats_GetModeBase() == PlayerStatsModeBase_Scavenge;
}

stock bool Stats_IsSurvivalMode()
{
	return Stats_GetModeBase() == PlayerStatsModeBase_Survival;
}

stock int Stats_GetConfiguredSurvivorLimit()
{
	return g_cvSurvivorLimit != null ? g_cvSurvivorLimit.IntValue : 0;
}

stock int Stats_GetConfiguredPlayerZombieLimit()
{
	return g_cvMaxPlayerZombies != null ? g_cvMaxPlayerZombies.IntValue : 0;
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

stock bool Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsVersusMode())
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

stock void Stats_GetModeBaseName(PlayerStatsModeBaseType baseMode, char[] buffer, int maxlen)
{
	switch (baseMode)
	{
		case PlayerStatsModeBase_Coop:
		{
			strcopy(buffer, maxlen, "Coop");
		}
		case PlayerStatsModeBase_Versus:
		{
			strcopy(buffer, maxlen, "Versus");
		}
		case PlayerStatsModeBase_Scavenge:
		{
			strcopy(buffer, maxlen, "Scavenge");
		}
		case PlayerStatsModeBase_Survival:
		{
			strcopy(buffer, maxlen, "Survival");
		}
		default:
		{
			strcopy(buffer, maxlen, "Unknown");
		}
	}
}

stock void Stats_GetHistoryScopeName(PlayerStatsHistoryScopeType scope, char[] buffer, int maxlen)
{
	switch (scope)
	{
		case PlayerStatsHistoryScope_CurrentMap:
		{
			strcopy(buffer, maxlen, "CurrentMap");
		}
		case PlayerStatsHistoryScope_CampaignRun:
		{
			strcopy(buffer, maxlen, "CampaignRun");
		}
		case PlayerStatsHistoryScope_CompetitiveSeries:
		{
			strcopy(buffer, maxlen, "CompetitiveSeries");
		}
		case PlayerStatsHistoryScope_ScavengeMatch:
		{
			strcopy(buffer, maxlen, "ScavengeMatch");
		}
		case PlayerStatsHistoryScope_SurvivalRuns:
		{
			strcopy(buffer, maxlen, "SurvivalRuns");
		}
		default:
		{
			strcopy(buffer, maxlen, "None");
		}
	}
}

stock PlayerStatsVersusContextType Stats_ClassifyVersusContext(int survivorLimit, int playerZombieLimit, int siPoolMask, int enabledSiClassCount)
{
	if (!Stats_IsVersusMode() || survivorLimit <= 0 || playerZombieLimit <= 0 || survivorLimit != playerZombieLimit || enabledSiClassCount <= 0)
	{
		return PlayerStatsVersusContext_None;
	}

	if (survivorLimit == 1 && enabledSiClassCount == 1)
	{
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Hunter)) != 0)
		{
			return PlayerStatsVersusContext_Hunter1v1;
		}
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Smoker)) != 0)
		{
			return PlayerStatsVersusContext_Smoker1v1;
		}
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Boomer)) != 0)
		{
			return PlayerStatsVersusContext_Boomer1v1;
		}
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Spitter)) != 0)
		{
			return PlayerStatsVersusContext_Spitter1v1;
		}
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Jockey)) != 0)
		{
			return PlayerStatsVersusContext_Jockey1v1;
		}
		if ((siPoolMask & view_as<int>(PlayerStatsSiPool_Charger)) != 0)
		{
			return PlayerStatsVersusContext_Charger1v1;
		}
	}

	switch (survivorLimit)
	{
		case 1:
		{
			return PlayerStatsVersusContext_MixedPool1v1;
		}
		case 2:
		{
			return PlayerStatsVersusContext_MixedPool2v2;
		}
		case 3:
		{
			return PlayerStatsVersusContext_MixedPool3v3;
		}
		case 4:
		{
			return PlayerStatsVersusContext_Versus4v4;
		}
	}

	return PlayerStatsVersusContext_CustomTeamVersus;
}

stock void Stats_GetVersusContextName(PlayerStatsVersusContextType context, char[] buffer, int maxlen)
{
	switch (context)
	{
		case PlayerStatsVersusContext_Hunter1v1:
		{
			strcopy(buffer, maxlen, "Hunter1v1");
		}
		case PlayerStatsVersusContext_Smoker1v1:
		{
			strcopy(buffer, maxlen, "Smoker1v1");
		}
		case PlayerStatsVersusContext_Boomer1v1:
		{
			strcopy(buffer, maxlen, "Boomer1v1");
		}
		case PlayerStatsVersusContext_Spitter1v1:
		{
			strcopy(buffer, maxlen, "Spitter1v1");
		}
		case PlayerStatsVersusContext_Jockey1v1:
		{
			strcopy(buffer, maxlen, "Jockey1v1");
		}
		case PlayerStatsVersusContext_Charger1v1:
		{
			strcopy(buffer, maxlen, "Charger1v1");
		}
		case PlayerStatsVersusContext_MixedPool1v1:
		{
			strcopy(buffer, maxlen, "MixedPool1v1");
		}
		case PlayerStatsVersusContext_MixedPool2v2:
		{
			strcopy(buffer, maxlen, "MixedPool2v2");
		}
		case PlayerStatsVersusContext_MixedPool3v3:
		{
			strcopy(buffer, maxlen, "MixedPool3v3");
		}
		case PlayerStatsVersusContext_Versus4v4:
		{
			strcopy(buffer, maxlen, "Versus4v4");
		}
		case PlayerStatsVersusContext_CustomTeamVersus:
		{
			strcopy(buffer, maxlen, "CustomTeamVersus");
		}
		default:
		{
			strcopy(buffer, maxlen, "None");
		}
	}
}

stock void Stats_BuildCurrentModeContext(PlayerStatsModeContextData context)
{
	context.Reset();
	context.baseMode = Stats_GetModeBase();
	context.isVersusMode = context.baseMode == PlayerStatsModeBase_Versus;
	context.readyUpAvailable = g_Runtime.readyUpAvailable;
	context.configuredSurvivorLimit = Stats_GetConfiguredSurvivorLimit();
	context.configuredPlayerZombieLimit = Stats_GetConfiguredPlayerZombieLimit();

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
		context.siPoolMask,
		context.enabledSiClassCount);
}

stock void Stats_GetLifecyclePolicyForContext(PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	policy.Reset();
	policy.baseMode = context.baseMode;

	switch (context.baseMode)
	{
		case PlayerStatsModeBase_Coop:
		{
			policy.historyScope = PlayerStatsHistoryScope_CampaignRun;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_SafeArea;
			policy.restartPolicy = PlayerStatsRestartPolicy_CoopFailureOrTransition;
		}
		case PlayerStatsModeBase_Versus:
		{
			policy.historyScope = PlayerStatsHistoryScope_CompetitiveSeries;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = context.readyUpAvailable
				? PlayerStatsRoundLiveSignal_ReadyUpOrSafeArea
				: PlayerStatsRoundLiveSignal_SafeArea;
			policy.restartPolicy = PlayerStatsRestartPolicy_CompetitiveVoteOrAdmin;
		}
		case PlayerStatsModeBase_Scavenge:
		{
			policy.historyScope = PlayerStatsHistoryScope_ScavengeMatch;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_ScavengeRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_ScavengeRoundFinished;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_Immediate;
			policy.restartPolicy = PlayerStatsRestartPolicy_ScavengeVoteOrAdmin;
		}
		case PlayerStatsModeBase_Survival:
		{
			policy.historyScope = PlayerStatsHistoryScope_SurvivalRuns;
			policy.roundStartSignal = PlayerStatsRoundStartSignal_GenericRoundStart;
			policy.roundEndSignal = PlayerStatsRoundEndSignal_GenericRoundEnd;
			policy.roundLiveSignal = PlayerStatsRoundLiveSignal_Immediate;
			policy.restartPolicy = PlayerStatsRestartPolicy_SurvivalRunReset;
		}
		default:
		{
			policy.historyScope = PlayerStatsHistoryScope_CurrentMap;
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
	g_Runtime.configuredSurvivorLimit = context.configuredSurvivorLimit;
	g_Runtime.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	g_Runtime.siPoolMask = context.siPoolMask;
	g_Runtime.enabledSiClassCount = context.enabledSiClassCount;
	g_Runtime.versusTeamSize = context.versusTeamSize;
	g_Runtime.versusContext = context.versusContext;
	g_Runtime.historyScope = policy.historyScope;
	g_Runtime.roundStartSignal = policy.roundStartSignal;
	g_Runtime.roundEndSignal = policy.roundEndSignal;
	g_Runtime.roundLiveSignal = policy.roundLiveSignal;
	g_Runtime.restartPolicy = policy.restartPolicy;
}

stock void Stats_ApplyModeContextToRoundMeta(PlayerStatsRoundMetaData meta, PlayerStatsModeContextData context, PlayerStatsLifecyclePolicyData policy)
{
	meta.baseMode = context.baseMode;
	meta.isVersusMode = context.isVersusMode;
	meta.configuredSurvivorLimit = context.configuredSurvivorLimit;
	meta.configuredPlayerZombieLimit = context.configuredPlayerZombieLimit;
	meta.siPoolMask = context.siPoolMask;
	meta.enabledSiClassCount = context.enabledSiClassCount;
	meta.versusTeamSize = context.versusTeamSize;
	meta.versusContext = context.versusContext;
	meta.historyScope = policy.historyScope;
	meta.roundStartSignal = policy.roundStartSignal;
	meta.roundEndSignal = policy.roundEndSignal;
	meta.roundLiveSignal = policy.roundLiveSignal;
	meta.restartPolicy = policy.restartPolicy;
}

stock bool Stats_ShouldHandleRoundStartEvent(const char[] eventName)
{
	switch (g_Runtime.roundStartSignal)
	{
		case PlayerStatsRoundStartSignal_ScavengeRoundStart:
		{
			return StrEqual(eventName, "scavenge_round_start", false);
		}
		case PlayerStatsRoundStartSignal_GenericRoundStart:
		{
			return StrEqual(eventName, "round_start", false);
		}
	}

	return false;
}

stock bool Stats_ShouldHandleRoundEndEvent(const char[] eventName)
{
	switch (g_Runtime.roundEndSignal)
	{
		case PlayerStatsRoundEndSignal_ScavengeRoundFinished:
		{
			return StrEqual(eventName, "scavenge_round_finished", false);
		}
		case PlayerStatsRoundEndSignal_GenericRoundEnd:
		{
			return StrEqual(eventName, "round_end", false);
		}
	}

	return false;
}

stock void Stats_RefreshModeContext()
{
	PlayerStatsModeContextData context;
	PlayerStatsLifecyclePolicyData policy;
	Stats_BuildCurrentModeContext(context);
	Stats_GetLifecyclePolicyForContext(context, policy);
	Stats_ApplyModeContextToRuntime(context, policy);

	char baseModeName[24];
	char contextName[32];
	char historyScopeName[24];
	Stats_GetModeBaseName(g_Runtime.baseMode, baseModeName, sizeof(baseModeName));
	Stats_GetVersusContextName(g_Runtime.versusContext, contextName, sizeof(contextName));
	Stats_GetHistoryScopeName(g_Runtime.historyScope, historyScopeName, sizeof(historyScopeName));
	Stats_Debug(PlayerStatsDebug_Core, "Mode context refreshed. base=%s history=%s context=%s team_size=%d survivor_limit=%d infected_limit=%d si_pool_mask=%d enabled_si=%d",
		baseModeName,
		historyScopeName,
		contextName,
		g_Runtime.versusTeamSize,
		g_Runtime.configuredSurvivorLimit,
		g_Runtime.configuredPlayerZombieLimit,
		g_Runtime.siPoolMask,
		g_Runtime.enabledSiClassCount);
}

stock void Stats_RefreshVersusContext()
{
	Stats_RefreshModeContext();
}

stock bool Stats_IsSkillTypeEnabledInCurrentMode(L4D2SkillType type)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee, L4D2Skill_HunterDeadstop, L4D2Skill_HunterHighPounce:
		{
			return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Hunter) : true;
		}
		case L4D2Skill_BoomerPop, L4D2Skill_BoomerVomitLanded:
		{
			return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Boomer) : true;
		}
		case L4D2Skill_ChargerLevel, L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup:
		{
			return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Charger) : true;
		}
		case L4D2Skill_SmokerTongueCut, L4D2Skill_SmokerSelfClear:
		{
			return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Smoker) : true;
		}
		case L4D2Skill_JockeyHighPounce:
		{
			return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Jockey) : true;
		}
	}

	return true;
}

stock bool Stats_IsZombieClassEnabledInCurrentMode(L4D2ZombieClassType zombieClass)
{
	return Stats_IsVersusMode() ? Stats_IsVersusSpecialLimitEnabled(zombieClass) : true;
}

stock bool Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClassType zombieClass, bool isVersusMode, int siPoolMask)
{
	if (!isVersusMode)
	{
		return true;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Smoker)) != 0;
		}
		case L4D2ZombieClass_Boomer:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Boomer)) != 0;
		}
		case L4D2ZombieClass_Hunter:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Hunter)) != 0;
		}
		case L4D2ZombieClass_Spitter:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Spitter)) != 0;
		}
		case L4D2ZombieClass_Jockey:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Jockey)) != 0;
		}
		case L4D2ZombieClass_Charger:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Charger)) != 0;
		}
	}

	return true;
}

stock bool Stats_IsZombieClassEnabledForRound(L4D2ZombieClassType zombieClass)
{
	return Stats_IsZombieClassEnabledForSnapshot(zombieClass, g_Round.meta.isVersusMode, g_Round.meta.siPoolMask);
}

stock bool Stats_IsSkillTypeEnabledForSnapshot(L4D2SkillType type, bool isVersusMode, int siPoolMask)
{
	switch (type)
	{
		case L4D2Skill_HunterSkeet, L4D2Skill_HunterSkeetMelee, L4D2Skill_HunterDeadstop, L4D2Skill_HunterHighPounce:
		{
			return Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClass_Hunter, isVersusMode, siPoolMask);
		}
		case L4D2Skill_BoomerPop, L4D2Skill_BoomerVomitLanded:
		{
			return Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClass_Boomer, isVersusMode, siPoolMask);
		}
		case L4D2Skill_ChargerLevel, L4D2Skill_ChargerInstaKill, L4D2Skill_ChargerDeathSetup:
		{
			return Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClass_Charger, isVersusMode, siPoolMask);
		}
		case L4D2Skill_SmokerTongueCut, L4D2Skill_SmokerSelfClear:
		{
			return Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClass_Smoker, isVersusMode, siPoolMask);
		}
		case L4D2Skill_JockeyHighPounce:
		{
			return Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClass_Jockey, isVersusMode, siPoolMask);
		}
	}

	return true;
}

stock bool Stats_IsSkillTypeEnabledForRound(L4D2SkillType type)
{
	return Stats_IsSkillTypeEnabledForSnapshot(type, g_Round.meta.isVersusMode, g_Round.meta.siPoolMask);
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
 * @brief Checks whether a specific debug category is enabled in the bitmask ConVar.
 *
 * @param category       Bitmask category from PlayerStatsDebugCategory.
 *
 * @return               True if that category is enabled.
 */
stock bool Stats_IsDebugEnabled(PlayerStatsDebugCategory category)
{
	if (g_cvDebug == null)
	{
		return false;
	}

	int mask = g_cvDebug.IntValue;
	return (mask & view_as<int>(category)) != 0;
}

/**
 * @brief Writes a formatted debug line when the selected category is enabled.
 *
 * @param category       Bitmask category from PlayerStatsDebugCategory.
 * @param fmt            Format string.
 * @param ...            Format arguments.
 *
 * @noreturn
 */
stock void Stats_Debug(PlayerStatsDebugCategory category, const char[] fmt, any...)
{
	if (!Stats_IsDebugEnabled(category))
	{
		return;
	}

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 3);
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
			g_Round.players[index].combat.smokerDamage += damage;
			g_Round.totals.survivorTotalSmokerDamage += damage;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combat.boomerDamage += damage;
			g_Round.totals.survivorTotalBoomerDamage += damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combat.hunterDamage += damage;
			g_Round.totals.survivorTotalHunterDamage += damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combat.spitterDamage += damage;
			g_Round.totals.survivorTotalSpitterDamage += damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combat.jockeyDamage += damage;
			g_Round.totals.survivorTotalJockeyDamage += damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combat.chargerDamage += damage;
			g_Round.totals.survivorTotalChargerDamage += damage;
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
			g_Round.players[index].combat.smokerKills++;
			g_Round.totals.survivorTotalSmokerKills++;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combat.boomerKills++;
			g_Round.totals.survivorTotalBoomerKills++;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combat.hunterKills++;
			g_Round.totals.survivorTotalHunterKills++;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combat.spitterKills++;
			g_Round.totals.survivorTotalSpitterKills++;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combat.jockeyKills++;
			g_Round.totals.survivorTotalJockeyKills++;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combat.chargerKills++;
			g_Round.totals.survivorTotalChargerKills++;
		}
		case L4D2ZombieClass_Tank:
		{
			g_Round.players[index].combat.tankKills++;
			g_Round.totals.survivorTotalTankKills++;
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
		g_Runtime.playerSlotByClient[client] = -1;
		g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
	}
}

stock PlayerStatsWeaponFamily Stats_GetWeaponFamily(const char[] weapon)
{
	if (weapon[0] == '\0')
	{
		return PlayerStatsWeaponFamily_None;
	}

	char normalized[64];
	if (strncmp(weapon, "weapon_", 7, false) == 0)
	{
		strcopy(normalized, sizeof(normalized), weapon);
	}
	else
	{
		Format(normalized, sizeof(normalized), "weapon_%s", weapon);
	}

	switch (WeaponNameToId(normalized))
	{
		case WEPID_PUMPSHOTGUN, WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_CHROME, WEPID_SHOTGUN_SPAS:
		{
			return PlayerStatsWeaponFamily_Shotgun;
		}
		case WEPID_SMG, WEPID_RIFLE, WEPID_SMG_SILENCED, WEPID_RIFLE_DESERT, WEPID_SMG_MP5, WEPID_RIFLE_AK47, WEPID_RIFLE_SG552, WEPID_RIFLE_M60:
		{
			return PlayerStatsWeaponFamily_SmgRifle;
		}
		case WEPID_HUNTING_RIFLE, WEPID_SNIPER_MILITARY, WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT:
		{
			return PlayerStatsWeaponFamily_Sniper;
		}
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM:
		{
			return PlayerStatsWeaponFamily_Pistol;
		}
	}

	return PlayerStatsWeaponFamily_None;
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

stock void Stats_RecordAccuracyShot(int index, PlayerStatsWeaponFamily family)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (family)
	{
		case PlayerStatsWeaponFamily_Shotgun:
		{
			g_Round.players[index].accuracy.shotgunShots++;
		}
		case PlayerStatsWeaponFamily_SmgRifle:
		{
			g_Round.players[index].accuracy.smgRifleShots++;
		}
		case PlayerStatsWeaponFamily_Sniper:
		{
			g_Round.players[index].accuracy.sniperShots++;
		}
		case PlayerStatsWeaponFamily_Pistol:
		{
			g_Round.players[index].accuracy.pistolShots++;
		}
	}
}

stock void Stats_RecordAccuracyHit(int index, PlayerStatsWeaponFamily family, bool headshot = false)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (family)
	{
		case PlayerStatsWeaponFamily_Shotgun:
		{
			g_Round.players[index].accuracy.shotgunHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.shotgunHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_SmgRifle:
		{
			g_Round.players[index].accuracy.smgRifleHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.smgRifleHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_Sniper:
		{
			g_Round.players[index].accuracy.sniperHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.sniperHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_Pistol:
		{
			g_Round.players[index].accuracy.pistolHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.pistolHeadshots++;
			}
		}
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

	g_Runtime.playerSlotByClient[client] = slot;
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

stock void Stats_RegisterTankVictim(int client)
{
	if (!IsValidClient(client))
	{
		return;
	}

	int userid = GetClientUserId(client);
	if (userid <= 0)
	{
		return;
	}

	for (int i = 0; i < g_Round.tankVictimCount; i++)
	{
		if (g_Round.tankVictimUserIds[i] == userid)
		{
			return;
		}
	}

	if (g_Round.tankVictimCount >= L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES)
	{
		return;
	}

	g_Round.tankVictimUserIds[g_Round.tankVictimCount++] = userid;
}

stock void Stats_RegisterWitchEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return;
	}

	for (int i = 0; i < g_Round.witchEntityCount; i++)
	{
		if (g_Round.witchEntityIds[i] == entity)
		{
			return;
		}
	}

	if (g_Round.witchEntityCount >= L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES)
	{
		return;
	}

	g_Round.witchEntityIds[g_Round.witchEntityCount++] = entity;
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

	int slot = g_Runtime.playerSlotByClient[client];
	if (Stats_IsValidRoundSlot(slot))
	{
		g_Round.players[slot].player.DetachClient();
	}

	g_Runtime.playerSlotByClient[client] = -1;
	g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
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
		g_Runtime.playerSlotByClient[player] = -1;
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
		g_Runtime.playerSlotByClient[bot] = -1;
	}

	Stats_AssignClientToSlot(player, slot);
}
