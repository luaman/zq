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
// sys.h -- non-portable functions
#ifndef _SYS_H_
#define _SYS_H_

#ifdef _WIN32
#define Sys_MSleep(x) Sleep(x)
#else
#define Sys_MSleep(x) usleep((x) * 1000)
#endif

//
// file IO
//

void Sys_mkdir (const char *path);

//
// memory protection
//
EXTERNC void Sys_MakeCodeWriteable (unsigned long startaddr, unsigned long length);


EXTERNC void Sys_Error (const char *error, ...);
// an error will cause the entire program to exit

EXTERNC void Sys_Printf (const char *fmt, ...);
// send text to the console

void Sys_Quit (void);

EXTERNC double Sys_DoubleTime (void);

char *Sys_ConsoleInput (void);

// if successful, returns Q_malloc'ed string (make sure to free it afterwards)
// returns NULL if the operation failed for some reason
wchar *Sys_GetClipboardTextW (void);

// Perform Key_Event () callbacks until the input que is empty
void Sys_SendKeyEvents (void);

EXTERNC_START
void Sys_LowFPPrecision (void);
void Sys_HighFPPrecision (void);
void Sys_SetFPCW (void);
EXTERNC_END

void Sys_Init (void);

#endif /* _SYS_H_ */

