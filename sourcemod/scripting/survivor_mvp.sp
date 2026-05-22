#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <l4d2_player_stats>

bool g_bPlayerStatsAvailable = false;

public Plugin myinfo =
{
	name = "Survivor MVP Wrapper",
	author = "lechuga",
	description = "Legacy survivor_mvp compatibility wrapper over l4d2_player_stats.",
	version = "1.0.0",
	url = "https://github.com/AoC-Gamers/L4D2-Player-Stats"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("survivor_mvp");
	CreateNative("SURVMVP_GetMVP", Native_SURVMVP_GetMVP);
	CreateNative("SURVMVP_GetMVPSlot", Native_SURVMVP_GetMVPSlot);
	CreateNative("SURVMVP_GetMVPDmgCount", Native_SURVMVP_GetMVPDmgCount);
	CreateNative("SURVMVP_GetMVPDmgPercent", Native_SURVMVP_GetMVPDmgPercent);
	CreateNative("SURVMVP_GetMVPKills", Native_SURVMVP_GetMVPKills);
	CreateNative("SURVMVP_GetMVPCI", Native_SURVMVP_GetMVPCI);
	CreateNative("SURVMVP_GetMVPCISlot", Native_SURVMVP_GetMVPCISlot);
	CreateNative("SURVMVP_GetMVPCIKills", Native_SURVMVP_GetMVPCIKills);
	CreateNative("SURVMVP_GetMVPCIPercent", Native_SURVMVP_GetMVPCIPercent);
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

bool Legacy_CanQueryRound(int &roundId)
{
	if (!g_bPlayerStatsAvailable)
	{
		return false;
	}

	roundId = PlayerStats_GetRoundId();
	return roundId > 0;
}

bool Legacy_OpenRoundKeyValues(int roundId, KeyValues kv)
{
	return PlayerStats_FillRoundKeyValues(roundId, kv);
}

bool Legacy_OpenPlayerKeyValues(int roundId, int slot, KeyValues kv)
{
	return PlayerStats_FillRoundPlayerKeyValues(roundId, slot, kv);
}

bool Legacy_GetCombatInt(int roundId, int slot, const char[] key, int &value)
{
	KeyValues kv = new KeyValues("player");

	if (!Legacy_OpenPlayerKeyValues(roundId, slot, kv))
	{
		delete kv;
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "player", false)
		|| !KvJumpToKey(kv, "combat", false))
	{
		delete kv;
		return false;
	}

	value = KvGetNum(kv, key, 0);
	delete kv;
	return true;
}

int Legacy_GetPlayerDamageScore(int roundId, int slot)
{
	int siDamage = 0;
	int tankDamage = 0;
	int witchDamage = 0;

	Legacy_GetCombatInt(roundId, slot, "si_damage", siDamage);
	Legacy_GetCombatInt(roundId, slot, "tank_damage", tankDamage);
	Legacy_GetCombatInt(roundId, slot, "witch_damage", witchDamage);

	return siDamage + tankDamage + witchDamage;
}

int Legacy_GetPlayerSpecialKills(int roundId, int slot)
{
	int kills = 0;
	int value = 0;

	static const char keys[][] =
	{
		"smoker_kills",
		"boomer_kills",
		"hunter_kills",
		"spitter_kills",
		"jockey_kills",
		"charger_kills"
	};

	for (int i = 0; i < sizeof(keys); i++)
	{
		if (Legacy_GetCombatInt(roundId, slot, keys[i], value))
		{
			kills += value;
		}
	}

	return kills;
}

int Legacy_GetPlayerCommonKills(int roundId, int slot)
{
	int commonKills = 0;
	Legacy_GetCombatInt(roundId, slot, "common_kills", commonKills);
	return commonKills;
}

bool Legacy_GetRoundTotals(int roundId, int &totalDamage, int &totalCommon)
{
	KeyValues kv = new KeyValues("round");

	if (!Legacy_OpenRoundKeyValues(roundId, kv))
	{
		delete kv;
		return false;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false)
		|| !KvJumpToKey(kv, "totals", false))
	{
		delete kv;
		return false;
	}

	totalDamage = KvGetNum(kv, "si_damage", 0)
		+ KvGetNum(kv, "tank_damage", 0)
		+ KvGetNum(kv, "witch_damage", 0);
	totalCommon = KvGetNum(kv, "common_kills", 0);

	delete kv;
	return true;
}

int Legacy_FindTopSlotByDamage(int roundId)
{
	KeyValues kv = new KeyValues("round");
	int bestSlot = -1;
	int bestScore = -1;

	if (!Legacy_OpenRoundKeyValues(roundId, kv))
	{
		delete kv;
		return -1;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false)
		|| !KvJumpToKey(kv, "players", false)
		|| !KvGotoFirstSubKey(kv, false))
	{
		delete kv;
		return -1;
	}

	do
	{
		int slot = KvGetNum(kv, "slot", -1);
		if (!PlayerStats_IsRoundPlayerSlotValid(roundId, slot))
		{
			continue;
		}

		int score = Legacy_GetPlayerDamageScore(roundId, slot);
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}
	while (KvGotoNextKey(kv, false));

	delete kv;
	return bestSlot;
}

int Legacy_FindTopSlotByCommon(int roundId)
{
	KeyValues kv = new KeyValues("round");
	int bestSlot = -1;
	int bestScore = -1;

	if (!Legacy_OpenRoundKeyValues(roundId, kv))
	{
		delete kv;
		return -1;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false)
		|| !KvJumpToKey(kv, "players", false)
		|| !KvGotoFirstSubKey(kv, false))
	{
		delete kv;
		return -1;
	}

	do
	{
		int slot = KvGetNum(kv, "slot", -1);
		if (!PlayerStats_IsRoundPlayerSlotValid(roundId, slot))
		{
			continue;
		}

		int score = Legacy_GetPlayerCommonKills(roundId, slot);
		if (score > bestScore)
		{
			bestScore = score;
			bestSlot = slot;
		}
	}
	while (KvGotoNextKey(kv, false));

	delete kv;
	return bestSlot;
}

int Legacy_GetClientSlot(int client)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId) || client <= 0)
	{
		return -1;
	}

	KeyValues kv = new KeyValues("round");

	if (!Legacy_OpenRoundKeyValues(roundId, kv))
	{
		delete kv;
		return -1;
	}

	KvRewind(kv);
	if (!KvJumpToKey(kv, "round", false)
		|| !KvJumpToKey(kv, "players", false)
		|| !KvGotoFirstSubKey(kv, false))
	{
		delete kv;
		return -1;
	}

	do
	{
		int slot = KvGetNum(kv, "slot", -1);
		if (!PlayerStats_IsRoundPlayerSlotValid(roundId, slot))
		{
			continue;
		}

		if (PlayerStats_GetRoundPlayerClient(roundId, slot) == client)
		{
			delete kv;
			return slot;
		}
	}
	while (KvGotoNextKey(kv, false));

	delete kv;
	return -1;
}

public int Native_SURVMVP_GetMVP(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0;
	}

	int slot = Legacy_FindTopSlotByDamage(roundId);
	return slot != -1 ? PlayerStats_GetRoundPlayerClient(roundId, slot) : 0;
}

public int Native_SURVMVP_GetMVPSlot(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return -1;
	}

	return Legacy_FindTopSlotByDamage(roundId);
}

public int Native_SURVMVP_GetMVPDmgCount(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0;
	}

	int client = GetNativeCell(1);
	int slot = Legacy_GetClientSlot(client);
	return slot != -1 ? Legacy_GetPlayerDamageScore(roundId, slot) : 0;
}

public any Native_SURVMVP_GetMVPDmgPercent(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0.0;
	}

	int client = GetNativeCell(1);
	int slot = Legacy_GetClientSlot(client);
	if (slot == -1)
	{
		return 0.0;
	}

	int totalDamage = 0;
	int totalCommon = 0;
	if (!Legacy_GetRoundTotals(roundId, totalDamage, totalCommon) || totalDamage <= 0)
	{
		return 0.0;
	}

	return (float(Legacy_GetPlayerDamageScore(roundId, slot)) / float(totalDamage)) * 100.0;
}

public int Native_SURVMVP_GetMVPKills(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0;
	}

	int client = GetNativeCell(1);
	int slot = Legacy_GetClientSlot(client);
	return slot != -1 ? Legacy_GetPlayerSpecialKills(roundId, slot) : 0;
}

public int Native_SURVMVP_GetMVPCI(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0;
	}

	int slot = Legacy_FindTopSlotByCommon(roundId);
	return slot != -1 ? PlayerStats_GetRoundPlayerClient(roundId, slot) : 0;
}

public int Native_SURVMVP_GetMVPCISlot(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return -1;
	}

	return Legacy_FindTopSlotByCommon(roundId);
}

public int Native_SURVMVP_GetMVPCIKills(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0;
	}

	int client = GetNativeCell(1);
	int slot = Legacy_GetClientSlot(client);
	return slot != -1 ? Legacy_GetPlayerCommonKills(roundId, slot) : 0;
}

public any Native_SURVMVP_GetMVPCIPercent(Handle plugin, int numParams)
{
	int roundId;
	if (!Legacy_CanQueryRound(roundId))
	{
		return 0.0;
	}

	int client = GetNativeCell(1);
	int slot = Legacy_GetClientSlot(client);
	if (slot == -1)
	{
		return 0.0;
	}

	int totalDamage = 0;
	int totalCommon = 0;
	if (!Legacy_GetRoundTotals(roundId, totalDamage, totalCommon) || totalCommon <= 0)
	{
		return 0.0;
	}

	return (float(Legacy_GetPlayerCommonKills(roundId, slot)) / float(totalCommon)) * 100.0;
}
