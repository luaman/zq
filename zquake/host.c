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

// this should be the only file that includes both server.h and client.h

#include "quakedef.h"
#include "pmove.h"
#include "version.h"

#if defined(QW_BOTH) || defined(SERVERONLY)
#include "server.h"

void SV_Init (void);
void SV_Error (char *error, ...);
#endif


#ifdef SERVERONLY
// these should go to cl_null.c
void CL_Init (void)
{
}

void Con_Init (void)
{
}
#endif

#if !defined(QW_BOTH) && !defined(SERVERONLY)
// this should go to sv_null.c
void SV_Init (void)
{
}
#endif


int			host_hunklevel;



/*
====================
Host_Init
====================
*/
void Host_Init (quakeparms_t *parms)
{
	COM_InitArgv (parms->argc, parms->argv);

	if (COM_CheckParm ("-minmemory"))
		parms->memsize = MINIMUM_MEMORY;

	host_parms = *parms;

	if (parms->memsize < MINIMUM_MEMORY)
		Sys_Error ("Only %4.1f megs of memory reported, can't execute game", parms->memsize / (float)0x100000);

	Memory_Init (parms->membase, parms->memsize);

	Cbuf_Init ();
	Cmd_Init ();
	Cvar_Init ();

	COM_Init ();

	Con_Init ();
	NET_Init ();
	Netchan_Init ();
	Sys_Init ();
	Pmove_Init ();
	Mod_Init ();
	
	SV_Init ();
	CL_Init ();

	Hunk_AllocName (0, "-HOST_HUNKLEVEL-");
	host_hunklevel = Hunk_LowMark ();

	host_initialized = true;

	Com_Printf ("Exe: "__TIME__" "__DATE__"\n");
	Com_Printf ("%4.1f megs RAM used.\n", parms->memsize / (1024*1024.0));
	
	Com_Printf ("\nZQuake version %s\n\n", VersionString());

#ifdef SERVERONLY

	Com_Printf ("========= ZQuake Initialized =========\n");

	Cbuf_InsertText ("exec server.cfg\n");
	
// process command line arguments
	Cmd_StuffCmds_f ();
	Cbuf_Execute ();

// if a map wasn't specified on the command line, spawn start map
	if (sv.state == ss_dead)
		Cmd_ExecuteString ("map start");
	if (sv.state == ss_dead)
		SV_Error ("Couldn't spawn a server");

#else

	Com_Printf ("€ ZQuake Initialized ‚\n");

	Cbuf_InsertText ("exec quake.rc\n");
	Cbuf_AddText ("cl_warncmd 1\n");

#endif
}
