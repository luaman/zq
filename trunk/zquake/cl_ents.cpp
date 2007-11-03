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
// cl_ents.c -- entity parsing and management

#include "client.h"
#include "pmove.h"
#include "teamplay.h"

extern cvar_t	cl_predict_players;
extern cvar_t	cl_solid_players;

cvar_t cl_lerp_monsters = {"cl_lerp_monsters", "1"};
cvar_t r_rocketlight = {"r_rocketLight", "1"};
cvar_t r_rockettrail = {"r_rocketTrail", "1"};
cvar_t r_grenadetrail = {"r_grenadeTrail", "1"};
cvar_t r_powerupglow = {"r_powerupGlow", "1"};
cvar_t r_lightflicker = {"r_lightflicker", "1"};
cvar_t	cl_deadbodyfilter = {"cl_deadbodyFilter", "0"};
cvar_t	cl_explosion = {"cl_explosion", "0"};
cvar_t	cl_gibfilter = {"cl_gibFilter", "0"};
cvar_t	cl_gibtime = {"cl_gibtime", "3"};
cvar_t	cl_r2g = {"cl_r2g", "0"};
cvar_t	cl_predict_players = {"cl_predict_players", "1"};
cvar_t	cl_solid_players = {"cl_solid_players", "1"};


static struct predicted_player {
	int		flags;
	qbool	active;
	vec3_t	origin;	// predicted origin
	vec3_t	angles;	//@@lerp test
#ifdef MVDPLAY
	qbool predict;
	vec3_t	oldo;
	vec3_t	olda;
	vec3_t	oldv;
	vec3_t	vel;
	player_state_t *oldstate;
#endif
} predicted_players[MAX_CLIENTS];

extern	int		cl_spikeindex, cl_playerindex, cl_flagindex;

/*
=========================================================================

PACKET ENTITY PARSING / LINKING

=========================================================================
*/

/*
==================
CL_ParseDelta

Can go from either a baseline or a previous packet_entity
==================
*/
int	bitcounts[32];	/// just for protocol profiling
void CL_ParseDelta (entity_state_t *from, entity_state_t *to, int bits)
{
	int			i;

	// set everything to the state we are delta'ing from
	*to = *from;

	to->number = bits & 511;
	bits &= ~511;

	if (bits & U_MOREBITS)
	{	// read in the low order bits
		i = MSG_ReadByte ();
		bits |= i;
	}

	// count the bits for net profiling
	for (i=0 ; i<16 ; i++)
		if (bits&(1<<i))
			bitcounts[i]++;

	to->flags = bits;
	
	if (bits & U_MODEL)
		to->modelindex = MSG_ReadByte ();
		
	if (bits & U_FRAME)
		to->frame = MSG_ReadByte ();

	if (bits & U_COLORMAP)
		to->colormap = MSG_ReadByte();

	if (bits & U_SKIN)
		to->skinnum = MSG_ReadByte();

	if (bits & U_EFFECTS)
		to->effects = MSG_ReadByte();

	if (bits & U_ORIGIN1)
		to->s_origin[0] = MSG_ReadShort ();
		
	if (bits & U_ANGLE1)
		to->s_angles[0] = MSG_ReadByte ();

	if (bits & U_ORIGIN2)
		to->s_origin[1] = MSG_ReadShort ();
		
	if (bits & U_ANGLE2)
		to->s_angles[1] = MSG_ReadByte ();

	if (bits & U_ORIGIN3)
		to->s_origin[2] = MSG_ReadShort ();
		
	if (bits & U_ANGLE3)
		to->s_angles[2] = MSG_ReadByte ();

	if (bits & U_SOLID)
	{
		// FIXME
		// oldman: is this not used?
		// to->solid = MSG_ReadShort ();
		// Tonik: no, it is not used (alas!)
	}
}


/*
=================
FlushEntityPacket
=================
*/
void FlushEntityPacket (void)
{
	int			word;
	static entity_state_t olde;	// all zeroes
	entity_state_t newe;

	Com_DPrintf ("FlushEntityPacket\n");

	// read it all, but ignore it
	while (1)
	{
		word = (unsigned short)MSG_ReadShort ();
		if (msg_badread)
		{	// something didn't parse right...
			Host_Error ("msg_badread in packetentities");
			return;
		}

		if (!word)
			break;	// done

		CL_ParseDelta (&olde, &newe, word);
	}
}

entity_state_t *CL_GetBaseline (int number)
{
	return &cl_entities[number].baseline;
}

// bump lastframe and copy current state to previous
static void UpdateEntities (void)
{
	int		i;
	packet_entities_t *pack;
	entity_state_t *ent;
	centity_t	*cent;

	pack = &new_snapshot.packet_entities;

	for (i = 0; i < pack->num_entities; i++) {
		ent = &pack->entities[i];
		cent = &cl_entities[ent->number];

		cent->prevframe = cent->lastframe;
		cent->lastframe = cl_entframecount;

		if (cent->prevframe == cl_entframecount - 1) {
			// move along, move along
			cent->previous = cent->current;
		} else {
			// not in previous message
			cent->previous = *ent;
			MSG_UnpackOrigin (ent->s_origin, cent->trail_origin);
		}

		cent->current = *ent;
	}
}

/*
==================
CL_ParsePacketEntities

An svc_packetentities has just been parsed, deal with the
rest of the data stream.
==================
*/
void CL_ParsePacketEntities (qbool delta)
{
	int			oldpacket;
	packet_entities_t	*oldp, *newp, dummy;
	int			oldindex, newindex;
	int			word, newnum, oldnum;
	qbool		full;
	byte		from;
	entity_state_t newents[BIG_MAX_PACKET_ENTITIES];
#ifdef MVDPLAY
	int maxents = cls.mvdplayback ? BIG_MAX_PACKET_ENTITIES	: MAX_PACKET_ENTITIES;
#else
	int maxents = MAX_PACKET_ENTITIES;
#endif

	newp = &new_snapshot.packet_entities;

#ifdef MVDPLAY
	if (delta && cls.mvdplayback) {
		MSG_ReadByte ();
		oldp = &cl.snapshots[0].packet_entities;
		full = false;
	} else
#endif
	if (delta)
	{
		from = MSG_ReadByte ();

		if (cls.netchan.outgoing_sequence - new_snapshot.sequence >= SENT_BACKUP-1)
		{	// don't have delta_sequence history for this packet
			FlushEntityPacket ();
			return;
		}

		oldpacket = cl.outpackets[new_snapshot.sequence&SENT_MASK].delta_sequence;

		if ( (from&UPDATE_MASK) != (oldpacket&UPDATE_MASK) ) {
			// should never happens unless the server misbehaves
			Com_DPrintf ("WARNING: from mismatch\n");
			FlushEntityPacket ();
			return;
		}

		int i;
		for (i = 0; i < cl.num_snapshots; i++)
			if (cl.snapshots[i].sequence == oldpacket)
				break;

		if (i == cl.num_snapshots) {
			// packet is too old, don't have the base frame anymore
			FlushEntityPacket ();
			return;
		}

		oldp = &cl.snapshots[i].packet_entities;
		full = false;
	}
	else
	{	// this is a full update that we can start delta compressing from now
		oldp = &dummy;
		dummy.num_entities = 0;
		dummy.entities = NULL;
		full = true;
	}

	oldindex = 0;
	newindex = 0;
	newp->num_entities = 0;

	while (1)
	{
		word = (unsigned short)MSG_ReadShort ();
		if (msg_badread)
		{	// something didn't parse right...
			Host_Error ("msg_badread in packetentities");
			return;
		}

		if (!word)
		{
			while (oldindex < oldp->num_entities)
			{	// copy all the rest of the entities from the old packet
				if (newindex >= maxents)
					Host_Error ("CL_ParsePacketEntities: newindex == MAX_PACKET_ENTITIES");
				newents[newindex] = oldp->entities[oldindex];
				newindex++;
				oldindex++;
			}
			break;
		}
		newnum = word&511;
		oldnum = oldindex >= oldp->num_entities ? 9999 : oldp->entities[oldindex].number;

		while (newnum > oldnum)
		{
			if (full)
			{
				Com_Printf ("WARNING: oldcopy on full update");
				FlushEntityPacket ();
				return;
			}

			// copy one of the old entities over to the new packet unchanged
			if (newindex >= maxents)
				Host_Error ("CL_ParsePacketEntities: newindex == MAX_PACKET_ENTITIES");
			newents[newindex] = oldp->entities[oldindex];
			newindex++;
			oldindex++;
			oldnum = oldindex >= oldp->num_entities ? 9999 : oldp->entities[oldindex].number;
		}

		if (newnum < oldnum)
		{	// new from baseline

			if (word & U_REMOVE)
			{
				if (full)
				{
					Com_Printf ("WARNING: U_REMOVE on full update\n");
					FlushEntityPacket ();
					return;
				}
				continue;
			}
			if (newindex >= maxents)
				Host_Error ("CL_ParsePacketEntities: newindex == MAX_PACKET_ENTITIES");
			CL_ParseDelta (&cl_entities[newnum].baseline, &newents[newindex], word);
			newindex++;
			continue;
		}

		if (newnum == oldnum)
		{	// delta from previous
			if (full) {
				// can this really ever happen?
				Com_Printf ("WARNING: delta on full update");
			}
			if (word & U_REMOVE)
			{
				oldindex++;
				continue;
			}

			CL_ParseDelta (&oldp->entities[oldindex], &newents[newindex], word);

			newindex++;
			oldindex++;
		}
	}

	newp->num_entities = newindex;
	Q_free (newp->entities);
	newp->entities = (entity_state_t *)Q_malloc (sizeof(entity_state_t) * newp->num_entities);
	memcpy (newp->entities, newents, sizeof(entity_state_t) * newp->num_entities);
	extern qbool new_snapshot_entities_valid;
	new_snapshot_entities_valid = true;

	cl_entframecount++;
	UpdateEntities ();

	if (cls.demorecording) {
		// write uncompressed packetentities to the demo
		MSG_EmitPacketEntities (NULL, -1, newp, &cls.demomessage, CL_GetBaseline);
		cls.demomessage_skipwrite = true;
	}
}


extern int	cl_playerindex; 
extern int	cl_rocketindex, cl_grenadeindex;

/*
===============
CL_LinkPacketEntities

===============
*/
void CL_LinkPacketEntities (void)
{
	entity_t			ent;
	centity_t			*cent;
	packet_entities_t	*pack;
	entity_state_t		*state;
	float				f;
	struct model_s		*model;
	int					modelflags;
	vec3_t				cur_origin;
	vec3_t				old_origin;
	float				autorotate, flicker;
	int					i;
	int					pnum;
	extern cvar_t		cl_nolerp;

	pack = &cl.snapshots[0].packet_entities;

	autorotate = anglemod (100*cl.time);

#ifdef MVDPLAY
	if (cls.mvdplayback) {
		if (cl.num_snapshots < 2)
			return;
		assert (cl.snapshots[0].servertime > cl.snapshots[1].servertime);
		f = bound(0, (cls.demotime - cl.snapshots[1].servertime) / (cl.snapshots[0].servertime - cl.snapshots[1].servertime), 1);
	}
	else
#endif
	if (cl_nolerp.value)
		f = 1;
	else
	{
		float t, simtime;

		simtime = cls.realtime - cl.entlatency;
		if (simtime > cl.snapshots[0].servertime) {
			cl.entlatency = cls.realtime - cl.snapshots[0].servertime;
		} else if (simtime < cl.snapshots[1].servertime) {
			cl.entlatency = cls.realtime - cl.snapshots[1].servertime;
		} else {
			// drift towards ideal latency
		}

		t = cl.snapshots[0].servertime - cl.snapshots[1].servertime;
		if (t)
			f = (cls.realtime - cl.entlatency - cl.snapshots[1].servertime) / t;
		else
			f = 1;
		f = bound (0, f, 1);
	}

	for (pnum=0 ; pnum<pack->num_entities ; pnum++)
	{
		state = &pack->entities[pnum];
		cent = &cl_entities[state->number];

#ifdef MVDPLAY
		if (!cls.mvdplayback)
#endif
		{ assert(cent->lastframe == cl_entframecount);
		assert(!memcmp(state, &cent->current, sizeof(*state))); }

		MSG_UnpackOrigin (state->s_origin, cur_origin);

		// control powerup glow for bots
		if (state->modelindex != cl_playerindex || r_powerupglow.value)
		{
			flicker = r_lightflicker.value ? (rand() & 31) : 10;
			// spawn light flashes, even ones coming from invisible objects
			if (state->effects & (EF_BLUE | EF_GREEN | EF_RED))
			{
				int type = ((state->effects & EF_BLUE) ? 1 : 0) | ((state->effects & EF_GREEN) ? 2 : 0)
					| ((state->effects & EF_RED) ? 4 : 0) - 1 + lt_blue;
				V_AddDlight (state->number, cur_origin, 200 + flicker, 0, (dlighttype_t)type);
			} else if (state->effects & EF_BRIGHTLIGHT) {
				vec3_t	tmp;
				VectorCopy (cur_origin, tmp);
				tmp[2] += 16;
				V_AddDlight (state->number, tmp, 400 + flicker, 0, lt_default);
			} else if (state->effects & EF_DIMLIGHT)
				V_AddDlight (state->number, cur_origin, 200 + flicker, 0, lt_default);
		}

		if (state->effects & EF_BRIGHTFIELD)
			CL_EntityParticles (cur_origin);

		// if set to invisible, skip
		if (!state->modelindex)
			continue;

		if (state->modelindex == cl_playerindex) {
			int f = state->frame;
			if (cl_deadbodyfilter.value == 2 && f >= 41 && f <= 102)
				continue;
			if (cl_deadbodyfilter.value && (f==49 || f==60 || f==69 || f==84 || f==93 || f==102))
				continue;
		}

		memset (&ent, 0, sizeof(ent));

		if (cl.modelinfos[state->modelindex] == mi_gib) {
			if (!cent->gib_start)
				cent->gib_start = cl.time;
			if (cl_gibfilter.value == 2) {
				if (cent->gib_start && cl.time - cent->gib_start > cl_gibtime.value)
					continue;
				// start to fade away 1 second before cl_gibtime is up
				if (cent->gib_start && cl.time - cent->gib_start > cl_gibtime.value - 1) {
					ent.alpha = cl_gibtime.value - (cl.time - cent->gib_start);
					ent.renderfx |= RF_TRANSLUCENT;
				}
			} else if (cl_gibfilter.value)
				continue;
		}
		else
			cent->gib_start = 0;

		ent.model = model = cl.model_precache[state->modelindex];
		if (!model)
			Host_Error ("CL_LinkPacketEntities: bad modelindex");

		if (cl_r2g.value && cl_grenadeindex != -1)
			if (state->modelindex == cl_rocketindex)
				ent.model = cl.model_precache[cl_grenadeindex];

		// set colormap
		if (state->colormap >= 1 && state->colormap <= MAX_CLIENTS
			&& state->modelindex == cl_playerindex
		)
			ent.colormap = state->colormap;
		else
			ent.colormap = 0;

		// set skin
		ent.skinnum = state->skinnum;
		
		// set frame
		ent.frame = state->frame;

		// decide whether to lerp frames
		if (cent->prevframe != cl_entframecount - 1) {
			// not in previous message
			cent->framelerp_start = 0;
		}
		else if (cent->current.frame != cent->previous.frame) {
//			Com_Printf ("%i -> %i\n", cent->current.frame, cent->previous.frame);
			cent->framelerp_start = cl.time;
			cent->oldframe = cent->previous.frame;
		}
		if (cent->framelerp_start) {
			ent.oldframe = cent->oldframe;
			ent.backlerp = 1 - (cl.time - cent->framelerp_start)*10;
			ent.backlerp = bound (0, ent.backlerp, 1);
//			if (ent.backlerp < 1)
//				Com_Printf ("backlerp %f\n", ent.backlerp);
		}

		modelflags = R_ModelFlags (model);

		//
		// calculate angles
		//
		if (modelflags & MF_ROTATE)
		{	// rotate binary objects locally
			ent.angles[0] = 0;
			ent.angles[1] = autorotate;
			ent.angles[2] = 0;
		}
		else if (cl.modelinfos[state->modelindex] == mi_monster && cl_lerp_monsters.value)
		{
			// monster angles interpolation
			if (cent->prevframe != cl_entframecount - 1) {
				// not in previous message
				cent->monsterlerp_angles_start = 0;
			}
			else {
				for (i=0 ; i<3 ; i++)
					if (cent->current.s_angles[i] != cent->previous.s_angles[i])
						break;
				if (i != 3) {
					cent->monsterlerp_angles_start = cl.time;
					MSG_UnpackAngles (cent->previous.s_angles, cent->monsterlerp_angles);
				}
			}
			if (cent->monsterlerp_angles_start) {
				float backlerp;
				vec3_t	cur;
				backlerp = 1 - (cl.time - cent->monsterlerp_angles_start)*10;
				backlerp = bound (0, backlerp, 1);
				MSG_UnpackAngles (cent->current.s_angles, cur);
				LerpAngles (cur, cent->monsterlerp_angles, backlerp, ent.angles);
			} else {
				MSG_UnpackAngles (cent->current.s_angles, ent.angles);
			}
		}
		else
		{
			// generic angles interpolation
			vec3_t	old, cur;
			MSG_UnpackAngles (cent->previous.s_angles, old);
			MSG_UnpackAngles (cent->current.s_angles, cur);
			LerpAngles (old, cur, f, ent.angles);
		}

		//
		// calculate origin
		//
		if (cl.modelinfos[state->modelindex] == mi_monster && cl_lerp_monsters.value) {
			// monster origin interpolation
			if (cent->prevframe != cl_entframecount - 1) {
				// not in previous message
				cent->monsterlerp_start = 0;
			}
			else {
				for (i=0 ; i<3 ; i++)
					if (cent->current.s_origin[i] != cent->previous.s_origin[i])
						break;
				if (i != 3) {
					cent->monsterlerp_start = cl.time;
					MSG_UnpackOrigin (cent->previous.s_origin, cent->monsterlerp_origin);
				}
			}
			if (cent->monsterlerp_start) {
				float backlerp;
				backlerp = 1 - (cl.time - cent->monsterlerp_start)*10;
				backlerp = bound (0, backlerp, 1);
				LerpVector (cur_origin, cent->monsterlerp_origin, backlerp, ent.origin);
			} else {
				VectorCopy (cur_origin, ent.origin);
			}
		}
		else {
			// generic origin interpolation
			for (i=0 ; i<3 ; i++)
				ent.origin[i] = cent->previous.s_origin[i] * 0.125 + 
					f * (cur_origin[i] - cent->previous.s_origin[i] * 0.125);
		}

		// add automatic particle trails
		if (modelflags & ~MF_ROTATE)
		{
			VectorCopy (cent->trail_origin, old_origin);

			for (i=0 ; i<3 ; i++)
				if (abs(old_origin[i] - ent.origin[i]) > 128)
				{	// no trail if too far
					VectorCopy (ent.origin, old_origin);
					break;
				}

			if (modelflags & MF_ROCKET)
			{
				if (r_rockettrail.value) {
					if (r_rockettrail.value == 2)
						CL_GrenadeTrail (old_origin, ent.origin, cent->trail_origin);
					else
						CL_RocketTrail (old_origin, ent.origin, cent->trail_origin);
				} else
					VectorCopy (ent.origin, cent->trail_origin);

				if (r_rocketlight.value)
					CL_NewDlight (state->number, ent.origin, 200, 0.1, lt_rocket);
			}
			else if (modelflags & MF_GRENADE && r_grenadetrail.value)
				CL_GrenadeTrail (old_origin, ent.origin, cent->trail_origin);
			else if (modelflags & MF_GIB)
				CL_BloodTrail (old_origin, ent.origin, cent->trail_origin);
			else if (modelflags & MF_ZOMGIB)
				CL_SlightBloodTrail (old_origin, ent.origin, cent->trail_origin);
			else if (modelflags & MF_TRACER)
				CL_TracerTrail (old_origin, ent.origin, cent->trail_origin, 52);
			else if (modelflags & MF_TRACER2)
				CL_TracerTrail (old_origin, ent.origin, cent->trail_origin, 230);
			else if (modelflags & MF_TRACER3)
				CL_VoorTrail (old_origin, ent.origin, cent->trail_origin);
		}

		V_AddEntity (&ent);
	}
}


/*
=========================================================================

NAIL PARSING / LINKING

=========================================================================
*/

#define	MAX_NAILS	32

typedef struct {
	byte	number;
	vec3_t	origin;
	vec3_t	angles;
} nail_t;

static nail_t			cl_nails[MAX_NAILS];

#ifdef MVDPLAY
typedef struct {
	int		newindex;
	int		sequence[2];
	vec3_t	origin[2];
} lerped_nail_t;

static lerped_nail_t	cl_lerped_nails[256];
#endif


void CL_ClearNails (void)
{
#ifdef MVDPLAY
	memset(cl_nails, 0, sizeof(cl_nails));
	memset(cl_lerped_nails, 0, sizeof(cl_lerped_nails));
#endif
}

#ifdef MVDPLAY
void CL_ParseNails (qbool tagged)
#else
void CL_ParsNails (void)
#endif
{
	byte bits[6];
	int i, c, j, num = 0;
	nail_t *pr;

	c = MSG_ReadByte();

	for (i = 0; i < c && cl.num_nails < MAX_NAILS; i++) {
#ifdef MVDPLAY
		num = tagged ? MSG_ReadByte() : 0;
#endif

		for (j = 0; j < 6; j++)
			bits[j] = MSG_ReadByte();

		pr = &cl_nails[cl.num_nails++];

		pr->origin[0] = (( bits[0] + ((bits[1] & 15) << 8)) << 1) - 4096;
		pr->origin[1] = (((bits[1] >> 4) + (bits[2] << 4)) << 1) - 4096;
		pr->origin[2] = ((bits[3] + ((bits[4] & 15) << 8)) << 1) - 4096;
		pr->angles[0] = 360 * (bits[4] >> 4) / 16;
		pr->angles[1] = 360 * bits[5] / 256;

#ifdef MVDPLAY
		if ((pr->number = num)) {
			int newindex = cl_lerped_nails[num].newindex = !cl_lerped_nails[num].newindex;
//@@FIXME			cl_lerped_nails[num].sequence[newindex] = cl.validsequence;
			VectorCopy(pr->origin, cl_lerped_nails[num].origin[newindex]);
		}
#endif
	}
}

static void CL_LinkNails (void)
{
	int i;
	entity_t ent;
	nail_t *pr;
#ifdef MVDPLAY
	float f;
#endif

	memset(&ent, 0, sizeof(entity_t));
	ent.model = cl.model_precache[cl_spikeindex];
	ent.colormap = 0;

#ifdef MVDPLAY
	if (cl.num_snapshots < 2)
		return;
	assert (cl.snapshots[0].servertime > cl.snapshots[1].servertime);
	f = bound(0, (cls.demotime - cl.snapshots[1].servertime) / (cl.snapshots[0].servertime - cl.snapshots[1].servertime), 1);
#endif

	for (i = 0, pr = cl_nails; i < cl.num_nails; i++, pr++)	{
#ifdef MVDPLAY
		int num;
		if ((num = cl_nails[i].number)) {
			lerped_nail_t *lpr = &cl_lerped_nails[num];
			// FIXME
			if (cl.oldparsecount && lpr->sequence[!lpr->newindex] == cl.oldparsecount) {
				LerpVector(lpr->origin[!lpr->newindex], lpr->origin[lpr->newindex], f, ent.origin);
				goto done_origin;
			}
		}
#endif
		VectorCopy(pr->origin, ent.origin);
		goto done_origin;		// suppress warning
done_origin:
		VectorCopy(pr->angles, ent.angles);
		V_AddEntity(&ent);
	}
}

//========================================

#ifdef MVDPLAY

int TranslateFlags(int src)
{
	int dst = 0;

	if (src & DF_EFFECTS)
		dst |= PF_EFFECTS;
	if (src & DF_SKINNUM)
		dst |= PF_SKINNUM;
	if (src & DF_DEAD)
		dst |= PF_DEAD;
	if (src & DF_GIB)
		dst |= PF_GIB;
	if (src & DF_WEAPONFRAME)
		dst |= PF_WEAPONFRAME;
	if (src & DF_MODEL)
		dst |= PF_MODEL;

	return dst;
}


static void MVD_ParsePlayerState (void)
{
	int			flags;
	player_info_t	*info;
	player_state_t	*state, *oldstate;
	static player_state_t dummy;	// all zeroes
	int			num;
	int			i;

	num = MSG_ReadByte ();
	if (num >= MAX_CLIENTS)
		Host_Error ("CL_ParsePlayerState: bad num");

	info = &cl.players[num];

	if (cls.mvd_findtarget && info->stats[STAT_HEALTH] != 0)
	{
		Cam_Lock (num);
		cls.mvd_findtarget = false;
	}

	state = &new_snapshot.playerstate[num];
	new_snapshot.playerstate_valid[num] = true;

	if (!cl.snapshots[0].playerstate_valid[num]) {
		oldstate = &dummy;
	} else {
		// FIXME, info->prevcount?  wtf?
		if (cl.parsecount - info->prevcount >= UPDATE_BACKUP-1)
			oldstate = &dummy;
		else 
//			oldstate = &cl.snapshots[info->prevcount&UPDATE_MASK].playerstate[num];
			// FIXME
			oldstate = &cl.snapshots[0].playerstate[num];
	}

	info->prevcount = cl.parsecount;

	memcpy(state, oldstate, sizeof(player_state_t));

	flags = MSG_ReadShort ();
	state->flags = TranslateFlags(flags);

	state->command.msec = 0;

	state->frame = MSG_ReadByte ();

	state->state_time = cls.realtime;
	state->command.msec = 0;

	for (i=0; i <3; i++)
		if (flags & (DF_ORIGIN << i))
			state->origin[i] = MSG_ReadCoord ();

	for (i=0; i <3; i++)
		if (flags & (DF_ANGLES << i))
			state->command.angles[i] = MSG_ReadAngle16 ();


	if (flags & DF_MODEL)
		state->modelindex = MSG_ReadByte ();
		
	if (flags & DF_SKINNUM)
		state->skinnum = MSG_ReadByte ();
		
	if (flags & DF_EFFECTS)
		state->effects = MSG_ReadByte ();
	
	if (flags & DF_WEAPONFRAME)
		state->weaponframe = MSG_ReadByte ();
		
	VectorCopy (state->command.angles, state->viewangles);
}

#endif	// MVDPLAY


/*
===================
CL_ParsePlayerState
===================
*/
void CL_ParsePlayerState (void)
{
	int			msec;
	int			flags;
	player_info_t	*info;
	player_state_t	*state;
	int			num;
	int			i;

#ifdef MVDPLAY
	if (cls.mvdplayback)
	{
		MVD_ParsePlayerState ();
		return;
	}
#endif

	num = MSG_ReadByte ();
	if (num >= MAX_CLIENTS)
		Host_Error ("CL_ParsePlayerState: bad num");

	info = &cl.players[num];

	state = &new_snapshot.playerstate[num];
	new_snapshot.playerstate_valid[num] = true;

	flags = state->flags = MSG_ReadShort ();

	state->origin[0] = MSG_ReadCoord ();
	state->origin[1] = MSG_ReadCoord ();
	state->origin[2] = MSG_ReadCoord ();

	state->frame = MSG_ReadByte ();

	// the other player's last move was likely some time
	// before the packet was sent out, so accurately track
	// the exact time it was valid at
	if (cls.demoplayback) {
		state->state_time = new_snapshot.servertime;
	} else {
		// FIXME, make sure new_snapshot.sequence is within range
		state->state_time = cl.outpackets[new_snapshot.sequence & SENT_MASK].senttime;
	}
	if (flags & PF_MSEC)
	{
		msec = MSG_ReadByte ();
		state->state_time -= msec*0.001;
	}

	if (flags & PF_COMMAND)
		MSG_ReadDeltaUsercmd (&nullcmd, &state->command, cl.protocol);

	if (cl.z_ext & Z_EXT_VWEP && !(state->flags & PF_GIB))
		state->vw_index = state->command.impulse;
	else
		state->vw_index = 0;

	for (i=0 ; i<3 ; i++)
	{
		if (flags & (PF_VELOCITY1<<i) )
			state->velocity[i] = MSG_ReadShort();
		else
			state->velocity[i] = 0;
	}
	if (flags & PF_MODEL)
		state->modelindex = MSG_ReadByte ();
	else
		state->modelindex = cl_playerindex;

	if (flags & PF_SKINNUM)
		state->skinnum = MSG_ReadByte ();
	else
		state->skinnum = 0;

	if (flags & PF_EFFECTS)
		state->effects = MSG_ReadByte ();
	else
		state->effects = 0;

	if (flags & PF_WEAPONFRAME)
		state->weaponframe = MSG_ReadByte ();
	else
		state->weaponframe = 0;

	if (cl.z_ext & Z_EXT_PM_TYPE)
	{
		int pm_code = (flags >> PF_PMC_SHIFT) & PF_PMC_MASK;

		if (pm_code == PMC_NORMAL || pm_code == PMC_NORMAL_JUMP_HELD) {
			if (flags & PF_DEAD)
				state->pm_type = PM_DEAD;
			else
			{
				state->pm_type = PM_NORMAL;
				state->jump_held = (pm_code == PMC_NORMAL_JUMP_HELD);
			}
		}
		else if (pm_code == PMC_OLD_SPECTATOR)
			state->pm_type = PM_OLD_SPECTATOR;
		else {
			if (cl.z_ext & Z_EXT_PM_TYPE_NEW) {
				if (pm_code == PMC_SPECTATOR)
					state->pm_type = PM_SPECTATOR;
				else if (pm_code == PMC_FLY)
					state->pm_type = PM_FLY;
				else if (pm_code == PMC_NONE)
					state->pm_type = PM_NONE;
				else if (pm_code == PMC_FREEZE)
					state->pm_type = PM_FREEZE;
				else {
					// future extension?
					goto guess_pm_type;
				}
			}
			else {
				// future extension?
				goto guess_pm_type;
			}
		}
	}
	else
	{
guess_pm_type:
		if (cl.players[num].spectator)
			state->pm_type = PM_OLD_SPECTATOR;
		else if (flags & PF_DEAD)
			state->pm_type = PM_DEAD;
		else
			state->pm_type = PM_NORMAL;
	}

	if (cl.z_ext & Z_EXT_PF_ONGROUND)
		state->onground = (flags & PF_ONGROUND) != 0;
	else
		state->onground = false;

	VectorCopy (state->command.angles, state->viewangles);
}


/*
================
CL_AddFlagModels

Called when the CTF flags are set
================
*/
void CL_AddFlagModels (entity_t *ent, int team)
{
	int		i;
	float	f;
	vec3_t	v_forward, v_right;
	entity_t	newent;

	if (cl_flagindex == -1)
		return;

	f = 14;
	if (ent->frame >= 29 && ent->frame <= 40) {
		if (ent->frame >= 29 && ent->frame <= 34) { //axpain
			if      (ent->frame == 29) f = f + 2; 
			else if (ent->frame == 30) f = f + 8;
			else if (ent->frame == 31) f = f + 12;
			else if (ent->frame == 32) f = f + 11;
			else if (ent->frame == 33) f = f + 10;
			else if (ent->frame == 34) f = f + 4;
		} else if (ent->frame >= 35 && ent->frame <= 40) { // pain
			if      (ent->frame == 35) f = f + 2; 
			else if (ent->frame == 36) f = f + 10;
			else if (ent->frame == 37) f = f + 10;
			else if (ent->frame == 38) f = f + 8;
			else if (ent->frame == 39) f = f + 4;
			else if (ent->frame == 40) f = f + 2;
		}
	} else if (ent->frame >= 103 && ent->frame <= 118) {
		if      (ent->frame >= 103 && ent->frame <= 104) f = f + 6;  //nailattack
		else if (ent->frame >= 105 && ent->frame <= 106) f = f + 6;  //light 
		else if (ent->frame >= 107 && ent->frame <= 112) f = f + 7;  //rocketattack
		else if (ent->frame >= 112 && ent->frame <= 118) f = f + 7;  //shotattack
	}

	memset (&newent, 0, sizeof(entity_t));

	newent.model = cl.model_precache[cl_flagindex];
	newent.skinnum = team;
	newent.colormap = 0;

	AngleVectors (ent->angles, v_forward, v_right, NULL);
	v_forward[2] = -v_forward[2]; // reverse z component
	for (i=0 ; i<3 ; i++)
		newent.origin[i] = ent->origin[i] - f*v_forward[i] + 22*v_right[i];
	newent.origin[2] -= 16;

	VectorCopy (ent->angles, newent.angles);
	newent.angles[2] -= 45;

	V_AddEntity (&newent);
}


/*
================
CL_AddVWepModel
================
*/
static qbool CL_AddVWepModel (entity_t *ent, int vw_index)
{
	entity_t	newent;

	if ((unsigned)vw_index >= MAX_VWEP_MODELS)
		return false;

	if (cl.vw_model_name[vw_index] == "-")
		return true;	// empty vwep model

	if (!cl.vw_model_precache[vw_index])
		return false;	// vwep model not present - draw default player.mdl

	// build the weapon entity
	memset (&newent, 0, sizeof(entity_t));
	VectorCopy (ent->origin, newent.origin);
	VectorCopy (ent->angles, newent.angles);
	newent.model = cl.vw_model_precache[vw_index];
	newent.frame = ent->frame;
	newent.oldframe = ent->oldframe;
	newent.backlerp = ent->backlerp;
	newent.skinnum = 0;
	newent.colormap = 0;
	newent.renderfx = RF_PLAYERMODEL;	// not really, but use same lighting rules

	V_AddEntity (&newent);
	return true;
}


/*
=============
CL_LinkPlayers

Create visible entities in the correct position
for all current players
=============
*/
void CL_LinkPlayers (void)
{
	int				i;
	player_info_t	*info;
	player_state_t	*state;
	entity_t		ent;
	centity_t		*cent;
	Snapshot		*snap;
	vec3_t			org;
	float			flicker;

	snap = &cl.snapshots[0];

	memset (&ent, 0, sizeof(entity_t));

	for (i=0, info=cl.players, state=snap->playerstate; i < MAX_CLIENTS;
		i++, info++, state++)
	{
		if (!snap->playerstate_valid[i])
			continue;	// not present in this snapshot

		// spawn light flashes, even ones coming from invisible objects
		if (r_powerupglow.value && !(r_powerupglow.value == 2 && i == Cam_PlayerNum()))
		{
			if (i == Cam_PlayerNum()) {
				// FIXME, this is lagging behind because we moved
				// setting of cl.simorg till after CL_EmitEntities
				VectorCopy (cl.simorg, org);
			} else
				VectorCopy (state->origin, org);

			flicker = r_lightflicker.value ? (rand() & 31) : 10;

			if ((state->effects & (EF_BLUE | EF_RED)) == (EF_BLUE | EF_RED))
				V_AddDlight (i+1, org, 200 + flicker, 0, lt_redblue);
			else if (state->effects & EF_BLUE)
				V_AddDlight (i+1, org, 200 + flicker, 0, lt_blue);
			else if (state->effects & EF_RED)
				V_AddDlight (i+1, org, 200 + flicker, 0, lt_red);
			else if (state->effects & EF_BRIGHTLIGHT) {
				vec3_t	tmp;
				VectorCopy (org, tmp);
				tmp[2] += 16;
				V_AddDlight (i+1, org, 200 + flicker, 0, lt_default);
			}
			else if (state->effects & EF_DIMLIGHT)
				V_AddDlight (i+1, org, 200 + flicker, 0, lt_default);
		}

		if (!state->modelindex)
			continue;

		cent = &cl_entities[i+1];
		cent->previous = cent->current;
		MSG_PackOrigin (state->origin, cent->current.s_origin);

		// the player object never gets added
		if (i == cl.playernum)
			continue;

		if (state->modelindex == cl_playerindex) {
			int f = state->frame;
			if (cl_deadbodyfilter.value == 2 && f >= 41 && f <= 102)
				continue;
			if (cl_deadbodyfilter.value && (f==49 || f==60 || f==69 || f==84 || f==93 || f==102))
				continue;
		}
		
		if (!Cam_DrawPlayer(i))
			continue;

		ent.model = cl.model_precache[state->modelindex];
		if (!ent.model)
			Host_Error ("CL_LinkPlayers: bad modelindex");
		ent.skinnum = state->skinnum;
		ent.frame = state->frame;
		ent.colormap = i + 1;

		if (state->frame != cent->current.frame) {
			cent->framelerp_start = cl.time;
			cent->oldframe = cent->current.frame;
			cent->current.frame = state->frame;
		}
		if (cent->framelerp_start) {
			ent.oldframe = cent->oldframe;
			ent.backlerp = 1 - (cl.time - cent->framelerp_start)*10;
		}

		//
		// angles
		//
		ent.angles[PITCH] = -state->viewangles[PITCH]/3;
		ent.angles[YAW] = state->viewangles[YAW];
		ent.angles[ROLL] = 0;
		ent.angles[ROLL] = V_CalcRoll (ent.angles, state->velocity)*4;

		if (cls.demoplayback)	//@@
			VectorCopy (predicted_players[i].angles, ent.angles);

		// origin
		VectorCopy (predicted_players[i].origin, ent.origin);

		if (state->effects & EF_FLAG1)
			CL_AddFlagModels (&ent, 0);
		else if (state->effects & EF_FLAG2)
			CL_AddFlagModels (&ent, 1);

		if (cl.vwep_enabled && state->vw_index) {
			qbool vwep;
			vwep = CL_AddVWepModel (&ent, state->vw_index);
			if (vwep) {
				if (cl.vw_model_name[0] != "-") {
					ent.model = cl.vw_model_precache[0];
					ent.renderfx = RF_PLAYERMODEL;
					V_AddEntity (&ent);
				} else {
					// server said don't add vwep player model
				}
			}
			else
				V_AddEntity (&ent);
		}
		else
			V_AddEntity (&ent);
	}
}

//======================================================================

/*
===============
CL_SetSolidEntities

Builds all the pmove physents for the current frame
===============
*/
void CL_SetSolidEntities (void)
{
	int		i;
	Snapshot	*frame;
	packet_entities_t	*pak;
	entity_state_t		*state;

	cl.pmove.physents[0].model = cl.clipmodels[1];
	VectorClear (cl.pmove.physents[0].origin);
	cl.pmove.physents[0].info = 0;
	cl.pmove.numphysent = 1;

	frame = &cl.snapshots[0];
	pak = &frame->packet_entities;

	for (i = 0; i < pak->num_entities; i++) {
		state = &pak->entities[i];
		if (!state->modelindex)
			continue;
		if (cl.clipmodels[state->modelindex]) {
			if (cl.pmove.numphysent == MAX_PHYSENTS)
				break;
			cl.pmove.physents[cl.pmove.numphysent].model = cl.clipmodels[state->modelindex];
			MSG_UnpackOrigin (state->s_origin, cl.pmove.physents[cl.pmove.numphysent].origin);
			cl.pmove.numphysent++;
		}
	}

}

#ifdef MVDPLAY

#define ISDEAD(i) ( (i) >=41 && (i) <=102 )

void MVD_InitInterpolation (void)
{
    int		i,j;
    struct predicted_player *pplayer;
    Snapshot	*frame, *oldframe;
    player_state_t	*state, *oldstate;
    vec3_t	dist;

	if (cl.num_snapshots < 2)
		return;

    frame = &cl.snapshots[0];
    oldframe = &cl.snapshots[1];

	assert (cl.snapshots[0].servertime > cl.snapshots[1].servertime);

    // clients
    for (i=0, pplayer = predicted_players, state=frame->playerstate, oldstate=oldframe->playerstate; 
            i < MAX_CLIENTS;
            i++, pplayer++, state++, oldstate++) {

        if (pplayer->predict)
        {
            VectorCopy(pplayer->oldo, oldstate->origin);
            VectorCopy(pplayer->olda, oldstate->command.angles);
        }

        pplayer->predict = false;

        if (cl.mvd_fixangle & 1 << i)
        {
            if (i == cam_curtarget) {
                VectorCopy(cl.viewangles, state->command.angles);
                VectorCopy(cl.viewangles, state->viewangles);
            }

            // no angle interpolation
            VectorCopy(state->command.angles, oldstate->command.angles);

            cl.mvd_fixangle &= ~(1 << i);
            //continue;
        }

		if (!frame->playerstate_valid[i]) {
            continue;	// not present this frame
        }

        if (!oldframe->playerstate_valid[i]) {
            continue;	// not present last frame
        }

        // we don't interpolate ourself if we are spectating
        if (i == cl.playernum) {
            if (cl.spectator)
                continue;
        }

        if (!ISDEAD(state->frame) && ISDEAD(oldstate->frame))
            continue;

        VectorSubtract(state->origin, oldstate->origin, dist);
        if (VectorLength(dist) > 150)
            continue;

        VectorCopy(state->origin, pplayer->oldo);
        VectorCopy(state->command.angles, pplayer->olda);

        pplayer->oldstate = oldstate;
        pplayer->predict = true;

        for (j = 0; j < 3; j++)
            pplayer->vel[j] = (state->origin[j] - oldstate->origin[j]) / (frame->servertime - oldframe->servertime);
    }

}

void MVD_ClearPredict(void)
{
    memset(predicted_players, 0, sizeof(predicted_players));
}

void MVD_Interpolate(void)
{
	int i;
	float f;
	Snapshot	*frame, *oldframe;
	player_state_t *state, *oldstate;
	struct predicted_player *pplayer;

	if (cl.num_snapshots < 2)
		return;

	frame = &cl.snapshots[0];
	oldframe = &cl.snapshots[1];

	assert (frame->servertime > oldframe->servertime);
	f = bound(0, (cls.demotime - oldframe->servertime) / (frame->servertime - oldframe->servertime), 1);

//	Com_Printf ("%f  (%f -> %f)\n", cls.demotime, oldframe->servertime, frame->servertime);

	// interpolate clients
	for (i = 0; i < MAX_CLIENTS; i++) {
		pplayer = &predicted_players[i];
		state = &frame->playerstate[i];
		oldstate = &oldframe->playerstate[i];

		if (pplayer->predict) {
			LerpAngles (oldstate->command.angles, pplayer->olda, f, state->viewangles);
			LerpVector (oldstate->origin, pplayer->oldo, f, state->origin);
			LerpVector (oldstate->velocity, pplayer->oldv, f, state->velocity);
		}
		VectorCopy (state->origin, pplayer->origin);	// For CL_LinkPlayers
	}
}

#endif

void CL_SetUpPlayerPrediction ()
{
	int				i;
	player_state_t	*state;
	Snapshot		*frame;
	struct predicted_player *pplayer;

	frame = &cl.snapshots[0];

	for (i=0, pplayer = predicted_players, state=frame->playerstate; 
		i < MAX_CLIENTS;
		i++, pplayer++, state++) {

		pplayer->active = false;

		if (!frame->playerstate_valid[i])
			continue;	// not present this frame

		if (!state->modelindex)
			continue;

		pplayer->active = true;
		pplayer->flags = state->flags;
		VectorCopy (state->origin, pplayer->origin);
	}
}


void CL_PredictOtherPlayers ()
{
	int				i;
	player_state_t	*state;
	player_state_t	exact;
	double			playertime;
	int				msec;
	Snapshot		*frame;
	int				oldphysent;
	struct predicted_player *pplayer;

	if (!cl_predict_players.value)
		return;

	playertime = cls.realtime - cls.latency + 0.02;
	if (playertime > cls.realtime)
		playertime = cls.realtime;

	frame = &cl.snapshots[0];

	// the local player is special, since he moves locally
	// we use his last predicted postition
	extern player_state_t predicted_state;
	VectorCopy(predicted_state.origin, predicted_players[cl.playernum].origin);

	for (i=0, pplayer = predicted_players, state=frame->playerstate; 
		i < MAX_CLIENTS;
		i++, pplayer++, state++) {

		if (!pplayer->active)
			continue;

		if (i == cl.playernum)
			continue;

		if (state->state_time >= playertime)
			continue;

		// only predict half the move to minimize overruns?
		msec = 1000 * (playertime - state->state_time);
		state->command.msec = min(msec, 255);

		oldphysent = cl.pmove.numphysent;
		CL_SetSolidPlayers (i);
		CL_PredictUsercmd (state, &exact, &state->command);
		cl.pmove.numphysent = oldphysent;
		VectorCopy (exact.origin, pplayer->origin);
	}
}

void CL_LerpPlayers ()
{
	int				i;
	double			playertime;
	Snapshot		*frame, *oldframe;
	float			f;	// lerp frac from old to new
	struct predicted_player *pplayer;
	static float playerlatency;

	playertime = cls.realtime - playerlatency;

	int maxsnaps = min(cl.num_snapshots, 3);
	for (i = 0; i < maxsnaps; i++) {
		if (cl.snapshots[i].servertime <= playertime)
			break;
	}
	if (i == maxsnaps) {
		i = maxsnaps - 1;	// guaranteed to be >= 0 because cl.num_snapshots is always >= 1
		frame = oldframe = &cl.snapshots[i];
	} else {
		oldframe = &cl.snapshots[i];
		frame = &cl.snapshots[max(i - 1, 0)];
	}

	if (frame->servertime - oldframe->servertime > 0)
		f = (playertime - oldframe->servertime) / (frame->servertime - oldframe->servertime);
	else
		f = 0;
	Com_DPrintf ("%i->%i  f = %f\n", oldframe-cl.snapshots, frame-cl.snapshots, f);
	f = bound(0, f, 1);

	// adjust latency
	if (playertime > cl.snapshots[0].servertime) {
		Com_DPrintf ("HIGH clamp\n");
		playerlatency = cls.realtime - cl.snapshots[0].servertime;
	}
	else if (playertime < oldframe->servertime) {
		Com_DPrintf ("   low clamp\n");
		playerlatency = cls.realtime - oldframe->servertime;
	} else {
		// drift towards ideal latency
		float ideal_latency = (frame->servertime - oldframe->servertime) * 1.2;
		if (Cvar_Value("driftlatency") && ideal_latency && playerlatency > ideal_latency)
			playerlatency = max(playerlatency - cls.frametime * 0.05, ideal_latency);
	}

	for (i=0, pplayer = predicted_players; i < MAX_CLIENTS; i++, pplayer++)
	{
		vec3_t viewangles, velocity;

//		if (!pplayer->active)
//			continue;
		if (!frame->playerstate_valid[i]) {
			if (cl.snapshots[0].playerstate_valid[i]) {
				// CL_LinkPlayers uses cl.snapshots[0], so fill in some sane values
				VectorCopy (cl.snapshots[0].playerstate[i].origin, pplayer->origin);
				VectorCopy (cl.snapshots[0].playerstate[i].viewangles, viewangles);
				VectorCopy (cl.snapshots[0].playerstate[i].velocity, velocity);
				goto calc_angles;
			}
			continue;
		}

		player_state_t *state = &frame->playerstate[i];

		if (!cls.demoplayback && i == cl.playernum)
			continue;

		if (!oldframe->playerstate_valid) {
nolerp:
			VectorCopy (state->origin, pplayer->origin);
			VectorCopy (state->viewangles, viewangles);
			VectorCopy (state->velocity, velocity);
		}
		else {
			player_state_t *oldstate = &oldframe->playerstate[i];

			int j;
			for (j = 0; j < 3; j++)
				if (fabs(state->origin[j] - oldstate->origin[j]) > 40)
					break;
			if (j < 3)
				goto nolerp;	// too far

			LerpVector (oldstate->origin, state->origin, f, pplayer->origin);
			LerpAngles (oldstate->viewangles, state->viewangles, f, viewangles);
			LerpVector (oldstate->velocity, state->velocity, f, velocity);
		}

calc_angles:
		pplayer->angles[PITCH] = -viewangles[PITCH]/3;
		pplayer->angles[YAW] = viewangles[YAW];
		pplayer->angles[ROLL] = V_CalcRoll(viewangles, velocity)*4;

		if (i == Cam_PlayerNum()) {
			extern vec3_t predicted_simorg, predicted_simangles;
			VectorCopy (pplayer->origin, predicted_simorg);
			VectorCopy (viewangles, predicted_simangles);
//			VectorCopy (velocity, cl.simvel); ?
		}
	}
}

void CL_PredictAndLerpPlayers ()
{
#ifdef MVDPLAY
	if (cls.mvdplayback && cls.state == ca_active) {
		MVD_Interpolate ();
		return;
	}
#endif

	if (cls.state != ca_active || CL_NetworkStalled() || cls.mvdplayback
	|| cls.nqprotocol)
		return;

	if (cl.spectator || !cl_predict_players.value)
		CL_LerpPlayers ();
	else
		CL_PredictOtherPlayers ();
}

/*
===============
CL_SetSolidPlayers

Builds all the pmove physents for the current frame
Note that CL_SetUpPlayerPrediction() must be called first!
pmove must be setup with world and solid entity hulls before calling
(via CL_PredictMove)
===============
*/
void CL_SetSolidPlayers (int ignore)
{
	int		i;
	extern	vec3_t	player_mins;
	extern	vec3_t	player_maxs;
	struct predicted_player *pplayer;
	physent_t *pent;

	if (!cl_solid_players.value)
		return;

	pent = cl.pmove.physents + cl.pmove.numphysent;

	for (i = 0, pplayer = predicted_players; i < MAX_CLIENTS; i++, pplayer++) {

		if (!pplayer->active)
			continue;	// not present this frame

		if (i == ignore)
			continue;

		if (pplayer->flags & PF_DEAD)
			continue; // dead players aren't solid

		if (cl.pmove.numphysent == MAX_PHYSENTS)
			break;

		pent->model = 0;
		VectorCopy(pplayer->origin, pent->origin);
		VectorCopy(player_mins, pent->mins);
		VectorCopy(player_maxs, pent->maxs);
		cl.pmove.numphysent++;
		pent++;
	}
}


/*
===============
CL_EmitEntities

Builds the visedicts array for cl.time

Made up of: clients, packet_entities, nails, and tents
===============
*/
void CL_EmitEntities (void)
{
	if (cls.state != ca_active || CL_NetworkStalled())
		return;

	V_ClearScene ();

	if (cls.nqprotocol)
		CLNQ_LinkEntities ();
	else {
		CL_LinkPlayers ();
		CL_LinkPacketEntities ();
		CL_LinkNails ();
	}
	CL_LinkDlights ();
	CL_LinkParticles ();

	CL_UpdateTEnts ();
}

void CL_Ents_Init (void)
{
	Cvar_Register (&cl_lerp_monsters);
	Cvar_Register (&r_rocketlight);
	Cvar_Register (&r_rockettrail);
	Cvar_Register (&r_grenadetrail);
	Cvar_Register (&r_powerupglow);
	Cvar_Register (&r_lightflicker);
	Cvar_Register (&cl_deadbodyfilter);
	Cvar_Register (&cl_explosion);
	Cvar_Register (&cl_gibfilter);
	Cvar_Register (&cl_gibtime);
	Cvar_Register (&cl_r2g);
	Cvar_Register (&cl_predict_players);
	Cvar_Register (&cl_solid_players);
	// Just for compatibility with ZQuake 0.14 (remove one day)
	Cmd_AddLegacyCommand ("cl_predictPlayers", "cl_predict_players");
	Cmd_AddLegacyCommand ("cl_solidPlayers", "cl_solid_players");
}
