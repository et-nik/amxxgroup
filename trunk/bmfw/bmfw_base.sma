#include <amxmodx>
#include <engine>
#include <hamsandwich>
#include <fakemeta>
#include <bmfw>

#define	PLUGIN_NAME	"BM FrameWork"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw"

#define MAX_PLAYERS	32
#define MAX_BLOCKS	64

#define _del_prop(%1,%2)		g_Player[%2] &= ~(1<<(%1 - 1))
#define _set_prop(%1,%2)		g_Player[%2] |= ~(1<<(%1 - 1))
#define _get_prop(%1,%2)		(g_Player[%2] & (1<<(%1 - 1)))

new const g_Corners[] = {-16, 16, 16, -16}
new const g_Functions[][] =
{
	"block_Spawn",
	"block_Touch",
	"block_AddToFullPack",
	"block_PlayerPreThink",
	"block_PlayerPostThink",
	"block_UpdateClientData",
	"block_Think"
}

new g_PlayerGrab[MAX_PLAYERS]
new g_PlayerBlock[MAX_PLAYERS]
new g_Player[Props]
new g_Blocks[MAX_BLOCKS][Blocks]
new g_Count = -1
new g_MaxClients

new Float:g_PlayerCooldown[MAX_PLAYERS][MAX_BLOCKS]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_think(BM_CLASSNAME, "block_Think")

	register_concmd("bm_list", "bm_list")
	register_concmd("bm_save", "bm_save")
	register_clcmd("bm_add", "bm_add")
	register_clcmd("bm_del", "bm_del")
	register_clcmd("+bm_grab", "bm_grab_hold")
	register_clcmd("-bm_grab", "bm_grab_release")

	g_MaxClients = global_get(glb_maxClients)
}

public plugin_natives()
{
	register_library(PLUGIN_CVAR)
	register_native("_reg_block", "_native_reg_block")

	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	for(new Props:i = Props:0; Props:i < Props; Props:i++)
	{
		_del_prop(id, i)
	}
	_set_prop(id, eConnected)
	g_PlayerBlock[id] = -1
}

////////////////////////////////////////////////////////////////////
//// NATIVES
////////////////////////////////////////////////////////////////////

public _native_reg_block(plugin, count)
{
	new name[32], model[128]
	new touchtype
	new cooldown
	new Float:size[3], Float:sizesmall[3], Float:sizelarge[3]

	get_string(1, name, charsmax(name))
	get_string(2, model, charsmax(model))
	touchtype = get_param(3)
	cooldown = get_param(4)
	get_array_f(5, size, charsmax(size))
	get_array_f(6, sizesmall, charsmax(sizesmall))
	get_array_f(7, sizelarge, charsmax(sizelarge))

	g_Count++
	server_print("Block registered %i:%s", g_Count, name)
	copy(g_Blocks[g_Count][bName], charsmax(g_Blocks), name)
	copy(g_Blocks[g_Count][bModel], charsmax(g_Blocks), model)
	g_Blocks[g_Count][bPlugin] = plugin
	g_Blocks[g_Count][bCooldown] = cooldown
	g_Blocks[g_Count][bTouch] = touchtype
	bm_vector_copy(g_Blocks[g_Count][bSize], size)
	bm_vector_copy(g_Blocks[g_Count][bSizeSmall], sizesmall)
	bm_vector_copy(g_Blocks[g_Count][bSizeLarge], sizelarge)
	for(new i=0; i< sizeof g_Functions; i++)
	{
		new idx = get_func_id(g_Functions[i], plugin)
		if(idx != -1) g_Blocks[g_Count][bHandlers][Handlers:i] = idx
	}
	return true
}

////////////////////////////////////////////////////////////////////
//// TESTING
////////////////////////////////////////////////////////////////////

public bm_list(id)
{
	for(new bType = 0; bType <= g_Count; bType++)
	{
		server_print("Block %i %s:%s", bType, g_Blocks[bType][bName], g_Blocks[bType][bModel])
		for(new j = 0; j < _:Handlers; j++)
		{
			if(g_Blocks[bType][bHandlers][Handlers:j])
				server_print("^tHandler %s -> %i", g_Functions[j], g_Blocks[bType][bHandlers][Handlers:j])
		}
	}
	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////
//// BMFW COMMANDS
////////////////////////////////////////////////////////////////////

public bm_save()
{
	new ent
	new name[32]
	new Float:vOrigin[3]
	new type

	server_print("Saving block to file")
	while((ent = find_ent_by_class(ent, BM_CLASSNAME)))
	{
		if(!is_valid_ent(ent)) continue

		type = entity_get_int(ent, EV_INT_body)
		copy(name, charsmax(name), g_Blocks[type][bName])
		entity_get_vector(ent, EV_VEC_origin, vOrigin)
		server_print("%s:%s:%i:%f:%f:%f", BM_CLASSNAME, name, 1, vOrigin[0], vOrigin[1], vOrigin[2])
	}
	return PLUGIN_HANDLED
}

public bm_add(id)
{
	static szTemp[32]
	read_argv(1, szTemp, charsmax(szTemp))
	new bType = str_to_num(szTemp)

	if(bType > g_Count)
		return PLUGIN_HANDLED

	server_print("Added block %i (%s) by player %i", bType, g_Blocks[bType][bModel], id)

	new origin[3], Float:vorigin[3]
	get_user_origin(id, origin, 3)
	IVecFVec(origin, vorigin)
	vorigin[2] += 15.0

	new model[128]
	formatex(model, charsmax(model), "%s%s.mdl", BM_BASEFILE, g_Blocks[bType][bModel])

	new ent = create_entity(BM_BASECLASS)
	if (is_valid_ent(ent))
	{
		entity_set_string(ent, EV_SZ_classname, BM_CLASSNAME)
		entity_set_model(ent, model)
		entity_set_size(ent, Float:{-32.0, -32.0, -4.0}, Float:{32.0, 32.0, 4.0})
		entity_set_origin(ent, vorigin)
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
		entity_set_int(ent, EV_INT_body, bType)
		// snaping code here

		if(g_Blocks[bType][bHandlers][Handlers:hSpawn] > 0)
		{
			if(callfunc_begin_i(g_Blocks[bType][bHandlers][Handlers:hSpawn], g_Blocks[bType][bPlugin]) > 0)
			{
				callfunc_push_int(ent)
				new ret = callfunc_end()
				return ret
			}
		}
	}
	return PLUGIN_HANDLED
}

public bm_del(id)
{
	new ent, body
	get_user_aiming(id, ent, body)
	if(_bm_is_block(ent))
	{
		remove_entity(ent)
	}
	return PLUGIN_HANDLED
}

public bm_grab_hold(id)
{
	g_PlayerGrab[id] = 0
	return PLUGIN_HANDLED
}

public bm_grab_release(id)
{
	g_PlayerGrab[id] = 0
	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////
//// BMFW CORE
////////////////////////////////////////////////////////////////////

stock _bm_is_block(ent)
{
	if(is_valid_ent(ent))
	{
		new class[32]
		entity_get_string(ent, EV_SZ_classname, class, charsmax(class))
		if(equal(class, BM_CLASSNAME))
			return true
	}
	return false
}

stock _bm_is_touched(ent, touchtype)
{
	new bType = entity_get_int(ent, EV_INT_body)
	return (g_Blocks[bType][bTouch] & touchtype)
}

public _bm_is_on_block(id)
{
	new ent
	new Float:pOrigin[3]
	new Float:pSize[3]
	new Float:pMaxs[3]
	new Float:vBottom[3]
	new Float:vHead[3]
	new Float:vReturn[3]
	entity_get_vector(id, EV_VEC_origin, pOrigin)
	entity_get_vector(id, EV_VEC_size, pSize)
	entity_get_vector(id, EV_VEC_maxs, pMaxs)
	pOrigin[2] = pOrigin[2] - ((pSize[2] - 36.0) - (pMaxs[2] - 36.0))
	vBottom[2] = pOrigin[2] - 1.0
	bm_vector_copy(vHead, pOrigin)
	vHead[2] += pSize[2] + 1.0

	for (new i = 0; i < 4; ++i)
	{
		vBottom[0] = pOrigin[0] + g_Corners[i]
		vBottom[1] = pOrigin[1] - g_Corners[i]

		ent = trace_line(id, pOrigin, vBottom, vReturn)
		if(_bm_is_block(ent) && _bm_is_touched(ent, touch_foot || touch_all || touch_both))
			return ent

		ent = trace_line(id, pOrigin, vHead, vReturn)
		if(_bm_is_block(ent) && _bm_is_touched(ent, touch_head || touch_all || touch_both))
			return ent
	}

	return false
}

////////////////////////////////////////////////////////////////////
//// BMFW MAGIC!!!
////////////////////////////////////////////////////////////////////

public pfn_touch(touched, toucher)
{
	if(!_bm_is_block(touched) || (toucher < 1) || (toucher > g_MaxClients))
		return PLUGIN_CONTINUE

	if(_bm_is_on_block(toucher) != touched)
	{
		g_PlayerBlock[toucher] = -1
		return PLUGIN_CONTINUE
	}

	new bType = entity_get_int(touched, EV_INT_body)
	if(g_Blocks[bType][bCooldown] >= 0)
	{
		new Float:time = halflife_time()
		new cooldown = g_Blocks[bType][bCooldown]
		if(time < (g_PlayerCooldown[toucher][bType] + cooldown))
		{
			return PLUGIN_CONTINUE
		}
		g_PlayerCooldown[toucher][bType] = time
	}

	g_PlayerBlock[toucher] = bType
	if(g_Blocks[bType][bHandlers][Handlers:hTouch] > 0)
	{
		if(callfunc_begin_i(g_Blocks[bType][bHandlers][Handlers:hTouch], g_Blocks[bType][bPlugin]) > 0)
		{
			callfunc_push_int(touched)
			callfunc_push_int(toucher)
			new ret = callfunc_end()
			return ret
		}
	}
	return PLUGIN_CONTINUE
}

public client_PreThink(id)
{
	if(g_PlayerBlock[id] < 0)
		return PLUGIN_CONTINUE

	if(g_Blocks[g_PlayerBlock[id]][bHandlers][Handlers:hPlayerPreThink] > 0)
	{
		if(callfunc_begin_i(g_Blocks[g_PlayerBlock[id]][bHandlers][Handlers:hPlayerPreThink], g_Blocks[g_PlayerBlock[id]][bPlugin]) > 0)
		{
			g_PlayerBlock[id] = -1
			callfunc_push_int(id)
			new ret = callfunc_end()
			return ret
		}
	}

	if(g_PlayerGrab[id])
	{
	}
	return PLUGIN_CONTINUE
}

public block_Think(ent)
{
	new bType = entity_get_int(ent, EV_INT_body)
	if(g_Blocks[bType][bHandlers][Handlers:hThink] > 0)
	{
		if(callfunc_begin_i(g_Blocks[bType][bHandlers][Handlers:hThink], g_Blocks[bType][bPlugin]) > 0)
		{
			callfunc_push_int(ent)
			new ret = callfunc_end()
			return ret
		}
	}
	return PLUGIN_CONTINUE
}

