#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>

#define PLUGIN_NAME	"No SpeedHack"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"JoRoPiTo"

#define	m_flNextPrimaryAttack	46
#define	m_flNextSecondaryAttack	47
#define	m_flTimeWeaponIdle	48

new const g_GunEvents[][] = {
	"events/awp.sc", "events/g3sg1.sc", "events/ak47.sc", "events/scout.sc", "events/m249.sc",
	"events/m4a1.sc", "events/sg552.sc", "events/aug.sc", "events/sg550.sc", "events/m3.sc",
	"events/xm1014.sc", "events/usp.sc", "events/mac10.sc", "events/ump45.sc", "events/fiveseven.sc",
	"events/p90.sc", "events/deagle.sc", "events/p228.sc", "events/glock18.sc", "events/mp5n.sc",
	"events/tmp.sc", "events/elite_left.sc", "events/elite_right.sc", "events/galil.sc", "events/famas.sc"
}

new Float:g_Attack[33]
new Float:g_Start[33][3]
new Float:g_End[33][3]
new Float:g_Last[33]
new g_Score[33]
new g_ForwardPrecacheEvent
new g_EventIds
new g_MaxClients

new gp_SpeedFactor
new gp_SpeedBanmode
new gp_SpeedBantime
new gp_SpeedBlock
new gp_SpeedScore

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("nospeedhack", PLUGIN_AUTHOR, FCVAR_SERVER|FCVAR_SPONLY)

	unregister_forward(FM_PrecacheEvent, g_ForwardPrecacheEvent, 1)
	gp_SpeedScore = register_cvar("amx_speed_score", "3")      // How many times should be detected to get banned
	gp_SpeedFactor = register_cvar("amx_speed_factor", "1.8")  // Maxspeed multiplier threshold to hack detection
	gp_SpeedBanmode = register_cvar("amx_speed_banmode", "0")  // Ban mode: 0=amx_banip / 1=amx_ban / 2=console log
	gp_SpeedBantime = register_cvar("amx_speed_bantime", "15") // Time for ban
	gp_SpeedBlock = register_cvar("amx_speed_block", "0")      // Block speedhack: 0=no block / 1=block

	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	register_forward(FM_PlaybackEvent, "player_attack")

	g_MaxClients = get_global_int(GL_maxClients)
}

public plugin_precache()
{
	g_ForwardPrecacheEvent = register_forward(FM_PrecacheEvent, "event_precache", 1)
}

public client_putinserver(id)
{
	g_Score[id] = 0
}

public event_precache(type, const name[])
{
	for(new i = 0; i < sizeof g_GunEvents; i++)
	{
		if(equal(g_GunEvents[i], name))
		{
			g_EventIds |= (1<<get_orig_retval())
			return FMRES_HANDLED
		}
	}
	return FMRES_IGNORED
}

public player_spawn(id)
{
	entity_get_vector(id, EV_VEC_origin, g_Start[id])
	g_Last[id] = halflife_time()
	g_Attack[id] = halflife_time()
	return HAM_IGNORED
}

public client_PostThink(id)
{
	if(!is_user_alive(id)) return PLUGIN_CONTINUE

	static Float:Aux
	Aux = halflife_time()
	if(Aux < (g_Last[id] + 1.0)) return PLUGIN_CONTINUE

	static Float:Distance
	static Float:Speed
	static Float:MaxSpeed
	static Float:FallSpeed
	static Float:BaseSpeed
	static Float:fAux[3]

	MaxSpeed = entity_get_float(id, EV_FL_maxspeed) * get_pcvar_float(gp_SpeedFactor)
	FallSpeed = entity_get_float(id, EV_FL_flFallVelocity)
	entity_get_vector(id, EV_VEC_basevelocity, fAux)
	BaseSpeed = vector_length(fAux)
	entity_get_vector(id, EV_VEC_origin, g_End[id])
	Distance = get_distance_f(g_Start[id], g_End[id])
	Speed = Distance / (Aux - g_Last[id])

	if((MaxSpeed > 150.0) && (Distance > 150.0) && (FallSpeed == 0) && (BaseSpeed == 0) && (Speed > MaxSpeed))
	{
		speed_detected(id, "running", Speed, MaxSpeed)
		g_Last[id] = Aux
		g_Start[id][0] = g_End[id][0]
		g_Start[id][1] = g_End[id][1]
		g_Start[id][2] = g_End[id][2]
		return get_pcvar_num(gp_SpeedBlock) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
	}
	
	g_Last[id] = Aux
	g_Start[id][0] = g_End[id][0]
	g_Start[id][1] = g_End[id][1]
	g_Start[id][2] = g_End[id][2]
	return PLUGIN_CONTINUE
}

public player_attack(flags, id, eventid)
{
	if (!(g_EventIds & (1<<eventid)) || !(1 <= id <= g_MaxClients))
		return FMRES_IGNORED

	static ent, weap, class[32]
	static Float:Aux
	Aux = halflife_time()
	weap = get_user_weapon(id)
	get_weaponname(weap, class, charsmax(class))
	ent = find_ent_by_owner(-1, class, id, 0)

	if(is_valid_ent(ent))
	{
		static Float:fNext
		fNext = get_pdata_float(ent, m_flNextPrimaryAttack, 4) * get_pcvar_float(gp_SpeedFactor)
		if((Aux - g_Attack[id]) < fNext)
		{
			speed_detected(id, "shooting", fNext, Aux - g_Attack[id])
			g_Attack[id] = Aux
			return get_pcvar_num(gp_SpeedBlock) ? FMRES_SUPERCEDE : FMRES_IGNORED
		}
	}
	g_Attack[id] = Aux
	return FMRES_IGNORED
}

public speed_detected(id, info[], Float:Speed, Float:MaxSpeed)
{
	static ip[32], name[32], minutes, userid, banmode
	minutes = get_pcvar_num(gp_SpeedBantime)
	get_user_name(id, name, charsmax(name))
	userid = get_user_userid(id)
	get_user_ip(id, ip, charsmax(ip))
	banmode = get_pcvar_num(gp_SpeedBanmode)

	g_Score[id]++
	if(g_Score[id] < get_pcvar_num(gp_SpeedScore))
		return

	server_print("Player %s using speedhack (%f %f) - %s @%s", name, Speed, MaxSpeed, info, ip)
	g_Score[id] = 0

	switch(banmode)
	{
		case 3:
		{
			server_cmd("amx_kick #%d ^"User kick for speedhack^"", userid)
			client_print(0, print_chat, "Player %s kick for speedhack", name)
		}
		case 2:
		{
			server_cmd("amx_banip #%d %i ^"User banned for speedhack^"", userid, minutes)
			client_print(0, print_chat, "Player %s banned for speedhack (%i minutes)", name, minutes)
		}
		case 1:
		{
			server_cmd("amx_ban #%d %i ^"User banned for speedhack^"", userid, minutes)
			client_print(0, print_chat, "Player %s banned for speedhack (%i minutes)", name, minutes)
		}
		default:
		{
			client_print(0, print_chat, "Player %s seems to be using speedhack (%s)", name, info)
		}
	}
}

