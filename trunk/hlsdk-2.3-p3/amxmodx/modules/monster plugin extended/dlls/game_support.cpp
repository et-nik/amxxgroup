// vi: set ts=4 sw=4 :
// vim: set tw=75 :

// game_support.cpp - info to recognize different HL mod "games"

/*
 * Copyright (c) 2001-2003 Will Day <willday@hpgx.net>
 *
 *    This file is part of Metamod.
 *
 *    Metamod is free software; you can redistribute it and/or modify it
 *    under the terms of the GNU General Public License as published by the
 *    Free Software Foundation; either version 2 of the License, or (at
 *    your option) any later version.
 *
 *    Metamod is distributed in the hope that it will be useful, but
 *    WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *    General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with Metamod; if not, write to the Free Software Foundation,
 *    Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 *    In addition, as a special exception, the author gives permission to
 *    link the code of this program with the Half-Life Game Engine ("HL
 *    Engine") and Modified Game Libraries ("MODs") developed by Valve,
 *    L.L.C ("Valve").  You must obey the GNU General Public License in all
 *    respects for all of the code used other than the HL Engine and MODs
 *    from Valve.  If you modify this file, you may extend this exception
 *    to your version of the file, but you are not obligated to do so.  If
 *    you do not wish to do so, delete this exception statement from your
 *    version.
 *
 */

#include <extdll.h>			// always

#include "game_support.h"	// me
#include "log_meta.h"		// META_LOG, etc
#include "types_meta.h"		// mBOOL
#include "osdep.h"			// win32 snprintf, etc

// Adapted from adminmod h_export.cpp:
//! this structure contains a list of supported mods and their dlls names
//! To add support for another mod add an entry here, and add all the 
//! exported entities to link_func.cpp
game_modlist_t known_games = {
	// name/gamedir	 linux_so			win_dll			desc
	// Valve/official game mods:
	{"valve",		"hl_i386.so",		"hl.dll",		"Half-Life Deathmatch"},
	{"tfc",			"tfc_i386.so",		"tfc.dll",		"Team Fortress Classic"},
	{"cstrike",		"cs_i386.so",		"mp.dll",		"Counter-Strike"},
	{"gearbox",		"opfor_i386.so",	"opfor.dll",	"Opposing Force"},
	{"dmc",			"dmc_i386.so",		"dmc.dll",		"Deathmatch Classic"},
	{"ricochet",	"ricochet_i386.so",	"mp.dll",		"Ricochet"},
	{"rewolf",		"hl_i386.so",		"gunman.dll",	"Gunman Chronicles"}, // unsure linux name
	// Other game mods, alphabetically:
	{"action",		"ahl_i386.so",		"ahl.dll",		"Action Half-Life"},
	{"ag",			"hl_i386.so",		"hl.dll",		"Adrenalinegamer 3.x"},
	{"aghl",		"ag_i386.so",		"ag.dll",		"Adrenalinegamer 4.x"},
	{"arg",			"arg_i386.so",		"hl.dll",		"Arg!"},
	{"asheep",		"hl_i386.so",		"hl.dll",		"Azure Sheep"},
	{"bg",			"bg_i386.so",		"bg.dll",		"The Battle Grounds"},
	{"bot",			"bot_i386.so",		"bot.dll",		"Bot"},
	{"bumpercars",	"hl_i386.so",		"hl.dll",		"Bumper Cars"},
	{"buzzybots",	"bb_i386.so",		"bb.dll",		"BuzzyBots"},
	{"dcrisis",		"dc_i386.so",		"dc.dll",		"Desert Crisis"},
	{"dpb",			"pb_i686.so",		"pb.dll",		"Digital Paintball"},
	{"dod",			"dod_i386.so",		"dod.dll",		"Day of Defeat"},
	{"dragonmodz",	"hl_i386.so",		"mp.dll",		"Dragon Mod Z"},
	{"esforces",	"hl_i386.so",		"hl.dll",		"Earth`s Special Forces"}, // unsure linux name
	{"esf",			"hl_i386.so",		"hl.dll",		"Earth`s Special Forces"},
	{"existence",	"ex_i386.so",		"existence.dll", "Existence"},
	{"firearms",	"fa_i386.so",		"firearms.dll",	"Firearms"},
	{"firearms25",	"fa_i386.so",		"firearms.dll",	"Retro Firearms"},
	{"freeze",		"mp_i386.so",		"mp.dll",		"Freeze"},
	{"frontline",	"front_i386.so", 	"frontline.dll", "Frontline Force"},
	{"gangstawars",	"gansta_i386.so",	"hl.dll",		"GangstaWars"},
	{"gangwars",	"mp_i386.so",		"mp.dll",		"Gangwars"},
	{"globalwarfare", "gw_i386.so",		"mp.dll",		"Global Warfare"},
	{"goldeneye",	"golden_i386.so",	"mp.dll",		"Goldeneye"},
	{"holywars",	"hl_i386.so",		"holywars.dll",	"Holy Wars"},
	{"ios",			"ios_i386.so",		"ios.dll",		"International Online Soccer"},
	{"judgedm",		"judge_i386.so",	"mp.dll",		"Judgement"},
	{"MorbidPR",	"morbid_i386.so",	"morbid.dll",	"Morbid Inclination"},
	{"ns",			"ns_i386.so",		"ns.dll",		"Natural Selection"},
	{"oel",			"hl_i386.so",		"hl.dll",		"OeL Half-Life"},
	{"ol",			"ol_i386.so",		"hl.dll",		"Outlawsmod"},
	{"osjb",		"osjb_i386.so",		"jail.dll",		"Open-Source Jailbreak"},
	{"oz",			"mp_i386.so",		"mp.dll",		"Oz Deathmatch"},
	{"paintball",	"pb_i386.so",		"mp.dll",		"Paintball"},
	{"penemy",		"pe_i386.so",		"pe.dll",		"Public Enemy"},
	{"phineas",		"phineas_i386.so",	"phineas.dll",	"Phineas Bot"},
	{"retrocs",		"rcs_i386.so",		"rcs.dll",		"Retro Counter-Strike"},
	{"rockcrowbar",	"rc_i386.so",		"rc.dll",		"Rocket Crowbar"},
	{"rspecies",	"hl_i386.so",		"hl.dll",		"Rival Species"},
	{"si",			"si_i386.so",		"si.dll",		"Science & Industry"},
	{"scihunt",		"shunt.so",			"shunt.dll",	"Scientist Hunt"},
	{"snow",		"hl_i386.so",		"snow.dll",		"Snow-War"},
	{"stargatetc",	"hl_i386.so",		"hl.dll",		"StargateTC"},
	{"svencoop",	"hl_i386.so",		"hl.dll",		"Sven Coop"},
	{"swarm",		"swarm_i386.so",	"swarm.dll",	"Swarm"},
	{"trainhunters", "th_i386.so",		"th.dll",		"Train Hunters"},
	{"TS",			"ts_i386.so",		"mp.dll",		"The Specialists"},
	{"tod", 		"hl_i386.so",		"hl.dll",		"Tour of Duty"},
	{"vs",			"vs_i386.so",		"mp.dll",		"VampireSlayer"},
	{"wantedhl",	"hl_i386.so",		"wanted.dll",	"Wanted!"},
	{"wasteland",	"whl_linux.so",		"mp.dll",		"Wasteland"},
	{"weapon_wars",	"ww_i386.so",		"hl.dll",		"Weapon Wars"},
	{"wizwars",		"mp_i386.so",		"hl.dll",		"Wizard Wars"},
	{"wormshl",		"wormshl_i586.so",	"wormshl.dll",	"WormsHL"},
	// End of list terminator:
	{NULL, NULL, NULL, NULL}
};

// Find a gamedll to use - either one listed in known_games matching the
// current gamedir, or one specified manually by the server admin.
//
// meta_errno values:
//  - ME_NOTFOUND	couldn't recognize game
mBOOL lookup_game(gamedll_t *gamedll) {
	static char override_desc_buf[256];
	char *cp;

	// Reproduce functionality of adminmod's "admin.ini", to allow
	// use of unknown gamedll's, as well as standalone bot dlls, except
	// that instead of a file "admin.ini", we prefer to have it specified
	// on the commandline, ie:
	//    ./hlds_run -game cstrike +localinfo mm_gamedll dlls/pod_bot.so

	// First, look for "localinfo mm_gamedll <dllpath>".
	if((cp=LOCALINFO("mm_gamedll")) && *cp != '\0') {
		char *dpath=cp;
		META_LOG("Gamedll specified via localinfo: %s", dpath);
		snprintf(gamedll->pathname, sizeof(gamedll->pathname), "%s/%s",
				gamedll->gamedir, dpath);
	}
	// Next, look for old-style "metagame.ini" containing dllpath and
	// complain.
	else {
		if(valid_gamedir_file("metagame.ini"))
			META_ERROR("File 'metagame.ini' is no longer supported; instead, run hlds with '+localinfo mm_gamedll <dllfile>'");
	}

	if(gamedll->pathname[0]) {
		// get filename from pathname
		cp=strrchr(gamedll->pathname, '/');
		if(cp) cp++;
		else cp=gamedll->pathname;
		gamedll->file=cp;
		// generate a desc
		snprintf(override_desc_buf, sizeof(override_desc_buf), 
				"%s (override)", cp);
		gamedll->desc=override_desc_buf;
		META_LOG("Overriding game '%s' with dllfile '%s'", gamedll->name, 
				gamedll->file);
		return(mTRUE);
	}
	else {
		int i;
		for(i=0; known_games[i].name; i++) {
			game_modinfo_t *iknown;
			char *idll;
			iknown=&known_games[i];
#ifdef _WIN32
			idll=iknown->win_dll;
#elif defined(linux)
			idll=iknown->linux_so;
#else
#error "OS unrecognized"
#endif /* _WIN32 */
			if(!strcasecmp(gamedll->name, iknown->name)) {
				gamedll->desc=iknown->desc;
				gamedll->file=idll;
				snprintf(gamedll->pathname, sizeof(gamedll->pathname), "%s/dlls/%s", gamedll->gamedir, idll);
				META_LOG("Recognized game '%s'; using dllfile '%s'", gamedll->name, gamedll->file);
				return(mTRUE);
			}
		}
	}
	RETURN_ERRNO(mFALSE, ME_NOTFOUND);
}
