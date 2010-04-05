#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
 
#define PLUGIN_NAME	"Lights Management"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"0.2"
#define PLUGIN_CVAR	"lightsmgmt"

enum _buttons { _ent, _class[32] }

new gp_PrecacheKeyValue
new gp_LightsMode
new gp_LightsAdmin
new gp_LightsOther

new Trie:g_Managers
new g_Buttons[10][_buttons]
 
public plugin_init()
{
	unregister_forward(FM_KeyValue, gp_PrecacheKeyValue)
 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
 
	register_dictionary("common.txt")

	gp_LightsMode = register_cvar("lightsmode", "3") // 0-everyone / 1-ct / 2-tt / 3-nobody
	gp_LightsAdmin = register_cvar("lightsadmin", "1") // 0-follow lightsmode / 1-allow admins
	gp_LightsOther = register_cvar("lightsother", "1") // 0-allow non-player callers / 1-disallow
	setup_buttons()
}

public plugin_precache()
{
 	g_Managers = TrieCreate()
	gp_PrecacheKeyValue = register_forward(FM_KeyValue, "precache_keyvalue", 1)
}

public precache_keyvalue(ent, kvd_handle)
{
	static info[32]
	if(!pev_valid(ent))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_ClassName, info, charsmax(info))
	if(!equal(info, "multi_manager"))
		return FMRES_IGNORED

	get_kvd(kvd_handle, KV_KeyName, info, charsmax(info))
	TrieSetCell(g_Managers, info, ent)
	return FMRES_IGNORED
}

public setup_buttons()
{
	new ent[3]
	new info[32]
	new pos

	while((pos <= sizeof(g_Buttons)) && (ent[0] = engfunc(EngFunc_FindEntityByString, ent[0], "classname", "light")))
	{
		if(!pev_valid(ent[0]))
			continue

		pev(ent[0], pev_targetname, info, charsmax(info))
		if(TrieKeyExists(g_Managers, info))
		{
			TrieGetCell(g_Managers, info, ent[1])
			pev(ent[1], pev_targetname, info, charsmax(info))
		}
		while((ent[2] = engfunc(EngFunc_FindEntityByString, ent[2], "target", info)))
		{
			if(!pev_valid(ent[2]))
				continue

			if(pev_valid(ent[2]) && (find_button(ent[2]) < 0))
			{
				g_Buttons[pos][_ent] = ent[2]
				pev(ent[2], pev_classname, g_Buttons[pos][_class], charsmax(g_Buttons[][_class]))
				pos++
				break
			}
		}
	}
	TrieDestroy(g_Managers)

	for(new i = 0; i < sizeof g_Buttons; i++)
	{
		if(g_Buttons[i][_ent])
		{
			RegisterHam(Ham_Use, g_Buttons[i][_class], "switch_use")
		}
	}
}

public switch_use(ent, caller, activator, use_type, Float:value)
{
	static mode, team, connected

	if(find_button(ent) < 0)
		return HAM_IGNORED

	mode = get_pcvar_num(gp_LightsMode)
	connected = is_user_connected(caller)

	if(!mode || (!connected && !get_pcvar_num(gp_LightsOther)))
		return HAM_IGNORED

	if(connected)
	{
		team = get_user_team(caller)
		if(team == mode || (get_pcvar_num(gp_LightsAdmin) && is_user_admin(caller)))
			return HAM_IGNORED

		client_print(caller, print_center, "%L", LANG_SERVER, "NO_ACC_COM")
	}
	return HAM_SUPERCEDE
}

stock find_button(needle)
{
	for(new i = 0; i < sizeof g_Buttons; i++)
	{
		if(g_Buttons[i][_ent] == needle)
			return i
	}
	return -1
}

