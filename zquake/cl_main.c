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
// cl_main.c  -- client main loop

#include <setjmp.h>
#include "quakedef.h"
#include "winquake.h"
#include "cdaudio.h"
#include "cl_slist.h"
#include "input.h"
#include "keys.h"
#include "pmove.h"
#include "sbar.h"
#include "sound.h"
#include "version.h"
#include "teamplay.h"

#ifdef QW_BOTH
#include "server.h"
#endif

#ifdef _WIN32
#include <winsock.h>
#else
#include <netinet/in.h>
#endif


cvar_t	rcon_password = {"rcon_password", ""};
cvar_t	rcon_address = {"rcon_address", ""};

cvar_t	cl_timeout = {"cl_timeout", "60"};

cvar_t	cl_shownet = {"cl_shownet", "0"};	// can be 0, 1, or 2

cvar_t	cl_sbar		= {"cl_sbar", "0", CVAR_ARCHIVE};
cvar_t	cl_hudswap	= {"cl_hudswap", "0", CVAR_ARCHIVE};
cvar_t	cl_maxfps	= {"cl_maxfps", "0", CVAR_ARCHIVE};

cvar_t	cl_writecfg = {"cl_writecfg", "1"};

cvar_t	entlatency = {"entlatency", "20"};
cvar_t	cl_predict_players = {"cl_predict_players", "1"};
cvar_t	cl_solid_players = {"cl_solid_players", "1"};

cvar_t  localid = {"localid", ""};

static qboolean allowremotecmd = true;

// ZQuake cvars
cvar_t	r_rocketlight = {"r_rocketLight", "1"};
cvar_t	r_rockettrail = {"r_rocketTrail", "1"};
cvar_t	r_grenadetrail = {"r_grenadeTrail", "1"};
cvar_t	r_powerupglow = {"r_powerupGlow", "1"};
cvar_t	cl_deadbodyfilter = {"cl_deadbodyFilter", "0"};
cvar_t	cl_explosion = {"cl_explosion", "0"};
cvar_t	cl_gibfilter = {"cl_gibFilter", "0"};
cvar_t	cl_muzzleflash = {"cl_muzzleflash", "1"};
cvar_t	cl_demospeed = {"cl_demospeed", "1"};
cvar_t	cl_staticsounds = {"cl_staticSounds", "1"};
cvar_t	cl_trueLightning = {"cl_trueLightning", "0"};
cvar_t	cl_parseWhiteText = {"cl_parseWhiteText", "1"};
cvar_t	cl_filterdrawviewmodel = {"cl_filterdrawviewmodel", "0"};
cvar_t	cl_oldPL = {"cl_oldPL", "0"};
cvar_t	cl_demoPingInterval = {"cl_demoPingInterval", "5"};
cvar_t	default_fov = {"default_fov", "0"};
cvar_t	qizmo_dir = {"qizmo_dir", "qizmo"};

//
// info mirrors
//
cvar_t	password = {"password", "", CVAR_USERINFO};
cvar_t	spectator = {"spectator", "", CVAR_USERINFO};
cvar_t	name = {"name","unnamed", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	team = {"team","", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	skin = {"skin","", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	topcolor = {"topcolor","0", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	bottomcolor = {"bottomcolor","0", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	rate = {"rate","2500", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	noaim = {"noaim","0", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	msg = {"msg","1", CVAR_ARCHIVE|CVAR_USERINFO};


client_static_t	cls;
client_state_t	cl;

entity_state_t	cl_baselines[MAX_EDICTS];
efrag_t			cl_efrags[MAX_EFRAGS];
entity_t		cl_static_entities[MAX_STATIC_ENTITIES];
lightstyle_t	cl_lightstyle[MAX_LIGHTSTYLES];
dlight_t		cl_dlights[MAX_DLIGHTS];

// refresh list
// this is double buffered so the last frame
// can be scanned for oldorigins of trailing objects
int				cl_numvisedicts, cl_oldnumvisedicts;
entity_t		*cl_visedicts, *cl_oldvisedicts;
entity_t		cl_visedicts_list[2][MAX_VISEDICTS];

double			connect_time = 0;		// for connection retransmits

quakeparms_t host_parms;

qboolean	host_initialized;		// true if into command execution

double		host_frametime;
double		realtime;				// without any filtering or bounding
double		oldrealtime;			// last frame run
int			host_framecount;
qboolean	host_skipframe;			// used in demo playback

int			host_hunklevel;

byte		*host_basepal;
byte		*host_colormap;

cvar_t	host_speeds = {"host_speeds","0"};			// set for running times
cvar_t	show_fps = {"show_fps","0"};			// set for running times

int			fps_count;

jmp_buf 	host_abort;

float	server_version = 0;	// version of server we connected to

/*
=======================
CL_SendConnectPacket

called by CL_Connect_f and CL_CheckResend
======================
*/
void CL_SendConnectPacket (void)
{
	netadr_t	adr;
	char	data[2048];
	double t1, t2;

	if (cls.state != ca_disconnected)
		return;

// JACK: Fixed bug where DNS lookups would cause two connects real fast
// Now, adds lookup time to the connect time.
	t1 = Sys_DoubleTime ();
	if (!NET_StringToAdr (cls.servername, &adr))
	{
		Com_Printf ("Bad server address\n");
		connect_time = 0;
		return;
	}
	t2 = Sys_DoubleTime ();
	connect_time = realtime + t2 - t1;	// for retransmit requests

	if (adr.port == 0)
		adr.port = BigShort (PORT_SERVER);

	cls.qport = Cvar_VariableValue("qport");

	sprintf (data, "\xff\xff\xff\xff" "connect %i %i %i \"%s\"\n",
		PROTOCOL_VERSION, cls.qport, cls.challenge, cls.userinfo);
	NET_SendPacket (NS_CLIENT, strlen(data), data, adr);
}

/*
=================
CL_CheckForResend

Resend a connect message if the last one has timed out
=================
*/
void CL_CheckForResend (void)
{
	netadr_t	adr;
	char	data[2048];
	double t1, t2;

	if (cls.state != ca_disconnected || !connect_time)
		return;
	if (realtime - connect_time < 5.0)
		return;

	t1 = Sys_DoubleTime ();
	if (!NET_StringToAdr (cls.servername, &adr))
	{
		Com_Printf ("Bad server address\n");
		connect_time = 0;
		return;
	}
	t2 = Sys_DoubleTime ();
	connect_time = realtime + t2 - t1;	// for retransmit requests

	if (adr.port == 0)
		adr.port = BigShort (PORT_SERVER);

	Com_Printf ("Connecting to %s...\n", cls.servername);
	sprintf (data, "\xff\xff\xff\xff" "getchallenge\n");
	NET_SendPacket (NS_CLIENT, strlen(data), data, adr);
}

void CL_BeginServerConnect(void)
{
	connect_time = -999;	// CL_CheckForResend() will fire immediately
	CL_CheckForResend();
}

/*
================
CL_Connect_f

================
*/
void CL_Connect_f (void)
{
	char	*server;

	if (Cmd_Argc() != 2)
	{
		Com_Printf ("usage: connect <server>\n");
		return;	
	}
	
	server = Cmd_Argv (1);

	CL_Disconnect ();

	Q_strncpyz (cls.servername, server, sizeof(cls.servername));
	CL_BeginServerConnect();
}


/*
=====================
CL_ClearState

=====================
*/
void CL_ClearState (void)
{
	int			i;

	S_StopAllSounds (true);

	Com_DPrintf ("Clearing memory\n");

	if (!com_serveractive)
	{
		D_FlushCaches ();
		Mod_ClearAll ();
		Hunk_FreeToLowMark (host_hunklevel);
	}

	CL_ClearTEnts ();

// wipe the entire cl structure
	memset (&cl, 0, sizeof(cl));

	SZ_Clear (&cls.netchan.message);

// clear other arrays	
	memset (cl_efrags, 0, sizeof(cl_efrags));
	memset (cl_dlights, 0, sizeof(cl_dlights));
	memset (cl_lightstyle, 0, sizeof(cl_lightstyle));
	memset (cl_baselines, 0, sizeof(cl_baselines));

//
// allocate the efrags and chain together into a free list
//
	cl.free_efrags = cl_efrags;
	for (i=0 ; i<MAX_EFRAGS-1 ; i++)
		cl.free_efrags[i].entnext = &cl.free_efrags[i+1];
	cl.free_efrags[i].entnext = NULL;
}

/*
=====================
CL_Disconnect

Sends a disconnect message to the server
This is also called on Host_Error, so it shouldn't cause any errors
=====================
*/
void CL_Disconnect (void)
{
	byte	final[10];

	connect_time = 0;
	server_version = 0;
	cl.teamfortress = false;

#ifdef _WIN32
	SetWindowText (mainwindow, "ZQuake");
#endif

// stop sounds (especially looping!)
	S_StopAllSounds (true);
	
	if (cls.demoplayback)
		CL_StopPlayback ();

	if (cls.demorecording)
		CL_Stop_f ();

	if (cls.state != ca_disconnected)
	{
		cls.state = ca_disconnected;

		final[0] = clc_stringcmd;
		strcpy (final+1, "drop");
		Netchan_Transmit (&cls.netchan, 6, final);
		Netchan_Transmit (&cls.netchan, 6, final);
		Netchan_Transmit (&cls.netchan, 6, final);

#ifdef QW_BOTH
		// if running a local server, shut it down
		if (com_serveractive)
			SV_Shutdown ("");
#endif
	}

	Cam_Reset();

	if (cls.download) {
		fclose(cls.download);
		cls.download = NULL;
	}

	CL_StopUpload ();
}

void CL_Disconnect_f (void)
{
	cl.intermission = 0;
	CL_Disconnect ();
}


/*
=====================
CL_NextDemo

Called to play the next demo in the demo loop
=====================
*/
void CL_NextDemo (void)
{
	char	str[MAX_OSPATH];

	if (cls.demonum == -1)
		return;		// don't play demos

	if (!cls.demos[cls.demonum][0] || cls.demonum == MAX_DEMOS)
	{
		cls.demonum = 0;
		if (!cls.demos[cls.demonum][0])
		{
//			Com_Printf ("No demos listed with startdemos\n");
			cls.demonum = -1;
			return;
		}
	}

	Q_snprintfz (str, sizeof(str), "playdemo %s\n", cls.demos[cls.demonum]);
	Cbuf_InsertText (str);
	cls.demonum++;
}


/*
=================
CL_Reconnect_f

The server is changing levels
=================
*/
void CL_Reconnect_f (void)
{
	if (cls.download)  // don't change when downloading
		return;

	S_StopAllSounds (true);

	if (cls.state == ca_connected) {
		Com_Printf ("reconnecting...\n");
		MSG_WriteChar (&cls.netchan.message, clc_stringcmd);
		MSG_WriteString (&cls.netchan.message, "new");
		return;
	}

	if (!*cls.servername) {
		Com_Printf ("No server to reconnect to.\n");
		return;
	}

	CL_Disconnect();
	CL_BeginServerConnect();
}

/*
=================
CL_ConnectionlessPacket

Responses to broadcasts, etc
=================
*/
void CL_ConnectionlessPacket (void)
{
	char	*s;
	int		c;

    MSG_BeginReading ();
    MSG_ReadLong ();        // skip the -1

	c = MSG_ReadByte ();
	if (!cls.demoplayback)
		Com_Printf ("%s: ", NET_AdrToString (net_from));
//	Com_DPrintf ("%s", net_message.data + 5);
	if (c == S2C_CONNECTION)
	{
		Com_Printf ("connection\n");
		if (cls.state >= ca_connected)
		{
			if (!cls.demoplayback)
				Com_Printf ("Dup connect received.  Ignored.\n");
			return;
		}
		Netchan_Setup (NS_CLIENT, &cls.netchan, net_from, cls.qport);
		MSG_WriteChar (&cls.netchan.message, clc_stringcmd);
		MSG_WriteString (&cls.netchan.message, "new");	
		cls.state = ca_connected;
		Com_Printf ("Connected.\n");
		allowremotecmd = false; // localid required now for remote cmds
		return;
	}
	// remote command from gui front end
	if (c == A2C_CLIENT_COMMAND)
	{
		char	cmdtext[2048];

		Com_Printf ("client command\n");

		if ((*(unsigned *)net_from.ip != *(unsigned *)net_local_adr.ip
			&& *(unsigned *)net_from.ip != htonl(INADDR_LOOPBACK)) )
		{
			Com_Printf ("Command packet from remote host.  Ignored.\n");
			return;
		}
#ifdef _WIN32
		ShowWindow (mainwindow, SW_RESTORE);
		SetForegroundWindow (mainwindow);
#endif
		s = MSG_ReadString ();

		Q_strncpyz (cmdtext, s, sizeof(cmdtext));

		s = MSG_ReadString ();

		while (*s && isspace(*s))
			s++;
		while (*s && isspace(s[strlen(s) - 1]))
			s[strlen(s) - 1] = 0;

		if (!allowremotecmd && (!*localid.string || strcmp(localid.string, s))) {
			if (!*localid.string) {
				Com_Printf ("===========================\n");
				Com_Printf ("Command packet received from local host, but no "
					"localid has been set.  You may need to upgrade your server "
					"browser.\n");
				Com_Printf ("===========================\n");
				return;
			}
			Com_Printf ("===========================\n");
			Com_Printf ("Invalid localid on command packet received from local host. "
				"\n|%s| != |%s|\n"
				"You may need to reload your server browser and QuakeWorld.\n",
				s, localid.string);
			Com_Printf ("===========================\n");
			Cvar_Set(&localid, "");
			return;
		}

		Cbuf_AddText (cmdtext);
		Cbuf_AddText ("\n");
		allowremotecmd = false;
		return;
	}
	// print command from somewhere
	if (c == A2C_PRINT)
	{
		Com_Printf ("print\n");

		s = MSG_ReadString ();
		Com_Printf ("%s", s);
		return;
	}

	// ping from somewhere
	if (c == A2A_PING)
	{
		char	data[6];

		Com_Printf ("ping\n");

		data[0] = 0xff;
		data[1] = 0xff;
		data[2] = 0xff;
		data[3] = 0xff;
		data[4] = A2A_ACK;
		data[5] = 0;
		
		NET_SendPacket (NS_CLIENT, 6, &data, net_from);
		return;
	}

	if (c == S2C_CHALLENGE) {
		Com_Printf ("challenge\n");

		s = MSG_ReadString ();
		cls.challenge = atoi(s);
		CL_SendConnectPacket ();
		return;
	}

	if (c == svc_disconnect) {
		if (cls.demoplayback) {
			Com_Printf ("\n======== End of demo ========\n\n");
			Host_EndGame ("End of demo");
		}
//		else
//			Host_EndGame ("Server disconnected");
		return;
	}

	Com_Printf ("unknown:  %c\n", c);
}


/*
=================
CL_ReadPackets
=================
*/
void CL_ReadPackets (void)
{
//	while (NET_GetPacket ())
	while (CL_GetMessage())
	{
		//
		// remote command packet
		//
		if (*(int *)net_message.data == -1)
		{
			CL_ConnectionlessPacket ();
			continue;
		}

		if (net_message.cursize < 8)
		{
			Com_DPrintf ("%s: Runt packet\n", NET_AdrToString(net_from));
			continue;
		}

		//
		// packet from server
		//
		if (!cls.demoplayback && 
			!NET_CompareAdr (net_from, cls.netchan.remote_address))
		{
			Com_DPrintf ("%s: sequenced packet without connection\n"
				,NET_AdrToString(net_from));
			continue;
		}
		if (!Netchan_Process(&cls.netchan))
			continue;		// wasn't accepted for some reason
		CL_ParseServerMessage ();
	}

	//
	// check timeout
	//
	if (!cls.demoplayback && cls.state >= ca_connected
	 && realtime - cls.netchan.last_received > cl_timeout.value)
	{
		Com_Printf ("\nServer connection timed out.\n");
		CL_Disconnect ();
		return;
	}
	
}


void CL_SendToServer (void)
{
	// when recording demos, request new ping times every 5 seconds
	if (cls.demorecording && !cls.demoplayback && cls.state == ca_active
		&& cl_demoPingInterval.value > 0) {
		if (realtime - cl.last_ping_request > cl_demoPingInterval.value)
		{
			cl.last_ping_request = realtime;
			MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
			SZ_Print (&cls.netchan.message, "pings");
		}
	}

	// send intentions now
	// resend a connection request if necessary
	if (cls.state == ca_disconnected) {
		CL_CheckForResend ();
	} else
		CL_SendCmd ();
}

//=============================================================================

void CL_InitCommands (void);

/*
=================
CL_Init
=================
*/
void CL_Init (void)
{
	extern	cvar_t		baseskin;
	extern	cvar_t		noskins;

	cls.state = ca_disconnected;

#ifndef RELEASE_VERSION
	Info_SetValueForStarKey (cls.userinfo, "*z_ver", Z_VERSION, MAX_INFO_STRING);
#endif

	CL_InitInput ();
	CL_InitTEnts ();
	CL_InitPrediction ();
	CL_InitCam ();
	Pmove_Init ();
	
//
// register our commands
//
	Cvar_Register (&show_fps);
	Cvar_Register (&host_speeds);

	Cvar_Register (&cl_warncmd);
	Cvar_Register (&cl_shownet);
	Cvar_Register (&cl_sbar);
	Cvar_Register (&cl_hudswap);
	Cvar_Register (&cl_maxfps);
	Cvar_Register (&cl_timeout);
	Cvar_Register (&cl_writecfg);

	Cvar_Register (&rcon_password);
	Cvar_Register (&rcon_address);

	Cvar_Register (&entlatency);
	Cvar_Register (&cl_predict_players);
	Cvar_Register (&cl_solid_players);

	Cvar_Register (&localid);

	Cvar_Register (&baseskin);
	Cvar_Register (&noskins);

	// ZQuake cvars
	Cvar_Register (&r_rockettrail);
	Cvar_Register (&r_grenadetrail);
	Cvar_Register (&r_powerupglow);
	Cvar_Register (&r_rocketlight);
	Cvar_Register (&cl_demospeed);
	Cvar_Register (&cl_deadbodyfilter);
	Cvar_Register (&cl_explosion);
	Cvar_Register (&cl_gibfilter);
	Cvar_Register (&cl_muzzleflash);
	Cvar_Register (&cl_staticsounds);
	Cvar_Register (&cl_trueLightning);
	Cvar_Register (&cl_parseWhiteText);
	Cvar_Register (&cl_filterdrawviewmodel);
	Cvar_Register (&cl_oldPL);
	Cvar_Register (&cl_demoPingInterval);
	Cvar_Register (&default_fov);
	Cvar_Register (&qizmo_dir);

	//
	// info mirrors
	//
	Cvar_Register (&name);
	Cvar_Register (&password);
	Cvar_Register (&spectator);
	Cvar_Register (&skin);
	Cvar_Register (&team);
	Cvar_Register (&topcolor);
	Cvar_Register (&bottomcolor);
	Cvar_Register (&rate);
	Cvar_Register (&msg);
	Cvar_Register (&noaim);


	CL_InitCommands ();

	Cmd_AddCommand ("disconnect", CL_Disconnect_f);
	Cmd_AddCommand ("connect", CL_Connect_f);
	Cmd_AddCommand ("reconnect", CL_Reconnect_f);

	SList_Init();
	SList_Load();
}


/*
================
Host_EndGame
================
*/
void Host_EndGame (char *message, ...)
{
	va_list		argptr;
	char		string[1024];
	
	va_start (argptr,message);
	vsprintf (string,message,argptr);
	va_end (argptr);
	Com_DPrintf ("Host_EndGame: %s\n",string);
	
	CL_Disconnect ();

	longjmp (host_abort, 1);
}

/*
================
Host_Error

This shuts down both the client and server
================
*/
void Host_Error (char *error, ...)
{
	va_list		argptr;
	char		string[1024];
	static	qboolean inerror = false;
	
	if (inerror)
		Sys_Error ("Host_Error: recursively entered");
	inerror = true;
	
	va_start (argptr,error);
	vsprintf (string,error,argptr);
	va_end (argptr);
	Com_Printf ("\n===========================\n");
	Com_Printf ("Host_Error: %s\n",string);
	Com_Printf ("===========================\n\n");
	
	CL_Disconnect ();
	cls.demonum = -1;

	if (!host_initialized)
		Sys_Error ("Host_Error: %s", string);

	inerror = false;

	longjmp (host_abort, 1);
}


/*
===============
Host_WriteConfiguration

Writes key bindings and archived cvars to config.cfg
===============
*/
void Host_WriteConfiguration (void)
{
	FILE	*f;

	if (host_initialized && cl_writecfg.value)
	{
		f = fopen (va("%s/config.cfg",com_gamedir), "w");
		if (!f)
		{
			Com_Printf ("Couldn't write config.cfg.\n");
			return;
		}
		
		Key_WriteBindings (f);
		Cvar_WriteVariables (f);

		fclose (f);
	}
}


//============================================================================

void Host_ConnectLocal ()
{
	if (cls.state < ca_connected)
		Cmd_ExecuteString ("connect local");
	else
		cls.state = ca_connected;
}


/*
===================
Host_FilterTime

Returns false if the time is too short to run a frame
===================
*/
qboolean Host_FilterTime (void)
{
	float fps, fpscap;

	if (cls.timedemo)
		return true;

	if (cls.demoplayback)
	{
		if (!cl_maxfps.value)
			return true;
		fps = max (30.0, cl_maxfps.value);
	}
	else
	{
		fpscap = cl.maxfps ? bound (30.0, cl.maxfps, 120.0) : 72.0;

		if (cl_maxfps.value)
			fps = bound (30.0, cl_maxfps.value, fpscap);
		else
		{
			if (com_serveractive)
				fps = fpscap;
			else
				fps = bound (30.0, rate.value/80.0, fpscap);
		}
	}

	if (realtime - oldrealtime < 1.0/fps)
		return false;

	return true;
}


/*
==================
Host_Frame

Runs all active servers
==================
*/
void Host_Frame (double time)
{
	static double		time1 = 0;
	static double		time2 = 0;
	static double		time3 = 0;
	int			pass1, pass2, pass3;
	float scale;

	if (setjmp (host_abort) )
		return;			// something bad happened, or the server disconnected

	// decide the simulation time

	if (host_skipframe) {
		host_skipframe = false;
		time = 0;
	}

	if (!cls.demoplayback)
		realtime += time;
	else {
		scale = cl_demospeed.value;
		if (scale <= 0) scale = 1;
		if (scale < 0.1) scale = 0.1;
		if (scale > 10) scale = 1;
		realtime += time*scale;
	}

	if (oldrealtime > realtime)
		oldrealtime = 0;

	if (!Host_FilterTime())
		return;			// framerate is too high

	host_frametime = realtime - oldrealtime;

	if (cls.demoplayback && (cl.paused & 2))
		realtime = oldrealtime;

	oldrealtime = realtime;
	if (host_frametime > 0.2)
		host_frametime = 0.2;
		
	// get new key events
	Sys_SendKeyEvents ();

	// allow mice or other external controllers to add commands
	IN_Commands ();

	// process console commands
	Cbuf_Execute ();

#ifdef QW_BOTH
	if (com_serveractive)
		SV_Frame(host_frametime);
#endif

	// fetch results from server
	CL_ReadPackets ();

	// process stuffed commands
	Cbuf_ExecuteEx (&cbuf_svc);

	CL_SendToServer ();

	if (cls.state >= ca_onserver)	// !!! Tonik
	{
		Cam_SetViewPlayer ();

		// Set up prediction for other players
		CL_SetUpPlayerPrediction(false);
		
		// do client side motion prediction
		CL_PredictMove ();
		
		// Set up prediction for other players
		CL_SetUpPlayerPrediction(true);
		
		// build a refresh entity list
		CL_EmitEntities ();
	}

	// update video
	if (host_speeds.value)
		time1 = Sys_DoubleTime ();

	SCR_UpdateScreen ();

	if (host_speeds.value)
		time2 = Sys_DoubleTime ();
		
	// update audio
	if (cls.state == ca_active)
	{
		S_Update (r_origin, vpn, vright, vup);
		CL_DecayLights ();
	}
	else
		S_Update (vec3_origin, vec3_origin, vec3_origin, vec3_origin);
	
	CDAudio_Update();

	if (host_speeds.value)
	{
		pass1 = (time1 - time3)*1000;
		time3 = Sys_DoubleTime ();
		pass2 = (time2 - time1)*1000;
		pass3 = (time3 - time2)*1000;
		Com_Printf ("%3i tot %3i server %3i gfx %3i snd\n",
					pass1+pass2+pass3, pass1, pass2, pass3);
	}

	host_framecount++;
	fps_count++;
}

//============================================================================

// emodel and pmodel are encrypted to prevent llamas from easily hacking them

char emodel_name[] = { 'e'^0xe5, 'm'^0xe5, 'o'^0xe5, 'd'^0xe5, 'e'^0xe5, 'l'^0xe5, 0 };
char pmodel_name[] = { 'p'^0xe5, 'm'^0xe5, 'o'^0xe5, 'd'^0xe5, 'e'^0xe5, 'l'^0xe5, 0 };

static void simple_crypt (char *buf, int len)
{
	while (len--)
		*buf++ ^= 0xe5;
}

void Host_FixupModelNames (void)
{
	simple_crypt (emodel_name, sizeof(emodel_name) - 1);
	simple_crypt (pmodel_name, sizeof(pmodel_name) - 1);
}

//============================================================================

/*
====================
Host_Init
====================
*/
void Host_Init (quakeparms_t *parms)
{
	COM_InitArgv (parms->argc, parms->argv);

	if (COM_CheckParm ("-minmemory"))
		parms->memsize = MINIMUM_MEMORY;

	host_parms = *parms;

	if (parms->memsize < MINIMUM_MEMORY)
		Sys_Error ("Only %4.1f megs of memory reported, can't execute game", parms->memsize / (float)0x100000);

	Memory_Init (parms->membase, parms->memsize);

	Cbuf_Init ();
	Cmd_Init ();
	Cvar_Init ();
	V_Init ();
	TP_Init ();

	COM_Init ();

#ifdef QW_BOTH
	PR_Init ();
	SV_InitLocal ();	// register server cvars and commands
#endif

	Host_FixupModelNames();
	
	NET_Init ();
	NET_Config (true, false);
	Netchan_Init ();

	W_LoadWadFile ("gfx.wad");

	Key_Init ();
	Con_Init ();	
	M_Init ();	
	Mod_Init ();
	
	Sys_mkdir(va("%s/%s", com_basedir, "qw"));

//	Com_Printf ("Exe: "__TIME__" "__DATE__"\n");
	Com_Printf ("%4.1f megs RAM used.\n",parms->memsize/ (1024*1024.0));
	
	R_InitTextures ();
 
	host_basepal = (byte *)COM_LoadHunkFile ("gfx/palette.lmp");
	if (!host_basepal)
		Sys_Error ("Couldn't load gfx/palette.lmp");
	host_colormap = (byte *)COM_LoadHunkFile ("gfx/colormap.lmp");
	if (!host_colormap)
		Sys_Error ("Couldn't load gfx/colormap.lmp");
#ifdef __linux__
	IN_Init ();
	CDAudio_Init ();
	VID_Init (host_basepal);
	Draw_Init ();
	SCR_Init ();
	R_Init ();

//	S_Init ();		// S_Init is now done as part of VID. Sigh.
	
	Sbar_Init ();
	CL_Init ();
#else
	VID_Init (host_basepal);
	Draw_Init ();
	SCR_Init ();
	R_Init ();
//	S_Init ();		// S_Init is now done as part of VID. Sigh.
#ifdef GLQUAKE
	S_Init();
#endif

	CDAudio_Init ();
	Sbar_Init ();
	CL_Init ();
	IN_Init ();
#endif

	Cbuf_InsertText ("exec quake.rc\n");
//	Cbuf_AddText ("echo Type connect <internet address> or use GameSpy to connect to a game.\n");
	Cbuf_AddText ("cl_warncmd 1\n");

	Hunk_AllocName (0, "-HOST_HUNKLEVEL-");
	host_hunklevel = Hunk_LowMark ();

	host_initialized = true;

#ifdef RELEASE_VERSION
	Com_Printf ("\nClient version %s\n\n", Z_VERSION);
#else
	Com_Printf ("\nClient version %s (Build %04d)\n\n", Z_VERSION, build_number());
#endif

	Com_Printf ("��������� ZQuake Initialized ���������\n");
}


/*
===============
Host_Shutdown

FIXME: this is a callback from Sys_Quit and Sys_Error.  It would be better
to run quit through here before the final handoff to the sys code.
===============
*/
void Host_Shutdown(void)
{
	static qboolean isdown = false;
	
	if (isdown)
	{
		printf ("recursive shutdown\n");
		return;
	}
	isdown = true;

	Host_WriteConfiguration (); 

#ifdef QW_BOTH
	SV_Shutdown ("Server quit\n");
#endif

	SList_Shutdown ();
	CDAudio_Shutdown ();
	NET_Shutdown ();
	S_Shutdown();
	IN_Shutdown ();
	if (host_basepal)
		VID_Shutdown();
}
