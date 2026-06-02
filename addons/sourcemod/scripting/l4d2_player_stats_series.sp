#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <console_table>
#include <left4dhooks>
#include <l4d2_player_stats>

#define L4D2_PLAYER_STATS_SERIES_MAX_SERIES 8
#define L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES 64
#define L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS 8
#define L4D2_PLAYER_STATS_SERIES_MAX_SLOTS 65
#define L4D2_PLAYER_STATS_SERIES_TEAM_SURVIVOR 1
#define L4D2_PLAYER_STATS_SERIES_TEAM_INFECTED 2

enum PlayerStatsSeriesScope
{
	PlayerStatsSeriesScope_None = 0,
	PlayerStatsSeriesScope_Mission,
	PlayerStatsSeriesScope_Map
}

enum struct PlayerStatsSeriesPlayerData
{
	bool active;
	int slot;
	int team;
	int accountId;
	bool bot;
	char name[MAX_NAME_LENGTH];
	int siDamage;
	int tankDamage;
	int witchDamage;
	int siKills;
	int commonKills;
	int ffGiven;
	int deaths;
	int incaps;
	int healsGiven;
	int revivesGiven;

	void Reset()
	{
		this.active = false;
		this.slot = -1;
		this.team = 0;
		this.accountId = 0;
		this.bot = false;
		this.name[0] = '\0';
		this.siDamage = 0;
		this.tankDamage = 0;
		this.witchDamage = 0;
		this.siKills = 0;
		this.commonKills = 0;
		this.ffGiven = 0;
		this.deaths = 0;
		this.incaps = 0;
		this.healsGiven = 0;
		this.revivesGiven = 0;
	}
}

enum struct PlayerStatsSeriesEntryData
{
	bool active;
	int roundId;
	int baseMode;
	int seriesScope;
	int scavengeRoundNumber;
	bool secondHalf;
	char map[64];
	char missionKey[32];
	int siDamage;
	int tankDamage;
	int witchDamage;
	int commonKills;
	int ff;
	int deaths;
	int incaps;
	int healsGiven;
	int revivesGiven;
	int siKills;
	PlayerStatsSeriesPlayerData players[L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS];

	void Reset()
	{
		this.active = false;
		this.roundId = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.seriesScope = 0;
		this.scavengeRoundNumber = 0;
		this.secondHalf = false;
		this.map[0] = '\0';
		this.missionKey[0] = '\0';
		this.siDamage = 0;
		this.tankDamage = 0;
		this.witchDamage = 0;
		this.commonKills = 0;
		this.ff = 0;
		this.deaths = 0;
		this.incaps = 0;
		this.healsGiven = 0;
		this.revivesGiven = 0;
		this.siKills = 0;

		for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; i++)
		{
			this.players[i].Reset();
		}
	}
}

enum struct PlayerStatsSeriesAggregateData
{
	bool active;
	int team;
	int accountId;
	bool bot;
	char name[MAX_NAME_LENGTH];
	int rounds;
	int siDamage;
	int tankDamage;
	int witchDamage;
	int commonKills;
	int ffGiven;
	int deaths;
	int incaps;
	int healsGiven;
	int revivesGiven;

	void Reset()
	{
		this.active = false;
		this.team = 0;
		this.accountId = 0;
		this.bot = false;
		this.name[0] = '\0';
		this.rounds = 0;
		this.siDamage = 0;
		this.tankDamage = 0;
		this.witchDamage = 0;
		this.commonKills = 0;
		this.ffGiven = 0;
		this.deaths = 0;
		this.incaps = 0;
		this.healsGiven = 0;
		this.revivesGiven = 0;
	}
}

enum struct PlayerStatsSeriesData
{
	bool active;
	bool closed;
	int id;
	int baseMode;
	PlayerStatsSeriesScope scope;
	int entryCount;
	int firstRoundId;
	int lastRoundId;
	char map[64];
	char missionKey[32];
	PlayerStatsSeriesEntryData entries[L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES];

	void Reset()
	{
		this.active = false;
		this.closed = false;
		this.id = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.scope = PlayerStatsSeriesScope_None;
		this.entryCount = 0;
		this.firstRoundId = 0;
		this.lastRoundId = 0;
		this.map[0] = '\0';
		this.missionKey[0] = '\0';

		for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES; i++)
		{
			this.entries[i].Reset();
		}
	}
}

PlayerStatsSeriesData g_Series[L4D2_PLAYER_STATS_SERIES_MAX_SERIES];
int g_iActiveSeriesIndex = -1;
int g_iSeriesSerial = 0;

public Plugin myinfo =
{
	name = "L4D2 Player Stats Series",
	author = "lechuga",
	description = "Stores finalized PlayerStats rounds into short-lived mode-aware series.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

public void OnPluginStart()
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_SERIES; i++)
	{
		g_Series[i].Reset();
	}

	RegConsoleCmd("sm_stats_series", Command_Series, "Print the current PlayerStats series buffer or a requested series detail.");
}

public void PlayerStats_OnRoundEnded(int roundId, StatsEndType endType, int endReason)
{
	if (roundId <= 0 || endType == StatsEndType_None)
	{
		return;
	}

	Handle kv = CreateKeyValues("player_stats_series_round");
	if (kv == INVALID_HANDLE || !PlayerStats_FillRoundKeyValues(roundId, kv))
	{
		if (kv != INVALID_HANDLE)
		{
			delete kv;
		}
		return;
	}

	char currentMap[64];
	char missionKey[32];
	GetCurrentMap(currentMap, sizeof(currentMap));
	Series_BuildMissionKeyFromMap(currentMap, missionKey, sizeof(missionKey));

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false) || !KvJumpToKey(kv, "context", false))
	{
		delete kv;
		return;
	}

	int baseMode = KvGetNum(kv, "base_mode", GAMEMODE_UNKNOWN);
	int seriesScope = KvGetNum(kv, "series_scope", 0);
	int scavengeRoundNumber = KvGetNum(kv, "scavenge_round_number", 0);
	bool secondHalf = KvGetNum(kv, "second_half", 0) > 0;
	KvRewind(kv);

	PlayerStatsSeriesScope scope = Series_DetermineScope(baseMode);
	if (scope == PlayerStatsSeriesScope_None)
	{
		delete kv;
		return;
	}

	if (g_iActiveSeriesIndex == -1 || Series_ShouldStartNewSeries(g_iActiveSeriesIndex, baseMode, scope, currentMap, missionKey))
	{
		Series_CloseActiveSeries();
		g_iActiveSeriesIndex = Series_AllocateSeriesSlot();
		if (g_iActiveSeriesIndex == -1)
		{
			delete kv;
			return;
		}

		Series_Open(g_iActiveSeriesIndex, baseMode, scope, currentMap, missionKey);
	}

	Series_AppendRound(g_iActiveSeriesIndex, roundId, baseMode, seriesScope, scavengeRoundNumber, secondHalf, currentMap, missionKey, kv);
	delete kv;
}

void Series_BuildMissionKeyFromMap(const char[] map, char[] buffer, int maxlen)
{
	buffer[0] = '\0';
	if (map[0] == '\0')
	{
		return;
	}

	int split = -1;
	int length = strlen(map);
	for (int i = 1; i < length; i++)
	{
		if (map[i] == 'm' || map[i] == 'M')
		{
			split = i;
			break;
		}
	}

	if (split <= 0)
	{
		strcopy(buffer, maxlen, map);
		return;
	}

	strcopy(buffer, maxlen, map);
	buffer[split] = '\0';
}

PlayerStatsSeriesScope Series_DetermineScope(int baseMode)
{
	switch (baseMode)
	{
		case GAMEMODE_COOP, GAMEMODE_VERSUS:
		{
			return PlayerStatsSeriesScope_Mission;
		}

		case GAMEMODE_SCAVENGE, GAMEMODE_SURVIVAL:
		{
			return PlayerStatsSeriesScope_Map;
		}
	}

	return PlayerStatsSeriesScope_None;
}

bool Series_ShouldStartNewSeries(int index, int baseMode, PlayerStatsSeriesScope scope, const char[] map, const char[] missionKey)
{
	if (index < 0 || index >= L4D2_PLAYER_STATS_SERIES_MAX_SERIES || !g_Series[index].active)
	{
		return true;
	}

	if (g_Series[index].baseMode != baseMode || g_Series[index].scope != scope)
	{
		return true;
	}

	switch (scope)
	{
		case PlayerStatsSeriesScope_Mission:
		{
			return !StrEqual(g_Series[index].missionKey, missionKey, false);
		}

		case PlayerStatsSeriesScope_Map:
		{
			return !StrEqual(g_Series[index].map, map, false);
		}
	}

	return true;
}

void Series_CloseActiveSeries()
{
	if (g_iActiveSeriesIndex == -1)
	{
		return;
	}

	g_Series[g_iActiveSeriesIndex].closed = true;
	g_iActiveSeriesIndex = -1;
}

int Series_AllocateSeriesSlot()
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_SERIES; i++)
	{
		if (!g_Series[i].active)
		{
			return i;
		}
	}

	int bestIndex = -1;
	int bestId = 2147483647;
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_SERIES; i++)
	{
		if (!g_Series[i].closed)
		{
			continue;
		}

		if (g_Series[i].id < bestId)
		{
			bestId = g_Series[i].id;
			bestIndex = i;
		}
	}

	if (bestIndex != -1)
	{
		g_Series[bestIndex].Reset();
	}

	return bestIndex;
}

void Series_Open(int index, int baseMode, PlayerStatsSeriesScope scope, const char[] map, const char[] missionKey)
{
	g_Series[index].Reset();
	g_Series[index].active = true;
	g_Series[index].closed = false;
	g_Series[index].id = ++g_iSeriesSerial;
	g_Series[index].baseMode = baseMode;
	g_Series[index].scope = scope;
	strcopy(g_Series[index].map, sizeof(g_Series[index].map), map);
	strcopy(g_Series[index].missionKey, sizeof(g_Series[index].missionKey), missionKey);
}

void Series_AppendRound(int index, int roundId, int baseMode, int seriesScope, int scavengeRoundNumber, bool secondHalf, const char[] map, const char[] missionKey, Handle kv)
{
	if (index < 0 || index >= L4D2_PLAYER_STATS_SERIES_MAX_SERIES || !g_Series[index].active)
	{
		delete kv;
		return;
	}

	int entryIndex = g_Series[index].entryCount;
	if (entryIndex >= L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES)
	{
		entryIndex = L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES - 1;
		g_Series[index].entries[entryIndex].Reset();
		g_Series[index].entryCount = entryIndex;
	}

	g_Series[index].entries[entryIndex].Reset();
	g_Series[index].entries[entryIndex].active = true;
	g_Series[index].entries[entryIndex].roundId = roundId;
	g_Series[index].entries[entryIndex].baseMode = baseMode;
	g_Series[index].entries[entryIndex].seriesScope = seriesScope;
	g_Series[index].entries[entryIndex].scavengeRoundNumber = scavengeRoundNumber;
	g_Series[index].entries[entryIndex].secondHalf = secondHalf;
	strcopy(g_Series[index].entries[entryIndex].map, sizeof(g_Series[index].entries[entryIndex].map), map);
	strcopy(g_Series[index].entries[entryIndex].missionKey, sizeof(g_Series[index].entries[entryIndex].missionKey), missionKey);
	Series_CaptureEntryTotals(index, entryIndex, kv);
	Series_CaptureEntryPlayers(index, entryIndex, roundId);

	if (g_Series[index].firstRoundId <= 0)
	{
		g_Series[index].firstRoundId = roundId;
	}

	g_Series[index].lastRoundId = roundId;
	if (g_Series[index].entryCount < L4D2_PLAYER_STATS_SERIES_MAX_ENTRIES)
	{
		g_Series[index].entryCount++;
	}
}

Action Command_Series(int client, int args)
{
	if (args >= 1)
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		int seriesId = StringToInt(arg);
		int seriesIndex = Series_FindIndexById(seriesId);
		if (seriesIndex == -1)
		{
			char line[96];
			Format(line, sizeof(line), "[PlayerStatsSeries] Series id %d was not found.", seriesId);
			Series_PrintConsoleLine(client, line);
			return Plugin_Handled;
		}

		Series_PrintTotalsTable(client, seriesIndex);
		Series_PrintPlayersTable(client, seriesIndex);
		Series_PrintEntriesTable(client, seriesIndex);
		return Plugin_Handled;
	}

	Series_PrintSummaryTable(client);
	return Plugin_Handled;
}

int Series_FindIndexById(int seriesId)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_SERIES; i++)
	{
		if (g_Series[i].id == seriesId && (g_Series[i].active || g_Series[i].closed))
		{
			return i;
		}
	}

	return -1;
}

void Series_PrintConsoleLine(int client, const char[] line)
{
	if (client > 0)
	{
		PrintToConsole(client, "%s", line);
		return;
	}

	PrintToServer("%s", line);
}

void Series_GetModeLabel(int baseMode, char[] buffer, int maxlen)
{
	switch (baseMode)
	{
		case GAMEMODE_COOP: strcopy(buffer, maxlen, "Coop");
		case GAMEMODE_VERSUS: strcopy(buffer, maxlen, "Versus");
		case GAMEMODE_SCAVENGE: strcopy(buffer, maxlen, "Scavenge");
		case GAMEMODE_SURVIVAL: strcopy(buffer, maxlen, "Survival");
		default: strcopy(buffer, maxlen, "Unknown");
	}
}

void Series_GetScopeLabel(PlayerStatsSeriesScope scope, char[] buffer, int maxlen)
{
	switch (scope)
	{
		case PlayerStatsSeriesScope_Mission: strcopy(buffer, maxlen, "Mission");
		case PlayerStatsSeriesScope_Map: strcopy(buffer, maxlen, "Map");
		default: strcopy(buffer, maxlen, "None");
	}
}

void Series_GetStatusLabel(int index, char[] buffer, int maxlen)
{
	if (index == g_iActiveSeriesIndex && g_Series[index].active)
	{
		strcopy(buffer, maxlen, "Active");
		return;
	}

	if (g_Series[index].closed)
	{
		strcopy(buffer, maxlen, "Closed");
		return;
	}

	strcopy(buffer, maxlen, "Idle");
}

void Series_GetSeriesScopeLabel(int seriesScope, char[] buffer, int maxlen)
{
	switch (seriesScope)
	{
		case 1: strcopy(buffer, maxlen, "Round");
		case 2: strcopy(buffer, maxlen, "Map");
		case 3: strcopy(buffer, maxlen, "Mission");
		default: strcopy(buffer, maxlen, "-");
	}
}

void Series_GetTeamLabel(int team, char[] buffer, int maxlen)
{
	switch (team)
	{
		case L4D2_PLAYER_STATS_SERIES_TEAM_SURVIVOR: strcopy(buffer, maxlen, "Survivor");
		case L4D2_PLAYER_STATS_SERIES_TEAM_INFECTED: strcopy(buffer, maxlen, "Infected");
		default: strcopy(buffer, maxlen, "-");
	}
}

void Series_PrintSummaryTable(int client)
{
	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[128];
	Format(line, sizeof(line), "PlayerStats Series Buffer");
	ConsolePanel_AddHeaderLine(panel, line);

	Format(line, sizeof(line), "Use sm_stats_series <id> for entry detail");
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Id", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "State", 8, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Mode", 9, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Scope", 8, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Entries", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "First", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Last", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Map", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Mission", 10, ConsoleTableAlignment_Left, ConsoleTableCellType_String);

	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_SERIES; i++)
	{
		if (!g_Series[i].active && !g_Series[i].closed)
		{
			continue;
		}

		if (!ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char state[16];
		char mode[16];
		char scope[16];
		Series_GetStatusLabel(i, state, sizeof(state));
		Series_GetModeLabel(g_Series[i].baseMode, mode, sizeof(mode));
		Series_GetScopeLabel(g_Series[i].scope, scope, sizeof(scope));

		ConsoleTable_AddIntCell(panel.table, g_Series[i].id);
		ConsoleTable_AddStringCell(panel.table, state);
		ConsoleTable_AddStringCell(panel.table, mode);
		ConsoleTable_AddStringCell(panel.table, scope);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].entryCount);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].firstRoundId);
		ConsoleTable_AddIntCell(panel.table, g_Series[i].lastRoundId);
		ConsoleTable_AddStringCell(panel.table, g_Series[i].map);
		ConsoleTable_AddStringCell(panel.table, g_Series[i].missionKey);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_PrintEntriesTable(int client, int index)
{
	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char mode[16];
	char scope[16];
	char state[16];
	char line[160];
	Series_GetModeLabel(g_Series[index].baseMode, mode, sizeof(mode));
	Series_GetScopeLabel(g_Series[index].scope, scope, sizeof(scope));
	Series_GetStatusLabel(index, state, sizeof(state));

	Format(line, sizeof(line), "PlayerStats Series %d", g_Series[index].id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "State=%s  Mode=%s  Scope=%s  Entries=%d", state, mode, scope, g_Series[index].entryCount);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Idx", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Round", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Map", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Scope", 8, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Half", 5, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Scav", 4, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 5, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "CI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Deaths", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Incaps", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	for (int i = 0; i < g_Series[index].entryCount; i++)
	{
		if (!g_Series[index].entries[i].active)
		{
			continue;
		}

		if (!ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char scopeValue[16];
		Series_GetSeriesScopeLabel(g_Series[index].entries[i].seriesScope, scopeValue, sizeof(scopeValue));

		ConsoleTable_AddIntCell(panel.table, i);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].roundId);
		ConsoleTable_AddStringCell(panel.table, g_Series[index].entries[i].map);
		ConsoleTable_AddStringCell(panel.table, scopeValue);
		ConsoleTable_AddStringCell(panel.table, g_Series[index].entries[i].secondHalf ? "2nd" : "1st");
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].scavengeRoundNumber);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].siKills);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].commonKills);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].deaths);
		ConsoleTable_AddIntCell(panel.table, g_Series[index].entries[i].incaps);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_PrintPlayersTable(int client, int index)
{
	PlayerStatsSeriesAggregateData players[L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS];
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; i++)
	{
		players[i].Reset();
	}

	for (int entryIndex = 0; entryIndex < g_Series[index].entryCount; entryIndex++)
	{
		if (!g_Series[index].entries[entryIndex].active)
		{
			continue;
		}

		for (int playerIndex = 0; playerIndex < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; playerIndex++)
		{
			if (!g_Series[index].entries[entryIndex].players[playerIndex].active)
			{
				continue;
			}

			int aggregateIndex = Series_FindAggregatePlayerIndex(players, g_Series[index].entries[entryIndex].players[playerIndex]);
			if (aggregateIndex == -1)
			{
				aggregateIndex = Series_AllocateAggregatePlayerIndex(players);
				if (aggregateIndex == -1)
				{
					continue;
				}

				players[aggregateIndex].active = true;
				players[aggregateIndex].team = g_Series[index].entries[entryIndex].players[playerIndex].team;
				players[aggregateIndex].accountId = g_Series[index].entries[entryIndex].players[playerIndex].accountId;
				players[aggregateIndex].bot = g_Series[index].entries[entryIndex].players[playerIndex].bot;
				strcopy(players[aggregateIndex].name, sizeof(players[aggregateIndex].name), g_Series[index].entries[entryIndex].players[playerIndex].name);
			}

			players[aggregateIndex].rounds++;
			players[aggregateIndex].siDamage += g_Series[index].entries[entryIndex].players[playerIndex].siDamage;
			players[aggregateIndex].tankDamage += g_Series[index].entries[entryIndex].players[playerIndex].tankDamage;
			players[aggregateIndex].witchDamage += g_Series[index].entries[entryIndex].players[playerIndex].witchDamage;
			players[aggregateIndex].commonKills += g_Series[index].entries[entryIndex].players[playerIndex].commonKills;
			players[aggregateIndex].ffGiven += g_Series[index].entries[entryIndex].players[playerIndex].ffGiven;
			players[aggregateIndex].deaths += g_Series[index].entries[entryIndex].players[playerIndex].deaths;
			players[aggregateIndex].incaps += g_Series[index].entries[entryIndex].players[playerIndex].incaps;
			players[aggregateIndex].healsGiven += g_Series[index].entries[entryIndex].players[playerIndex].healsGiven;
			players[aggregateIndex].revivesGiven += g_Series[index].entries[entryIndex].players[playerIndex].revivesGiven;
		}
	}

	Series_SortAggregatePlayers(players);

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 132);
	ConsolePanel_EnableSafeAscii(panel, false);

	char line[160];
	Format(line, sizeof(line), "PlayerStats Series %d Players", g_Series[index].id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "Aggregated player contribution across %d entries", g_Series[index].entryCount);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Player", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Team", 10, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Rounds", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "SI", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Tank", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Witch", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "CI", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "FF", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Deaths", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Incaps", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Heals", 6, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);
	ConsoleTable_AddColumn(panel.table, "Revives", 7, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; i++)
	{
		if (!players[i].active)
		{
			continue;
		}

		if (!ConsoleTable_BeginRow(panel.table))
		{
			continue;
		}

		char teamLabel[16];
		Series_GetTeamLabel(players[i].team, teamLabel, sizeof(teamLabel));
		ConsoleTable_AddStringCell(panel.table, players[i].name);
		ConsoleTable_AddStringCell(panel.table, teamLabel);
		ConsoleTable_AddIntCell(panel.table, players[i].rounds);
		ConsoleTable_AddIntCell(panel.table, players[i].siDamage);
		ConsoleTable_AddIntCell(panel.table, players[i].tankDamage);
		ConsoleTable_AddIntCell(panel.table, players[i].witchDamage);
		ConsoleTable_AddIntCell(panel.table, players[i].commonKills);
		ConsoleTable_AddIntCell(panel.table, players[i].ffGiven);
		ConsoleTable_AddIntCell(panel.table, players[i].deaths);
		ConsoleTable_AddIntCell(panel.table, players[i].incaps);
		ConsoleTable_AddIntCell(panel.table, players[i].healsGiven);
		ConsoleTable_AddIntCell(panel.table, players[i].revivesGiven);
		ConsoleTable_EndRow(panel.table);
	}

	ConsolePanel_RenderToClient(panel, client);
}

void Series_SortAggregatePlayers(PlayerStatsSeriesAggregateData[] players)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS - 1; i++)
	{
		int bestIndex = i;

		for (int j = i + 1; j < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; j++)
		{
			if (Series_ShouldPlayerSortBefore(players[j], players[bestIndex]))
			{
				bestIndex = j;
			}
		}

		if (bestIndex == i)
		{
			continue;
		}

		Series_SwapAggregatePlayers(players, i, bestIndex);
	}
}

bool Series_ShouldPlayerSortBefore(PlayerStatsSeriesAggregateData left, PlayerStatsSeriesAggregateData right)
{
	if (left.active != right.active)
	{
		return left.active && !right.active;
	}

	if (!left.active)
	{
		return false;
	}

	int leftCombat = left.siDamage + left.tankDamage + left.witchDamage;
	int rightCombat = right.siDamage + right.tankDamage + right.witchDamage;
	if (leftCombat != rightCombat)
	{
		return leftCombat > rightCombat;
	}

	if (left.commonKills != right.commonKills)
	{
		return left.commonKills > right.commonKills;
	}

	if (left.ffGiven != right.ffGiven)
	{
		return left.ffGiven < right.ffGiven;
	}

	if (left.rounds != right.rounds)
	{
		return left.rounds > right.rounds;
	}

	return strcmp(left.name, right.name, false) < 0;
}

void Series_SwapAggregatePlayers(PlayerStatsSeriesAggregateData[] players, int leftIndex, int rightIndex)
{
	bool tempActive = players[leftIndex].active;
	int tempTeam = players[leftIndex].team;
	int tempAccountId = players[leftIndex].accountId;
	bool tempBot = players[leftIndex].bot;
	char tempName[MAX_NAME_LENGTH];
	strcopy(tempName, sizeof(tempName), players[leftIndex].name);
	int tempRounds = players[leftIndex].rounds;
	int tempSiDamage = players[leftIndex].siDamage;
	int tempTankDamage = players[leftIndex].tankDamage;
	int tempWitchDamage = players[leftIndex].witchDamage;
	int tempCommonKills = players[leftIndex].commonKills;
	int tempFfGiven = players[leftIndex].ffGiven;
	int tempDeaths = players[leftIndex].deaths;
	int tempIncaps = players[leftIndex].incaps;
	int tempHealsGiven = players[leftIndex].healsGiven;
	int tempRevivesGiven = players[leftIndex].revivesGiven;

	players[leftIndex].active = players[rightIndex].active;
	players[leftIndex].team = players[rightIndex].team;
	players[leftIndex].accountId = players[rightIndex].accountId;
	players[leftIndex].bot = players[rightIndex].bot;
	strcopy(players[leftIndex].name, sizeof(players[leftIndex].name), players[rightIndex].name);
	players[leftIndex].rounds = players[rightIndex].rounds;
	players[leftIndex].siDamage = players[rightIndex].siDamage;
	players[leftIndex].tankDamage = players[rightIndex].tankDamage;
	players[leftIndex].witchDamage = players[rightIndex].witchDamage;
	players[leftIndex].commonKills = players[rightIndex].commonKills;
	players[leftIndex].ffGiven = players[rightIndex].ffGiven;
	players[leftIndex].deaths = players[rightIndex].deaths;
	players[leftIndex].incaps = players[rightIndex].incaps;
	players[leftIndex].healsGiven = players[rightIndex].healsGiven;
	players[leftIndex].revivesGiven = players[rightIndex].revivesGiven;

	players[rightIndex].active = tempActive;
	players[rightIndex].team = tempTeam;
	players[rightIndex].accountId = tempAccountId;
	players[rightIndex].bot = tempBot;
	strcopy(players[rightIndex].name, sizeof(players[rightIndex].name), tempName);
	players[rightIndex].rounds = tempRounds;
	players[rightIndex].siDamage = tempSiDamage;
	players[rightIndex].tankDamage = tempTankDamage;
	players[rightIndex].witchDamage = tempWitchDamage;
	players[rightIndex].commonKills = tempCommonKills;
	players[rightIndex].ffGiven = tempFfGiven;
	players[rightIndex].deaths = tempDeaths;
	players[rightIndex].incaps = tempIncaps;
	players[rightIndex].healsGiven = tempHealsGiven;
	players[rightIndex].revivesGiven = tempRevivesGiven;
}

void Series_PrintTotalsTable(int client, int index)
{
	int siDamage = 0;
	int tankDamage = 0;
	int witchDamage = 0;
	int commonKills = 0;
	int ff = 0;
	int deaths = 0;
	int incaps = 0;
	int healsGiven = 0;
	int revivesGiven = 0;
	int firstHalfCount = 0;
	int secondHalfCount = 0;

	for (int i = 0; i < g_Series[index].entryCount; i++)
	{
		if (!g_Series[index].entries[i].active)
		{
			continue;
		}

		if (g_Series[index].entries[i].secondHalf)
		{
			secondHalfCount++;
		}
		else
		{
			firstHalfCount++;
		}

		siDamage += g_Series[index].entries[i].siDamage;
		tankDamage += g_Series[index].entries[i].tankDamage;
		witchDamage += g_Series[index].entries[i].witchDamage;
		commonKills += g_Series[index].entries[i].commonKills;
		ff += g_Series[index].entries[i].ff;
		deaths += g_Series[index].entries[i].deaths;
		incaps += g_Series[index].entries[i].incaps;
		healsGiven += g_Series[index].entries[i].healsGiven;
		revivesGiven += g_Series[index].entries[i].revivesGiven;
	}

	ConsolePanel panel;
	ConsolePanel_Reset(panel);
	ConsolePanel_SetWidth(panel, 100);
	ConsolePanel_EnableSafeAscii(panel, false);

	char mode[16];
	char scope[16];
	char state[16];
	char line[160];
	Series_GetModeLabel(g_Series[index].baseMode, mode, sizeof(mode));
	Series_GetScopeLabel(g_Series[index].scope, scope, sizeof(scope));
	Series_GetStatusLabel(index, state, sizeof(state));

	Format(line, sizeof(line), "PlayerStats Series %d Totals", g_Series[index].id);
	ConsolePanel_AddHeaderLine(panel, line);
	Format(line, sizeof(line), "State=%s  Mode=%s  Scope=%s  Entries=%d  Halves=%d/%d", state, mode, scope, g_Series[index].entryCount, firstHalfCount, secondHalfCount);
	ConsolePanel_AddHeaderLine(panel, line);

	ConsoleTable_AddColumn(panel.table, "Metric", 18, ConsoleTableAlignment_Left, ConsoleTableCellType_String);
	ConsoleTable_AddColumn(panel.table, "Value", 14, ConsoleTableAlignment_Right, ConsoleTableCellType_Int);

	Series_AddTotalsRow(panel, "SI Damage", siDamage);
	Series_AddTotalsRow(panel, "Tank Damage", tankDamage);
	Series_AddTotalsRow(panel, "Witch Damage", witchDamage);
	Series_AddTotalsRow(panel, "Common Kills", commonKills);
	Series_AddTotalsRow(panel, "Friendly Fire", ff);
	Series_AddTotalsRow(panel, "Deaths", deaths);
	Series_AddTotalsRow(panel, "Incaps", incaps);
	Series_AddTotalsRow(panel, "Heals Given", healsGiven);
	Series_AddTotalsRow(panel, "Revives Given", revivesGiven);

	ConsolePanel_RenderToClient(panel, client);
}

void Series_AddTotalsRow(ConsolePanel panel, const char[] label, int value)
{
	if (!ConsoleTable_BeginRow(panel.table))
	{
		return;
	}

	ConsoleTable_AddStringCell(panel.table, label);
	ConsoleTable_AddIntCell(panel.table, value);
	ConsoleTable_EndRow(panel.table);
}

void Series_CaptureEntryPlayers(int seriesIndex, int entryIndex, int roundId)
{
	int outputIndex = 0;

	for (int slot = 0; slot < L4D2_PLAYER_STATS_SERIES_MAX_SLOTS && outputIndex < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; slot++)
	{
		if (!PlayerStats_IsRoundPlayerSlotValid(roundId, slot))
		{
			continue;
		}

		Handle kv = CreateKeyValues("player_stats_series_player");
		if (kv == INVALID_HANDLE || !PlayerStats_FillRoundPlayerKeyValues(roundId, slot, kv))
		{
			if (kv != INVALID_HANDLE)
			{
				delete kv;
			}
			continue;
		}

		if (!Series_ReadPlayerSnapshotFromKv(g_Series[seriesIndex].entries[entryIndex].players[outputIndex], kv, slot))
		{
			delete kv;
			continue;
		}

		g_Series[seriesIndex].entries[entryIndex].siKills += g_Series[seriesIndex].entries[entryIndex].players[outputIndex].siKills;
		outputIndex++;
		delete kv;
	}
}

void Series_CaptureEntryTotals(int seriesIndex, int entryIndex, Handle kv)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false) || !KvJumpToKey(kv, "totals", false))
	{
		KvRewind(kv);
		return;
	}

	g_Series[seriesIndex].entries[entryIndex].siDamage = KvGetNum(kv, "si_damage", 0);
	g_Series[seriesIndex].entries[entryIndex].tankDamage = KvGetNum(kv, "tank_damage", 0);
	g_Series[seriesIndex].entries[entryIndex].witchDamage = KvGetNum(kv, "witch_damage", 0);
	g_Series[seriesIndex].entries[entryIndex].commonKills = KvGetNum(kv, "common_kills", 0);
	g_Series[seriesIndex].entries[entryIndex].ff = KvGetNum(kv, "ff", 0);
	g_Series[seriesIndex].entries[entryIndex].deaths = KvGetNum(kv, "deaths", 0);
	g_Series[seriesIndex].entries[entryIndex].incaps = KvGetNum(kv, "incaps", 0);
	g_Series[seriesIndex].entries[entryIndex].healsGiven = KvGetNum(kv, "heals_given", 0);
	g_Series[seriesIndex].entries[entryIndex].revivesGiven = KvGetNum(kv, "revives_given", 0);

	KvGoBack(kv);
	KvRewind(kv);
}

bool Series_ReadPlayerSnapshotFromKv(PlayerStatsSeriesPlayerData player, Handle kv, int slot)
{
	KvRewind(kv);
	if (!KvJumpToKey(kv, "player", false))
	{
		return false;
	}

	if (!KvJumpToKey(kv, "identity", false))
	{
		KvRewind(kv);
		return false;
	}

	player.Reset();
	player.active = true;
	player.slot = slot;
	player.accountId = KvGetNum(kv, "accountid", 0);
	player.bot = KvGetNum(kv, "bot", 0) > 0;
	player.team = KvGetNum(kv, "team", 0);
	KvGetString(kv, "name", player.name, sizeof(player.name), "");
	KvGoBack(kv);

	if (KvJumpToKey(kv, "combat", false))
	{
		player.siDamage = KvGetNum(kv, "si_damage", 0);
		player.tankDamage = KvGetNum(kv, "tank_damage", 0);
		player.witchDamage = KvGetNum(kv, "witch_damage", 0);
		player.siKills =
			KvGetNum(kv, "smoker_kills", 0) +
			KvGetNum(kv, "boomer_kills", 0) +
			KvGetNum(kv, "hunter_kills", 0) +
			KvGetNum(kv, "spitter_kills", 0) +
			KvGetNum(kv, "jockey_kills", 0) +
			KvGetNum(kv, "charger_kills", 0);
		player.commonKills = KvGetNum(kv, "common_kills", 0);
		player.ffGiven = KvGetNum(kv, "ff_given", 0);
		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "survivability", false))
	{
		player.deaths = KvGetNum(kv, "deaths", 0);
		player.incaps = KvGetNum(kv, "incaps", 0);
		KvGoBack(kv);
	}

	if (KvJumpToKey(kv, "support", false))
	{
		player.healsGiven = KvGetNum(kv, "heals_given", 0);
		player.revivesGiven = KvGetNum(kv, "revives_given", 0);
		KvGoBack(kv);
	}

	KvRewind(kv);
	return true;
}

int Series_FindAggregatePlayerIndex(PlayerStatsSeriesAggregateData[] players, PlayerStatsSeriesPlayerData player)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; i++)
	{
		if (!players[i].active)
		{
			continue;
		}

		if (!player.bot && player.accountId > 0 && players[i].accountId == player.accountId)
		{
			return i;
		}

		if (player.bot && players[i].bot && players[i].team == player.team && StrEqual(players[i].name, player.name, false))
		{
			return i;
		}
	}

	return -1;
}

int Series_AllocateAggregatePlayerIndex(PlayerStatsSeriesAggregateData[] players)
{
	for (int i = 0; i < L4D2_PLAYER_STATS_SERIES_MAX_PLAYERS; i++)
	{
		if (!players[i].active)
		{
			return i;
		}
	}

	return -1;
}
