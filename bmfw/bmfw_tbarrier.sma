#include <bmfw>

#define	PLUGIN_NAME	"BM CT Barrier"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw_tbarrier"

#define BM_CLIPTIME	1.5

new const g_Name[] = "T Barrier"
new const g_Model[] = "barrier_t"
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

public block_Touch(touched, toucher)
{
	if((get_user_team(toucher) == 1) && !entity_get_int(touched, EV_INT_iuser4))
	{
		entity_set_int(touched, EV_INT_iuser4, 1)
		entity_set_float(touched, EV_FL_nextthink, halflife_time() + 0.1)
	}
	return PLUGIN_CONTINUE
}

public block_Think(ent)
{
	if(entity_get_int(ent, EV_INT_iuser4) == 1)
	{
		set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransAdd, 25)
		entity_set_int(ent, EV_INT_solid, SOLID_NOT)
		entity_set_int(ent, EV_INT_iuser4, 2)
		entity_set_float(ent, EV_FL_nextthink, halflife_time() + BM_CLIPTIME)
	}
	else
	{
		set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderNormal, 0)
		entity_set_int(ent, EV_INT_iuser4, 0)
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
	}
	return PLUGIN_HANDLED
}
