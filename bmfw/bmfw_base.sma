#include <bmfw>

#define	PLUGIN_NAME	"BM FrameWork"
#define	PLUGIN_AUTHOR	"JoRoPiTo"
#define	PLUGIN_VERSION	"0.2"
#define	PLUGIN_CVAR	"bmfw"

#define MAX_PLAYERS	32
#define MAX_BLOCKS	64
#define MAX_ENTBLOCKS	250

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

new g_Config[128]
new g_Map[64]
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

	register_clcmd("bm_load", "bm_load", ADMIN_RCON)
	register_clcmd("bm_save", "bm_save", ADMIN_RCON)
	register_clcmd("bm_list", "bm_list", ADMIN_KICK)
	register_clcmd("bm_add", "bm_add", ADMIN_KICK)
	register_clcmd("bm_del", "bm_del", ADMIN_KICK)
	register_clcmd("bm_rotate", "bm_rotate", ADMIN_KICK)
	register_clcmd("bm_cleanup", "bm_cleanup", ADMIN_KICK)
	register_clcmd("+bm_grab", "bm_grab_hold", ADMIN_KICK)
	register_clcmd("-bm_grab", "bm_grab_release", ADMIN_KICK)

	g_MaxEntities = get_global_int(GL_maxEntities)
	g_MaxClients = get_global_int(GL_maxClients)
}

public plugin_cfg()
{
	get_localinfo("amxx_configsdir", g_Config, charsmax(g_Config))
	strcat(g_Config, "/bmfw/", charsmax(g_Config))

	if(!dir_exists(g_Config))
	{
		server_print("[BMFW] Creating config directory %s", g_Config)
		mkdir(g_Config)
	}

	get_mapname(g_Map, charsmax(g_Map))
	strcat(g_Config, g_Map, charsmax(g_Config))
	strcat(g_Config, ".bmfw", charsmax(g_Config))

	if(file_exists(g_Config))
	{
		server_print("[BMFW] Configuracion file found for current map")
		_native_bm_load()
	}
}

public plugin_natives()
{
	register_library(PLUGIN_CVAR)
	register_native("_set_handler", "_native_set_handler")
	register_native("_reg_block", "_native_reg_block")
	register_native("_bm_load", "_native_bm_load")
	register_native("_bm_save", "_native_bm_save")
	register_native("_bm_cleanup", "_native_bm_cleanup")
	register_native("_bm_rotate_block", "_native_rotate_block")
	register_native("_bm_create_block", "_native_create_block")

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
	server_print("[BMFW] Block registered %i:%s", g_Count, name)
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
//// BMFW COMMANDS
////////////////////////////////////////////////////////////////////

public bm_list(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	for(new bType = 0; bType <= g_Count; bType++)
	{
		client_print(id, print_console, "Block %i %s:%s", bType, g_Blocks[bType][bName], g_Blocks[bType][bModel])
	}
	return PLUGIN_HANDLED
}

public bm_load(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	_native_bm_load()
	return PLUGIN_HANDLED
}

public bm_save(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	_native_bm_save(id)
	return PLUGIN_HANDLED
}

public bm_add(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	if(g_BlocksCount >= MAX_ENTBLOCKS)
	{
		server_print("[BMFW] You have reached the maximum of blocks you can create")
		return PLUGIN_HANDLED
	}

	if(entity_count() > (0.9 * g_MaxEntities))
	{
		server_print("[BMFW] There's no enought save space for new entities")
		return PLUGIN_HANDLED
	}

	static szTemp[32], size[2]
	read_argv(1, szTemp, charsmax(szTemp))
	read_argv(2, size, charsmax(size))

	new bType = _get_bm_id(szTemp)

	if((bType > g_Count) || (bType < 0))
		return PLUGIN_HANDLED

	new origin[3], Float:vorigin[3]
	get_user_origin(id, origin, 3)
	IVecFVec(origin, vorigin)

	_native_create_block(bType, vorigin, size)
	return PLUGIN_HANDLED
}

public bm_del(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new ent, body
	get_user_aiming(id, ent, body)
	if(_bm_is_block(ent) && !_bm_is_grabbed(ent))
	{
		remove_entity(ent)
		g_BlocksCount--
	}
	return PLUGIN_HANDLED
}

public bm_rotate(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	new ent, body
	get_user_aiming(id, ent, body)
	if(_bm_is_block(ent) && !_bm_is_grabbed(ent))
	{
		_native_rotate_block(ent, -1)
	}
	return PLUGIN_HANDLED
}

public bm_cleanup(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	_native_bm_cleanup()
	return PLUGIN_HANDLED
}

public bm_grab_release(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

	g_PlayerGrab[id] = 0
	return PLUGIN_HANDLED
}

public bm_grab_hold(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED

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

public _native_bm_save(id)
{
	new ent
	new name[32], model[128], line[256], size[2]
	new Float:vOrigin[3], Float:vAngles[3]
	new type, angle, count

	server_print("[BMFW] Saving blocks to file %s", g_Config)

	if(file_exists(g_Config))
		unlink(g_Config)

	new fh = fopen(g_Config, "wt")

	if(!fh)
	{
		server_print("[BMFW] An error ocurred while writing blocks to file")
		return PLUGIN_HANDLED
	}

	while((ent = find_ent_by_class(ent, BM_CLASSNAME)))
	{
		if(!is_valid_ent(ent)) continue

		count++
		type = entity_get_int(ent, EV_INT_body)
		copy(name, charsmax(name), g_Blocks[type][bModel])
		entity_get_vector(ent, EV_VEC_origin, vOrigin)
		entity_get_vector(ent, EV_VEC_angles, vAngles)
		entity_get_string(ent, EV_SZ_model, model, charsmax(model))

		if(vAngles[0] == 0.0 && vAngles[2] == 0.0)
		{
			angle = 0
		}
		else if(vAngles[0] == 90.0 && vAngles[2] == 0.0)
		{
			angle = 1
		}
		else
		{
			angle = 2
		}

		if(contain(model, "_large.mdl") != -1)
		{
			size[0] = 'l'
		}
		else if(contain(model, "_small.mdl") != -1)
		{
			size[0] = 's'
		}
		else
		{
			size[0] = 'd'
		}

		formatex(line, charsmax(line), "%s %s %i %f %f %f^n", name, size, angle, vOrigin[0], vOrigin[1], vOrigin[2])
		fputs(fh, line)
	}
	fclose(fh)
	server_print("[BMFW] Saved %i blocks in %s file", count, g_Config)
	client_print(id, print_console, "[BMFW] Saved %i blocks in %s file", count, g_Config)

	return PLUGIN_HANDLED
}

public _native_bm_load()
{
	new ent
	new line[256]
	new name[32], size[2], angle[2], vx[16], vy[16], vz[16]
	new Float:vorigin[3]

	// We need to remove every block before populate new ones from file
	_native_bm_cleanup()
	new fh = fopen(g_Config, "rt")
	while(!feof(fh))
	{
		if(fgets(fh, line, charsmax(line)))
		{
			parse(line, name, charsmax(name), size, charsmax(size), angle, charsmax(angle), vx, charsmax(vx), vy, charsmax(vy), vz, charsmax(vz))

			vorigin[0] = str_to_float(vx)
			vorigin[1] = str_to_float(vy)
			vorigin[2] = str_to_float(vz)
			ent = _native_create_block(_get_bm_id(name), vorigin, size)
			if(is_valid_ent(ent))
				_native_rotate_block(ent, str_to_num(angle))
		}
	}
	fclose(fh)
	return PLUGIN_HANDLED
}

public _native_bm_cleanup()
{
	new ent
	while((ent = find_ent_by_class(ent, BM_CLASSNAME)))
	{
		if(!is_valid_ent(ent)) continue
		remove_entity(ent)
	}
}

public _native_rotate_block(ent, opt)
{
	new Float:vAngles[3], Float:vMins[3], Float:vMaxs[3], Float:ftemp

	entity_get_vector(ent, EV_VEC_angles, vAngles)
	entity_get_vector(ent, EV_VEC_mins, vMins)
	entity_get_vector(ent, EV_VEC_maxs, vMaxs)

	switch(opt)
	{
		case -1:
		{
			if(vAngles[0] == 0.0 && vAngles[2] == 0.0)
			{
				vAngles[0] = 90.0
			}
			else if(vAngles[0] == 90.0 && vAngles[2] == 0.0)
			{
				vAngles[0] = 90.0
				vAngles[2] = 90.0
			}
			else
			{
				vAngles = Float:{0.0, 0.0, 0.0}
			}

			ftemp = vMins[0]
			vMins[0] = vMins[2]
			vMins[2] = vMins[1]
			vMins[1] = ftemp
			ftemp = vMaxs[0]
			vMaxs[0] = vMaxs[2]
			vMaxs[2] = vMaxs[1]
			vMaxs[1] = ftemp
		}
		case 1:
		{
			vAngles[0] = 90.0

			ftemp = vMins[0]
			vMins[0] = vMins[2]
			vMins[2] = vMins[1]
			vMins[1] = ftemp
			ftemp = vMaxs[0]
			vMaxs[0] = vMaxs[2]
			vMaxs[2] = vMaxs[1]
			vMaxs[1] = ftemp
		}
		case 2:
		{
			vAngles[0] = vAngles[2] = 90.0

			ftemp = vMins[0]
			vMins[0] = vMins[1]
			vMins[1] = vMins[2]
			vMins[2] = ftemp
			ftemp = vMaxs[0]
			vMaxs[0] = vMaxs[1]
			vMaxs[1] = vMaxs[2]
			vMaxs[2] = ftemp
		}
		default:
		{
			vAngles = Float:{0.0, 0.0, 0.0}
		}
	}
			

	entity_set_vector(ent, EV_VEC_angles, vAngles)
	entity_set_size(ent, vMins, vMaxs)
}

public _native_create_block(bType, Float:vorigin[3], size[2])
{
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
				callfunc_end()
				return ent
			}
		}
	}
	return ent
}

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

public _bm_is_on_block(id, touched)
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
		if(_bm_is_block(ent) && _bm_is_touched(ent, TOUCH_FOOT | TOUCH_ALL | TOUCH_BOTH) && (ent == touched))
			return ent

		vHead[0] = pOrigin[0] + g_Corners[0][i]
		vHead[1] = pOrigin[1] - g_Corners[1][i]
		ent = trace_line(id, pOrigin, vHead, vReturn)
		if(_bm_is_block(ent) && _bm_is_touched(ent, TOUCH_HEAD | TOUCH_ALL | TOUCH_BOTH) && (ent == touched))
			return ent
	}

	return false
}

public _bm_snap(ent, Float:vOrigin[3])
{
	new Float:snapsize = 20.0
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

public _get_bm_id(const name[32])
{
	for(new i = 0; i <= g_Count; i++)
	{
		if(equal(g_Blocks[i][bModel], name))
			return i
	}
	return -1
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
	if(!toucher || !touched || !is_user_alive(toucher) || !_bm_is_block(touched))
		return PLUGIN_CONTINUE

	new bType = entity_get_int(touched, EV_INT_body)
	if(!(g_Blocks[bType][bTouch] & (TOUCH_ALL | TOUCH_FOOT | TOUCH_HEAD | TOUCH_OTHER)))
		return PLUGIN_CONTINUE

	new flags = entity_get_int(toucher, EV_INT_flags)
	if(!(flags & FL_ONGROUND))
		return PLUGIN_CONTINUE

	if(!(g_Blocks[bType][bTouch] & TOUCH_ALL) && !_bm_is_on_block(toucher, touched))
		return PLUGIN_CONTINUE

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

	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

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
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE

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

