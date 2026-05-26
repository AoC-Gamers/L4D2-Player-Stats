#if defined _l4d2_player_stats_types_included
	#endinput
#endif
#define _l4d2_player_stats_types_included

#define L4D2_PLAYER_STATS_MAX_PLAYERS 33
#define L4D2_PLAYER_STATS_MAX_SLOTS 65
#define L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES 16
#define L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS 32
#define L4D2_PLAYER_STATS_MAX_SURVIVORS 4

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

enum PlayerStatsWeaponFamily
{
	PlayerStatsWeaponFamily_None = 0,
	PlayerStatsWeaponFamily_Shotgun,
	PlayerStatsWeaponFamily_SmgRifle,
	PlayerStatsWeaponFamily_Sniper,
	PlayerStatsWeaponFamily_Pistol
}

enum PlayerStatsWeaponDetailType
{
	PlayerStatsWeaponDetail_None = 0,
	PlayerStatsWeaponDetail_PumpShotgun,
	PlayerStatsWeaponDetail_Autoshotgun,
	PlayerStatsWeaponDetail_ChromeShotgun,
	PlayerStatsWeaponDetail_SpasShotgun,
	PlayerStatsWeaponDetail_Smg,
	PlayerStatsWeaponDetail_SmgSilenced,
	PlayerStatsWeaponDetail_SmgMp5,
	PlayerStatsWeaponDetail_Rifle,
	PlayerStatsWeaponDetail_RifleAk47,
	PlayerStatsWeaponDetail_RifleDesert,
	PlayerStatsWeaponDetail_RifleSg552,
	PlayerStatsWeaponDetail_RifleM60,
	PlayerStatsWeaponDetail_HuntingRifle,
	PlayerStatsWeaponDetail_SniperMilitary,
	PlayerStatsWeaponDetail_SniperAwp,
	PlayerStatsWeaponDetail_SniperScout,
	PlayerStatsWeaponDetail_Pistol,
	PlayerStatsWeaponDetail_Magnum,
	PlayerStatsWeaponDetail_Count
}

enum PlayerStatsSiPoolFlag
{
	PlayerStatsSiPool_None = 0,
	PlayerStatsSiPool_Smoker = 1 << 0,
	PlayerStatsSiPool_Boomer = 1 << 1,
	PlayerStatsSiPool_Hunter = 1 << 2,
	PlayerStatsSiPool_Spitter = 1 << 3,
	PlayerStatsSiPool_Jockey = 1 << 4,
	PlayerStatsSiPool_Charger = 1 << 5
}

enum PlayerStatsFeatureFlag
{
	PlayerStatsFeature_None = 0,
	PlayerStatsFeature_Enable = 1 << 0,
	PlayerStatsFeature_Announce = 1 << 1
}

enum PlayerStatsGamemodeFlag
{
	PlayerStatsGamemode_None = 0,
	PlayerStatsGamemode_Coop = 1 << 0,
	PlayerStatsGamemode_Versus = 1 << 1,
	PlayerStatsGamemode_Scavenge = 1 << 2,
	PlayerStatsGamemode_Survival = 1 << 3
}

enum PlayerStatsVersusContextType
{
	PlayerStatsVersusContext_None = 0,
	PlayerStatsVersusContext_Hunter1v1,
	PlayerStatsVersusContext_Smoker1v1,
	PlayerStatsVersusContext_Boomer1v1,
	PlayerStatsVersusContext_Spitter1v1,
	PlayerStatsVersusContext_Jockey1v1,
	PlayerStatsVersusContext_Charger1v1,
	PlayerStatsVersusContext_MixedPool1v1,
	PlayerStatsVersusContext_MixedPool2v2,
	PlayerStatsVersusContext_MixedPool3v3,
	PlayerStatsVersusContext_Versus4v4,
	PlayerStatsVersusContext_CustomTeamVersus
}

enum PlayerStatsHistoryScopeType
{
	PlayerStatsHistoryScope_None = 0,
	PlayerStatsHistoryScope_CurrentMap,
	PlayerStatsHistoryScope_CampaignRun,
	PlayerStatsHistoryScope_CompetitiveSeries,
	PlayerStatsHistoryScope_ScavengeMatch,
	PlayerStatsHistoryScope_SurvivalRuns
}

enum PlayerStatsRoundStartSignalType
{
	PlayerStatsRoundStartSignal_None = 0,
	PlayerStatsRoundStartSignal_GenericRoundStart,
	PlayerStatsRoundStartSignal_ScavengeRoundStart
}

enum PlayerStatsRoundEndSignalType
{
	PlayerStatsRoundEndSignal_None = 0,
	PlayerStatsRoundEndSignal_GenericRoundEnd,
	PlayerStatsRoundEndSignal_ScavengeRoundFinished
}

enum PlayerStatsRoundLiveSignalType
{
	PlayerStatsRoundLiveSignal_None = 0,
	PlayerStatsRoundLiveSignal_Immediate,
	PlayerStatsRoundLiveSignal_SafeArea,
	PlayerStatsRoundLiveSignal_ReadyUpOrSafeArea
}

enum PlayerStatsRestartPolicyType
{
	PlayerStatsRestartPolicy_None = 0,
	PlayerStatsRestartPolicy_CoopFailureOrTransition,
	PlayerStatsRestartPolicy_CompetitiveVoteOrAdmin,
	PlayerStatsRestartPolicy_ScavengeVoteOrAdmin,
	PlayerStatsRestartPolicy_SurvivalRunReset
}

enum PlayerStatsRoundEndReasonType
{
	PlayerStatsRoundEndReason_None = 0,
	PlayerStatsRoundEndReason_GenericRoundEnd,
	PlayerStatsRoundEndReason_VersusModeRoundEnd,
	PlayerStatsRoundEndReason_ScavengeRoundFinished,
	PlayerStatsRoundEndReason_ScavengeMatchFinished,
	PlayerStatsRoundEndReason_MapTransition,
	PlayerStatsRoundEndReason_FinaleWin,
	PlayerStatsRoundEndReason_MapEnd,
	PlayerStatsRoundEndReason_PluginEnd
}

enum PlayerStatsRestartSourceType
{
	PlayerStatsRestartSource_None = 0,
	PlayerStatsRestartSource_VotePassed,
	PlayerStatsRestartSource_DirectScenarioRestart
}

enum PlayerStatsDebugCategory
{
	PlayerStatsDebug_None		= 0,
	PlayerStatsDebug_Core		= 1 << 0,
	PlayerStatsDebug_Event		= 1 << 1,
	PlayerStatsDebug_Detect		= 1 << 2,
	PlayerStatsDebug_Api		= 1 << 3,
	PlayerStatsDebug_Announce	= 1 << 4
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

enum struct PlayerStatsModeContextData
{
	int baseMode;
	bool isVersusMode;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerStatsVersusContextType versusContext;
	bool hasReadyUp;

	void Reset()
	{
		this.baseMode = GAMEMODE_UNKNOWN;
		this.isVersusMode = false;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = PlayerStatsSiPool_None;
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerStatsVersusContext_None;
		this.hasReadyUp = false;
	}
}

enum struct PlayerStatsLifecyclePolicyData
{
	int baseMode;
	PlayerStatsHistoryScopeType historyScope;
	PlayerStatsRoundStartSignalType roundStartSignal;
	PlayerStatsRoundEndSignalType roundEndSignal;
	PlayerStatsRoundLiveSignalType roundLiveSignal;
	PlayerStatsRestartPolicyType restartPolicy;

	void Reset()
	{
		this.baseMode = GAMEMODE_UNKNOWN;
		this.historyScope = PlayerStatsHistoryScope_None;
		this.roundStartSignal = PlayerStatsRoundStartSignal_None;
		this.roundEndSignal = PlayerStatsRoundEndSignal_None;
		this.roundLiveSignal = PlayerStatsRoundLiveSignal_None;
		this.restartPolicy = PlayerStatsRestartPolicy_None;
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
	int zombiesIgnited;
	int playersBiled;
	int tanksBiled;

	void Reset()
	{
		this.pillsUsed = 0;
		this.adrenalineUsed = 0;
		this.medkitsUsed = 0;
		this.defibsUsed = 0;
		this.molotovsThrown = 0;
		this.pipebombsThrown = 0;
		this.vomitjarsThrown = 0;
		this.zombiesIgnited = 0;
		this.playersBiled = 0;
		this.tanksBiled = 0;
	}
}

enum struct PlayerStatsScavengeData
{
	int gascansPoured;
	int gascansDropped;
	int gascansDestroyed;

	void Reset()
	{
		this.gascansPoured = 0;
		this.gascansDropped = 0;
		this.gascansDestroyed = 0;
	}
}

enum struct PlayerStatsAccuracyData
{
	int shotgunShots;
	int shotgunHits;
	int shotgunHeadshots;
	int smgRifleShots;
	int smgRifleHits;
	int smgRifleHeadshots;
	int sniperShots;
	int sniperHits;
	int sniperHeadshots;
	int pistolShots;
	int pistolHits;
	int pistolHeadshots;

	void Reset()
	{
		this.shotgunShots = 0;
		this.shotgunHits = 0;
		this.shotgunHeadshots = 0;
		this.smgRifleShots = 0;
		this.smgRifleHits = 0;
		this.smgRifleHeadshots = 0;
		this.sniperShots = 0;
		this.sniperHits = 0;
		this.sniperHeadshots = 0;
		this.pistolShots = 0;
		this.pistolHits = 0;
		this.pistolHeadshots = 0;
	}
}

enum struct PlayerStatsAccuracyDetailData
{
	int shots[PlayerStatsWeaponDetail_Count];
	int hits[PlayerStatsWeaponDetail_Count];
	int headshots[PlayerStatsWeaponDetail_Count];

	void Reset()
	{
		for (int i = 0; i < view_as<int>(PlayerStatsWeaponDetail_Count); i++)
		{
			this.shots[i] = 0;
			this.hits[i] = 0;
			this.headshots[i] = 0;
		}
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
	PlayerStatsScavengeData scavenge;
	PlayerStatsAccuracyData accuracy;
	PlayerStatsAccuracyDetailData accuracyDetails;

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
		this.scavenge.Reset();
		this.accuracy.Reset();
		this.accuracyDetails.Reset();
	}
}

enum struct PlayerStatsRoundMetaData
{
	int id;
	bool active;
	float startedAt;
	float endedAt;
	int baseMode;
	bool isVersusMode;
	int scavengeRoundNumber;
	bool scavengeInSecondHalf;
	int scavengeItemsGoal;
	bool scavengeWentOvertime;
	bool scavengeScoreTied;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerStatsVersusContextType versusContext;
	PlayerStatsHistoryScopeType historyScope;
	PlayerStatsRoundStartSignalType roundStartSignal;
	PlayerStatsRoundEndSignalType roundEndSignal;
	PlayerStatsRoundLiveSignalType roundLiveSignal;
	PlayerStatsRestartPolicyType restartPolicy;
	PlayerStatsRoundEndReasonType endReason;
	int storedTankPercent;
	int storedWitchPercent;

	void Reset()
	{
		this.id = 0;
		this.active = false;
		this.startedAt = 0.0;
		this.endedAt = 0.0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.isVersusMode = false;
		this.scavengeRoundNumber = 0;
		this.scavengeInSecondHalf = false;
		this.scavengeItemsGoal = 0;
		this.scavengeWentOvertime = false;
		this.scavengeScoreTied = false;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = PlayerStatsSiPool_None;
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerStatsVersusContext_None;
		this.historyScope = PlayerStatsHistoryScope_None;
		this.roundStartSignal = PlayerStatsRoundStartSignal_None;
		this.roundEndSignal = PlayerStatsRoundEndSignal_None;
		this.roundLiveSignal = PlayerStatsRoundLiveSignal_None;
		this.restartPolicy = PlayerStatsRestartPolicy_None;
		this.endReason = PlayerStatsRoundEndReason_None;
		this.storedTankPercent = -1;
		this.storedWitchPercent = -1;
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
	int survivorTotalZombiesIgnited;
	int survivorTotalPlayersBiled;
	int survivorTotalTanksBiled;
	int survivorTotalGascansPoured;
	int survivorTotalGascansDropped;
	int survivorTotalGascansDestroyed;

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
		this.survivorTotalZombiesIgnited = 0;
		this.survivorTotalPlayersBiled = 0;
		this.survivorTotalTanksBiled = 0;
		this.survivorTotalGascansPoured = 0;
		this.survivorTotalGascansDropped = 0;
		this.survivorTotalGascansDestroyed = 0;
	}
}

enum struct PlayerStatsRoundData
{
	PlayerStatsRoundMetaData meta;
	PlayerStatsRoundTotalsData totals;
	PlayerStatsPlayerRoundData players[L4D2_PLAYER_STATS_MAX_SLOTS];
	int tankVictimUserIds[L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES];
	int tankVictimCount;
	int witchEntityIds[L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES];
	int witchEntityCount;

	/**
	 * @brief Resets the current round snapshot and all tracked players.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.meta.Reset();
		this.totals.Reset();
		this.tankVictimCount = 0;
		this.witchEntityCount = 0;

		for (int boss = 0; boss < L4D2_PLAYER_STATS_MAX_TRACKED_BOSSES; boss++)
		{
			this.tankVictimUserIds[boss] = 0;
			this.witchEntityIds[boss] = 0;
		}

		for (int client = 0; client < L4D2_PLAYER_STATS_MAX_SLOTS; client++)
		{
			this.players[client].Reset();
		}
	}
}

enum struct PlayerStatsRuntimeState
{
	bool roundLive;
	bool hasLeft4DHooks;
	bool hasReadyUp;
	bool hasConfogl;
	bool hasPlayerSkills;
	bool hasBossPercents;
	bool lateload;
	int baseMode;
	int configuredSurvivorLimit;
	int configuredPlayerZombieLimit;
	int siPoolMask;
	int enabledSiClassCount;
	int versusTeamSize;
	PlayerStatsVersusContextType versusContext;
	PlayerStatsHistoryScopeType historyScope;
	PlayerStatsRoundStartSignalType roundStartSignal;
	PlayerStatsRoundEndSignalType roundEndSignal;
	PlayerStatsRoundLiveSignalType roundLiveSignal;
	PlayerStatsRestartPolicyType restartPolicy;
	int playerSlotByClient[L4D2_PLAYER_STATS_MAX_PLAYERS];
	PlayerStatsWeaponFamily lastWeaponFamilyByClient[L4D2_PLAYER_STATS_MAX_PLAYERS];
	PlayerStatsWeaponDetailType lastWeaponDetailByClient[L4D2_PLAYER_STATS_MAX_PLAYERS];

	/**
	 * @brief Resets runtime flags and client-to-slot mappings.
	 *
	 * @noreturn
	 */
	void Reset()
	{
		this.roundLive = false;
		this.hasLeft4DHooks = false;
		this.hasReadyUp = false;
		this.hasConfogl = false;
		this.hasPlayerSkills = false;
		this.hasBossPercents = false;
		this.lateload = false;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.configuredSurvivorLimit = 0;
		this.configuredPlayerZombieLimit = 0;
		this.siPoolMask = PlayerStatsSiPool_None;
		this.enabledSiClassCount = 0;
		this.versusTeamSize = 0;
		this.versusContext = PlayerStatsVersusContext_None;
		this.historyScope = PlayerStatsHistoryScope_None;
		this.roundStartSignal = PlayerStatsRoundStartSignal_None;
		this.roundEndSignal = PlayerStatsRoundEndSignal_None;
		this.roundLiveSignal = PlayerStatsRoundLiveSignal_None;
		this.restartPolicy = PlayerStatsRestartPolicy_None;

		for (int client = 0; client < L4D2_PLAYER_STATS_MAX_PLAYERS; client++)
		{
			this.playerSlotByClient[client] = -1;
			this.lastWeaponFamilyByClient[client] = PlayerStatsWeaponFamily_None;
			this.lastWeaponDetailByClient[client] = PlayerStatsWeaponDetail_None;
		}
	}
}

enum struct PlayerStatsGameRoundEntry
{
	bool active;
	int roundId;
	int baseMode;
	PlayerStatsHistoryScopeType historyScope;
	char map[64];
	int durationSeconds;
	int siKills;
	int commonKills;
	int deaths;
	int incaps;
	int kitsUsed;
	int pillsUsed;
	int restarts;
	PlayerStatsRestartSourceType restartSource;
	PlayerStatsRoundEndReasonType endReason;

	void Reset()
	{
		this.active = false;
		this.roundId = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.historyScope = PlayerStatsHistoryScope_None;
		this.map[0] = '\0';
		this.durationSeconds = 0;
		this.siKills = 0;
		this.commonKills = 0;
		this.deaths = 0;
		this.incaps = 0;
		this.kitsUsed = 0;
		this.pillsUsed = 0;
		this.restarts = 0;
		this.restartSource = PlayerStatsRestartSource_None;
		this.endReason = PlayerStatsRoundEndReason_None;
	}
}

enum struct PlayerStatsHistoricalPlayerData
{
	bool active;
	char name[MAX_NAME_LENGTH];
	PlayerStatsCombatData combat;
	PlayerStatsResourceData resources;
	PlayerStatsScavengeData scavenge;
	PlayerStatsSupportData support;
	PlayerStatsAccuracyData accuracy;
	PlayerStatsAccuracyDetailData accuracyDetails;

	void Reset()
	{
		this.active = false;
		this.name[0] = '\0';
		this.combat.Reset();
		this.resources.Reset();
		this.scavenge.Reset();
		this.support.Reset();
		this.accuracy.Reset();
		this.accuracyDetails.Reset();
	}
}

enum struct PlayerStatsHistoricalRoundData
{
	bool active;
	int roundId;
	int baseMode;
	bool isVersusMode;
	int scavengeRoundNumber;
	bool scavengeInSecondHalf;
	int scavengeItemsGoal;
	bool scavengeWentOvertime;
	bool scavengeScoreTied;
	int siPoolMask;
	int durationSeconds;
	int storedTankPercent;
	int storedWitchPercent;
	int tankCount;
	int witchCount;
	PlayerStatsRoundEndReasonType endReason;
	PlayerStatsHistoryScopeType historyScope;
	PlayerStatsRoundTotalsData totals;
	PlayerStatsHistoricalPlayerData players[L4D2_PLAYER_STATS_MAX_SURVIVORS];

	void Reset()
	{
		this.active = false;
		this.roundId = 0;
		this.baseMode = GAMEMODE_UNKNOWN;
		this.isVersusMode = false;
		this.scavengeRoundNumber = 0;
		this.scavengeInSecondHalf = false;
		this.scavengeItemsGoal = 0;
		this.scavengeWentOvertime = false;
		this.scavengeScoreTied = false;
		this.siPoolMask = PlayerStatsSiPool_None;
		this.durationSeconds = 0;
		this.storedTankPercent = -1;
		this.storedWitchPercent = -1;
		this.tankCount = 0;
		this.witchCount = 0;
		this.endReason = PlayerStatsRoundEndReason_None;
		this.historyScope = PlayerStatsHistoryScope_None;
		this.totals.Reset();

		for (int i = 0; i < L4D2_PLAYER_STATS_MAX_SURVIVORS; i++)
		{
			this.players[i].Reset();
		}
	}
}

enum struct PlayerStatsGameHistoryData
{
	bool active;
	int seriesId;
	int roundCount;
	int lastCampaignScoreA;
	int lastCampaignScoreB;
	bool pendingScavengeMatchReset;
	int restartCount;
	PlayerStatsRestartSourceType restartSource;
	PlayerStatsGameRoundEntry rounds[L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS];

	void Reset()
	{
		this.active = false;
		this.seriesId = 0;
		this.roundCount = 0;
		this.lastCampaignScoreA = 0;
		this.lastCampaignScoreB = 0;
		this.pendingScavengeMatchReset = false;
		this.restartCount = 0;
		this.restartSource = PlayerStatsRestartSource_None;

		for (int i = 0; i < L4D2_PLAYER_STATS_MAX_HISTORY_ROUNDS; i++)
		{
			this.rounds[i].Reset();
		}
	}
}
