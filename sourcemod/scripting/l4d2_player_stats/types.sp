#if defined _l4d2_player_stats_types_included
	#endinput
#endif
#define _l4d2_player_stats_types_included

#define L4D2_PLAYER_STATS_MAX_PLAYERS 33
#define L4D2_PLAYER_STATS_MAX_SLOTS 65

enum PlayerStatsTeam
{
	PlayerStatsTeam_None = 0,
	PlayerStatsTeam_Survivor,
	PlayerStatsTeam_Infected
}

enum PlayerStatsAttributionType
{
	PlayerStatsAttribution_None = 0,
	PlayerStatsAttribution_Survivor,
	PlayerStatsAttribution_InfectedPlayer,
	PlayerStatsAttribution_InfectedAI
}

enum PlayerStatsDebugCategory
{
	PlayerStatsDebug_None		= 0,
	PlayerStatsDebug_Core		= 1 << 0,
	PlayerStatsDebug_Detect		= 1 << 1,
	PlayerStatsDebug_Api		= 1 << 2,
	PlayerStatsDebug_Announce	= 1 << 3
}

enum struct PlayerStatsPlayerRef
{
	int  client;
	int  userid;
	int  accountId;
	bool bot;
	int  character;
	char name[MAX_NAME_LENGTH];
	char auth[32];

	/**
	 * @brief Clears the captured player snapshot.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.client = 0;
		this.userid = 0;
		this.accountId = 0;
		this.bot = false;
		this.character = -1;
		this.name[0] = '\0';
		this.auth[0] = '\0';
	}

	/**
	 * @brief Captures the current identity of a connected client.
	 *
	 * @param clientIndex   SourceMod client index.
	 *
	 * @noreturn
	 */
	void Capture(int clientIndex)
	{
		this.Reset();

		if (!IsValidClient(clientIndex))
		{
			return;
		}

		this.client = clientIndex;
		this.userid = GetClientUserId(clientIndex);
		this.accountId = GetSteamAccountID(clientIndex);
		this.bot = IsFakeClient(clientIndex);
		this.character = (L4D_GetClientTeam(clientIndex) == L4DTeam_Survivor) ? GetEntProp(clientIndex, Prop_Send, "m_survivorCharacter") : -1;
		GetClientName(clientIndex, this.name, sizeof(this.name));
		GetClientAuthId(clientIndex, AuthId_Steam2, this.auth, sizeof(this.auth), true);
	}

	/**
	 * @brief Clears the runtime client binding while keeping persistent identity fields.
	 *
	 * @noreturn
	 */
	void DetachClient()
	{
		this.client = 0;
		this.userid = 0;
	}

	/**
	 * @brief Returns whether the captured player is currently online.
	 *
	 * @return               True if the stored runtime client is still valid.
	 */
	bool IsOnline()
	{
		return IsValidClient(this.client);
	}

	/**
	 * @brief Resolves the stored runtime userid back to a live client index.
	 *
	 * @return               Client index, or 0 if the player is offline.
	 */
	int ResolveClient()
	{
		int current = GetClientOfUserId(this.userid);
		return IsValidClient(current) ? current : 0;
	}

	/**
	 * @brief Checks whether a live client matches this runtime snapshot.
	 *
	 * @param clientIndex    SourceMod client index.
	 *
	 * @return               True if the userid matches the captured runtime user.
	 */
	bool IsSameRuntimePlayer(int clientIndex)
	{
		return IsValidClient(clientIndex) && this.userid > 0 && GetClientUserId(clientIndex) == this.userid;
	}

	/**
	 * @brief Checks whether a runtime client matches this persistent identity.
	 *
	 * @param clientIndex    SourceMod client index.
	 *
	 * @return               True if the client matches the stored human or bot identity.
	 */
	bool IsSamePersistentPlayer(int clientIndex)
	{
		if (!IsValidClient(clientIndex))
		{
			return false;
		}

		if (!IsFakeClient(clientIndex))
		{
			int accountId = GetSteamAccountID(clientIndex);
			if (this.accountId > 0 && accountId > 0)
			{
				return this.accountId == accountId;
			}

			char auth[32];
			GetClientAuthId(clientIndex, AuthId_Steam2, auth, sizeof(auth), true);
			return this.auth[0] != '\0' && strcmp(this.auth, auth) == 0;
		}

		if (!this.bot)
		{
			return false;
		}

		if (L4D_GetClientTeam(clientIndex) != L4DTeam_Survivor || this.character < 0)
		{
			return false;
		}

		return GetEntProp(clientIndex, Prop_Send, "m_survivorCharacter") == this.character;
	}
}

enum struct PlayerStatsCombatData
{
	int siDamage;
	int smokerDamage;
	int boomerDamage;
	int hunterDamage;
	int spitterDamage;
	int jockeyDamage;
	int chargerDamage;
	int commonKills;
	int smokerKills;
	int boomerKills;
	int hunterKills;
	int spitterKills;
	int jockeyKills;
	int chargerKills;
	int tankKills;
	int ffGiven;
	int tankDamage;
	int witchDamage;

	void Reset()
	{
		this.siDamage = 0;
		this.smokerDamage = 0;
		this.boomerDamage = 0;
		this.hunterDamage = 0;
		this.spitterDamage = 0;
		this.jockeyDamage = 0;
		this.chargerDamage = 0;
		this.commonKills = 0;
		this.smokerKills = 0;
		this.boomerKills = 0;
		this.hunterKills = 0;
		this.spitterKills = 0;
		this.jockeyKills = 0;
		this.chargerKills = 0;
		this.tankKills = 0;
		this.ffGiven = 0;
		this.tankDamage = 0;
		this.witchDamage = 0;
	}
}

enum struct PlayerStatsSurvivabilityData
{
	int deaths;
	int incaps;
	int deathBySurvivor;
	int deathByInfectedPlayer;
	int deathByInfectedAI;
	int incapBySurvivor;
	int incapByInfectedPlayer;
	int incapByInfectedAI;

	void Reset()
	{
		this.deaths = 0;
		this.incaps = 0;
		this.deathBySurvivor = 0;
		this.deathByInfectedPlayer = 0;
		this.deathByInfectedAI = 0;
		this.incapBySurvivor = 0;
		this.incapByInfectedPlayer = 0;
		this.incapByInfectedAI = 0;
	}
}

enum struct PlayerStatsSupportData
{
	int healsGiven;
	int healsReceived;
	int revivesGiven;
	int revivesReceived;
	int rescuesGiven;
	int rescuesReceived;

	void Reset()
	{
		this.healsGiven = 0;
		this.healsReceived = 0;
		this.revivesGiven = 0;
		this.revivesReceived = 0;
		this.rescuesGiven = 0;
		this.rescuesReceived = 0;
	}
}

enum struct PlayerStatsPressureData
{
	int tongueGrabs;
	int hunterPouncesLanded;
	int jockeyRidesLanded;
	int boomerVomitVictims;

	void Reset()
	{
		this.tongueGrabs = 0;
		this.hunterPouncesLanded = 0;
		this.jockeyRidesLanded = 0;
		this.boomerVomitVictims = 0;
	}
}

enum struct PlayerStatsSkillData
{
	int skeets;
	int skeetMelees;
	int deadstops;
	int boomerPops;
	int levels;
	int crowns;
	int tongueCuts;
	int smokerSelfClears;
	int instaKills;

	void Reset()
	{
		this.skeets = 0;
		this.skeetMelees = 0;
		this.deadstops = 0;
		this.boomerPops = 0;
		this.levels = 0;
		this.crowns = 0;
		this.tongueCuts = 0;
		this.smokerSelfClears = 0;
		this.instaKills = 0;
	}
}

enum struct PlayerStatsResourceData
{
	int pillsUsed;
	int adrenalineUsed;
	int medkitsUsed;
	int defibsUsed;
	int molotovsThrown;
	int pipebombsThrown;
	int vomitjarsThrown;

	void Reset()
	{
		this.pillsUsed = 0;
		this.adrenalineUsed = 0;
		this.medkitsUsed = 0;
		this.defibsUsed = 0;
		this.molotovsThrown = 0;
		this.pipebombsThrown = 0;
		this.vomitjarsThrown = 0;
	}
}

enum struct PlayerStatsPlayerRoundData
{
	bool active;
	PlayerStatsPlayerRef player;
	PlayerStatsTeam team;
	PlayerStatsCombatData combat;
	PlayerStatsSurvivabilityData survivability;
	PlayerStatsSupportData support;
	PlayerStatsPressureData pressure;
	PlayerStatsSkillData skills;
	PlayerStatsResourceData resources;

	/**
	 * @brief Resets all tracked per-player round values.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.active = false;
		this.player.Reset();
		this.team = PlayerStatsTeam_None;
		this.combat.Reset();
		this.survivability.Reset();
		this.support.Reset();
		this.pressure.Reset();
		this.skills.Reset();
		this.resources.Reset();
	}
}

enum struct PlayerStatsRoundMetaData
{
	int id;
	bool active;
	float startedAt;
	float endedAt;

	void Reset()
	{
		this.id = 0;
		this.active = false;
		this.startedAt = 0.0;
		this.endedAt = 0.0;
	}
}

enum struct PlayerStatsRoundTotalsData
{
	int survivorTotalSiDamage;
	int survivorTotalSmokerDamage;
	int survivorTotalBoomerDamage;
	int survivorTotalHunterDamage;
	int survivorTotalSpitterDamage;
	int survivorTotalJockeyDamage;
	int survivorTotalChargerDamage;
	int survivorTotalTankDamage;
	int survivorTotalWitchDamage;
	int survivorTotalCommonKills;
	int survivorTotalSmokerKills;
	int survivorTotalBoomerKills;
	int survivorTotalHunterKills;
	int survivorTotalSpitterKills;
	int survivorTotalJockeyKills;
	int survivorTotalChargerKills;
	int survivorTotalTankKills;
	int survivorTotalFF;
	int survivorTotalDeaths;
	int survivorTotalIncaps;
	int survivorTotalHealsGiven;
	int survivorTotalRevivesGiven;
	int survivorTotalRescuesGiven;
	int infectedTotalTongueGrabs;
	int infectedTotalHunterPouncesLanded;
	int infectedTotalJockeyRidesLanded;
	int infectedTotalBoomerVomitVictims;
	int survivorTotalSkeets;
	int survivorTotalSkeetMelees;
	int survivorTotalDeadstops;
	int survivorTotalBoomerPops;
	int survivorTotalLevels;
	int survivorTotalCrowns;
	int survivorTotalTongueCuts;
	int survivorTotalSmokerSelfClears;
	int survivorTotalInstaKills;
	int survivorTotalPillsUsed;
	int survivorTotalAdrenalineUsed;
	int survivorTotalMedkitsUsed;
	int survivorTotalDefibsUsed;
	int survivorTotalMolotovsThrown;
	int survivorTotalPipebombsThrown;
	int survivorTotalVomitjarsThrown;

	void Reset()
	{
		this.survivorTotalSiDamage = 0;
		this.survivorTotalSmokerDamage = 0;
		this.survivorTotalBoomerDamage = 0;
		this.survivorTotalHunterDamage = 0;
		this.survivorTotalSpitterDamage = 0;
		this.survivorTotalJockeyDamage = 0;
		this.survivorTotalChargerDamage = 0;
		this.survivorTotalTankDamage = 0;
		this.survivorTotalWitchDamage = 0;
		this.survivorTotalCommonKills = 0;
		this.survivorTotalSmokerKills = 0;
		this.survivorTotalBoomerKills = 0;
		this.survivorTotalHunterKills = 0;
		this.survivorTotalSpitterKills = 0;
		this.survivorTotalJockeyKills = 0;
		this.survivorTotalChargerKills = 0;
		this.survivorTotalTankKills = 0;
		this.survivorTotalFF = 0;
		this.survivorTotalDeaths = 0;
		this.survivorTotalIncaps = 0;
		this.survivorTotalHealsGiven = 0;
		this.survivorTotalRevivesGiven = 0;
		this.survivorTotalRescuesGiven = 0;
		this.infectedTotalTongueGrabs = 0;
		this.infectedTotalHunterPouncesLanded = 0;
		this.infectedTotalJockeyRidesLanded = 0;
		this.infectedTotalBoomerVomitVictims = 0;
		this.survivorTotalSkeets = 0;
		this.survivorTotalSkeetMelees = 0;
		this.survivorTotalDeadstops = 0;
		this.survivorTotalBoomerPops = 0;
		this.survivorTotalLevels = 0;
		this.survivorTotalCrowns = 0;
		this.survivorTotalTongueCuts = 0;
		this.survivorTotalSmokerSelfClears = 0;
		this.survivorTotalInstaKills = 0;
		this.survivorTotalPillsUsed = 0;
		this.survivorTotalAdrenalineUsed = 0;
		this.survivorTotalMedkitsUsed = 0;
		this.survivorTotalDefibsUsed = 0;
		this.survivorTotalMolotovsThrown = 0;
		this.survivorTotalPipebombsThrown = 0;
		this.survivorTotalVomitjarsThrown = 0;
	}
}

enum struct PlayerStatsRoundData
{
	PlayerStatsRoundMetaData meta;
	PlayerStatsRoundTotalsData totals;
	PlayerStatsPlayerRoundData players[L4D2_PLAYER_STATS_MAX_SLOTS];

	/**
	 * @brief Resets the current round snapshot and all tracked players.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.meta.Reset();
		this.totals.Reset();

		for (int client = 0; client < L4D2_PLAYER_STATS_MAX_SLOTS; client++)
		{
			this.players[client].Reset();
		}
	}
}

enum struct PlayerStatsRuntimeState
{
	bool roundLive;
	bool readyUpAvailable;
	bool playerSkillsAvailable;
	bool lateload;
	int playerSlotByClient[L4D2_PLAYER_STATS_MAX_PLAYERS];

	/**
	 * @brief Resets runtime flags and client-to-slot mappings.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.roundLive = false;
		this.readyUpAvailable = false;
		this.playerSkillsAvailable = false;
		this.lateload = false;

		for (int client = 0; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
		{
			this.playerSlotByClient[client] = -1;
		}
	}
}
