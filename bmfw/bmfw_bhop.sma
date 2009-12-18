#include <bmfw>

#define	PLUGIN_NAME	"BM Bunny Hop"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw_bhop"

#define BHOP_VELOCITY	250.0

new const g_Name[] = "Auto Bunny-Hop"
new const g_Model[] = "autobhop"
new const Float:g_Size[3] = { 10.0, 10.0, 10.0 }

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	_reg_block(g_Name, g_Model, -1, g_Size, g_Size, g_Size)
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
}

public block_PlayerPreThink(id)
{
	new Float:velocity[3]
	entity_get_vector(id, EV_VEC_velocity, velocity)
	velocity[2] += (velocity[2] >= 0.0) ? BHOP_VELOCITY : (BHOP_VELOCITY - velocity[2])
	entity_set_vector(id, EV_VEC_velocity, velocity)
	dllfunc(DLLFunc_PlayerPreThink, id)
	return PLUGIN_CONTINUE
}

public block_Spawn(ent)
{
	server_print("New block created!!! %i", ent)
	return PLUGIN_CONTINUE
}
