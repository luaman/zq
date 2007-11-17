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
// render.h -- public interface to rendering functions
#ifndef _RENDER_H_
#define _RENDER_H_

#define	TOP_RANGE		16			// soldier uniform colors
#define	BOTTOM_RANGE	96

#define	MAX_VISEDICTS			256
#define MAX_PARTICLES			4096	// default max # of particles at one
										// time

// entity->renderfx
#define RF_WEAPONMODEL	1
#define RF_PLAYERMODEL	2
#define RF_TRANSLUCENT	4
#define RF_LIMITLERP	8

//=============================================================================

typedef struct
{
	int		length;
	char	map[64];
} lightstyle_t;


#define	MAX_DLIGHTS		32

typedef enum {	lt_default,
				lt_blue, lt_green, lt_cyan, lt_red, lt_redblue, lt_yellow, lt_white,
				lt_muzzleflash,
				lt_explosion, lt_rocket, NUM_DLIGHTTYPES
} dlighttype_t;

typedef struct
{
	int				key;		// FIXME
	vec3_t			origin;
	float			radius;
	float			minlight;
	dlighttype_t	type;
} dlight_t;

typedef struct entity_s
{
	vec3_t					origin;
	vec3_t					angles;
	struct model_s			*model;			// NULL = no model
	int						frame;
	int						oldframe;		// frame to lerp from
	float					backlerp;
	int						colormap;
	int						skinnum;		// for alias models
	int						renderfx;		// RF_WEAPONMODEL, etc
	float					alpha;

	int						visframe;		// last frame this entity was
											// found in an active leaf
											// only used for static objects

// FIXME: could turn these into a union
	int						trivial_accept;
	struct mnode_s			*topnode;		// for bmodels, first world node
											//  that splits bmodel, or NULL if
											//  not split
} entity_t;

// !!! if this is changed, it must be changed in d_ifacea.h too !!!
typedef struct particle_s
{
	vec3_t		org;
	int			color;
	float		alpha;
} particle_t;


typedef struct translation_info_s {
	int		topcolor;
	int		bottomcolor;
	char	skinname[32];
} translation_info_t;


// eye position, enitiy list, etc - filled in before calling R_RenderView
typedef struct {
	vrect_t			vrect;			// subwindow in video for refresh

	vec3_t			vieworg;
	vec3_t			viewangles;
	float			fov_x, fov_y;

	float			time;
	qbool			allow_cheats;
	qbool			allow_fbskins;
	int				viewplayernum;	// don't draw own glow when gl_flashblend 1
	qbool			watervis;

	lightstyle_t	*lightstyles;
	int				numDlights;
	dlight_t		*dlights;
	int				numParticles;
	particle_t		*particles;
	int				num_entities;
	entity_t		*entities;

	translation_info_t	*translations;	// [MAX_CLIENTS]
	char			baseskin[32];
} refdef2_t;


typedef struct mpic_s
{
	int			width;
	int			height;
	qbool		alpha;	// will be true if there are any transparent pixels
} mpic_t;

//====================================================


//
// refresh
//
EXTERNC_START
extern refdef2_t	r_refdef2;
EXTERNC_END

EXTERNC void R_Init (unsigned char *palette);
EXTERNC void R_InitTextures (void);
EXTERNC void R_NewMap (struct model_s *model_precache[MAX_MODELS]);
#ifdef GLQUAKE
void R_AddStaticEntity (entity_t *ent);
#else
#define R_AddStaticEntity(ent)
#endif
EXTERNC void R_RenderView (void);			// must set r_refdef first
EXTERNC void R_SetSky (const char *name);	// Quake2 skybox

EXTERNC void R_PushDlights (void);

// memory pointed to by pcxdata is allocated using Hunk_TempAlloc
// never store this pointer for later use!
EXTERNC void R_RSShot (byte **pcxdata, int *pcxsize);

//
// surface cache related
//
EXTERNC_START
extern qbool	r_cache_thrash;	// set if thrashing the surface cache
EXTERNC_END

EXTERNC int	D_SurfaceCacheForRes (int width, int height);
EXTERNC void D_FlushCaches (void);
EXTERNC void D_InitCaches (void *buffer, int size);

// 2D drawing functions
EXTERNC void R_DrawChar (int x, int y, int num);
EXTERNC void R_DrawCharW (int x, int y, wchar num);
EXTERNC void R_DrawString (int x, int y, const char *str);
EXTERNC void R_DrawStringW (int x, int y, const wchar *ws);
#ifdef __cplusplus
inline void R_DrawString (int x, int y, const string s) { R_DrawString(x, y, s.c_str()); }
inline void R_DrawStringW (int x, int y, const wstring s) { R_DrawStringW(x, y, s.c_str()); }
#endif
EXTERNC void R_DrawPixel (int x, int y, byte color);
EXTERNC void R_DrawPic (int x, int y, mpic_t *pic);
EXTERNC void R_DrawSubPic (int x, int y, mpic_t *pic, int srcx, int srcy, int width, int height);
EXTERNC void R_DrawTransPicTranslate (int x, int y, mpic_t *pic, byte *translation);
EXTERNC void R_DrawFilledRect (int x, int y, int w, int h, int c);
EXTERNC void R_DrawTile (int x, int y, int w, int h, mpic_t *pic);
EXTERNC void R_FadeScreen (void);
EXTERNC void R_DrawDebugChar (char num);
EXTERNC void R_BeginDisc (void);
EXTERNC void R_EndDisc (void);
EXTERNC mpic_t *R_CachePic (char *path);
EXTERNC mpic_t *R_CacheWadPic (char *name);
EXTERNC void R_FlushPics (void);
EXTERNC void R_DrawStretchPic (int x, int y, int width, int height, mpic_t *pic, float alpha);
EXTERNC void R_DrawCrosshair (int num, int crossx, int crossy);

#define GetPicWidth(pic) (pic->width)
#define GetPicHeight(pic) (pic->height)

// model flags
#define	MF_ROCKET	1			// leave a trail
#define	MF_GRENADE	2			// leave a trail
#define	MF_GIB		4			// leave a trail
#define	MF_ROTATE	8			// rotate (bonus items)
#define	MF_TRACER	16			// green split trail
#define	MF_ZOMGIB	32			// small blood trail
#define	MF_TRACER2	64			// orange split trail + rotate
#define	MF_TRACER3	128			// purple trail

EXTERNC void Mod_ClearAll (void);
EXTERNC void Mod_TouchModel (const char *name);
EXTERNC struct model_s *Mod_ForName (const char *name, qbool crash, qbool worldmodel);
EXTERNC int R_ModelFlags (const struct model_s *model);
EXTERNC unsigned short R_ModelChecksum (const struct model_s *model);
EXTERNC void R_LoadModelTextures (struct model_s *m);

EXTERNC void V_SetContentsColor (int contents);	// this is a callback from R_RenderView to the client

#endif /* _RENDER_H_ */

