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

#include "server.h"

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
		(&PR_GLOBAL(parm1))[i] = cl->spawn_parms[i];

	// call the spawn function
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	PR_ExecuteProgram (PR_GLOBAL(ClientConnect));

	// actually spawn the player
	pr_global_struct->time = sv.time;
	pr_global_struct->self = EDICT_TO_PROG(ent);
	PR_ExecuteProgram (PR_GLOBAL(PutClientInServer));

	cl->sendinfo = true;
}

edict_t *SV_CreateBot ()
{
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

	newcl->clear();
	newcl->state = cs_spawned;
	newcl->bot = true;
	newcl->userid = SV_GenerateUserID();
	newcl->extensions = CLIENT_EXTENSIONS;	// bots always use latest ZQuake :-)

	// init a bogus network connection
	SZ_Init (&newcl->datagram, newcl->datagram_buf, sizeof(newcl->datagram_buf));
	newcl->datagram.allowoverflow = true;
	Netchan_Setup (NS_SERVER, &newcl->netchan, net_null, 0);

	// set up the edict
	ent = EDICT_NUM((newcl - svs.clients) + 1);
	newcl->edict = ent;

//	Com_DPrintf ("Bot %s connected\n", newcl->name.c_str());

	SetUpClientEdict (newcl, ent);

	return ent;
}

void SV_RemoveBot (client_t *cl)
{
	if (cl->state == cs_spawned)
	{
		if (!cl->spectator)
		{
			// call the prog function for removing a client
			// this will set the body to a dead frame, among other things
			pr_global_struct->self = EDICT_TO_PROG(cl->edict);
			PR_ExecuteProgram (PR_GLOBAL(ClientDisconnect));
		}
		else if (SpectatorDisconnect)
		{
			// call the prog function for removing a client
			// this will set the body to a dead frame, among other things
			pr_global_struct->self = EDICT_TO_PROG(cl->edict);
			PR_ExecuteProgram (SpectatorDisconnect);
		}
	}

	Com_DPrintf ("Bot %s removed\n", cl->name.c_str());

	cl->state = cs_free;		// we don't have zombie bots :)
	cl->bot = false;
	cl->old_frags = 0;
	cl->name = "";
//	cl->edict->inuse = false;
	cl->edict->v.frags = 0;
	cl->userinfo.clear();

	SV_FreeDelayedPackets (cl);

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

	for (i = 0, cl = svs.clients; i < MAX_CLIENTS; i++, cl++) {
		if (!cl->bot)
			continue;

		// FIXME FIXME, we get an infinite loop in COM_HullPointContents
		// if we spawn the bot in one of the first two SV_Physics calls
		// sv.old_time is a workaround for now
		if (cl->state == cs_connected && sv.old_time) {
			Bot_Spawn_And_Begin (cl);
			continue;
		}

		if (cl->state != cs_spawned)
			continue;

		ent = cl->edict;

		// create a fake client move command for prediction's sake
		cmd = nullcmd;
		VectorCopy (ent->v.v_angle, cmd.angles);
		cmd.msec = min ((svs.realtime - cl->cmdtime) * 1000, 255);
		cl->lastcmd = cmd;
		cl->cmdtime = svs.realtime;

		// update bogus network stuff
		cl->netchan.last_received = curtime;
		SZ_Clear (&cl->datagram);			// don't overflow
		SV_ClearReliable (cl);				// don't overflow

		//
		// think and run physics
		//
		if (sv_paused.value)
			continue;

		sv_client = cl;
		sv_player = ent;

		SV_PreRunCmd ();
		SV_RunCmd (&cmd);
		SV_PostRunCmd ();
	}
}


