#if defined _l4d2_player_stats_observations_included
	#endinput
#endif
#define _l4d2_player_stats_observations_included

enum struct StatsPlayerDeathObservation
{
	int victimUserid;
	int attackerUserid;
	char weapon[64];
}

enum struct StatsInfectedDeathObservation
{
	int attackerUserid;
	int infectedType;
	char eventName[32];
}

enum struct StatsIncapacitationObservation
{
	int victim;
	int attacker;
}

enum struct StatsPlayerIncapacitatedStartObservation
{
	int victimUserid;
	int attackerUserid;
	char weapon[64];
}

enum PlayerStatsScavengeObjectiveType
{
	PlayerStatsScavengeObjective_Poured = 0,
	PlayerStatsScavengeObjective_Dropped,
	PlayerStatsScavengeObjective_Destroyed
}

enum PlayerStatsScavengeApplyResult
{
	PlayerStatsScavengeApply_Applied = 0,
	PlayerStatsScavengeApply_InvalidPayload,
	PlayerStatsScavengeApply_RoundNotLive,
	PlayerStatsScavengeApply_TrackingDisabled,
	PlayerStatsScavengeApply_WrongMode,
	PlayerStatsScavengeApply_InvalidActor,
	PlayerStatsScavengeApply_NoSlot
}

enum struct StatsObjectiveRecord
{
	PlayerStatsScavengeObjectiveType type;
	int userid;
	int client;
	bool validPayload;
}

enum PlayerStatsSurvivorActionType
{
	PlayerStatsSurvivorAction_PillsUsed = 0,
	PlayerStatsSurvivorAction_AdrenalineUsed,
	PlayerStatsSurvivorAction_HealSuccess,
	PlayerStatsSurvivorAction_DefibrillatorUsed,
	PlayerStatsSurvivorAction_ReviveSuccess,
	PlayerStatsSurvivorAction_Rescued
}

enum PlayerStatsSurvivorRejectReason
{
	PlayerStatsSurvivorReject_None = 0,
	PlayerStatsSurvivorReject_NotEvaluated,
	PlayerStatsSurvivorReject_InvalidObservation,
	PlayerStatsSurvivorReject_RoundNotLive,
	PlayerStatsSurvivorReject_TrackingDisabled,
	PlayerStatsSurvivorReject_InvalidActorPayload,
	PlayerStatsSurvivorReject_InvalidActor,
	PlayerStatsSurvivorReject_InvalidRecipientPayload,
	PlayerStatsSurvivorReject_InvalidRecipient,
	PlayerStatsSurvivorReject_ActorNoSlot,
	PlayerStatsSurvivorReject_RecipientNoSlot
}

enum PlayerStatsSurvivorApplyStatus
{
	PlayerStatsSurvivorApply_Rejected = 0,
	PlayerStatsSurvivorApply_Partial,
	PlayerStatsSurvivorApply_Applied
}

enum struct StatsSurvivorActionRecord
{
	PlayerStatsSurvivorActionType type;
	int actorUserid;
	int actorClient;
	bool actorPayloadValid;
	int recipientUserid;
	int recipientClient;
	bool hasRecipient;
	bool recipientPayloadValid;
}

enum struct StatsSurvivorActionResult
{
	bool actorApplied;
	bool recipientApplied;
	PlayerStatsSurvivorRejectReason gateReason;
	PlayerStatsSurvivorRejectReason actorReason;
	PlayerStatsSurvivorRejectReason recipientReason;

	void Reset()
	{
		this.actorApplied = false;
		this.recipientApplied = false;
		this.gateReason = PlayerStatsSurvivorReject_None;
		this.actorReason = PlayerStatsSurvivorReject_NotEvaluated;
		this.recipientReason = PlayerStatsSurvivorReject_NotEvaluated;
	}
}

enum PlayerStatsUtilityActionType
{
	PlayerStatsUtilityAction_PlayerNowIt = 0,
	PlayerStatsUtilityAction_VomitBombTank,
	PlayerStatsUtilityAction_ZombieIgnited
}

enum PlayerStatsUtilityApplyResult
{
	PlayerStatsUtilityApply_Applied = 0,
	PlayerStatsUtilityApply_RoundNotLive,
	PlayerStatsUtilityApply_ThrowablesDisabled,
	PlayerStatsUtilityApply_BoomerAttributed,
	PlayerStatsUtilityApply_FireAmmo,
	PlayerStatsUtilityApply_InvalidPayload,
	PlayerStatsUtilityApply_InvalidActor,
	PlayerStatsUtilityApply_NoSlot,
	PlayerStatsUtilityApply_NoMolotovRecorded,
	PlayerStatsUtilityApply_InvalidObservation
}

enum struct StatsUtilityRecord
{
	PlayerStatsUtilityActionType type;
	int userid;
	int client;
	bool validPayload;
	bool byBoomer;
	bool fireAmmo;
}

enum PlayerStatsShotRouteResult
{
	PlayerStatsShotRoute_ReadyForUtility = 0,
	PlayerStatsShotRoute_RoundNotLive,
	PlayerStatsShotRoute_FeaturesDisabled,
	PlayerStatsShotRoute_InvalidPayload,
	PlayerStatsShotRoute_InvalidActor,
	PlayerStatsShotRoute_EmptyWeapon,
	PlayerStatsShotRoute_NoSlot
}

enum PlayerStatsUtilityThrowResult
{
	PlayerStatsUtilityThrow_NotEvaluated = 0,
	PlayerStatsUtilityThrow_Disabled,
	PlayerStatsUtilityThrow_InvalidSlot,
	PlayerStatsUtilityThrow_NotThrowable,
	PlayerStatsUtilityThrow_MolotovApplied,
	PlayerStatsUtilityThrow_PipeBombApplied,
	PlayerStatsUtilityThrow_VomitjarApplied
}

enum struct StatsShotRecord
{
	int userid;
	int client;
	bool validPayload;
	char weapon[64];
}

enum struct StatsWeaponFireResult
{
	PlayerStatsShotRouteResult route;
	PlayerStatsUtilityThrowResult throwable;
}

enum PlayerStatsControlType
{
	PlayerStatsControl_TongueGrab = 0,
	PlayerStatsControl_HunterPounce,
	PlayerStatsControl_JockeyRide,
	PlayerStatsControl_BoomerVomit
}

enum PlayerStatsControlApplyResult
{
	PlayerStatsControlApply_Applied = 0,
	PlayerStatsControlApply_BoomerExplosion,
	PlayerStatsControlApply_TrackingDisabled,
	PlayerStatsControlApply_RoundNotLive,
	PlayerStatsControlApply_InvalidVictim,
	PlayerStatsControlApply_InvalidAttacker,
	PlayerStatsControlApply_NoSlot,
	PlayerStatsControlApply_InvalidObservation
}

enum struct StatsControlRecord
{
	PlayerStatsControlType type;
	int victim;
	int attacker;
	bool boomerExplosion;
}
