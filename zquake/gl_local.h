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
// gl_local.h -- private refresh defs

#include "quakedef.h"		// FIXME
#include "gl_model.h"

// disable data conversion warnings

#pragma warning(disable : 4244)		// MIPS
#pragma warning(disable : 4136)		// X86
#pragma warning(disable : 4051)		// ALPHA

#ifdef _WIN32
#include <windows.h>
#endif

#include <GL/gl.h>

void GL_EndRendering (void);


// Function prototypes for the Texture Object Extension routines
typedef GLboolean (APIENTRY *ARETEXRESFUNCPTR)(GLsizei, const GLuint *,
                    const GLboolean *);
typedef void (APIENTRY *BINDTEXFUNCPTR)(GLenum, GLuint);
typedef void (APIENTRY *DELTEXFUNCPTR)(GLsizei, const GLuint *);
typedef void (APIENTRY *GENTEXFUNCPTR)(GLsizei, GLuint *);
typedef GLboolean (APIENTRY *ISTEXFUNCPTR)(GLuint);
typedef void (APIENTRY *PRIORTEXFUNCPTR)(GLsizei, const GLuint *,
                    const GLclampf *);
typedef void (APIENTRY *TEXSUBIMAGEPTR)(int, int, int, int, int, int, int, int, void *);

extern	BINDTEXFUNCPTR bindTexFunc;
extern	DELTEXFUNCPTR delTexFunc;
extern	TEXSUBIMAGEPTR TexSubImage2DFunc;

extern	int texture_extension_number;

extern	float	gldepthmin, gldepthmax;

#define MAX_GLTEXTURES 1024

void GL_Upload32 (unsigned *data, int width, int height,  qbool mipmap, qbool alpha);
void GL_Upload8 (byte *data, int width, int height,  qbool mipmap, qbool alpha, qbool brighten);
void GL_Upload8_EXT (byte *data, int width, int height,  qbool mipmap, qbool alpha);
int GL_LoadTexture (char *identifier, int width, int height, byte *data, qbool mipmap, qbool alpha, qbool brighten);
int GL_LoadTexture32 (char *identifier, int width, int height, byte *data, qbool mipmap, qbool alpha, qbool brighten);
int GL_FindTexture (char *identifier);

typedef struct
{
	float	x, y, z;
	float	s, t;
	float	r, g, b;
} glvert_t;

extern glvert_t glv;

#ifdef _WIN32
extern	PROC glArrayElementEXT;
extern	PROC glColorPointerEXT;
extern	PROC glTexturePointerEXT;
extern	PROC glVertexPointerEXT;
#endif

#define ALIAS_BASE_SIZE_RATIO		(1.0 / 11.0)
					// normalizing factor so player model works out to about
					//  1 pixel per triangle
#define	MAX_LBM_HEIGHT		480

#define TILE_SIZE		128		// size of textures generated by R_GenTiledSurf

#define SKYSHIFT		7
#define	SKYSIZE			(1 << SKYSHIFT)
#define SKYMASK			(SKYSIZE - 1)

#define BACKFACE_EPSILON	0.01


void R_TimeRefresh_f (void);
texture_t *R_TextureAnimation (texture_t *base);

//====================================================


extern model_t		*r_worldmodel;
extern entity_t		r_worldentity;
extern qbool		r_cache_thrash;		// compatability
extern vec3_t		modelorg, r_entorigin;
extern entity_t		*currententity;
extern int			r_visframecount;
extern int			r_framecount;
extern mplane_t		frustum[4];
extern int			c_brush_polys, c_alias_polys;


//
// view origin
//
extern	vec3_t	vup;
extern	vec3_t	vpn;
extern	vec3_t	vright;
extern	vec3_t	r_origin;

//
// screen size info
//
extern	refdef_t	r_refdef;
extern	mleaf_t		*r_viewleaf, *r_oldviewleaf;
extern	mleaf_t		*r_viewleaf2, *r_oldviewleaf2;	// for watervis hack
extern	texture_t	*r_notexture_mip;
extern	int		d_lightstylevalue[256];	// 8.8 fraction of base light value

extern	int	currenttexture;
extern	int	cnttextures[2];
extern	int	particletexture;
extern	int	netgraphtexture;
extern	int	playertextures;
extern	int	playerfbtextures[MAX_CLIENTS];
extern	int	skyboxtextures;

extern	int	skytexturenum;		// index in cl.loadmodel, not gl texture object

extern	cvar_t	r_norefresh;
extern	cvar_t	r_drawentities;
extern	cvar_t	r_drawworld;
extern	cvar_t	r_drawflame;
extern	cvar_t	r_speeds;
extern	cvar_t	r_fullbright;
extern	cvar_t	r_lightmap;
extern	cvar_t	r_shadows;
extern	cvar_t	r_wateralpha;
extern	cvar_t	r_dynamic;
extern	cvar_t	r_novis;
extern	cvar_t	r_netgraph;
extern	cvar_t	r_fullbrightSkins;
extern	cvar_t	r_fastsky;
extern	cvar_t	r_skycolor;

extern	cvar_t	gl_subdivide_size;
extern	cvar_t	gl_clear;
extern	cvar_t	gl_cull;
extern	cvar_t	gl_texsort;
extern	cvar_t	gl_smoothmodels;
extern	cvar_t	gl_affinemodels;
extern	cvar_t	gl_polyblend;
extern	cvar_t	gl_flashblend;
extern	cvar_t	gl_nocolors;
extern	cvar_t	gl_finish;
extern	cvar_t	gl_fb_depthhack;
extern	cvar_t	gl_fb_bmodels;
extern	cvar_t	gl_fb_models;
extern	cvar_t	gl_colorlights;
extern	cvar_t	gl_loadlitfiles;
extern	cvar_t	gl_contrast;
extern	cvar_t	gl_gamma;
extern	cvar_t	gl_lightmode;
extern	cvar_t	gl_solidparticles;

extern	int		lightmode;		// set to gl_lightmode on mapchange

extern	int		gl_lightmap_format;
extern	int		gl_solid_format;
extern	int		gl_alpha_format;

extern	cvar_t	gl_playermip;

extern	float	r_world_matrix[16];

extern	const char *gl_vendor;
extern	const char *gl_renderer;
extern	const char *gl_version;
extern	const char *gl_extensions;

extern	int		gl_max_texsize;

void R_TranslatePlayerSkin (int playernum);

void GL_Bind (int texnum);
void GL_SelectTexture (GLenum target);

// Multitexture
#define	GL_TEXTURE0_ARB 			0x84C0
#define	GL_TEXTURE1_ARB 			0x84C1

#ifdef _WIN32
typedef void (APIENTRY *lpMTexFUNC) (GLenum, GLfloat, GLfloat);
typedef void (APIENTRY *lpSelTexFUNC) (GLenum);
extern lpMTexFUNC qglMultiTexCoord2f;
extern lpSelTexFUNC qglActiveTexture;
#endif

extern qbool gl_mtexable;
extern qbool gl_mtexfbskins;

void GL_DisableMultitexture(void);
void GL_EnableMultitexture(void);

//
// gl_warp.c
//
void GL_SubdivideSurface (msurface_t *fa);
void GL_BuildSkySurfacePolys (msurface_t *fa);
void EmitBothSkyLayers (msurface_t *fa);
void EmitWaterPolys (msurface_t *fa);
void R_ClearSky (void);
void R_DrawSky (void);			// skybox or classic sky
void R_InitSky (texture_t *mt);	// classic Quake sky
extern qbool	r_skyboxloaded;

//
// gl_draw.c
//
void GL_Set2D (void);

//
// gl_rmain.c
//
qbool R_CullBox (vec3_t mins, vec3_t maxs);
qbool R_CullSphere (vec3_t centre, float radius);
void R_RotateForEntity (entity_t *e);
void R_PolyBlend (void);
void R_BrightenScreen (void);

// gl_rmisc.c
void R_ScreenShot_f (void);
void R_LoadSky_f (void);

//
// gl_rlight.c
//
void R_MarkLights (dlight_t *light, int bit, mnode_t *node);
void R_AnimateLight (void);
void R_RenderDlights (void);
int R_LightPoint (vec3_t p, /* out */ vec3_t color);

//
// gl_refrag.c
//
void R_StoreEfrags (efrag_t **ppefrag);

//
// gl_mesh.c
//
void GL_MakeAliasModelDisplayLists (model_t *m, aliashdr_t *hdr);

//
// gl_rsurf.c
//
void R_DrawBrushModel (entity_t *e);
void R_DrawWorld (void);
void R_DrawWaterSurfaces (void);
void GL_BuildLightmaps (void);

//
// gl_ngraph.c
//
void R_NetGraph (void);

//
// gl_ralias.c
//
void R_DrawAliasModel (entity_t *ent);

//
// gl_rsprite.c
//
void R_DrawSpriteModel (entity_t *ent);
