/*  Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/
// cmdlib.h

#ifndef __CMDLIB__
#define __CMDLIB__

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>
#include <ctype.h>
#include <sys/types.h>
#include <sys/stat.h>
#ifndef _WIN32
#include <sys/file.h>
#endif
#include <stdarg.h>
#include <assert.h>

#ifdef NeXT
#include <libc.h>
#endif

#ifndef __BYTEBOOL__
#define __BYTEBOOL__
typedef int qboolean;
typedef unsigned char byte;
#endif


#ifdef _WIN32
#pragma warning( disable : 4244 )
#endif


// the dec offsetof macro doesn't work very well...
#define myoffsetof(type,identifier) ((size_t)&((type *)0)->identifier)


// set these before calling CheckParm
extern int myargc;
extern char **myargv;

#ifdef _WIN32
#define Q_stricmp(s1, s2) _stricmp((s1), (s2))
#define Q_strnicmp(s1, s2, n) _strnicmp((s1), (s2), (n))
#else
#define Q_stricmp(s1, s2) strcasecmp((s1), (s2))
#define Q_strnicmp(s1, s2, n) strncasecmp((s1), (s2), (n))
#endif


char *strupr (char *in);
char *strlower (char *in);
int Q_filelength (int handle);
int Q_tell (int handle);

double I_FloatTime (void);

void	Error (char *error, ...);
int		CheckParm (char *check);

int 	SafeOpenWrite (char *filename);
int 	SafeOpenRead (char *filename);
void 	SafeRead (int handle, void *buffer, long count);
void 	SafeWrite (int handle, void *buffer, long count);
void 	*SafeMalloc (long size);

long	LoadFile (char *filename, void **bufferptr);
void	SaveFile (char *filename, void *buffer, long count);

void 	DefaultExtension (char *path, char *extension);
void 	DefaultPath (char *path, char *basepath);
void 	StripFilename (char *path);
void 	StripExtension (char *path);

void 	ExtractFilePath (char *path, char *dest);
void 	ExtractFileBase (char *path, char *dest);
void	ExtractFileExtension (char *path, char *dest);

long 	ParseNum (char *str);

short	BigShort (short l);
short	LittleShort (short l);
long	BigLong (long l);
long	LittleLong (long l);
float	BigFloat (float l);
float	LittleFloat (float l);


char *COM_Parse (char *data);

extern	char	com_token[1024];
extern	int		com_eof;



#endif
