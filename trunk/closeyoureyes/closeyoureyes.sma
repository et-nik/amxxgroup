/*

*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME	"Close Your Eyes"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"jrpt"

#define TASK_OPENEYES	918273

new gp_closedtime
new g_msg_screenfade
new g_closed_eyes[33]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	gp_closedtime = register_cvar("cye_closedtime", "1.5")
	g_msg_screenfade = get_user_msgid("ScreenFade")

	register_clcmd("say /blink", "close_eyes")
	register_message(g_msg_screenfade, "screen_fade")
}

public close_eyes(id)
{
	g_closed_eyes[id] = 1
	set_task(get_pcvar_float(gp_closedtime), "open_eyes", TASK_OPENEYES + id)
	return PLUGIN_HANDLED
}

public open_eyes(taskid)
{
	g_closed_eyes[taskid - TASK_OPENEYES] = 0
}

public screen_fade(msgid, dest, id)
{
	if(g_closed_eyes[id])
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}
