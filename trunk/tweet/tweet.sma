/*

Cvars:
	tweet_username: Login name in twitter
	tweet_password: Password for username
	tweet_mode: 0 [only admin] / 1 [allow everyone]


Credits
	Black Rose (base64 code) --- http://forums.alliedmods.net/showpost.php?p=777210&postcount=4

*/

#include <amxmodx>
#include <sockets>

#define PLUGIN_NAME	"Twitter Client"
#define PLUGIN_AUTHOR	"JoRoPiTo"
#define PLUGIN_VERSION	"1.0"
#define PLUGIN_CVAR	"tweet"

new gp_mode
new gp_username
new gp_password
new gp_delay

new const g_host[] = "twitter.com"
new const g_url[] = "/statuses/update.xml?status="

new Float:g_last[33]

//--------------------------------------------

new const sBase64Table[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
new const sHexTable[] = "0123456789abcdef"

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_cvar(PLUGIN_CVAR, PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)

	gp_mode = register_cvar("tweet_mode", "1")		// 0=All Users / 1=Only Admin
	gp_username = register_cvar("tweet_username", "")
	gp_password = register_cvar("tweet_password", "")
	gp_delay = register_cvar("tweet_delay", "15.0")
}

public plugin_cfg()
{
	register_clcmd("say", "say_handler")
}

/* Encodes a string to Base64 */
stock encode64(const sString[], sResult[], len)
{

	new const cFillChar = '=';
	new nLength = strlen(sString);
	new resPos;
	
	for ( new nPos = 0 ; nPos < nLength ; nPos++ )
	{
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

stock urlencode(const sString[], sResult[], len)
{
	new from, c
	new to

	while(from < len)
	{
		c = sString[from++]
		if(c == 0)
		{
			sResult[to++] = c
			return
		}
		else if(c == ' ')
		{
			sResult[to++] = '+'
		}
		else if((c < '0' && c != '-' && c != '.') ||
				(c < 'A' && c > '9') ||
				(c > 'Z' && c < 'a' && c != '_') ||
				(c > 'z'))
		{
			sResult[to] = '%'
			sResult[to+1] = sHexTable[c >> 4]
			sResult[to+2] = sHexTable[c & 15]
			to += 3
		}
		else
		{
			sResult[to++] = c
		}
	}
}

public say_handler(id)
{
	static message[64], Float:now, Float:delay, mode
	read_args(message, 63)

	if(!(message[0] == '@') || !(message[1] == 't') || !(message[2] == 'w') || !(message[3] == ' '))
		return PLUGIN_CONTINUE

	mode = get_pcvar_num(gp_mode)
	if(mode && !(get_user_flags(id) & 4095))
		return PLUGIN_HANDLED

	delay = get_pcvar_float(gp_delay)
	now = get_gametime()
	if(now > (g_last[id] + delay))
	{
		client_print(id, print_chat, "You have to wait %f seconds to tweet again!", (now - delay))
		return PLUGIN_HANDLED
	}

	g_last[id] = now

	static name[32], username[32], password[32], encoded[64], plain[64]

	get_user_name(id, name, charsmax(name))
	get_pcvar_string(gp_username, username, charsmax(username))
	get_pcvar_string(gp_password, password, charsmax(password))

	formatex(plain, charsmax(plain), "%s:%s", username, password)
	encode64(plain, encoded, charsmax(encoded))

	new error, socket
	new request[512], request2[512], tmp[64]

	urlencode(message[4], tmp, charsmax(tmp))
	
	socket = socket_open(g_host, 80, SOCKET_TCP, error)
	if(socket > 0)
	{
		formatex(request, charsmax(request), "POST %s%s HTTP/1.1^n", g_url, tmp)
		formatex(request2, charsmax(request2), "%sHost: %s^nAccept-Encoding: none^n", request, g_host)
		formatex(request, charsmax(request), "%sAuthorization: Basic %s^n", request2, encoded)
		formatex(request2, charsmax(request2), "%sConnection: Close^n^n", request)
		socket_send(socket, request2, charsmax(request2))
		server_print("Tweet sent (%s) ^"%s^"", name, message)
	}
	else
	{
		server_print("Socket error %i", error)
	}
	return PLUGIN_HANDLED
}

