// cl_nqdemo.c

#include "quakedef.h"
#include "sound.h"
#include "cdaudio.h"

void CL_FindModelNumbers (void);
void TP_NewMap (void);
void CL_ParseBaseline (entity_state_t *es);
void CL_ParseStatic (void);
void CL_ParseStaticSound (void);
void R_TranslatePlayerSkin (int playernum);

#define	NQ_PROTOCOL_VERSION	15

#define	NQ_MAX_CLIENTS	16
#define NQ_SIGNONS		4

#define	NQ_MAX_EDICTS	600			// Must be <= MAX_EDICTS!

// if the high bit of the servercmd is set, the low bits are fast update flags:
#define	NQ_U_MOREBITS	(1<<0)
#define	NQ_U_ORIGIN1	(1<<1)
#define	NQ_U_ORIGIN2	(1<<2)
#define	NQ_U_ORIGIN3	(1<<3)
#define	NQ_U_ANGLE2	(1<<4)
#define	NQ_U_NOLERP	(1<<5)		// don't interpolate movement
#define	NQ_U_FRAME		(1<<6)
#define NQ_U_SIGNAL	(1<<7)		// just differentiates from other updates
#define	NQ_U_ANGLE1	(1<<8)
#define	NQ_U_ANGLE3	(1<<9)
#define	NQ_U_MODEL		(1<<10)
#define	NQ_U_COLORMAP	(1<<11)
#define	NQ_U_SKIN		(1<<12)
#define	NQ_U_EFFECTS	(1<<13)
#define	NQ_U_LONGENTITY	(1<<14)

#define	SU_VIEWHEIGHT	(1<<0)
#define	SU_IDEALPITCH	(1<<1)
#define	SU_PUNCH1		(1<<2)
#define	SU_PUNCH2		(1<<3)
#define	SU_PUNCH3		(1<<4)
#define	SU_VELOCITY1	(1<<5)
#define	SU_VELOCITY2	(1<<6)
#define	SU_VELOCITY3	(1<<7)
//define	SU_AIMENT		(1<<8)  AVAILABLE BIT
#define	SU_ITEMS		(1<<9)
#define	SU_ONGROUND		(1<<10)		// no data follows, the bit is it
#define	SU_INWATER		(1<<11)		// no data follows, the bit is it
#define	SU_WEAPONFRAME	(1<<12)
#define	SU_ARMOR		(1<<13)
#define	SU_WEAPON		(1<<14)

// a sound with no channel is a local only sound
#define	NQ_SND_VOLUME		(1<<0)		// a byte
#define	NQ_SND_ATTENUATION	(1<<1)		// a byte
#define	NQ_SND_LOOPING		(1<<2)		// a long


#define	svc_time			7	// [float] server time
#define	svc_version			4	// [long] server version
#define	svc_setview			5	// [short] entity number
#define	svc_updatename		13	// [byte] [string]
#define	svc_updatefrags		14	// [byte] [short]
#define	svc_clientdata		15	// <shortbits + data>
#define	svc_updatecolors	17	// [byte] [byte]
#define	svc_particle		18	// [vec3] <variable>
#define	svc_signonnum		25	// [byte]  used for the signon sequence
#define svc_cutscene		34


//=========================================================================================

qboolean	nq_drawpings;	// for sbar code

qboolean	nq_player_teleported;	// hacky

vec3_t	nq_last_fixangle;

int		nq_num_entities;
int		nq_viewentity;
int		nq_forcecdtrack;
int		nq_signon;
int		nq_maxclients;
float	nq_mtime[2];
vec3_t	nq_mvelocity[2];
vec3_t	nq_mviewangles[2];
vec3_t	nq_mviewangles_temp;
qboolean	standard_quake = true;


qboolean CL_GetNQDemoMessage (void)
{
	int r, i;
	float f;

	// decide if it is time to grab the next message		
	if (cls.state == ca_active				// always grab until fully connected
		&& !(cl.paused & PAUSED_SERVER))	// or if the game was paused by server
	{
		if (cls.timedemo)
		{
			if (cls.framecount == cls.td_lastframe)
				return false;		// already read this frame's message
			cls.td_lastframe = cls.framecount;
			// if this is the second frame, grab the real td_starttime
			// so the bogus time on the first frame doesn't count
			if (cls.framecount == cls.td_startframe + 1)
				cls.td_starttime = cls.realtime;
		}
		else if (cl.time <= nq_mtime[0])
		{
			return false;		// don't need another message yet
		}
	}


	// get the next message
	fread (&net_message.cursize, 4, 1, cls.demofile);
	for (i=0 ; i<3 ; i++) {
		r = fread (&f, 4, 1, cls.demofile);
		nq_mviewangles_temp[i] = LittleFloat (f);
	}

	net_message.cursize = LittleLong (net_message.cursize);
	if (net_message.cursize > MAX_BIG_MSGLEN)
		Host_Error ("Demo message > MAX_BIG_MSGLEN");

	r = fread (net_message.data, net_message.cursize, 1, cls.demofile);
	if (r != 1) {
		Host_Error ("Unexpected end of demo");
	}

	return true;
}


void NQD_BumpEntityCount (int num)
{
	if (num >= nq_num_entities)
		nq_num_entities = num + 1;
}


void NQD_ParseClientdata (int bits)
{
	extern void Sbar_Changed (void);
	int		i, j;

	if (bits & SU_VIEWHEIGHT)
		cl.viewheight = MSG_ReadChar ();
	else
		cl.viewheight = DEFAULT_VIEWHEIGHT;

	if (bits & SU_IDEALPITCH)
		MSG_ReadChar ();		// ignore
	
	VectorCopy (nq_mvelocity[0], nq_mvelocity[1]);
	for (i=0 ; i<3 ; i++)
	{
		if (bits & (SU_PUNCH1<<i) ) {
			if (i == 0)
				cl.punchangle = MSG_ReadChar ();
			else
				MSG_ReadChar();			// ignore
		}
		if (bits & (SU_VELOCITY1<<i) )
			nq_mvelocity[0][i] = MSG_ReadChar()*16;
		else
			nq_mvelocity[0][i] = 0;
	}

// [always sent]	if (bits & SU_ITEMS)
	i = MSG_ReadLong ();			// FIXME, check SU_ITEMS anyway? -- Tonik

	if (cl.stats[STAT_ITEMS] != i)
	{	// set flash times
		Sbar_Changed ();
		for (j=0 ; j<32 ; j++)
			if ( (i & (1<<j)) && !(cl.stats[STAT_ITEMS] & (1<<j)))
				cl.item_gettime[j] = cl.time;
		cl.stats[STAT_ITEMS] = i;
	}
		
	cl.onground = (bits & SU_ONGROUND) != 0;
//	cl.inwater = (bits & SU_INWATER) != 0;

	if (bits & SU_WEAPONFRAME)
/*@@@	cl.stats[STAT_WEAPONFRAME] =*/ MSG_ReadByte ();
/*	else
		cl.stats[STAT_WEAPONFRAME] = 0;*/

	if (bits & SU_ARMOR)
		i = MSG_ReadByte ();
	else
		i = 0;
	if (cl.stats[STAT_ARMOR] != i)
	{
		cl.stats[STAT_ARMOR] = i;
		Sbar_Changed ();
	}

	if (bits & SU_WEAPON)
		i = MSG_ReadByte ();
	else
		i = 0;
	if (cl.stats[STAT_WEAPON] != i)
	{
		cl.stats[STAT_WEAPON] = i;
		Sbar_Changed ();
	}
	
	i = MSG_ReadShort ();
	if (cl.stats[STAT_HEALTH] != i)
	{
		cl.stats[STAT_HEALTH] = i;
		Sbar_Changed ();
	}

	i = MSG_ReadByte ();
	if (cl.stats[STAT_AMMO] != i)
	{
		cl.stats[STAT_AMMO] = i;
		Sbar_Changed ();
	}

	for (i=0 ; i<4 ; i++)
	{
		j = MSG_ReadByte ();
		if (cl.stats[STAT_SHELLS+i] != j)
		{
			cl.stats[STAT_SHELLS+i] = j;
			Sbar_Changed ();
		}
	}

	i = MSG_ReadByte ();

	if (standard_quake)
	{
		if (cl.stats[STAT_ACTIVEWEAPON] != i)
		{
			cl.stats[STAT_ACTIVEWEAPON] = i;
			Sbar_Changed ();
		}
	}
	else
	{
		if (cl.stats[STAT_ACTIVEWEAPON] != (1<<i))
		{
			cl.stats[STAT_ACTIVEWEAPON] = (1<<i);
			Sbar_Changed ();
		}
	}
}

/*
==================
NQD_ParseUpdatecolors
==================
*/
void NQD_ParseUpdatecolors (void)
{
	int	i, colors;

	i = MSG_ReadByte ();
	if (i >= nq_maxclients)
		Host_Error ("CL_ParseServerMessage: svc_updatecolors > NQ_MAX_CLIENTS");
	colors = MSG_ReadByte ();
	cl.players[i].bottomcolor = cl.players[i].real_bottomcolor = min(colors & 15, 13);
	cl.players[i].topcolor = cl.players[i].real_topcolor = min((colors >> 4) & 15, 13);
	CL_NewTranslation (i);
	Sbar_Changed ();
}

			
/*
==================
NQD_ParsePrint
==================
*/
void NQD_ParsePrint (void)
{
	extern cvar_t	cl_chatsound;

	char *s = MSG_ReadString();
	if (s[0] == 1) {	// chat
		if (cl_chatsound.value)
			S_LocalSound ("misc/talk.wav");
	}
	Com_Printf ("%s", s);
}


// JPG's ProQuake hacks
int ReadPQByte (void) {
	int msvc_optimizations_are_buggy = MSG_ReadByte() * 16 + MSG_ReadByte() - 272;
	return msvc_optimizations_are_buggy;
}
int ReadPQShort (void) {
	return ReadPQByte() * 256 + ReadPQByte();
}

/*
==================
NQD_ParseStufftext
==================
*/
void NQD_ParseStufftext (void)
{
	char	*s;
	byte	*p;

	if (msg_readcount + 7 <= net_message.cursize &&
		net_message.data[msg_readcount] == 1 && net_message.data[msg_readcount + 1] == 7)
	{
		int num, ping;
		MSG_ReadByte();
		MSG_ReadByte();
		while (ping = ReadPQShort())
		{
			num = ping / 4096;
			if ((unsigned int)num >= nq_maxclients)
				Host_Error ("Bad ProQuake message");
			cl.players[num].ping = ping & 4095;
			nq_drawpings = true;
		}
		// fall through to stufftext parsing (yes that's how it's intended by JPG)
	}

	s = MSG_ReadString ();
	Com_DPrintf ("stufftext: %s\n", s);

	for (p = s; *p; p++) {
		if (*p > 32 && *p < 128)
			goto ok;
	}
	// ignore weird ProQuake stuff
	return;

ok:
	Cbuf_AddTextEx (&cbuf_svc, s);
}


/*
==================
NQD_ParseServerData
==================
*/
void NQD_ParseServerData (void)
{
	char	*str;
	int		i;
	int		nummodels, numsounds;

	Com_DPrintf ("Serverdata packet received.\n");
//
// wipe the client_state_t struct
//
	CL_ClearState ();

// parse protocol version number
	i = MSG_ReadLong ();
	if (i != NQ_PROTOCOL_VERSION)
		Host_Error ("Server returned version %i, not %i", i, NQ_PROTOCOL_VERSION);

// parse maxclients
	nq_maxclients = MSG_ReadByte ();
	if (nq_maxclients < 1 || nq_maxclients > NQ_MAX_CLIENTS)
		Host_Error ("Bad maxclients (%u) from server", nq_maxclients);

// parse gametype
	cl.gametype = MSG_ReadByte() ? GAME_DEATHMATCH : GAME_COOP;

// parse signon message
	str = MSG_ReadString ();
	strncpy (cl.levelname, str, sizeof(cl.levelname)-1);

// seperate the printfs so the server message can have a color
	Com_Printf("\n\n\35\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\36\37\n\n");
	Com_Printf ("%c%s\n", 2, str);

//
// first we go through and touch all of the precache data that still
// happens to be in the cache, so precaching something else doesn't
// needlessly purge it
//

// precache models
	for (nummodels=1 ; ; nummodels++)
	{
		str = MSG_ReadString ();
		if (!str[0])
			break;
		if (nummodels == MAX_MODELS)
			Host_Error ("Server sent too many model precaches");
		Q_strncpyz (cl.model_name[nummodels], str, sizeof(cl.model_name[0]));
		Mod_TouchModel (str);
	}

// precache sounds
	for (numsounds=1 ; ; numsounds++)
	{
		str = MSG_ReadString ();
		if (!str[0])
			break;
		if (numsounds == MAX_SOUNDS)
			Host_Error ("Server sent too many sound precaches");
		Q_strncpyz (cl.sound_name[numsounds], str, sizeof(cl.sound_name[0]));
		S_TouchSound (str);
	}

//
// now we try to load everything else until a cache allocation fails
//

	for (i=1 ; i<nummodels ; i++)
	{
		cl.model_precache[i] = Mod_ForName (cl.model_name[i], false);
		if (cl.model_precache[i] == NULL)
			Host_Error ("Model %s not found", cl.model_name[i]);
	}

	for (i=1 ; i<numsounds ; i++) {
		cl.sound_precache[i] = S_PrecacheSound (cl.sound_name[i]);
	}


// local state
	cl.worldmodel = cl.model_precache[1];
	if (!cl.worldmodel)
		Host_Error ("NQD_ParseServerData: NULL worldmodel");
	CL_ClearParticles ();
	CL_FindModelNumbers ();
	TP_NewMap ();
	R_NewMap ();

	Hunk_Check ();		// make sure nothing is hurt

	nq_signon = 0;
	nq_num_entities = 0;
	nq_drawpings = false;	// unless we have the ProQuake extension
	cl.servertime_works = true;
	cl.allow_fbskins = true;
	r_refdef2.allowCheats = true;	// why not
	cls.state = ca_onserver;
}

/*
==================
NQD_ParseStartSoundPacket
==================
*/
void NQD_ParseStartSoundPacket(void)
{
    vec3_t  pos;
    int 	channel, ent;
    int 	sound_num;
    int 	volume;
    int 	field_mask;
    float 	attenuation;  
 	int		i;
	           
    field_mask = MSG_ReadByte(); 

    if (field_mask & NQ_SND_VOLUME)
		volume = MSG_ReadByte ();
	else
		volume = DEFAULT_SOUND_PACKET_VOLUME;
	
    if (field_mask & NQ_SND_ATTENUATION)
		attenuation = MSG_ReadByte () / 64.0;
	else
		attenuation = DEFAULT_SOUND_PACKET_ATTENUATION;
	
	channel = MSG_ReadShort ();
	sound_num = MSG_ReadByte ();

	ent = channel >> 3;
	channel &= 7;

	if (ent > NQ_MAX_EDICTS)
		Host_Error ("NQD_ParseStartSoundPacket: ent = %i", ent);
	
	for (i=0 ; i<3 ; i++)
		pos[i] = MSG_ReadCoord ();
 
    S_StartSound (ent, channel, cl.sound_precache[sound_num], pos, volume/255.0, attenuation);
}       


/*
===============
NQD_ParseParticleEffect
===============
*/
void NQD_ParseParticleEffect (void)
{
	vec3_t		org, dir;
	int			i, count, msgcount, color;
	
	for (i=0 ; i<3 ; i++)
		org[i] = MSG_ReadCoord ();
	for (i=0 ; i<3 ; i++)
		dir[i] = MSG_ReadChar () * (1.0/16);
	msgcount = MSG_ReadByte ();
	color = MSG_ReadByte ();

	if (msgcount == 255)
		count = 1024;
	else
		count = msgcount;
	
	CL_RunParticleEffect (org, dir, color, count);
}


/*
==================
NQD_ParseUpdate

Parse an entity update message from the server
If an entities model or origin changes from frame to frame, it must be
relinked.  Other attributes can change without relinking.
==================
*/
void NQD_ParseUpdate (int bits)
{
	int			i;
//	model_t		*model;
	int			modnum;
	qboolean	forcelink;
	centity_t	*ent;
	entity_state_t	*state;
	int			num;
#ifdef GLQUAKE
	int			skin;
#endif

	if (nq_signon == NQ_SIGNONS - 1)
	{	// first update is the final signon stage
		nq_signon = NQ_SIGNONS;
		Con_ClearNotify ();
		//TP_ExecTrigger ("f_spawn");
		SCR_EndLoadingPlaque ();
		cls.state = ca_active;
	}

	if (bits & NQ_U_MOREBITS)
	{
		i = MSG_ReadByte ();
		bits |= (i<<8);
	}

	if (bits & NQ_U_LONGENTITY)	
		num = MSG_ReadShort ();
	else
		num = MSG_ReadByte ();

	if (num >= NQ_MAX_EDICTS)
		Host_Error ("NQD_ParseUpdate: ent > MAX_EDICTS");

	NQD_BumpEntityCount (num);

	ent = &cl_entities[num];
	ent->previous = ent->current;
	ent->current = ent->baseline;
	state = &ent->current;
	state->number = num;

	if (ent->lastframe != cl_entframecount-1)
		forcelink = true;	// no previous frame to lerp from
	else
		forcelink = false;

	ent->lastframe = cl_entframecount;
	
	if (bits & NQ_U_MODEL)
	{
		modnum = MSG_ReadByte ();
		if (modnum >= MAX_MODELS)
			Host_Error ("CL_ParseModel: bad modnum");
	}
	else
		modnum = ent->baseline.modelindex;
		
//	model = cl.model_precache[modnum];
	if (modnum != state->modelindex)
	{
		state->modelindex = modnum;
	// automatic animation (torches, etc) can be either all together
	// or randomized
		if (modnum)
		{
			/*if (model->synctype == ST_RAND)
				state->syncbase = (float)(rand()&0x7fff) / 0x7fff;
			else
				state->syncbase = 0.0;
				*/
		}
		else
			forcelink = true;	// hack to make null model players work
#ifdef GLQUAKE
		if (num > 0 && num <= nq_maxclients)
			R_TranslatePlayerSkin (num - 1);
#endif
	}
	
	if (bits & NQ_U_FRAME)
		state->frame = MSG_ReadByte ();
	else
		state->frame = ent->baseline.frame;

	if (bits & NQ_U_COLORMAP)
		i = MSG_ReadByte();
	else
		i = ent->baseline.colormap;

	state->colormap = i;

#ifdef GLQUAKE
	if (bits & NQ_U_SKIN)
		skin = MSG_ReadByte();
	else
		skin = ent->baseline.skinnum;
	if (skin != state->skinnum) {
		state->skinnum = skin;
		if (num > 0 && num <= nq_maxclients)
			R_TranslatePlayerSkin (num - 1);
	}

#else

	if (bits & NQ_U_SKIN)
		state->skinnum = MSG_ReadByte();
	else
		state->skinnum = ent->baseline.skinnum;
#endif

	if (bits & NQ_U_EFFECTS)
		state->effects = MSG_ReadByte();
	else
		state->effects = 0;

	if (bits & NQ_U_ORIGIN1)
		state->origin[0] = MSG_ReadCoord ();
	else
		state->origin[0] = ent->baseline.origin[0];
	if (bits & NQ_U_ANGLE1)
		state->angles[0] = MSG_ReadAngle();
	else
		state->angles[0] = ent->baseline.angles[0];

	if (bits & NQ_U_ORIGIN2)
		state->origin[1] = MSG_ReadCoord ();
	else
		state->origin[1] = ent->baseline.origin[1];
	if (bits & NQ_U_ANGLE2)
		state->angles[1] = MSG_ReadAngle();
	else
		state->angles[1] = ent->baseline.angles[1];

	if (bits & NQ_U_ORIGIN3)
		state->origin[2] = MSG_ReadCoord ();
	else
		state->origin[2] = ent->baseline.origin[2];
	if (bits & NQ_U_ANGLE3)
		state->angles[2] = MSG_ReadAngle();
	else
		state->angles[2] = ent->baseline.angles[2];

	if ( bits & NQ_U_NOLERP )
		forcelink = true;

	if ( forcelink )
	{	// didn't have an update last message
		VectorCopy (state->origin, ent->previous.origin);
		VectorCopy (state->origin, ent->lerp_origin);
		VectorCopy (state->angles, ent->previous.angles);
		//ent->forcelink = true;
	}
}


/*
===============
NQD_LerpPoint

Determines the fraction between the last two messages that the objects
should be put at.
===============
*/
float NQD_LerpPoint (void)
{
	float	f, frac;

	f = nq_mtime[0] - nq_mtime[1];
	
	if (!f || /* cl_nolerp.value || */ cls.timedemo) {
		cl.time = nq_mtime[0];
		return 1;
	}
		
	if (f > 0.1)
	{	// dropped packet, or start of demo
		nq_mtime[1] = nq_mtime[0] - 0.1;
		f = 0.1;
	}
	frac = (cl.time - nq_mtime[1]) / f;
	if (frac < 0)
	{
		if (frac < -0.01)
			cl.time = nq_mtime[1];
		frac = 0;
	}
	else if (frac > 1)
	{
		if (frac > 1.01)
			cl.time = nq_mtime[0];
		frac = 1;
	}
		
	return frac;
}



extern int		cl_playerindex; 
extern int		cl_h_playerindex, cl_gib1index, cl_gib2index, cl_gib3index;
extern int		cl_rocketindex, cl_grenadeindex;

void NQD_LerpPlayerinfo (float f)
{
	int		i;

	if (cl.intermission) {
		// just stay there
		return;
	}

	if (nq_player_teleported) {
		VectorCopy (nq_mvelocity[0], cl.simvel);
		VectorCopy (nq_mviewangles[0], cl.viewangles);
		VectorCopy (nq_mviewangles[0], cl.simangles);
		return;
	}

	for (i=0 ; i<3 ; i++)
		cl.simvel[i] = nq_mvelocity[1][i] + 
			f * (nq_mvelocity[0][i] - nq_mvelocity[1][i]);

	for (i = 0; i < 3; i++)
	{
		float	d;
		d = nq_mviewangles[0][i] - nq_mviewangles[1][i];
		if (d > 180)
			d -= 360;
		else if (d < -180)
			d += 360;
		cl.viewangles[i] = cl.simangles[i] = nq_mviewangles[1][i] + f*d;
	}
}

void NQD_LinkEntities (void)
{
	entity_t			ent;
	centity_t			*cent;
	entity_state_t		*state;
	float				f;
	model_t				*model;
	vec3_t				old_origin;
	float				autorotate;
	int					i;
	int					num;

	f = NQD_LerpPoint ();

	NQD_LerpPlayerinfo (f);

	autorotate = anglemod (100*cl.time);

	memset (&ent, 0, sizeof(ent));

	for (num = 1; num < nq_num_entities; num++)
	{
		cent = &cl_entities[num];
		state = &cent->current;

		if (cent->lastframe != cl_entframecount)
			continue;		// not present in this frame

		// spawn light flashes, even ones coming from invisible objects
		if (state->effects & EF_MUZZLEFLASH) {
			vec3_t		forward;
			dlight_t	*dl;

			dl = CL_AllocDlight (-num);
			AngleVectors (state->angles, forward, NULL, NULL);
			VectorMA (state->origin, 18, forward, dl->origin);
			dl->origin[2] += 16;
			dl->radius = 200 + (rand()&31);
			dl->minlight = 32;
			dl->die = cl.time + 0.1;
			dl->type = lt_muzzleflash;
		}
		if (state->effects & EF_BRIGHTLIGHT) {
			if (state->modelindex != cl_playerindex || r_powerupglow.value) {
				vec3_t	tmp;
				VectorCopy (state->origin, tmp);
				tmp[2] += 16;
				CL_NewDlight (state->number, tmp, 400 + (rand()&31), 0.1, lt_default);
			}
		}
		if (state->effects & EF_DIMLIGHT)
			CL_NewDlight (state->number, state->origin, 200 + (rand()&31), 0.1, lt_default);

		// if set to invisible, skip
		if (!state->modelindex)
			continue;

		cent->current = *state;

		ent.model = model = cl.model_precache[state->modelindex];
		if (!model)
			Host_Error ("CL_LinkPacketEntities: bad modelindex");

		if (cl_r2g.value && cl_grenadeindex != -1)
			if (state->modelindex == cl_rocketindex)
				ent.model = cl.model_precache[cl_grenadeindex];

		// rotate binary objects locally
		if (model->flags & EF_ROTATE)
		{
			ent.angles[0] = 0;
			ent.angles[1] = autorotate;
			ent.angles[2] = 0;
		}
		else
		{
			float	a1, a2;

			for (i=0 ; i<3 ; i++)
			{
				a1 = cent->current.angles[i];
				a2 = cent->previous.angles[i];
				if (a1 - a2 > 180)
					a1 -= 360;
				if (a1 - a2 < -180)
					a1 += 360;
				ent.angles[i] = a2 + f * (a1 - a2);
			}
		}

		// calculate origin
		for (i=0 ; i<3 ; i++)
		{
			if (cent->current.origin[i] - cent->previous.origin[i] > 128) {
				// teleport or something, don't lerp
				VectorCopy (cent->current.origin, ent.origin);
				if (num == nq_viewentity)
					nq_player_teleported = true;
				break;
			}
			ent.origin[i] = cent->previous.origin[i] + 
				f * (cent->current.origin[i] - cent->previous.origin[i]);
		}

		if (num == nq_viewentity) {
			VectorCopy (ent.origin, cent->lerp_origin);	// FIXME?
			continue;			// player entity
		}

		if (cl_deadbodyfilter.value && state->modelindex == cl_playerindex
			&& ( (i=state->frame)==49 || i==60 || i==69 || i==84 || i==93 || i==102) )
			continue;

		if (cl_gibfilter.value)
		if (state->modelindex == cl_h_playerindex || state->modelindex == cl_gib1index
			|| state->modelindex == cl_gib2index || state->modelindex == cl_gib3index)
			continue;

		// set colormap
		if (state->colormap && (state->colormap < MAX_CLIENTS) 
			&& ent.model->modhint == MOD_PLAYER)
		{
			ent.colormap = cl.players[state->colormap-1].translations;
			ent.scoreboard = &cl.players[state->colormap-1];
		}
		else
		{
			ent.colormap = vid.colormap;
			ent.scoreboard = NULL;
		}

		// set skin
		ent.skinnum = state->skinnum;
		
		// set frame
		ent.frame = state->frame;

		// add automatic particle trails
		if ((model->flags & ~EF_ROTATE))
		{
			if (false /*cl_entframecount == 1 || cent->lastframe != cl_entframecount-1*/)
			{	// not in last message
				VectorCopy (ent.origin, old_origin);
			}
			else
			{
				VectorCopy (cent->lerp_origin, old_origin);

				for (i=0 ; i<3 ; i++)
					if ( abs(old_origin[i] - ent.origin[i]) > 128)
					{	// no trail if too far
						VectorCopy (ent.origin, old_origin);
						break;
					}
			}

			if (model->flags & EF_ROCKET)
			{
				if (r_rockettrail.value) {
					if (r_rockettrail.value == 2)
						CL_GrenadeTrail (old_origin, ent.origin);
					else
						CL_RocketTrail (old_origin, ent.origin);
				}

				if (r_rocketlight.value)
					CL_NewDlight (state->number, ent.origin, 200, 0.1, lt_rocket);
			}
			else if (model->flags & EF_GRENADE && r_grenadetrail.value)
				CL_GrenadeTrail (old_origin, ent.origin);
			else if (model->flags & EF_GIB)
				CL_BloodTrail (old_origin, ent.origin);
			else if (model->flags & EF_ZOMGIB)
				CL_SlightBloodTrail (old_origin, ent.origin);
			else if (model->flags & EF_TRACER)
				CL_TracerTrail (old_origin, ent.origin, 52);
			else if (model->flags & EF_TRACER2)
				CL_TracerTrail (old_origin, ent.origin, 230);
			else if (model->flags & EF_TRACER3)
				CL_VoorTrail (old_origin, ent.origin);
		}

		VectorCopy (ent.origin, cent->lerp_origin);
		cent->lastframe = cl_entframecount;
		V_AddEntity (&ent);
	}

	if (nq_viewentity == 0)
		Host_Error ("viewentity == 0");
	VectorCopy (cl_entities[nq_viewentity].lerp_origin, cl.simorg);
}





extern char *svc_strings[];

#define SHOWNET(x) {if(cl_shownet.value==2)Com_Printf ("%3i:%s\n", msg_readcount-1, x);}

void NQD_ParseServerMessage (void)
{
	int			cmd;
	int			i;
	qboolean	message_with_datagram;		// hack to fix glitches when receiving a packet
											// without a datagram

	nq_player_teleported = false;		// OMG, it's a hack!
	message_with_datagram = false;
	cl_entframecount++;

	if (cl_shownet.value == 1)
		Com_Printf ("%i ", net_message.cursize);
	else if (cl_shownet.value == 2)
		Com_Printf ("------------------\n");
	
	cl.onground = false;	// unless the server says otherwise	

//
// parse the message
//
	MSG_BeginReading ();
	
	while (1)
	{
		if (msg_badread)
			Host_Error ("CL_ParseServerMessage: Bad server message");

		cmd = MSG_ReadByte ();

		if (cmd == -1)
		{
			SHOWNET("END OF MESSAGE");
			if (!message_with_datagram) {
				cl_entframecount--;
			}
			else
			{
				VectorCopy (nq_mviewangles[0], nq_mviewangles[1]);
				VectorCopy (nq_mviewangles_temp, nq_mviewangles[0]);
			}
			return;		// end of message
		}

	// if the high bit of the command byte is set, it is a fast update
		if (cmd & 128)
		{
			SHOWNET("fast update");
			NQD_ParseUpdate (cmd&127);
			continue;
		}

		SHOWNET(svc_strings[cmd]);
	
	// other commands
		switch (cmd)
		{
		default:
			Host_Error ("CL_ParseServerMessage: Illegible server message");
			break;

		case svc_nop:
			break;

		case svc_time:
			nq_mtime[1] = nq_mtime[0];
			nq_mtime[0] = MSG_ReadFloat ();
			cl.servertime = nq_mtime[0];
			message_with_datagram = true;
			break;

		case svc_clientdata:
			i = MSG_ReadShort ();
			NQD_ParseClientdata (i);
			break;

		case svc_version:
			i = MSG_ReadLong ();
			if (i != NQ_PROTOCOL_VERSION)
				Host_Error ("CL_ParseServerMessage: Server is protocol %i instead of %i\n", i, NQ_PROTOCOL_VERSION);
			break;

		case svc_disconnect:
			Com_Printf ("\n======== End of demo ========\n\n");
			CL_NextDemo ();
			Host_EndGame ();
			Host_Abort ();
			break;

		case svc_print:
			NQD_ParsePrint ();
			break;
			
		case svc_centerprint:
			SCR_CenterPrint (MSG_ReadString ());
			break;

		case svc_stufftext:
			NQD_ParseStufftext ();
			break;

		case svc_damage:
			V_ParseDamage ();
			break;

		case svc_serverdata:
			NQD_ParseServerData ();
			vid.recalc_refdef = true;	// leave intermission full screen
			break;

		case svc_setangle:
			for (i=0 ; i<3 ; i++)
				nq_last_fixangle[i] = cl.simangles[i] = cl.viewangles[i] = MSG_ReadAngle ();
			break;

		case svc_setview:
			nq_viewentity = MSG_ReadShort ();
			if (nq_viewentity <= nq_maxclients)
				cl.playernum = nq_viewentity - 1;
			else	{
				// just let cl.playernum stay where it was
			}
			break;

		case svc_lightstyle:
			i = MSG_ReadByte ();
			if (i >= MAX_LIGHTSTYLES)
				Sys_Error ("svc_lightstyle > MAX_LIGHTSTYLES");
			Q_strncpyz (cl_lightstyle[i].map,  MSG_ReadString(), sizeof(cl_lightstyle[0].map));
			cl_lightstyle[i].length = strlen(cl_lightstyle[i].map);
			break;

		case svc_sound:
			NQD_ParseStartSoundPacket();
			break;

		case svc_stopsound:
			i = MSG_ReadShort();
			S_StopSound(i>>3, i&7);
			break;

		case svc_updatename:
			Sbar_Changed ();
			i = MSG_ReadByte ();
			if (i >= nq_maxclients)
				Host_Error ("CL_ParseServerMessage: svc_updatename > NQ_MAX_CLIENTS");
			Q_strncpyz(cl.players[i].name, MSG_ReadString(), sizeof(cl.players[i].name));
			break;

		case svc_updatefrags:
			Sbar_Changed ();
			i = MSG_ReadByte ();
			if (i >= nq_maxclients)
				Host_Error ("CL_ParseServerMessage: svc_updatefrags > NQ_MAX_CLIENTS");
			cl.players[i].frags = MSG_ReadShort();
			break;

		case svc_updatecolors:
			NQD_ParseUpdatecolors ();
			break;
			
		case svc_particle:
			NQD_ParseParticleEffect ();
			break;

		case svc_spawnbaseline:
			i = MSG_ReadShort ();
			if (i >= NQ_MAX_EDICTS)
				Host_Error ("svc_spawnbaseline: ent > MAX_EDICTS");
			NQD_BumpEntityCount (i);
			CL_ParseBaseline (&cl_entities[i].baseline);
			break;
		case svc_spawnstatic:
			CL_ParseStatic ();
			break;
		case svc_temp_entity:
			CL_ParseTEnt ();
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

		case svc_signonnum:
			i = MSG_ReadByte ();
			if (i <= nq_signon)
				Host_Error ("Received signon %i when at %i", i, nq_signon);
			nq_signon = i;
			break;

		case svc_killedmonster:
			cl.stats[STAT_MONSTERS]++;
			break;

		case svc_foundsecret:
			cl.stats[STAT_SECRETS]++;
			break;

		case svc_updatestat:
			i = MSG_ReadByte ();
			if (i < 0 || i >= MAX_CL_STATS)
				Sys_Error ("svc_updatestat: %i is invalid", i);
			cl.stats[i] = MSG_ReadLong ();;
			break;

		case svc_spawnstaticsound:
			CL_ParseStaticSound ();
			break;

		case svc_cdtrack:
			cl.cdtrack = MSG_ReadByte ();
			MSG_ReadByte();		// loop track (unused)
			if (nq_forcecdtrack != -1)
				CDAudio_Play ((byte)nq_forcecdtrack, true);
			else
				CDAudio_Play ((byte)cl.cdtrack, true);
			break;

		case svc_intermission:
			cl.intermission = 1;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			VectorCopy (nq_last_fixangle, cl.simangles);
			break;

		case svc_finale:
			cl.intermission = 2;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			SCR_CenterPrint (MSG_ReadString ());
			VectorCopy (nq_last_fixangle, cl.simangles);
			break;

		case svc_cutscene:
			cl.intermission = 3;
			cl.completed_time = cl.time;
			vid.recalc_refdef = true;	// go to full screen
			SCR_CenterPrint (MSG_ReadString ());
			VectorCopy (nq_last_fixangle, cl.simangles);
			break;

		case svc_sellscreen:
			break;
		}
	}

}


void NQD_ReadPackets (void)
{
	while (CL_GetNQDemoMessage()) {
		NQD_ParseServerMessage();
	}
}


void NQD_StartPlayback ()
{
	int c;
	qboolean	neg;

	// parse forced cd track
	while ((c = getc(cls.demofile)) != '\n') {
		if (c == '-')
			neg = true;
		else
			nq_forcecdtrack = nq_forcecdtrack * 10 + (c - '0');
	}
	if (neg)
		nq_forcecdtrack = -nq_forcecdtrack;

	cl.spectator = false;
	nq_signon = 0;
	nq_mtime[0] = 0;
	nq_maxclients = 0;
}
