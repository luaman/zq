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

	// set colormap, name, entgravity and maxspeed
	SetUpClientEdict (cl, ent);

	cl->state = cs_spawned;

	// copy spawn parms out of the client_t
	for (i=0 ; i< NUM_SPAWN_PARMS ; i++)
		(&pr_global_struct->parm1)[i] = cl->spawn_parms[i];

	// call the spawn function
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	if (BotConnect)
		PR_ExecuteProgram (BotConnect);
	else
		PR_ExecuteProgram (pr_global_struct->ClientConnect);

	// actually spawn the player
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	PR_ExecuteProgram (pr_global_struct->PutClientInServer);

	cl->sendinfo = true;
}

edict_t *SV_CreateBot (char *name)
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
	strlcpy (newcl->name, name, sizeof(newcl->name));

	// init a bogus network connection
	SZ_Init (&newcl->datagram, newcl->datagram_buf, sizeof(newcl->datagram_buf));
	newcl->datagram.allowoverflow = true;
	Netchan_Setup (NS_SERVER, &newcl->netchan, net_null, 0);

	Info_SetValueForStarKey (newcl->userinfo, "*bot", "1", MAX_INFO_STRING);
	Info_SetValueForKey (newcl->userinfo, "name", newcl->name, MAX_INFO_STRING);

	// set up the edict
	ent = EDICT_NUM((newcl - svs.clients) + 1);
	newcl->edict = ent;

	Com_DPrintf ("Bot %s connected\n", newcl->name);

	SetUpClientEdict (newcl, ent);

	// the bot will spawn next time SV_RunBots is run

//	newcl->sendinfo = true;

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
			if (BotDisconnect)
				PR_ExecuteProgram (BotDisconnect);
			else
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


void SV_PreRunCmd (void);
void SV_RunCmd (usercmd_t *ucmd);
void SV_PostRunCmd (void);

void SV_RunBots (void)
{
	int			i;
	client_t	*cl;
	edict_t		*ent;
	usercmd_t	cmd;
	int			num_bots_spawned = 0;

	for (i = 0, cl = svs.clients; i < MAX_CLIENTS; i++, cl++) {
		if (!cl->bot)
			continue;

		if (cl->state == cs_connected) {
			if (num_bots_spawned > 3)
				continue;			// don't spawn them all at once

			if (sv.time < 1.4)
				continue;			// give the local player a chance to reconnect

			if (!cl->cmdtime /* FIXME, a good idea to check this particular field? */) {
				// call the progs to get default spawn parms for the new client
				PR_ExecuteProgram (pr_global_struct->SetNewParms);
				for (i=0 ; i<NUM_SPAWN_PARMS ; i++)
					cl->spawn_parms[i] = (&pr_global_struct->parm1)[i];
			}

			Bot_Spawn_And_Begin (cl);
			num_bots_spawned++;
		}

		if (cl->state != cs_spawned)
			continue;

		ent = cl->edict;

		// create a fake client move command for prediction's sake
		cmd = nullcmd;
		VectorCopy (ent->v.v_angle, cmd.angles);
		cmd.msec = (svs.realtime - cl->cmdtime) * 1000;
		cl->cmdtime += cmd.msec * 0.001;
		if (cmd.msec > 255)
			cmd.msec = 255;
		cl->lastcmd = cmd;

		// update bogus network stuff
		cl->netchan.last_received = curtime;
		SZ_Clear (&cl->datagram);			// don't overflow
		SZ_Clear (&cl->netchan.message);	// don't overflow

		if (sv.paused)
			continue;

		//
		// think and run physics
		//
		sv_client = cl;
		sv_player = ent;

		SV_PreRunCmd ();
		SV_RunCmd (&cmd);
		SV_PostRunCmd ();
	}
}


