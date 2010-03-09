#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <fun>
#include <cstrike>
 
#define	PLUGIN_NAME	"JailBreak Extreme"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"1.1"
#define	PLUGIN_CVAR	"jbextreme"

#define TASK_STATUS	2487000

#define get_bit(%1,%2) 		( %1 &   1 << ( %2 & 31 ) )
#define set_bit(%1,%2)	 	%1 |=  ( 1 << ( %2 & 31 ) )
#define clear_bit(%1,%2)	%1 &= ~( 1 << ( %2 & 31 ) )

// Offsets
#define m_iPrimaryWeapon	116
#define m_iVGUI			510
 
enum _hud { _hudsync, Float:_x, Float:_y, Float:_time }

new gp_PrecacheSpawn
new gp_CrowbarMax
new gp_CrowbarMul
new gp_TeamRatio
new gp_CtMax
new gp_MaxDays
new gp_BoxMax
new gp_TalkMode
new gp_RetryTime

new g_MaxClients
new g_MsgStatusIcon
new g_MsgVGUIMenu
new g_MsgShowMenu
new g_MsgMOTD

// Precache
new const _FistModels[][] = { "models/p_bknuckles.mdl", "models/v_bknuckles.mdl" }
new const _CrowbarModels[][] = { "models/p_crowbar.mdl", "models/v_crowbar.mdl" }
new const _FistSounds[][] = { "weapons/cbar_hitbod2.wav", "weapons/cbar_hitbod1.wav", "weapons/bullet_hit1.wav", "weapons/bullet_hit2.wav" }
new const _RemoveEntities[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone", "func_buyzone"
}


// Reasons
new const g_Reasons[][] =  { "", "robbery", "kidnapping", "hijacking", "murder", "battery", "prostitution" }

// HudSync: 0=status / 1=messages / 2=skills / 3=alerts / 4=info
new const g_HudSync[][_hud] = { {0,  0.1,  0.3,  2.0}, {0, -1.0, 0.7,  5.0}, {0,  0.1, 0.2, 10.0}, {0, 0.2, 0.3, 10.0}, {0, -1.0, 0.9, 3.0} }

// UNASSIGNED / T / CT / SPECTATOR
//new const g_TeamColors[CsTeams][3] = { {0, 0, 0}, {255, 0, 0}, {0, 0, 255}, {0, 0, 0} }

// Status
new const g_ModeStatus[][] = { "disabled", "enabled" }

new g_PlayerDaysleft[33]
new g_PlayerReason[33]
new g_PlayerNomic
new g_PlayerWanted
new g_PlayerCrowbar
new g_PlayerRevolt
new g_TeamCount[CsTeams]
new g_TeamAlive[CsTeams]
new g_BoxStarted
new g_CrowbarCount
new g_Simon
new g_SimonTalking
new g_RoundStarted
 
public plugin_init()
{
	unregister_forward(FM_Spawn, gp_PrecacheSpawn)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	g_MsgStatusIcon = get_user_msgid("StatusIcon")
	g_MsgVGUIMenu = get_user_msgid("VGUIMenu")
	g_MsgShowMenu = get_user_msgid("ShowMenu")
	g_MsgMOTD = get_user_msgid("MOTD")

	register_message(g_MsgStatusIcon, "msg_statusicon")
	register_message(g_MsgVGUIMenu, "msg_vguimenu")
	register_message(g_MsgShowMenu, "msg_showmenu")
	register_message(g_MsgMOTD, "msg_motd")

	register_event("CurWeapon", "current_weapon", "be", "1=1", "2=29")
	register_event("StatusValue", "player_status", "be", "1=2", "2!0")
	register_event("StatusValue", "player_status", "be", "1=1", "2=0")

	register_impulse(100, "impulse_100")

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "player_damage")
	RegisterHam(Ham_TraceAttack, "player", "player_attack")
	RegisterHam(Ham_Killed, "player", "player_killed", 1)

	register_forward(FM_SetClientKeyValue, "set_client_kv")
	register_forward(FM_EmitSound, "sound_emit")
	register_forward(FM_Voice_SetClientListening, "voice_listening")

	register_logevent("round_end", 2, "1=Round_End")
	register_logevent("round_end", 2, "0=World triggered", "1&Restart_Round_")
	register_logevent("round_end", 2, "0=World triggered", "1=Game_Commencing")
	register_logevent("round_start", 2, "0=World triggered", "1=Round_Start")

	register_menucmd(register_menuid("#Team_Select"), 51, "team_select") 

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("joinclass", "cmd_joinclass")
	register_clcmd("+simonvoice", "cmd_voiceon")
	register_clcmd("-simonvoice", "cmd_voiceoff")

	register_clcmd("say /simon", "cmd_simon")
	register_clcmd("say /nomic", "cmd_nomic")
	register_clcmd("say /box", "cmd_box")
 
	gp_CrowbarMul = register_cvar("jbe_crowbarmultiplier", "25.0")
	gp_CrowbarMax = register_cvar("jbe_maxcrowbar", "1")
	gp_TeamRatio = register_cvar("jbe_teamratio", "3")
	gp_MaxDays = register_cvar("jbe_maxdays", "15")
	gp_CtMax = register_cvar("jbe_maxct", "7")
	gp_BoxMax = register_cvar("jbe_boxmax", "6")
	gp_RetryTime = register_cvar("jbe_retrytime", "10")
	gp_TalkMode = register_cvar("jbe_talkmode", "2")	// 0-alltak / 1-tt
 
	g_MaxClients = get_global_int(GL_maxClients)
 
	for(new i = 0; i < sizeof(g_HudSync); i++)
		g_HudSync[i][_hudsync] = CreateHudSyncObj()
}
 
public plugin_cfg()
{
	set_cvar_num("sv_alltalk", 1)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_friendlyfire", 1)
 
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

public precache_spawn(ent)
{
	if(is_valid_ent(ent))
	{
		static szClass[33]
		entity_get_string(ent, EV_SZ_classname, szClass, sizeof(szClass))
		for(new i = 0; i < sizeof(_RemoveEntities); i++)
			if(equal(szClass, _RemoveEntities[i]))
				remove_entity(ent)
	}
}

public client_putinserver(id)
{
	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerNomic, id)
	clear_bit(g_PlayerWanted, id)
	g_PlayerDaysleft[id] = 0
}
 
public msg_statusicon(msgid, dest, id)
{
	static icon[5] 
	get_msg_arg_string(2, icon, charsmax(icon))
	if(icon[0] == 'b' && icon[2] == 'y' && icon[3] == 'z')
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0))
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_vguimenu(msgid, dest, id)
{
	static msgarg1

	msgarg1 = get_msg_arg_int(1)
	if(msgarg1 == 2)
	{
		if(is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_T))
		{
			client_print(id, print_center, "You can't change team right now")
			return PLUGIN_HANDLED
		}
		show_menu(id, 51, "#Team_Select", -1)
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_showmenu(msgid, dest, id)
{
	static msgarg1
	msgarg1 = get_msg_arg_int(1)
	if(msgarg1 != 531)
		return PLUGIN_CONTINUE

	if(is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_T))
	{
		client_print(id, print_center, "You can't change team right now")
		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}

public msg_motd(msgid, dest, id)
{
	return PLUGIN_HANDLED
}

public current_weapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

	if(get_bit(g_PlayerCrowbar, id))
	{
		set_pev(id, pev_viewmodel2, _CrowbarModels[1])
		set_pev(id, pev_weaponmodel2, _CrowbarModels[0])
	}
	else
	{
		set_pev(id, pev_viewmodel2, _FistModels[1])
		set_pev(id, pev_weaponmodel2, _FistModels[0])
	}
	return PLUGIN_CONTINUE
}

public player_status(id)
{
	static type, player, CsTeams:team, name[32], health
	type = read_data(1)
	player = read_data(2)
	switch(type)
	{
		case(1):
		{
			ClearSyncHud(id, g_HudSync[1][_hudsync])
		}
		case(2):
		{
			team = cs_get_user_team(player)
			if((team != CS_TEAM_T) && (team != CS_TEAM_CT))
				return PLUGIN_HANDLED

			health = get_user_health(player)
			get_user_name(player, name, charsmax(name))
			player_hudmessage(id, 4, 3.0, {0, 255, 0},
				(team == CS_TEAM_T) ? "Prisoner: %s - %i%" : "Guard: %s - %i%", name, health)
		}
	}
	
	return PLUGIN_HANDLED
}

public impulse_100(id)
{
	if(cs_get_user_team(id) == CS_TEAM_T)
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

public player_spawn(id)
{
	static CsTeams:team

	if(!is_user_alive(id))
		return HAM_IGNORED

	set_user_rendering(id, 255, 255, 255, 16, kRenderFxNone, kRenderNormal)
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
	set_pdata_int(id, m_iPrimaryWeapon, 0)

	clear_bit(g_PlayerCrowbar, id)
	clear_bit(g_PlayerWanted, id)
	team = cs_get_user_team(id)
	switch(team)
	{
		case(CS_TEAM_T):
		{
			
			player_hudmessage(id, 2, _, _, "You have %i days left. ^nYou're in jail for %s",
				g_PlayerDaysleft[id], g_Reasons[g_PlayerReason[id]])
			g_PlayerDaysleft[id]--
			set_bit(g_TeamAlive[CS_TEAM_T], id)
			set_user_info(id, "model", "wiezien")
			if(g_CrowbarCount < get_pcvar_num(gp_CrowbarMax))
			{
				if(random_num(0, g_MaxClients) > (g_MaxClients / 2))
				{
					g_CrowbarCount++
					set_bit(g_PlayerCrowbar, id)
				}
			}
		}
		case(CS_TEAM_CT):
		{
			set_bit(g_TeamAlive[CS_TEAM_CT], id)
			set_user_info(id, "model", "straznik")
		}
	}
	return HAM_IGNORED
}

public player_damage(victim, ent, attacker, Float:damage, bits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(get_user_weapon(attacker) == CSW_KNIFE && get_bit(g_PlayerCrowbar, attacker))
	{
		SetHamParamFloat(4, damage * get_pcvar_float(gp_CrowbarMul))
		return HAM_OVERRIDE
	}

	return HAM_IGNORED
}

public player_attack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagebits)
{
	static CsTeams:vteam, CsTeams:ateam
	vteam = cs_get_user_team(victim)
	ateam = cs_get_user_team(attacker)

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_CT)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_CT && vteam == CS_TEAM_T)
	{
		if(get_bit(g_PlayerRevolt, victim))
		{
			clear_bit(g_PlayerRevolt, victim)
			hud_status(0)
		}
		return HAM_IGNORED
	}

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_T && !g_BoxStarted)
		return HAM_SUPERCEDE

	if(ateam == CS_TEAM_T && vteam == CS_TEAM_CT)
	{
		if(!g_PlayerRevolt)
			revolt_start()

		set_bit(g_PlayerRevolt, attacker)
	}

	return HAM_IGNORED
}

public player_killed(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	switch(team)
	{
		case(CS_TEAM_CT):
		{
			team_count()
			if(g_TeamCount[CS_TEAM_CT] > ctcount_allowed())
				cs_set_user_team(id, CS_TEAM_T)

			if(g_Simon == id)
			{
				g_Simon = 0
				ClearSyncHud(0, g_HudSync[2][_hudsync])
				player_hudmessage(0, 2, 5.0, _, "Simon was killed. Another guard should take his job")
			}
		}
		case(CS_TEAM_T):
		{
			clear_bit(g_PlayerRevolt, id)
		}
	}
}

public set_client_kv(id, const info[], const key[])
{
	if(equal(key, "model"))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}

public sound_emit(id, channel, sample[])
{
	if(is_user_alive(id) && equal(sample, "weapons/knife_", 14))
	{
		switch(sample[17])
		{
			case('b'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			case('w'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/cbar_hitbod1.wav", 1.0, ATTN_NORM, 0, PITCH_LOW)
			}
			case('1', '2'):
			{
				emit_sound(id, CHAN_WEAPON, "weapons/bullet_hit2.wav", random_float(0.5, 1.0), ATTN_NORM, 0, PITCH_NORM)
			}
		}
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public voice_listening(receiver, sender, bool:listen)
{
	if(!is_user_connected(receiver) || !is_user_connected(sender) || (receiver == sender) || (sender == g_Simon) || is_user_admin(sender))
		return FMRES_IGNORED
 
	if(g_SimonTalking && (sender != g_Simon))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	else if((get_pcvar_num(gp_TalkMode) == 1) && (get_user_team(sender) == _:CS_TEAM_T) && (get_user_team(receiver) == _:CS_TEAM_CT))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	else if((get_pcvar_num(gp_TalkMode) == 2) && !is_user_alive(sender))
	{
		engfunc(EngFunc_SetClientListening, receiver, sender, false)
		return FMRES_SUPERCEDE
	}
	
 
	return FMRES_IGNORED
}

public round_end()
{
	new CsTeams:team
	g_PlayerRevolt = 0
	g_BoxStarted = 0
	g_CrowbarCount = 0
	g_Simon = 0
	g_RoundStarted = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0

	remove_task(TASK_STATUS)
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(!is_user_connected(i))
			continue

		team = cs_get_user_team(i)
		if((team == CS_TEAM_T) && (g_PlayerDaysleft[i] <= 0))
		{
			g_PlayerDaysleft[i] = random_num(4, get_pcvar_num(gp_MaxDays))
			g_PlayerReason[i] = random_num(1, 6)
			continue
		}
	}
	for(new i = 0; i < sizeof(g_HudSync); i++)
		ClearSyncHud(0, g_HudSync[i][_hudsync])
}

public round_start()
{
	set_task(2.0, "hud_status", TASK_STATUS, _, _, "b")
}

public cmd_jointeam(id)
{
	return PLUGIN_HANDLED
}

public cmd_joinclass(id)
{
	return PLUGIN_HANDLED
}

public cmd_voiceon(id)
{
	client_cmd(id, "+voicerecord")
	if(g_Simon != id)
		return PLUGIN_HANDLED
 
	g_SimonTalking = 1
	return PLUGIN_HANDLED
}

public cmd_voiceoff(id)
{
	client_cmd(id, "-voicerecord")
	if(g_Simon != id)
		return PLUGIN_HANDLED
 
	g_SimonTalking = 0
	return PLUGIN_HANDLED
}

public cmd_simon(id)
{
	static CsTeams:team, name[32]
	team = cs_get_user_team(id)
	if(is_user_alive(id) && team == CS_TEAM_CT && !g_Simon)
	{
		g_Simon = id
		get_user_name(id, name, charsmax(name))
		set_user_rendering(id, kRenderFxGlowShell, 0, 255, 0, kRenderNormal, 20)
		hud_status(0)
	}
	return PLUGIN_HANDLED
}

public cmd_nomic(id)
{
	static CsTeams:team, alive
	team = cs_get_user_team(id)
	if(team == CS_TEAM_CT)
	{
		if(g_Simon == id)
		{
			g_Simon = 0
			player_hudmessage(0, 0, 5.0, _, "Simon was transfered to prisoners team.^nAnother guard should take his job")
		}
		alive = is_user_alive(id)
		cs_set_user_team(id, CS_TEAM_T)
		if(alive)
			spawn(id)
	}
	return PLUGIN_HANDLED
}

public cmd_box(id)
{
	static CsTeams:team
	team = cs_get_user_team(id)
	if(is_user_alive(id) && team == CS_TEAM_CT)
	{
		team_count()
		if(g_TeamCount[CS_TEAM_T] <= get_pcvar_num(gp_BoxMax))
		{
			g_BoxStarted = 1
			player_hudmessage(0, 1, 3.0, _, "Box mod %s", g_ModeStatus[g_BoxStarted])
		}
		else
		{
			player_hudmessage(id, 1, 3.0, _, "You can't start box mode. Too many prisoners.")
		}
	}
	return PLUGIN_HANDLED
}

public team_select(id, key)
{
	static CsTeams:team

	team = cs_get_user_team(id)
	team_count()

	if((g_RoundStarted >= (get_pcvar_num(gp_RetryTime) / 2)) && g_TeamCount[CS_TEAM_CT] && g_TeamCount[CS_TEAM_T] && !is_user_alive(id))
	{
		client_print(id, print_center, "You can't join while in game")
		return PLUGIN_HANDLED
	}

	switch(key)
	{
		case(0):
		{
			if(team == CS_TEAM_T)
				return PLUGIN_HANDLED

			g_PlayerDaysleft[id] = random_num(4, get_pcvar_num(gp_MaxDays))
			g_PlayerReason[id] = random_num(1, 6)

			team_join(id, CS_TEAM_T)
		}
		case(1):
		{
			if(team == CS_TEAM_CT)
				return PLUGIN_HANDLED

			if(g_TeamCount[CS_TEAM_CT] < ctcount_allowed())
				team_join(id, CS_TEAM_CT)
			else
				client_print(id, print_center, "There's too much CTs")
		}
	}
	return PLUGIN_HANDLED
}

public team_join(id, CsTeams:team)
{
	static restore, vgui, msgblock

	restore = get_pdata_int(id, m_iVGUI)
	vgui = restore & (1<<0)
	if(vgui)
		set_pdata_int(id, m_iVGUI, restore & ~(1<<0))

	msgblock = get_msg_block(g_MsgShowMenu)
	set_msg_block(g_MsgShowMenu, BLOCK_ONCE)
	engclient_cmd(id, "jointeam", (team == CS_TEAM_T) ? "1" : "2")
	engclient_cmd(id, "joinclass", "1")
	set_msg_block(g_MsgShowMenu, msgblock)

	if(vgui)
		set_pdata_int(id, m_iVGUI, restore)
}

public team_count()
{
	static CsTeams:team
	g_TeamCount[CS_TEAM_UNASSIGNED] = 0
	g_TeamCount[CS_TEAM_T] = 0
	g_TeamCount[CS_TEAM_CT] = 0
	g_TeamCount[CS_TEAM_SPECTATOR] = 0
	g_TeamAlive[CS_TEAM_UNASSIGNED] = 0
	g_TeamAlive[CS_TEAM_T] = 0
	g_TeamAlive[CS_TEAM_CT] = 0
	g_TeamAlive[CS_TEAM_SPECTATOR] = 0
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(is_user_connected(i))
		{
			team = cs_get_user_team(i)
			g_TeamCount[team]++
			if(is_user_alive(i))
				set_bit(g_TeamAlive[team], i)
			else
				clear_bit(g_TeamAlive[team], i)
		}
	}
}

public revolt_start()
{
	client_cmd(0,"speak ambience/siren")
	set_task(8.0, "stop_sound")
	hud_status(0)
}

public stop_sound(task)
{
	client_cmd(0, "stopsound")
}

public hud_status(task)
{
	static szStatus[32], alive, i, name[32]
 
	if(g_RoundStarted < (get_pcvar_num(gp_RetryTime) / 2))
		g_RoundStarted++

	team_count()
	alive = 0
	for(i = 0; i < g_MaxClients; i++)
	{
		alive += get_bit(g_TeamAlive[CS_TEAM_T], i) ? 1 : 0
	}

	formatex(szStatus, charsmax(szStatus), "Prisoners: %i Alive / %i Total", alive, g_TeamCount[CS_TEAM_T])
	message_begin(MSG_BROADCAST, get_user_msgid("StatusText"), {0,0,0}, 0)
	write_byte(0)
	write_string(szStatus)
	message_end()

	if(g_Simon)
	{
		get_user_name(g_Simon, name, charsmax(name))
		player_hudmessage(0, 2, 2.0, {0, 255, 0}, "%s is Simon. All prisoners must follow his orders", name)
	}
	if(g_PlayerRevolt)
	{
		player_hudmessage(0, 3, 3.0, {255, 25, 50}, "Prisoners started revolt!")
	}
}

stock is_user_admin(id)
{
	static __flags
	__flags = get_user_flags(id);
	return (__flags>0 && !(__flags&ADMIN_USER));
}

stock ctcount_allowed()
{
	static count
	count = (get_playersnum() / get_pcvar_num(gp_TeamRatio))
	if(count < 2)
		count = 2
	else if(count > get_pcvar_num(gp_CtMax))
		count = get_pcvar_num(gp_CtMax)

	return count
}

stock player_hudmessage(id, hudid, Float:time = 0.0, color[3] = {0, 255, 0}, msg[128], any:...)
{
	static text[128], Float:x, Float:y
	x = g_HudSync[hudid][_x]
	y = g_HudSync[hudid][_y]
	
	if(time <= 0)
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.01, time, 0.01, 0.01, 1)
	else
		set_hudmessage(color[0], color[1], color[2], x, y, 0, 0.01, g_HudSync[hudid][_time], 0.01, 0.01, 1)

	vformat(text, charsmax(text), msg, 6)
	ShowSyncHudMsg(id, g_HudSync[hudid][_hudsync], text)
}

