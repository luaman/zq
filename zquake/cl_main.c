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

#include "quakedef.h"
#include "winquake.h"
#include "cdaudio.h"
#include "input.h"
#include "keys.h"
#include "menu.h"
#include "sbar.h"
#include "sound.h"
#include "version.h"
#include "teamplay.h"


cvar_t	*cl_rconPassword;
cvar_t	cl_rconAddress = {"rcon_address", ""};

cvar_t	cl_timeout = {"cl_timeout", "60"};

cvar_t	cl_shownet = {"cl_shownet", "0"};	// can be 0, 1, or 2

cvar_t	cl_sbar		= {"cl_sbar", "0", CVAR_ARCHIVE};
cvar_t	cl_hudswap	= {"cl_hudswap", "0", CVAR_ARCHIVE};
cvar_t	cl_maxfps	= {"cl_maxfps", "0", CVAR_ARCHIVE};

cvar_t	cl_writecfg = {"cl_writecfg", "1"};

cvar_t	cl_predictPlayers = {"cl_predictPlayers", "1"};
cvar_t	cl_solidPlayers = {"cl_solidPlayers", "1"};

cvar_t  localid = {"localid", ""};

static qbool allowremotecmd = true;

// ZQuake cvars
// FIXME: r_ prefix is wrong, but not changing for compatibility reasons
cvar_t	r_rocketlight = {"r_rocketLight", "1"};
cvar_t	r_rockettrail = {"r_rocketTrail", "1"};
cvar_t	r_grenadetrail = {"r_grenadeTrail", "1"};
cvar_t	r_powerupglow = {"r_powerupGlow", "1"};
cvar_t	r_lightflicker = {"r_lightflicker", "1"};
cvar_t	cl_deadbodyfilter = {"cl_deadbodyFilter", "0"};
cvar_t	cl_explosion = {"cl_explosion", "0"};
cvar_t	cl_gibfilter = {"cl_gibFilter", "0"};
cvar_t	cl_muzzleflash = {"cl_muzzleflash", "1"};
cvar_t	cl_r2g = {"cl_r2g", "0"};
cvar_t	cl_demospeed = {"cl_demospeed", "1"};
cvar_t	cl_staticsounds = {"cl_staticSounds", "1"};
cvar_t	cl_trueLightning = {"cl_trueLightning", "0"};
cvar_t	cl_nofake = {"cl_nofake", "2"};
cvar_t	cl_parseWhiteText = {"cl_parseWhiteText", "1"};
cvar_t	cl_filterdrawviewmodel = {"cl_filterdrawviewmodel", "0"};
cvar_t	cl_oldPL = {"cl_oldPL", "0"};
cvar_t	cl_demoPingInterval = {"cl_demoPingInterval", "5"};
cvar_t	cl_chatsound = {"cl_chatsound", "1"};
cvar_t	cl_confirmquit = {"cl_confirmquit", "1", CVAR_INIT};
cvar_t	cl_fakename = {"cl_fakename", ""};
cvar_t	cl_useproxy = {"cl_useproxy", "1"};
cvar_t	default_fov = {"default_fov", "0"};
cvar_t	qizmo_dir = {"qizmo_dir", "qizmo"};

//
// info mirrors
//
cvar_t	*password;
cvar_t	spectator = {"spectator", "", CVAR_USERINFO};
cvar_t	name = {"name", "player", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	team = {"team", "", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	topcolor = {"topcolor","0", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	bottomcolor = {"bottomcolor","0", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	skin = {"skin", "", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	rate = {"rate", "2500", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	msg = {"msg", "1", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	noaim = {"noaim", "", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	w_switch = {"w_switch", "", CVAR_ARCHIVE|CVAR_USERINFO};
cvar_t	b_switch = {"b_switch", "", CVAR_ARCHIVE|CVAR_USERINFO};


client_persistent_t	cls;
client_state_t		cl;

centity_t		cl_entities[MAX_CL_EDICTS];
efrag_t			cl_efrags[MAX_EFRAGS];
entity_t		cl_static_entities[MAX_STATIC_ENTITIES];
lightstyle_t	cl_lightstyle[MAX_LIGHTSTYLES];
dlight_t		cl_dlights[MAX_DLIGHTS];

// refresh list
// this is double buffered so the last frame
// can be scanned for oldorigins of trailing objects
int				cl_numvisedicts;
entity_t		cl_visedicts[MAX_VISEDICTS];

// used to determine if an entity was present in the last or previous message
int				cl_entframecount, cl_oldentframecount;

double			connect_time = 0;		// for connection retransmits

qbool		host_skipframe;			// used in demo playback

byte		*host_basepal;
byte		*host_colormap;

cvar_t	host_speeds = {"host_speeds","0"};			// set for running times

int			fps_count;

// emodel and pmodel are encrypted to prevent llamas from easily hacking them
char emodel_name[] = { 'e'^0xe5, 'm'^0xe5, 'o'^0xe5, 'd'^0xe5, 'e'^0xe5, 'l'^0xe5, 0 };
char pmodel_name[] = { 'p'^0xe5, 'm'^0xe5, 'o'^0xe5, 'd'^0xe5, 'e'^0xe5, 'l'^0xe5, 0 };

static void simple_crypt (char *buf, int len)
{
	while (len--)
		*buf++ ^= 0xe5;
}

static void CL_FixupModelNames (void)
{
	simple_crypt (emodel_name, sizeof(emodel_name) - 1);
	simple_crypt (pmodel_name, sizeof(pmodel_name) - 1);
}

//============================================================================

int CL_ClientState (void)
{
	return cls.state;
}

// just for sv_save.c
int CL_IntermissionRunning (void) { return cl.intermission; }
int CL_Stat_Monsters (void) { return cl.stats[STAT_MONSTERS]; }
int CL_Stat_TotalMonsters (void) { return cl.stats[STAT_TOTALMONSTERS]; }

/*
*/
void CL_GamedirChanged (void)
{
	if (dedicated || !cls.initialized)
		return;

	// free old data and load a new gfx.wad
	R_FlushPics ();

	// register the pics we need
	SCR_RegisterPics ();
	Sbar_RegisterPics ();
}

/*
==================
CL_UserinfoChanged

Cvar system calls this when a CVAR_USERINFO cvar changes
==================
*/
void CL_UserinfoChanged (char *key, char *string)
{
	char *s;

	s = TP_ParseFunChars (string, false);

	if (strcmp(s, Info_ValueForKey (cls.userinfo, key)))
	{
		Info_SetValueForKey (cls.userinfo, key, s, MAX_INFO_STRING);

		if (cls.state >= ca_connected)
		{
			MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
			SZ_Print (&cls.netchan.message, va("setinfo \"%s\" \"%s\"\n", key, s));
		}
	}
}


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
	char	biguserinfo[MAX_INFO_STRING + 32];
	char	extensionstring[32] = "";

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
	connect_time = cls.realtime + t2 - t1;	// for retransmit requests

	if (adr.port == 0)
		adr.port = BigShort (PORT_SERVER);

	cls.qport = Cvar_VariableValue("qport");

	// let the server know what extensions we support
	strcpy (biguserinfo, cls.userinfo);
	Info_SetValueForStarKey (biguserinfo, "*z_ext", va("%i", SUPPORTED_EXTENSIONS), sizeof(biguserinfo));

	sprintf (data, "\xff\xff\xff\xff" "connect %i %i %i \"%s\"\n",
		PROTOCOL_VERSION, cls.qport, cls.challenge, biguserinfo);
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

	if (cls.state == ca_disconnected && com_serveractive) {
		// if the local server is running and we are not, then connect
		strlcpy (cls.servername, "local", sizeof(cls.servername));
		CL_SendConnectPacket ();	// we don't need a challenge on the local server
		// FIXME: cls.state = ca_connecting so that we don't send the packet twice?
		return;
	}

	if (cls.state != ca_disconnected || !connect_time)
		return;
	if (cls.realtime - connect_time < 5.0)
		return;

	t1 = Sys_DoubleTime ();
	if (!NET_StringToAdr (cls.servername, &adr))
	{
		Com_Printf ("Bad server address\n");
		connect_time = 0;
		return;
	}
	t2 = Sys_DoubleTime ();
	connect_time = cls.realtime + t2 - t1;	// for retransmit requests

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

	Host_EndGame ();

	strlcpy (cls.servername, server, sizeof(cls.servername));
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
	extern float	scr_centertime_off;

	S_StopAllSounds (true);

	Com_DPrintf ("Clearing memory\n");

	if (!com_serveractive)
	{
		Host_ClearMemory ();
	}

	CL_ClearTEnts ();

// wipe the entire cl structure
	memset (&cl, 0, sizeof(cl));

	SZ_Clear (&cls.netchan.message);

// clear other arrays	
	memset (cl_efrags, 0, sizeof(cl_efrags));
	memset (cl_dlights, 0, sizeof(cl_dlights));
	memset (cl_lightstyle, 0, sizeof(cl_lightstyle));
	memset (cl_entities, 0, sizeof(cl_entities));

	cl_numvisedicts = 0;
	cl_oldentframecount = -1;
	cl_entframecount = 0;
	cl.viewheight = DEFAULT_VIEWHEIGHT;

	V_NewMap ();

// make sure no centerprint messages are left from previous level
	scr_centertime_off = 0;

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
	cl.teamfortress = false;

	VID_SetCaption (PROGRAM);

// stop sounds (especially looping!)
	S_StopAllSounds (true);
	
	Cmd_RemoveStuffedAliases ();

	if (cls.demorecording && cls.state != ca_disconnected)
		CL_Stop_f ();

	if (cls.demoplayback)
	{
		CL_StopPlayback ();
	}
	else if (cls.state != ca_disconnected)
	{
		final[0] = clc_stringcmd;
		strcpy (final+1, "drop");
		Netchan_Transmit (&cls.netchan, 6, final);
		Netchan_Transmit (&cls.netchan, 6, final);
		Netchan_Transmit (&cls.netchan, 6, final);
	}

	cls.state = ca_disconnected;

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
	cls.playdemos = 0;	// stop demo loop
	Host_EndGame ();
}

void CL_HandleHostError (void)
{
	cls.playdemos = 0;	// stop demo loop
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

	CL_Disconnect();	// FIXME: replace with Host_EndGame?
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

	if (c == A2C_PRINT && net_message.data[msg_readcount] == '\\')
	{
		extern double qstat_senttime;
		extern void CL_PrintQStatReply (char *s);

		if (qstat_senttime && curtime - qstat_senttime < 10)
		{
			CL_PrintQStatReply (MSG_ReadString());
			return;
		}
	}

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

		if (!NET_IsLocalAddress(net_from))
		{
			Com_Printf ("Command packet from remote host.  Ignored.\n");
			return;
		}
#ifdef _WIN32
		ShowWindow (mainwindow, SW_RESTORE);
		SetForegroundWindow (mainwindow);
#endif
		s = MSG_ReadString ();

		strlcpy (cmdtext, s, sizeof(cmdtext));

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
			CL_NextDemo ();
			Host_EndGame ();
			Host_Abort ();
		}
//		else
//			Host_Error ("Server disconnected");
		return;
	}

	Com_Printf ("unknown:  %c\n", c);
}


/*
====================
CL_GetMessage

Handles playback of demos, on top of NET_ code
====================
*/
qbool CL_GetMessage (void)
{
#ifdef _WIN32
	extern void CheckQizmoCompletion ();
	CheckQizmoCompletion ();
#endif

	if (cls.demoplayback)
		return CL_GetDemoMessage ();

	if (!NET_GetPacket(NS_CLIENT))
		return false;

	return true;
}


/*
=================
CL_ReadPackets
=================
*/
void CL_ReadPackets (void)
{
	if (cls.nqdemoplayback) {
		NQD_ReadPackets ();
		return;
	}

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
	 && curtime - cls.netchan.last_received > cl_timeout.value)
	{
		Com_Printf ("\nServer connection timed out.\n");
		Host_EndGame ();
		return;
	}
	
}


void CL_SendToServer (void)
{
	// when recording demos, request new ping times every 5 seconds
	if (cls.demorecording && !cls.demoplayback && cls.state == ca_active
		&& cl_demoPingInterval.value > 0) {
		if (cls.realtime - cl.last_ping_request > cl_demoPingInterval.value)
		{
			cl.last_ping_request = cls.realtime;
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

void CL_InitLocal (void)
{
	extern	cvar_t		baseskin;
	extern	cvar_t		noskins;

	Cvar_Register (&host_speeds);

	Cvar_Register (&cl_warncmd);
	Cvar_Register (&cl_shownet);
	Cvar_Register (&cl_sbar);
	Cvar_Register (&cl_hudswap);
	Cvar_Register (&cl_maxfps);
	Cvar_Register (&cl_timeout);
	Cvar_Register (&cl_writecfg);
	Cvar_Register (&cl_predictPlayers);
	Cvar_Register (&cl_solidPlayers);

	cl_rconPassword = Cvar_Get ("rcon_password", "", 0);
	Cvar_Register (&cl_rconAddress);

	Cvar_Register (&localid);

	Cvar_Register (&baseskin);
	Cvar_Register (&noskins);

	// ZQuake cvars
	Cvar_Register (&r_rocketlight);
	Cvar_Register (&r_rockettrail);
	Cvar_Register (&r_grenadetrail);
	Cvar_Register (&r_powerupglow);
	Cvar_Register (&r_lightflicker);
	Cvar_Register (&cl_demospeed);
	Cmd_AddLegacyCommand ("demotimescale", "cl_demospeed");
	Cvar_Register (&cl_deadbodyfilter);
	Cvar_Register (&cl_explosion);
	Cvar_Register (&cl_gibfilter);
	Cvar_Register (&cl_muzzleflash);
	Cvar_Register (&cl_r2g);
	Cvar_Register (&cl_staticsounds);
	Cvar_Register (&cl_trueLightning);
	Cvar_Register (&cl_nofake);
	Cvar_Register (&cl_parseWhiteText);
	Cvar_Register (&cl_filterdrawviewmodel);
	Cvar_Register (&cl_oldPL);
	Cvar_Register (&cl_demoPingInterval);
	Cvar_Register (&cl_chatsound);
	Cvar_Register (&cl_confirmquit);
	Cvar_Register (&cl_fakename);
	Cvar_Register (&cl_useproxy);
	Cvar_Register (&default_fov);
	Cvar_Register (&qizmo_dir);

#ifndef RELEASE_VERSION
	// inform everyone that we're using a development version
//	Info_SetValueForStarKey (cls.userinfo, "*ver", va(PROGRAM " %s", VersionString()), MAX_INFO_STRING);
#endif

	//
	// info mirrors
	//
	password = Cvar_Get ("password", "",  CVAR_USERINFO);
	Cvar_Register (&spectator);
	Cvar_Register (&name);
	Cvar_Register (&team);
	Cvar_Register (&topcolor);
	Cvar_Register (&bottomcolor);
	Cvar_Register (&skin);
	Cvar_Register (&rate);
	Cvar_Register (&msg);
	Cvar_Register (&noaim);
	Cvar_Register (&w_switch);
	Cvar_Register (&b_switch);

	CL_InitCommands ();

	Cmd_AddCommand ("disconnect", CL_Disconnect_f);
	Cmd_AddCommand ("connect", CL_Connect_f);
	Cmd_AddCommand ("reconnect", CL_Reconnect_f);
}

static void CL_CheckGfxWad (void)
{
	FILE *f;
	FS_FOpenFile ("gfx.wad", &f);
	if (!f) {
		Sys_Error ("Couldn't find gfx.wad.\n"
			"Make sure you start " PROGRAM
			"from your Quake directory or use -basedir <path>");
	}
	fclose (f);
}

/*
=================
CL_Init
=================
*/
void CL_Init (void)
{
	if (dedicated)
		return;

	cls.state = ca_disconnected;

	strcpy (cls.gamedirfile, com_gamedirfile);
	strcpy (cls.gamedir, com_gamedir);

	CL_CheckGfxWad ();

	host_basepal = (byte *)FS_LoadHunkFile ("gfx/palette.lmp");
	if (!host_basepal)
		Sys_Error ("Couldn't load gfx/palette.lmp");
	host_colormap = (byte *)FS_LoadHunkFile ("gfx/colormap.lmp");
	if (!host_colormap)
		Sys_Error ("Couldn't load gfx/colormap.lmp");

	Sys_mkdir(va("%s/%s", com_basedir, "qw"));

	V_Init ();

#ifdef __linux__
	IN_Init ();
#endif

	VID_Init (host_basepal);

#ifndef __linux__
	IN_Init ();
#endif


	R_Init (host_basepal);

	S_Init ();
	CDAudio_Init ();

	CL_InitLocal ();
	CL_FixupModelNames ();
	CL_InitInput ();
	CL_InitTEnts ();
	CL_InitPrediction ();
	CL_InitCam ();
	CL_InitParticles ();
	TP_Init ();
	SCR_Init ();
	Sbar_Init ();
	M_Init ();	

	NET_ClientConfig (true);

#if 0
	// bring up the main menu
	M_Menu_Main_f ();
#endif

	cls.initialized = true;
}


//============================================================================

void CL_BeginLocalConnection (void)
{
	S_StopAllSounds (true);
	SCR_BeginLoadingPlaque ();

	// make sure we're not connected to an external server,
	// and demo playback is stopped
	if (!com_serveractive)
		CL_Disconnect ();

	cl.worldmodel = NULL;

#if 1
	if (cls.state == ca_active)
		cls.state = ca_connected;
#else
	if (cls.state < ca_connected)
		Cmd_ExecuteString ("connect local");
	else
		cls.state = ca_connected;
#endif
}


// automatically pause the game when going into the menus in single player
static void CL_CheckAutoPause (void)
{
#ifndef CLIENTONLY
	extern void SV_TogglePause (const char *msg);
	extern cvar_t sv_paused;

	if (com_serveractive && cls.state == ca_active && !cl.deathmatch && cl.maxclients == 1
		&& (key_dest == key_menu /*|| key_dest == key_console*/))
	{
		if (!((int)sv_paused.value & 2))
			SV_TogglePause (NULL);
	}
	else {
		if ((int)sv_paused.value & 2)
			SV_TogglePause (NULL);
	}
#endif
}


/*
===================
CL_MinFrameTime

Can't run a frame if enough time hasn't passed
===================
*/
static double CL_MinFrameTime ()
{
	double fps, fpscap;

	if (cls.timedemo)
		return 0;

	if (cls.demoplayback) {
		if (!cl_maxfps.value)
			return 0;
		fps = max (30.0, cl_maxfps.value);
	}
	else {
		fpscap = cl.maxfps ? max (30.0, cl.maxfps) : 72.0;

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

	return 1.0/fps;
}


/*
==================
CL_Frame

==================
*/
void CL_Frame (double time)
{
	static double	time1 = 0;
	static double	time2 = 0;
	static double	time3 = 0;
	int				pass1, pass2, pass3;
	static double	extratime = 0.001;
	double			minframetime;

	extratime += time;

	minframetime = CL_MinFrameTime();
	if (extratime < minframetime)
		return;

	cls.trueframetime = extratime - 0.001;
	if (cls.trueframetime < minframetime)
		cls.trueframetime = minframetime;
	extratime -= cls.trueframetime;

	cls.frametime = min (cls.trueframetime, 0.2);

	if (cls.demoplayback) {
		cls.frametime *= bound (0, cl_demospeed.value, 100);
		if (cl.paused & PAUSED_DEMO)
			cls.frametime = 0;
		if (!host_skipframe)
			cls.demotime += cls.frametime;
		host_skipframe = false;
	}

	cls.realtime += cls.frametime;		// go on even if paused (dunno why...)

	if (cl.paused)
		cls.frametime = 0;

	cl.time += cls.frametime;
	cl.servertime += cls.frametime;

	// get new key events
	Sys_SendKeyEvents ();

	// allow mice or other external controllers to add commands
	IN_Commands ();

	// process console commands
	Cbuf_Execute ();
	CL_CheckAutoPause ();

	if (com_serveractive)
		SV_Frame (cls.frametime);

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

	cls.framecount++;
	fps_count++;
}

//============================================================================

/*
===============
CL_Shutdown
===============
*/
void CL_Shutdown (void)
{
	CL_Disconnect ();

	CL_WriteConfiguration (); 

	CDAudio_Shutdown ();
	S_Shutdown();
	IN_Shutdown ();
	if (host_basepal)
		VID_Shutdown();
}
