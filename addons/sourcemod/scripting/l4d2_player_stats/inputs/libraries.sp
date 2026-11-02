#if defined _l4d2_player_stats_inputs_libraries_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_libraries_included

void Input_OnReadyUpRoundLive()
{
	Stats_Debug(PlayerStatsDebug_Event, "Readyup forward received: OnRoundIsLive");
	Round_OnReadyUpLive();
}

void Input_OnFirstSurvivorLeftSafeArea(int client)
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnFirstSurvivorLeftSafeArea_Post] client=%d", client);
	Round_OnFirstSurvivorLeftSafeArea(client);
}

void Input_OnEndVersusModeRoundPost()
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D2_OnEndVersusModeRound_Post]");
	Round_OnEndVersusModeRoundPost();
}

void Input_OnAllPluginsLoaded()
{
	g_Runtime.hasLeft4DHooks		= LibraryExists(LIBRARY_LEFT4DHOOKS);
	g_Runtime.hasReadyUp			= LibraryExists(LIBRARY_READYUP);
	g_Runtime.hasConfogl			= LibraryExists(LIBRARY_CONFOGL);
	g_Runtime.hasPlayerSkills		= LibraryExists(LIBRARY_L4D2_PLAYER_SKILLS);
	g_Runtime.hasBossPercents		= LibraryExists(LIBRARY_L4D2_BOSS_PERCENTS);
	Stats_RefreshReadyUpConVars();
	Stats_RefreshConfoglConVars();
}

void Input_OnLibraryAdded(const char[] name)
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
		SkillsImport_OnPlayerSkillsLibraryChanged();
	}
	else if (strcmp(name, LIBRARY_L4D2_BOSS_PERCENTS) == 0)
	{
		g_Runtime.hasBossPercents = true;
	}
}

void Input_OnLibraryRemoved(const char[] name)
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
		SkillsImport_OnPlayerSkillsLibraryChanged();
	}
	else if (strcmp(name, LIBRARY_L4D2_BOSS_PERCENTS) == 0)
	{
		g_Runtime.hasBossPercents = false;
	}
}

void Input_OnConfigsExecuted()
{
	Stats_Debug(PlayerStatsDebug_Event, "[OnConfigsExecuted]");
	Stats_RefreshModeContext();
	Round_RefreshLiveState();
}

void Input_OnGameModeChange(int gamemode)
{
	Stats_Debug(PlayerStatsDebug_Event, "[L4D_OnGameModeChange] gamemode=%d", gamemode);
	Stats_RefreshModeContext();
	Round_RefreshLiveState();
}

PlayerStatsControlApplyResult Input_ControlTongueGrab(int victim, int attacker)
{
	StatsControlRecord observation;
	Input_ReadControl(victim, attacker, false, PlayerStatsControl_TongueGrab, observation);
	return Infected_ApplyControl(observation);
}

PlayerStatsControlApplyResult Input_ControlHunterPounce(int victim, int attacker)
{
	StatsControlRecord observation;
	Input_ReadControl(victim, attacker, false, PlayerStatsControl_HunterPounce, observation);
	return Infected_ApplyControl(observation);
}

PlayerStatsControlApplyResult Input_ControlJockeyRide(int victim, int attacker)
{
	StatsControlRecord observation;
	Input_ReadControl(victim, attacker, false, PlayerStatsControl_JockeyRide, observation);
	return Infected_ApplyControl(observation);
}

PlayerStatsControlApplyResult Input_ControlBoomerVomit(int victim, int attacker, bool boomerExplosion)
{
	StatsControlRecord observation;
	Input_ReadControl(victim, attacker, boomerExplosion, PlayerStatsControl_BoomerVomit, observation);
	return Infected_ApplyControl(observation);
}

void Input_ReadControl(int victim, int attacker, bool boomerExplosion, PlayerStatsControlType type, StatsControlRecord observation)
{
	observation.type = type;
	observation.victim = victim;
	observation.attacker = attacker;
	observation.boomerExplosion = boomerExplosion;
}
