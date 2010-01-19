/*

Cvars:
	dyndns_mode: 0 | 1 | 2 => 0=Custom Service - 1=DynDNS Service - 2=NO-IP Service
	dyndns_hostname: xxx.dyndns.org => Hostname to update (use domain selected on service provider)
	dyndns_username: User account name on selected service provider
	dyndns_password: Password for username


	Options for dyndns_mode = 0
		dyndns_provider: Textual name of service provider (informational purpose)
		dyndns_host: Host or IP Address of update gateway
		dyndns_url: URL for custom updated service



Credits
	Black Rose (base64 code) --- http://forums.alliedmods.net/showpost.php?p=777210&postcount=4

*/

#include <amxmodx>
#include <sockets>

#define PLUGIN_NAME	"DynDNS Client"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"dyndns"

new gp_mode
new gp_provider
new gp_host
new gp_url
new gp_hostname
new gp_username
new gp_password

// DYNDNS Web Update API Specific information

new const g_provider[][] =
{
	"custom",
	"dyndns.org",
	"no-ip.com"
}

new const g_host[][] =
{
	"",
	"members.dyndns.org",
	"dynupdate.no-ip.com"
}

new const g_url[][] =
{
	"/nic/update?hostname=",
	"/nic/update?hostname=",
	"/nic/update?hostname="
}

//--------------------------------------------

new const sBase64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	gp_mode = register_cvar("dyndns_mode", "1")
	gp_provider = register_cvar("dyndns_provider", g_provider[0])
	gp_host = register_cvar("dyndns_host", g_host[0])
	gp_url = register_cvar("dyndns_url", g_url[0])
	gp_hostname = register_cvar("dyndns_hostname", "")
	gp_username = register_cvar("dyndns_username", "")
	gp_password = register_cvar("dyndns_password", "")

}

public plugin_cfg()
{
	set_task(5.0, "update_request")
}

/* Encodes a string to Base64 */
stock encode64(const sString[], sResult[], len) {

	new const cFillChar = '=';
	new nLength = strlen(sString);
	new resPos;
	
	for ( new nPos = 0 ; nPos < nLength ; nPos++ ) {
		new cCode;
		cCode = (sString[nPos] >> 2) & 0x3f;
		resPos += formatex(sResult[resPos], len, "%c", sBase64Table[cCode]);
		cCode = (sString[nPos] << 4) & 0x3f;

		if(++nPos < nLength)
			cCode |= (sString[nPos] >> 4) & 0x0f;

		resPos += formatex(sResult[resPos], len, "%c", sBase64Table[cCode]);

		if ( nPos < nLength )
		{
			cCode = (sString[nPos] << 2) & 0x3f;
			if(++nPos < nLength)
				cCode |= (sString[nPos] >> 6) & 0x03;

			resPos += formatex(sResult[resPos], len, "%c", sBase64Table[cCode]);
		}
		else
		{
			nPos++;
			resPos += formatex(sResult[resPos], len, "%c", cFillChar);
		}

		if(nPos < nLength)
		{
			cCode = sString[nPos] & 0x3f;
			resPos += formatex(sResult[resPos], len, "%c", sBase64Table[cCode]);
		}
		else
		{
			resPos += formatex(sResult[resPos], len, "%c", cFillChar);
		}
	}
}

public update_request()
{
	new mode, provider[64], host[64], url[64], hostname[64]
	new username[32], password[32], plain[64], encoded[64]

	mode = get_pcvar_num(gp_mode)
	get_pcvar_string(gp_username, username, charsmax(username))
	get_pcvar_string(gp_password, password, charsmax(password))
	get_pcvar_string(gp_hostname, hostname, charsmax(hostname))

	formatex(plain, charsmax(plain), "%s:%s", username, password)
	encode64(plain, encoded, charsmax(encoded))

	if(!mode)
	{
		get_pcvar_string(gp_url, url, charsmax(url))
		get_pcvar_string(gp_host, host, charsmax(host))
		get_pcvar_string(gp_provider, provider, charsmax(provider))
	}
	else
	{
		copy(url, charsmax(url), g_url[mode])
		copy(host, charsmax(host), g_host[mode])
		copy(provider, charsmax(provider), g_provider[mode])
	}

	if(0 < mode < sizeof(g_provider))
	{
		new error, socket
		new request[512], request2[512]

		socket = socket_open(host, 80, SOCKET_TCP, error)
		if(socket > 0)
		{
			server_print("Updating on %s for %s", provider, hostname)
			formatex(request, charsmax(request), "GET %s%s HTTP/1.0^n", url, hostname)
			formatex(request2, charsmax(request2), "%sHost: %s^n", request, host)
			formatex(request, charsmax(request), "%sAuthorization: Basic %s^n", request2, encoded)
			formatex(request2, charsmax(request2), "%sUser-Agent: %s - %s - %s^n^n", request, PLUGIN_NAME, PLUGIN_AUTHOR, PLUGIN_VERSION)
			socket_send(socket, request2, charsmax(request2))
		}
	}
}

