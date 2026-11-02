#if defined _l4d2_player_stats_bootstrap_included
	#endinput
#endif
#define _l4d2_player_stats_bootstrap_included

APLRes Bootstrap_OnLoad(bool late)
{
	Trace_Init();
	g_Runtime.Reset();
	g_Runtime.lateload = late;
	RegPluginLibrary("l4d2_player_stats");
	API_CreateForwards();
	API_CreateNatives();
	return APLRes_Success;
}

void Bootstrap_OnPluginStart()
{
	LoadPluginTranslations();
	BuildPath(Path_SM, g_sDebugLogPath, sizeof(g_sDebugLogPath), LOG_DIRECTORY);

	g_cvDebug		= CreateConVar("sm_stats_debug", "0", "Debug bitmask for l4d2_player_stats. 0=None 1=Core 2=Event 4=Detect 8=Api 16=Announce 31=all.");
	g_cvEnable		= CreateConVar("sm_stats_enable", "1", "Enable the l4d2_player_stats plugin.");
	g_cvTracking	= CreateConVar("sm_stats_tracking", "3", "Bitmask for round stats tracking. 1=enable 2=announce 3=all.");
	g_cvAccuracy	= CreateConVar("sm_stats_accuracy", "1", "Enable accuracy tracking. 1=enable.");
	g_cvThrowables	= CreateConVar("sm_stats_throwables", "3", "Bitmask for throwable utility tracking. 1=enable 2=announce 3=all.");
	g_cvGamemode	= CreateConVar("sm_stats_gamemode", "15", "Enabled game modes. 1=coop 2=versus 4=scavenge 8=survival 15=all.");
	g_cvInfectedValidDamage = CreateConVar("sm_stats_infected_valid_damage", "3", "Valid infected damage bitmask. 0=all 1=exclude incap 2=exclude ledge 3=exclude both.");
	g_cvTankValidDamage = CreateConVar("sm_stats_tank_valid_damage", "3", "Valid tank damage bitmask. 0=all 1=exclude incap 2=exclude ledge 3=exclude both.");

	g_cvSurvivorLimit		= FindConVar("survivor_limit");
	g_cvMaxPlayerZombies	= FindConVar("z_max_player_zombies");
	g_cvVersusBoomerLimit	= FindConVar("z_versus_boomer_limit");
	g_cvVersusSmokerLimit	= FindConVar("z_versus_smoker_limit");
	g_cvVersusHunterLimit	= FindConVar("z_versus_hunter_limit");
	g_cvVersusSpitterLimit	= FindConVar("z_versus_spitter_limit");
	g_cvVersusJockeyLimit	= FindConVar("z_versus_jockey_limit");
	g_cvVersusChargerLimit	= FindConVar("z_versus_charger_limit");

	g_cvGamemode.AddChangeHook(ConVarChange_ModeContext);
	g_cvSurvivorLimit.AddChangeHook(ConVarChange_ModeContext);
	g_cvMaxPlayerZombies.AddChangeHook(ConVarChange_ModeContext);

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_Post);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_Post);
	HookEvent("mission_lost", Event_MissionLost, EventHookMode_Post);
	HookEvent("versus_match_finished", Event_VersusMatchFinished, EventHookMode_Post);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_Post);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_Post);
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime, EventHookMode_Post);
	HookEvent("scavenge_match_finished", Event_ScavengeMatchFinished, EventHookMode_Post);
	HookEvent("begin_scavenge_overtime", Event_ScavengeOvertime, EventHookMode_Post);
	HookEvent("scavenge_score_tied", Event_ScavengeScoreTied, EventHookMode_Post);
	HookEvent("gascan_pour_completed", Event_GascanPourCompleted, EventHookMode_Post);
	HookEvent("gascan_dropped", Event_GascanDropped, EventHookMode_Post);
	HookEvent("scavenge_gas_can_destroyed", Event_ScavengeGascanDestroyed, EventHookMode_Post);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_Post);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("infected_death", Event_InfectedDeath, EventHookMode_Post);
	HookEvent("infected_hurt", Event_InfectedHurt, EventHookMode_Post);
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_now_it", Event_PlayerNowIt, EventHookMode_Post);
	HookEvent("vomit_bomb_tank", Event_VomitBombTank, EventHookMode_Post);
	HookEvent("zombie_ignited", Event_ZombieIgnited, EventHookMode_Post);
	HookEvent("pills_used", Event_PillsUsed, EventHookMode_Post);
	HookEvent("adrenaline_used", Event_AdrenalineUsed, EventHookMode_Post);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("defibrillator_used", Event_DefibrillatorUsed, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("survivor_rescued", Event_SurvivorRescued, EventHookMode_Post);

	RegConsoleCmd("sm_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_stats_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_stats_rank", Command_Rank, "Print the client's current MVP ranks in chat and the global rank table in console.");
	RegConsoleCmd("sm_stats_acc", Command_Acc, "Print the current round accuracy table in console.");
	RegConsoleCmd("sm_stats_utils", Command_Utils, "Print throwable utility stats for the current round.");
	RegConsoleCmd("sm_stats_items", Command_Items, "Print consumable usage stats for the current round.");
	RegConsoleCmd("sm_stats_support", Command_Support, "Print support stats for the current round.");
	RegConsoleCmd("sm_stats_scav", Command_Scavenge, "Print scavenge-specific stats for the current round.");
	RegConsoleCmd("sm_stats_infect", Command_Infect, "Print infected grab/support stats for the current half.");
	RegConsoleCmd("sm_stats_tank", Command_Tank, "Print tank session stats for the current half.");
	RegConsoleCmd("sm_stats_help", Command_Help, "Print stats command help to console.");

	AutoExecConfig(false, LIBRARY_L4D2PLAYERSTATS);
	Substitutions_ResetAll();

	L4D2Weapons_Init();

	if (!g_Runtime.lateload)
	{
		g_Runtime.hasLeft4DHooks		= LibraryExists(LIBRARY_LEFT4DHOOKS);
		g_Runtime.hasReadyUp			= LibraryExists(LIBRARY_READYUP);
		g_Runtime.hasConfogl			= LibraryExists(LIBRARY_CONFOGL);
		g_Runtime.hasPlayerSkills		= LibraryExists(LIBRARY_L4D2_PLAYER_SKILLS);
		g_Runtime.hasBossPercents		= LibraryExists(LIBRARY_L4D2_BOSS_PERCENTS);
	}

	Stats_RefreshReadyUpConVars();
	Stats_RefreshConfoglConVars();
	Stats_RefreshModeContext();

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client))
		{
			StatsTraceContext traceContext;
			traceContext = Trace_BeginSignal();
			Input_OnClientPutInServer(client, traceContext);
		}
	}
}

void Bootstrap_OnMapStart()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnMapStart");

	if (g_Round.meta.active || g_Round.meta.id > 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Skipping OnMapStart reset. round=%d active=%d live=%d", g_Round.meta.id, g_Round.meta.active, g_Runtime.roundLive);
		return;
	}

	Round_ResetAll("OnMapStart");
}

void Bootstrap_OnMapEnd()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnMapEnd");
	bool broadcastOnMapEnd = g_Runtime.baseMode == GAMEMODE_SURVIVAL;
	Round_FinalizeActiveSnapshot("map_end", PlayerStatsRoundEndReason_MapEnd, broadcastOnMapEnd);
	Round_ResetAll("OnMapEnd");
}

void Bootstrap_OnPluginEnd()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnPluginEnd");
	Round_FinalizeActiveSnapshot("plugin_end", PlayerStatsRoundEndReason_PluginEnd, false);
	Round_ResetAll("OnPluginEnd");
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
