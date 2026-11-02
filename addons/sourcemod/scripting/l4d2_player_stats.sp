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
#include "l4d2_player_stats/types/observations.sp"
#include "l4d2_player_stats/types/player_skills.sp"
#include "l4d2_player_stats/types/trace.sp"
#include "l4d2_player_stats/types/damage.sp"

#define LIBRARY_READYUP "readyup"
#define LIBRARY_CONFOGL "confogl"
#define LIBRARY_L4D2_BOSS_PERCENTS "l4d_boss_percent"
#define LIBRARY_LEFT4DHOOKS "left4dhooks"
#define LOG_DIRECTORY "logs/l4d2_player_stats.log"
#define TRANSLATION_FILE "l4d2_player_stats.phrases"

PlayerStatsRoundData g_Round;
PlayerStatsRuntimeState g_Runtime;
bool g_bRoundClosing = false;
int g_iPlayerSkillsGeneration;
int g_iPlayerSkillsLedgerNext[4];
int g_iPlayerSkillsLedgerGeneration[4][L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY];
int g_iPlayerSkillsLedgerIds[4][L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY];
int g_iPlayerSkillsLedgerRounds[4][L4D2_PLAYER_STATS_SKILLS_LEDGER_CAPACITY];

ConVar	g_cvEnable = null;
ConVar	g_cvDebug	= null;
ConVar	g_cvTracking = null;
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
#include "l4d2_player_stats/trace.sp"
#include "l4d2_player_stats/damage/resolve.sp"
#include "l4d2_player_stats/modules/skills_import.sp"
#include "l4d2_player_stats/config.sp"
#include "l4d2_player_stats/runtime/context.sp"
#include "l4d2_player_stats/runtime/players.sp"
#include "l4d2_player_stats/runtime/substitutions.sp"
#include "l4d2_player_stats/queries.sp"
#include "l4d2_player_stats/api/forwards.sp"
#include "l4d2_player_stats/api/exports.sp"
#include "l4d2_player_stats/inputs/natives.sp"
#include "l4d2_player_stats/presentation/announce.sp"
#include "l4d2_player_stats/runtime/rounds.sp"
#include "l4d2_player_stats/modules/tank.sp"
#include "l4d2_player_stats/damage/capture.sp"
#include "l4d2_player_stats/detect.sp"
#include "l4d2_player_stats/modules/scavenge.sp"
#include "l4d2_player_stats/modules/survivor.sp"
#include "l4d2_player_stats/modules/accuracy.sp"
#include "l4d2_player_stats/modules/combat.sp"
#include "l4d2_player_stats/modules/utility.sp"
#include "l4d2_player_stats/modules/infected.sp"
#include "l4d2_player_stats/inputs/game_events.sp"
#include "l4d2_player_stats/inputs/player_skills.sp"
#include "l4d2_player_stats/inputs/commands.sp"
#include "l4d2_player_stats/inputs/libraries.sp"
#include "l4d2_player_stats/inputs/players.sp"
#include "l4d2_player_stats/inputs/sdkhooks.sp"
#include "l4d2_player_stats/bootstrap.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
	return Bootstrap_OnLoad(late);
}

public void OnPluginStart()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Bootstrap_OnPluginStart();
	Trace_RuntimeLifecycleResult(traceContext, "plugin_start", before);
}

public void OnAllPluginsLoaded()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnAllPluginsLoaded();
	Trace_RuntimeLifecycleResult(traceContext, "all_plugins_loaded", before);
}

public void OnLibraryAdded(const char[] name)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnLibraryAdded(name);
	Trace_RuntimeLifecycleResult(traceContext, "library_added", before);
}

public void OnLibraryRemoved(const char[] name)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnLibraryRemoved(name);
	Trace_RuntimeLifecycleResult(traceContext, "library_removed", before);
}

public void OnMapStart()
{
	Trace_AdvanceMapGeneration();
	Trace_BeginSignal();
	Bootstrap_OnMapStart();
}

public void OnMapEnd()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Bootstrap_OnMapEnd();
	Trace_RuntimeLifecycleResult(traceContext, "map_end", before);
}

public void OnConfigsExecuted()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnConfigsExecuted();
	Trace_RuntimeLifecycleResult(traceContext, "configs_executed", before);
}

public void ConVarChange_ModeContext(ConVar convar, const char[] oldValue, const char[] newValue)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnModeContextConVarChanged(convar, oldValue, newValue);
	Trace_RuntimeLifecycleResult(traceContext, "mode_convar", before);
}

public void L4D_OnGameModeChange(int gamemode)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Input_OnGameModeChange(gamemode);
	Trace_RuntimeLifecycleResult(traceContext, "gamemode_change", before);
}

public void OnPluginEnd()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsRuntimeTraceSnapshot before;
	Trace_CaptureRuntimeSnapshot(before);
	Bootstrap_OnPluginEnd();
	Trace_RuntimeLifecycleResult(traceContext, "plugin_end", before);
}

public int Native_PlayerStats_IsRoundActive(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_IsRoundActive();
	Trace_ApiResult(traceContext, "playerstats_is_round_active", "returned", StatsApiTrace_IsRoundActive, true);
	return result;
}

public int Native_PlayerStats_IsRoundLive(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_IsRoundLive();
	Trace_ApiResult(traceContext, "playerstats_is_round_live", "returned", StatsApiTrace_IsRoundLive, true);
	return result;
}

public int Native_PlayerStats_GetRoundId(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_GetRoundId();
	Trace_ApiResult(traceContext, "playerstats_get_round_id", "returned", StatsApiTrace_GetRoundId, true);
	return result;
}

public int Native_PlayerStats_IsRoundPlayerSlotValid(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_IsRoundPlayerSlotValid();
	Trace_ApiResult(traceContext, "playerstats_is_round_slot_valid", "returned", StatsApiTrace_IsRoundPlayerSlotValid, true);
	return result;
}

public int Native_PlayerStats_GetRoundPlayerClient(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_GetRoundPlayerClient();
	Trace_ApiResult(traceContext, "playerstats_get_round_player_client", "returned", StatsApiTrace_GetRoundPlayerClient, true);
	return result;
}

public int Native_PlayerStats_GetCurrentModeProperty(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_GetCurrentModeProperty();
	Trace_ApiResult(traceContext, "playerstats_get_mode_property", "returned", StatsApiTrace_GetCurrentModeProperty, true);
	return result;
}

public int Native_PlayerStats_FillRoundKeyValues(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_FillRoundKeyValues();
	Trace_ApiResult(traceContext, "playerstats_fill_round_keyvalues", result ? "written" : "rejected", StatsApiTrace_FillRoundKeyValues, true);
	return result;
}

public int Native_PlayerStats_FillRoundPlayerKeyValues(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_FillRoundPlayerKeyValues();
	Trace_ApiResult(traceContext, "playerstats_fill_round_player_keyvalues", result ? "written" : "rejected", StatsApiTrace_FillRoundPlayerKeyValues, true);
	return result;
}

public int Native_PlayerStats_ApplySubstitutionSnapshotToSlot(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_ApplySubstitutionSnapshotToSlot();
	Trace_ApiResult(traceContext, "playerstats_apply_substitution_snapshot", result ? "restored" : "rejected", StatsApiTrace_ApplySubstitutionSnapshot, false);
	return result;
}

public int Native_PlayerStats_BroadcastRoundStats(Handle plugin, int numParams)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	int result = Input_NativePlayerStats_BroadcastRoundStats();
	Trace_ApiResult(traceContext, "playerstats_broadcast_round_stats", "delegated", StatsApiTrace_BroadcastRoundStats, true);
	return result;
}

public void OnClientPutInServer(int client)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_OnClientPutInServer(client, traceContext);
}

public void OnClientDisconnect(int client)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_OnClientDisconnect(client, traceContext);
}

public Action SDK_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_SdkOnTakeDamage(victim, attacker, inflictor, damage, damagetype, traceContext);
	return Plugin_Continue;
}

public void OnRoundIsLive()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_OnReadyUpRoundLive();
	Trace_LifecycleResult(traceContext, "readyup_round_live", before);
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_OnFirstSurvivorLeftSafeArea(client);
	Trace_LifecycleResult(traceContext, "first_survivor_left_safe_area", before);
}

public void L4D_OnGrabWithTongue_Post(int victim, int attacker)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnGrabWithTongue_Post] victim=%d attacker=%d", victim, attacker);
	PlayerStatsControlApplyResult result = Input_ControlTongueGrab(victim, attacker);
	Trace_ControlResult(traceContext, PlayerStatsControl_TongueGrab, result);
}

public void L4D_OnPouncedOnSurvivor_Post(int victim, int attacker)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnPouncedOnSurvivor_Post] victim=%d attacker=%d", victim, attacker);
	PlayerStatsControlApplyResult result = Input_ControlHunterPounce(victim, attacker);
	Trace_ControlResult(traceContext, PlayerStatsControl_HunterPounce, result);
}

public void L4D2_OnJockeyRide_Post(int victim, int attacker)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Stats_Debug(PlayerStatsDebug_Event, "[L4D2_OnJockeyRide_Post] victim=%d attacker=%d", victim, attacker);
	PlayerStatsControlApplyResult result = Input_ControlJockeyRide(victim, attacker);
	Trace_ControlResult(traceContext, PlayerStatsControl_JockeyRide, result);
}

public void L4D_OnVomitedUpon_Post(int victim, int attacker, bool boomerExplosion)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnVomitedUpon_Post] victim=%d attacker=%d boomer_explosion=%d", victim, attacker, boomerExplosion);
	PlayerStatsControlApplyResult result = Input_ControlBoomerVomit(victim, attacker, boomerExplosion);
	Trace_ControlResult(traceContext, PlayerStatsControl_BoomerVomit, result);
}

public Action PlayerSkills_OnSkillDetected(int eventId, L4D2ApiSkillType type)
{
	StatsTraceContext trace;
	trace = Trace_BeginSignal();
	StatsSkillsImportResult result;
	result = Input_PlayerSkillsSkillDetected(eventId, type);
	Trace_SkillsImportResult(trace, PlayerStatsSkillsStream_SkillEvent, eventId, type, result);
	return Plugin_Continue;
}

public Action PlayerSkills_OnKillDetected(int eventId, L4D2ApiKillType type)
{
	StatsTraceContext trace;
	trace = Trace_BeginSignal();
	StatsSkillsImportResult result;
	result = Input_PlayerSkillsKillDetected(eventId, type);
	Trace_SkillsImportResult(trace, PlayerStatsSkillsStream_KillEvent, eventId, type, result);
	return Plugin_Continue;
}

public Action PlayerSkills_OnBossEventDetected(int eventId, L4D2ApiBossEventType type)
{
	StatsTraceContext trace;
	trace = Trace_BeginSignal();
	StatsSkillsImportResult result;
	result = Input_PlayerSkillsBossEventDetected(eventId, type);
	Trace_SkillsImportResult(trace, PlayerStatsSkillsStream_BossEvent, eventId, type, result);
	return Plugin_Continue;
}

public Action PlayerSkills_OnBossSessionFinalized(int sessionId, L4D2BossType type)
{
	StatsTraceContext trace;
	trace = Trace_BeginSignal();
	StatsSkillsImportResult result;
	result = Input_PlayerSkillsBossSessionFinalized(sessionId, type);
	Trace_SkillsImportResult(trace, PlayerStatsSkillsStream_BossSession, sessionId, type, result);
	return Plugin_Continue;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_RoundStart(event, name);
	Trace_LifecycleResult(traceContext, "round_start", before);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_RoundEnd(event, name);
	Trace_LifecycleResult(traceContext, "round_end", before);
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_MapTransition(name);
	Trace_LifecycleResult(traceContext, "map_transition", before);
}

public void Event_FinaleWin(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_FinaleWin(event, name);
	Trace_LifecycleResult(traceContext, "finale_win", before);
}

public void Event_MissionLost(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_MissionLost(name);
	Trace_LifecycleResult(traceContext, "mission_lost", before);
}

public void Event_ScavengeRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeRoundStart(event, name);
	Trace_LifecycleResult(traceContext, "scavenge_round_start", before);
}

public void Event_ScavengeRoundFinished(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeRoundFinished(name);
	Trace_LifecycleResult(traceContext, "scavenge_round_finished", before);
}

public void Event_ScavengeRoundHalftime(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeRoundHalftime(name);
	Trace_LifecycleResult(traceContext, "scavenge_round_halftime", before);
}

public void Event_ScavengeMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeMatchFinished(event, name);
	Trace_LifecycleResult(traceContext, "scavenge_match_finished", before);
}

public void Event_VersusMatchFinished(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_VersusMatchFinished(event, name);
	Trace_LifecycleResult(traceContext, "versus_match_finished", before);
}

public void Event_ScavengeOvertime(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeOvertime(name);
	Trace_LifecycleResult(traceContext, "begin_scavenge_overtime", before);
}

public void Event_ScavengeScoreTied(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_ScavengeScoreTied(name);
	Trace_LifecycleResult(traceContext, "scavenge_score_tied", before);
}

public void L4D2_OnEndVersusModeRound_Post()
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsLifecycleTraceSnapshot before;
	Trace_CaptureLifecycleSnapshot(before);
	Input_OnEndVersusModeRoundPost();
	Trace_LifecycleResult(traceContext, "versus_mode_round_end_post", before);
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_PlayerBotReplace(event, traceContext);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_BotPlayerReplace(event, traceContext);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsPlayerHurtObservation observation;
	Input_ReadPlayerHurt(event, observation);
	Detect_ProcessPlayerHurt(observation, traceContext);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsPlayerDeathObservation observation;
	observation.victimUserid = event.GetInt("userid");
	observation.attackerUserid = event.GetInt("attacker");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
	Detect_ProcessPlayerDeath(observation, traceContext);
}

public void Event_PlayerIncapacitatedStart(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsPlayerIncapacitatedStartObservation observation;
	observation.victimUserid = event.GetInt("userid");
	observation.attackerUserid = event.GetInt("attacker");
	event.GetString("weapon", observation.weapon, sizeof(observation.weapon));
	Detect_ProcessPlayerIncapacitatedStart(observation, traceContext);
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Trace_Result(traceContext, "player_spawn", "receive", "input", "received");
	Input_PlayerSpawn(event);
}

public void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsInfectedDeathObservation observation;
	observation.attackerUserid = event.GetInt("attacker");
	observation.infectedType = event.GetInt("gender");
	strcopy(observation.eventName, sizeof(observation.eventName), name);
	Detect_ProcessInfectedDeath(observation, traceContext);
}

public void Event_InfectedHurt(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_InfectedHurt(event, traceContext);
}

public void L4D_OnIncapacitated_Post(int client, int inflictor, int attacker, float damage, int damagetype, int weapon)
{
	Input_IncapacitatedPost(client, attacker);
}

public void Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsWeaponFireResult result;
	result = Input_WeaponFire(event);
	Trace_WeaponFireResult(traceContext, result);
}

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_UtilityPlayerNowIt(event, traceContext);
}

public void Event_VomitBombTank(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_UtilityVomitBombTank(event, traceContext);
}

public void Event_ZombieIgnited(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_UtilityZombieIgnited(event, traceContext);
}

public void Event_PillsUsed(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorPillsUsed(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_PillsUsed, result, detail);
}

public void Event_AdrenalineUsed(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorAdrenalineUsed(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_AdrenalineUsed, result, detail);
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorHealSuccess(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_HealSuccess, result, detail);
}

public void Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorDefibrillatorUsed(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_DefibrillatorUsed, result, detail);
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorReviveSuccess(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_ReviveSuccess, result, detail);
}

public void Event_SurvivorRescued(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	StatsSurvivorActionResult detail;
	PlayerStatsSurvivorApplyStatus result;
	result = Input_SurvivorRescued(event, detail);
	Trace_SurvivorActionResult(traceContext, PlayerStatsSurvivorAction_Rescued, result, detail);
}

public void Event_GascanPourCompleted(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_ScavengeGascanPoured(event, traceContext);
}

public void Event_GascanDropped(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_ScavengeGascanDropped(event, traceContext);
}

public void Event_ScavengeGascanDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Input_ScavengeGascanDestroyed(event, traceContext);
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Trace_Result(traceContext, "tank_spawn", "receive", "input", "received");
	StatsTankSpawnResult result;
	result = Input_TankSpawn(event);
	Trace_TankSpawnResult(traceContext, result);
}

Action Command_MVP(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandMVP(client);
	Trace_CommandResult(traceContext, "command_mvp", StatsCommandTrace_MVP, result);
	return result;
}

Action Command_Rank(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandRank(client);
	Trace_CommandResult(traceContext, "command_rank", StatsCommandTrace_Rank, result);
	return result;
}

Action Command_Acc(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandAcc(client);
	Trace_CommandResult(traceContext, "command_acc", StatsCommandTrace_Acc, result);
	return result;
}

Action Command_Utils(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandUtils(client);
	Trace_CommandResult(traceContext, "command_utils", StatsCommandTrace_Utils, result);
	return result;
}

Action Command_Items(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandItems(client);
	Trace_CommandResult(traceContext, "command_items", StatsCommandTrace_Items, result);
	return result;
}

Action Command_Support(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandSupport(client);
	Trace_CommandResult(traceContext, "command_support", StatsCommandTrace_Support, result);
	return result;
}

Action Command_Scavenge(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandScavenge(client);
	Trace_CommandResult(traceContext, "command_scavenge", StatsCommandTrace_Scavenge, result);
	return result;
}

Action Command_Help(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandHelp(client);
	Trace_CommandResult(traceContext, "command_help", StatsCommandTrace_Help, result);
	return result;
}

Action Command_Infect(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandInfect(client);
	Trace_CommandResult(traceContext, "command_infect", StatsCommandTrace_Infect, result);
	return result;
}

Action Command_Tank(int client, int args)
{
	StatsTraceContext traceContext;
	traceContext = Trace_BeginSignal();
	Action result = Input_CommandTank(client);
	Trace_CommandResult(traceContext, "command_tank", StatsCommandTrace_Tank, result);
	return result;
}
