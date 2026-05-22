#if defined _survivor_mvp_included
	#endinput
#endif
#define _survivor_mvp_included

native int SURVMVP_GetMVP();
native int SURVMVP_GetMVPSlot();
native int SURVMVP_GetMVPDmgCount(int client);
native float SURVMVP_GetMVPDmgPercent(int client);
native int SURVMVP_GetMVPKills(int client);
native int SURVMVP_GetMVPCI();
native int SURVMVP_GetMVPCISlot();
native int SURVMVP_GetMVPCIKills(int client);
native float SURVMVP_GetMVPCIPercent(int client);

public SharedPlugin __pl_survivor_mvp =
{
	name = "survivor_mvp",
	file = "survivor_mvp.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_survivor_mvp_SetNTVOptional()
{
	MarkNativeAsOptional("SURVMVP_GetMVP");
	MarkNativeAsOptional("SURVMVP_GetMVPSlot");
	MarkNativeAsOptional("SURVMVP_GetMVPDmgCount");
	MarkNativeAsOptional("SURVMVP_GetMVPDmgPercent");
	MarkNativeAsOptional("SURVMVP_GetMVPKills");
	MarkNativeAsOptional("SURVMVP_GetMVPCI");
	MarkNativeAsOptional("SURVMVP_GetMVPCISlot");
	MarkNativeAsOptional("SURVMVP_GetMVPCIKills");
	MarkNativeAsOptional("SURVMVP_GetMVPCIPercent");
}
#endif
