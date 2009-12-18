#include <bmfw>

#define	PLUGIN_NAME	"BM Bunny Hop"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw_bhop"

#define BM_FOV		180
#define BM_DEFAULTFOV	90
#define BM_COOLDOWN	30

new const g_Name[] = "Drug"
new const g_Model[] = "slap"
new const Float:g_Size[3] = { 10.0, 10.0, 10.0 }

new g_SetFOV

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	_reg_block(g_Name, g_Model, touch_foot, BM_COOLDOWN, g_Size, g_Size, g_Size)
	g_SetFOV = get_user_msgid("SetFOV")

}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
}

public block_Touch(touched, toucher)
{
	message_begin(MSG_ONE, g_SetFOV, {0, 0, 0}, toucher)
	write_byte(BM_FOV)
	message_end()
	set_task(30.0, "player_undrug", toucher)
	return PLUGIN_CONTINUE
}

public player_undrug(id)
{
	message_begin(MSG_ONE, g_SetFOV, {0, 0, 0}, id)
	write_byte(BM_DEFAULTFOV)
	message_end()
}
