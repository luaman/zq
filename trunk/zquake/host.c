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
#include <setjmp.h>


#if !defined(CLIENTONLY) && !defined(SERVERONLY)
qboolean	dedicated = false;
#endif

double		curtime;

qboolean	host_initialized;		// true if into command execution
int			host_hunklevel;
int			host_memsize;
void		*host_membase;

jmp_buf 	host_abort;



/*
================
Host_EndGame
================
*/
void Host_EndGame (char *message, ...)
{
	va_list		argptr;
	char		string[1024];
	
	va_start (argptr,message);
	vsprintf (string,message,argptr);
	va_end (argptr);
	Com_DPrintf ("Host_EndGame: %s\n",string);

//	SV_Shutdown ("");	// FIXME
	CL_Disconnect ();

	longjmp (host_abort, 1);
}

/*
================
Host_Error

This shuts down both the client and server
================
*/
void Host_Error (char *error, ...)
{
	va_list		argptr;
	char		string[1024];
	static	qboolean inerror = false;
	
	if (inerror)
		Sys_Error ("Host_Error: recursively entered");
	inerror = true;

#ifndef SERVERONLY
	SCR_EndLoadingPlaque ();		// reenable screen updates
#endif
	
	va_start (argptr,error);
	vsprintf (string,error,argptr);
	va_end (argptr);

	Com_Printf ("\n===========================\n");
	Com_Printf ("Host_Error: %s\n",string);
	Com_Printf ("===========================\n\n");
	
	SV_Shutdown (va("server crashed: %s\n", string));
	CL_Disconnect ();

	if (dedicated)
	{
		NET_Shutdown ();
		COM_Shutdown ();
		Sys_Error ("%s", string);
	}

	if (!host_initialized)
		Sys_Error ("Host_Error: %s", string);

	inerror = false;

	longjmp (host_abort, 1);
}


/*
===============
Host_InitMemory

memsize is the recommended amount of memory to use for hunk
===============
*/
void Host_InitMemory (int memsize)
{
	int		t;

	if (COM_CheckParm ("-minmemory"))
		memsize = MINIMUM_MEMORY;

	if ((t = COM_CheckParm ("-heapsize")) != 0 && t + 1 < com_argc)
		memsize = Q_atoi (com_argv[t + 1]) * 1024;

	if ((t = COM_CheckParm ("-mem")) != 0 && t + 1 < com_argc)
		memsize = Q_atoi (com_argv[t + 1]) * 1024 * 1024;

	if (memsize < MINIMUM_MEMORY)
		Sys_Error ("Only %4.1f megs of memory reported, can't execute game", memsize / (float)0x100000);

	host_memsize = memsize;
	host_membase = Q_Malloc (host_memsize);
	Memory_Init (host_membase, host_memsize);
}


/*
===============
Host_Frame
===============
*/
void Host_Frame (double time)
{
	if (setjmp (host_abort))
		return;			// something bad happened, or the server disconnected

	curtime += time;

	if (dedicated)
		SV_Frame (time);
	else
		CL_Frame (time);	// will also call SV_Frame
}

/*
====================
Host_Init
====================
*/
void Host_Init (int argc, char **argv, int default_memsize)
{
	COM_InitArgv (argc, argv);

#if !defined(CLIENTONLY) && !defined(SERVERONLY)
	if (COM_CheckParm("-dedicated"))
		dedicated = true;
#endif

	Host_InitMemory (default_memsize);

	Cbuf_Init ();
	Cmd_Init ();
	Cvar_Init ();
	COM_Init ();

	FS_InitFilesystem ();
	COM_CheckRegistered ();

	Cbuf_AddEarlyCommands ();
	Cbuf_Execute ();

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
	Com_Printf ("%4.1f megs RAM used.\n", host_memsize / (1024*1024.0));
	
	Com_Printf ("\n========= " PROGRAM " Initialized =========\n");


	if (dedicated)
	{
		Cbuf_AddText ("exec server.cfg\n");
		Cmd_StuffCmds_f ();		// process command line arguments
		Cbuf_Execute ();

	// if a map wasn't specified on the command line, spawn start map
		if (!com_serveractive)
			Cmd_ExecuteString ("map start");
		if (!com_serveractive)
			Host_Error ("Couldn't spawn a server");
	}
	else
	{
		Cbuf_AddText ("exec default.cfg\n");
		Cbuf_AddText ("exec config.cfg\n");
		Cbuf_AddText ("exec autoexec.cfg\n");
		Cmd_StuffCmds_f ();		// process command line arguments
		Cbuf_AddText ("cl_warncmd 1\n");
	}
}


/*
===============
Host_Shutdown

FIXME: this is a callback from Sys_Quit and Sys_Error.  It would be better
to run quit through here before the final handoff to the sys code.
===============
*/
void Host_Shutdown (void)
{
	static qboolean isdown = false;
	
	if (isdown)
	{
		printf ("recursive shutdown\n");
		return;
	}
	isdown = true;

	SV_Shutdown ("Server quit\n");
	CL_Shutdown ();
	NET_Shutdown ();
	COM_Shutdown ();
}

/*
===============
Host_Quit
===============
*/
void Host_Quit (void)
{
	Host_Shutdown ();
	Sys_Quit ();
}

