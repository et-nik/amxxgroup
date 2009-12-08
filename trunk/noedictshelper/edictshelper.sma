#include <amxmodx> 
#include <engine> 
#include <fakemeta> 
#include <hamsandwich> 

#define PLUGIN_NAME "No Edicts Helper"
#define PLUGIN_AUTHOR "JoRoPiTo"
#define PLUGIN_VERSION "1.0"

#define BSPMAX 500

new g_MaxClients
new g_MaxEntities
new g_Threshold
new g_ShouldDelete

new g_Init
new g_WorldCount
new g_LastCount

new gf_Spawn
new gf_CreateEntity
new gf_CreateNamedEntity

new g_BspTop
new g_Players[32]

public plugin_init() 
{ 
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	g_Init = 1
	g_WorldCount = g_LastCount
	server_print("Plugin initialized")
	server_print("World entities: %i", g_WorldCount)
	register_concmd("check_edicts", "do_magic")

	unregister_forward(FM_Spawn, gf_Spawn)
	// unregister_forward(FM_CreateEntity, gf_CreateEntity)
	// unregister_forward(FM_CreateNamedEntity, gf_CreateNamedEntity)
} 

public plugin_precache()
{
	g_Threshold = register_cvar("amx_ents_threshold", "95")
	g_ShouldDelete = register_cvar("amx_ents_autodelete", "0")

	g_MaxClients = global_get(glb_maxClients)
	g_MaxEntities = global_get(glb_maxEntities)

	gf_Spawn = register_forward(FM_Spawn, "fwd_Spawn", 1)
	gf_CreateEntity = register_forward(FM_CreateEntity, "fwd_CreateEntity", 0)
	gf_CreateNamedEntity = register_forward(FM_CreateNamedEntity, "fwd_CreateNamedEntity", 0)
}

public client_putinserver(id) g_Players[id] = 1
public client_disconnect(id) g_Players[id] = 0

////////////////////////////////////////////////////////////////////////

stock check_entities()
{
	g_WorldCount = engfunc(EngFunc_NumberOfEntities)

	server_print("Checking entities in world (current:%i last:%i)", g_WorldCount, g_LastCount)
	if((g_WorldCount > (110 * g_LastCount / 100)) || (g_WorldCount > (get_pcvar_num(g_Threshold) * g_MaxEntities / 100)))
	{
		g_LastCount = g_WorldCount
		do_magic()
	}
	return
}

stock kill_entity(Ent)
{
	server_print("Removing entity %i", Ent)
	remove_entity(Ent)
}

////////////////////////////////////////////////////////////////////////

public fwd_CreateNamedEntity(Class[])
{
	if(g_Init)
		check_entities()

	return FMRES_IGNORED
}

public fwd_CreateEntity()
{
	if(g_Init)
		check_entities()

	return FMRES_IGNORED
}

public fwd_Spawn(Ent)
{
	if(!g_Init)
	{
		g_BspTop = Ent
	}

	g_LastCount++

	return FMRES_IGNORED
}

public do_magic()
{
	new Ent, Result

	server_print("Starting entity consistency check")
	server_print("Number of entities in map is %i (bsptop:%i last:%i)", g_WorldCount, g_BspTop, g_LastCount)
	for(Ent = (g_BspTop + 1); Ent < g_MaxEntities; Ent++)
	{
		if(!pev_valid(Ent))
			continue

		Result = validate_ent(Ent)
		if(Result)
		{
			server_print("Detected orphan entity %i", Ent)
			if(get_pcvar_num(g_ShouldDelete))
				kill_entity(Ent)
		}
	}
	server_print("Finished entity consistency check")
}

public validate_ent(Ent)
{
	static Class[33]
	static Model[33]
	static Owner

	Owner = pev(Ent, pev_owner)
	pev(Ent, pev_classname, Class, charsmax(Class))
	pev(Ent, pev_model, Model, charsmax(Model))

	// Check for unlinked entities
	if(!Owner)
	{
		server_print("Invalid entity %i: unlinked entities", Ent)
		return true
	}

	// Check for linked entities to disconnected player
	if(Owner && (Owner <= g_MaxClients) && !g_Players[Owner])
	{
		server_print("Invalid entity %i: disconnected player (owner:%i)", Ent, Owner)
		return true
	}

	return false
}
