/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the included (GNU.txt) GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/

#ifndef __GL_TEXTURE_H
#define __GL_TEXTURE_H

#define MAX_GLTEXTURES 1024

// texture "mode" mask, passed to upload functions
#define TEX_MIPMAP			1
#define TEX_ALPHA			2
#define	TEX_BRIGHTEN		4

void GL_Upload32 (unsigned *data, int width, int height,  qbool mipmap, qbool alpha);
void GL_Upload8 (byte *data, int width, int height,  qbool mipmap, qbool alpha, qbool brighten);
int GL_LoadTexture (char *identifier, int width, int height, byte *data, qbool mipmap, qbool alpha, qbool brighten);
int GL_LoadTexture32 (char *identifier, int width, int height, byte *data, qbool mipmap, qbool alpha, qbool brighten);
int GL_FindTexture (char *identifier);
//int GL_LoadPicTexture (char *name, mpic_t *pic, byte *data);


void GL_Bind (int texnum);

void GL_SelectTexture (GLenum target);
void GL_DisableMultitexture (void);
void GL_EnableMultitexture (void);

/*
// here's what FuhQuake has...
void GL_Upload8 (byte *data, int width, int height, int mode);
void GL_Upload32 (unsigned *data, int width, int height, int mode);
int GL_LoadTexture (char *identifier, int width, int height, byte *data, int mode, int bpp);

byte *GL_LoadImagePixels (char *, int, int, int);
int GL_LoadTexturePixels (byte *, char *, int, int, int);
int GL_LoadTextureImage (char * , char *, int, int, int);
mpic_t *GL_LoadPicImage (char *, char *, int, int, int);
int GL_LoadCharsetImage (char *, char *);

void GL_Texture_Init(void);
*/

extern int gl_lightmap_format, gl_solid_format, gl_alpha_format;

extern int currenttexture;
extern int cnttextures[2];

extern int gl_max_texsize;

extern int texture_extension_number;

#endif	//__GL_TEXTURE_H
