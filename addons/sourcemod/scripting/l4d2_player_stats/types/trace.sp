#if defined _l4d2_player_stats_trace_types_included
	#endinput
#endif
#define _l4d2_player_stats_trace_types_included

enum struct StatsTraceContext
{
	int runId;
	int mapGeneration;
	int roundId;
	int signalId;
	int damageId;
}

enum struct StatsTraceState
{
	int runId;
	int mapGeneration;
	int signalSerial;
}
