#include <bmfw>

#define	PLUGIN_NAME	"BM Flash"
#define	PLUGIN_AUTHOR	"Asd'"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw_flash"

#define	FADE_IN		0x0000
#define	BM_FLASHTIME	10.0

new NameBlock[] = "Flash"
new ModelBlock[] = "random"
new Float:SizeBlock[3] = { 10.0, 10.0, 10.0 }

new Flash
new Float:UserTime[32]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	_reg_block(NameBlock, ModelBlock, 3, SizeBlock, SizeBlock, SizeBlock)
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
	new Float:Now = halflife_time()
	if(UserTime[Toucher] < (Now - BM_FLASHTIME))
	{
		UserTime[Toucher] = Now
		message_begin(MSG_ONE_UNRELIABLE, Flash , _, Toucher)
		write_short(1<<14)
		write_short(1<<14)
		write_short(FADE_IN)
		write_byte(255)
		write_byte(255)
		write_byte(255)
		write_byte(255)
		message_end()
	}
	return PLUGIN_CONTINUE
}
