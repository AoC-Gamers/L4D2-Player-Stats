#if defined _l4d2_player_stats_inputs_sdkhooks_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_sdkhooks_included

void Input_SdkOnTakeDamage(int victim, int attacker, int inflictor, float damage, int damagetype, StatsTraceContext traceContext)
{
	StatsSdkDamageObservation observation;
	observation.context = traceContext;
	observation.victimClient = victim;
	observation.attackerClient = attacker;
	observation.inflictor = inflictor;
	observation.damage = damage;
	observation.damageType = damagetype;
	StatsSdkDamageCaptureResult captureResult;
	captureResult = Damage_CaptureLegacyTankTerminal(observation);
	Trace_SdkDamageCaptureResult(traceContext, captureResult, damage);
}
