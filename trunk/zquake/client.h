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
// client.h


typedef struct
{
	char		name[16];
	qboolean	failedload;		// the name isn't a valid skin
	cache_user_t	cache;
} skin_t;

// player_state_t is the information needed by a player entity
// to do move prediction and to generate a drawable entity
typedef struct
{
	int			messagenum;		// all players won't be updated each frame

	double		state_time;		// not the same as the packet time,
								// because player commands come asyncronously
	usercmd_t	command;		// last command for prediction

	vec3_t		origin;
	vec3_t		viewangles;		// only for demos, not from server
	vec3_t		velocity;
	int			weaponframe;

	int			modelindex;
	int			frame;
	int			skinnum;
	int			effects;

	int			flags;			// dead, gib, etc

	int			pm_type;
	float		waterjumptime;
	qboolean	onground;
	qboolean	jump_held;
	int			jump_msec;		// hack for fixing bunny-hop flickering on non-ZQuake servers
} player_state_t;


#define	MAX_SCOREBOARDNAME	16
typedef struct player_info_s
{
	int		userid;
	char	userinfo[MAX_INFO_STRING];

	// scoreboard information
	char	name[MAX_SCOREBOARDNAME];
	char	team[MAX_INFO_STRING];
	float	entertime;
	int		frags;
	int		ping;
	byte	pl;
	qboolean	spectator;

	// skin information
	int		real_topcolor;			// what the server tells us
	int		real_bottomcolor;

	int		topcolor;				// real, or forced by enemycolor etc
	int		bottomcolor;

	// FIXME, get rid of these two
	int		_topcolor;
	int		_bottomcolor;

	byte	translations[VID_GRADES*256];
	skin_t	*skin;
} player_info_t;


typedef struct
{
	// generated on client side
	usercmd_t	cmd;		// cmd that generated the frame
	double		senttime;	// time cmd was sent off
	int			delta_sequence;		// sequence number to delta from, -1 = full update

	// received from server
	double		receivedtime;	// time message was received, or -1
	player_state_t	playerstate[MAX_CLIENTS];	// message received that reflects performing
							// the usercmd
	packet_entities_t	packet_entities;
	qboolean	invalid;		// true if the packet_entities delta was invalid
} frame_t;

typedef struct
{
	entity_state_t	baseline;
	entity_state_t	previous;
	entity_state_t	current;

	int				lastframe;
	vec3_t			lerp_origin;
} centity_t;

typedef struct
{
	int		destcolor[3];
	int		percent;		// 0-256
} cshift_t;

#define	CSHIFT_CONTENTS	0
#define	CSHIFT_DAMAGE	1
#define	CSHIFT_BONUS	2
#define	CSHIFT_POWERUP	3
#define	NUM_CSHIFTS		4


//
// clientState_t should hold all pieces of the client state
//

#define	MAX_DLIGHTS		64

typedef enum { lt_default, lt_blue, lt_red, lt_redblue, lt_muzzleflash,
lt_explosion, lt_rocket, NUM_DLIGHTTYPES } dlighttype_t;

typedef struct
{
	int		key;				// so entities can reuse same entry
	vec3_t	origin;
	float	radius;
	float	die;				// stop lighting after this time
	float	decay;				// drop this each second
	float	minlight;			// don't add when contributing less
	int		type;
} dlight_t;

typedef struct
{
	int		length;
	char	map[MAX_STYLESTRING];
} lightstyle_t;

typedef struct cparticle_s
{
	vec3_t		org;
	int			color;
	float		alpha;
	struct cparticle_s *next;
	vec3_t		vel;
	float		ramp;
	float		die;
	int			type;
} cparticle_t;

typedef enum {
	ca_disconnected, 	// full screen console with no connection
	ca_demostart,		// starting up a demo
	ca_connected,		// netchan_t established, waiting for svc_serverdata
	ca_onserver,		// processing data lists, donwloading, etc
	ca_active			// everything is in, so frames can be rendered
} cactive_t;

typedef enum {
	dl_none,
	dl_model,
	dl_sound,
	dl_skin,
	dl_single
} dltype_t;		// download type


#define	MAX_DEMOS	8

//
// the clientPersistent_t structure is persistent through an arbitrary number
// of server connections
//
typedef struct
{
// connection information
	cactive_t	state;

	int			framecount;		// incremented every frame, never reset
	double		realtime;		// scaled by cl_demospeed
	double		demotime;		// scaled by cl_demospeed, reset when starting a demo
	double		trueframetime;	// time since last frame
	double		frametime;		// time since last frame, scaled by cl_demospeed

// network stuff
	netchan_t	netchan;
	int			qport;
	char		servername[MAX_OSPATH];	// name of server from original connect

// private userinfo for sending to masterless servers
	char		userinfo[MAX_INFO_STRING];

// on a local server these may differ from com_gamedirfile and com_gamedir
	char		gamedirfile[MAX_QPATH];
	char		gamedir[MAX_OSPATH];

	FILE		*download;		// file transfer from server
	char		downloadtempname[MAX_OSPATH];
	char		downloadname[MAX_OSPATH];
	int			downloadnumber;
	dltype_t	downloadtype;
	int			downloadpercent;

// demo loop control
	int			playdemos;			// 1 = play all and stop, 2 = loop
	int			demonum;			// demo being played
	char		demos[MAX_DEMOS][MAX_QPATH];

// demo recording info must be here, because record is started before
// entering a map (and clearing clientState_t)
	qboolean	demorecording;
	qboolean	demoplayback;
	qboolean	nqdemoplayback;
	FILE		*demofile;
	byte		demomessage_data[MAX_MSGLEN * 2 /* FIXME */];
	sizebuf_t	demomessage;
	qboolean	demomessage_skipwrite;
	qboolean	timedemo;
	float		td_lastframe;		// to meter out one message a frame
	int			td_startframe;		// cls.framecount at start
	float		td_starttime;		// realtime at second frame of timedemo

	int			challenge;

	float		latency;		// rolling average
} clientPersistent_t;

extern clientPersistent_t	cls;


// cl.paused flags
#define PAUSED_SERVER	1
#define PAUSED_DEMO		2

//
// the clientState_t structure is wiped completely at every
// server signon
//
typedef struct
{
	int			servercount;	// server identification for prespawns
	char		serverinfo[MAX_SERVERINFO_STRING];
	qboolean	protocol_26;
// some important serverinfo keys are mirrored here:
	int			maxclients;
	int			deathmatch;
	int			teamplay;
	int			gametype;		// GAME_COOP or GAME_DEATHMATCH
	qboolean	teamfortress;	// true if gamedir is "fortress"
	int			fpd;			// FAQ proxy flags
	int			z_ext;			// ZQuake protocol extensions flags
	qboolean	servertime_works;	// Does the server actually send STAT_TIME/svc_time?
	float		maxfps;
	float		minpitch;
	float		maxpitch;
	qboolean	allow_fbskins;
	qboolean	allow_truelightning;

	int			parsecount;		// server message counter
	int			validsequence;	// this is the sequence number of the last good
								// packetentity_t we got.  If this is 0, we can't
								// render a frame yet
	int			oldvalidsequence;
	int			delta_sequence;	// sequence number of the packet we can request
								// delta from

	int			spectator;

	double		last_ping_request;	// while showing scoreboard
	double		last_servermessage;

// sentcmds[cl.netchan.outgoing_sequence & UPDATE_MASK] = cmd
	frame_t		frames[UPDATE_BACKUP];

// information for local display
	double		servertime;			// for display on solo status bar
	int			stats[MAX_CL_STATS];	// health, etc
	float		item_gettime[32];	// cl.time of acquiring item, for blinking
	float		faceanimtime;		// use anim frame if cl.time < this

	cshift_t	cshifts[NUM_CSHIFTS];	// color shifts for damage, powerups and content types

// the client maintains its own idea of view angles, which are
// sent to the server each frame.  And only reset at level change
// and teleport times
	vec3_t		viewangles;

// the client simulates or interpolates movement to get these values
	double		time;			// this is the time value that the client
								// is rendering at
	vec3_t		simorg;
	vec3_t		simvel;
	vec3_t		simangles;

// pitch drifting vars
	float		pitchvel;
	qboolean	nodrift;
	float		driftmove;
	double		laststop;

	qboolean	onground;
	float		crouch;			// local amount for smoothing stepups
	float		viewheight;

	int			paused;			// a combination of PAUSED_SERVER and PAUSED_DEMO flags

	float		ideal_punchangle;	// temporary view kick from weapon firing
	float		punchangle;		// drifts towards ideal_punchangle
	float		rollangle;		// smooth out rollangle changes when strafing
	
	int			intermission;	// don't change view angle, full screen, etc
	float		completed_time;	// latched from time at intermission start
	int			solo_completed_time;	// to draw on intermission screen
	
//
// information that is static for the entire time connected to a server
//
	char		model_name[MAX_MODELS][MAX_QPATH];
	char		sound_name[MAX_SOUNDS][MAX_QPATH];

	struct model_s		*model_precache[MAX_MODELS];
	struct sfx_s		*sound_precache[MAX_SOUNDS];

	char		levelname[40];	// for display on solo scoreboard
	int			playernum;
	int			viewplayernum;	// either playernum or spec_track (in chase camera mode)

// refresh related state
	struct model_s	*worldmodel;	// cl_entitites[0].model
	struct efrag_s	*free_efrags;
	int			num_entities;	// stored bottom up in cl_entities array
	int			num_statics;	// stored top down in cl_entities

	int			cdtrack;		// cd audio

	entity_t	viewent;		// weapon model

// all player information
	player_info_t	players[MAX_CLIENTS];

// sprint buffer
	int			sprint_level;
	char		sprint_buf[1024];

// localized movement vars
	float		entgravity;
	float		maxspeed;
	float		bunnyspeedcap;

	char		sky[32];
} clientState_t;

extern	clientState_t	cl;


//
// cvars
//
extern  cvar_t	cl_warncmd;
extern	cvar_t	cl_shownet;
extern	cvar_t	cl_sbar;
extern	cvar_t	cl_hudswap;


// ZQuake cvars
extern	cvar_t	cl_deadbodyfilter;
extern	cvar_t	cl_explosion;
extern	cvar_t	cl_gibfilter;
extern	cvar_t	cl_muzzleflash;
extern	cvar_t	cl_trueLightning;
extern	cvar_t	r_rocketlight;
extern	cvar_t	r_rockettrail;
extern	cvar_t	r_grenadetrail;
extern	cvar_t	r_powerupglow;

#define	MAX_EFRAGS		512
#define	MAX_STATIC_ENTITIES	128			// torches, etc

// FIXME, allocate dynamically
extern	centity_t		cl_entities[MAX_EDICTS];
extern	efrag_t			cl_efrags[MAX_EFRAGS];
extern	entity_t		cl_static_entities[MAX_STATIC_ENTITIES];
extern	lightstyle_t	cl_lightstyle[MAX_LIGHTSTYLES];
extern	dlight_t		cl_dlights[MAX_DLIGHTS];

extern float	server_version;	// version of server we connected to

extern byte		*host_basepal;
extern byte		*host_colormap;

//=============================================================================


//
// cl_main
//
void CL_Init (void);
void CL_WriteConfiguration (void);
void CL_ClearState (void);
void CL_ReadPackets (void);
void CL_BeginServerConnect(void);
void CL_Disconnect (void);
void CL_Disconnect_f (void);
void CL_NextDemo (void);

extern	int				cl_entframecount;

extern	int				cl_numvisedicts;
extern	entity_t		cl_visedicts[MAX_VISEDICTS];

extern	int				cl_numvisparticles;
extern	particle_t		cl_visparticles[MAX_PARTICLES];

extern char emodel_name[], pmodel_name[];


//
// cl_demo.c
//
qboolean CL_GetDemoMessage (void);
void CL_WriteDemoCmd (usercmd_t *pcmd);
void CL_WriteDemoMessage (sizebuf_t *msg);
void CL_StopPlayback (void);
void CL_Record_f (void);
void CL_EasyRecord_f (void);
void CL_Stop_f (void);
void CL_PlayDemo_f (void);
void CL_TimeDemo_f (void);
void CL_NextDemo (void);
void CL_StartDemos_f (void);

//
// cl_nqdemo.c
//
void NQD_ReadPackets (void);
void NQD_StartPlayback (void);
void NQD_LinkEntities (void);

//
// cl_parse.c
//
#define NET_TIMINGS 256
#define NET_TIMINGSMASK 255
extern int	packet_latency[NET_TIMINGS];
int CL_CalcNet (void);
void CL_ParseServerMessage (void);
void CL_NewTranslation (int slot);
qboolean CL_CheckOrDownloadFile (char *filename);
qboolean CL_IsUploading(void);
void CL_NextUpload(void);
void CL_StartUpload (byte *data, int size);
void CL_StopUpload(void);


//
// cl_tent.c
//
void CL_InitTEnts (void);
void CL_ClearTEnts (void);
void CL_ParseTEnt (void);
void CL_UpdateTEnts (void);

//
// cl_effects.c
//
dlight_t *CL_AllocDlight (int key);
void CL_NewDlight (int key, vec3_t origin, float radius, float time, int type);
void CL_DecayLights (void);

void CL_InitParticles (void);
void CL_ClearParticles (void);
void CL_LinkParticles (void);
void CL_ReadPointFile_f (void);

void CL_BlobExplosion (vec3_t org);
void CL_ParticleExplosion (vec3_t org);
void CL_LavaSplash (vec3_t org);
void CL_TeleportSplash (vec3_t org);
void CL_SlightBloodTrail (vec3_t start, vec3_t end);
void CL_BloodTrail (vec3_t start, vec3_t end);
void CL_VoorTrail (vec3_t start, vec3_t end);
void CL_GrenadeTrail (vec3_t start, vec3_t end);
void CL_RocketTrail (vec3_t start, vec3_t end);
void CL_TracerTrail (vec3_t start, vec3_t end, int color);
void CL_RunParticleEffect (vec3_t org, vec3_t dir, int color, int count);

//
// cl_ents.c
//
void CL_SetSolidPlayers (int playernum);
void CL_SetUpPlayerPrediction(qboolean dopred);
void CL_EmitEntities (void);
void CL_ClearProjectiles (void);
void CL_ParseProjectiles (void);
void CL_ParsePacketEntities (qboolean delta);
void CL_SetSolidEntities (void);
void CL_ParsePlayerinfo (void);

//
// cl_pred.c
//
void CL_InitPrediction (void);
void CL_PredictMove (void);
void CL_PredictUsercmd (player_state_t *from, player_state_t *to, usercmd_t *u);

//
// cl_cam.c
//
#define CAM_NONE	0
#define CAM_TRACK	1

extern int	autocam;
extern int	spec_track; // player# of who we are tracking

qboolean Cam_DrawViewModel (void);
qboolean Cam_DrawPlayer (int playernum);
void Cam_Track (usercmd_t *cmd);
void Cam_FinishMove (usercmd_t *cmd);
void Cam_Reset (void);
void Cam_SetViewPlayer (void);
void CL_InitCam (void);

//
// skin.c
//

void	Skin_Find (player_info_t *sc);
byte	*Skin_Cache (skin_t *skin);
void	Skin_Skins_f (void);
void	Skin_AllSkins_f (void);
void	Skin_NextDownload (void);

#define RSSHOT_WIDTH 320
#define RSSHOT_HEIGHT 200
