/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/

#include "quakedef.h"
#include "winquake.h"
#include "menu.h"
#include "teamplay.h"
#include "version.h"


void SCR_RSShot_f (void);
void CL_ProcessServerInfo (void);
void SV_Serverinfo_f (void);
void Key_WriteBindings (FILE *f);
void S_StopAllSounds (qboolean clear);

/*
===================
Cmd_ForwardToServer

adds the current command line as a clc_stringcmd to the client message.
things like kill, say, etc, are commands directed to the server,
so when they are typed in at the console, they will need to be forwarded.
===================
*/
void Cmd_ForwardToServer (void)
{
	char	*s;

	if (cls.state == ca_disconnected)
	{
		Com_Printf ("Can't \"%s\", not connected\n", Cmd_Argv(0));
		return;
	}

	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	// lowercase command
	for (s=Cmd_Argv(0) ; *s ; s++)
		*s = (char)tolower(*s);
	SZ_Print (&cls.netchan.message, Cmd_Argv(0));
	if (Cmd_Argc() > 1)
	{
		SZ_Print (&cls.netchan.message, " ");
		SZ_Print (&cls.netchan.message, Cmd_Args());
	}
}

// don't forward the first argument
void CL_ForwardToServer_f (void)
{
	if (cls.state == ca_disconnected)
	{
		Com_Printf ("Can't \"%s\", not connected\n", Cmd_Argv(0));
		return;
	}

	if (Q_stricmp(Cmd_Argv(1), "snap") == 0) {
		SCR_RSShot_f ();
		return;
	}
	
	if (cls.demoplayback)
		return;		// not really connected

	if (Cmd_Argc() > 1)
	{
		MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
		SZ_Print (&cls.netchan.message, Cmd_Args());
	}
}

/*
===============
CL_Say_f

Handles both say and say_team
===============
*/
void CL_Say_f (void)
{
	char	*s;

	if (cls.state == ca_disconnected)
	{
		Com_Printf ("Can't \"%s\", not connected\n", Cmd_Argv(0));
		return;
	}

	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	// lowercase command
	for (s=Cmd_Argv(0) ; *s ; s++)
		*s = (char)tolower(*s);
	SZ_Print (&cls.netchan.message, Cmd_Argv(0));
	if (Cmd_Argc() > 1)
	{
		SZ_Print (&cls.netchan.message, " ");

		s = TP_ParseMacroString (Cmd_Args());
		s = TP_ParseFunChars (s, true);
		if (*s && *s < 32)
		{
			SZ_Print (&cls.netchan.message, "\"");
			SZ_Print (&cls.netchan.message, s);
			SZ_Print (&cls.netchan.message, "\"");
		}
		else
			SZ_Print (&cls.netchan.message, s);
	}
}


/*
=====================
CL_Pause_f
=====================
*/
void CL_Pause_f (void)
{
	if (cls.demoplayback)
		cl.paused ^= PAUSED_DEMO;
	else
		Cmd_ForwardToServer();
}


/*
====================
CL_Packet_f

packet <destination> <contents>

Contents allows \n escape character
====================
*/
void CL_Packet_f (void)
{
	char	send[2048];
	int		i, l;
	char	*in, *out;
	netadr_t	adr;

	if (Cmd_Argc() != 3)
	{
		Com_Printf ("packet <destination> <contents>\n");
		return;
	}

	if (!NET_StringToAdr (Cmd_Argv(1), &adr))
	{
		Com_Printf ("Bad address\n");
		return;
	}

	if (adr.port == 0)
		adr.port = BigShort (PORT_SERVER);

	in = Cmd_Argv(2);
	out = send+4;
	send[0] = send[1] = send[2] = send[3] = 0xff;

	l = strlen (in);
	for (i=0 ; i<l ; i++)
	{
		if (in[i] == '\\' && in[i+1] == 'n')
		{
			*out++ = '\n';
			i++;
		}
		else
			*out++ = in[i];
	}
	*out = 0;

	NET_SendPacket (NS_CLIENT, out-send, send, adr);
}


void CL_PrintQStatReply (char *s)
{
	char *p;
	int n, numplayers;
	int userid, frags, time, ping, topcolor, bottomcolor;
	char name[33], skin[17];
	
	Com_Printf ("\n");
	//Com_Printf ("-------------------------------------\n");

	con_ormask = 128;
	Com_Printf ("qstat %s:\n", NET_AdrToString(net_from));
	con_ormask = 0;

	// count players
	numplayers = -1;
	p = s;
	while (*p) if (*p++ == '\n') numplayers++;

	// extract serverinfo string
	s = strtok (s, "\n");

	Com_Printf ("hostname   %s\n", Info_ValueForKey(s, "hostname"));
	if (*(p = Info_ValueForKey(s, "*gamedir")) && strcmp(p, "qw"))
		Com_Printf ("gamedir    %s\n", p);
	Com_Printf ("map        %s\n", Info_ValueForKey(s, "map"));
	if (*(p = Info_ValueForKey(s, "status")))
		Com_Printf ("status     %s\n", p);
	//	Com_Printf ("deathmatch %s\n", Info_ValueForKey(s, "deathmatch"));
	//	Com_Printf ("teamplay   %s\n", Info_ValueForKey(s, "teamplay"));
	//	Com_Printf ("timelimit  %s\n", Info_ValueForKey(s, "timelimit"));
	//	Com_Printf ("fraglimit  %s\n", Info_ValueForKey(s, "fraglimit"));
	if ((n = Q_atoi(Info_ValueForKey(s, "needpass")) & 3) != 0)
		Com_Printf ("needpass   %s%s%s\n", n & 1 ? "player" : "",
			n == 3 ? ", " : "", n & 2 ? "spectator" : "");
/*	if (Q_atoi(Info_ValueForKey(s, "needpass")) & 1)
		Com_Printf ("player password required\n");
	if (Q_atoi(Info_ValueForKey(s, "needpass")) & 2)
		Com_Printf ("spectator password required\n");*/

	Com_Printf ("players    %i/%s\n", numplayers, Info_ValueForKey(s, "maxclients"));

	p = strtok (NULL, "\n");
	
	if (p)
	{
		con_ormask = 128;
		Com_Printf ("\nping time frags name\n");
		con_ormask = 0;
		//Com_Printf ("-------------------------------------\n");
		
		while (p)
		{
			sscanf (p, "%d %d %d %d \"%32[^\"]\" \"%16[^\"]\" %d %d", 
				&userid, &frags, &time, &ping, &name, &skin, &topcolor, &bottomcolor);
			Com_Printf("%4d %4d %4d  %-16.16s\n", ping, time, frags, name);
			p = strtok (NULL, "\n");
		}
		//Com_Printf ("-------------------------------------\n");
	}

	Com_Printf ("\n");
}

/*
====================
CL_QStat_f

qstat <destination>
====================
*/
double	qstat_senttime = 0;

void CL_QStat_f (void)
{
	char	send[10] = {0xff, 0xff, 0xff, 0xff, 's', 't', 'a', 't', 'u', 's'};
	netadr_t	adr;

	if (Cmd_Argc() < 2)
	{
		Com_Printf ("usage: qstat <server>\n");
		return;
	}

	if (!NET_StringToAdr (Cmd_Argv(1), &adr))
	{
		Com_Printf ("Bad address\n");
		return;
	}

	if (adr.port == 0)
		adr.port = BigShort (PORT_SERVER);

	NET_SendPacket (NS_CLIENT, 10, send, adr);

	qstat_senttime = curtime;
}


/*
=====================
CL_Rcon_f

Send the rest of the command line over as
an unconnected command.
=====================
*/
void CL_Rcon_f (void)
{
	char	message[1024];
	int		i;
	netadr_t	to;
	extern cvar_t	rcon_password, rcon_address;

	message[0] = 255;
	message[1] = 255;
	message[2] = 255;
	message[3] = 255;
	message[4] = 0;

	strcat (message, "rcon ");

	if (rcon_password.string[0])
	{
		strcat (message, rcon_password.string);
		strcat (message, " ");
	}

	for (i=1 ; i<Cmd_Argc() ; i++)
	{
		strcat (message, Cmd_Argv(i));
		strcat (message, " ");
	}

	if (cls.state >= ca_connected)
		to = cls.netchan.remote_address;
	else
	{
		if (!strlen(rcon_address.string))
		{
			Com_Printf ("You must either be connected,\n"
						"or set the 'rcon_address' cvar\n"
						"to issue rcon commands\n");

			return;
		}
		NET_StringToAdr (rcon_address.string, &to);
		if (to.port == 0)
			to.port = BigShort (PORT_SERVER);
	}
	
	NET_SendPacket (NS_CLIENT, strlen(message)+1, message
		, to);
}


/*
=====================
CL_Download_f
=====================
*/
void CL_Download_f (void)
{
	char *p, *q;

	if (cls.state == ca_disconnected)
	{
		Com_Printf ("Must be connected.\n");
		return;
	}

	if (Cmd_Argc() != 2)
	{
		Com_Printf ("Usage: download <datafile>\n");
		return;
	}

	Q_snprintfz (cls.downloadname, sizeof(cls.downloadname),
		"%s/%s", cls.gamedir, Cmd_Argv(1));

	p = cls.downloadname;
	for (;;) {
		if ((q = strchr(p, '/')) != NULL) {
			*q = 0;
			Sys_mkdir(cls.downloadname);
			*q = '/';
			p = q + 1;
		} else
			break;
	}

	strcpy(cls.downloadtempname, cls.downloadname);
	cls.download = fopen (cls.downloadname, "wb");
	cls.downloadtype = dl_single;

	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	SZ_Print (&cls.netchan.message, va("download %s\n",Cmd_Argv(1)));
}


/*
====================
CL_User_f

user <name or userid>

Dump userdata / masterdata for a user
====================
*/
void CL_User_f (void)
{
	int		uid;
	int		i;

	if (Cmd_Argc() != 2)
	{
		Com_Printf ("Usage: user <username / userid>\n");
		return;
	}

	uid = atoi(Cmd_Argv(1));

	for (i=0 ; i<MAX_CLIENTS ; i++)
	{
		if (!cl.players[i].name[0])
			continue;
		if (cl.players[i].userid == uid
		|| !strcmp(cl.players[i].name, Cmd_Argv(1)) )
		{
			Info_Print (cl.players[i].userinfo);
			return;
		}
	}
	Com_Printf ("User not in server.\n");
}

/*
====================
CL_Users_f

Dump userids for all current players
====================
*/
void CL_Users_f (void)
{
	int		i;
	int		c;

	c = 0;
	Com_Printf ("userid frags name\n");
	Com_Printf ("------ ----- ----\n");
	for (i=0 ; i<MAX_CLIENTS ; i++)
	{
		if (cl.players[i].name[0])
		{
			Com_Printf ("%6i %4i %s\n", cl.players[i].userid, cl.players[i].frags, cl.players[i].name);
			c++;
		}
	}

	Com_Printf ("%i total users\n", c);
}

/*
====================
CL_Color_f

Just for quake compatability
====================
*/
void CL_Color_f (void)
{
	extern cvar_t	topcolor, bottomcolor;
	int		top, bottom;
	char	num[16];

	if (Cmd_Argc() == 1)
	{
		Com_Printf ("\"color\" is \"%s %s\"\n",
			Info_ValueForKey (cls.userinfo, "topcolor"),
			Info_ValueForKey (cls.userinfo, "bottomcolor") );
		Com_Printf ("color <0-13> [0-13]\n");
		return;
	}

	if (Cmd_Argc() == 2)
		top = bottom = atoi(Cmd_Argv(1));
	else
	{
		top = atoi(Cmd_Argv(1));
		bottom = atoi(Cmd_Argv(2));
	}
	
	top &= 15;
	if (top > 13)
		top = 13;
	bottom &= 15;
	if (bottom > 13)
		bottom = 13;
	
	sprintf (num, "%i", top);
	Cvar_Set (&topcolor, num);
	sprintf (num, "%i", bottom);
	Cvar_Set (&bottomcolor, num);
}


/*
==================
CL_FullInfo_f

usage:
fullinfo \name\unnamed\topcolor\0\bottomcolor\1, etc
==================
Casey was here :)
*/
void CL_FullInfo_f (void)
{
	char	key[512];
	char	value[512];
	char	*o;
	char	*s;

	if (Cmd_Argc() != 2)
	{
		Com_Printf ("fullinfo <complete info string>\n");
		return;
	}

	s = Cmd_Argv(1);
	if (*s == '\\')
		s++;
	while (*s)
	{
		o = key;
		while (*s && *s != '\\')
			*o++ = *s++;
		*o = 0;

		if (!*s)
		{
			Com_Printf ("MISSING VALUE\n");
			return;
		}

		o = value;
		s++;
		while (*s && *s != '\\')
			*o++ = *s++;
		*o = 0;

		if (*s)
			s++;

		if (!Q_stricmp(key, pmodel_name) || !Q_stricmp(key, emodel_name))
			continue;

		Info_SetValueForKey (cls.userinfo, key, value, MAX_INFO_STRING);
	}
}

/*
==================
CL_SetInfo_f

Allow clients to change userinfo
==================
*/
void CL_SetInfo_f (void)
{
	if (Cmd_Argc() == 1)
	{
		Info_Print (cls.userinfo);
		return;
	}
	if (Cmd_Argc() != 3)
	{
		Com_Printf ("usage: setinfo [ <key> <value> ]\n");
		return;
	}
	if (!Q_stricmp(Cmd_Argv(1), pmodel_name) || !strcmp(Cmd_Argv(1), emodel_name))
		return;

	Info_SetValueForKey (cls.userinfo, Cmd_Argv(1), Cmd_Argv(2), MAX_INFO_STRING);
	if (cls.state >= ca_connected)
		Cmd_ForwardToServer ();
}


/*
==================
CL_Quit_f
==================
*/
void CL_Quit_f (void)
{
	extern void SV_Quit_f (void);
	extern cvar_t cl_confirmquit;

#ifndef CLIENTONLY
	if (dedicated)
		SV_Quit_f ();
	else
#endif
	{
		if (cl_confirmquit.value)
			M_Menu_Quit_f ();
		else
			Host_Quit ();
	}
}


/*
===============
CL_Windows_f
===============
*/
#ifdef _WINDOWS
void CL_Windows_f (void)
{
	SendMessage(mainwindow, WM_SYSKEYUP, VK_TAB, 1 | (0x0F << 16) | (1<<29));
}
#endif


/*
===============
CL_Serverinfo_f
===============
*/
void CL_Serverinfo_f (void)
{
#ifndef CLIENTONLY
	if (cls.state < ca_connected || com_serveractive) {
		SV_Serverinfo_f();
		return;
	}
#endif

	if (cls.state >= ca_onserver && cl.serverinfo)
		Info_Print (cl.serverinfo);
	else
		// so that it says we are not connected :)
		Cmd_ForwardToServer();	
}


//============================================================================

void CL_WriteConfig (char *name)
{
	FILE	*f;

	f = fopen (va("%s/%s", cls.gamedir, name), "w");
	if (!f) {
		Com_Printf ("Couldn't write %s.\n", name);
		return;
	}

	fprintf (f, "// Generated by " PROGRAM "\n");
	fprintf (f, "\n// Key bindings\n");
	Key_WriteBindings (f);
	fprintf (f, "\n// Variables\n");
	Cvar_WriteVariables (f);
	fprintf (f, "\n// Aliases\n");
	Cmd_WriteAliases (f);

	fclose (f);
}

/*
===============
CL_WriteConfiguration

Writes key bindings and archived cvars to config.cfg
===============
*/
void CL_WriteConfiguration (void)
{
	extern cvar_t	cl_writecfg;

	if (host_initialized && cl_writecfg.value)
		CL_WriteConfig ("config.cfg");
}

/*
===============
CL_WriteConfig_f

Writes key bindings and archived cvars to a custom config file
===============
*/
void CL_WriteConfig_f (void)
{
	char	name[MAX_OSPATH];

	if (Cmd_Argc() != 2) {
		Com_Printf ("usage: writeconfig <filename>\n");
		return;
	}

	Q_strncpyz (name, Cmd_Argv(1), sizeof(name));
	COM_ForceExtension (name, ".cfg");

	Com_Printf ("Writing %s\n", name);

	CL_WriteConfig (name);
}


void CL_InitCommands (void)
{
// general commands
	Cmd_AddCommand ("cmd", CL_ForwardToServer_f);
	Cmd_AddCommand ("download", CL_Download_f);
	Cmd_AddCommand ("qstat", CL_QStat_f);
	Cmd_AddCommand ("packet", CL_Packet_f);
	Cmd_AddCommand ("rcon", CL_Rcon_f);
	Cmd_AddCommand ("pause", CL_Pause_f);
	Cmd_AddCommand ("quit", CL_Quit_f);
	Cmd_AddCommand ("say", CL_Say_f);
	Cmd_AddCommand ("say_team", CL_Say_f);
	Cmd_AddCommand ("serverinfo", CL_Serverinfo_f);
	Cmd_AddCommand ("skins", Skin_Skins_f);
	Cmd_AddCommand ("allskins", Skin_AllSkins_f);
	Cmd_AddCommand ("user", CL_User_f);
	Cmd_AddCommand ("users", CL_Users_f);
	Cmd_AddCommand ("version", CL_Version_f);
	Cmd_AddCommand ("writeconfig", CL_WriteConfig_f);

#ifndef CLIENTONLY
	Cmd_AddCommand ("pointfile", CL_ReadPointFile_f);	
#endif

// client info setting
	Cmd_AddCommand ("color", CL_Color_f);
	Cmd_AddCommand ("fullinfo", CL_FullInfo_f);
	Cmd_AddCommand ("setinfo", CL_SetInfo_f);

// demo recording & playback
	Cmd_AddCommand ("record", CL_Record_f);
	Cmd_AddCommand ("easyrecord", CL_EasyRecord_f);
	Cmd_AddCommand ("stop", CL_Stop_f);
	Cmd_AddCommand ("playdemo", CL_PlayDemo_f);
	Cmd_AddCommand ("timedemo", CL_TimeDemo_f);

//
// forward to server commands
//
	Cmd_AddCommand ("kill", NULL);

//
//  Windows commands
//
#ifdef _WINDOWS
	Cmd_AddCommand ("windows", CL_Windows_f);
#endif
}


/*
==============================================================================

SERVER COMMANDS

Server commands are commands stuffed by server into client's cbuf
We use a separate command buffer for them -- there are several
reasons for that:
1. So that partially stuffed commands are always executed properly
2. Not to let players cheat in TF (v_cshift etc don't work in console)
3. To hide some commands the user doesn't need to know about, like
changing, fullserverinfo, nextul, stopul
==============================================================================
*/

/*
=================
CL_Changing_f

Just sent as a hint to the client that they should
drop to full console
=================
*/
void CL_Changing_f (void)
{
	cl.intermission = 0;

	if (cls.download)  // don't change when downloading
		return;

	S_StopAllSounds (true);
	cls.state = ca_connected;	// not active anymore, but not disconnected

	Com_Printf ("\nChanging map...\n");
}


/*
==================
CL_FullServerinfo_f

Sent by server when serverinfo changes
==================
*/
void CL_FullServerinfo_f (void)
{
	char *p;

	if (Cmd_Argc() != 2)
		return;

	Q_strncpyz (cl.serverinfo, Cmd_Argv(1), sizeof(cl.serverinfo));

	if ((p = Info_ValueForKey(cl.serverinfo, "*z_version")) && *p)
	{
		// only print version if connecting to a remote server
		if (!com_serveractive && !server_version)
				Com_Printf ("ZQuake %s server\n", p);
		server_version = 2.40;
	}
	else if ((p = Info_ValueForKey(cl.serverinfo, "*qf_version")) && *p) {
		if (!server_version)
			Com_Printf ("QuakeForge %s server\n", p);
		server_version = 2.40;
	}
	else if ((p = Info_ValueForKey(cl.serverinfo, "*version")) && *p) {
		float v;
		v = Q_atof(p);
		if (v) {
			if (!server_version)
				Com_Printf ("QuakeWorld %1.2f server\n", v);
			server_version = v;
		}
	}

	p = Info_ValueForKey (cl.serverinfo, "*cheats");
	if (*p)
		Com_Printf ("== Cheats are enabled ==\n");

	CL_ProcessServerInfo ();
}


void CL_Fov_f (void)
{
	extern cvar_t scr_fov, default_fov;

	if (Cmd_Argc() == 1)
	{
		Com_Printf ("\"fov\" is \"%s\"\n", scr_fov.string);
		return;
	}

	if (Q_atof(Cmd_Argv(1)) == 90.0 && default_fov.value)
		Cvar_SetValue (&scr_fov, default_fov.value);
	else
		Cvar_Set (&scr_fov, Cmd_Argv(1));
}


void CL_R_DrawViewModel_f (void)
{
	extern cvar_t cl_filterdrawviewmodel;

	if (cl_filterdrawviewmodel.value)
		return;
	Cvar_Command ();
}


typedef struct {
	char	*name;
	void	(*func) (void);
} svcmd_t;

svcmd_t svcmds[] =
{
	{"changing", CL_Changing_f},
	{"fullserverinfo", CL_FullServerinfo_f},
	{"nextul", CL_NextUpload},
	{"stopul", CL_StopUpload},
	{"fov", CL_Fov_f},
	{"r_drawviewmodel", CL_R_DrawViewModel_f},
	{NULL, NULL}
};

/*
================
CL_CheckServerCommand

Called by Cmd_ExecuteString if cbuf_current==&cbuf_svc
================
*/
qboolean CL_CheckServerCommand ()
{
	svcmd_t	*cmd;
	char	*s;

	s = Cmd_Argv (0);
	for (cmd=svcmds ; cmd->name ; cmd++)
		if (!strcmp (s, cmd->name) ) {
			cmd->func ();
			return true;
		}

	return false;
}

/*
==============================================================================

"LEGACY" COMMANDS (QuakeWorld compatibility)

==============================================================================
*/

typedef struct {
	cvar_t	*var;
	char *oldname;
} legacyvar_t;

extern cvar_t s_volume;
extern cvar_t s_nosound;
extern cvar_t s_precache;
extern cvar_t s_loadas8bit;
extern cvar_t s_ambientlevel;
extern cvar_t s_ambientfade;
extern cvar_t s_noextraupdate;
extern cvar_t s_show;
extern cvar_t s_mixahead;
extern cvar_t cl_demospeed;

legacyvar_t legacyvars[] =
{
	{&s_volume, "volume"},
	{&s_nosound, "nosound"},
	{&s_precache, "precache"},
	{&s_loadas8bit, "loadas8bit"},
	{&s_ambientlevel, "ambient_level"},
	{&s_ambientfade, "ambient_fade"},
	{&s_noextraupdate, "snd_noextraupdate"},
	{&s_show, "snd_show"},
	{&s_mixahead, "_snd_mixahead"},
	{&cl_demospeed, "demotimescale"},
	{NULL, NULL}
};

/*
================
CL_CheckServerCommand
================
*/
qboolean CL_LegacyCommand (void)
{
	int			i, c;
	char		*name;
	legacyvar_t *lvar;
	cvar_t		*v;
	char		string[1024];

	c = Cmd_Argc();
	name = Cmd_Argv(0);

	// Cheat commands. They are not added to normal command list
	// so they are invisible to user and an alias can override them
	if (!Q_stricmp(name, "god") || !Q_stricmp(name, "give") ||
		!Q_stricmp(name, "noclip"))
	{
		Cmd_ForwardToServer ();
		return true;
	}

	// this is to suppress the warning message when a mod stuffs
	// "play <sound.wav>" to the console but sound is not initialized
	if (!Q_stricmp(name, "play"))
		return true;

	for (lvar=legacyvars ; lvar->var ; lvar++) {
		if (!Q_stricmp(lvar->oldname, name))
			break;
	}
	if (!lvar->var)
		return false;

	v = lvar->var;

	if (c == 1)
	{
		Com_Printf ("\"%s\" is \"%s\"\n", v->name, v->string);
		return true;
	}

	string[0] = 0;
	for (i=1 ; i < c ; i++)
	{
		if (i > 1)
			strcat (string, " ");
		strcat (string, Cmd_Argv(i));
	}

	Cvar_Set (v, string);
	return true;
}
