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
// server.h - primary header for server
#ifndef _SERVER_H_
#define _SERVER_H_

//define	PARANOID			// speed sapping error checking

#include "common.h"
#include "progs.h"
#include "pmove.h"


#define	MAX_MASTERS	8				// max recipients for heartbeat packets

#define	MAX_SIGNON_BUFFERS	10

typedef struct
{
	int		original;	// what entity is currently using this translation slot
	double	lastused;	// last time this slot was used
} entity_translation_t;

typedef enum {
	ss_dead,			// no map loaded
	ss_loading,			// spawning level edicts
	ss_active			// actively running
} server_state_t;
// some qc commands are only valid before the server has finished
// initializing (precache commands, static sounds / objects, etc)

typedef struct packet_s
{
	double		time;
	sizebuf_t	msg;
	byte		buf[MAX_MSGLEN];
	struct packet_s *next;
} packet_t;

#define MAX_DELAYED_PACKETS 128

typedef struct
{
	server_state_t	state;			// precache commands are only valid during load

	double		time;
	double		old_time;			// bumped by SV_Physics

	int			lastcheck;			// used by PF_checkclient
	double		lastchecktime;		// for monster ai

	double		pausedstart;		// curtime when pause started

	qbool		loadgame;			// handle connections specially

	//check player/eyes models for hacks
	unsigned	model_player_checksum;
	unsigned	eyes_player_checksum;

	string		sky;				// skybox file name ("unit1_", etc)

	string		mapname;			// "e1m1", "dm6", etc
	string		modelname;			// maps/<name>.bsp, for model_precache[0]
	unsigned	map_checksum;
	unsigned	map_checksum2;
	cmodel_t 	*worldmodel;
	string		model_name[MAX_MODELS];	// NULL terminated
	string		vw_model_name[MAX_VWEP_MODELS];	// NULL terminated
	string		sound_name[MAX_SOUNDS];	// NULL terminated
	char		*lightstyles[MAX_LIGHTSTYLES];
	cmodel_t	*models[MAX_MODELS];
	movevars_t	movevars;

	int			num_edicts;			// increases towards MAX_EDICTS
	edict_t		*edicts;			// can NOT be array indexed, because
									// edict_t is variable sized, but can
									// be used to reference the world ent

	int			entmap[MAX_EDICTS];		// because QW protocol only handles 512 entities,
										// translate entnums dynamically before sending
	entity_translation_t	translations[512];	// translated numbers are tracked here

	// added to every client's unreliable buffer each frame, then cleared
	sizebuf_t	datagram;
	byte		datagram_buf[MAX_DATAGRAM];

	// added to every client's reliable buffer each frame, then cleared
	sizebuf_t	reliable_datagram;
	byte		reliable_datagram_buf[MAX_MSGLEN];

	// the multicast buffer is used to send a message to a set of clients
	sizebuf_t	multicast;
	byte		multicast_buf[MAX_MSGLEN];

	// the signon buffer will be sent to each client as they connect
	// includes the entity baselines, the static entities, etc
	// large levels will have >MAX_DATAGRAM sized signons, so
	// multiple signon messages are kept
	sizebuf_t	signon;
	int			num_signon_buffers;
	int			signon_buffer_size[MAX_SIGNON_BUFFERS];
	byte		signon_buffers[MAX_SIGNON_BUFFERS][MAX_DATAGRAM];

	qbool		intermission_running;	// when true, use intermission PVS
	int			intermission_hunt;		// looking for WriteCoords to fill in intermission_origin
	qbool		intermission_origin_valid;
	vec3_t		intermission_origin;

	void clear () {
		state = ss_dead;
		time = old_time = 0;
		lastcheck = 0;
		lastchecktime = 0;
		pausedstart = 0;
		loadgame = false;
		model_player_checksum = eyes_player_checksum = 0;
		sky = "";
		mapname[0] = 0;
		modelname[0] = 0;
		map_checksum = map_checksum2 = 0;
		worldmodel = 0;
		for (int i = 0; i < MAX_MODELS; i++)
			model_name[i] = "";
		for (int i = 0; i < MAX_VWEP_MODELS; i++)
			vw_model_name[i] = "";
		for (int i = 0; i < MAX_SOUNDS; i++)
			sound_name[i] = "";
		memset (lightstyles, 0, sizeof(lightstyles));
		memset (models, 0, sizeof(models));
		memset (&movevars, 0, sizeof(movevars));
		num_edicts = 0;
		edicts = NULL;
		memset (entmap, 0, sizeof(entmap));
		memset (translations, 0, sizeof(translations));
		memset (&datagram, 0, sizeof(datagram));
		memset (datagram_buf, 0, sizeof(datagram_buf));
		memset (&reliable_datagram, 0, sizeof(reliable_datagram));
		memset (reliable_datagram_buf, 0, sizeof(reliable_datagram_buf));
		memset (&multicast, 0, sizeof(multicast));
		memset (multicast_buf, 0, sizeof(multicast_buf));
		memset (&signon, 0, sizeof(signon));
		num_signon_buffers = 0;
		memset (signon_buffer_size, 0, sizeof(signon_buffer_size));
		memset (signon_buffers, 0, sizeof(signon_buffers));
		intermission_running = false;
		intermission_hunt = 0;
		intermission_origin_valid = false;
		VectorClear (intermission_origin);
	}
} server_t;


#define	NUM_SPAWN_PARMS			16

typedef enum
{
	cs_free,		// can be reused for a new connection
	cs_zombie,		// client has been disconnected, but don't reuse
					// connection for a couple seconds
	cs_connected,	// has been assigned to a client_t, but not in game yet
	cs_spawned		// client is fully in game
} client_state_e;

typedef struct
{
	// received from client

	// reply
	double				senttime;
	float				ping_time;
	packet_entities_t	entities;
} client_frame_t;

#ifndef AGRIP
#define MAX_BACK_BUFFERS	4
#else
#define MAX_BACK_BUFFERS    8   // AGRIP needs bigger backbufs
#endif
#define MAX_STUFFTEXT		256

struct client_t
{
	client_state_e	state;
	qbool			bot;

	int				userid;							// identifying number
	Info			userinfo;			// infostring
	string			name;				// for printing to other people
										// extracted from userinfo
	int				messagelevel;		// for filtering printed messages
	qbool			spectator;			// non-interactive
	int				extensions;			// what ZQuake extensions the client supports
	qbool			uses_proxy;			// if true, disable any non-standard protocols

	qbool			sendinfo;			// at end of frame, send info to all
										// this prevents malicious multiple broadcasts
	float			lastnametime;		// time of last name change
	int				lastnamecount;		// time of last name change
	qbool			drop;				// lose this guy next opportunity
	int				lossage;			// loss percentage

	usercmd_t		lastcmd;			// for filling in big drops and partial predictions
	double			cmdtime;			// realtime of last message

	qbool			jump_held;
	float			maxspeed;			// localized maxspeed
	float			entgravity;			// localized ent gravity

	edict_t			*edict;				// EDICT_NUM(clientnum+1)

	// the datagram is written to after every frame, but only cleared
	// when it is sent out to the client.  overflow is tolerated.
	sizebuf_t		datagram;
	byte			datagram_buf[MAX_DATAGRAM];

	// back buffers for client reliable data
	sizebuf_t		backbuf;
	int				num_backbuf;
	int				backbuf_size[MAX_BACK_BUFFERS];
	byte			backbuf_data[MAX_BACK_BUFFERS][MAX_MSGLEN];

	// stufftext and sprint messages are buffered to reduce traffic
	char			stufftext_buf[MAX_STUFFTEXT];
	char			sprint_buf[256];
	int				sprint_level;
	qbool			sprint_nq_low_level;

	double			connection_started;	// or time of disconnect for zombies
	qbool			send_message;		// set on frames a datagram arived on

// spawn parms are carried from level to level
	float			spawn_parms[NUM_SPAWN_PARMS];

// client known data for deltas
	int				stats[MAX_CL_STATS];
	int				old_frags;

	double			lastservertimeupdate;	// last svs.realtime we sent STAT_TIME to the client

	client_frame_t	frames[UPDATE_BACKUP];	// updates can be deltad from here

	FILE			*download;			// file being downloaded
	int				downloadsize;		// total bytes
	int				downloadcount;		// bytes sent

	int				spec_track;			// entnum of player tracking

	double			whensaid[10];		// For floodprots
 	int				whensaidhead;		// Head value for floodprots
 	double			lockedtill;

	FILE			*upload;
	char			uploadfn[MAX_QPATH];
	netadr_t		snap_from;
	qbool			remote_snap;

	double			delay;
	packet_t		*packets, *last_packet;

//===== NETWORK ============
	int				chokecount;
	int				delta_sequence;		// -1 = no compression
	netchan_t		netchan;

	client_t() : userinfo(MAX_INFO_STRING-1) {};
	void clear() {
		state = cs_free;
		bot = false;
		userid = 0;
		userinfo.clear();
		name = "";
		messagelevel = 0;
		spectator = false;
		extensions = 0;
		uses_proxy = false;
		sendinfo = false;
		lastnametime = 0;
		lastnamecount = 0;
		drop = false;
		lossage = 0;
		memset (&lastcmd, 0, sizeof(lastcmd));
		cmdtime = 0;
		jump_held = false;
		maxspeed = 0;
		entgravity = 0;
		edict = NULL;
		memset (&datagram, 0, sizeof(datagram));
		memset (&backbuf, 0, sizeof(backbuf));
		num_backbuf = 0;
		memset (backbuf_size, 0, sizeof(backbuf_size));
		stufftext_buf[0] = 0;
		sprint_buf[0] = 0;
		sprint_level = 0;
		sprint_nq_low_level = false;
		connection_started = 0;
		send_message = false;
		memset (spawn_parms, 0, sizeof(spawn_parms));
		memset (stats, 0, sizeof(stats));
		old_frags = 0;
		lastservertimeupdate = 0;
		memset (frames, 0, sizeof(frames));
		download = NULL;
		downloadsize = 0;
		downloadcount = 0;
		spec_track = 0;
		memset (whensaid, 0, sizeof(whensaid));
		whensaidhead = 0;
		lockedtill = 0;
		upload = NULL;
		uploadfn[0] = 0;
		memset (&snap_from, 0, sizeof(snap_from));
		remote_snap = false;
		delay = 0;
		packets = NULL;
		last_packet = NULL;
		chokecount = 0;
		delta_sequence = 0;
		memset (&netchan, 0, sizeof(netchan));
	};
};

// a client can leave the server in one of four ways:
// dropping properly by quiting or disconnecting
// timing out if no valid messages are received for timeout.value seconds
// getting kicked off by the server operator
// a program error, like an overflowed reliable buffer

//=============================================================================


#define	STATFRAMES	100
typedef struct
{
	double	active;
	double	idle;
	int		count;
	int		packets;

	double	latched_active;
	double	latched_idle;
	int		latched_packets;
} svstats_t;

// MAX_CHALLENGES is made large to prevent a denial
// of service attack that could cycle all of them
// out before legitimate users connected
#define	MAX_CHALLENGES	1024

typedef struct
{
	netadr_t	adr;
	int			challenge;
	int			time;
} challenge_t;

struct serverPersistent_t
{
	double		realtime;			// increased by SV_Frame, never reset

	int			spawncount;			// number of servers spawned since start,
									// used to check late spawns
	int			lastuserid;			// userid of last spawned client
	client_t	clients[MAX_CLIENTS];
	int			serverflags;		// episode completion information

	double		last_heartbeat;
	int			heartbeat_sequence;
	svstats_t	stats;

	Info		info;
	Info		localinfo;			// local game info
	qbool		hipnotic;

	// log messages are used so that fraglog processes can get stats
	int			logsequence;	// the message currently being filled
	double		logtime;		// time of last swap
	sizebuf_t	log[2];
	byte		log_buf[2][MAX_DATAGRAM];

	challenge_t	challenges[MAX_CHALLENGES];	// to prevent invalid IPs from connecting

	packet_t	*free_packets;

	serverPersistent_t() : info(MAX_SERVERINFO_STRING-1),
		localinfo(MAX_LOCALINFO_STRING-1) {};
};

//=============================================================================

// edict->movetype values
#define	MOVETYPE_NONE			0		// never moves
#define	MOVETYPE_ANGLENOCLIP	1
#define	MOVETYPE_ANGLECLIP		2
#define	MOVETYPE_WALK			3		// gravity
#define	MOVETYPE_STEP			4		// gravity, special edge handling
#define	MOVETYPE_FLY			5
#define	MOVETYPE_TOSS			6		// gravity
#define	MOVETYPE_PUSH			7		// no clip to world, push and crush
#define	MOVETYPE_NOCLIP			8
#define	MOVETYPE_FLYMISSILE		9		// extra size to monsters
#define	MOVETYPE_BOUNCE			10

// edict->solid values
#define	SOLID_NOT				0		// no interaction with other objects
#define	SOLID_TRIGGER			1		// touch on edge, but not blocking
#define	SOLID_BBOX				2		// touch on edge, block
#define	SOLID_SLIDEBOX			3		// touch on edge, but not an onground
#define	SOLID_BSP				4		// bsp clip, touch on edge, block

// edict->takedamage
#define	DAMAGE_NO				0
#define	DAMAGE_YES				1
#define	DAMAGE_AIM				2

// edict->flags
#define	FL_FLY					1
#define	FL_SWIM					2
#define	FL_GLIMPSE				4
#define	FL_CLIENT				8
#define	FL_INWATER				16
#define	FL_MONSTER				32
#define	FL_GODMODE				64
#define	FL_NOTARGET				128
#define	FL_ITEM					256
#define	FL_ONGROUND				512
#define	FL_PARTIALGROUND		1024	// not all corners are valid
#define	FL_WATERJUMP			2048	// player jumping out of water

#define	SPAWNFLAG_NOT_EASY			256
#define	SPAWNFLAG_NOT_MEDIUM		512
#define	SPAWNFLAG_NOT_HARD			1024
#define	SPAWNFLAG_NOT_DEATHMATCH	2048

#define	MULTICAST_ALL			0
#define	MULTICAST_PHS			1
#define	MULTICAST_PVS			2

#define	MULTICAST_ALL_R			3
#define	MULTICAST_PHS_R			4
#define	MULTICAST_PVS_R			5

//============================================================================

extern	cvar_t	sv_paused;		// 1 - normal, 2 - auto (single player), 3 - both
extern	cvar_t	sv_mintic, sv_maxtic;
extern	cvar_t	maxclients;
extern	cvar_t	sv_fastconnect;
extern	cvar_t	pm_maxspeed;

extern	cvar_t	teamplay;
extern	cvar_t	deathmatch;
extern	cvar_t	fraglimit;
extern	cvar_t	timelimit;
extern	cvar_t	skill;
extern	cvar_t	coop;

extern	int		current_skill;

extern	serverPersistent_t	svs;			// persistent server info
extern	server_t		sv;					// local server

extern	client_t	*sv_client;
extern	edict_t		*sv_player;

extern	char		localmodels[MAX_MODELS][5];	// inline model names for precache

extern	FILE		*sv_fraglogfile;

//===========================================================

//
// sv_main.c
//
void SV_Shutdown (const string finalmsg);
void SV_Frame (double time);
void SV_FinalMessage (char *message);
void SV_FreeDelayedPackets (client_t *cl);
void SV_DropClient (client_t *drop);
void SV_InitLocal (void);

int SV_GenerateUserID (void);
int SV_CalcPing (client_t *cl);
void SV_FullClientUpdate (client_t *client, sizebuf_t *buf);
void SV_FullClientUpdateToClient (client_t *client, client_t *cl);

void SV_InitOperatorCommands (void);

void SV_ExtractFromUserinfo (client_t *cl);
int SV_BoundRate (int rate);

//
// sv_move.c
//
qbool SV_CheckBottom (edict_t *ent);
qbool SV_movestep (edict_t *ent, vec3_t move, qbool relink);
void SV_MoveToGoal (void);

//
// sv_init.c
//
int SV_ModelIndex (char *name);
void SV_FlushSignon (void);
void SV_SaveSpawnparms (void);
void SV_SpawnServer (char *mapname, qbool devmap);


//
// sv_phys.c
//
void SV_ProgStartFrame (void);
void SV_Physics (void);
void SV_CheckVelocity (edict_t *ent);
qbool SV_RunThink (edict_t *ent);
void SV_RunNewmis (void);
void SV_RunNQNewmis (void);
void SV_SetMoveVars(void);

//
// sv_send.c
//
typedef enum {RD_NONE, RD_CLIENT, RD_PACKET} redirect_t;
void SV_BeginRedirect (redirect_t rd);
void SV_EndRedirect (void);

void SV_Multicast (vec3_t origin, int to);
void SV_StartParticle (vec3_t org, vec3_t dir, int color, int count,
						int replacement_te, int replacement_count);
void SV_StartSound (edict_t *entity, int channel, char *sample, int volume,
					float attenuation, /* optional */ client_t *to_client);
void SV_ClientPrintf (client_t *cl, int level, char *fmt, ...);
void SV_BroadcastPrintf (int level, char *fmt, ...);
void SV_BroadcastCommand (char *fmt, ...);
void SV_SendClientMessages (void);
void SV_SendMessagesToAll (void);
void SV_FindModelNumbers (void);


//
// sv_user.c
//
void SV_ExecuteClientMessage (client_t *cl);
void SV_TogglePause (qbool menu, const string msg);


//
// sv_ccmds.c
//
void SV_Status_f (void);
void SV_SendServerInfoChange (char *key, char *value);

//
// sv_ents.c
//
int SV_TranslateEntnum (int num);
void SV_WriteEntitiesToClient (client_t *client, sizebuf_t *msg);
void SV_WriteClientdataToMessage (client_t *client, sizebuf_t *msg);

//
// sv_nchan.c
//
void ClientReliableWrite_Begin0 (client_t *cl);
void ClientReliableWrite_Begin (client_t *cl, int c);
void ClientReliableWrite_End (void);
void ClientReliableWrite_Angle (float f);
void ClientReliableWrite_Angle16 (float f);
void ClientReliableWrite_Byte (int c);
void ClientReliableWrite_Char (int c);
void ClientReliableWrite_Float (float f);
void ClientReliableWrite_Coord (float f);
void ClientReliableWrite_Long (int c);
void ClientReliableWrite_Short (int c);
void ClientReliableWrite_String (const char *s);
inline void ClientReliableWrite_String (const string s) { ClientReliableWrite_String(s.c_str()); };
void ClientReliableWrite_SZ (void *data, int len);
void SV_AddToReliable (client_t *cl, const byte *data, int size);
void SV_FlushBackbuf (client_t *cl);
void SV_ClearBackbuf (client_t *cl);
void SV_ClearReliable (client_t *cl);	// clear cl->netchan.message and backbuf

//
// sv_save.c
//
void SV_SaveGame_f (void);
void SV_LoadGame_f (void);

//
// sv_bot.c
//
edict_t *SV_CreateBot (char *name);
void SV_RemoveBot (client_t *cl);
void SV_RunBots (void);

//
// sv_master.c
//
void SV_SetMaster_f (void);
void SV_Heartbeat_f (void);
void Master_Shutdown (void);
void Master_Heartbeat (void);

#endif /* _SERVER_H_ */

