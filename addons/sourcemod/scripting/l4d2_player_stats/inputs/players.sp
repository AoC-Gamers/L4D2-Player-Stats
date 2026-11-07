#if defined _l4d2_player_stats_inputs_players_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_players_included

void Input_PlayerBotReplace(Event event, StatsTraceContext traceContext)
{
	int playerUserid = event.GetInt("player");
	int botUserid = event.GetInt("bot");
	int player = GetClientOfUserId(playerUserid);
	int bot = GetClientOfUserId(botUserid);
	int playerSlotBefore = Stats_GetPlayerRoundIndex(player);
	int botSlotBefore = Stats_GetPlayerRoundIndex(bot);
	int roundBefore = g_Round.meta.id;
	Substitutions_OnPlayerBotReplace(player, bot);
	int playerSlotAfter = Stats_GetPlayerRoundIndex(player);
	int botSlotAfter = Stats_GetPlayerRoundIndex(bot);
	Trace_SubstitutionBoundary(traceContext, "player_bot_replace", roundBefore, g_Round.meta.id,
		player, playerUserid, bot, botUserid, playerSlotBefore, botSlotBefore, playerSlotAfter, botSlotAfter);
}

void Input_BotPlayerReplace(Event event, StatsTraceContext traceContext)
{
	int botUserid = event.GetInt("bot");
	int playerUserid = event.GetInt("player");
	int bot = GetClientOfUserId(botUserid);
	int player = GetClientOfUserId(playerUserid);
	int botSlotBefore = Stats_GetPlayerRoundIndex(bot);
	int playerSlotBefore = Stats_GetPlayerRoundIndex(player);
	int roundBefore = g_Round.meta.id;
	Substitutions_OnBotPlayerReplace(bot, player);
	int botSlotAfter = Stats_GetPlayerRoundIndex(bot);
	int playerSlotAfter = Stats_GetPlayerRoundIndex(player);
	Trace_SubstitutionBoundary(traceContext, "bot_player_replace", roundBefore, g_Round.meta.id,
		bot, botUserid, player, playerUserid, botSlotBefore, playerSlotBefore, botSlotAfter, playerSlotAfter);
}

void Input_OnClientPutInServer(int client, StatsTraceContext traceContext)
{
	int userid = GetClientUserId(client);
	int teamBefore = GetClientTeam(client);
	int slotBefore = Stats_GetPlayerRoundIndex(client);
	Stats_Debug(PlayerStatsDebug_Event, "[OnClientPutInServer] client=%d bot=%d", client, IsFakeClient(client));
	Stats_OnClientPutInServer(client);
	SDKHook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
	int teamAfter = GetClientTeam(client);
	int slotAfter = Stats_GetPlayerRoundIndex(client);
	Trace_ClientBindingResult(traceContext, "client_put_in_server", client, userid, teamBefore, teamAfter, slotBefore, slotAfter);
}

void Input_OnClientDisconnect(int client, StatsTraceContext traceContext)
{
	int userid = GetClientUserId(client);
	// Disconnect also runs for clients that never entered the game.
	int teamBefore = IsClientInGame(client) ? GetClientTeam(client) : 0;
	int slotBefore = Stats_GetPlayerRoundIndex(client);
	Stats_Debug(PlayerStatsDebug_Event, "[OnClientDisconnect] client=%d bot=%d", client, IsFakeClient(client));
	Detect_OnClientDisconnect(client);
	SDKUnhook(client, SDKHook_OnTakeDamage, SDK_OnTakeDamage);
	Stats_OnClientDisconnect(client);
	int teamAfter = IsClientInGame(client) ? GetClientTeam(client) : 0;
	int slotAfter = Stats_GetPlayerRoundIndex(client);
	Trace_ClientBindingResult(traceContext, "client_disconnect", client, userid, teamBefore, teamAfter, slotBefore, slotAfter);
}
