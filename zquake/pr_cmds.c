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

#include "server.h"
#include "sv_world.h"


#define	RETURN_EDICT(e) (((int *)pr_globals)[OFS_RETURN] = EDICT_TO_PROG(e))
#define	RETURN_STRING(s) (((int *)pr_globals)[OFS_RETURN] = PR_SetString(s))

// Used when returning a string
// Let us hope it's large enough (no crashes, but result may be truncated)
// Well, QW had 128...
static char	pr_string_temp[512];


/*
===============================================================================

						BUILT-IN FUNCTIONS

===============================================================================
*/

/*
=================
PF_Fixme

Progs attempted to call a non-existent builtin function
=================
*/
static void PF_Fixme (void)
{
	PR_RunError ("unimplemented builtin");
}


// strcat all builtin parms starting with 'first' into a temp buffer
static char *PF_VarString (int first)
{
	int		i;
	static char out[256];
	
	out[0] = 0;
	for (i = first; i < pr_argc; i++)
	{
		strlcat (out, G_STRING((OFS_PARM0 + i*3)), sizeof(out));
	}
	return out;
}


/*
=================
PF_errror

This is a TERMINAL error, which will kill off the entire server.
Dumps self.

error(string s, ...)
=================
*/
static void PF_error (void)
{
	char	*s;
	edict_t	*ed;
	
	s = PF_VarString(0);
	Com_Printf ("======SERVER ERROR in %s:\n%s\n", PR_GetString(pr_xfunction->s_name) ,s);
	ed = PROG_TO_EDICT(pr_global_struct->self);
	ED_Print (ed);

	Host_Error ("Program error");
}

/*
=================
PF_objerror

Dumps out self, then an error message.  The program is aborted and self is
removed, but the level can continue.

objerror(string s, ...)
=================
*/
static void PF_objerror (void)
{
	char	*s;
	edict_t	*ed;
	
	s = PF_VarString(0);
	Com_Printf ("======OBJECT ERROR in %s:\n%s\n", PR_GetString(pr_xfunction->s_name),s);
	ed = PROG_TO_EDICT(pr_global_struct->self);
	ED_Print (ed);
	ED_Free (ed);
	
	Host_Error ("Program error");
}



/*
==============
PF_makevectors

Writes new values for v_forward, v_up, and v_right based on angles
makevectors(vector)
==============
*/
static void PF_makevectors (void)
{
	AngleVectors (G_VECTOR(OFS_PARM0), pr_global_struct->v_forward, pr_global_struct->v_right, pr_global_struct->v_up);
}

/*
=================
PF_setorigin

This is the only valid way to move an object without using the physics of the world (setting velocity and waiting).  Directly changing origin will not set internal links correctly, so clipping would be messed up.  This should be called when an object is spawned, and then only if it is teleported.

setorigin (entity, origin)
=================
*/
static void PF_setorigin (void)
{
	edict_t	*e;
	float	*org;
	
	e = G_EDICT(OFS_PARM0);
	org = G_VECTOR(OFS_PARM1);
	VectorCopy (org, e->v.origin);
	SV_LinkEdict (e, false);
}


/*
=================
PF_setsize

the size box is rotated by the current angle

setsize (entity, minvector, maxvector)
=================
*/
static void PF_setsize (void)
{
	edict_t	*e;
	float	*min, *max;
	
	e = G_EDICT(OFS_PARM0);
	min = G_VECTOR(OFS_PARM1);
	max = G_VECTOR(OFS_PARM2);
	VectorCopy (min, e->v.mins);
	VectorCopy (max, e->v.maxs);
	VectorSubtract (max, min, e->v.size);
	SV_LinkEdict (e, false);
}


/*
=================
PF_setmodel

Also sets size, mins, and maxs for inline bmodels
void setmodel(entity e, string m)
=================
*/
static void PF_setmodel (void)
{
	int			i;
	edict_t		*e;
	char		*m, **check;
	cmodel_t	*mod;

	e = G_EDICT(OFS_PARM0);
	m = G_STRING(OFS_PARM1);

// check to see if model was properly precached
	for (i = 0, check = sv.model_name; i < MAX_MODELS && *check ; i++, check++)
		if (!strcmp(*check, m))
			goto ok;
	PR_RunError ("PF_setmodel: no precache: %s\n", m);
ok:

	e->v.model = G_INT(OFS_PARM1);
	e->v.modelindex = i;

// if it is an inline model, get the size information for it
	if (m[0] == '*') {
		mod = CM_InlineModel (m);
		VectorCopy (mod->mins, e->v.mins);
		VectorCopy (mod->maxs, e->v.maxs);
		VectorSubtract (mod->maxs, mod->mins, e->v.size);
		SV_LinkEdict (e, false);
	}

}

/*
=================
PF_bprint

broadcast print to everyone on server

void bprint(string s, ...)
=================
*/
static void PF_bprint (void)
{
	char		*s;
	int			level;
	
	level = G_FLOAT(OFS_PARM0);

	s = PF_VarString(1);
	SV_BroadcastPrintf (level, "%s", s);
}

/*
=================
PF_sprint

single print to a specific client

void sprint(entity client, float level, string s, ...)
=================
*/
static void PF_sprint (void)
{
	client_t	*cl;
	int			entnum;
	int			level;
	char		*buf, *str;
	int			buflen, len;
	int			i;
	qbool		flush = false, flushboth = false;
	
	entnum = G_EDICTNUM(OFS_PARM0);
	level = G_FLOAT(OFS_PARM1);

	str = PF_VarString(2);
	
	if (entnum < 1 || entnum > MAX_CLIENTS)
	{
		Com_Printf ("tried to sprint to a non-client\n");
		return;
	}
		
	cl = &svs.clients[entnum-1];
	
	buf = cl->sprint_buf;
	buflen = strlen (buf);
	len = strlen (str);

	// flush the buffer if there's not enough space
	// also flush if sprint level has changed
	// or if str is a colored message
	if (len >= sizeof(cl->sprint_buf)
		|| str[0] == 1 || str[0] == 2)		// a colored message
		flushboth = true;
	else if (buflen + len >= sizeof(cl->sprint_buf)
		|| level != cl->sprint_level)
		flush = true;

	if ((flush || flushboth) && buflen) {
		SV_ClientPrintf (cl, cl->sprint_level, "%s", buf);
		buf[0] = 0;
	}

	if (flushboth) {
		SV_ClientPrintf (cl, level, "%s", str);
		return;
	}

	strcat (buf, str);
	cl->sprint_level = level;
	buflen += len;

	// flush complete (\n terminated) strings
	for (i=buflen-1 ; i>=0 ; i--) {
		if (buf[i] == '\n') {
			buf[i] = 0;
			SV_ClientPrintf (cl, cl->sprint_level, "%s\n", buf);
			// move the remainder to buffer beginning
			strcpy (buf, buf + i + 1);
			return;
		}
	}

}


/*
=================
PF_centerprint

single print to a specific client

void centerprint(entity client, string s, ...)
=================
*/
static void PF_centerprint (void)
{
	char		*s;
	int			entnum;
	client_t	*cl;
	
	entnum = G_EDICTNUM(OFS_PARM0);
	s = PF_VarString(1);
	
	if (entnum < 1 || entnum > MAX_CLIENTS)
	{
		Com_Printf ("tried to sprint to a non-client\n");
		return;
	}
		
	cl = &svs.clients[entnum-1];

	ClientReliableWrite_Begin (cl, svc_centerprint);
	ClientReliableWrite_String (s);
	ClientReliableWrite_End ();
}


/*
=================
PF_normalize

vector normalize(vector)
=================
*/
static void PF_normalize (void)
{
	float	*value1;
	vec3_t	newvalue;
	float	new;
	
	value1 = G_VECTOR(OFS_PARM0);

	new = value1[0] * value1[0] + value1[1] * value1[1] + value1[2]*value1[2];
	
	if (new == 0)
		newvalue[0] = newvalue[1] = newvalue[2] = 0;
	else
	{
		new = 1/sqrt(new);
		newvalue[0] = value1[0] * new;
		newvalue[1] = value1[1] * new;
		newvalue[2] = value1[2] * new;
	}
	
	VectorCopy (newvalue, G_VECTOR(OFS_RETURN));	
}

/*
=================
PF_vlen

float vlen(vector v)
=================
*/
static void PF_vlen (void)
{
	float	*value1;
	float	new;
	
	value1 = G_VECTOR(OFS_PARM0);

	new = value1[0] * value1[0] + value1[1] * value1[1] + value1[2]*value1[2];
	
	G_FLOAT(OFS_RETURN) = (new) ? sqrt(new) : 0;
}

/*
=================
PF_vectoyaw

float vectoyaw(vector)
=================
*/
static void PF_vectoyaw (void)
{
	float	*value1;
	float	yaw;
	
	value1 = G_VECTOR(OFS_PARM0);

	if (value1[1] == 0 && value1[0] == 0)
		yaw = 0;
	else
	{
		yaw = atan2(value1[1], value1[0]) * 180 / M_PI;
		if (yaw < 0)
			yaw += 360;
	}

	G_FLOAT(OFS_RETURN) = yaw;
}


/*
=================
PF_vectoangles

vector vectoangles(vector)
=================
*/
static void PF_vectoangles (void)
{
	vectoangles (G_VECTOR(OFS_PARM0), G_VECTOR(OFS_RETURN));
}

/*
=================
PF_Random

Returns a number from 0<= num < 1

random()
=================
*/
static void PF_random (void)
{
	float		num;
		
	num = (rand ()&0x7fff) / ((float)0x7fff);
	
	G_FLOAT(OFS_RETURN) = num;
}


/*
=================
PF_particle

particle(origin, dir, color, count [,replacement_te [,replacement_count]])
=================
*/
static void PF_particle (void)
{
	float	*org, *dir;
	float	color, count;
	int		replacement_te, replacement_count;
			
	org = G_VECTOR(OFS_PARM0);
	dir = G_VECTOR(OFS_PARM1);
	color = G_FLOAT(OFS_PARM2);
	count = G_FLOAT(OFS_PARM3);

	// Progs should provide a tempentity code and particle count for the case
	// when a client doesn't support svc_particle
	if (pr_argc >= 5) {
		replacement_te = G_FLOAT(OFS_PARM4);
		replacement_count = (pr_argc >= 6) ? G_FLOAT(OFS_PARM5) : 1;
	} else {
		// To aid porting of NQ mods, if the extra arguments are not provided, try
		// to figure out what progs want by inspecting color and count
		if (count == 255) {
			replacement_te = TE_EXPLOSION;		// count is not used
		} else if (color == 73) {
			replacement_te = TE_BLOOD;
			replacement_count = 1;	// FIXME: use count / <some value>?
		} else if (color == 225) {
			replacement_te = TE_LIGHTNINGBLOOD;	// count is not used
		} else {
			replacement_te = 0;		// don't send anything
		}
	}

	SV_StartParticle (org, dir, color, count, replacement_te, replacement_count);
}


/*
=================
PF_ambientsound

=================
*/
static void PF_ambientsound (void)
{
	char		**check;
	char		*samp;
	float		*pos;
	float 		vol, attenuation;
	int			i, soundnum;

	pos = G_VECTOR (OFS_PARM0);
	samp = G_STRING(OFS_PARM1);
	vol = G_FLOAT(OFS_PARM2);
	attenuation = G_FLOAT(OFS_PARM3);

// check to see if samp was properly precached
	for (soundnum = 1, check = sv.sound_name + 1;
		soundnum < MAX_SOUNDS && *check;
		check++, soundnum++)
	{
		if (!strcmp(*check, samp))
			break;
	}
			
	if (!*check)
	{
		Com_Printf ("no precache: %s\n", samp);
		return;
	}

// add an svc_spawnambient command to the level signon packet
	MSG_WriteByte (&sv.signon, svc_spawnstaticsound);
	for (i = 0; i < 3; i++)
		MSG_WriteCoord (&sv.signon, pos[i]);
	MSG_WriteByte (&sv.signon, soundnum);
	MSG_WriteByte (&sv.signon, vol*255);
	MSG_WriteByte (&sv.signon, attenuation*64);

}

/*
=================
PF_sound

Each entity can have eight independent sound sources, like voice,
weapon, feet, etc.

Channel 0 is an auto-allocate channel, the others override anything
already running on that entity/channel pair.

An attenuation of 0 will play full volume everywhere in the level.
Larger attenuations will drop off.

=================
*/
static void PF_sound (void)
{
	char		*sample;
	int			channel;
	edict_t		*entity;
	int 		volume;
	float attenuation;
		
	entity = G_EDICT(OFS_PARM0);
	channel = G_FLOAT(OFS_PARM1);
	sample = G_STRING(OFS_PARM2);
	volume = G_FLOAT(OFS_PARM3) * 255;
	attenuation = G_FLOAT(OFS_PARM4);
	
	SV_StartSound (entity, channel, sample, volume, attenuation);
}

/*
=================
PF_debugbreak

debugbreak()
=================
*/
static void PF_debugbreak (void)
{
	assert (false);		// drop to debugger
	PR_RunError ("break statement");	// just in case debugbreak is called in a release build
}

/*
=================
PF_traceline

Used for use tracing and shot targeting.
Traces are blocked by bbox and exact bsp entities, and also slide box entities,
unless nomonsters flag is set.

An entity will also be ignored for testing if ent == ignore,
ent == ignore->owner, or ent->owner == ignore.

void traceline (vector v1, vector v2, float nomonsters, entity ignore)
=================
*/
static void PF_traceline (void)
{
	float	*v1, *v2;
	trace_t	trace;
	int		nomonsters;
	edict_t	*ent;

	v1 = G_VECTOR(OFS_PARM0);
	v2 = G_VECTOR(OFS_PARM1);
	nomonsters = G_FLOAT(OFS_PARM2);
	ent = G_EDICT(OFS_PARM3);

	trace = SV_Trace (v1, vec3_origin, vec3_origin, v2, nomonsters, ent);

	pr_global_struct->trace_allsolid = trace.allsolid;
	pr_global_struct->trace_startsolid = trace.startsolid;
	pr_global_struct->trace_fraction = trace.fraction;
	pr_global_struct->trace_inwater = trace.inwater;
	pr_global_struct->trace_inopen = trace.inopen;
	VectorCopy (trace.endpos, pr_global_struct->trace_endpos);
	VectorCopy (trace.plane.normal, pr_global_struct->trace_plane_normal);
	pr_global_struct->trace_plane_dist =  trace.plane.dist;	
	if (trace.ent)
		pr_global_struct->trace_ent = EDICT_TO_PROG(trace.ent);
	else
		pr_global_struct->trace_ent = EDICT_TO_PROG(sv.edicts);
}

//============================================================================

// Unlike Quake's Mod_LeafPVS, CM_LeafPVS returns a pointer to static data
// uncompressed at load time, so it's safe to store for future use
static byte	*checkpvs;

int PF_newcheckclient (int check)
{
	int		i;
	edict_t	*ent;
	vec3_t	org;

// cycle to the next one

	if (check < 1)
		check = 1;
	if (check > MAX_CLIENTS)
		check = MAX_CLIENTS;

	if (check == MAX_CLIENTS)
		i = 1;
	else
		i = check + 1;

	for ( ;  ; i++)
	{
		if (i == MAX_CLIENTS+1)
			i = 1;

		ent = EDICT_NUM(i);

		if (i == check)
			break;	// didn't find anything else

		if (!ent->inuse)
			continue;
		if (ent->v.health <= 0)
			continue;
		if ((int)ent->v.flags & FL_NOTARGET)
			continue;

	// anything that is a client, or has a client as an enemy
		break;
	}

// get the PVS for the entity
	VectorAdd (ent->v.origin, ent->v.view_ofs, org);
	checkpvs = CM_LeafPVS (CM_PointInLeaf(org));

	return i;
}

/*
=================
PF_checkclient

Returns a client (or object that has a client enemy) that would be a
valid target.

If there are more than one valid options, they are cycled each frame

If (self.origin + self.viewofs) is not in the PVS of the current target,
it is not returned at all.

name checkclient ()
=================
*/
#define	MAX_CHECK	16
static void PF_checkclient (void)
{
	edict_t	*ent, *self;
	int		l;
	vec3_t	vieworg;
	
// find a new check if on a new frame
	if (sv.time - sv.lastchecktime >= 0.1)
	{
		sv.lastcheck = PF_newcheckclient (sv.lastcheck);
		sv.lastchecktime = sv.time;
	}

// return check if it might be visible	
	ent = EDICT_NUM(sv.lastcheck);
	if (!ent->inuse || ent->v.health <= 0)
	{
		RETURN_EDICT(sv.edicts);
		return;
	}

// if current entity can't possibly see the check entity, return 0
	self = PROG_TO_EDICT(pr_global_struct->self);
	VectorAdd (self->v.origin, self->v.view_ofs, vieworg);
	l = CM_Leafnum(CM_PointInLeaf(vieworg)) - 1;
	if ( (l<0) || !(checkpvs[l>>3] & (1<<(l&7)) ) )
	{
		RETURN_EDICT(sv.edicts);
		return;
	}

// might be able to see it
	RETURN_EDICT(ent);
}

//============================================================================


/*
=================
PF_stuffcmd

Sends text over to the client's execution buffer

stuffcmd (clientent, value)
=================
*/
static void PF_stuffcmd (void)
{
	int		entnum;
	client_t	*cl;
	char	*buf, *str;
	int		buflen, newlen;
	int		i;
	
	entnum = G_EDICTNUM(OFS_PARM0);
	if (entnum < 1 || entnum > MAX_CLIENTS)
		PR_RunError ("Parm 0 not a client");
	cl = &svs.clients[entnum-1];
	str = G_STRING(OFS_PARM1);	

	buf = cl->stufftext_buf;

	if (!strcmp(str, "disconnect\n")) {
		// so long and thanks for all the fish
		cl->drop = true;
		buf[0] = 0;
		return;
	}

	buflen = strlen (buf);
	newlen = strlen (str);

	if (buflen + newlen >= MAX_STUFFTEXT-1) {
		// flush the buffer because there's no space left
		if (buflen) {
			ClientReliableWrite_Begin (cl, svc_stufftext);
			ClientReliableWrite_String (buf);
			ClientReliableWrite_End ();
			buf[0] = 0;
		}
		if (newlen >= MAX_STUFFTEXT-1) {
			ClientReliableWrite_Begin (cl, svc_stufftext);
			ClientReliableWrite_String (str);
			ClientReliableWrite_End ();
			return;
		}
	}

	strcat (buf, str);
	buflen += newlen;

	// flush complete (\n terminated) strings
	for (i=buflen-1 ; i>=0 ; i--) {
		if (buf[i] == '\n') {
			ClientReliableWrite_Begin (cl, svc_stufftext);
			ClientReliableWrite_SZ (buf, i+1);
			ClientReliableWrite_Byte (0);
			ClientReliableWrite_End ();

			// move the remainder to buffer beginning
			strcpy (buf, buf + i + 1);
			return;
		}
	}
}


/*
=================
PF_localcmd

Sends text over to the server's execution buffer

localcmd (string)
=================
*/
static void PF_localcmd (void)
{
	char	*str;
	
	str = G_STRING(OFS_PARM0);	
	Cbuf_AddText (str);
}

/*
=================
PF_cvar

float cvar (string)
=================
*/
static void PF_cvar (void)
{
	char	*str;
	
	str = G_STRING(OFS_PARM0);

	if (!strcmp(str, "pr_checkextension")) {
		// we do support PF_checkextension
		G_FLOAT(OFS_RETURN) = 1;
		return;
	}

	G_FLOAT(OFS_RETURN) = Cvar_VariableValue (str);
}

/*
=================
PF_cvar_set

float cvar (string)
=================
*/
static void PF_cvar_set (void)
{
	char	*var_name, *val;
	cvar_t	*var;

	var_name = G_STRING(OFS_PARM0);
	val = G_STRING(OFS_PARM1);

	if (!strcmp(var_name, "pausable")) {
		extern cvar_t sv_pausable;
		// special handling because we renamed the cvar
		Cvar_Set (&sv_pausable, val);
	}

	var = Cvar_FindVar(var_name);
	if (!var)
	{
		Com_DPrintf ("PF_cvar_set: variable %s not found\n", var_name);
		return;
	}

	Cvar_Set (var, val);
}

/*
=================
PF_findradius

Returns a chain of entities that have origins within a spherical area

findradius (origin, radius)
=================
*/
static void PF_findradius (void)
{
	edict_t	*ent, *chain;
	float	rad, rad2;
	float	*org;
	vec3_t	eorg;
	int		i, j;

	chain = (edict_t *)sv.edicts;
	
	org = G_VECTOR(OFS_PARM0);
	rad = G_FLOAT(OFS_PARM1);
	rad2 = rad * rad;

	ent = NEXT_EDICT(sv.edicts);
	for (i=1 ; i<sv.num_edicts ; i++, ent = NEXT_EDICT(ent))
	{
		if (!ent->inuse)
			continue;
		if (ent->v.solid == SOLID_NOT)
			continue;
		for (j=0 ; j<3 ; j++)
			eorg[j] = org[j] - (ent->v.origin[j] + (ent->v.mins[j] + ent->v.maxs[j])*0.5);			
		if (DotProduct(eorg,eorg) > rad2)
			continue;
			
		ent->v.chain = EDICT_TO_PROG(chain);
		chain = ent;
	}

	RETURN_EDICT(chain);
}


/*
=========
PF_dprint
=========
*/
static void PF_dprint (void)
{
	Com_Printf ("%s", PF_VarString(0));
}

static void PF_ftos (void)
{
	float	v;
	int	i;

	v = G_FLOAT(OFS_PARM0);

	if (v == (int)v)
		sprintf (pr_string_temp, "%d", (int)v);
	else
	{
		Q_snprintfz (pr_string_temp, sizeof(pr_string_temp), "%f", v);

		for (i=strlen(pr_string_temp)-1 ; i>0 && pr_string_temp[i]=='0' ; i--)
			pr_string_temp[i] = 0;
		if (pr_string_temp[i] == '.')
			pr_string_temp[i] = 0;
	}

	G_INT(OFS_RETURN) = PR_SetString(pr_string_temp);
}

static void PF_fabs (void)
{
	float	v;
	v = G_FLOAT(OFS_PARM0);
	G_FLOAT(OFS_RETURN) = fabs(v);
}

static void PF_vtos (void)
{
	sprintf (pr_string_temp, "'%5.1f %5.1f %5.1f'", G_VECTOR(OFS_PARM0)[0], G_VECTOR(OFS_PARM0)[1], G_VECTOR(OFS_PARM0)[2]);
	G_INT(OFS_RETURN) = PR_SetString(pr_string_temp);
}

static void PF_Spawn (void)
{
	edict_t	*ed;
	ed = ED_Alloc();
	RETURN_EDICT(ed);
}

static void PF_Remove (void)
{
	edict_t	*ed;
	int		num;

	ed = G_EDICT(OFS_PARM0);

	num = NUM_FOR_EDICT(ed);
	if (num >= 0 && num <= MAX_CLIENTS)
		return;		// world and clients cannot be removed

	ED_Free (ed);
}


// entity (entity start, .string field, string match) find = #5;
static void PF_Find (void)
{
	int		e;	
	int		f;
	char	*s, *t;
	edict_t	*ed;
	
	e = G_EDICTNUM(OFS_PARM0);
	f = G_INT(OFS_PARM1);
	s = G_STRING(OFS_PARM2);
	if (!s)
		PR_RunError ("PF_Find: bad search string");
		
	for (e++ ; e < sv.num_edicts ; e++)
	{
		ed = EDICT_NUM(e);
		if (!ed->inuse)
			continue;
		t = E_STRING(ed,f);
		if (!t)
			continue;
		if (!strcmp(t,s))
		{
			RETURN_EDICT(ed);
			return;
		}
	}
	
	RETURN_EDICT(sv.edicts);
}

static void PR_CheckEmptyString (char *s)
{
	if (s[0] <= ' ')
		PR_RunError ("Bad string");
}

static void PF_precache_file (void)
{	// precache_file is only used to copy files with qcc, it does nothing
	G_INT(OFS_RETURN) = G_INT(OFS_PARM0);
}

static void PF_precache_sound (void)
{
	char	*s;
	int		i;
	
	if (sv.state != ss_loading)
		PR_RunError ("PF_Precache_*: Precache can only be done in spawn functions");
		
	s = G_STRING(OFS_PARM0);
	G_INT(OFS_RETURN) = G_INT(OFS_PARM0);
	PR_CheckEmptyString (s);
	
	for (i = 1; i < MAX_SOUNDS; i++)
	{
		if (!sv.sound_name[i]) {
			sv.sound_name[i] = s;
			return;
		}
		if (!strcmp(sv.sound_name[i], s))
			return;
	}
	PR_RunError ("PF_precache_sound: overflow");
}

static void PF_precache_model (void)
{
	char	*s;
	int		i;
	
	if (sv.state != ss_loading)
		PR_RunError ("PF_Precache_*: Precache can only be done in spawn functions");
		
	s = G_STRING(OFS_PARM0);
	G_INT(OFS_RETURN) = G_INT(OFS_PARM0);
	PR_CheckEmptyString (s);

	for (i = 1; i < MAX_MODELS; i++)
	{
		if (!sv.model_name[i]) {
			sv.model_name[i] = s;
			return;
		}
		if (!strcmp(sv.model_name[i], s))
			return;
	}
	PR_RunError ("PF_precache_model: overflow");
}


static void PF_coredump (void)
{
	ED_PrintEdicts_f ();
}

static void PF_traceon (void)
{
	pr_trace = true;
}

static void PF_traceoff (void)
{
	pr_trace = false;
}

static void PF_eprint (void)
{
	ED_PrintNum (G_EDICTNUM(OFS_PARM0));
}

/*
===============
PF_walkmove

float(float yaw, float dist) walkmove
===============
*/
static void PF_walkmove (void)
{
	edict_t	*ent;
	float	yaw, dist;
	vec3_t	move;
	dfunction_t	*oldf;
	int 	oldself;
	
	ent = PROG_TO_EDICT(pr_global_struct->self);
	yaw = G_FLOAT(OFS_PARM0);
	dist = G_FLOAT(OFS_PARM1);
	
	if ( !( (int)ent->v.flags & (FL_ONGROUND|FL_FLY|FL_SWIM) ) )
	{
		G_FLOAT(OFS_RETURN) = 0;
		return;
	}

	yaw = yaw*M_PI*2 / 360;
	
	move[0] = cos(yaw)*dist;
	move[1] = sin(yaw)*dist;
	move[2] = 0;

// save program state, because SV_movestep may call other progs
	oldf = pr_xfunction;
	oldself = pr_global_struct->self;
	
	G_FLOAT(OFS_RETURN) = SV_movestep(ent, move, true);
	
	
// restore program state
	pr_xfunction = oldf;
	pr_global_struct->self = oldself;
}

/*
===============
PF_droptofloor

void() droptofloor
===============
*/
static void PF_droptofloor (void)
{
	edict_t		*ent;
	vec3_t		end;
	trace_t		trace;
	
	ent = PROG_TO_EDICT(pr_global_struct->self);

	VectorCopy (ent->v.origin, end);
	end[2] -= 256;
	
	trace = SV_Trace (ent->v.origin, ent->v.mins, ent->v.maxs, end, false, ent);

	if (trace.fraction == 1 || trace.allsolid)
		G_FLOAT(OFS_RETURN) = 0;
	else
	{
		VectorCopy (trace.endpos, ent->v.origin);
		SV_LinkEdict (ent, false);
		ent->v.flags = (int)ent->v.flags | FL_ONGROUND;
		ent->v.groundentity = EDICT_TO_PROG(trace.ent);
		G_FLOAT(OFS_RETURN) = 1;
	}
}

/*
===============
PF_lightstyle

void(float style, string value) lightstyle
===============
*/
static void PF_lightstyle (void)
{
	int		style;
	char	*val;
	client_t	*client;
	int			j;
	
	style = G_FLOAT(OFS_PARM0);
	val = G_STRING(OFS_PARM1);

// change the string in sv
	sv.lightstyles[style] = val;
	
// send message to all clients on this server
	if (sv.state != ss_active)
		return;
	
	for (j=0, client = svs.clients ; j<MAX_CLIENTS ; j++, client++)
		if ( client->state == cs_spawned )
		{
			ClientReliableWrite_Begin (client, svc_lightstyle);
			ClientReliableWrite_Char (style);
			ClientReliableWrite_String (val);
			ClientReliableWrite_End ();
		}
}

static void PF_rint (void)
{
	float	f;
	f = G_FLOAT(OFS_PARM0);
	if (f > 0)
		G_FLOAT(OFS_RETURN) = (int)(f + 0.5);
	else
		G_FLOAT(OFS_RETURN) = (int)(f - 0.5);
}
static void PF_floor (void)
{
	G_FLOAT(OFS_RETURN) = floor(G_FLOAT(OFS_PARM0));
}
static void PF_ceil (void)
{
	G_FLOAT(OFS_RETURN) = ceil(G_FLOAT(OFS_PARM0));
}


/*
=============
PF_checkbottom
=============
*/
static void PF_checkbottom (void)
{
	edict_t	*ent;
	
	ent = G_EDICT(OFS_PARM0);

	G_FLOAT(OFS_RETURN) = SV_CheckBottom (ent);
}

/*
=============
PF_pointcontents
=============
*/
static void PF_pointcontents (void)
{
	float	*v;
	
	v = G_VECTOR(OFS_PARM0);

	G_FLOAT(OFS_RETURN) = SV_PointContents (v);	
}

/*
=============
PF_nextent

entity nextent(entity)
=============
*/
static void PF_nextent (void)
{
	int		i;
	edict_t	*ent;
	
	i = G_EDICTNUM(OFS_PARM0);
	while (1)
	{
		i++;
		if (i == sv.num_edicts)
		{
			RETURN_EDICT(sv.edicts);
			return;
		}
		ent = EDICT_NUM(i);
		if (ent->inuse || i <= MAX_CLIENTS /* compatibility */)
		{
			RETURN_EDICT(ent);
			return;
		}
	}
}

/*
=============
PF_aim

Used to pick a vector for the player to shoot along. Now a stub.

vector aim(entity, missilespeed)
=============
*/
static void PF_aim (void)
{
//	ent = G_EDICT(OFS_PARM0);
//	speed = G_FLOAT(OFS_PARM1);
	VectorCopy (pr_global_struct->v_forward, G_VECTOR(OFS_RETURN));
}

/*
==============
PF_changeyaw

This was a major timewaster in progs, so it was converted to C
==============
*/
void PF_changeyaw (void)
{
	edict_t		*ent;
	float		ideal, current, move, speed;
	
	ent = PROG_TO_EDICT(pr_global_struct->self);
	current = anglemod( ent->v.angles[1] );
	ideal = ent->v.ideal_yaw;
	speed = ent->v.yaw_speed;
	
	if (current == ideal)
		return;
	move = ideal - current;
	if (ideal > current)
	{
		if (move >= 180)
			move = move - 360;
	}
	else
	{
		if (move <= -180)
			move = move + 360;
	}
	if (move > 0)
	{
		if (move > speed)
			move = speed;
	}
	else
	{
		if (move < -speed)
			move = -speed;
	}
	
	ent->v.angles[1] = anglemod (current + move);
}

/*
===============================================================================

MESSAGE WRITING

===============================================================================
*/

#define	MSG_BROADCAST	0		// unreliable to all
#define	MSG_ONE			1		// reliable to one (msg_entity)
#define	MSG_ALL			2		// reliable to all
#define	MSG_INIT		3		// write to the init string
#define	MSG_MULTICAST	4		// for multicast()

sizebuf_t *WriteDest (void)
{
	int		dest;
//	int		entnum;
//	edict_t	*ent;

	dest = G_FLOAT(OFS_PARM0);
	switch (dest)
	{
	case MSG_BROADCAST:
		return &sv.datagram;
	
	case MSG_ONE:
		Host_Error("Shouldn't be at MSG_ONE");
#if 0
		ent = PROG_TO_EDICT(pr_global_struct->msg_entity);
		entnum = NUM_FOR_EDICT(ent);
		if (entnum < 1 || entnum > MAX_CLIENTS)
			PR_RunError ("WriteDest: not a client");
		return &svs.clients[entnum-1].netchan.message;
#endif
		
	case MSG_ALL:
		return &sv.reliable_datagram;
	
	case MSG_INIT:
		if (sv.state != ss_loading)
			PR_RunError ("PF_Write_*: MSG_INIT can only be written in spawn functions");
		return &sv.signon;

	case MSG_MULTICAST:
		return &sv.multicast;

	default:
		PR_RunError ("WriteDest: bad destination");
		break;
	}
	
	return NULL;
}

static client_t *Write_GetClient(void)
{
	int		entnum;
	edict_t	*ent;

	ent = PROG_TO_EDICT(pr_global_struct->msg_entity);
	entnum = NUM_FOR_EDICT(ent);
	if (entnum < 1 || entnum > MAX_CLIENTS)
		PR_RunError ("WriteDest: not a client");
	return &svs.clients[entnum-1];
}

// this is an extremely nasty hack
static void CheckIntermission (void)
{
	sizebuf_t *msg = WriteDest();

	if (G_FLOAT(OFS_PARM1) != svc_intermission)
		return;

	if ( (msg->cursize == 2 && msg->data[0] == svc_cdtrack)	/* QW progs send svc_cdtrack first */
		|| msg->cursize == 0  /* just in case */ )
	{
		sv.intermission_running = true;
		sv.intermission_hunt = 1;	// start looking for WriteCoord's
		// prefix the svc_intermission message with an sv.time update
		// to make sure intermission screen has the right value
		MSG_WriteByte (&sv.reliable_datagram, svc_updatestatlong);
		MSG_WriteByte (&sv.reliable_datagram, STAT_TIME);
		MSG_WriteLong (&sv.reliable_datagram, (int)(sv.time * 1000));
	}
}

static void PF_WriteByte (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Byte (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	} else {
		if (G_FLOAT(OFS_PARM0) == MSG_ALL)
			CheckIntermission ();
		MSG_WriteByte (WriteDest(), G_FLOAT(OFS_PARM1));
	}
}

static void PF_WriteChar (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Char (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	} else
		MSG_WriteChar (WriteDest(), G_FLOAT(OFS_PARM1));
}

static void PF_WriteShort (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Short (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	} else
		MSG_WriteShort (WriteDest(), G_FLOAT(OFS_PARM1));
}

static void PF_WriteLong (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Long (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	} else
		MSG_WriteLong (WriteDest(), G_FLOAT(OFS_PARM1));
}

static void PF_WriteAngle (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Angle (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	} else
		MSG_WriteAngle (WriteDest(), G_FLOAT(OFS_PARM1));
}

static void PF_WriteCoord (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Coord (G_FLOAT(OFS_PARM1));
		ClientReliableWrite_End ();
	}
	else
	{
		if (sv.intermission_hunt) {
			sv.intermission_origin[sv.intermission_hunt - 1] = G_FLOAT(OFS_PARM1);
			sv.intermission_hunt++;
			if (sv.intermission_hunt == 4) {
				sv.intermission_origin_valid = true;
				sv.intermission_hunt = 0;
			}
		}

		MSG_WriteCoord (WriteDest(), G_FLOAT(OFS_PARM1));
	}
}

static void PF_WriteString (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_String (G_STRING(OFS_PARM1));
		ClientReliableWrite_End ();
	} else
		MSG_WriteString (WriteDest(), G_STRING(OFS_PARM1));
}


static void PF_WriteEntity (void)
{
	if (G_FLOAT(OFS_PARM0) == MSG_ONE) {
		ClientReliableWrite_Begin0 (Write_GetClient());
		ClientReliableWrite_Short (SV_TranslateEntnum(G_EDICTNUM(OFS_PARM1)));
		ClientReliableWrite_End ();
	} else
		MSG_WriteShort (WriteDest(), SV_TranslateEntnum(G_EDICTNUM(OFS_PARM1)));
}

//=============================================================================

// DP_QC_SINCOSSQRTPOW
// float(float x) sin = #60
static void PF_sin (void)
{
	G_FLOAT(OFS_RETURN) = sin(G_FLOAT(OFS_PARM0));
}

// DP_QC_SINCOSSQRTPOW
// float(float x) cos = #61
static void PF_cos (void)
{
	G_FLOAT(OFS_RETURN) = cos(G_FLOAT(OFS_PARM0));
}

// DP_QC_SINCOSSQRTPOW
// float(float x) sin = #62
static void PF_sqrt (void)
{
	G_FLOAT(OFS_RETURN) = sqrt(G_FLOAT(OFS_PARM0));
}

//=============================================================================

static void PF_makestatic (void)
{
	edict_t	*ent;
	int		i;
	
	ent = G_EDICT(OFS_PARM0);

	MSG_WriteByte (&sv.signon,svc_spawnstatic);

	MSG_WriteByte (&sv.signon, SV_ModelIndex(PR_GetString(ent->v.model)));

	MSG_WriteByte (&sv.signon, ent->v.frame);
	MSG_WriteByte (&sv.signon, ent->v.colormap);
	MSG_WriteByte (&sv.signon, ent->v.skin);
	for (i=0 ; i<3 ; i++)
	{
		MSG_WriteCoord(&sv.signon, ent->v.origin[i]);
		MSG_WriteAngle(&sv.signon, ent->v.angles[i]);
	}

// throw the entity away now
	ED_Free (ent);
}

//=============================================================================

/*
==============
PF_setspawnparms
==============
*/
static void PF_setspawnparms (void)
{
	edict_t	*ent;
	int		i;
	client_t	*client;

	ent = G_EDICT(OFS_PARM0);
	i = NUM_FOR_EDICT(ent);
	if (i < 1 || i > MAX_CLIENTS)
		PR_RunError ("Entity is not a client");

	// copy spawn parms out of the client_t
	client = svs.clients + (i-1);

	for (i=0 ; i< NUM_SPAWN_PARMS ; i++)
		(&pr_global_struct->parm1)[i] = client->spawn_parms[i];
}

/*
==============
PF_changelevel
==============
*/
static void PF_changelevel (void)
{
	char	*s;
	static	int	last_spawncount;

// make sure we don't issue two changelevels
	if (svs.spawncount == last_spawncount)
		return;
	last_spawncount = svs.spawncount;
	
	s = G_STRING(OFS_PARM0);
	Cbuf_AddText (va("map %s\n",s));
}


/*
==============
PF_logfrag

logfrag (killer, killee)
==============
*/
static void PF_logfrag (void)
{
	edict_t	*ent1, *ent2;
	int		e1, e2;
	char	*s;

	ent1 = G_EDICT(OFS_PARM0);
	ent2 = G_EDICT(OFS_PARM1);

	e1 = NUM_FOR_EDICT(ent1);
	e2 = NUM_FOR_EDICT(ent2);
	
	if (e1 < 1 || e1 > MAX_CLIENTS
	|| e2 < 1 || e2 > MAX_CLIENTS)
		return;
	
	s = va("\\%s\\%s\\\n",svs.clients[e1-1].name, svs.clients[e2-1].name);

	SZ_Print (&svs.log[svs.logsequence&1], s);
	if (sv_fraglogfile) {
		fprintf (sv_fraglogfile, s);
		fflush (sv_fraglogfile);
	}
}


/*
==============
PF_infokey

string(entity e, string key) infokey
==============
*/
static void PF_infokey (void)
{
	edict_t	*e;
	int		e1;
	char	*value;
	char	*key;
	static	char ov[256];

	e = G_EDICT(OFS_PARM0);
	e1 = NUM_FOR_EDICT(e);
	key = G_STRING(OFS_PARM1);

	if (e1 == 0) {
		if ((value = Info_ValueForKey (svs.info, key)) == NULL || !*value)
			value = Info_ValueForKey(localinfo, key);
	} else if (e1 <= MAX_CLIENTS) {
		if (!strcmp(key, "ip"))
			value = strcpy(ov, NET_BaseAdrToString (svs.clients[e1-1].netchan.remote_address));
		else if (!strcmp(key, "*z_ext")) {
			sprintf(ov, "%d", svs.clients[e1-1].extensions);
			value = ov;
		} else if (!strcmp(key, "ping")) {
			int ping = SV_CalcPing (&svs.clients[e1-1]);
			sprintf(ov, "%d", ping);
			value = ov;
		} else
			value = Info_ValueForKey (svs.clients[e1-1].userinfo, key);
	} else
		value = "";

	RETURN_STRING(value);
}

/*
==============
PF_stof

float(string s) stof
==============
*/
static void PF_stof (void)
{
	char	*s;

	s = G_STRING(OFS_PARM0);

	G_FLOAT(OFS_RETURN) = atof(s);
}


/*
==============
PF_multicast

void(vector where, float set) multicast
==============
*/
static void PF_multicast (void)
{
	float	*o;
	int		to;

	o = G_VECTOR(OFS_PARM0);
	to = G_FLOAT(OFS_PARM1);

	SV_Multicast (o, to);
}

/*
=================
PF_min

Returns the minimum of two or more floats
float min(float a, float b, ...)
=================
*/
// DP_QC_MINMAXBOUND
void PF_min (void)
{
	int i;
	float min, *f;
	
	min = G_FLOAT(OFS_PARM0);
	for (i = 1, f = &G_FLOAT(OFS_PARM1); i < pr_argc; i++, f += 3) {
		if (*f < min)
			min = *f;
	}

	G_FLOAT(OFS_RETURN) = min;
}

/*
=================
PF_max

Returns the maximum of two or more floats
float max(float a, float b, ...)
=================
*/
// DP_QC_MINMAXBOUND
void PF_max (void)
{
	int i;
	float max, *f;
	
	max = G_FLOAT(OFS_PARM0);
	for (i = 1, f = &G_FLOAT(OFS_PARM1); i < pr_argc; i++, f += 3) {
		if (*f > max)
			max = *f;
	}

	G_FLOAT(OFS_RETURN) = max;
}

/*
=================
PF_bound

Clamp value to supplied range
float bound(float min, float value, float max)
=================
*/
// DP_QC_MINMAXBOUND
void PF_bound (void)
{
	G_FLOAT(OFS_RETURN) = bound(G_FLOAT(OFS_PARM0), G_FLOAT(OFS_PARM1), G_FLOAT(OFS_PARM2));
}


// DP_QC_SINCOSSQRTPOW
// float(float x, float y) pow = #97;
static void PF_pow (void)
{
	G_FLOAT(OFS_RETURN) = pow(G_FLOAT(OFS_PARM0), G_FLOAT(OFS_PARM1));
}


// float(string s) strlen = #114;
static void PF_strlen (void)
{
	G_FLOAT(OFS_RETURN) = strlen(G_STRING(OFS_PARM0));
}

// string(string s1, string s2, ...) stradd = #115; 
static void PF_stradd (void)
{
	int i;

	pr_string_temp[0] = '\0';
	for (i = 0; i < pr_argc; i++)
		strlcat (pr_string_temp, G_STRING(OFS_PARM0 + i * 3), sizeof(pr_string_temp));

	RETURN_STRING(pr_string_temp);
}

// string(string s, float start, float count) substr = #116;
static void PF_substr (void)
{
	int		start, count;
	char	*s;

	s = G_STRING(OFS_PARM0);
	start = (int)G_FLOAT(OFS_PARM1);
	count = (int)G_FLOAT(OFS_PARM2);

	if (start < 0)
		Host_Error ("PF_substr: start < 0");

	if (count <= 0 || strlen(s) <= start) {
		G_INT(OFS_RETURN) = 0;
		return;
	}

	// up to count characters, or until buffer size is exceeded
	strlcpy (pr_string_temp, s + start, min(count + 1, sizeof(pr_string_temp)));

	RETURN_STRING(pr_string_temp);
}


// string(string s) strzone = #118
static void PF_strzone (void)
{
	int i;
	char *s;

	if (pr_argc >= 1)
		s = G_STRING(OFS_PARM0);
	else
		s = "";

	for (i = MAX_PRSTR; i < MAX_PRSTR + MAX_DYN_PRSTR; i++) {
		if (pr_strtbl[i] != pr_strings)
			continue;
		// found an empty slot
		pr_strtbl[i] = Q_strdup(s);
		G_INT(OFS_RETURN) = -i;
		return;
	}

	Host_Error ("PF_strzone: no free strings");
}

// void(string s) strunzone = #119
static void PF_strunzone (void)
{
	int num;

	num = G_INT(OFS_PARM0);
	if (num > -MAX_PRSTR)
		Host_Error ("PF_strunzone: not a dynamic string");

	if (num <= -(MAX_PRSTR + MAX_DYN_PRSTR))
		Host_Error ("PF_strunzone: bad string");

	if (pr_strtbl[-num] == pr_strings)
		return;	// allow multiple strunzone on the same string (like free in C)

	Q_free (pr_strtbl[-num]);
	pr_strtbl[-num] = pr_strings;
}

/*
==============
PF_checkextension

float(string extension) checkextension = #99;
==============
*/
static void PF_checkextension (void)
{
	static char *supported_extensions[] = {
		"DP_HALFLIFE_MAP_CVAR",
		"DP_QC_SINCOSSQRTPOW",
		"DP_QC_MINMAXBOUND",
		"ZQ_QC_CHECKBUILTIN",
		"ZQ_MOVETYPE_NOCLIP",
		"ZQ_MOVETYPE_FLY",
		"ZQ_MOVETYPE_NONE",
		NULL
	};
	char **pstr, *extension;
	extension = G_STRING(OFS_PARM0);

	for (pstr = supported_extensions; *pstr; pstr++) {
		if (!Q_stricmp(*pstr, extension)) {
			G_FLOAT(OFS_RETURN) = 1;	// supported
			return;
		}
	}

	G_FLOAT(OFS_RETURN) = 0;	// not supported
}


// Tonik's experiments -->
static void PF_testbot (void)
{
	edict_t	*ed;
	ed = SV_CreateBot (G_STRING(OFS_PARM0));
	RETURN_EDICT(ed);
}

static void PF_setinfo (void)
{
	int entnum;
	char *key, *value;

	entnum = G_EDICTNUM(OFS_PARM0);

	if (entnum < 1 || entnum > MAX_CLIENTS)
		PR_RunError ("Entity is not a client");

	key = G_STRING(OFS_PARM1);
	value = G_STRING(OFS_PARM2);

	Info_SetValueForKey (svs.clients[entnum-1].userinfo, key, value, MAX_INFO_STRING);

	// FIXME?
	SV_ExtractFromUserinfo (&svs.clients[entnum-1]);

	// FIXME
	MSG_WriteByte (&sv.reliable_datagram, svc_setinfo);
	MSG_WriteByte (&sv.reliable_datagram, entnum - 1);
	MSG_WriteString (&sv.reliable_datagram, key);
	MSG_WriteString (&sv.reliable_datagram, value);
}

static void PF_precache_vwep_model (void)
{
	char	*s;
	int		i;
	
	if (sv.state != ss_loading)
		PR_RunError ("PF_Precache_*: Precache can only be done in spawn functions");
		
	i = G_FLOAT(OFS_PARM0);
	s = G_STRING(OFS_PARM1);
	G_INT(OFS_RETURN) = G_INT(OFS_PARM1);	// FIXME, remove?
	PR_CheckEmptyString (s);

	if (i < 0 || i >= MAX_VWEP_MODELS)
		PR_RunError ("PF_precache_vwep_model: bad index %i", i);

	sv.vw_model_name[i] = s;
}

// <-- Tonik's experiments


static qbool CheckBuiltin (int num)
{
	// check ZQuake builtins
	if (num >= ZQ_BUILTINS && num < ZQ_BUILTINS + pr_numextbuiltins)
		return (pr_extbuiltins[num - ZQ_BUILTINS] != PF_Fixme);

	// check other builtins
	if (num <= 0 || num >= pr_numbuiltins || pr_builtins[num] == PF_Fixme
		// I'm being paranoid here
		|| pr_builtins[num] == PF_testbot
		|| pr_builtins[num] == PF_setinfo
		|| pr_builtins[num] == PF_precache_vwep_model)
	{
		return false;
	}

	return true;
}

/*
==============
PF_checkbuiltin

Check presence of a builtin by number rather than by name
Up to 8 builtins can be checked with one call; result will be 1
only if all supplied builtins are supported.

float(float num, ...) checkbuiltin = #0x5a00;
==============
*/
// ZQ_QC_CHECKBUILTIN
static void PF_checkbuiltin (void)
{
	int i;
	float *f;

	for (i = 0, f = &G_FLOAT(OFS_PARM0); i < pr_argc; i++, f += 3) {
		if (!CheckBuiltin(*f)) {
			G_FLOAT(OFS_RETURN) = 0;
			return;
		}
	}

	G_FLOAT(OFS_RETURN) = 1;
}

/*
==============
PF_checkbuiltinrange

Check a range of builtins by number

float(float start, float num) checkbuiltinrange = #0x5a01;
==============
*/
// ZQ_QC_CHECKBUILTIN
static void PF_checkbuiltinrange (void)
{
	int	i, start, end;

	start = G_FLOAT(OFS_PARM0);
	end = G_FLOAT(OFS_PARM1);

	for (i = start; i < end; i++) {
		if (!CheckBuiltin(i)) {
			G_FLOAT(OFS_RETURN) = 0;
			return;
		}
	}

	G_FLOAT(OFS_RETURN) = 1;
}

/*
==============
PF_maptobuiltin

Turn a function into a builtin.
Ok to call if we're not sure the builtin is present;
0 will be returned then, and the function will not be mapped

float(void() from_func, float to_num) maptobuiltin = #0x5a02;
==============
*/
static void PF_maptobuiltin (void)
{
	int func;
	int	num;

	func = G_FUNCTION(OFS_PARM0);
	num = G_FLOAT(OFS_PARM1);

	if (func <= 0 || func >= progs->numfunctions)
		Host_Error ("PF_mapbuiltin: bad function");

	if (!CheckBuiltin(num)) {
		G_FLOAT(OFS_RETURN) = 0;
		return;
	}

	pr_functions[func].first_statement = -num;

	G_FLOAT(OFS_RETURN) = 1;
}

/*
==============
PF_mapfunction

Maps one function to another function.
Either function can be a normal function or a builtin.
If to_func is a builtin, then the same rules apply as in PF_maptobuiltin:
no mapping is done, and zero is returned

float(void() from_func, void() to_func) mapfunction = #0x5a03;
==============
*/
static void PF_mapfunction (void)
{
	int func1, func2;
	int to_num;

	func1 = G_FUNCTION(OFS_PARM0);
	func2 = G_FUNCTION(OFS_PARM1);

	if (func1 <= 0 || func1 >= progs->numfunctions ||
		func2 <= 0 || func2 >= progs->numfunctions)
		Host_Error ("PF_mapfunction: bad function");

	to_num = pr_functions[func2].first_statement;

	if (to_num < 0 && !CheckBuiltin(-to_num)) {
		G_FLOAT(OFS_RETURN) = 0;
		return;
	}

	if (to_num < 0) {
		// if mapping to a builtin, only copy the number
		pr_functions[func1].first_statement = to_num;
	} else {
		// copy the entire function
		// FIXME: except .profile?
		pr_functions[func1] = pr_functions[func2];
	}

	G_FLOAT(OFS_RETURN) = 1;
}


//=============================================================================

builtin_t pr_builtins[] =
{
PF_Fixme,
PF_makevectors,		// void(entity e) makevectors 			= #1;
PF_setorigin,		// void(entity e, vector o) setorigin	= #2;
PF_setmodel,		// void(entity e, string m) setmodel	= #3;
PF_setsize,			// void(entity e, vector min, vector max) setsize = #4;
PF_Fixme,
PF_debugbreak,		// void() debugbreak					= #6;
PF_random,			// float() random						= #7;
PF_sound,			// void(entity e, float chan, string samp) sound = #8;
PF_normalize,		// vector(vector v) normalize			= #9;
PF_error,			// void(string s, ...) error			= #10;
PF_objerror,		// void(string s, ...) objerror			= #11;
PF_vlen,			// float(vector v) vlen					= #12;
PF_vectoyaw,		// float(vector v) vectoyaw				= #13;
PF_Spawn,			// entity() spawn						= #14;
PF_Remove,			// void(entity e) remove				= #15;
PF_traceline,		// float(vector v1, vector v2, float nomonsters, entity ignore) traceline = #16;
PF_checkclient,		// entity() checkclient					= #17;
PF_Find,			// entity(entity start, .string fld, string match) find = #18;
PF_precache_sound,	// void(string s) precache_sound		= #19;
PF_precache_model,	// void(string s) precache_model		= #20;
PF_stuffcmd,		// void(entity client, string s) stuffcmd = #21;
PF_findradius,		// entity(vector org, float rad) findradius = #22;
PF_bprint,			// void(string s, ...) bprint			= #23;
PF_sprint,			// void(entity client, float level, string s, ...) sprint = #24;
PF_dprint,			// void(string s, ...) dprint			= #25;
PF_ftos,			// void(string s) ftos					= #26;
PF_vtos,			// void(string s) vtos					= #27;
PF_coredump,		// void() coredump						= #28;
PF_traceon,			// void() traceon						= #29;
PF_traceoff,		// void() traceoff						= #30;
PF_eprint,			// void(entity e)						= #31;
PF_walkmove,		// float(float yaw, float dist) walkmove = #32;
PF_Fixme,
PF_droptofloor,
PF_lightstyle,
PF_rint,
PF_floor,
PF_ceil,
PF_Fixme,
PF_checkbottom,
PF_pointcontents,
PF_Fixme,
PF_fabs,
PF_aim,
PF_cvar,
PF_localcmd,
PF_nextent,
PF_particle,
PF_changeyaw,
PF_Fixme,
PF_vectoangles,

PF_WriteByte,
PF_WriteChar,
PF_WriteShort,
PF_WriteLong,
PF_WriteCoord,
PF_WriteAngle,
PF_WriteString,
PF_WriteEntity,

PF_sin,				// float(float x) sin = #60
PF_cos,				// float(float x) cos = #61
PF_sqrt,			// float(float x) sqrt = #62

PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,

SV_MoveToGoal,
PF_precache_file,
PF_makestatic,

PF_changelevel,
PF_Fixme,

PF_cvar_set,
PF_centerprint,		// void(entity client, string s, ...) centerprint = #73;

PF_ambientsound,

PF_precache_model,
PF_precache_sound,		// precache_sound2 is different only for qcc
PF_precache_file,

PF_setspawnparms,

PF_logfrag,

PF_infokey,
PF_stof,
PF_multicast,

PF_testbot,			// !!! Temporary! It will be removed !!!
PF_setinfo,			// !!! Temporary! It will be removed !!!
PF_precache_vwep_model,			// !!! Temporary! It will be removed !!!
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_Fixme,
PF_min,				// float(float a, float b, ...) min					= #94;
PF_max,				// float(float a, float b, ...) max					= #95;
PF_bound,			// float(float min, float value, float max) bound	= #96;
PF_pow,				// float(float x, float y) pow						= #97;
PF_Fixme,
PF_checkextension,	// float(string name) checkextension				= #99;
PF_Fixme,			// #100
PF_Fixme,			// #101
PF_Fixme,			// #102
PF_Fixme,			// #103
PF_Fixme,			// #104
PF_Fixme,			// #105
PF_Fixme,			// #106
PF_Fixme,			// #107
PF_Fixme,			// #108
PF_Fixme,			// #109
PF_Fixme,			// #110
PF_Fixme,			// #111
PF_Fixme,			// #112
PF_Fixme,			// #113
PF_strlen,			// float(string s) strlen							= #114;
PF_stradd,			// string(string s1, string s2, ...) stradd			= #115; 
PF_substr,			// string(string s, float start, float count) substr = #116;
PF_Fixme,			// #117
PF_strzone,			// string(string s) strzone							= #118
PF_strunzone,		// void(string s) strunzone							= #119
};

int pr_numbuiltins = sizeof(pr_builtins)/sizeof(pr_builtins[0]);

void PF_checkbuiltin (void);

builtin_t pr_extbuiltins[] =
{
	PF_checkbuiltin,	// float(float num, ...) checkbuiltin			= #0x5a00;
	PF_checkbuiltinrange, // float(float start, float num) checkbuiltinrange = #0x5a01;
	PF_maptobuiltin,	// float(void() from_func, float to_num) maptobuiltin = #0x5a02;
	PF_mapfunction,		// float(void() from_func, void() to_func) mapfunction = #0x5a03;
};

int pr_numextbuiltins = sizeof(pr_extbuiltins)/sizeof(pr_extbuiltins[0]);

