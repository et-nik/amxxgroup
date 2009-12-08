#include <amxmodx>

#define PLUGIN_NAME	"Multi FastDL"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_AUTHOR	"JoRoPiTo"

#define PLUGIN_CONFIG	"multifastdl.ini"
#define MAX_URL		32

new g_last
new g_total
new g_url[MAX_URL][128]
new gp_downloadurl

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)

	gp_downloadurl = get_cvar_pointer("sv_downloadurl")

	new cfgdir[32], cfgfile[128], line[128]
	get_localinfo("amxx_configsdir", cfgdir, charsmax(cfgdir));
	formatex(cfgfile, charsmax(cfgfile), "%s/%s", cfgdir, PLUGIN_CONFIG)
	new f = fopen(cfgfile, "rt")
	while(!feof(f)) {
		new tmp[8]
		if(g_total == MAX_URL) break

		fgets(f, line, charsmax(line))
		trim(line)
		strcat(tmp, line, charsmax(tmp))
		strtolower(tmp)

		if(!equal(tmp, "http://")) continue

		copy(g_url[g_total], charsmax(g_url), line)
		g_total++
	}
	g_total--
	fclose(f)
}

public client_connect(id)
{
	g_last = (g_last < g_total) ? g_last + 1 : 0
	set_pcvar_string(gp_downloadurl, g_url[g_last])
	return PLUGIN_CONTINUE
}
