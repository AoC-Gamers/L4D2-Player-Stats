#if defined _l4d2_player_stats_modules_accuracy_included
	#endinput
#endif
#define _l4d2_player_stats_modules_accuracy_included

PlayerStatsAccuracyApplyResult Accuracy_ApplyWitchHit(const StatsWitchDamageRecord record)
{
	if (!Stats_IsAccuracyEnabled())
	{
		return PlayerStatsAccuracy_Disabled;
	}

	if (!Stats_IsValidRoundSlot(record.roundSlot))
	{
		return PlayerStatsAccuracy_InvalidSlot;
	}

	Stats_RecordAccuracyHit(record.roundSlot, record.family, record.headshot);
	Stats_RecordAccuracyDetailHit(record.roundSlot, record.detail, record.headshot);
	return PlayerStatsAccuracy_Applied;
}

PlayerStatsAccuracyApplyResult Accuracy_ApplyPlayerHurtHit(int index, PlayerStatsWeaponFamily family, PlayerStatsWeaponDetailType detail, bool headshot)
{
	if (!Stats_IsAccuracyEnabled())
	{
		return PlayerStatsAccuracy_Disabled;
	}

	if (!Stats_IsValidRoundSlot(index))
	{
		return PlayerStatsAccuracy_InvalidSlot;
	}

	Stats_RecordAccuracyHit(index, family, headshot);
	Stats_RecordAccuracyDetailHit(index, detail, headshot);
	return PlayerStatsAccuracy_Applied;
}

PlayerStatsShotRouteResult Accuracy_ApplyShot(const StatsShotRecord observation, int &index)
{
	index = -1;

	if (!Stats_IsRoundLive())
	{
		return PlayerStatsShotRoute_RoundNotLive;
	}

	if (!Stats_IsTrackingEnabled() && !Stats_IsAccuracyEnabled() && !Stats_IsThrowablesEnabled())
	{
		return PlayerStatsShotRoute_FeaturesDisabled;
	}

	if (!observation.validPayload)
	{
		return PlayerStatsShotRoute_InvalidPayload;
	}

	int client = observation.client;
	if (!IsValidSurvivor(client))
	{
		return PlayerStatsShotRoute_InvalidActor;
	}

	if (observation.weapon[0] == '\0')
	{
		return PlayerStatsShotRoute_EmptyWeapon;
	}

	index = Stats_EnsurePlayerRoundSlot(client);
	if (index == -1)
	{
		return PlayerStatsShotRoute_NoSlot;
	}

	PlayerStatsWeaponFamily family = Stats_GetWeaponFamily(observation.weapon);
	PlayerStatsWeaponDetailType detail = Stats_GetWeaponDetailType(observation.weapon);
	if (family == PlayerStatsWeaponFamily_None && detail != PlayerStatsWeaponDetail_None)
	{
		family = Stats_GetWeaponFamilyFromDetail(detail);
	}
	Stats_SetLastWeaponFamily(client, family);
	Stats_SetLastWeaponDetail(client, detail);
	Stats_RecordAccuracyShot(index, family);
	Stats_RecordAccuracyDetailShot(index, detail);

	return PlayerStatsShotRoute_ReadyForUtility;
}

stock void Stats_RecordAccuracyShot(int index, PlayerStatsWeaponFamily family)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (family)
	{
		case PlayerStatsWeaponFamily_Shotgun:
		{
			g_Round.players[index].accuracy.shotgunShots++;
		}
		case PlayerStatsWeaponFamily_SmgRifle:
		{
			g_Round.players[index].accuracy.smgRifleShots++;
		}
		case PlayerStatsWeaponFamily_Sniper:
		{
			g_Round.players[index].accuracy.sniperShots++;
		}
		case PlayerStatsWeaponFamily_Pistol:
		{
			g_Round.players[index].accuracy.pistolShots++;
		}
	}
}

stock void Stats_RecordAccuracyDetailShot(int index, PlayerStatsWeaponDetailType detail)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index) || detail <= PlayerStatsWeaponDetail_None || detail >= PlayerStatsWeaponDetail_Count)
	{
		return;
	}

	g_Round.players[index].accuracyDetails.shots[detail]++;
}

stock void Stats_RecordAccuracyHit(int index, PlayerStatsWeaponFamily family, bool headshot = false)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index))
	{
		return;
	}

	switch (family)
	{
		case PlayerStatsWeaponFamily_Shotgun:
		{
			g_Round.players[index].accuracy.shotgunHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.shotgunHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_SmgRifle:
		{
			g_Round.players[index].accuracy.smgRifleHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.smgRifleHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_Sniper:
		{
			g_Round.players[index].accuracy.sniperHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.sniperHeadshots++;
			}
		}
		case PlayerStatsWeaponFamily_Pistol:
		{
			g_Round.players[index].accuracy.pistolHits++;
			if (headshot)
			{
				g_Round.players[index].accuracy.pistolHeadshots++;
			}
		}
	}
}

stock void Stats_RecordAccuracyDetailHit(int index, PlayerStatsWeaponDetailType detail, bool headshot = false)
{
	if (!Stats_IsAccuracyEnabled() || !Stats_IsValidRoundSlot(index) || detail <= PlayerStatsWeaponDetail_None || detail >= PlayerStatsWeaponDetail_Count)
	{
		return;
	}

	g_Round.players[index].accuracyDetails.hits[detail]++;
	if (headshot)
	{
		g_Round.players[index].accuracyDetails.headshots[detail]++;
	}
}
