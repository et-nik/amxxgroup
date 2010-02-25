#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <cstrike>
#include <fun>

#define PLUGIN_NAME	"Ultimate Hero City"
#define PLUGIN_VERSION	"0.1"
#define PLUGIN_AUTHOR	"JoRoPiTo"

#define TASK_JOIN	248000
#define TASK_WARMUP	248100
#define TASK_RESPAWN	248200

new cvar_MinPlayers
new cvar_RestartRound

new bool:g_WarmUp = true

new CsTeams:g_PlayerTeam[33]

new g_Players = 0
new g_HudSync

new const g_RemoveEntities[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"armoury_entity"
};

new const MAX_REMOVED_ENTITIES = sizeof(g_RemoveEntities);


public plugin_precache()
{
	register_forward(FM_Spawn, "fwd_Spawn", 0)
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("uhc", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_message(get_user_msgid("ShowMenu"), "msg_ShowMenu");
	register_message(get_user_msgid("VGUIMenu"), "msg_VGUIMenu");
	register_message(get_user_msgid("MOTD"), "msg_MOTD");

	RegisterHam(Ham_Killed, "player", "ham_PlayerKilled", 1)
	RegisterHam(Ham_Spawn, "player", "ham_Spawn", 1)

	cvar_MinPlayers = register_cvar("uhc_minplayers", "2")

	cvar_RestartRound = get_cvar_pointer("sv_restartround")

	g_HudSync = CreateHudSyncObj()
}

public plugin_cfg()
{
	task_WarmUp()
}

public client_connect(iPlayer)
{
	g_PlayerTeam[iPlayer] = CS_TEAM_UNASSIGNED
}

public client_disconnect(iPlayer)
{
	g_Players--
	g_WarmUp = g_Players < get_pcvar_num(cvar_MinPlayers)
	if(g_WarmUp)
		task_WarmUp()
}

public client_putinserver(iPlayer)
{
	g_Players++
	g_WarmUp = g_Players < get_pcvar_num(cvar_MinPlayers)
}


//- Forwards & Calls -//
public fwd_Spawn(iEnt)
{
	if(!pev_valid(iEnt))
		return FMRES_IGNORED;

	new sClass[32];
	pev(iEnt, pev_classname, sClass, charsmax(sClass));

	for(new i=0; i<MAX_REMOVED_ENTITIES; i++)
	{
		if(equal(sClass, g_RemoveEntities[i]))
		{
			engfunc(EngFunc_RemoveEntity, iEnt);
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public msg_MOTD(iMsgid, iDest, iPlayer)
{
	return PLUGIN_HANDLED
}

public msg_ShowMenu(iMsgid, iDest, iPlayer)
{
	static iMsgArg
	iMsgArg = get_msg_arg_int(1)
	switch(iMsgArg)
	{
		case 51:
		{
			set_task(1.0, "task_JoinTeam", TASK_JOIN + iPlayer)
			return PLUGIN_HANDLED
		}
		case 31, 531:
		{
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public msg_VGUIMenu(iMsgid, iDest, iPlayer)
{
	static iMsgArg
	iMsgArg = get_msg_arg_int(1)
	switch(iMsgArg)
	{
		case 2:
		{
			set_task(1.0, "task_JoinTeam", TASK_JOIN + iPlayer)
			return PLUGIN_HANDLED
		}
		case 26:
		{
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public ham_PlayerKilled(iPlayer, iAtacker, iShouldGib)
{
	if(cs_get_user_team(iPlayer) == CS_TEAM_CT)
	{
		cs_set_user_team(iPlayer, CS_TEAM_T)
		cs_set_user_team(iAtacker, CS_TEAM_CT)
		strip_user_weapons(iAtacker)
		set_task(3.0, "task_Respawn")
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public ham_Spawn(iPlayer)
{
	if(is_user_alive(iPlayer) && cs_get_user_team(iPlayer) == CS_TEAM_CT)
		strip_user_weapons(iPlayer)

	return HAM_HANDLED
}

//- Plugin Functions -//
public task_JoinTeam(iTaskId)
{
	new iPlayer = iTaskId - TASK_JOIN
	engclient_cmd(iPlayer, "jointeam", "1")
	engclient_cmd(iPlayer, "joinclass", "5")
}

public task_WarmUp()
{
	if(!g_WarmUp)
	{
		set_hudmessage(0, 255, 0, -1.0, 0.4, 0, 6.0, 2.2, 0.4, 0.4)
		ShowSyncHudMsg(0, g_HudSync, "Ultimate Hero City: Starting Game!!!")
		set_task(3.0, "task_Start")
	}
	else
	{
		set_hudmessage(255, 0, 0, -1.0, 0.4, 0, 6.0, 0.4, 0.3, 0.3)
		ShowSyncHudMsg(0, g_HudSync, "Ultimate Hero City: Warmup time!!!")
		set_task(1.0, "task_WarmUp")
	}
}

public task_Start()
{
	set_pcvar_num(cvar_RestartRound, 1)
}

public task_Respawn(iTaskId)
{
	spawn(iTaskId - TASK_RESPAWN)
}
