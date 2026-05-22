#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d2_player_stats>

bool g_bPlayerStatsAvailable = false;

public Plugin myinfo =
{
	name = "L4D2 PlayStats Wrapper",
	author = "lechuga",
	description = "Legacy l4d2_playstats compatibility wrapper over l4d2_player_stats.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("l4d2_playstats");
	CreateNative("PLAYSTATS_BroadcastRoundStats", Native_PLAYSTATS_BroadcastRoundStats);
	CreateNative("PLAYSTATS_BroadcastGameStats", Native_PLAYSTATS_BroadcastGameStats);
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_bPlayerStatsAvailable = LibraryExists("l4d2_player_stats");
}

public void OnAllPluginsLoaded()
{
	g_bPlayerStatsAvailable = LibraryExists("l4d2_player_stats");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "l4d2_player_stats") == 0)
	{
		g_bPlayerStatsAvailable = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "l4d2_player_stats") == 0)
	{
		g_bPlayerStatsAvailable = false;
	}
}

public int Native_PLAYSTATS_BroadcastRoundStats(Handle plugin, int numParams)
{
	if (g_bPlayerStatsAvailable)
	{
		PlayerStats_BroadcastRoundStats();
	}
	return 0;
}

public int Native_PLAYSTATS_BroadcastGameStats(Handle plugin, int numParams)
{
	if (g_bPlayerStatsAvailable)
	{
		PlayerStats_BroadcastRoundStats();
	}
	return 0;
}
