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
#include "client.h"
#include "pmove.h"

cvar_t	cl_nopred = {"cl_nopred", "0"};
cvar_t	cl_nolerp = {"cl_nolerp", "0"};

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

	VectorCopy (from->origin, cl.pmove.origin);
//	VectorCopy (from->viewangles, pmove.angles);
	VectorCopy (u->angles, cl.pmove.angles);
	VectorCopy (from->velocity, cl.pmove.velocity);

	if (cl.z_ext & Z_EXT_PM_TYPE)
		cl.pmove.jump_msec = 0;
	else
		cl.pmove.jump_msec = from->jump_msec;
	cl.pmove.jump_held = from->jump_held;
	cl.pmove.waterjumptime = from->waterjumptime;
	cl.pmove.pm_type = from->pm_type;
	cl.pmove.onground = from->onground;
	cl.pmove.cmd = *u;
	cl.pmove.wetsuit = (cl.hipnotic && (cl.stats[STAT_ITEMS] & (1<<25)))
		/*HIT_WETSUIT*/	? true : false;

	PM_PlayerMove (&cl.pmove, &cl.movevars);

	to->waterjumptime = cl.pmove.waterjumptime;
	to->pm_type = cl.pmove.pm_type;
	to->jump_held = cl.pmove.jump_held;
	to->jump_msec = cl.pmove.jump_msec;
	cl.pmove.jump_msec = 0;

	VectorCopy (cl.pmove.origin, to->origin);
	VectorCopy (cl.pmove.angles, to->viewangles);
	VectorCopy (cl.pmove.velocity, to->velocity);
	to->onground = cl.pmove.onground;

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
	if (cl.spectator && cam_curtarget == CAM_NOTARGET) {
		cl.onground = false;	// in air
		cl.waterlevel = 0;
		return;
	}
	VectorClear (cl.pmove.velocity);
	VectorCopy (cl.simorg, cl.pmove.origin);
	cl.pmove.numtouch = 0;
	PM_CategorizePosition (&cl.pmove);
	cl.onground = cl.pmove.onground;
	cl.waterlevel = cl.pmove.waterlevel;
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

vec3_t predicted_simorg;
vec3_t predicted_simangles;
player_state_t predicted_state;


static void CL_LerpViewPlayer (qbool demo)
{	
	static double playerlatency = 0.01;
	float	simtime;
	int		from, to;
	extern cvar_t cl_nolerp;

	if (cl_nolerp.value || cls.netchan.outgoing_sequence < 3) {
		VectorCopy (predicted_simorg, cl.simorg);
		if (demo)
			VectorCopy(cl.outpackets[(cls.netchan.outgoing_sequence-1)&SENT_MASK].demo_angles,
				cl.simangles);
		return;
	}
	
	double basetime = demo ? cls.demotime : cls.realtime;
	simtime = basetime - playerlatency;

	double	lerp_times[3];
	float	*lerp_origin[3];
	float	*lerp_angles[3];

	int cur = cls.netchan.outgoing_sequence - 1;
	for (int i = 0; i < 3; i++) {
		if (demo)
			lerp_times[i] = cl.outpackets[(cur-i)&SENT_MASK].senttime;
		else
			lerp_times[i] = cl.outpackets[(cur-i)&SENT_MASK].cmdtime_msec * 0.001;
		lerp_origin[i] = cl.outpackets[(cur-i)&SENT_MASK].predicted_origin;
		lerp_angles[i] = cl.outpackets[(cur-i)&SENT_MASK].demo_angles;
	}

	// Adjust latency
	if (simtime > lerp_times[0]) {
		// High clamp
		//Com_DPrintf ("HIGH clamp\n");
		playerlatency = basetime - lerp_times[0];
	}
	else if (simtime < lerp_times[2]) {
		// Low clamp
		//Com_DPrintf ("   low clamp\n");
		playerlatency = basetime - lerp_times[2];
	} 
	else
	{
		// Drift towards ideal latency.
		float ideal_latency = 0;

		if (demo) {
			ideal_latency = (lerp_times[0] - lerp_times[2]) * 0.6;
			if (playerlatency > ideal_latency)
				playerlatency = max(playerlatency - cls.frametime * 0.1, ideal_latency);
		}
		else {
#if 0
			/* 
			FIXME: cmdtime_msec and cls.frametime are not in sync so we shouldn't do this...
			ideal_latency = (lerp_times[0] - lerp_times[2]) * 0.2;	// tune this!
			if (cls.physframe) {
				if (playerlatency > ideal_latency)
					playerlatency = max(playerlatency - cls.frametime * 0.1, ideal_latency);
				
				if (playerlatency < ideal_latency)
					playerlatency = min(playerlatency + cls.frametime * 0.1, ideal_latency);
			}
			*/
#else
			// just drift down till corrected
			if (cls.physframe)
				playerlatency -= min(cls.physframetime * 0.005, 0.001);
#endif
		}
	}

	// decide where to lerp from
	if (simtime > lerp_times[1])
	{
		from = 1;
		to = 0;
	} 
	else 
	{
		from = 2;
		to = 1;
	}

//	outpacket_t *to_p = &cl.outpackets[(cur - to)&SENT_MASK];
//	outpacket_t *from_p = &cl.outpackets[(cur - from)&SENT_MASK];

   	float frac = (simtime - lerp_times[from]) / (lerp_times[to] - lerp_times[from]);
   	frac = bound (0, frac, 1);

	int i;
	for (i = 0; i < 3; i++)
		if (fabs(lerp_origin[to][i] - lerp_origin[from][i]) > 100)
			break;

	if (i < 3) {
		// no lerp
		VectorCopy (lerp_origin[to], cl.simorg);
		if (demo)
			VectorCopy (lerp_angles[to], cl.simangles);
	}
	else {
		LerpVector (lerp_origin[from], lerp_origin[to], frac, cl.simorg);
		if (demo)
			LerpAngles (lerp_angles[from], lerp_angles[to], frac, cl.simangles);
	}
}

/*
** CL_PredictLocalPlayer
** Normal player movement or spectator free fly, on server and in QWD demos
** (QW protocol only)
*/
static void CL_PredictLocalPlayer (void)
{
	qbool		nopred = false;
	int			i;
	Snapshot	*frame;
	int			oldphysent;
	extern cvar_t cl_smartjump;

	if (CL_NetworkStalled())
		return;

	assert(!(cls.netchan.outgoing_sequence - cl.snapshots[0].sequence >= SENT_BACKUP-1));

//	if (cam_track && !cls.demoplayback /* FIXME */)
//		return;

	// this is the last valid frame received from the server
	frame = &cl.snapshots[0];

	// setup cl.simangles + decide whether to predict local player
	if (cls.demoplayback && cl.spectator && cam_curtarget != CAM_NOTARGET) {
		// useless?
		VectorCopy (frame->playerstate[Cam_PlayerNum()].viewangles, predicted_simangles);
		nopred = true;		// FIXME
	} else if (cls.demoplayback) {
		// CL_GetDemoMessage fills in cl.viewangles
		VectorCopy (cl.viewangles, predicted_simangles);
	} else {
		nopred = (cl_nopred.value || cls.netchan.outgoing_sequence - cl.snapshots[0].sequence <= 1);
	}

	if (nopred)
	{
		VectorCopy (frame->playerstate[Cam_PlayerNum()].velocity, cl.simvel);
		VectorCopy (frame->playerstate[Cam_PlayerNum()].origin, predicted_simorg);
		if (cl.z_ext & Z_EXT_PF_ONGROUND) {
			if (cl_smartjump.value)
				CL_CategorizePosition ();	// need to get cl.waterlevel
			cl.onground = frame->playerstate[Cam_PlayerNum()].onground;
		}
		else
			CL_CategorizePosition ();
		return;
	}

	oldphysent = cl.pmove.numphysent;
	CL_SetSolidPlayers (cl.playernum);

	// run frames
	player_state_t state = frame->playerstate[cl.playernum];
	for (i = cl.snapshots[0].sequence + 1; i < cls.netchan.outgoing_sequence; i++)
	{
		outpacket_t *outp = &cl.outpackets[i & SENT_MASK];
		CL_PredictUsercmd (&state, &state, &outp->cmd);
		VectorCopy (state.origin, outp->predicted_origin);
	}

	cl.pmove.numphysent = oldphysent;

	// save results
	predicted_state = state;
	VectorCopy (state.velocity, cl.simvel);
	VectorCopy (state.origin, predicted_simorg);
	cl.onground = cl.pmove.onground;
	cl.waterlevel = cl.pmove.waterlevel;
	if (cl.pmove.landspeed < -650 && !cl.landtime)
		cl.landtime = cl.time;
}

/*
==============
CL_PredictMovement

Predict the local player and other players
==============
*/
void CL_PredictMovement (void)
{
	if (cls.state != ca_active)
		return;

	if (cl.intermission)
		return;

#ifdef MVDPLAY
	if (cls.mvdplayback && cam_curtarget == CAM_NOTARGET)
	{
		player_state_t	state;

		memset (&state, 0, sizeof(state));
		state.pm_type = PM_SPECTATOR;
		VectorCopy (cl.simorg, state.origin);
		VectorCopy (cl.simvel, state.velocity);

		CL_PredictUsercmd (&state, &state, &cl.lastcmd);

		VectorCopy (state.origin, cl.simorg);
		VectorCopy (state.velocity, cl.simvel);
		VectorCopy (cl.viewangles, cl.simangles);
		cl.onground = false;
		return;
	}

	if (cls.mvdplayback)
		return;
#endif

	if (cl.paused)
		return;

	if (cl.spectator && cam_curtarget != CAM_NOTARGET /**/)
		return;

	CL_SetUpPlayerPrediction();
	CL_PredictLocalPlayer ();
//	CL_PredictOtherPlayers ();	// done every display frame to make things smooth
}


void CL_SetViewPosition ()
{
	if (cls.state < ca_active || CL_NetworkStalled())
		return;

	if (cl.intermission) {
		cl.crouch = 0;

		if ((cl.intermission == 2 || cl.intermission == 3) && !cls.nqprotocol)
			// svc_finale and svc_cutscene don't send origin or angles;
			// we expect progs to move the player to the intermission spot
			// and set their angles correctly.  This is unlike qwcl, but
			// QW never used svc_finale so this should't break anything
			VectorCopy (cl.snapshots[0].playerstate[Cam_PlayerNum()].origin, cl.simorg);

		return;
	}

	if (cls.mvdplayback) {
		// if tracking a player, update view position
		if (cam_curtarget != CAM_NOTARGET) {
			player_state_t *state = &cl.snapshots[0].playerstate[cam_curtarget];
			VectorCopy (state->origin, cl.simorg);
			VectorCopy (state->viewangles, cl.simangles);
			// so that we're looking that way when we go into free fly
			VectorCopy (state->viewangles, cl.viewangles);
		}
		return;
	}

	if (cls.nqprotocol) {
		if (!cls.demoplayback)
			VectorCopy (cl.viewangles, cl.simangles);
		// cl.sim* were set in CLNQ_LinkEntities
		return;
	}

//	outpacket_t *outp = &cl.outpackets[cl.snapshots[0].sequence & SENT_MASK];
	if (cls.demoplayback && !(cl.spectator && cam_curtarget != CAM_NOTARGET)) {
		CL_LerpViewPlayer (true);
	}
	else if (cl.spectator && cam_curtarget != CAM_NOTARGET) {
//		player_state_t *state = &cl.snapshots[0].playerstate[cam_curtarget];
//		VectorCopy (state->origin, cl.simorg);
//		VectorCopy (state->viewangles, cl.simangles);
		VectorCopy (predicted_simorg, cl.simorg);
		VectorCopy (predicted_simangles, cl.simangles);
		// so that we're looking that way when we go into free fly
		VectorCopy (cl.simangles, cl.viewangles);
	}
	else {
		// player has the control (normal movement or spectator free fly)
		if (cl_independentPhysics.value)
			CL_LerpViewPlayer (false);
		else
			VectorCopy (predicted_simorg, cl.simorg);
		VectorCopy (cl.viewangles, cl.simangles);
	}

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
	Cvar_Register (&cl_nolerp);
}
