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
// gl_texture.c - GL texture management

#include "gl_local.h"
#include "crc.h"
#include "version.h"
#include "rc_pixops.h"

#ifdef MINGW32
#include <GL/glext.h>	// GL_COLOR_INDEX8_EXT is defined here
#endif /* MINGW32 */


unsigned d_8to24table[256];
unsigned d_8to24table2[256];

static void	OnChange_gl_texturemode (cvar_t *var, char *string, qbool *cancel);

cvar_t		gl_nobind = {"gl_nobind", "0"};
cvar_t		gl_picmip = {"gl_picmip", "0"};
cvar_t		gl_texturemode = {"gl_texturemode", "GL_LINEAR_MIPMAP_NEAREST", 0, OnChange_gl_texturemode};

int		texture_extension_number = 1;

int		gl_lightmap_format = 4;
int		gl_solid_format = 3;
int		gl_alpha_format = 4;

int		gl_filter_min = GL_LINEAR_MIPMAP_NEAREST;
int		gl_filter_max = GL_LINEAR;

int		gl_max_texsize;

int		texels;

extern byte	scrap_texels[2][256*256*4];	// FIXME FIXME FIXME

typedef struct
{
	int		texnum;
	char	identifier[64];
	int		width, height;
	int		scaled_width, scaled_height;
	int		mode;
	unsigned	crc;
} gltexture_t;

gltexture_t	gltextures[MAX_GLTEXTURES];
int			numgltextures;

qbool	mtexenabled = false;

#ifdef _WIN32
lpMTexFUNC qglMultiTexCoord2f = NULL;
lpSelTexFUNC qglActiveTexture = NULL;
#endif

void GL_Bind (int texnum)
{
	extern int char_textures[1];

	if (gl_nobind.value)
		texnum = char_textures[0];
	if (currenttexture == texnum)
		return;
	currenttexture = texnum;
#ifdef _WIN32
	bindTexFunc (GL_TEXTURE_2D, texnum);
#else
	glBindTexture (GL_TEXTURE_2D, texnum);
#endif
}

static GLenum oldtarget = GL_TEXTURE0_ARB;

void GL_SelectTexture (GLenum target)
{
	if (!gl_mtexable)
		return;
#ifdef _WIN32 // no multitexture under Linux or Darwin yet
	qglActiveTexture (target);
#endif
	if (target == oldtarget)
		return;
	cnttextures[oldtarget-GL_TEXTURE0_ARB] = currenttexture;
	currenttexture = cnttextures[target-GL_TEXTURE0_ARB];
	oldtarget = target;
}

void GL_DisableMultitexture (void)
{
	if (mtexenabled) {
		glDisable (GL_TEXTURE_2D);
		GL_SelectTexture (GL_TEXTURE0_ARB);
		mtexenabled = false;
	}
}

void GL_EnableMultitexture (void)
{
	if (gl_mtexable) {
		GL_SelectTexture (GL_TEXTURE1_ARB);
		glEnable (GL_TEXTURE_2D);
		mtexenabled = true;
	}
}


//====================================================================

typedef struct
{
	char *name;
	int	minimize, maximize;
} glmode_t;

static glmode_t modes[] = {
	{"GL_NEAREST", GL_NEAREST, GL_NEAREST},
	{"GL_LINEAR", GL_LINEAR, GL_LINEAR},
	{"GL_NEAREST_MIPMAP_NEAREST", GL_NEAREST_MIPMAP_NEAREST, GL_NEAREST},
	{"GL_LINEAR_MIPMAP_NEAREST", GL_LINEAR_MIPMAP_NEAREST, GL_LINEAR},
	{"GL_NEAREST_MIPMAP_LINEAR", GL_NEAREST_MIPMAP_LINEAR, GL_NEAREST},
	{"GL_LINEAR_MIPMAP_LINEAR", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR}
};


static void OnChange_gl_texturemode (cvar_t *var, char *string, qbool *cancel)
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
		*cancel = true;		// don't change the cvar
		return;
	}

	gl_filter_min = modes[i].minimize;
	gl_filter_max = modes[i].maximize;

	// change all the existing mipmap texture objects
	for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++)
	{
		if (glt->mode & TEX_MIPMAP)
		{
			GL_Bind (glt->texnum);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, gl_filter_min);
			glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, gl_filter_max);
		}
	}
}


//====================================================================

void R_SetPalette (unsigned char *palette)
{
	int			i;
	byte		*pal;
	unsigned	r,g,b;
	unsigned	v;
	unsigned	*table;

//
// 8 8 8 encoding
//
	pal = palette;
	table = d_8to24table;
	for (i=0 ; i<256 ; i++)
	{
		r = pal[0];
		g = pal[1];
		b = pal[2];
		pal += 3;

//		v = (255<<24) + (r<<16) + (g<<8) + (b<<0);
//		v = (255<<0) + (r<<8) + (g<<16) + (b<<24);
		v = (255<<24) + (r<<0) + (g<<8) + (b<<16);
		*table++ = v;
	}
	d_8to24table[255] = 0;	// 255 is transparent

// Tonik: create a brighter palette for bmodel textures
	pal = palette;
	table = d_8to24table2;

	for (i=0 ; i<256 ; i++)
	{
		r = pal[0] * (2.0 / 1.5); if (r > 255) r = 255;
		g = pal[1] * (2.0 / 1.5); if (g > 255) g = 255;
		b = pal[2] * (2.0 / 1.5); if (b > 255) b = 255;
		pal += 3;
		*table++ = (255<<24) + (r<<0) + (g<<8) + (b<<16);
	}
	d_8to24table2[255] = 0;	// 255 is transparent
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


/*
================
GL_ResampleTexture

Copyright (C) 2005 Anton 'Tonik' Gavrilov

Look what I can do in two lines of code!
Perhaps I should sell a supported version for a living.
================
*/
void GL_ResampleTexture (unsigned *indata, int inwidth, int inheight,
		unsigned *outdata, int outwidth, int outheight)
{
	_pixops_scale ((guchar *)outdata, 0, 0, outwidth, outheight, outwidth * 4, 4, 1, (const guchar *)indata,
		inwidth, inheight, inwidth * 4, 4, 1, (double)outwidth/inwidth, (double)outheight/inheight, PIXOPS_INTERP_BILINEAR);
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

static void
ScaleDimensions (int width, int height, int *scaled_width, int *scaled_height, int mode)
{
	int picmip;
	qbool scale;

	scale = (mode & TEX_MIPMAP) && !(mode & TEX_NOSCALE);

	for (*scaled_width = 1; *scaled_width < width; *scaled_width <<= 1) {};
	for (*scaled_height = 1; *scaled_height < height; *scaled_height <<= 1) {};

	if (scale) {
		picmip = (int) bound(0, gl_picmip.value, 16);
		*scaled_width >>= picmip;
		*scaled_height >>= picmip;		
	}

	*scaled_width = bound(1, *scaled_width, gl_max_texsize);
	*scaled_height = bound(1, *scaled_height, gl_max_texsize);
}


/*
===============
GL_Upload32

Accepts TEX_MIPMAP, TEX_ALPHA, TEX_NOSCALE
===============
*/
void GL_Upload32 (unsigned *data, int width, int height, int mode /*qbool mipmap, qbool alpha*/)
{
	int			samples;
static	unsigned	scaled[1024*512];	// [512*256];
	int			scaled_width, scaled_height;

	ScaleDimensions (width, height, &scaled_width, &scaled_height, mode);

	if (scaled_width * scaled_height > sizeof(scaled)/4)
		Sys_Error ("GL_LoadTexture: too big");

	samples = (mode & TEX_ALPHA) ? gl_alpha_format : gl_solid_format;

	texels += scaled_width * scaled_height;

	if (scaled_width == width && scaled_height == height)
	{
		if (!(mode & TEX_MIPMAP))
		{
			glTexImage2D (GL_TEXTURE_2D, 0, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
			goto done;
		}
		memcpy (scaled, data, width*height*4);
	}
	else
		GL_ResampleTexture (data, width, height, scaled, scaled_width, scaled_height);

	glTexImage2D (GL_TEXTURE_2D, 0, samples, scaled_width, scaled_height, 0, GL_RGBA, GL_UNSIGNED_BYTE, scaled);
	if (mode & TEX_MIPMAP)
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


	if (mode & TEX_MIPMAP)
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

/*
===============
GL_Upload8

Accepts TEX_MIPMAP, TEX_ALPHA, TEX_FULLBRIGHTMASK, TEX_BRIGHTEN, TEX_NOSCALE
===============
*/
void GL_Upload8 (byte *data, int width, int height, int mode)
{
	static	unsigned	trans[640*480];		// FIXME, temporary
	int			i, s;
	qbool		noalpha;
	int			p;
	unsigned	*table;

	if (mode & TEX_BRIGHTEN)
		table = d_8to24table2;
	else
		table = d_8to24table;

	s = width*height;

	if (mode & TEX_FULLBRIGHTMASK)
	{
		mode |= TEX_ALPHA;
	// this is a fullbright mask, so make all non-fullbright
	// colors transparent
		for (i=0 ; i<s ; i++)
		{
			p = data[i];
			if (p < 224)
				trans[i] = table[p] & LittleLong(0x00FFFFFF); // transparent
			else
				trans[i] = table[p];	// fullbright
		}
	}
	else if (mode & TEX_ALPHA)
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

		if (noalpha)
			mode &= ~TEX_ALPHA;
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

	GL_Upload32 (trans, width, height, mode);
}

/*
================
GL_LoadTexture

Accepts TEX_MIPMAP, TEX_ALPHA, TEX_FULLBRIGHTMASK, TEX_BRIGHTEN, TEX_NOSCALE
================
*/
int GL_LoadTexture (char *identifier, int width, int height, byte *data, int mode)
{
	int i, scaled_width, scaled_height;
	unsigned	crc = 0;
	gltexture_t	*glt;

	if (lightmode != 2)
		mode &= ~TEX_BRIGHTEN;

	ScaleDimensions (width, height, &scaled_width, &scaled_height, mode);

	// see if the texture is already present
	if (identifier[0]) {
		crc = CRC_Block (data, width*height);
		for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++) {
			if (!strncmp (identifier, glt->identifier, sizeof(glt->identifier)-1)) {
				if (width == glt->width && height == glt->height
					&& crc == glt->crc && (mode & TEX_BRIGHTEN) == (glt->mode & TEX_BRIGHTEN)
					&& scaled_width == glt->scaled_width && scaled_height == glt->scaled_height)
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

	strlcpy (glt->identifier, identifier, sizeof(glt->identifier));
	glt->texnum = texture_extension_number;
	texture_extension_number++;

setuptexture:
	glt->width = width;
	glt->height = height;
	glt->scaled_width = scaled_width;
	glt->scaled_height = scaled_height;
	glt->mode = mode;
	glt->crc = crc;

	GL_Bind (glt->texnum);

	GL_Upload8 (data, width, height, mode);

	return glt->texnum;
}


/*
================
GL_LoadTexture32

Accepts TEX_MIPMAP, TEX_ALPHA, TEX_BRIGHTEN(FIXME not yet), TEX_NOSCALE

FIXME: merge with GL_LoadTexture
================
*/
int GL_LoadTexture32 (char *identifier, int width, int height, byte *data, int mode)
{
	int			i;
	unsigned	crc = 0;
	gltexture_t	*glt;

//	if (lightmode != 2)
		mode &= ~TEX_BRIGHTEN;

	// see if the texture is already present
	if (identifier[0]) {
		crc = CRC_Block (data, width*height);
		for (i=0, glt=gltextures ; i<numgltextures ; i++, glt++) {
			if (!strncmp (identifier, glt->identifier, sizeof(glt->identifier)-1)) {
				if (width == glt->width && height == glt->height
					&& crc == glt->crc && ((mode & TEX_BRIGHTEN) == (glt->mode & TEX_BRIGHTEN)))
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

	strlcpy (glt->identifier, identifier, sizeof(glt->identifier));
	glt->texnum = texture_extension_number;
	texture_extension_number++;

setuptexture:
	glt->width = width;
	glt->height = height;
	glt->mode = mode;
	glt->crc = crc;

	GL_Bind (glt->texnum);

	GL_Upload32 ((unsigned int *)data, width, height, mode);

	return glt->texnum;
}


static void R_InitParticleTexture (void)
{
	int		i, x, y;
	unsigned int	data[32][32];

	particletexture = texture_extension_number++;
    GL_Bind (particletexture);

	// clear to transparent white
	for (i=0 ; i<32*32 ; i++)
		((unsigned *)data)[i] = LittleLong(0x00FFFFFF);

	// draw a circle in the top left corner
	for (x=0 ; x<16 ; x++)
		for (y=0 ; y<16 ; y++) {
			if ((x - 7.5)*(x - 7.5) + (y - 7.5)*(y - 7.5) <= 8*8)
				data[y][x] = LittleLong(0xFFFFFFFF);	// solid white
		}

	glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_MODULATE);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);
	glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	GL_Upload32 ((unsigned *) data, 32, 32, TEX_MIPMAP|TEX_ALPHA);
}


static void R_InitDefaultTexture (void)
{
	int		x,y, m;
	byte	*dest;

// create a simple checkerboard texture for the default
	r_notexture_mip = Hunk_AllocName (sizeof(texture_t) + 16*16+8*8+4*4+2*2, "notexture");

	r_notexture_mip->width = r_notexture_mip->height = 16;
	r_notexture_mip->offsets[0] = sizeof(texture_t);
	r_notexture_mip->offsets[1] = r_notexture_mip->offsets[0] + 16*16;
	r_notexture_mip->offsets[2] = r_notexture_mip->offsets[1] + 8*8;
	r_notexture_mip->offsets[3] = r_notexture_mip->offsets[2] + 4*4;

	for (m=0 ; m<4 ; m++)
	{
		dest = (byte *)r_notexture_mip + r_notexture_mip->offsets[m];
		for (y=0 ; y< (16>>m) ; y++)
			for (x=0 ; x< (16>>m) ; x++)
			{
				if (  (y< (8>>m) ) ^ (x< (8>>m) ) )
					*dest++ = 0;
				else
					*dest++ = 15;
			}
	}
}


/*
===============
R_InitTextures
===============
*/
void R_InitTextures (void)
{
	Cvar_Register (&gl_nobind);
	Cvar_Register (&gl_picmip);
	Cvar_Register (&gl_texturemode);

	texture_extension_number = 1;
	numgltextures = 0;

	// get the maximum texture size from driver
	glGetIntegerv (GL_MAX_TEXTURE_SIZE, (GLint *) &gl_max_texsize);

	GL_AllocTextureSlots ();

	R_InitDefaultTexture ();
	R_InitParticleTexture ();

}

/* vi: set noet ts=4 sts=4 ai sw=4: */
