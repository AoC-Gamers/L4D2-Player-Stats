#if defined _l4d2_player_stats_modules_survivor_included
	#endinput
#endif
#define _l4d2_player_stats_modules_survivor_included

void Survivor_ApplyDeath(int index, int attacker)
{
	g_Round.players[index].survivability.deaths++;
	g_Round.totals.survivorTotalDeaths++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].survivability.deathBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].survivability.deathByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].survivability.deathByInfectedAI++;
		}
	}
}

void Survivor_ApplyIncap(int index, int attacker)
{
	g_Round.players[index].survivability.incaps++;
	g_Round.totals.survivorTotalIncaps++;

	switch (Stats_GetAttributionType(attacker))
	{
		case PlayerStatsAttribution_Survivor:
		{
			g_Round.players[index].survivability.incapBySurvivor++;
		}
		case PlayerStatsAttribution_InfectedPlayer:
		{
			g_Round.players[index].survivability.incapByInfectedPlayer++;
		}
		case PlayerStatsAttribution_InfectedAI:
		{
			g_Round.players[index].survivability.incapByInfectedAI++;
		}
	}
}

PlayerStatsSurvivorApplyStatus Survivor_ApplyAction(const StatsSurvivorActionRecord observation, StatsSurvivorActionResult result)
{
	result.Reset();

	if (!Stats_IsRoundLive())
	{
		result.gateReason = PlayerStatsSurvivorReject_RoundNotLive;
		return PlayerStatsSurvivorApply_Rejected;
	}

	if (!Stats_IsTrackingEnabled())
	{
		result.gateReason = PlayerStatsSurvivorReject_TrackingDisabled;
		return PlayerStatsSurvivorApply_Rejected;
	}

	bool hasRecipient = Survivor_ActionHasRecipient(observation.type);
	if (hasRecipient != observation.hasRecipient)
	{
		result.gateReason = PlayerStatsSurvivorReject_InvalidObservation;
		return PlayerStatsSurvivorApply_Rejected;
	}

	if (observation.type == PlayerStatsSurvivorAction_HealSuccess)
	{
		int actorIndex;
		if (!Survivor_TryGetActorIndex(observation, actorIndex, result))
		{
			return PlayerStatsSurvivorApply_Rejected;
		}

		Survivor_ApplyCredit(observation.type, actorIndex, false);
		result.actorApplied = true;
		result.actorReason = PlayerStatsSurvivorReject_None;

		int recipientIndex;
		if (!Survivor_TryGetRecipientIndex(observation, recipientIndex, result))
		{
			return PlayerStatsSurvivorApply_Partial;
		}

		Survivor_ApplyCredit(observation.type, recipientIndex, true);
		result.recipientApplied = true;
		result.recipientReason = PlayerStatsSurvivorReject_None;
		return PlayerStatsSurvivorApply_Applied;
	}

	if (observation.type == PlayerStatsSurvivorAction_ReviveSuccess
		|| observation.type == PlayerStatsSurvivorAction_Rescued)
	{
		int actorIndex;
		if (Survivor_TryGetActorIndex(observation, actorIndex, result))
		{
			Survivor_ApplyCredit(observation.type, actorIndex, false);
			result.actorApplied = true;
			result.actorReason = PlayerStatsSurvivorReject_None;
		}

		int recipientIndex;
		if (Survivor_TryGetRecipientIndex(observation, recipientIndex, result))
		{
			Survivor_ApplyCredit(observation.type, recipientIndex, true);
			result.recipientApplied = true;
			result.recipientReason = PlayerStatsSurvivorReject_None;
		}

		return Survivor_GetApplyStatus(result, true);
	}

	if (observation.hasRecipient || !Survivor_IsActorOnlyAction(observation.type))
	{
		result.gateReason = PlayerStatsSurvivorReject_InvalidObservation;
		return PlayerStatsSurvivorApply_Rejected;
	}

	int index;
	if (!Survivor_TryGetActorIndex(observation, index, result))
	{
		return PlayerStatsSurvivorApply_Rejected;
	}

	Survivor_ApplyCredit(observation.type, index, false);
	result.actorApplied = true;
	result.actorReason = PlayerStatsSurvivorReject_None;
	return PlayerStatsSurvivorApply_Applied;
}

bool Survivor_ActionHasRecipient(PlayerStatsSurvivorActionType type)
{
	return type == PlayerStatsSurvivorAction_HealSuccess
		|| type == PlayerStatsSurvivorAction_ReviveSuccess
		|| type == PlayerStatsSurvivorAction_Rescued;
}

bool Survivor_IsActorOnlyAction(PlayerStatsSurvivorActionType type)
{
	return type == PlayerStatsSurvivorAction_PillsUsed
		|| type == PlayerStatsSurvivorAction_AdrenalineUsed
		|| type == PlayerStatsSurvivorAction_DefibrillatorUsed;
}

bool Survivor_TryGetActorIndex(const StatsSurvivorActionRecord observation, int &index, StatsSurvivorActionResult result)
{
	index = -1;
	if (!observation.actorPayloadValid)
	{
		result.actorReason = PlayerStatsSurvivorReject_InvalidActorPayload;
		return false;
	}

	if (!IsValidSurvivor(observation.actorClient))
	{
		result.actorReason = PlayerStatsSurvivorReject_InvalidActor;
		return false;
	}

	index = Stats_EnsurePlayerRoundSlot(observation.actorClient);
	if (index == -1)
	{
		result.actorReason = PlayerStatsSurvivorReject_ActorNoSlot;
		return false;
	}

	return true;
}

bool Survivor_TryGetRecipientIndex(const StatsSurvivorActionRecord observation, int &index, StatsSurvivorActionResult result)
{
	index = -1;
	if (!observation.recipientPayloadValid)
	{
		result.recipientReason = PlayerStatsSurvivorReject_InvalidRecipientPayload;
		return false;
	}

	if (!IsValidSurvivor(observation.recipientClient))
	{
		result.recipientReason = PlayerStatsSurvivorReject_InvalidRecipient;
		return false;
	}

	index = Stats_EnsurePlayerRoundSlot(observation.recipientClient);
	if (index == -1)
	{
		result.recipientReason = PlayerStatsSurvivorReject_RecipientNoSlot;
		return false;
	}

	return true;
}

PlayerStatsSurvivorApplyStatus Survivor_GetApplyStatus(const StatsSurvivorActionResult result, bool hasRecipient)
{
	if (result.actorApplied && (!hasRecipient || result.recipientApplied))
	{
		return PlayerStatsSurvivorApply_Applied;
	}

	if (result.actorApplied || result.recipientApplied)
	{
		return PlayerStatsSurvivorApply_Partial;
	}

	return PlayerStatsSurvivorApply_Rejected;
}

void Survivor_ApplyCredit(PlayerStatsSurvivorActionType type, int index, bool recipient)
{
	if (recipient)
	{
		switch (type)
		{
			case PlayerStatsSurvivorAction_HealSuccess:
			{
				g_Round.players[index].support.healsReceived++;
			}
			case PlayerStatsSurvivorAction_ReviveSuccess:
			{
				g_Round.players[index].support.revivesReceived++;
			}
			case PlayerStatsSurvivorAction_Rescued:
			{
				g_Round.players[index].support.rescuesReceived++;
			}
		}
		return;
	}

	switch (type)
	{
		case PlayerStatsSurvivorAction_PillsUsed:
		{
			g_Round.players[index].resources.pillsUsed++;
			g_Round.totals.survivorTotalPillsUsed++;
		}
		case PlayerStatsSurvivorAction_AdrenalineUsed:
		{
			g_Round.players[index].resources.adrenalineUsed++;
			g_Round.totals.survivorTotalAdrenalineUsed++;
		}
		case PlayerStatsSurvivorAction_HealSuccess:
		{
			g_Round.players[index].resources.medkitsUsed++;
			g_Round.players[index].support.healsGiven++;
			g_Round.totals.survivorTotalMedkitsUsed++;
			g_Round.totals.survivorTotalHealsGiven++;
		}
		case PlayerStatsSurvivorAction_DefibrillatorUsed:
		{
			g_Round.players[index].resources.defibsUsed++;
			g_Round.totals.survivorTotalDefibsUsed++;
		}
		case PlayerStatsSurvivorAction_ReviveSuccess:
		{
			g_Round.players[index].support.revivesGiven++;
			g_Round.totals.survivorTotalRevivesGiven++;
		}
		case PlayerStatsSurvivorAction_Rescued:
		{
			g_Round.players[index].support.rescuesGiven++;
			g_Round.totals.survivorTotalRescuesGiven++;
		}
	}
}
