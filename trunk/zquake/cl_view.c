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
// cl_view.c -- player eye positioning

#include "quakedef.h"
#ifdef GLQUAKE
#include "gl_local.h"
#else
#include "r_local.h"
#endif
#include "pmove.h"

/*

The view is allowed to move slightly from its true position for bobbing,
but if it exceeds 8 pixels linear distance (spherical, not box), the list of
entities sent from the server may not include everything in the pvs, especially
when crossing a water boudnary.

*/

cvar_t	cl_rollspeed = {"cl_rollspeed", "200"};
cvar_t	cl_rollangle = {"cl_rollangle", "2.0"};
cvar_t	cl_bob = {"cl_bob","0.02"};
cvar_t	cl_bobcycle = {"cl_bobcycle","0.6"};
cvar_t	cl_bobup = {"cl_bobup","0.5"};
cvar_t	v_kicktime = {"v_kicktime", "0.5"};
cvar_t	v_kickroll = {"v_kickroll", "0.6"};
cvar_t	v_kickpitch = {"v_kickpitch", "0.6"};
cvar_t	v_gunkick = {"v_gunkick", "0"};

cvar_t	cl_drawgun = {"r_drawviewmodel", "1"};

qboolean Change_v_idle (cvar_t *var, char *value);
cvar_t	v_iyaw_cycle = {"v_iyaw_cycle", "2", 0, Change_v_idle};
cvar_t	v_iroll_cycle = {"v_iroll_cycle", "0.5", 0, Change_v_idle};
cvar_t	v_ipitch_cycle = {"v_ipitch_cycle", "1", 0, Change_v_idle};
cvar_t	v_iyaw_level = {"v_iyaw_level", "0.3", 0, Change_v_idle};
cvar_t	v_iroll_level = {"v_iroll_level", "0.1", 0, Change_v_idle};
cvar_t	v_ipitch_level = {"v_ipitch_level", "0.3", 0, Change_v_idle};
cvar_t	v_idlescale = {"v_idlescale", "0", 0, Change_v_idle};

cvar_t	crosshair = {"crosshair", "2", CVAR_ARCHIVE};
cvar_t	crosshaircolor = {"crosshaircolor", "79", CVAR_ARCHIVE};
cvar_t  cl_crossx = {"cl_crossx", "0", CVAR_ARCHIVE};
cvar_t  cl_crossy = {"cl_crossy", "0", CVAR_ARCHIVE};

cvar_t  v_contentblend = {"v_contentblend", "1"};
cvar_t	v_damagecshift = {"v_damagecshift", "1"};
cvar_t	v_quadcshift = {"v_quadcshift", "1"};
cvar_t	v_suitcshift = {"v_suitcshift", "1"};
cvar_t	v_ringcshift = {"v_ringcshift", "1"};
cvar_t	v_pentcshift = {"v_pentcshift", "1"};
#ifdef GLQUAKE
cvar_t	v_dlightcshift = {"v_dlightcshift", "1"};
#endif

cvar_t	v_bonusflash = {"cl_bonusflash", "1"};

float	v_dmg_time, v_dmg_roll, v_dmg_pitch;

frame_t		*view_frame;
player_state_t		*view_message;


qboolean Change_v_idle (cvar_t *var, char *value)
{
	// Don't allow cheating in TF
	if (cl.teamfortress && cls.state >= ca_connected &&
		cbuf_current != &cbuf_svc)
		return true;
	return false;
}

/*
===============
V_CalcRoll

===============
*/
float V_CalcRoll (vec3_t angles, vec3_t velocity)
{
	vec3_t	right;
	float	sign;
	float	side;
	
	AngleVectors (angles, NULL, right, NULL);
	side = DotProduct (velocity, right);
	sign = side < 0 ? -1 : 1;
	side = fabs(side);
	
	if (side < cl_rollspeed.value)
		side = side * cl_rollangle.value / cl_rollspeed.value;
	else
		side = cl_rollangle.value;

	if (side > 45)
		side = 45;

	return side*sign;
	
}


/*
===============
V_CalcBob

===============
*/
float V_CalcBob (void)
{
	static	double	bobtime;
	static float	bob;
	float	cycle;
	
	if (cl.spectator)
		return 0;

	if (!cl.onground)
		return bob;		// just use old value

	if (!cl_bobcycle.value)
		return 0;

	bobtime += cls.frametime;
	cycle = bobtime - (int)(bobtime/cl_bobcycle.value)*cl_bobcycle.value;
	cycle /= cl_bobcycle.value;
	if (cycle < cl_bobup.value)
		cycle = M_PI * cycle / cl_bobup.value;
	else
		cycle = M_PI + M_PI*(cycle-cl_bobup.value)/(1.0 - cl_bobup.value);

// bob is proportional to simulated velocity in the xy plane
// (don't count Z, or jumping messes it up)

	bob = sqrt(cl.simvel[0]*cl.simvel[0] + cl.simvel[1]*cl.simvel[1]) * cl_bob.value;
	bob = bob*0.3 + bob*0.7*sin(cycle);
	if (bob > 4)
		bob = 4;
	else if (bob < -7)
		bob = -7;
	return bob;
	
}


//=============================================================================


cvar_t	v_centermove = {"v_centermove", "0.15"};
cvar_t	v_centerspeed = {"v_centerspeed","500"};


void V_StartPitchDrift (void)
{
#if 1
	if (cl.laststop == cl.time)
	{
		return;		// something else is keeping it from drifting
	}
#endif
	if (cl.nodrift || !cl.pitchvel)
	{
		cl.pitchvel = v_centerspeed.value;
		cl.nodrift = false;
		cl.driftmove = 0;
	}
}

void V_StopPitchDrift (void)
{
	cl.laststop = cl.time;
	cl.nodrift = true;
	cl.pitchvel = 0;
}

/*
===============
V_DriftPitch

Moves the client pitch angle towards cl.idealpitch sent by the server.

If the user is adjusting pitch manually, either with lookup/lookdown,
mlook and mouse, or klook and keyboard, pitch drifting is constantly stopped.

Drifting is enabled when the center view key is hit, mlook is released and
lookspring is non 0, or when 
===============
*/
void V_DriftPitch (void)
{
	float		delta, move;

	if (!cl.onground || cls.demoplayback)
	{
		cl.driftmove = 0;
		cl.pitchvel = 0;
		return;
	}

// don't count small mouse motion
	if (cl.nodrift)
	{
		if ( fabs(cl.frames[(cls.netchan.outgoing_sequence-1)&UPDATE_MASK].cmd.forwardmove) < 200)
			cl.driftmove = 0;
		else
			cl.driftmove += cls.frametime;
	
		if ( cl.driftmove > v_centermove.value)
		{
			V_StartPitchDrift ();
		}
		return;
	}
	
	delta = 0 - cl.viewangles[PITCH];

	if (!delta)
	{
		cl.pitchvel = 0;
		return;
	}

	move = cls.frametime * cl.pitchvel;
	cl.pitchvel += cls.frametime * v_centerspeed.value;
	
//Com_Printf ("move: %f (%f)\n", move, cls.frametime);

	if (delta > 0)
	{
		if (move > delta)
		{
			cl.pitchvel = 0;
			move = delta;
		}
		cl.viewangles[PITCH] += move;
	}
	else if (delta < 0)
	{
		if (move > -delta)
		{
			cl.pitchvel = 0;
			move = -delta;
		}
		cl.viewangles[PITCH] -= move;
	}
}





/*
============================================================================== 
 
						PALETTE FLASHES 
 
============================================================================== 
*/ 
 
cshift_t	cshift_empty = { {130,80,50}, 0 };
cshift_t	cshift_water = { {130,80,50}, 128 };
cshift_t	cshift_slime = { {0,25,5}, 150 };
cshift_t	cshift_lava = { {255,80,0}, 150 };

#define ONCHANGE(FUNC, VAR)									\
qboolean FUNC (cvar_t *var, char *string) {					\
	Cvar_SetValue (&VAR, Q_atof(string)); return false;	}	\

#ifdef GLQUAKE
ONCHANGE(ch_gamma, gl_gamma)	ONCHANGE(ch_contrast, gl_contrast)
#else
ONCHANGE(ch_gamma, sw_gamma)	ONCHANGE(ch_contrast, sw_contrast)
#endif

cvar_t		gamma = {"gamma", "1", CVAR_ARCHIVE, ch_gamma};
cvar_t		contrast = {"contrast", "1", 0, ch_contrast};


#ifdef	GLQUAKE

ONCHANGE(ch_gl_gamma, gamma)	ONCHANGE(ch_gl_contrast, contrast)

cvar_t		gl_gamma = {"gl_gamma", "1", CVAR_USER_ARCHIVE, ch_gl_gamma};
cvar_t		gl_contrast = {"gl_contrast", "1", CVAR_USER_ARCHIVE, ch_gl_contrast};
cvar_t		gl_cshiftpercent = {"gl_cshiftpercent", "100"};
cvar_t		gl_hwblend = {"gl_hwblend","1"};


float		v_blend[4];		// rgba 0.0 - 1.0
unsigned short	ramps[3][256];

#else

ONCHANGE(ch_sw_gamma, gamma)	ONCHANGE(ch_sw_contrast, contrast)

cvar_t		sw_gamma = {"sw_gamma", "1", CVAR_USER_ARCHIVE, ch_sw_gamma};
cvar_t		sw_contrast = {"sw_contrast", "1", CVAR_USER_ARCHIVE, ch_sw_contrast};

byte		gammatable[256];	// palette is sent through this

byte		current_pal[768];	// Tonik: used for screenshots

#endif




#ifndef GLQUAKE
void BuildGammaTable (float g, float c)
{
	int		i, inf;

	g = bound (0.3, g, 3);
	c = bound (1, c, 3);

	if (g == 1 && c == 1)
	{
		for (i=0 ; i<256 ; i++)
			gammatable[i] = i;
		return;
	}
	
	for (i=0 ; i<256 ; i++)
	{
		inf = 255 * pow ((i+0.5)/255.5*c, g) + 0.5;
		if (inf < 0)
			inf = 0;
		if (inf > 255)
			inf = 255;
		gammatable[i] = inf;
	}
}

/*
=================
V_CheckGamma
=================
*/
qboolean V_CheckGamma (void)
{
	static float old_gamma;
	static float old_contrast;
	
	if (sw_gamma.value == old_gamma && sw_contrast.value == old_contrast)
		return false;
	old_gamma = sw_gamma.value;
	old_contrast = sw_contrast.value;
	
	BuildGammaTable (sw_gamma.value, sw_contrast.value);
	vid.recalc_refdef = 1;				// force a surface cache flush
	
	return true;
}
#endif	// !GLQUAKE


/*
===============
V_ParseDamage
===============
*/
void V_ParseDamage (void)
{
	int		armor, blood;
	vec3_t	from;
	int		i;
	vec3_t	forward, right;
	float	side;
	float	count;
	float	fraction;
	
	armor = MSG_ReadByte ();
	blood = MSG_ReadByte ();
	for (i=0 ; i<3 ; i++)
		from[i] = MSG_ReadCoord ();

	count = blood*0.5 + armor*0.5;
	if (count < 10)
		count = 10;

	cl.faceanimtime = cl.time + 0.2;		// but sbar face into pain frame

	cl.cshifts[CSHIFT_DAMAGE].percent += 3*count;
	if (cl.cshifts[CSHIFT_DAMAGE].percent < 0)
		cl.cshifts[CSHIFT_DAMAGE].percent = 0;
	if (cl.cshifts[CSHIFT_DAMAGE].percent > 150)
		cl.cshifts[CSHIFT_DAMAGE].percent = 150;

	fraction = v_damagecshift.value;
	if (fraction < 0) fraction = 0;
	if (fraction > 1) fraction = 1;
	cl.cshifts[CSHIFT_DAMAGE].percent *= fraction;

	if (armor > blood)		
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 200;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 100;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 100;
	}
	else if (armor)
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 220;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 50;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 50;
	}
	else
	{
		cl.cshifts[CSHIFT_DAMAGE].destcolor[0] = 255;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[1] = 0;
		cl.cshifts[CSHIFT_DAMAGE].destcolor[2] = 0;
	}

//
// calculate view angle kicks
//
	VectorSubtract (from, cl.simorg, from);
	VectorNormalize (from);
	
	AngleVectors (cl.simangles, forward, right, NULL);

	side = DotProduct (from, right);
	v_dmg_roll = count*side*v_kickroll.value;
	
	side = DotProduct (from, forward);
	v_dmg_pitch = count*side*v_kickpitch.value;

	v_dmg_time = v_kicktime.value;
}


/*
==================
V_cshift_f
==================
*/
void V_cshift_f (void)
{
	// don't allow cheating in TF
	if (cls.state >= ca_connected && cl.teamfortress
	&& cbuf_current != &cbuf_svc)
		return;

	cshift_empty.destcolor[0] = atoi(Cmd_Argv(1));
	cshift_empty.destcolor[1] = atoi(Cmd_Argv(2));
	cshift_empty.destcolor[2] = atoi(Cmd_Argv(3));
	cshift_empty.percent = atoi(Cmd_Argv(4));
}


/*
==================
V_BonusFlash_f

When you run over an item, the server sends this command
==================
*/
void V_BonusFlash_f (void)
{
	if (!v_bonusflash.value && cbuf_current == &cbuf_svc)
		return;

	cl.cshifts[CSHIFT_BONUS].destcolor[0] = 215;
	cl.cshifts[CSHIFT_BONUS].destcolor[1] = 186;
	cl.cshifts[CSHIFT_BONUS].destcolor[2] = 69;
	cl.cshifts[CSHIFT_BONUS].percent = 50;
}

/*
=============
V_SetContentsColor

Underwater, lava, etc each has a color shift
=============
*/
void V_SetContentsColor (int contents)
{
	if (!v_contentblend.value) {
		cl.cshifts[CSHIFT_CONTENTS] = cshift_empty;
#ifdef GLQUAKE
		cl.cshifts[CSHIFT_CONTENTS].percent *= 100;
#endif
		return;
	}

	switch (contents)
	{
	case CONTENTS_EMPTY:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_empty;
		break;
	case CONTENTS_LAVA:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_lava;
		break;
	case CONTENTS_SOLID:
	case CONTENTS_SLIME:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_slime;
		break;
	default:
		cl.cshifts[CSHIFT_CONTENTS] = cshift_water;
	}

	if (v_contentblend.value > 0 && v_contentblend.value < 1
		&& contents != CONTENTS_EMPTY)
		cl.cshifts[CSHIFT_CONTENTS].percent *= v_contentblend.value;

#ifdef GLQUAKE
	if (!gl_polyblend.value && !cl.teamfortress)
		cl.cshifts[CSHIFT_CONTENTS].percent = 0;
	else {
		// ignore gl_cshiftpercent on custom cshifts (set with v_cshift
		// command) to avoid cheating in TF
		if (contents != CONTENTS_EMPTY) {
			if (!gl_polyblend.value)
				cl.cshifts[CSHIFT_CONTENTS].percent = 0;
			else
				cl.cshifts[CSHIFT_CONTENTS].percent *= gl_cshiftpercent.value;
		}
		else
			cl.cshifts[CSHIFT_CONTENTS].percent *= 100;
	}

#endif
}

/*
=============
V_CalcPowerupCshift
=============
*/
void V_CalcPowerupCshift (void)
{
	float fraction;

	if (cl.stats[STAT_ITEMS] & IT_QUAD)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 255;
		fraction = bound (0, v_quadcshift.value, 1);
		cl.cshifts[CSHIFT_POWERUP].percent = 30 * fraction;
	}
	else if (cl.stats[STAT_ITEMS] & IT_SUIT)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 0;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 0;
		fraction = bound (0, v_suitcshift.value, 1);
		cl.cshifts[CSHIFT_POWERUP].percent = 20 * fraction;
	}
	else if (cl.stats[STAT_ITEMS] & IT_INVISIBILITY)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 100;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 100;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 100;
		fraction = bound (0, v_ringcshift.value, 1);
		cl.cshifts[CSHIFT_POWERUP].percent = 100 * fraction;
	}
	else if (cl.stats[STAT_ITEMS] & IT_INVULNERABILITY)
	{
		cl.cshifts[CSHIFT_POWERUP].destcolor[0] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[1] = 255;
		cl.cshifts[CSHIFT_POWERUP].destcolor[2] = 0;
		fraction = bound (0, v_pentcshift.value, 1);
		cl.cshifts[CSHIFT_POWERUP].percent = 30 * fraction;
	}
	else
		cl.cshifts[CSHIFT_POWERUP].percent = 0;
}


/*
=============
V_CalcBlend
=============
*/
#ifdef	GLQUAKE
void V_CalcBlend (void)
{
	float	r, g, b, a, a2;
	int		j;

	r = 0;
	g = 0;
	b = 0;
	a = 0;

	if (cls.state != ca_active) {
		cl.cshifts[CSHIFT_CONTENTS] = cshift_empty;
		cl.cshifts[CSHIFT_POWERUP].percent = 0;
	}
	else
		V_CalcPowerupCshift ();

// drop the damage value
	cl.cshifts[CSHIFT_DAMAGE].percent -= cls.frametime*150;
	if (cl.cshifts[CSHIFT_DAMAGE].percent <= 0)
		cl.cshifts[CSHIFT_DAMAGE].percent = 0;

// drop the bonus value
	cl.cshifts[CSHIFT_BONUS].percent -= cls.frametime*100;
	if (cl.cshifts[CSHIFT_BONUS].percent <= 0)
		cl.cshifts[CSHIFT_BONUS].percent = 0;

	for (j=0 ; j<NUM_CSHIFTS ; j++)	
	{
		if ((!gl_cshiftpercent.value || !gl_polyblend.value)
			&& j != CSHIFT_CONTENTS)
			continue;

		if (j == CSHIFT_CONTENTS)
			a2 = cl.cshifts[j].percent / 100.0 / 255.0;
		else
			a2 = ((cl.cshifts[j].percent * gl_cshiftpercent.value) / 100.0) / 255.0;

		if (!a2)
			continue;
		a = a + a2*(1-a);
//Com_Printf ("j:%i a:%f\n", j, a);
		a2 = a2/a;
		r = r*(1-a2) + cl.cshifts[j].destcolor[0]*a2;
		g = g*(1-a2) + cl.cshifts[j].destcolor[1]*a2;
		b = b*(1-a2) + cl.cshifts[j].destcolor[2]*a2;
	}

	v_blend[0] = r/255.0;
	v_blend[1] = g/255.0;
	v_blend[2] = b/255.0;
	v_blend[3] = a;
	if (v_blend[3] > 1)
		v_blend[3] = 1;
	if (v_blend[3] < 0)
		v_blend[3] = 0;
}

void V_AddLightBlend (float r, float g, float b, float a2)
{
	float	a;

	if (!gl_polyblend.value || !gl_cshiftpercent.value || !v_dlightcshift.value)
		return;

	a2 = a2 * bound(0, v_dlightcshift.value, 1) * gl_cshiftpercent.value / 100.0;

	v_blend[3] = a = v_blend[3] + a2*(1-v_blend[3]);

	if (!a)
		return;

	a2 = a2/a;

	v_blend[0] = v_blend[0]*(1-a2) + r*a2;
	v_blend[1] = v_blend[1]*(1-a2) + g*a2;
	v_blend[2] = v_blend[2]*(1-a2) + b*a2;
}
#endif


/*
=============
V_UpdatePalette
=============
*/
#ifdef	GLQUAKE
void V_UpdatePalette (void)
{
	int		i, j;
	qboolean	new;
	static float	prev_blend[4];
	float	a, rgb[3];
	int		c;
	float	gamma, contrast;
	static float	old_gamma, old_contrast, old_hwblend;
	extern float	vid_gamma;

	new = false;

	for (i=0 ; i<4 ; i++) {
		if (v_blend[i] != prev_blend[i]) {
			new = true;
			prev_blend[i] = v_blend[i];
		}
	}

	gamma = bound (0.3, gl_gamma.value, 3);
	if (gamma != old_gamma) {
		old_gamma = gamma;
		new = true;
	}

	contrast = bound (1, gl_contrast.value, 3);
	if (contrast != old_contrast) {
		old_contrast = contrast;
		new = true;
	}

	if (gl_hwblend.value != old_hwblend) {
		new = true;
		old_hwblend = gl_hwblend.value;
	}

	if (!new)
		return;

	a = v_blend[3];

	if (!vid_hwgamma_enabled || !gl_hwblend.value || cl.teamfortress)
		a = 0;

	rgb[0] = 255*v_blend[0]*a;
	rgb[1] = 255*v_blend[1]*a;
	rgb[2] = 255*v_blend[2]*a;

	a = 1-a;

	if (vid_gamma != 1.0) {
		contrast = pow (contrast, vid_gamma);
		gamma = gamma/vid_gamma;
	}

	for (i=0 ; i<256 ; i++)
	{
		for (j=0 ; j<3 ; j++) {
			// apply blend and contrast
			c = (i*a + rgb[j]) * contrast;
			if (c > 255)
				c = 255;
			// apply gamma
			c = 255 * pow((c + 0.5)/255.5, gamma) + 0.5;
			c = bound (0, c, 255);
			ramps[j][i] = c << 8;
		}
	}

	VID_SetDeviceGammaRamp ((unsigned short *) ramps);
}
#else	// !GLQUAKE
/*
=============
V_UpdatePalette
=============
*/
void V_UpdatePalette (void)
{
	int		i, j;
	qboolean	new;
	byte	*basepal, *newpal;
//	byte	pal[768];
	int		r,g,b;
	qboolean force;
	static cshift_t	prev_cshifts[NUM_CSHIFTS];

	if (cls.state != ca_active) {
		cl.cshifts[CSHIFT_CONTENTS] = cshift_empty;
		cl.cshifts[CSHIFT_POWERUP].percent = 0;
	}
	else
		V_CalcPowerupCshift ();
	
	new = false;
	
	for (i=0 ; i<NUM_CSHIFTS ; i++)
	{
		if (cl.cshifts[i].percent != prev_cshifts[i].percent)
		{
			new = true;
			prev_cshifts[i].percent = cl.cshifts[i].percent;
		}
		for (j=0 ; j<3 ; j++)
			if (cl.cshifts[i].destcolor[j] != prev_cshifts[i].destcolor[j])
			{
				new = true;
				prev_cshifts[i].destcolor[j] = cl.cshifts[i].destcolor[j];
			}
	}
	
// drop the damage value
	cl.cshifts[CSHIFT_DAMAGE].percent -= cls.frametime*150;
	if (cl.cshifts[CSHIFT_DAMAGE].percent <= 0)
		cl.cshifts[CSHIFT_DAMAGE].percent = 0;

// drop the bonus value
	cl.cshifts[CSHIFT_BONUS].percent -= cls.frametime*100;
	if (cl.cshifts[CSHIFT_BONUS].percent <= 0)
		cl.cshifts[CSHIFT_BONUS].percent = 0;

	force = V_CheckGamma ();
	if (!new && !force)
		return;
			
	basepal = host_basepal;
//	newpal = pal;
	newpal = current_pal;	// Tonik: so we can use current_pal
							// for screenshots
	
	for (i=0 ; i<256 ; i++)
	{
		r = basepal[0];
		g = basepal[1];
		b = basepal[2];
		basepal += 3;
	
		for (j=0 ; j<NUM_CSHIFTS ; j++)	
		{
			r += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[0]-r))>>8;
			g += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[1]-g))>>8;
			b += (cl.cshifts[j].percent*(cl.cshifts[j].destcolor[2]-b))>>8;
		}
		
		newpal[0] = gammatable[r];
		newpal[1] = gammatable[g];
		newpal[2] = gammatable[b];
		newpal += 3;
	}

	VID_ShiftPalette (current_pal);	
}

#endif	// !GLQUAKE

/* 
============================================================================== 
 
						VIEW RENDERING 
 
============================================================================== 
*/ 

float angledelta (float a)
{
	a = anglemod(a);
	if (a > 180)
		a -= 360;
	return a;
}

/*
==============
V_BoundOffsets
==============
*/
void V_BoundOffsets (void)
{
// absolutely bound refresh relative to entity clipping hull
// so the view can never be inside a solid wall

	if (r_refdef.vieworg[0] < cl.simorg[0] - 14)
		r_refdef.vieworg[0] = cl.simorg[0] - 14;
	else if (r_refdef.vieworg[0] > cl.simorg[0] + 14)
		r_refdef.vieworg[0] = cl.simorg[0] + 14;
	if (r_refdef.vieworg[1] < cl.simorg[1] - 14)
		r_refdef.vieworg[1] = cl.simorg[1] - 14;
	else if (r_refdef.vieworg[1] > cl.simorg[1] + 14)
		r_refdef.vieworg[1] = cl.simorg[1] + 14;
	if (r_refdef.vieworg[2] < cl.simorg[2] - 22)
		r_refdef.vieworg[2] = cl.simorg[2] - 22;
	else if (r_refdef.vieworg[2] > cl.simorg[2] + 30)
		r_refdef.vieworg[2] = cl.simorg[2] + 30;
}

/*
==============
V_AddIdle

Idle swaying
==============
*/
void V_AddIdle (void)
{
	r_refdef.viewangles[ROLL] += v_idlescale.value * sin(cl.time*v_iroll_cycle.value) * v_iroll_level.value;
	r_refdef.viewangles[PITCH] += v_idlescale.value * sin(cl.time*v_ipitch_cycle.value) * v_ipitch_level.value;
	r_refdef.viewangles[YAW] += v_idlescale.value * sin(cl.time*v_iyaw_cycle.value) * v_iyaw_level.value;
}


/*
==============
V_CalcViewRoll

Roll is induced by movement and damage
==============
*/
void V_CalcViewRoll (void)
{
	float	side;
	float	adjspeed;
	
	side = V_CalcRoll (cl.simangles, cl.simvel);
	adjspeed = 20 * bound (2, fabs(cl_rollangle.value), 45);
	if (side > cl.rollangle) {
		cl.rollangle += cls.frametime * adjspeed;
		if (cl.rollangle > side)
			cl.rollangle = side;
	}
	else if (side < cl.rollangle)
	{
		cl.rollangle -= cls.frametime * adjspeed;
		if (cl.rollangle < side)
			cl.rollangle = side;
	}
	r_refdef.viewangles[ROLL] += cl.rollangle;

	if (v_dmg_time > 0)
	{
		r_refdef.viewangles[ROLL] += v_dmg_time/v_kicktime.value*v_dmg_roll;
		r_refdef.viewangles[PITCH] += v_dmg_time/v_kicktime.value*v_dmg_pitch;
		v_dmg_time -= cls.frametime;
	}
}


/*
==================
V_AddViewWeapon
==================
*/
void V_AddViewWeapon (float bob)
{
	vec3_t		forward;
	entity_t	*view;
	extern cvar_t	scr_fov;

	view = &cl.viewent;

	if (!cl_drawgun.value || (cl_drawgun.value == 2 && scr_fov.value > 90)
		|| view_message->flags & (PF_GIB|PF_DEAD)
		|| (cl.stats[STAT_ITEMS] & IT_INVISIBILITY)
		|| (cl.stats[STAT_HEALTH] <= 0)
		|| !Cam_DrawViewModel())
	{
 		view->model = NULL;
		return;
	}

	view->angles[YAW] = r_refdef.viewangles[YAW];
	view->angles[PITCH] = -r_refdef.viewangles[PITCH];
	view->angles[ROLL] = r_refdef.viewangles[ROLL];

	AngleVectors (r_refdef.viewangles, forward, NULL, NULL);
	
	VectorCopy (r_refdef.vieworg, view->origin);
	VectorMA (view->origin, bob * 0.4, forward, view->origin);

	// fudge position around to keep amount of weapon visible
	// roughly equal with different FOV
	if (scr_viewsize.value == 110)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 100)
		view->origin[2] += 2;
	else if (scr_viewsize.value == 90)
		view->origin[2] += 1;
	else if (scr_viewsize.value == 80)
		view->origin[2] += 0.5;

	view->model = cl.model_precache[cl.stats[STAT_WEAPON]];
	view->frame = view_message->weaponframe;
	view->colormap = vid.colormap;
}

/*
==================
V_CalcIntermissionRefdef

==================
*/
void V_CalcIntermissionRefdef (void)
{
	float		old;

	VectorCopy (cl.simorg, r_refdef.vieworg);
	VectorCopy (cl.simangles, r_refdef.viewangles);

// we don't draw weapon in intermission
	cl.viewent.model = NULL;

// always idle in intermission
	old = v_idlescale.value;
	v_idlescale.value = 1;
	V_AddIdle ();
	v_idlescale.value = old;
}

/*
==================
V_CalcRefdef

==================
*/
void V_CalcRefdef (void)
{
	vec3_t		forward;
	float		bob;

	V_DriftPitch ();

	bob = V_CalcBob ();

//	
// set up the refresh position
//
	VectorCopy (cl.simorg, r_refdef.vieworg);

	// never let it sit exactly on a node line, because a water plane can
	// dissapear when viewed with the eye exactly on it.
	// the server protocol only specifies to 1/8 pixel, so add 1/16 in each axis
	r_refdef.vieworg[0] += 1.0/16;
	r_refdef.vieworg[1] += 1.0/16;
	r_refdef.vieworg[2] += 1.0/16;

	// add view height
	if (view_message->flags & PF_GIB)
		r_refdef.vieworg[2] += 8;	// gib view height
	else if (view_message->flags & PF_DEAD)
		r_refdef.vieworg[2] -= 16;	// corpse view height
	else
	{
		r_refdef.vieworg[2] += 22;	// normal view height

		r_refdef.vieworg[2] += bob;

		// smooth out stair step ups
		r_refdef.vieworg[2] += cl.crouch;
	}

//
// set up refresh view angles
//
	VectorCopy (cl.simangles, r_refdef.viewangles);
	V_CalcViewRoll ();
	V_AddIdle ();

	if (v_gunkick.value)
	{
		// add weapon kick offset
		AngleVectors (r_refdef.viewangles, forward, NULL, NULL);
		VectorMA (r_refdef.vieworg, cl.punchangle, forward, r_refdef.vieworg);

		// add weapon kick angle
		r_refdef.viewangles[PITCH] += cl.punchangle * 0.5;
	}

	if (view_message->flags & PF_DEAD)		// PF_GIB will also set PF_DEAD
		r_refdef.viewangles[ROLL] = 80;	// dead view angle

	V_AddViewWeapon (bob);
}

/*
=============
DropPunchAngle
=============
*/
void DropPunchAngle (void)
{
	if (cl.ideal_punchangle < cl.punchangle)
	{
		if (cl.ideal_punchangle == -2)	// small kick
			cl.punchangle -= 20 * cls.frametime;
		else							// big kick
			cl.punchangle -= 40 * cls.frametime;

		if (cl.punchangle < cl.ideal_punchangle)
		{
			cl.punchangle = cl.ideal_punchangle;
			cl.ideal_punchangle = 0;
		}
	}
	else
	{
		cl.punchangle += 20 * cls.frametime;
		if (cl.punchangle > 0)
			cl.punchangle = 0;
	}
}

/*
==================
V_ClearScene
==================
*/
void V_ClearScene (void)
{
	cl_numvisedicts = 0;
	cl_numvisparticles = 0;
}

/*
==================
V_AddEntity
==================
*/
void V_AddEntity (entity_t *ent)
{
	if (cl_numvisedicts >= MAX_VISEDICTS)
		return;
	
	cl_visedicts[cl_numvisedicts++] = *ent;
}

/*
==================
V_AddParticle
==================
*/
void V_AddParticle (vec3_t origin, int color, float alpha)
{
	if (cl_numvisparticles >= MAX_PARTICLES)
		return;
	
	cl_visparticles[cl_numvisparticles].color = color;
	cl_visparticles[cl_numvisparticles].alpha = alpha;
	VectorCopy (origin, cl_visparticles[cl_numvisparticles].org);
	cl_numvisparticles++;
}

/*
==================
V_RenderView

The player's clipping box goes from (-16 -16 -24) to (16 16 32) from
the entity origin, so any view position inside that will be valid
==================
*/
extern vrect_t scr_vrect;

void V_RenderView (void)
{
//	if (cl.simangles[ROLL])
//		Sys_Error ("cl.simangles[ROLL]");	// DEBUG
cl.simangles[ROLL] = 0;	// FIXME @@@ 

	if (cls.state != ca_active) {
#ifdef GLQUAKE
		V_CalcBlend ();
#endif
		return;
	}

	view_frame = &cl.frames[cl.validsequence & UPDATE_MASK];
	view_message = &view_frame->playerstate[cl.viewplayernum];

	DropPunchAngle ();
	if (cl.intermission)
	{	// intermission / finale rendering
		V_CalcIntermissionRefdef ();	
	}
	else
	{
		V_CalcRefdef ();
	}

	R_PushDlights ();

	r_refdef2.time = cl.time;
//	r_refdef2.allowCheats = false;

	R_RenderView ();
}

//============================================================================

/*
=============
V_Init
=============
*/
void V_Init (void)
{
	Cmd_AddCommand ("v_cshift", V_cshift_f);	
	Cmd_AddCommand ("bf", V_BonusFlash_f);
	Cmd_AddCommand ("centerview", V_StartPitchDrift);

	Cvar_Register (&v_centermove);
	Cvar_Register (&v_centerspeed);

	Cvar_Register (&v_idlescale);
	Cvar_Register (&v_iyaw_cycle);
	Cvar_Register (&v_iroll_cycle);
	Cvar_Register (&v_ipitch_cycle);
	Cvar_Register (&v_iyaw_level);
	Cvar_Register (&v_iroll_level);
	Cvar_Register (&v_ipitch_level);

	Cvar_Register (&crosshaircolor);
	Cvar_Register (&crosshair);
	Cvar_Register (&cl_crossx);
	Cvar_Register (&cl_crossy);

	Cvar_Register (&cl_rollspeed);
	Cvar_Register (&cl_rollangle);
	Cvar_Register (&cl_bob);
	Cvar_Register (&cl_bobcycle);
	Cvar_Register (&cl_bobup);
	Cvar_Register (&v_kicktime);
	Cvar_Register (&v_kickroll);
	Cvar_Register (&v_kickpitch);
	Cvar_Register (&v_gunkick);
	Cvar_Register (&cl_drawgun);

	Cvar_Register (&v_bonusflash);
	Cvar_Register (&v_contentblend);
	Cvar_Register (&v_damagecshift);
	Cvar_Register (&v_quadcshift);
	Cvar_Register (&v_suitcshift);
	Cvar_Register (&v_ringcshift);
	Cvar_Register (&v_pentcshift);
#ifdef GLQUAKE
	Cvar_Register (&v_dlightcshift);
#endif

#ifdef GLQUAKE
	Cvar_Register (&gl_gamma);
	Cvar_Register (&gl_contrast);
	Cvar_Register (&gl_cshiftpercent);
	Cvar_Register (&gl_hwblend);
#else
	Cvar_Register (&sw_gamma);
	Cvar_Register (&sw_contrast);
	BuildGammaTable (sw_gamma.value, sw_contrast.value);
#endif

	// gamma and contrast are just shortcuts to sw_ or gl_ equivalents
	// for compatibility and easier access from the console
	Cvar_Register (&gamma);
	Cvar_Register (&contrast);
}
