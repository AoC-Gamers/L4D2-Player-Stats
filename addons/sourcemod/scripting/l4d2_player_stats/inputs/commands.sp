#if defined _l4d2_player_stats_inputs_commands_included
	#endinput
#endif
#define _l4d2_player_stats_inputs_commands_included

Action Input_CommandMVP(int client)
{
	bool fromChat = Announce_WasCommandInvokedFromChat(client);

	if (fromChat && !Announce_BroadcastRoundSummary(client))
	{
		return Plugin_Handled;
	}

	if (client > 0 && IsValidClient(client))
	{
		Announce_RenderRoundConsolePanel(client);
	}

	return Plugin_Handled;
}

Action Input_CommandRank(int client)
{
	if (!IsValidSurvivor(client))
	{
		return Plugin_Handled;
	}

	if (Announce_WasCommandInvokedFromChat(client))
	{
		Announce_PrintClientRanks(client);
	}

	Announce_RenderGlobalRankPanel(client);
	return Plugin_Handled;
}

Action Input_CommandAcc(int client)
{
	if (Announce_RenderAccuracyPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandUtils(int client)
{
	if (Announce_RenderUtilitiesPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandItems(int client)
{
	if (Announce_RenderConsumablesPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandSupport(int client)
{
	if (Announce_RenderSupportPanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandScavenge(int client)
{
	if (Announce_RenderScavengePanel(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandHelp(int client)
{
	Announce_PrintHelpToConsole(client);
	Announce_NotifyConsoleDelivery(client);
	return Plugin_Handled;
}

Action Input_CommandInfect(int client)
{
	if (Announce_RenderInfectedPanels(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}

Action Input_CommandTank(int client)
{
	if (Announce_RenderTankPanels(client))
	{
		Announce_NotifyConsoleDelivery(client);
	}
	return Plugin_Handled;
}
