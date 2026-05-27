#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <console_table>
#include <left4dhooks>
#include <l4d2util_stocks>
#include <l4d2util_weapons>
#include <l4d2_player_stats>

#undef REQUIRE_PLUGIN
#include <readyup>
#include <l4d2_player_skills>
#include <l4d2_boss_percents>
#define REQUIRE_PLUGIN

#include "l4d2_player_stats/types.sp"

#define LIBRARY_READYUP "readyup"
#define LIBRARY_CONFOGL "confogl"
#define LIBRARY_L4D2_PLAYER_SKILLS "l4d2_player_skills"
#define LIBRARY_L4D2_BOSS_PERCENTS "l4d_boss_percent"
#define LIBRARY_LEFT4DHOOKS "left4dhooks"
#define LOG_DIRECTORY "logs/l4d2_player_stats.log"
#define TRANSLATION_FILE "l4d2_player_stats.phrases"

PlayerStatsRoundData g_Round;
PlayerStatsRoundData g_RoundBackup;
PlayerStatsHistoricalRoundData g_RoundHistory[L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS];
PlayerStatsSubstitutionSnapshotData g_SubstitutionSnapshots[L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS];
PlayerStatsGameHistoryData g_GameHistory;
PlayerStatsRuntimeState g_Runtime;
int g_iSubstitutionSnapshotCount = 0;
int g_iSubstitutionSnapshotNext = 0;
int g_iSubstitutionSnapshotSerial = 0;

ConVar	g_cvEnable = null;
ConVar	g_cvDebug	= null;
ConVar	g_cvTracking = null;
ConVar	g_cvHistory = null;
ConVar	g_cvAccuracy = null;
ConVar	g_cvThrowables = null;
ConVar	g_cvGamemode = null;
ConVar	g_cvInfectedValidDamage = null;
ConVar	g_cvTankValidDamage = null;
ConVar	g_cvReadyCfgName = null;
ConVar	g_cvSurvivorLimit = null;
ConVar	g_cvMaxPlayerZombies = null;
ConVar	g_cvVersusBoomerLimit = null;
ConVar	g_cvVersusSmokerLimit = null;
ConVar	g_cvVersusHunterLimit = null;
ConVar	g_cvVersusSpitterLimit = null;
ConVar	g_cvVersusJockeyLimit = null;
ConVar	g_cvVersusChargerLimit = null;
ConVar	g_cvConfoglAdrenalineLimit = null;
ConVar	g_cvConfoglPipebombLimit = null;
ConVar	g_cvConfoglMolotovLimit = null;
ConVar	g_cvConfoglVomitjarLimit = null;
ConVar	g_cvConfoglRemoveDefib = null;
char	g_sDebugLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "L4D2 Player Stats",
	author		= "lechuga",
	description = "Modern player statistics core for competitive L4D2.",
	version		= "1.0.0",
	url			= "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

#include "l4d2_player_stats/helpers.sp"
#include "l4d2_player_stats/api.sp"
#include "l4d2_player_stats/announce.sp"
#include "l4d2_player_stats/rounds.sp"
#include "l4d2_player_stats/series.sp"
#include "l4d2_player_stats/detect.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
	g_Runtime.Reset();
	g_Runtime.lateload = late;
	RegPluginLibrary("l4d2_player_stats");
	API_CreateForwards();
	API_CreateNatives();
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadPluginTranslations();
	BuildPath(Path_SM, g_sDebugLogPath, sizeof(g_sDebugLogPath), LOG_DIRECTORY);

	g_cvDebug		= CreateConVar("sm_stats_debug", "31", "Debug bitmask for l4d2_player_stats. 0=None 1=Core 2=Event 4=Detect 8=Api 16=Announce 31=all.");
	g_cvEnable		= CreateConVar("sm_stats_enable", "1", "Enable the l4d2_player_stats plugin.");
	g_cvTracking	= CreateConVar("sm_stats_tracking", "3", "Bitmask for round stats tracking. 1=enable 2=announce 3=all.");
	g_cvHistory		= CreateConVar("sm_stats_history", "1", "Enable mission or series history. 1=enable.");
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

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	HookEvent("finale_win", Event_FinaleWin, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_start", Event_ScavengeRoundStart, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_finished", Event_ScavengeRoundFinished, EventHookMode_PostNoCopy);
	HookEvent("scavenge_round_halftime", Event_ScavengeRoundHalftime, EventHookMode_PostNoCopy);
	HookEvent("scavenge_match_finished", Event_ScavengeMatchFinished, EventHookMode_PostNoCopy);
	HookEvent("begin_scavenge_overtime", Event_ScavengeOvertime, EventHookMode_PostNoCopy);
	HookEvent("scavenge_score_tied", Event_ScavengeScoreTied, EventHookMode_PostNoCopy);
	HookEvent("gascan_pour_completed", Event_GascanPourCompleted, EventHookMode_PostNoCopy);
	HookEvent("gascan_dropped", Event_GascanDropped, EventHookMode_PostNoCopy);
	HookEvent("scavenge_gas_can_destroyed", Event_ScavengeGascanDestroyed, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_PostNoCopy);

	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_incapacitated_start", Event_PlayerIncapacitatedStart, EventHookMode_Post);
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
	HookEvent("vote_passed", Event_VotePassed, EventHookMode_PostNoCopy);

	RegConsoleCmd("sm_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_stats_mvp", Command_MVP, "Print the current survivor MVP summary.");
	RegConsoleCmd("sm_stats_rank", Command_Rank, "Print the client's current MVP ranks in chat and the global rank table in console.");
	RegConsoleCmd("sm_stats_history", Command_Stats, "Print the aggregated mission history for the current map, a requested map, or all maps.");
	RegConsoleCmd("sm_stats_acc", Command_Acc, "Print the current round accuracy table in console.");
	RegConsoleCmd("sm_stats_acc_details", Command_AccDetails, "Print detailed per-weapon accuracy for the current round or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_utils", Command_Utils, "Print throwable utility stats for the current round or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_items", Command_Items, "Print consumable usage stats for the current round or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_support", Command_Support, "Print support stats for the current round or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_scav", Command_Scavenge, "Print scavenge-specific stats for the current round or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_infect", Command_Infect, "Print infected grab/support stats for the current half or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_tank", Command_Tank, "Print tank session stats for the current half or the latest historical map snapshot.");
	RegConsoleCmd("sm_stats_subs", Command_Substitutions, "Print substitution snapshots kept in the in-memory buffer.");
	RegConsoleCmd("sm_stats_help", Command_Help, "Print stats command help to console.");

	AutoExecConfig(false, LIBRARY_L4D2PLAYERSTATS);
	g_GameHistory.Reset();
	g_iSubstitutionSnapshotCount = 0;
	g_iSubstitutionSnapshotNext = 0;
	g_iSubstitutionSnapshotSerial = 0;
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS; i++)
	{
		g_RoundHistory[i].Reset();
	}
	for (int i = 0; i < L4D2_PLAYER_STATS_MAX_SUBSTITUTION_SNAPSHOTS; i++)
	{
		g_SubstitutionSnapshots[i].Reset();
	}

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
			OnClientPutInServer(client);
		}
	}
}

public void OnAllPluginsLoaded()
{
	g_Runtime.hasLeft4DHooks		= LibraryExists(LIBRARY_LEFT4DHOOKS);
	g_Runtime.hasReadyUp			= LibraryExists(LIBRARY_READYUP);
	g_Runtime.hasConfogl			= LibraryExists(LIBRARY_CONFOGL);
	g_Runtime.hasPlayerSkills		= LibraryExists(LIBRARY_L4D2_PLAYER_SKILLS);
	g_Runtime.hasBossPercents		= LibraryExists(LIBRARY_L4D2_BOSS_PERCENTS);
	Stats_RefreshReadyUpConVars();
	Stats_RefreshConfoglConVars();
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) == 0)
	{
		g_Runtime.hasLeft4DHooks = true;
		Stats_RefreshModeContext();
		Round_RefreshLiveState();
	}
	else if (strcmp(name, LIBRARY_READYUP) == 0)
	{
		g_Runtime.hasReadyUp = true;
		Stats_RefreshReadyUpConVars();
		Stats_RefreshModeContext();
		Round_RefreshLiveState();
	}
	else if (strcmp(name, LIBRARY_CONFOGL) == 0)
	{
		g_Runtime.hasConfogl = true;
		Stats_RefreshConfoglConVars();
	}
	else if (strcmp(name, LIBRARY_L4D2_PLAYER_SKILLS) == 0)
	{
		g_Runtime.hasPlayerSkills = true;
	}
	else if (strcmp(name, LIBRARY_L4D2_BOSS_PERCENTS) == 0)
	{
		g_Runtime.hasBossPercents = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, LIBRARY_LEFT4DHOOKS) == 0)
	{
		g_Runtime.hasLeft4DHooks = false;
		Stats_RefreshModeContext();
		Round_RefreshLiveState();
	}
	else if (strcmp(name, LIBRARY_READYUP) == 0)
	{
		g_Runtime.hasReadyUp = false;
		Stats_RefreshReadyUpConVars();
		Stats_RefreshModeContext();
		Round_RefreshLiveState();
	}
	else if (strcmp(name, LIBRARY_CONFOGL) == 0)
	{
		g_Runtime.hasConfogl = false;
		Stats_ClearConfoglConVars();
	}
	else if (strcmp(name, LIBRARY_L4D2_PLAYER_SKILLS) == 0)
	{
		g_Runtime.hasPlayerSkills = false;
	}
	else if (strcmp(name, LIBRARY_L4D2_BOSS_PERCENTS) == 0)
	{
		g_Runtime.hasBossPercents = false;
	}
}

public void OnMapStart()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnMapStart");
	Series_OnMapStart();

	if (g_Round.meta.active || g_Round.meta.id > 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Skipping OnMapStart reset. round=%d active=%d live=%d", g_Round.meta.id, g_Round.meta.active, g_Runtime.roundLive);
		return;
	}

	Round_ResetAll("OnMapStart");
}

public void OnMapEnd()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnMapEnd");
	bool broadcastOnMapEnd = g_Runtime.baseMode == GAMEMODE_SURVIVAL;
	Round_FinalizeActiveSnapshot("map_end", PlayerStatsRoundEndReason_MapEnd, broadcastOnMapEnd);
	Round_ResetAll("OnMapEnd");
}

public void OnConfigsExecuted()
{
	Stats_RefreshModeContext();
	Round_RefreshLiveState();
}

public void ConVarChange_ModeContext(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Stats_RefreshModeContext();
}

public void L4D_OnGameModeChange(int gamemode)
{
	Stats_RefreshModeContext();
	Round_RefreshLiveState();
}

public void OnPluginEnd()
{
	Stats_Debug(PlayerStatsDebug_Core, "Lifecycle: OnPluginEnd");
	Round_FinalizeActiveSnapshot("plugin_end", PlayerStatsRoundEndReason_PluginEnd, false);
	Round_ResetAll("OnPluginEnd");
}

public void OnClientPutInServer(int client)
{
	Stats_OnClientPutInServer(client);
	SDKHook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	Detect_OnClientDisconnect(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, Detect_OnTakeDamage);
	Stats_OnClientDisconnect(client);
}

public void OnRoundIsLive()
{
	Stats_Debug(PlayerStatsDebug_Event, "Readyup forward received: OnRoundIsLive");
	Round_OnReadyUpLive();
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnFirstSurvivorLeftSafeArea_Post] client=%d", client);
	Round_OnFirstSurvivorLeftSafeArea(client);
}

public void L4D_OnGrabWithTongue_Post(int victim, int attacker)
{
	Detect_OnGrabWithTonguePost(victim, attacker);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	Detect_OnPouncedOnSurvivorPost(victim, attacker);
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	Detect_OnJockeyRidePost(victim, attacker);
}

public void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion)
{
	Detect_OnVomitedUponPost(victim, attacker, boomerExplosion);
}

public Action PlayerSkills_OnSkillDetected(int eventId, L4D2SkillType type)
{
	Detect_OnPlayerSkillDetected(eventId, type);
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	char objective[64];
	event.GetString("objective", objective, sizeof(objective));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] timelimit=%d fraglimit=%d objective=%s", name, event.GetInt("timelimit"), event.GetInt("fraglimit"), objective);
	Round_EventRoundStart(event, name, dontBroadcast);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	char message[128];
	event.GetString("message", message, sizeof(message));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] winner=%d reason=%d message=%s time=%.1f", name, event.GetInt("winner"), event.GetInt("reason"), message, event.GetFloat("time"));
	Round_EventRoundEnd(event, name, dontBroadcast);
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnMapTransition();
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	char mapName[64];
	event.GetString("map_name", mapName, sizeof(mapName));
	Stats_Debug(PlayerStatsDebug_Event, "[%s] map_name=%s difficulty=%d", name, mapName, event.GetInt("difficulty"));
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnFinaleWin();
}

public void Event_ScavengeRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s] round=%d firsthalf=%d", name, event.GetInt("round"), event.GetBool("firsthalf"));
	Round_EventRoundStart(event, name, dontBroadcast);
}

public void Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Round_EventRoundEnd(event, name, dontBroadcast);
}

public void Event_ScavengeRoundHalftime(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnScavengeRoundHalftime();
	Series_OnScavengeRoundHalftime();
}

public void Event_ScavengeMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s] winners=%d", name, event.GetInt("winners"));
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnScavengeMatchFinished();
	Series_OnScavengeMatchFinished();
}

public void Event_ScavengeOvertime(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnScavengeOvertime();
}

public void Event_ScavengeScoreTied(Event event, const char[] name, bool dontBroadcast)
{
	Stats_Debug(PlayerStatsDebug_Event, "[%s]", name);
	Stats_ConsumeEventContext(event, name, dontBroadcast);
	Round_OnScavengeScoreTied();
}

public void L4D2_OnEndVersusModeRound_Post()
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D2_OnEndVersusModeRound_Post]");
	Round_OnEndVersusModeRoundPost();
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_EventPlayerBotReplace(event, name, dontBroadcast);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_EventBotPlayerReplace(event, name, dontBroadcast);
}

public Action L4D_OnClearTeamScores(bool newCampaign)
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnClearTeamScores] newCampaign=%d", newCampaign);
	Series_OnClearTeamScores(newCampaign);
	return Plugin_Continue;
}

public void L4D_OnSetCampaignScores_Post(int scoreA, int scoreB)
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnSetCampaignScores_Post] scoreA=%d scoreB=%d", scoreA, scoreB);
	Series_OnSetCampaignScoresPost(scoreA, scoreB);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerHurt(event, name, dontBroadcast);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerDeath(event, name, dontBroadcast);
}

public void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerIncapacitatedStart(event, name, dontBroadcast);
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventInfectedDeath(event, name, dontBroadcast);
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventInfectedHurt(event, name, dontBroadcast);
}

public void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	Detect_OnIncapacitatedPost(client, inflictor, attacker, damage, damagetype, weapon);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventWeaponFire(event, name, dontBroadcast);
}

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerNowIt(event, name, dontBroadcast);
}

public void Event_VomitBombTank(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventVomitBombTank(event, name, dontBroadcast);
}

public void Event_ZombieIgnited(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventZombieIgnited(event, name, dontBroadcast);
}

public void Event_VotePassed(Event event, const char[] name, bool dontBroadcast)
{
	Series_EventVotePassed(event, name, dontBroadcast);
}

public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPillsUsed(event, name, dontBroadcast);
}

public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventAdrenalineUsed(event, name, dontBroadcast);
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventHealSuccess(event, name, dontBroadcast);
}

public void Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventDefibrillatorUsed(event, name, dontBroadcast);
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventReviveSuccess(event, name, dontBroadcast);
}

public void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventSurvivorRescued(event, name, dontBroadcast);
}

public void Event_GascanPourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventGascanPourCompleted(event, name, dontBroadcast);
}

public void Event_GascanDropped(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventGascanDropped(event, name, dontBroadcast);
}

public void Event_ScavengeGascanDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventScavengeGascanDestroyed(event, name, dontBroadcast);
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventTankSpawn(event, name, dontBroadcast);
}

Action Command_MVP(int client, int args)
{
	bool fromChat = Announce_WasCommandInvokedFromChat(client);

	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		Announce_RenderHistoricalRoundSummary(client, mapFilter, fromChat);
		return Plugin_Handled;
	}

	if (fromChat && !Announce_BroadcastRoundSummary(client))
	{
		return Plugin_Handled;
	}

	if (client > 0 && IsValidClient(client))
	{
		Announce_RenderRoundConsolePanel(client);
	}

	return Plugin_Handled;
}

Action Command_Rank(int client, int args)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}

	if (Announce_WasCommandInvokedFromChat(client))
	{
		Announce_PrintClientRanks(client);
	}

	Announce_RenderGlobalRankPanel(client);
	return Plugin_Handled;
}

Action Command_Stats(int client, int args)
{
	char mapFilter[64];
	mapFilter[0] = '\0';
	bool useCurrentMapDefault = args < 1;

	if (args >= 1)
	{
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (StrEqual(mapFilter, "all", false))
		{
			mapFilter[0] = '\0';
		}
	}
	else
	{
		GetCurrentMap(mapFilter, sizeof(mapFilter));
	}

	if (useCurrentMapDefault && mapFilter[0] != '\0' && Announce_CountHistoryRowsForFilter(mapFilter) <= 0 && Announce_CountHistoryRowsForFilter() > 0)
	{
		mapFilter[0] = '\0';
	}

	if (Announce_RenderGameHistoryPanel(client, mapFilter))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Acc(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalAccuracyPanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderAccuracyPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_AccDetails(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalAccuracyDetailsPanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderAccuracyDetailsPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Utils(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalUtilitiesPanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderUtilitiesPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Items(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalConsumablesPanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderConsumablesPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Support(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalSupportPanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderSupportPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Scavenge(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalScavengePanel(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderScavengePanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Help(int client, int args)
{
	Announce_PrintHelpToConsole(client);
	Announce_NotifyConsoleDelivery(client);
	return Plugin_Handled;
}

Action Command_Substitutions(int client, int args)
{
	if (Announce_PrintSubstitutionSnapshotsToConsole(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Infect(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalInfectedPanels(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderInfectedPanels(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Command_Tank(int client, int args)
{
	if (args > 0)
	{
		char mapFilter[64];
		GetCmdArg(1, mapFilter, sizeof(mapFilter));
		if (Announce_RenderHistoricalTankPanels(client, mapFilter))
		{
			Announce_NotifyConsoleDelivery(client);
		}
		return Plugin_Handled;
	}

	if (Announce_RenderTankPanels(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}
