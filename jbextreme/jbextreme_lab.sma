#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>

#define PLUGIN_NAME     "JailBreak Extreme Lab"
#define PLUGIN_AUTHOR   "JoRoPiTo"
#define PLUGIN_VERSION  "0.1"
#define PLUGIN_CVAR     "jbelab"

public plugin_init()
{
        register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
        register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

        register_concmd("test", "test")
}

public test(id)
{
        new ent = getbutton()
        if(ent)
        {
                server_print("Searching for button %i", ent)
                fm_set_rendering(ent, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 50)
        }
        else
        {
                server_print("Not found")
        }
        return PLUGIN_HANDLED
}

public getbutton()
{
        new ent = -1
        new ent2
        new ent3
        new Float:origin[3]
        new Float:radius = 2000.0
        new class[32]
        new name[32]
        while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_deathmatch")))
        {
                ent2 = 1
                pev(ent, pev_origin, origin)
                while((ent2 = engfunc(EngFunc_FindEntityInSphere, ent2, origin, radius)))
                {
                        if(!pev_valid(ent2))
                                continue

                        pev(ent2, pev_classname, class, charsmax(class))
                        if(!equal(class, "func_door"))
                                continue

                        pev(ent2, pev_targetname, name, charsmax(name))
                        ent3 = engfunc(EngFunc_FindEntityByString, 0, "target", name)
                        pev(ent3, pev_classname, class, charsmax(class))
						if(equal(class, "func_button") || equal(class, "button_target"))
                                return ent3
                }
        }
        return 0
}
