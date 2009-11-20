/*

--- multimod.ini ---
[Gun Game]:[gungame-plugins.ini]:[gungame-config.cfg]
[Paint Ball]:[paintball-plugins.ini]:[paintball-config.cfg]
[Hid'N Seek]:[hns-plugins.ini]:[hns-config.cfg]
[Death Run]:[deathrun-plugins.ini]:[deathrun-config.cfg]
[Zombie Plague]:[zombieplague-plugins.ini]:[zombieplague-config.cfg]
[Biohazard]:[biohazard-plugins.ini]:[biohazard-config.cfg]
--------------------

TODO
* add some commands for admins

v0.1
* The very first release
v0.2
* Fixed warning 204 with one unused symbol
v0.3
* Fixed wrong use of cvar amx_nextmod instead of amx_mm_nextmod
* Added admin command amx_votemod
v0.4
* Added hud message every 15 seconds to display current mod name
* Added check for connected players before mod votting
* Added control to remove task avoiding duplicate amx_votemod commands
v0.5
* Added say nextmod command
* Added say /votemod command
* Execute cfg files in first round instead of game_commencing
v0.6
* Added multilangual support (thanks crazyeffect!)
* Added intermission at map change to show scoreboard
* Added timer to execute *.cfg
* Modified where I do sv_restart
* Deleted unused cvar amx_mm_nextmap
* Changed cvar amx_mm_nextmod to amx_nextmod
v0.8
* Added 30 seconds of warmup to avoid conflict/crash with other plugins
* Changed all cvars to amx_xxx format (removed _mm_ part)
* Fixed and improved pcvar usage
v2.0
* Removed a lot of code
* Removed map voting code
* Added compatibility with galileo
* Added semi-compatibility with mapchooser (requires mapchooser patch)

Credits:

fysiks: The first to realize the idea and some code improvements
crazyeffect: colaborate with multilangual support

*/

#include <amxmodx>
#include <amxmisc>

#define PLUGIN_NAME	"MultiMod Manager"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"2.0"

#define AMX_MULTIMOD	"amx_multimod"
#define AMX_PLUGINS	"amxx_plugins"
#define AMX_MAPCYCLE	"mapcyclefile"
#define AMX_LASTCYCLE	"lastmapcycle"

#define AMX_DEFAULTCYCLE	"mapcycle.txt"
#define AMX_DEFAULTPLUGINS	"addons/amxmodx/configs/plugins.ini"
#define	AMX_BASEMAPFILES	"multimod"

#define TASK_VOTEMOD 2487002
#define TASK_CHVOMOD 2487004
#define MAXMODS 10
#define LSTRING 193
#define SSTRING 33

new g_votemodcount[MAXMODS]
new g_modnames[MAXMODS][SSTRING]	// Per-mod Mod Names
new g_fileconf[MAXMODS][LSTRING]	// Per-mod Configuration Files
new g_filemaps[MAXMODS][LSTRING]	// Per-mod Maps Files
new g_fileplugins[MAXMODS][LSTRING]	// Per-mod Plugin Files

new g_alreadyvoted
new g_coloredmenus
new g_modcount = -1			// integer with configured mods count
new g_currentmodid
new g_multimod[SSTRING]
new g_nextmap[SSTRING]
new g_currentmod[SSTRING]
new g_confdir[LSTRING]

new gp_mintime
new gp_voteanswers
new gp_timelimit

new gp_mode
new gp_mapcyclefile

// galileo specific cvars
new gp_galileo_nommapfile
new gp_galileo_votemapfile

public plugin_init()
{
	new MenuName[SSTRING]

	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar("MultiModManager", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	register_dictionary("mapchooser.txt")
	register_dictionary("multimod.txt")
	
	gp_mode = register_cvar("amx_multimod_mode", "0")	// 0=auto ; 1=mapchooser ; 2=galileo
	gp_mintime = register_cvar("amx_mintime", "10")

	get_configsdir(g_confdir, charsmax(g_confdir))

//	register_clcmd("amx_votemod", "mmVoteMod", ADMIN_MAP, "Vote for the next mod")
//	register_clcmd("say nextmod", "user_votemod")
	register_clcmd("say /votemod", "user_votemod")
	register_clcmd("say_team /votemod", "user_votemod")

	format(MenuName, charsmax(MenuName), "%L", LANG_PLAYER, "CHOOSE_NEXTM")
	register_menucmd(register_menuid("Vote Nextmod"), 1023, "player_vote")
	g_coloredmenus = colored_menus()
}

public plugin_cfg()
{
	gp_voteanswers = get_cvar_pointer("amx_vote_answers")
	gp_timelimit = get_cvar_pointer("mp_timelimit")
	gp_mapcyclefile = get_cvar_pointer(AMX_MAPCYCLE)

	if(!get_pcvar_num(gp_mode))
	{
		if(is_plugin_loaded("mapchooser"))
			set_pcvar_num(gp_mode, 1)
		else if(is_plugin_loaded("galileo"))
			set_pcvar_num(gp_mode, 2)
	}
	get_localinfo(AMX_MULTIMOD, g_multimod, charsmax(g_multimod))
	load_cfg()
	if(!equal(g_currentmod, g_multimod) || (g_multimod[0] == 0))
	{
		set_multimod(0)
		get_firstmap(0)
		server_print("Server restart - First Run")
		server_cmd("changelevel %s", g_nextmap)
	}
	
}

public load_cfg()
{
	new szData[LSTRING]
	new szFilename[LSTRING]

	formatex(szFilename, charsmax(szFilename), "%s/%s", g_confdir, "multimod.ini")

	new f = fopen(szFilename, "rt")
	new szTemp[SSTRING],szModName[SSTRING], szTag[SSTRING], szCfg[SSTRING]
	while(!feof(f)) {
		fgets(f, szData, charsmax(szData))
		trim(szData)
		if(!szData[0] || szData[0] == ';' || (szData[0] == '/' && szData[1] == '/')) continue

		if(szData[0] == '[') {
			g_modcount++
			replace_all(szData, charsmax(szData), "[", "")
			replace_all(szData, charsmax(szData), "]", "")

			strtok(szData, szModName, charsmax(szModName), szTemp, charsmax(szTemp), ':', 0)
			strtok(szTemp, szTag, charsmax(szTag), szCfg, charsmax(szCfg), ':', 0)

			if(equal(szModName, g_multimod)) {
				copy(g_currentmod, charsmax(g_currentmod), szModName)
				g_currentmodid = g_modcount
				server_print("[AMX MultiMod] %L", LANG_PLAYER, "MM_WILL_BE", g_multimod, szTag, szCfg)
			}
			formatex(g_modnames[g_modcount], 32, "%s", szModName)
			formatex(g_filemaps[g_modcount], 192, "%s/%s-maps.ini", AMX_BASEMAPFILES, szTag)
			formatex(g_fileplugins[g_modcount], 192, "%s/%s-plugins.ini", g_confdir, szTag)
			formatex(g_fileconf[g_modcount], 192, "%s/%s", g_confdir, szCfg)
			server_print("MOD Loaded: %s %s %s", g_modnames[g_modcount], g_filemaps[g_modcount], g_fileconf[g_modcount])
		}
	}
	fclose(f)
	set_task(10.0, "check_task", TASK_VOTEMOD, "", 0, "b")
}

public get_firstmap(modid)
{
	new ilen

	if(!file_exists(g_filemaps[modid]))
		get_mapname(g_nextmap, charsmax(g_nextmap))
	else
		read_file(g_filemaps[modid], 0, g_nextmap, charsmax(g_nextmap), ilen)
}

public set_multimod(modid)
{
	set_localinfo("amx_multimod", g_modnames[modid])
	server_cmd("localinfo amxx_plugins ^"^"")
	server_cmd("localinfo lastmapcycle ^"^"")
	set_localinfo(AMX_PLUGINS, file_exists(g_fileplugins[modid]) ? g_fileplugins[modid] : AMX_DEFAULTPLUGINS)
	set_localinfo(AMX_LASTCYCLE, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
	set_pcvar_string(gp_mapcyclefile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)

	switch(get_pcvar_num(gp_mode))
	{
		case 2:
		{
			if(gp_galileo_nommapfile)
				set_pcvar_string(gp_galileo_nommapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)

			if(gp_galileo_votemapfile)
				set_pcvar_string(gp_galileo_votemapfile, file_exists(g_filemaps[modid]) ? g_filemaps[modid] : AMX_DEFAULTCYCLE)
		}
		case 1:
		{
			callfunc_begin("plugin_init", "mapchooser.amxx");
			callfunc_end();
		}
	}
}

public check_task()
{
	new timeleft = get_timeleft()
	if(timeleft < 1 || timeleft > 180)
		return

	remove_task(TASK_VOTEMOD)
	start_vote()
}

public start_vote()
{
	if(g_alreadyvoted)
		return

	g_alreadyvoted = 1
	remove_task(TASK_VOTEMOD)
	remove_task(TASK_CHVOMOD)

	new menu[512], mkeys, i
	new pos = format(menu, 511, g_coloredmenus ? "\y%L:\w^n^n" : "%L:^n^n", LANG_PLAYER, "MM_CHOOSE")

	for(i=0; i<= g_modcount; i++) {
		pos += format(menu[pos], 511, "%d. %s^n", i + 1, g_modnames[i])
		g_votemodcount[i] = 0
		mkeys |= (1<<i)
	}

	new szMenuName[32]
	formatex(szMenuName, 31, "%L", LANG_PLAYER, "MM_VOTE")
	show_menu(0, mkeys, menu, 15, szMenuName)
	client_cmd(0, "spk Gman/Gman_Choose2")

	set_task(15.0, "check_vote", TASK_CHVOMOD)
	return
}

public user_votemod(id)
{
	new Float:elapsedTime = get_pcvar_float(gp_timelimit) - (float(get_timeleft()) / 60.0)
	new Float:minTime

	minTime = get_pcvar_float(gp_mintime)

	if(elapsedTime < minTime) {
		client_print(0, print_chat, "[AMX MultiMod] %L", LANG_PLAYER, "MM_PL_WAIT", floatround(minTime - elapsedTime, floatround_ceil))
		return PLUGIN_HANDLED
	}

	new timeleft = get_timeleft()
	if(timeleft < 180)
		return PLUGIN_HANDLED

	start_vote()
	return PLUGIN_HANDLED
}

public player_vote(id, key)
{
	if(key <= g_modcount)
	{
		if(get_pcvar_num(gp_voteanswers))
		{
			new player[SSTRING]
			get_user_name(id, player, charsmax(player))
			client_print(0, print_chat, "%L", LANG_PLAYER, "X_CHOSE_X", player, g_modnames[key])
		}
		g_votemodcount[key]++
	}
}

public check_vote()
{
	new b = 0
	for(new a = 0; a <= g_modcount; a++)
		if(g_votemodcount[b] < g_votemodcount[a]) b = a

	client_print(0, print_chat, "%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	server_print("%L", LANG_PLAYER, "MM_VOTEMOD", g_modnames[b])
	if(b != g_currentmodid)
		set_multimod(b)
}
