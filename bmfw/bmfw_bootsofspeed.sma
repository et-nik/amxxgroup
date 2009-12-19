#include <bmfw>
#include <fun>

#define	PLUGIN_NAME	"BM Boots of Speed"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define	BM_COOLDOWN	30.0
#define	BM_SPEEDTIME	15.0
#define	BM_MAXSPEED	1500.0

new g_BlockId
new const g_Name[] = "Boots Of Speed"
new const g_Model[] = "bootsofspeed"

new const Float:g_Size[4] = { 64.0, 64.0, 8.0 }
new const Float:g_SizeSmall[4] = { 16.0, 16.0, 8.0 }
new const Float:g_SizeLarge[4] = { 128.0, 128.0, 8.0 }

new g_PlayerSpeed[32]

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
	if(!g_PlayerSpeed[toucher])
	{
		set_user_maxspeed(toucher, BM_MAXSPEED)
		g_PlayerSpeed[toucher] = 1
		_set_handler(toucher, g_BlockId, g_BlockId, hPlayerPreThink)
		set_task(BM_SPEEDTIME, "player_Unspeed", toucher)
	}
	return PLUGIN_CONTINUE
}

public block_PlayerPreThink(id)
{
	if(g_PlayerSpeed[id])
	{
		entity_set_float(id, EV_FL_fuser2, 0.0)
		set_user_maxspeed(id, BM_MAXSPEED)
	}
	return PLUGIN_CONTINUE
}

public player_Unspeed(id)
{
	set_user_maxspeed(id, 250.0)
	_set_handler(id, g_BlockId, -1, hPlayerPreThink)
	g_PlayerSpeed[id] = 0
	return PLUGIN_CONTINUE
}
