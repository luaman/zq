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

#include "quakedef.h"
#include "gl_local.h"
#include "crc.h"
#include "version.h"
#include "sbar.h"

extern unsigned char d_15to8table[65536];
extern unsigned d_8to24table2[256];
extern cvar_t crosshair, cl_crossx, cl_crossy, crosshaircolor;

qboolean OnChange_gl_texturemode (cvar_t *var, char *string);
qboolean OnChange_gl_smoothfont (cvar_t *var, char *string);

cvar_t		gl_nobind = {"gl_nobind", "0"};
cvar_t		gl_max_size = {"gl_max_size", "1024"};
cvar_t		gl_picmip = {"gl_picmip", "0"};
cvar_t		gl_lerpimages = {"r_lerpimages", "1"};
cvar_t		gl_conalpha = {"gl_conalpha", "0.8"};
cvar_t		gl_texturemode = {"gl_texturemode", "GL_LINEAR_MIPMAP_NEAREST", 0, OnChange_gl_texturemode};
cvar_t		gl_smoothfont = {"gl_smoothfont", "1", 0, OnChange_gl_smoothfont};

byte		*draw_chars;				// 8*8 graphic characters
mpic_t		*draw_disc;
mpic_t		*draw_backtile;

int			translate_texture;
int			char_texture;
int			crosshairtextures[3];

static byte crosshairdata[3][64] = {
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xfe, 0xff, 0xfe, 0xff, 0xfe, 0xff, 0xfe, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,

	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xfe, 0xfe, 0xfe, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,

	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
	0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
};


int GL_LoadPicTexture (char *name, mpic_t *pic, byte *data);
void Draw_LoadConback (void);
void Draw_LoadCharset (void);

mpic_t	conback_data;
mpic_t	*conback = &conback_data;

int		gl_lightmap_format = 4;
int		gl_solid_format = 3;
int		gl_alpha_format = 4;

int		gl_filter_min = GL_LINEAR_MIPMAP_NEAREST;
int		gl_filter_max = GL_LINEAR;


int		texels;

typedef struct
{
	int		texnum;
	char	identifier[64];
	int		width, height;
	qboolean	mipmap;
	qboolean	brighten;
	unsigned	crc;
} gltexture_t;

gltexture_t	gltextures[MAX_GLTEXTURES];
int			numgltextures;

void GL_Bind (int texnum)
{
	if (gl_nobind.value)
		texnum = char_texture;
	if (currenttexture == texnum)
		return;
	currenttexture = texnum;
#ifdef _WIN32
	bindTexFunc (GL_TEXTURE_2D, texnum);
#else
	glBindTexture (GL_TEXTURE_2D, texnum);
#endif
}


/*
=============================================================================

  scrap allocation

  Allocate all the little status bar objects into a single texture
  to crutch up stupid hardware / drivers

=============================================================================
*/

// some cards have low quality of alpha pics, so load the pics
// without transparent pixels into a different scrap block.
// scrap 0 is solid pics, 1 is transparent
#define	MAX_SCRAPS		2
#define	BLOCK_WIDTH		256
#define	BLOCK_HEIGHT	256

int			scrap_allocated[MAX_SCRAPS][BLOCK_WIDTH];
byte		scrap_texels[MAX_SCRAPS][BLOCK_WIDTH*BLOCK_HEIGHT*4];
int			scrap_dirty = 0;	// bit mask
int			scrap_texnum;

// returns false if allocation failed
qboolean Scrap_AllocBlock (int scrapnum, int w, int h, int *x, int *y)
{
	int		i, j;
	int		best, best2;

	best = BLOCK_HEIGHT;
	
	for (i=0 ; i<BLOCK_WIDTH-w ; i++)
	{
		best2 = 0;
		
		for (j=0 ; j<w ; j++)
		{
			if (scrap_allocated[scrapnum][i+j] >= best)
				break;
			if (scrap_allocated[scrapnum][i+j] > best2)
				best2 = scrap_allocated[scrapnum][i+j];
		}
		if (j == w)
		{	// this is a valid spot
			*x = i;
			*y = best = best2;
		}
	}
	
	if (best + h > BLOCK_HEIGHT)
		return false;
	
	for (i=0 ; i<w ; i++)
		scrap_allocated[scrapnum][*x + i] = best + h;

	scrap_dirty |= (1 << scrapnum);

	return true;
}

int	scrap_uploads;

void Scrap_Upload (void)
{
	int i;

	scrap_uploads++;
	for (i=0 ; i<2 ; i++) {
		if ( !(scrap_dirty & (1 << i)) )
			continue;
		scrap_dirty &= ~(1 << i);
		GL_Bind(scrap_texnum + i);
		GL_Upload8 (scrap_texels[i], BLOCK_WIDTH, BLOCK_HEIGHT, false, i, false);
	}
}

//=============================================================================
/* Support Routines */

typedef struct cachepic_s
{
	char		name[MAX_QPATH];
	mpic_t		pic;
	qboolean	valid;
} cachepic_t;

#define	MAX_CACHED_PICS		128
cachepic_t	cachepics[MAX_CACHED_PICS];
int			numcachepics;

byte		menuplyr_pixels[4096];

int		pic_texels;
int		pic_count;

/*
ideally all mpic_t's should have a flushcount field that would be
checked against a global gl_flushcount; the pic would be reloaded
if the two don't match.
currently, the pics are only updated when Draw_CachePic is called,
and wad pics are never updated.
*/
void Draw_FlushCache (void)
{
	int i;

	for (i = 0; i < numcachepics; i++)
		cachepics[i].valid = false;		// force it to be reloaded

	// I hope this doesn't cause texture memory leaks
	Draw_LoadConback ();
	Draw_LoadCharset ();
}


mpic_t *Draw_CacheWadPic (char *name)
{
	qpic_t	*p;
	mpic_t	*pic;

	p = W_GetLumpName (name);
	pic = (mpic_t *)p;

	// load little ones into the scrap
	if (p->width < 64 && p->height < 64)
	{
		int		x, y;
		int		i, j, k;
		int		texnum;

		texnum = memchr(p->data, 255, p->width*p->height) != NULL;
		if (!Scrap_AllocBlock (texnum, p->width, p->height, &x, &y)) {
			GL_LoadPicTexture (name, pic, p->data);
			return pic;
		}
		k = 0;
		for (i=0 ; i<p->height ; i++)
			for (j=0 ; j<p->width ; j++, k++)
				scrap_texels[texnum][(y+i)*BLOCK_WIDTH + x + j] = p->data[k];
		texnum += scrap_texnum;
		pic->texnum = texnum;
		pic->sl = (x+0.01)/(float)BLOCK_WIDTH;
		pic->sh = (x+p->width-0.01)/(float)BLOCK_WIDTH;
		pic->tl = (y+0.01)/(float)BLOCK_WIDTH;
		pic->th = (y+p->height-0.01)/(float)BLOCK_WIDTH;

		pic_count++;
		pic_texels += p->width*p->height;
	}
	else
		GL_LoadPicTexture (name, pic, p->data);

	return pic;
}


/*
================
Draw_CachePic
================
*/
mpic_t *Draw_CachePic (char *path)
{
	cachepic_t	*pic;
	int			i;
	qpic_t		*dat;

	for (pic=cachepics, i=0 ; i<numcachepics ; pic++, i++)
		if (!strcmp (path, pic->name) && pic->valid)
			return &pic->pic;

	if (numcachepics == MAX_CACHED_PICS)
		Sys_Error ("numcachepics == MAX_CACHED_PICS");
	numcachepics++;
	strcpy (pic->name, path);

//
// load the pic from disk
//
	dat = (qpic_t *)FS_LoadTempFile (path);	
	if (!dat)
		Sys_Error ("Draw_CachePic: failed to load %s", path);
	SwapPic (dat);

	// HACK HACK HACK --- we need to keep the bytes for
	// the translatable player picture just for the menu
	// configuration dialog
	if (!strcmp (path, "gfx/menuplyr.lmp"))
		memcpy (menuplyr_pixels, dat->data, dat->width*dat->height);

	pic->pic.width = dat->width;
	pic->pic.height = dat->height;

	GL_LoadPicTexture (path, &pic->pic, dat->data);

	pic->valid = true;

	return &pic->pic;
}


void Draw_CharToConback (int num, byte *dest)
{
	int		row, col;
	byte	*source;
	int		drawline;
	int		x;

	row = num>>4;
	col = num&15;
	source = draw_chars + (row<<10) + (col<<3);

	drawline = 8;

	while (drawline--)
	{
		for (x=0 ; x<8 ; x++)
			if (source[x] != 255)
				dest[x] = 0x60 + source[x];
		source += 128;
		dest += 320;
	}

}

typedef struct
{
	char *name;
	int	minimize, maximize;
} glmode_t;

glmode_t modes[] = {
	{"GL_NEAREST", GL_NEAREST, GL_NEAREST},
	{"GL_LINEAR", GL_LINEAR, GL_LINEAR},
	{"GL_NEAREST_MIPMAP_NEAREST", GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST},
	{"GL_LINEAR_MIPMAP_NEAREST", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR},
	{"GL_NEAREST_MIPMAP_LINEAR", GL_NEAREST_MIPMAP_LINEAR, GL_NEAREST},
	{"GL_LINEAR_MIPMAP_LINEAR", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR}
};


qboolean OnChange_gl_texturemode (cvar_t *var, char *string)
{
	int		i;
	gltexture_t	*glt;

	for (i=0 ; i<6 ; i++)
	{
		if (!Q_stricmp (modes[i].name, string ) )
			break;
	}
	if (i == 6)
	{
		Com_Printf ("bad filter name: %s\n", string);
		return true;	// don't change the cvar
	}

	gl_filter_min = modes[i].minimize;
	gl_filter_max = modes[i].maximize;

	// change all the existing mipmap texture objects
	for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++)
	{
		if (glt->mipmap)
		{
			GL_Bind (glt->texnum);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
		}
	}

	return false;
}


qboolean OnChange_gl_smoothfont (cvar_t *var, char *string)
{
	float	newval;

	newval = Q_atof (string);
	if (!newval == !gl_smoothfont.value || !char_texture)
		return false;

	if (newval)
	{
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	}
	else
	{
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	}

	return false;
}


void Draw_LoadCharset (void)
{
	int i;
	char	buf[128*256];
	char	*src, *dest;

	draw_chars = W_GetLumpName ("conchars");
	for (i=0 ; i<256*64 ; i++)
		if (draw_chars[i] == 0)
			draw_chars[i] = 255;	// proper transparent color

	// Convert the 128*128 conchars texture to 128*256 leaving
	// empty space between rows so that chars don't stumble on
	// each other because of texture smoothing.
	// This hack costs us 64K of GL texture memory
	memset (buf, 255, sizeof(buf));
	src = draw_chars;
	dest = buf;
	for (i=0 ; i<16 ; i++) {
		memcpy (dest, src, 128*8);
		src += 128*8;
		dest += 128*8*2;
	}

	char_texture = GL_LoadTexture ("pic:charset", 128, 256, buf, false, true, false);
	if (!gl_smoothfont.value)
	{
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	}
}

void Draw_LoadConback (void)
{
	qpic_t	*cb;
	int		start;

	start = Hunk_LowMark ();

	cb = (qpic_t *)FS_LoadHunkFile ("gfx/conback.lmp");	
	if (!cb)
		Sys_Error ("Couldn't load gfx/conback.lmp");
	SwapPic (cb);

	if (cb->width != 320 || cb->height != 200)
		Sys_Error ("Draw_Init: conback.lmp size is not 320x200");

	conback->width = cb->width;
	conback->height = cb->height;
	GL_LoadPicTexture ("conback", conback, cb->data);
	conback->width = vid.conwidth;
	conback->height = vid.conheight;

	// free loaded console
	Hunk_FreeToLowMark (start);
}


/*
===============
Draw_Init
===============
*/
void Draw_Init (void)
{
	int		i;

	Cvar_Register (&gl_nobind);
	Cvar_Register (&gl_max_size);
	Cvar_Register (&gl_picmip);
	Cvar_Register (&gl_lerpimages);
	Cvar_Register (&gl_conalpha);
	Cvar_Register (&gl_texturemode);
	Cvar_Register (&gl_smoothfont);

	// 3dfx can only handle 256 wide textures
	if (!Q_strnicmp ((char *)gl_renderer, "3dfx",4) ||
		!Q_strnicmp ((char *)gl_renderer, "Mesa",4))
		Cvar_Set (&gl_max_size, "256");

	// load the console background and the charset
	// by hand, because we need to write the version
	// string into the background before turning
	// it into a texture

	Draw_LoadCharset ();

	Draw_LoadConback ();

	// save a texture slot for translated picture
	translate_texture = texture_extension_number++;

	// save slots for scraps
	scrap_texnum = texture_extension_number;
	texture_extension_number += MAX_SCRAPS;

	// Load the crosshair pics
	for (i=0 ; i<3 ; i++) {
		crosshairtextures[i] = GL_LoadTexture ("", 8, 8, crosshairdata[i], false, true, false);
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
		glTexParameterf (GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
	}

	//
	// get the other pics we need
	//
	draw_disc = Draw_CacheWadPic ("disc");
	draw_backtile = Draw_CacheWadPic ("backtile");
}



/*
================
Draw_Character

Draws one 8*8 graphics character with 0 being transparent.
It can be clipped to the top of the screen to allow the console to be
smoothly scrolled off.
================
*/
void Draw_Character (int x, int y, int num)
{
	int				row, col;
	float			frow, fcol;

	if (y <= -8)
		return;			// totally off screen

	if (num == 32)
		return;		// space

	num &= 255;

	row = num>>4;
	col = num&15;

	frow = row*0.0625;
	fcol = col*0.0625;

	GL_Bind (char_texture);

	glBegin (GL_QUADS);
	glTexCoord2f (fcol, frow);
	glVertex2f (x, y);
	glTexCoord2f (fcol + 0.0625, frow);
	glVertex2f (x+8, y);
	glTexCoord2f (fcol + 0.0625, frow + 0.03125);
	glVertex2f (x+8, y+8);
	glTexCoord2f (fcol, frow + 0.03125);
	glVertex2f (x, y+8);
	glEnd ();
}

/*
================
Draw_String
================
*/
void Draw_String (int x, int y, char *str)
{
	float			frow, fcol;
	int num;

	if (y <= -8)
		return;			// totally off screen
	if (!*str)
		return;

	GL_Bind (char_texture);

	glBegin (GL_QUADS);

	while (*str) // stop rendering when out of characters
	{
		if ((num = *str++) != 32) // skip spaces
		{
			frow = (float) (num >> 4)*0.0625;
			fcol = (float) (num & 15)*0.0625;
			glTexCoord2f (fcol, frow);
			glVertex2f (x, y);
			glTexCoord2f (fcol + 0.0625, frow);
			glVertex2f (x+8, y);
			glTexCoord2f (fcol + 0.0625, frow + 0.03125);
			glVertex2f (x+8, y+8);
			glTexCoord2f (fcol, frow + 0.03125);
			glVertex2f (x, y+8);
		}

		x += 8;
	}

	glEnd ();
}

/*
================
Draw_Alt_String
================
*/
void Draw_Alt_String (int x, int y, char *str)
{
	float			frow, fcol;
	int num;

	if (y <= -8)
		return;			// totally off screen
	if (!*str)
		return;

	GL_Bind (char_texture);

	glBegin (GL_QUADS);

	while (*str) // stop rendering when out of characters
	{
		if ((num = *str++|0x80) != (32|0x80)) // skip spaces
		{
			frow = (float) (num >> 4)*0.0625;
			fcol = (float) (num & 15)*0.0625;
			glTexCoord2f (fcol, frow);
			glVertex2f (x, y);
			glTexCoord2f (fcol + 0.0625, frow);
			glVertex2f (x+8, y);
			glTexCoord2f (fcol + 0.0625, frow + 0.03125);
			glVertex2f (x+8, y+8);
			glTexCoord2f (fcol, frow + 0.03125);
			glVertex2f (x, y+8);
		}

		x += 8;
	}

	glEnd ();
}

void Draw_Crosshair (void)
{
	int		x, y;
	int		ofs1, ofs2;
	extern vrect_t scr_vrect;

	if (crosshair.value == 2 || crosshair.value == 3 || crosshair.value == 4) {
		x = scr_vrect.x + scr_vrect.width/2 + cl_crossx.value; 
		y = scr_vrect.y + scr_vrect.height/2 + cl_crossy.value;

		glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
		glColor3ubv ((byte *) &d_8to24table[(byte) crosshaircolor.value]);
		GL_Bind (crosshairtextures[(int)crosshair.value - 2]);

		if (vid.width == 320) {
			ofs1 = 3;//3.5;
			ofs2 = 5;//4.5;
		} else {
			ofs1 = 7;
			ofs2 = 9;
		}
		glBegin (GL_QUADS);
		glTexCoord2f (0, 0);
		glVertex2f (x - ofs1, y - ofs1);
		glTexCoord2f (1, 0);
		glVertex2f (x + ofs2, y - ofs1);
		glTexCoord2f (1, 1);
		glVertex2f (x + ofs2, y + ofs2);
		glTexCoord2f (0, 1);
		glVertex2f (x - ofs1, y + ofs2);
		glEnd ();
		
		glTexEnvf (GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);
		glColor3f (1, 1, 1);
	} else if (crosshair.value)
		Draw_Character (scr_vrect.x + scr_vrect.width/2-4 + cl_crossx.value, 
			scr_vrect.y + scr_vrect.height/2-4 + cl_crossy.value, 
			'+');
}


/*
================
Draw_TextBox
================
*/
void Draw_TextBox (int x, int y, int width, int lines)
{
	mpic_t	*p;
	int		cx, cy;
	int		n;

	// draw left side
	cx = x;
	cy = y;
	p = Draw_CachePic ("gfx/box_tl.lmp");
	Draw_TransPic (cx, cy, p);
	p = Draw_CachePic ("gfx/box_ml.lmp");
	for (n = 0; n < lines; n++)
	{
		cy += 8;
		Draw_TransPic (cx, cy, p);
	}
	p = Draw_CachePic ("gfx/box_bl.lmp");
	Draw_TransPic (cx, cy+8, p);

	// draw middle
	cx += 8;
	while (width > 0)
	{
		cy = y;
		p = Draw_CachePic ("gfx/box_tm.lmp");
		Draw_TransPic (cx, cy, p);
		p = Draw_CachePic ("gfx/box_mm.lmp");
		for (n = 0; n < lines; n++)
		{
			cy += 8;
			if (n == 1)
				p = Draw_CachePic ("gfx/box_mm2.lmp");
			Draw_TransPic (cx, cy, p);
		}
		p = Draw_CachePic ("gfx/box_bm.lmp");
		Draw_TransPic (cx, cy+8, p);
		width -= 2;
		cx += 16;
	}

	// draw right side
	cy = y;
	p = Draw_CachePic ("gfx/box_tr.lmp");
	Draw_TransPic (cx, cy, p);
	p = Draw_CachePic ("gfx/box_mr.lmp");
	for (n = 0; n < lines; n++)
	{
		cy += 8;
		Draw_TransPic (cx, cy, p);
	}
	p = Draw_CachePic ("gfx/box_br.lmp");
	Draw_TransPic (cx, cy+8, p);
}


/*
================
Draw_DebugChar

Draws a single character directly to the upper right corner of the screen.
This is for debugging lockups by drawing different chars in different parts
of the code.
================
*/
void Draw_DebugChar (char num)
{
}

/*
=============
Draw_Pic
=============
*/
void Draw_Pic (int x, int y, mpic_t *pic)
{
	if (scrap_dirty)
		Scrap_Upload ();
	GL_Bind (pic->texnum);
	glBegin (GL_QUADS);
	glTexCoord2f (pic->sl, pic->tl);
	glVertex2f (x, y);
	glTexCoord2f (pic->sh, pic->tl);
	glVertex2f (x+pic->width, y);
	glTexCoord2f (pic->sh, pic->th);
	glVertex2f (x+pic->width, y+pic->height);
	glTexCoord2f (pic->sl, pic->th);
	glVertex2f (x, y+pic->height);
	glEnd ();
}

/*
=============
Draw_AlphaPic
=============
*/
void Draw_AlphaPic (int x, int y, mpic_t *pic, float alpha)
{
	if (scrap_dirty)
		Scrap_Upload ();
	glDisable(GL_ALPHA_TEST);
	glEnable (GL_BLEND);
//	glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
	glCullFace(GL_FRONT);
	glColor4f (1, 1, 1, alpha);
	GL_Bind (pic->texnum);
	glBegin (GL_QUADS);
	glTexCoord2f (pic->sl, pic->tl);
	glVertex2f (x, y);
	glTexCoord2f (pic->sh, pic->tl);
	glVertex2f (x+pic->width, y);
	glTexCoord2f (pic->sh, pic->th);
	glVertex2f (x+pic->width, y+pic->height);
	glTexCoord2f (pic->sl, pic->th);
	glVertex2f (x, y+pic->height);
	glEnd ();
	glColor3f (1, 1, 1);
	glEnable(GL_ALPHA_TEST);
	glDisable (GL_BLEND);
}

void Draw_SubPic(int x, int y, mpic_t *pic, int srcx, int srcy, int width, int height)
{
	float newsl, newtl, newsh, newth;
	float oldglwidth, oldglheight;

	if (scrap_dirty)
		Scrap_Upload ();
	
	oldglwidth = pic->sh - pic->sl;
	oldglheight = pic->th - pic->tl;

	newsl = pic->sl + (srcx*oldglwidth)/pic->width;
	newsh = newsl + (width*oldglwidth)/pic->width;

	newtl = pic->tl + (srcy*oldglheight)/pic->height;
	newth = newtl + (height*oldglheight)/pic->height;
	
	GL_Bind (pic->texnum);
	glBegin (GL_QUADS);
	glTexCoord2f (newsl, newtl);
	glVertex2f (x, y);
	glTexCoord2f (newsh, newtl);
	glVertex2f (x+width, y);
	glTexCoord2f (newsh, newth);
	glVertex2f (x+width, y+height);
	glTexCoord2f (newsl, newth);
	glVertex2f (x, y+height);
	glEnd ();
}

/*
=============
Draw_TransPic
=============
*/
void Draw_TransPic (int x, int y, mpic_t *pic)
{
	if (x < 0 || (unsigned)(x + pic->width) > vid.width || y < 0 ||
		 (unsigned)(y + pic->height) > vid.height)
	{
		Sys_Error ("Draw_TransPic: bad coordinates");
	}
		
	Draw_Pic (x, y, pic);
}


/*
=============
Draw_TransPicTranslate

Only used for the player color selection menu
=============
*/
void Draw_TransPicTranslate (int x, int y, mpic_t *pic, byte *translation)
{
	int				v, u, c;
	unsigned		trans[64*64], *dest;
	byte			*src;
	int				p;

	GL_Bind (translate_texture);

	c = pic->width * pic->height;

	dest = trans;
	for (v=0 ; v<64 ; v++, dest += 64)
	{
		src = &menuplyr_pixels[ ((v*pic->height)>>6) *pic->width];
		for (u=0 ; u<64 ; u++)
		{
			p = src[(u*pic->width)>>6];
			if (p == 255)
				dest[u] = p;
			else
				dest[u] =  d_8to24table[translation[p]];
		}
	}

	glTexImage2D (GL_TEXTURE_2D, 0, gl_alpha_format, 64, 64, 0, GL_RGBA, GL_UNSIGNED_BYTE, trans);

	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

	glBegin (GL_QUADS);
	glTexCoord2f (0, 0);
	glVertex2f (x, y);
	glTexCoord2f (1, 0);
	glVertex2f (x+pic->width, y);
	glTexCoord2f (1, 1);
	glVertex2f (x+pic->width, y+pic->height);
	glTexCoord2f (0, 1);
	glVertex2f (x, y+pic->height);
	glEnd ();
}


/*
================
Draw_ConsoleBackground

================
*/
void Draw_ConsoleBackground (int lines)
{
	char ver[80];

	if (lines == vid.height)
		Draw_Pic(0, lines - vid.height, conback);
	else
		Draw_AlphaPic (0, lines - vid.height, conback, gl_conalpha.value);

	sprintf (ver, PROGRAM " %s", PROGRAM_VERSION);
	Draw_Alt_String (vid.conwidth - strlen(ver)*8 - 8, lines - 10, ver);
}


/*
=============
Draw_TileClear

This repeats a 64*64 tile graphic to fill the screen around a sized down
refresh window.
=============
*/
void Draw_TileClear (int x, int y, int w, int h)
{
	GL_Bind (draw_backtile->texnum);
	glBegin (GL_QUADS);
	glTexCoord2f (x/64.0, y/64.0);
	glVertex2f (x, y);
	glTexCoord2f ( (x+w)/64.0, y/64.0);
	glVertex2f (x+w, y);
	glTexCoord2f ( (x+w)/64.0, (y+h)/64.0);
	glVertex2f (x+w, y+h);
	glTexCoord2f ( x/64.0, (y+h)/64.0 );
	glVertex2f (x, y+h);
	glEnd ();
}


/*
=============
Draw_Fill

Fills a box of pixels with a single color
=============
*/
void Draw_Fill (int x, int y, int w, int h, int c)
{
	glDisable (GL_TEXTURE_2D);
	glColor3f (host_basepal[c*3]/255.0,
		host_basepal[c*3+1]/255.0,
		host_basepal[c*3+2]/255.0);

	glBegin (GL_QUADS);

	glVertex2f (x,y);
	glVertex2f (x+w, y);
	glVertex2f (x+w, y+h);
	glVertex2f (x, y+h);

	glEnd ();
	glColor3f (1, 1, 1);
	glEnable (GL_TEXTURE_2D);
}
//=============================================================================

/*
================
Draw_FadeScreen

================
*/
void Draw_FadeScreen (void)
{
	glEnable (GL_BLEND);
	glDisable (GL_TEXTURE_2D);
	glColor4f (0, 0, 0, 0.7);
	glBegin (GL_QUADS);

	glVertex2f (0,0);
	glVertex2f (vid.width, 0);
	glVertex2f (vid.width, vid.height);
	glVertex2f (0, vid.height);

	glEnd ();
	glColor3f (1, 1, 1);
	glEnable (GL_TEXTURE_2D);
	glDisable (GL_BLEND);

	Sbar_Changed();
}

//=============================================================================

/*
================
Draw_BeginDisc

Draws the little blue disc in the corner of the screen.
Call before beginning any disc IO.
================
*/
void Draw_BeginDisc (void)
{
	if (!draw_disc)
		return;
	glDrawBuffer  (GL_FRONT);
	Draw_Pic (vid.width - 24, 0, draw_disc);
	glDrawBuffer  (GL_BACK);
}


/*
================
Draw_EndDisc

Erases the disc icon.
Call after completing any disc IO
================
*/
void Draw_EndDisc (void)
{
}

/*
================
GL_Set2D

Setup as if the screen was 320*200
================
*/
void GL_Set2D (void)
{
	glViewport (glx, gly, glwidth, glheight);

	glMatrixMode(GL_PROJECTION);
    glLoadIdentity ();
	glOrtho  (0, vid.width, vid.height, 0, -99999, 99999);

	glMatrixMode(GL_MODELVIEW);
    glLoadIdentity ();

	glDisable (GL_DEPTH_TEST);
	glDisable (GL_CULL_FACE);
	glDisable (GL_BLEND);
	glEnable (GL_ALPHA_TEST);
//	glDisable (GL_ALPHA_TEST);

	glColor3f (1, 1, 1);
}

//====================================================================

/*
================
GL_FindTexture
================
*/
int GL_FindTexture (char *identifier)
{
	int		i;
	gltexture_t	*glt;

	for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++)
	{
		if (!strcmp (identifier, glt->identifier))
			return gltextures[i].texnum;
	}

	return -1;
}


void R_ResampleTextureLerpLine (byte *in, byte *out, int inwidth,
		int outwidth)
{
	int		j, xi, oldx = 0, f, fstep, endx;
	fstep = (int) (inwidth*65536.0f/outwidth);
	endx = (inwidth-1);
	for (j = 0,f = 0;j < outwidth;j++, f += fstep)
	{
		xi = (int) f >> 16;
		if (xi != oldx)
		{
			in += (xi - oldx) * 4;
			oldx = xi;
		}
		if (xi < endx)
		{
			int lerp = f & 0xFFFF;
			*out++ = (byte) ((((in[4] - in[0]) * lerp) >> 16) + in[0]);
			*out++ = (byte) ((((in[5] - in[1]) * lerp) >> 16) + in[1]);
			*out++ = (byte) ((((in[6] - in[2]) * lerp) >> 16) + in[2]);
			*out++ = (byte) ((((in[7] - in[3]) * lerp) >> 16) + in[3]);
		}
		else // last pixel of the line has no pixel to lerp to
		{
			*out++ = in[0];
			*out++ = in[1];
			*out++ = in[2];
			*out++ = in[3];
		}
	}
}

/*
================
GL_ResampleTexture
================
*/
void GL_ResampleTexture (unsigned *indata, int inwidth, int inheight,
		unsigned *outdata, int outwidth, int outheight)
{
	if (gl_lerpimages.value)
	{
		int		i, j, yi, oldy, f, fstep, endy = (inheight-1);
		byte	*inrow, *out, *row1, *row2;
		out = (byte *) outdata;
		fstep = (int) (inheight*65536.0f/outheight);

		row1 = Q_Malloc(outwidth*4);
		row2 = Q_Malloc(outwidth*4);
		inrow = (byte *) indata;
		oldy = 0;
		R_ResampleTextureLerpLine (inrow, row1, inwidth, outwidth);
		R_ResampleTextureLerpLine (inrow + inwidth*4, row2, inwidth,
				outwidth);
		for (i = 0, f = 0;i < outheight;i++,f += fstep)
		{
			yi = f >> 16;
			if (yi < endy)
			{
				int lerp = f & 0xFFFF;
				if (yi != oldy)
				{
					inrow = (byte *)indata + inwidth*4*yi;
					if (yi == oldy+1)
						memcpy(row1, row2, outwidth*4);
					else
						R_ResampleTextureLerpLine (inrow, row1, inwidth,
								outwidth);
					R_ResampleTextureLerpLine (inrow + inwidth*4, row2,
							inwidth, outwidth);
					oldy = yi;
				}
				for (j=outwidth ; j ; j--)
				{
					out[0] = (byte) ((((row2[ 0] - row1[ 0]) * lerp) >> 16)
							+ row1[ 0]);
					out[1] = (byte) ((((row2[ 1] - row1[ 1]) * lerp) >> 16)
							+ row1[ 1]);
					out[2] = (byte) ((((row2[ 2] - row1[ 2]) * lerp) >> 16)
							+ row1[ 2]);
					out[3] = (byte) ((((row2[ 3] - row1[ 3]) * lerp) >> 16)
							+ row1[ 3]);
					out += 4;
					row1 += 4;
					row2 += 4;
				}
				row1 -= outwidth*4;
				row2 -= outwidth*4;
			}
			else
			{
				if (yi != oldy)
				{
					inrow = (byte *)indata + inwidth*4*yi;
					if (yi == oldy+1)
						memcpy(row1, row2, outwidth*4);
					else
						R_ResampleTextureLerpLine (inrow, row1, inwidth,
								outwidth);
					oldy = yi;
				}
				memcpy(out, row1, outwidth * 4);
			}
		}
		free(row1);
		free(row2);
	}
	else
	{
		int i, j;
		unsigned frac, fracstep;
		unsigned int *inrow, *out;
		out = outdata;

		fracstep = inwidth*0x10000/outwidth;
		for (i = 0;i < outheight;i++)
		{
			inrow = (int *)indata + inwidth*(i*inheight/outheight);
			frac = fracstep >> 1;
			for (j = outwidth >> 2 ; j ; j--)
			{
				out[0] = inrow[frac >> 16]; frac += fracstep;
				out[1] = inrow[frac >> 16]; frac += fracstep;
				out[2] = inrow[frac >> 16]; frac += fracstep;
				out[3] = inrow[frac >> 16]; frac += fracstep;
				out += 4;
			}
			for (j = outwidth & 3 ; j ; j--)
			{
				*out = inrow[frac >> 16]; frac += fracstep;
				out++;
			}
		}
	}
}

/*
================
GL_Resample8BitTexture -- JACK
================
*/
void GL_Resample8BitTexture (unsigned char *in, int inwidth, int inheight, unsigned char *out,  int outwidth, int outheight)
{
	int		i, j;
	unsigned	char *inrow;
	unsigned	frac, fracstep;

	fracstep = inwidth*0x10000/outwidth;
	for (i=0 ; i<outheight ; i++, out += outwidth)
	{
		inrow = in + inwidth*(i*inheight/outheight);
		frac = fracstep >> 1;
		for (j=0 ; j<outwidth ; j+=4)
		{
			out[j] = inrow[frac>>16];
			frac += fracstep;
			out[j+1] = inrow[frac>>16];
			frac += fracstep;
			out[j+2] = inrow[frac>>16];
			frac += fracstep;
			out[j+3] = inrow[frac>>16];
			frac += fracstep;
		}
	}
}

/*
================
GL_MipMap

Operates in place, quartering the size of the texture
================
*/
void GL_MipMap (byte *in, int width, int height)
{
	int		i, j;
	byte	*out;

	width <<=2;
	height >>= 1;
	out = in;
	for (i=0 ; i<height ; i++, in+=width)
	{
		for (j=0 ; j<width ; j+=8, out+=4, in+=8)
		{
			out[0] = (in[0] + in[4] + in[width+0] + in[width+4])>>2;
			out[1] = (in[1] + in[5] + in[width+1] + in[width+5])>>2;
			out[2] = (in[2] + in[6] + in[width+2] + in[width+6])>>2;
			out[3] = (in[3] + in[7] + in[width+3] + in[width+7])>>2;
		}
	}
}

/*
================
GL_MipMap8Bit

Mipping for 8 bit textures
================
*/
void GL_MipMap8Bit (byte *in, int width, int height)
{
	int		i, j;
	byte	*out;
	unsigned short     r,g,b;
	byte	*at1, *at2, *at3, *at4;

	height >>= 1;
	out = in;
	for (i=0 ; i<height ; i++, in+=width)
		for (j=0 ; j<width ; j+=2, out+=1, in+=2)
		{
			at1 = (byte *) &d_8to24table[in[0]];
			at2 = (byte *) &d_8to24table[in[1]];
			at3 = (byte *) &d_8to24table[in[width+0]];
			at4 = (byte *) &d_8to24table[in[width+1]];

 			r = (at1[0]+at2[0]+at3[0]+at4[0]); r>>=5;
 			g = (at1[1]+at2[1]+at3[1]+at4[1]); g>>=5;
 			b = (at1[2]+at2[2]+at3[2]+at4[2]); b>>=5;

			out[0] = d_15to8table[(r<<0) + (g<<5) + (b<<10)];
		}
}

/*
===============
GL_Upload32
===============
*/
void GL_Upload32 (unsigned *data, int width, int height,  qboolean mipmap, qboolean alpha)
{
	int			samples;
static	unsigned	scaled[1024*512];	// [512*256];
	int			scaled_width, scaled_height;

	for (scaled_width = 1 ; scaled_width < width ; scaled_width<<=1)
		;
	for (scaled_height = 1 ; scaled_height < height ; scaled_height<<=1)
		;

	if (mipmap) {
		scaled_width >>= (int)gl_picmip.value;
		scaled_height >>= (int)gl_picmip.value;
	}

	if (scaled_width > gl_max_size.value)
		scaled_width = gl_max_size.value;
	if (scaled_height > gl_max_size.value)
		scaled_height = gl_max_size.value;
	if (scaled_width < 1)
		scaled_width = 1;
	if (scaled_height < 1)
		scaled_height = 1;

	if (scaled_width * scaled_height > sizeof(scaled)/4)
		Sys_Error ("GL_LoadTexture: too big");

	samples = alpha ? gl_alpha_format : gl_solid_format;

#if 0
	if (mipmap)
		gluBuild2DMipmaps (GL_TEXTURE_2D, samples, width, height, GL_RGBA, GL_UNSIGNED_BYTE, trans);
	else if (scaled_width == width && scaled_height == height)
		glTexImage2D (GL_TEXTURE_2D, 0, samples, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, trans);
	else
	{
		gluScaleImage (GL_RGBA, width, height, GL_UNSIGNED_BYTE, trans,
			scaled_width, scaled_height, GL_UNSIGNED_BYTE, scaled);
		glTexImage2D (GL_TEXTURE_2D, 0, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, scaled);
	}
#else
texels += scaled_width * scaled_height;

	if (scaled_width == width && scaled_height == height)
	{
		if (!mipmap)
		{
			glTexImage2D (GL_TEXTURE_2D, 0, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
			goto done;
		}
		memcpy (scaled, data, width*height*4);
	}
	else
		GL_ResampleTexture (data, width, height, scaled, scaled_width, scaled_height);

	glTexImage2D (GL_TEXTURE_2D, 0, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, scaled);
	if (mipmap)
	{
		int		miplevel;

		miplevel = 0;
		while (scaled_width > 1 || scaled_height > 1)
		{
			GL_MipMap ((byte *)scaled, scaled_width, scaled_height);
			scaled_width >>= 1;
			scaled_height >>= 1;
			if (scaled_width < 1)
				scaled_width = 1;
			if (scaled_height < 1)
				scaled_height = 1;
			miplevel++;
			glTexImage2D (GL_TEXTURE_2D, miplevel, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, scaled);
		}
	}
done: ;
#endif


	if (mipmap)
	{
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
	}
	else
	{
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_max);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
	}
}

void GL_Upload8_EXT (byte *data, int width, int height,  qboolean mipmap, qboolean alpha) 
{
	int			i, s;
	qboolean	noalpha;
	int			samples;
    static	unsigned char scaled[1024*512];	// [512*256];
	int			scaled_width, scaled_height;

	s = width*height;
	// if there are no transparent pixels, make it a 3 component
	// texture even if it was specified as otherwise
	if (alpha)
	{
		noalpha = true;
		for (i=0 ; i<s ; i++)
		{
			if (data[i] == 255)
				noalpha = false;
		}

		if (alpha && noalpha)
			alpha = false;
	}
	for (scaled_width = 1 ; scaled_width < width ; scaled_width<<=1)
		;
	for (scaled_height = 1 ; scaled_height < height ; scaled_height<<=1)
		;

	if (mipmap) {
		scaled_width >>= (int)gl_picmip.value;
		scaled_height >>= (int)gl_picmip.value;
	}

	if (scaled_width > gl_max_size.value)
		scaled_width = gl_max_size.value;
	if (scaled_height > gl_max_size.value)
		scaled_height = gl_max_size.value;
	if (scaled_width < 1)
		scaled_width = 1;
	if (scaled_height < 1)
		scaled_height = 1;

	if (scaled_width * scaled_height > sizeof(scaled))
		Sys_Error ("GL_LoadTexture: too big");

	samples = 1; // alpha ? gl_alpha_format : gl_solid_format;

	texels += scaled_width * scaled_height;

	if (scaled_width == width && scaled_height == height)
	{
		if (!mipmap)
		{
			glTexImage2D (GL_TEXTURE_2D, 0, GL_COLOR_INDEX8_EXT, scaled_width, scaled_height, 0, GL_COLOR_INDEX , GL_UNSIGNED_BYTE, data);
			goto done;
		}
		memcpy (scaled, data, width*height);
	}
	else
		GL_Resample8BitTexture (data, width, height, scaled, scaled_width, scaled_height);

	glTexImage2D (GL_TEXTURE_2D, 0, GL_COLOR_INDEX8_EXT, scaled_width, scaled_height, 0, GL_COLOR_INDEX, GL_UNSIGNED_BYTE, scaled);
	if (mipmap)
	{
		int		miplevel;

		miplevel = 0;
		while (scaled_width > 1 || scaled_height > 1)
		{
			GL_MipMap8Bit ((byte *)scaled, scaled_width, scaled_height);
			scaled_width >>= 1;
			scaled_height >>= 1;
			if (scaled_width < 1)
				scaled_width = 1;
			if (scaled_height < 1)
				scaled_height = 1;
			miplevel++;
			glTexImage2D (GL_TEXTURE_2D, miplevel, GL_COLOR_INDEX8_EXT, scaled_width, scaled_height, 0, GL_COLOR_INDEX, GL_UNSIGNED_BYTE, scaled);
		}
	}
done: ;

	if (mipmap)
	{
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
	}
	else
	{
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_max);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
	}
}

extern qboolean VID_Is8bit();

/*
===============
GL_Upload8
===============
*/
void GL_Upload8 (byte *data, int width, int height,  qboolean mipmap, qboolean alpha, qboolean brighten)
{
static	unsigned	trans[640*480];		// FIXME, temporary
	int			i, s;
	qboolean	noalpha;
	int			p;
	unsigned	*table;

	if (brighten)
		table = d_8to24table2;
	else
		table = d_8to24table;

	s = width*height;

	if (alpha == 2)
	{
	// this is a fullbright mask, so make all non-fullbright
	// colors transparent
		for (i=0 ; i<s ; i++)
		{
			p = data[i];
			if (p < 224)
				trans[i] = table[p] & 0x00FFFFFF; // transparent 
			else
				trans[i] = table[p];	// fullbright
		}
	}
	else if (alpha)
	{
	// if there are no transparent pixels, make it a 3 component
	// texture even if it was specified as otherwise
		noalpha = true;
		for (i=0 ; i<s ; i++)
		{
			p = data[i];
			if (p == 255)
				noalpha = false;
			trans[i] = table[p];
		}

		if (alpha && noalpha)
			alpha = false;
	}
	else
	{
		if (s&3)
			Sys_Error ("GL_Upload8: s&3");
		for (i=0 ; i<s ; i+=4)
		{
			trans[i] = table[data[i]];
			trans[i+1] = table[data[i+1]];
			trans[i+2] = table[data[i+2]];
			trans[i+3] = table[data[i+3]];
		}
	}

	if (VID_Is8bit() && !alpha && (data!=scrap_texels[0])) {
		GL_Upload8_EXT (data, width, height, mipmap, alpha);
		return;
	}

	GL_Upload32 (trans, width, height, mipmap, alpha);
}

/*
================
GL_LoadTexture
================
*/
int GL_LoadTexture (char *identifier, int width, int height, byte *data, qboolean mipmap, qboolean alpha, qboolean brighten)
{
	int			i;
	unsigned	crc;
	gltexture_t	*glt;

	if (lightmode != 2)
		brighten = false;

	// see if the texture is already present
	if (identifier[0]) {
		crc = CRC_Block (data, width*height);
		for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++) {
			if (!strncmp (identifier, glt->identifier, sizeof(glt->identifier)-1)) {
				if (width == glt->width && height == glt->height
					&& crc == glt->crc && brighten == glt->brighten)
					return gltextures[i].texnum;
				else
					goto setuptexture;	// reload the texture into the same slot
			}
		}
	}
	else
		glt = &gltextures[numgltextures];

	if (numgltextures == MAX_GLTEXTURES)
		Sys_Error ("GL_LoadTexture: numgltextures == MAX_GLTEXTURES");
	numgltextures++;

	Q_strncpyz (glt->identifier, identifier, sizeof(glt->identifier));
	glt->texnum = texture_extension_number;
	texture_extension_number++;

setuptexture:
	glt->width = width;
	glt->height = height;
	glt->mipmap = mipmap;
	glt->brighten = brighten;
	glt->crc = crc;

	GL_Bind (glt->texnum);

	GL_Upload8 (data, width, height, mipmap, alpha, brighten);

	return glt->texnum;
}

/*
================
GL_LoadPicTexture

================
*/
int GL_LoadPicTexture (char *name, mpic_t *pic, byte *data)
{
	int		glwidth, glheight;
	int		i;
	char	fullname[64] = "pic:";

	Q_strncpyz (fullname + 4, name, sizeof(fullname)-4);

	for (glwidth = 1 ; glwidth < pic->width ; glwidth<<=1)
		;
	for (glheight = 1 ; glheight < pic->height ; glheight<<=1)
		;

	if (glwidth == pic->width && glheight == pic->height)
	{
		pic->texnum = GL_LoadTexture (fullname, glwidth, glheight, data,
						false, true, false);
		pic->sl = 0;
		pic->sh = 1;
		pic->tl = 0;
		pic->th = 1;
	}
	else
	{
		byte *src, *dest;
		byte *buf;

		buf = Q_Malloc (glwidth*glheight);

		memset (buf, 0, glwidth*glheight);
		src = data;
		dest = buf;
		for (i=0 ; i<pic->height ; i++) {
			memcpy (dest, src, pic->width);
			src += pic->width;
			dest += glwidth;
		}

		pic->texnum = GL_LoadTexture ("", glwidth, glheight, buf,
						false, true, false);
		pic->sl = 0;
		pic->sh = (float)pic->width / glwidth;
		pic->tl = 0;
		pic->th = (float)pic->height / glheight;

		free (buf);
	}

	return pic->texnum;
}

/****************************************/

static GLenum oldtarget = TEXTURE0_ARB;

void GL_SelectTexture (GLenum target) 
{
	if (!gl_mtexable)
		return;
#ifndef __linux__ // no multitexture under Linux yet
	qglActiveTexture (target);
#endif
	if (target == oldtarget) 
		return;
	cnttextures[oldtarget-TEXTURE0_ARB] = currenttexture;
	currenttexture = cnttextures[target-TEXTURE0_ARB];
	oldtarget = target;
}
