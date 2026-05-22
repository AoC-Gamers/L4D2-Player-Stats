#if defined _l4d2_player_skills_included
	#endinput
#endif
#define _l4d2_player_skills_included

enum L4D2SkillType
{
	L4D2Skill_None = 0,
	L4D2Skill_HunterSkeet,
	L4D2Skill_HunterSkeetMelee,
	L4D2Skill_HunterDeadstop,
	L4D2Skill_BoomerPop,
	L4D2Skill_ChargerLevel,
	L4D2Skill_TankDead,
	L4D2Skill_WitchDead,
	L4D2Skill_WitchIncap,
	L4D2Skill_SmokerTongueCut,
	L4D2Skill_SmokerSelfClear,
	L4D2Skill_TankRockSkeet,
	L4D2Skill_TankRockHit,
	L4D2Skill_HunterHighPounce,
	L4D2Skill_JockeyHighPounce,
	L4D2Skill_ChargerInstaKill,
	L4D2Skill_ChargerDeathSetup,
	L4D2Skill_SpecialPinClear,
	L4D2Skill_BoomerVomitLanded,
	L4D2Skill_BunnyHopStreak,
	L4D2Skill_CarAlarmTriggered,

	L4D2Skill_Size
}

enum L4D2SkillPlayerSlot
{
	L4D2SkillPlayer_Actor = 0,
	L4D2SkillPlayer_Victim,
	L4D2SkillPlayer_Assister,
	L4D2SkillPlayer_PinVictim
}

enum L4D2SkillBoolField
{
	L4D2SkillBool_WithShove = 0,
	L4D2SkillBool_Indirect,
	L4D2SkillBool_Forced,
	L4D2SkillBool_WasCarried,
	L4D2SkillBool_ReportedHigh,
	L4D2SkillBool_Incapped,
	L4D2SkillBool_LedgeHang,
	L4D2SkillBool_FatalFall,
	L4D2SkillBool_DeadlySlam,
	L4D2SkillBool_WouldQualifyAtBaseline,
	L4D2SkillBool_Crown,
	L4D2SkillBool_Startled,
	L4D2SkillBool_Perfect,
	L4D2SkillBool_Headshot,
	L4D2SkillBool_Sniper,
	L4D2SkillBool_GrenadeLauncher
}

forward Action PlayerSkills_OnSkillDetected(int eventId, L4D2SkillType type);

native bool PlayerSkills_IsEventValid(int eventId);
native int PlayerSkills_GetEventType(int eventId);
native bool PlayerSkills_GetEventBool(int eventId, L4D2SkillBoolField field);
native int PlayerSkills_GetEventClient(int eventId, L4D2SkillPlayerSlot slot);

public SharedPlugin __pl_l4d2_player_skills =
{
	name = "l4d2_player_skills",
	file = "l4d2_player_skills.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_player_skills_SetNTVOptional()
{
	MarkNativeAsOptional("PlayerSkills_IsEventValid");
	MarkNativeAsOptional("PlayerSkills_GetEventType");
	MarkNativeAsOptional("PlayerSkills_GetEventBool");
	MarkNativeAsOptional("PlayerSkills_GetEventClient");
}
#endif
