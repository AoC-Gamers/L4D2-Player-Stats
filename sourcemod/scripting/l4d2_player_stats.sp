#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>
#include <console_table>
#include <left4dhooks>

#undef REQUIRE_PLUGIN
#include <readyup>
#include <l4d2_player_skills>
#define REQUIRE_PLUGIN

#include "l4d2_player_stats/types.sp"

#define READYUP_LIBRARY "readyup"
#define L4D2_PLAYER_SKILLS_LIBRARY "l4d2_player_skills"

PlayerStatsRoundData g_Round;
bool				 g_bRoundLive			  = false;
bool				 g_bReadyUpAvailable	  = false;
bool				 g_bPlayerSkillsAvailable = false;
bool				 g_bLateload			  = false;	
int					 g_iPlayerSlotByClient[L4D2_PLAYER_STATS_MAX_PLAYERS];

ConVar				 g_cvEnable = null;
ConVar				 g_cvDebug	= null;
char				 g_sDebugLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name		= "L4D2 Player Stats",
	author		= "lechuga",
	description = "Modern player statistics core for competitive L4D2.",
	version		= "1.0.0",
	url			= "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int errorMax)
{
	g_bLateload = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d2_player_stats.phrases");

	g_cvEnable = CreateConVar("l4d2_player_stats_enable", "1", "Enable the l4d2_player_stats plugin.");
	g_cvDebug  = CreateConVar("l4d2_player_stats_debug", "0", "Enable debug logging for l4d2_player_stats.");

	BuildPath(Path_SM, g_sDebugLogPath, sizeof(g_sDebugLogPath), "logs/l4d2_player_stats_debug.log");

	AutoExecConfig(false, "l4d2_player_stats");

	API_Init();
	Announce_Init();
	Round_Init();
	Detect_Init();

	if (!g_bLateload)
		return;

	g_bReadyUpAvailable		 = LibraryExists(READYUP_LIBRARY);
	g_bPlayerSkillsAvailable = LibraryExists(L4D2_PLAYER_SKILLS_LIBRARY);
}

public void OnAllPluginsLoaded()
{
	g_bReadyUpAvailable		 = LibraryExists(READYUP_LIBRARY);
	g_bPlayerSkillsAvailable = LibraryExists(L4D2_PLAYER_SKILLS_LIBRARY);
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, READYUP_LIBRARY) == 0)
	{
		g_bReadyUpAvailable = true;
	}
	else if (strcmp(name, L4D2_PLAYER_SKILLS_LIBRARY) == 0)
	{
		g_bPlayerSkillsAvailable = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, READYUP_LIBRARY) == 0)
	{
		g_bReadyUpAvailable = false;
	}
	else if (strcmp(name, L4D2_PLAYER_SKILLS_LIBRARY) == 0)
	{
		g_bPlayerSkillsAvailable = false;
	}
}

public void OnMapStart()
{
	Round_ResetAll();
}

public void OnMapEnd()
{
	Round_ResetAll();
}

public void OnPluginEnd()
{
	Round_ResetAll();
}

public void OnClientPutInServer(int client)
{
	Stats_OnClientPutInServer(client);
}

public void OnClientDisconnect(int client)
{
	Stats_OnClientDisconnect(client);
}

public void OnRoundIsLive()
{
	Round_OnReadyUpLive();
}

public void L4D_OnFirstSurvivorLeftSafeArea_Post(int client)
{
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
	Round_EventRoundStart(event, name, dontBroadcast);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Round_EventRoundEnd(event, name, dontBroadcast);
}

public void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_EventPlayerBotReplace(event, name, dontBroadcast);
}

public void Event_BotPlayerReplace(Event event, const char[] name, bool dontBroadcast)
{
	Stats_EventBotPlayerReplace(event, name, dontBroadcast);
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerHurt(event, name, dontBroadcast);
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	Detect_EventPlayerDeath(event, name, dontBroadcast);
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

#include "l4d2_player_stats/helpers.sp"
#include "l4d2_player_stats/api.sp"
#include "l4d2_player_stats/announce.sp"
#include "l4d2_player_stats/rounds.sp"
#include "l4d2_player_stats/detect.sp"
