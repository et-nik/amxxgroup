#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>

#define	PLUGIN_NAME	"JailBreak Extreme"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"jbextreme"

#define TASK_JOIN	2487000
#define TASK_HUD	2487100

// Offsets
#define m_iPrimaryWeapon	116

#define GetRole()	random(_Roles)

enum _Player { Alive, Team, Role, JailTime, DaysLeft, Pursued, Reason }

new _Roles[][] = { "Drug dealer", "Assasin", "Thief", "Junkie", "Athlete", "Brawny" }
new _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone", "func_buyzone"
}

new g_CtCount
new g_TtCount
new g_TtAlive
new g_Day
new g_Simon
new g_LastSimon
new g_SimonTalking

new g_Player[33][_Player]
new g_MaxClients
new g_HudSync[4] // 0=status / 1=messages / 2=skills / 3=alerts

new gp_PrecacheSpawn
new gp_CtRatio
new gp_Skills
new gp_MaxDays

public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)

	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_message(get_user_msgid("ShowMenu"), "msg_TeamChoice")
	register_message(get_user_msgid("VGUIMenu"), "msg_TeamChoice")
	register_message(get_user_msgid("MOTD"), "msg_MOTD")

	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
	register_event("TeamInfo", "team_info", "a", "2=TERRORIST", "2=CT")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")

	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")

	register_clcmd("say /simon", "simon_say")
	register_clcmd("say /nomic", "simon_nomic")
	register_clcmd("+simonvoice", "voicerecord_on")
	register_clcmd("-simonvoice", "voicerecord_off")
	register_clcmd("joinclass", "block_command")
	register_clcmd("jointeam", "block_command")
	register_clcmd("chooseteam", "block_command")

	gp_CtRatio = register_cvar("jbe_ctratio", "3")
	gp_Skills = register_cvar("jbe_skills", "1")
	gp_MaxDays = register_cvar("jbe_maxdays", "15")

	for(new i=0; i < sizeof(g_HudSync); i++)
	{
		g_HudSync[i] = CreateHudSyncObj()
	}
	g_MaxClients = get_global_int(GL_maxClients)

}

public plugin_cfg()
{
	set_cvar_num("sv_alltalk", 1)

}

public plugin_precache()
{
	static i
	precache_model("models/player/straznik/straznik.mdl")
	precache_model("models/player/wiezien/wiezien.mdl")

	for(i = 0; i < sizeof(_FistModels); i++)
		precache_model(_FistModels[i])

	for(i = 0; i < sizeof(_CrowbarModels); i++)
		precache_model(_CrowbarModels[i])

	for(i = 0; i < sizeof(_FistSounds); i++)
		precache_sound(_FistSounds[i])

	gp_PrecacheSpawn = register_forward(FM_Spawn, "precache_spawn", 1)
}

public precache_spawn(iEnt)
{
	if(is_valid_ent(iEnt))
	{
		static szClass[33]
		entity_get_string(iEnt, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
				remove_entity(iEnt)
	}
}

public client_putinserver(iPlayer)
{
	client_cmd(iPlayer, "hud_centerid 0")
}

public client_disconnect(iPlayer)
{
	if(g_Player[iPlayer][Team] == _:CS_TEAM_CT)
		g_CtCount = g_CtCount > 0 ? g_CtCount - 1 : 0
	else
		g_TtCount = g_TtCount > 0 ? g_TtCount - 1 : 0

	if(g_Player[iPlayer][Alive] && (g_Player[iPlayer][Team] == _:CS_TEAM_T))
		g_TtAlive = g_TtAlive > 0 ? g_TtAlive-- : g_TtAlive

	g_Player[iPlayer][Alive] = 0
	g_Player[iPlayer][Team] = 0
	g_Player[iPlayer][Role] = 0
	g_Player[iPlayer][JailTime] = 0
	g_Player[iPlayer][DaysLeft] = 0
	g_Player[iPlayer][Pursued] = 0

	if(g_Simon == iPlayer) simon_select(g_LastSimon)
	if(g_CtCount < 1)
	{
		balance_teams()
	}

}

///////////////////////////////////////////////////////////////////////////////////////
// Messages & Forwards
///////////////////////////////////////////////////////////////////////////////////////

public msg_MOTD(iMsgid, iDest, iPlayer)
{
	return PLUGIN_HANDLED
}

public msg_TeamChoice(iMsgid, iDest, iPlayer)
{
	static iMsgArg
	iMsgArg = get_msg_arg_int(1)

	if(g_Player[iPlayer][Team] != 0)
		return PLUGIN_HANDLED

	switch(iMsgArg)
	{
		case 51:
		{
			set_task(1.0, "task_jointeam", TASK_JOIN + iPlayer)
			return PLUGIN_HANDLED
		}
		case 31, 531:
		{
			return PLUGIN_HANDLED
		}
		case 2:
		{
			set_task(1.0, "task_jointeam", TASK_JOIN + iPlayer)
			return PLUGIN_HANDLED
		}
		case 27:
		{
			return PLUGIN_HANDLED
		}
	}
	return PLUGIN_CONTINUE
}

public set_client_kv(iPlayer, const info[], const key[])
{
	if(equal(key, "model"))
	{
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public sound_emit(iPlayer, iChannel, szSample[])
{
	if(is_user_alive(iPlayer) && equal(szSample, "weapons/knife_", 14))
	{
		switch(szSample[17])
		{
			case('b'):
			{
				emit_sound(iPlayer, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				emit_sound(iPlayer, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(iPlayer, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
		}
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public voice_listening(iReceiver, iSender, bool:bListen)
{
	if(!is_user_connected(iReceiver) || !is_user_connected(iSender) || (iReceiver == iSender) || (iSender == g_Simon))
		return FMRES_IGNORED

	bListen = true

	if(g_SimonTalking)
	{
		if(iSender != g_Simon)
		{
			engfunc(EngFunc_SetClientListening, iReceiver, iSender, false)
			return FMRES_SUPERCEDE
		}
	}
	else
	{
		if(g_Player[iSender][Team] == _:CS_TEAM_T)
		{
			if(g_Player[iReceiver][Team] == _:CS_TEAM_CT)
				bListen = false
			else
				return FMRES_IGNORED
		}
	}

	engfunc(EngFunc_SetClientListening, iReceiver, iSender, bListen)
	return FMRES_SUPERCEDE
}

public current_weapon(iPlayer)
{
	if(is_user_alive(iPlayer))
	{
		set_pev(iPlayer, pev_viewmodel2, _FistModels[1])
		set_pev(iPlayer, pev_weaponmodel2, _FistModels[0])
	}
}

public team_info()
{
	static iPlayer, iTeam, szTeam[32]

	iPlayer = read_data(1)
	read_data(2, szTeam, charsmax(szTeam))
	iTeam = (szTeam[0] == 'T') ? _:CS_TEAM_T : _:CS_TEAM_CT

	if(g_Player[iPlayer][Team] != iTeam)
	{
		g_Player[iPlayer][Team] = iTeam
		switch(iTeam)
		{
			case(_:CS_TEAM_T):
			{
				g_TtCount++
			}
			case(_:CS_TEAM_CT):
			{
				g_CtCount++
			}
		}
	}
}

public round_end()
{
	remove_task(TASK_HUD)
	g_CtCount = g_TtCount = g_TtAlive = 0
	g_LastSimon = g_Simon
	g_Simon = 0
	g_SimonTalking = 0

	balance_teams()

	return PLUGIN_CONTINUE
}

public round_start()
{
	set_task(2.0, "hud_update", TASK_HUD,_,_,"b")
}

public player_spawn(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return HAM_IGNORED

	set_user_rendering(iPlayer, 255, 255, 255, 16, kRenderFxNone, kRenderNormal)
	strip_user_weapons(iPlayer)
	give_item(iPlayer, "weapon_knife")
	set_pdata_int(iPlayer, m_iPrimaryWeapon, 0)

	new iTeam = _:cs_get_user_team(iPlayer)
	g_Player[iPlayer][Alive] = 1
	g_Player[iPlayer][Team] = _:iTeam

	switch(_:iTeam)
	{
		case(_:CS_TEAM_T):
		{
			g_TtCount++
			g_TtAlive++
			set_user_info(iPlayer, "model", "wiezien")
			set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 0.0, 10.0, 0.0, 0.0, -1)
			ShowSyncHudMsg(iPlayer, g_HudSync[2], "You have %s skill. You're prisoner for %i days.^n^rYou have %i days left in jail",
					_Roles[g_Player[iPlayer][Role]], g_Player[iPlayer][JailTime], g_Player[iPlayer][DaysLeft])
		}
		case(_:CS_TEAM_CT):
		{
			g_CtCount++
			set_user_info(iPlayer, "model", "straznik")
		}
	}
	return HAM_IGNORED
}

public player_killed(iPlayer)
{
	g_Player[iPlayer][Alive] = 0
	switch(g_Player[iPlayer][Team])
	{
		case(_:CS_TEAM_T):
		{
			g_TtAlive = g_TtAlive > 0 ? g_TtAlive-- : g_TtAlive
		}
	}
	return HAM_IGNORED
}

public player_damage(iVictim, iEnt, iAttacker, Float:fDamage, iDamageBits)
{
	if(g_Player[iAttacker][Team] == _:CS_TEAM_T)
	{
		if(g_Player[iVictim][Team] == _:CS_TEAM_CT)
		{
			client_print(0, print_center, "Revolt started")
		}
		
	}
	return HAM_IGNORED
}

public simon_say(iPlayer)
{
	if(!is_user_alive(iPlayer) || (g_Player[iPlayer][Team] != _:CS_TEAM_CT))
		return PLUGIN_CONTINUE

	simon_select(iPlayer)
	return PLUGIN_HANDLED
}

public simon_nomic(iPlayer)
{
	if(!is_user_alive(iPlayer) || (g_Player[iPlayer][Team] != _:CS_TEAM_CT))
		return PLUGIN_CONTINUE

	engclient_cmd(iPlayer, "jointeam", "1")
	engclient_cmd(iPlayer, "joinclass", "5")
	return PLUGIN_HANDLED
}

public voicerecord_on(iPlayer)
{
	client_cmd(iPlayer, "+voicerecord")
	if(g_Simon != iPlayer)
		return PLUGIN_HANDLED

	g_SimonTalking = 1
	return PLUGIN_HANDLED
}

public voicerecord_off(iPlayer)
{
	client_cmd(iPlayer, "-voicerecord")
	if(g_Simon != iPlayer)
		return PLUGIN_HANDLED

	g_SimonTalking = 0
	return PLUGIN_HANDLED
}

public block_command(iPlayer)
{
	return PLUGIN_HANDLED
}


///////////////////////////////////////////////////////////////////////////////////////
// Internal Functions
///////////////////////////////////////////////////////////////////////////////////////

stock balance_teams()
{
	static iPlayer
	for(iPlayer = 1; iPlayer < g_MaxClients; iPlayer++)
	{
		if((g_CtCount < 1 || team_balance()) && (iPlayer =  random_num(1,g_MaxClients)) && (g_Player[iPlayer][Team] == _:CS_TEAM_T))
		{
			server_print("player team %i %i", iPlayer, g_Player[iPlayer][Team])
			g_Player[iPlayer][Team] = _:CS_TEAM_CT
			g_CtCount++
			g_TtCount--
			cs_set_user_team(iPlayer, CS_TEAM_CT)
			user_silentkill(iPlayer)
		}
	}
}

stock team_balance()
{
	return g_CtCount < (g_TtCount / get_pcvar_num(gp_CtRatio))
}

stock check_team(iTeam)
{
	return (g_CtCount < 1) || ((iTeam == _:CS_TEAM_CT) && team_balance())
}

public hud_update()
{
	static szStatus[32]

	formatex(szStatus, charsmax(szStatus), "Prisoners: %i Alive / %i Total", g_TtAlive, g_TtCount)
	message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
	write_byte(0)
	write_string(szStatus)
	message_end()  
}

public task_jointeam(iTaskId)
{
	static iTeam
	new iPlayer = iTaskId - TASK_JOIN

	iTeam = random_num(1,2)
	if(check_team(iTeam))
	{
		g_CtCount++
		g_Player[iPlayer][Team] = _:CS_TEAM_CT
	}
	else
	{
		g_TtCount++
		g_Player[iPlayer][Team] = _:CS_TEAM_T
		g_Player[iPlayer][JailTime] = random_num(1,get_pcvar_num(gp_MaxDays))
		g_Player[iPlayer][DaysLeft] = g_Player[iPlayer][JailTime]
		g_Player[iPlayer][Role] = random(sizeof(_Roles))
		g_Player[iPlayer][Pursued] = 0
	}
	hud_update()
	
	switch(g_Player[iPlayer][Team])
	{
		case(_:CS_TEAM_CT):
		{
			engclient_cmd(iPlayer, "jointeam", "2")
			engclient_cmd(iPlayer, "joinclass", "5")
		}
		case(_:CS_TEAM_T):
		{
			engclient_cmd(iPlayer, "jointeam", "1")
			engclient_cmd(iPlayer, "joinclass", "5")
		}
	}
}

public simon_select(iPlayer)
{
	if(is_user_alive(iPlayer) && (g_Player[iPlayer][Team] == _:CS_TEAM_CT))
	{
		g_Simon = iPlayer
		set_user_rendering(iPlayer, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 10.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(iPlayer, g_HudSync[2], "You're Simon. You're in charge of the prisioners")
	}
}
