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
// sv_bot.c -- bot functions

#include "qwsvdef.h"

void SetUpClientEdict (client_t *cl, edict_t *ent);


// called every time when adding a bot or bringing the bot from previous map
void Bot_Spawn_And_Begin (client_t *cl)
{
	int i;
	edict_t	*ent = cl->edict;

	// spawn
	// set colormap, name, entgravity and maxspeed
	SetUpClientEdict (cl, ent);

//=================
	// begin

	cl->state = cs_spawned;

	// copy spawn parms out of the client_t
	for (i=0 ; i< NUM_SPAWN_PARMS ; i++)
		(&pr_global_struct->parm1)[i] = cl->spawn_parms[i];

	// call the spawn function
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	PR_ExecuteProgram (pr_global_struct->ClientConnect);

	// actually spawn the player
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	PR_ExecuteProgram (pr_global_struct->PutClientInServer);
}

edict_t *SV_SpawnBot (char *name, char *team, int topcolor, int bottomcolor)
{
	extern cvar_t	maxclients;
	int			i, numclients;
	client_t	*cl, *newcl;
	edict_t		*ent;

	numclients = 0;
	newcl = NULL;

	for (i = 0, cl = svs.clients; i < MAX_CLIENTS; i++, cl++) {
		if (cl->state == cs_free) {
			if (!newcl)
				newcl = cl;
			continue;
		}
		if (!cl->spectator)
			numclients++;
	}

	if (numclients >= maxclients.value || !newcl)
		return sv.edicts;		// all player spots full, return world

	memset (newcl, 0, sizeof(*newcl));
	newcl->state = cs_connected;
	newcl->bot = true;
	newcl->userid = ++svs.lastuserid;
	newcl->extensions = SUPPORTED_EXTENSIONS;	// bots always use latest ZQuake :-)
	Q_strncpyz (newcl->name, name, sizeof(newcl->name));

	// init a bogus network connection
	SZ_Init (&newcl->datagram, newcl->datagram_buf, sizeof(newcl->datagram_buf));
	newcl->datagram.allowoverflow = true;
	Netchan_Setup (NS_SERVER, &newcl->netchan, net_null, 0);

	Info_SetValueForStarKey (newcl->userinfo, "*bot", "1", MAX_INFO_STRING);
	Info_SetValueForKey (newcl->userinfo, "name", newcl->name, MAX_INFO_STRING);
	Info_SetValueForKey (newcl->userinfo, "team", team, MAX_INFO_STRING);
	Info_SetValueForKey (newcl->userinfo, "topcolor", va("%i", topcolor), MAX_INFO_STRING);
	Info_SetValueForKey (newcl->userinfo, "bottomcolor", va("%i", bottomcolor), MAX_INFO_STRING);

	// set up the edict
	ent = EDICT_NUM((newcl - svs.clients) + 1);
	newcl->edict = ent;

	// call the progs to get default spawn parms for the new client
	PR_ExecuteProgram (pr_global_struct->SetNewParms);
	for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
		newcl->spawn_parms[i] = (&pr_global_struct->parm1)[i];

	Com_DPrintf ("Bot %s connected\n", newcl->name);

	newcl->sendinfo = true;



//=================
	// spawn

	Bot_Spawn_And_Begin (newcl);

	return ent;
}

void SV_RemoveBot (client_t *cl)
{
	if (cl->state == cs_spawned)
		if (!cl->spectator)
		{
			// call the prog function for removing a client
			// this will set the body to a dead frame, among other things
			pr_global_struct->self = EDICT_TO_PROG(cl->edict);
			PR_ExecuteProgram (pr_global_struct->ClientDisconnect);
		}
		else if (SpectatorDisconnect)
		{
			// call the prog function for removing a client
			// this will set the body to a dead frame, among other things
			pr_global_struct->self = EDICT_TO_PROG(cl->edict);
			PR_ExecuteProgram (SpectatorDisconnect);
		}

	Com_DPrintf ("Bot %s removed\n", cl->name);

	cl->state = cs_free;		// we don't have zombie bots :)
	cl->bot = false;
	cl->old_frags = 0;
	cl->edict->v.frags = 0;
	cl->name[0] = 0;
	memset (cl->userinfo, 0, sizeof(cl->userinfo));

// send notification to all remaining clients
	SV_FullClientUpdate (cl, &sv.reliable_datagram);
}


void SV_ReconnectBots (void)
{
	int i;
	client_t *cl;

	for (i = 0, cl = svs.clients; i < MAX_CLIENTS; i++, cl++) {
		if (cl->state == cs_free || !cl->bot)
			continue;

		assert (cl->state == cs_connected);

		Bot_Spawn_And_Begin (cl);
	}
}


void SV_PreRunCmd (void);
void SV_RunCmd (usercmd_t *ucmd);
void SV_PostRunCmd (void);

void SV_RunBots (void)
{
	int			i;
	client_t	*cl;
	edict_t		*ent;
	eval_t		*val;
	usercmd_t	cmd;

	for (i = 0, cl = svs.clients; i < MAX_CLIENTS; i++, cl++) {
		if (!cl->bot || cl->state != cs_spawned)
			continue;

		ent = cl->edict;

		// fake a client move command for prediction's sake
		cmd = nullcmd;
		VectorCopy (ent->v.v_angle, cmd.angles);
		cmd.msec = (svs.realtime - cl->cmdtime) * 1000;
		cl->cmdtime += cmd.msec * 0.001;
		if (cmd.msec > 255)
			cmd.msec = 255;

		// update bogus network stuff
		cl->lastcmd = cmd;
		cl->netchan.last_received = curtime;
		SZ_Clear (&cl->datagram);			// don't overflow
		SZ_Clear (&cl->netchan.message);	// don't overflow

		if (sv.paused)
			continue;

		//
		// run physics
		//
		sv_client = cl;
		sv_player = ent;

		if (BotPreThink) {
			// let the bots decide what they want to do this frame
			pr_global_struct->frametime = cmd.msec * 0.001;
			pr_global_struct->time = sv.time;
			pr_global_struct->self = EDICT_TO_PROG(ent);
			PR_ExecuteProgram (BotPreThink);
		}

		VectorCopy (ent->v.v_angle, cmd.angles);
		cmd.impulse = ent->v.impulse;
		cmd.buttons = (ent->v.button0 ? BUTTON_ATTACK : 0) | (ent->v.button2 ? BUTTON_JUMP : 0) | (ent->v.button1 ? BUTTON_USE : 0);

		val = GetEdictFieldValue(ent, "forwardmove");		// FIXME, cache field offset
		cmd.forwardmove = val ? val->_float : 0;
		val = GetEdictFieldValue(ent, "sidemove");
		cmd.sidemove = val ? val->_float : 0;
		val = GetEdictFieldValue(ent, "upmove");
		cmd.upmove = val ? val->_float : 0;

		SV_PreRunCmd ();
		SV_RunCmd (&cmd);
		SV_PostRunCmd ();
	}
}


