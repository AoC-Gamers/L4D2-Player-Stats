#if defined _l4d2_player_stats_helpers_included
	#endinput
#endif
#define _l4d2_player_stats_helpers_included


stock bool Stats_IsSkillTypeEnabledInCurrentMode(L4D2ApiSkillType type)
{
	switch (type)
	{
		case L4D2ApiSkill_HunterSkeet, L4D2ApiSkill_HunterSkeetMelee, L4D2ApiSkill_HunterDeadstop, L4D2ApiSkill_HunterHighPounce:
		{
			return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Hunter) : true;
		}
		case L4D2ApiSkill_BoomerPop, L4D2ApiSkill_BoomerVomitLanded:
		{
			return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Boomer) : true;
		}
		case L4D2ApiSkill_ChargerLevel, L4D2ApiSkill_ChargerInstaKill, L4D2ApiSkill_ChargerDeathSetup:
		{
			return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Charger) : true;
		}
		case L4D2ApiSkill_SmokerTongueCut, L4D2ApiSkill_SmokerSelfClear:
		{
			return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Smoker) : true;
		}
		case L4D2ApiSkill_JockeyHighPounce:
		{
			return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(L4D2ZombieClass_Jockey) : true;
		}
	}

	return true;
}

stock bool Stats_IsZombieClassEnabledInCurrentMode(L4D2ZombieClassType zombieClass)
{
	return Stats_IsCompetitiveMode() ? Stats_IsVersusSpecialLimitEnabled(zombieClass) : true;
}

stock bool Stats_IsZombieClassEnabledForSnapshot(L4D2ZombieClassType zombieClass, bool isVersusMode, int siPoolMask)
{
	if (!isVersusMode)
	{
		return true;
	}

	switch (zombieClass)
	{
		case L4D2ZombieClass_Smoker:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Smoker)) != 0;
		}
		case L4D2ZombieClass_Boomer:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Boomer)) != 0;
		}
		case L4D2ZombieClass_Hunter:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Hunter)) != 0;
		}
		case L4D2ZombieClass_Spitter:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Spitter)) != 0;
		}
		case L4D2ZombieClass_Jockey:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Jockey)) != 0;
		}
		case L4D2ZombieClass_Charger:
		{
			return (siPoolMask & view_as<int>(PlayerStatsSiPool_Charger)) != 0;
		}
	}

	return true;
}


/**
 * @brief Checks whether an entity is a Witch.
 *
 * @param entity         Entity index to inspect.
 *
 * @return               True if the entity classname matches a Witch variant.
 */
stock bool IsWitchEntity(int entity)
{
	if (entity <= MaxClients || !IsValidEntity(entity))
	{
		return false;
	}

	char classname[64];
	GetEntityClassname(entity, classname, sizeof(classname));
	return StrContains(classname, "witch", false) != -1;
}


stock PlayerStatsWeaponFamily Stats_GetWeaponFamily(const char[] weapon)
{
	if (weapon[0] == '\0')
	{
		return PlayerStatsWeaponFamily_None;
	}

	char normalized[64];
	if (strncmp(weapon, "weapon_", 7, false) == 0)
	{
		strcopy(normalized, sizeof(normalized), weapon);
	}
	else
	{
		Format(normalized, sizeof(normalized), "weapon_%s", weapon);
	}

	switch (WeaponNameToId(normalized))
	{
		case WEPID_PUMPSHOTGUN, WEPID_AUTOSHOTGUN, WEPID_SHOTGUN_CHROME, WEPID_SHOTGUN_SPAS:
		{
			return PlayerStatsWeaponFamily_Shotgun;
		}
		case WEPID_SMG, WEPID_RIFLE, WEPID_SMG_SILENCED, WEPID_RIFLE_DESERT, WEPID_SMG_MP5, WEPID_RIFLE_AK47, WEPID_RIFLE_SG552, WEPID_RIFLE_M60:
		{
			return PlayerStatsWeaponFamily_SmgRifle;
		}
		case WEPID_HUNTING_RIFLE, WEPID_SNIPER_MILITARY, WEPID_SNIPER_AWP, WEPID_SNIPER_SCOUT:
		{
			return PlayerStatsWeaponFamily_Sniper;
		}
		case WEPID_PISTOL, WEPID_PISTOL_MAGNUM:
		{
			return PlayerStatsWeaponFamily_Pistol;
		}
	}

	return PlayerStatsWeaponFamily_None;
}

stock PlayerStatsWeaponDetailType Stats_GetWeaponDetailType(const char[] weapon)
{
	if (weapon[0] == '\0')
	{
		return PlayerStatsWeaponDetail_None;
	}

	char normalized[64];
	if (strncmp(weapon, "weapon_", 7, false) == 0)
	{
		strcopy(normalized, sizeof(normalized), weapon);
	}
	else
	{
		Format(normalized, sizeof(normalized), "weapon_%s", weapon);
	}

	switch (WeaponNameToId(normalized))
	{
		case WEPID_PUMPSHOTGUN:
		{
			return PlayerStatsWeaponDetail_PumpShotgun;
		}
		case WEPID_AUTOSHOTGUN:
		{
			return PlayerStatsWeaponDetail_Autoshotgun;
		}
		case WEPID_SHOTGUN_CHROME:
		{
			return PlayerStatsWeaponDetail_ChromeShotgun;
		}
		case WEPID_SHOTGUN_SPAS:
		{
			return PlayerStatsWeaponDetail_SpasShotgun;
		}
		case WEPID_SMG:
		{
			return PlayerStatsWeaponDetail_Smg;
		}
		case WEPID_SMG_SILENCED:
		{
			return PlayerStatsWeaponDetail_SmgSilenced;
		}
		case WEPID_SMG_MP5:
		{
			return PlayerStatsWeaponDetail_SmgMp5;
		}
		case WEPID_RIFLE:
		{
			return PlayerStatsWeaponDetail_Rifle;
		}
		case WEPID_RIFLE_AK47:
		{
			return PlayerStatsWeaponDetail_RifleAk47;
		}
		case WEPID_RIFLE_DESERT:
		{
			return PlayerStatsWeaponDetail_RifleDesert;
		}
		case WEPID_RIFLE_SG552:
		{
			return PlayerStatsWeaponDetail_RifleSg552;
		}
		case WEPID_RIFLE_M60:
		{
			return PlayerStatsWeaponDetail_RifleM60;
		}
		case WEPID_HUNTING_RIFLE:
		{
			return PlayerStatsWeaponDetail_HuntingRifle;
		}
		case WEPID_SNIPER_MILITARY:
		{
			return PlayerStatsWeaponDetail_SniperMilitary;
		}
		case WEPID_SNIPER_AWP:
		{
			return PlayerStatsWeaponDetail_SniperAwp;
		}
		case WEPID_SNIPER_SCOUT:
		{
			return PlayerStatsWeaponDetail_SniperScout;
		}
		case WEPID_PISTOL:
		{
			return PlayerStatsWeaponDetail_Pistol;
		}
		case WEPID_PISTOL_MAGNUM:
		{
			return PlayerStatsWeaponDetail_Magnum;
		}
	}

	return PlayerStatsWeaponDetail_None;
}

stock PlayerStatsWeaponFamily Stats_GetWeaponFamilyFromDetail(PlayerStatsWeaponDetailType detail)
{
	switch (detail)
	{
		case PlayerStatsWeaponDetail_PumpShotgun, PlayerStatsWeaponDetail_Autoshotgun, PlayerStatsWeaponDetail_ChromeShotgun, PlayerStatsWeaponDetail_SpasShotgun:
		{
			return PlayerStatsWeaponFamily_Shotgun;
		}
		case PlayerStatsWeaponDetail_Smg, PlayerStatsWeaponDetail_SmgSilenced, PlayerStatsWeaponDetail_SmgMp5,
			PlayerStatsWeaponDetail_Rifle, PlayerStatsWeaponDetail_RifleAk47, PlayerStatsWeaponDetail_RifleDesert, PlayerStatsWeaponDetail_RifleSg552, PlayerStatsWeaponDetail_RifleM60:
		{
			return PlayerStatsWeaponFamily_SmgRifle;
		}
		case PlayerStatsWeaponDetail_HuntingRifle, PlayerStatsWeaponDetail_SniperMilitary, PlayerStatsWeaponDetail_SniperAwp, PlayerStatsWeaponDetail_SniperScout:
		{
			return PlayerStatsWeaponFamily_Sniper;
		}
		case PlayerStatsWeaponDetail_Pistol, PlayerStatsWeaponDetail_Magnum:
		{
			return PlayerStatsWeaponFamily_Pistol;
		}
	}

	return PlayerStatsWeaponFamily_None;
}

stock void Stats_GetWeaponDetailName(PlayerStatsWeaponDetailType detail, char[] buffer, int maxlen)
{
	static const char g_PlayerStatsWeaponDetailNames[PlayerStatsWeaponDetail_Count][] =
	{
		"Unknown",
		"Pump",
		"Auto Shotgun",
		"Chrome",
		"SPAS Shotgun",
		"Uzi",
		"Silenced SMG",
		"MP5",
		"M-16",
		"AK-47",
		"Desert Rifle",
		"SG552",
		"M60",
		"Hunting Rifle",
		"Military Sniper",
		"AWP",
		"Scout",
		"Pistol",
		"Magnum"
	};

	if (detail >= PlayerStatsWeaponDetail_None && detail < PlayerStatsWeaponDetail_Count)
	{
		strcopy(buffer, maxlen, g_PlayerStatsWeaponDetailNames[detail]);
		return;
	}

	strcopy(buffer, maxlen, "Unknown");
}
