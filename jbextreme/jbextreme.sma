/*
http://forums.alliedmods.net/showthread.php?t=117769&highlight=team

jointeam
	Admin can switch manually


transferPlayer
	cs_set_user_defuse(id, 0);
	cs_set_user_team
	cs_reset_user_model


*/

#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
 
#define	PLUGIN_NAME	"JailBreak Extreme"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.7"
#define	PLUGIN_CVAR	"jbextreme"
 
#define TASK_JOINTEAM	2487000
#define TASK_JOINCLASS	2487100
#define TASK_JOINBOT	2487300
#define TASK_SPAWN	2487400
#define TASK_HUD	2487500
 
#define DEBUG		1

#define SetBit(%1,%2)	%1 |=  ( 1 << ( %2 & 31 ) )
#define ClearBit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )
#define GetBit(%1,%2)	( %1 &   1 << ( %2 & 31 ) )

 
// Offsets
#define m_iPrimaryWeapon	116
#define m_iTeam			114
 
new const _TeamStrings[][] = { "0", "1", "2", "3" }
new const _TeamModels[][] = { "", "wiezien", "straznik", "" }
new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone", "func_buyzone"
}
 
enum _Player { Alive, Connected, Team, NewTeam, Mic, Name[33], Msgid }

new g_CtCount
new g_TtCount
new g_CtAlive
new g_TtAlive

new g_Player[33][_Player]
new g_Simon
new g_LastSimon
new g_SimonTalking
 
new g_MaxClients
new g_HudSync[4] // 0=status / 1=messages / 2=skills / 3=alerts
new g_MsgStatusIcon
new g_MsgVGUIMenu
new g_MsgShowMenu
new g_MsgTeamInfo
new g_MsgMOTD
 
new gp_PrecacheSpawn
new gp_CtRatio
new gp_Skills
new gp_MaxDays

 
public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgMOTD = get_user_msgid("MOTD")

	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_teamchoice")
	register_message(g_MsgShowMenu, "msg_teamchoice")
	register_message(g_MsgTeamInfo, "msg_teaminfo")
	register_message(g_MsgMOTD, "msg_motd")
 
	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
//	register_event("StatusValue", "status_show", "be", "1=2", "2!0")
//	register_event("StatusValue", "status_hide", "be", "1=1", "2=0")
	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_end", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")
 
	register_impulse(100, "impulse_100")
	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")
 
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_Killed, "player", "player_killed", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
 
	register_clcmd("say /info", "simon_info")
	register_clcmd("say /simon", "simon_say")
	register_clcmd("say /nomic", "simon_nomic")
	register_clcmd("+simonvoice", "voicerecord_on")
	register_clcmd("-simonvoice", "voicerecord_off")
	register_clcmd("joinclass", "block_command")
	register_clcmd("jointeam", "block_command")
	register_clcmd("chooseteam", "block_command")

	register_clcmd("caca", "caca")
 
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
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
 
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
	_debug("Client putinserver %i", iPlayer)
	client_cmd(iPlayer, "hud_centerid 0")
	g_Player[iPlayer][Mic] = 1
	g_Player[iPlayer][Connected] = 1
}
 
public client_disconnect(iPlayer)
{
	_debug("Player disconnected %i", iPlayer)
	g_Player[iPlayer][Connected] = 0
}
 
///////////////////////////////////////////////////////////////////////////////////////
// Messages & Forwards
///////////////////////////////////////////////////////////////////////////////////////
 
public msg_motd(iMsgid, iDest, iPlayer)
{
	return PLUGIN_HANDLED
}
 
public msg_statusicon(iMsgid, iDest, iPlayer)
{
	static szIcon[5]
	get_msg_arg_string(2, szIcon, charsmax(szIcon))
	if(szIcon[0] == 'b' && szIcon[2] == 'y' && szIcon[3] == 'z')
	{
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public msg_teamchoice(iMsgid, iDest, iPlayer)
{
	static iMsgArg

	iMsgArg = get_msg_arg_int(1)

	if(!is_user_connected(iPlayer))
		return PLUGIN_CONTINUE

	_debug("Msg (%i:%i) %i %i %i", g_MsgVGUIMenu, g_MsgShowMenu, iPlayer, iMsgid, iMsgArg)
	if(((iMsgid == g_MsgVGUIMenu) && (iMsgArg == 2)) || ((iMsgid == g_MsgShowMenu) && (iMsgArg == 51)))
	{
		g_Player[iPlayer][Msgid] = iMsgid
		set_task(1.0, "task_join", TASK_JOINTEAM + iPlayer)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_teaminfo(iMsgid, iDest, iPlayer)
{
	static szTeam[32], iPlayerInfo
	iPlayerInfo = get_msg_arg_int(1)
	get_msg_arg_string(2, szTeam, charsmax(szTeam))

	switch(szTeam[0])
	{
		case('U'):
		{
			g_Player[iPlayerInfo][Team] = 0
		}
		case('T'):
		{
			g_Player[iPlayerInfo][Team] = 1
		}
		case('C'):
		{
			g_Player[iPlayerInfo][Team] = 2
		}
		case('S'):
		{
			g_Player[iPlayerInfo][Team] = 3
		}
	}

	return PLUGIN_CONTINUE
}
 
public impulse_100(iPlayer)
{
	if(g_Player[iPlayer][Team] == _:CS_TEAM_T)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public set_client_kv(iPlayer, const info[], const key[])
{
	if(equal(key, "model"))
		return FMRES_SUPERCEDE

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
		if(get_user_team(iSender) == _:CS_TEAM_T)
		{
			if(get_user_team(iReceiver) == _:CS_TEAM_CT)
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

public status_show(iPlayer)
{
	static szName[33], iPlayer2
	if(iPlayer && g_Player[iPlayer][Alive])
	{
		iPlayer2 = read_data(2)
		get_user_name(iPlayer2, szName, charsmax(szName))
		switch(g_Player[iPlayer2][Team])
		{
			case(_:CS_TEAM_T):
			{
				set_hudmessage(100, 255, 0, -1.0, 0.80, 0, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(iPlayer, g_HudSync[0], "Prisoner: %s [%d HP]", szName, get_user_health(iPlayer2))
			}
			case(_:CS_TEAM_CT):
			{
				set_hudmessage(0, 255, 100, -1.0, 0.80, 0, 0.01, 3.0, 0.01, 0.01, -1)
				ShowSyncHudMsg(iPlayer, g_HudSync[0], "Guard: %s [%d HP]", szName, get_user_health(iPlayer2))
			}
		}
		return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public status_hide(iPlayer)
{
	ClearSyncHud(iPlayer, g_HudSync[0])
	return PLUGIN_HANDLED
}
 
public round_end()
{
	static iCtNeeded, iTtNeeded, iTeam, iPlayer, iCount, iNeeded
	new iStack

	g_LastSimon = g_Simon
	g_Simon = 0
	iCount = get_playersnum()
	iCtNeeded = iCount / get_pcvar_num(gp_CtRatio)
	iTtNeeded = iCount - iCtNeeded

	if((iCtNeeded > 0) && (g_CtCount < iCtNeeded))
	{
		iNeeded = iCtNeeded - g_CtCount
		iTeam = _:CS_TEAM_CT
	}
	else if((iTtNeeded > 0) && (g_TtCount < iTtNeeded))
	{
		iNeeded = iTtNeeded - g_TtCount
		iTeam = _:CS_TEAM_T
	}
	else
	{
		iNeeded = 0
	}
	_debug("CT Needed %i (%i:%i) (%i:%i) %i", iNeeded, g_CtCount, g_TtCount, iCtNeeded, iTtNeeded, iTeam)

	if(iNeeded)
	{
		for(new i = 1; i <= iCount; i++)
		{
			new ixx
			while(iNeeded && (iPlayer = random_num(1, g_MaxClients)))
			{
				ixx++
				_debug("While %i %i %i %i", iNeeded, iPlayer, iStack, !GetBit(iStack, iPlayer))
				if(!GetBit(iStack, iPlayer) && g_Player[iPlayer][Connected])
				{
					g_Player[iPlayer][Team] = _:cs_get_user_team(iPlayer)
					if(g_Player[iPlayer][Team] != iTeam)
					{
						iNeeded--
						break
					}
				}
				if(ixx > (2 * g_MaxClients))
					break
			}
			_debug("While post %i %i %i %i %i", iPlayer, iStack, !GetBit(iStack, iPlayer), (g_Player[iPlayer][Team] != _:CS_TEAM_CT),
				g_Player[iPlayer][Connected])

			SetBit(iStack, iPlayer)
	
			_debug("While end %i %i %i %i", iPlayer, iStack, iNeeded, iTeam)
			force_team(iPlayer, iTeam, 1, 1)
			if(iNeeded <= 0)
				break
		}
	}
	g_CtCount = g_TtCount = 0
}
 
public round_start()
{
}
 
public player_spawn(iPlayer)
{
	if(!is_user_alive(iPlayer))
		return HAM_IGNORED

	if(!task_exists(TASK_HUD))
		set_task(2.0, "hud_update", TASK_HUD, _, _, "b")

	set_user_rendering(iPlayer, 255, 255, 255, 16, kRenderFxNone, kRenderNormal)
	strip_user_weapons(iPlayer)
	give_item(iPlayer, "weapon_knife")
	set_pdata_int(iPlayer, m_iPrimaryWeapon, 0)
 
	new iTeam = _:cs_get_user_team(iPlayer)
 
	switch(_:iTeam)
	{
		case(_:CS_TEAM_T):
		{
			g_TtCount++
			g_TtAlive++
			set_user_info(iPlayer, "model", "wiezien")
			set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 0.0, 10.0, 0.0, 0.0, -1)
//			ShowSyncHudMsg(iPlayer, g_HudSync[2], "You have %s skill. You're prisoner for %i days.^n^rYou have %i days left in jail",
//					_Roles[g_Player[iPlayer][Role]], g_Player[iPlayer][JailTime], g_Player[iPlayer][DaysLeft])
		}
		case(_:CS_TEAM_CT):
		{
			g_CtCount++
			g_CtAlive++
			set_user_info(iPlayer, "model", "straznik")
		}
	}
	g_Player[iPlayer][Alive] = 1
	g_Player[iPlayer][Team] = iTeam
	get_user_name(iPlayer, g_Player[iPlayer][Name], charsmax(g_Player[][Name]))
	return HAM_IGNORED
}
 
public player_killed(iPlayer)
{
	g_Player[iPlayer][Alive] = 0
	if(g_Simon == iPlayer)
	{
		g_Simon = 0
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 10.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_HudSync[2], "Simon was killed. Another guard should take his job")
	}
	switch(g_Player[iPlayer][Alive])
	{
		case(_:CS_TEAM_T):
		{
			g_TtAlive--
		}
		case(_:CS_TEAM_CT):
		{
			g_CtAlive--
		}
	}

	return HAM_IGNORED
}
 
public player_damage(iVictim, iEnt, iAttacker, Float:fDamage, iDamageBits)
{
	return HAM_IGNORED
}
 
public simon_info(iPlayer)
{
	_debug("Info: %i %i %i %i", g_CtAlive, g_TtAlive, g_CtCount, g_TtCount)
	return PLUGIN_HANDLED
}
 
public simon_say(iPlayer)
{
	if(!is_user_alive(iPlayer) || (get_user_team(iPlayer) != _:CS_TEAM_CT))
		return PLUGIN_CONTINUE
 
	if(!g_Simon && g_Player[iPlayer][Mic])
		simon_select(iPlayer)

	return PLUGIN_HANDLED
}
 
public simon_nomic(iPlayer)
{
	if(!is_user_alive(iPlayer) || (get_user_team(iPlayer) != _:CS_TEAM_CT))
		return PLUGIN_CONTINUE
 
	cs_set_user_team(iPlayer, _:CS_TEAM_T)
	g_Player[iPlayer][Mic] = 0
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
stock _debug(const szFormat[], any:...)
{
#if defined DEBUG
	static szText[4096]
	vformat(szText, charsmax(szText), szFormat, 2)
	server_print("#DEBUG: %f - %s", halflife_time(), szText)
#endif
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
 
public simon_select(iPlayer)
{
	static szName[32]
	if(is_user_alive(iPlayer) && (get_user_team(iPlayer) == _:CS_TEAM_CT))
	{
		g_Simon = iPlayer
		get_user_name(iPlayer, szName, charsmax(szName))
		set_user_rendering(iPlayer, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
		set_hudmessage(255, 255, 255, -1.0, -1.0, 0, 0.0, 10.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(0, g_HudSync[2], "%s is Simon. All prisoners must follow his orders.", szName)
	}
}

public task_join(iTask)
{
	static iPlayer
	iPlayer = iTask - TASK_JOINTEAM
	force_team(iPlayer, _:CS_TEAM_T, 0, 0)
}

stock force_team(iPlayer, iTeam, iAlive, iRespawn)
{
	static iMsgBlock, iRestore, iVGUI

	if(!iAlive && g_Player[iPlayer][Msgid])
	{
		iRestore = get_pdata_int(iPlayer, 510)
		if(iVGUI)
			set_pdata_int(iPlayer, 510, iRestore & ~(1<<0)) 

		iMsgBlock = get_msg_block(g_Player[iPlayer][Msgid])
		set_msg_block(g_Player[iPlayer][Msgid], BLOCK_SET)
		dllfunc(DLLFunc_ClientPutInServer, iPlayer)
		engclient_cmd(iPlayer, "jointeam", _TeamStrings[iTeam])
		engclient_cmd(iPlayer, "joinclass", _TeamStrings[iTeam])
		set_msg_block(g_Player[iPlayer][Msgid], iMsgBlock)
		if(iVGUI)
			set_pdata_int(iPlayer, 510, iRestore)
	}
	else
	{
		cs_set_user_team(iPlayer, CsTeams:iTeam)
		cs_set_user_model(iPlayer, _TeamModels[iTeam])
		engclient_cmd(iPlayer, "joinclass", "5")
	}
	if(iRespawn)
		spawn(iPlayer)
}

public caca(id)
{
	new iteam = cs_get_user_team(id) == CS_TEAM_CT ? 1 : 2
	force_team(id, iteam, 1, 1)
	return PLUGIN_HANDLED
}
