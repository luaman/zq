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
// cl_parse.c  -- parse a message received from the server

#include "quakedef.h"
#include "cdaudio.h"
#include "pmove.h"
#include "cl_sbar.h"
#include "sound.h"
#include "teamplay.h"
#include "version.h"
#include "textencoding.h"


char *svc_strings[] =
{
	"svc_bad",
	"svc_nop",
	"svc_disconnect",
	"svc_updatestat",
	"NQ svc_version",		// [long] server version
	"NQ svc_setview",		// [short] entity number
	"svc_sound",			// <see code>
	"NQ svc_time",			// [float] server time
	"svc_print",			// [string] null terminated string
	"svc_stufftext",		// [string] stuffed into client's console buffer
							// the string should be \n terminated
	"svc_setangle",			// [vec3] set the view angle to this absolute value
	
	"svc_serverdata",		// [long] version ...
	"svc_lightstyle",		// [byte] [string]
	"NQ svc_updatename",	// [byte] [string]
	"svc_updatefrags",		// [byte] [short]
	"svc_clientdata",		// <shortbits + data>
	"svc_stopsound",		// <see code>
	"NQ svc_updatecolors",	// [byte] [byte]
	"NQ svc_particle",		// [vec3] <variable>
	"svc_damage",			// [byte] impact [byte] blood [vec3] from
	
	"svc_spawnstatic",
	"OBSOLETE svc_spawnbinary",
	"svc_spawnbaseline",
	
	"svc_temp_entity",		// <variable>
	"svc_setpause",
	"NQ svc_signonnum",
	"svc_centerprint",
	"svc_killedmonster",
	"svc_foundsecret",
	"svc_spawnstaticsound",
	"svc_intermission",
	"svc_finale",

	"svc_cdtrack",
	"svc_sellscreen",

	"svc_smallkick",
	"svc_bigkick",

	"svc_updateping",
	"svc_updateentertime",

	"svc_updatestatlong",
	"svc_muzzleflash",
	"svc_updateuserinfo",
	"svc_download",
	"svc_playerinfo",
	"svc_nails",
	"svc_choke",
	"svc_modellist",
	"svc_soundlist",
	"svc_packetentities",
 	"svc_deltapacketentities",
	"svc_maxspeed",
	"svc_entgravity",

	"svc_setinfo",
	"svc_serverinfo",
	"svc_updatepl",

	"MVD svc_nails2",
};

int num_svc_strings = sizeof(svc_strings)/sizeof(svc_strings[0]);

int		cl_spikeindex, cl_playerindex, cl_eyesindex, cl_flagindex;
int		cl_rocketindex, cl_grenadeindex;

//=============================================================================

int packet_latency[NET_TIMINGS];

int CL_CalcNet (void)
{
	int		a, i;
	frame_t	*frame;
	int lost;
	int packetcount;

	for (i=cls.netchan.outgoing_sequence-UPDATE_BACKUP+1
		; i <= cls.netchan.outgoing_sequence
		; i++)
	{
		frame = &cl.frames[i&UPDATE_MASK];
		if (frame->receivedtime == -1)
			packet_latency[i&NET_TIMINGSMASK] = 9999;	// dropped
		else if (frame->receivedtime == -2)
			packet_latency[i&NET_TIMINGSMASK] = 10000;	// choked
		else if (frame->receivedtime == -3)
			packet_latency[i&NET_TIMINGSMASK] = -1;	// choked by c2spps
		else if (!frame->valid)
			packet_latency[i&NET_TIMINGSMASK] = 9998;	// invalid delta
		else
			packet_latency[i&NET_TIMINGSMASK] = (frame->receivedtime - frame->senttime)*20;
	}

	lost = 0;
	packetcount = 0;
	for (a=0 ; a<NET_TIMINGS ; a++)
	{
		if (a < UPDATE_BACKUP && (cls.realtime -
			cl.frames[(cls.netchan.outgoing_sequence-a)&UPDATE_MASK].senttime) < cls.latency)
			continue;

		i = (cls.netchan.outgoing_sequence-a) & NET_TIMINGSMASK;
		if (packet_latency[i] == 9999)
			lost++;
		if (packet_latency[i] != -1)	// don't count packets choked by c2spps
			packetcount++;
	}
	if (packetcount == 0)
		return 100;
	else
		return lost * 100 / packetcount;
}

//=============================================================================

/*
===============
CL_CheckOrDownloadFile

Returns true if the file exists, otherwise it attempts
to start a download from the server.
===============
*/
qbool CL_CheckOrDownloadFile (string filename)
{
	FILE	*f;

	if (filename.find("..") != string::npos)
	{
		Com_Printf ("Refusing to download a path with ..\n");
		return true;
	}

	FS_FOpenFile ((char *)filename.c_str(), &f);
	if (f)
	{	// it exists, no need to download
		fclose (f);
		return true;
	}

	//ZOID - can't download when recording
	if (cls.demorecording) {
		Com_Printf ("Unable to download %s in record mode.\n", cls.downloadname);
		return true;
	}
	//ZOID - can't download when playback
	if (cls.demoplayback)
		return true;

	strcpy (cls.downloadname, filename.c_str());
	Com_Printf ("Downloading %s...\n", cls.downloadname);

	// download to a temp name, and only rename
	// to the real name when done, so if interrupted
	// a runt file wont be left
	COM_StripExtension (cls.downloadname, cls.downloadtempname);
	strcat (cls.downloadtempname, ".tmp");

	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	MSG_WriteString (&cls.netchan.message, va("download %s", cls.downloadname));

	cls.downloadnumber++;

	return false;
}


void CL_FindModelNumbers (void)
{
	int	i;

	cl_playerindex = cl_eyesindex = cl_spikeindex = cl_flagindex = -1;
	cl_rocketindex = cl_grenadeindex = -1;

	for (i = 1; i < MAX_MODELS; i++) {
		if (cl.model_name[i].substr(0, 6) != "progs/"
		|| cl.model_name[i].substr(cl.model_name[i].length() - 4) != ".mdl")
			continue;
		string s = cl.model_name[i].substr(6, cl.model_name[i].length() - 6 - 4);
		if (s == "spike")
			cl_spikeindex = i;
		else if (s == "player") {
			cl_playerindex = i;
			if (!strcmp(host_mapname.string, "hipend"))
				cl.modelinfos[i] = mi_monster;	// lerp the cutscene hero's movement
		} else if (s == "eyes")
			cl_eyesindex = i;
		else if (s == "flag")
			cl_flagindex = i;
		else if (s == "gib1" || s == "gib2" || s == "gib3" || s == "h_player"
		|| s == "h_demon" || s == "h_dog" || s == "h_guard" || s == "h_knight"
		|| s == "h_ogre" || s == "h_shams" || s == "h_wizard" || s == "h_zombie"
		|| s == "h_hellkn" || s == "h_mega" || s == "h_shal")
			cl.modelinfos[i] = mi_gib;
		else if (s == "missile")
			cl_rocketindex = i;
		else if (s == "grenade")
			cl_grenadeindex = i;
		else if (s == "v_axe" || s == "v_bio" || s == "v_grap" || s == "v_knife"
		|| s == "v_knife2" || s == "v_medi"	|| s == "v_span")
			cl.modelinfos[i] = mi_no_lerp_hack;
		else if (s == "soldier" || s == "dog" || s == "demon" || s == "ogre"
		|| s == "shambler" || s == "knight"	|| s == "zombie" || s == "wizard"
		|| s == "enforcer" || s == "fish" || s == "hknight" || s == "shalrath"
		|| s == "tarbaby" || s == "armabody" || s == "armalegs"
		|| s == "grem" || s == "scor")
			cl.modelinfos[i] = mi_monster;
	}
}

static void CL_TransmitModelCrc(int index, string info_key)
{
	if (index != -1) {
		struct model_s *model = cl.model_precache[index];
		unsigned short crc = R_ModelChecksum (model);
		MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
		MSG_WriteString (&cls.netchan.message, va("setinfo %s %d", info_key.c_str(), (int) crc));
	}
}


/*
=================
CL_Prespawn
=================
*/
void CL_Prespawn (void)
{
	if (!cl.model_precache[1])
		Host_Error ("CL_Prespawn: NULL worldmodel");

	CL_FindModelNumbers ();
	R_NewMap (cl.model_precache[1]);
	R_SetSky (cl.sky);

	TP_NewMap ();

	Hunk_Check ();		// make sure nothing is hurt

	CL_TransmitModelCrc (cl_playerindex, "pmodel");
	CL_TransmitModelCrc (cl_eyesindex, "emodel");

	// done with modellist, request first of static signon messages
	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	MSG_WriteString (&cls.netchan.message, va("prespawn %i 0 %i", cl.servercount, cl.map_checksum2));
}


/*
=================
VWepModel_NextDownload
=================
*/
#ifdef VWEP_TEST
void VWepModel_NextDownload (void)
{
	int		i;

	if (!cl.z_ext & Z_EXT_VWEP || !cl.vw_model_name[0][0]) {
		// no vwep support, go straight to prespawn
		CL_Prespawn ();
		return;
	}

	if (cls.downloadnumber == 0) {
		if (!com_serveractive || developer.value)
			Com_Printf ("Checking vwep models...\n");
		//cls.downloadnumber = 0;
	}

	cls.downloadtype = dl_vwep_model;
	for ( ; cls.downloadnumber < MAX_VWEP_MODELS; cls.downloadnumber++)
	{
		if (!cl.vw_model_name[cls.downloadnumber][0] ||
			!strcmp(cl.vw_model_name[cls.downloadnumber], "-"))
			continue;
		if (!CL_CheckOrDownloadFile(cl.vw_model_name[cls.downloadnumber]))
			return;		// started a download
	}

	for (i = 0; i < MAX_VWEP_MODELS; i++)
	{
		if (!cl.vw_model_name[i][0])
			continue;

		if (strcmp(cl.vw_model_name[i], "*"))
			cl.vw_model_precache[i] = Mod_ForName (cl.vw_model_name[i], false, false);

		if (!cl.vw_model_precache[i]) {
			// never mind
			// Com_Printf ("Warning: model %s could not be found\n", cl.vw_model_name[i]);
		}
	}

	if (!strcmp(cl.vw_model_name[0], "*") || cl.vw_model_precache[0])
		cl.vwep_enabled = true;
	else {
		// if the vwep player model is required but not present,
		// don't enable vwep support
	}

	// all done
	CL_Prespawn ();
}
#endif


/*
=================
Model_NextDownload
=================
*/
void Model_NextDownload (void)
{
	string s;
	int		i;
	qbool gpl_map;
	extern qbool r_gpl_map;
	char mapname[MAX_QPATH];
	int cs2;

	if (cls.downloadnumber == 0)
	{
		if (!com_serveractive || developer.value)
			Com_Printf ("Checking models...\n");
		cls.downloadnumber = 1;
	}

	cls.downloadtype = dl_model;
	for ( 
		; cl.model_name[cls.downloadnumber][0]
		; cls.downloadnumber++)
	{
		s = cl.model_name[cls.downloadnumber];
		if (s[0] == '*')
			continue;	// inline brush model
		if (!CL_CheckOrDownloadFile(s))
			return;		// started a download
	}

	cl.clipmodels[1] = CM_LoadMap (cl.model_name[1], true, NULL, &cl.map_checksum2);

	COM_StripExtension (COM_SkipPath(cl.model_name[1].c_str()), mapname);
	cs2 = Com_TranslateMapChecksum (mapname, cl.map_checksum2);
	gpl_map = (cl.map_checksum2 != cs2);
	cl.map_checksum2 = cs2;
#ifdef GLQUAKE
	r_gpl_map = gpl_map;
#endif

	for (i=1 ; i<MAX_MODELS ; i++)
	{
		if (!cl.model_name[i][0])
			break;

		cl.model_precache[i] = Mod_ForName(cl.model_name[i], false, i == 1);

		if (!cl.model_precache[i])
		{
			Com_Printf ("\nThe required model file '%s' could not be found or downloaded.\n\n"
				, cl.model_name[i]);
			Com_Printf ("You may need to download or purchase a %s client "
				"pack in order to play on this server.\n\n", cls.gamedirfile);
			Host_EndGame ();
			return;
		}

		if (cl.model_name[i][0] == '*')
			cl.clipmodels[i] = CM_InlineModel(cl.model_name[i]);
	}

#ifdef VWEP_TEST
	// done with normal models, request vwep models if necessary
	cls.downloadtype = dl_vwep_model;
	cls.downloadnumber = 0;
	VWepModel_NextDownload ();
#else
	CL_Prespawn ();
#endif
}

/*
=================
ownload
=================
*/
void Sound_NextDownload (void)
{
	string s;

	if (cls.downloadnumber == 0)
	{
		if (!com_serveractive || developer.value)
			Com_Printf ("Checking sounds...\n");
		cls.downloadnumber = 1;
	}

	cls.downloadtype = dl_sound;
	for ( 
		; cl.sound_name[cls.downloadnumber][0]
		; cls.downloadnumber++)
	{
		s = cl.sound_name[cls.downloadnumber];
		if (!CL_CheckOrDownloadFile("sound/" + s))
			return;		// started a download
	}

	for (int i=1 ; i<MAX_SOUNDS ; i++)
	{
		if (!cl.sound_name[i][0])
			break;
		cl.sound_precache[i] = S_PrecacheSound((char *)cl.sound_name[i].c_str());
	}

	// done with sounds, request models now
	memset (cl.model_precache, 0, sizeof(cl.model_precache));
	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	MSG_WriteString (&cls.netchan.message, va("modellist %i %i", cl.servercount, 0));
}


static char skinlist[MAX_CLIENTS][32];
static int numskins;

void Skin_NextDownload (void);

// Build a list of skins to download and start downloading
void CL_Skins_f (void)
{
	int i, j;

	if (cls.demoplayback || cls.state != ca_onserver)
		return;

	numskins = 0;

	if (noskins.value)
		goto done;

	// build a list of skins to check
	CL_UpdateSkins ();
	for (i = 0; i < MAX_CLIENTS; i++)
	{
		char *s = cl.players[i].skin;
		if (i == cl.playernum || !*s)
			continue;
		for (j = 0; j < numskins; j++)
			if (!strcmp(s, skinlist[j]))
				goto skip;
		assert (numskins < MAX_CLIENTS);
		strlcpy (skinlist[numskins], s, sizeof(skinlist[0]));
		numskins++;
skip:	;
	}

done:
	cls.downloadnumber = 0;
	cls.downloadtype = dl_skin;
	Skin_NextDownload ();
}


/*
=================
Skin_NextDownload
=================
*/
void Skin_NextDownload (void)
{
	if (!numskins)
		goto done;

	if (cls.downloadnumber == 0) {
		if (!com_serveractive || developer.value)
			Com_Printf ("Checking skins...\n");
	}
	cls.downloadtype = dl_skin;

	for ( 
		; cls.downloadnumber != numskins
		; cls.downloadnumber++)
	{
		char *s = skinlist[cls.downloadnumber];
		if (!CL_CheckOrDownloadFile(va("skins/%s.pcx", s)))
			return;		// started a download
	}

done:
	cls.downloadtype = dl_none;

	// get next signon phase
	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	MSG_WriteString (&cls.netchan.message, va("begin %i", cl.servercount));
	Cache_Report ();		// print remaining memory
}



/*
======================
CL_RequestNextDownload
======================
*/
void CL_RequestNextDownload (void)
{
	switch (cls.downloadtype)
	{
	case dl_single:
		break;
	case dl_skin:
		Skin_NextDownload ();
		break;
	case dl_model:
		Model_NextDownload ();
		break;
#ifdef VWEP_TEST
	case dl_vwep_model:
		VWepModel_NextDownload ();
		break;
#endif
	case dl_sound:
		Sound_NextDownload ();
		break;
	case dl_none:
	default:
		Com_DPrintf ("Unknown download type.\n");
	}
}

/*
=====================
CL_ParseDownload

A download message has been received from the server
=====================
*/
void CL_ParseDownload (void)
{
	int		size, percent;
	char	name[1024];
	int		r;


	// read the data
	size = MSG_ReadShort ();
	percent = MSG_ReadByte ();

	if (cls.demoplayback) {
		if (size > 0)
			msg_readcount += size;
		return; // not in demo playback
	}

	if (size == -1)
	{
		Com_Printf ("File not found.\n");
		if (cls.download)
		{
			Com_Printf ("cls.download shouldn't have been set\n");
			fclose (cls.download);
			cls.download = NULL;
		}
		CL_RequestNextDownload ();
		return;
	}

	// open the file if not opened yet
	if (!cls.download)
	{
		if (strncmp(cls.downloadtempname, "skins/", 6))
			snprintf (name, sizeof(name), "%s/%s", cls.gamedir, cls.downloadtempname);
		else
			snprintf (name, sizeof(name), "qw/%s", cls.downloadtempname);

		COM_CreatePath (name);

		cls.download = fopen (name, "wb");
		if (!cls.download)
		{
			msg_readcount += size;
			Com_Printf ("Failed to open %s\n", cls.downloadtempname);
			CL_RequestNextDownload ();
			return;
		}
	}

	fwrite (net_message.data + msg_readcount, 1, size, cls.download);
	msg_readcount += size;

	if (percent != 100)
	{
// change display routines by zoid
		// request next block
#if 0
		Com_Printf (".");
		if (10*(percent/10) != cls.downloadpercent)
		{
			cls.downloadpercent = 10*(percent/10);
			Com_Printf ("%i%%", cls.downloadpercent);
		}
#endif
		cls.downloadpercent = percent;

		MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
		SZ_Print (&cls.netchan.message, "nextdl");
	}
	else
	{
		char	oldn[MAX_OSPATH];
		char	newn[MAX_OSPATH];

#if 0
		Com_Printf ("100%%\n");
#endif

		fclose (cls.download);

		// rename the temp file to its final name
		if (strcmp(cls.downloadtempname, cls.downloadname)) {
			if (strncmp(cls.downloadtempname,"skins/",6)) {
				sprintf (oldn, "%s/%s", cls.gamedir, cls.downloadtempname);
				sprintf (newn, "%s/%s", cls.gamedir, cls.downloadname);
			} else {
				sprintf (oldn, "qw/%s", cls.downloadtempname);
				sprintf (newn, "qw/%s", cls.downloadname);
			}
			r = rename (oldn, newn);
			if (r)
				Com_Printf ("failed to rename.\n");
		}

		cls.download = NULL;
		cls.downloadpercent = 0;

		// get another file if needed

		CL_RequestNextDownload ();
	}
}

static byte *upload_data;
static int upload_pos;
static int upload_size;

void CL_NextUpload(void)
{
	byte	buffer[1024];
	int		r;
	int		percent;
	int		size;

	if (!upload_data)
		return;

	r = upload_size - upload_pos;
	if (r > 768)
		r = 768;
	memcpy(buffer, upload_data + upload_pos, r);
	MSG_WriteByte (&cls.netchan.message, clc_upload);
	MSG_WriteShort (&cls.netchan.message, r);

	upload_pos += r;
	size = upload_size;
	if (!size)
		size = 1;
	percent = upload_pos*100/size;
	MSG_WriteByte (&cls.netchan.message, percent);
	SZ_Write (&cls.netchan.message, buffer, r);

	Com_DPrintf ("UPLOAD: %6d: %d written\n", upload_pos - r, r);

	if (upload_pos != upload_size)
		return;

	Com_Printf ("Upload completed\n");

	Q_free (upload_data);
	upload_data = 0;
	upload_pos = upload_size = 0;
}

void CL_StartUpload (byte *data, int size)
{
	if (cls.state < ca_onserver)
		return; // gotta be connected

	// override
	if (upload_data)
		Q_free (upload_data);

	Com_DPrintf ("Upload starting of %d...\n", size);

	upload_data = (byte *)Q_malloc (size);
	memcpy (upload_data, data, size);
	upload_size = size;
	upload_pos = 0;

	CL_NextUpload();
} 

qbool CL_IsUploading(void)
{
	if (upload_data)
		return true;
	return false;
}

void CL_StopUpload(void)
{
	if (upload_data)
		Q_free (upload_data);
	upload_data = NULL;
}

/*
=====================================================================

  SERVER CONNECTING MESSAGES

=====================================================================
*/

/*
==================
CL_ParseServerData
==================
*/
void CL_ParseServerData (void)
{
	char	*str;
	FILE	*f;
	char	fn[MAX_OSPATH];
	qbool	cflag = false;
	int		protover;

	Com_DPrintf ("Serverdata packet received.\n");
//
// wipe the client_state_t struct
//
	CL_ClearState ();

// parse protocol version number
// allow old demos to play
	protover = MSG_ReadLong ();
	if (protover != PROTOCOL_VERSION && !(cls.demoplayback && (protover >= 24 && protover <= 28))) {
		Host_Error ("Server returned version %i, not %i\n", protover, PROTOCOL_VERSION);
	}
	cl.protocol = protover;

	cl.servercount = MSG_ReadLong ();

	// game directory
	str = MSG_ReadString ();

	cl.teamfortress = !Q_stricmp(str, "fortress");
	cl.hipnotic = !Q_stricmp(str, "hipnotic");

	if (Q_stricmp(cls.gamedirfile, str)) {
		// save current config
		CL_WriteConfiguration ();
		strlcpy (cls.gamedirfile, str, sizeof(cls.gamedirfile));
		snprintf (cls.gamedir, sizeof(cls.gamedir),
			"%s/%s", com_basedir, cls.gamedirfile);
		cflag = true;
	}

	if (!com_serveractive)
		FS_SetGamedir (str);

	// run config.cfg and frontend.cfg in the gamedir if they exist
	if (cflag) {
		int cl_warncmd_val = cl_warncmd.value;
		snprintf (fn, sizeof(fn), "%s/%s", cls.gamedir, "config.cfg");
		if ((f = fopen(fn, "r")) != NULL) {
			fclose(f);
			Cbuf_AddText ("cl_warncmd 0\n");
			if (!strcmp(cls.gamedirfile, com_gamedirfile))
				Cbuf_AddText ("exec config.cfg\n");
			else
				Cbuf_AddText (va("exec ../%s/config.cfg\n", cls.gamedirfile));
		}
		snprintf (fn, sizeof(fn), "%s/%s", cls.gamedir, "frontend.cfg");
		if ((f = fopen(fn, "r")) != NULL) {
			fclose(f);
			Cbuf_AddText ("cl_warncmd 0\n");
			if (!strcmp(cls.gamedirfile, com_gamedirfile))
				Cbuf_AddText ("exec frontend.cfg\n");
			else
				Cbuf_AddText (va("exec ../%s/frontend.cfg\n", cls.gamedirfile));
		}
		snprintf (fn, sizeof(fn), "cl_warncmd %d\n", cl_warncmd_val);
		Cbuf_AddText (fn);
	}

#ifdef MVDPLAY
	if (cls.mvdplayback)
	{
		// FIXME
		cls.mvd_newtime = cls.mvd_oldtime = MSG_ReadFloat();
		cl.playernum = MAX_CLIENTS - 1;
		cl.spectator = true;
	} else
#endif
	{
		// parse player slot, high bit means spectator
		cl.playernum = MSG_ReadByte ();
		if (cl.playernum & 128) {
			cl.spectator = true;
			cl.playernum &= ~128;
		}
    }

	// get the full level name
	str = MSG_ReadString ();
	cl.levelname = str;

	// get the movevars
	if (cl.protocol >= 25)
	{	// from QW 2.00 on
		cl.movevars.gravity			   = MSG_ReadFloat();
		cl.movevars.stopspeed          = MSG_ReadFloat();
		cl.movevars.maxspeed           = MSG_ReadFloat();
		cl.movevars.spectatormaxspeed  = MSG_ReadFloat();
		cl.movevars.accelerate         = MSG_ReadFloat();
		cl.movevars.airaccelerate      = MSG_ReadFloat();
		cl.movevars.wateraccelerate    = MSG_ReadFloat();
		cl.movevars.friction           = MSG_ReadFloat();
		cl.movevars.waterfriction      = MSG_ReadFloat();
		cl.movevars.entgravity         = MSG_ReadFloat();
	}
	else
	{
		cl.movevars.gravity = 800;
		cl.movevars.stopspeed = 100;
		cl.movevars.maxspeed = 320;
		cl.movevars.spectatormaxspeed = 500;
		cl.movevars.accelerate = 10;
		cl.movevars.airaccelerate = 10;
		cl.movevars.wateraccelerate = 10;
		cl.movevars.friction = 4;
		cl.movevars.waterfriction = 4;
		cl.movevars.entgravity = 1;
	}

	// separate the printfs so the server message can have a color
	Com_Printf ("\n");
	Com_Printf ("\35\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\37\n");
	Com_Printf ("%c%s\n", 2, str);
	if (!strstr(str, "\236\236\236"))
		Com_Printf ("\35\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\37\n");
	// ask for the sound list next
	memset(cl.sound_name, 0, sizeof(cl.sound_name));
	MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
	MSG_WriteString (&cls.netchan.message, va("soundlist %i %i", cl.servercount, 0));

	// now waiting for downloads, etc
	cls.state = ca_onserver;
}

/*
==================
CL_ParseSoundlist
==================
*/
void CL_ParseSoundlist (void)
{
	int	numsounds;
	char	*str;
	int n;

// precache sounds
//	memset (cl.sound_precache, 0, sizeof(cl.sound_precache));

	if (cl.protocol >= 26)
		numsounds = MSG_ReadByte();
	else
		numsounds = 0;

	for (;;) {
		str = MSG_ReadString ();
		if (!str[0])
			break;
		numsounds++;
		if (numsounds == MAX_SOUNDS)
			Host_Error ("Server sent too many sound precaches");
		cl.sound_name[numsounds] = str;
	}

	if (cl.protocol >= 26)
	{
		n = MSG_ReadByte();

		if (n) {
			MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
			MSG_WriteString (&cls.netchan.message, va("soundlist %i %i", cl.servercount, n));
			return;
		}
	}

	cls.downloadnumber = 0;
	cls.downloadtype = dl_sound;
	Sound_NextDownload ();
}

/*
==================
CL_ParseModellist
==================
*/
void CL_ParseModellist (void)
{
	int	nummodels;
	char	*str;
	int n;

// precache models and note certain default indexes
	if (cl.protocol >= 26)
		nummodels = MSG_ReadByte();
	else
		nummodels = 0;

	for (;;)
	{
		str = MSG_ReadString ();
		if (!str[0])
			break;

		if (++nummodels==MAX_MODELS)
			Host_Error ("Server sent too many model precaches");

		cl.model_name[nummodels] = str;
	}

	if (cl.protocol >= 26)
	{
		n = MSG_ReadByte();

		if (n) {
			MSG_WriteByte (&cls.netchan.message, clc_stringcmd);
			MSG_WriteString (&cls.netchan.message, va("modellist %i %i", cl.servercount, n));
			return;
		}
	}

	char	mapname[MAX_QPATH];
	COM_StripExtension (COM_SkipPath(cl.model_name[1].c_str()), mapname);
	Cvar_ForceSet (&host_mapname, mapname);

	cls.downloadnumber = 0;
	cls.downloadtype = dl_model;
	Model_NextDownload ();
}

/*
==================
CL_ParseBaseline
==================
*/
void CL_ParseBaseline (entity_state_t *es)
{
	int			i;
	
	es->modelindex = MSG_ReadByte ();
	es->frame = MSG_ReadByte ();
	es->colormap = MSG_ReadByte();
	es->skinnum = MSG_ReadByte();

	for (i=0 ; i<3 ; i++)
	{
		es->s_origin[i] = MSG_ReadShort ();
		es->s_angles[i] = MSG_ReadChar ();
	}
}



/*
=====================
CL_ParseStatic

Static entities are non-interactive world objects
like torches
=====================
*/
void CL_ParseStatic (void)
{
	entity_t *ent;
	entity_state_t	es;

	CL_ParseBaseline (&es);

	if (!cl.model_precache[es.modelindex])
		return;		// a Host_Error would be more appropriate, but we
					// tolerate this just to be compatible with QW 2.30

	if (cl.num_statics >= MAX_STATIC_ENTITIES)
		Host_Error ("Too many static entities");
	ent = &cl_static_entities[cl.num_statics];
	cl.num_statics++;

// copy it to the current state
	ent->model = cl.model_precache[es.modelindex];
	ent->frame = es.frame;
	ent->colormap = 0;
	ent->skinnum = es.skinnum;

	MSG_UnpackOrigin (es.s_origin, ent->origin);
	MSG_UnpackAngles (es.s_angles, ent->angles);
	
	R_AddEfrags (ent);
}

/*
===================
CL_ParseStaticSound
===================
*/
void CL_ParseStaticSound (void)
{
	extern cvar_t	cl_staticsounds;
	static_sound_t	ss;
	int			i;
	
	for (i=0 ; i<3 ; i++)
		ss.org[i] = MSG_ReadCoord ();
	ss.sound_num = MSG_ReadByte ();
	ss.vol = MSG_ReadByte ();
	ss.atten = MSG_ReadByte ();

	if (cl.num_static_sounds < MAX_STATIC_SOUNDS) {
		cl.static_sounds[cl.num_static_sounds] = ss;
		cl.num_static_sounds++;
	}

	if (cl_staticsounds.value)
		S_StaticSound (cl.sound_precache[ss.sound_num], ss.org, ss.vol, ss.atten);
}



/*
=====================================================================

ACTION MESSAGES

=====================================================================
*/

/*
==================
CL_ParseStartSoundPacket
==================
*/
void CL_ParseStartSoundPacket(void)
{
    vec3_t  pos;
    int 	channel, ent;
    int 	sound_num;
    int 	volume;
    float 	attenuation;  
 	int		i;
	           
    channel = MSG_ReadShort(); 

    if (channel & SND_VOLUME)
		volume = MSG_ReadByte ();
	else
		volume = DEFAULT_SOUND_PACKET_VOLUME;
	
    if (channel & SND_ATTENUATION)
		attenuation = MSG_ReadByte () / 64.0;
	else
		attenuation = DEFAULT_SOUND_PACKET_ATTENUATION;
	
	sound_num = MSG_ReadByte ();

	for (i=0 ; i<3 ; i++)
		pos[i] = MSG_ReadCoord ();
 
	ent = (channel>>3)&1023;
	channel &= 7;

	if (ent > MAX_CL_EDICTS)
		Host_Error ("CL_ParseStartSoundPacket: ent = %i", ent);
	
// FIXME oldman
#ifdef MVDPLAY
    if (cls.mvdplayback) {
	    if (cl.spectator && cam_curtarget != CAM_NOTARGET && ent == cam_curtarget + 1)
		    ent = cl.playernum + 1;
    }
#endif

    S_StartSound (ent, channel, cl.sound_precache[sound_num], pos, volume/255.0, attenuation);
	if (ent == cl.playernum+1)
		TP_CheckPickupSound ((char *)cl.sound_name[sound_num].c_str(), pos);
}       


/*
==================
CL_ParseClientdata

Server information pertaining to this client only, sent every frame
==================
*/
void CL_ParseClientdata (void)
{
	float		latency;
	frame_t		*frame;

// calculate simulated time of message
    cl.oldparsecount = cl.parsecount;
	cl.parsecount = cls.netchan.incoming_acknowledged;
	frame = &cl.frames[cl.parsecount & UPDATE_MASK];

#ifdef MVDPLAY
	if (cls.mvdplayback)
        frame->senttime = cls.realtime - cls.frametime;
#endif

	frame->receivedtime = cls.realtime;

// calculate latency
	latency = frame->receivedtime - frame->senttime;

	if (latency >= 0 && latency <= 1) {
	// drift the average latency towards the observed latency
		if (latency < cls.latency)
			cls.latency = latency;
		else
			cls.latency += 0.001;	// drift up, so correction is needed
    }

	cl.num_nails = 0;
}

/*
** CL_NewTranslation
*/
void CL_NewTranslation (int slot)
{
	char	skin[32];
	player_info_t	*player;
	string myteam;

	assert (slot >= 0 && slot <= MAX_CLIENTS);

	player = &cl.players[slot];
	if (player->spectator)
		return;

	player->topcolor = atoi(player->userinfo["topcolor"].c_str());
	player->bottomcolor = atoi(player->userinfo["bottomcolor"].c_str());

	if (noskins.value == 1) {
		player->skin[0] = 0;
		return;
	}

	strlcpy (skin, player->userinfo["skin"].c_str(), sizeof(skin));
	if (!skin[0] || !strcmp(skin, "base"))
		strlcpy (skin, baseskin.string, sizeof(skin));
	if (allskins.string[0])
		strlcpy (skin, allskins.string, sizeof(skin));

	// check team/enemy overrides
	if ( !cl.teamfortress && !(cl.fpd & FPD_NO_FORCE_COLOR) ) {
        qbool teammate;

		if (cl.spectator && cam_curtarget != CAM_NOTARGET)
			myteam = cl.players[Cam_PlayerNum()].team;
		else if (!cl.spectator)
    	    myteam = cl.players[cl.playernum].team;

        teammate = (cl.teamplay	&& player->team == myteam) ? true : false;

		if (teammate && cl_teamtopcolor >= 0) {
			player->topcolor = cl_teamtopcolor;
			player->bottomcolor = cl_teambottomcolor;
		}
        else if (!teammate && cl_enemytopcolor >= 0 && slot != cl.playernum) {
			player->topcolor = cl_enemytopcolor;
			player->bottomcolor = cl_enemybottomcolor;
		}

		if (teammate && teamskin.string[0])
			strlcpy (skin, teamskin.string, sizeof(skin));
		else if (!teammate && enemyskin.string[0])
			strlcpy (skin, enemyskin.string, sizeof(skin));
	}

	COM_StripExtension(skin, skin);
	strlcpy (player->skin, skin, sizeof(player->skin));
}

/*
** CL_UpdateSkins
*/
void CL_UpdateSkins (void)
{
	int i;

	for (i = 0; i < MAX_CLIENTS; i++)
		CL_NewTranslation (i);
}

/*
==============
CL_ProcessUserInfo
==============
*/
void CL_ProcessUserInfo (int slot, player_info_t *player)
{
	string old_team;

	player->name = player->userinfo["name"];
	if (player->name == "" && player->userid && player->userinfo.to_string().length() >= MAX_INFO_STRING - 17) {
		// somebody's trying to hide himself by overflowing userinfo
		player->name = " ";
	}
	old_team = player->team;
	player->team = player->userinfo["team"];

	if (player->userinfo["*spectator"] != "")
		player->spectator = true;
	else
		player->spectator = false;

#ifdef MVDPLAY
	if (!cls.mvdplayback && slot == cl.playernum && player->name[0]) {
#else
	if (slot == cl.playernum && player->name[0]) {
#endif
		if (cl.spectator && !player->spectator)
			Cam_Reset ();	// switching to player mode
		cl.spectator = player->spectator;
	}

	Sbar_Changed ();

	if (slot == cl.playernum && player->team != old_team)
		CL_UpdateSkins ();
	else
		CL_NewTranslation (slot);
}

/*
==============
CL_UpdateUserinfo
==============
*/
void CL_UpdateUserinfo (void)
{
	int		slot;
	player_info_t	*player;

	slot = MSG_ReadByte ();
	if (slot >= MAX_CLIENTS)
		Host_Error ("CL_ParseServerMessage: svc_updateuserinfo > MAX_CLIENTS");

	player = &cl.players[slot];

	player->userid = MSG_ReadLong ();
	string tmp = MSG_ReadString();

	tmp = tmp.substr(0, MAX_INFO_STRING-1);
	player->userinfo.load_from_string(tmp);

	CL_ProcessUserInfo (slot, player);
}

/*
==============
CL_SetInfo
==============
*/
void CL_SetInfo (void)
{
	int		slot;
	player_info_t	*player;
	char key[MAX_INFO_KEY];
	char value[MAX_INFO_KEY];

	slot = MSG_ReadByte ();
	if (slot >= MAX_CLIENTS)
		Host_Error ("CL_ParseServerMessage: svc_setinfo > MAX_CLIENTS");

	player = &cl.players[slot];

	strlcpy (key, MSG_ReadString(), sizeof(key));
	strlcpy (value, MSG_ReadString(), sizeof(value));

	if (!cl.teamfortress)	// don't allow cheating in TF
		Com_DPrintf ("SETINFO %s: %s=%s\n", player->name, key, value);

	bool r = player->userinfo.set(key, value);
	if (!r)
		return;

	CL_ProcessUserInfo (slot, player);
}


/*
==============
CL_ProcessServerInfo

Called by CL_FullServerinfo_f and CL_ParseServerInfoChange

MUST be called at least once when entering a new map so that things initialize properly
==============
*/
void CL_ProcessServerInfo (void)
{
	string p;

	// game type (sbar code checks it)
	p = cl.serverinfo["deathmatch"];
	if (p != "")
		cl.gametype = atoi(p.c_str()) ? GAME_DEATHMATCH : GAME_COOP;
	else
		cl.gametype = GAME_DEATHMATCH;	// assume GAME_DEATHMATCH by default

	cl.maxclients = Q_atoi(cl.serverinfo["maxclients"].c_str());
	cl.maxfps = Q_atof(cl.serverinfo["maxfps"]);

	p = cl.serverinfo["fbskins"];
	cl.allow_fbskins = (p != "") ? (Q_atoi(p) != 0) : !cl.teamfortress; // for TF, fbskins are disabled by default

	p = cl.serverinfo["fakeshaft"];
	if (p != "")
		cl.allow_fakeshaft = Q_atoi(p);
	else {
		p = cl.serverinfo["truelightning"];
		cl.allow_fakeshaft = (p != "") ? (Q_atoi(p) != 0) : true;	// allowed by default
	}

	p = cl.serverinfo["allow_frj"];
	cl.allow_frj = (p != "") ? Q_atoi(p) : true;		// allowed by default

	int fpd = cls.demoplayback ? 0 : atoi(cl.serverinfo["fpd"].c_str());

	// Get the server's ZQuake extension bits
	cl.z_ext = atoi(cl.serverinfo["*z_ext"].c_str());

#ifdef VWEP_TEST
	if (atoi(cl.serverinfo["*vwtest"].c_str()))
		cl.z_ext |= Z_EXT_VWEP;
#endif

	// Initialize cl.maxpitch & cl.minpitch
	p = (cl.z_ext & Z_EXT_PITCHLIMITS) ? cl.serverinfo["maxpitch"] : "";
	cl.maxpitch = (p != "") ? Q_atof(p) : 80.0f;
	p = (cl.z_ext & Z_EXT_PITCHLIMITS) ? cl.serverinfo["minpitch"] : "";
	cl.minpitch = (p != "") ? Q_atof(p) : -70.0f;

	// movement vars for prediction
	cl.movevars.bunnyspeedcap = Q_atof(cl.serverinfo["pm_bunnyspeedcap"]);
	cl.movevars.slidefix = (Q_atof(cl.serverinfo["pm_slidefix"]) != 0);
	cl.movevars.airstep = (Q_atof(cl.serverinfo["pm_airstep"]) != 0);
	cl.movevars.pground = (Q_atof(cl.serverinfo["pm_pground"]) != 0)
		&& (cl.z_ext & Z_EXT_PF_ONGROUND) /* pground doesn't make sense without this */;
	p = cl.serverinfo["pm_ktjump"];
	cl.movevars.ktjump = (p != "") ? Q_atof(p) : (cl.teamfortress ? 0 : 0.5); 

	// deathmatch and teamplay
	cl.deathmatch = atoi(cl.serverinfo["deathmatch"].c_str());
	int teamplay = atoi(cl.serverinfo["teamplay"].c_str());

	// update skins if needed
	if (teamplay != cl.teamplay || fpd != cl.fpd) {
		cl.teamplay = teamplay;
		cl.fpd = fpd;
		if (cls.state == ca_active)
			CL_UpdateSkins ();
	}

	// parse skybox
	if (cl.sky != (p = cl.serverinfo["sky"])) {
		// sky has changed
		cl.sky = p;
		if (cl.sky.find("..") != string::npos)
			cl.sky = "";
		if (cls.state >= ca_onserver && cl.model_precache[1])
			R_SetSky (cl.sky);
	}
}


/*
==============
CL_ParseVWepPrecache

A typical vwep model list will look like this:
"0 player_w.mdl"	// player model to use
"1"					// no weapon at all
"2 w_shot.mdl"
"3 w_shot2.mdl"
...
""					// list is terminated with an empty key
==============
*/
#ifdef VWEP_TEST
void CL_ParseVWepPrecache (char *str)
{
	int num;
	char *p;

	if (cls.state == ca_active) {
		// could do a Host_Error as well
		Com_Printf ("CL_ParseVWepPrecache: ca_active, ignoring\n");
		return;
	}

	if (!*str) {
		Com_DPrintf ("VWEP END\n");
		return;
	}

	num = atoi(str);

	if ( !isdigit((int)(unsigned char)str[0]) )
		return;		// not a vwep model message

	if ((unsigned)num >= MAX_MODELS)
		Host_Error("CL_ParseVWepModel: num >= MAX_MODELS");

	if ((unsigned)num >= MAX_VWEP_MODELS)
		return;		// fail silently to allow for expansion in future

	p = strchr (str, ' ');
	if (p && p[1]) {
		p++;	// skip the space

		if (!strcmp(p, "*")) {
			// empty model
			strcpy (cl.vw_model_name[num], "*");
		}
		else {
			if (strstr(p, "..") || p[0] == '/' || p[0] == '\\')
				Host_Error("CL_ParseVWepModel: illegal model name '%s'", p);

			if (strstr(p, "/"))
				// a full path was specified
				strlcpy (cl.vw_model_name[num], p, sizeof(cl.vw_model_name[0]));
			else {
				// use default path
				strcpy (cl.vw_model_name[num], "progs/");	// FIXME, "progs/vwep/"	?
				strlcat (cl.vw_model_name[num], p, sizeof(cl.vw_model_name[0]));
			}

			// use default extension if not specified
			if (!strstr(p, "."))
				strlcat (cl.vw_model_name[num], ".mdl", sizeof(cl.vw_model_name[0]));
		}
	}
	else
		cl.vw_model_name[num][0] = '\0';

	Com_DPrintf ("VWEP %i: '%s'\n", num, cl.vw_model_name[num]);
}
#endif


/*
==============
CL_ParseServerInfoChange
==============
*/
void CL_ParseServerInfoChange (void)
{
	string key = MSG_ReadString();
	string value = MSG_ReadString();

#ifdef VWEP_TEST
	if ( (cl.z_ext & Z_EXT_VWEP) && key == "#vw" ) {
		CL_ParseVWepPrecache (value.c_str());
		return;
	}
#endif

	Com_DPrintf ("SERVERINFO: %s=%s\n", key.c_str(), value.c_str());

	bool r = cl.serverinfo.set(key, value);
	if (!r)
		return;

	CL_ProcessServerInfo ();
}


// for CL_ParsePrint
static void FlushString (const string s, int level, qbool team, int offset)
{
	wchar *ws = decode_string(s.c_str());

#ifndef AGRIP
	if (level == PRINT_CHAT)
	{
		wchar	buf[2048];
		wchar	*out = buf, *p, *p1;
		extern cvar_t	cl_parseWhiteText;
		qbool	parsewhite;

		parsewhite = cl_parseWhiteText.value == 1 ||
			(cl_parseWhiteText.value == 2 && team);

		for (p=ws; *p; p++) {
			if  (*p == '{' && parsewhite && p-ws >= offset) {
				p1 = qwcschr (p + 1, '}');
				if (p1) {
					memcpy (out, p + 1, (p1 - p - 1) * sizeof(out[0]));
					out += p1 - p - 1;
					p = p1;
					continue;
				}
			}
			if (*p != 10 && *p != 13
				&& !(p==ws && (*p==1 || *p==2)))
				*out++ = *p | 128;	// convert to red
			else
				*out++ = *p;
		}
		*out = 0;
		Com_PrintW (buf);
	}
	else
#endif
		Com_PrintW (ws);
	if (level > 3)
		return;
	if (team)
		level = 4;
	TP_SearchForMsgTriggers ((char *)s.c_str() + offset, level);
}

/*
==============
CL_ParsePrint
==============
*/
void CL_ParsePrint (void)
{
	int		flags=0;
	int		offset = 0;
	extern cvar_t	cl_chatsound, cl_nofake;
	qbool	suppress_talksound;

	int level = MSG_ReadByte ();
	char *s = MSG_ReadString ();

	if (level == PRINT_CHAT) {
		TP_CheckVersionRequest (s);
		flags = TP_CategorizeMessage (s, &offset);

		if (flags == 2 && !TP_FilterMessage(s + offset))
			return;

		suppress_talksound = false;

		if (flags == 2)
			suppress_talksound = TP_CheckSoundTrigger (s + offset);

		if (!cl_chatsound.value ||		// no sound at all
			(cl_chatsound.value == 2 && flags != 2))	// only play sound in mm2
			suppress_talksound = true;

		if (!suppress_talksound)
			S_LocalSound ("misc/talk.wav");

		if (cl_nofake.value == 1 || (cl_nofake.value == 2 && flags != 2)) {
			for (char *p = s; *p; p++)
				if (*p == 13 || (*p == 10 && p[1]))
					*p = ' '; 
		}
	}

//#ifndef AGRIP
	if (cl.sprint_buf[0] && (level != cl.sprint_level
		|| s[0] == 1 || s[0] == 2)) {
		FlushString (cl.sprint_buf, cl.sprint_level, false, 0);
		cl.sprint_buf[0] = 0;
	}

	if (s[0] == 1 || s[0] == 2) {
		FlushString (s, level, (flags==2), offset);
		return;
	}
//#endif

	cl.sprint_buf += s;
	cl.sprint_level = level;

	int pos;
	if ((pos = cl.sprint_buf.rfind('\n')) != string::npos) {
		string str = cl.sprint_buf.substr(0, pos + 1);
		cl.sprint_buf = cl.sprint_buf.substr(pos + 1);
		FlushString (str, level, (flags==2), offset);
	}
}


/*
==============
CL_ParseStufftext
==============
*/
void CL_ParseStufftext (void)
{
	char	*s;

	s = MSG_ReadString ();

	Com_DPrintf ("stufftext: %s\n", s);
	Cbuf_AddTextEx (&cbuf_svc, s);

	// This is how we transmit svc_cutscene via the QW protocol
	if (!strcmp(s, "//cutscene\n") ||
	// one day we may support a text message here
	(!strncmp(s, "//cutscene ", 11) && s[strlen(s)-1] == '\n') ) {
		cl.intermission = 3;
		cl.completed_time = cl.time;
		// we don't support cutscene messages... but no one seems
		// to use them anyway so never mind 
		SCR_CenterPrint ("");
	}

	// Execute stuffed commands immediately when starting a demo
	if (cls.demoplayback && cls.state != ca_active)
		Cbuf_ExecuteEx (&cbuf_svc); // FIXME: execute cbuf_main too?
}


/*
=====================
CL_SetStat
=====================
*/
void CL_SetStat (int stat, int value)
{
	int	j;
	if (stat < 0 || stat >= MAX_CL_STATS)
		Host_Error ("CL_SetStat: %i is invalid", stat);

#ifdef MVDPLAY
	if (cls.mvdplayback) {
		cl.players[cls.mvd_lastto].stats[stat]=value;
		if (cam_curtarget != cls.mvd_lastto)
			return;
	}
#endif
    
	Sbar_Changed ();
	
	if (stat == STAT_ITEMS)
	{	// set flash times
		if (cl.stats[STAT_ITEMS] || cls.state == ca_active) {
			for (j=0 ; j<32 ; j++)
				if ( (value & (1<<j)) && !(cl.stats[STAT_ITEMS] & (1<<j)))
					cl.item_gettime[j] = cl.time;
		}
		else {
			// reset flash times if we're just entering the map
			for (j = 0; j < 32; j++)
				cl.item_gettime[j] = -99;
		}
	}

	cl.stats[stat] = value;

	if (stat == STAT_VIEWHEIGHT && cl.z_ext & Z_EXT_VIEWHEIGHT)
		cl.viewheight = cl.stats[STAT_VIEWHEIGHT];

	if (stat == STAT_TIME && cl.z_ext & Z_EXT_SERVERTIME) {
		cl.servertime_works = true;
		cl.servertime = cl.stats[STAT_TIME] * 0.001;
	}

	TP_StatChanged(stat, value);
}

/*
==============
CL_MuzzleFlash
==============
*/
void CL_MuzzleFlash (void)
{
	vec3_t		forward;
	vec3_t		origin, angles;
	cdlight_t	*dl;
	int			i;
	int			j, num_ent;
	entity_state_t	*ent;
	player_state_t	*state;

	i = MSG_ReadShort ();

	if (!cl_muzzleflash.value)
		return;

	if (!cl.validsequence)
		return;

	if ((unsigned)(i-1) >= MAX_CLIENTS)
	{
		// a monster firing
		num_ent = cl.frames[cl.validsequence & UPDATE_MASK].packet_entities.num_entities;
		for (j=0; j<num_ent; j++)
		{
			ent = &cl.frames[cl.validsequence & UPDATE_MASK].packet_entities.entities[j];
			if (ent->number == i)
			{
				dl = CL_AllocDlight (-i);
				MSG_UnpackAngles (ent->s_angles, angles);
				AngleVectors (angles, forward, NULL, NULL);
				MSG_UnpackOrigin (ent->s_origin, origin);
				VectorMA (origin, 18, forward, dl->origin);
				dl->radius = 200 + (rand()&31);
				dl->minlight = 32;
				dl->die = cl.time + 0.1;
				dl->type = lt_muzzleflash;
				break;
			}
		}
		return;
	}


	//fuh : cl.playernum is used here instead of cl.viewplayernum because
	//fuh : Cam_SetViewPlayer() is not called until after CL_ReadPackets().
	if (i - 1 == cl.playernum)
	{
		if (cl_muzzleflash.value == 2)
			return;

		VectorCopy (cl.simorg, origin);
		VectorCopy (cl.simangles, angles);
	}
	else
	{
#ifdef MVDPLAY
		if (cls.mvdplayback)
			state = &cl.frames[cl.oldparsecount & UPDATE_MASK].playerstate[i-1];
		else
#endif
			state = &cl.frames[cl.parsecount & UPDATE_MASK].playerstate[i-1];

		VectorCopy (state->origin, origin);
		VectorCopy (state->viewangles, angles);
	}

	dl = CL_AllocDlight (-i);
	AngleVectors (angles, forward, NULL, NULL);
	VectorMA (origin, 18, forward, dl->origin);
	dl->radius = 200 + (rand()&31);
	dl->minlight = 32;
	dl->die = cl.time + 0.1;
	dl->type = lt_muzzleflash;
}


/*
===============
CL_ParseParticleEffect

Back from NetQuake
===============
*/
void CL_ParseParticleEffect (void)
{
	vec3_t		org, dir;
	int			i, count, color;
	int			replacement_te;

	for (i = 0; i < 3; i++)
		org[i] = MSG_ReadCoord ();
	for (i = 0; i < 3; i++)
		dir[i] = MSG_ReadChar () * (1.0/16);
	count = MSG_ReadByte ();
	color = MSG_ReadByte ();

	if (cls.demorecording) {
		// Don't write the svc_particle message to the demo, other clients
		// may not support it. Use "best approximation" if possible.
		if (count == 255)
			replacement_te = TE_EXPLOSION;
		else if (color == 73)
			replacement_te = TE_BLOOD;
		else if (color == 225) {
			replacement_te = TE_LIGHTNINGBLOOD;
		} else
			replacement_te = 0;		// don't write anything

		if (replacement_te) {
			MSG_WriteByte (&cls.demomessage, svc_temp_entity);
			MSG_WriteByte (&cls.demomessage, replacement_te);
			if (replacement_te == TE_BLOOD)
				MSG_WriteByte (&cls.demomessage, 1 /* FIXME: use count / <some value>?*/);
			MSG_WriteCoord (&cls.demomessage, org[0]);
			MSG_WriteCoord (&cls.demomessage, org[1]);
			MSG_WriteCoord (&cls.demomessage, org[2]);
		}

		cls.demomessage_skipwrite = true;
	}

	// now run the effect
	if (count == 255)
		CL_ParticleExplosion (org);
	else
		CL_RunParticleEffect2 (org, dir, color, count, 1);
}


void CL_ParseQizmoVoice (void)
{
	int i;
	int	seq, bits;
	int	num, unknown;
	
	// read the two-byte header
	seq = MSG_ReadByte ();
	bits = MSG_ReadByte ();

	seq |= (bits & 0x30) << 4;	// 10-bit block sequence number, strictly increasing
	num = bits >> 6;			// 2-bit sample number, bumped at the start of a new sample
	unknown = bits & 0x0f;		// mysterious 4 bits

	// 32 bytes of voice data follow
	for (i = 0; i < 32; i++)
		MSG_ReadByte ();
}

#define SHOWNET(x) {if(cl_shownet.value==2)Com_Printf ("%3i:%s\n", msg_readcount-1, x);}
/*
=====================
CL_ParseServerMessage
=====================
*/

void CL_ParseServerMessage (void)
{
	int			cmd;
	int			i, j;
	int			old_readcount;

//
// if recording demos, copy the message out
//
	SZ_Init (&cls.demomessage, cls.demomessage_data, sizeof(cls.demomessage_data));
	SZ_Write (&cls.demomessage, net_message.data, 8);	// store sequence numbers

	if (cl_shownet.value == 1)
		Com_Printf ("%i ",net_message.cursize);
	else if (cl_shownet.value == 2)
		Com_Printf ("------------------\n");


#ifdef MVDPLAY
	if (!cls.mvdplayback)
#endif
		CL_ParseClientdata ();

//
// parse the message
//
	while (1)
	{
		if (msg_badread)
		{
			Host_Error ("CL_ParseServerMessage: Bad server message");
			break;
		}

		old_readcount = msg_readcount;
		cls.demomessage_skipwrite = false;

		cmd = MSG_ReadByte ();

		if (cmd == -1)
		{
			msg_readcount++;	// so the EOM showner has the right value
			SHOWNET("END OF MESSAGE");
			break;
		}

		if (cmd == svc_qizmovoice)
			SHOWNET("svc_qizmovoice")
		else if (cmd < num_svc_strings)
			SHOWNET(svc_strings[cmd]);
	
	// other commands
		switch (cmd)
		{
		default:
#ifdef MVDPLAY
bad_message:
#endif
			Host_Error ("CL_ParseServerMessage: Illegible server message");
			break;
			
		case svc_nop:
			break;
			
		case svc_disconnect:
			if (cls.state == ca_connected)
				Host_Error ("Server disconnected\n"
					"Server version may not be compatible");
			else
			{
				Com_DPrintf ("Server disconnected\n");
				// the server will be killed if it tries to kick local player
				Host_EndGame ();
				Host_Abort ();
			}
			break;

		case nq_svc_time:
			MSG_ReadFloat ();
			break;

		case svc_print:
			CL_ParsePrint ();
			break;
			
		case svc_centerprint:
			{	char *s = MSG_ReadString();
				SCR_CenterPrint (s);
#ifdef AGRIP
				Sys_Printf ("%s\n", s);
#endif
			}
			break;
			
		case svc_stufftext:
			CL_ParseStufftext ();
			break;
			
		case svc_damage:
			V_ParseDamage ();
			break;
			
		case svc_serverdata:
			Cbuf_ExecuteEx (&cbuf_svc);		// make sure any stuffed commands are done
			CL_ParseServerData ();
			break;
			
		case svc_setangle:
#ifdef MVDPLAY
			if (cls.mvdplayback)
			{
				vec3_t ang;

				j = MSG_ReadByte();
				cl.mvd_fixangle |= 1 << j;
				for (i = 0; i < 3; i++)
					ang[i] = MSG_ReadAngle();
				if (j == cam_curtarget)
					VectorCopy (ang, cl.viewangles);
			}
			else
#endif
			{
				for (i = 0; i < 3 ; i++)
					cl.viewangles[i] = MSG_ReadAngle ();
			}
//			cl.viewangles[PITCH] = cl.viewangles[ROLL] = 0;
			// svc_finale and svc_cutscene don't send origin or angles;
			// we expect progs to move the player to the intermission spot
			// and set their angles correctly.  This is unlike qwcl, but
			// QW never used svc_finale so this should't break anything
			if (cl.intermission == 2 || cl.intermission == 3)
				VectorCopy (cl.viewangles, cl.simangles);
			break;
			
		case svc_lightstyle:
			i = MSG_ReadByte ();
			if (i >= MAX_LIGHTSTYLES)
				Host_Error ("svc_lightstyle > MAX_LIGHTSTYLES");
			strlcpy (cl_lightstyle[i].map,  MSG_ReadString(), sizeof(cl_lightstyle[i].map));
			cl_lightstyle[i].length = strlen(cl_lightstyle[i].map);
			break;
			
		case svc_sound:
			CL_ParseStartSoundPacket();
			break;
			
		case svc_stopsound:
			i = MSG_ReadShort();
			S_StopSound(i>>3, i&7);
			break;

		case nq_svc_particle:
			CL_ParseParticleEffect ();
			break;

		case svc_updatefrags:
			Sbar_Changed ();
			i = MSG_ReadByte ();
			if (i >= MAX_CLIENTS)
				Host_Error ("CL_ParseServerMessage: svc_updatefrags > MAX_CLIENTS");
			cl.players[i].frags = MSG_ReadShort ();
			break;			

		case svc_updateping:
			i = MSG_ReadByte ();
			if (i >= MAX_CLIENTS)
				Host_Error ("CL_ParseServerMessage: svc_updateping > MAX_CLIENTS");
			cl.players[i].ping = MSG_ReadShort ();
			break;
			
		case svc_updatepl:
			i = MSG_ReadByte ();
			if (i >= MAX_CLIENTS)
				Host_Error ("CL_ParseServerMessage: svc_updatepl > MAX_CLIENTS");
			cl.players[i].pl = MSG_ReadByte ();
			break;
			
		case svc_updateentertime:
		// time is sent over as seconds ago
			i = MSG_ReadByte ();
			if (i >= MAX_CLIENTS)
				Host_Error ("CL_ParseServerMessage: svc_updateentertime > MAX_CLIENTS");
			cl.players[i].entertime = cls.realtime - MSG_ReadFloat ();
			break;
			
		case svc_spawnbaseline:
			i = MSG_ReadShort ();
			if (i >= MAX_CL_EDICTS)
				Host_Error ("svc_spawnbaseline: ent > MAX_EDICTS");
			CL_ParseBaseline (&cl_entities[i].baseline);
			break;
		case svc_spawnstatic:
			CL_ParseStatic ();
			break;			
		case svc_temp_entity:
			CL_ParseTEnt ();
			break;

		case svc_killedmonster:
			cl.stats[STAT_MONSTERS]++;
			break;

		case svc_foundsecret:
			cl.stats[STAT_SECRETS]++;
			break;

		case svc_updatestat:
			i = MSG_ReadByte ();
			j = MSG_ReadByte ();
			CL_SetStat (i, j);
			break;
		case svc_updatestatlong:
			i = MSG_ReadByte ();
			j = MSG_ReadLong ();
			CL_SetStat (i, j);
			break;
			
		case svc_spawnstaticsound:
			CL_ParseStaticSound ();
			break;

		case svc_cdtrack:
			cl.cdtrack = MSG_ReadByte ();
			CDAudio_Play ((byte)cl.cdtrack, true);
			break;

		case svc_intermission:
			cl.intermission = 1;
			cl.completed_time = cls.realtime;
			cl.solo_completed_time = cl.servertime;
			for (i=0 ; i<3 ; i++)
				cl.simorg[i] = MSG_ReadCoord ();
			for (i=0 ; i<3 ; i++)
				cl.simangles[i] = MSG_ReadAngle ();
			VectorClear (cl.simvel);
			TP_ExecTrigger ("f_mapend");
			break;

		case svc_finale:
			cl.intermission = 2;
			cl.completed_time = cls.realtime;
			cl.solo_completed_time = cl.servertime;
			SCR_CenterPrint (MSG_ReadString ());			
			break;
			
		case svc_sellscreen:
			Cmd_ExecuteString ("help");
			break;

		case svc_smallkick:
			cl.ideal_punchangle = -2;
			break;
		case svc_bigkick:
			cl.ideal_punchangle = -4;
			break;

		case svc_muzzleflash:
			CL_MuzzleFlash ();
			break;

		case svc_updateuserinfo:
			CL_UpdateUserinfo ();
			break;

		case svc_setinfo:
			CL_SetInfo ();
			break;

		case svc_serverinfo:
			CL_ParseServerInfoChange ();
			break;

		case svc_download:
			CL_ParseDownload ();
			break;

		case svc_playerinfo:
			CL_ParsePlayerState ();
			break;

		case svc_nails:
#ifndef MVDPLAY
			CL_ParseNails ();
#else
            CL_ParseNails (false);
            break;
        case svc_nails2:
			if (!cls.mvdplayback)
				goto bad_message;
            CL_ParseNails (true);
#endif
			break;

		case svc_chokecount:		// some preceding packets were choked
			i = MSG_ReadByte ();
			for (j = cls.netchan.incoming_acknowledged - 1 ; i > 0
				&& j > cls.netchan.outgoing_sequence - UPDATE_BACKUP ; j--)
			{
				if (cl.frames[j & UPDATE_MASK].receivedtime != -3) {
					cl.frames[j & UPDATE_MASK].receivedtime = -2;
					i--;
				}
			}
			break;

		case svc_modellist:
			CL_ParseModellist ();
			break;

		case svc_soundlist:
			CL_ParseSoundlist ();
			break;

		case svc_packetentities:
			CL_ParsePacketEntities (false);
			break;

		case svc_deltapacketentities:
			CL_ParsePacketEntities (true);
			break;

		case svc_maxspeed :
			cl.movevars.maxspeed = MSG_ReadFloat();
			break;

		case svc_entgravity :
			cl.movevars.entgravity = MSG_ReadFloat();
			break;

		case svc_setpause:
			if (MSG_ReadByte() != 0)
				cl.paused |= PAUSED_SERVER;
			else
				cl.paused &= ~PAUSED_SERVER;

			if (cl.paused)
				CDAudio_Pause ();
			else
				CDAudio_Resume ();
			break;

		case svc_qizmovoice:
			CL_ParseQizmoVoice ();
			break;
		}

		if (!cls.demomessage_skipwrite) {
			SZ_Write (&cls.demomessage, &net_message.data[old_readcount],
				msg_readcount - old_readcount);
		}
	}

	CL_SetSolidEntities ();

	CL_WriteDemoMessage (&cls.demomessage);
}
