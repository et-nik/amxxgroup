#include <bmfw>

#define	PLUGIN_NAME	"BM Glass"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define BM_COOLDOWN	0.5
#define BM_GLASSHEALTH	350.0
#define BM_DAMAGESTEP	10.0

new const g_Name[] = "Glass"
new const g_Model[] = "glass"

new const Float:g_Size[4] = { 64.0, 64.0, 8.0 }
new const Float:g_SizeSmall[4] = { 16.0, 16.0, 8.0 }
new const Float:g_SizeLarge[4] = { 128.0, 128.0, 8.0 }

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	_reg_block(g_Name, PLUGIN_VERSION, g_Model, TOUCH_FOOT, BM_COOLDOWN, g_Size, g_SizeSmall, g_SizeLarge)

//	register_event("TextMsg", "round_Start", "a", "2&#Game_C", "2&#Game_w")
	register_logevent("round_Start", 2, "1=Round_Start")
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
}

public block_Touch(touched, toucher)
{
	ExecuteHamB(Ham_TakeDamage, touched, toucher, toucher, BM_DAMAGESTEP, DMG_CRUSH)
	return PLUGIN_CONTINUE
}

public block_Spawn(ent)
{
	entity_set_float(ent, EV_FL_takedamage, 1.0)
	entity_set_float(ent, EV_FL_health, BM_GLASSHEALTH)
	set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransColor, 50)
	return PLUGIN_CONTINUE
}

public round_Start()
{
	new ent
	new name[32]
	while((ent = find_ent_by_class(ent, BM_CLASSNAME)))
	{
		if(!is_valid_ent(ent)) continue

		entity_get_string(ent, EV_SZ_netname, name, charsmax(name))
		if(equal(g_Name, name))
		{
			entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
			entity_set_int(ent, EV_INT_effects, 0)
			entity_set_int(ent, EV_INT_deadflag, DEAD_NO)
			entity_set_float(ent, EV_FL_health, BM_GLASSHEALTH)
			entity_set_float(ent, EV_FL_takedamage, 1.0)
			set_rendering(ent, kRenderFxNone, 255, 255, 255, kRenderTransColor, 50)
		}
	}
	return PLUGIN_CONTINUE
}
