#include <amxmodx>
#include <engine>
#include <hamsandwich>

#define PLUGIN_NAME	"No SpeedHack"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"JoRoPiTo"

new Float:g_Start[33][3]
new Float:g_End[33][3]
new Float:g_Last[33]

new gp_SpeedFactor
new gp_SpeedBanmode
new gp_SpeedBantime

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("nospeedhack", PLUGIN_AUTHOR, FCVAR_SERVER|FCVAR_SPONLY)

	gp_SpeedFactor = register_cvar("amx_speed_factor", "1.5")
	gp_SpeedBanmode = register_cvar("amx_speed_banmode", "2")
	gp_SpeedBantime = register_cvar("amx_speed_bantime", "15")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1);
}

public player_spawn(id)
{
	entity_get_vector(id, EV_VEC_origin, g_Start[id])
	g_Last[id] = halflife_time()
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

	if((Distance > 150.0) && (FallSpeed == 0) && (BaseSpeed == 0) && (Speed > MaxSpeed))
		speed_detected(id, Speed, MaxSpeed)

	g_Last[id] = Aux
	g_Start[id][0] = g_End[id][0]
	g_Start[id][1] = g_End[id][1]
	g_Start[id][2] = g_End[id][2]
	return PLUGIN_CONTINUE
}

public speed_detected(id, Float:Speed, Float:MaxSpeed)
{
	static name[32], minutes, userid, banmode
	minutes = get_pcvar_num(gp_SpeedBantime)
	get_user_name(id, name, charsmax(name))
	userid = get_user_userid(id)
	banmode = get_pcvar_num(gp_SpeedBanmode)
	switch(banmode)
	{
		case 2:
		{
			server_print("Player %s using speedhack (%f %f)", name, Speed, MaxSpeed)
		}
		case 1:
		{
			server_cmd("amx_ban #%d %i ^"User banned for speedhack^"", userid, minutes)
			client_print(0, print_chat, "Player %s banned for speedhack (%i minutes)", name, minutes)
		}
		default:
		{
			server_cmd("amx_banip #%d %i ^"User banned for speedhack^"", userid, minutes)
			client_print(0, print_chat, "Player %s banned for speedhack (%i minutes)", name, minutes)
		}
	}
}
