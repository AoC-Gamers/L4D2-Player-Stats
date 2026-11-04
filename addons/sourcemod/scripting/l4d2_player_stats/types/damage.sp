#if defined _l4d2_player_stats_damage_types_included
	#endinput
#endif
#define _l4d2_player_stats_damage_types_included

enum PlayerStatsDamageQuantityBasis
{
	PlayerStatsDamageBasis_InfectedHurtAmount = 0,
	PlayerStatsDamageBasis_PlayerHurtDmgHealth
}

enum PlayerStatsWitchHurtResolveResult
{
	PlayerStatsWitchHurt_Ready = 0,
	PlayerStatsWitchHurt_InvalidPayload,
	PlayerStatsWitchHurt_RoundNotLive,
	PlayerStatsWitchHurt_FeaturesDisabled,
	PlayerStatsWitchHurt_NotWitch,
	PlayerStatsWitchHurt_InvalidDamage,
	PlayerStatsWitchHurt_InvalidAttacker,
	PlayerStatsWitchHurt_NoSlot
}

enum PlayerStatsAccuracyApplyResult
{
	PlayerStatsAccuracy_NotEvaluated = 0,
	PlayerStatsAccuracy_Applied,
	PlayerStatsAccuracy_Disabled,
	PlayerStatsAccuracy_InvalidSlot
}

enum PlayerStatsWitchCombatResult
{
	PlayerStatsWitchCombat_NotEvaluated = 0,
	PlayerStatsWitchCombat_Applied,
	PlayerStatsWitchCombat_TrackingDisabled,
	PlayerStatsWitchCombat_InvalidRecord
}

enum PlayerStatsDamageRouteResult
{
	PlayerStatsDamageRoute_Applied = 0,
	PlayerStatsDamageRoute_AccuracyOnly,
	PlayerStatsDamageRoute_FeaturesDisabled,
	PlayerStatsDamageRoute_TrackingDisabled,
	PlayerStatsDamageRoute_NoSlot,
	PlayerStatsDamageRoute_InvalidRecord
}

enum PlayerStatsInfectedDamageApplyResult
{
	PlayerStatsInfectedDamage_Applied = 0,
	PlayerStatsInfectedDamage_UnmappedClass,
	PlayerStatsInfectedDamage_InvalidRecord
}

enum struct StatsInfectedHurtObservation
{
	int entity;
	int attackerUserid;
	int attackerClient;
	int amount;
	int hitgroup;
	bool validPayload;
	char weapon[64];
}

enum struct StatsPlayerHurtObservation
{
	PlayerStatsDamageQuantityBasis quantityBasis;
	int victimUserid;
	int victimClient;
	int attackerUserid;
	int attackerClient;
	int damage;
	int hitgroup;
	char weapon[64];
}

enum struct StatsSdkDamageObservation
{
	StatsTraceContext context;
	int victimClient;
	int attackerClient;
	int inflictor;
	float damage;
	int damageType;
}

enum struct StatsInfectedDamageRecord
{
	PlayerStatsDamageQuantityBasis quantityBasis;
	L4D2ZombieClassType attackerClass;
	int roundSlot;
	int damage;
}

enum struct StatsWitchDamageRecord
{
	PlayerStatsDamageQuantityBasis quantityBasis;
	int entity;
	int attackerUserid;
	int attackerClient;
	int amount;
	int roundSlot;
	bool headshot;
	PlayerStatsWeaponFamily family;
	PlayerStatsWeaponDetailType detail;
}

enum struct StatsWitchHurtResult
{
	PlayerStatsWitchHurtResolveResult resolution;
	PlayerStatsAccuracyApplyResult accuracy;
	PlayerStatsWitchCombatResult combat;
}
