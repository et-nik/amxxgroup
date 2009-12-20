#include <bmfw>
#include <fun>

#define	PLUGIN_NAME	"BM Death"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define BM_COOLDOWN	-1.0

new const g_Name[] = "Death"
new const g_Model[] = "death"

new const Float:g_Size[4] = { 64.0, 64.0, 8.0 }
new const Float:g_SizeSmall[4] = { 16.0, 16.0, 8.0 }
new const Float:g_SizeLarge[4] = { 128.0, 128.0, 8.0 }

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	_reg_block(g_Name, PLUGIN_VERSION, g_Model, TOUCH_FOOT, BM_COOLDOWN, g_Size, g_SizeSmall, g_SizeLarge)
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
}

public block_Touch(touched, toucher)
{
	user_kill(toucher)
	return PLUGIN_CONTINUE
}
