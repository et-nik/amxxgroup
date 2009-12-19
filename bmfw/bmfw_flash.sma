#include <bmfw>

#define	PLUGIN_NAME	"BM Flash"
#define	PLUGIN_AUTHOR	"Asd'"
#define	PLUGIN_VERSION	"0.1"

#define	FADE_IN		0x0000
#define	BM_COOLDOWN	10.0

new const NameBlock[] = "Flash"
new const ModelBlock[] = "random"
new Float:SizeBlock[3] = { 10.0, 10.0, 10.0 }

new Flash

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	_reg_block(NameBlock, PLUGIN_VERSION, ModelBlock, TOUCH_FOOT, BM_COOLDOWN, SizeBlock, SizeBlock, SizeBlock)
	Flash = get_user_msgid("ScreenFade")
	
}

public plugin_precache()
{
	bm_precache_model("%s%s.mdl", BM_BASEFILE, ModelBlock)
	bm_precache_model("%s%s_large.mdl", BM_BASEFILE, ModelBlock)
	bm_precache_model("%s%s_small.mdl", BM_BASEFILE, ModelBlock)
}

public block_Touch(Touched, Toucher)
{
	message_begin(MSG_ONE_UNRELIABLE, Flash , _, Toucher)
	write_short(1<<14)
	write_short(1<<14)
	write_short(FADE_IN)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	message_end()
	return PLUGIN_CONTINUE
}
