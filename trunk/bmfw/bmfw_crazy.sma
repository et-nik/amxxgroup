#include <bmfw>
#include <fun>

#define	PLUGIN_NAME	"BM Crazy"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"

#define	BM_COOLDOWN	25.0
#define	BM_CRAZYTIME	15.0
#define MODULATE	0x0002

new g_BlockId
new const g_Name[] = "Crazy"
new const g_Model[] = "gift"

new const Float:g_Size[4] = { 25.0, 25.0, 26.0 }
new const Float:g_SizeSmall[4] = { 25.0, 25.0, 26.0 }
new const Float:g_SizeLarge[4] = { 25.0, 25.0, 26.0 }

new g_Flash

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	g_BlockId = _reg_block(g_Name, PLUGIN_VERSION, g_Model, TOUCH_ALL, BM_COOLDOWN, g_Size, g_SizeSmall, g_SizeLarge)
	g_Flash = get_user_msgid("ScreenFade")
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, g_Model)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, g_Model)
}

public block_Touch(touched, toucher)
{
	_set_handler(toucher, g_BlockId, g_BlockId, hPlayerPreThink)
	set_task(BM_CRAZYTIME, "player_Uncrazy", toucher)
	return PLUGIN_CONTINUE
}

public block_PlayerPreThink(id)
{
	new r, g, b, a
	r = random(255)
	g = random(255)
	b = random(255)
	a = random_num(64, 192)
	message_begin(MSG_ONE_UNRELIABLE, g_Flash, _, id)
	write_short(1<<10)
	write_short(1<<10)
	write_short(MODULATE)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(a)
	message_end()

	return PLUGIN_CONTINUE
}

public player_Uncrazy(id)
{
	_set_handler(id, g_BlockId, -1, hPlayerPreThink)
	return PLUGIN_CONTINUE
}
