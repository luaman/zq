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

#include "wad.h"

// FIXME FIXME, everything but width, height and (possibly) alpha should be private to refresh
#ifdef GLQUAKE
typedef struct
{
	int			width, height;
	int			texnum;
	float		sl, tl, sh, th;
} mpic_t;
#else
typedef struct
{
	int			width;
	short		height;
	byte		alpha;
	byte		pad;
	byte		data[4];	// variable sized
} mpic_t;
#endif

extern	mpic_t		*draw_disc;	// also used on sbar

void Draw_Alt_String (int x, int y, const char *str);
void Draw_TextBox (int x, int y, int width, int lines);
void Draw_Crosshair (void);
