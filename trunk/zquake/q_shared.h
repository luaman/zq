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
// q_shared.h -- functions shared by all subsystems
#ifndef _Q_SHARED_H_
#define _Q_SHARED_H_

#include <math.h>
#include <string.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <ctype.h>
#include <assert.h>
#include <wchar.h>

#ifdef __cplusplus
#include <string>
#include <vector>
#include <map>
#include <iostream>
using std::string;
using std::wstring;
#endif

#ifdef __cplusplus
#define EXTERNC extern "C"
#define EXTERNC_START extern "C" {
#define EXTERNC_END }
#else
#define EXTERNC
#define EXTERNC_START
#define EXTERNC_END
#endif

//#define wchar unsigned short	// 16-bit Unicode char
#define wchar wchar_t
typedef unsigned char 		byte;
#define _DEF_BYTE_

#include "sys.h"
#include "mathlib.h"

#ifdef _MSC_VER
#pragma warning( disable : 4244 4127 4201 4214 4514 4305 4115 4018 4996)
#pragma warning( disable : 4309)	// truncation of constant value
#endif

#undef gamma	// math.h defines this

#define	QUAKE_GAME			// as opposed to utilities

#define PROGRAM "ZQuake"

#ifndef __cplusplus
#ifndef false
#define false 0
#endif
#ifndef true
#define true 1
#endif
#endif

typedef int qbool;

#ifndef NULL
#define NULL ((void *)0)
#endif


#ifdef _WIN32
#define IS_SLASH(c) ((c) == '/' || (c) == '\\')
#else
#define IS_SLASH(c) ((c) == '/')
#endif


#ifndef min
#define min(a,b) ((a) < (b) ? (a) : (b))
#endif
#ifndef max
#define max(a,b) ((a) > (b) ? (a) : (b))
#endif

//#define bound(a,b,c) (max((a), min((b), (c))))
#define bound(a,b,c) ((a) >= (c) ? (a) : \
					(b) < (a) ? (a) : (b) > (c) ? (c) : (b))


//============================================================================

#if id386
#define UNALIGNED_OK	1	// set to 0 if unaligned accesses are not supported
#else
#define UNALIGNED_OK	0
#endif

#define UNUSED(x)	(x = x)	// for pesky compiler / lint warnings

//============================================================================

#define	MINIMUM_MEMORY	0x550000

#define	MAX_QPATH		64			// max length of a quake game pathname
#define	MAX_OSPATH		128			// max length of a filesystem pathname

//============================================================================

typedef struct sizebuf_s
{
	qbool	allowoverflow;	// if false, do a Sys_Error
	qbool	overflowed;		// set to true if the buffer size failed
	byte	*data;
	int		maxsize;
	int		cursize;
} sizebuf_t;

void SZ_Init (sizebuf_t *buf, byte *data, int length);
void SZ_Clear (sizebuf_t *buf);
void *SZ_GetSpace (sizebuf_t *buf, int length);
void SZ_Write (sizebuf_t *buf, const void *data, int length);
void SZ_Print (sizebuf_t *buf, const char *data);	// strcats onto the sizebuf

//============================================================================

EXTERNC short	ShortSwap (short l);
EXTERNC int		LongSwap (int l);
EXTERNC float	FloatSwap (float f);

#if defined(__BIG_ENDIAN__) && !defined(BIGENDIAN)
#define BIGENDIAN
#endif

#ifdef BIGENDIAN
#define BigShort(x) (x)
#define BigLong(x) (x)
#define BigFloat(x) (x)
#define LittleShort(x) ShortSwap (x)
#define LittleLong(x) LongSwap(x)
#define LittleFloat(x) FloatSwap(x)
#else
#define BigShort(x) ShortSwap (x)
#define BigLong(x) LongSwap(x)
#define BigFloat(x) FloatSwap(x)
#define LittleShort(x) (x)
#define LittleLong(x) (x)
#define LittleFloat(x) (x)
#endif

//============================================================================

#ifdef _WIN32
#define Q_stricmp(s1, s2) _stricmp((s1), (s2))
#define Q_strnicmp(s1, s2, n) _strnicmp((s1), (s2), (n))
#else
#define Q_stricmp(s1, s2) strcasecmp((s1), (s2))
#define Q_strnicmp(s1, s2, n) strncasecmp((s1), (s2), (n))
#endif
EXTERNC char	*Q_strlwr( char *s1 );
EXTERNC char	*Q_strupr( char *s1 );

EXTERNC int	Q_atoi (const char *str);
float Q_atof (const char *str);
#ifdef __cplusplus
inline float Q_atoi (const string str) { return Q_atoi(str.c_str()); }
inline float Q_atof (const string str) { return Q_atof(str.c_str()); }
#endif
char *Q_ftos (float value);		// removes trailing zero chars

EXTERNC wchar char2wc (char c);
char wc2char (wchar wc);
wchar *str2wcs (const char *str);
char *wcs2str (const wchar *ws);
#ifdef _WIN32
#define qwcscpy(a,b) (wchar *)wcscpy((wchar_t *)(a), (wchar_t *)(b))
#define qwcschr(a,b) (wchar *)wcschr((wchar_t *)(a),b)
#define qwcslen(a) wcslen((wchar_t *)(a))
#else
wchar *qwcscpy (wchar *dest, const wchar *src);
wchar *qwcschr (const wchar *ws, wchar wc);
size_t qwcslen (const wchar *s);
#endif
size_t qwcslcpy (wchar *dst, const wchar *src, size_t size);
size_t qwcslcat (wchar *dst, const wchar *src, size_t size);
wchar *Q_wcsdup(const wchar *src);

EXTERNC size_t strlcpy (char *dst, const char *src, size_t size);
EXTERNC size_t strlcat (char *dst, const char *src, size_t size);
EXTERNC int snprintf(char *buffer, size_t count, char const *format, ...);
EXTERNC int vsnprintf(char *buffer, size_t count, const char *format, va_list argptr);
#define Q_snprintfz snprintf 	// nuke this one day

qbool Q_glob_match (const char *pattern, const char *text);

// does a varargs printf into a temp buffer
EXTERNC const char	*va(const char *format, ...);

int Com_HashKey (const char *name);

//============================================================================

EXTERNC void *Q_malloc (size_t size);
void *Q_calloc (size_t count, size_t size);
char *Q_strdup (const char *src);
// might be turned into a function that makes sure all Q_*alloc calls are matched with Q_free
#define Q_free(ptr) free((void *)ptr)

//============================================================================

// these are here for net.h's sake
#define	MAX_MSGLEN		1450		// max length of a reliable message
#define	MAX_DATAGRAM	1450		// max length of unreliable message
#define	MAX_BIG_MSGLEN	8000		// max length of a demo or loop message, >= MAX_MSGLEN + header

#define	MAX_NQMSGLEN	8000		// max length of a reliable message
#define MAX_OVERALLMSGLEN	MAX_NQMSGLEN
#define	MAX_NQDATAGRAM	1024		// max length of unreliable message

//============================================================================

#ifndef NOMVDPLAY
#ifndef SERVERONLY
#define MVDPLAY
#endif
#endif

#define WITH_NQPROGS

#endif /* _Q_SHARED_H_ */

