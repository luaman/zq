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

// cl_draw.h - 2d drawing functions which don't belong to refresh

#ifdef _WIN32
typedef struct mpic_s	mpic_t;
#else
#ifdef GLQUAKE
typedef struct mpic_s
{
	int			width, height;
	int			texnum;
	float		sl, tl, sh, th;
} mpic_t;
#else
typedef struct mpic_s
{
	int			width;
	short		height;
	byte		alpha;
	byte		pad;
	byte		data[4];	// variable sized
} mpic_t;
#endif
#endif

// FIXME, load separately in refresh and client?
extern	mpic_t		*draw_disc;	// also used on sbar


void Draw_Alt_String (int x, int y, const char *str);
void Draw_TextBox (int x, int y, int width, int lines);
void Draw_Crosshair (void);


// !!! If we ever put the renderer into a dll, this heavy wizardry
// should be replaced with real function calls
// Also, GetPicHeight has endian problems
#ifdef HAVE_INLINE
inline int GetPicWidth (mpic_t *pic) { return *(int *)pic; }
inline int GetPicHeight (mpic_t *pic) { return *(short *)((int *)pic + 1); }
#else
#define GetPicWidth(pic) (*(int *)pic)
#define GetPicHeight(pic) ((int)*(short *)((int *)pic + 1))
#endif

