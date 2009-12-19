#include <bmfw>

#define	PLUGIN_NAME	"BM Bunny Hop"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define BHOP_VELOCITY	250.0
#define BM_COOLDOWN	-1.0

new g_BlockId = -1
new const g_Name[] = "Auto Bunny-Hop"
new const g_Model[] = "autobhop"

new const Float:g_Size[4] = { 64.0, 64.0, 8.0 }
new const Float:g_SizeSmall[4] = { 16.0, 16.0, 8.0 }
new const Float:g_SizeLarge[4] = { 128.0, 128.0, 8.0 }

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	g_BlockId = _reg_block(g_Name, PLUGIN_VERSION, g_Model, TOUCH_FOOT, BM_COOLDOWN, g_Size, g_SizeSmall, g_SizeLarge)
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
}

public block_Touch(touched, toucher)
{
	_set_handler(toucher, g_BlockId, g_BlockId, hPlayerPreThink)
	return PLUGIN_CONTINUE
}

public block_PlayerPreThink(id)
{
	new Float:velocity[3]
	entity_get_vector(id, EV_VEC_velocity, velocity)
	velocity[2] += (velocity[2] >= 0.0) ? BHOP_VELOCITY : (BHOP_VELOCITY - velocity[2])
	entity_set_vector(id, EV_VEC_velocity, velocity)
	_set_handler(id, g_BlockId, -1, hPlayerPreThink)
	return PLUGIN_CONTINUE
}

public block_Spawn(ent)
{
	server_print("New block created!!! %i", ent)
	return PLUGIN_CONTINUE
}
