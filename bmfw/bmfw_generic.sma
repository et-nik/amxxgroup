#include <bmfw>

#define	PLUGIN_NAME	"BM Generic"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define	BM_COOLDOWN	9999.0

new const g_Name[] = "Generic"
new const g_Model[] = "default"
new Float:SizeBlock[3] = { 10.0, 10.0, 10.0 }

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	_reg_block(g_Name, PLUGIN_VERSION, g_Model, TOUCH_FOOT, BM_COOLDOWN, SizeBlock, SizeBlock, SizeBlock)
	
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
}
