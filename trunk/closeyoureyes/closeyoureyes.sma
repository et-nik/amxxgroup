/*

Usage:

- bind any letter or button to +blink
	bind mouse3 +blink
- hold that button to close your eyes before get flashed!


Credits: Asd^ (testing and ideas)

*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME	"Close Your Eyes"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"jrpt"

#define FADE_IN		4
#define FADE_OUT	0
#define TASK_UNFLASH	19283746

new g_msg_screenfade
new g_closed_eyes[33]
new g_flashed[33]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	g_msg_screenfade = get_user_msgid("ScreenFade")

	register_clcmd("+blink", "close_eyes")
	register_clcmd("-blink", "open_eyes")
	register_message(g_msg_screenfade, "screen_fade")
}

public close_eyes(id)
{
	if(g_closed_eyes[id] || g_flashed[id])
		return PLUGIN_CONTINUE

	g_closed_eyes[id] = 1
	player_fade(id, FADE_IN)
	return PLUGIN_HANDLED
}

public open_eyes(id)
{
	if(!g_closed_eyes[id] || g_flashed[id])
		return PLUGIN_CONTINUE

	g_closed_eyes[id] = 0
	player_fade(id, FADE_OUT)
	return PLUGIN_HANDLED
}


public player_fade(id, flag)
{
	message_begin(MSG_ONE, g_msg_screenfade, _, id)
	write_short(9000)
	write_short(0)
	write_short(flag)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(250)
	message_end()
}

public screen_fade(msgid, dest, id)
{
	if(g_closed_eyes[id])
		return PLUGIN_HANDLED

	g_flashed[id] = 1
	new duration = get_msg_arg_int(1)
	new holdtime = get_msg_arg_int(2)
	new Float:tasktime = (float(duration) / 4096.0) - (float(holdtime) / 4096.0)
	remove_task(TASK_UNFLASH + id)
	set_task(tasktime, "player_unflash", TASK_UNFLASH + id)
	return PLUGIN_CONTINUE
}

public player_unflash(taskid)
{
	g_flashed[taskid - TASK_UNFLASH] = 0
}
