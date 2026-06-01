#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <l4d2_player_stats>
#define REQUIRE_PLUGIN

#define STATS_API_LOGDIR "logs/l4d2_player_stats"
#define STATS_API_LOG_PREFIX "[Player Stats API]"
#define STATS_API_SUBDIR_ROUND "round/finalized"
#define STATS_API_SUBDIR_PLAYER "round/player_detail"
#define STATS_API_SUBDIR_SUBSTITUTION "substitution/player_substituted"
#define STATS_API_ROOT_DATA "data"
#define STATS_API_FAMILY_ROUND "round"
#define STATS_API_FAMILY_PLAYER "player"
#define STATS_API_FAMILY_SUBSTITUTION "substitution"
#define STATS_API_MAX_SLOTS 65

ConVar g_cvDebug;

enum struct PlayerStatsApiRuntimeState
{
	bool hasPlayerStats;
	bool isLate;

	void Reset()
	{
		this.hasPlayerStats = false;
		this.isLate = false;
	}
}

PlayerStatsApiRuntimeState g_Runtime;

void Runtime_SetHasPlayerStats(bool value, const char[] reason)
{
	if (g_Runtime.hasPlayerStats == value)
	{
		return;
	}

	g_Runtime.hasPlayerStats = value;
	LogMessage("%s hasPlayerStats=%d reason=%s", STATS_API_LOG_PREFIX, value ? 1 : 0, reason);
}

public Plugin myinfo =
{
	name = "L4D2 Player Stats API",
	author = "lechuga",
	description = "Consumes the current l4d2_player_stats public API and dumps KeyValues payloads to logs.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_Runtime.isLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_cvDebug = CreateConVar("sm_stats_api_debug", "0", "Enable debug logging for the l4d2_player_stats API probe.", FCVAR_NONE, true, 0.0, true, 1.0);

	if (g_Runtime.isLate)
	{
		Runtime_SetHasPlayerStats(LibraryExists(LIBRARY_L4D2PLAYERSTATS), "late_start");
	}
}

public void OnAllPluginsLoaded()
{
	Runtime_SetHasPlayerStats(LibraryExists(LIBRARY_L4D2PLAYERSTATS), "all_plugins_loaded");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, LIBRARY_L4D2PLAYERSTATS) != 0)
	{
		return;
	}

	Runtime_SetHasPlayerStats(true, "library_added");
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, LIBRARY_L4D2PLAYERSTATS) != 0)
	{
		return;
	}

	Runtime_SetHasPlayerStats(false, "library_removed");
}

public void PlayerStats_OnRoundFinalized(int roundId)
{
	if (roundId <= 0)
	{
		return;
	}

	DumpRoundSnapshot(roundId);
	DumpRoundPlayerSnapshots(roundId);
}

public Action PlayerStats_OnPlayerSubstituted(const char[] substitutionId, int roundId, int slot, int incomingClient)
{
	DumpSubstitutionEvent(substitutionId, roundId, slot, incomingClient);
	return Plugin_Continue;
}

void DumpRoundSnapshot(int roundId)
{
	KeyValues kv = new KeyValues(STATS_API_ROOT_DATA);
	if (!PlayerStats_FillRoundKeyValues(roundId, kv))
	{
		delete kv;
		return;
	}

	WriteCommonMetadata(kv, STATS_API_FAMILY_ROUND);

	char label[32];
	Format(label, sizeof(label), "round_%d", roundId);

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(STATS_API_SUBDIR_ROUND, label, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, label);
	delete kv;
}

void DumpRoundPlayerSnapshots(int roundId)
{
	for (int slot = 0; slot < STATS_API_MAX_SLOTS; slot++)
	{
		if (!PlayerStats_IsRoundPlayerSlotValid(roundId, slot))
		{
			continue;
		}

		KeyValues kv = new KeyValues(STATS_API_ROOT_DATA);
		if (!PlayerStats_FillRoundPlayerKeyValues(roundId, slot, kv))
		{
			delete kv;
			continue;
		}

		WriteCommonMetadata(kv, STATS_API_FAMILY_PLAYER);

		char label[48];
		Format(label, sizeof(label), "round_%d_slot_%d", roundId, slot);

		char filePath[PLATFORM_MAX_PATH];
		BuildLogPath(STATS_API_SUBDIR_PLAYER, label, filePath, sizeof(filePath));
		ExportKvToFile(kv, filePath, label);
		delete kv;
	}
}

void DumpSubstitutionEvent(const char[] substitutionId, int roundId, int slot, int incomingClient)
{
	KeyValues kv = new KeyValues(STATS_API_ROOT_DATA);
	WriteCommonMetadata(kv, STATS_API_FAMILY_SUBSTITUTION);
	kv.SetString("substitution_id", substitutionId);
	kv.SetNum("round_id", roundId);
	kv.SetNum("slot", slot);
	kv.SetNum("incoming_client", incomingClient);

	char incomingName[MAX_NAME_LENGTH];
	incomingName[0] = '\0';
	if (incomingClient > 0 && incomingClient <= MaxClients && IsClientInGame(incomingClient))
	{
		GetClientName(incomingClient, incomingName, sizeof(incomingName));
	}

	kv.SetString("incoming_name", incomingName);

	char label[64];
	Format(label, sizeof(label), "round_%d_slot_%d", roundId, slot);

	char filePath[PLATFORM_MAX_PATH];
	BuildLogPath(STATS_API_SUBDIR_SUBSTITUTION, label, filePath, sizeof(filePath));
	ExportKvToFile(kv, filePath, label);
	delete kv;
}

void Debug(const char[] fmt, any ...)
{
	if (g_cvDebug == null || !g_cvDebug.BoolValue)
	{
		return;
	}

	char buffer[512];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	LogMessage("%s %s", STATS_API_LOG_PREFIX, buffer);
}

void EnsureLogDirectory()
{
	char basePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, basePath, sizeof(basePath), STATS_API_LOGDIR);
	if (!DirExists(basePath))
	{
		EnsureDirectoryRecursive(basePath);
		Debug("EnsureLogDirectory path=%s created=%d exists_after=%d", basePath, 1, DirExists(basePath));
	}
	else
	{
		Debug("EnsureLogDirectory path=%s already_exists=1", basePath);
	}
}

void EnsureDirectoryRecursive(const char[] fullPath)
{
	int length = strlen(fullPath);
	for (int i = 0; i < length; i++)
	{
		if (fullPath[i] != '/' && fullPath[i] != '\\')
		{
			continue;
		}

		if (i == 0)
		{
			continue;
		}

		if (i == 2 && fullPath[1] == ':')
		{
			continue;
		}

		char partial[PLATFORM_MAX_PATH];
		strcopy(partial, i + 1, fullPath);
		if (!DirExists(partial))
		{
			bool created = CreateDirectory(partial, 511);
			Debug("EnsureDirectoryRecursive path=%s created=%d exists_after=%d", partial, created, DirExists(partial));
		}
	}

	if (!DirExists(fullPath))
	{
		bool created = CreateDirectory(fullPath, 511);
		Debug("EnsureDirectoryRecursive final_path=%s created=%d exists_after=%d", fullPath, created, DirExists(fullPath));
	}
}

void BuildLogPath(const char[] subdir, const char[] typeName, char[] path, int maxlen)
{
	char mapName[64];
	char timestamp[32];
	int tick = GetGameTickCount();

	FormatTime(timestamp, sizeof(timestamp), "%Y%m%d_%H%M%S", GetTime());
	GetCurrentMap(mapName, sizeof(mapName));

	BuildPath(Path_SM, path, maxlen, "%s/%s/%s_%s_%s_%d.cfg",
		STATS_API_LOGDIR,
		subdir,
		typeName,
		timestamp,
		mapName,
		tick);
	Debug("BuildLogPath subdir=%s type=%s path=%s", subdir, typeName, path);
}

void EnsureFilePathReady(const char[] filePath)
{
	EnsureLogDirectory();

	char directoryPath[PLATFORM_MAX_PATH];
	strcopy(directoryPath, sizeof(directoryPath), filePath);
	int separator = FindCharInString(directoryPath, '\\', true);
	if (separator == -1)
	{
		separator = FindCharInString(directoryPath, '/', true);
	}

	if (separator != -1)
	{
		directoryPath[separator] = '\0';
		if (!DirExists(directoryPath))
		{
			EnsureDirectoryRecursive(directoryPath);
		}
	}

	if (!FileExists(filePath))
	{
		File file = OpenFile(filePath, "w");
		Debug("EnsureFilePathReady file=%s opened=%d", filePath, file != null);
		if (file != null)
		{
			delete file;
		}
	}
}

void WriteCommonMetadata(KeyValues kv, const char[] family)
{
	char mapName[64];
	GetCurrentMap(mapName, sizeof(mapName));

	kv.SetString("family", family);
	kv.SetString("map", mapName);
	kv.SetNum("tick_id", GetGameTickCount());
}

void ExportKvToFile(KeyValues kv, const char[] filePath, const char[] label)
{
	EnsureFilePathReady(filePath);

	bool ok = kv.ExportToFile(filePath);
	Debug("ExportKvToFile label=%s path=%s ok=%d", label, filePath, ok);
	if (!ok)
	{
		LogMessage("%s Export failed label=%s path=%s", STATS_API_LOG_PREFIX, label, filePath);
	}
}
