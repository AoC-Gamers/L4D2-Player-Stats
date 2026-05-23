#if defined _l4d2_player_stats_rounds_included
	#endinput
#endif
#define _l4d2_player_stats_rounds_included

int g_iRoundSerial = 0;

void Round_Init()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_bot_replace", Event_PlayerBotReplace, EventHookMode_PostNoCopy);
	HookEvent("bot_player_replace", Event_BotPlayerReplace, EventHookMode_PostNoCopy);
}

void Round_ResetAll()
{
	g_Round.Reset();
	g_Runtime.roundLive = false;
	Stats_ResetRuntimeMappings();
}

void Round_EventRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsEnabled())
	{
		return;
	}

	g_Round.Reset();
	g_Round.meta.id = ++g_iRoundSerial;
	g_Round.meta.active = true;
	g_Round.meta.startedAt = GetGameTime();
	g_Runtime.roundLive = false;

	Stats_Debug(PlayerStatsDebug_Core, "Round started. round=%d", g_Round.meta.id);
}

void Round_EventRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	Stats_ConsumeEventContext(event, name, dontBroadcast);

	if (!Stats_IsEnabled() || !g_Round.meta.active)
	{
		return;
	}

	g_Round.meta.active = false;
	g_Round.meta.endedAt = GetGameTime();
	g_Runtime.roundLive = false;

	Stats_Debug(PlayerStatsDebug_Core, "Round ended. round=%d si=%d ci=%d ff=%d",
		g_Round.meta.id,
		g_Round.totals.survivorTotalSiDamage,
		g_Round.totals.survivorTotalCommonKills,
		g_Round.totals.survivorTotalFF);

	Announce_RenderRoundConsolePanel(0);
	API_FireRoundFinalized(g_Round.meta.id);
}

void Round_MarkLive(const char[] reason, int client = 0)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_Runtime.roundLive)
	{
		return;
	}

	g_Runtime.roundLive = true;

	if (client > 0)
	{
		Stats_Debug(PlayerStatsDebug_Core, "Round is live. round=%d reason=%s client=%d", g_Round.meta.id, reason, client);
		return;
	}

	Stats_Debug(PlayerStatsDebug_Core, "Round is live. round=%d reason=%s", g_Round.meta.id, reason);
}

void Round_OnReadyUpLive()
{
	Round_MarkLive("readyup_live");
}

void Round_OnFirstSurvivorLeftSafeArea(int client)
{
	if (!Stats_IsEnabled() || !g_Round.meta.active || g_Runtime.readyUpAvailable)
	{
		return;
	}

	Round_MarkLive("left_safe_area", client);
}
