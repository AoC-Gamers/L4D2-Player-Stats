#if defined _l4d2_player_stats_config_included
	#endinput
#endif
#define _l4d2_player_stats_config_included

void Input_OnModeContextConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	char name[64];
	if (convar != null)
	{
		convar.GetName(name, sizeof(name));
	}
	else
	{
		strcopy(name, sizeof(name), "<null>");
	}

	Stats_Debug(PlayerStatsDebug_Event, "[ConVarChange_ModeContext] cvar=%s old=%s new=%s", name, oldValue, newValue);
	Stats_RefreshModeContext();
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
