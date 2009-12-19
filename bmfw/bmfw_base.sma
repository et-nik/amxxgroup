#include <bmfw>

#define	PLUGIN_NAME	"BM FrameWork"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.1"
#define	PLUGIN_CVAR	"bmfw"

#define MAX_PLAYERS	32
#define MAX_BLOCKS	64
#define MAX_ENTBLOCKS	400

new const g_Corners[][] = { {-16, 16, 16, -16, -8, 8, 8, -8, 0}, {-16, -16, 16, 16, -8, -8, 8, 8, 0} }
new const g_Functions[][] =
{
	"block_Spawn",
	"block_Touch",
	"block_Think",
	"block_AddToFullPack",
	"block_PlayerPreThink",
	"block_PlayerPostThink",
	"block_UpdateClientData"
}

new g_PlayerGrab[MAX_PLAYERS+1]
new Float:g_PlayerGrabLen[MAX_PLAYERS+1]
new Float:g_PlayerGrabLook[MAX_PLAYERS+1][3]
new g_PlayerHandler[MAX_PLAYERS+1][MAX_BLOCKS][Handlers]
new g_Blocks[MAX_BLOCKS][Blocks]
new g_Count = -1
new g_BlocksCount
new g_MaxEntities
new g_MaxClients

new Float:g_PlayerCooldown[MAX_PLAYERS+1][MAX_BLOCKS]
new Float:g_PlayerLastOrigin[MAX_PLAYERS+1][3]
new g_PlayerLastBlock[MAX_PLAYERS+1]

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	register_logevent("round_Start", 2, "1=Round_Start")
	register_think(BM_CLASSNAME, "block_Think")

	register_concmd("bm_list", "bm_list")
	register_concmd("bm_save", "bm_save")
	register_clcmd("bm_add", "bm_add")
	register_clcmd("bm_del", "bm_del")
	register_clcmd("+bm_grab", "bm_grab_hold")
	register_clcmd("-bm_grab", "bm_grab_release")

	g_MaxEntities = get_global_int(GL_maxEntities)
	g_MaxClients = get_global_int(GL_maxClients)
}

public plugin_natives()
{
	register_library(PLUGIN_CVAR)
	register_native("_set_handler", "_native_set_handler")
	register_native("_reg_block", "_native_reg_block")

	return PLUGIN_CONTINUE
}

public client_putinserver(id)
{
	g_PlayerLastOrigin[id] = Float:{ 99999.9, 99999.9, 99999.9 }
	g_PlayerLastBlock[id] = -1
	for(new j = 0; j <= g_Count; j++)
		for(new i = 0; i < _:Handlers; i++)
			g_PlayerHandler[id][j][Handlers:i] = -1

}

////////////////////////////////////////////////////////////////////
//// NATIVES
////////////////////////////////////////////////////////////////////

public _native_set_handler(plugin, count)
{
	new id = get_param(1)
	new blockid = get_param(2)
	new val = get_param(3)
	new handler = get_param(4)

	g_PlayerHandler[id][blockid][Handlers:handler] = val
}

public _native_reg_block(plugin, count)
{
	new name[32], cvarname[32], version[32], model[128]
	new touchtype
	new Float:cooldown
	new Float:size[4], Float:sizesmall[4], Float:sizelarge[4]

	get_string(1, name, charsmax(name))
	get_string(2, version, charsmax(version))
	get_string(3, model, charsmax(model))
	touchtype = get_param(4)
	cooldown = get_param_f(5)
	get_array_f(6, size, charsmax(size))
	get_array_f(7, sizesmall, charsmax(sizesmall))
	get_array_f(8, sizelarge, charsmax(sizelarge))

	formatex(cvarname, charsmax(cvarname), "bmfw_%s", model)
	register_cvar(cvarname, version, FCVAR_SERVER|FCVAR_SPONLY)

	g_Count++
	server_print("Block registered %i:%s", g_Count, name)
	copy(g_Blocks[g_Count][bName], charsmax(g_Blocks), name)
	copy(g_Blocks[g_Count][bModel], charsmax(g_Blocks), model)
	g_Blocks[g_Count][bPlugin] = plugin
	g_Blocks[g_Count][bCooldown] = _:cooldown
	g_Blocks[g_Count][bTouch] = touchtype
	bm_vector_copy(g_Blocks[g_Count][bSize], size)
	bm_vector_copy(g_Blocks[g_Count][bSizeSmall], sizesmall)
	bm_vector_copy(g_Blocks[g_Count][bSizeLarge], sizelarge)
	for(new i=0; i< sizeof g_Functions; i++)
	{
		new idx = get_func_id(g_Functions[i], plugin)
		if(idx != -1) g_Blocks[g_Count][bHandlers][Handlers:i] = idx
	}
	return g_Count
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
		copy(name, charsmax(name), g_Blocks[type][bModel])
		entity_get_vector(ent, EV_VEC_origin, vOrigin)
		server_print("%s:%s:%i:%f:%f:%f", BM_CLASSNAME, name, 1, vOrigin[0], vOrigin[1], vOrigin[2])
	}
	return PLUGIN_HANDLED
}

public bm_add(id)
{
	if(g_BlocksCount >= MAX_ENTBLOCKS)
	{
		server_print("You have reached the maximum of blocks you can create")
		return PLUGIN_HANDLED
	}

	if(entity_count() > (0.9 * g_MaxEntities))
	{
		server_print("There's no enought save space for new entities")
		return PLUGIN_HANDLED
	}

	static szTemp[32], size[2]
	read_argv(1, szTemp, charsmax(szTemp))
	read_argv(2, size, charsmax(size))

	new bType = str_to_num(szTemp)

	if(bType > g_Count)
		return PLUGIN_HANDLED

	server_print("Added block %i (%s) by player %i", bType, g_Blocks[bType][bModel], id)

	new model[128], modelsize[16]
	new Float:vMins[3], Float:vMaxs[3]
	switch(size[0])
	{
		case 'l':
		{
			copy(modelsize, charsmax(modelsize), BM_MODELLARGE)
			bm_vector_copy(vMins, g_Blocks[bType][bSizeLarge])
			bm_vector_copy(vMaxs, g_Blocks[bType][bSizeLarge])
		}
		case 's':
		{
			copy(modelsize, charsmax(modelsize), BM_MODELSMALL)
			bm_vector_copy(vMins, g_Blocks[bType][bSizeSmall])
			bm_vector_copy(vMaxs, g_Blocks[bType][bSizeSmall])
		}
		default:
		{
			bm_vector_copy(vMins, g_Blocks[bType][bSize])
			bm_vector_copy(vMaxs, g_Blocks[bType][bSize])
		}
	}
	bm_vector_mul(vMins, -0.5)
	bm_vector_mul(vMaxs, 0.5)

	formatex(model, charsmax(model), "%s%s%s.mdl", BM_BASEFILE, g_Blocks[bType][bModel], modelsize)

	new origin[3], Float:vorigin[3]
	get_user_origin(id, origin, 3)
	IVecFVec(origin, vorigin)
	vorigin[2] -= vMins[2]

	new ent = create_entity(BM_BASECLASS)
	if(is_valid_ent(ent))
	{
		g_BlocksCount++
		entity_set_string(ent, EV_SZ_classname, BM_CLASSNAME)
		entity_set_model(ent, model)
		entity_set_size(ent, vMins, vMaxs)
		entity_set_int(ent, EV_INT_solid, SOLID_BBOX)
		entity_set_int(ent, EV_INT_movetype, MOVETYPE_FLY)
		entity_set_int(ent, EV_INT_body, bType)
		entity_set_string(ent, EV_SZ_netname, g_Blocks[bType][bName])

		// snaping code here
		_bm_snap(ent, vorigin)

		entity_set_origin(ent, vorigin)

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
	if(_bm_is_block(ent) && !_bm_is_grabbed(ent))
	{
		remove_entity(ent)
		g_BlocksCount--
	}
	return PLUGIN_HANDLED
}

public bm_grab_release(id)
{
	g_PlayerGrab[id] = 0
	return PLUGIN_HANDLED
}

public bm_grab_hold(id)
{
	new ent, body
	get_user_aiming(id, ent, body)
	if(_bm_is_block(ent) && !_bm_is_grabbed(ent))
	{
		new iorigin[3], Float:vorigin[3], Float:end[3]
		get_user_origin(id, iorigin, 1)
		IVecFVec(iorigin, vorigin)
		entity_get_vector(ent, EV_VEC_origin, end)
		new Float:len = get_distance_f(vorigin, end)
		g_PlayerGrab[id] = ent
		g_PlayerGrabLen[id] = len
	}
	return PLUGIN_HANDLED
}

////////////////////////////////////////////////////////////////////
//// BMFW CORE
////////////////////////////////////////////////////////////////////

stock _bm_is_grabbed(ent)
{
	for(new i = 1; i <= g_MaxClients; i++)
	{
		if(g_PlayerGrab[i] == ent)
			return true
	}
	return false
}

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
	vHead = pOrigin
	vHead[2] += pSize[2] + 1.0

	// To avoid cpu usage we can cache last touched block for same origin
	if(bm_vector_compare(g_PlayerLastOrigin[id], pOrigin))
		return g_PlayerLastBlock[id]

	g_PlayerLastOrigin[id] = pOrigin
	for(new i = 0; i < 9; ++i)
	{
		vBottom[0] = pOrigin[0] + g_Corners[0][i]
		vBottom[1] = pOrigin[1] - g_Corners[1][i]

		ent = trace_line(id, pOrigin, vBottom, vReturn)
		if(_bm_is_block(ent) && _bm_is_touched(ent, TOUCH_FOOT | TOUCH_ALL | TOUCH_BOTH))
			return ent

		vHead[0] = pOrigin[0] + g_Corners[0][i]
		vHead[1] = pOrigin[1] - g_Corners[1][i]
		ent = trace_line(id, pOrigin, vHead, vReturn)
		if(_bm_is_block(ent) && _bm_is_touched(ent, TOUCH_HEAD | TOUCH_ALL | TOUCH_BOTH))
			return ent
	}

	return false
}

public _bm_snap(ent, Float:vOrigin[3])
{
	new Float:snapsize = 10.0
	new Float:vReturn[3]
	new Float:dist
	new Float:olddist = 99999.9
	new Float:vStart[3]
	new Float:vEnd[3]
	new tr, closest, face

	new Float:vMins[3], Float:vMaxs[3]
	new Float:vMinsTr[3], Float:vMaxsTr[3]

	entity_get_vector(ent, EV_VEC_mins, vMins)
	entity_get_vector(ent, EV_VEC_maxs, vMaxs)

	for(new i = 0; i < 6; i++)
	{
		vStart = vOrigin
		switch(i)
		{
			case 0: vStart[0] += vMins[0]
			case 1: vStart[0] += vMaxs[0]
			case 2: vStart[1] += vMins[1]
			case 3: vStart[1] += vMaxs[1]
			case 4: vStart[2] += vMins[2]
			case 5: vStart[2] += vMaxs[2]
		}

		vEnd = vStart
		switch(i)
		{
			case 0: vEnd[0] -= snapsize
			case 1: vEnd[0] += snapsize
			case 2: vEnd[1] -= snapsize
			case 3: vEnd[1] += snapsize
			case 4: vEnd[2] -= snapsize
			case 5: vEnd[2] += snapsize
		}

		tr = trace_line(ent, vStart, vEnd, vReturn)

		if(_bm_is_block(tr))
		{
			dist = get_distance_f(vStart, vReturn)
			if(dist < olddist)
			{
				closest = tr
				olddist = dist
				face = i
			}
		}
	}

	if(is_valid_ent(closest))
	{
		entity_get_vector(closest, EV_VEC_origin, vReturn)
		entity_get_vector(closest, EV_VEC_mins, vMinsTr)
		entity_get_vector(closest, EV_VEC_maxs, vMaxsTr)

		vOrigin = vReturn

		switch(face)
		{
			case 0: vOrigin[0] += vMaxs[0] + vMaxsTr[0]
			case 1: vOrigin[0] += vMins[0] + vMinsTr[0]
			case 2: vOrigin[1] += vMaxs[1] + vMaxsTr[1]
			case 3: vOrigin[1] += vMins[1] + vMinsTr[1]
			case 4: vOrigin[2] += vMaxs[2] + vMaxsTr[2]
			case 5: vOrigin[2] += vMins[2] + vMinsTr[2]
		}
	}

	new other = g_MaxClients + 1
	while((other = find_ent_in_sphere(other, vOrigin, 4.0)))
	{
		if(is_valid_ent(other) && _bm_is_block(other))
		{
			entity_get_vector(other, EV_VEC_maxs, vMaxsTr)
			vOrigin[2] += vMaxsTr[2] + vMins[2]
			return
		}
	} 
	return
}

////////////////////////////////////////////////////////////////////
//// BMFW MAGIC!!!
////////////////////////////////////////////////////////////////////

public round_Start()
{
	for(new id = 1; id <= g_MaxClients; id++)
		for(new j = 0; j <= g_Count; j++)
			for(new i = 0; i < _:Handlers; i++)
				g_PlayerHandler[id][j][Handlers:i] = -1

	return PLUGIN_CONTINUE
}

public pfn_touch(touched, toucher)
{
	if(!_bm_is_block(touched) || !is_user_alive(toucher))
		return PLUGIN_CONTINUE

	new bType = entity_get_int(touched, EV_INT_body)
	if(!(g_Blocks[bType][bTouch] & TOUCH_ALL) &&  (_bm_is_on_block(toucher) != touched))
	{
		return PLUGIN_CONTINUE
	}

	// To avoid cpu usage we can cache last touched block for same origin
	g_PlayerLastBlock[toucher] = touched

	if(g_Blocks[bType][bCooldown] >= 0)
	{
		new Float:time = float(get_systime())
		new Float:cooldown = Float:g_Blocks[bType][bCooldown]
		if(time < (g_PlayerCooldown[toucher][bType] + cooldown))
		{
			return PLUGIN_CONTINUE
		}
		g_PlayerCooldown[toucher][bType] = time
	}

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
	if(g_PlayerGrab[id])
	{
		new iorigin[3], ilook[3]
		new Float:vdest[3], Float:vorigin[3], Float:vlook[3], Float:vdir[3], Float:vlen
		get_user_origin(id, iorigin, 1)
		get_user_origin(id, ilook, 3)
		IVecFVec(iorigin, vorigin)
		IVecFVec(ilook, vlook)
		if(!bm_vector_compare(vlook, g_PlayerGrabLook[id]))
		{
			g_PlayerGrabLook[id] = vlook
			vdir = vlook
			bm_vector_substract(vdir, vorigin)
			vlen = get_distance_f(vlook, vorigin)

			if(vlen == 0.0) vlen = 1.0

			vdest[0] = (vorigin[0] + vdir[0] * g_PlayerGrabLen[id] / vlen)
			vdest[1] = (vorigin[1] + vdir[1] * g_PlayerGrabLen[id] / vlen)
			vdest[2] = (vorigin[2] + vdir[2] * g_PlayerGrabLen[id] / vlen)
			vdest[2] = float(floatround(vdest[2], floatround_floor))

			_bm_snap(g_PlayerGrab[id], vdest)
			entity_set_origin(g_PlayerGrab[id], vdest)
		}
	}

	new ret, ret2
	for(new i = 0; i <= g_Count; i++)
	{
		new bType = g_PlayerHandler[id][i][hPlayerPreThink]

		if(bType < 0) continue

		if(g_Blocks[bType][bHandlers][Handlers:hPlayerPreThink] > 0)
		{
			if(callfunc_begin_i(g_Blocks[bType][bHandlers][Handlers:hPlayerPreThink], g_Blocks[bType][bPlugin]) > 0)
			{
				callfunc_push_int(id)
				ret2 = callfunc_end()
				ret = (ret2 > ret) ? ret2 : ret
			}
		}
	}
	return ret
}

public client_PostThink(id)
{
	new ret, ret2
	for(new i = 0; i <= g_Count; i++)
	{
		new bType = g_PlayerHandler[id][i][hPlayerPostThink]
		if(bType < 0) continue

		if(g_Blocks[bType][bHandlers][Handlers:hPlayerPostThink] > 0)
		{
			if(callfunc_begin_i(g_Blocks[bType][bHandlers][Handlers:hPlayerPostThink], g_Blocks[bType][bPlugin]) > 0)
			{
				callfunc_push_int(id)
				ret2 = callfunc_end()
				ret = (ret2 > ret) ? ret2 : ret
			}
		}
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

