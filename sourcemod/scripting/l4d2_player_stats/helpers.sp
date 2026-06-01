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

stock void Stats_ClearConfoglConVars()
{
	g_cvConfoglAdrenalineLimit = null;
	g_cvConfoglPipebombLimit = null;
	g_cvConfoglMolotovLimit = null;
	g_cvConfoglVomitjarLimit = null;
	g_cvConfoglRemoveDefib = null;
}

stock void Stats_RefreshReadyUpConVars()
{
	if (!g_Runtime.hasReadyUp)
	{
		g_cvReadyCfgName = null;
		return;
	}

	g_cvReadyCfgName = FindConVar("l4d_ready_cfg_name");
}

stock void Stats_RefreshConfoglConVars()
{
	if (!g_Runtime.hasConfogl)
	{
		Stats_ClearConfoglConVars();
		return;
	}

	g_cvConfoglAdrenalineLimit = FindConVar("confogl_adrenaline_limit");
	g_cvConfoglPipebombLimit = FindConVar("confogl_pipebomb_limit");
	g_cvConfoglMolotovLimit = FindConVar("confogl_molotov_limit");
	g_cvConfoglVomitjarLimit = FindConVar("confogl_vomitjar_limit");
	g_cvConfoglRemoveDefib = FindConVar("confogl_remove_defib");
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

stock bool Stats_IsCompetitiveMode()
{
	int baseMode = g_Round.meta.baseMode != GAMEMODE_UNKNOWN ? g_Round.meta.baseMode : g_Runtime.baseMode;
	return baseMode == GAMEMODE_VERSUS || baseMode == GAMEMODE_SCAVENGE;
}

stock int Stats_GetValidDamagePolicy(ConVar cvar)
{
	return cvar != null ? cvar.IntValue : view_as<int>(PlayerStatsValidDamage_ExcludeIncap) | view_as<int>(PlayerStatsValidDamage_ExcludeLedge);
}

stock bool Stats_ShouldCountVictimForDamage(int victim, ConVar cvar)
{
	if (!IsValidSurvivor(victim))
	{
		return false;
	}

	int policy = Stats_GetValidDamagePolicy(cvar);
	if ((policy & view_as<int>(PlayerStatsValidDamage_ExcludeIncap)) != 0 && Stats_IsSurvivorIncapacitated(victim))
	{
		return false;
	}

	if ((policy & view_as<int>(PlayerStatsValidDamage_ExcludeLedge)) != 0 && Stats_IsSurvivorHanging(victim))
	{
		return false;
	}

	return true;
}

stock bool Stats_IsSurvivorIncapacitated(int client)
{
	return IsValidSurvivor(client) && GetEntProp(client, Prop_Send, "m_isIncapacitated") != 0;
}

stock bool Stats_IsSurvivorHanging(int client)
{
	return IsValidSurvivor(client) && GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0;
}

stock int Stats_GetSurvivorCurrentHealthTotal(int client)
{
	if (!IsValidSurvivor(client))
	{
		return 0;
	}

	float tempHealth = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	int total = GetClientHealth(client) + RoundToFloor(tempHealth);
	return total > 0 ? total : 0;
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
	if (!Stats_IsMode(GAMEMODE_VERSUS))
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
	if (!Stats_IsMode(GAMEMODE_VERSUS) || survivorLimit <= 0 || playerZombieLimit <= 0 || survivorLimit != playerZombieLimit || enabledSiClassCount <= 0)
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
	context.isVersusMode = context.baseMode == GAMEMODE_VERSUS;
	context.hasReadyUp = g_Runtime.hasReadyUp;
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
			policy.seriesScope = PlayerStatsSeriesScope_CompetitiveSeries;
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

stock int Stats_GetScavengeRoundNumber()
{
	return Stats_IsMode(GAMEMODE_SCAVENGE) ? GameRules_GetProp("m_nRoundNumber") : 0;
}

stock bool Stats_IsScavengeSecondHalf()
{
	return Stats_IsMode(GAMEMODE_SCAVENGE) ? view_as<bool>(GameRules_GetProp("m_bInSecondHalfOfRound")) : false;
}

stock void Stats_RefreshScavengeRoundMetaState(PlayerStatsRoundMetaData meta)
{
	if (meta.baseMode != GAMEMODE_SCAVENGE)
	{
		meta.scavengeRoundNumber = 0;
		meta.scavengeInSecondHalf = false;
		meta.scavengeItemsGoal = 0;
		meta.scavengeWentOvertime = false;
		meta.scavengeScoreTied = false;
		return;
	}

	meta.scavengeRoundNumber = Stats_GetScavengeRoundNumber();
	meta.scavengeInSecondHalf = Stats_IsScavengeSecondHalf();
	meta.scavengeItemsGoal = GameRules_GetProp("m_nScavengeItemsGoal");
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

	Stats_Debug(PlayerStatsDebug_Core, "Mode context refreshed. base_mode=%d series_scope=%d versus_context=%d team_size=%d survivor_limit=%d infected_limit=%d si_pool_mask=%d enabled_si=%d", g_Runtime.baseMode, g_Runtime.seriesScope, g_Runtime.versusContext, g_Runtime.versusTeamSize, g_Runtime.configuredSurvivorLimit, g_Runtime.configuredPlayerZombieLimit, g_Runtime.siPoolMask, g_Runtime.enabledSiClassCount);
}

stock bool Stats_IsSkillTypeEnabledInCurrentMode(L4D2ApiSkillType type)
{
	switch (type)
	{
		case L4D2ApiSkill_HunterSkeet, L4D2ApiSkill_HunterSkeetMelee, L4D2ApiSkill_HunterDeadstop, L4D2ApiSkill_HunterHighPounce:
		{
			return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Hunter) : true;
		}
		case L4D2ApiSkill_BoomerPop, L4D2ApiSkill_BoomerVomitLanded:
		{
			return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Boomer) : true;
		}
		case L4D2ApiSkill_ChargerLevel, L4D2ApiSkill_ChargerInstaKill, L4D2ApiSkill_ChargerDeathSetup:
		{
			return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Charger) : true;
		}
		case L4D2ApiSkill_SmokerTongueCut, L4D2ApiSkill_SmokerSelfClear:
		{
			return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Smoker) : true;
		}
		case L4D2ApiSkill_JockeyHighPounce:
		{
			return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Jockey) : true;
		}
	}

	return true;
}

stock bool Stats_IsZombieClassEnabledInCurrentMode(L4D2ZombieClassType zombieClass)
{
	return Stats_IsMode(GAMEMODE_VERSUS) ? Stats_IsVersusSpecialLimitEnabled(zombieClass) : true;
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
	LogToFileEx(g_sDebugLogPath, "tick=%d %s", GetGameTickCount(), buffer);
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

stock void Stats_AddWitchKill(int index)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	g_Round.players[index].combat.witchKills++;
	g_Round.totals.survivorTotalWitchKills++;
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
		g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
	}
}

stock void Stats_AddSpecialKillAssistByClass(int index, L4D2ZombieClassType zombieClass)
{
	if (!Stats_IsValidRoundSlot(index))
	{
		return;
	}

	g_Round.players[index].combatAssists.siKillAssists++;
	g_Round.totals.survivorTotalSiKillAssists++;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combatAssists.smokerKillAssists++;
			g_Round.totals.survivorTotalSmokerKillAssists++;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combatAssists.boomerKillAssists++;
			g_Round.totals.survivorTotalBoomerKillAssists++;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combatAssists.hunterKillAssists++;
			g_Round.totals.survivorTotalHunterKillAssists++;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combatAssists.spitterKillAssists++;
			g_Round.totals.survivorTotalSpitterKillAssists++;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combatAssists.jockeyKillAssists++;
			g_Round.totals.survivorTotalJockeyKillAssists++;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combatAssists.chargerKillAssists++;
			g_Round.totals.survivorTotalChargerKillAssists++;
		}
	}
}

stock void Stats_AddSpecialAssistDamageByClass(int index, L4D2ZombieClassType zombieClass, int damage)
{
	if (!Stats_IsValidRoundSlot(index) || damage <= 0)
	{
		return;
	}

	g_Round.players[index].combatAssists.siAssistDamage += damage;
	g_Round.totals.survivorTotalSiAssistDamage += damage;

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			g_Round.players[index].combatAssists.smokerAssistDamage += damage;
			g_Round.totals.survivorTotalSmokerAssistDamage += damage;
		}
		case L4D2ZombieClass_Boomer:
		{
			g_Round.players[index].combatAssists.boomerAssistDamage += damage;
			g_Round.totals.survivorTotalBoomerAssistDamage += damage;
		}
		case L4D2ZombieClass_Hunter:
		{
			g_Round.players[index].combatAssists.hunterAssistDamage += damage;
			g_Round.totals.survivorTotalHunterAssistDamage += damage;
		}
		case L4D2ZombieClass_Spitter:
		{
			g_Round.players[index].combatAssists.spitterAssistDamage += damage;
			g_Round.totals.survivorTotalSpitterAssistDamage += damage;
		}
		case L4D2ZombieClass_Jockey:
		{
			g_Round.players[index].combatAssists.jockeyAssistDamage += damage;
			g_Round.totals.survivorTotalJockeyAssistDamage += damage;
		}
		case L4D2ZombieClass_Charger:
		{
			g_Round.players[index].combatAssists.chargerAssistDamage += damage;
			g_Round.totals.survivorTotalChargerAssistDamage += damage;
		}
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

stock PlayerStatsWeaponDetailType Stats_GetWeaponDetailType(const char[] weapon)
{
	if (weapon[0] == '\0')
	{
		return PlayerStatsWeaponDetail_None;
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
		case WEPID_PUMPSHOTGUN:
		{
			return PlayerStatsWeaponDetail_PumpShotgun;
		}
		case WEPID_AUTOSHOTGUN:
		{
			return PlayerStatsWeaponDetail_Autoshotgun;
		}
		case WEPID_SHOTGUN_CHROME:
		{
			return PlayerStatsWeaponDetail_ChromeShotgun;
		}
		case WEPID_SHOTGUN_SPAS:
		{
			return PlayerStatsWeaponDetail_SpasShotgun;
		}
		case WEPID_SMG:
		{
			return PlayerStatsWeaponDetail_Smg;
		}
		case WEPID_SMG_SILENCED:
		{
			return PlayerStatsWeaponDetail_SmgSilenced;
		}
		case WEPID_SMG_MP5:
		{
			return PlayerStatsWeaponDetail_SmgMp5;
		}
		case WEPID_RIFLE:
		{
			return PlayerStatsWeaponDetail_Rifle;
		}
		case WEPID_RIFLE_AK47:
		{
			return PlayerStatsWeaponDetail_RifleAk47;
		}
		case WEPID_RIFLE_DESERT:
		{
			return PlayerStatsWeaponDetail_RifleDesert;
		}
		case WEPID_RIFLE_SG552:
		{
			return PlayerStatsWeaponDetail_RifleSg552;
		}
		case WEPID_RIFLE_M60:
		{
			return PlayerStatsWeaponDetail_RifleM60;
		}
		case WEPID_HUNTING_RIFLE:
		{
			return PlayerStatsWeaponDetail_HuntingRifle;
		}
		case WEPID_SNIPER_MILITARY:
		{
			return PlayerStatsWeaponDetail_SniperMilitary;
		}
		case WEPID_SNIPER_AWP:
		{
			return PlayerStatsWeaponDetail_SniperAwp;
		}
		case WEPID_SNIPER_SCOUT:
		{
			return PlayerStatsWeaponDetail_SniperScout;
		}
		case WEPID_PISTOL:
		{
			return PlayerStatsWeaponDetail_Pistol;
		}
		case WEPID_PISTOL_MAGNUM:
		{
			return PlayerStatsWeaponDetail_Magnum;
		}
	}

	return PlayerStatsWeaponDetail_None;
}

stock PlayerStatsWeaponFamily Stats_GetWeaponFamilyFromDetail(PlayerStatsWeaponDetailType detail)
{
	switch (detail)
	{
		case PlayerStatsWeaponDetail_PumpShotgun, PlayerStatsWeaponDetail_Autoshotgun, PlayerStatsWeaponDetail_ChromeShotgun, PlayerStatsWeaponDetail_SpasShotgun:
		{
			return PlayerStatsWeaponFamily_Shotgun;
		}
		case PlayerStatsWeaponDetail_Smg, PlayerStatsWeaponDetail_SmgSilenced, PlayerStatsWeaponDetail_SmgMp5,
			PlayerStatsWeaponDetail_Rifle, PlayerStatsWeaponDetail_RifleAk47, PlayerStatsWeaponDetail_RifleDesert, PlayerStatsWeaponDetail_RifleSg552, PlayerStatsWeaponDetail_RifleM60:
		{
			return PlayerStatsWeaponFamily_SmgRifle;
		}
		case PlayerStatsWeaponDetail_HuntingRifle, PlayerStatsWeaponDetail_SniperMilitary, PlayerStatsWeaponDetail_SniperAwp, PlayerStatsWeaponDetail_SniperScout:
		{
			return PlayerStatsWeaponFamily_Sniper;
		}
		case PlayerStatsWeaponDetail_Pistol, PlayerStatsWeaponDetail_Magnum:
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

stock void Stats_RecordAccuracyShot(int index, PlayerStatsWeaponFamily family)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index))
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

stock void Stats_RecordAccuracyDetailShot(int index, PlayerStatsWeaponDetailType detail)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index) || detail <= PlayerStatsWeaponDetail_None || detail >= PlayerStatsWeaponDetail_Count)
	{
		return;
	}

	g_Round.players[index].accuracyDetails.shots[detail]++;
}

stock void Stats_RecordAccuracyHit(int index, PlayerStatsWeaponFamily family, bool headshot = false)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index))
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

stock void Stats_RecordAccuracyDetailHit(int index, PlayerStatsWeaponDetailType detail, bool headshot = false)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index) || detail <= PlayerStatsWeaponDetail_None || detail >= PlayerStatsWeaponDetail_Count)
	{
		return;
	}

	g_Round.players[index].accuracyDetails.hits[detail]++;
	if (headshot)
	{
		g_Round.players[index].accuracyDetails.headshots[detail]++;
	}
}

stock void Stats_GetWeaponDetailName(PlayerStatsWeaponDetailType detail, char[] buffer, int maxlen)
{
	static const char g_PlayerStatsWeaponDetailNames[PlayerStatsWeaponDetail_Count][] =
	{
		"Unknown",
		"Pump",
		"Auto Shotgun",
		"Chrome",
		"SPAS Shotgun",
		"Uzi",
		"Silenced SMG",
		"MP5",
		"M-16",
		"AK-47",
		"Desert Rifle",
		"SG552",
		"M60",
		"Hunting Rifle",
		"Military Sniper",
		"AWP",
		"Scout",
		"Pistol",
		"Magnum"
	};

	if (detail >= PlayerStatsWeaponDetail_None && detail < PlayerStatsWeaponDetail_Count)
	{
		strcopy(buffer, maxlen, g_PlayerStatsWeaponDetailNames[detail]);
		return;
	}

	strcopy(buffer, maxlen, "Unknown");
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

stock void Stats_AssignBotToSlotPreserveIdentity(int bot, int slot)
{
	if (!IsValidClient(bot) || !Stats_IsValidRoundSlot(slot))
	{
		return;
	}

	g_Runtime.playerSlotByClient[bot] = slot;
	g_Round.players[slot].player.client = bot;
	g_Round.players[slot].player.userid = GetClientUserId(bot);
	g_Round.players[slot].player.bot = true;
	g_Round.players[slot].player.character = (L4D_GetClientTeam(bot) == L4DTeam_Survivor)
		? GetEntProp(bot, Prop_Send, "m_survivorCharacter")
		: -1;
	g_Round.players[slot].team = Stats_GetPlayerTeam(bot);
}

stock void Stats_SubtractPlayerRoundDataFromTotals(PlayerStatsPlayerRoundData playerData)
{
	g_Round.totals.survivorTotalSiDamage -= playerData.combat.siDamage;
	g_Round.totals.survivorTotalSmokerDamage -= playerData.combat.smokerDamage;
	g_Round.totals.survivorTotalBoomerDamage -= playerData.combat.boomerDamage;
	g_Round.totals.survivorTotalHunterDamage -= playerData.combat.hunterDamage;
	g_Round.totals.survivorTotalSpitterDamage -= playerData.combat.spitterDamage;
	g_Round.totals.survivorTotalJockeyDamage -= playerData.combat.jockeyDamage;
	g_Round.totals.survivorTotalChargerDamage -= playerData.combat.chargerDamage;
	g_Round.totals.survivorTotalTankDamage -= playerData.combat.tankDamage;
	g_Round.totals.survivorTotalWitchDamage -= playerData.combat.witchDamage;
	g_Round.totals.survivorTotalCommonKills -= playerData.combat.commonKills;
	g_Round.totals.survivorTotalSmokerKills -= playerData.combat.smokerKills;
	g_Round.totals.survivorTotalBoomerKills -= playerData.combat.boomerKills;
	g_Round.totals.survivorTotalHunterKills -= playerData.combat.hunterKills;
	g_Round.totals.survivorTotalSpitterKills -= playerData.combat.spitterKills;
	g_Round.totals.survivorTotalJockeyKills -= playerData.combat.jockeyKills;
	g_Round.totals.survivorTotalChargerKills -= playerData.combat.chargerKills;
	g_Round.totals.survivorTotalSiKillAssists -= playerData.combatAssists.siKillAssists;
	g_Round.totals.survivorTotalSmokerKillAssists -= playerData.combatAssists.smokerKillAssists;
	g_Round.totals.survivorTotalBoomerKillAssists -= playerData.combatAssists.boomerKillAssists;
	g_Round.totals.survivorTotalHunterKillAssists -= playerData.combatAssists.hunterKillAssists;
	g_Round.totals.survivorTotalSpitterKillAssists -= playerData.combatAssists.spitterKillAssists;
	g_Round.totals.survivorTotalJockeyKillAssists -= playerData.combatAssists.jockeyKillAssists;
	g_Round.totals.survivorTotalChargerKillAssists -= playerData.combatAssists.chargerKillAssists;
	g_Round.totals.survivorTotalSiAssistDamage -= playerData.combatAssists.siAssistDamage;
	g_Round.totals.survivorTotalSmokerAssistDamage -= playerData.combatAssists.smokerAssistDamage;
	g_Round.totals.survivorTotalBoomerAssistDamage -= playerData.combatAssists.boomerAssistDamage;
	g_Round.totals.survivorTotalHunterAssistDamage -= playerData.combatAssists.hunterAssistDamage;
	g_Round.totals.survivorTotalSpitterAssistDamage -= playerData.combatAssists.spitterAssistDamage;
	g_Round.totals.survivorTotalJockeyAssistDamage -= playerData.combatAssists.jockeyAssistDamage;
	g_Round.totals.survivorTotalChargerAssistDamage -= playerData.combatAssists.chargerAssistDamage;
	g_Round.totals.survivorTotalTankKills -= playerData.combat.tankKills;
	g_Round.totals.survivorTotalWitchKills -= playerData.combat.witchKills;
	g_Round.totals.survivorTotalFF -= playerData.combat.ffGiven;
	g_Round.totals.survivorTotalDeaths -= playerData.survivability.deaths;
	g_Round.totals.survivorTotalIncaps -= playerData.survivability.incaps;
	g_Round.totals.survivorTotalHealsGiven -= playerData.support.healsGiven;
	g_Round.totals.survivorTotalRevivesGiven -= playerData.support.revivesGiven;
	g_Round.totals.survivorTotalRescuesGiven -= playerData.support.rescuesGiven;
	g_Round.totals.infectedTotalTongueGrabs -= playerData.infectedGrab.tongueGrabs;
	g_Round.totals.infectedTotalHunterPouncesLanded -= playerData.infectedGrab.hunterPounces;
	g_Round.totals.infectedTotalJockeyRidesLanded -= playerData.infectedGrab.jockeyRides;
	g_Round.totals.infectedTotalBoomerVomitVictims -= playerData.infectedSupport.boomerVomitVictims;
	g_Round.totals.infectedTotalSmokerDamage -= playerData.infectedGrab.smokerDamage;
	g_Round.totals.infectedTotalHunterDamage -= playerData.infectedGrab.hunterDamage;
	g_Round.totals.infectedTotalJockeyDamage -= playerData.infectedGrab.jockeyDamage;
	g_Round.totals.infectedTotalChargerDamage -= playerData.infectedGrab.chargerDamage;
	g_Round.totals.infectedTotalGrabDamage -= playerData.infectedGrab.totalDamage;
	g_Round.totals.infectedTotalSpitterDamage -= playerData.infectedSupport.spitterDamage;
	g_Round.totals.survivorTotalPillsUsed -= playerData.resources.pillsUsed;
	g_Round.totals.survivorTotalAdrenalineUsed -= playerData.resources.adrenalineUsed;
	g_Round.totals.survivorTotalMedkitsUsed -= playerData.resources.medkitsUsed;
	g_Round.totals.survivorTotalDefibsUsed -= playerData.resources.defibsUsed;
	g_Round.totals.survivorTotalMolotovsThrown -= playerData.resources.molotovsThrown;
	g_Round.totals.survivorTotalPipebombsThrown -= playerData.resources.pipebombsThrown;
	g_Round.totals.survivorTotalVomitjarsThrown -= playerData.resources.vomitjarsThrown;
	g_Round.totals.survivorTotalZombiesIgnited -= playerData.resources.zombiesIgnited;
	g_Round.totals.survivorTotalPlayersBiled -= playerData.resources.playersBiled;
	g_Round.totals.survivorTotalTanksBiled -= playerData.resources.tanksBiled;
	g_Round.totals.survivorTotalGascansPoured -= playerData.scavenge.gascansPoured;
	g_Round.totals.survivorTotalGascansDropped -= playerData.scavenge.gascansDropped;
	g_Round.totals.survivorTotalGascansDestroyed -= playerData.scavenge.gascansDestroyed;
}

stock void Stats_AddPlayerRoundDataToTotals(PlayerStatsPlayerRoundData playerData)
{
	g_Round.totals.survivorTotalSiDamage += playerData.combat.siDamage;
	g_Round.totals.survivorTotalSmokerDamage += playerData.combat.smokerDamage;
	g_Round.totals.survivorTotalBoomerDamage += playerData.combat.boomerDamage;
	g_Round.totals.survivorTotalHunterDamage += playerData.combat.hunterDamage;
	g_Round.totals.survivorTotalSpitterDamage += playerData.combat.spitterDamage;
	g_Round.totals.survivorTotalJockeyDamage += playerData.combat.jockeyDamage;
	g_Round.totals.survivorTotalChargerDamage += playerData.combat.chargerDamage;
	g_Round.totals.survivorTotalTankDamage += playerData.combat.tankDamage;
	g_Round.totals.survivorTotalWitchDamage += playerData.combat.witchDamage;
	g_Round.totals.survivorTotalCommonKills += playerData.combat.commonKills;
	g_Round.totals.survivorTotalSmokerKills += playerData.combat.smokerKills;
	g_Round.totals.survivorTotalBoomerKills += playerData.combat.boomerKills;
	g_Round.totals.survivorTotalHunterKills += playerData.combat.hunterKills;
	g_Round.totals.survivorTotalSpitterKills += playerData.combat.spitterKills;
	g_Round.totals.survivorTotalJockeyKills += playerData.combat.jockeyKills;
	g_Round.totals.survivorTotalChargerKills += playerData.combat.chargerKills;
	g_Round.totals.survivorTotalSiKillAssists += playerData.combatAssists.siKillAssists;
	g_Round.totals.survivorTotalSmokerKillAssists += playerData.combatAssists.smokerKillAssists;
	g_Round.totals.survivorTotalBoomerKillAssists += playerData.combatAssists.boomerKillAssists;
	g_Round.totals.survivorTotalHunterKillAssists += playerData.combatAssists.hunterKillAssists;
	g_Round.totals.survivorTotalSpitterKillAssists += playerData.combatAssists.spitterKillAssists;
	g_Round.totals.survivorTotalJockeyKillAssists += playerData.combatAssists.jockeyKillAssists;
	g_Round.totals.survivorTotalChargerKillAssists += playerData.combatAssists.chargerKillAssists;
	g_Round.totals.survivorTotalSiAssistDamage += playerData.combatAssists.siAssistDamage;
	g_Round.totals.survivorTotalSmokerAssistDamage += playerData.combatAssists.smokerAssistDamage;
	g_Round.totals.survivorTotalBoomerAssistDamage += playerData.combatAssists.boomerAssistDamage;
	g_Round.totals.survivorTotalHunterAssistDamage += playerData.combatAssists.hunterAssistDamage;
	g_Round.totals.survivorTotalSpitterAssistDamage += playerData.combatAssists.spitterAssistDamage;
	g_Round.totals.survivorTotalJockeyAssistDamage += playerData.combatAssists.jockeyAssistDamage;
	g_Round.totals.survivorTotalChargerAssistDamage += playerData.combatAssists.chargerAssistDamage;
	g_Round.totals.survivorTotalTankKills += playerData.combat.tankKills;
	g_Round.totals.survivorTotalWitchKills += playerData.combat.witchKills;
	g_Round.totals.survivorTotalFF += playerData.combat.ffGiven;
	g_Round.totals.survivorTotalDeaths += playerData.survivability.deaths;
	g_Round.totals.survivorTotalIncaps += playerData.survivability.incaps;
	g_Round.totals.survivorTotalHealsGiven += playerData.support.healsGiven;
	g_Round.totals.survivorTotalRevivesGiven += playerData.support.revivesGiven;
	g_Round.totals.survivorTotalRescuesGiven += playerData.support.rescuesGiven;
	g_Round.totals.infectedTotalTongueGrabs += playerData.infectedGrab.tongueGrabs;
	g_Round.totals.infectedTotalHunterPouncesLanded += playerData.infectedGrab.hunterPounces;
	g_Round.totals.infectedTotalJockeyRidesLanded += playerData.infectedGrab.jockeyRides;
	g_Round.totals.infectedTotalBoomerVomitVictims += playerData.infectedSupport.boomerVomitVictims;
	g_Round.totals.infectedTotalSmokerDamage += playerData.infectedGrab.smokerDamage;
	g_Round.totals.infectedTotalHunterDamage += playerData.infectedGrab.hunterDamage;
	g_Round.totals.infectedTotalJockeyDamage += playerData.infectedGrab.jockeyDamage;
	g_Round.totals.infectedTotalChargerDamage += playerData.infectedGrab.chargerDamage;
	g_Round.totals.infectedTotalGrabDamage += playerData.infectedGrab.totalDamage;
	g_Round.totals.infectedTotalSpitterDamage += playerData.infectedSupport.spitterDamage;
	g_Round.totals.survivorTotalPillsUsed += playerData.resources.pillsUsed;
	g_Round.totals.survivorTotalAdrenalineUsed += playerData.resources.adrenalineUsed;
	g_Round.totals.survivorTotalMedkitsUsed += playerData.resources.medkitsUsed;
	g_Round.totals.survivorTotalDefibsUsed += playerData.resources.defibsUsed;
	g_Round.totals.survivorTotalMolotovsThrown += playerData.resources.molotovsThrown;
	g_Round.totals.survivorTotalPipebombsThrown += playerData.resources.pipebombsThrown;
	g_Round.totals.survivorTotalVomitjarsThrown += playerData.resources.vomitjarsThrown;
	g_Round.totals.survivorTotalZombiesIgnited += playerData.resources.zombiesIgnited;
	g_Round.totals.survivorTotalPlayersBiled += playerData.resources.playersBiled;
	g_Round.totals.survivorTotalTanksBiled += playerData.resources.tanksBiled;
	g_Round.totals.survivorTotalGascansPoured += playerData.scavenge.gascansPoured;
	g_Round.totals.survivorTotalGascansDropped += playerData.scavenge.gascansDropped;
	g_Round.totals.survivorTotalGascansDestroyed += playerData.scavenge.gascansDestroyed;
}

stock void Stats_ClearSlotRuntimeBindings(int slot)
{
	for (int client = 1; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
	{
		if (g_Runtime.playerSlotByClient[client] != slot)
		{
			continue;
		}

		g_Runtime.playerSlotByClient[client] = -1;
		g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
		g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
	}
}

stock void Stats_ResetRoundSlotForReplacement(int slot)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		return;
	}

	Stats_SubtractPlayerRoundDataFromTotals(g_Round.players[slot]);
	Stats_ClearSlotRuntimeBindings(slot);
	g_Round.players[slot].Reset();
}

stock void Stats_BuildSubstitutionId(int accountId, int timestamp, char[] buffer, int maxlen)
{
	Format(buffer, maxlen, "%d:%d", accountId, timestamp);
}

stock bool Stats_StoreSubstitutionSnapshot(int slot, char[] substitutionId, int maxlen)
{
	if (!Stats_IsValidRoundSlot(slot))
	{
		if (maxlen > 0)
		{
			substitutionId[0] = '\0';
		}
		return false;
	}

	int timestamp = GetTime();
	PlayerStatsSubstitutionSnapshotData snapshot;
	snapshot.Reset();
	snapshot.active = true;
	snapshot.restored = false;
	snapshot.accountId = g_Round.players[slot].player.accountId;
	snapshot.timestamp = timestamp;
	snapshot.roundId = g_Round.meta.id;
	snapshot.slot = slot;
	snapshot.baseMode = g_Round.meta.baseMode;
	GetCurrentMap(snapshot.map, sizeof(snapshot.map));
	Stats_BuildSubstitutionId(snapshot.accountId, snapshot.timestamp, snapshot.substitutionId, sizeof(snapshot.substitutionId));
	while (API_FindSubstitutionSnapshotById(snapshot.substitutionId) != -1)
	{
		snapshot.timestamp = timestamp + ++g_iSubstitutionSnapshotSerial;
		Stats_BuildSubstitutionId(snapshot.accountId, snapshot.timestamp, snapshot.substitutionId, sizeof(snapshot.substitutionId));
	}
	snapshot.player = g_Round.players[slot];
	snapshot.player.player.DetachClient();
	snapshot.player.player.bot = false;

	int writeIndex = g_iSubstitutionSnapshotNext;
	g_SubstitutionSnapshots[writeIndex] = snapshot;
	g_iSubstitutionSnapshotNext = (g_iSubstitutionSnapshotNext + 1) % L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS;
	if (g_iSubstitutionSnapshotCount < L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS)
	{
		g_iSubstitutionSnapshotCount++;
	}

	strcopy(substitutionId, maxlen, snapshot.substitutionId);
	return true;
}

stock int Stats_FindRestorableSubstitutionSnapshotIndex(int accountId, int roundId, int slot)
{
	if (accountId <= 0 || roundId <= 0 || slot < 0)
	{
		return -1;
	}

	for (int offset = 1; offset <= g_iSubstitutionSnapshotCount; offset++)
	{
		int snapshotIndex = (g_iSubstitutionSnapshotNext - offset + L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS) % L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS;
		if (!g_SubstitutionSnapshots[snapshotIndex].active || g_SubstitutionSnapshots[snapshotIndex].restored)
		{
			continue;
		}

		if (g_SubstitutionSnapshots[snapshotIndex].accountId != accountId
			|| g_SubstitutionSnapshots[snapshotIndex].roundId != roundId
			|| g_SubstitutionSnapshots[snapshotIndex].slot != slot)
		{
			continue;
		}

		return snapshotIndex;
	}

	return -1;
}

stock bool Stats_RestoreSubstitutionSnapshotToSlot(int snapshotIndex, int slot, int client)
{
	if (snapshotIndex < 0 || snapshotIndex >= L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS
		|| !g_SubstitutionSnapshots[snapshotIndex].active
		|| g_SubstitutionSnapshots[snapshotIndex].restored
		|| !IsValidClient(client))
	{
		return false;
	}

	g_Round.players[slot] = g_SubstitutionSnapshots[snapshotIndex].player;
	g_Round.players[slot].active = true;
	Stats_AddPlayerRoundDataToTotals(g_Round.players[slot]);
	g_SubstitutionSnapshots[snapshotIndex].restored = true;
	Stats_AssignClientToSlot(client, slot);
	return true;
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

	int slot = g_Runtime.playerSlotByClient[client];
	if (Stats_IsValidRoundSlot(slot))
	{
		g_Round.players[slot].player.DetachClient();
	}

	g_Runtime.playerSlotByClient[client] = -1;
	g_Runtime.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
	g_Runtime.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
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

	Stats_AssignBotToSlotPreserveIdentity(bot, slot);
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

	if (g_Round.players[slot].player.IsSamePersistentPlayer(player))
	{
		Stats_AssignClientToSlot(player, slot);
		return;
	}

	char substitutionId[64];
	Stats_StoreSubstitutionSnapshot(slot, substitutionId, sizeof(substitutionId));
	Stats_ResetRoundSlotForReplacement(slot);
	Action substitutionAction = API_FirePlayerSubstituted(substitutionId, g_Round.meta.id, slot, player);
	if (substitutionAction >= Plugin_Handled)
	{
		g_Round.players[slot].active = true;
		Stats_AssignClientToSlot(player, slot);
		return;
	}

	int restoreIndex = Stats_FindRestorableSubstitutionSnapshotIndex(GetSteamAccountID(player), g_Round.meta.id, slot);
	if (restoreIndex != -1 && Stats_RestoreSubstitutionSnapshotToSlot(restoreIndex, slot, player))
	{
		return;
	}

	g_Round.players[slot].active = true;
	Stats_AssignClientToSlot(player, slot);
}

void LoadPluginTranslations()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof sPath, "translations/"...TRANSLATION_FILE... ".txt");
	if (!FileExists(sPath))
	{
		SetFailState("Missing translation file \""...TRANSLATION_FILE...".txt\"");
	}
	LoadTranslations(TRANSLATION_FILE);
}
