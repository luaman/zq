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
#include "pmove.h"
#include "teamplay.h"

cvar_t	cl_nopred = {"cl_nopred","0"};

/*
==============
CL_PredictUsercmd
==============
*/
void CL_PredictUsercmd (player_state_t *from, player_state_t *to, usercmd_t *u)
{
	// split up very long moves
	if (u->msec > 50)
	{
		player_state_t	temp;
		usercmd_t	split;

		split = *u;
		split.msec /= 2;

		CL_PredictUsercmd (from, &temp, &split);
		CL_PredictUsercmd (&temp, to, &split);
		return;
	}

	VectorCopy (from->origin, pmove.origin);
//	VectorCopy (from->viewangles, pmove.angles);
	VectorCopy (u->angles, pmove.angles);
	VectorCopy (from->velocity, pmove.velocity);

	if (cl.z_ext & Z_EXT_PM_TYPE)
		pmove.jump_msec = 0;
	else
		pmove.jump_msec = from->jump_msec;
	pmove.jump_held = from->jump_held;
	pmove.waterjumptime = from->waterjumptime;
	pmove.pm_type = from->pm_type;
	pmove.cmd = *u;

	movevars.entgravity = cl.entgravity;
	movevars.maxspeed = cl.maxspeed;
	movevars.bunnyspeedcap = cl.bunnyspeedcap;

	PM_PlayerMove ();

	to->waterjumptime = pmove.waterjumptime;
	to->pm_type = pmove.pm_type;
	to->jump_held = pmove.jump_held;
	to->jump_msec = pmove.jump_msec;
	pmove.jump_msec = 0;

	VectorCopy (pmove.origin, to->origin);
	VectorCopy (pmove.angles, to->viewangles);
	VectorCopy (pmove.velocity, to->velocity);
	to->onground = pmove.onground;

	to->weaponframe = from->weaponframe;
}


/*
==================
CL_CategorizePosition

Used when cl_nopred is 1 to determine whether we are on ground,
otherwise stepup smoothing code produces ugly jump physics
==================
*/
void CL_CategorizePosition (void)
{
	if (cl.spectator && cl.playernum == cl.viewplayernum) {
		cl.onground = false;	// in air
		return;
	}
	VectorClear (pmove.velocity);
	VectorCopy (cl.simorg, pmove.origin);
	pmove.numtouch = 0;
	PM_CategorizePosition ();
	cl.onground = pmove.onground;
}


/*
==============
CL_CalcCrouch

Smooth out stair step ups.
Called before CL_EmitEntities so that the player's lightning model
origin is updated properly
==============
*/
void CL_CalcCrouch (void)
{
	static vec3_t	oldorigin;
	static float	oldz;
	static float	extracrouch;
	static float	crouchspeed = 100;
	int	i;

	for (i=0 ; i<3 ; i++)
		if (fabs(cl.simorg[i] - oldorigin[i]) > 40)
			break;

	VectorCopy (cl.simorg, oldorigin);

	if (i < 3) {
		// possibly teleported or respawned
		oldz = cl.simorg[2];
		extracrouch = 0;
		crouchspeed = 100;
		cl.crouch = 0;
		return;
	}

	if (cl.onground && cl.simorg[2] - oldz > 0)
	{
		if (cl.simorg[2] - oldz > 20) {
			// if on steep stairs, increase speed
			if (crouchspeed < 160) {
				extracrouch = cl.simorg[2] - oldz - cls.frametime*200 - 15;
				if (extracrouch > 5)
					extracrouch = 5;
			}
			crouchspeed = 160;
		}
		
		oldz += cls.frametime * crouchspeed;
		if (oldz > cl.simorg[2])
			oldz = cl.simorg[2];
		
		if (cl.simorg[2] - oldz > 15 + extracrouch)
			oldz = cl.simorg[2] - 15 - extracrouch;
		extracrouch -= cls.frametime*200;
		if (extracrouch < 0)
			extracrouch = 0;
		
		cl.crouch = oldz - cl.simorg[2];
	} else {
		// in air or moving down
		oldz = cl.simorg[2];
		cl.crouch += cls.frametime * 150;
		if (cl.crouch > 0)
			cl.crouch = 0;
		crouchspeed = 100;
		extracrouch = 0;
	}
}


/*
==============
CL_PredictMove
==============
*/
void CL_PredictMove (void)
{
	int			i;
	frame_t		*from = NULL, *to;
	int			oldphysent;

	if (cl.paused)
		return;

	if (cl.intermission) {
		cl.crouch = 0;
		return;
	}

	if (!cl.validsequence)
		return;

	if (cls.netchan.outgoing_sequence - cl.validsequence >= UPDATE_BACKUP-1)
		return;

	VectorCopy (cl.viewangles, cl.simangles);

	// this is the last valid frame received from the server
	to = &cl.frames[cl.validsequence & UPDATE_MASK];

	// FIXME...
	if (cls.demoplayback && cl.spectator && cl.viewplayernum != cl.playernum) {
		VectorCopy (to->playerstate[cl.viewplayernum].velocity, cl.simvel);
		VectorCopy (to->playerstate[cl.viewplayernum].origin, cl.simorg);
		VectorCopy (to->playerstate[cl.viewplayernum].viewangles, cl.simangles);
		CL_CategorizePosition ();
		goto out;
	}

	if (cl_nopred.value || cl.validsequence + 1 >= cls.netchan.outgoing_sequence)
	{
		VectorCopy (to->playerstate[cl.playernum].velocity, cl.simvel);
		VectorCopy (to->playerstate[cl.playernum].origin, cl.simorg);
		CL_CategorizePosition ();
		goto out;
	}

	oldphysent = pmove.numphysent;
	CL_SetSolidPlayers (cl.playernum);

	// run frames
	for (i=1 ; i<UPDATE_BACKUP-1 && cl.validsequence+i <
			cls.netchan.outgoing_sequence; i++)
	{
		from = to;
		to = &cl.frames[(cl.validsequence+i) & UPDATE_MASK];
		CL_PredictUsercmd (&from->playerstate[cl.playernum]
			, &to->playerstate[cl.playernum], &to->cmd);
		cl.onground = pmove.onground;
	}

	pmove.numphysent = oldphysent;

	// copy results out for rendering
	VectorCopy (to->playerstate[cl.playernum].velocity, cl.simvel);
	VectorCopy (to->playerstate[cl.playernum].origin, cl.simorg);

out:
	CL_CalcCrouch ();
}


/*
==============
CL_InitPrediction
==============
*/
void CL_InitPrediction (void)
{
	Cvar_Register (&cl_nopred);
}

